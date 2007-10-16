/**
 * Authors: The D DBI project
 *
 * Version: 0.2.5
 *
 * Copyright: BSD license
 */
module dbi.ErrorCode;

/**
 * The standardized D DBI error code list.
 *
 * Note that the only things guaranteed not to change are NoError and Unknown.
 */
enum ErrorCode {
	NoError = 0,		// There is no error right now.
	Unknown,		// Either DB-specific or not mapped to a standard error code.

	// Errors in establishing a connection.

	SocketError,		/// There was a local error initializing the connection.
	ProtocolError,		/// Different versions of the connection protocol are in use.
	ConnectionError,	/// Invalid username, password, or security settings.

	// Errors in making a query (general).

	OutOfSync,		/// The statement was valid, but couldn't be executed.
	InvalidData,		/// Invalid data was passed to or received from the server.
	InvalidQuery,		/// A query could not be successfully parsed.
	PermissionsError,	/// You do not have appropriate permission to do that.

	// Errors in making a query (prepared statements).

	NotPrepared,		/// A statement wasn't prepared.
	ParamsNotBound,		/// A prepared statement had unbound parameters.
	InvalidParams,		/// A prepared statement was given invalid parameters.

	// Miscellaneous

	NotImplemented,		/// A feature or function couldn't be used.
	ServerError		/// An error occurred on the server.
}

/**
 * Convert an ErrorCode to its string form.
 *
 * Params:
 *	error = The ErrorCode in enum format.
 *
 * Returns:
 *	The string form of error.
 */
char[] toString (ErrorCode error) {
	switch (error) {
		case (ErrorCode.NoError):
			return "No Error";
		case (ErrorCode.Unknown):
			return "Unknown";
		case (ErrorCode.SocketError):
			return "Socket Error";
		case (ErrorCode.ProtocolError):
			return "Protocol Mismatch Error";
		case (ErrorCode.ConnectionError):
			return "Connection Error";
		case (ErrorCode.OutOfSync):
			return "Out Of Sync";
		case (ErrorCode.InvalidData):
			return "Invalid Data";
		case (ErrorCode.InvalidQuery):
			return "Invalid Query";
		case (ErrorCode.PermissionsError):
			return "Permissions Error";
		case (ErrorCode.NotPrepared):
			return "Not Prepared";
		case (ErrorCode.ParamsNotBound):
			return "Params Not Bound";
		case (ErrorCode.InvalidParams):
			return "Invalid Params";
		case (ErrorCode.NotImplemented):
			return "Not Implemented";
		case (ErrorCode.ServerError):
			return "Server Error";
		default:
			return "Not a valid ErrorCode";
	}
	// Bugfix for DMD 0.162
	return "Not a valid ErrorCode";
}