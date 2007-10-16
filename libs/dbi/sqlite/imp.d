/**
 * SQLite import library.
 *
 * Part of the D DBI project.
 *
 * Version:
 *	SQLite version 3.3.11
 *
 *	Import library version 0.05
 *
 * Authors: The D DBI project
 *
 * Copyright: BSD license
 */

module dbi.sqlite.imp;

version (GNU) {
} else {
version (Windows) {
	pragma (lib, "sqlite3.lib");
} else version (linux) {
	pragma (lib, "libsqlite.so");
} else version (Posix) {
	pragma (lib, "libsqlite.so");
} else version (darwin) {
	pragma (lib, "libsqlite.so");
} else {
	pragma (msg, "You will need to manually link in the SQLite library.");
}
}

version (Phobos) {
	private import std.c.stdarg;
} else {
	private import tango.stdc.stdarg;
}

/**
 *
 */
struct sqlite3 {
}

/**
 *
 */
struct sqlite3_context {
}

/**
 *
 */
struct sqlite3_index_info {
	int nConstraint;			/// Number of entries in aConstraint.
	struct sqlite3_index_constraint {
		int iColumn;			/// Column on left-hand side of constraint.
		ubyte op;			/// Constraint operator.
		ubyte usable;			/// true if this constraint is usable.
		int iTermOffset;		/// Used internally - xBestIndex should ignore.
	}
	sqlite3_index_constraint* aConstraint;	/// Table of WHERE clause constraints.

	int nOrderBy;				/// Number of terms in the ORDER BY clause.
	struct sqlite3_index_orderby {
		int iColumn;			/// Column number.
		ubyte desc;			/// true for DESC and false for ASC.
	}
	sqlite3_index_orderby* aOrderBy;	/// The ORDER BY clause.

	struct sqlite3_index_constraint_usage {
		int argvIndex;			/// if >0, constraint is part of argv to xFilter.
		ubyte omit;			/// Do not code a test for this constraint.
	}
	sqlite3_index_constraint_usage* aConstraintUsage; ///
	int idxNum;				/// Number used to identify the index.
	char* idxStr;				/// String, possibly obtained from sqlite3_malloc.
	int needToFreeIdxStr;			/// Free idxStr using sqlite3_free() if true.
	int orderByConsumed;			/// true if output is already ordered.
	double estimatedCost;			/// Estimated cost of using this index.
}

/**
 *
 */
struct sqlite3_module {
	int iVersion;
	extern (C) int function(sqlite3* db, void* pAux, int argc, char** argv, sqlite3_vtab** ppVTab, char**) xCreate;
	extern (C) int function(sqlite3* db, void* pAux, int argc, char** argv, sqlite3_vtab** ppVTab, char**) xConnect;
	extern (C) int function(sqlite3_vtab* pVTab, sqlite3_index_info* pInfo) xBestIndex;
	extern (C) int function(sqlite3_vtab* pVTab) xDisconnect;
	extern (C) int function(sqlite3_vtab* pVTab) xDestroy;
	extern (C) int function(sqlite3_vtab* pVTab, sqlite3_vtab_cursor** ppCursor) xOpen;
	extern (C) int function(sqlite3_vtab_cursor* pVTabCursor) xClose;
	extern (C) int function(sqlite3_vtab_cursor* pVTabCursor, int idxNum, char* idxStr, int argc, sqlite3_value** argv) xFilter;
	extern (C) int function(sqlite3_vtab_cursor* pVTabCursor) xNext;
	extern (C) int function(sqlite3_vtab_cursor* pVTabCursor) xEof;
	extern (C) int function(sqlite3_vtab_cursor* pVTabCursor, sqlite3_context*, int) xColumn;
	extern (C) int function(sqlite3_vtab_cursor* pVTabCursor, long* pRowid) xRowid;
	extern (C) int function(sqlite3_vtab* pVTab, int, sqlite3_value**, long*) xUpdate;
	extern (C) int function(sqlite3_vtab* pVTab) xBegin;
	extern (C) int function(sqlite3_vtab* pVTab) xSync;
	extern (C) int function(sqlite3_vtab* pVTab) xCommit;
	extern (C) int function(sqlite3_vtab* pVTab) xRollback;
	extern (C) int function(sqlite3_vtab* pVtab, int nArg, char* zName, void function(sqlite3_context*, int, sqlite3_value**)pxFunc, void** ppArg) xFindFunction;
}

/**
 *
 */
struct sqlite3_stmt {
}

/**
 *
 */
struct sqlite3_value {
}

/**
 *
 */
struct sqlite3_vtab {
	sqlite3_module* pModule;	/// The module for this virtual table.
	int nRef;			/// Used internally.
	char* zErrMsg;			/// Error message from sqlite3_mprintf().
}

/**
 *
 */
struct sqlite3_vtab_cursor {
	sqlite3_vtab* pVtab;		/// Virtual table of this cursor.
}

/**
 *
 */
alias int function(void*, int, char**, char**) sqlite_callback;

const int SQLITE_OK			= 0;	/// Successful result.
const int SQLITE_ERROR			= 1;	/// SQL error or missing database.
const int SQLITE_INTERNAL		= 2;	/// An internal logic error in SQLite.
const int SQLITE_PERM			= 3;	/// Access permission denied.
const int SQLITE_ABORT			= 4;	/// Callback routine requested an abort.
const int SQLITE_BUSY			= 5;	/// The database file is locked.
const int SQLITE_LOCKED			= 6;	/// A table in the database is locked.
const int SQLITE_NOMEM			= 7;	/// A malloc() failed.
const int SQLITE_READONLY		= 8;	/// Attempt to write a readonly database.
const int SQLITE_INTERRUPT		= 9;	/// Operation terminated by sqlite_interrupt().
const int SQLITE_IOERR			= 10;	/// Some kind of disk I/O error occurred.
const int SQLITE_CORRUPT		= 11;	/// The database disk image is malformed.
const int SQLITE_NOTFOUND		= 12;	/// (Internal Only) Table or record not found.
const int SQLITE_FULL			= 13;	/// Insertion failed because database is full.
const int SQLITE_CANTOPEN		= 14;	/// Unable to open the database file.
const int SQLITE_PROTOCOL		= 15;	/// Database lock protocol error.
const int SQLITE_EMPTY			= 16;	/// (Internal Only) Database table is empty.
const int SQLITE_SCHEMA			= 17;	/// The database schema changed.
const int SQLITE_TOOBIG			= 18;	/// Too much data for one row of a table.
const int SQLITE_CONSTRAINT		= 19;	/// Abort due to constraint violation.
const int SQLITE_MISMATCH		= 20;	/// Data type mismatch.
const int SQLITE_MISUSE			= 21;	/// Library used incorrectly.
const int SQLITE_NOLFS			= 22;	/// Uses OS features not supported on host.
const int SQLITE_AUTH			= 23;	/// Authorization denied.
const int SQLITE_ROW			= 100;	/// sqlite_step() has another row ready.
const int SQLITE_DONE			= 101;	/// sqlite_step() has finished executing.
const int SQLITE_UTF8			= 1;	/// The text is in UTF8 format.
const int SQLITE_UTF16BE		= 2;	/// The text is in UTF16 big endian format.
const int SQLITE_UTF16LE		= 3;	/// The text is in UTF16 little endian format.
const int SQLITE_UTF16			= 4;	/// The text is in UTF16 format.
const int SQLITE_ANY			= 5;	/// The text is in some format or another.

const int SQLITE_INTEGER		= 1;	/// The data value is an integer.
const int SQLITE_FLOAT			= 2;	/// The data value is a float.
const int SQLITE_TEXT			= 3;	/// The data value is text.
const int SQLITE_BLOB			= 4;	/// The data value is a blob.
const int SQLITE_NULL			= 5;	/// The data value is _null.

const int SQLITE_DENY			= 1;	/// Abort the SQL statement with an error.
const int SQLITE_IGNORE			= 2;	/// Don't allow access, but don't generate an error.

const void function(void*) SQLITE_STATIC = cast(void function(void*))0; /// The data doesn't need to be freed by SQLite.
const void function(void*) SQLITE_TRANSIENT = cast(void function(void*))-1; /// SQLite should make a private copy of the data.

const int SQLITE_CREATE_INDEX		= 1;	/// Index Name		Table Name
const int SQLITE_CREATE_TABLE		= 2;	/// Table Name		NULL
const int SQLITE_CREATE_TEMP_INDEX	= 3;	/// Index Name		Table Name
const int SQLITE_CREATE_TEMP_TABLE	= 4;	/// Table Name		NULL
const int SQLITE_CREATE_TEMP_TRIGGER	= 5;	/// Trigger Name	Table Name
const int SQLITE_CREATE_TEMP_VIEW	= 6;	/// View Name		NULL
const int SQLITE_CREATE_TRIGGER		= 7;	/// Trigger Name	Table Name
const int SQLITE_CREATE_VIEW		= 8;	/// View Name		NULL
const int SQLITE_DELETE			= 9;	/// Table Name		NULL
const int SQLITE_DROP_INDEX		= 10;	/// Index Name		Table Name
const int SQLITE_DROP_TABLE		= 11;	/// Table Name		NULL
const int SQLITE_DROP_TEMP_INDEX	= 12;	/// Index Name		Table Name
const int SQLITE_DROP_TEMP_TABLE	= 13;	/// Table Name		NULL
const int SQLITE_DROP_TEMP_TRIGGER	= 14;	/// Trigger Name	Table Name
const int SQLITE_DROP_TEMP_VIEW		= 15;	/// View Name		NULL
const int SQLITE_DROP_TRIGGER		= 16;	/// Trigger Name	Table Name
const int SQLITE_DROP_VIEW		= 17;	/// View Name		NULL
const int SQLITE_INSERT			= 18;	/// Table Name		NULL
const int SQLITE_PRAGMA			= 19;	/// Pragma Name		1st arg or NULL
const int SQLITE_READ			= 20;	/// Table Name		Column Name
const int SQLITE_SELECT			= 21;	/// NULL		NULL
const int SQLITE_TRANSACTION		= 22;	/// NULL		NULL
const int SQLITE_UPDATE			= 23;	/// Table Name		Column Name
const int SQLITE_ATTACH			= 24;	/// Filename		NULL
const int SQLITE_DETACH			= 25;	/// Database Name	NULL
const int SQLITE_ALTER_TABLE		= 26;	/// Database Name	Table Name
const int SQLITE_REINDEX		= 27;	/// Index Name		NULL
const int SQLITE_ANALYZE		= 28;	/// Table Name		NULL
const int SQLITE_CREATE_VTABLE		= 29;	/// Table Name		Module Name
const int SQLITE_DROP_VTABLE		= 30;	/// Table Name		Module Name
const int SQLITE_FUNCTION		= 31;	/// Function Name	NULL

const int SQLITE_INDEX_CONSTRAINT_EQ	= 2;	///
const int SQLITE_INDEX_CONSTRAINT_GT	= 4;	///
const int SQLITE_INDEX_CONSTRAINT_LE	= 8;	///
const int SQLITE_INDEX_CONSTRAINT_LT	= 16;	///
const int SQLITE_INDEX_CONSTRAINT_GE	= 32;	///
const int SQLITE_INDEX_CONSTRAINT_MATCH = 64;	///

const int SQLITE_IOERR_READ		= SQLITE_IOERR | (1<<8); ///
const int SQLITE_IOERR_SHORT_READ	= SQLITE_IOERR | (2<<8); ///
const int SQLITE_IOERR_WRITE		= SQLITE_IOERR | (3<<8); ///
const int SQLITE_IOERR_FSYNC		= SQLITE_IOERR | (4<<8); ///
const int SQLITE_IOERR_DIR_FSYNC	= SQLITE_IOERR | (5<<8); ///
const int SQLITE_IOERR_TRUNCATE		= SQLITE_IOERR | (6<<8); ///
const int SQLITE_IOERR_FSTAT		= SQLITE_IOERR | (7<<8); ///
const int SQLITE_IOERR_UNLOCK		= SQLITE_IOERR | (8<<8); ///
const int SQLITE_IOERR_RDLOCK		= SQLITE_IOERR | (9<<8); ///

extern (C):

/**
 *
 */
void* sqlite3_aggregate_context (sqlite3_context* ctx, int nBytes);

/**
 *
 */
deprecated int sqlite3_aggregate_count (sqlite3_context* ctx);

/**
 *
 */
int sqlite3_auto_extension (void* xEntryPoint);

/**
 *
 */
int sqlite3_bind_blob (sqlite3_stmt* stmt, int index, void* value, int n, void function(void*) destructor);

/**
 *
 */
int sqlite3_bind_double (sqlite3_stmt* stmt, int index, double value);

/**
 *
 */
int sqlite3_bind_int (sqlite3_stmt* stmt, int index, int value);

/**
 *
 */
int sqlite3_bind_int64 (sqlite3_stmt* stmt, int index, long value);

/**
 *
 */
int sqlite3_bind_null (sqlite3_stmt* stmt, int index);

/**
 *
 */
int sqlite3_bind_text (sqlite3_stmt* stmt, int index, char* value, int n, void function(void*) destructor);

/**
 *
 */
int sqlite3_bind_text16 (sqlite3_stmt* stmt, int index, void* value, int n, void function(void*) destructor);

/**
 *
 */
int sqlite3_bind_parameter_count (sqlite3_stmt* stmt);

/**
 *
 */
int sqlite3_bind_parameter_index (sqlite3_stmt* stmt, char* zName);

/**
 *
 */
char* sqlite3_bind_parameter_name (sqlite3_stmt* stmt, int n);

/**
 *
 */
int sqlite3_busy_handler (sqlite3* database, int function(void*, int) handler, void* n);

/**
 *
 */
int sqlite3_busy_timeout (sqlite3* database, int ms);

/**
 *
 */
int sqlite3_changes (sqlite3* database);

/**
 *
 */
int sqlite3_clear_bindings(sqlite3_stmt* statement);

/**
 *
 */
int sqlite3_close(sqlite3* database);

/**
 *
 */
int sqlite3_collation_needed (sqlite3* database, void* names, void function(void* names, sqlite3* database, int eTextRep, char* sequence));

/**
 *
 */
int sqlite3_collation_needed (sqlite3* database, void* names, void function(void* names, sqlite3* database, int eTextRep, void* sequence));

/**
 *
 */
void* sqlite3_column_blob (sqlite3_stmt* stmt, int iCol);

/**
 *
 */
int sqlite3_column_bytes (sqlite3_stmt* stmt, int iCol);

/**
 *
 */
int sqlite3_column_bytes16 (sqlite3_stmt* stmt, int iCol);

/**
 *
 */
double sqlite3_column_double (sqlite3_stmt* stmt, int iCol);

/**
 *
 */
int sqlite3_column_int (sqlite3_stmt* stmt, int iCol);

/**
 *
 */
long sqlite3_column_int64 (sqlite3_stmt* stmt, int iCol);

/**
 *
 */
char* sqlite3_column_text (sqlite3_stmt* stmt, int iCol);

/**
 *
 */
void* sqlite3_column_text16 (sqlite3_stmt* stmt, int iCol);

/**
 *
 */
int sqlite3_column_type (sqlite3_stmt* stmt, int iCol);

/**
 *
 */
int sqlite3_column_count (sqlite3_stmt* stmt);

/**
 *
 */
char* sqlite3_column_database_name (sqlite3_stmt* stmt, int n);

/**
 *
 */
void* sqlite3_column_database_name16 (sqlite3_stmt* stmt, int n);

/**
 *
 */
char* sqlite3_column_decltype (sqlite3_stmt* stmt, int i);

/**
 *
 */
void* sqlite3_column_decltype16 (sqlite3_stmt* stmt, int i);

/**
 *
 */
char* sqlite3_column_name (sqlite3_stmt* stmt, int n);

/**
 *
 */
void* sqlite3_column_name16 (sqlite3_stmt* stmt, int n);

/**
 *
 */
char* sqlite3_column_origin_name (sqlite3_stmt* stmt, int n);

/**
 *
 */
void* sqlite3_column_origin_name16 (sqlite3_stmt* sStmt, int n);

/**
 *
 */
char* sqlite3_column_table_name (sqlite3_stmt* stmt, int n);

/**
 *
 */
void* sqlite3_column_table_name16 (sqlite3_stmt* stmt, int n);

/**
 *
 */
sqlite3_value* sqlite3_column_value (sqlite3_stmt* stmt, int iCol);

/**
 *
 */
void* sqlite3_commit_hook (sqlite3* database, int function(void* args) xCallback, void* args);

/**
 *
 */
int sqlite3_complete (char* sql);

/**
 *
 */
int sqlite3_complete16 (void* sql);

/**
 *
 */
int sqlite3_create_collation (sqlite3* database, char* zName, int pref16, void* routine, int function(void*, int, void*, int, void*) xCompare);

/**
 *
 */
int sqlite3_create_collation16 (sqlite3* database, char* zName, int pref16, void* routine, int function(void*, int, void*, int, void*) xCompare);

/**
 *
 */
int sqlite3_create_function (sqlite3* database, char* zFunctionName, int nArg, int eTextRep, void* pUserData, void function(sqlite3_context*, int, sqlite3_value**) xFunc, void function(sqlite3_context*, int, sqlite3_value**) xStep, void function(sqlite3_context*) xFinal);

/**
 *
 */
int sqlite3_create_function (sqlite3* database, void* zFunctionName, int nArg, int eTextRep, void* pUserData, void function(sqlite3_context*, int, sqlite3_value**) xFunc, void function(sqlite3_context*, int, sqlite3_value**) xStep, void function(sqlite3_context*) xFinal);

/**
 *
 */
int sqlite3_create_module (sqlite3* db,	char* zName, sqlite3_module* methods, void* data);

/**
 *
 */
int sqlite3_data_count (sqlite3_stmt* stmt);

/**
 *
 */
sqlite3* sqlite3_db_handle (sqlite3_stmt* stmt);

/**
 *
 */
int sqlite3_declare_vtab (sqlite3* db, char* zCreateTable);

/**
 *
 */
int sqlite3_enable_load_extension (sqlite3* db, int onoff);

/**
 *
 */
int sqlite3_enable_shared_cache (int enable);

/**
 *
 */
int sqlite3_errcode (sqlite3* db);

/**
 *
 */
char* sqlite3_errmsg (sqlite3* database);

/**
 *
 */
void* sqlite3_errmsg16 (sqlite3* database);

/**
 *
 */
int sqlite3_exec (sqlite3* database, char* sql, sqlite_callback routine, void* arg, char** errmsg);

/**
 *
 */
int sqlite3_expired (sqlite3_stmt* stmt);

/**
 *
 */
int sqlite3_extended_result_codes (sqlite3* database, int onoff);

/**
 *
 */
int sqlite3_finalize (sqlite3_stmt* stmt);

/**
 *
 */
void sqlite3_free (char* ptr);

/**
 *
 */
int sqlite3_get_table (sqlite3* database, char* sql, char*** resultp, int* nrow, int* ncolumn, char** errmsg);

/**
 *
 */
void sqlite3_free_table (char** result);

/**
 *
 */
int sqlite3_get_autocommit (sqlite3* database);

/**
 *
 */
int sqlite3_global_recover ();

/**
 *
 */
void sqlite3_interrupt (sqlite3* database);

/**
 *
 */
long sqlite3_last_insert_rowid (sqlite3* database);

/**
 *
 */
char* sqlite3_libversion ();

/**
 *
 */
int sqlite3_load_extension (sqlite3* db, char* zFile, char* zProc, char** ppErrMsg);

/**
 *
 */
void* sqlite3_malloc (int size);

/**
 *
 */
char* sqlite3_mprintf (char* string, ...);

/**
 *
 */
char* sqlite3_vmprintf (char* string, va_list args);

/**
 *
 */
int sqlite3_open (char* filename, sqlite3** database);

/**
 *
 */
int sqlite3_open16 (void* filename, sqlite3** database);

/**
 *
 */
int sqlite3_overload_function (sqlite3* database, char* zFuncName, int nArg);

/**
 *
 */
int sqlite3_prepare (sqlite3* database, char* zSql, int nBytes, sqlite3_stmt** stmt, char** zTail);

/**
 *
 */
int sqlite3_prepare16 (sqlite3* database, void* zSql, int nBytes, sqlite3_stmt** stmt, void** zTail);

/**
 *
 */
int sqlite3_prepare_v2 (sqlite3* database, char* zSql, int nBytes, sqlite3_stmt** stmt, char** zTail);

/**
 *
 */
int sqlite3_prepare16_v2 (sqlite3* database, void* zSql, int nBytes, sqlite3_stmt** stmt, void** zTail);

/**
 *
 */
void sqlite3_progress_handler (sqlite3* database, int n, int function(void*) callback, void* arg);

/**
 *
 */
void* sqlite3_realloc (void* ptr, int size);

/**
 *
 */
int sqlite3_release_memory (int n);

/**
 *
 */
int sqlite3_reset (sqlite3_stmt* stmt);

/**
 *
 */
void sqlite3_reset_auto_extension ();

/**
 *
 */
void sqlite3_result_blob (sqlite3_context* context, void* value, int n, void function(void*) destructor);

/**
 *
 */
void sqlite3_result_double (sqlite3_context* context, double value);

/**
 *
 */
void sqlite3_result_error (sqlite3_context* context, char* value, int n);

/**
 *
 */
void sqlite3_result_error16 (sqlite3_context* context, void* value, int n);

/**
 *
 */
void sqlite3_result_int (sqlite3_context* context, int value);

/**
 *
 */
void sqlite3_result_int64 (sqlite3_context* context, long value);

/**
 *
 */
void sqlite3_result_null (sqlite3_context* context);

/**
 *
 */
void sqlite3_result_text (sqlite3_context* context, char* value, int n, void function(void*) destructor);

/**
 *
 */
void sqlite3_result_text16 (sqlite3_context* context, void* value, int n, void function(void*) destructor);

/**
 *
 */
void sqlite3_result_text16be (sqlite3_context* context, void* value, int n, void function(void*) destructor);

/**
 *
 */
void sqlite3_result_text16le (sqlite3_context* context, void* value, int n, void function(void*) destructor);

/**
 *
 */
void sqlite3_result_value (sqlite3_context* context, sqlite3_value* value);

/**
 *
 */
void* sqlite3_rollback_hook (sqlite3* database, void function(void*) callback, void* args);

/**
 *
 */
int sqlite3_set_authorizer (sqlite3* database, int function(void*, int, char*, char*, char*, char*) xAuth, void* UserData);

/**
 *
 */
int sqlite3_sleep (int ms);

/**
 *
 */
void sqlite3_soft_heap_limit (int n);

/**
 *
 */
int sqlite3_step (sqlite3_stmt* stmt);

/**
 *
 */
int sqlite3_table_column_metadata (sqlite3* database, char* zDbName, char* zTableName, char* zColumnName, char** zDataType, char** zCollSeq, int* notNull, int* primaryKey, int* autoInc);

/**
 *
 */
void sqlite3_thread_cleanup ();

/**
 *
 */
int sqlite3_total_changes (sqlite3* database);

/**
 *
 */
void* sqlite3_trace (sqlite3* database, void function(void*, char*) xTrace, void* args);

/**
 *
 */
int sqlite3_transfer_bindings (sqlite3_stmt* stmt, sqlite3_stmt* stmt);

/**
 *
 */
void* sqlite3_update_hook (sqlite3* database, void function(void*, int, char*, char*, long) callback, void* args);

/**
 *
 */
void* sqlite3_user_data (sqlite3_context* context);

/**
 *
 */
void* sqlite3_value_blob (sqlite3_value* value);

/**
 *
 */
int sqlite3_value_bytes (sqlite3_value* value);

/**
 *
 */
int sqlite3_value_bytes16 (sqlite3_value* value);

/**
 *
 */
double sqlite3_value_double (sqlite3_value* value);

/**
 *
 */
int sqlite3_value_int (sqlite3_value* value);

/**
 *
 */
long sqlite3_value_int64 (sqlite3_value* value);

/**
 *
 */
char* sqlite3_value_text (sqlite3_value* value);

/**
 *
 */
void* sqlite3_value_text16 (sqlite3_value* value);

/**
 *
 */
void* sqlite3_value_text16be (sqlite3_value* value);

/**
 *
 */
void* sqlite3_value_text16le (sqlite3_value* value);

/**
 *
 */
int sqlite3_value_type (sqlite3_value* value);