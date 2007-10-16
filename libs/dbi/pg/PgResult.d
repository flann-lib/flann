/**
 * Authors: The D DBI project
 *
 * Version: 0.2.5
 *
 * Copyright: BSD license
 */
module dbi.pg.PgResult;

version (Phobos) {
	private import std.string : trim = strip, toDString = toString;
} else {
	private import tango.stdc.stringz : toDString = fromUtf8z;
	private import tango.text.Util : trim;
}
private import dbi.DBIException, dbi.Result, dbi.Row;
private import dbi.pg.imp, dbi.pg.PgError;

/**
 * Manage a result set from a PostgreSQL database query.
 *
 * See_Also:
 *	Result is the interface of which this provides an implementation.
 */
class PgResult : Result {
	public:
	this (PGconn* conn, PGresult* results) {
		this.results = results;
		numRows = PQntuples(results);
		numFields = PQnfields(results);
	}

	/**
	 * Get the next row from a result set.
	 *
	 * Returns:
	 *	A Row object with the queried information or null for an empty set.
	 */
	override Row fetchRow () {
		if (index >= numRows) {
			return null;
		}
		Row r = new Row();
		for (int a = 0; a < numFields; a++) {
			r.addField(trim(toDString(PQfname(results, a))), trim(toDString(PQgetvalue(results, index, a))), "", PQftype(results, a));
		}
		index++;
		return r;
	}

	/**
	 * Free all database resources used by a result set.
	 */
	override void finish () {
		if (results !is null) {
			PQclear(results);
			results = null;
		}
	}

	private:
	PGresult* results;
	int index;
	const int numRows;
	const int numFields;
}