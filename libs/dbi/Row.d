
/**
 * Authors: The D DBI project
 *
 * Version: 0.2.5
 *
 * Copyright: BSD license
 */
module dbi.Row;

version (Phobos) {
	debug (UnitTest) private static import std.stdio;
} else {
	debug (UnitTest) private static import tango.io.Stdout;
}
private import dbi.DBIException;

/**
 * Access to a single row in a result set.
 *
 * Almost everything in this file is going to be deprecated and replaced soon.  To
 * give your opinions on what should be done with it, go to the D DBI forums at
 * www.dsource.org/forums/viewtopic.php?t=1640.  Whatever is decided will
 * take effect in version 0.3.0.  Anything deprecated will be removed in version
 * 0.4.0.
 *
 * As a result, this file is no longer being updated with the exception of bug
 * fixes.  It is highly recommended that even if you do not want to contribute
 * to the discussion on what to do to this file, you should follow the link to see
 * what the new version is likely to look like.
 */
final class Row {
	/**
	 * Get a field's contents by index.
	 *
	 * Params:
	 *	idx = Field index.
	 *
	 * Examples:
	 *	---
	 *	Row row = res.fetchRow();
	 *	writefln("first=%s, last=%s\n", row[0], row[1]);
	 *	---
	 *
	 * Returns:
	 *	The field's contents.
	 */
	char[] opIndex (int idx) {
		return get(idx);
	}

	/**
	 * Get a field's contents by field _name.
	 *
	 * Params:
	 *	name = Field _name.
	 *
	 * Examples:
	 *	---
	 *	Row row = res.fetchRow();
	 *	wriefln("first=%s, last=%s\n", row["first"], row["last"]);
	 *	---
	 *
	 * Returns:
	 *	The field's contents.
	 */
	char[] opIndex (char[] name) {
		return get(name);
	}

	/**
	 * Get a field's contents by index.
	 *
	 * Params:
	 *	idx = Field index.
	 *
	 * Returns:
	 *	The field's contents.
	 */
	char[] get (int idx) {
		return fieldValues[idx];
	}

	/**
	 * Get a field's contents by field _name.
	 *
	 * Params:
	 *	name = Field _name.
	 *
	 * Returns:
	 *	The field's contents.
	 */
	char[] get (char[] name) {
		return fieldValues[getFieldIndex(name)];
	}

	/**
	 * Get a field's index by field _name.
	 *
	 * Params:
	 *	name = Field _name.
	 *
	 * Throws:
	 *	DBIException if name is not a valid index.
	 *
	 * Returns:
	 *	The field's index.
	 */
	int getFieldIndex (char[] name) {
		for (int idx = 0; idx < fieldNames.length; idx++) {
			if (fieldNames[idx] == name) {
				return idx;
			}
		}
		throw new DBIException("The name '" ~ name ~ "' is not a valid index.");
	}

	/**
	 * Get the field type.
	 *
	 * Params:
	 *	idx = Field index.
	 *
	 * Returns:
	 *	The field's type.
	 */
	int getFieldType (int idx) {
		return fieldTypes[idx];
	}

	/**
	 * Get a field's SQL declaration.
	 *
	 * Params:
	 *	idx = Field index.
	 *
	 * Returns:
	 *	The field's SQL declaration.
	 */
	char[] getFieldDecl (int idx) {
		return fieldDecls[idx];
	}

	/**
	 * Add a new field to this row.
	 *
	 * Params:
	 *	name = Name.
	 *	value = Value.
	 *	decl = SQL declaration, i.e. varchar(20), decimal(12,2), etc...
	 *	type = SQL _type.
	 *
	 * Todo:
	 *	SQL _type should be defined by the D DBI DBD interface spec, therefore
	 *	each DBD module will act exactly alike.
	 */
	void addField (char[] name, char[] value, char[] decl, int type) {
		fieldNames ~= name;
		fieldValues ~= value.dup;
		fieldDecls ~= decl.dup;
		fieldTypes ~= type;
	}

	private:
	char[][] fieldNames;
	char[][] fieldValues;
	char[][] fieldDecls;
	int[] fieldTypes;
}

unittest {
	version (Phobos) {
		void s1 (char[] s) {
			std.stdio.writefln("%s", s);
		}

		void s2 (char[] s) {
			std.stdio.writefln("   ...%s", s);
		}
	} else {
		void s1 (char[] s) {
			tango.io.Stdout.Stdout(s).newline();
		}

		void s2 (char[] s) {
			tango.io.Stdout.Stdout("   ..." ~ s).newline();
		}
	}

	s1("dbi.Row:");
	Row r1 = new Row();
	r1.addField("name", "John Doe", "text", 3);
	r1.addField("age", "23", "integer", 1);

	s2("get(int)");
	assert (r1.get(0) == "John Doe");

	s2("get(char[])");
	assert (r1.get("name") == "John Doe");

	s2("[int]");
	assert (r1[0] == "John Doe");

	s2("[char[]]");
	assert (r1["age"] == "23");

	s2("getFieldIndex");
	assert (r1.getFieldIndex("name") == 0);

	s2("getFieldType");
	assert (r1.getFieldType(0) == 3);

	s2("getFieldDecl");
	assert (r1.getFieldDecl(1) == "integer");
}