
// Written in the D programming language.

/**
 * Templates with which to do compile time manipulation of strings.
 *
 * Macros:
 *	WIKI = Phobos/StdMetastrings
 * Copyright:
 *	Public Domain
 */

/*
 * Authors:
 *	Walter Bright, Digital Mars, www.digitalmars.com
 *	Don Clugston
 */

module std.metastrings;

/**
 * Formats constants into a string at compile time.
 * Analogous to std.string.format().
 * Parameters:
 *	A =	tuple of constants, which can be strings,
 *		characters, or integral values.
 * Formats:
 *	The formats supported are %s for strings, and %%
 *	for the % character.
 * Example:
 * ---
import std.metastrings;
import std.stdio;

void main()
{
  string s = Format!("Arg %s = %s", "foo", 27);
  writefln(s); // "Arg foo = 27"
}
 * ---
 */

template Format(A...)
{
    static if (A.length == 0)
	const char[] Format = "";
    else static if (is(typeof(A[0]) : char[]))
	const char[] Format = FormatString!(A[0], A[1..$]);
	//const char[] Format = FormatString!(A[0]);
    else
	const char[] Format = ToString!(A[0]) ~ Format!(A[1..$]);
}

template FormatString(string F, A...)
{
    static if (F.length == 0)
	const char[] FormatString = Format!(A);
    else static if (F.length == 1)
	const char[] FormatString = F[0] ~ Format!(A);
    else static if (F[0..2] == "%s")
	const char[] FormatString = ToString!(A[0]) ~ FormatString!(F[2..$],A[1..$]);
    else static if (F[0..2] == "%%")
	const char[] FormatString = "%" ~ FormatString!(F[2..$],A);
    else static if (F[0] == '%')
	static assert(0, "unrecognized format %" ~ F[1]);
    else
	const char[] FormatString = F[0] ~ FormatString!(F[1..$],A);
}

/**
 * Convert constant argument to a string.
 */

template ToString(ulong U)
{
    static if (U < 10)
	const char[] ToString = "" ~ cast(char)(U + '0');
    else
	const char[] ToString = ToString!(U / 10) ~ ToString!(U % 10);
}

/// ditto
template ToString(long I)
{
    static if (I < 0)
	const char[] ToString = "-" ~ ToString!(cast(ulong)(-I));
    else
	const char[] ToString = ToString!(cast(ulong)I);
}

static assert(ToString!(0x100000000) == "4294967296");

/// ditto
template ToString(uint U)
{
    const char[] ToString = ToString!(cast(ulong)U);
}

/// ditto
template ToString(int I)
{
    const char[] ToString = ToString!(cast(long)I);
}

/// ditto
template ToString(ushort U)
{
    const char[] ToString = ToString!(cast(ulong)U);
}

/// ditto
template ToString(short I)
{
    const char[] ToString = ToString!(cast(long)I);
}

/// ditto
template ToString(ubyte U)
{
    const char[] ToString = ToString!(cast(ulong)U);
}

/// ditto
template ToString(byte I)
{
    const char[] ToString = ToString!(cast(long)I);
}

/// ditto
template ToString(bool B)
{
    const char[] ToString = B ? "true" : "false";
}

/// ditto
template ToString(string S)
{
    const char[] ToString = S;
}

/// ditto
template ToString(char C)
{
    const char[] ToString = "" ~ C;
}

unittest
{
    string s = Format!("hel%slo", "world", -138, 'c', true);
    assert(s == "helworldlo-138ctrue");
}


/********
 * Parse unsigned integer literal from the start of string s.
 * returns:
 *	.value = the integer literal as a string,
 *	.rest = the string following the integer literal
 * Otherwise:
 *	.value = null,
 *	.rest = s
 */

template ParseUinteger(string s)
{
    static if (s.length == 0)
    {	const char[] value = "";
	const char[] rest = "";
    }
    else static if (s[0] >= '0' && s[0] <= '9')
    {	const char[] value = s[0] ~ ParseUinteger!(s[1..$]).value;
	const char[] rest = ParseUinteger!(s[1..$]).rest;
    }
    else
    {	const char[] value = "";
	const char[] rest = s;
    }
}

/********
 * Parse integer literal optionally preceded by '-'
 * from the start of string s.
 * returns:
 *	.value = the integer literal as a string,
 *	.rest = the string following the integer literal
 * Otherwise:
 *	.value = null,
 *	.rest = s
 */

template ParseInteger(string s)
{
    static if (s.length == 0)
    {	const char[] value = "";
	const char[] rest = "";
    }
    else static if (s[0] >= '0' && s[0] <= '9')
    {	const char[] value = s[0] ~ ParseUinteger!(s[1..$]).value;
	const char[] rest = ParseUinteger!(s[1..$]).rest;
    }
    else static if (s.length >= 2 &&
		s[0] == '-' && s[1] >= '0' && s[1] <= '9')
    {	const char[] value = s[0..2] ~ ParseUinteger!(s[2..$]).value;
	const char[] rest = ParseUinteger!(s[2..$]).rest;
    }
    else
    {	const char[] value = "";
	const char[] rest = s;
    }
}

unittest
{
    assert(ParseUinteger!("1234abc").value == "1234");
    assert(ParseUinteger!("1234abc").rest == "abc");
    assert(ParseInteger!("-1234abc").value == "-1234");
    assert(ParseInteger!("-1234abc").rest == "abc");
}

