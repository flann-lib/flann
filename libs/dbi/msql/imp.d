/**
 * mSQL import library.
 *
 * Part of the D DBI project.
 *
 * Version:
 *	mSQL version 3.8
 *
 *	Import library version 0.02
 *
 * Authors: The D DBI project
 *
 * Copyright: BSD license
 */
module dbi.msql.imp;

version (Windows) {
	pragma (msg, "You will need to manually link in the mSQL library.");
} else version (linux) {
	pragma (lib, "libmsql.a");
} else version (Posix) {
	pragma (lib, "libmsql.a");
} else version (darwin) {
	pragma (msg, "You will need to manually link in the mSQL library.");
} else {
	pragma (msg, "You will need to manually link in the mSQL library.");
}

private import std.c.time;

const uint INT_TYPE		= 1;		///
const uint CHAR_TYPE		= 2;		///
const uint REAL_TYPE		= 3;		///
const uint IDENT_TYPE		= 4;		///
const uint NULL_TYPE		= 5;		///
const uint TEXT_TYPE		= 6;		///
const uint DATE_TYPE		= 7;		///
const uint UINT_TYPE		= 8;		///
const uint MONEY_TYPE		= 9;		///
const uint TIME_TYPE		= 10;		///
const uint IPV4_TYPE		= 11;		///
const uint INT64_TYPE		= 12;		///
const uint UINT64_TYPE		= 13;		///
const uint INT8_TYPE		= 14;		///
const uint INT16_TYPE		= 15;		///
const uint UINT8_TYPE		= 16;		///
const uint UINT16_TYPE		= 17;		///
const uint BYTE_TYPE		= 18;		///
const uint CIDR4_TYPE		= 19;		///
const uint CIDR6_TYPE		= 21;		///
const uint DATETIME_TYPE	= 20;		///
const uint MILLITIME_TYPE	= 22;		///
const uint MILLIDATETIME_TYPE	= 23;		///

const uint LAST_REAL_TYPE	= 23;		///
const uint IDX_TYPE		= 253;		///
const uint SYSVAR_TYPE		= 254;		///
const uint ANY_TYPE		= 255;		///

const uint NOT_NULL_FLAG   	= 1;		///
const uint UNIQUE_FLAG		= 2;		///

const uint MSQL_PKT_LEN		= 131072;	///

const char[12][] msqlTypeNames	= ["???", "int", "char", "real", "ident", "null", "text", "date", "uint", "money","time","ip","int64","uint64","int8","int16","cidr4", "cidr6", "???"]; ///

/**
 *
 */
alias char** m_row;

/**
 *
 */
struct field_s {
	char*name, table;
	int type, length, flags;
}
alias field_s m_field;

/**
 *
 */
struct m_seq_s {
	int step, value;
}
alias m_seq_s m_seq;

/**
 *
 */
struct m_data_s {
	int width;
	m_row data;
	m_data_s* next;
}
alias m_data_s m_data;

/**
 *
 */
struct m_fdata_s {
	m_field	field;
	m_fdata_s* next;
}
alias m_fdata_s m_fdata;

/**
 *
 */
struct result_s {
        m_data* queryData, cursor;
	m_fdata* fieldData, fieldCursor;
	int numRows, numFields;
}
alias result_s m_result;

/**
 * Deprecated:
 *	Use msqlGetErrMsg directly.
 */
deprecated char* msqlErrMsg () {
	return msqlGetErrMsg(null);
}

/**
 * Get the number of rows in a result set.
 *
 * Params:
 *	result = The result set to read from.
 *
 * Returns:
 *	The number of rows.
 */
int msqlNumRows (m_result result) {
	return result.numRows;
}

/**
 * Get the number of fields in a result set.
 *
 * Params:
 *	result = The result set to read from.
 *
 * Returns:
 *	The number of fields.
 */
int mysqlNumFields (m_result result) {
	return result.numFields;
}

/**
 *
 */
bool IS_NOT_NULL (uint n) {
	return (n && NOT_NULL_FLAG);
}

/**
 *
 */
bool IS_UNIQUE (uint n) {
	return (n && UNIQUE_FLAG);
}

extern (C):

version (Windows) {
	/**
	 *
	 */
	int msqlUserConnect (char*, char*);

	/**
	 *
	 */
	char* msqlGetWinRegistryEntry (char*, char*, int);
}

/**
 *
 */
int msqlLoadConfigFile (char*);

/**
 *
 */
char* msqlGetErrMsg (char*);

/**
 * Connect to a mSQL server.
 *
 * Params:
 *	host = The name or IP address of the server to connect to.  Use null for localhost.
 *
 * Returns:
 *	The database handle on success and -1 on failure.
 */
int msqlConnect (char* host);

/**
 * Select a database on the server.
 *
 * Params:
 *	sock = The database handle.
 *	dbName = The name of the database to use.
 *
 * Returns:
 *	-1 on failure.
 */
int msqlSelectDB (int sock, char* dbName);

/**
 * Execute a SQL query.
 *
 * Params:
 *	sock = The database handle.
 *	query = The SQL _query to execute.
 *
 * Returns:
 *	The number of rows used on success and -1 on failure.
 */
int msqlQuery (int sock, char* query);

/**
 *
 */
int msqlExplain (int, char*);

/**
 *
 */
int msqlCreateDB (int, char*);

/**
 *
 */
int msqlDropDB (int, char*);

/**
 *
 */
int msqlShutdown (int);

/**
 *
 */
int msqlGetProtoInfo ();

/**
 *
 */
int msqlReloadAcls (int);

/**
 *
 */
int msqlGetServerStats (int);

/**
 *
 */
int msqlCopyDB (int, char*, char*);

/**
 *
 */
int msqlMoveDB (int, char*, char*);

/**
 * Get the number of days between two mSQL dates.
 *
 * Params:
 *	date1 = A string containing "DD:Mon:YYYY" using English month names.
 *	date2 = A string containing "DD:Mon:YYYY" using English month names.
 *
 * Returns:
 *	The number of days between date1 and date2.
 */
int msqlDiffDates (char* date1, char* date2);

/**
 * Load a configuation file.
 *
 * Params:
 *	file = The name of the file.
 *
 * Returns:
 *	0 on success and -1 on failure.
 */
int msqlLoadConfigFile (char* file);

/**
 *
 */
int msqlGetIntConf (char*, char*);

/**
 *
 */
char* msqlGetCharConf (char*, char*);

/**
 *
 */
char* msqlGetServerInfo ();

/**
 *
 */
char* msqlGetHostInfo ();

/**
 * Convert a standard UNIX time to a mSQL time.
 *
 * Params:
 *	clock = The number of seconds since January 1, 1970.
 *
 * Returns:
 *	A string containing "HH:MM:SS" in a 24 hour format.
 */
char* msqlUnixTimeToTime (int clock);

/**
 * Convert a standard UNIX time to a mSQL date.
 *
 * Params:
 *	clock = The number of seconds since January 1, 1970.
 *
 * Returns:
 *	A string containing "DD:Mon:YYYY" using English month names.
 */
char* msqlUnixTimeToDate (int clock);

/**
 *
 */
char* msqlUnixTimeToDatetime (int);

/**
 *
 */
char* msqlUnixTimeToMillitime (int);

/**
 *
 */
char* msqlUnixTimeToMillidatetime (int);

/**
 * Get the sum of two mSQL times.
 *
 * Params:
 *	time1 = A string containing "HH:MM:SS" in a 24 hour format.
 *	time2 = A string containing "HH:MM:SS" in a 24 hour format.
 *
 * Returns:
 *	The sum of the times.
 */
char* msqlSumTimes (char* time1, char* time2);

/**
 * Get the difference between two mSQL times.
 *
 * Params:
 *	time1 = A string containing "HH:MM:SS" in a 24 hour format.
 *	time2 = A string containing "HH:MM:SS" in a 24 hour format.
 *
 * Returns:
 *	The difference between the times.
 */
char* msqlDiffTimes (char* time1, char* time2);

/**
 * Change a mSQL date by a certain amount of time.
 *
 * Params:
 *	date = A string containing "DD:Mon:YYYY" using English month names.
 *	dOff = The number of days to move.
 *	mOff = The number of months to move.
 *	yOff = The number of years to move.
 *
 * Returns:
 *	A string containing "DD:Mon:YYYY" using English month names offset the specified amount of time.
 */
char* msqlDateOffset (char* date, int dOff, int mOff, int yOff);

/**
 *
 */
char* msqlTypeName (int);

/**
 * Close a connection to the mSQL server.
 *
 * Params:
 *	sock = The database handle.
 */
void msqlClose (int sock);

/**
 * Set the position to read a row from in a result set.
 *
 * Params:
 *	result = The result set that needs the changed pointer.
 *	pos = The zero-based index to read from next.
 */
void msqlDataSeek (m_result* result, int pos);

/**
 * Set the position to read a field from in a result set.
 *
 * Params:
 *	result = The result set that needs the changed pointer.
 *	pos = The zero-based index to read from next.
 */
void msqlFieldSeek (m_result* result, int pos);

/**
 * Free the memory used by a stored result set.
 *
 * Params:
 *	result = The result set to erase.
 */
void msqlFreeResult (m_result* result);

/**
 * Get a row from a stored result set.
 *
 * Params:
 *	result = The result set to read.
 *
 * Returns:
 *	The next row if it exists or null otherwise.
 */
m_row msqlFetchRow (m_result* result);

/**
 *
 */
m_seq* msqlGetSequenceInfo (int, char*);

/**
 * Get information about what type of data can be stored in a field.
 *
 * Params:
 *	result = The result set to analyze.
 *
 * Returns:
 *	The next field if it exists or null otherwise.
 */
m_field* msqlFetchField (m_result* result);

/**
 * Get the names of all of the databases.
 *
 * Params:
 *	sock = The database handle.
 *
 * Returns:
 *	A result set with a single field containing the database names.
 */
m_result* msqlListDBs (int sock);

/**
 * Get the names of all of the tables in the current database.
 *
 * Params:
 *	sock = The database handle.
 *
 * Returns:
 *	A result set with a single field containing the table names.
 */
m_result* msqlListTables (int sock);

/**
 * Get the names of all of the fields in the current database.
 *
 * Params:
 *	sock = The database handle.
 *
 * Returns:
 *	A result set with a single field containing the field names.
 */
m_result* msqlListFields (int sock , char* tableName);

/**
 * Get the structure of a table index.
 *
 * Params:
 *	sock = The database handle.
 *	tableName = The name of the table to analyze.
 *	index = The type of index.  Only "avl" is accepted right now.
 *
 * Returns:
 *	A result set containing the structure information.  See the mSQL manual for more information.
 */
m_result* msqlListIndex (int sock, char* tableName, char* index);

/**
 * Store a result set to memory so it isn't erased when a new query is executed.
 *
 * Returns:
 *	The stored query results.
 */
m_result* msqlStoreResult ();

/**
 *
 */
time_t msqlDateToUnixTime (char*);

/**
 * Convert a mSQL time to a standard UNIX time.
 *
 * Params:
 *	msqltime = A string containing "HH:MM:SS" in a 24 hour format.
 *
 * Returns:
 *	The number of seconds since January 1, 1970.
 */
time_t msqlTimeToUnixTime (char* msqltime);

/**
 * Convert a mSQL date to a standard UNIX time.
 *
 * Params:
 *	msqldate = A string containing "DD:Mon:YYYY" using English month names.
 *
 * Returns:
 *	The number of seconds since January 1, 1970.
 */
time_t msqlDatetimeToUnixTime (char* msqldate);

/**
 *
 */
time_t msqlMillitimeToUnixTime (char*);

/**
 *
 */
time_t msqlMillidatetimeToUnixTime (char*);