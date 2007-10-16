/**
 * Authors: The D DBI project
 *
 * Version: 0.2.5
 *
 * Copyright: BSD license
 */
module dbi.odbc.OdbcResult;

// Almost every cast involving chars and SQLCHARs shouldn't exist, but involve bugs in
// WindowsAPI revision 144.  I'll see about fixing their ODBC and SQL files soon.
// WindowsAPI should also include odbc32.lib itself.

version (Phobos) {
	private import std.string : trim = strip;
} else {
	private import tango.text.Util : trim;
}
private import dbi.DBIException, dbi.Result, dbi.Row;
private import win32.odbcinst, win32.sql, win32.sqlext, win32.sqltypes, win32.sqlucode, win32.windef;

version (Windows) pragma (lib, "odbc32.lib");

/*
 * This is in the sql headers, but wasn't ported in WindowsAPI revision 144.
 */
private bool SQL_SUCCEEDED (SQLRETURN ret) {
	return (ret == SQL_SUCCESS || ret == SQL_SUCCESS_WITH_INFO) ? true : false;
}

/**
 * Manage a result set from an ODBC interface query.
 *
 * See_Also:
 *	Result is the interface of which this provides an implementation.
 */
class OdbcResult : Result {
	public:
	this (SQLHSTMT stmt) {
		this.stmt = stmt;

		if (!SQL_SUCCEEDED(SQLNumResultCols(stmt, &numColumns))) {
			throw new DBIException("Unable to get the number of columns.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
		}
		columnTypesNum.length = numColumns;
		columnTypesName.length = numColumns;
		columnNames.length = numColumns;

		SQLLEN typeNum;
		SQLCHAR[512] typeName;
		SQLSMALLINT typeNameLength;
		SQLCHAR[512] columnName;
		SQLSMALLINT columnNameLength;
		for (SQLUSMALLINT i = 1; i <= numColumns; i++) {
			if (!SQL_SUCCEEDED(SQLColAttribute(stmt, i, SQL_DESC_TYPE, null, 0, null, &typeNum))) {
				throw new DBIException("Unable to get the SQL column types.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
			}
			if (!SQL_SUCCEEDED(SQLColAttribute(stmt, i, SQL_DESC_TYPE_NAME, typeName.ptr, typeName.length, &typeNameLength, null))) {
				throw new DBIException("Unable to get the SQL column type names.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
			}
			if (!SQL_SUCCEEDED(SQLColAttribute(stmt, i, SQL_DESC_NAME, columnName.ptr, columnName.length, &columnNameLength, null))) {
				throw new DBIException("Unable to get the SQL column names.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
			}

			columnTypesNum[i - 1] = typeNum;
			columnTypesName[i - 1] = cast(char[])typeName[0 .. typeNameLength].dup;
			columnNames[i - 1] = cast(char[])columnName[0 .. columnNameLength].dup;
		}
	}

	/**
	 * Get the next row from a result set.
	 *
	 * Returns:
	 *	A Row object with the queried information or null for an empty set.
	 */
	override Row fetchRow () {
		if (SQL_SUCCEEDED(SQLFetch(stmt))) {
			Row row = new Row();
			SQLLEN indicator;
			SQLCHAR[512] buf;

			for (SQLUSMALLINT i = 1; i <= numColumns; i++) {
				if (SQL_SUCCEEDED(SQLGetData(stmt, i, SQL_C_CHAR, buf.ptr, buf.length, &indicator))) {
					if (indicator == SQL_NULL_DATA) {
						buf[0 .. 4] = cast(SQLCHAR[])"null";
						buf[4 .. length] = cast(SQLCHAR)'\0';
					}
					if (indicator < 0) {
						row.addField(columnNames[i - 1], null, columnTypesName[i - 1], columnTypesNum[i - 1]);
					} else {
						row.addField(columnNames[i - 1], trim(cast(char[])buf[0 .. indicator]), columnTypesName[i - 1], columnTypesNum[i - 1]);
					}
				}
			}
			return row;
		} else {
			return null;
		}
	}

	/**
	 * Free all database resources used by a result set.
	 *
	 * Throws:
	 *	DBIException if an ODBC statement couldn't be destroyed.
	 */
	override void finish () {
		if (cast(void*)stmt !is null) {
			if (!SQL_SUCCEEDED(SQLFreeHandle(SQL_HANDLE_STMT, stmt))) {
				throw new DBIException("Unable to destroy an ODBC statement.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
			}
			stmt = cast(SQLHANDLE)null;
		}
	}

	private:
	SQLHSTMT stmt;
	SQLSMALLINT numColumns;
	int[] columnTypesNum;
	char[][] columnTypesName;
	char[][] columnNames;
	char[512][] columnData;

	/**
	 * Get the last error message returned by the server.
	 */
	char[] getLastErrorMessage () {
		SQLSMALLINT errorNumber;
		SQLCHAR[5] state;
		SQLINTEGER nativeCode;
		SQLCHAR[512] text;
		SQLSMALLINT textLength;

		SQLGetDiagField(SQL_HANDLE_STMT, stmt, 0, SQL_DIAG_NUMBER, &errorNumber, 0, null);
		SQLGetDiagRec(SQL_HANDLE_STMT, stmt, errorNumber, state.ptr, &nativeCode, text.ptr, text.length, &textLength);
		return cast(char[])state ~ " = " ~ cast(char[])text;
	}

	/**
	 * Get the last error code return by the server.  This is the native code.
	 */
	int getLastErrorCode () {
		SQLSMALLINT errorNumber;
		SQLCHAR[5] state;
		SQLINTEGER nativeCode;
		SQLCHAR[512] text;
		SQLSMALLINT textLength;

		SQLGetDiagField(SQL_HANDLE_STMT, stmt, 0, SQL_DIAG_NUMBER, &errorNumber, 0, null);
		SQLGetDiagRec(SQL_HANDLE_STMT, stmt, errorNumber, state.ptr, &nativeCode, text.ptr, text.length, &textLength);
		return nativeCode;
	}
}