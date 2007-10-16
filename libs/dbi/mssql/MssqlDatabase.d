/**
 * Authors: The D DBI project
 *
 * Version: 0.2.5
 *
 * Copyright: BSD license
 */
module dbi.mssql.MssqlDatabase;

version (Phobos) {
	private import std.string : toDString = toString, toCString = toStringz;
	debug (UnitTest) private static import std.stdio;
} else {
	private import tango.stdc.stringz : toDString = fromUtf8z, toCString = toUtf8z;
	debug (UnitTest) private static import tango.io.Stdout;
}
private import dbi.Database, dbi.DBIException, dbi.Result, dbi.Row, dbi.Statement;
private import dbi.mssql.imp, dbi.mssql.MssqlResult;

/**
 * An implementation of Database for use with MSSQL databases.
 *
 * See_Also:
 *	Database is the interface that this provides an implementation of.
 */
class MssqlDatabase : Database {
	public:
	/**
	 * Create a new instance of Database, but don't connect.
	 */
	this () {
	}

	/**
	 * Create a new instance of Database and connect to a server.
	 *
	 * See_Also:
	 *	connect
	 */
	this (char[] params, char[] username = null, char[] password = null) {
		this();
		connect(params, username, password);
	}

	/**
	 * Connect to a database on a MSSQL server.
	 *
	 * Params:
	 *	params = A string in the form "server port"
	 *
	 * Todo: is it supposed to be "keyword1=value1;keyword2=value2;etc."
	 *           and be consistent with other DBI's ??
	 *
	 *	username = The _username to _connect with.
	 *	password = The _password to _connect with.
	 *
	 * Throws:
	 *	DBIException if there was an error connecting.
	 *
	 * Examples:
	 *	---
	 *	MssqlDatabase db = new MssqlDatabase();
	 *	db.connect("host port", "username", "password");
	 *	---
	 */
	override void connect (char[] params, char[] username = null, char[] password = null) {
		CS_RETCODE ret;
		if (params is null) {
			params = "";
		}

		// allocate context
		ret = cs_ctx_alloc(CS_VERSION_100, &ctx);
		if (ret != CS_SUCCEED) {
			throw new DBIException("Cannot allocate context");
		}

		// init context
		ret = ct_init(ctx, CS_VERSION_100);
		if (ret != CS_SUCCEED) {
			throw new DBIException("Cannot init context");
		}

		// allocate connection
		ret = ct_con_alloc(ctx, &con);
		if (ret != CS_SUCCEED) {
			throw new DBIException("Cannot allocate connection");
		}

		// propset username
		ret = ct_con_props(con, CS_SET, CS_USERNAME, toCString(username), CS_NULLTERM, null);
		if (ret != CS_SUCCEED) {
			throw new DBIException("Cannot set 'username' connection property");
		}

		// propset password
		ret = ct_con_props(con, CS_SET, CS_PASSWORD, toCString(password), CS_NULLTERM, null);
		if (ret != CS_SUCCEED) {
			throw new DBIException("Cannot set 'password' connection property");
		}

		// propset serveraddr (host, port)
		ret = ct_con_props(con, CS_SET, CS_SERVERADDR, toCString(params), CS_NULLTERM, null);
		if (ret != CS_SUCCEED) {
			throw new DBIException("Cannot set 'serveraddr' connection properties");
		}

		// connect
		ret = ct_connect(con, null, CS_NULLTERM);
		if (ret != CS_SUCCEED) {
			throw new DBIException("Cannot connect to database");
		}
	}

	/**
	 * Close the current connection to the database.
	 */
	override void close () {
		if (con !is null) {
			if (ct_close(con, CS_UNUSED) != CS_SUCCEED) {
				throw new DBIException("Cannot close connection to database");
			} else {
				con = null;
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
	 *	DBIException if the SQL code couldn't be executed.
	 */
	override void execute (char[] sql) {
		if (ct_cmd_alloc(con, &cmd) != CS_SUCCEED) {
			throw new DBIException("Cannot allocate command");
		}

		if (ct_command(cmd, CS_LANG_CMD, toCString(sql), CS_NULLTERM, CS_UNUSED) != CS_SUCCEED) {
			throw new DBIException("Command failed", sql);
		}

		if (ct_send(cmd) != CS_SUCCEED) {
			throw new DBIException("Sending of command failed");
		}

		CS_RETCODE ret, restype;
		do {
			ret = ct_results(cmd, &restype);

			switch (restype) {
				case CS_CMD_SUCCEED:
					break;
				case CS_CMD_DONE:
					break;
				case CS_CMD_FAIL:
					throw new DBIException("Failed to execute command");
				default:
					break;
			}
		} while (ret == CS_SUCCEED)

		switch (ret) {
			case CS_END_RESULTS:
				break;
			case CS_FAIL:
				throw new DBIException("ct_results() failed");
			default:
				throw new DBIException("ct_results() unexpected return");
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
	override MssqlResult query (char[] sql) {
		if (ct_cmd_alloc(con, &cmd) != CS_SUCCEED) {
			throw new DBIException("Cannot allocate command");
		}

		if (ct_command(cmd, CS_LANG_CMD, toCString(sql), CS_NULLTERM, CS_UNUSED) != CS_SUCCEED) {
			throw new DBIException("Command failed", sql);
		}

		if (ct_send(cmd) != CS_SUCCEED) {
			throw new DBIException("Sending of command failed");
		}

		return new MssqlResult(cmd);
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
		// TODO: implement?  or let deprectate take care of it?
		return 0;
		// return m_errorCode;
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
		// TODO: implement? or let depreacate take care of it?
		return "not implemented";
		// return m_errorString;
	}

	private:
	CS_CONTEXT* ctx;
	CS_CONNECTION* con;
	CS_COMMAND* cmd;

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

	s1("dbi.mssql.MssqlDatabase:");
	MssqlDatabase db = new MssqlDatabase();
	s2("connect");
	db.connect("sqlvs1 1433", "test", "test");

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
	/** TODO: test some type retrieval functions */
	//assert (row.getFieldType(1) == FIELD_TYPE_STRING);
	//assert (row.getFieldDecl(1) == "char(40)");
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
}