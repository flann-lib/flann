/**
 * Oracle import library.
 *
 * Part of the D DBI project.
 *
 * Version:
 *	Oracle 10g revision 2
 *
 *	Import library version 0.04
 *
 * Authors: The D DBI project
 *
 * Copyright: BSD license
 */
module dbi.oracle.imp.nzt;

private import dbi.oracle.imp.nzerror, dbi.oracle.imp.oratypes;

const uint NZT_MAX_SHA1			= 20;		///
const uint NZT_MAX_MD5			= 16;		///

deprecated const text[] NZT_DEFAULT_WRL	= "default:";	/// Uses directory defined by the parameter SNZD_DEFAULT_FILE_DIRECTORY which in unix is "$HOME/oracle/oss."
const text[] NZT_SQLNET_WRL		= "sqlnet:";	/// In this case, the directory path will be retrieved from the sqlnet.ora file under the oss.source.my_wallet parameter.
const text[] NZT_FILE_WRL		= "file:";	/// Find the Oracle wallet in this directory. eg: file:<dir-path>.
const text[] NZT_ENTR_WRL		= "entr:";	/// Entrust WRL. eg: entr:<dir-path>.
const text[] NZT_MCS_WRL		= "mcs:";	/// Microsoft WRL.
const text[] NZT_ORACLE_WRL		= "oracle:";	///
const text[] NZT_REGISTRY_WRL		= "reg:";	///

/**
 *
 */
enum nzttwrl {
	NZTTWRL_DEFAULT = 1,				/// Default, use SNZD_DEFAULT_FILE_DIRECTORY.
	NZTTWRL_SQLNET,					/// Use oss.source.my_wallet in sqlnet.ora file.
	NZTTWRL_FILE,					/// Find the oracle wallet in this directory.
	NZTTWRL_ENTR,					/// Find the entrust profile in this directory.
	NZTTWRL_MCS,					/// WRL for Microsoft.
	NZTTWRL_ORACLE,					/// Get the wallet from OSS db.
	NZTTWRL_NULL,					/// New SSO defaulting mechanism.
	NZTTWRL_REGISTRY				/// Find the wallet in Windows Registry.
}

/**
 *
 */
struct nzctx {
}

/**
 *
 */
struct nzstrc {
}

/**
 *
 */
struct nzosContext {
}

/**
 *
 */
struct nzttIdentityPrivate {
}

/**
 *
 */
struct nzttPersonaPrivate {
}

/**
 *
 */
struct nzttWalletPrivate {
}

/**
 * For wallet object.
 */
struct nzttWalletObj {
}

/**
 * For secretstore.
 */
struct nzssEntry {
}

/**
 *
 */
struct nzpkcs11_Info {
}

/**
 * Crypto Engine State.
 *
 * Once the crypto engine (CE) has been initialized for a particular
 * cipher, it is either at the initial state, or it is continuing to
 * use the cipher.  NZTCES_END is used to change the state back to
 * initialized and flush any remaining output.  NZTTCES_RESET can be
 * used to change the state back to initialized and throw away any
 * remaining output.
 */
enum nzttces {
	NZTTCES_CONTINUE = 1,				/// Continue processing input.
	NZTTCES_END,					/// End processing input.
	NZTTCES_RESET					/// Reset processing and skip generating output.
}

/**
 * Crypto Engine Functions.
 *
 * List of crypto engine categories; used to index into protection
 * vector.
 */
enum nzttcef {
	NZTTCEF_DETACHEDSIGNATURE = 1,			/// Signature detached from content.
	NZTTCEF_SIGNATURE,				/// Signature combined with content.
	NZTTCEF_ENVELOPING,				/// Signature and encryption with content.
	NZTTCEF_PKENCRYPTION,				/// Encryption for one or more recipients.
	NZTTCEF_ENCRYPTION,				/// Symmetric encryption.
	NZTTCEF_KEYEDHASH,				/// Keyed hash/checksum.
	NZTTCEF_HASH,					/// Hash/checksum.
	NZTTCEF_RANDOM,					/// Random byte generation.
	NZTTCEF_LAST					/// Used for array size.
}

/**
 * State of the persona.
 */
enum nzttState {
	NZTTSTATE_EMPTY = 0,				/// Is not in any state(senseless???).
	NZTTSTATE_REQUESTED,				/// Cert-request.
	NZTTSTATE_READY,				/// Certificate.
	NZTTSTATE_INVALID,				/// Certificate.
	NZTTSTATE_RENEWAL				/// Renewal-requested.
}

/**
 * Cert-version types.
 *
 * This is used to quickly look-up the cert-type.
 */
enum nzttVersion {
	NZTTVERSION_X509v1 = 1,				/// X.509v1.
	NZTTVERSION_X509v3,				/// X.509v3.
	NZTTVERSION_SYMMETRIC,				/// Deprecated.  Symmetric.
	NZTTVERSION_INVALID_TYPE			/// For Initialization.
}

/**
 * Cipher Types.
 *
 * List of all cryptographic algorithms, some of which may not be
 * available.
 */
enum nzttCipherType {
	NZTTCIPHERTYPE_RSA = 1,				/// RSA public key.
	NZTTCIPHERTYPE_DES,				/// DES.
	NZTTCIPHERTYPE_RC4,				/// RC4.
	NZTTCIPHERTYPE_MD5DES,				/// DES encrypted MD5 with salt (PBE).
	NZTTCIPHERTYPE_MD5RC2,				/// RC2 encrypted MD5 with salt (PBE).
	NZTTCIPHERTYPE_MD5,				/// MD5.
	NZTTCIPHERTYPE_SHA				/// SHA.
}

/**
 * TDU Formats.
 *
 * List of possible toolkit data unit (TDU) formats.  Depending on the
 * function and cipher used some may be not be available.
 */
enum nztttdufmt {
	NZTTTDUFMT_PKCS7 = 1,				/// PKCS7 format.
	NZTTTDUFMT_RSAPAD,				/// RSA padded format.
	NZTTTDUFMT_ORACLEv1,				/// Oracle v1 format.
	NZTTTDUFMT_LAST					/// Used for array size.
}

/**
 * Validation States.
 *
 * Possible validation states an identity can be in.
 */
enum nzttValState {
	NZTTVALSTATE_NONE = 1,				/// Needs to be validated.
	NZTTVALSTATE_GOOD,				/// Validated.
	NZTTVALSTATE_REVOKED				/// Failed to validate.
}

/**
 * Policy Fields.
 *
 * Policies enforced.
 */
enum nzttPolicy {
	NZTTPOLICY_NONE = 0,				/// No retries are allowed.
	NZTTPOLICY_RETRY_1,				/// Number of retries for decryption = 1.
	NZTTPOLICY_RETRY_2,				/// Number of retries for decryption = 2.
	NZTTPOLICY_RETRY_3				/// Number of retries for decryption = 3.
}

/*
 * Persona Usage.
 *
 * Deprecated:
 *
 *
 * What a persona will be used for?
 */
deprecated enum nzttUsage {
	NZTTUSAGE_NONE = 0,				///
	NZTTUSAGE_SSL					/// Persona for SSL usage.
}

/**
 * Personas and identities have unique id's that are represented with
 * 128 bits.
 */
alias ub1[16] nzttID;

/**
 * Identity Types
 *
 * List of all Identity types..
 */
enum nzttIdentType {
	NZTTIDENTITYTYPE_INVALID_TYPE = 0,		///
	NZTTIDENTITYTYPE_CERTIFICTAE,			///
	NZTTIDENTITYTYPE_CERT_REQ,			///
	NZTTIDENTITYTYPE_RENEW_CERT_REQ,		///
	NZTTIDENTITYTYPE_CLEAR_ETP,			///
	NZTTIDENTITYTYPE_CLEAR_UTP,			///
	NZTTIDENTITYTYPE_CLEAR_PTP			///
}

alias ub4 nzttKPUsage;

const uint NZTTKPUSAGE_NONE		= 0;
const uint NZTTKPUSAGE_SSL		= 1;		/// SSL Server.
const uint NZTTKPUSAGE_SMIME_ENCR	= 2;
const uint NZTTKPUSAGE_SMIME_SIGN	= 4;
const uint NZTTKPUSAGE_CODE_SIGN	= 8;
const uint NZTTKPUSAGE_CERT_SIGN	= 16;
const uint NZTTKPUSAGE_SSL_CLIENT	= 32;		/// SSL Client.
const uint NZTTKPUSAGE_INVALID_USE	= 0xffff;

/**
 * Timestamp as 32 bit quantity in UTC.
 */
alias ub1[4] nzttTStamp;

/**
 * Buffer Block.
 *
 * A function that needs to fill (and possibly grow) an output buffer
 * uses an output parameter block to describe each buffer.
 *
 * The flags_nzttBufferBlock member tells the function whether the
 * buffer can be grown or not.  If flags_nzttBufferBlock is 0, then
 * the buffer will be realloc'ed automatically.
 *
 * The buflen_nzttBufferBLock member is set to the length of the
 * buffer before the function is called and will be the length of the
 * buffer when the function is finished.  If buflen_nzttBufferBlock is
 * 0, then the initial pointer stored in pobj_nzttBufferBlock is
 * ignored.
 *
 * The objlen_nzttBufferBlock member is set to the length of the
 * object stored in the buffer when the function is finished.  If the
 * initial buffer had a non-0 length, then it is possible that the
 * object length is shorter than the buffer length.
 *
 * The pobj_nzttBufferBlock member is a pointer to the output object.
 */
struct nzttBufferBlock {
	uword flags_nzttBufferBlock;			/// Flags.
	ub4 buflen_nzttBufferBlock;			/// Total length of buffer.
	ub4 usedlen_nzttBufferBlock;			/// Length of used buffer part.
	ub1 *buffer_nzttBufferBlock;			/// Pointer to buffer.
}

const uint NZT_NO_AUTO_REALLOC		= 0x1;		///

/**
 * Wallet.
 */
struct nzttWallet {
	ub1* ldapName_nzttWallet;			/// User's LDAP name.
	ub4 ldapNamelen_nzttWallet;			/// Length of user's LDAP name.
	nzttPolicy securePolicy_nzttWallet;		/// Secured-policy of the wallet.
	nzttPolicy openPolicy_nzttWallet;		/// Open-policy of the wallet.
	nzttPersona* persona_nzttWallet;		/// List of personas in wallet.
	nzttWalletPrivate* private_nzttWallet;		/// Private wallet information.
	ub4 npersona_nzttWallet;			/// Deprecated.  Number of personas.
}

/**
 * Persona.
 *
 * The wallet contains one or more personas.  A persona always
 * contains its private key and its identity.  It may also contain
 * other 3rd party identites.  All identities qualified with trust
 * where the qualifier can indicate anything from untrusted to trusted
 * for specific operations.
 */
struct nzttPersona {
	ub1*genericName_nzttPersona;			/// User-friendly persona name.
	ub4 genericNamelen_nzttPersona;			/// Persona-name length.
	nzttPersonaPrivate* private_nzttPersona;	/// Opaque part of persona.
	nzttIdentity* mycertreqs_nzttPersona;		/// My cert-requests.
	nzttIdentity* mycerts_nzttPersona;		/// My certificates.
	nzttIdentity* mytps_nzttPersona;		/// List of trusted identities.
	nzssEntry* mystore_nzttPersona;			/// List of secrets.
	nzpkcs11_Info* mypkcs11Info_nzttPersona;	/// PKCS11 token info.
	nzttPersona* next_nzttPersona;			/// Next persona.

	nzttUsage usage_nzttPersona;			/// Deprecated.  persona usage; SSL/SET/etc.
	nzttState state_nzttPersona;			/// Deprecated.  persona state-requested/ready.
	ub4 ntps_nzttPersona;				/// Deprecated.  Num of trusted identities.
}

/**
 * Identity.
 *
 * Structure containing information about an identity.
 *
 * NOTE
 *  -- the next_trustpoint field only applies to trusted identities and
 *     has no meaning (i.e. is null) for self identities.
 */
struct nzttIdentity {
	text* dn_nzttIdentity;				/// Alias.
	ub4 dnlen_nzttIdentity;				/// Length of alias.
	text* comment_nzttIdentity;			/// Comment.
	ub4 commentlen_nzttIdentity;			/// Length of comment.
	nzttIdentityPrivate* private_nzttIdentity;	/// Opaque part of identity.
	nzttIdentity* next_nzttIdentity;		/// Next identity in list.
}

/**
 *
 */
struct nzttB64Cert {
	ub1* b64Cert_nzttB64Cert;			///
	ub4 b64Certlen_nzttB64Cert;			///
	nzttB64Cert* next_nzttB64Cert;			///
}

/**
 *
 */
struct nzttPKCS7ProtInfo {
	nzttCipherType mictype_nzttPKCS7ProtInfo;	/// Hash cipher.
	nzttCipherType symmtype_nzttPKCS7ProtInfo;	/// Symmetric cipher.
	ub4 keylen_nzttPKCS7ProtInfo;			/// Length of key to use.
}

/**
 * Protection Information.
 *
 * Information specific to a type of protection.
 */
union nzttProtInfo {
	nzttPKCS7ProtInfo pkcs7_nzttProtInfo;		///
}

/**
 * A description of a persona so that the toolkit can create one.  A
 * persona can be symmetric or asymmetric and both contain an
 * identity.  The identity for an asymmetric persona will be the
 * certificate and the identity for the symmetric persona will be
 * descriptive information about the persona.  In either case, an
 * identity will have been created before the persona is created.
 *
 * A persona can be stored separately from the wallet that references
 * it.  By default, a persona is stored with the wallet (it inherits
 * with WRL used to open the wallet).  If a WRL is specified, then it
 * is used to store the actuall persona and the wallet will have a
 * reference to it.
 */
struct nzttPersonaDesc {
	ub4 privlen_nzttPersonaDesc;			/// Length of private info (key).
	ub1* priv_nzttPersonaDesc;			/// Private information.
	ub4 prllen_nzttPersonaDesc;			/// Length of PRL.
	text* prl_nzttPersonaDesc;			/// PRL for storage.
	ub4 aliaslen_nzttPersonaDesc;			/// Length of alias.
	text* alias_nzttPersonaDesc;			/// Alias.
	ub4 longlen_nzttPersonaDesc;			/// Length of longer description.
	text* long_nzttPersonaDesc;			/// Longer persona description.
}

/**
 * A description of an identity so that the toolkit can create one.
 * Since an identity can be symmetric or asymmetric, the asymmetric
 * identity information will not be used when a symmetric identity is
 * created.  This means the publen_nzttIdentityDesc and
 * pub_nzttIdentityDesc members will not be used when creating a
 * symmetric identity.
 */
struct nzttIdentityDesc {
	ub4 publen_nzttIdentityDesc;			/// Length of identity.
	ub1* pub_nzttIdentityDesc;			/// Type specific identity.
	ub4 dnlen_nzttIdentityDesc;			/// Length of alias.
	text* dn_nzttIdentityDesc;			/// Alias.
	ub4 longlen_nzttIdentityDesc;			/// Length of longer description.
	text* long_nzttIdentityDesc;			/// Longer description.
	ub4 quallen_nzttIdentityDesc;			/// Length of trust qualifier.
	text* trustqual_nzttIdentityDesc;		/// Trust qualifier.
}

/**
 * Open a wallet based on a wallet Resource Locator (WRL).
 *
 * The syntax for a WRL is <Wallet Type>:<Wallet Type Parameters>.
 *
 * Wallet Type	Wallet Type Parameters.
 * -----------	----------------------
 * File		Pathname (e.g. "file:/home/asriniva")
 * Oracle	Connect string (e.g. "oracle:scott/tiger@oss")
 *
 * There are also defaults.  If the WRL is NZT_DEFAULT_WRL, then
 * the platform specific WRL default is used.  If only the wallet
 * type is specified, then the WRL type specific default is used
 * (e.g. "oracle:")
 *
 * There is an implication with Oracle that should be stated: An
 * Oracle based wallet can be implemented in a user's private space
 * or in world readable space.
 *
 * When the wallet is opened, the password is verified by hashing
 * it and comparing against the password hash stored with the
 * wallet.  The list of personas (and their associated identities)
 * is built and stored into the wallet structure.
 *
 * Params:
 *	osscntxt = OSS context.
 *	wrllen = Length of WRL.
 *	wrl = WRL.
 *	pwdlen = Length of password.
 *	pwd = Password.
 *	wallet = Initialized wallet structure.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_RIO_OPEN	RIO could not open wallet (see network trace file).
 *	NZERROR_TK_PASSWORD	Password verification failed.
 *	NZERROR_TK_WRLTYPE	WRL type is not known.
 *	NZERROR_TK_WRLPARM	WRL parm does not match type.
 */
extern (C) nzerror nztwOpenWallet (nzctx* osscntxt, ub4 wrllen, text* wrl, ub4 pwdlen, text* pwd, nzttWallet* wallet);

/**
 * Close a wallet.
 *
 * Closing a wallet also closes all personas associated with that
 * wallet.  It does not cause a persona to automatically be saved
 * if it has changed.  The implication is that a persona can be
 * modified by an application but if it is not explicitly saved it
 * reverts back to what was in the wallet.
 *
 * Params:
 *	osscntxt = OSS context.
 *	wallet = Wallet.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_RIO_CLOSE	RIO could not close wallet (see network trace file).
 */
extern (C) nzerror nztwCloseWallet (nzctx* osscntxt, nzttWallet* wallet);

/**
 * This function shouldn't be called.  It's a temporary Oracle hack.
 */
deprecated extern(C) nzerror nztwGetCertInfo (nzctx* nz_context, nzosContext* nzosCtx, nzttWallet* walletRef, void* peerCert);

/+
/**
 *
 */
extern (C) nzerror nztwConstructWallet (nzctx* oss_context, nzttPolicy openPolicy, nzttPolicy securePolicy, ub1* ldapName, ub4 ldapNamelen, nzstrc* wrl, nzttPersona* personas, nzttWallet** wallet );
+/

/**
 * Retrieve a persona from wallet.
 *
 * Retrieves a persona from the wallet based on the index number passed
 * in.  This persona is a COPY of the one stored in the wallet, therefore
 * it is perfectly fine for the wallet to be closed after this call is
 * made.
 *
 * The caller is responsible for disposing of the persona when completed.
 *
 * Params:
 *	osscntxt = OSS context.
 *	wallet = Wallet.
 *	index = Which wallet index to remove (first persona is zero).
 *	persona = Persona found.
 *
 * Returns:
 *	NZERROR_OK		Success.
 */
extern (C) nzerror nztwRetrievePersonaCopy (nzctx* osscntxt, nzttWallet* wallet, ub4 index, nzttPersona** persona);

/**
 * Retrieve a persona based on its name.
 *
 * Retrieves a persona from the wallet based on the name of the persona.
 * This persona is a COPY of the one stored in the wallet, therefore
 * it is perfectly fine for the wallet to be closed after this call is
 * made.
 *
 * The caller is responsible for disposing of the persona when completed.
 *
 * Params:
 *	osscntxt = OSS context.
 *	wallet = Wallet.
 *	name = Name of the persona
 *	persona = Persona found.
 *
 * Returns:
 *	NZERROR_OK		Success.
 */
extern (C) nzerror nztwRetrievePersonaCopyByName(nzctx* osscntxt, nzttWallet* wallet, char* name, nzttPersona** persona);

/**
 * Open a persona.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_PASSWORD	Password failed to decrypt persona.
 *	NZERROR_TK_BADPRL	Persona resource locator did not work.
 *	NZERROR_RIO_OPEN	Could not open persona (see network trace file).
 */
extern (C) nzerror nzteOpenPersona (nzctx* osscntxt, nzttPersona* persona);

/**
 * Close a persona.
 *
 * Closing a persona does not store the persona, it simply releases
 * the memory associated with the crypto engine.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *
 * Returns:
 *	NZERROR_OK		Success.
 */
extern (C) nzerror nzteClosePersona (nzctx* osscntxt, nzttPersona* persona);

/**
 * Destroy a persona.
 *
 * The persona is destroyed in the open state, but it will
 * not be associated with a wallet.
 *
 * The persona parameter is doubly indirect so that at the
 * conclusion of the function, the pointer can be set to null.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_TYPE		Unsupported itype/ctype combination.
 *	NZERROR_TK_PARMS	Error in persona description.
 */
extern (C) nzerror nzteDestroyPersona (nzctx* osscntxt, nzttPersona** persona);

/**
 * Retrieve a trusted identity from a persona.
 *
 * Retrieves a trusted identity from the persona based on the index
 * number passed in.  This identity is a copy of the one stored in
 * the persona, therefore it is perfectly fine to close the persona
 * after this call is made.
 *
 * The caller is responsible for freeing the memory of this object
 * by calling nztiAbortIdentity it is no longer needed.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	index = Which wallet index to remove (first element is zero).
 *	identity = Trusted Identity from this persona.
 *
 * Returns:
 *	NZERROR_OK		Success.
 */
extern (C) nzerror nzteRetrieveTrustedIdentCopy (nzctx* osscntxt, nzttPersona* persona, ub4 index, nzttIdentity** identity);

/**
 * Get the decrypted Private Key for the Persona.
 *
 * This function will only work for X.509 based persona which contain
 * a private key.
 * A copy of the private key is returned to the caller so that they do not
 * have to worry about the key changing "underneath them."
 * Memory will be allocated for the vkey and therefore, the caller
 * will be responsible for freeing this memory.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	vkey = Private Key [B_KEY_OBJ].
 *	vkey_len = Private Key Length.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_NO_MEMORY	ossctx is null.
 *	NZERROR_TK_BADPRL	Persona resource locator did not work.
 */
extern (C) nzerror nztePriKey (nzctx* osscntxt, nzttPersona* persona, ub1** vkey, ub4* vkey_len);

/**
 * Get the X.509 Certificate for a persona.
 *
 * This funiction will only work for X.509 based persona which contain
 * a certificate for the self identity.
 * A copy of the certificate is returned to the caller so that they do not
 * have to worry about the certificate changing "underneath them."
 * Memory will be allocated for the cert and therefore, the caller
 * will be responsible for freeing this memory.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	cert = X.509 Certificate [BER encoded].
 *	cert_len = Certificate length.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_NO_MEMORY	ossctx is null.
 */
extern (C) nzerror nzteMyCert (nzctx* osscntxt, nzttPersona* persona, ub1** cert, ub4* cert_len);

/**
 * Create a persona gives a BER X.509 cert.
 *
 * Memory will be allocated for the persona and therefore, the caller
 * will be responsible for freeing this memory.
 *
 * Params:
 *	osscntxt = OSS context.
 *	cert = X.509 Certificate [BER encoded].
 *	cert_len = Certificate length.
 *	persona = Persona.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_NO_MEMORY	ossctx is null.
 */
extern (C) nzerror nzteX509CreatePersona (nzctx* osscntxt, ub1* cert, ub4 cert_len, nzttPersona** persona);

/**
 * Create an identity.
 *
 * Memory is only allocated for the identity structure.  The elements in
 * the description struct are not copied.  Rather their pointers are copied
 * into the identity structure.  Therefore, the caller should not free
 * the elements referenced by the description.  These elements will be freed
 * when nztiDestroyIdentity is called.
 *
 * Params:
 *	osscntxt = OSS context.
 *	itype = Identity type.
 *	desc = Description of identity.
 *	identity = Identity.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_PARMS		Error in description.
 */
extern (C) nzerror nztiCreateIdentity (nzctx* osscntxt, nzttVersion itype, nzttIdentityDesc* desc, nzttIdentity** identity);

version (NZ_OLD_TOOLS) {

/**
 * Duplicate an identity.
 *
 * Memory for the identity is allocated inside the function, and all
 * internal identity elements as well.
 *
 * Params:
 *	osscntxt = OSS context.
 *	identity = Target Identity.
 *	new_identity = New Identity.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_NOTFOUND	Identity not found.
 *	NZERROR_PARMS		Error in description.
 */
extern (C) nzerror nztiDuplicateIdentity (nzctx* osscntxt, nzttIdentity* identity, nzttIdentity** new_identity);

}

/**
 * Abort an unassociated identity.
 *
 * It is an error to try to abort an identity that can be
 * referenced through a persona.
 *
 * The identity pointer is set to null at the conclusion.
 *
 * Params:
 *	osscntxt = OSS context.
 *	identity = Identity.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_CANTABORT	Identity is associated with persona.
 */
extern (C) nzerror nztiAbortIdentity (nzctx* osscntxt, nzttIdentity** identity);

version (NZ_OLD_TOOLS) {

/**
 * Get an Identity Description from an identity.
 *
 * Memory is allocated for the Identity Description. It
 * is the caller's responsibility to free this memory by calling
 * nztiFreeIdentityDesc.
 *
 * Params:
 *	osscntxt = OSS context.
 *	identity = Identity.
 *	description = Identity Description.
 *
 * Returns:
 *	NZERROR_OK		Success.
 */
extern (C) nzerror nztidGetIdentityDesc (nzctx* osscntxt, nzttIdentity* identity, nzttIdentityDesc** description);

/**
 * Free memory from an Identity Description object.
 *
 * Memory is freed for all Identity Description elements.  The pointer is then set to null.
 *
 * PARAMETERS
 *    osscntxt = OSS context.
 *    description = Identity Description.
 *
 * Returns:
 *	NZERROR_OK		Success.
 */
extern (C) nzerror nztidFreeIdentityDesc (nzctx* osscntxt, nzttIdentityDesc** description);

}

/**
 * Free the contents of an identity.
 *
 * Params:
 *	osscntxt = OSS context.
 *	identity = Identity to free.
 *
 * Returns:
 *	NZERROR_OK		Success.
 */
extern (C) nzerror nztific_FreeIdentityContent (nzctx* ossctx, nzttIdentity* identity);

/**
 * Create an attached signature.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Open persona acting as signer.
 *	state = State of signature.
 *	inlen = Length of this input part.
 *	input = This input part.
 *	tdubuf = TDU buffer.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_CANTGROW	Needed to grow output buffer but could not.
 *	NZERROR_TK_NOTOPEN	Persona is not open.
 *	NZERROR_TK_NOTSUPP	Function not supported with persona.
 */
extern (C) nzerror nztSign (nzctx* osscntxt, nzttPersona* persona, nzttces state, ub4 inlen, ub1* input, nzttBufferBlock* tdubuf);

/*
 * Verify an attached signature.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	state = State of verification.
 *	intdulen = TDU length.
 *	intdu = TDU.
 *	output = Extracted message.
 *	verified = TRUE if signature verified.
 *	validated = TRUE if signing identity validated.
 *	identity = Identity of signing party.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_CANTGROW	Needed to grow outptu buffer but could not.
 *	NZERROR_TK_NOTOPEN	Persona is not open.
 *	NZERROR_TK_NOTSUPP	Function not supported with persona.
 */
extern (C) nzerror nztVerify (nzctx* osscntxt, nzttPersona* persona, nzttces state, ub4 intdulen, ub1* intdu, nzttBufferBlock* output, boolean* verified, boolean* validated, nzttIdentity** identity);

/**
 * Validate an identity.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	identity = Identity.
 *	validated = TRUE if identity was validated.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_NOTOPEN	Persona is not open.
 *	NZERROR_TK_NOTSUPP	Function not supported with persona.
 */
extern (C) nzerror nztValidate (nzctx* osscntxt, nzttPersona* persona, nzttIdentity* identity, boolean* validated);

/**
 * Generate a detached signature.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	state = State of signature.
 *	inlen = Length of this input part.
 *	input = The input.
 *	tdubuf = TDU buffer.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_CANTGROW	Needed to grow output buffer but could not.
 *	NZERROR_TK_NOTOPEN	Persona is not open.
 *	NZERROR_TK_NOTSUPP	Function not supported with persona.
 */
extern (C) nzerror nztsd_SignDetached (nzctx* osscntxt, nzttPersona* persona, nzttces state, ub4 inlen, ub1* input, nzttBufferBlock* tdubuf);

/**
 * Verify a detached signature.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	state = State of verification.
 *	inlen = Length of data.
 *	input = Data.
 *	intdulen = Input TDU length.
 *	tdu = Input TDU.
 *	verified = TRUE if signature verified.
 *	validated = TRUE if signing identity validated.
 *	identity = Identity of signing party.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_NOTOPEN	Persona is not open.
 *	NZERROR_TK_NOTSUPP	Function not supported with persona.
 */
extern (C) nzerror nztved_VerifyDetached (nzctx* osscntxt, nzttPersona* persona, nzttces state, ub4 inlen, ub1* input, ub4 intdulen, ub1* tdu, boolean* verified, boolean* validated, nzttIdentity** identity);

/**
 * Encrypt data symmetrically, encrypt key asymmetrically
 *
 * There is a limitation of 1 recipient (nrecipients = 1) at this time.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	nrecipients = Number of recipients for this encryption.
 *	recipients = List of recipients.
 *	state = State of encryption.
 *	inlen = Length of this input part.
 *	input = The input.
 *	tdubuf = TDU buffer.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_CANTGROW	Needed to grow output buffer but could not.
 *	NZERROR_TK_NOTOPEN	Persona is not open.
 *	NZERROR_TK_NOTSUPP	Function not supported with persona.
 */
extern (C) nzerror nztkec_PKEncrypt (nzctx* osscntxt, nzttPersona* persona, ub4 nrecipients, nzttIdentity* recipients, nzttces state, ub4 inlen, ub1* input, nzttBufferBlock* tdubuf);

/**
 * Determine the buffer size needed for PKEncrypt.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	nrecipients = Number of recipients.
 *	inlen = Length of input.
 *	tdulen = Length of buffer need.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_NOTOPEN	Persona is not open.
 *	NZERROR_TK_NOTSUPP	Function not supported with persona.
 */
extern (C) nzerror nztxkec_PKEncryptExpansion (nzctx* osscntxt, nzttPersona* persona, ub4 nrecipients, ub4 inlen, ub4* tdulen);

/**
 * Decrypt a PKEncrypted message.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	state = State of encryption.
 *	inlen = Length of this input part.
 *	input = The input.
 *	tdubuf = TDU buffer.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_CANTGROW	Needed to grow output buffer but couldn't.
 *	NZERROR_TK_NOTOPEN	Persona is not open.
 *	NZERROR_TK_NOTSUPP	Function not supported with persona.
 */
extern (C) nzerror nztkdc_PKDecrypt (nzctx* osscntxt, nzttPersona* persona, nzttces state, ub4 inlen, ub1* input, nzttBufferBlock* tdubuf);

/**
 * Generate a hash.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	state = State of hash.
 *	inlen = Length of this input.
 *	input = The input.
 *	tdu = TDU buffer.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_CANTGROW	Needed to grow TDU buffer but could not.
 *	NZERROR_TK_NOTOPEN	Persona is not open.
 *	NZERROR_TK_NOTSUPP	Function not supported with persona.
 */
extern (C) nzerror nztHash (nzctx* osscntxt, nzttPersona* persona, nzttces state, ub4 inlen, ub1* input, nzttBufferBlock* tdu);

/**
 * Seed the random function.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	seedlen = Length of seed.
 *	seed = Seed.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_NOTOPEN	Persona is not open.
 *	NZERROR_TK_NOTSUPP	Function not supported with persona.
 */
extern (C) nzerror nztSeedRandom (nzctx* osscntxt, nzttPersona* persona, ub4 seedlen, ub1* seed);

/**
 * Generate a buffer of random bytes.
 *
 * Params:
 *    osscntxt = OSS context.
 *    persona = Persona.
 *    nbytes = Number of bytes desired.
 *    output = Buffer block for bytes.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_CANTGROW	Needed to grow TDU buffer but could not.
 *	NZERROR_TK_NOTOPEN	Persona is not open.
 *	NZERROR_TK_NOTSUPP	Function not supported with persona.
 */
extern (C) nzerror nztrb_RandomBytes (nzctx* osscntxt, nzttPersona* persona, ub4 nbytes, nzttBufferBlock* output);

/**
 * Generate a random number.
 *
 * Params:
 *    osscntxt = OSS context.
 *    persona = Persona.
 *    num = Number.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_NOTOPEN	Persona is not open.
 *	NZERROR_TK_NOTSUPP	Function not supported with persona.
 */
extern (C) nzerror nztrn_RandomNumber (nzctx* osscntxt, nzttPersona* persona, uword* num);

/**
 * Initialize a buffer block.
 *
 * The buffer block is initialized to be empty (all members are set
 * to 0/null).  Such a block will be allocated memory as needed.
 *
 * Params:
 *	osscntxt = OSS context.
 *	block = Buffer block.
 *
 * Returns:
 *	NZERROR_OK		Success.
 */
extern (C) nzerror nztbbInitBlock (nzctx* osscntxt, nzttBufferBlock* block);

/**
 * Reuse an already initialized and possibly used block.
 *
 * This function simply sets the used length member of the buffer
 * block to 0.  If the block already has memory allocated to it,
 * this will cause it to be reused.
 *
 * Params:
 *	osscntxt = OSS context.
 *	block = Buffer block.
 *
 * Returns:
 *	NZERROR_OK		Success.
 */
extern (C) nzerror nztbbReuseBlock (nzctx* osscntxt, nzttBufferBlock* block);

/**
 * Resize an initialized block to a particular size.
 *
 * Params:
 *	osscntxt = OSS context.
 *	len = Minimum number of unused bytes desired.
 *	block = Buffer block.
 *
 * Returns:
 *	NZERROR_OK		Success.
 */
extern (C) nzerror nztbbSizeBlock (nzctx* osscntxt, ub4 len, nzttBufferBlock* block);

/**
 * Increase the size of a buffer block.
 *
 * Params:
 *	osscntxt = OSS context.
 *	inc = Number of bytes to increase.
 *	block = Buffer block.
 *
 * Returns:
 *	NZERROR_OK		Success.
 */
extern (C) nzerror nztbbGrowBlock (nzctx* osscntxt, ub4 inc, nzttBufferBlock* block);

/**
 * Purge a buffer block of its memory.
 *
 * The memory used by the buffer block as the buffer is released.
 * The buffer block itself is not affected.
 *
 * Params:
 *	osscntxt = OSS context.
 *	block = Buffer block.
 *
 * Returns:
 *	NZERROR_OK		Success.
 */
extern (C) nzerror nztbbPurgeBlock (nzctx* osscntxt, nzttBufferBlock* block);

/**
 * Set a buffer block to a known state.
 *
 * If buflen > 0, objlen == 0, and obj == null, then buflen bytes
 * of memory is allocated and a pointer is stored in the buffer
 * block.
 *
 * The buffer parameter remains unchanged.
 *
 * Params:
 *	osscntxt = OSS context.
 *	flags = Flags to set.
 *	buflen = Length of buffer.
 *	usedlen = Used length.
 *	buffer = Buffer.
 *	block = Buffer block.
 *
 * Returns:
 *	NZERROR_OK		Success.
 */
extern (C) nzerror nztbbSetBlock (nzctx* osscntxt, uword flags, ub4 buflen, ub4 usedlen, ub1* buffer, nzttBufferBlock* block);

/**
 * Get some security information for SSL.
 *
 * This function allocate memories for issuername, certhash, and dname.
 * To deallocate memory for those params, you should call nztdbuf_DestroyBuf.
 *
 * Bugs:
 *	An unknown parameter is missing from the documentation.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	dname = Distinguished name of the certificate.
 *	dnamelen = Length of the distinguished name.
 *	issuername = Issuer name of the certificate.
 *	certhash = SHA1 hash of the certificate.
 *	certhashlen = Length of the hash.
 *
 * Returns:
 *
 */
extern (C) nzerror nztiGetSecInfo (nzctx* osscntxt, nzttPersona* persona, text** dname, ub4* dnamelen, text** issuername, ub4*, ub1**, ub4*);

/**
 * Get the distinguished name for the given identity.
 *
 * Params:
 *	osscntxt = OSS context.
 *	identity = Identity to get dname from.
 *	dn = Distinguished name.
 *	dnlen = Length of the dname.
 *
 * Returns:
 *
 */
extern (C) nzerror nztiGetDName (nzctx* osscntxt, nzttIdentity* identity, text** dn, ub4* dnlen);

/**
 * Get the IssuerName of an identity.
 *
 * Params:
 *	osscntxt = OSS context.
 *	identity = Identity need to get issuername from
 *	issuername = Issuer's name
 *	issuernamelen = Length of the issuer's name
 *
 * Returns:
 *
 */
extern (C) nzerror nztiGetIssuerName (nzctx* osscntxt, nzttIdentity* identity, text** issuername, ub4* issuernamelen);

/**
 * Get the SHA1 hash for the certificate of an identity.
 *
 * Need to call nztdbuf_DestroyBuf to deallocate memory for certHash.
 *
 * Params:
 *	osscntxt = OSS context.
 *	identity = Identity need to get issuername from.
 *	certHash = SHA1 hash buffer.
 *	hashLen = Length of the certHash.
 *
 * Returns:
 *
 */
extern (C) nzerror nztgch_GetCertHash (nzctx* osscntxt, nzttIdentity* identity, ub1** certHash, ub4* hashLen);

/**
 * Deallocate a ub1 or text buffer.
 *
 * Params:
 *	osscntxt = OSS context.
 *	buf = Allocated buffer to be destroyed.
 *
 * Returns:
 *
 */
extern (C) nzerror nztdbuf_DestroyBuf (nzctx* osscntxt, dvoid** buf);

/**
 *
 *
 * Bugs:
 *	An unknown parameter is missing from the documentation.
 *
 * Params:
 *	osscntxt = OSS context.
 *
 * Returns:
 *
 */
extern (C) nzerror nztGetCertChain (nzctx* osscntxt, nzttWallet* );

/**
 *
 *
 * Bugs:
 *	An unknown parameter is missing from the documentation.
 *
 * Params:
 *	osscntxt = OSS context.
 *	dn1 = Distinguished name 1.
 *	dn2 = Distinguished name 2.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	others			Failure.
 */
extern (C) nzerror nztCompareDN (nzctx* osscntxt, ub1*, ub4,  ub1 *, ub4, boolean*);

version (NZ_OLD_TOOLS) {

/**
 * Allocate memory for nzttIdentity context.
 *
 * Params:
 *	osscntxt = OSS context.
 *	identity = nzttIdentity context
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	others			Failure.
 */
extern (C) nzerror nztIdentityAlloc (nzctx* osscntxt, nzttIdentity** identity);

/**
 * Allocate memory for nzttIdentityPrivate.
 *
 * Params:
 *	osscntxt = OSS context.
 *	ipriv = identityPrivate structure.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	others			Failure.
 */
extern (C) nzerror nztIPrivateAlloc (nzctx* osscntxt, nzttIdentityPrivate** ipriv);

/**
 *
 *
 * Params:
 *	osscntxt = OSS context.
 *	targetIdentity = Target identity.
 *	sourceIdentity = Source identity.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	others			Failure.
 */
extern (C) nzerror nztIDupContent (nzctx* osscntxt, nzttIdentity* targetIdentity, nzttIdentity* sourceIdentity);

/**
 *
 *
 * Params:
 *	osscntxt = OSS context.
 *	target_ipriv = Target identityPrivate.
 *	source_ipriv = Source identityPrivate.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	others			Failure.
 */
extern (C) nzerror nztIPDuplicate (nzctx* osscntxt, nzttIdentityPrivate** target_ipriv, nzttIdentityPrivate* source_ipriv);

/**
 *
 *
 * Params:
 *	osscntxt = OSS context.
 *	source_identities = Source identity list.
 *	numIdent = Number of identity in the list.
 *	ppidentity = Target of identity.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	others			Failure.
 */
extern (C) nzerror nztiDupIdentList (nzctx* osscntxt, nzttIdentity* source_identities, ub4* numIdent, nzttIdentity** ppidentity);

/**
 * Free memory for a list of Identities.
 *
 * Params:
 *	osscntxt = OSS context.
 *	identity = identity context
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	others			Failure.
 */
extern (C) nzerror nztFreeIdentList (nzctx* osscntxt, nzttIdentity** identity);

}

/**
 * Check the validity of a certificate.
 *
 * Params:
 *	osscntxt = OSS context.
 *	start_time = Start time of the certificate.
 *	end_time = End time of the certificate.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	others			Failure.
 */
extern (C) nzerror nztCheckValidity (nzctx* osscntxt, ub4 start_time, ub4 end_time);

/**
 * Create a new wallet.
 *
 * It is an error to try to create a wallet that already exists.  The
 * existing wallet must be destroyed first.
 *
 * The wallet itself is not encrypted.  Rather, all the personas in the
 * wallet are encrypted under the same password.  A hash of the password
 * is stored in the wallet.
 *
 * Upon success, an empty open wallet is stored in the wallet parameter.
 *
 * Bugs:
 *	This function is unsupported at this time.
 *
 * Params:
 *	osscntxt = OSS context.
 *	wrllen = Length of wallet resource locator.
 *	wrl = WRL.
 *	pwdlen = Length of password (see notes below).
 *	pwd = Password.
 *	wallet = Wallet.
 *
 * Returns:
 *	NZERROR_OK			Success.
 *	NZERROR_TK_WALLET_EXISTS	Wallet already exists.
 *	NZERROR_RIO_OPEN		RIO could not create wallet (see trace file).
 */
extern (C) nzerror nztwCreateWallet (nzctx* osscntxt, ub4 wrllen, text* wrl, ub4 pwdlen, text* pwd, nzttWallet* wallet);

/**
 * Destroy an existing wallet.
 *
 * Bugs:
 *	This function is unsupported at this time.
 *
 * Params:
 *	osscntxt = OSS context.
 *	wrllen = Length of wallet resource locator.
 *	wrl = WRL.
 *	pwdlen = Length of password.
 *	pwd = Password.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_PASSWORD	Password verification failed.
 *	NZERROR_RIO_OPEN	RIO could not open wallet (see trace file).
 *	NZERROR_RIO_DELETE	Delete failed (see trace file).
 */
extern (C) nzerror nztwDestroyWallet (nzctx* osscntxt, ub4 wrllen, text* wrl, ub4 pwdlen, text* pwd);

/**
 * Store an open persona in a wallet.
 *
 * If the open persona is not associated with any wallet (it was
 * created via the nzteClosePersona function), then storing the
 * persona creates that association.  The wallet will also have an
 * updated persona list that reflects this association.
 *
 * If the open persona was associated with wallet 'A' (it was
 * opened via the nztwOpenWallet function), and is stored back into
 * wallet 'A', then then the old persona is overwritten by the new
 * persona if the password can be verified.  Recall that all
 * personas have a unique identity id.  If that id changes then
 * storing the persona will put a new persona in the wallet.
 *
 * If the open persona was associated with wallet 'A' and is stored
 * into wallet 'B', and if wallet 'B' does not contain a persona
 * with that unique identity id, then the persona will be copied
 * into wallet 'B', wallet 'B''s persona list will be updated, and
 * the persona structure will be updated to be associated with
 * wallet 'B'.  If wallet 'B' already contained the persona, it
 * would be overwritten by the new persona.
 *
 * The persona parameter is doubly indirect so that at the
 * conclusion of the function call, the pointer can be directed to
 * the persona in the wallet.
 *
 * Bugs:
 *	This function is unsupported at this time.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	wallet = Wallet.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_PASSWORD	Password verification failed.
 *	NZERROR_RIO_STORE	Store failed (see network trace file).
 */
extern (C) nzerror nzteStorePersona (nzctx* osscntxt, nzttPersona** persona, nzttWallet* wallet);

/**
 * Remove a persona from the wallet.
 *
 * The password is verified before trying to remove the persona.
 *
 * If the persona is open, it is closed.  The persona is removed
 * from the wallet list and the persona pointer is set to null.
 *
 * A double indirect pointer to the persona is required so that the
 * persona pointer can be set to null upon completion.
 *
 * Bugs:
 *	This function is unsupported at this time.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_PASSWORD	Password verification failed.
 *	NZERROR_RIO_DELETE	Delete failed.
 */
extern (C) nzerror nzteRemovePersona (nzctx* osscntxt, nzttPersona** persona);

/**
 * Create a persona.
 *
 * The resulting persona is created in the open state, but it will
 * not be associated with a wallet.
 *
 * The memory for the persona is allocated by the function.
 *
 * Bugs:
 *	This function is unsupported at this time.
 *
 * Params:
 *	osscntxt = OSS context.
 *	itype = Identity type.
 *	ctype = Cipher type.
 *	desc = Persona description.
 *	persona = Persona.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_TYPE		Unsupported itype/ctype combination.
 *	NZERROR_TK_PARMS	Error in persona description.
 */
extern (C) nzerror nzteCreatePersona (nzctx* osscntxt, nzttVersion itype, nzttCipherType ctype, nzttPersonaDesc* desc, nzttPersona** persona);

/**
 * Store an identity into a persona.
 *
 * The identity is not saved with the persona in the wallet until
 * the persona is stored.
 *
 * The identity parameter is double indirect so that it can point
 * into the persona at the conclusion of the call.
 *
 * Params:
 *	osscntxt = Success.
 *	identity = Trusted Identity.
 *	persona = Persona.
 *
 * Returns:
 *	NZERROR_OK		Success.
 */
extern (C) nzerror nztiStoreTrustedIdentity (nzctx* osscntxt, nzttIdentity** identity, nzttPersona* persona);

/**
 * Set the protection type for a CE function.
 *
 * Bugs:
 *	This function is unsupported at this time.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona  = Persona.
 *	func = CE function.
 *	tdufmt = TDU Format.
 *	protinfo = Protection information specific to this format.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_PROTECTION	Unsupported protection.
 *	NZERROR_TK_PARMS	Error in protection info.
 */
extern (C) nzerror nzteSetProtection (nzctx* osscntxt, nzttPersona* persona, nzttcef func, nztttdufmt tdufmt, nzttProtInfo* protinfo);

/**
 * Get the protection type for a CE function.
 *
 * Bugs:
 *	This function is unsupported at this time.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	func = CE function.
 *	tdufmt = TDU format.
 *	protinfo = Protection information.
 *
 * Returns:
 *	NZERROR_OK		Success.
 */
extern (C) nzerror nzteGetProtection (nzctx* osscntxt, nzttPersona* persona, nzttcef func, nztttdufmt* tdufmt, nzttProtInfo* protinfo);

/**
 * Remove an identity from an open persona.
 *
 * If the persona is not stored, this identity will still be in the
 * persona stored in the wallet.
 *
 * The identity parameter is doubly indirect so that at the
 * conclusion of the function, the pointer can be set to null.
 *
 * Bugs:
 *	This function is unsupported at this time.
 *
 * Params:
 *	osscntxt = OSS context.
 *	identity = Identity.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_NOTFOUND	Identity not found.
 *	NZERROR_TK_NOTOPEN	Persona is not open.
 */
extern (C) nzerror nztiRemoveIdentity (nzctx* osscntxt, nzttIdentity** identity);

/**
 * Create an Identity From a Distinguished Name.
 *
 * PARAMETERS
 *    osscntxt = OSS context.
 *    length = Length of distinguished_name.
 *    distinguished_name = Distinguished Name string.
 *    ppidentity = Created identity.
 *
 * Returns:
 *	NZERROR_OK		Success.
 */
extern (C) nzerror nztifdn (nzctx* ossctx, ub4 length, text* distinguished_name, nzttIdentity** ppidentity);

/**
 * Determine the size of the attached signature buffer.
 *
 * Bugs:
 *	This function is unsupported at this time.
 *
 * Parameters:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	inlen = Length of input.
 *	tdulen = Buffer needed for signature.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_NOTOPEN	Persona is not open.
 *	NZERROR_TK_NOTSUPP	Function not supported with persona.
 */
extern (C) nzerror nztxSignExpansion (nzctx* osscntxt, nzttPersona* persona, ub4 inlen, ub4* tdulen);

/**
 * Determine the size of buffer needed.
 *
 * Bugs:
 *	This function is unsupported at this time.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	inlen = Length of input.
 *	tdulen = Buffer needed for signature.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_NOTOPEN	Persona is not open.
 *	NZERROR_TK_NOTSUPP	Function not supported with persona.
 */
extern (C) nzerror nztxsd_SignDetachedExpansion (nzctx* osscntxt, nzttPersona* persona, ub4 inlen, ub4* tdulen);

/**
 * Symmetrically encrypt.
 *
 * Bugs:
 *	An unknown parameter is missing from the documentation.
 *	This function is unsupported at this time.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	state = ?  Is this even state  ?
 *	inlen = Length of this input part.
 *	input = This input part.
 *	tdubuf = TDU buffer.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_CANTGROW	Needed to grow TDU buffer but could not.
 *	NZERROR_TK_NOTOPEN	Persona is not open.
 *	NZERROR_TK_NOTSUPP	Function not supported with persona.
 */
extern (C) nzerror nztEncrypt (nzctx* osscntxt, nzttPersona* persona, nzttces state, ub4 inlen, ub1* input, nzttBufferBlock* tdubuf);

/**
 * Determine the size of the TDU to encrypt.
 *
 * Bugs:
 *	This function is unsupported at this time.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	inlen = Length of this input part.
 *	tdulen = Length of TDU.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_NOTOPEN	Persona is not open.
 *	NZERROR_TK_NOTSUPP	Function not supported with persona.
 */
extern (C) nzerror nztxEncryptExpansion (nzctx* osscntxt, nzttPersona* persona, ub4 inlen, ub4* tdulen);

/**
 * Decrypt an encrypted message.
 *
 * Bugs:
 *	This function is unsupported at this time.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	state = State of decryption.
 *	inlen = Length of this input part.
 *	input = This input part.
 *	output = Decrypted message.
 *
 * Returns:
 *	NZERROR_OK           Success.
 *	NZERROR_TK_CANTGROW  Needed to grow TDU buffer but could not.
 *	NZERROR_TK_NOTOPEN   Persona is not open.
 *	NZERROR_TK_NOTSUPP   Function not supported with persona.
 */
extern (C) nzerror nztDecrypt (nzctx* osscntxt, nzttPersona* persona, nzttces state, ub4 inlen, ub1* input, nzttBufferBlock* output);

/**
 * Sign and PKEncrypt a message.
 *
 * Bugs:
 *	This function is unsupported at this time.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	nrecipients = Number of recipients for this encryption.
 *	recipients = List of recipients.
 *	state = State of encryption.
 *	inlen = Length of this input part.
 *	input = This input part.
 *	tdubuf = TDU buffer.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_CANTGROW	Needed to grow output buffer but could not.
 *	NZERROR_TK_NOTOPEN	Persona is not open.
 *	NZERROR_TK_NOTSUPP	Function not supported with persona.
 */
extern (C) nzerror nztEnvelope (nzctx* osscntxt, nzttPersona* persona, ub4 nrecipients, nzttIdentity* recipients, nzttces state, ub4 inlen, ub1* input, nzttBufferBlock* tdubuf);

/**
 * PKDecrypt and verify a message.
 *
 * Bugs:
 *	This function is unsupported at this time.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	state = State of encryption.
 *	inlen = Length of this input part.
 *	input = This input part.
 *	output = Message from TDU.
 *	verified = TRUE if verified.
 *	validated = TRUE if validated.
 *	sender = Identity of sender.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_CANTGROW	Needed to grow TDU buffer but could not.
 *	NZERROR_TK_NOTOPEN	Persona is not open.
 *	NZERROR_TK_NOTSUPP	Function not supported with persona.
 */
extern (C) nzerror nztDeEnvelope (nzctx* osscntxt, nzttPersona* persona, nzttces state, ub4 inlen, ub1* input, nzttBufferBlock* output, boolean* verified, boolean* validated, nzttIdentity** sender);

/**
 * Generate a keyed hash.
 *
 * Bugs:
 *	This function is unsupported at this time.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	state = State of hash.
 *	inlen = Length of this input.
 *	input = This input.
 *	tdu = Output tdu.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_CANTGROW	Needed to grow TDU buffer but could not.
 *	NZERROR_TK_NOTOPEN	Persona is not open.
 *	NZERROR_TK_NOTSUPP	Function not supported with persona.
 */
extern (C) nzerror nztKeyedHash (nzctx* osscntxt, nzttPersona* persona, nzttces state, ub4 inlen, ub1* input, nzttBufferBlock* tdu);

/**
 * Determine the space needed for a keyed hash.
 *
 * Bugs:
 *	This function is unsupported at this time.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	inlen = Length of this input.
 *	tdulen = TDU length.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_NOTOPEN	Persona is not open.
 *	NZERROR_TK_NOTSUPP	Function not supported with persona.
 */
extern (C) nzerror nztxKeyedHashExpansion (nzctx* osscntxt, nzttPersona* persona, ub4 inlen, ub4* tdulen);

/**
 * Determine the size of the TDU for a hash.
 *
 * Bugs:
 *	This function is unsupported at this time.
 *
 * Params:
 *	osscntxt = OSS context.
 *	persona = Persona.
 *	inlen = Length of this input.
 *	tdulen = TDU length.
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_NOTOPEN	Persona is not open.
 *	NZERROR_TK_NOTSUPP	Function not supported with persona.
 */
extern (C) nzerror nztxHashExpansion (nzctx* osscntxt, nzttPersona* persona, ub4 inlen, ub4* tdulen);

/**
 * Check to see if authentication is enabled in the current Cipher Spec.
 *
 * Params:
 *	ctx = Oracle SSL context.
 *	ncipher = CipherSuite.
 *	authEnabled = Boolean for is Auth Enabled?
 *
 * Returns:
 *      NZERROR_OK		Success.
 *      NZERROR_TK_INV_CIPHR_TYPE Cipher Spec is not recognized.
 */
extern (C) nzerror nztiae_IsAuthEnabled (nzctx* ctx, ub2 ncipher, boolean* authEnabled);

/**
 * Check to see if encryption is enabled in the current Cipher Spec.
 *
 * Params:
 *	ctx = Oracle SSL context.
 *	ncipher = CipherSuite.
 *	encrEnabled = Boolean for is Auth Enabled?
 *
 * Returns:
 *      NZERROR_OK		Success.
 *      NZERROR_TK_INV_CIPHR_TYPE Cipher Spec is not recognized.
 */
extern (C) nzerror nztiee_IsEncrEnabled (nzctx* ctx, ub2 ncipher, boolean* encrEnabled);

/**
 * Check to see if hashing is enabled in the current Cipher Spec.
 *
 * Params:
 *	ctx = Oracle SSL context.
 *	ncipher = CipherSuite.
 *	hashEnabled = Boolean for is Auth Enabled?
 *
 * Returns:
 *	NZERROR_OK		Success.
 *	NZERROR_TK_INV_CIPHR_TYPE Cipher Spec is not recognized.
 */
extern (C) nzerror nztihe_IsHashEnabled (nzctx* ctx, ub2 ncipher, boolean* hashEnabled);

/**
 * Bugs:
 *	An unknown parameter is missing from the documentation.
 */
extern (C) nzerror nztGetIssuerName (nzctx*, nzttIdentity*, ub1**, ub4*);

/**
 * Bugs:
 *	An unknown parameter is missing from the documentation.
 */
extern (C) nzerror nztGetSubjectName (nzctx*, nzttIdentity*, ub1**, ub4*);


/**
 * Bugs:
 *	An unknown parameter is missing from the documentation.
 */
extern (C) nzerror nztGetBase64Cert (nzctx*, nzttIdentity*, ub1**, ub4*);

/**
 * Bugs:
 *	An unknown parameter is missing from the documentation.
 */
extern (C) nzerror nztGetSerialNumber (nzctx*, nzttIdentity*, ub1**, ub4*);

/**
 * Bugs:
 *	An unknown parameter is missing from the documentation.
 */
extern (C) nzerror nztGetValidDate (nzctx*, nzttIdentity*, ub4*, ub4*);

/**
 * Bugs:
 *	An unknown parameter is missing from the documentation.
 */
extern (C) nzerror nztGetVersion (nzctx*, nzttIdentity*, nzstrc*);

/**
 * Bugs:
 *	An unknown parameter is missing from the documentation.
 */
extern (C) nzerror nztGetPublicKey (nzctx*, nzttIdentity*, ub1**, ub4*);

/**
 * Bugs:
 *	An unknown parameter is missing from the documentation.
 */
extern (C) nzerror nztGenericDestroy (nzctx*, ub1**);

/**
 * Bugs:
 *	An unknown parameter is missing from the documentation.
 */
extern (C) nzerror nztSetAppDefaultLocation (nzctx*, text*, size_t);

/**
 * Bugs:
 *	An unknown parameter is missing from the documentation.
 */
extern (C) nzerror nztSearchNZDefault (nzctx*, boolean*);