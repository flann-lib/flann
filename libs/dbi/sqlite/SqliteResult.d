/**
 * Authors: The D DBI project
 *
 * Version: 0.2.5
 *
 * Copyright: BSD license
 */
module dbi.sqlite.SqliteResult;

version (Phobos) {
	private import std.string : asString = toString;
} else {
	private import tango.stdc.stringz : asString = fromUtf8z;
}
private import dbi.Result, dbi.Row;
private import dbi.sqlite.imp;

/**
 * Manage a result set from a SQLite database query.
 *
 * See_Also:
 *	Result is the interface of which this provides an implementation.
 */
class SqliteResult : Result {
	public:
	this (sqlite3_stmt* stmt) {
		this.stmt = stmt;
	}

	/**
	 * Get the next row from a result set.
	 *
	 * Returns:
	 *	A Row object with the queried information or null for an empty set.
	 */
	override Row fetchRow () {
		if (sqlite3_step(stmt) != SQLITE_ROW) {
			return null;
		}
		Row r = new Row();
		for (int a = 0; a < sqlite3_column_count(stmt); a++) {
			r.addField(asString(sqlite3_column_name(stmt,a)).dup, asString(sqlite3_column_text(stmt,a)).dup, asString(sqlite3_column_decltype(stmt,a)).dup, sqlite3_column_type(stmt,a));
		}
		return r;
	}

	/**
	 * Free all database resources used by a result set.
	 */
	override void finish () {
		if (stmt !is null) {
			sqlite3_finalize(stmt);
			stmt = null;
		}
	}

	private:
	sqlite3_stmt* stmt;
}