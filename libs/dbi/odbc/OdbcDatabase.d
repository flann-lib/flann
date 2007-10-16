/**
 * Authors: The D DBI project
 *
 * Version: 0.2.5
 *
 * Copyright: BSD license
 */
module dbi.odbc.OdbcDatabase;

// Almost every cast involving chars and SQLCHARs shouldn't exist, but involve bugs in
// WindowsAPI revision 144.  I'll see about fixing their ODBC and SQL files soon.
// WindowsAPI should also include odbc32.lib itself.

version (Phobos) {
	private static import std.string;
	debug (UnitTest) private static import std.stdio;
} else {
	private static import tango.text.Util;
	debug (UnitTest) private static import tango.io.Stdout;
}
private import dbi.Database, dbi.DBIException, dbi.Result;
private import dbi.odbc.OdbcResult;
private import win32.odbcinst, win32.sql, win32.sqlext, win32.sqltypes, win32.sqlucode, win32.windef;
debug (UnitTest) private import dbi.Row, dbi.Statement;

version (Windows) pragma (lib, "odbc32.lib");

private SQLHENV environment;

/*
 * This is in the sql headers, but wasn't ported in WindowsAPI revision 144.
 */
private bool SQL_SUCCEEDED (SQLRETURN ret) {
	return (ret == SQL_SUCCESS || ret == SQL_SUCCESS_WITH_INFO) ? true : false;
}

static this () {
	// Note: The cast is a pseudo-bug workaround for WindowsAPI revision 144.
	if (!SQL_SUCCEEDED(SQLAllocHandle(SQL_HANDLE_ENV, cast(SQLHANDLE)SQL_NULL_HANDLE, &environment))) {
		throw new DBIException("Unable to initialize the ODBC environment.");
	}
	// Note: The cast is a pseudo-bug workaround for WindowsAPI revision 144.
	if (!SQL_SUCCEEDED(SQLSetEnvAttr(environment, SQL_ATTR_ODBC_VERSION, cast(SQLPOINTER)SQL_OV_ODBC3, 0))) {
		throw new DBIException("Unable to set the ODBC environment to version 3.");
	}
}

static ~this () {
	if (!SQL_SUCCEEDED(SQLFreeHandle(SQL_HANDLE_ENV, environment))) {
		throw new DBIException("Unable to close the ODBC environment.");
	}
}

/**
 * An implementation of Database for use with the ODBC interface.
 *
 * Bugs:
 *	Database-specific error codes are not converted to ErrorCode.
 *
 * See_Also:
 *	Database is the interface that this provides an implementation of.
 */
class OdbcDatabase : Database {
	public:
	/**
	 * Create a new instance of OdbcDatabase, but don't connect.
	 *
	 * Throws:
	 *	DBIException if an ODBC connection couldn't be created.
	 */
	this () {
		if (!SQL_SUCCEEDED(SQLAllocHandle(SQL_HANDLE_DBC, environment, &connection))) {
			throw new DBIException("Unable to create the ODBC connection.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
		}

	}

	/**
	 * Create a new instance of OdbcDatabase and connect to a server.
	 *
	 * Throws:
	 *	DBIException if an ODBC connection couldn't be created.
	 *
	 * See_Also:
	 *	connect
	 */
	this (char[] params, char[] username = null, char[] password = null) {
		this();
		connect(params, username, password);
	}

	/**
	 * Deallocate the connection handle.
	 */
	~this () {
		close();
		if (!SQL_SUCCEEDED(SQLFreeHandle(SQL_HANDLE_DBC, connection))) {
			throw new DBIException("Unable to close an ODBC connection.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
		}
		connection = cast(SQLHANDLE)null;
	}

	/**
	 * Connect to a database using ODBC.
	 *
	 * This function will connect without DSN if params has a '=' and with DSN
	 * otherwise.  For information on how to use connect without DSN, see the
	 * ODBC documentation.
	 *
	 * Bugs:
	 *	Connecting without DSN ignores username and password.
	 *
	 * Params:
	 *	params = The DSN to use or the connection parameters.
	 *	username = The _username to _connect with.
	 *	password = The _password to _connect with.
	 *
	 * Throws:
	 *	DBIException if there was an error connecting.
	 *
	 * Examples:
	 *	---
	 *	OdbcDatabase db = new OdbcDatabase();
	 *	db.connect("Data Source Name", "_username", "_password");
	 *	---
	 *
	 * See_Also:
	 *	The ODBC documentation included with the MDAC 2.8 SDK.
	 */
	override void connect (char[] params, char[] username = null, char[] password = null) {
		void connectWithoutDSN () {
			SQLCHAR[1024] buffer;

			if (!SQL_SUCCEEDED(SQLDriverConnect(connection, null, cast(SQLCHAR*)params.ptr, cast(SQLSMALLINT)params.length, buffer.ptr, buffer.length, null, SQL_DRIVER_COMPLETE))) {
				throw new DBIException("Unable to connect to the database.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
			}
		}

		void connectWithDSN () {
			if (!SQL_SUCCEEDED(SQLConnect(connection, cast(SQLCHAR*)params.ptr, cast(SQLSMALLINT)params.length, cast(SQLCHAR*)username.ptr, cast(SQLSMALLINT)username.length, cast(SQLCHAR*)password.ptr, cast(SQLSMALLINT)password.length))) {
				throw new DBIException("Unable to connect to the database.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
			}
		}

		version (Phobos) {
			if (std.string.find(params, "=") == -1) {
				connectWithDSN();
			} else {
				connectWithoutDSN();
			}
		} else {
			if (tango.text.Util.contains(params, '=')) {
				connectWithoutDSN();
			} else {
				connectWithDSN();
			}
		}
	}

	/**
	 * Close the current connection to the database.
	 *
	 * Throws:
	 *	DBIException if there was an error disconnecting.
	 */
	override void close () {
		if (cast(void*)connection !is null && !SQL_SUCCEEDED(SQLDisconnect(connection))) {
			if (getLastErrorMessage[0 .. 5] != "08003") {
				throw new DBIException("Unable to disconnect from the database.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
			}
		}
	}

	/**
	 * Execute a SQL statement that returns no results.
	 *
	 * Params:
	 *	sql = The SQL statement to _execute.
	 *
	 * Throws:
	 *	DBIException if an ODBC statement couldn't be created.
	 *
	 *	DBIException if the SQL code couldn't be executed.
	 *
	 *	DBIException if there is an error while committing the changes.
	 *
	 *	DBIException if there is an error while rolling back the changes.
	 *
	 *	DBIException if an ODBC statement couldn't be destroyed.
	 */
	override void execute (char[] sql) {
		scope (exit)
			stmt = cast(SQLHANDLE)null;
		scope (exit)
			if (!SQL_SUCCEEDED(SQLFreeHandle(SQL_HANDLE_STMT, stmt))) {
				throw new DBIException("Unable to destroy an ODBC statement.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
			}
		scope (failure)
			if (!SQL_SUCCEEDED(SQLEndTran(SQL_HANDLE_DBC, connection, SQL_ROLLBACK))) {
				throw new DBIException("Unable to rollback after a query failure.  ODBC returned " ~ getLastErrorMessage, sql, getLastErrorCode);
			}
		if (!SQL_SUCCEEDED(SQLAllocHandle(SQL_HANDLE_STMT, connection, &stmt))) {
			throw new DBIException("Unable to create an ODBC statement.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
		}
		if (!SQL_SUCCEEDED(SQLExecDirect(stmt, cast(SQLCHAR*)sql.ptr, sql.length))) {
			throw new DBIException("Unable to execute SQL code.  ODBC returned " ~ getLastErrorMessage, sql, getLastErrorCode);
		}

	}

	/**
	 * Query the database.
	 *
	 * Params:
	 *	sql = The SQL statement to execute.
	 *
	 * Returns:
	 *	A Result object with the queried information.
	 *
	 * Throws:
	 *	DBIException if an ODBC statement couldn't be created.
	 *
	 *	DBIException if the SQL code couldn't be executed.
	 *
	 *	DBIException if there is an error while committing the changes.
	 *
	 *	DBIException if there is an error while rolling back the changes.
	 *
	 *	DBIException if an ODBC statement couldn't be destroyed.
	 */
	override OdbcResult query (char[] sql) {
		scope (failure)
			if (!SQL_SUCCEEDED(SQLFreeHandle(SQL_HANDLE_STMT, stmt))) {
				throw new DBIException("Unable to destroy an ODBC statement.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
			}
		scope (failure)
			if (!SQL_SUCCEEDED(SQLEndTran(SQL_HANDLE_DBC, connection, SQL_ROLLBACK))) {
				throw new DBIException("Unable to rollback after a query failure.  ODBC returned " ~ getLastErrorMessage, sql, getLastErrorCode);
			}
		if (!SQL_SUCCEEDED(SQLAllocHandle(SQL_HANDLE_STMT, connection, &stmt))) {
			throw new DBIException("Unable to create an ODBC statement.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
		}
		if (SQL_SUCCEEDED(SQLExecDirect(stmt, cast(SQLCHAR*)sql.ptr, sql.length))) {
			return new OdbcResult(stmt);
		} else {
			throw new DBIException("Unable to query the database.  ODBC returned " ~ getLastErrorMessage, sql, getLastErrorCode);
		}
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
		return getLastErrorCode;
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
		return getLastErrorMessage();
}

	/*
	 * Note: The following are not in the DBI API.
	 */

	/**
	 * Get a list of currently installed ODBC drivers.
	 *
	 * Returns:
	 *	A list of all the installed ODBC drivers.
	 */
	char[][] getDrivers () {
		SQLCHAR[][] driverList;
		SQLCHAR[512] driver;
		SQLCHAR[512] attr;
		SQLSMALLINT driverLength;
		SQLSMALLINT attrLength;
		SQLUSMALLINT direction = SQL_FETCH_FIRST;
		SQLRETURN ret = SQL_SUCCESS;

		while (SQL_SUCCEEDED(ret = SQLDrivers(environment, direction, driver.ptr, driver.length, &driverLength, attr.ptr, attr.length, &attrLength))) {
			direction = SQL_FETCH_NEXT;
			driverList ~= driver[0 .. driverLength] ~ cast(SQLCHAR[])" ~ " ~ attr[0 .. attrLength];
			if (ret == SQL_SUCCESS_WITH_INFO) {
				throw new DBIException("Data truncation occurred in the driver list.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
			}
		}
		return cast(char[][])driverList;
	}

	/**
	 * Get a list of currently available ODBC data sources.
	 *
	 * Returns:
	 *	A list of all the installed ODBC data sources.
	 */
	char[][] getDataSources () {
		SQLCHAR[][] dataSourceList;
		SQLCHAR[512] dsn;
		SQLCHAR[512] desc;
		SQLSMALLINT dsnLength;
		SQLSMALLINT descLength;
		SQLUSMALLINT direction = SQL_FETCH_FIRST;
		SQLRETURN ret = SQL_SUCCESS;

		while (SQL_SUCCEEDED(ret = SQLDataSources(environment, direction, dsn.ptr, dsn.length, &dsnLength, desc.ptr, desc.length, &descLength))) {
			if (ret == SQL_SUCCESS_WITH_INFO) {
				throw new DBIException("Data truncation occurred in the data source list.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
			}
			direction = SQL_FETCH_NEXT;
			dataSourceList ~= dsn[0 .. dsnLength] ~ cast(SQLCHAR[])" ~ " ~ desc[0 .. descLength];
		}
		return cast(char[][])dataSourceList;
	}

	private:
	SQLHDBC connection;
	SQLHSTMT stmt;

	/**
	 * Get the last error message returned by the server.
	 *
	 * Returns:
	 *	The last error message returned by the server.
	 */
	char[] getLastErrorMessage () {
		SQLSMALLINT errorNumber;
		SQLCHAR[5] state;
		SQLINTEGER nativeCode;
		SQLCHAR[512] text;
		SQLSMALLINT textLength;

		SQLGetDiagField(SQL_HANDLE_DBC, connection, 0, SQL_DIAG_NUMBER, &errorNumber, 0, null);
		SQLGetDiagRec(SQL_HANDLE_DBC, connection, errorNumber, state.ptr, &nativeCode, text.ptr, text.length, &textLength);
		return cast(char[])state ~ " = " ~ cast(char[])text;
	}

	/**
	 * Get the last error code return by the server.  This is the native code.
	 *
	 * Returns:
	 *	The last error message returned by the server.
	 */
	int getLastErrorCode () {
		SQLSMALLINT errorNumber;
		SQLCHAR[5] state;
		SQLINTEGER nativeCode;
		SQLCHAR[512] text;
		SQLSMALLINT textLength;

		SQLGetDiagField(SQL_HANDLE_DBC, connection, 0, SQL_DIAG_NUMBER, &errorNumber, 0, null);
		SQLGetDiagRec(SQL_HANDLE_DBC, connection, errorNumber, state.ptr, &nativeCode, text.ptr, text.length, &textLength);
		return nativeCode;
	}
}

unittest {
	version (Phobos) {
		void s1 (char[] s) {
			std.stdio.writefln("%s", s);
		}

		void s2 (char[] s) {
			std.stdio.writefln("   ...%s", s);
		}
	} else {
		void s1 (char[] s) {
			tango.io.Stdout.Stdout(s).newline();
		}

		void s2 (char[] s) {
			tango.io.Stdout.Stdout("   ..." ~ s).newline();
		}
	}

	s1("dbi.odbc.OdbcDatabase:");
	OdbcDatabase db = new OdbcDatabase();
	s2("connect (with DSN)");
	db.connect("DDBI Unittest", "test", "test");

	s2("query");
	Result res = db.query("SELECT * FROM test");
	assert (res !is null);

	s2("fetchRow");
	Row row = res.fetchRow();
	assert (row !is null);
	assert (row.getFieldIndex("id") == 0);
	assert (row.getFieldIndex("name") == 1);
	assert (row.getFieldIndex("dateofbirth") == 2);
	assert (row.get("id") == "1");
	assert (row.get("name") == "John Doe");
	assert (row.get("dateofbirth") == "1970-01-01");
	assert (row.getFieldType(0) == SQL_INTEGER);
	assert (row.getFieldType(1) == SQL_CHAR || row.getFieldType(1) == SQL_WCHAR);
	assert (row.getFieldType(2) == SQL_TYPE_DATE || row.getFieldType(2) == SQL_DATE);
	res.finish();

	s2("prepare");
	Statement stmt = db.prepare("SELECT * FROM test WHERE id = ?");
	stmt.bind(1, "1");
	res = stmt.query();
	row = res.fetchRow();
	res.finish();
	assert (row[0] == "1");

	s2("fetchOne");
	row = db.queryFetchOne("SELECT * FROM test");
	assert (row[0] == "1");

	s2("execute(INSERT)");
	db.execute("INSERT INTO test VALUES (2, 'Jane Doe', '2000-12-31')");

	s2("execute(DELETE via prepare statement)");
	stmt = db.prepare("DELETE FROM test WHERE id=?");
	stmt.bind(1, "2");
	stmt.execute();

	s2("close");
	db.close();
	delete db;
}