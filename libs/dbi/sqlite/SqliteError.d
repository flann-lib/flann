/**
 * Authors: The D DBI project
 *
 * Version: 0.2.5
 *
 * Copyright: BSD license
 */
module dbi.sqlite.SqliteError;

private import dbi.ErrorCode;
private import dbi.sqlite.imp;

/**
 * Convert a SQLite _error code to an ErrorCode.
 *
 * Params:
 *	error = The SQLite _error code.
 *
 * Returns:
 *	The ErrorCode representing error.
 *
 * Note:
 *	Written against the SQLite 3.3.6 documentation.
 */
package ErrorCode specificToGeneral (int error) {
	switch (error) {
		case (SQLITE_OK):
			return ErrorCode.NoError;
		case (SQLITE_ERROR):
			return ErrorCode.InvalidQuery;
		case (SQLITE_INTERNAL):
			return ErrorCode.ServerError;
		case (SQLITE_PERM):
			return ErrorCode.PermissionsError;
		case (SQLITE_ABORT):
			return ErrorCode.Unknown;
		case (SQLITE_BUSY):
			return ErrorCode.ServerError;
		case (SQLITE_LOCKED):
			return ErrorCode.ServerError;
		case (SQLITE_NOMEM):
			return ErrorCode.ServerError;
		case (SQLITE_READONLY):
			return ErrorCode.InvalidQuery;
		case (SQLITE_INTERRUPT):
			return ErrorCode.Unknown;
		case (SQLITE_IOERR):
			return ErrorCode.InvalidData;
		case (SQLITE_CORRUPT):
			return ErrorCode.InvalidData;
		case (SQLITE_NOTFOUND):
			return ErrorCode.InvalidQuery;
		case (SQLITE_FULL):
			return ErrorCode.ServerError;
		case (SQLITE_CANTOPEN):
			return ErrorCode.ServerError;
		case (SQLITE_PROTOCOL):
			return ErrorCode.ProtocolError;
		case (SQLITE_EMPTY):
			return ErrorCode.InvalidData;
		case (SQLITE_SCHEMA):
			return ErrorCode.InvalidData;
		case (SQLITE_TOOBIG):
			return ErrorCode.InvalidData;
		case (SQLITE_CONSTRAINT):
			return ErrorCode.InvalidQuery;
		case (SQLITE_MISMATCH):
			return ErrorCode.InvalidData;
		case (SQLITE_MISUSE):
			return ErrorCode.InvalidQuery;
		case (SQLITE_NOLFS):
			return ErrorCode.ServerError;
		case (SQLITE_AUTH):
			return ErrorCode.PermissionsError;
		case (SQLITE_ROW):
			return ErrorCode.NoError;
		case (SQLITE_DONE):
			return ErrorCode.NoError;
		default:
			return ErrorCode.Unknown;
	}
	// Bugfix for DMD 0.162
	return ErrorCode.Unknown;
}