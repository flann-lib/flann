/* /////////////////////////////////////////////////////////////////////////////
 * File:    std/openrj.d
 *
 * Purpose: Open-RJ/D mapping for the D standard library
 *
 * Created: 11th June 2004
 * Updated: 10th March 2005
 *
 * Home:    http://openrj.org/
 *
 * Copyright 2004-2005 by Matthew Wilson and Synesis Software
 * Written by Matthew Wilson
 *
 * This software is provided 'as-is', without any express or implied
 * warranty. In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, in both source and binary form, subject to the following
 * restrictions:
 *
 * -  The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * -  Altered source versions must be plainly marked as such, and must not
 *    be misrepresented as being the original software.
 * -  This notice may not be removed or altered from any source
 *    distribution.
 *
 * //////////////////////////////////////////////////////////////////////////
 * Altered by Walter Bright.
 */


/**
 * Open-RJ mapping for the D standard library.
 *
 * Authors:
 *	Matthew Wilson
 * References:
 *	$(LINK2 http://www.$(OPENRJ).org/, Open-RJ)
 * Macros:
 *	WIKI=Phobos/StdOpenrj
 *	OPENRJ=openrj
 */

/* /////////////////////////////////////////////////////////////////////////////
 * Module
 */

module std.openrj;

/* /////////////////////////////////////////////////////////////////////////////
 * Imports
 */

private import std.ctype;
version(MainTest)
{
    private import std.file;
    private import std.perf;
} // version(MainTest)
private import std.string;

/* /////////////////////////////////////////////////////////////////////////////
 * Version information
 */

// This'll be moved out to somewhere common soon

private struct Version
{
    char[]  name;
    char[]  description;
    uint    major;
    uint    minor;
    uint    revision;
    uint    edit;
    ulong   buildTime;
}

public static Version   VERSION =
{
        "std.openrj"
    ,   "Record-JAR database reader"
    ,   1
    ,   0
    ,   7
    ,   7
    ,   0
};

/* /////////////////////////////////////////////////////////////////////////////
 * Structs
 */

// This'll be moved out to somewhere common soon

private struct EnumString
{
    int     value;
    char[]  str;
};

private template enum_to_string(T)
{
    char[] enum_to_string(EnumString[] strings, T t)
    {
        // 'Optimised' search.
        //
        // Since many enums start at 0 and are contiguously ordered, it's quite
        // likely that the value will equal the index. If it does, we can just
        // return the string from that index.
        int index   =   cast(int)(t);

        if( index >= 0 &&
            index < strings.length &&
            strings[index].value == index)
        {
            return strings[index].str;
        }

        // Otherwise, just do a linear search
        foreach(EnumString s; strings)
        {
            if(cast(int)(t) == s.value)
            {
                return s.str;
            }
        }

        return "<unknown>";
    }
}

/* /////////////////////////////////////////////////////////////////////////////
 * Enumerations
 */

/** Flags that moderate the creation of Databases */
public enum ORJ_FLAG
{
    ORDER_FIELDS                    =   0x0001,  /// Arranges the fields in alphabetical order
    ELIDE_BLANK_RECORDS             =   0x0002,  /// Causes blank records to be ignored
}

/**
 *
 */
public char[] toString(ORJ_FLAG f)
{
    const EnumString    strings[] = 
    [
            {   ORJ_FLAG.ORDER_FIELDS,           "Arranges the fields in alphabetical order" }
        ,   {   ORJ_FLAG.ELIDE_BLANK_RECORDS,    "Causes blank records to be ignored"        }
    ];

    return enum_to_string!(ORJ_FLAG)(strings, f);
}

/** General error codes */
public enum ORJRC
{
    SUCCESS                      =   0,          /// Operation was successful
    CANNOT_OPEN_JAR_FILE,                        /// The given file does not exist, or cannot be accessed
    NO_RECORDS,                                  /// The database file contained no records
    OUT_OF_MEMORY,                               /// The API suffered memory exhaustion
    BAD_FILE_READ,                               /// A read operation failed
    PARSE_ERROR,                                 /// Parsing of the database file failed due to a syntax error
    INVALID_INDEX,                               /// An invalid index was specified
    UNEXPECTED,                                  /// An unexpected condition was encountered
    INVALID_CONTENT,                             /// The database file contained invalid content
}

/**
 *
 */
public char[] toString(ORJRC f)
{
    const EnumString    strings[] = 
    [
            {   ORJRC.SUCCESS,              "Operation was successful"                                      }
        ,   {   ORJRC.CANNOT_OPEN_JAR_FILE, "The given file does not exist, or cannot be accessed"          }
        ,   {   ORJRC.NO_RECORDS,           "The database file contained no records"                        }
        ,   {   ORJRC.OUT_OF_MEMORY,        "The API suffered memory exhaustion"                            }
        ,   {   ORJRC.BAD_FILE_READ,        "A read operation failed"                                       }
        ,   {   ORJRC.PARSE_ERROR,          "Parsing of the database file failed due to a syntax error"     }
        ,   {   ORJRC.INVALID_INDEX,        "An invalid index was specified"                                }
        ,   {   ORJRC.UNEXPECTED,           "An unexpected condition was encountered"                       }   
        ,   {   ORJRC.INVALID_CONTENT,      "The database file contained invalid content"                   }       
    ];

    return enum_to_string!(ORJRC)(strings, f);
}

/** Parsing error codes */
public enum ORJ_PARSE_ERROR
{
    SUCCESS                         =   0,       /// Parsing was successful
    RECORD_SEPARATOR_IN_CONTINUATION,            /// A record separator was encountered during a content line continuation
    UNFINISHED_LINE,                             /// The last line in the database was not terminated by a line-feed
    UNFINISHED_FIELD,                            /// The last field in the database file was not terminated by a record separator
    UNFINISHED_RECORD,                           /// The last record in the database file was not terminated by a record separator
}

/**
 *
 */
public char[] toString(ORJ_PARSE_ERROR f)
{
    const EnumString    strings[] = 
    [
            {   ORJ_PARSE_ERROR.SUCCESS,                            "Parsing was successful"                                                        }
        ,   {   ORJ_PARSE_ERROR.RECORD_SEPARATOR_IN_CONTINUATION,   "A record separator was encountered during a content line continuation"         }
        ,   {   ORJ_PARSE_ERROR.UNFINISHED_LINE,                    "The last line in the database was not terminated by a line-feed"               }
        ,   {   ORJ_PARSE_ERROR.UNFINISHED_FIELD,                   "The last field in the database file was not terminated by a record separator"  }
        ,   {   ORJ_PARSE_ERROR.UNFINISHED_RECORD,                  "The last record in the database file was not terminated by a record separator" }
    ];

    return enum_to_string!(ORJ_PARSE_ERROR)(strings, f);
}

/* /////////////////////////////////////////////////////////////////////////////
 * Classes
 */

/**
 *
 */
class OpenRJException
    : public Exception
{
/* \name Construction */

protected:
    this(char[] message)
    {
        super(message);
    }

}

/**
 *
 */
class DatabaseException
    : public OpenRJException
{
/* \name Construction */
private:
    this(char[] details, ORJRC rc)
    {
//printf("DatabaseException(0: %.*s, %.*s)\n", details, std.openrj.toString(rc));

        char[]  message    =   std.string.format(   "Database creation failed; error: %s, %s"
                                                ,   cast(int)rc
                                                ,   std.openrj.toString(rc));

        m_rc        =   rc;
        m_pe        =   ORJ_PARSE_ERROR.SUCCESS;
        m_lineNum   =   -1;

        super(message);
    }

    this(ORJRC rc, int lineNum)
    {
//printf("DatabaseException(1: %.*s, %d)\n", std.openrj.toString(rc), lineNum);

        char[]  message    =   std.string.format(   "Database creation failed, at line %s; error: %s, %s"
                                                ,   lineNum
                                                ,   cast(int)rc
                                                ,   std.openrj.toString(rc));

        m_rc        =   rc;
        m_pe        =   ORJ_PARSE_ERROR.SUCCESS;
        m_lineNum   =   lineNum;

        super(message);
    }

    this(ORJ_PARSE_ERROR pe, int lineNum)
    {
//printf("DatabaseException(2: %.*s, %d)\n", std.openrj.toString(pe), lineNum);

        char[]  message    =   std.string.format(   "Parsing error in database, at line %s; parse error: %s, %s"
                                                ,   lineNum
                                                ,   cast(int)pe
                                                ,   std.openrj.toString(pe));

        m_rc        =   ORJRC.PARSE_ERROR;
        m_pe        =   pe;
        m_lineNum   =   lineNum;

        super(message);
    }

    this(char[] details, ORJ_PARSE_ERROR pe, int lineNum)
    {
//printf("DatabaseException(3: %.*s, %.*s, %d)\n", details, std.openrj.toString(rc), lineNum);

        char[]  message    =   std.string.format(   "Parsing error in database, at line %s; parse error: %s, %s; %s"
                                                ,   lineNum
                                                ,   cast(int)pe
                                                ,   std.openrj.toString(pe)
                                                ,   details);

        m_rc        =   ORJRC.PARSE_ERROR;
        m_pe        =   pe;
        m_lineNum   =   lineNum;

        super(message);
    }

/* \name Attributes */
public:

    /**
     *
     */
    ORJRC rc()
    {
        return m_rc;
    }

    /**
     *
     */
    ORJ_PARSE_ERROR parseError()
    {
        return m_pe;
    }

    /**
     *
     */
    int lineNum()
    {
        return m_lineNum;
    }

// Members
private:
    int             m_lineNum;
    ORJRC           m_rc;
    ORJ_PARSE_ERROR m_pe;
}

/**
 *
 */
class InvalidKeyException
    : public OpenRJException
{
/* \name Construction */
private:
    this(char[] message)
    {
        super(message);
    }
}

/**
 *
 */
class InvalidTypeException
    : public OpenRJException
{
/* \name Construction */
private:
    this(char[] message)
    {
        super(message);
    }
}

/* /////////////////////////////////////////////////////////////////////////////
 * Classes
 */

/// Represents a field in the database
class Field
{
/* \name Construction */

private:
    this(char[] name, char[] value/* , Record record */)
    in
    {
        assert(null !is name);
        assert(null !is value);
    }
    body
    {
        m_name      =   name;
        m_value     =   value;
        /* m_record =   record; */
    }


/* \name Attributes */

public:

    /**
     *
     */
    final char[]  name()
    {
        return m_name;
    }

    /**
     *
     */
    final char[]  value()
    {
        return m_value;
    }

    /**
     *
     */
    Record record()
    {
        return m_record;
    }


/* \name Comparison */

/+
public:
    int opCmp(Object rhs)
    {
        Field   f   =   cast(Field)(rhs);

        if(null is f)
        {
            throw new InvalidTypeException("Attempt to compare a Field with an instance of another type");
        }

        return opCmp(f);
    }
public:
    int opCmp(Field rhs)
    {
        int res;

        if(this is rhs)
        {
            res = 0;
        }
        else
        {
            res = std.string.cmp(m_name, rhs.m_name);

            if(0 == res)
            {
                res = std.string.cmp(m_value, rhs.m_value);
            }
        }

        return res;
    }
+/


// Members
private:
    char[]  m_name;
    char[]  m_value;
    Record  m_record;
}

/// Represents a record in the database, consisting of a set of fields
class Record
{
/* \name Types */

public:
    alias object.size_t     size_type;
    alias object.size_t     index_type;
    alias object.ptrdiff_t  difference_type;


/* \name Construction */

private:
    this(Field[] fields, uint flags, Database database)
    {
        m_fields = fields.dup;

        if(flags & ORJ_FLAG.ORDER_FIELDS)
        {
            m_fields = m_fields.sort;
        }

        foreach(Field field; m_fields)
        {
            if(!(field.name in m_values))
            {
                m_values[field.name] = field;
            }
        }

        m_database = database;
    }


/* \name Attributes */

public:

    /**
     *
     */
    uint numFields()
    {
        return m_fields.length;
    }

    /**
     *
     */
    uint length()
    {
        return numFields();
    }

    /**
     *
     */
    Field[] fields()
    {
        return m_fields.dup;
    }

    /**
     *
     */
    Field opIndex(index_type index)
    in
    {
        assert(index < m_fields.length);
    }
    body
    {
        return m_fields[index];
    }

    /**
     *
     */
    char[] opIndex(char[] fieldName)
    {
        return getField(fieldName).value;
    }

    /**
     *
     */
    Field   getField(char[] fieldName)
    in
    {
        assert(null !is fieldName);
    }
    body
    {
        Field   field   =   findField(fieldName);

        if(null is field)
        {
            throw new InvalidKeyException("field not found");
        }

        return field;
    }

    /**
     *
     */
    Field   findField(char[] fieldName)
    in
    {
        assert(null !is fieldName);
    }
    body
    {
        Field   *pfield =   (fieldName in m_values);

        return (null is pfield) ? null : *pfield;
    }

    /**
     *
     */
    int hasField(char[] fieldName)
    {
        return null !is findField(fieldName);
    }

    /**
     *
     */
    Database database()
    {
        return m_database;
    }


/* \name Enumeration */

public:

    /**
     *
     */
    int opApply(int delegate(inout Field field) dg)
    {
        int result  =   0;

        foreach(Field field; m_fields)
        {
            result = dg(field);

            if(0 != result)
            {
                break;
            }
        }

        return result;
    }

    /**
     *
     */
    int opApply(int delegate(in char[] name, in char[] value) dg)
    {
        int result  =   0;

        foreach(Field field; m_fields)
        {
            result = dg(field.name(), field.value());

            if(0 != result)
            {
                break;
            }
        }

        return result;
    }


// Members
private:
    Field[]         m_fields;
    Field[char[]]   m_values;
    Database        m_database;
}


/**
 *
 */
class Database
{
/* \name Types */

public:
    alias object.size_t     size_type;
    alias object.size_t     index_type;
    alias object.ptrdiff_t  difference_type;


/* \name Construction */

private:
    void init_(char[][] lines, uint flags)
    {
        // Enumerate
        int         bContinuing =   false;
        Field[]     fields;
        char[]      nextLine;
        int         lineNum     =   1;
        int         nextLineNum =   1;

        foreach(char[] line; lines)
        {
            // Always strip trailing space
            line = stripr(line);

            // Check that we don't start a continued line with a record separator
            if( bContinuing &&
                line.length > 1 &&
                "%%" == line[0 .. 2])
            {
                throw new DatabaseException(ORJ_PARSE_ERROR.RECORD_SEPARATOR_IN_CONTINUATION, lineNum);
            }

            // Always strip leading whitespace
            line = stripl(line);

            int bContinuationLine;

            if( line.length > 0 &&
                '\\' == line[line.length - 1])
            {
                bContinuationLine   =   true;
                bContinuing         =   true;
                line                =   line[0 .. line.length - 1];
            }

            // Always add on to the previous line
            nextLine = nextLine ~ line;

            line = null;

            if(!bContinuationLine)
            {
                if(0 == nextLine.length)
                {
                    // Just ignore these lines
                }
                else if(1 == nextLine.length)
                {
                    throw new DatabaseException(ORJ_PARSE_ERROR.UNFINISHED_FIELD, lineNum);
                }
                else
                {
                    if("%%" == nextLine[0 .. 2])
                    {
                        // Comment line - terminate the record
//                      printf("-- record --\n");

                        if( 0 != fields.length ||
                            0 == (ORJ_FLAG.ELIDE_BLANK_RECORDS & flags))
                        {
                            Record  record  =   new Record(fields, flags, this);

                            foreach(Field field; fields)
                            {
                                field.m_record = record;
                            }

                            m_records   ~=  record;
                            fields      =   null;
                        }
                    }
                    else
                    {
                        int colon   =   find(nextLine, ':');

                        if(-1 == colon)
                        {
                            throw new DatabaseException(ORJ_PARSE_ERROR.UNFINISHED_FIELD, lineNum);
                        }

//                      printf("%.*s(%d): %.*s (%d)\n", file, nextLineNum, nextLine, colon);

                        char[]  name    =   nextLine[0 .. colon];
                        char[]  value   =   nextLine[colon + 1 .. nextLine.length];

                        name    =   stripr(name);
                        value   =   stripl(value);

//                      printf("%.*s(%d): %.*s=%.*s\n", file, nextLineNum, name, value);

                        Field   field   =   new Field(name, value);

                        fields      ~=  field;
                        m_fields    ~=  field;
                    }
                }

                nextLine    =   "";
                nextLineNum =   lineNum + 1;
                bContinuing =   false;
            }

/+ // This is currently commented out as it seems unlikely to be sensible to 
   // order the Fields globally. The reasoning is that if the Fields are used
   // globally then it's more likely that their ordering in the database source
   // is meaningful. If someone really needs an all-Fields array ordered, they
   // can do it manually.
            if(flags & ORJ_FLAG.ORDER_FIELDS)
            {
                m_fields = m_fields.sort;
            }
+/

            ++lineNum;
        }
        if(bContinuing)
        {
            throw new DatabaseException(ORJ_PARSE_ERROR.UNFINISHED_LINE, lineNum);
        }
        if(fields.length > 0)
        {
            throw new DatabaseException(ORJ_PARSE_ERROR.UNFINISHED_RECORD, lineNum);
        }
        if(0 == m_records.length)
        {
            throw new DatabaseException(ORJRC.NO_RECORDS, lineNum);
        }

        m_flags     =   flags;
        m_numLines  =   lines.length;
    }
public:

    /**
     *
     */
    this(char[] memory, uint flags)
    {
        char[][]    lines = split(memory, "\n");

        init_(lines, flags);
    }

    /**
     *
     */
    this(char[][] lines, uint flags)
    {
        init_(lines, flags);
    }


/* \name Attributes */

public:

    /**
     *
     */
    size_type   numRecords()
    {
        return m_records.length;
    }

    /**
     *
     */
    size_type   numFields()
    {
        return m_fields.length;
    }

    /**
     *
     */
    size_type   numLines()
    {
        return m_numLines;
    }


/* \name Attributes */

public:

    /**
     *
     */
    uint flags()
    {
        return m_flags;
    }

    /**
     *
     */
    Record[] records()
    {
        return m_records.dup;
    }

    /**
     *
     */
    Field[] fields()
    {
        return m_fields.dup;
    }

    /**
     *
     */
    uint length()
    {
        return numRecords();
    }

    /**
     *
     */
    Record  opIndex(index_type index)
    in
    {
        assert(index < m_records.length);
    }
    body
    {
        return m_records[index];
    }


/* \name Searching */

public:

    /**
     *
     */
    Record[]    getRecordsContainingField(char[] fieldName)
    {
        Record[]    records;

        foreach(Record record; m_records)
        {
            if(null !is record.findField(fieldName))
            {
                records ~= record;
            }
        }

        return records;
    }

    /**
     *
     */
    Record[]    getRecordsContainingField(char[] fieldName, char[] fieldValue)
    {
        Record[]    records;
        uint        flags   =   flags;

        foreach(Record record; m_records)
        {
            Field   field   =   record.findField(fieldName);

            if(null !is field)
            {
                // Since there can be more than one field with the same name in
                // the same record, we need to search all fields in this record
                if(ORJ_FLAG.ORDER_FIELDS == (flags & ORJ_FLAG.ORDER_FIELDS))
                {
                    // We can do a sorted search
                    foreach(Field field; record)
                    {
                        int res =   cmp(field.name, fieldName);

                        if( 0 == res &&
                            (   null is fieldValue ||
                                field.value == fieldValue))
                        {
                            records ~= record;

                            break;
                        }
                        else if(res > 0)
                        {
                            break;
                        }
                    }
                }
                else
                {
                    foreach(Field field; record)
                    {
                        if( field.name == fieldName &&
                            (   null is fieldValue ||
                                field.value == fieldValue))
                        {
                            records ~= record;

                            break;
                        }
                    }
                }
            }
        }

        return records;
    }


/* \name Enumeration */

public:

    /**
     *
     */
    int opApply(int delegate(inout Record record) dg)
    {
        int result  =   0;

        foreach(Record record; m_records)
        {
            result = dg(record);

            if(0 != result)
            {
                break;
            }
        };

        return result;
    }

    /**
     *
     */
    int opApply(int delegate(inout Field field) dg)
    {
        int result  =   0;

        foreach(Field field; m_fields)
        {
            result = dg(field);

            if(0 != result)
            {
                break;
            }
        };

        return result;
    }


// Members
private:
    uint        m_flags;
    size_type   m_numLines;
    Record[]    m_records;
    Field[]     m_fields;
}

/* ////////////////////////////////////////////////////////////////////////// */

version(MainTest)
{

    int main(char[][] args)
    {
        int flags   =   0
                    |   ORJ_FLAG.ORDER_FIELDS
                    |   ORJ_FLAG.ELIDE_BLANK_RECORDS
                    |   0;

        if(args.length < 2)
        {
            printf("Need to specify jar file\n");
        }
        else
        {
            PerformanceCounter  counter =   new PerformanceCounter();

            try
            {
                printf( "std.openrj test:\n\tmodule:      \t%.*s\n\tdescription: \t%.*s\n\tversion:     \t%d.%d.%d.%d\n"
                    ,   cast(int) std.openrj.VERSION.name.length
                    ,   std.openrj.VERSION.name.ptr
                    ,   std.openrj.VERSION.description
                    ,   std.openrj.VERSION.major
                    ,   std.openrj.VERSION.minor
                    ,   std.openrj.VERSION.revision
                    ,   std.openrj.VERSION.edit);

                counter.start();

                char[]      file        =   args[1];
                char[]      chars       =   cast(char[])std.file.read(file);
                Database    database    =   new Database(chars, flags);
//                Database    database    =   new Database(split(chars, "\n"), flags);

                counter.stop();

                PerformanceCounter.interval_type    loadTime    =   counter.microseconds();

                counter.start();

                int i   =   0;
                foreach(Record record; database.records)
                {
                    foreach(Field field; record)
                    {
                        i += field.name.length + field.value.length;
                    }
                }

                counter.stop();

                PerformanceCounter.interval_type    enumerateTime   =   counter.microseconds();

                printf("Open-RJ/D test: 100%%-D!!\n");
                printf("Load time:       %ld\n", loadTime);
                printf("Enumerate time:  %ld\n", enumerateTime);

                return 0;

                printf("Records (%u)\n", database.numRecords);
                foreach(Record record; database)
                {
                    printf("  Record\n");
                    foreach(Field field; record.fields)
                    {
                        printf("    Field: %.*s=%.*s\n",
			    cast(int) field.name.length, field.name.ptr,
			    cast(int) field.value.length, field.value.ptr);
                    }
                }

                printf("Fields (%u)\n", database.numFields);
                foreach(Field field; database)
                {
                        printf("    Field: %.*s=%.*s\n",
			    cast(int) field.name.length, field.name.ptr,
			    cast(int) field.value.length, field.value.ptr);
                }

                Record[]    records =   database.getRecordsContainingField("Name");
                printf("Records containing 'Name' (%u)\n", records);
                foreach(Record record; records)
                {
                    printf("  Record\n");
                    foreach(Field field; record.fields)
                    {
                        printf("    Field: %.*s=%.*s\n",
			    cast(int) field.name.length, field.name.ptr,
			    cast(int) field.value.length, field.value.ptr);
                    }
                }
            }
            catch(Exception x)
            {
                char[] s = x.toString();
                printf("Exception: %.*s\n", cast(int) s.length, s.ptr);
            }
        }

        return 0;
    }

} // version(MainTest)

/* ////////////////////////////////////////////////////////////////////////// */
