/*******************************************************************************

        copyright:      Copyright (c) 2008 Jeff Davey. All rights reserved

        license:        BSD style: $(LICENSE)

        author:         Jeff Davey <j@submersion.com>

*******************************************************************************/

module tango.net.PKI;

import tango.net.C.OpenSSL;
import tango.time.Time;
import tango.stdc.stringz;

/*******************************************************************************

  PKI provides Public Key Infrastructure. 

  Specifically, it provides the ability to:

  - Make a X509 Certificate (SSL Certificate)

  - Make a Public and Private key pair

  - Validate a X509 Certificate against a Certificate Authority

  - Generate a SSLCtx for SSLSocketConduit and SSLServerSocket

  - Wrap a SSLVerifyCallback so that retrieving the peer cert is easier

  PKI requires the OpenSSL library, and uses a dynamic binding to the library.
  You can find the library at http://www.openssl.org and a Win32 specific port 
  at http://www.slproweb.com/products/Win32OpenSSL.html.

*******************************************************************************/


/*******************************************************************************

  Do not verify the peer certificate. Nor fail if it's not provided (server 
  only).

*******************************************************************************/

const int SSL_VERIFY_NONE = 0x00;

/*******************************************************************************

  Ask for a peer certificate, but do not fail if it is not provided.

*******************************************************************************/

const int SSL_VERIFY_PEER = 0x01;

/*******************************************************************************

  Ask for a peer certificate, however, fail if it is not provided

*******************************************************************************/

const int SSL_VERIFY_FAIL_IF_NO_PEER_CERT = 0x02;

/*******************************************************************************

  Only validate once, do not re-validate during handshake renegotiation.

*******************************************************************************/

const int SSL_VERIFY_CLIENT_ONCE = 0x04;

const int SSL_SESS_CACHE_SERVER = 0x0002;

/*******************************************************************************

  SSLVerifyCallback is passed into SSLCtx and is called during handshake
  when OpenSSL is doing certificate validation.

  Wrapping the X509_STORE_CTX in the CertificateStoreCtx utility class
  gives the ability to access the peer certificate, and reason for error.

*******************************************************************************/

extern (C) typedef int function(int, X509_STORE_CTX *ctx) SSLVerifyCallback;


/*******************************************************************************

    SSLCtx is provided to SSLSocketConduit and SSLServerSocket.

    It contains the public/private keypair, and some additional options that
    control how the SSL streams work.

    Example
    ---
    auto cert = new Certificate(cast(char[])File("public.pem").read);
    auto pkey = new PrivateKey(cast(char[])File("private.pem").read);;
    auto ctx = new SSLCtx();
    ctx.certificate = cert;
    ctx.pkey = pkey;
    ctx.checkKey();
    ---

*******************************************************************************/

class SSLCtx
{
    package SSL_CTX *_ctx = null;
    private Certificate _cert = null;
    private PrivateKey _key = null;
    private CertificateStore _store = null;

    /*******************************************************************************

        Creates a new SSLCtx supporting SSLv3 and TLSv1 methods.

    *******************************************************************************/

    this()
    {
        if ((_ctx = SSL_CTX_new(SSLv23_method())) is null)
            throwOpenSSLError();
    }

    ~this()
    {
        if (_ctx)
        {
            SSL_CTX_free(_ctx);
            _ctx = null;
        }
        _cert = null;
        _key = null;
        _store = null;
    }

    /*******************************************************************************

        Assigns a X509 Certificate to the SSLCtx.

        This is required for SSL
        
    *******************************************************************************/

    SSLCtx certificate(Certificate cert)
    {
        if (SSL_CTX_use_certificate(_ctx, cert._cert))
            _cert = cert;
        else
            throwOpenSSLError();
        return this;
    }

    /*******************************************************************************

        Assigns a PrivateKey (public/private keypair to the SSLCtx.

        This is required for SSL.
                
    *******************************************************************************/


    SSLCtx privateKey(PrivateKey key)
    {
        if (SSL_CTX_use_PrivateKey(_ctx, key._evpKey))
            _key = key;
        else
            throwOpenSSLError();
        return this;
    }

    /*******************************************************************************

        Validates that the X509 certificate was signed with the provided
        public/private keypair. Throws an exception if this is not the case.
                
    *******************************************************************************/

    SSLCtx checkKey()
    {
        if (!SSL_CTX_check_private_key(_ctx))
            throwOpenSSLError();
        return this;
    }

    /*******************************************************************************

        Sets a SSLVerifyCallback function using the SSL_VERIFY_(NONE|PEER|etc) flags
        to control how verification is handled.
                
    *******************************************************************************/

    SSLCtx setVerification(int flags, SSLVerifyCallback cb)
    {
        SSL_CTX_set_verify(_ctx, flags, cb);
        return this;
    }

    /*******************************************************************************

        Sets a CertificateStore of certs that are valid and trust Certificate
        Authorities during verification.
                
    *******************************************************************************/


    SSLCtx store(CertificateStore store) // warning this will free the existing one.. not sure if it frees on close yet ( so don't set it twice! ?!)
    {
        SSL_CTX_set_cert_store(_ctx, store._store);
        _store = store;
        return this;
    }

    /*******************************************************************************

        Loads valid Certificate Authorities from the specified path.

        From the SSL_CTX_load_verify_locations manpage:

        Each file must contain only one CA certificate. Also, the files are
        looked up by the CA subject name hash value, which must be available. If
        more than one CA certificate with the same name hash value exists, the
        extension must be different. (ie: 9d66eef0.0, 9d66eef0.1, etc). The search 
        is performed in the ordering of the extension, regardless of other properties
        of the certificates. Use the c_rehash utility to create the necessary symlinks
                
    *******************************************************************************/

    SSLCtx caCertsPath(char[] path)
    {
        if (!SSL_CTX_load_verify_locations(_ctx, null, toStringz(path)))
            throwOpenSSLError();
        return this;
    }

    // TODO need to finish adding Session handling functionality
/*    void sessionCacheMode(int mode)
    {
        if (!SSL_CTX_set_session_cache_mode(_ctx, mode))
            throwOpenSSLError();
    }

    void sessionId(ubyte[] id)
    {
        if (!SSL_CTX_set_session_id_context(_ctx, id.ptr, id.length))
            throwOpenSSLError();
    } */
}

/*******************************************************************************

    The CertificateStoreCtx is a wrapper to the SSLVerifyCallback X509_STORE_CTX
    parameter.

    It allows retrieving the peer certificate, and examining any errors during
    validation.


    The following example will probably change sometime soon.

    Example
    ---
    extern (C)
    {
        int myCallback(int code, X509_STORE_CTX *ctx)
        {
            auto myCtx = new CertificateStoreCtx(ctx);
            Certificate cert = myCtx.cert;
            Stdout(cert.subject).newline;
            return 0; // BAD CERT! (1 is good)
        }
    }
    ---

*******************************************************************************/

class CertificateStoreCtx
{
    private X509_STORE_CTX *_ctx = null;

    /*******************************************************************************

        This constructor takes a X509_STORE_CTX as provided by the SSLVerifyCallback
        function.
                
    *******************************************************************************/

    this(X509_STORE_CTX *ctx)
    {
        _ctx = ctx;
    }

    /*******************************************************************************

        Returns the peer certificate.
                
    *******************************************************************************/

    Certificate cert()
    {
        X509 *cert = X509_STORE_CTX_get_current_cert(_ctx);
        if (cert is null)
            throwOpenSSLError();
        return new Certificate(cert);
    }

    // TODO need more research on what used for
    int error()
    {
        return X509_STORE_CTX_get_error(_ctx);
    }

    // TODO need more research on what used for
    int errorDepth()
    {
        return X509_STORE_CTX_get_error_depth(_ctx);
    }

}

/*******************************************************************************

    CertificateStore stores numerous X509 Certificates for use in CRL lists,
    CA lists, etc.

    Example
    ---
    auto store = new CertificateStore();
    auto caCert = new Certificate(cast(char[])File("cacert.pem").read);
    store.add(caCert);
    auto untrustedCert = new Certificate(cast(char[])File("cert.pem").read);
    if (untrustedCert.verify(store))
        Stdout("The untrusted cert was signed by our caCert and is valid.").newline;
    else
        Stdout("The untrusted cert was expired, or not signed by the caCert").newline;
    ---
            
*******************************************************************************/

class CertificateStore
{
    package X509_STORE *_store = null;
    Certificate[] _certs;


    this()
    {
        if ((_store = X509_STORE_new()) is null)
            throwOpenSSLError();
    }

    ~this()
    {
        if (_store)
        {
            X509_STORE_free(_store);
            _store = null;
        }
    }

    /*******************************************************************************

        Add a Certificate to the store.
            
    *******************************************************************************/

    CertificateStore add(Certificate cert)
    {
        if (X509_STORE_add_cert(_store, cert._cert))
            _certs ~= cert; // just in case it gets GC'd?
        else
            throwOpenSSLError();
        return this;
    }
}

/*******************************************************************************

    PublicKey contains the RSA public key from a private/public keypair.

    It also allows extraction of the public key from a keypair.

    This is useful for encryption, you can encrypt data with someone's public key
    and they can decrypt it with their private key.

    Example
    ---
    auto public = new PublicKey(cast(char[])File("public.pem").read);
    auto encrypted = public.encrypt(cast(ubyte[])"Hello, how are you today?");
    auto pemData = public.pemFormat;
    ---

*******************************************************************************/

class PublicKey
{
    package RSA *_evpKey = null;
    private PrivateKey _existingKey = null;

    /*******************************************************************************

        Generate a PublicKey object from the passed PEM formatted data

        Params:
            publicPemData = pem encoded data containing the public key 
            
    *******************************************************************************/
    this (char[] publicPemData)
    {
        BIO *bp = BIO_new_mem_buf(publicPemData.ptr, publicPemData.length);
        if (bp)
        {
            _evpKey = PEM_read_bio_RSAPublicKey(bp, null, null, null);
            BIO_free_all(bp);
        }

        if (_evpKey is null)
            throwOpenSSLError();
    }
    package this(PrivateKey key) 
    {        
        this._evpKey = cast(RSA *)key._evpKey.pkey;
        this._existingKey = key;
    }

    ~this()
    {
        if (_existingKey !is null)
        {
            _existingKey = null;
            _evpKey = null;
        }
        else if (_evpKey)
        {
            RSA_free(_evpKey);
            _evpKey = null;
        }
    }

    /*******************************************************************************

        Return a PublicKey in the PEM format.
            
    *******************************************************************************/

    char[] pemFormat()
    {
        char[] rtn = null;
        BIO *bp = BIO_new(BIO_s_mem());
        if (bp)
        {
            if (PEM_write_bio_RSAPublicKey(bp, _evpKey))
            {
                char *pemData = null;
                int pemSize = BIO_get_mem_data(bp, &pemData);
                rtn = pemData[0..pemSize].dup;
            }
            BIO_free_all(bp);
        }
        if (rtn is null)
            throwOpenSSLError();
        return rtn;
    }

    /*******************************************************************************

        Encrypt the passed data using the PublicKey 
        
        Notes:
        This is size limited based off the key
        Not recommended for general encryption, use RSA for encrypting a 
        random key instead and switch to a block cipher.

        Params:
        data = the data to encrypt
            
    *******************************************************************************/

    ubyte[] encrypt(ubyte[] data)
    {
        ubyte[] rtn;

        uint maxSize = RSA_size(_evpKey);
        if (data.length > maxSize)
            throw new Exception("The specified data is larger than the size that can be encrypted by this public key.");
        ubyte[] tmpRtn = new ubyte[maxSize];
        int numBytes = RSA_public_encrypt(data.length, data.ptr, tmpRtn.ptr, _evpKey, RSA_PKCS1_OAEP_PADDING);
        if (numBytes >= 0)
            rtn = tmpRtn[0..numBytes];
        if (rtn is null)
            throwOpenSSLError();
        return rtn;
    }

     /*******************************************************************************

        Decrypts data previously encrypted with the matching PrivateKey

        Please see the encrypt notes.

        Parmas:
            data = the data to encrypt

    *******************************************************************************/
       
    ubyte[] decrypt(ubyte[] data)
    {
        ubyte[] rtn;

        uint maxSize = RSA_size(_evpKey);
        ubyte[] tmpRtn = new ubyte[maxSize];
        int numBytes = RSA_public_decrypt(data.length, data.ptr, tmpRtn.ptr, _evpKey, RSA_PKCS1_PADDING);
        if (numBytes >= 0)
            rtn = tmpRtn[0..numBytes];
        if (rtn is null)
            throwOpenSSLError();
        return rtn;
    }

}

/*******************************************************************************

    Generates a RSA public/private key pair for use with X509 Certificates
    and other applications search as S/MIME, DomainKeys, etc.

    Example
    ---
    auto newPkey = new PrivateKey(2048); // create new keypair
    Stdout(newPkey.pemFormat("password")); // dumps in pemFormat with encryption
    Stdout(newPkey.pemFormat()); // dumps in pemFormat without encryption
    Stdout(newPkey.publicKey.pemFormat); // dump out just the public key portion
    auto data = newPkey.decrypt(someData); // decrypt data encrypted with public Key
    ---

*******************************************************************************/

class PrivateKey
{
    package EVP_PKEY *_evpKey = null;

    /*******************************************************************************

        Reads in the provided PEM data, with an optional password to decrypt
        the private key.

        Params:
            privatePemData = the PEM encoded data of the private key
            certPass = an optional password to decrypt the key.
        
    *******************************************************************************/

    this (char[] privatePemData, char[] certPass = null)
    {
        BIO *bp = BIO_new_mem_buf(privatePemData.ptr, privatePemData.length);
        if (bp)
        {
            _evpKey = PEM_read_bio_PrivateKey(bp, null, null, certPass ? toStringz(certPass) : null);
            BIO_free_all(bp);
        }

        if (_evpKey is null)
            throwOpenSSLError();
    }

    /*******************************************************************************

        Generates a new private/public key at the specified bit leve.

        Params:
            bits = Number of bits to use, 2048 is a good number for this.
        
    *******************************************************************************/


    this(int bits)
    {
        RSA *rsa = RSA_generate_key(bits, RSA_F4, null, null);
        if (rsa)
        {
            if ((_evpKey = EVP_PKEY_new()) !is null)
                EVP_PKEY_assign_RSA(_evpKey, rsa);
            if (_evpKey is null)
                RSA_free(rsa);
        }

        if (_evpKey is null)
            throwOpenSSLError();
    }
    
    ~this()
    {
        if (_evpKey)
        {
            EVP_PKEY_free(_evpKey);
            _evpKey = null;
        }
    }

    /*******************************************************************************

        Compares two PrivateKey classes to see if the internal structures are 
        the same.
        
    *******************************************************************************/


    int opEquals(PrivateKey obj)
    {
        return EVP_PKEY_cmp_parameters(obj._evpKey, this._evpKey);
    }

    /*******************************************************************************

        Returns the underlying public/private key pair in PEM format.

        Params:
            pass = If this is provided, the private key will be encrypted using
            AES 256bit encryption, with this as the key.
        
    *******************************************************************************/


    char[] pemFormat(char[] pass = null)
    {
        char[] rtn = null;
        BIO *bp = BIO_new(BIO_s_mem());
        if (bp)
        {
            if (PEM_write_bio_PKCS8PrivateKey(bp, _evpKey, pass ? EVP_aes_256_cbc() : null, null, 0, null, pass ? toStringz(pass) : null))
            {
                char *pemData = null;
                int pemSize = BIO_get_mem_data(bp, &pemData);
                rtn = pemData[0..pemSize].dup;
            }
            BIO_free_all(bp);
        }
        if (rtn is null)
            throwOpenSSLError();
        return rtn;
    }

    /*******************************************************************************

        Returns the underlying PublicKey

    *******************************************************************************/

    PublicKey publicKey()
    {
        auto rtn = new PublicKey(this);
        return rtn;
    }

    /*******************************************************************************

        Encrypt the passed data using the PrivateKey
        
        Notes:
        This is size limited based off the key
        Not recommended for general encryption, use RSA for encrypting a 
        random key instead and switch to a block cipher.

        Params:
        data = the data to encrypt
            
    *******************************************************************************/

    ubyte[] encrypt(ubyte[] data)
    {
        ubyte[] rtn;

        uint maxSize = RSA_size(cast(RSA *)_evpKey.pkey);
        if (data.length > maxSize)
            throw new Exception("The specified data is larger than the size that can be encrypted by this public key.");
        ubyte[] tmpRtn = new ubyte[maxSize];
        int numBytes = RSA_private_encrypt(data.length, data.ptr, tmpRtn.ptr, cast(RSA *)_evpKey.pkey, RSA_PKCS1_PADDING);
        if (numBytes >= 0)
            rtn = tmpRtn[0..numBytes];
        if (rtn is null)
            throwOpenSSLError();
        return rtn;
    }

     /*******************************************************************************

        Decrypts data previously encrypted with the matching PublicKey

        Please see the encrypt notes.

        Parmas:
            data = the data to encrypt

    *******************************************************************************/
       
    ubyte[] decrypt(ubyte[] data)
    {
        ubyte[] rtn;

        uint maxSize = RSA_size(cast(RSA *)_evpKey.pkey);
        ubyte[] tmpRtn = new ubyte[maxSize];
        int numBytes = RSA_private_decrypt(data.length, data.ptr, tmpRtn.ptr, cast(RSA *)_evpKey.pkey, RSA_PKCS1_OAEP_PADDING);
        if (numBytes >= 0)
            rtn = tmpRtn[0..numBytes];
        if (rtn is null)
            throwOpenSSLError();
        return rtn;
    }

}

/*******************************************************************************

    Certificate provides necessary functionality to create and read X509 
    Certificates.

    Note, once a Certificate has been signed, it is immutable, and cannot
    be modified.

    X509 Certificates are sometimes called SSL Certificates.

    Example
    ---
    auto newPkey = new PrivateKey(2048); // create new keypair
    auto cert = new Certificate();
    cert.privateKey = newPkey;
    cert.serialNumber = 1;
    cert.dateBeforeOffset = TimeSpan.zero;
    cert.dateAfterOffset = TimeSpan.days(365); // cert is valid for one year
    cert.setSubject("US", "State", "City", "Organization", "CN", "Organizational Unit", "Email");
    cert.sign(cert, newPkey); // self signed cert
    Stdout(newPkey.pemFormat).newline;
    Stdout(cert.pemFormat).newline;
    ---

*******************************************************************************/

class Certificate
{
    package X509 *_cert = null;
    private bool readOnly = true;
    private bool freeIt = true;

    // used with X509_STORE_CTX
    package this (X509 *cert)
    {
        _cert = cert;
        freeIt = false;
    }

    /*******************************************************************************

        Parses a X509 Certificate from the provided PEM encoded data.
            
    *******************************************************************************/
    this(char[] publicPemData)
    {
        BIO *data = BIO_new_mem_buf(publicPemData.ptr, publicPemData.length);
        if (data)
        {
            _cert = PEM_read_bio_X509(data, null, null, null);
            BIO_free_all(data);
        }
        if (_cert is null)
            throwOpenSSLError();
    }

    /*******************************************************************************

        Creates a new and un-signed (empty) X509 certificate. Useful for generating
        X509 certificates programatically.
            
    *******************************************************************************/
    this()
    {
        if ((_cert = X509_new()) !is null)
        {
            if (!X509_set_version(_cert, 2)) // 2 == Version 3
            {
                X509_free(_cert);
                _cert = null;
            }
            else
                readOnly = false;
        }
        if (_cert is null)
            throwOpenSSLError();
    }

    ~this()
    {
        if (_cert && freeIt)
        {
            X509_free(_cert);
            _cert = null;
        }
    }

    /*******************************************************************************

        Sets the serial number of the new unsigned certificate.

        Note, this serial number should be unique for all certificates signed
        by the provided certificate authority. Having two Certificates with the
        same serial number can cause problems with web browsers and other apps
        because they will be different certificates.
            
    *******************************************************************************/

    Certificate serialNumber(uint serial)
    {
        checkFlag();
        if (!ASN1_INTEGER_set(X509_get_serialNumber(_cert), serial))
            throwOpenSSLError();
        return this;
    }
    /*******************************************************************************

        Returns the serial number of the Certificate
            
    *******************************************************************************/

    uint serialNumber()
    {
        if (!X509_get_serialNumber(_cert))
            throwOpenSSLError();
        return ASN1_INTEGER_get(X509_get_serialNumber(_cert));
    }

    /*******************************************************************************

        If the current date is "before" the date set here, the certificate will be
        invalid.

        Params:
            t = A TimeSpan representing the earliest time the Certificate will be valid

        Example:
            cert.dateBeforeOffset = TimeSpan.seconds(-86400); // Certificate is invalid before yesterday
            
    *******************************************************************************/

    Certificate dateBeforeOffset(TimeSpan t)
    {
        checkFlag();
        if (!X509_gmtime_adj(X509_get_notBefore(_cert), cast(int)t.seconds))
            throwOpenSSLError();
        return this;
    }

    /*******************************************************************************

        If the current date is "after" the date set here, the certificate will be
        invalid.

        Params:
            t = A TimeSpan representing the amount of time from now that the
            Certificate will be valid. This must be larger than dateBefore

        Example:
            cert.dateAfterOffset = TimeSpan.seconds(86400 * 365); // Certificate is valid up to one year from now
            
    *******************************************************************************/

    Certificate dateAfterOffset(TimeSpan t)
    {
        checkFlag();
        if (!X509_gmtime_adj(X509_get_notAfter(_cert), cast(int)t.seconds))
            throwOpenSSLError();
        return this;
    }

    
    /*******************************************************************************

        Returns the dateAfter field of the certificate in ASN1_GENERALIZEDTIME.

        Note, this will eventually befome a DateTime struct.
            
    *******************************************************************************/

    char[] dateAfter()
    {
        char[] rtn;
        ASN1_GENERALIZEDTIME *genTime = ASN1_TIME_to_generalizedtime(X509_get_notAfter(_cert), null);
        if (genTime)
        {
            rtn = genTime.data[0..genTime.length].dup;
            ASN1_STRING_free(cast(ASN1_STRING*)genTime);
        }

        return rtn;
    }

    /*******************************************************************************

        Returns the dateBefore field of the certificate in ASN1_GENERALIZEDTIME.

        Note, this will eventually befome a DateTime struct.
            
    *******************************************************************************/

    char[] dateBefore()    
    {
        char[] rtn;
        ASN1_GENERALIZEDTIME *genTime = ASN1_TIME_to_generalizedtime(X509_get_notBefore(_cert), null);
        if (genTime)
        {
            rtn = genTime.data[0..genTime.length].dup;
            ASN1_STRING_free(cast(ASN1_STRING*)genTime);
        }
        return rtn;
    }

    /*******************************************************************************

        Sets the public/private keypair of an unsigned certificate.
            
    *******************************************************************************/

    Certificate privateKey(PrivateKey key)
    {
        checkFlag();
        if (key)
        {
            if (!X509_set_pubkey(_cert, key._evpKey))
                throwOpenSSLError();
        }
        return this;
    }

    /*******************************************************************************

        Sets the subject (who this certificate is for) of an unsigned certificate.

        The country code must be a valid two-letter country code (ie: CA, US, etc)

        Params:
        country = the two letter country code of the subject
        stateProvince = the state or province of the subject
        city = the city the subject belong to
        organization = the organization the subject belongs to
        cn = the cn of the subject. For websites, this should be the website url
        or a wildcard version of it (ie: *.dsource.org)
        organizationUnit = the optional orgnizationalUnit of the subject
        email = the optional email address of the subject

    *******************************************************************************/

    // this kinda sucks.. but it has to be done in a certain order..
    Certificate setSubject(char[] country, char[] stateProvince, char[] city, char[] organization, char[] cn, char[] organizationalUnit = null, char[] email = null)
    in
    {
        assert(country);
        assert(stateProvince);
        assert(organization);
        assert(cn);
    }
    body
    {
        checkFlag();
        X509_NAME *name = X509_get_subject_name(_cert);
        if (name)
        {
            addNameEntry(name, "C", country);
            addNameEntry(name, "ST", stateProvince);
            addNameEntry(name, "L", city);
            addNameEntry(name, "O", organization);
            if (organizationalUnit !is null)
                addNameEntry(name, "OU", organizationalUnit);
            if (email) // this might have to go after the CN
                addNameEntry(name, "emailAddress", email);
            addNameEntry(name, "CN", cn);
        }
        else
            throwOpenSSLError();
        return this;
    }

    /*******************************************************************************

        Returns the Certificate subject in a multi-line string.
            
    *******************************************************************************/

    char[] subject() // currently multi-line, could be single-line..
    {
        char[] rtn = null;
        X509_NAME *subjectName = X509_get_subject_name(_cert);
        if (subjectName)
        {
            BIO *subjectBIO = BIO_new(BIO_s_mem());
            if (subjectBIO)
            {
                if (X509_NAME_print_ex(subjectBIO, subjectName, 0, XN_FLAG_MULTILINE))
                {
                    char *subjectPtr = null;
                    int length = BIO_get_mem_data(subjectBIO, &subjectPtr);
                    rtn = subjectPtr ? subjectPtr[0..length].dup : null;
                }
                BIO_free_all(subjectBIO);
            }
        }
        if (rtn is null)
            throwOpenSSLError();
        return rtn;
    }

    /*******************************************************************************

        Signs the unsigned Certificate with the specified CA X509 Certificate and
        it's corresponding public/private keypair.

        Once the Certificate is signed, it can no longer be modified.
            
    *******************************************************************************/

    Certificate sign(Certificate caCert, PrivateKey caKey)
    in
    {
        assert(caCert);
        assert(caKey);
    }
    body
    {
        checkFlag();
        X509_NAME *issuer = X509_get_subject_name(caCert._cert);
        if (issuer)
        {
            if (X509_set_issuer_name(_cert, issuer))
            {
                if (X509_sign(_cert, caKey._evpKey, EVP_sha1()))
                    readOnly = true;
            }
        }

        if (!readOnly)
            throwOpenSSLError();
        return this;
    }

    /*******************************************************************************

        Checks if the underlying data structur of the Certificate is equal
            
    *******************************************************************************/

    int opEquals(Certificate obj)
    {
        return !X509_cmp(obj._cert, this._cert);
    }

    /*******************************************************************************

        Verifies that the Certificate was signed and issues by a CACert in the 
        passed CertificateStore.

        This will also verify the dateBefore and dateAfter fields to see if the
        current date falls between them.
            
    *******************************************************************************/

    bool verify(CertificateStore store)
    {
        bool rtn = false;
        X509_STORE_CTX *verifyCtx = X509_STORE_CTX_new();
        if (verifyCtx)
        {
            if (X509_STORE_CTX_init(verifyCtx, store._store, _cert, null))
            {
                if (X509_verify_cert(verifyCtx))
                    rtn = true;
            }
            X509_STORE_CTX_free(verifyCtx);
        }

        return rtn;
    }

    /*******************************************************************************

        Returns the Certificate in a PEM encoded string.
            
    *******************************************************************************/

    char[] pemFormat()
    {
        char[] rtn = null;
        BIO *bp = BIO_new(BIO_s_mem());
        if (bp)
        {
            if (PEM_write_bio_X509(bp, _cert))
            {
                char *pemData = null;
                int pemSize = BIO_get_mem_data(bp, &pemData);
                rtn = pemData[0..pemSize].dup;
            }
            BIO_free_all(bp);
        }
        if (rtn is null)
            throwOpenSSLError();
        return rtn;    
    }

    private void addNameEntry(X509_NAME *name, char *type, char[] value)
    {
        if (!X509_NAME_add_entry_by_txt(name, type, MBSTRING_ASC, toStringz(value), value.length, -1, 0))
            throwOpenSSLError();
    }

    private void checkFlag()
    {
        if (readOnly)
            throw new Exception("The cert is signed already, and cannot be modified.");
    }
}


version (Test)
{
    import tetra.util.Test;
    import tango.io.Stdout;

    auto t1 = TimeSpan.zero;
    auto t2 = TimeSpan.days(365); // can't set this up in delegate ..??
    unittest
    {
        Test.Status _pkeyGenTest(inout char[][] messages)
        {
            auto pkey = new PrivateKey(2048);
            char[] pem = pkey.pemFormat;
            auto pkey2 = new PrivateKey(pem);
            if (pkey == pkey2)
            {
                auto pkey3 = new PrivateKey(2048);
                char[] pem2 = pkey3.pemFormat("hello");
                try
                    auto pkey4 = new PrivateKey(pem2, "badpass");
                catch (Exception ex)
                {
                    auto pkey4 = new PrivateKey(pem2, "hello");
                    return Test.Status.Success;
                }
            }
                
            return Test.Status.Failure;
        }

        Test.Status _certGenTest(inout char[][] messages)
        {
            auto cert = new Certificate();
            auto pkey = new PrivateKey(2048);
            cert.privateKey(pkey).serialNumber(123).dateBeforeOffset(t1).dateAfterOffset(t2);
            cert.setSubject("CA", "Alberta", "Place", "None", "First Last", "no unit", "email@example.com").sign(cert, pkey);
            char[] pemData = cert.pemFormat;
            auto cert2 = new Certificate(pemData);
//            Stdout.formatln("{}\n{}\n{}\n{}", cert2.serialNumber, cert2.subject, cert2.dateBefore, cert2.dateAfter);
            if (cert2 == cert)
                return Test.Status.Success;
            return Test.Status.Failure;
        }

        Test.Status _chainValidation(inout char[][] messages)
        {
            auto caCert = new Certificate();
            auto caPkey = new PrivateKey(2048);
            caCert.serialNumber = 1;
            caCert.privateKey = caPkey;
            caCert.dateBeforeOffset = t1;
            caCert.dateAfterOffset = t2;
            caCert.setSubject("CA", "Alberta", "CA Place", "Super CACerts Anon", "CA Manager");
            caCert.sign(caCert, caPkey);
            auto store = new CertificateStore();
            store.add(caCert);

            auto subCert = new Certificate();
            auto subPkey = new PrivateKey(2048);
            subCert.serialNumber = 2;
            subCert.privateKey = subPkey;
            subCert.dateBeforeOffset = t1;
            subCert.dateAfterOffset = t2;
            subCert.setSubject("US", "California", "Customer Place", "Penny-Pincher", "IT Director");
            subCert.sign(caCert, caPkey);

            if (subCert.verify(store))
            {
                auto fakeCert = new Certificate();
                auto fakePkey = new PrivateKey(2048);
                fakeCert.serialNumber = 1;
                fakeCert.privateKey = fakePkey;
                fakeCert.dateBeforeOffset = t1;
                fakeCert.dateAfterOffset = t2;
                fakeCert.setSubject("CA", "Alberta", "CA Place", "Super CACerts Anon", "CA Manager");
                fakeCert.sign(caCert, caPkey);
                auto store2 = new CertificateStore();
                if (!subCert.verify(store2))
                    return Test.Status.Success;
            }

            return Test.Status.Failure;
        }   

        Test.Status _rsaCrypto(inout char[][] messages)
        {
            auto key = new PrivateKey(2048);
            char[] pemData = key.publicKey.pemFormat;
            auto pub = new PublicKey(pemData);
            auto encrypted = pub.encrypt(cast(ubyte[])"Hello, how are you today?");
            auto decrypted = key.decrypt(encrypted);
            if (cast(char[])decrypted == "Hello, how are you today?")
            {
                encrypted = key.encrypt(cast(ubyte[])"Hello, how are you today, mister?");
                decrypted = pub.decrypt(encrypted);
                if (cast(char[])decrypted == "Hello, how are you today, mister?")
                    return Test.Status.Success;
            }
            return Test.Status.Failure;
        }


        auto t = new Test("tetra.net.PKI");
        t["Public/Private Keypair"] = &_pkeyGenTest;
        t["Self-Signed Certificate"] = &_certGenTest;
        t["Chain Validation"] = &_chainValidation;
        t["RSA Crypto"] = &_rsaCrypto;
        t.run();
    }
}
