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
module dbi.oracle.imp.oro;

private import dbi.oracle.imp.ocidfn, dbi.oracle.imp.oratypes;

/**
 * OCI object reference.
 *
 * In the Oracle object runtime environment, an object is identified by an
 * object reference (ref) which contains the object identifier plus other
 * runtime information.  The contents of a ref is opaque to clients.  Use
 * OCIObjectNew() to construct a ref.
 */
struct OCIRef {
}

/**
 * A variable of this type contains (null) indicator information.
 */
alias sb2 OCIInd;

const OCIInd OCI_IND_NOTNULL		= 0;		/// Not null.
const OCIInd OCI_IND_NULL		= -1;		/// Is null.
const OCIInd OCI_IND_BADNULL		= -2;		/// Bad null.
const OCIInd OCI_IND_NOTNULLABLE	= -3;		/// Can't be null.

const uint OCI_ATTR_OBJECT_DETECTCHANGE	= 0x00000020;	/// To enable object change detection mode, set this to TRUE.

const uint OCI_ATTR_OBJECT_NEWNOTNULL	= 0x00000010;	/// To enable object creation with non-null attributes by default, set this to TRUE.  By default, an object is created with null attributes.

const uint OCI_ATTR_CACHE_ARRAYFLUSH	= 0x00000040;	/// To enable sorting of the objects that belong to the same table before being flushed through OCICacheFlush, set this to TRUE.  Please note that by enabling this object cache will not be flushing the objects in the same order they were dirtied.

/**
 * OCI object pin option.
 *
 * In the Oracle object runtime environment, the program has the option to
 * specify which copy of the object to pin.
 *
 * OCI_PINOPT_DEFAULT pins an object using the default pin option.  The default
 * pin option can be set as an attribute of the OCI environment handle
 * (OCI_ATTR_PINTOPTION).  The value of the default pin option can be
 * OCI_PINOPT_ANY, OCI_PINOPT_RECENT, or OCI_PIN_LATEST. The default option
 * is initialized to OCI_PINOPT_ANY.
 *
 * OCI_PIN_ANY pins any copy of the object.  The object is pinned
 * using the following criteria:
 *   If the object copy is not loaded, load it from the persistent store.
 *   Otherwise, the loaded object copy is returned to the program.
 *
 * OCI_PIN_RECENT pins the latest copy of an object.  The object is
 * pinned using the following criteria:
 *   If the object is not loaded, load the object from the persistent store
 *       from the latest version.
 *   If the object is not loaded in the current transaction and it is not
 *       dirtied, the object is refreshed from the latest version.
 *   Otherwise, the loaded object copy is returned to the program.
 *
 * OCI_PINOPT_LATEST pins the latest copy of an object.  The object copy is
 * pinned using the following criteria:
 *   If the object copy is not loaded, load it from the persistent store.
 *   If the object copy is loaded and dirtied, it is returned to the program.
 *   Otherwise, the loaded object copy is refreshed from the persistent store.
 */
enum OCIPinOpt {
	OCI_PIN_DEFAULT = 1,				/// Default pin option.
	OCI_PIN_ANY = 3,				/// Pin any copy of the object.
	OCI_PIN_RECENT = 4,				/// Pin recent copy of the object.
	OCI_PIN_LATEST = 5				/// Pin latest copy of the object.
}

/**
 * OCI object lock option.
 *
 * This option is used to specify the locking preferences when an object is
 * loaded from the server.
 */
enum OCILockOpt {
	OCI_LOCK_NONE = 1,				/// null (same as no lock).
	OCI_LOCK_X = 2,					/// Exclusive lock.
	OCI_LOCK_X_NOWAIT = 3				/// Exclusive lock, do not wait.
}

/**
 * OCI object mark option.
 *
 * When the object is marked updated, the client has to specify how the
 * object is intended to be changed.
 */
enum OCIMarkOpt {
	OCI_MARK_DEFAULT = 1,				/// Default (the same as OCI_MARK_NONE).
	OCI_MARK_NONE = OCI_MARK_DEFAULT,		/// Object has not been modified.
	OCI_MARK_UPDATE					/// Object is to be updated.
}

/**
 * OCI object duration.
 *
 * A client can specify the duration of which an object is pinned (pin
 * duration) and the duration of which the object is in memory (allocation
 * duration).  If the objects are still pinned at the end of the pin duration,
 * the object cache manager will automatically unpin the objects for the
 * client. If the objects still exist at the end of the allocation duration,
 * the object cache manager will automatically free the objects for the client.
 *
 * Objects that are pinned with the option OCI_DURATION_TRANS will get unpinned
 * automatically at the end of the current transaction.
 *
 * Objects that are pinned with the option OCI_DURATION_SESSION will get
 * unpinned automatically at the end of the current session (connection).
 *
 * The option OCI_DURATION_NULL is used when the client does not want to set
 * the pin duration.  If the object is already loaded into the cache, then the
 * pin duration will remain the same.  If the object is not yet loaded, the
 * pin duration of the object will be set to OCI_DURATION_DEFAULT.
 */
typedef ub2 OCIDuration;

const OCIDuration OCI_DURATION_INVALID	= 0xFFFF;	/// Invalid duration.
const OCIDuration OCI_DURATION_BEGIN	= 10;		/// Beginning sequence of duration.
const OCIDuration OCI_DURATION_NULL	= OCI_DURATION_BEGIN - 1; /// Null duration.
const OCIDuration OCI_DURATION_DEFAULT	= OCI_DURATION_BEGIN - 2; /// Default.
const OCIDuration OCI_DURATION_USER_CALLBACK = OCI_DURATION_BEGIN - 3; ///
const OCIDuration OCI_DURATION_NEXT	= OCI_DURATION_BEGIN - 4; /// Next special duration.
const OCIDuration OCI_DURATION_SESSION	= OCI_DURATION_BEGIN; /// The end of user session.
const OCIDuration OCI_DURATION_TRANS	= OCI_DURATION_BEGIN + 1; /// The end of user transaction.
deprecated const OCIDuration OCI_DURATION_CALL = OCI_DURATION_BEGIN + 2; /// Deprecated.  The end of user client/server call.
const OCIDuration OCI_DURATION_STATEMENT= OCI_DURATION_BEGIN + 3; ///
const OCIDuration OCI_DURATION_CALLOUT	= OCI_DURATION_BEGIN + 4; /// This is to be used only during callouts.  It is similar to that of OCI_DURATION_CALL, but lasts only for the duration of a callout.  Its heap is from PGA.
const OCIDuration OCI_DURATION_LAST	= OCI_DURATION_CALLOUT; /// The last predefined duration.
const OCIDuration OCI_DURATION_PROCESS	= OCI_DURATION_BEGIN - 5; /// This is not being treated as other predefined durations such as SESSION, CALL etc, because this would not have an entry in the duration table and its functionality is primitive such that only allocate, free, resize memory are allowed, but one cannot create subduration out of this.

/**
 * OCI object property.
 *
 * Deprecated:
 *	This will be removed or changed in a future release.
 *
 * This specifies the properties of objects in the object cache.
 */
deprecated enum OCIObjectProperty {
	OCI_OBJECTPROP_DIRTIED = 1,			/// Dirty objects.
	OCI_OBJECTPROP_LOADED,				/// Objects loaded in the transaction.
	OCI_OBJECTPROP_LOCKED				/// Locked objects.
}

/**
 * OCI cache refresh option.
 *
 * This option is used to specify the set of objects to be refreshed.
 *
 * OCI_REFRESH_LOAD refreshes the objects that are loaded in the current
 * transaction.
 */
enum OCIRefreshOpt {
	OCI_REFRESH_LOADED = 1				/// Refresh objects loaded in the transaction.
}

/**
 * OCI Object Event.
 *
 * Deprecated:
 *	This will be removed or changed in a future release.
 *
 * This specifies the kind of event that is supported by the object
 * cache.  The program can register a callback that is invoked when the
 * specified event occurs.
 */
deprecated enum OCIObjectEvent {
	OCI_OBJECTEVENT_BEFORE_FLUSH = 1,		/// Before flushing the cache.
	OCI_OBJECTEVENT_AFTER_FLUSH,			/// After flushing the cache.
	OCI_OBJECTEVENT_BEFORE_REFRESH,			/// Before refreshing the cache.
	OCI_OBJECTEVENT_AFTER_REFRESH,			/// After refreshing the cache.
	OCI_OBJECTEVENT_WHEN_MARK_UPDATED,		/// When an object is marked updated.
	OCI_OBJECTEVENT_WHEN_MARK_DELETED,		/// When an object is marked deleted.
	OCI_OBJECTEVENT_WHEN_UNMARK,			/// When an object is being unmarked.
	OCI_OBJECTEVENT_WHEN_LOCK			/// When an object is being locked.
}

const ub1 OCI_OBJECTCOPY_NOREF		= 0x01;		/// If OCI_OBJECTCOPY_NOREF is specified when copying an instance, the  reference and lob will not be copied to the target instance.

const ub2 OCI_OBJECTFREE_FORCE		= 0x0001;	/// If OCI_OBJECTCOPY_FORCE is specified when freeing an instance, the instance is freed regardless it is pinned or dirtied.
const ub2 OCI_OBJECTFREE_NONULL		= 0x0002;	/// If OCI_OBJECTCOPY_NONULL is specified when freeing an instance, the null structure is not freed.
const ub2 OCI_OBJECTFREE_HEADER		= 0x0004;	///

/**
 * OCI object property id.
 *
 * Identifies the different properties of objects.
 */
alias ub1 OCIObjectPropId;

const OCIObjectPropId OCI_OBJECTPROP_LIFETIME = 1;	/// Persistent or transient or value.
const OCIObjectPropId OCI_OBJECTPROP_SCHEMA = 2;	/// Schema name of table containing object.
const OCIObjectPropId OCI_OBJECTPROP_TABLE = 3;		/// Table name of table containing object.
const OCIObjectPropId OCI_OBJECTPROP_PIN_DURATION = 4;	/// Pin duartion of object.
const OCIObjectPropId OCI_OBJECTPROP_ALLOC_DURATION = 5;/// Alloc duartion of object.
const OCIObjectPropId OCI_OBJECTPROP_LOCK = 6;		/// Lock status of object.
const OCIObjectPropId OCI_OBJECTPROP_MARKSTATUS = 7;	/// Mark status of object.
const OCIObjectPropId OCI_OBJECTPROP_VIEW = 8;		/// Is object a view object or not?

/**
 * OCI object lifetime.
 *
 * Classifies objects depending upon the lifetime and referenceability
 * of the object.
 */
enum OCIObjectLifetime {
	OCI_OBJECT_PERSISTENT = 1,			/// Persistent object.
	OCI_OBJECT_TRANSIENT,				/// Transient object.
	OCI_OBJECT_VALUE				/// Value object.
}

/**
 * OCI object mark status.
 *
 * Status of the object - new, updated or deleted.
 */
alias uword OCIObjectMarkStatus;

const OCIObjectMarkStatus OCI_OBJECT_NEW= 0x0001;	/// New object.
const OCIObjectMarkStatus OCI_OBJECT_DELETED = 0x0002;	/// Object marked deleted.
const OCIObjectMarkStatus OCI_OBJECT_UPDATED = 0x0004;	/// Object marked updated.


/**
 *
 */
bool OCI_OBJECT_IS_DELETED (OCIObjectMarkStatus flag) {
	return flag && OCI_OBJECT_DELETED;
}

/**
 *
 */
bool OCI_OBJECT_IS_NEW (OCIObjectMarkStatus flag) {
	return flag && OCI_OBJECT_NEW;
}

/**
 *
 */
bool OCI_OBJECT_IS_DIRTY (OCIObjectMarkStatus flag) {
	return flag && (OCI_OBJECT_UPDATED | OCI_OBJECT_NEW | OCI_OBJECT_DELETED);
}

/**
 * The OCITypeCode type is interchangeable with the existing SQLT type, which is a ub2.
 */
alias ub2 OCITypeCode;

const OCITypeCode OCI_TYPECODE_REF	= SQLT_REF;	/// SQL/OTS OBJECT REFERENCE.
const OCITypeCode OCI_TYPECODE_DATE	= SQLT_DAT;	/// SQL DATE  OTS DATE.
const OCITypeCode OCI_TYPECODE_SIGNED8	= 27;		/// SQL SIGNED INTEGER(8)  OTS SINT8.
const OCITypeCode OCI_TYPECODE_SIGNED16	= 28;		/// SQL SIGNED INTEGER(16)  OTS SINT16.
const OCITypeCode OCI_TYPECODE_SIGNED32	= 29;		/// SQL SIGNED INTEGER(32)  OTS SINT32.
const OCITypeCode OCI_TYPECODE_REAL	= 21;		/// SQL REAL  OTS SQL_REAL.
const OCITypeCode OCI_TYPECODE_DOUBLE	= 22;		/// SQL DOUBLE PRECISION  OTS SQL_DOUBLE.
const OCITypeCode OCI_TYPECODE_BFLOAT	= SQLT_IBFLOAT;	/// Binary float.
const OCITypeCode OCI_TYPECODE_BDOUBLE	= SQLT_IBDOUBLE;/// Binary double.
const OCITypeCode OCI_TYPECODE_FLOAT	= SQLT_FLT;	/// SQL FLOAT(P)  OTS FLOAT(P).
const OCITypeCode OCI_TYPECODE_NUMBER	= SQLT_NUM;	/// SQL NUMBER(P S)  OTS NUMBER(P S).
const OCITypeCode OCI_TYPECODE_DECIMAL	= SQLT_PDN;	/// SQL DECIMAL(P S)  OTS DECIMAL(P S).
const OCITypeCode OCI_TYPECODE_UNSIGNED8= SQLT_BIN;	/// SQL UNSIGNED INTEGER(8)  OTS OCITypeCode8.
const OCITypeCode OCI_TYPECODE_UNSIGNED16 = 25;		/// SQL UNSIGNED INTEGER(16)  OTS OCITypeCode16.
const OCITypeCode OCI_TYPECODE_UNSIGNED32 = 26;		/// SQL UNSIGNED INTEGER(32)  OTS OCITypeCode32.
const OCITypeCode OCI_TYPECODE_OCTET	= 245;		/// SQL ???  OTS OCTET.
const OCITypeCode OCI_TYPECODE_SMALLINT	= 246;		/// SQL SMALLINT  OTS SMALLINT.
const OCITypeCode OCI_TYPECODE_INTEGER	= SQLT_INT;	/// SQL INTEGER  OTS INTEGER.
const OCITypeCode OCI_TYPECODE_RAW	= SQLT_LVB;	/// SQL RAW(N)  OTS RAW(N).
const OCITypeCode OCI_TYPECODE_PTR	= 32;		/// SQL POINTER  OTS POINTER.
const OCITypeCode OCI_TYPECODE_VARCHAR2	= SQLT_VCS;	/// SQL VARCHAR2(N)  OTS SQL_VARCHAR2(N).
const OCITypeCode OCI_TYPECODE_CHAR	= SQLT_AFC;	/// SQL CHAR(N)  OTS SQL_CHAR(N).
const OCITypeCode OCI_TYPECODE_VARCHAR	= SQLT_CHR;	/// SQL VARCHAR(N)  OTS SQL_VARCHAR(N).
const OCITypeCode OCI_TYPECODE_MLSLABEL	= SQLT_LAB;	/// OTS MLSLABEL.
const OCITypeCode OCI_TYPECODE_VARRAY	= 247;		/// SQL VARRAY  OTS PAGED VARRAY.
const OCITypeCode OCI_TYPECODE_TABLE	= 248;		/// SQL TABLE  OTS MULTISET.
const OCITypeCode OCI_TYPECODE_OBJECT	= SQLT_NTY;	/// SQL/OTS NAMED OBJECT TYPE.
const OCITypeCode OCI_TYPECODE_OPAQUE	= 58;		/// SQL/OTS Opaque Types.
const OCITypeCode OCI_TYPECODE_NAMEDCOLLECTION = SQLT_NCO; /// SQL/OTS NAMED COLLECTION TYPE.
const OCITypeCode OCI_TYPECODE_BLOB	= SQLT_BLOB;	/// SQL/OTS BINARY LARGE OBJECT.
const OCITypeCode OCI_TYPECODE_BFILE	= SQLT_BFILEE;	/// SQL/OTS BINARY FILE OBJECT.
const OCITypeCode OCI_TYPECODE_CLOB	= SQLT_CLOB;	/// SQL/OTS CHARACTER LARGE OBJECT.
const OCITypeCode OCI_TYPECODE_CFILE	= SQLT_CFILEE;	/// SQL/OTS CHARACTER FILE OBJECT.

const OCITypeCode OCI_TYPECODE_TIME	= SQLT_TIME;	/// SQL/OTS TIME.
const OCITypeCode OCI_TYPECODE_TIME_TZ	= SQLT_TIME_TZ;	/// SQL/OTS TIME_TZ.
const OCITypeCode OCI_TYPECODE_TIMESTAMP= SQLT_TIMESTAMP; /// SQL/OTS TIMESTAMP.
const OCITypeCode OCI_TYPECODE_TIMESTAMP_TZ = SQLT_TIMESTAMP_TZ; /// SQL/OTS TIMESTAMP_TZ.

const OCITypeCode OCI_TYPECODE_TIMESTAMP_LTZ = SQLT_TIMESTAMP_LTZ; /// TIMESTAMP_LTZ.

const OCITypeCode OCI_TYPECODE_INTERVAL_YM = SQLT_INTERVAL_YM; /// SQL/OTS INTRVL YR-MON.
const OCITypeCode OCI_TYPECODE_INTERVAL_DS = SQLT_INTERVAL_DS; /// SQL/OTS INTRVL DAY-SEC.
const OCITypeCode OCI_TYPECODE_UROWID	= SQLT_RDD;	/// Urowid type.


const OCITypeCode OCI_TYPECODE_OTMFIRST	= 228;		/// first Open Type Manager typecode.
const OCITypeCode OCI_TYPECODE_OTMLAST	= 320;		/// last OTM typecode.
const OCITypeCode OCI_TYPECODE_SYSFIRST	= 228;		/// first OTM system type (internal).
const OCITypeCode OCI_TYPECODE_SYSLAST	= 235;		/// last OTM system type (internal).
const OCITypeCode OCI_TYPECODE_PLS_INTEGER = 266;	/// type code for PLS_INTEGER.

//const OCITypeCode OCI_TYPECODE_ITABLE	= SQLT_TAB;	/// PLSQL indexed table.  Do not use.
//const OCITypeCode OCI_TYPECODE_RECORD	= SQLT_REC;	/// PLSQL record.  Do not use.
//const OCITypeCode OCI_TYPECODE_BOOLEAN	= SQLT_BOL;	/// PLSQL boolean.  Do not use.

const OCITypeCode OCI_TYPECODE_NCHAR	= 286;		/// Intended for use in the OCIAnyData API only.
const OCITypeCode OCI_TYPECODE_NVARCHAR2= 287;		/// Intended for use in the OCIAnyData API only.
const OCITypeCode OCI_TYPECODE_NCLOB	= 288;		/// Intended for use in the OCIAnyData API only.

const OCITypeCode OCI_TYPECODE_NONE	= 0;		/// To indicate absence of typecode being specified.
const OCITypeCode OCI_TYPECODE_ERRHP	= 283;		/// To indicate error has to be taken from error handle - reserved for sqlplus use.

/**
 * This is the flag passed to OCIGetTypeArray() to indicate how the TDO is
 * going to be loaded into the object cache.
 * OCI_TYPEGET_HEADER implies that only the header portion is to be loaded
 * initially, with the rest loaded in on a 'lazy' basis. Only the header is
 * needed for PL/SQL and OCI operations. OCI_TYPEGET_ALL implies that ALL
 * the attributes and methods belonging to a TDO will be loaded into the
 * object cache in one round trip. Hence it will take much longer to execute,
 * but will ensure that no more loading needs to be done when pinning ADOs
 * etc. This is only needed if your code needs to examine and manipulate
 * attribute and method information.
 *
 * The default is OCI_TYPEGET_HEADER.
 */
enum OCITypeGetOpt {
	OCI_TYPEGET_HEADER,				/// Load only the header portion of the TDO when getting the type.
	OCI_TYPEGET_ALL					/// Load all attribute and method descriptors as well.
}

/**
 * OCI Encapsulation Level
 */
enum OCITypeEncap {
	OCI_TYPEENCAP_PRIVATE,				/// Private: only visible internally.
	OCI_TYPEENCAP_PUBLIC				/// Public: visible both internally and externally.
}

/**
 *
 */
enum OCITypeMethodFlag : size_t {
	OCI_TYPEMETHOD_INLINE = 0x0001,			/// Inline.
	OCI_TYPEMETHOD_CONSTANT = 0x0002,		/// Constant.
	OCI_TYPEMETHOD_VIRTUAL = 0x0004,		/// Virtual.
	OCI_TYPEMETHOD_CONSTRUCTOR = 0x0008,		/// Constructor.
	OCI_TYPEMETHOD_DESTRUCTOR = 0x0010,		/// Destructor.
	OCI_TYPEMETHOD_OPERATOR  = 0x0020,		/// Operator.
	OCI_TYPEMETHOD_SELFISH = 0x0040,		/// Selfish method (generic otherwise).
	OCI_TYPEMETHOD_MAP = 0x0080,			/// Map (relative ordering).
	OCI_TYPEMETHOD_ORDER  = 0x0100,			/// Order (relative ordering).
	OCI_TYPEMETHOD_RNDS= 0x0200,			/// Read no Data State (default).
	OCI_TYPEMETHOD_WNDS= 0x0400,			/// Write no Data State.
	OCI_TYPEMETHOD_RNPS= 0x0800,			/// Read no Process State.
	OCI_TYPEMETHOD_WNPS= 0x1000,			/// Write no Process State.
	OCI_TYPEMETHOD_ABSTRACT = 0x2000,		/// Abstract (not instantiable) method.
	OCI_TYPEMETHOD_OVERRIDING = 0x4000,		/// Overriding method.
	OCI_TYPEMETHOD_PIPELINED = 0x8000		/// Method is pipelined.
}

/**
 *
 */
bool OCI_METHOD_IS_NEW (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_INLINE;
}

/**
 *
 */
bool OCI_METHOD_IS_CONSTANT (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_CONSTANT;
}

/**
 *
 */
bool OCI_METHOD_IS_VIRTUAL (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_VIRTUAL;
}

/**
 *
 */
bool OCI_METHOD_IS_CONSTRUCTOR (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_CONSTRUCTOR;
}

/**
 *
 */
bool OCI_METHOD_IS_DESTRUCTOR (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_DESTRUCTOR;
}

/**
 *
 */
bool OCI_METHOD_IS_OPERATOR (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_OPERATOR;
}

/**
 *
 */
bool OCI_METHOD_IS_SELFISH (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_SELFISH;
}

/**
 *
 */
bool OCI_METHOD_IS_MAP (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_MAP;
}

/**
 *
 */
bool OCI_METHOD_IS_ORDER (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_ORDER;
}

/**
 *
 */
bool OCI_METHOD_IS_RNDS (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_RNDS;
}

/**
 *
 */
bool OCI_METHOD_IS_WNDS (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_WNDS;
}

/**
 *
 */
bool OCI_METHOD_IS_RNPS (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_RNPS;
}

/**
 *
 */
bool OCI_METHOD_IS_WNPS (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_WNPS;
}

/**
 *
 */
bool OCI_METHOD_IS_ABSTRACT (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_ABSTRACT;
}

/**
 *
 */
bool OCI_METHOD_IS_OVERRIDING (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_OVERRIDING;
}

/**
 *
 */
bool OCI_METHOD_IS_PIPELINED (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_PIPELINED;
}

/**
 *
 */
bool OCI_TYPEMETHOD_IS_INLINE (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_INLINE;
}

/**
 *
 */
bool OCI_TYPEMETHOD_IS_CONSTANT (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_CONSTANT;
}

/**
 *
 */
bool OCI_TYPEMETHOD_IS_VIRTUAL (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_VIRTUAL;
}

/**
 *
 */
bool OCI_TYPEMETHOD_IS_CONSTRUCTOR (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_CONSTRUCTOR;
}

/**
 *
 */
bool OCI_TYPEMETHOD_IS_DESTRUCTOR (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_DESTRUCTOR;
}

/**
 *
 */
bool OCI_TYPEMETHOD_IS_OPERATOR (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_OPERATOR;
}

/**
 *
 */
bool OCI_TYPEMETHOD_IS_SELFISH (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_SELFISH;
}

/**
 *
 */
bool OCI_TYPEMETHOD_IS_MAP (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_MAP;
}

/**
 *
 */
bool OCI_TYPEMETHOD_IS_ORDER (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_ORDER;
}

/**
 *
 */
bool OCI_TYPEMETHOD_IS_RNDS (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_RNDS;
}

/**
 *
 */
bool OCI_TYPEMETHOD_IS_WNDS (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_WNDS;
}

/**
 *
 */
bool OCI_TYPEMETHOD_IS_RNPS (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_RNPS;
}

/**
 *
 */
bool OCI_TYPEMETHOD_IS_WNPS (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_WNPS;
}

/**
 *
 */
bool OCI_TYPEMETHOD_IS_ABSTRACT (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_ABSTRACT;
}

/**
 *
 */
bool OCI_TYPEMETHOD_IS_OVERRIDING (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_OVERRIDING;
}

/**
 *
 */
bool OCI_TYPEMETHOD_IS_PIPELINED (OCITypeMethodFlag flag) {
	return flag && OCITypeMethodFlag.OCI_TYPEMETHOD_PIPELINED;
}

/**
 *
 */
void OCI_TYPEMETHOD_SET_INLINE (OCITypeMethodFlag flag) {
	return flag &= OCITypeMethodFlag.OCI_TYPEMETHOD_INLINE;
}

/**
 *
 */
void OCI_TYPEMETHOD_SET_CONSTANT (OCITypeMethodFlag flag) {
	return flag &= OCITypeMethodFlag.OCI_TYPEMETHOD_CONSTANT;
}

/**
 *
 */
void OCI_TYPEMETHOD_SET_VIRTUAL (OCITypeMethodFlag flag) {
	return flag &= OCITypeMethodFlag.OCI_TYPEMETHOD_VIRTUAL;
}

/**
 *
 */
void OCI_TYPEMETHOD_SET_CONSTRUCTOR (OCITypeMethodFlag flag) {
	return flag &= OCITypeMethodFlag.OCI_TYPEMETHOD_CONSTRUCTOR;
}

/**
 *
 */
void OCI_TYPEMETHOD_SET_DESTRUCTOR (OCITypeMethodFlag flag) {
	return flag &= OCITypeMethodFlag.OCI_TYPEMETHOD_DESTRUCTOR;
}

/**
 *
 */
void OCI_TYPEMETHOD_SET_OPERATOR (OCITypeMethodFlag flag) {
	return flag &= OCITypeMethodFlag.OCI_TYPEMETHOD_OPERATOR;
}

/**
 *
 */
void OCI_TYPEMETHOD_SET_SELFISH (OCITypeMethodFlag flag) {
	return flag &= OCITypeMethodFlag.OCI_TYPEMETHOD_SELFISH;
}

/**
 *
 */
void OCI_TYPEMETHOD_SET_MAP (OCITypeMethodFlag flag) {
	return flag &= OCITypeMethodFlag.OCI_TYPEMETHOD_MAP;
}

/**
 *
 */
void OCI_TYPEMETHOD_SET_ORDER (OCITypeMethodFlag flag) {
	return flag &= OCITypeMethodFlag.OCI_TYPEMETHOD_ORDER;
}

/**
 *
 */
void OCI_TYPEMETHOD_SET_RNDS (OCITypeMethodFlag flag) {
	return flag &= OCITypeMethodFlag.OCI_TYPEMETHOD_RNDS;
}

/**
 *
 */
void OCI_TYPEMETHOD_SET_WNDS (OCITypeMethodFlag flag) {
	return flag &= OCITypeMethodFlag.OCI_TYPEMETHOD_WNDS;
}

/**
 *
 */
void OCI_TYPEMETHOD_SET_RNPS (OCITypeMethodFlag flag) {
	return flag &= OCITypeMethodFlag.OCI_TYPEMETHOD_RNPS;
}

/**
 *
 */
void OCI_TYPEMETHOD_SET_WNPS (OCITypeMethodFlag flag) {
	return flag &= OCITypeMethodFlag.OCI_TYPEMETHOD_WNPS;
}

/**
 *
 */
void OCI_TYPEMETHOD_CLEAR_INLINE (OCITypeMethodFlag flag) {
	return flag ^= OCITypeMethodFlag.OCI_TYPEMETHOD_INLINE;
}

/**
 *
 */
void OCI_TYPEMETHOD_CLEAR_CONSTANT (OCITypeMethodFlag flag) {
	return flag ^= OCITypeMethodFlag.OCI_TYPEMETHOD_CONSTANT;
}

/**
 *
 */
void OCI_TYPEMETHOD_CLEAR_VIRTUAL (OCITypeMethodFlag flag) {
	return flag ^= OCITypeMethodFlag.OCI_TYPEMETHOD_VIRTUAL;
}

/**
 *
 */
void OCI_TYPEMETHOD_CLEAR_CONSTRUCTOR (OCITypeMethodFlag flag) {
	return flag ^= OCITypeMethodFlag.OCI_TYPEMETHOD_CONSTRUCTOR;
}

/**
 *
 */
void OCI_TYPEMETHOD_CLEAR_DESTRUCTOR (OCITypeMethodFlag flag) {
	return flag ^= OCITypeMethodFlag.OCI_TYPEMETHOD_DESTRUCTOR;
}

/**
 *
 */
void OCI_TYPEMETHOD_CLEAR_OPERATOR (OCITypeMethodFlag flag) {
	return flag ^= OCITypeMethodFlag.OCI_TYPEMETHOD_OPERATOR;
}

/**
 *
 */
void OCI_TYPEMETHOD_CLEAR_SELFISH (OCITypeMethodFlag flag) {
	return flag ^= OCITypeMethodFlag.OCI_TYPEMETHOD_SELFISH;
}

/**
 *
 */
void OCI_TYPEMETHOD_CLEAR_MAP (OCITypeMethodFlag flag) {
	return flag ^= OCITypeMethodFlag.OCI_TYPEMETHOD_MAP;
}

/**
 *
 */
void OCI_TYPEMETHOD_CLEAR_ORDER (OCITypeMethodFlag flag) {
	return flag ^= OCITypeMethodFlag.OCI_TYPEMETHOD_ORDER;
}

/**
 *
 */
void OCI_TYPEMETHOD_CLEAR_RNDS (OCITypeMethodFlag flag) {
	return flag ^= OCITypeMethodFlag.OCI_TYPEMETHOD_RNDS;
}

/**
 *
 */
void OCI_TYPEMETHOD_CLEAR_WNDS (OCITypeMethodFlag flag) {
	return flag ^= OCITypeMethodFlag.OCI_TYPEMETHOD_WNDS;
}

/**
 *
 */
void OCI_TYPEMETHOD_CLEAR_RNPS (OCITypeMethodFlag flag) {
	return flag ^= OCITypeMethodFlag.OCI_TYPEMETHOD_RNPS;
}

/**
 *
 */
void OCI_TYPEMETHOD_CLEAR_WNPS (OCITypeMethodFlag flag) {
	return flag ^= OCITypeMethodFlag.OCI_TYPEMETHOD_WNPS;
}

/**
 *
 */
enum OCITypeParamMode {
	OCI_TYPEPARAM_IN = 0,				/// In.
	OCI_TYPEPARAM_OUT,				/// Out.
	OCI_TYPEPARAM_INOUT,				/// Inout.
	OCI_TYPEPARAM_BYREF,				/// Call by reference (implicitly in-out).
	OCI_TYPEPARAM_OUTNCPY,				/// OUT with NOCOPY modifier.
	OCI_TYPEPARAM_INOUTNCPY				/// IN OUT with NOCOPY modifier.
}

const ub1 OCI_NUMBER_DEFAULTPREC	= 0;		/// No precision specified.
deprecated const sb1 OCI_NUMBER_DEFAULTSCALE = -127;	 /// No binary/decimal scale specified.

const uint OCI_VARRAY_MAXSIZE		= 4000;		/// Default maximum number of elements for a varray.
const uint OCI_STRING_MAXLEN		= 4000;		/// Default maximum length of a vstring.

deprecated alias OCIRefreshOpt OCICoherency;		/// Deprecated: Only used for beta2.
deprecated OCIRefreshOpt OCI_COHERENCY	= cast(OCIRefreshOpt)2; /// Deprecated: Only used for beta2.
deprecated OCIRefreshOpt OCI_COHERENCY_NULL = cast(OCIRefreshOpt)4; /// Deprecated: Only used for beta2.
deprecated OCIRefreshOpt OCI_COHERENCY_ALWAYS = cast(OCIRefreshOpt)5; /// Deprecated: Only used for beta2.