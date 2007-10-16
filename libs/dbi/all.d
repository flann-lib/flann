/**
 * Authors: The D DBI project
 *
 * Version: 0.2.5
 *
 * Copyright: BSD license
 */
module dbi.all;

version (build) {
	pragma (ignore);
}

public import	dbi.Database,
		dbi.DBIException,
		dbi.ErrorCode,
		dbi.Result,
		dbi.Row,
		dbi.Statement;