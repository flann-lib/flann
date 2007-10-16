/**
 * Authors: The D DBI project
 *
 * Version: 0.2.5
 *
 * Copyright: BSD license
 */
module dbi.sqlite.SqliteDatabase;

version (Phobos) {
	private import std.string : toDString = toString, toCString = toStringz;
	debug (UnitTest) private import std.stdio;
} else {
	private import tango.stdc.stringz : toDString = fromUtf8z, toCString = toUtf8z;
}
private import dbi.Database, dbi.DBIException, dbi.Result, dbi.Row, dbi.Statement;
private import dbi.sqlite.imp, dbi.sqlite.SqliteError, dbi.sqlite.SqliteResult;

/**
 * An implementation of Database for use with SQLite databases.
 *
 * See_Also:
 *	Database is the interface that this provides an implementation of.
 */
class SqliteDatabase : Database {
	public:

	/**
	 * Create a new instance of SqliteDatabase, but don't open a database.
	 */
	this () {
	}

	/**
	 * Create a new instance of SqliteDatabase and open a database.
	 *
	 * See_Also:
	 *	connect
	 */
	this (char[] dbFile) {
		connect(dbFile);
	}

	/**
	 * Open a SQLite database for use.
	 *
	 * Params:
	 *	params = The name of the SQLite database to open.
	 *	username = Unused.
	 *	password = Unused.
	 *
	 * Throws:
	 *	DBIException if there was an error accessing the database.
	 *
	 * Examples:
	 *	---
	 *	SqliteDatabase db = new SqliteDatabase();
	 *	db.connect("_test.db", null, null);
	 *	---
	 */
	override void connect (char[] params, char[] username = null, char[] password = null) {
		if ((errorCode = sqlite3_open(toCString(params), &database)) != SQLITE_OK) {
			throw new DBIException("Could not open or create " ~ params, errorCode, specificToGeneral(errorCode));
		}
	}

	/**
	 * Close the current connection to the database.
	 */
	override void close () {
		if (database !is null) {
			if ((errorCode = sqlite3_close(database)) != SQLITE_OK) {
				throw new DBIException(asString(sqlite3_errmsg(database)), errorCode, specificToGeneral(errorCode));
			}
			database = null;
		}
	}

	/**
	 * Execute a SQL statement that returns no results.
	 *
	 * Params:
	 *	sql = The SQL statement to _execute.
	 *
	 * Throws:
	 *	DBIException if the SQL code couldn't be executed.
	 */
	override void execute (char[] sql) {
		char** errorMessage;
		if ((errorCode = sqlite3_exec(database, sql.dup.ptr, null, null, errorMessage)) != SQLITE_OK) {
			throw new DBIException(toDString(sqlite3_errmsg(database)), sql, errorCode, specificToGeneral(errorCode));
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
	 *	DBIException if the SQL code couldn't be executed.
	 */
	override SqliteResult query (char[] sql) {
		char** errorMessage;
		sqlite3_stmt* stmt;
		if ((errorCode = sqlite3_prepare(database, toCString(sql), sql.length, &stmt, errorMessage)) != SQLITE_OK) {
			throw new DBIException(toDString(sqlite3_errmsg(database)), sql, errorCode, specificToGeneral(errorCode));
		}
		return new SqliteResult(stmt);
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
		return sqlite3_errcode(database);
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
		return toDString(sqlite3_errmsg(database));
	}

	/*
	 * Note: The following are not in the DBI API.
	 */

	/**
	 * Get the rowid of the last insert.
	 *
	 * Returns:
	 *	The row of the last insert or 0 if no inserts have been done.
	 */
	long getLastInsertRowId () {
		return sqlite3_last_insert_rowid(database);
	}

	/**
	 * Get the number of rows affected by the last SQL statement.
	 *
	 * Returns:
	 *	The number of rows affected by the last SQL statement.
	 */
	int getChanges () {
		return sqlite3_changes(database);
	}

	/**
	 * Get a list of all the table names.
	 *
	 * Returns:
	 *	An array of all the table names.
	 */
	char[][] getTableNames () {
		return getItemNames("table");
	}

	/**
	 * Get a list of all the view names.
	 *
	 * Returns:
	 *	An array of all the view names.
	 */
	char[][] getViewNames () {
		return getItemNames("view");
	}

	/**
	 * Get a list of all the index names.
	 *
	 * Returns:
	 *	An array of all the index names.
	 */
	char[][] getIndexNames () {
		return getItemNames("index");
	}

	/**
	 * Check if a table exists.
	 *
	 * Param:
	 *	name = Name of the table to check for the existance of.
	 *
	 * Returns:
	 *	true if it exists or false otherwise.
	 */
	bool hasTable (char[] name) {
		return hasItem("table", name);
	}

	/**
	 * Check if a view exists.
	 *
	 * Params:
	 *	name = Name of the view to check for the existance of.
	 *
	 * Returns:
	 *	true if it exists or false otherwise.
	 */
	bool hasView (char[] name) {
		return hasItem("view", name);
	}

	/**
	 * Check if an index exists.
	 *
	 * Params:
	 *	name = Name of the index to check for the existance of.
	 *
	 * Returns:
	 *	true if it exists or false otherwise.
	 */
	bool hasIndex (char[] name) {
		return hasItem("index", name);
	}

	private:
	sqlite3* database;
	bool isOpen = false;
	int errorCode;

	/**
	 *
	 */
	char[][] getItemNames(char[] type) {
		char[][] items;
		Row[] rows = queryFetchAll("SELECT name FROM sqlite_master WHERE type='" ~ type ~ "'");
		for (size_t i = 0; i < rows.length; i++) {
			items ~= rows[i].get(0);
		}
		return items;
	}

	/**
	 *
	 */
	bool hasItem(char[] type, char[] name) {
		Row[] rows = queryFetchAll("SELECT name FROM sqlite_master WHERE type='" ~ type ~ "' AND name='" ~ name ~ "'");
		if (rows !is null && rows.length > 0) {
			return true;
		}
		return false;
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

	s1("dbi.sqlite.SqliteDatabase:");
	SqliteDatabase db = new SqliteDatabase();
	s2("connect");
	db.connect("test.db");

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
	assert (row.getFieldType(1) == SQLITE_TEXT);
	assert (row.getFieldDecl(1) == "char(40)");
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

	s2("getChanges");
	assert (db.getChanges() == 1);

	s2("getTableNames, getViewNames, getIndexNames");
	assert (db.getTableNames().length == 1);
	assert (db.getIndexNames().length == 1);
	assert (db.getViewNames().length == 0);

	s2("hasTable, hasView, hasIndex");
	assert (db.hasTable("test") == true);
	assert (db.hasTable("doesnotexist") == false);
	assert (db.hasIndex("doesnotexist") == false);
	assert (db.hasView("doesnotexist") == false);

	s2("close");
	db.close();
}