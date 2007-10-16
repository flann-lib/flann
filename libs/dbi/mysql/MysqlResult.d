/**
 * Authors: The D DBI project
 *
 * Version: 0.2.5
 *
 * Copyright: BSD license
 */
module dbi.mysql.MysqlResult;

version (Phobos) {
	private import std.string : asString = toString;
} else {
	private import tango.stdc.stringz : asString = fromUtf8z;
}
private import dbi.DBIException, dbi.Result, dbi.Row;
private import dbi.mysql.imp;

/**
 * Manage a result set from a MySQL database query.
 *
 * See_Also:
 *	Result is the interface of which this provides an implementation.
 */
class MysqlResult : Result {
	public:
	this (MYSQL_RES* results) {
		this.results = results;

		fields = mysql_fetch_fields(results);
		fieldCount = mysql_num_fields(results);
	}

	/**
	 * Get the next row from a result set.
	 *
	 * Returns:
	 *	A Row object with the queried information or null for an empty set.
	 */
	override Row fetchRow () {
		MYSQL_ROW row = mysql_fetch_row(results);
		uint* lengths = mysql_fetch_lengths(results);
		if (row is null) {
			return null;
		}
		assert (lengths !is null);
		Row r = new Row();
		for (uint index = 0; index < fieldCount; index++) {
			r.addField(asString(fields[index].name), row[index][0 .. lengths[index]], "", fields[index].type);
		}
		return r;
	}

	/**
	 * Free all database resources used by a result set.
	 */
	override void finish () {
		if (results !is null) {
			mysql_free_result(results);
			results = null;
		}
	}

	private:
	MYSQL_RES* results;
	const MYSQL_FIELD* fields;
	const uint fieldCount;
}