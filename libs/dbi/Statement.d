/**
 * Authors: The D DBI project
 *
 * Version: 0.2.5
 *
 * Copyright: BSD license
 */
module dbi.Statement;

version (Phobos) {
	private static import std.string;
	debug (UnitTest) private static import std.stdio;
} else {
	private static import tango.text.Util;
	private static import tango.text.Regex;
	debug (UnitTest) private static import tango.io.Stdout;
}
private import dbi.Database, dbi.DBIException, dbi.Result;

/**
 * A prepared SQL statement.
 *
 * Bugs:
 *	The statement is stored but not prepared.
 *
 *	The index version of bind ignores its first parameter.
 *
 *	The two forms of bind cannot be used at the same time.
 *
 * Todo:
 *	make execute/query("10", "20", 30); work (variable arguments for binding to ?, ?, ?, etc...)
 */
final class Statement {
	/**
	 * Make a new instance of Statement.
	 *
	 * Params:
	 *	database = The database connection to use.
	 *	sql = The SQL code to prepare.
	 */
	this (Database database, char[] sql) {
		this.database = database;
		this.sql = sql;
	}

	/**
	 * Bind a _value to the next "?".
	 *
	 * Params:
	 *	index = Currently ignored.  This is a bug.
	 *	value = The _value to _bind.
	 */
	void bind (size_t index, char[] value) {
		binds ~= escape(value);
	}

	/**
	 * Bind a _value to a ":name:".
	 *
	 * Params:
	 *	fn = The name to _bind value to.
	 *	value = The _value to _bind.
	 */
	void bind (char[] fn, char[] value) {
		bindsFNs ~= fn;
		binds ~= escape(value);
	}

	/**
	 * Execute a SQL statement that returns no results.
	 */
	void execute () {
		database.execute(getSql());
	}

	/**
	 * Query the database.
	 *
	 * Returns:
	 *	A Result object with the queried information.
	 */
	Result query () {
		return database.query(getSql());
	}

	private:
	Database database;
	char[] sql;
	char[][] binds;
	char[][] bindsFNs;

	/**
	 * Escape a SQL statement.
	 *
	 * Params:
	 *	string = An unescaped SQL statement.
	 *
	 * Returns:
	 *	The escaped form of string.
	 */
	char[] escape (char[] string) {
		if (database !is null) {
			return database.escape(string);
		} else {
			char[] result;
			size_t count = 0;

			// Maximum length needed if every char is to be quoted
			result.length = string.length * 2;

			for (size_t i = 0; i < string.length; i++) {
				switch (string[i]) {
					case '"':
					case '\'':
					case '\\':
						result[count++] = '\\';
						break;
					default:
						break;
				}
				result[count++] = string[i];
			}

			result.length = count;
			return result;
		}
	}

	/**
	 * Replace every "?" in the current SQL statement with its bound value.
	 *
	 * Returns:
	 *	The current SQL statement with all occurences of "?" replaced.
	 *
	 * Todo:
	 *	Raise an exception if binds.length != count(sql, "?")
	 */
	char[] getSqlByQM () {
		char[] result;
		size_t i = 0, j = 0, count = 0;

		// binds.length is for the '', only 1 because we replace the ? too
		result.length = sql.length + binds.length;
		for (i = 0; i < binds.length; i++) {
			result.length = result.length + binds[i].length;
		}

		for (i = 0; i < sql.length; i++) {
			if (sql[i] == '?') {
				result[j++] = '\'';
				result[j .. j + binds[count].length] = binds[count];
				j += binds[count++].length;
				result[j++] = '\'';
			}
			else {
				result[j++] = sql[i];
			}
		}

		sql = result;
		return result;
	}

	/**
	 * Replace every ":name:" in the current SQL statement with its bound value.
	 *
	 * Returns:
	 *	The current SQL statement with all occurences of ":name:" replaced.
	 *
	 * Todo:
	 *	Raise an exception if binds.length != (count(sql, ":") * 2)
	 */
	char[] getSqlByFN () {
		char[] result = sql;
		version (Phobos) {
			ptrdiff_t beginIndex = 0, endIndex = 0;
			while ((beginIndex = std.string.find(result, ":")) != -1 && (endIndex = std.string.find(result[beginIndex + 1 .. length], ":")) != -1) {
				result = result[0 .. beginIndex] ~ "'" ~ getBoundValue(result[beginIndex + 1.. beginIndex + endIndex + 1]) ~ "'" ~ result[beginIndex + endIndex + 2 .. length];
			}
		} else {
			uint beginIndex = 0, endIndex = 0;
			while ((beginIndex = tango.text.Util.locate(result, ':')) != result.length && (endIndex = tango.text.Util.locate(result, ':', beginIndex + 1)) != result.length) {
				result = result[0 .. beginIndex] ~ "'" ~ getBoundValue(result[beginIndex + 1 .. endIndex]) ~ "'" ~ result[endIndex + 1 .. length];
			}
		}
		return result;
	}

	/**
	 * Replace all variables with their bound values.
	 *
	 * Returns:
	 *	The current SQL statement with all occurences of variables replaced.
	 */
	char[] getSql () {
		version (Phobos) {
			if (std.string.find(sql, "?") != -1) {
				return getSqlByQM();
			} else if (std.string.find(sql, ":") != -1) {
				return getSqlByFN();
			} else {
				return sql;
			}
		} else {
			if (tango.text.Util.contains(sql, '?')) {
				return getSqlByQM();
			} else if (tango.text.Util.contains(sql, ':')) {
				return getSqlByFN();
			} else {
				return sql;
			}
		}
	}

	/**
	 * Get the value bound to a ":name:".
	 *
	 * Params:
	 *	fn = The ":name:" to return the bound value of.
	 *
	 * Returns:
	 *	The bound value of fn.
	 *
	 * Throws:
	 *	DBIException if fn is not bound
	 */
	char[] getBoundValue (char[] fn) {
		for (size_t index = 0; index < bindsFNs.length; index++) {
			if (bindsFNs[index] == fn) {
				return binds[index];
			}
		}
		throw new DBIException(fn ~ " is not bound in the Statement.");
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

	s1("dbi.Statement:");
	Statement stmt = new Statement(null, "SELECT * FROM people");
	char[] resultingSql = "SELECT * FROM people WHERE id = '10' OR name LIKE 'John Mc\\'Donald'";

	s2("escape");
	assert (stmt.escape("John Mc'Donald") == "John Mc\\'Donald");

	s2("simple sql");
	stmt = new Statement(null, "SELECT * FROM people");
	assert (stmt.getSql() == "SELECT * FROM people");

	s2("bind by '?'");
	stmt = new Statement(null, "SELECT * FROM people WHERE id = ? OR name LIKE ?");
	stmt.bind(1, "10");
	stmt.bind(2, "John Mc'Donald");
	assert (stmt.getSql() == resultingSql);

	/+
	s2("bind by '?' sent to getSql via variable arguments");
	stmt = new Statement("SELECT * FROM people WHERE id = ? OR name LIKE ?");
	assert (stmt.getSql("10", "John Mc'Donald") == resultingSql);
	+/

	s2("bind by ':fieldname:'");
	stmt = new Statement(null, "SELECT * FROM people WHERE id = :id: OR name LIKE :name:");
	stmt.bind("id", "10");
	stmt.bind("name", "John Mc'Donald");
	assert (stmt.getBoundValue("name") == "John Mc\\'Donald");
	assert (stmt.getSql() == resultingSql);
}