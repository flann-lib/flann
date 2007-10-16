/**
 * Authors: The D DBI project
 *
 * Version: 0.2.5
 *
 * Copyright: BSD license
 */
module dbi.mssql.MssqlResult;

version (Phobos) {
	private import std.string : toDString = toString, toCString = toStringz, locate = find;
} else {
	private import tango.stdc.stringz : toDString = fromUtf8z, toCString = toUtf8z;
	private import tango.text.Util : locate;
	private static import tango.text.convert.Float, tango.text.convert.Integer;
}
import dbi.DBIException, dbi.Result, dbi.Row;
import dbi.mssql.imp, dbi.mssql.MssqlDate;

/**
 * Manage a result set from a MSSQL database query.
 *
 * See_Also:
 *	Result is the interface of which this provides an implementation.
 */
class MssqlResult : Result {
	public:
	this (CS_COMMAND* cmd) {
		this.cmd = cmd;
	}

	/**
	 * Get the next row from a result set.
	 *
	 * Returns:
	 *	A Row object with the queried information or null for an empty set.
	 */
	override Row fetchRow () {
		while (ct_results(cmd, &restype) == CS_SUCCEED) {
			switch (restype) {
				case CS_CMD_SUCCEED:
					break;
				case CS_CMD_DONE:
					break;
				case CS_CMD_FAIL:
					// TODO: MssqlError or some such
					throw new DBIException("Failed to get Results");
				case CS_ROW_RESULT:
					// set numFields if needed
					if (numFields < 0) {
						setNumFields();
						setFields();
					}
					// create new Row object, populate it, and return it
					Row r = new Row();
					int count;

					while (ct_fetch(cmd, CS_UNUSED, CS_UNUSED, CS_UNUSED, &count) == CS_SUCCEED) {
						numRows += count;

						char[] value;
						char[] fieldname;

						for (int i = 0; i < numFields; ++i) {
							fieldname = fields[i].name[0 .. locate(fields[i].name, '\0')];
							switch (fields[i].datatype) {
								case CS_CHAR_TYPE:
									value = strings[i][0 .. lengths[i]];
									break;
								case CS_FLOAT_TYPE:
									version (Phobos) {
										value = toDString(floats[i]);
									} else {
										value = tango.text.convert.Float.toUtf8(floats[i]);
									}
									break;
								case CS_DATETIME_TYPE:
									MssqlDate date = new MssqlDate(dts[i]);
									value = date.getString();
									break;
								case CS_DATETIME4_TYPE:
									MssqlDate date = new MssqlDate(dt4s[i]);
									value = date.getString();
									break;
								case CS_MONEY_TYPE:
									/* fall through */
								case CS_MONEY4_TYPE:
									version (Phobos) {
										value = toDString(cast(float)ints[i] / 10000);
									} else {
										value = tango.text.convert.Float.toUtf8(cast(float)ints[i] / 10000);
									}
									break;
								default:
									version (Phobos) {
										value = toDString(ints[i]);
									} else {
										value = tango.text.convert.Integer.toUtf8(ints[i]);
									}
									break;
							}

							version (Phobos) {
								r.addField(fieldname, value, toDString(fields[i].datatype), fields[i].datatype);
							} else {
								r.addField(fieldname, value, tango.text.convert.Integer.toUtf8(fields[i].datatype), fields[i].datatype);
							}
						}
						// we only want to return one row, so exit both while loops
						return r;
					}
					default:
						break;
				}
			}
			return null;
		}

	/**
	 * Free all database resources used by a result set.
	 */
	override void finish () {
		/* TODO: */
	}

	private:
	CS_COMMAND* cmd;
	CS_RETCODE restype;

	int numRows = -1;
	int numFields = -1;

	CS_DATAFMT[] fields;
	char[][] strings;
	CS_FLOAT[] floats;
	CS_INT[] ints;
	CS_DATETIME[] dts;
	CS_DATETIME4[] dt4s;
	int[] lengths;
	short[] inds;

	void setNumFields() {
		// get field count
		int _numFields;
		ct_res_info(cmd, CS_NUMDATA, &_numFields, CS_UNUSED, null);
		this.numFields =_numFields;

		// we can also set the length of the fields, strings, lengths, inds arrays
		fields.length = lengths.length = inds.length= strings.length = floats.length = ints.length = dts.length = dt4s.length = numFields;
	}

	void setFields() {
		int i;

		// for each field, set the field info in fields array, and bind field
		// to other arrays
		for (i = 0; i < numFields; ++i) {
			ct_describe(cmd, (i + 1), &fields[i]);

			switch (fields[i].datatype) {
				case CS_CHAR_TYPE:
					if (strings[i].length != fields[i].maxlength) {
						strings[i].length = fields[i].maxlength;
					}
					ct_bind(cmd, (i + 1), &fields[i], strings[i].ptr, &lengths[i], &inds[i]);
					break;
				case CS_FLOAT_TYPE:
					ct_bind(cmd, (i + 1), &fields[i], &floats[i], &lengths[i], &inds[i]);
					break;
				case CS_DATETIME_TYPE:
					ct_bind(cmd, (i + 1), &fields[i], &dts[i], &lengths[i], &inds[i]);
					break;
				case CS_DATETIME4_TYPE:
					ct_bind(cmd, (i + 1), &fields[i], &dt4s[i], &lengths[i], &inds[i]);
					break;
				default:
					ct_bind(cmd, (i + 1), &fields[i], &ints[i], &lengths[i], &inds[i]);
					break;
			}
		}
	}
}