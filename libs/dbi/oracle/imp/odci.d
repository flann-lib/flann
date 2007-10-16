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
module dbi.oracle.imp.odci;

private import dbi.oracle.imp.oci, dbi.oracle.imp.orl, dbi.oracle.imp.oro, dbi.oracle.imp.ort;

const uint ODCI_SUCCESS			= 0;		///
const uint ODCI_ERROR			= 1;		///
const uint ODCI_WARNING			= 2;		///
const uint ODCI_ERROR_CONTINUE		= 3;		///
const uint ODCI_FATAL			= 4;		///

const uint ODCI_PRED_EXACT_MATCH	= 0x0001;	///
const uint ODCI_PRED_PREFIX_MATCH	= 0x0002;	///
const uint ODCI_PRED_INCLUDE_START	= 0x0004;	///
const uint ODCI_PRED_INCLUDE_STOP	= 0x0008;	///
const uint ODCI_PRED_OBJECT_FUNC	= 0x0010;	///
const uint ODCI_PRED_OBJECT_PKG		= 0x0020;	///
const uint ODCI_PRED_OBJECT_TYPE	= 0x0040;	///
const uint ODCI_PRED_MULTI_TABLE	= 0x0080;	///

const uint ODCI_QUERY_FIRST_ROWS	= 0x01;		///
const uint ODCI_QUERY_ALL_ROWS		= 0x02;		///
const uint ODCI_QUERY_SORT_ASC		= 0x04;		///
const uint ODCI_QUERY_SORT_DESC		= 0x08;		///
const uint ODCI_QUERY_BLOCKING		= 0x10;		///

const uint ODCI_CLEANUP_CALL		= 1;		///
const uint ODCI_REGULAR_CALL		= 2;		///

const uint ODCI_OBJECT_FUNC		= 0x01;		///
const uint ODCI_OBJECT_PKG		= 0x02;		///
const uint ODCI_OBJECT_TYPE		= 0x04;		///

const uint ODCI_ARG_OTHER		= 1;		///
const uint ODCI_ARG_COL			= 2;		/// Column.
const uint ODCI_ARG_LIT			= 3;		/// Literal.
const uint ODCI_ARG_ATTR		= 4;		/// Object attribute.
const uint ODCI_ARG_NULL		= 5;		///
const uint ODCI_ARG_CURSOR		= 6;		///

const uint ODCI_ARG_DESC_LIST_MAXSIZE	= 32767;	/// Maximum size of ODCIArgDescList array.

const uint ODCI_PERCENT_OPTION		= 1;		///
const uint ODCI_ROW_OPTION		= 2;		///

const uint ODCI_ESTIMATE_STATS		= 0x01;		///
const uint ODCI_COMPUTE_STATS		= 0x02;		///
const uint ODCI_VALIDATE		= 0x04;		///

const uint ODCI_ALTIDX_NONE		= 0;		///
const uint ODCI_ALTIDX_RENAME		= 1;		///
const uint ODCI_ALTIDX_REBUILD		= 2;		///
const uint ODCI_ALTIDX_REBUILD_ONL	= 3;		///
const uint ODCI_ALTIDX_MODIFY_COL	= 4;		///
const uint ODCI_ALTIDX_UPDATE_BLOCK_REFS= 5;		///

const uint ODCI_INDEX_LOCAL		= 0x0001;	///
const uint ODCI_INDEX_RANGE_PARTN	= 0x0002;	///
const uint ODCI_INDEX_HASH_PARTN	= 0x0004;	///
const uint ODCI_INDEX_ONLINE		= 0x0008;	///
const uint ODCI_INDEX_PARALLEL		= 0x0010;	///
const uint ODCI_INDEX_UNUSABLE		= 0x0020;	///
const uint ODCI_INDEX_ONIOT		= 0x0040;	///
const uint ODCI_INDEX_TRANS_TBLSPC	= 0x0080;	///
const uint ODCI_INDEX_FUNCTION_IDX	= 0x0100;	///

const uint ODCI_INDEX_DEFAULT_DEGREE	= 32767;	///

const uint ODCI_DEBUGGING_ON		= 0x01;		///

const uint ODCI_CALL_NONE		= 0;		///
const uint ODCI_CALL_FIRST		= 1;		///
const uint ODCI_CALL_INTERMEDIATE	= 2;		///
const uint ODCI_CALL_FINAL		= 3;		///

const uint ODCI_EXTTABLE_INFO_OPCODE_FETCH = 1;		///
const uint ODCI_EXTTABLE_INFO_OPCODE_POPULATE = 2;	///

const uint ODCI_EXTTABLE_INFO_FLAG_SAMPLE = 0x00000001;	///
const uint ODCI_EXTTABLE_INFO_FLAG_SAMPLE_BLOCK = 0x00000002; ///
const uint ODCI_EXTTABLE_INFO_FLAG_ACCESS_PARM_CLOB = 0x00000004; ///
const uint ODCI_EXTTABLE_INFO_FLAG_ACCESS_PARM_BLOB = 0x00000008; ///

const uint ODCI_TRUE			= 1;		///
const uint ODCI_FALSE			= 0;		///

const uint ODCI_EXTTABLE_OPEN_FLAGS_QC	= 0x00000001;	/// Caller is Query Coord.
const uint ODCI_EXTTABLE_OPEN_FLAGS_SHADOW = 0x00000002;/// Caller is shadow proc.
const uint ODCI_EXTTABLE_OPEN_FLAGS_SLAVE = 0x00000004;	/// Caller is slave proc.

const uint ODCI_EXTTABLE_FETCH_FLAGS_EOS= 0x00000001;	/// End-of-stream on fetch.

const uint ODCI_AGGREGATE_REUSE_CTX	= 1;		/// Constants for Flags argument to ODCIAggregateTerminate.

/**
 *
 */
alias OCIRef ODCIColInfo_ref;

/**
 *
 */
alias OCIArray ODCIColInfoList;

/**
 *
 */
alias OCIArray ODCIColInfoList2;

/**
 *
 */
alias OCIRef ODCIIndexInfo_ref;

/**
 *
 */
alias OCIRef ODCIPredInfo_ref;

/**
 *
 */
alias OCIArray ODCIRidList;

/**
 *
 */
alias OCIRef ODCIIndexCtx_ref;

/**
 *
 */
alias OCIRef ODCIObject_ref;

/**
 *
 */
alias OCIArray ODCIObjectList;

/**
 *
 */
alias OCIRef ODCIQueryInfo_ref;

/**
 *
 */
alias OCIRef ODCIFuncInfo_ref;

/**
 *
 */
alias OCIRef ODCICost_ref;

/**
 *
 */
alias OCIRef ODCIArgDesc_ref;

/**
 *
 */
alias OCIArray ODCIArgDescList;

/**
 *
 */
alias OCIRef ODCIStatsOptions_ref;

/**
 *
 */
alias OCIRef ODCIPartInfo_ref;

/**
 *
 */
alias OCIRef ODCIEnv_ref;

/**
 * External table support.
 */
alias OCIRef ODCIExtTableInfo_ref;

/**
 * External table support.
 */
alias OCIArray ODCIGranuleList;

/**
 * External table support.
 */
alias OCIRef ODCIExtTableQCInfo_ref;

/**
 * External table support.
 */
alias OCIRef ODCIFuncCallInfo_ref;

/**
 *
 */
alias OCIArray ODCINumberList;

/**
 *
 */
struct ODCIColInfo {
	OCIString* TableSchema;				///
	OCIString* TableName;				///
	OCIString* ColName;				///
	OCIString* ColTypName;				///
	OCIString* ColTypSchema;			///
	OCIString* TablePartition;			///
}

/**
 *
 */
struct ODCIColInfo_ind {
	OCIInd atomic;					///
	OCIInd TableSchema;				///
	OCIInd TableName;				///
	OCIInd ColName;					///
	OCIInd ColTypName;				///
	OCIInd ColTypSchema;				///
	OCIInd TablePartition;				///
}

/**
 *
 */
struct ODCIFuncCallInfo {
	ODCIColInfo ColInfo;				///
}

/**
 *
 */
struct ODCIFuncCallInfo_ind {
	ODCIColInfo_ind ColInfo;			///
}

/**
 *
 */
struct ODCIIndexInfo {
	OCIString* IndexSchema;				///
	OCIString* IndexName;				///
	ODCIColInfoList* IndexCols;			///
	OCIString* IndexPartition;			///
	OCINumber IndexInfoFlags;			///
	OCINumber IndexParaDegree;			///
}

/**
 *
 */
struct ODCIIndexInfo_ind {
	OCIInd atomic;					///
	OCIInd IndexSchema;				///
	OCIInd IndexName;				///
	OCIInd IndexCols;				///
	OCIInd IndexPartition;				///
	OCIInd IndexInfoFlags;				///
	OCIInd IndexParaDegree;				///
}

/**
 *
 */
struct ODCIPredInfo {
	OCIString* ObjectSchema;			///
	OCIString* ObjectName;				///
	OCIString* MethodName;				///
	OCINumber Flags;				///
}

/**
 *
 */
struct ODCIPredInfo_ind {
	OCIInd atomic;					///
	OCIInd ObjectSchema;				///
	OCIInd ObjectName;				///
	OCIInd MethodName;				///
	OCIInd Flags;					///
}

/**
 *
 */
struct ODCIObject {
	OCIString* ObjectSchema;			///
	OCIString* ObjectName;				///
}

/**
 *
 */
struct ODCIObject_ind {
	OCIInd atomic;					///
	OCIInd ObjectSchema;				///
	OCIInd ObjectName;				///
}

/**
 *
 */
struct ODCIQueryInfo {
	OCINumber Flags;				///
	ODCIObjectList* AncOps;				///
}

/**
 *
 */
struct ODCIQueryInfo_ind {
	OCIInd atomic;					///
	OCIInd Flags;					///
	OCIInd AncOps;					///
}

/**
 *
 */
struct ODCIIndexCtx {
	ODCIIndexInfo IndexInfo;			///
	OCIString* Rid;					///
	ODCIQueryInfo QueryInfo;			///
}

/**
 *
 */
struct ODCIIndexCtx_ind {
	OCIInd atomic;					///
	ODCIIndexInfo_ind IndexInfo;			///
	OCIInd Rid;					///
	ODCIQueryInfo_ind QueryInfo;			///
}

/**
 *
 */
struct ODCIFuncInfo {
	OCIString* ObjectSchema;			///
	OCIString* ObjectName;				///
	OCIString* MethodName;				///
	OCINumber Flags;				///
}

/**
 *
 */
struct ODCIFuncInfo_ind {
	OCIInd atomic;					///
	OCIInd ObjectSchema;				///
	OCIInd ObjectName;				///
	OCIInd MethodName;				///
	OCIInd Flags;					///
}

/**
 *
 */
struct ODCICost {
	OCINumber CPUcost;				///
	OCINumber IOcost;				///
	OCINumber NetworkCost;				///
	OCIString* IndexCostInfo;			///
}

/**
 *
 */
struct ODCICost_ind {
	OCIInd atomic;					///
	OCIInd CPUcost;					///
	OCIInd IOcost;					///
	OCIInd NetworkCost;				///
	OCIInd IndexCostInfo;				///
}

/**
 *
 */
struct ODCIArgDesc {
   OCINumber  ArgType;					///
   OCIString* TableName;				///
   OCIString* TableSchema;				///
   OCIString* ColName;					///
   OCIString* TablePartitionLower;			///
   OCIString* TablePartitionUpper;			///
   OCINumber  Cardinality;				///
}

/**
 *
 */
struct ODCIArgDesc_ind {
	OCIInd atomic;					///
	OCIInd ArgType;					///
	OCIInd TableName;				///
	OCIInd TableSchema;				///
	OCIInd ColName;					///
	OCIInd TablePartitionLower;			///
	OCIInd TablePartitionUpper;			///
	OCIInd Cardinality;				///
}

/**
 *
 */
struct ODCIStatsOptions {
	OCINumber Sample;				///
	OCINumber Options;				///
	OCINumber Flags;				///
}

/**
 *
 */
struct ODCIStatsOptions_ind {
	OCIInd atomic;					///
	OCIInd Sample;					///
	OCIInd Options;					///
	OCIInd Flags;					///
}

/**
 *
 */
struct ODCIEnv {
	OCINumber EnvFlags;				///
	OCINumber CallProperty;				///
	OCINumber DebugLevel;				///
	OCINumber CursorNum;				///
}

/**
 *
 */
struct ODCIEnv_ind {
	OCIInd _atomic;					///
	OCIInd EnvFlags;				///
	OCIInd CallProperty;				///
	OCIInd DebugLevel;				///
	OCIInd CursorNum;				///
}

/**
 *
 */
struct ODCIPartInfo {
	OCIString* TablePartition;			///
	OCIString* IndexPartition;			///
}

/**
 *
 */
struct ODCIPartInfo_ind {
	OCIInd atomic;					///
	OCIInd TablePartition;				///
	OCIInd IndexPartition;				///
}

/**
 * External Tables.
 */
struct ODCIExtTableInfo {
	OCIString* TableSchema;				///
	OCIString* TableName;				///
	ODCIColInfoList* RefCols;			///
	OCIClobLocator* AccessParmClob;			///
	OCIBlobLocator* AccessParmBlob;			///
	ODCIArgDescList* Locations;			///
	ODCIArgDescList* Directories;			///
	OCIString* DefaultDirectory;			///
	OCIString* DriverType;				///
	OCINumber OpCode;				///
	OCINumber AgentNum;				///
	OCINumber GranuleSize;				///
	OCINumber Flag;					///
	OCINumber SamplePercent;			///
	OCINumber MaxDoP;				///
	OCIRaw* SharedBuf;				///
	OCIString* MTableName;				///
	OCIString* MTableSchema;			///
	OCINumber TableObjNo;				///
}

/**
 * ditto
 */
struct ODCIExtTableInfo_ind {
	OCIInd _atomic;					///
	OCIInd TableSchema;				///
	OCIInd TableName;				///
	OCIInd RefCols;					///
	OCIInd AccessParmClob;				///
	OCIInd AccessParmBlob;				///
	OCIInd Locations;				///
	OCIInd Directories;				///
	OCIInd DefaultDirectory;			///
	OCIInd DriverType;				///
	OCIInd OpCode;					///
	OCIInd AgentNum;				///
	OCIInd GranuleSize;				///
	OCIInd Flag;					///
	OCIInd SamplePercent;				///
	OCIInd MaxDoP;					///
	OCIInd SharedBuf;				///
	OCIInd MTableName;				///
	OCIInd MTableSchema;				///
	OCIInd TableObjNo;				///
}

/**
 * ditto
 */
struct ODCIExtTableQCInfo {
	OCINumber NumGranules;				///
	OCINumber NumLocations;				///
	ODCIGranuleList* GranuleInfo;			///
	OCINumber IntraSourceConcurrency;		///
	OCINumber MaxDoP;				///
	OCIRaw* SharedBuf;				///
}

/**
 * ditto
 */
struct ODCIExtTableQCInfo_ind {
	OCIInd _atomic;					///
	OCIInd NumGranules;				///
	OCIInd NumLocations;				///
	OCIInd GranuleInfo;				///
	OCIInd IntraSourceConcurrency;			///
	OCIInd MaxDoP;					///
	OCIInd SharedBuf;				///
}

/**
 * Table Function Info types (used by ODCITablePrepare).
 */
struct ODCITabFuncInfo {
	ODCINumberList* Attrs;				///
	OCIType* RetType;				///
}

/**
 * ditto
 */
struct ODCITabFuncInfo_ind {
	OCIInd _atomic;					///
	OCIInd Attrs;					///
	OCIInd RetType;					///
}

/**
 * Table Function Statistics types (used by ODCIStatsTableFunction).
 */
struct ODCITabFuncStats {
	OCINumber num_rows;				///
}

/**
 * ditto
 */
struct ODCITabFuncStats_ind {
	OCIInd _atomic;					///
	OCIInd num_rows;				///
}