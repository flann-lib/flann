/**
 * Authors: The D DBI project
 *
 * Version: 0.2.5
 *
 * Copyright: BSD license
 */
module dbi.pg.PgError;

private import dbi.ErrorCode;

/**
 * Convert a PostgreSQL _error code to an ErrorCode.
 *
 * Params:
 *	error = The PostgreSQL _error code.
 *
 * Returns:
 *	The ErrorCode representing error.
 *
 * Note:
 *	Written against the PostgreSQL 8.1.4 documentation.
 */
package ErrorCode specificToGeneral (char* error) {
	if (error[0 .. 2] == "22") {
		return ErrorCode.InvalidData;
	} else if (error[0 .. 2] == "23") {
		return ErrorCode.InvalidQuery;
	} else if (error[0 .. 2] == "25") {
		return ErrorCode.ServerError;
	} else if (error[0 .. 2] == "42" && error[2 .. 5] != "501") {
		return ErrorCode.InvalidQuery;
	} else if (error[0 .. 2] == "53") {
		return ErrorCode.Unknown;
	} else if (error[0 .. 2] == "54") {
		return ErrorCode.ServerError;
	} else if (error[0 .. 2] == "55") {
		return ErrorCode.ServerError;
	} else if (error[0 .. 2] == "57") {
		return ErrorCode.Unknown;
	} else if (error[0 .. 2] == "58") {
		return ErrorCode.Unknown;
	}
	switch (error[0 .. 5]) {
		case "0":
			return ErrorCode.NoError;
		case "1000":
			return ErrorCode.Unknown;
		case "1003":
			return ErrorCode.NoError;
		case "1004":
			return ErrorCode.InvalidData;
		case "1006":
			return ErrorCode.ServerError;
		case "1007":
			return ErrorCode.ServerError;
		case "1008":
			return ErrorCode.NoError;
		case "0100C":
			return ErrorCode.NoError;
		case "01P01":
			return ErrorCode.NotImplemented;
		case "2000":
			return ErrorCode.NoError;
		case "2001":
			return ErrorCode.NoError;
		case "3000":
			return ErrorCode.InvalidQuery;
		case "8000":
			return ErrorCode.ConnectionError;
		case "8001":
			return ErrorCode.ConnectionError;
		case "8003":
			return ErrorCode.ConnectionError;
		case "8004":
			return ErrorCode.ConnectionError;
		case "8006":
			return ErrorCode.ConnectionError;
		case "08P01":
			return ErrorCode.ConnectionError;
		case "9000":
			return ErrorCode.ServerError;
		case "0A000":
			return ErrorCode.NotImplemented;
		case "0B000":
			return ErrorCode.InvalidQuery;
		case "0F000":
			return ErrorCode.InvalidData;
		case "0F001":
			return ErrorCode.InvalidData;
		case "0L000":
			return ErrorCode.InvalidData;
		case "0LP01":
			return ErrorCode.InvalidQuery;
		case "0P000":
			return ErrorCode.InvalidQuery;
		case "21000":
			return ErrorCode.InvalidData;
		case "24000":
			return ErrorCode.InvalidData;
		case "26000":
			return ErrorCode.InvalidData;
		case "27000":
			return ErrorCode.ServerError;
		case "28000":
			return ErrorCode.InvalidData;
		case "2B000":
			return ErrorCode.Unknown;
		case "2BP01":
			return ErrorCode.Unknown;
		case "2D000":
			return ErrorCode.InvalidQuery;
		case "2F000":
			return ErrorCode.ServerError;
		case "2F002":
			return ErrorCode.PermissionsError;
		case "2F003":
			return ErrorCode.PermissionsError;
		case "2F004":
			return ErrorCode.PermissionsError;
		case "2F005":
			return ErrorCode.InvalidQuery;
		case "34000":
			return ErrorCode.InvalidData;
		case "38000":
			return ErrorCode.ServerError;
		case "38001":
			return ErrorCode.PermissionsError;
		case "38002":
			return ErrorCode.PermissionsError;
		case "38003":
			return ErrorCode.PermissionsError;
		case "38004":
			return ErrorCode.PermissionsError;
		case "39000":
			return ErrorCode.ServerError;
		case "39001":
			return ErrorCode.InvalidData;
		case "39004":
			return ErrorCode.InvalidData;
		case "39P01":
			return ErrorCode.ProtocolError;
		case "39P02":
			return ErrorCode.ProtocolError;
		case "3B000":
			return ErrorCode.ServerError;
		case "3B001":
			return ErrorCode.InvalidQuery;
		case "3D000":
			return ErrorCode.InvalidQuery;
		case "3F000":
			return ErrorCode.InvalidQuery;
		case "40000":
			return ErrorCode.NoError;
		case "40001":
			return ErrorCode.ServerError;
		case "40002":
			return ErrorCode.InvalidQuery;
		case "40003":
			return ErrorCode.Unknown;
		case "40P01":
			return ErrorCode.Unknown;
		case "42501":
			return ErrorCode.PermissionsError;
		case "44000":
			return ErrorCode.InvalidQuery;
		case "F0000":
			return ErrorCode.ServerError;
		case "F0001":
			return ErrorCode.ServerError;
		case "P0000":
			return ErrorCode.ServerError;
		case "P0001":
			return ErrorCode.ServerError;
		case "XX000":
			return ErrorCode.ServerError;
		case "XX001":
			return ErrorCode.ServerError;
		case "XX002":
			return ErrorCode.ServerError;
		default:
			return ErrorCode.Unknown;
	}
	// Bugfix for DMD 0.162
	return ErrorCode.Unknown;
}