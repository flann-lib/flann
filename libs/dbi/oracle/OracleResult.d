/**
 * Authors: The D DBI project
 *
 * Version: 0.2.5
 *
 * Copyright: BSD license
 */
module dbi.oracle.OracleResult;

private import dbi.DBIException, dbi.Result, dbi.Row;
private import dbi.oracle.imp.oci;

/**
 * Manage a result set from an Oracle database query.
 *
 * See_Also:
 *	Result is the interface of which this provides an implementation.
 */
class OracleResult : Result {
	public:
	this () {

	}

	/**
	 * Get the next row from a result set.
	 *
	 * Returns:
	 *	A Row object with the queried information or null for an empty set.
	 */
	override Row fetchRow () {
		return null;
	}

	/**
	 * Free all database resources used by a result set.
	 */
	override void finish () {

	}

	private:
}