/**
 * Authors: The D DBI project
 *
 * Version: 0.2.5
 *
 * Copyright: BSD license
 */
module dbi.oracle.OracleDatabase;

private import dbi.Database, dbi.DBIException, dbi.Result, dbi.Row, dbi.Statement;
private import dbi.oracle.imp.oci, dbi.oracle.OracleResult;

private OCIEnv* env;

static this () {
	if (sword error = OCIEnvCreate(&env, OCI_DEFAULT, null, null, null, null, 0, null) != OCI_SUCCESS) {
		throw new DBIException("Unable to initialize the Oracle database.", error);
	}
}

/**
 * An implementation of Database for use with Oracle databases.
 *
 * Bugs:
 *	Database-specific error codes are not converted to ErrorCode.
 *
 * See_Also:
 *	Database is the interface that this provides an implementation of.
 */
class OracleDatabase : Database {
	public:
	/**
	 * Create a new instance of OracleDatabase, but don't connect.
	 */
	this () {
		if (sword error = OCIHandleAlloc(env, cast(void**)&err, OCI_HTYPE_ERROR, 0, null) != OCI_SUCCESS) {
			throw new DBIException("Unable to initialize the Oracle error handle.", error);
		}
		if (sword error = OCIHandleAlloc(env, cast(void**)&svc, OCI_HTYPE_SVCCTX, 0, null) != OCI_SUCCESS) {
			throw new DBIException("Unable to initialize the Oracle service handle.", error);
		}
	}

	/**
	 * Create a new instance of OracleDatabase and connect to a server.
	 *
	 * See_Also:
	 *	connect
	 */
	this (char[] params, char[] username = null, char[] password = null) {
		this();
		connect(params, username, password);
	}

	/**
	 * Connect to a database on a Oracle server.
	 *
	 * Params:
	 *	params = The database to use.
	 *	username = The _username to connect with.
	 *	password = The _password to connect with.
	 *
	 * Throws:
	 *	DBIException if there was an error connecting.
	 *
	 * Example:
	 *	(start code)
	 *	OracleDatabase db = new OracleDatabase();
	 *	db.connect("database", "username", "password");
	 *	(end code)
	 */
	override void connect (char[] params, char[] username, char[] password) {
		if (sword error = OCILogon(env, err, &svc, username.ptr, username.length, password.ptr, password.length, params.ptr, params.length) != OCI_SUCCESS) {
			throw new DBIException("Unable to connect to the Oracle database.", error);
		}
	}

	/**
	 * Close the current connection to the database.
	 *
	 * Throws:
	 *	DBIException if there was an error disconnecting.
	 *
	 *	DBIException if the Oracle service handle couldn't be freed.
	 *
	 *	DBIException if the Oracle error handle couldn't be freed.
	 */
	override void close () {
		if (sword error = OCILogoff(svc, err) != OCI_SUCCESS) {
			throw new DBIException("Unable to disconnect from the Oracle database.", error);
		}
		if (sword error = OCIHandleFree(svc, OCI_HTYPE_SVCCTX) != OCI_SUCCESS) {
			throw new DBIException("Unable to free the Oracle service handle.", error);
		}
		if (sword error = OCIHandleFree(err, OCI_HTYPE_ERROR) != OCI_SUCCESS) {
			throw new DBIException("Unable to free the Oracle error handle.", error);
		}
	}

	/**
	 * Execute a SQL statement that returns no results.
	 *
	 * Params:
	 *	sql = The SQL statement to execute.
	 */
	override void execute (char[] sql) {
	}

	/**
	 * Query the database.
	 *
	 * Params:
	 *	sql = The SQL statement to execute.
	 *
	 * Returns:
	 *	A Result object with the queried information.
	 */
	override OracleResult query (char[] sql) {
		return null;
	}

	/**
	 * Get the error code.
	 *
	 * Deprecated:
	 *	This functionality now exists in DBIException.  This will be
	 *	removed in version 0.3.0.
	 *
	 * Returns:
	 *	The database specific error code.
	 */
	deprecated override int getErrorCode () {
		return 0;
	}

	/**
	 * Get the error message.
	 *
	 * Deprecated:
	 *	This functionality now exists in DBIException.  This will be
	 *	removed in version 0.3.0.
	 *
	 * Returns:
	 *	The database specific error message.
	 */
	deprecated override char[] getErrorMessage () {
		return "";
	}

	private:
	OCIError* err;
	OCISvcCtx* svc;
	OCIStmt* sql;
}