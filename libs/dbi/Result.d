/**
 * Authors: The D DBI project
 *
 * Version: 0.2.5
 *
 * Copyright: BSD license
 */
module dbi.Result;

private import dbi.Row;

/**
 * Manage a result set from a database query.
 *
 * This is the class returned by every query function, not the DBD specific result
 * class.
 *
 * See_Also:
 *	The result class for the DBD you are using.
 */
abstract class Result {
	/**
	 * A destructor that attempts to force the the release of of all
	 * statements handles and similar things.
	 *
	 * The current D garbage collector doesn't always call destructors,
	 * so it is HIGHLY recommended that you close connections manually.
	 */
	~this () {
		finish();
	}

	/**
	 * Get the next row from a result set.
	 *
	 * Returns:
	 *	A Row object with the queried information or null for an empty set.
	 */
	abstract Row fetchRow ();

	/**
	 * Get all of the remaining rows from a result set.
	 *
	 * Returns:
	 *	An array of Row objects with the queried information.
	 */
	Row[] fetchAll () {
		Row[] rows;
		Row row;
		while ((row = fetchRow()) !is null) {
			rows ~= row;
		}
		finish();
		return rows;
	}

	/**
	 * Free all database resources used by a result set.
	 */
	abstract void finish ();
}