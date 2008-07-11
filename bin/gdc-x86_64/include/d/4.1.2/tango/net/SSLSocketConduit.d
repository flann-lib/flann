/*******************************************************************************

        copyright:      Copyright (c) 2008 Jeff Davey. All rights reserved

        license:        BSD style: $(LICENSE)

        author:         Jeff Davey <j@submersion.com>

*******************************************************************************/

module tango.net.SSLSocketConduit;

import tango.net.SocketConduit;
import tango.net.Socket;
import tango.net.C.OpenSSL;
import tango.net.PKI;
import tango.io.FilePath;
import tango.stdc.stringz;
import tango.time.Time;
import tango.core.Thread;

/*******************************************************************************
    
    SSLSocketConduit is a sub-class of SocketConduit. It's purpose is to
    provide SSL encryption at the socket level as well as easily fit into
    existing Tango network applications that may already be using SocketConduit.

    SSLSocketConduit requires the OpenSSL library, and uses a dynamic binding
    to the library. You can find the library at http://www.openssl.org and a
    Win32 specific port at http://www.slproweb.com/products/Win32OpenSSL.html.

    SSLSocketConduit's have two modes:

    1. Client mode, useful for connecting to existing servers, but not
    accepting new connections. Accepting a new connection will cause 
    the library to stall on a write on connection.

    2. Server mode, useful for creating an SSL server, but not connecting
    to an existing server. Connection will cause the library to stall on a 
    read on connection.

    Example
    ---
    auto s1 = new SSLSocketConduit();
    if (s1.connect(new InternetAddress("www.yahoo.com", 443)))
    {
        char[] cmd = "GET / HTTP/1.0\r\n\r\n";
        s1.write(cmd);
        char[1024] buff;
        uint bytesRead = read(buff);
        if (byteRead != SSLSocketConduit.Eof)
            Stdout.formatln("received: {}", buff[0..bytesRead]);
    }
    ---

*******************************************************************************/

class SSLSocketConduit : SocketConduit
{
    protected BIO *sslSocket = null;
    protected SSLCtx sslCtx = null;
    private bool timeout;
    private timeval tv;
    private SocketSet readSet;
    private SocketSet writeSet;
    private bool fromList;
    private static SSLSocketConduit freelist;
    private SSLSocketConduit next;


    /*******************************************************************************

        Create a default Client Mode SSLSocketConduit.

    *******************************************************************************/

    override this()
    {
        super();
        sslCtx = new SSLCtx();
        sslSocket = _convertToSSL(sslCtx, false, true);
    }

    /*******************************************************************************

        Creates a Client Mode SSLSocketConduit

        This is overriding the SocketConduit ctor in order to emulate the 
        existing free-list frameowrk.

        Specifying anything other than ProtocolType.TCP or SocketType.STREAM will
        cause an Exception to be thrown.

    *******************************************************************************/

    override this(SocketType type, ProtocolType protocol, bool create = true)
    {
        if (protocol != ProtocolType.TCP)
            throw new Exception("SSL is only supported over TCP.");
        if (type != SocketType.STREAM)
            throw new Exception("SSL is only supporting with streaming types.");
        super(type, protocol, create);
        if (create)
        {
            sslCtx = new SSLCtx();
            sslSocket = _convertToSSL(sslCtx, false, true);
        }
    }

    /*******************************************************************************

        Creates a SSLSocketConduit

        This class allows the ability to turn a regular Socket into an
        SSLSocketConduit. It also gives the ability to change an SSLSocketConduit 
        into Server Mode or ClientMode.

        Params:
            sock = The socket to wrap in SSL
            SSLCtx = the SSL Context as provided by the PKI layer.
            clientMode = if true the socket will be Client Mode, Server otherwise.

    *******************************************************************************/


    this(Socket sock, SSLCtx ctx, bool clientMode = true)
    {
        super(SocketType.STREAM, ProtocolType.TCP, false);
        socket_ = sock;
        sslCtx = ctx;
        sslSocket = _convertToSSL(sslCtx, false, clientMode);
    }


    ~this()
    {
        if (sslSocket)
        {
            BIO_reset(sslSocket);
            BIO_free_all(sslSocket);
            sslSocket = null;
        }
    }

    /*******************************************************************************

        Release this SSLSocketConduit. 
        
        As per SocketConduit.detach.

    *******************************************************************************/

    override void detach()
    {
        if (sslSocket)
        {
            BIO_reset(sslSocket);
            BIO_free_all(sslSocket);
            sslSocket = null;
        }
        super.detach();

        if (fromList)
            deallocate(this);
    }    

    /*******************************************************************************

        Allocate a SSLSocketConduit from a free-list, rather than creating a new
        one. 
        
        As per SocketConduit.allocate

    *******************************************************************************/

    package static synchronized SSLSocketConduit allocate()
    {
        SSLSocketConduit s;
        if (freelist)
        {
            s = freelist;
            freelist = s.next;
        }
        else
        {
            s = new SSLSocketConduit(SocketType.STREAM, ProtocolType.TCP, false);
            s.fromList = true;
        }
        return s;
    }

    private static synchronized void deallocate(SSLSocketConduit s)
    {
        s.next = freelist;
        freelist = s;
    }

    /*******************************************************************************

        Writes the passed buffer to the underlying socket stream. This will
        block until socket error.

        As per SocketConduit.write

    *******************************************************************************/

    override uint write(void[] src)
    {
        int bytes = BIO_write(sslSocket, src.ptr, src.length);
        if (bytes <= 0)
            return Eof;
        return bytes;
    }

    /*******************************************************************************

         Reads from the underlying socket stream. If needed, setTimeout will 
        set the max length of time the read will take before returning.

        As per SocketConduit.read

    *******************************************************************************/


    override uint read(void[] dst)
    {
        timeout = false;
        if (tv.tv_usec | tv.tv_sec)
        {
            uint rtn = Eof;
            // need to switch to nonblocking...
            bool blocking = socket_.blocking;
            if (blocking) socket_.blocking = false;
            do
            {
                int bytesRead = BIO_read(sslSocket, dst.ptr, dst.length);
                if (bytesRead <= 0)
                {
                    bool read = false;
                    bool write = false;
                    if (!BIO_should_retry(sslSocket))
                        break;
                    if (BIO_should_read(sslSocket))
                        read = true;
                    if (BIO_should_write(sslSocket))
                        write = true;
                    if (read || write)
                    {
                        if (read)
                        {
                            if (readSet is null)
                                readSet = new SocketSet(1);
                            readSet.reset();
                            readSet.add(socket_);
                        }
                        if (write)
                        {
                            if (writeSet is null)
                                writeSet = new SocketSet(1);
                            writeSet.reset();
                            writeSet.add(socket_);
                        }
                        auto copy = tv;
                        int i = socket_.select(read ? readSet : null, write ? writeSet : null, null, &copy);
                        if (i <= 0)
                        {
                            if (i is 0)
                                timeout = true;
                            break;
                        }
                    }
                    else if (BIO_should_io_special(sslSocket)) // wasn't write, wasn't read.. something "special" just wait for the socket to become ready...
                        Thread.sleep(.05); 
                    else
                        break;
                }
                else
                {                    
                    rtn = bytesRead;
                    break;
                }
            } while(BIO_should_retry(sslSocket));
            if (blocking) socket_.blocking = blocking;
            return rtn;
        }
        int bytes = BIO_read(sslSocket, dst.ptr, dst.length);
        if (bytes <= 0)
            return Eof;
        return bytes;
    }

    /*******************************************************************************

        Returns true if the last read operation timed out.

        As per SocketConduit.hadTimeout;

    *******************************************************************************/

    override bool hadTimeout()
    {
        return timeout;
    }

    /*******************************************************************************

        Shuts down the underlying socket for reading and writing.

        As per SocketConduit.shutdown

    *******************************************************************************/

    override SocketConduit shutdown()
    {
        SSL *obj;
        BIO_get_ssl(sslSocket, &obj);
        if (obj)
        {
            if (!SSL_get_shutdown)
                SSL_set_shutdown(obj, SSL_SENT_SHUTDOWN | SSL_RECEIVED_SHUTDOWN);
        }
        return this;
    }

    /*******************************************************************************

        Used to set the max timeout on read operations.

        As per SocketConduit.setTimeout;

    *******************************************************************************/

    override SocketConduit setTimeout(TimeSpan interval)
    {
        tv = Socket.toTimeval(interval);
        return this;
    }

    /*******************************************************************************

        Used in conjuction with the above ctor with the create flag disabled. It is
        useful for accepting a new socket into a SSLSocketConduit, and then re-using
        the Server's existing SSLCtx.
    
        Params:
            ctx = SSLCtx class as provided by PKI
            clientMode = if true, the socket will be in Client Mode, Server otherwise.

    *******************************************************************************/


    void setCtx(SSLCtx ctx, bool clientMode = true)
    {
        sslCtx = ctx;
        sslSocket = _convertToSSL(sslCtx, false, clientMode);
    }

    /*
        Converts an existing socket (should be TCP) to an "SSL" socket
        close = close the socket when finished -- should probably be false usually
        client = if true, "client-mode" if false "server-mode"
    */
    private BIO *_convertToSSL(SSLCtx sslCtx, bool close, bool client)
    {
        BIO *rtn = null;

        BIO *socketBio = BIO_new_socket(socket_.fileHandle(), close ? BIO_CLOSE : BIO_NOCLOSE);
        if (socketBio)
        {
            rtn = BIO_new_ssl(sslCtx._ctx, client);
            if (rtn)
                rtn = BIO_push(rtn, socketBio);
            if (!rtn)
                BIO_free_all(socketBio);            
        }

        if (rtn is null)
            throwOpenSSLError();
        return rtn;
    }
}

version(Test)
{
    import tetra.util.Test; 
    import tango.io.Stdout;
    import tango.io.File;
    extern (C)
    {
        int blah(int booger, void *x)
        {
            return 1;
        }
    }


    unittest
    {
        auto t2 = TimeSpan.seconds(1);
        loadOpenSSL();
        Test.Status sslCTXTest(inout char[][] messages)
        {
            auto s1 = new SSLSocketConduit();
            if (s1)
            {
                bool good = false;
                try
                    auto s2 = new SSLSocketConduit(SocketType.STREAM,  ProtocolType.UDP);
                catch (Exception e)
                    good = true;

                if (good)
                {
                    Socket mySock = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
                    if (mySock)
                    {
                        Certificate publicCertificate;
                        PrivateKey privateKey;
                        try
                        {
                            publicCertificate = new Certificate(cast(char[])File("public.pem").read); 
                            privateKey = new PrivateKey(cast(char[])File("private.pem").read);
                        }                        
                        catch (Exception ex)
                        {
                            privateKey = new PrivateKey(2048);
                            publicCertificate = new Certificate();
                            publicCertificate.privateKey(privateKey).serialNumber(123).dateBeforeOffset(t1).dateAfterOffset(t2);
                            publicCertificate.setSubject("CA", "Alberta", "Place", "None", "First Last", "no unit", "email@example.com").sign(publicCertificate, privateKey);
                        }                        
                        auto sslCtx = new SSLCtx();
                        sslCtx.certificate(publicCertificate).privateKey(privateKey).checkKey();
                        auto s3 = new SSLSocketConduit(mySock, sslCtx);
                        if (s3)
                            return Test.Status.Success;
                    }
                }
            }
            return Test.Status.Failure;
        }

        Test.Status sslReadWriteTest(inout char[][] messages)
        {
            auto s1 = new SSLSocketConduit();
            auto address = new IPv4Address("209.115.221.132", 443);
            if (s1.connect(address))
            {
                char[] command = "GET /result.txt\r\n";
                s1.write(command);
                char[1024] result;
                uint bytesRead = s1.read(result);
                if (bytesRead > 0 && (result[0 .. bytesRead] == "I got results!\n"))
                    return Test.Status.Success;
                else
                    messages ~= Stdout.layout()("Received wrong results: (bytesRead: {}), (result: {})", bytesRead, result[0..bytesRead]);
            }
            return Test.Status.Failure;
        }

        Test.Status sslReadWriteTestWithTimeout(inout char[][] messages)
        {
            auto s1 = new SSLSocketConduit();
            auto address = new IPv4Address("209.115.221.132", 443);
            if (s1.connect(address))
            {
                char[] command = "GET /result.txt HTTP/1.1\r\nHost: submersion.com\r\n\r\n";
                s1.write(command);
                char[1024] result;
                uint bytesRead = s1.read(result);
                char[] expectedResult = "HTTP/1.1 200 OK";
                if (bytesRead > 0 && (result[0 .. expectedResult.length] == expectedResult))
                {
                    s1.setTimeout(t2);
                    while (bytesRead != SocketConduit.Eof)
                        bytesRead = s1.read(result);                
                    if (s1.hadTimeout)
                        return Test.Status.Success;
                    else
                        messages ~= Stdout.layout()("Did not get timeout on read: {}", bytesRead);
                }
                else
                    messages ~= Stdout.layout()("Received wrong results: (bytesRead: {}), (result: {})", bytesRead, result[0..bytesRead]);
            }
            return Test.Status.Failure;    
        }

        auto t = new Test("tetra.net.SSLSocketConduit");
        t["SSL_CTX"] = &sslCTXTest;
        t["Read/Write"] = &sslReadWriteTest;
        t["Read/Write Timeout"] = &sslReadWriteTestWithTimeout; 
        t.run();
    }
}
