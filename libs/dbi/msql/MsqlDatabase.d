/**
 * Authors: The D DBI project
 *
 * Version: 0.2.5
 *
 * Copyright: BSD license
 */
module dbi.msql.MsqlDatabase;

private import dbi.Database, dbi.DBIException, dbi.Result, dbi.Row, dbi.Statement;
private import dbi.msql.imp, dbi.msql.MsqlResult;

/**
 * An implementation of Database for use with mSQL databases.
 *
 * Bugs:
 *	Database-specific error codes are not converted to ErrorCode.
 *
 * See_Also:
 *	Database is the interface that this provides an implementation of.
 */
class MsqlDatabase : Database {
	public:
	/**
	 * Create a new instance of MsqlDatabase, but don't connect.
	 */
	this () {
	}

	/**
	 * Create a new instance of MsqlDatabase and connect to a server.
	 *
	 * See_Also:
	 *	connect
	 */
	this (char[] params, char[] username = null, char[] password = null) {
		this();
		connect(params, username, password);
	}

	/**
	 *
	 */
	override void connect (char[] params, char[] username = null, char[] password = null) {
	}

	/**
	 * Close the current connection to the database.
	 */
	override void close () {
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
	override MsqlResult query (char[] sql) {
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

}