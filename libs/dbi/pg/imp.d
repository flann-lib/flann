/**
 * PostgreSQL import library.
 *
 * Part of the D DBI project.
 *
 * Version:
 *	PostgreSQL version 8.2.1
 *
 *	Import library version 1.04
 *
 * Authors: The D DBI project
 *
 * Copyright: BSD license
 */
module dbi.pg.imp;

private import std.c.stdio;

version (Windows) {
	pragma (lib, "libpq.lib");
} else version (linux) {
	pragma (lib, "libpq.a");
} else version (Posix) {
	pragma (lib, "libpq.a");
} else version (darwin) {
	pragma (lib, "libpq.a");
} else {
	pragma (msg, "You will need to manually link in the PostgreSQL library.");
}

/**
 * This type is used with PQprint because C doesn't have a _true boolean type.
 */
alias byte pqbool;

/**
 * Object ID is a fundamental type in PostgreSQL.
 */
typedef uint Oid;

/**
 * InvalidOid indicates that something went wrong.  Try checking for errors.
 */
const Oid InvalidOid			= 0;

/**
 * Deprecated:
 *	Use Oid.max directly.
 */
deprecated const Oid OID_MAX		= Oid.max;

/**
 * This is the max length for system identifiers.  It must be a multiple of int.sizeof.
 *
 * Databases with different NAMEDATALEN values cannot interoperate!
 */
const uint NAMEDATALEN			= 64;

/**
 * Identifiers of error message fields.
 */
const char PG_DIAG_SEVERITY		= 'S';
const char PG_DIAG_SQLSTATE		= 'C';
const char PG_DIAG_MESSAGE_PRIMARY	= 'M';
const char PG_DIAG_MESSAGE_DETAIL	= 'D';
const char PG_DIAG_MESSAGE_HINT		= 'H';
const char PG_DIAG_STATEMENT_POSITION	= 'P';
const char PG_DIAG_INTERNAL_POSITION	= 'p';
const char PG_DIAG_INTERNAL_QUERY	= 'q';
const char PG_DIAG_CONTEXT		= 'W';
const char PG_DIAG_SOURCE_FILE		= 'F';
const char PG_DIAG_SOURCE_LINE		= 'L';
const char PG_DIAG_SOURCE_FUNCTION	= 'R';

/**
 * Read/write mode flags for inversion (large object) calls.
 */
const uint INV_WRITE			= 0x20000;
const uint INV_READ			= 0x40000;


/**
 * Define the string so all uses are consistent.
 */
const char[] PQnoPasswordSupplied	= "fe_sendauth: no password supplied\n";


/**
 * This is actually from std.c.stdio, but it is used with the large objects.
 */
enum {
	SEEK_SET,	/// Start seeking from the start.
	SEEK_CUR,	/// Start seeking from the current position.
	SEEK_END	/// Start seeking from the end.
}

/**
 * ConnStatusType is the structure that describes the current status of the
 * connection to the server.
 */
enum ConnStatusType {
	/*
	 * Although it is okay to add to this list, values which become unused
	 * should never be removed, nor should constants be redefined - that would
	 * break compatibility with existing code.
	 */
	CONNECTION_OK,			/// Everything is working.
	CONNECTION_BAD,			/// Error in the connection.
	/* Non-blocking mode only below here. */

	/*
	 * The existence of these should never be relied upon - they should only
	 * be used for user feedback or similar purposes.
	 */
	CONNECTION_STARTED,		/// Waiting for connection to be made.
	CONNECTION_MADE,		/// Connection OK; waiting to send.
	CONNECTION_AWAITING_RESPONSE,	/// Waiting for a response from the postmaster.
	CONNECTION_AUTH_OK,		/// Received authentication; waiting for backend startup.
	CONNECTION_SETENV,		/// Negotiating environment.
	CONNECTION_SSL_STARTUP,		/// Negotiating SSL.
	CONNECTION_NEEDED		/// Internal state: connect() needed.
}

/**
 * PostgresPollingStatusType is the structure that describes the current status of a non-blocking command.
 */
enum PostgresPollingStatusType {
	PGRES_POLLING_FAILED = 0,	/// Something went wrong.
	PGRES_POLLING_READING,		/// You may use select before polling again.
	PGRES_POLLING_WRITING,		/// You may use select before polling again.
	PGRES_POLLING_OK,		/// The work has been completed.
	PGRES_POLLING_ACTIVE		/// Unused; keep for awhile for backwards compatibility.
}

/**
 * ExecStatusType is the structure that describes the results.
 */
enum ExecStatusType {
	PGRES_EMPTY_QUERY = 0,		/// Empty query string was executed.
	PGRES_COMMAND_OK,		/// A query command that doesn't return anything was executed properly by the backend.
	PGRES_TUPLES_OK,		/// A query command that returns tuples was executed properly by the backend, PGresult contains the result tuples.
	PGRES_COPY_OUT,			/// Copy Out data transfer in progress.
	PGRES_COPY_IN,			/// Copy In data transfer in progress.
	PGRES_BAD_RESPONSE,		/// An unexpected response was received from the backend.
	PGRES_NONFATAL_ERROR,		/// Notice or warning message.
	PGRES_FATAL_ERROR		/// Query failed.
}

/**
 * PGTransactionStatusType is the structure that describes the current status of the transaction.
 */
enum PGTransactionStatusType {
	PQTRANS_IDLE,			/// Connection idle.
	PQTRANS_ACTIVE,			/// Command in progress.
	PQTRANS_INTRANS,		/// Idle, within transaction block.
	PQTRANS_INERROR,		/// Idle, within failed transaction.
	PQTRANS_UNKNOWN			/// Cannot determine status.
}

/**
 * PGVerbosity is the structure that describes how verbose error message should be.
 */
enum PGVerbosity {
	PQERRORS_TERSE,			/// Single-line error messages.
	PQERRORS_DEFAULT,		/// Recommended style.
	PQERRORS_VERBOSE		/// All the facts.
}

/**
 * PGconn encapsulates a connection to the backend.
 *
 * The contents of this struct are not supposed to be known to applications.
 */
struct PGconn {
}

/**
 * PGresult encapsulates the result of a query (or more precisely, of a single
 * SQL command --- a query string given to PQsendQuery can contain multiple
 * commands and thus return multiple PGresult objects).
 *
 * The contents of this struct are not supposed to be known to applications.
 */
struct PGresult {
}

/**
 * PGcancel encapsulates the information needed to cancel a running
 * query on an existing connection.
 *
 * The contents of this struct are not supposed to be known to applications.
 */
struct PGcancel {
}

/**
 * PGnotify represents the occurrence of a NOTIFY message.
 *
 * Ideally this would be an opaque typedef, but it's so simple that it's
 * unlikely to change.
 *
 * Note:
 *	In Postgres 6.4 and later, the be_pid is the notifying backend's,
 * whereas in earlier versions it was always your own backend's PID.
 */
struct pgNotify {
	char* relname;			/// Notification condition name.
	int be_pid;			/// Process ID of notifying server process.
	char* extra;			/// Notification parameter.
	/* Fields below here are private to libpq; apps should not use 'em */
	pgNotify* next;			/// List link.
}
alias pgNotify PGnotify;

/**
 * Function types for notice-handling callbacks.
 */
alias void function(void* arg, PGresult* res) PQnoticeReceiver;
alias void function(void* arg, char* message) PQnoticeProcessor;

/**
 * Print options for PQprint().
 */
struct _PQprintOpt {
	pqbool header;			/// Print output field headings and row count.
	pqbool alignment;		/// Fill align the fields.
	pqbool standard;		/// Old brain dead format.
	pqbool html3;			/// Output html tables.
	pqbool expanded;		/// Expand tables.
	pqbool pager;			/// Use pager for output if needed.
	char* fieldSep;			/// Field separator.
	char* tableOpt;			/// Insert a table in HTML.
	char* caption;			/// Insert a caption in HTML.
	char** fieldName;		/// Null terminated array of replacement field names.
}
alias _PQprintOpt PQprintOpt;

/**
 * Structure for the conninfo parameter definitions returned by PQconndefaults
 *
 * All fields except "val" point at static strings which must not be altered.
 * "val" is either NULL or a malloc'd current-value string.  PQconninfoFree()
 * will release both the val strings and the PQconninfoOption array itself.
 */
struct _PQconninfoOption {
	char* keyword;			/// The keyword of the option.
	char* envvar;			/// Fallback environment variable name.
	char* compiled;			/// Fallback compiled in default value.
	char* val;			/// Option's current value, or null.
	char* label;			/// Label for field in connect dialog.
	char* dispchar;			/// Character to display for this field in a connect dialog. Values are: "" Display entered value as is "*" Password field - hide value "D"  Debug option - don't show by default.
	int dispsize;			/// Field size in characters for dialog.
}
alias _PQconninfoOption PQconninfoOption;

/**
 * PQArgBlock is the structure used for PQfn arguments.
 *
 * Deprecated:
 *	This is only used for PQfn and that is deprecated.
 */
deprecated struct PQArgBlock {
	int len;
	int isint;
	union u {
		void* ptr;
		int integer;
	}
}

extern (C):

/**
 * Make a new connection to the database server in a nonblocking manner.
 *
 * Params:
 *	conninfo = Parameters to use when connecting.
 *
 * Returns:
 *	A PostgreSQL connection that is inactive.
 *
 * See_Also:
 *	The online PostgreSQL documentation describes what you can use in conninfo.
 */
PGconn* PQconnectStart (char* conninfo);

/**
 * Get the current status of the nonblocking PostgreSQL connection.
 *
 * Params:
 *	conn = The nonblocking PostgreSQL connection.
 *
 * Returns:
 *	A PostgrePollingStatusType describing the current condition of the connection.
 */
PostgresPollingStatusType PQconnectPoll (PGconn* conn);

/**
 * Make a new connection to the database server in a blocking manner.
 *
 * Params:
 *	conninfo = Parameters to use when connecting.
 *
 * Returns:
 *	The PostgreSQL connection.
 *
 * See_Also:
 *	The online PostgreSQL documentation describes what you can use in conninfo.
 */
PGconn* PQconnectdb (char* conninfo);

/**
 * Make a new connection to the database server in a blocking manner.
 *
 * Deprecated:
 *	Although this isn't actually deprecated, it is preferred that you use PQconnectdb.
 *
 * Params:
 *	pghost = Name of the host to connect to.  Defaults to either a Unix socket or localhost.
 *	pgport = Port number to connect to the server with.  Defaults to nothing.
 *	pgoptions = Command line options to send to the server.  Defaults to nothing.
 *	pgtty = Currently ignored.
 *	dbName = The name of the database to use.  Defaults to login.
 *	login = Username to authenticate with.  Defaults to the current OS username.
 *	pwd = Password to authenticate with.
 *
 * Returns:
 *	The PostgreSQL connection.
 */
PGconn* PQsetdbLogin (char* pghost, char* pgport, char* pgoptions, char* pgtty, char* dbName, char* login, char* pwd);

/**
 * Make a new connection to the database server in a blocking manner.
 *
 * Deprecated:
 *	This is deprecated in favor of PQsetdbLogin, but PQconnectdb is an even better choice.
 *
 * Params:
 *	pghost = Name of the host to connect to.  Defaults to either a Unix socket or localhost.
 *	pgport = Port number to connect to the server with.  Defaults to nothing.
 *	pgoptions = Command line options to send to the server.  Defaults to nothing.
 *	pgtty = Currently ignored.
 *	dbName = The name of the database to use.  Defaults to the login username.
 *
 * Returns:
 *	The PostgreSQL connection.
 */
deprecated void PQsetdb (char* M_PGHOST, char* M_PGPORT, char* M_PGOPT, char* M_PGTTY, char* M_DBNAME) {
	PQsetdbLogin(M_PGHOST, M_PGPORT, M_PGOPT, M_PGTTY, M_DBNAME, null, null);
}

/**
 * Close the PostgreSQL connection and free the memory it used.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 */
void PQfinish (PGconn* conn);

/**
 * Get the default connection options.
 *
 * Returns:
 *	A PQconninfoOption structure with all of the default values filled in.
 */
PQconninfoOption* PQconndefaults ();

/**
 * Free the memory used by a PQconninfoOption structure.
 *
 * Params:
 *	connOptions = The PQconnifoOption structure to erase.
 */
void PQconninfoFree (PQconninfoOption* connOptions);

/**
 * Reset the connection to PostgreSQL in a nonblocking manner.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	1 on success and 0 on failure.
 */
int PQresetStart (PGconn* conn);

/**
 * Get the current status of the nonblocking reset of the PostgreSQL connection.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	A PostgrePollingStatusType describing the current condition of the connection.
 */
PostgresPollingStatusType PQresetPoll (PGconn* conn);

/**
 * Reset the connection to PostgreSQL in a blocking manner.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 */
void PQreset (PGconn* conn);

/**
 * Create the structure used to cancel commands.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	The PGcancel structure on success or null on failure.
 */
PGcancel* PQgetCancel (PGconn* conn);

/**
 * Free the memory used by a PGcancel structure.
 *
 * Params:
 *	cancel = The PGcancel structure to erase.
 */
void PQfreeCancel (PGcancel* cancel);

/**
 * Request that the server stops processing the current command.
 *
 * Params:
 *	cancel = The PGcancel structure returned by PQgetCancel.
 *	errbuf = A buffer to place the reason PQcancel failed in.
 *	errbufsize = The size of errbuf.  The recommended size is 256.
 *
 * Returns:
 *	1 on success and 0 on failure.
 */
int PQcancel (PGcancel* cancel, char* errbuf, int errbufsize);

/**
 * Request that the server stops processing the current command.
 *
 * Deprecated:
 *	PQcancel should be used instead because it is thread-safe.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 */
deprecated int PQrequestCancel (PGconn* conn);

/**
 * Get the name of the database used in the connection.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	The database name.
 */
char* PQdb (PGconn* conn);

/**
 * Get the username used in the connection.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	The username.
 */
char* PQuser (PGconn* conn);

/**
 * Get the password used in the connection.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	The password.
 */
char* PQpass (PGconn* conn);

/**
 * Get the server host name used in the connection.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	The server host name.
 */
char* PQhost (PGconn* conn);

/**
 * Get the port used in the connection.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	The port.
 */
char* PQport (PGconn* conn);

/**
 * Deprecated:
 *	This no longer has any effect.  Don't use it.
 */
deprecated char* PQtty (PGconn* conn);

/**
 * Get the command line options used in the connection.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	The command line options.
 */
char* PQoptions (PGconn* conn);

/**
 * Get the status of the connection.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	A ConnStatusType value describing the current connection.
 */
ConnStatusType PQstatus (PGconn* conn);

/**
 * Get the current in-transaction status of the server.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	A PGTransactionStatusType value describing the status of the transaction.
 */
PGTransactionStatusType PQtransactionStatus (PGconn* conn);

/**
 * Get the current parameter settings of the server.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	A string containing various parameter settings of the server.
 *
 * See_Also:
 *	The online PostgreSQL documentation describes what is in the returned string.
 */
char* PQparameterStatus (PGconn* conn, char* paramName);

/**
 * Get the version of the protocol used in the connection.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	The protocol version.
 */
int PQprotocolVersion (PGconn* conn);

/**
 * Get the version of PostgreSQL used by the server..
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	The version of PostgreSQL.
 */
int PQserverVersion (PGconn* conn);

/**
 * Get the most recent error message from the connection.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	The most recent error message.
 */
char* PQerrorMessage (PGconn* conn);

/**
 * Get the socket used in the connection.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	The number that represents the socket.  A negative number is returned if no connection is open.
 */
int PQsocket (PGconn* conn);

/**
 * Get the PID of PostgreSQL on the server..
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	The PID.
 */
int PQbackendPID (PGconn* conn);

/**
 * Get the character encoding currently being used.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	The integer representation of the character encoding.
 */
int PQclientEncoding (PGconn* conn);

/**
 * Change the character encoding used in the connection.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	encoding = The string representation of the desired character _encoding.
 *
 * Returns:
 *	0 on success and -1 on failure.
 */
int PQsetClientEncoding (PGconn* conn, char* encoding);

/**
 * Get the OpenSSL structure associated with a connection.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	The SSL structure used in the connection or null if SSL is not in use.
 */
void* PQgetssl (PGconn* conn);

/**
 * Tell the interface that SSL has already been initialized within your application.
 *
 * Params:
 *	do_init = Set to 1 if you use SSL within your application and 0 otherwise.
 */
void PQinitSSL (int do_init);

/**
 * Set how verbose the error messages should be.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	verbosity = A PGVerbosity value of the desired setting.
 *
 * Returns:
 *	A PGVerbosity value with the previous setting.
 */
PGVerbosity PQsetErrorVerbosity (PGconn* conn, PGVerbosity verbosity);

/**
 * Start copying all of the communications with the server to a stream.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	debug_port = The CStream to send the data to.
 */
void PQtrace (PGconn* conn, FILE* debug_port);

/**
 * Stop copying all of the communications with the server to a stream.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 */
void PQuntrace (PGconn* conn);

/**
 * Change the function that formats the notices.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	proc = The new function.
 *	arg = Arguments to pass to the function whenever it is called.
 *
 * Returns:
 *	The previous function.
 */
PQnoticeReceiver PQsetNoticeReceiver (PGconn* conn, PQnoticeReceiver proc, void* arg);

/**
 * Change the function that handles the notices.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	proc = The new function.
 *	arg = Arguments to pass to the function whenever it is called.
 *
 * Returns:
 *	The previous function.
 */
PQnoticeProcessor PQsetNoticeProcessor (PGconn* conn, PQnoticeProcessor proc, void* arg);

/**
 * Used to set callback that prevents concurrent access to
 * non-thread safe functions that libpq needs.
 * The default implementation uses a libpq internal mutex.
 * Only required for multithreaded apps that use kerberos
 * both within their app and for postgresql connections.
 */
alias void function(int acquire) pgthreadlock_t;

/**
 *
 */
pgthreadlock_t PQregisterThreadLock (pgthreadlock_t newhandler);

/**
 * Submit a command to the server and wait for the results.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	query = The SQL command(s) to execute.
 *
 * Results:
 *	A PGresult structure containing the results or null on a serious error.
 */
PGresult* PQexec (PGconn* conn, char* query);

/**
 * Submit a command to the server and wait for the results.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	command = The SQL _command to execute.
 *	nParams = The number of parameters.
 *	paramTypes = An array of types specified using Oid.  Use null or 0 to have the server guess.
 *	paramValues = The parameters themselves in the expected format.
 *	paramLengths = An array of lengths of the parameters.  This is ignored for non-binary data.
 *	paramFormats = An array of formats of the parameters.  Use 0 for text and 1 for binary.
 *	resultFormat = Use 0 to obtain the results in text format and 1 for binary.
 *
 * Returns:
 *	A PGresult structure containing the results or null on a serious error.
 */
PGresult* PQexecParams (PGconn* conn, char* command, int nParams, Oid* paramTypes, char** paramValues, int* paramLengths, int* paramFormats, int resultFormat);

/**
 * Create a prepared statement and wait for completion.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	stmtName = The name to assign to the prepared statement.
 *	query = The SQL command to prepare.
 *	nParams = The number of parameters.
 *	paramTypes = An array of types specified using Oid.  Use null or 0 to have the server guess.
 *
 * Results:
 *	A PGresult structure containing the results or null on a serious error.
 */
PGresult* PQprepare (PGconn* conn, char* stmtName, char* query, int nParams, Oid* paramTypes);

/**
 * Execute a prepared statement and wait for the results.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	stmtName = The name of the prepared statement to execute.
 *	nParams = The number of parameters.
 *	paramValues = The parameters themselves in the expected format.
 *	paramLengths = An array of lengths of the parameters.  This is ignored for non-binary data.
 *	paramFormats = An array of formats of the parameters.  Use 0 for text and 1 for binary.
 *	resultFormat = Use 0 to obtain the results in text format and 1 for binary.
 *
 * Results:
 *	A PGresult structure containing the results or null on a serious error.
 */
PGresult* PQexecPrepared (PGconn* conn, char* stmtName, int nParams, char** paramValues, int* paramLengths, int* paramFormats, int resultFormat);

/**
 * Submit a command to the server without waiting for the results.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	query = The SQL command(s) to execute.
 *
 * Returns:
 *	1 on success or 0 on failure.
 */
int PQsendQuery (PGconn* conn, char* query);

/**
 * Submit a _command to the server without waiting for the results.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	command = The SQL _command to execute.
 *	nParams = The number of parameters.
 *	paramTypes = An array of types specified using Oid.  Use null or 0 to have the server guess.
 *	paramValues = The parameters themselves in the expected format.
 *	paramLengths = An array of lengths of the parameters.  This is ignored for non-binary data.
 *	paramFormats = An array of formats of the parameters.  Use 0 for text and 1 for binary.
 *	resultFormat = Use 0 to obtain the results in text format and 1 for binary.
 *
 * Returns:
 *	1 on success or 0 on failure.
 */
int PQsendQueryParams (PGconn* conn, char* command, int nParams, Oid* paramTypes, char** paramValues, int* paramLengths, int* paramFormats, int resultFormat);

/**
 * Create a prepared statement without waiting for completion.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	stmtName = The name to assign to the prepared statement.
 *	query = The SQL command to prepare.
 *	nParams = The number of parameters.
 *	paramTypes = An array of types specified using Oid.  Use null or 0 to have the server guess.
 *
 * Returns:
 *	1 on success or 0 on failure.
 */
int PQsendPrepare (PGconn* conn, char* stmtName, char* query, int nParams, Oid* paramTypes);

/**
 * Execute a prepared statement without waiting for the results.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	stmtName = The name of the prepared statement to execute.
 *	nParams = The number of parameters.
 *	paramValues = The parameters themselves in the expected format.
 *	paramLengths = An array of lengths of the parameters.  This is ignored for non-binary data.
 *	paramFormats = An array of formats of the parameters.  Use 0 for text and 1 for binary.
 *	resultFormat = Use 0 to obtain the results in text format and 1 for binary.
 *
 * Returns:
 *	1 on success or 0 on failure.
 */
int PQsendQueryPrepared (PGconn* conn, char* stmtName, int nParams, char** paramValues, int* paramLengths, int* paramFormats, int resultFormat);

/**
 * Get the current result set.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	A PGresult structure describing the current status or null if no command is being processed.
 */
PGresult* PQgetResult (PGconn* conn);

/**
 * Determine if the server is currently busy with a command.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	1 if a command is busy and 0 if it is safe to call PQgetResult.
 */
int PQisBusy (PGconn* conn);

/**
 * Get any input from the server.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	1 on success and 0 on failure.
 */
int PQconsumeInput (PGconn* conn);

/**
 * Get the next unhandled notification event.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	The PGnotify structure representing the notification event.
 */
PGnotify* PQnotifies (PGconn* conn);

/**
 * Send data to the server after a copy command.
 *
 * This function will only be unable to send the data if nonblocking is set.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	buffer = The data to send to the server.
 *	nbytes = The length of buffer.
 *
 * Returns:
 *	1 on success, -1 on failure, or 0 if the data wasn't sent.
 */
int PQputCopyData (PGconn* conn, char* buffer, int nbytes);

/**
 * Tell the server that no more data needs to be copied.
 *
 * This function will only be unable to send the data if nonblocking is set.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	errormsg = null on success and the error message on failure.
 *
 * Returns:
 *	1 on success, -1 on failure, or 0 if the data wasn't sent.
 */
int PQputCopyEnd (PGconn* conn, char* errormsg);

/**
 * Get the data from the server after a copy command.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	buffer = A pointer to the _buffer.  The memory will be allocated by PostgreSQL.
 *	async = Use 0 for nonblocking and any other number for blocking.
 *
 * Returns:
 *	-1 on success, -2 on failure, or 0 if the command is still in progress.
 */
int PQgetCopyData (PGconn* conn, char** buffer, int async);

/**
 * Deprecated:
 *	These functions have poor error handling, nonblocking transfers, binary data,
 *	or easy end of data detection.  Use PQputCopyData, PQputCopyEnd, and PQgetCopyData instead.
 */
deprecated int PQgetline (PGconn* conn, char* string, int length);
deprecated int PQputline (PGconn* conn, char* string); /// ditto
deprecated int PQgetlineAsync (PGconn* conn, char* buffer, int bufsize); /// ditto
deprecated int PQputnbytes (PGconn* conn, char* buffer, int nbytes); /// ditto
deprecated int PQendcopy (PGconn* conn); /// ditto

/**
 * Set the nonblocking status of the connection.
 *
 * PQexec will ignore this setting.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	arg = 1 for nonblocking and 0 for blocking.
 *
 * Returns:
 *	0 on success and -1 on failure.
 */
int PQsetnonblocking (PGconn* conn, int arg);

/**
 * Get the current nonblocking status of the connection.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	1 if the connection is nonblocking and 0 if it is blocking.
 */
int PQisnonblocking (PGconn* conn);

/**
 * todo
 */
int PQisthreadsafe ();

/**
 * Attempt to send all queries to the server immediately.
 *
 * This function will only be unable to send the data if nonblocking is set.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *
 * Returns:
 *	0 on success, -1 on failure, or 1 if not all of the data was sent.
 */
int PQflush (PGconn* conn);

/**
 * Send a simple command to the query very quickly.
 *
 * Deprecated:
 *	Prepared functions are just as fast and more powerful.  Use them instead.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	fnid = The Oid of the function to execute.
 *	result_buf = The buffer the return value will be placed in.
 *	result_len = The length of result_buf.
 *	result_is_int = This is 1 if an integer of 4 bytes or less is to be returned.  Use 0 otherwise.
 *	args = An array of PQArgBlock structures.
 *	nargs = The length of args.
 *
 * Returns:
 *	A PGresult structure describing the current status.
 */
deprecated PGresult* PQfn (PGconn* conn, int fnid, int* result_buf, int* result_len, int result_is_int, PQArgBlock* args, int nargs) ;

/**
 * Get the result status of a command.
 *
 * Params:
 *	res = The PGresult structure returned by the server.
 *
 * Returns:
 *	An ExecStatusType value describing the result status.
 */
ExecStatusType PQresultStatus (PGresult* res);

/**
 * Get the string representing an ExecStatusType value.
 *
 * Params:
 *	status = The ExecStatusType value.
 *
 * Returns:
 *	The representative string.
 */
char* PQresStatus (ExecStatusType status);

/**
 * Get the error message associated with a command.
 *
 * Params:
 *	res = The PGresult structure returned by the server.
 *
 * Returns:
 *	The string form of the error if there is one or an empty string otherwise.
 */
char* PQresultErrorMessage (PGresult* res);

/**
 * Get an individual field of an error report.
 *
 * Params:
 *	res = The PGresult structure returned by the server.
 *	fieldcode = The error filed to return.  Accepted values start with PG_DIAG_
 *
 * Returns:
 *	The string form of the error if there is one or null otherwise.
 *
 * See_Also:
 *	The online PostgreSQL documentation describes what you can use in fieldcode.
 */
char* PQresultErrorField (PGresult* res, char fieldcode);

/**
 * Get the number of tuples in a query result.
 *
 * Params:
 *	res = The PGresult structure returned by the server.
 *
 * Returns:
 *	The number of tuples.
 */
int PQntuples (PGresult* res);

/**
 * Get the number of fields in a query result.
 *
 * Params:
 *	res = The PGresult structure returned by the server.
 *
 * Returns:
 *	The number of fields.
 */
int PQnfields (PGresult* res);

/**
 * Get whether a query result contains binary data or not.
 *
 * Params:
 *	res = The PGresult structure returned by the server.
 *
 * Returns:
 *	1 if the result set contains binary data and 0 otherwise.
 */
int PQbinaryTuples (PGresult* res);

/**
 * Get the column name associated with a column number in a query result.
 *
 * Params:
 *	res = The PGresult structure returned by the server.
 *	field_num = The number of the column.
 *
 * Returns:
 *	The name of the column if it exists or null otherwise.
 */
char* PQfname (PGresult* res, int field_num);

/**
 * Get the column number associated with a column name in a query result.
 *
 * Params:
 *	res = The PGresult structure returned by the server.
 *	field_name = The name of the column.
 *
 * Returns:
 *	The number of the column if it exists or -1 otherwise.
 */
int PQfnumber (PGresult* res, char* field_name);

/**
 * Get the Oid of the table from which a column in a query result was fetched.
 *
 * Params:
 *	res = The PGresult structure returned by the server.
 *	field_num = The number of the column.
 *
 * Returns:
 *	The Oid of the table if it exists or InvalidOid otherwise.
 */
Oid PQftable (PGresult* res, int field_num);

/**
 * Get the number of a column in its table from its number in a query result.
 *
 * Params:
 *	res = The PGresult structure returned by the server.
 *	field_num = The number of the column within the query result.
 *
 * Returns:
 *	The column number if it exists or 0 otherwise.
 */
int PQftablecol (PGresult* res, int field_num);

/**
 * Get the format code of a column in a query result.
 *
 * Params:
 *	res = The PGresult structure returned by the server.
 *	field_num = The number of the column.
 *
 * Returns:
 *	0 if the format is text and 1 if it is binary.
 */
int PQfformat (PGresult* res, int field_num);

/**
 * Get the data type of a column in a query result.
 *
 * Params:
 *	res = The PGresult structure returned by the server.
 *	field_num = The number of the column.
 *
 * Returns:
 *	The Oid representing the data type.
 */
Oid PQftype (PGresult* res, int field_num);

/**
 * Get the number of bytes4/17/2006 in a column in a query result.
 *
 * Params:
 *	res = The PGresult structure returned by the server.
 *	field_num = The number of the column.
 *
 * Returns:
 *	The number of bytes.
 */
int PQfsize (PGresult* res, int field_num);

/**
 * Get the type modifier of a column in a query result.
 *
 * Params:
 *	res = The PGresult structure returned by the server.
 *	field_num = The number of the column.
 *
 * Returns:
 *	The type modifier if it exists or -1 otherwise.
 */
int PQfmod (PGresult* res, int field_num);

/**
 * Get the command status tag from a query result.
 *
 * Params:
 *	res = The PGresult structure returned by the server.
 *
 * Returns:
 *	The command status tag.
 */
char* PQcmdStatus (PGresult* res);

/**
 * Get the Oid in string format of a valid insert in a query result.
 *
 * Deprecated:
 *	Use PQoidValue instead.  It is thread-safe.
 *
 * Params:
 *	res = The PGresult structure returned by the server.
 *
 * Returns:
 *	The Oid if it exists and is valid. "0" or "" is returned otherwise.
 */
deprecated char* PQoidStatus (PGresult* res);

/**
 * Get the Oid of a valid insert in a query result.
 *
 * Params:
 *	res = The PGresult structure returned by the server.
 *
 * Returns:
 *	The Oid if it exists and is valid or InvalidOid if it isn't.
 */
Oid PQoidValue (PGresult* res);

/**
 * Get the number of tuples affected by a query.
 *
 * Params:
 *	res = The PGresult structure returned by the server.
 *
 * Returns:
 *	The number of affected tuples.
 */
char* PQcmdTuples (PGresult* res);

/**
 * Get the value of a single field in a query result.
 *
 * Params:
 *	res = The PGresult structure returned by the server.
 *	tup_num = The number of the row.
 *	field_num = The number of the column.
 *
 * Returns:
 *	The value of the field.
 */
char* PQgetvalue (PGresult* res, int tup_num, int field_num);

/**
 * Get the number of bytes in the length of a single field in a query result.
 *
 * Params:
 *	res = The PGresult structure returned by the server.
 *	tup_num = The number of the row.
 *	field_num = The number of the column.
 *
 * Returns:
 *	The number of bytes in the length of the field.
 */
int PQgetlength (PGresult* res, int tup_num, int field_num);

/**
 * Get whether or not a single field in a query result is null.
 *
 * Params:
 *	res = The PGresult structure returned by the server.
 *	tup_num = The number of the row.
 *	field_num = The number of the column.
 *
 * Returns:
 *	1 if it is null or 0 otherwise.
 */
int PQgetisnull (PGresult* res, int tup_num, int field_num);

/**
 * todo
 */
int PQnparams (PGresult* res);

/**
 * todo
 */
Oid PQparamtype (PGresult* res, int param_num);

/**
 * todo
 */
PGresult* PQdescribePrepared (PGconn* conn, char* stmt);

/**
 * todo
 */
PGresult* PQdescribePortal (PGconn* conn, char* portal);

/**
 * todo
 */
int PQsendDescribePrepared (PGconn* conn, char* stmt);

/**
 * todo
 */
int PQsendDescribePortal (PGconn* conn, char* portal);

/**
 * Free all memory associated with a result.  This includes all returned strings.
 *
 * Params:
 *	res = The PGresult structure to erase.
 */
void PQclear (PGresult* res);

/**
 * Free memory allocated by the the interface library.
 *
 * This is necessary only on Windows.  Users of other operating systems can simply use free.
 *
 * Params:
 *	ptr = A pointer to the memory to free.
 */
void PQfreemem (void* ptr);

/**
 * Deprecated:
 *	Use PQfreemem or free directly.
 */
deprecated alias PQfreemem PQfreeNotify;

/**
 * Make an empty PGresult structure with a given _status.
 *
 * Note that anything from the PostgreSQL connection will be added in.
 *
 * Params:
 *	conn = The PostgreSQL connection.  This can be null.
 *	status = The error message to add to the PGresult structure.
 *
 * Returns:
 *	The created PGresult structure.
 */
PGresult* PQmakeEmptyPGresult (PGconn* conn, ExecStatusType status);

/**
 * Escape a string for use within a SQL command.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	to = The buffer the results will be put in.  Must be at least 2 * length + 1 chars long.
 *	from = The string _to convert.
 *	length = The number of chars _to escape.  The terminating 0 should not be included.
 *	error = 0 on success and nonzero on failure.  Can be null.
 *
 * Returns:
 *	The number of characters in to.  This doesn't include the terminating 0.
 */
size_t PQescapeStringConn (PGconn* conn, char* to, char* from, size_t length, int* error);

/**
 * Escape binary data for use within a SQL command.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	from = A pointer to the first byte to escape.
 *	from_length = The number of bytes to escape.  The terminating 0 should not be included.
 *	to_length = A pointer to a variable that will hold the length of the escaped string.
 *
 * Returns:
 *	The escaped version of bintext on success and null on failure.
 */
char* PQescapeByteaConn (PGconn* conn, ubyte* from, size_t from_length, size_t* to_length);

/**
 * Escape a string for use within a SQL command.
 *
 * Deprecated:
 *	Replaced by PQescapeStringConn in PostgreSQL 8.1.4.
 *
 * Params:
 *	to = The buffer the results will be put in.  Must be at least 2 * length + 1 chars long.
 *	from = The string _to convert.
 *	length = The number of chars _to escape.  The terminating 0 should not be included.
 *
 * Returns:
 *	The number of characters in to.
 */
deprecated size_t PQescapeString (char* to, char* from, size_t length);

/**
 * Escape binary data for use within a SQL command.
 *
 * Deprecated:
 *	Replaced by PQescapeByteaConn in PostgreSQL 8.1.4.
 *
 * Params:
 *	bintext = A pointer to the first byte to escape.
 *	binlen = The number of bytes to escape.  The terminating 0 should not be included.
 *	bytealen = A pointer to a variable that will hold the length of the escaped string.
 *
 * Returns:
 *	The escaped version of bintext.
 */
deprecated char* PQescapeBytea (ubyte* bintext, size_t binlen, size_t* bytealen);

/**
 * Unescape binary data.
 *
 * Params:
 *	strtext = The escaped binary data.
 *	retbuflen = A pointer to a variable that will hold the length of the escaped string.
 *
 * Returns:
 *	The unescaped version of strtext.
 */
ubyte* PQunescapeBytea (char* strtext, size_t* retbuflen);

/**
 * Print all of the rows to a stream.
 *
 * Params:
 *	fout = The CStream to output the information to.
 *	res = The PGresult structure returned by the server.
 *	ps = A PQprintOpt structure containing your printing options.
 */
void PQprint (FILE* fout, PGresult* res, PQprintOpt* ps);

/**
 * Print all of the rows to a stream.
 *
 * Deprecated:
 *	Use PQprint instead.
 *
 * Params:
 *	res = The PGresult structure returned by the server.
 *	fp = The CStream to output the information to.
 *	fillAlign = Space fill to align columns.
 *	fieldSep = The character to use as a field seperator.
 *	printHeader = Use 1 to display headers and 0 not to.
 *	quiet = Use 0 to show row count at the end and 1 not to.
 */
deprecated void PQdisplayTuples (PGresult* res, FILE* fp, int fillAlign, char* fieldSep, int printHeader, int quiet);

/**
 * Print all of the rows to a stream.
 *
 * Deprecated:
 *	Use PQprint instead.
 *
 * Params:
 *	res = The PGresult structure returned by the server.
 *	fout = The CStream to output the information to.
 *	printAttName = Use 1 to print attribute names and 0 not to.
 *	terseOutput = Use 1 to show delimiter bars and 0 not to.
 *	width = The _width of the columns.  Use 0 for variable _width.
 */
deprecated void PQprintTuples (PGresult* res, FILE* fout, int printAttName, int terseOutput, int width);

/**
 * Open an existing large object.
 *
 * Params:
 *	conn = PostgreSQL connection.
 *	lobjId = Oid of the large object to open.
 *	mode = Whether to make it readonly or not.  Uses INV_READ and INV_WRITE.
 *
 * Returns:
 *	An integer for use with other large object functions on success or -1 on failure.
 */
int lo_open (PGconn* conn, Oid lobjId, int mode);

/**
 * Close an opened large object.
 *
 * This is done automatically to any large objects that are open at the end of a transaction.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	fd = The integer returned when the large object was opened.
 *
 * Returns:
 *	0 on success or -1 on failure.
 */
int lo_close (PGconn* conn, int fd);

/**
 * Read from an open large object.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	fd = The integer returned when the large object was opened;
 *	buf = The buffer that that data will be written to.
 *	len = The number of bytes to copy to buf.
 *
 * Returns:
 *	The number of bytes read on success or a negative number on failure.
 */
int lo_read (PGconn* conn, int fd, byte* buf, size_t len);

/**
 * Writes to an open large object.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	fd = The integer returned when the large object was opened.
 *	buf = The buffer that the data will be read from.
 *	len = The number of bytes to copy from buf.
 *
 * Returns:
 *	The number of bytes read on success or a negative number on failure.
 */
int lo_write (PGconn* conn, int fd, byte* buf, size_t len);

/**
 * Change the location of reading and writing in an open large object.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	fd = The integer returned when the large object was opened.
 *	offset = How far to move.
 *	whence = Where to start counting.  Uses SEEK_SET, SEEK_CUR, and SEEK_END.
 *
 * Returns:
 *	The new location pointer on success or -1 on failure.
 */
int lo_lseek (PGconn* conn, int fd, int offset, int whence);

/**
 * Create a new large object.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	mode = Ignored as of PostgreSQL version 8.1.
 *
 * Returns:
 *	The Oid of the large object on success or InvalidOid on failure.
 */
Oid lo_creat (PGconn* conn, int mode);

/**
 * Create a new large object.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	lobjId = Requested Oid to assign the large object to.
 *
 * Returns:
 *	The Oid of the large object or InvalidOid on failure.
 */
Oid lo_create (PGconn* conn, Oid lobjId);

/**
 * Get the location pointer of an open large object.
 *
 * Params:
 *	conn =  The PostgreSQL connection.
 *	fd = The integer returned when the large object was opened.
 *
 * Returns:
 *	The location pointer or a negative number on failure.
 */
int lo_tell (PGconn* conn, int fd);

/**
 * Remove a large object from the database.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	lobjOid = the Oid of the large object to remove.
 *
 * Returns:
 *	1 on success or -1 on failure.
 */
int lo_unlink (PGconn* conn, Oid lobjId);

/**
 * Load a large object from a file.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	filename = Name of the file to load.
 *
 * Returns:
 *	The Oid of the large object or InvalidOid on failure.
 */
Oid lo_import (PGconn* conn, char* filename);

/**
 * Save a large object to a file.
 *
 * Params:
 *	conn = The PostgreSQL connection.
 *	lobjOid = Oid of the large object to save.
 *	filename = Name of the file to save to.
 *
 * Returns:
 *	1 on success or -1 on failure.
 */
int lo_export (PGconn* conn, Oid lobjId, char* filename);

/**
 * todo
 */
int PQmblen (char* s, int encoding);

/**
 * todo
 */
int PQdsplen (char* s, int encoding);

/**
 * todo
 */
int PQenv2encoding ();

/**
 * todo
 */
char* PQencryptPassword (char* passwd, char* user);