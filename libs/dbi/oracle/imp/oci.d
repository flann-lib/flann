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
module dbi.oracle.imp.oci;


version (Windows) {
	pragma (lib, "oci.lib");
} else version (linux) {
	pragma (lib, "liboci.a");
} else version (Posix) {
	pragma (lib, "liboci.a");
} else version (darwin) {
	pragma (msg, "You will need to manually link in the Oracle library.");
} else {
	pragma (msg, "You will need to manually link in the Oracle library.");
}

public import	dbi.oracle.imp.nzerror,
		dbi.oracle.imp.nzt,
		dbi.oracle.imp.oci1,
		dbi.oracle.imp.oci8dp,
		dbi.oracle.imp.ociap,
		dbi.oracle.imp.ociapr,
		dbi.oracle.imp.ocidef,
		dbi.oracle.imp.ocidem,
		dbi.oracle.imp.ocidfn,
		dbi.oracle.imp.ociextp,
		dbi.oracle.imp.ocikpr,
		dbi.oracle.imp.ocixmldb,
		dbi.oracle.imp.odci,
		dbi.oracle.imp.oratypes,
		dbi.oracle.imp.ori,
		dbi.oracle.imp.orid,
		dbi.oracle.imp.orl,
		dbi.oracle.imp.oro,
		dbi.oracle.imp.ort,
		dbi.oracle.imp.xa;

const uint OCI_HTYPE_FIRST		= 1;		/// Start value of handle type.
const uint OCI_HTYPE_ENV		= 1;		/// Environment handle.
const uint OCI_HTYPE_ERROR		= 2;		/// Error handle.
const uint OCI_HTYPE_SVCCTX		= 3;		/// Service handle.
const uint OCI_HTYPE_STMT		= 4;		/// Statement handle.
const uint OCI_HTYPE_BIND		= 5;		/// Bind handle.
const uint OCI_HTYPE_DEFINE		= 6;		/// Define handle.
const uint OCI_HTYPE_DESCRIBE		= 7;		/// Describe handle.
const uint OCI_HTYPE_SERVER		= 8;		/// Server handle.
const uint OCI_HTYPE_SESSION		= 9;		/// Authentication handle.
const uint OCI_HTYPE_AUTHINFO		= OCI_HTYPE_SESSION; /// SessionGet auth handle.
const uint OCI_HTYPE_TRANS		= 10;		/// Transaction handle.
const uint OCI_HTYPE_COMPLEXOBJECT	= 11;		/// Complex object retrieval handle.
const uint OCI_HTYPE_SECURITY		= 12;		/// Security handle.
const uint OCI_HTYPE_SUBSCRIPTION	= 13;		/// Subscription handle.
const uint OCI_HTYPE_DIRPATH_CTX	= 14;		/// Direct path context.
const uint OCI_HTYPE_DIRPATH_COLUMN_ARRAY = 15;		/// Direct path column array.
const uint OCI_HTYPE_DIRPATH_STREAM	= 16;		/// Direct path stream.
const uint OCI_HTYPE_PROC		= 17;		/// Process handle.
const uint OCI_HTYPE_DIRPATH_FN_CTX	= 18;		/// Direct path function context.
const uint OCI_HTYPE_DIRPATH_FN_COL_ARRAY = 19;		/// Direct path object column array.
const uint OCI_HTYPE_XADSESSION		= 20;		/// Access driver session.
const uint OCI_HTYPE_XADTABLE		= 21;		/// Access driver table.
const uint OCI_HTYPE_XADFIELD		= 22;		/// Access driver field.
const uint OCI_HTYPE_XADGRANULE		= 23;		/// Access driver granule.
const uint OCI_HTYPE_XADRECORD		= 24;		/// Access driver record.
const uint OCI_HTYPE_XADIO		= 25;		/// Access driver I/O.
const uint OCI_HTYPE_CPOOL		= 26;		/// Connection pool handle.
const uint OCI_HTYPE_SPOOL		= 27;		/// Session pool handle.
const uint OCI_HTYPE_ADMIN		= 28;		/// Admin handle.
const uint OCI_HTYPE_EVENT		= 29;		/// HA event handle.
const uint OCI_HTYPE_LAST		= 29;		/// Last value of a handle type.

const uint OCI_DTYPE_FIRST		= 50;		/// Start value of descriptor type.
const uint OCI_DTYPE_LOB		= 50;		/// Lob locator.
const uint OCI_DTYPE_SNAP		= 51;		/// Snapshot descriptor.
const uint OCI_DTYPE_RSET		= 52;		/// Result set descriptor.
const uint OCI_DTYPE_PARAM		= 53;		/// A parameter descriptor obtained from ocigparm.
const uint OCI_DTYPE_ROWID		= 54;		/// Rowid descriptor.
const uint OCI_DTYPE_COMPLEXOBJECTCOMP	= 55;		/// Complex object retrieval descriptor.
const uint OCI_DTYPE_FILE		= 56;		/// File Lob locator.
const uint OCI_DTYPE_AQENQ_OPTIONS	= 57;		/// Enqueue options.
const uint OCI_DTYPE_AQDEQ_OPTIONS	= 58;		/// Dequeue options.
const uint OCI_DTYPE_AQMSG_PROPERTIES	= 59;		/// Message properties.
const uint OCI_DTYPE_AQAGENT		= 60;		/// Aq agent.
const uint OCI_DTYPE_LOCATOR		= 61;		/// LOB locator.
const uint OCI_DTYPE_INTERVAL_YM	= 62;		/// Interval year month.
const uint OCI_DTYPE_INTERVAL_DS	= 63;		/// Interval day second.
const uint OCI_DTYPE_AQNFY_DESCRIPTOR	= 64;		/// AQ notify descriptor.
const uint OCI_DTYPE_DATE		= 65;		/// Date.
const uint OCI_DTYPE_TIME		= 66;		/// Time.
const uint OCI_DTYPE_TIME_TZ		= 67;		/// Time with timezone.
const uint OCI_DTYPE_TIMESTAMP		= 68;		/// Timestamp.
const uint OCI_DTYPE_TIMESTAMP_TZ	= 69;		/// Timestamp with timezone.
const uint OCI_DTYPE_TIMESTAMP_LTZ	= 70;		/// Timestamp with local tz.
const uint OCI_DTYPE_UCB		= 71;		/// User callback descriptor.
const uint OCI_DTYPE_SRVDN		= 72;		/// Server DN list descriptor.
const uint OCI_DTYPE_SIGNATURE		= 73;		/// Signature.
const uint OCI_DTYPE_RESERVED_1		= 74;		/// Reserved for internal use.
const uint OCI_DTYPE_AQLIS_OPTIONS	= 75;		/// AQ listen options.
const uint OCI_DTYPE_AQLIS_MSG_PROPERTIES = 76;		/// AQ listen msg props.
const uint OCI_DTYPE_CHDES		= 77;		/// Top level change notification desc.
const uint OCI_DTYPE_TABLE_CHDES	= 78;		/// Table change descriptor.
const uint OCI_DTYPE_ROW_CHDES		= 79;		/// Row change descriptor.
const uint OCI_DTYPE_LAST		= 79;		/// Last value of a descriptor type.

const uint OCI_TEMP_BLOB		= 1;		/// LOB type - BLOB.
const uint OCI_TEMP_CLOB		= 2;		/// LOB type - CLOB.

const uint OCI_OTYPE_NAME		= 1;		/// Object name.
const uint OCI_OTYPE_REF		= 2;		/// REF to TDO.
const uint OCI_OTYPE_PTR		= 3;		/// PTR to TDO.

const uint OCI_ATTR_FNCODE		= 1;		/// The OCI function code.
const uint OCI_ATTR_OBJECT		= 2;		/// Is the environment initialized in object mode?
const uint OCI_ATTR_NONBLOCKING_MODE	= 3;		/// Non blocking mode.
const uint OCI_ATTR_SQLCODE		= 4;		/// The SQL verb.
const uint OCI_ATTR_ENV			= 5;		/// The environment handle.
const uint OCI_ATTR_SERVER		= 6;		/// The server handle.
const uint OCI_ATTR_SESSION		= 7;		/// The user session handle.
const uint OCI_ATTR_TRANS		= 8;		/// The transaction handle.
const uint OCI_ATTR_ROW_COUNT		= 9;		/// The rows processed so far.
const uint OCI_ATTR_SQLFNCODE		= 10;		/// The SQL verb of the statement.
const uint OCI_ATTR_PREFETCH_ROWS	= 11;		/// Sets the number of rows to prefetch.
const uint OCI_ATTR_NESTED_PREFETCH_ROWS= 12;		/// The prefetch rows of nested table.
const uint OCI_ATTR_PREFETCH_MEMORY	= 13;		/// Memory limit for rows fetched.
const uint OCI_ATTR_NESTED_PREFETCH_MEMORY = 14;	/// Memory limit for nested rows.
const uint OCI_ATTR_CHAR_COUNT		= 15;		/// This specifies the bind and define size in characters.
const uint OCI_ATTR_PDSCL		= 16;		/// Packed decimal scale.
const uint OCI_ATTR_FSPRECISION		= OCI_ATTR_PDSCL; /// Fs prec for datetime data types.
const uint OCI_ATTR_PDPRC		= 17;		/// Packed decimal format.
const uint OCI_ATTR_LFPRECISION		= OCI_ATTR_PDPRC; /// Fs prec for datetime data types.
const uint OCI_ATTR_PARAM_COUNT		= 18;		/// Number of column in the select list.
const uint OCI_ATTR_ROWID		= 19;		/// The rowid.
const uint OCI_ATTR_CHARSET		= 20;		/// The character set value.
const uint OCI_ATTR_NCHAR		= 21;		/// NCHAR type.
const uint OCI_ATTR_USERNAME		= 22;		/// Username attribute.
const uint OCI_ATTR_PASSWORD		= 23;		/// Password attribute.
const uint OCI_ATTR_STMT_TYPE		= 24;		/// Statement type.
const uint OCI_ATTR_INTERNAL_NAME	= 25;		/// Tser friendly global name.
const uint OCI_ATTR_EXTERNAL_NAME	= 26;		/// The internal name for global txn.
const uint OCI_ATTR_XID			= 27;           /// XOPEN defined global transaction id.
const uint OCI_ATTR_TRANS_LOCK		= 28;		///
const uint OCI_ATTR_TRANS_NAME		= 29;		/// String to identify a global transaction.
const uint OCI_ATTR_HEAPALLOC		= 30;		/// Memory allocated on the heap.
const uint OCI_ATTR_CHARSET_ID		= 31;		/// Character Set ID.
const uint OCI_ATTR_CHARSET_FORM	= 32;		/// Character Set Form.
const uint OCI_ATTR_MAXDATA_SIZE	= 33;		/// Maximumsize of data on the server .
const uint OCI_ATTR_CACHE_OPT_SIZE	= 34;		/// Object cache optimal size.
const uint OCI_ATTR_CACHE_MAX_SIZE	= 35;		/// Object cache maximum size percentage.
const uint OCI_ATTR_PINOPTION		= 36;		/// Object cache default pin option.
const uint OCI_ATTR_ALLOC_DURATION	= 37;		/// Object cache default allocation duration.
const uint OCI_ATTR_PIN_DURATION	= 38;		/// Object cache default pin duration.
const uint OCI_ATTR_FDO			= 39;		/// Format Descriptor object attribute.
const uint OCI_ATTR_POSTPROCESSING_CALLBACK = 40;	/// Callback to process outbind data.
const uint OCI_ATTR_POSTPROCESSING_CONTEXT = 41;	/// Callback context to process outbind data.
const uint OCI_ATTR_ROWS_RETURNED	= 42;		/// Number of rows returned in current iter - for Bind handles.
const uint OCI_ATTR_FOCBK		= 43;		/// Failover Callback attribute.
const uint OCI_ATTR_IN_V8_MODE		= 44;		/// Is the server/service context in V8 mode?
const uint OCI_ATTR_LOBEMPTY		= 45;		/// Empty lob ?
const uint OCI_ATTR_SESSLANG		= 46;		/// Session language handle.

const uint OCI_ATTR_VISIBILITY		= 47;		/// Visibility.
const uint OCI_ATTR_RELATIVE_MSGID	= 48;		/// Relative message id.
const uint OCI_ATTR_SEQUENCE_DEVIATION	= 49;		/// Sequence deviation.

const uint OCI_ATTR_CONSUMER_NAME	= 50;		/// Consumer name.
const uint OCI_ATTR_DEQ_MODE		= 51;		/// Dequeue mode.
const uint OCI_ATTR_NAVIGATION		= 52;		/// Navigation.
const uint OCI_ATTR_WAIT		= 53;		/// Wait.
const uint OCI_ATTR_DEQ_MSGID		= 54;		/// Dequeue message id.

const uint OCI_ATTR_PRIORITY		= 55;		/// Priority.
const uint OCI_ATTR_DELAY		= 56;		/// Delay.
const uint OCI_ATTR_EXPIRATION		= 57;		/// Expiration.
const uint OCI_ATTR_CORRELATION		= 58;		/// Correlation id.
const uint OCI_ATTR_ATTEMPTS		= 59;		/// # of attempts.
const uint OCI_ATTR_RECIPIENT_LIST	= 60;		/// Recipient list.
const uint OCI_ATTR_EXCEPTION_QUEUE	= 61;		/// Exception queue name.
const uint OCI_ATTR_ENQ_TIME		= 62;		/// Enqueue time (only OCIAttrGet).
const uint OCI_ATTR_MSG_STATE		= 63;		/// Message state (only OCIAttrGet).
const uint OCI_ATTR_AGENT_NAME		= 64;		/// Agent name.
const uint OCI_ATTR_AGENT_ADDRESS	= 65;		/// Agent address.
const uint OCI_ATTR_AGENT_PROTOCOL	= 66;		/// Agent protocol.
const uint OCI_ATTR_USER_PROPERTY	= 67;		/// User property.
const uint OCI_ATTR_SENDER_ID		= 68;		/// Sender id.
const uint OCI_ATTR_ORIGINAL_MSGID	= 69;		/// Original message id.

const uint OCI_ATTR_QUEUE_NAME		= 70;		/// Queue name.
const uint OCI_ATTR_NFY_MSGID		= 71;		/// Message id.
const uint OCI_ATTR_MSG_PROP		= 72;		/// Message properties.

const uint OCI_ATTR_NUM_DML_ERRORS	= 73;		/// Number of errors in array DML.
const uint OCI_ATTR_DML_ROW_OFFSET	= 74;		/// Row offset in the array.

const uint OCI_ATTR_AQ_NUM_ERRORS	= OCI_ATTR_NUM_DML_ERRORS; ///
const uint OCI_ATTR_AQ_ERROR_INDEX	= OCI_ATTR_DML_ROW_OFFSET; ///

const uint OCI_ATTR_DATEFORMAT		= 75;		/// Default date format string.
const uint OCI_ATTR_BUF_ADDR		= 76;		/// Buffer address.
const uint OCI_ATTR_BUF_SIZE		= 77;		/// Buffer size.

const uint OCI_ATTR_NUM_ROWS		= 81;		/// Number of rows in column array.
const uint OCI_ATTR_COL_COUNT		= 82;		/// Columns of column array processed so far.      .
const uint OCI_ATTR_STREAM_OFFSET	= 83;		/// Str off of last row processed.
const uint OCI_ATTR_SHARED_HEAPALLOC	= 84;		/// Shared Heap Allocation Size.

const uint OCI_ATTR_SERVER_GROUP	= 85;		/// Server group name.

const uint OCI_ATTR_MIGSESSION		= 86;		/// Migratable session attribute.

const uint OCI_ATTR_NOCACHE		= 87;		/// Temporary LOBs.

const uint OCI_ATTR_MEMPOOL_SIZE	= 88;		/// Pool Size.
const uint OCI_ATTR_MEMPOOL_INSTNAME	= 89;		/// Instance name.
const uint OCI_ATTR_MEMPOOL_APPNAME	= 90;		/// Application name.
const uint OCI_ATTR_MEMPOOL_HOMENAME	= 91;		/// Home Directory name.
const uint OCI_ATTR_MEMPOOL_MODEL	= 92;		/// Pool Model (proc,thrd,both).
const uint OCI_ATTR_MODES		= 93;		/// Modes.

const uint OCI_ATTR_SUBSCR_NAME		= 94;		/// Name of subscription.
const uint OCI_ATTR_SUBSCR_CALLBACK	= 95;		/// Associated callback.
const uint OCI_ATTR_SUBSCR_CTX		= 96;		/// Associated callback context.
const uint OCI_ATTR_SUBSCR_PAYLOAD	= 97;		/// Associated payload.
const uint OCI_ATTR_SUBSCR_NAMESPACE	= 98;		/// Associated namespace.

const uint OCI_ATTR_PROXY_CREDENTIALS	= 99;		/// Proxy user credentials.
const uint OCI_ATTR_INITIAL_CLIENT_ROLES= 100;		/// Initial client role list.

const uint OCI_ATTR_UNK			= 101;		/// Unknown attribute.
const uint OCI_ATTR_NUM_COLS		= 102;		/// Number of columns.
const uint OCI_ATTR_LIST_COLUMNS	= 103;		/// Parameter of the column list.
const uint OCI_ATTR_RDBA		= 104;		/// DBA of the segment header.
const uint OCI_ATTR_CLUSTERED		= 105;		/// Whether the table is clustered.
const uint OCI_ATTR_PARTITIONED		= 106;		/// Whether the table is partitioned.
const uint OCI_ATTR_INDEX_ONLY		= 107;		/// Whether the table is index only.
const uint OCI_ATTR_LIST_ARGUMENTS	= 108;		/// Parameter of the argument list.
const uint OCI_ATTR_LIST_SUBPROGRAMS	= 109;		/// Parameter of the subprogram list.
const uint OCI_ATTR_REF_TDO		= 110;		/// REF to the type descriptor.
const uint OCI_ATTR_LINK		= 111;		/// The database link name.
const uint OCI_ATTR_MIN			= 112;		/// Minimum value.
const uint OCI_ATTR_MAX			= 113;		/// Maximum value.
const uint OCI_ATTR_INCR		= 114;		/// Increment value.
const uint OCI_ATTR_CACHE		= 115;		/// Number of sequence numbers cached.
const uint OCI_ATTR_ORDER		= 116;		/// Whether the sequence is ordered.
const uint OCI_ATTR_HW_MARK		= 117;		/// High-water mark.
const uint OCI_ATTR_TYPE_SCHEMA		= 118;		/// Type's schema name.
const uint OCI_ATTR_TIMESTAMP		= 119;		/// Timestamp of the object.
const uint OCI_ATTR_NUM_ATTRS		= 120;		/// Number of sttributes.
const uint OCI_ATTR_NUM_PARAMS		= 121;		/// Number of parameters.
const uint OCI_ATTR_OBJID		= 122;		/// Object id for a table or view.
const uint OCI_ATTR_PTYPE		= 123;		/// Type of info described by.
const uint OCI_ATTR_PARAM		= 124;		/// Parameter descriptor.
const uint OCI_ATTR_OVERLOAD_ID		= 125;		/// Overload ID for funcs and procs.
const uint OCI_ATTR_TABLESPACE		= 126;		/// Table name space.
const uint OCI_ATTR_TDO			= 127;		/// TDO of a type.
const uint OCI_ATTR_LTYPE		= 128;		/// List type.
const uint OCI_ATTR_PARSE_ERROR_OFFSET	= 129;		/// Parse Error offset.
const uint OCI_ATTR_IS_TEMPORARY	= 130;		/// Whether table is temporary.
const uint OCI_ATTR_IS_TYPED		= 131;		/// Whether table is typed.
const uint OCI_ATTR_DURATION		= 132;		/// Duration of temporary table.
const uint OCI_ATTR_IS_INVOKER_RIGHTS	= 133;		/// Is invoker rights.
const uint OCI_ATTR_OBJ_NAME		= 134;		/// Top level schema obj name.
const uint OCI_ATTR_OBJ_SCHEMA		= 135;		/// Schema name.
const uint OCI_ATTR_OBJ_ID		= 136;		/// Top level schema object id.

const uint OCI_ATTR_TRANS_TIMEOUT	= 142;		/// Transaction timeout.
const uint OCI_ATTR_SERVER_STATUS	= 143;		/// State of the server handle.
const uint OCI_ATTR_STATEMENT		= 144;		/// Statement txt in stmt hdl.

const uint OCI_ATTR_DEQCOND		= 146;		/// Dequeue condition.
const uint OCI_ATTR_RESERVED_2		= 147;		/// Reserved.


const uint OCI_ATTR_SUBSCR_RECPT	= 148;		/// Recepient of subscription.
const uint OCI_ATTR_SUBSCR_RECPTPROTO	= 149;		/// Protocol for recepient.

const uint OCI_ATTR_LDAP_HOST		= 153;		/// LDAP host to connect to.
const uint OCI_ATTR_LDAP_PORT		= 154;		/// LDAP port to connect to.
const uint OCI_ATTR_BIND_DN		= 155;		/// Bind DN.
const uint OCI_ATTR_LDAP_CRED		= 156;		/// Credentials to connect to LDAP.
const uint OCI_ATTR_WALL_LOC		= 157;		/// Client wallet location.
const uint OCI_ATTR_LDAP_AUTH		= 158;		/// LDAP authentication method.
const uint OCI_ATTR_LDAP_CTX		= 159;		/// LDAP adminstration context DN.
const uint OCI_ATTR_SERVER_DNS		= 160;		/// List of registration server DNs.

const uint OCI_ATTR_DN_COUNT		= 161;		/// The number of server DNs.
const uint OCI_ATTR_SERVER_DN		= 162;		/// Server DN attribute.

const uint OCI_ATTR_MAXCHAR_SIZE	= 163;		/// Max char size of data.

const uint OCI_ATTR_CURRENT_POSITION	= 164;		/// For scrollable result sets.

const uint OCI_ATTR_RESERVED_3		= 165;		/// Reserved.
const uint OCI_ATTR_RESERVED_4		= 166;		/// Reserved.

const uint OCI_ATTR_DIGEST_ALGO		= 168;		/// Digest algorithm.
const uint OCI_ATTR_CERTIFICATE		= 169;		/// Certificate.
const uint OCI_ATTR_SIGNATURE_ALGO	= 170;		/// Signature algorithm.
const uint OCI_ATTR_CANONICAL_ALGO	= 171;		/// Canonicalization algo..
const uint OCI_ATTR_PRIVATE_KEY		= 172;		/// Private key.
const uint OCI_ATTR_DIGEST_VALUE	= 173;		/// Digest value.
const uint OCI_ATTR_SIGNATURE_VAL	= 174;		/// Signature value.
const uint OCI_ATTR_SIGNATURE		= 175;		/// Signature.

const uint OCI_ATTR_STMTCACHESIZE	= 176;		/// Size of the stm cache.

const uint OCI_ATTR_CONN_NOWAIT		= 178;		///
const uint OCI_ATTR_CONN_BUSY_COUNT	= 179;		///
const uint OCI_ATTR_CONN_OPEN_COUNT	= 180;		///
const uint OCI_ATTR_CONN_TIMEOUT	= 181;		///
const uint OCI_ATTR_STMT_STATE		= 182;		///
const uint OCI_ATTR_CONN_MIN		= 183;		///
const uint OCI_ATTR_CONN_MAX		= 184;		///
const uint OCI_ATTR_CONN_INCR		= 185;		///

const uint OCI_ATTR_NUM_OPEN_STMTS	= 188;		/// Open stmts in session.
const uint OCI_ATTR_DESCRIBE_NATIVE	= 189;		/// Get native info via desc.

const uint OCI_ATTR_BIND_COUNT		= 190;		/// Number of bind postions.
const uint OCI_ATTR_HANDLE_POSITION	= 191;		/// Position of bind/define handle.
const uint OCI_ATTR_RESERVED_5		= 192;		/// Reserved.
const uint OCI_ATTR_SERVER_BUSY		= 193;		/// Call in progress on server.

const uint OCI_ATTR_SUBSCR_RECPTPRES	= 195;		///
const uint OCI_ATTR_TRANSFORMATION	= 196;		/// AQ message transformation.

const uint OCI_ATTR_ROWS_FETCHED	= 197;		/// Rows fetched in last call.

const uint OCI_ATTR_SCN_BASE		= 198;		/// Snapshot base.
const uint OCI_ATTR_SCN_WRAP		= 199;		/// Snapshot wrap.

const uint OCI_ATTR_RESERVED_6		= 200;		/// Reserved.
const uint OCI_ATTR_READONLY_TXN	= 201;		/// Txn is readonly.
const uint OCI_ATTR_RESERVED_7		= 202;		/// Reserved.
const uint OCI_ATTR_ERRONEOUS_COLUMN	= 203;		/// Position of erroneous col.
const uint OCI_ATTR_RESERVED_8		= 204;		/// Reserved.

const uint OCI_ATTR_INST_TYPE		= 207;		/// Oracle instance type.

const uint OCI_ATTR_ENV_UTF16		= 209;		/// Is env in UTF16 mode?
const uint OCI_ATTR_RESERVED_9		= 210;		/// Reserved for TMZ.
const uint OCI_ATTR_RESERVED_10		= 211;		/// Reserved.

const uint OCI_ATTR_RESERVED_12		= 214;		/// Reserved.
const uint OCI_ATTR_RESERVED_13		= 215;		/// Reserved.
const uint OCI_ATTR_IS_EXTERNAL		= 216;		/// Whether table is external.

const uint OCI_ATTR_RESERVED_15		= 217;		/// Reserved.
const uint OCI_ATTR_STMT_IS_RETURNING	= 218;		/// Stmt has returning clause.
const uint OCI_ATTR_RESERVED_16		= 219;		/// Reserved.
const uint OCI_ATTR_RESERVED_17		= 220;		/// Reserved.
const uint OCI_ATTR_RESERVED_18		= 221;		/// Reserved.

const uint OCI_ATTR_RESERVED_19		= 222;		/// Reserved.
const uint OCI_ATTR_RESERVED_20		= 223;		/// Reserved.
const uint OCI_ATTR_CURRENT_SCHEMA	= 224;		/// Current Schema.

const uint OCI_ATTR_SUBSCR_QOSFLAGS	= 225;		/// QOS flags.
const uint OCI_ATTR_SUBSCR_PAYLOADCBK	= 226;		/// Payload callback.
const uint OCI_ATTR_SUBSCR_TIMEOUT	= 227;		/// Timeout.
const uint OCI_ATTR_SUBSCR_NAMESPACE_CTX= 228;		/// Namespace context.

const uint OCI_ATTR_BIND_ROWCBK		= 301;		/// Bind row callback.
const uint OCI_ATTR_BIND_ROWCTX		= 302;		/// Ctx for bind row callback.
const uint OCI_ATTR_SKIP_BUFFER		= 303;		/// Skip buffer in array ops.

const uint OCI_ATTR_EVTCBK		= 304;		/// Ha callback.
const uint OCI_ATTR_EVTCTX		= 305;		/// Ctx for ha callback.

const uint OCI_ATTR_USER_MEMORY		= 306;		/// Pointer to user memory.

const uint OCI_ATTR_SUBSCR_PORTNO	= 390;		/// Port no to listen.

const uint OCI_ATTR_CHNF_TABLENAMES	= 401;		/// Out: array of table names.
const uint OCI_ATTR_CHNF_ROWIDS		= 402;		/// In: rowids needed.
const uint OCI_ATTR_CHNF_OPERATIONS	= 403;		/// In: notification operation filter.
const uint OCI_ATTR_CHNF_CHANGELAG	= 404;		/// Txn lag between notifications.

const uint OCI_ATTR_CHDES_DBNAME	= 405;		/// Source database.
const uint OCI_ATTR_CHDES_NFYTYPE	= 406;		/// Notification type flags.
const uint OCI_ATTR_CHDES_XID		= 407;		/// XID  of the transaction.
const uint OCI_ATTR_CHDES_TABLE_CHANGES	= 408;		/// Array of table chg descriptors.

const uint OCI_ATTR_CHDES_TABLE_NAME	= 409;		/// Table name.
const uint OCI_ATTR_CHDES_TABLE_OPFLAGS	= 410;		/// Table operation flags.
const uint OCI_ATTR_CHDES_TABLE_ROW_CHANGES = 411;	/// Array of changed rows.
const uint OCI_ATTR_CHDES_ROW_ROWID	= 412;		/// Rowid of changed row.
const uint OCI_ATTR_CHDES_ROW_OPFLAGS	= 413;		/// Row operation flags.

const uint OCI_ATTR_CHNF_REGHANDLE	= 414;		/// IN: subscription handle.
const uint OCI_ATTR_RESERVED_21		= 415;		/// Reserved.
const uint OCI_ATTR_PROXY_CLIENT	= 416;		///

const uint OCI_ATTR_TABLE_ENC		= 417;		/// Does table have any encrypt columns.
const uint OCI_ATTR_TABLE_ENC_ALG	= 418;		/// Table encryption Algorithm.
const uint OCI_ATTR_TABLE_ENC_ALG_ID	= 419;		/// Internal Id of encryption Algorithm.

const uint OCI_ATTR_ENV_CHARSET_ID	= OCI_ATTR_CHARSET_ID; /// Charset id in env.
const uint OCI_ATTR_ENV_NCHARSET_ID	= OCI_ATTR_NCHARSET_ID; /// Ncharset id in env.

const uint OCI_EVENT_NONE		= 0x0;		/// None.
const uint OCI_EVENT_STARTUP		= 0x1;		/// Startup database.
const uint OCI_EVENT_SHUTDOWN		= 0x2;		/// Shutdown database.
const uint OCI_EVENT_SHUTDOWN_ANY	= 0x3;		/// Startup instance.
const uint OCI_EVENT_DROP_DB		= 0x4;		/// Drop database   .
const uint OCI_EVENT_DEREG		= 0x5;		/// Subscription deregistered.
const uint OCI_EVENT_OBJCHANGE		= 0x6;		/// Object change notification.

const uint OCI_OPCODE_ALLOPS		= 0x0;		/// Interested in all operations.
const uint OCI_OPCODE_ALLROWS		= 0x1;		/// All rows invalidated .
const uint OCI_OPCODE_INSERT		= 0x2;		/// INSERT.
const uint OCI_OPCODE_UPDATE		= 0x4;		/// UPDATE.
const uint OCI_OPCODE_DELETE		= 0x8;		/// DELETE.
const uint OCI_OPCODE_ALTER		= 0x10;		/// ALTER.
const uint OCI_OPCODE_DROP		= 0x20;		/// DROP TABLE.
const uint OCI_OPCODE_UNKNOWN		= 0x40;		/// GENERIC/ UNKNOWN.

const uint OCI_SUBSCR_PROTO_OCI		= 0;		/// OCI.
const uint OCI_SUBSCR_PROTO_MAIL	= 1;		/// Mail.
const uint OCI_SUBSCR_PROTO_SERVER	= 2;		/// Server.
const uint OCI_SUBSCR_PROTO_HTTP	= 3;		/// HTTP.
const uint OCI_SUBSCR_PROTO_MAX		= 4;		/// Max current protocols.
const uint OCI_SUBSCR_PRES_DEFAULT	= 0;		/// Default.
const uint OCI_SUBSCR_PRES_XML		= 1;		/// XML.
const uint OCI_SUBSCR_PRES_MAX		= 2;		/// Max current presentations.
const uint OCI_SUBSCR_QOS_RELIABLE	= 0x01;		/// Reliable.
const uint OCI_SUBSCR_QOS_PAYLOAD	= 0x02;		/// Payload delivery.
const uint OCI_SUBSCR_QOS_REPLICATE	= 0x04;		/// Replicate to director.
const uint OCI_SUBSCR_QOS_SECURE	= 0x08;		/// Secure payload delivery.
const uint OCI_SUBSCR_QOS_PURGE_ON_NTFN	= 0x10;		/// Purge on first ntfn.
const uint OCI_SUBSCR_QOS_MULTICBK	= 0x20;		/// Multi instance callback.

const uint OCI_UCS2ID			= 1000;		/// UCS2 charset ID.
const uint OCI_UTF16ID			= 1000;		/// UTF16 charset ID.

const uint OCI_SERVER_NOT_CONNECTED	= 0x0;		///
const uint OCI_SERVER_NORMAL		= 0x1;		///

const uint OCI_SUBSCR_NAMESPACE_ANONYMOUS = 0;		/// Anonymous Namespace.
const uint OCI_SUBSCR_NAMESPACE_AQ	= 1;		/// Advanced Queues.
const uint OCI_SUBSCR_NAMESPACE_DBCHANGE= 2;		/// Change notification.
const uint OCI_SUBSCR_NAMESPACE_MAX	= 3;		/// Max Name Space Number.

const uint OCI_CRED_RDBMS		= 1;		/// Database username/password.
const uint OCI_CRED_EXT			= 2;		/// Externally provided credentials.
const uint OCI_CRED_PROXY		= 3;		/// Proxy authentication.
const uint OCI_CRED_RESERVED_1		= 4;		/// Reserved.
const uint OCI_CRED_RESERVED_2		= 5;		/// Reserved.

const uint OCI_SUCCESS			= 0;		/// Maps to SQL_SUCCESS of SAG CLI.
const uint OCI_SUCCESS_WITH_INFO	= 1;		/// Maps to SQL_SUCCESS_WITH_INFO.
const uint OCI_RESERVED_FOR_INT_USE	= 200;		/// Reserved.
const uint OCI_NO_DATA			= 100;		/// Maps to SQL_NO_DATA.
const int OCI_ERROR			= -1;		/// Maps to SQL_ERROR.
const int OCI_INVALID_HANDLE		= -2;		/// Maps to SQL_INVALID_HANDLE.
const uint OCI_NEED_DATA		= 99;		/// Maps to SQL_NEED_DATA.
const int OCI_STILL_EXECUTING		= -3123;	/// OCI would block error.

const int OCI_CONTINUE			= -24200;	/// Continue with the body of the OCI function.
const int OCI_ROWCBK_DONE		= -24201;	/// Done with user row callback.

const uint OCI_DT_INVALID_DAY		= 0x1;		/// Bad day.
const uint OCI_DT_DAY_BELOW_VALID	= 0x2;		/// Bad DAy Low/high bit (1=low).
const uint OCI_DT_INVALID_MONTH		= 0x4;		/// Bad MOnth.
const uint OCI_DT_MONTH_BELOW_VALID	= 0x8;		/// Bad MOnth Low/high bit (1=low).
const uint OCI_DT_INVALID_YEAR		= 0x10;		/// Bad YeaR.
const uint OCI_DT_YEAR_BELOW_VALID	= 0x20;		/// Bad YeaR Low/high bit (1=low).
const uint OCI_DT_INVALID_HOUR		= 0x40;		/// Bad HouR.
const uint OCI_DT_HOUR_BELOW_VALID	= 0x80;		/// Bad HouR Low/high bit (1=low).
const uint OCI_DT_INVALID_MINUTE	= 0x100;	/// Bad MiNute.
const uint OCI_DT_MINUTE_BELOW_VALID	= 0x200;	/// Bad MiNute Low/high bit (1=low).
const uint OCI_DT_INVALID_SECOND	= 0x400;	/// Bad SeCond.
const uint OCI_DT_SECOND_BELOW_VALID	= 0x800;	/// Bad second Low/high bit (1=low).
const uint OCI_DT_DAY_MISSING_FROM_1582	= 0x1000;	/// Day is one of those "missing" from 1582.
const uint OCI_DT_YEAR_ZERO		= 0x2000;	/// Year may not equal zero.
const uint OCI_DT_INVALID_TIMEZONE	= 0x4000;	/// Bad Timezone.
const uint OCI_DT_INVALID_FORMAT	= 0x8000;	/// Bad date format input.

const uint OCI_INTER_INVALID_DAY	= 0x1;		/// Bad day.
const uint OCI_INTER_DAY_BELOW_VALID	= 0x2;		/// Bad DAy Low/high bit (1=low).
const uint OCI_INTER_INVALID_MONTH	= 0x4;		/// Bad MOnth.
const uint OCI_INTER_MONTH_BELOW_VALID	= 0x8;		/// Bad MOnth Low/high bit (1=low).
const uint OCI_INTER_INVALID_YEAR	= 0x10;		/// Bad YeaR.
const uint OCI_INTER_YEAR_BELOW_VALID	= 0x20;		/// Bad YeaR Low/high bit (1=low).
const uint OCI_INTER_INVALID_HOUR	= 0x40;		/// Bad HouR.
const uint OCI_INTER_HOUR_BELOW_VALID	= 0x80;		/// Bad HouR Low/high bit (1=low).
const uint OCI_INTER_INVALID_MINUTE	= 0x100;	/// Bad MiNute.
const uint OCI_INTER_MINUTE_BELOW_VALID	= 0x200;	/// Bad MiNute Low/high bit(1=low).
const uint OCI_INTER_INVALID_SECOND	= 0x400;	/// Bad SeCond.
const uint OCI_INTER_SECOND_BELOW_VALID	= 0x800;	/// Bad second Low/high bit(1=low).
const uint OCI_INTER_INVALID_FRACSEC	= 0x1000;	/// Bad Fractional second.
const uint OCI_INTER_FRACSEC_BELOW_VALID= 0x2000;	/// Bad fractional second Low/High.

const uint OCI_V7_SYNTAX		= 2;		/// V815 language - for backwards compatibility.
const uint OCI_V8_SYNTAX		= 3;		/// V815 language - for backwards compatibility.
const uint OCI_NTV_SYNTAX		= 1;		/// Use whatever is the native lang of server.

const uint OCI_FETCH_CURRENT		= 0x00000001;	/// Refetching current position .
const uint OCI_FETCH_NEXT		= 0x00000002;	/// Next row.
const uint OCI_FETCH_FIRST		= 0x00000004;	/// First row of the result set.
const uint OCI_FETCH_LAST		= 0x00000008;	/// The last row of the result set.
const uint OCI_FETCH_PRIOR		= 0x00000010;	/// Previous row relative to current.
const uint OCI_FETCH_ABSOLUTE		= 0x00000020;	/// Absolute offset from first.
const uint OCI_FETCH_RELATIVE		= 0x00000040;	/// Offset relative to current.
const uint OCI_FETCH_RESERVED_1		= 0x00000080;	/// Reserved.
const uint OCI_FETCH_RESERVED_2		= 0x00000100;	/// Reserved.
const uint OCI_FETCH_RESERVED_3		= 0x00000200;	/// Reserved.
const uint OCI_FETCH_RESERVED_4		= 0x00000400;	/// Reserved.
const uint OCI_FETCH_RESERVED_5		= 0x00000800;	/// Reserved.

const uint OCI_SB2_IND_PTR		= 0x00000001;	/// Unused.
const uint OCI_DATA_AT_EXEC		= 0x00000002;	/// Fata at execute time.
const uint OCI_DYNAMIC_FETCH		= 0x00000002;	/// Detch dynamically.
const uint OCI_PIECEWISE		= 0x00000004;	/// Piecewise DMLs or fetch.
const uint OCI_DEFINE_RESERVED_1	= 0x00000008;	/// Reserved.
const uint OCI_BIND_RESERVED_2		= 0x00000010;	/// Reserved.
const uint OCI_DEFINE_RESERVED_2	= 0x00000020;	/// Reserved.
const uint OCI_BIND_SOFT		= 0x00000040;	/// Soft bind or define.
const uint OCI_DEFINE_SOFT		= 0x00000080;	/// Soft bind or define.
const uint OCI_BIND_RESERVED_3		= 0x00000100;	/// Reserved.

const uint OCI_DEFAULT			= 0x00000000;	/// The default value for parameters and attributes.
const uint OCI_THREADED			= 0x00000001;	/// Application is in threaded environment.
const uint OCI_OBJECT			= 0x00000002;	/// Application is in object environment.
const uint OCI_EVENTS			= 0x00000004;	/// Application is enabled for events.
const uint OCI_RESERVED1		= 0x00000008;	/// Reserved.
const uint OCI_SHARED			= 0x00000010;	/// The application is in shared mode.
const uint OCI_RESERVED2		= 0x00000020;	/// Reserved.

const uint OCI_NO_UCB			= 0x00000040;	/// No user callback called during ini.
const uint OCI_NO_MUTEX			= 0x00000080;	/// The environment handle will not be protected by a mutex internally.
const uint OCI_SHARED_EXT		= 0x00000100;	/// Used for shared forms.
const uint OCI_ALWAYS_BLOCKING		= 0x00000400;	/// All connections always blocking.
const uint OCI_USE_LDAP			= 0x00001000;	/// Allow  LDAP connections.
const uint OCI_REG_LDAPONLY		= 0x00002000;	/// Only register to LDAP.
const uint OCI_UTF16			= 0x00004000;	/// Mode for all UTF16 metadata.
const uint OCI_AFC_PAD_ON		= 0x00008000;	/// Turn on AFC blank padding when rlenp present.
const uint OCI_ENVCR_RESERVED3		= 0x00010000;	/// Reserved.
const uint OCI_NEW_LENGTH_SEMANTICS	= 0x00020000;	/// Adopt new length semantics.
const uint OCI_NO_MUTEX_STMT		= 0x00040000;	/// Do not mutex stmt handle.
const uint OCI_MUTEX_ENV_ONLY		= 0x00080000;	/// Mutex only the environment handle.
const uint OCI_STM_RESERVED4		= 0x00100000;	/// Reserved.
const uint OCI_MUTEX_TRY		= 0x00200000;	/// Try to acquire mutex.
const uint OCI_NCHAR_LITERAL_REPLACE_ON	= 0x00400000;	/// Nchar literal replace on.
const uint OCI_NCHAR_LITERAL_REPLACE_OFF= 0x00800000;	/// Nchar literal replace off.
const uint OCI_SRVATCH_RESERVED5	= 0x01000000;	/// Reserved.

const uint OCI_CPOOL_REINITIALIZE	= 0x111;	///

const uint OCI_LOGON2_SPOOL		= 0x0001;	/// Use session pool.
const uint OCI_LOGON2_CPOOL		= OCI_CPOOL;	/// Use connection pool.
const uint OCI_LOGON2_STMTCACHE		= 0x0004;	/// Use Stmt Caching.
const uint OCI_LOGON2_PROXY		= 0x0008;	/// Proxy authentiaction.

const uint OCI_SPC_REINITIALIZE		= 0x0001;	/// Reinitialize the session pool.
const uint OCI_SPC_HOMOGENEOUS		= 0x0002;	/// Session pool is homogeneneous.
const uint OCI_SPC_STMTCACHE		= 0x0004;	/// Session pool has stmt cache.

const uint OCI_SESSGET_SPOOL		= 0x0001;	/// SessionGet called in SPOOL mode.
const uint OCI_SESSGET_CPOOL		= OCI_CPOOL;	/// SessionGet called in CPOOL mode.
const uint OCI_SESSGET_STMTCACHE	= 0x0004;	/// Use statement cache.
const uint OCI_SESSGET_CREDPROXY	= 0x0008;	/// SessionGet called in proxy mode.
const uint OCI_SESSGET_CREDEXT		= 0x0010;	///
const uint OCI_SESSGET_SPOOL_MATCHANY	= 0x0020;	///

const uint OCI_SPOOL_ATTRVAL_WAIT	= 0;		/// Block till you get a session.
const uint OCI_SPOOL_ATTRVAL_NOWAIT	= 1;		/// Error out if no session avaliable.
const uint OCI_SPOOL_ATTRVAL_FORCEGET	= 2;		/// Get session even if max is exceeded.

const uint OCI_SESSRLS_DROPSESS		= 0x0001;	/// Drop the Session.
const uint OCI_SESSRLS_RETAG		= 0x0002;	/// Retag the session.

const uint OCI_SPD_FORCE		= 0x0001;	/// Force the sessions to terminate.

const uint OCI_STMT_STATE_INITIALIZED	= 0x0001;	///
const uint OCI_STMT_STATE_EXECUTED	= 0x0002;	///
const uint OCI_STMT_STATE_END_OF_FETCH	= 0x0003;	///

const uint OCI_MEM_INIT			= 0x01;		///
const uint OCI_MEM_CLN			= 0x02;		///
const uint OCI_MEM_FLUSH		= 0x04;		///
const uint OCI_DUMP_HEAP		= 0x80;		///

const uint OCI_CLIENT_STATS		= 0x10;		///
const uint OCI_SERVER_STATS		= 0x20;		///

deprecated const uint OCI_ENV_NO_UCB	= 0x01;		/// A user callback will not be called in OCIEnvInit().
deprecated const uint OCI_ENV_NO_MUTEX	= 0x08;		/// The environment handle will not be protected by a mutex internally.

const uint OCI_NO_SHARING		= 0x01;		/// Turn off statement handle sharing.
const uint OCI_PREP_RESERVED_1		= 0x02;		/// Reserved.
const uint OCI_PREP_AFC_PAD_ON		= 0x04;		/// Turn on blank padding for AFC.
const uint OCI_PREP_AFC_PAD_OFF		= 0x08;		/// Turn off blank padding for AFC.

const uint OCI_BATCH_MODE		= 0x01;		/// Batch the oci statement for execution.
const uint OCI_EXACT_FETCH		= 0x02;		/// Fetch the exact rows specified.
const uint OCI_STMT_SCROLLABLE_READONLY	= 0x08;		/// If result set is scrollable.
const uint OCI_DESCRIBE_ONLY		= 0x10;		/// Only describe the statement.
const uint OCI_COMMIT_ON_SUCCESS	= 0x20;		/// Commit, if successful execution.
const uint OCI_NON_BLOCKING		= 0x40;		/// Non-blocking.
const uint OCI_BATCH_ERRORS		= 0x80;		/// Batch errors in array dmls.
const uint OCI_PARSE_ONLY		= 0x100;	/// Only parse the statement.
const uint OCI_EXACT_FETCH_RESERVED_1	= 0x200;	/// Reserved.
const uint OCI_SHOW_DML_WARNINGS	= 0x400;	/// Return OCI_SUCCESS_WITH_INFO for delete/update w/no where clause.
const uint OCI_EXEC_RESERVED_2		= 0x800;	/// Reserved.
const uint OCI_DESC_RESERVED_1		= 0x1000;	/// Reserved.
const uint OCI_EXEC_RESERVED_3		= 0x2000;	/// Reserved.
const uint OCI_EXEC_RESERVED_4		= 0x4000;	/// Reserved.
const uint OCI_EXEC_RESERVED_5		= 0x8000;	/// Reserved.

const uint OCI_MIGRATE			= 0x00000001;	/// Migratable auth context.
const uint OCI_SYSDBA			= 0x00000002;	/// For SYSDBA authorization.
const uint OCI_SYSOPER			= 0x00000004;	/// For SYSOPER authorization.
const uint OCI_PRELIM_AUTH		= 0x00000008;	/// For preliminary authorization.
const uint OCIP_ICACHE			= 0x00000010;	/// Private OCI cache mode.
const uint OCI_AUTH_RESERVED_1		= 0x00000020;	/// Reserved.
const uint OCI_STMT_CACHE		= 0x00000040;	/// Enable OCI Stmt Caching.
const uint OCI_STATELESS_CALL		= 0x00000080;	/// Stateless at call boundary.
const uint OCI_STATELESS_TXN		= 0x00000100;	/// Stateless at txn boundary.
const uint OCI_STATELESS_APP		= 0x00000200;	/// Stateless at user-specified pts.
const uint OCI_AUTH_RESERVED_2		= 0x00000400;	/// Reserved.
const uint OCI_AUTH_RESERVED_3		= 0x00000800;	/// Reserved.
const uint OCI_AUTH_RESERVED_4		= 0x00001000;	/// Reserved.
const uint OCI_AUTH_RESERVED_5		= 0x00002000;	/// Reserved.

const uint OCI_SESSEND_RESERVED_1	= 0x0001;	/// Reserved.
const uint OCI_SESSEND_RESERVED_2	= 0x0002;	/// Reserved.

const uint OCI_FASTPATH			= 0x0010;	/// Attach in fast path mode.
const uint OCI_ATCH_RESERVED_1		= 0x0020;	/// Reserved.
const uint OCI_ATCH_RESERVED_2		= 0x0080;	/// Reserved.
const uint OCI_ATCH_RESERVED_3		= 0x0100;	/// Reserved.
const uint OCI_CPOOL			= 0x0200;	/// Attach using server handle from pool.
const uint OCI_ATCH_RESERVED_4		= 0x0400;	/// Reserved.
const uint OCI_ATCH_RESERVED_5		= 0x2000;	/// Reserved.

const uint OCI_PREP2_CACHE_SEARCHONLY	= 0x0010;	/// Only search.
const uint OCI_PREP2_GET_PLSQL_WARNINGS	= 0x0020;	/// Get PL/SQL warnings .
const uint OCI_PREP2_RESERVED_1		= 0x0040;	/// Reserved.

const uint OCI_STRLS_CACHE_DELETE	= 0x0010;	/// Delete from Cache.

const uint OCI_PARAM_IN			= 0x01;		/// In parameter.
const uint OCI_PARAM_OUT		= 0x02;		/// Out parameter.

const uint OCI_TRANS_NEW		= 0x00000001;	/// Starts a new transaction branch.
const uint OCI_TRANS_JOIN		= 0x00000002;	/// Join an existing transaction.
const uint OCI_TRANS_RESUME		= 0x00000004;	/// Resume this transaction.
const uint OCI_TRANS_STARTMASK		= 0x000000ff;	///

const uint OCI_TRANS_READONLY		= 0x00000100;	/// Starts a readonly transaction.
const uint OCI_TRANS_READWRITE		= 0x00000200;	/// Starts a read-write transaction.
const uint OCI_TRANS_SERIALIZABLE	= 0x00000400;	/// Starts a serializable transaction.
const uint OCI_TRANS_ISOLMASK		= 0x0000ff00;	///

const uint OCI_TRANS_LOOSE		= 0x00010000;	/// A loosely coupled branch.
const uint OCI_TRANS_TIGHT		= 0x00020000;	/// A tightly coupled branch.
const uint OCI_TRANS_TYPEMASK		= 0x000f0000;	///

const uint OCI_TRANS_NOMIGRATE		= 0x00100000;	/// Non migratable transaction.
const uint OCI_TRANS_SEPARABLE		= 0x00200000;	/// Separable transaction (8.1.6+).
const uint OCI_TRANS_OTSRESUME		= 0x00400000;	/// OTS resuming a transaction.

const uint OCI_TRANS_TWOPHASE		= 0x01000000;	/// Use two phase commit.
const uint OCI_TRANS_WRITEBATCH		= 0x00000001;	/// Force cmt-redo for local txns.
const uint OCI_TRANS_WRITEIMMED		= 0x00000002;	/// No force cmt-redo.
const uint OCI_TRANS_WRITEWAIT		= 0x00000004;	/// No sync cmt-redo.
const uint OCI_TRANS_WRITENOWAIT	= 0x00000008;	/// Sync cmt-redo for local txns.

const uint OCI_ENQ_IMMEDIATE		= 1;		/// Enqueue is an independent transaction.
const uint OCI_ENQ_ON_COMMIT		= 2;		/// Enqueue is part of current transaction.

const uint OCI_DEQ_BROWSE		= 1;		/// Read message without acquiring a lock.
const uint OCI_DEQ_LOCKED		= 2;		/// Read and obtain write lock on message.
const uint OCI_DEQ_REMOVE		= 3;		/// Read the message and delete it.
const uint OCI_DEQ_REMOVE_NODATA	= 4;		/// Delete message w'o returning payload.
const uint OCI_DEQ_GETSIG		= 5;		/// Get signature only.

const uint OCI_DEQ_FIRST_MSG		= 1;		/// Get first message at head of queue.
const uint OCI_DEQ_NEXT_MSG		= 3;		/// Next message that is available.
const uint OCI_DEQ_NEXT_TRANSACTION	= 2;		/// Get first message of next txn group.
const uint OCI_DEQ_MULT_TRANSACTION	= 5;		/// Array dequeue across txn groups.

const uint OCI_DEQ_RESERVED_1		= 0x000001;	///

const uint OCI_MSG_WAITING		= 1;		/// The message delay has not yet completed.
const uint OCI_MSG_READY		= 0;		/// The message is ready to be processed.
const uint OCI_MSG_PROCESSED		= 2;		/// The message has been processed.
const uint OCI_MSG_EXPIRED		= 3;		/// Message has moved to exception queue.

const uint OCI_ENQ_BEFORE		= 2;		/// Enqueue message before another message.
const uint OCI_ENQ_TOP			= 3;		/// Enqueue message before all messages.

const uint OCI_DEQ_IMMEDIATE		= 1;		/// Dequeue is an independent transaction.
const uint OCI_DEQ_ON_COMMIT		= 2;		/// Dequeue is part of current transaction.

const int OCI_DEQ_WAIT_FOREVER		= -1;		/// Wait forever if no message available.
const uint OCI_DEQ_NO_WAIT		= 0;		/// Do not wait if no message is available.

const uint OCI_MSG_NO_DELAY		= 0;		/// Message is available immediately.

const int OCI_MSG_NO_EXPIRATION		= -1;		/// Message will never expire.
const uint OCI_MSG_PERSISTENT_OR_BUFFERED = 3;		///
const uint OCI_MSG_BUFFERED		= 2;		///
const uint OCI_MSG_PERSISTENT		= 1;		///

const uint OCI_AQ_RESERVED_1		= 0x0002;	///
const uint OCI_AQ_RESERVED_2		= 0x0004;	///
const uint OCI_AQ_RESERVED_3		= 0x0008;	///
const uint OCI_AQ_RESERVED_4		= 0x0010;	///

deprecated const uint OCI_OTYPE_UNK	= 0;		///
deprecated const uint OCI_OTYPE_TABLE	= 1;		///
deprecated const uint OCI_OTYPE_VIEW	= 2;		///
deprecated const uint OCI_OTYPE_SYN	= 3;		///
deprecated const uint OCI_OTYPE_PROC	= 4;		///
deprecated const uint OCI_OTYPE_FUNC	= 5;		///
deprecated const uint OCI_OTYPE_PKG	= 6;		///
deprecated const uint OCI_OTYPE_STMT	= 7;		///

const uint OCI_ATTR_DATA_SIZE		= 1;		/// Maximum size of the data.
const uint OCI_ATTR_DATA_TYPE		= 2;		/// The SQL type of the column/argument.
const uint OCI_ATTR_DISP_SIZE		= 3;		/// The display size.
const uint OCI_ATTR_NAME		= 4;		/// The name of the column/argument.
const uint OCI_ATTR_PRECISION		= 5;		/// Precision if number type.
const uint OCI_ATTR_SCALE		= 6;		/// Scale if number type.
const uint OCI_ATTR_IS_NULL		= 7;		/// Is it null?
const uint OCI_ATTR_TYPE_NAME		= 8;		/// Name of the named data type or a package name for package private types.
const uint OCI_ATTR_SCHEMA_NAME		= 9;		/// The schema name.
const uint OCI_ATTR_SUB_NAME		= 10;		/// Type name if package private type.
const uint OCI_ATTR_POSITION		= 11;		/// Relative position of col/arg in the list of cols/args.

const uint OCI_ATTR_COMPLEXOBJECTCOMP_TYPE = 50;	///
const uint OCI_ATTR_COMPLEXOBJECTCOMP_TYPE_LEVEL = 51;	///
const uint OCI_ATTR_COMPLEXOBJECT_LEVEL = 52;		///
const uint OCI_ATTR_COMPLEXOBJECT_COLL_OUTOFLINE = 53;	///

const uint OCI_ATTR_DISP_NAME		= 100;		/// The display name.
const uint OCI_ATTR_ENCC_SIZE		= 101;		/// Encrypted data size.
const uint OCI_ATTR_COL_ENC		= 102;		/// Column is encrypted?
const uint OCI_ATTR_COL_ENC_SALT	= 103;		/// Is encrypted column salted?

const uint OCI_ATTR_OVERLOAD		= 210;		/// Is this position overloaded.
const uint OCI_ATTR_LEVEL		= 211;		/// Level for structured types.
const uint OCI_ATTR_HAS_DEFAULT		= 212;		/// Has a default value.
const uint OCI_ATTR_IOMODE		= 213;		/// In, out inout.
const uint OCI_ATTR_RADIX		= 214;		/// Returns a radix.
const uint OCI_ATTR_NUM_ARGS		= 215;		/// Total number of arguments.

const uint OCI_ATTR_TYPECODE		= 216;		/// Object or collection.
const uint OCI_ATTR_COLLECTION_TYPECODE	= 217;		/// Varray or nested table.
const uint OCI_ATTR_VERSION		= 218;		/// User assigned version.
const uint OCI_ATTR_IS_INCOMPLETE_TYPE	= 219;		/// Is this an incomplete type.
const uint OCI_ATTR_IS_SYSTEM_TYPE	= 220;		/// A system type.
const uint OCI_ATTR_IS_PREDEFINED_TYPE	= 221;		/// A predefined type.
const uint OCI_ATTR_IS_TRANSIENT_TYPE	= 222;		/// A transient type.
const uint OCI_ATTR_IS_SYSTEM_GENERATED_TYPE = 223;	/// System generated type.
const uint OCI_ATTR_HAS_NESTED_TABLE	= 224;		/// Contains nested table attr.
const uint OCI_ATTR_HAS_LOB		= 225;		/// Has a lob attribute.
const uint OCI_ATTR_HAS_FILE		= 226;		/// Has a file attribute.
const uint OCI_ATTR_COLLECTION_ELEMENT	= 227;		/// Has a collection attribute.
const uint OCI_ATTR_NUM_TYPE_ATTRS	= 228;		/// Number of attribute types.
const uint OCI_ATTR_LIST_TYPE_ATTRS	= 229;		/// List of type attributes.
const uint OCI_ATTR_NUM_TYPE_METHODS	= 230;		/// Number of type methods.
const uint OCI_ATTR_LIST_TYPE_METHODS	= 231;		/// List of type methods.
const uint OCI_ATTR_MAP_METHOD		= 232;		/// Map method of type.
const uint OCI_ATTR_ORDER_METHOD	= 233;		/// Order method of type.

const uint OCI_ATTR_NUM_ELEMS		= 234;		/// Number of elements.

const uint OCI_ATTR_ENCAPSULATION	= 235;		/// Encapsulation level.
const uint OCI_ATTR_IS_SELFISH		= 236;		/// Method selfish.
const uint OCI_ATTR_IS_VIRTUAL		= 237;		/// Virtual.
const uint OCI_ATTR_IS_INLINE		= 238;		/// Inline.
const uint OCI_ATTR_IS_CONSTANT		= 239;		/// Constant.
const uint OCI_ATTR_HAS_RESULT		= 240;		/// Has result.
const uint OCI_ATTR_IS_CONSTRUCTOR	= 241;		/// Constructor.
const uint OCI_ATTR_IS_DESTRUCTOR	= 242;		/// Destructor.
const uint OCI_ATTR_IS_OPERATOR		= 243;		/// Operator.
const uint OCI_ATTR_IS_MAP		= 244;		/// A map method.
const uint OCI_ATTR_IS_ORDER		= 245;		/// Order method.
const uint OCI_ATTR_IS_RNDS		= 246;		/// Read no data state method.
const uint OCI_ATTR_IS_RNPS		= 247;		/// Read no process state.
const uint OCI_ATTR_IS_WNDS		= 248;		/// Write no data state method.
const uint OCI_ATTR_IS_WNPS		= 249;		/// Write no process state.

const uint OCI_ATTR_DESC_PUBLIC		= 250;		/// Public object.

const uint OCI_ATTR_CACHE_CLIENT_CONTEXT= 251;		///
const uint OCI_ATTR_UCI_CONSTRUCT	= 252;		///
const uint OCI_ATTR_UCI_DESTRUCT	= 253;		///
const uint OCI_ATTR_UCI_COPY		= 254;		///
const uint OCI_ATTR_UCI_PICKLE		= 255;		///
const uint OCI_ATTR_UCI_UNPICKLE	= 256;		///
const uint OCI_ATTR_UCI_REFRESH		= 257;		///

const uint OCI_ATTR_IS_SUBTYPE		= 258;		///
const uint OCI_ATTR_SUPERTYPE_SCHEMA_NAME = 259;	///
const uint OCI_ATTR_SUPERTYPE_NAME	= 260;		///

const uint OCI_ATTR_LIST_OBJECTS	= 261;		/// List of objects in schema.

const uint OCI_ATTR_NCHARSET_ID		= 262;		/// Char set id.
const uint OCI_ATTR_LIST_SCHEMAS	= 263;		/// List of schemas.
const uint OCI_ATTR_MAX_PROC_LEN	= 264;		/// Max procedure length.
const uint OCI_ATTR_MAX_COLUMN_LEN	= 265;		/// Max column name length.
const uint OCI_ATTR_CURSOR_COMMIT_BEHAVIOR = 266;	/// Cursor commit behavior.
const uint OCI_ATTR_MAX_CATALOG_NAMELEN	= 267;		/// Catalog namelength.
const uint OCI_ATTR_CATALOG_LOCATION	= 268;		/// Catalog location.
const uint OCI_ATTR_SAVEPOINT_SUPPORT	= 269;		/// Savepoint support.
const uint OCI_ATTR_NOWAIT_SUPPORT	= 270;		/// Nowait support.
const uint OCI_ATTR_AUTOCOMMIT_DDL	= 271;		/// Autocommit DDL.
const uint OCI_ATTR_LOCKING_MODE	= 272;		/// Locking mode.

const uint OCI_ATTR_APPCTX_SIZE		= 273;		/// Count of context to be init.
const uint OCI_ATTR_APPCTX_LIST		= 274;		/// Count of context to be init.
const uint OCI_ATTR_APPCTX_NAME		= 275;		/// Name of context to be init.
const uint OCI_ATTR_APPCTX_ATTR		= 276;		/// Attr of context to be init.
const uint OCI_ATTR_APPCTX_VALUE	= 277;		/// Value of context to be init.

const uint OCI_ATTR_CLIENT_IDENTIFIER	= 278;		/// Value of client id to set.

const uint OCI_ATTR_IS_FINAL_TYPE	= 279;		/// Is final type?
const uint OCI_ATTR_IS_INSTANTIABLE_TYPE= 280;		/// Is instantiable type?
const uint OCI_ATTR_IS_FINAL_METHOD	= 281;		/// Is final method?
const uint OCI_ATTR_IS_INSTANTIABLE_METHOD = 282;	/// Is instantiable method?
const uint OCI_ATTR_IS_OVERRIDING_METHOD= 283;		/// Is overriding method?

const uint OCI_ATTR_DESC_SYNBASE	= 284;		/// Describe the base object.

const uint OCI_ATTR_CHAR_USED		= 285;		/// Char length semantics.
const uint OCI_ATTR_CHAR_SIZE		= 286;		/// Char length.

const uint OCI_ATTR_IS_JAVA_TYPE	= 287;		/// Is Java implemented type ?.

const uint OCI_ATTR_DISTINGUISHED_NAME	= 300;		/// Use DN as user name.
const uint OCI_ATTR_KERBEROS_TICKET	= 301;		/// Kerberos ticket as cred..

const uint OCI_ATTR_ORA_DEBUG_JDWP	= 302;		/// ORA_DEBUG_JDWP attribute.

const uint OCI_ATTR_RESERVED_14		= 303;		/// Reserved.


const uint OCI_ATTR_SPOOL_TIMEOUT	= 308;		/// Session timeout.
const uint OCI_ATTR_SPOOL_GETMODE	= 309;		/// Session get mode.
const uint OCI_ATTR_SPOOL_BUSY_COUNT	= 310;		/// Busy session count.
const uint OCI_ATTR_SPOOL_OPEN_COUNT	= 311;		/// Open session count.
const uint OCI_ATTR_SPOOL_MIN		= 312;		/// Min session count.
const uint OCI_ATTR_SPOOL_MAX		= 313;		/// Max session count.
const uint OCI_ATTR_SPOOL_INCR		= 314;		/// Session increment count.
const uint OCI_ATTR_SPOOL_STMTCACHESIZE	= 208;		/// Stmt cache size of pool .

const uint OCI_ATTR_IS_XMLTYPE		= 315;		/// Is the type an XML type?.
const uint OCI_ATTR_XMLSCHEMA_NAME	= 316;		/// Name of XML Schema.
const uint OCI_ATTR_XMLELEMENT_NAME	= 317;		/// Name of XML Element.
const uint OCI_ATTR_XMLSQLTYPSCH_NAME	= 318;		/// SQL type's schema for XML Ele.
const uint OCI_ATTR_XMLSQLTYPE_NAME	= 319;		/// Name of SQL type for XML Ele.
const uint OCI_ATTR_XMLTYPE_STORED_OBJ	= 320;		/// XML type stored as object?.

const uint OCI_ATTR_HAS_SUBTYPES	= 321;		/// Has subtypes?.
const uint OCI_ATTR_NUM_SUBTYPES	= 322;		/// Number of subtypes.
const uint OCI_ATTR_LIST_SUBTYPES	= 323;		/// List of subtypes.

const uint OCI_ATTR_XML_HRCHY_ENABLED	= 324;		/// Hierarchy enabled?.

const uint OCI_ATTR_IS_OVERRIDDEN_METHOD= 325;		/// Method is overridden?.

const uint OCI_ATTR_OBJ_SUBS		= 336;		/// Obj col/tab substitutable.

const uint OCI_ATTR_XADFIELD_RESERVED_1	= 339;		/// Reserved.
const uint OCI_ATTR_XADFIELD_RESERVED_2	= 340;		/// Reserved.

const uint OCI_ATTR_KERBEROS_CID	= 341;		/// Kerberos db service ticket.

const uint OCI_ATTR_CONDITION		= 342;		/// Rule condition.
const uint OCI_ATTR_COMMENT		= 343;		/// Comment.
const uint OCI_ATTR_VALUE		= 344;		/// Anydata value.
const uint OCI_ATTR_EVAL_CONTEXT_OWNER	= 345;		/// Eval context owner.
const uint OCI_ATTR_EVAL_CONTEXT_NAME	= 346;		/// Eval context name.
const uint OCI_ATTR_EVALUATION_FUNCTION	= 347;		/// Eval function name.
const uint OCI_ATTR_VAR_TYPE		= 348;		/// Variable type.
const uint OCI_ATTR_VAR_VALUE_FUNCTION	= 349;		/// Variable value function.
const uint OCI_ATTR_VAR_METHOD_FUNCTION	= 350;		/// Variable method function.
const uint OCI_ATTR_ACTION_CONTEXT	= 351;		/// Action context.
const uint OCI_ATTR_LIST_TABLE_ALIASES	= 352;		/// List of table aliases.
const uint OCI_ATTR_LIST_VARIABLE_TYPES	= 353;		/// List of variable types.
const uint OCI_ATTR_TABLE_NAME		= 356;		/// Table name.

const uint OCI_ATTR_MESSAGE_CSCN	= 360;		/// Message cscn.
const uint OCI_ATTR_MESSAGE_DSCN	= 361;		/// Message dscn.

const uint OCI_ATTR_AUDIT_SESSION_ID	= 362;		/// Audit session ID.

const uint OCI_ATTR_KERBEROS_KEY	= 363;		/// N-tier Kerberos cred key.
const uint OCI_ATTR_KERBEROS_CID_KEY	= 364;		/// SCID Kerberos cred key.


const uint OCI_ATTR_TRANSACTION_NO	= 365;		/// AQ enq txn number.

const uint OCI_ATTR_MODULE		= 366;		/// Module for tracing.
const uint OCI_ATTR_ACTION		= 367;		/// Action for tracing.
const uint OCI_ATTR_CLIENT_INFO		= 368;		/// Client info.
const uint OCI_ATTR_COLLECT_CALL_TIME	= 369;		/// Collect call time.
const uint OCI_ATTR_CALL_TIME		= 370;		/// Extract call time.
const uint OCI_ATTR_ECONTEXT_ID		= 371;		/// Execution-id context.
const uint OCI_ATTR_ECONTEXT_SEQ	= 372;		/// Execution-id sequence num.

const uint OCI_ATTR_SESSION_STATE	= 373;		/// Session state.
const uint OCI_SESSION_STATELESS	= 1;		/// Valid states.
const uint OCI_SESSION_STATEFUL		= 2;		///

const uint OCI_ATTR_SESSION_STATETYPE	= 374;		/// Session state type.
const uint OCI_SESSION_STATELESS_DEF	= 0;		/// Valid state types.
const uint OCI_SESSION_STATELESS_CAL	= 1;		///
const uint OCI_SESSION_STATELESS_TXN	= 2;		///
const uint OCI_SESSION_STATELESS_APP	= 3;		///

const uint OCI_ATTR_SESSION_STATE_CLEARED = 376;	/// Session state cleared.
const uint OCI_ATTR_SESSION_MIGRATED	= 377;		/// Did session migrate.
const uint OCI_ATTR_SESSION_PRESERVE_STATE = 388;	/// Preserve session state.

const uint OCI_ATTR_ADMIN_PFILE		= 389;		/// Client-side param file.

const uint OCI_ATTR_HOSTNAME		= 390;		/// SYS_CONTEXT hostname.
const uint OCI_ATTR_DBNAME		= 391;		/// SYS_CONTEXT dbname.
const uint OCI_ATTR_INSTNAME		= 392;		/// SYS_CONTEXT instance name.
const uint OCI_ATTR_SERVICENAME		= 393;		/// SYS_CONTEXT service name.
const uint OCI_ATTR_INSTSTARTTIME	= 394;		/// Instance start time.
const uint OCI_ATTR_HA_TIMESTAMP	= 395;		/// Event time.
const uint OCI_ATTR_RESERVED_22		= 396;		/// Reserved.
const uint OCI_ATTR_RESERVED_23		= 397;		/// Reserved.
const uint OCI_ATTR_RESERVED_24		= 398;		/// Reserved.
const uint OCI_ATTR_DBDOMAIN		= 399;		/// Db domain.

const uint OCI_ATTR_EVENTTYPE		= 400;		/// Event type.
const uint OCI_EVENTTYPE_HA		= 0;		/// Valid value for OCI_ATTR_EVENTTYPE.

const uint OCI_ATTR_HA_SOURCE		= 401;		///

const uint OCI_HA_SOURCE_INSTANCE	= 0;		///
const uint OCI_HA_SOURCE_DATABASE	= 1;		///
const uint OCI_HA_SOURCE_NODE		= 2;		///
const uint OCI_HA_SOURCE_SERVICE	= 3;		///
const uint OCI_HA_SOURCE_SERVICE_MEMBER	= 4;		///
const uint OCI_HA_SOURCE_ASM_INSTANCE	= 5;		///
const uint OCI_HA_SOURCE_SERVICE_PRECONNECT = 6;	///

const uint OCI_ATTR_HA_STATUS		= 402;		///
const uint OCI_HA_STATUS_DOWN		= 0;		/// Valid values for OCI_ATTR_HA_STATUS.
const uint OCI_HA_STATUS_UP		= 1;		///

const uint OCI_ATTR_HA_SRVFIRST		= 403;		///

const uint OCI_ATTR_HA_SRVNEXT		= 404;		///

const uint OCI_ATTR_TAF_ENABLED		= 405;		///

const uint OCI_ATTR_NFY_FLAGS		= 406;		///

const uint OCI_ATTR_MSG_DELIVERY_MODE	= 407;		/// Msg delivery mode.
const uint OCI_ATTR_DB_CHARSET_ID	= 416;		/// Database charset ID.
const uint OCI_ATTR_DB_NCHARSET_ID	= 417;		/// Database ncharset ID.
const uint OCI_ATTR_RESERVED_25		= 418;		/// Reserved.

const uint OCI_DIRPATH_STREAM_VERSION_1	= 100;		///
const uint OCI_DIRPATH_STREAM_VERSION_2	= 200;		///
const uint OCI_DIRPATH_STREAM_VERSION_3	= 300;		/// Default.

const uint OCI_ATTR_DIRPATH_MODE	= 78;		/// Mode of direct path operation.
const uint OCI_ATTR_DIRPATH_NOLOG	= 79;		/// Nologging option.
const uint OCI_ATTR_DIRPATH_PARALLEL	= 80;		/// Parallel (temp seg) option.

const uint OCI_ATTR_DIRPATH_SORTED_INDEX= 137;		/// Index that data is sorted on.

const uint OCI_ATTR_DIRPATH_INDEX_MAINT_METHOD = 138;	///

const uint OCI_ATTR_DIRPATH_FILE	= 139;		/// DB file to load into.
const uint OCI_ATTR_DIRPATH_STORAGE_INITIAL = 140;	/// Initial extent size.
const uint OCI_ATTR_DIRPATH_STORAGE_NEXT= 141;		/// Next extent size.
const uint OCI_ATTR_DIRPATH_SKIPINDEX_METHOD = 145;	/// Direct path index maint method (see oci8dp.h).

const uint OCI_ATTR_DIRPATH_EXPR_TYPE	= 150;		/// Expr type of OCI_ATTR_NAME.

const uint OCI_ATTR_DIRPATH_INPUT	= 151;		/// Input in text or stream format.
const uint OCI_DIRPATH_INPUT_TEXT	= 0x01;		///
const uint OCI_DIRPATH_INPUT_STREAM	= 0x02;		///
const uint OCI_DIRPATH_INPUT_UNKNOWN	= 0x04;		///

const uint OCI_ATTR_DIRPATH_FN_CTX	= 167;		/// Fn ctx ADT attrs or args.

const uint OCI_ATTR_DIRPATH_OID		= 187;		/// Loading into an OID col.
const uint OCI_ATTR_DIRPATH_SID		= 194;		/// Loading into an SID col.
const uint OCI_ATTR_DIRPATH_OBJ_CONSTR	= 206;		/// Obj type of subst obj tbl.

const uint OCI_ATTR_DIRPATH_STREAM_VERSION = 212;	/// Version of the stream.

const uint OCIP_ATTR_DIRPATH_VARRAY_INDEX = 213;	/// Varray index column.

const uint OCI_ATTR_DIRPATH_DCACHE_NUM	= 303;		/// Date cache entries.
const uint OCI_ATTR_DIRPATH_DCACHE_SIZE	= 304;		/// Date cache limit.
const uint OCI_ATTR_DIRPATH_DCACHE_MISSES = 305;	/// Date cache misses.
const uint OCI_ATTR_DIRPATH_DCACHE_HITS	= 306;		/// Date cache hits.
const uint OCI_ATTR_DIRPATH_DCACHE_DISABLE = 307;	/// Disable datecache.

const uint OCI_ATTR_DIRPATH_RESERVED_7	= 326;		/// Reserved.
const uint OCI_ATTR_DIRPATH_RESERVED_8	= 327;		/// Reserved.
const uint OCI_ATTR_DIRPATH_CONVERT	= 328;		/// Stream conversion needed?.
const uint OCI_ATTR_DIRPATH_BADROW	= 329;		/// Info about bad row.
const uint OCI_ATTR_DIRPATH_BADROW_LENGTH = 330;	/// Length of bad row info.
const uint OCI_ATTR_DIRPATH_WRITE_ORDER	= 331;		/// Column fill order.
const uint OCI_ATTR_DIRPATH_GRANULE_SIZE= 332;		/// Granule size for unload.
const uint OCI_ATTR_DIRPATH_GRANULE_OFFSET = 333;	/// Offset to last granule.
const uint OCI_ATTR_DIRPATH_RESERVED_1	= 334;		/// Reserved.
const uint OCI_ATTR_DIRPATH_RESERVED_2	= 335;		/// Reserved.

const uint OCI_ATTR_DIRPATH_RESERVED_3	= 337;		/// Reserved.
const uint OCI_ATTR_DIRPATH_RESERVED_4	= 338;		/// Reserved.
const uint OCI_ATTR_DIRPATH_RESERVED_5	= 357;		/// Reserved.
const uint OCI_ATTR_DIRPATH_RESERVED_6	= 358;		/// Reserved.

const uint OCI_ATTR_DIRPATH_LOCK_WAIT	= 359;		/// Wait for lock in dpapi.

const uint OCI_ATTR_DIRPATH_RESERVED_9	= 2000;		/// Reserved.

const uint OCI_ATTR_DIRPATH_RESERVED_10	= 2001;		/// Vector of functions.
const uint OCI_ATTR_DIRPATH_RESERVED_11	= 2002;		/// Encryption metadata.

const uint OCI_ATTR_CURRENT_ERRCOL	= 2003;		/// Current error column.

const uint OCI_CURSOR_OPEN		= 0;		///
const uint OCI_CURSOR_CLOSED		= 1;		///

const uint OCI_CL_START			= 0;		///
const uint OCI_CL_END			= 1;		///

const uint OCI_SP_SUPPORTED		= 0;		///
const uint OCI_SP_UNSUPPORTED		= 1;		///

const uint OCI_NW_SUPPORTED		= 0;		///
const uint OCI_NW_UNSUPPORTED		= 1;		///

const uint OCI_AC_DDL			= 0;		///
const uint OCI_NO_AC_DDL		= 1;		///

const uint OCI_LOCK_IMMEDIATE		= 0;		///
const uint OCI_LOCK_DELAYED		= 1;		///

const uint OCI_INSTANCE_TYPE_UNKNOWN	= 0;		///
const uint OCI_INSTANCE_TYPE_RDBMS	= 1;		///
const uint OCI_INSTANCE_TYPE_OSM	= 2;		///

const uint OCI_AUTH			= 0x08;		/// Change the password but do not login.

const uint OCI_MAX_FNS			= 100;		/// Max number of OCI Functions.
const uint OCI_SQLSTATE_SIZE		= 5;		///
const uint OCI_ERROR_MAXMSG_SIZE	= 1024;		/// Max size of an error message.
const uint OCI_LOBMAXSIZE		= 4294967295;	/// Maximum lob data size.
const uint OCI_ROWID_LEN		= 23;		///

const uint OCI_FO_END			= 0x00000001;	///
const uint OCI_FO_ABORT			= 0x00000002;	///
const uint OCI_FO_REAUTH		= 0x00000004;	///
const uint OCI_FO_BEGIN			= 0x00000008;	///
const uint OCI_FO_ERROR			= 0x00000010;	///

const uint OCI_FO_RETRY			= 25410;	///

const uint OCI_FO_NONE			= 0x00000001;	///
const uint OCI_FO_SESSION		= 0x00000002;	///
const uint OCI_FO_SELECT		= 0x00000004;	///
const uint OCI_FO_TXNAL			= 0x00000008;	///

const uint OCI_FNCODE_INITIALIZE	= 1;		/// OCIInitialize.
const uint OCI_FNCODE_HANDLEALLOC	= 2;		/// OCIHandleAlloc.
const uint OCI_FNCODE_HANDLEFREE	= 3;		/// OCIHandleFree.
const uint OCI_FNCODE_DESCRIPTORALLOC	= 4;		/// OCIDescriptorAlloc.
const uint OCI_FNCODE_DESCRIPTORFREE	= 5;		/// OCIDescriptorFree.
const uint OCI_FNCODE_ENVINIT		= 6;		/// OCIEnvInit.
const uint OCI_FNCODE_SERVERATTACH	= 7;		/// OCIServerAttach.
const uint OCI_FNCODE_SERVERDETACH	= 8;		/// OCIServerDetach.
const uint OCI_FNCODE_SESSIONBEGIN	= 10;		/// OCISessionBegin.
const uint OCI_FNCODE_SESSIONEND	= 11;		/// OCISessionEnd.
const uint OCI_FNCODE_PASSWORDCHANGE	= 12;		/// OCIPasswordChange.
const uint OCI_FNCODE_STMTPREPARE	= 13;		/// OCIStmtPrepare.
const uint OCI_FNCODE_BINDDYNAMIC	= 17;		/// OCIBindDynamic.
const uint OCI_FNCODE_BINDOBJECT	= 18;		/// OCIBindObject.
const uint OCI_FNCODE_BINDARRAYOFSTRUCT	= 20;		/// OCIBindArrayOfStruct.
const uint OCI_FNCODE_STMTEXECUTE	= 21;		/// OCIStmtExecute.
const uint OCI_FNCODE_DEFINEOBJECT	= 25;		/// OCIDefineObject.
const uint OCI_FNCODE_DEFINEDYNAMIC	= 26;		/// OCIDefineDynamic.
const uint OCI_FNCODE_DEFINEARRAYOFSTRUCT = 27;		/// OCIDefineArrayOfStruct.
const uint OCI_FNCODE_STMTFETCH		= 28;		/// OCIStmtFetch.
const uint OCI_FNCODE_STMTGETBIND	= 29;		/// OCIStmtGetBindInfo.
const uint OCI_FNCODE_DESCRIBEANY	= 32;		/// OCIDescribeAny.
const uint OCI_FNCODE_TRANSSTART	= 33;		/// OCITransStart.
const uint OCI_FNCODE_TRANSDETACH	= 34;		/// OCITransDetach.
const uint OCI_FNCODE_TRANSCOMMIT	= 35;		/// OCITransCommit.
const uint OCI_FNCODE_ERRORGET		= 37;		/// OCIErrorGet.
const uint OCI_FNCODE_LOBOPENFILE	= 38;		/// OCILobFileOpen.
const uint OCI_FNCODE_LOBCLOSEFILE	= 39;		/// OCILobFileClose.
const uint OCI_FNCODE_LOBCOPY		= 42;		/// OCILobCopy.
const uint OCI_FNCODE_LOBAPPEND		= 43;		/// OCILobAppend.
const uint OCI_FNCODE_LOBERASE		= 44;		/// OCILobErase.
const uint OCI_FNCODE_LOBLENGTH		= 45;		/// OCILobGetLength.
const uint OCI_FNCODE_LOBTRIM		= 46;		/// OCILobTrim.
const uint OCI_FNCODE_LOBREAD		= 47;		/// OCILobRead.
const uint OCI_FNCODE_LOBWRITE		= 48;		/// OCILobWrite.
const uint OCI_FNCODE_SVCCTXBREAK	= 50;		/// OCIBreak.
const uint OCI_FNCODE_SERVERVERSION	= 51;		/// OCIServerVersion.
const uint OCI_FNCODE_KERBATTRSET	= 52;		/// OCIKerbAttrSet.
const uint OCI_FNCODE_ATTRGET		= 54;		/// OCIAttrGet.
const uint OCI_FNCODE_ATTRSET		= 55;		/// OCIAttrSet.
const uint OCI_FNCODE_PARAMSET		= 56;		/// OCIParamSet.
const uint OCI_FNCODE_PARAMGET		= 57;		/// OCIParamGet.
const uint OCI_FNCODE_STMTGETPIECEINFO	= 58;		/// OCIStmtGetPieceInfo.
const uint OCI_FNCODE_LDATOSVCCTX	= 59;		/// OCILdaToSvcCtx.
const uint OCI_FNCODE_STMTSETPIECEINFO	= 61;		/// OCIStmtSetPieceInfo.
const uint OCI_FNCODE_TRANSFORGET	= 62;		/// OCITransForget.
const uint OCI_FNCODE_TRANSPREPARE	= 63;		/// OCITransPrepare.
const uint OCI_FNCODE_TRANSROLLBACK	= 64;		/// OCITransRollback.
const uint OCI_FNCODE_DEFINEBYPOS	= 65;		/// OCIDefineByPos.
const uint OCI_FNCODE_BINDBYPOS		= 66;		/// OCIBindByPos.
const uint OCI_FNCODE_BINDBYNAME	= 67;		/// OCIBindByName.
const uint OCI_FNCODE_LOBASSIGN		= 68;		/// OCILobAssign.
const uint OCI_FNCODE_LOBISEQUAL	= 69;		/// OCILobIsEqual.
const uint OCI_FNCODE_LOBISINIT		= 70;		/// OCILobLocatorIsInit.
const uint OCI_FNCODE_LOBENABLEBUFFERING= 71;           /// OCILobEnableBuffering.
const uint OCI_FNCODE_LOBCHARSETID	= 72;		/// OCILobCharSetID.
const uint OCI_FNCODE_LOBCHARSETFORM	= 73;		/// OCILobCharSetForm.
const uint OCI_FNCODE_LOBFILESETNAME	= 74;		/// OCILobFileSetName.
const uint OCI_FNCODE_LOBFILEGETNAME	= 75;		/// OCILobFileGetName.
const uint OCI_FNCODE_LOGON		= 76;		/// OCILogon.
const uint OCI_FNCODE_LOGOFF		= 77;		/// OCILogoff.
const uint OCI_FNCODE_LOBDISABLEBUFFERING = 78;		/// OCILobDisableBuffering.
const uint OCI_FNCODE_LOBFLUSHBUFFER	= 79;		/// OCILobFlushBuffer.
const uint OCI_FNCODE_LOBLOADFROMFILE	= 80;		/// OCILobLoadFromFile.
const uint OCI_FNCODE_LOBOPEN		= 81;		/// OCILobOpen.
const uint OCI_FNCODE_LOBCLOSE		= 82;		/// OCILobClose.
const uint OCI_FNCODE_LOBISOPEN		= 83;		/// OCILobIsOpen.
const uint OCI_FNCODE_LOBFILEISOPEN	= 84;		/// OCILobFileIsOpen.
const uint OCI_FNCODE_LOBFILEEXISTS	= 85;		/// OCILobFileExists.
const uint OCI_FNCODE_LOBFILECLOSEALL	= 86;		/// OCILobFileCloseAll.
const uint OCI_FNCODE_LOBCREATETEMP	= 87;		/// OCILobCreateTemporary.
const uint OCI_FNCODE_LOBFREETEMP	= 88;		/// OCILobFreeTemporary.
const uint OCI_FNCODE_LOBISTEMP		= 89;		/// OCILobIsTemporary.
const uint OCI_FNCODE_AQENQ		= 90;		/// OCIAQEnq.
const uint OCI_FNCODE_AQDEQ		= 91;		/// OCIAQDeq.
const uint OCI_FNCODE_RESET		= 92;		/// OCIReset.
const uint OCI_FNCODE_SVCCTXTOLDA	= 93;		/// OCISvcCtxToLda.
const uint OCI_FNCODE_LOBLOCATORASSIGN	= 94;		/// OCILobLocatorAssign.
const uint OCI_FNCODE_UBINDBYNAME	= 95;		///
const uint OCI_FNCODE_AQLISTEN		= 96;		/// OCIAQListen.
const uint OCI_FNCODE_SVC2HST		= 97;		/// Reserved.
const uint OCI_FNCODE_SVCRH		= 98;		/// Reserved.
const uint OCI_FNCODE_TRANSMULTIPREPARE	= 99;		/// OCITransMultiPrepare.
const uint OCI_FNCODE_CPOOLCREATE	= 100;		/// OCIConnectionPoolCreate.
const uint OCI_FNCODE_CPOOLDESTROY	= 101;		/// OCIConnectionPoolDestroy.
const uint OCI_FNCODE_LOGON2		= 102;		/// OCILogon2.
const uint OCI_FNCODE_ROWIDTOCHAR	= 103;		/// OCIRowidToChar.

const uint OCI_FNCODE_SPOOLCREATE	= 104;		/// OCISessionPoolCreate.
const uint OCI_FNCODE_SPOOLDESTROY	= 105;		/// OCISessionPoolDestroy.
const uint OCI_FNCODE_SESSIONGET	= 106;		/// OCISessionGet.
const uint OCI_FNCODE_SESSIONRELEASE	= 107;		/// OCISessionRelease.
const uint OCI_FNCODE_STMTPREPARE2	= 108;		/// OCIStmtPrepare2.
const uint OCI_FNCODE_STMTRELEASE	= 109;		/// OCIStmtRelease.
const uint OCI_FNCODE_AQENQARRAY	= 110;		/// OCIAQEnqArray.
const uint OCI_FNCODE_AQDEQARRAY	= 111;		/// OCIAQDeqArray.
const uint OCI_FNCODE_LOBCOPY2		= 112;		/// OCILobCopy2.
const uint OCI_FNCODE_LOBERASE2		= 113;		/// OCILobErase2.
const uint OCI_FNCODE_LOBLENGTH2	= 114;		/// OCILobGetLength2.
const uint OCI_FNCODE_LOBLOADFROMFILE2	= 115;		/// OCILobLoadFromFile2.
const uint OCI_FNCODE_LOBREAD2		= 116;		/// OCILobRead2.
const uint OCI_FNCODE_LOBTRIM2		= 117;		/// OCILobTrim2.
const uint OCI_FNCODE_LOBWRITE2		= 118;		/// OCILobWrite2.
const uint OCI_FNCODE_LOBGETSTORAGELIMIT= 119;		/// OCILobGetStorageLimit.
const uint OCI_FNCODE_DBSTARTUP		= 120;		/// OCIDBStartup.
const uint OCI_FNCODE_DBSHUTDOWN	= 121;		/// OCIDBShutdown.
const uint OCI_FNCODE_LOBARRAYREAD	= 122;		/// OCILobArrayRead.
const uint OCI_FNCODE_LOBARRAYWRITE	= 123;		/// OCILobArrayWrite.
const uint OCI_FNCODE_MAXFCN		= 123;		/// Maximum OCI function code.

/**
 * OCI environment handle.
 */
struct OCIEnv {
}

/**
 * OCI error handle.
 */
struct OCIError {
}

/**
 * OCI service handle.
 */
struct OCISvcCtx {
}

/**
 * OCI statement handle.
 */
struct OCIStmt {
}

/**
 * OCI bind handle.
 */
struct OCIBind {
}

/**
 * OCI Define handle.
 */
struct OCIDefine {
}

/**
 * OCI Describe handle.
 */
struct OCIDescribe {
}

/**
 * OCI Server handle.
 */
struct OCIServer {
}

/**
 * OCI Authentication handle.
 */
struct OCISession {
}

/**
 * OCI COR handle.
 */
struct OCIComplexObject {
}

/**
 * OCI Transaction handle.
 */
struct OCITrans {
}

/**
 * OCI Security handle.
 */
struct OCISecurity {
}

/**
 * Subscription handle.
 */
struct OCISubscription {
}

/**
 * Connection pool handle.
 */
struct OCICPool {
}

/**
 * Session pool handle.
 */
struct OCISPool {
}

/**
 * Auth handle.
 */
struct OCIAuthInfo {
}

/**
 * Admin handle.
 */
struct OCIAdmin {
}

/**
 * HA event handle.
 */
struct OCIEvent {
}

/**
 * OCI snapshot descriptor.
 */
struct OCISnapshot {
}

/**
 * OCI Result Set descriptor.
 */
struct OCIResult {
}

/**
 * OCI Lob Locator descriptor.
 */
struct OCILobLocator {
}

/**
 * OCI Parameter descriptor.
 */
struct OCIParam {
}

/**
 * OCI COR descriptor.
 */
struct OCIComplexObjectComp {
}

/**
 * OCI ROWID descriptor.
 */
struct OCIRowid {
}

/**
 * OCI DateTime descriptor.
 */
struct OCIDateTime {
}

/**
 * OCI Interval descriptor.
 */
struct OCIInterval {
}

/**
 * OCI User Callback descriptor.
 */
struct OCIUcb {
}

/**
 * OCI server DN descriptor.
 */
struct OCIServerDNs {
}

/**
 * AQ Enqueue Options hdl.
 */
struct OCIAQEnqOptions {
}

/**
 * AQ Dequeue Options hdl.
 */
struct OCIAQDeqOptions {
}

/**
 * AQ Msg properties.
 */
struct OCIAQMsgProperties {
}

/**
 * AQ Agent descriptor.
 */
struct OCIAQAgent {
}

/**
 * AQ Nfy descriptor.
 */
struct OCIAQNfyDescriptor {
}

/**
 * AQ Siganture.
 */
struct OCIAQSignature {
}

/**
 * AQ listen options.
 */
struct OCIAQListenOpts {
}

/**
 * AQ listen msg props.
 */
struct OCIAQLisMsgProps {
}

/**
 * OCI Character LOB Locator.
 */
struct OCIClobLocator {
}

/**
 * OCI Binary LOB Locator.
 */
struct OCIBlobLocator {
}

/**
 * OCI Binary LOB File Locator.
 */
struct OCIBFileLocator {
}

const uint OCI_INTHR_UNK		= 24;		/// Undefined value for tz in interval types.

const uint OCI_ADJUST_UNK		= 10;		///
const uint OCI_ORACLE_DATE		= 0;		///
const uint OCI_ANSI_DATE		= 1;		///

/**
 * OCI Lob Offset.
 *
 * The offset in the lob data.  The offset is specified in terms of bytes for
 * BLOBs and BFILes.  Character offsets are used for CLOBs, NCLOBs.
 * The maximum size of internal lob data is 4 gigabytes.  FILE LOB
 * size is limited by the operating system.
 */
alias ub4 OCILobOffset;

/**
 * OCI Lob Length (of lob data).
 *
 * Specifies the length of lob data in bytes for BLOBs and BFILes and in
 * characters for CLOBs, NCLOBs.  The maximum length of internal lob
 * data is 4 gigabytes.  The length of FILE LOBs is limited only by the
 * operating system.
 */
alias ub4 OCILobLength;

/**
 * OCI Lob Open Modes.
 *
 * The mode specifies the planned operations that will be performed on the
 * FILE lob data.  The FILE lob can be opened in read-only mode only.
 *
 * In the future, we may include read/write, append and truncate modes.  Append
 * is equivalent to read/write mode except that the FILE is positioned for
 * writing to the end.  Truncate is equivalent to read/write mode except that
 * the FILE LOB data is first truncated to a length of 0 before use.
 */
enum OCILobMode {
	OCI_LOBMODE_READONLY = 1,			/// Read-only.
	OCI_LOBMODE_READWRITE = 2			/// Read and write for internal lobs only.
}

const uint OCI_FILE_READONLY		= 1;		/// Read-only mode open for FILE types.

const uint OCI_LOB_READONLY		= 1;		/// Read-only mode open for ILOB types.
const uint OCI_LOB_READWRITE		= 2;		/// Read and write mode open for ILOBs.

const uint OCI_LOB_BUFFER_FREE		= 1;		///
const uint OCI_LOB_BUFFER_NOFREE	= 2;		///

const uint OCI_STMT_SELECT		= 1;		/// Select statement.
const uint OCI_STMT_UPDATE		= 2;		/// Update statement.
const uint OCI_STMT_DELETE		= 3;		/// Delete statement.
const uint OCI_STMT_INSERT		= 4;		/// Insert statement.
const uint OCI_STMT_CREATE		= 5;		/// Create statement.
const uint OCI_STMT_DROP		= 6;		/// Drop statement.
const uint OCI_STMT_ALTER		= 7;		/// Alter statement.
const uint OCI_STMT_BEGIN		= 8;		/// Begin ... (pl/sql statement).
const uint OCI_STMT_DECLARE		= 9;		/// Declare ... (pl/sql statement).

const uint OCI_PTYPE_UNK		= 0;		/// Unknown.
const uint OCI_PTYPE_TABLE		= 1;		/// Table.
const uint OCI_PTYPE_VIEW		= 2;		/// View.
const uint OCI_PTYPE_PROC		= 3;		/// Procedure.
const uint OCI_PTYPE_FUNC		= 4;		/// Function.
const uint OCI_PTYPE_PKG		= 5;		/// Package.
const uint OCI_PTYPE_TYPE		= 6;		/// User-defined type.
const uint OCI_PTYPE_SYN		= 7;		/// Synonym.
const uint OCI_PTYPE_SEQ		= 8;		/// Sequence.
const uint OCI_PTYPE_COL		= 9;		/// Column.
const uint OCI_PTYPE_ARG		= 10;		/// Argument.
const uint OCI_PTYPE_LIST		= 11;		/// List.
const uint OCI_PTYPE_TYPE_ATTR		= 12;		/// User-defined type's attribute.
const uint OCI_PTYPE_TYPE_COLL		= 13;		/// Collection type's element.
const uint OCI_PTYPE_TYPE_METHOD	= 14;		/// User-defined type's method.
const uint OCI_PTYPE_TYPE_ARG		= 15;		/// User-defined type method's arg.
const uint OCI_PTYPE_TYPE_RESULT	= 16;		/// User-defined type method's result.
const uint OCI_PTYPE_SCHEMA		= 17;		/// Schema.
const uint OCI_PTYPE_DATABASE		= 18;		/// Database.
const uint OCI_PTYPE_RULE		= 19;		/// Rule.
const uint OCI_PTYPE_RULE_SET		= 20;		/// Rule set.
const uint OCI_PTYPE_EVALUATION_CONTEXT	= 21;		/// Evaluation context.
const uint OCI_PTYPE_TABLE_ALIAS	= 22;		/// Table alias.
const uint OCI_PTYPE_VARIABLE_TYPE	= 23;		/// Variable type.
const uint OCI_PTYPE_NAME_VALUE		= 24;		/// Name value pair.

const uint OCI_LTYPE_UNK		= 0;		/// Unknown.
const uint OCI_LTYPE_COLUMN		= 1;		/// Column list.
const uint OCI_LTYPE_ARG_PROC		= 2;		/// Procedure argument list.
const uint OCI_LTYPE_ARG_FUNC		= 3;		/// Function argument list.
const uint OCI_LTYPE_SUBPRG		= 4;		/// Subprogram list.
const uint OCI_LTYPE_TYPE_ATTR		= 5;		/// Type attribute.
const uint OCI_LTYPE_TYPE_METHOD	= 6;		/// Type method.
const uint OCI_LTYPE_TYPE_ARG_PROC	= 7;		/// Type method w/o result argument list.
const uint OCI_LTYPE_TYPE_ARG_FUNC	= 8;		/// Type method w/ result argument list.
const uint OCI_LTYPE_SCH_OBJ		= 9;		/// Schema object list.
const uint OCI_LTYPE_DB_SCH		= 10;		/// Database schema list.
const uint OCI_LTYPE_TYPE_SUBTYPE	= 11;		/// Subtype list.
const uint OCI_LTYPE_TABLE_ALIAS	= 12;		/// Table alias list.
const uint OCI_LTYPE_VARIABLE_TYPE	= 13;		/// Variable type list.
const uint OCI_LTYPE_NAME_VALUE		= 14;		/// Name value list.

const uint OCI_MEMORY_CLEARED		= 1;		///

/**
 *
 */
struct OCIPicklerTdsCtx {
}

/**
 *
 */
struct OCIPicklerTds {
}

/**
 *
 */
struct OCIPicklerImage {
}

/**
 *
 */
struct OCIPicklerFdo {
}

/**
 *
 */
struct OCIAnyData {
}

/**
 *
 */
struct OCIAnyDataSet {
}

/**
 *
 */
struct OCIAnyDataCtx {
}

alias ub4 OCIPicklerTdsElement;

const uint OCI_UCBTYPE_ENTRY		= 1;		/// Entry callback.
const uint OCI_UCBTYPE_EXIT		= 2;		/// Exit callback.
const uint OCI_UCBTYPE_REPLACE		= 3;		/// Replacement callback.

const uint OCI_NLS_DAYNAME1		= 1;		/// Native name for Monday.
const uint OCI_NLS_DAYNAME2		= 2;		/// Native name for Tuesday.
const uint OCI_NLS_DAYNAME3		= 3;		/// Native name for Wednesday.
const uint OCI_NLS_DAYNAME4		= 4;		/// Native name for Thursday.
const uint OCI_NLS_DAYNAME5		= 5;		/// Native name for Friday.
const uint OCI_NLS_DAYNAME6		= 6;		/// Native name for Saturday.
const uint OCI_NLS_DAYNAME7		= 7;		/// Native name for Sunday.
const uint OCI_NLS_ABDAYNAME1		= 8;		/// Native abbreviated name for Monday.
const uint OCI_NLS_ABDAYNAME2		= 9;		/// Native abbreviated name for Tuesday.
const uint OCI_NLS_ABDAYNAME3		= 10;		/// Native abbreviated name for Wednesday.
const uint OCI_NLS_ABDAYNAME4		= 11;		/// Native abbreviated name for Thursday.
const uint OCI_NLS_ABDAYNAME5		= 12;		/// Native abbreviated name for Friday.
const uint OCI_NLS_ABDAYNAME6		= 13;		/// Native abbreviated name for Saturday.
const uint OCI_NLS_ABDAYNAME7		= 14;		/// Native abbreviated name for Sunday.
const uint OCI_NLS_MONTHNAME1		= 15;		/// Native name for January.
const uint OCI_NLS_MONTHNAME2		= 16;		/// Native name for February.
const uint OCI_NLS_MONTHNAME3		= 17;		/// Native name for March.
const uint OCI_NLS_MONTHNAME4		= 18;		/// Native name for April.
const uint OCI_NLS_MONTHNAME5		= 19;		/// Native name for May.
const uint OCI_NLS_MONTHNAME6		= 20;		/// Native name for June.
const uint OCI_NLS_MONTHNAME7		= 21;		/// Native name for July.
const uint OCI_NLS_MONTHNAME8		= 22;		/// Native name for August.
const uint OCI_NLS_MONTHNAME9		= 23;		/// Native name for September.
const uint OCI_NLS_MONTHNAME10		= 24;		/// Native name for October.
const uint OCI_NLS_MONTHNAME11		= 25;		/// Native name for November.
const uint OCI_NLS_MONTHNAME12		= 26;		/// Native name for December.
const uint OCI_NLS_ABMONTHNAME1		= 27;		/// Native abbreviated name for January.
const uint OCI_NLS_ABMONTHNAME2		= 28;		/// Native abbreviated name for February.
const uint OCI_NLS_ABMONTHNAME3		= 29;		/// Native abbreviated name for March.
const uint OCI_NLS_ABMONTHNAME4		= 30;		/// Native abbreviated name for April.
const uint OCI_NLS_ABMONTHNAME5		= 31;		/// Native abbreviated name for May.
const uint OCI_NLS_ABMONTHNAME6		= 32;		/// Native abbreviated name for June.
const uint OCI_NLS_ABMONTHNAME7		= 33;		/// Native abbreviated name for July.
const uint OCI_NLS_ABMONTHNAME8		= 34;		/// Native abbreviated name for August.
const uint OCI_NLS_ABMONTHNAME9		= 35;		/// Native abbreviated name for September.
const uint OCI_NLS_ABMONTHNAME10	= 36;		/// Native abbreviated name for October.
const uint OCI_NLS_ABMONTHNAME11	= 37;		/// Native abbreviated name for November.
const uint OCI_NLS_ABMONTHNAME12	= 38;		/// Native abbreviated name for December.
const uint OCI_NLS_YES			= 39;		/// Native string for affirmative response.
const uint OCI_NLS_NO			= 40;		/// Native negative response.
const uint OCI_NLS_AM			= 41;		/// Native equivalent string of AM.
const uint OCI_NLS_PM			= 42;		/// Native equivalent string of PM.
const uint OCI_NLS_AD			= 43;		/// Native equivalent string of AD.
const uint OCI_NLS_BC			= 44;		/// Native equivalent string of BC.
const uint OCI_NLS_DECIMAL		= 45;		/// Decimal character.
const uint OCI_NLS_GROUP		= 46;		/// Group separator.
const uint OCI_NLS_DEBIT		= 47;		/// Native symbol of debit.
const uint OCI_NLS_CREDIT		= 48;		/// Native sumbol of credit.
const uint OCI_NLS_DATEFORMAT		= 49;		/// Oracle date format.
const uint OCI_NLS_INT_CURRENCY		= 50;		/// International currency symbol.
const uint OCI_NLS_LOC_CURRENCY		= 51;		/// Locale currency symbol.
const uint OCI_NLS_LANGUAGE		= 52;		/// Language name.
const uint OCI_NLS_ABLANGUAGE		= 53;		/// Abbreviation for language name.
const uint OCI_NLS_TERRITORY		= 54;		/// Territory name.
const uint OCI_NLS_CHARACTER_SET	= 55;		/// Character set name.
const uint OCI_NLS_LINGUISTIC_NAME	= 56;		/// Linguistic name.
const uint OCI_NLS_CALENDAR		= 57;		/// Calendar name.
const uint OCI_NLS_DUAL_CURRENCY	= 78;		/// Dual currency symbol.
const uint OCI_NLS_WRITINGDIR		= 79;		/// Language writing direction.
const uint OCI_NLS_ABTERRITORY		= 80;		/// Territory Abbreviation.
const uint OCI_NLS_DDATEFORMAT		= 81;		/// Oracle default date format.
const uint OCI_NLS_DTIMEFORMAT		= 82;		/// Oracle default time format.
const uint OCI_NLS_SFDATEFORMAT		= 83;		/// Local string formatted date format.
const uint OCI_NLS_SFTIMEFORMAT		= 84;		/// Local string formatted time format.
const uint OCI_NLS_NUMGROUPING		= 85;		/// Number grouping fields.
const uint OCI_NLS_LISTSEP		= 86;		/// List separator.
const uint OCI_NLS_MONDECIMAL		= 87;		/// Monetary decimal character.
const uint OCI_NLS_MONGROUP		= 88;		/// Monetary group separator.
const uint OCI_NLS_MONGROUPING		= 89;		/// Monetary grouping fields.
const uint OCI_NLS_INT_CURRENCYSEP	= 90;		/// International currency separator.
const uint OCI_NLS_CHARSET_MAXBYTESZ	= 91;		/// Maximum character byte size     .
const uint OCI_NLS_CHARSET_FIXEDWIDTH	= 92;		/// Fixed-width charset byte size   .
const uint OCI_NLS_CHARSET_ID		= 93;		/// Character set id.
const uint OCI_NLS_NCHARSET_ID		= 94;		/// NCharacter set id.

const uint OCI_NLS_MAXBUFSZ		= 100;		/// Max buffer size may need for OCINlsGetInfo.

const uint OCI_NLS_BINARY		= 0x1;		/// For the binary comparison.
const uint OCI_NLS_LINGUISTIC		= 0x2;		/// For linguistic comparison.
const uint OCI_NLS_CASE_INSENSITIVE	= 0x10;		/// For case-insensitive comparison.

const uint OCI_NLS_UPPERCASE		= 0x20;		/// Convert to uppercase.
const uint OCI_NLS_LOWERCASE		= 0x40;		/// Convert to lowercase.

const uint OCI_NLS_CS_IANA_TO_ORA	= 0;		/// Map charset name from IANA to Oracle.
const uint OCI_NLS_CS_ORA_TO_IANA	= 1;		/// Map charset name from Oracle to IANA.
const uint OCI_NLS_LANG_ISO_TO_ORA	= 2;		/// Map language name from ISO to Oracle.
const uint OCI_NLS_LANG_ORA_TO_ISO	= 3;		/// Map language name from Oracle to ISO.
const uint OCI_NLS_TERR_ISO_TO_ORA	= 4;		/// Map territory name from ISO to Oracle.
const uint OCI_NLS_TERR_ORA_TO_ISO	= 5;		/// Map territory name from Oracle to ISO.
const uint OCI_NLS_TERR_ISO3_TO_ORA	= 6;		/// Map territory name from 3-letter ISO abbreviation to Oracle.
const uint OCI_NLS_TERR_ORA_TO_ISO3	= 7;		/// Map territory name from Oracle to  3-letter ISO abbreviation.

/**
 *
 */
struct OCIMsg {
}

alias ub4 OCIWchar;

const uint OCI_XMLTYPE_CREATE_OCISTRING	= 1;		///
const uint OCI_XMLTYPE_CREATE_CLOB	= 2;		///
const uint OCI_XMLTYPE_CREATE_BLOB	= 3;		///

const uint OCI_KERBCRED_PROXY		= 1;		/// Apply Kerberos Creds for Proxy.
const uint OCI_KERBCRED_CLIENT_IDENTIFIER = 2;		/// Apply Creds for Secure Client ID.

const uint OCI_DBSTARTUPFLAG_FORCE	= 0x00000001;	/// Abort running instance, start.
const uint OCI_DBSTARTUPFLAG_RESTRICT	= 0x00000002;	/// Restrict access to DBA.

const uint OCI_DBSHUTDOWN_TRANSACTIONAL	= 1;		/// Wait for all the transactions.
const uint OCI_DBSHUTDOWN_TRANSACTIONAL_LOCAL = 2;	/// Wait for local transactions.
const uint OCI_DBSHUTDOWN_IMMEDIATE	= 3;		/// Terminate and roll back.
const uint OCI_DBSHUTDOWN_ABORT		= 4;		/// Terminate and don't roll back.
const uint OCI_DBSHUTDOWN_FINAL		= 5;		/// Orderly shutdown.

const uint OCI_MAJOR_VERSION		= 10;		/// Major release version.
const uint OCI_MINOR_VERSION		= 2;		/// Minor release version.