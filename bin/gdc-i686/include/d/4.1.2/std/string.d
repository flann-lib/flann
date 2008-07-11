
// Written in the D programming language.

/**
 * String handling functions.
 *
 * To copy or not to copy?
 * When a function takes a string as a parameter, and returns a string,
 * is that string the same as the input string, modified in place, or
 * is it a modified copy of the input string? The D array convention is
 * "copy-on-write". This means that if no modifications are done, the
 * original string (or slices of it) can be returned. If any modifications
 * are done, the returned string is a copy.
 *
 * Macros:
 *	WIKI = Phobos/StdString
 * Copyright:
 *	Public Domain
 */

/* Author:
 *	Walter Bright, Digital Mars, www.digitalmars.com
 */

// The code is not optimized for speed, that will have to wait
// until the design is solidified.

/* NOTE: This file has been patched from the original DMD distribution to
   work with the GDC compiler.

   Modified by David Friedman, September 2004
*/

module std.string;

//debug=string;		// uncomment to turn on debugging printf's

private import std.stdio;
private import std.c.stdio;
private import std.c.stdlib;
private import std.c.string;
private import std.utf;
private import std.uni;
private import std.array;
private import std.format;
private import std.ctype;
private import std.stdarg;

extern (C)
{
    size_t wcslen(wchar *);
    int wcscmp(wchar *, wchar *);
}

/* ************* Exceptions *************** */

/// Thrown on errors in string functions.
class StringException : Exception
{
    this(char[] msg)	/// Constructor
    {
	super(msg);
    }
}

/* ************* Constants *************** */

const char[16] hexdigits = "0123456789ABCDEF";			/// 0..9A..F
const char[10] digits    = "0123456789";			/// 0..9
const char[8]  octdigits = "01234567";				/// 0..7
const char[26] lowercase = "abcdefghijklmnopqrstuvwxyz";	/// a..z
const char[26] uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";	/// A..Z
const char[52] letters   = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
			   "abcdefghijklmnopqrstuvwxyz";	/// A..Za..z
const char[6] whitespace = " \t\v\r\n\f";			/// ASCII whitespace

const dchar LS = '\u2028';	/// UTF line separator
const dchar PS = '\u2029';	/// UTF paragraph separator

/// Newline sequence for this system
version (Windows)
    const char[2] newline = "\r\n";
else version (Unix)
    const char[1] newline = "\n";

/**********************************
 * Returns true if c is whitespace
 */

bool iswhite(dchar c)
{
    return (c <= 0x7F)
		? find(whitespace, c) != -1
		: (c == PS || c == LS);
}

/*********************************
 * Convert string to integer.
 */

long atoi(char[] s)
{
    return std.c.stdlib.atoi(toStringz(s));
}

/*************************************
 * Convert string to real.
 */

real atof(char[] s)
{   char* endptr;

    auto result = strtold(toStringz(s), &endptr);
    return result;
}

/**********************************
 * Compare two strings. cmp is case sensitive, icmp is case insensitive.
 * Returns:
 *	<table border=1 cellpadding=4 cellspacing=0>
 *	$(TR $(TD < 0)	$(TD s1 < s2))
 *	$(TR $(TD = 0)	$(TD s1 == s2))
 *	$(TR $(TD > 0)	$(TD s1 > s2))
 *	</table>
 */

int cmp(char[] s1, char[] s2)
{
    auto len = s1.length;
    int result;

    //printf("cmp('%.*s', '%.*s')\n", s1, s2);
    if (s2.length < len)
	len = s2.length;
    result = memcmp(s1.ptr, s2.ptr, len);
    if (result == 0)
	result = cast(int)s1.length - cast(int)s2.length;
    return result;
}

/*********************************
 * ditto
 */

int icmp(char[] s1, char[] s2)
{
    auto len = s1.length;
    int result;

    if (s2.length < len)
	len = s2.length;
    version (Win32)
    {
	result = memicmp(s1.ptr, s2.ptr, len);
    }
    version (Unix)
    {
	for (size_t i = 0; i < len; i++)
	{
	    if (s1[i] != s2[i])
	    {
		char c1 = s1[i];
		char c2 = s2[i];

		if (c1 >= 'A' && c1 <= 'Z')
		    c1 += cast(int)'a' - cast(int)'A';
		if (c2 >= 'A' && c2 <= 'Z')
		    c2 += cast(int)'a' - cast(int)'A';
		result = cast(int)c1 - cast(int)c2;
		if (result)
		    break;
	    }
	}
    }
    if (result == 0)
	result = cast(int)s1.length - cast(int)s2.length;
    return result;
}

unittest
{
    int result;

    debug(string) printf("string.cmp.unittest\n");
    result = icmp("abc", "abc");
    assert(result == 0);
    result = icmp(null, null);
    assert(result == 0);
    result = icmp("", "");
    assert(result == 0);
    result = icmp("abc", "abcd");
    assert(result < 0);
    result = icmp("abcd", "abc");
    assert(result > 0);
    result = icmp("abc", "abd");
    assert(result < 0);
    result = icmp("bbc", "abc");
    assert(result > 0);
}

/* ********************************
 * Converts a D array of chars to a C-style 0 terminated string.
 * Deprecated: replaced with toStringz().
 */

deprecated char* toCharz(char[] s)
{
    return toStringz(s);
}

/*********************************
 * Convert array of chars s[] to a C-style 0 terminated string.
 */

char* toStringz(char[] s)
    in
    {
    }
    out (result)
    {
	if (result)
	{   assert(strlen(result) == s.length);
	    assert(memcmp(result, s.ptr, s.length) == 0);
	}
    }
    body
    {
	char[] copy;

	if (s.length == 0)
	    return "";

	/+ Unfortunately, this isn't reliable.
	   We could make this work if string literals are put
	   in read-only memory and we test if s[] is pointing into
	   that.

	    /* Peek past end of s[], if it's 0, no conversion necessary.
	     * Note that the compiler will put a 0 past the end of static
	     * strings, and the storage allocator will put a 0 past the end
	     * of newly allocated char[]'s.
	     */
	    char* p = &s[0] + s.length;
	    if (*p == 0)
		return s;
	+/

	// Need to make a copy
	copy = new char[s.length + 1];
	copy[0..s.length] = s;
	copy[s.length] = 0;
	return copy.ptr;
    }

unittest
{
    debug(string) printf("string.toStringz.unittest\n");

    char* p = toStringz("foo");
    assert(strlen(p) == 3);
    char foo[] = "abbzxyzzy";
    p = toStringz(foo[3..5]);
    assert(strlen(p) == 2);

    char[] test = "";
    p = toStringz(test);
    assert(*p == 0);
}

/******************************************
 * find, ifind _find first occurrence of c in string s.
 * rfind, irfind _find last occurrence of c in string s.
 *
 * find, rfind are case sensitive; ifind, irfind are case insensitive.
 * Returns:
 *	Index in s where c is found, -1 if not found.
 */

ptrdiff_t find(char[] s, dchar c)
{
    if (c <= 0x7F)
    {	// Plain old ASCII
	auto p = cast(char*)memchr(s.ptr, c, s.length);
	if (p)
	    return p - cast(char *)s;
	else
	    return -1;
    }

    // c is a universal character
    foreach (ptrdiff_t i, dchar c2; s)
    {
	if (c == c2)
	    return i;
    }
    return -1;
}

unittest
{
    debug(string) printf("string.find.unittest\n");

    int i;

    i = find(null, cast(dchar)'a');
    assert(i == -1);
    i = find("def", cast(dchar)'a');
    assert(i == -1);
    i = find("abba", cast(dchar)'a');
    assert(i == 0);
    i = find("def", cast(dchar)'f');
    assert(i == 2);
}


/******************************************
 * ditto
 */

ptrdiff_t ifind(char[] s, dchar c)
{
    char* p;

    if (c <= 0x7F)
    {	// Plain old ASCII
	char c1 = cast(char) std.ctype.tolower(c);

	foreach (ptrdiff_t i, char c2; s)
	{
	    c2 = cast(char)std.ctype.tolower(c2);
	    if (c1 == c2)
		return i;
	}
    }
    else
    {	// c is a universal character
	dchar c1 = std.uni.toUniLower(c);

	foreach (ptrdiff_t i, dchar c2; s)
	{
	    c2 = std.uni.toUniLower(c2);
	    if (c1 == c2)
		return i;
	}
    }
    return -1;
}

unittest
{
    debug(string) printf("string.ifind.unittest\n");

    int i;

    i = ifind(null, cast(dchar)'a');
    assert(i == -1);
    i = ifind("def", cast(dchar)'a');
    assert(i == -1);
    i = ifind("Abba", cast(dchar)'a');
    assert(i == 0);
    i = ifind("def", cast(dchar)'F');
    assert(i == 2);

    char[] sPlts = "Mars: the fourth Rock (Planet) from the Sun.";

    i = ifind("def", cast(char)'f');
    assert(i == 2);

    i = ifind(sPlts, cast(char)'P');
    assert(i == 23);
    i = ifind(sPlts, cast(char)'R');
    assert(i == 2);
}


/******************************************
 * ditto
 */

ptrdiff_t rfind(char[] s, dchar c)
{
    size_t i;

    if (c <= 0x7F)
    {	// Plain old ASCII
	for (i = s.length; i-- != 0;)
	{
	    if (s[i] == c)
		break;
	}
	return i;
    }

    // c is a universal character
    char[4] buf;
    char[] t;
    t = std.utf.toUTF8(buf, c);
    return rfind(s, t);
}

unittest
{
    debug(string) printf("string.rfind.unittest\n");

    int i;

    i = rfind(null, cast(dchar)'a');
    assert(i == -1);
    i = rfind("def", cast(dchar)'a');
    assert(i == -1);
    i = rfind("abba", cast(dchar)'a');
    assert(i == 3);
    i = rfind("def", cast(dchar)'f');
    assert(i == 2);
}

/******************************************
 * ditto
 */

ptrdiff_t irfind(char[] s, dchar c)
{
    size_t i;

    if (c <= 0x7F)
    {	// Plain old ASCII
	char c1 = cast(char) std.ctype.tolower(c);

	for (i = s.length; i-- != 0;)
	{   char c2 = s[i];

	    c2 = cast(char) std.ctype.tolower(c2);
	    if (c1 == c2)
		break;
	}
    }
    else
    {	// c is a universal character
	dchar c1 = std.uni.toUniLower(c);

	for (i = s.length; i-- != 0;)
	{   char cx = s[i];

	    if (cx <= 0x7F)
		continue;		// skip, since c is not ASCII
	    if ((cx & 0xC0) == 0x80)
		continue;		// skip non-starting UTF-8 chars

	    size_t j = i;
	    dchar c2 = std.utf.decode(s, j);
	    c2 = std.uni.toUniLower(c2);
	    if (c1 == c2)
		break;
	}
    }
    return i;
}

unittest
{
    debug(string) printf("string.irfind.unittest\n");

    int i;

    i = irfind(null, cast(dchar)'a');
    assert(i == -1);
    i = irfind("def", cast(dchar)'a');
    assert(i == -1);
    i = irfind("AbbA", cast(dchar)'a');
    assert(i == 3);
    i = irfind("def", cast(dchar)'F');
    assert(i == 2);

    char[] sPlts = "Mars: the fourth Rock (Planet) from the Sun.";

    i = irfind("def", cast(char)'f');
    assert(i == 2);

    i = irfind(sPlts, cast(char)'M');
    assert(i == 34);
    i = irfind(sPlts, cast(char)'S');
    assert(i == 40);
}


/******************************************
 * find, ifind _find first occurrence of sub[] in string s[].
 * rfind, irfind _find last occurrence of sub[] in string s[].
 *
 * find, rfind are case sensitive; ifind, irfind are case insensitive.
 * Returns:
 *	Index in s where c is found, -1 if not found.
 */

ptrdiff_t find(char[] s, char[] sub)
    out (result)
    {
	if (result == -1)
	{
	}
	else
	{
	    assert(0 <= result && result < s.length - sub.length + 1);
	    assert(memcmp(&s[result], sub.ptr, sub.length) == 0);
	}
    }
    body
    {
	auto sublength = sub.length;

	if (sublength == 0)
	    return 0;

	if (s.length >= sublength)
	{
	    auto c = sub[0];
	    if (sublength == 1)
	    {
		auto p = cast(char*)memchr(s.ptr, c, s.length);
		if (p)
		    return p - &s[0];
	    }
	    else
	    {
		size_t imax = s.length - sublength + 1;

		// Remainder of sub[]
		char *q = &sub[1];
		sublength--;

		for (size_t i = 0; i < imax; i++)
		{
		    char *p = cast(char*)memchr(&s[i], c, imax - i);
		    if (!p)
			break;
		    i = p - &s[0];
		    if (memcmp(p + 1, q, sublength) == 0)
			return i;
		}
	    }
	}
	return -1;
    }


unittest
{
    debug(string) printf("string.find.unittest\n");

    int i;

    i = find(null, "a");
    assert(i == -1);
    i = find("def", "a");
    assert(i == -1);
    i = find("abba", "a");
    assert(i == 0);
    i = find("def", "f");
    assert(i == 2);
    i = find("dfefffg", "fff");
    assert(i == 3);
    i = find("dfeffgfff", "fff");
    assert(i == 6);
}

/******************************************
 * ditto
 */

ptrdiff_t ifind(char[] s, char[] sub)
    out (result)
    {
	if (result == -1)
	{
	}
	else
	{
	    assert(0 <= result && result < s.length - sub.length + 1);
	    assert(icmp(s[result .. result + sub.length], sub) == 0);
	}
    }
    body
    {
	auto sublength = sub.length;
	ptrdiff_t i;

	if (sublength == 0)
	    return 0;

	if (s.length < sublength)
	    return -1;

	auto c = sub[0];
	if (sublength == 1)
	{
	    i = ifind(s, c);
	}
	else if (c <= 0x7F)
	{
	    size_t imax = s.length - sublength + 1;

	    // Remainder of sub[]
	    char[] subn = sub[1 .. sublength];

	    for (i = 0; i < imax; i++)
	    {
		auto j = ifind(s[i .. imax], c);
		if (j == -1)
		    return -1;
		i += j;
		if (icmp(s[i + 1 .. i + sublength], subn) == 0)
		    return i;
	    }
	    i = -1;
	}
	else
	{
	    size_t imax = s.length - sublength;

	    for (i = 0; i <= imax; i++)
	    {
		if (icmp(s[i .. i + sublength], sub) == 0)
		    return i;
	    }
	    i = -1;
	}
	return i;
    }


unittest
{
    debug(string) printf("string.ifind.unittest\n");

    int i;

    i = ifind(null, "a");
    assert(i == -1);
    i = ifind("def", "a");
    assert(i == -1);
    i = ifind("abba", "a");
    assert(i == 0);
    i = ifind("def", "f");
    assert(i == 2);
    i = ifind("dfefffg", "fff");
    assert(i == 3);
    i = ifind("dfeffgfff", "fff");
    assert(i == 6);

    char[] sPlts = "Mars: the fourth Rock (Planet) from the Sun.";
    char[] sMars = "Who\'s \'My Favorite Maritian?\'";

    i = ifind(sMars, "MY fAVe");
    assert(i == -1);
    i = ifind(sMars, "mY fAVOriTe");
    assert(i == 7);
    i = ifind(sPlts, "mArS:");
    assert(i == 0);
    i = ifind(sPlts, "rOcK");
    assert(i == 17);
    i = ifind(sPlts, "Un.");
    assert(i == 41);
    i = ifind(sPlts, sPlts);
    assert(i == 0);

    i = ifind("\u0100", "\u0100");
    assert(i == 0);

    // Thanks to Carlos Santander B. and zwang
    i = ifind("sus mejores cortesanos. Se embarcaron en el puerto de Dubai y",
	"page-break-before");
    assert(i == -1);
}

/******************************************
 * ditto
 */

ptrdiff_t rfind(char[] s, char[] sub)
    out (result)
    {
	if (result == -1)
	{
	}
	else
	{
	    assert(0 <= result && result < s.length - sub.length + 1);
	    assert(memcmp(&s[0] + result, sub.ptr, sub.length) == 0);
	}
    }
    body
    {
	char c;

	if (sub.length == 0)
	    return s.length;
	c = sub[0];
	if (sub.length == 1)
	    return rfind(s, c);
	for (ptrdiff_t i = s.length - sub.length; i >= 0; i--)
	{
	    if (s[i] == c)
	    {
		if (memcmp(&s[i + 1], &sub[1], sub.length - 1) == 0)
		    return i;
	    }
	}
	return -1;
    }

unittest
{
    int i;

    debug(string) printf("string.rfind.unittest\n");
    i = rfind("abcdefcdef", "c");
    assert(i == 6);
    i = rfind("abcdefcdef", "cd");
    assert(i == 6);
    i = rfind("abcdefcdef", "x");
    assert(i == -1);
    i = rfind("abcdefcdef", "xy");
    assert(i == -1);
    i = rfind("abcdefcdef", "");
    assert(i == 10);
}


/******************************************
 * ditto
 */

ptrdiff_t irfind(char[] s, char[] sub)
    out (result)
    {
	if (result == -1)
	{
	}
	else
	{
	    assert(0 <= result && result < s.length - sub.length + 1);
	    assert(icmp(s[result .. result + sub.length], sub) == 0);
	}
    }
    body
    {
	dchar c;

	if (sub.length == 0)
	    return s.length;
	c = sub[0];
	if (sub.length == 1)
	    return irfind(s, c);
	if (c <= 0x7F)
	{
	    c = std.ctype.tolower(c);
	    for (ptrdiff_t i = s.length - sub.length; i >= 0; i--)
	    {
		if (std.ctype.tolower(s[i]) == c)
		{
		    if (icmp(s[i + 1 .. i + sub.length], sub[1 .. sub.length]) == 0)
			return i;
		}
	    }
	}
	else
	{
	    for (ptrdiff_t i = s.length - sub.length; i >= 0; i--)
	    {
		if (icmp(s[i .. i + sub.length], sub) == 0)
		    return i;
	    }
	}
	return -1;
    }

unittest
{
    int i;

    debug(string) printf("string.irfind.unittest\n");
    i = irfind("abcdefCdef", "c");
    assert(i == 6);
    i = irfind("abcdefCdef", "cD");
    assert(i == 6);
    i = irfind("abcdefcdef", "x");
    assert(i == -1);
    i = irfind("abcdefcdef", "xy");
    assert(i == -1);
    i = irfind("abcdefcdef", "");
    assert(i == 10);

    char[] sPlts = "Mars: the fourth Rock (Planet) from the Sun.";
    char[] sMars = "Who\'s \'My Favorite Maritian?\'";
    
    i = irfind("abcdefcdef", "c");
    assert(i == 6);
    i = irfind("abcdefcdef", "cd");
    assert(i == 6);
    i = irfind( "abcdefcdef", "def" );
    assert(i == 7);
    
    i = irfind(sMars, "RiTE maR");
    assert(i == 14);
    i = irfind(sPlts, "FOuRTh");
    assert(i == 10);
    i = irfind(sMars, "whO\'s \'MY");
    assert(i == 0);
    i = irfind(sMars, sMars);
    assert(i == 0);
}


/************************************
 * Convert string s[] to lower case.
 */

string tolower(string s)
{
    int changed;
    char[] r;

    for (size_t i = 0; i < s.length; i++)
    {
	auto c = s[i];
	if ('A' <= c && c <= 'Z')
	{
	    if (!changed)
	    {
		r = s.dup;
		changed = 1;
	    }
	    r[i] = cast(char) (c + (cast(char)'a' - 'A'));
	}
	else if (c > 0x7F)
	{
	    foreach (size_t j, dchar dc; s[i .. length])
	    {
		if (std.uni.isUniUpper(dc))
		{
		    dc = std.uni.toUniLower(dc);
		    if (!changed)
		    {
			r = s[0 .. i + j].dup;
			changed = 2;
		    }
		}
		if (changed)
		{
		    if (changed == 1)
		    {	r = r[0 .. i + j];
			changed = 2;
		    }
		    std.utf.encode(r, dc);
		}
	    }
	    break;
	}
    }
    return changed ? r : s;
}

unittest
{
    debug(string) printf("string.tolower.unittest\n");

    char[] s1 = "FoL";
    char[] s2;

    s2 = tolower(s1);
    assert(cmp(s2, "fol") == 0);
    assert(s2 != s1);

    s1 = "A\u0100B\u0101d";
    s2 = tolower(s1);
    assert(cmp(s2, "a\u0101b\u0101d") == 0);
    assert(s2 !is s1);

    s1 = "A\u0460B\u0461d";
    s2 = tolower(s1);
    assert(cmp(s2, "a\u0461b\u0461d") == 0);
    assert(s2 !is s1);

    s1 = "\u0130";
    s2 = tolower(s1);
    assert(s2 == "i");
    assert(s2 !is s1);
}

/************************************
 * Convert string s[] to upper case.
 */

string toupper(string s)
{
    int changed;
    char[] r;

    for (size_t i = 0; i < s.length; i++)
    {
	auto c = s[i];
	if ('a' <= c && c <= 'z')
	{
	    if (!changed)
	    {
		r = s.dup;
		changed = 1;
	    }
	    r[i] = cast(char) (c - (cast(char)'a' - 'A'));
	}
	else if (c > 0x7F)
	{
	    foreach (size_t j, dchar dc; s[i .. length])
	    {
		if (std.uni.isUniLower(dc))
		{
		    dc = std.uni.toUniUpper(dc);
		    if (!changed)
		    {
			r = s[0 .. i + j].dup;
			changed = 2;
		    }
		}
		if (changed)
		{
		    if (changed == 1)
		    {	r = r[0 .. i + j];
			changed = 2;
		    }
		    std.utf.encode(r, dc);
		}
	    }
	    break;
	}
    }
    return changed ? r : s;
}

unittest
{
    debug(string) printf("string.toupper.unittest\n");

    char[] s1 = "FoL";
    char[] s2;

    s2 = toupper(s1);
    assert(cmp(s2, "FOL") == 0);
    assert(s2 !is s1);

    s1 = "a\u0100B\u0101d";
    s2 = toupper(s1);
    assert(cmp(s2, "A\u0100B\u0100D") == 0);
    assert(s2 !is s1);

    s1 = "a\u0460B\u0461d";
    s2 = toupper(s1);
    assert(cmp(s2, "A\u0460B\u0460D") == 0);
    assert(s2 !is s1);
}


/********************************************
 * Capitalize first character of string s[], convert rest of string s[]
 * to lower case.
 */

char[] capitalize(char[] s)
{
    int changed;
    char[] r = s;

    changed = 0;

    foreach (size_t i, dchar c; s)
    {	dchar c2;

	if (i == 0)
	{
	    c2 = std.uni.toUniUpper(c);
	    if (c != c2)
	    {
		changed = 1;
		r = null;
	    }
	}
	else
	{
	    c2 = std.uni.toUniLower(c);
	    if (c != c2)
	    {
		if (!changed)
		{   changed = 1;
		    r = s[0 .. i].dup;
		}
	    }
	}
	if (changed)
	    std.utf.encode(r, c2);
    }
    return r;
}


unittest
{
    debug(string) printf("string.toupper.capitalize\n");

    char[] s1 = "FoL";
    char[] s2;

    s2 = capitalize(s1);
    assert(cmp(s2, "Fol") == 0);
    assert(s2 !is s1);

    s2 = capitalize(s1[0 .. 2]);
    assert(cmp(s2, "Fo") == 0);
    assert(s2.ptr == s1.ptr);

    s1 = "fOl";
    s2 = capitalize(s1);
    assert(cmp(s2, "Fol") == 0);
    assert(s2 !is s1);
}


/********************************************
 * Capitalize all words in string s[].
 * Remove leading and trailing whitespace.
 * Replace all sequences of whitespace with a single space.
 */

char[] capwords(char[] s)
{
    char[] r;
    bool inword = false;
    size_t istart = 0;
    size_t i;

    for (i = 0; i < s.length; i++)
    {
	switch (s[i])
	{
	    case ' ':
	    case '\t':
	    case '\f':
	    case '\r':
	    case '\n':
	    case '\v':
		if (inword)
		{
		    r ~= capitalize(s[istart .. i]);
		    inword = false;
		}
		break;

	    default:
		if (!inword)
		{
		    if (r.length)
			r ~= ' ';
		    istart = i;
		    inword = true;
		}
		break;
	}
    }
    if (inword)
    {
	r ~= capitalize(s[istart .. i]);
    }

    return r;
}


unittest
{
    debug(string) printf("string.capwords.unittest\n");

    char[] s1 = "\tfoo abc(aD)*  \t  (q PTT  ";
    char[] s2;

    s2 = capwords(s1);
    //writefln("s2 = '%s'", s2);
    assert(cmp(s2, "Foo Abc(ad)* (q Ptt") == 0);
}

/********************************************
 * Return a string that consists of s[] repeated n times.
 */

char[] repeat(char[] s, size_t n)
{
    if (n == 0)
	return null;
    if (n == 1)
	return s;
    char[] r = new char[n * s.length];
    if (s.length == 1)
	r[] = s[0];
    else
    {	auto len = s.length;

	for (size_t i = 0; i < n * len; i += len)
	{
	    r[i .. i + len] = s[];
	}
    }
    return r;
}


unittest
{
    debug(string) printf("string.repeat.unittest\n");

    char[] s;

    s = repeat("1234", 0);
    assert(s is null);
    s = repeat("1234", 1);
    assert(cmp(s, "1234") == 0);
    s = repeat("1234", 2);
    assert(cmp(s, "12341234") == 0);
    s = repeat("1", 4);
    assert(cmp(s, "1111") == 0);
    s = repeat(null, 4);
    assert(s is null);
}


/********************************************
 * Concatenate all the strings in words[] together into one
 * string; use sep[] as the separator.
 */

char[] join(char[][] words, char[] sep)
{
    char[] result;

    if (words.length)
    {
	size_t len = 0;
	size_t i;

	for (i = 0; i < words.length; i++)
	    len += words[i].length;

	auto seplen = sep.length;
	len += (words.length - 1) * seplen;

	result = new char[len];

	size_t j;
	i = 0;
	while (true)
	{
	    size_t wlen = words[i].length;

	    result[j .. j + wlen] = words[i];
	    j += wlen;
	    i++;
	    if (i >= words.length)
		break;
	    result[j .. j + seplen] = sep;
	    j += seplen;
	}
	assert(j == len);
    }
    return result;
}

unittest
{
    debug(string) printf("string.join.unittest\n");

    char[] word1 = "peter";
    char[] word2 = "paul";
    char[] word3 = "jerry";
    char[][3] words;
    char[] r;
    int i;

    words[0] = word1;
    words[1] = word2;
    words[2] = word3;
    r = join(words, ",");
    i = cmp(r, "peter,paul,jerry");
    assert(i == 0);
}


/**************************************
 * Split s[] into an array of words,
 * using whitespace as the delimiter.
 */

char[][] split(char[] s)
{
    size_t i;
    size_t istart = 0;
    bool inword = false;
    char[][] words;

    for (i = 0; i < s.length; i++)
    {
	switch (s[i])
	{
	    case ' ':
	    case '\t':
	    case '\f':
	    case '\r':
	    case '\n':
	    case '\v':
		if (inword)
		{
		    words ~= s[istart .. i];
		    inword = false;
		}
		break;

	    default:
		if (!inword)
		{   istart = i;
		    inword = true;
		}
		break;
	}
    }
    if (inword)
	words ~= s[istart .. i];
    return words;
}

unittest
{
    debug(string) printf("string.split1\n");

    char[] s = " peter paul\tjerry ";
    char[][] words;
    int i;

    words = split(s);
    assert(words.length == 3);
    i = cmp(words[0], "peter");
    assert(i == 0);
    i = cmp(words[1], "paul");
    assert(i == 0);
    i = cmp(words[2], "jerry");
    assert(i == 0);
}


/**************************************
 * Split s[] into an array of words,
 * using delim[] as the delimiter.
 */

char[][] split(char[] s, char[] delim)
    in
    {
	assert(delim.length > 0);
    }
    body
    {
	size_t i;
	size_t j;
	char[][] words;

	i = 0;
	if (s.length)
	{
	    if (delim.length == 1)
	    {	char c = delim[0];
		size_t nwords = 0;
		char* p = &s[0];
		char* pend = p + s.length;

		while (true)
		{
		    nwords++;
		    p = cast(char*)memchr(p, c, pend - p);
		    if (!p)
			break;
		    p++;
		    if (p == pend)
		    {	nwords++;
			break;
		    }
		}
		words.length = nwords;

		size_t wordi = 0;
		i = 0;
		while (true)
		{
		    p = cast(char*)memchr(&s[i], c, s.length - i);
		    if (!p)
		    {
			words[wordi] = s[i .. s.length];
			break;
		    }
		    j = p - &s[0];
		    words[wordi] = s[i .. j];
		    wordi++;
		    i = j + 1;
		    if (i == s.length)
		    {
			words[wordi] = "";
			break;
		    }
		}
		assert(wordi + 1 == nwords);
	    }
	    else
	    {	size_t nwords = 0;

		while (true)
		{
		    nwords++;
		    j = find(s[i .. s.length], delim);
		    if (j == -1)
			break;
		    i += j + delim.length;
		    if (i == s.length)
		    {	nwords++;
			break;
		    }
		    assert(i < s.length);
		}
		words.length = nwords;

		size_t wordi = 0;
		i = 0;
		while (true)
		{
		    j = find(s[i .. s.length], delim);
		    if (j == -1)
		    {
			words[wordi] = s[i .. s.length];
			break;
		    }
		    words[wordi] = s[i .. i + j];
		    wordi++;
		    i += j + delim.length;
		    if (i == s.length)
		    {
			words[wordi] = "";
			break;
		    }
		    assert(i < s.length);
		}
		assert(wordi + 1 == nwords);
	    }
	}
	return words;
    }

unittest
{
    debug(string) printf("string.split2\n");

    char[] s = ",peter,paul,jerry,";
    char[][] words;
    int i;

    words = split(s, ",");
    assert(words.length == 5);
    i = cmp(words[0], "");
    assert(i == 0);
    i = cmp(words[1], "peter");
    assert(i == 0);
    i = cmp(words[2], "paul");
    assert(i == 0);
    i = cmp(words[3], "jerry");
    assert(i == 0);
    i = cmp(words[4], "");
    assert(i == 0);

    s = s[0 .. s.length - 1];	// lop off trailing ','
    words = split(s, ",");
    assert(words.length == 4);
    i = cmp(words[3], "jerry");
    assert(i == 0);

    s = s[1 .. s.length];	// lop off leading ','
    words = split(s, ",");
    assert(words.length == 3);
    i = cmp(words[0], "peter");
    assert(i == 0);

    char[] s2 = ",,peter,,paul,,jerry,,";

    words = split(s2, ",,");
    //printf("words.length = %d\n", words.length);
    assert(words.length == 5);
    i = cmp(words[0], "");
    assert(i == 0);
    i = cmp(words[1], "peter");
    assert(i == 0);
    i = cmp(words[2], "paul");
    assert(i == 0);
    i = cmp(words[3], "jerry");
    assert(i == 0);
    i = cmp(words[4], "");
    assert(i == 0);

    s2 = s2[0 .. s2.length - 2];	// lop off trailing ',,'
    words = split(s2, ",,");
    assert(words.length == 4);
    i = cmp(words[3], "jerry");
    assert(i == 0);

    s2 = s2[2 .. s2.length];	// lop off leading ',,'
    words = split(s2, ",,");
    assert(words.length == 3);
    i = cmp(words[0], "peter");
    assert(i == 0);
}


/**************************************
 * Split s[] into an array of lines,
 * using CR, LF, or CR-LF as the delimiter.
 */

char[][] splitlines(char[] s)
{
    size_t i;
    size_t istart;
    size_t nlines;
    char[][] lines;

    nlines = 0;
    for (i = 0; i < s.length; i++)
    {	char c;

	c = s[i];
	if (c == '\r' || c == '\n')
	{
	    nlines++;
	    istart = i + 1;
	    if (c == '\r' && i + 1 < s.length && s[i + 1] == '\n')
	    {
		i++;
		istart++;
	    }
	}
    }
    if (istart != i)
	nlines++;

    lines = new char[][nlines];
    nlines = 0;
    istart = 0;
    for (i = 0; i < s.length; i++)
    {	char c;

	c = s[i];
	if (c == '\r' || c == '\n')
	{
	    lines[nlines] = s[istart .. i];
	    nlines++;
	    istart = i + 1;
	    if (c == '\r' && i + 1 < s.length && s[i + 1] == '\n')
	    {
		i++;
		istart++;
	    }
	}
    }
    if (istart != i)
    {	lines[nlines] = s[istart .. i];
	nlines++;
    }

    assert(nlines == lines.length);
    return lines;
}

unittest
{
    debug(string) printf("string.splitlines\n");

    char[] s = "\rpeter\n\rpaul\r\njerry\n";
    char[][] lines;
    int i;

    lines = splitlines(s);
    //printf("lines.length = %d\n", lines.length);
    assert(lines.length == 5);
    //printf("lines[0] = %llx, '%.*s'\n", lines[0], lines[0]);
    assert(lines[0].length == 0);
    i = cmp(lines[1], "peter");
    assert(i == 0);
    assert(lines[2].length == 0);
    i = cmp(lines[3], "paul");
    assert(i == 0);
    i = cmp(lines[4], "jerry");
    assert(i == 0);

    s = s[0 .. s.length - 1];	// lop off trailing \n
    lines = splitlines(s);
    //printf("lines.length = %d\n", lines.length);
    assert(lines.length == 5);
    i = cmp(lines[4], "jerry");
    assert(i == 0);
}


/*****************************************
 * Strips leading or trailing whitespace, or both.
 */

char[] stripl(char[] s)
{
    size_t i;

    for (i = 0; i < s.length; i++)
    {
	if (!std.ctype.isspace(s[i]))
	    break;
    }
    return s[i .. s.length];
}

char[] stripr(char[] s) /// ditto
{
    size_t i;

    for (i = s.length; i > 0; i--)
    {
	if (!std.ctype.isspace(s[i - 1]))
	    break;
    }
    return s[0 .. i];
}

char[] strip(char[] s) /// ditto
{
    return stripr(stripl(s));
}

unittest
{
    debug(string) printf("string.strip.unittest\n");
    char[] s;
    int i;

    s = strip("  foo\t ");
    i = cmp(s, "foo");
    assert(i == 0);
}

/*******************************************
 * Returns s[] sans trailing delimiter[], if any.
 * If delimiter[] is null, removes trailing CR, LF, or CRLF, if any.
 */

char[] chomp(char[] s, char[] delimiter = null)
{
    if (delimiter is null)
    {   auto len = s.length;

	if (len)
	{   auto c = s[len - 1];

	    if (c == '\r')			// if ends in CR
		len--;
	    else if (c == '\n')			// if ends in LF
	    {
		len--;
		if (len && s[len - 1] == '\r')
		    len--;			// remove CR-LF
	    }
	}
	return s[0 .. len];
    }
    else if (s.length >= delimiter.length)
    {
	if (s[length - delimiter.length .. length] == delimiter)
	    return s[0 .. length - delimiter.length];
    }
    return s;
}

unittest
{
    debug(string) printf("string.chomp.unittest\n");
    char[] s;

    s = chomp(null);
    assert(s is null);
    s = chomp("hello");
    assert(s == "hello");
    s = chomp("hello\n");
    assert(s == "hello");
    s = chomp("hello\r");
    assert(s == "hello");
    s = chomp("hello\r\n");
    assert(s == "hello");
    s = chomp("hello\n\r");
    assert(s == "hello\n");
    s = chomp("hello\n\n");
    assert(s == "hello\n");
    s = chomp("hello\r\r");
    assert(s == "hello\r");
    s = chomp("hello\nxxx\n");
    assert(s == "hello\nxxx");

    s = chomp(null, null);
    assert(s is null);
    s = chomp("hello", "o");
    assert(s == "hell");
    s = chomp("hello", "p");
    assert(s == "hello");
    s = chomp("hello", null);
    assert(s == "hello");
    s = chomp("hello", "llo");
    assert(s == "he");
}


/***********************************************
 * Returns s[] sans trailing character, if there is one.
 * If last two characters are CR-LF, then both are removed.
 */

char[] chop(char[] s)
{   auto len = s.length;

    if (len)
    {
	if (len >= 2 && s[len - 1] == '\n' && s[len - 2] == '\r')
	    return s[0 .. len - 2];

	// If we're in a tail of a UTF-8 sequence, back up
	while ((s[len - 1] & 0xC0) == 0x80)
	{
	    len--;
	    if (len == 0)
		throw new std.utf.UtfException("invalid UTF sequence", 0);
	}

	return s[0 .. len - 1];
    }
    return s;
}


unittest
{
    debug(string) printf("string.chop.unittest\n");
    char[] s;

    s = chop(null);
    assert(s is null);
    s = chop("hello");
    assert(s == "hell");
    s = chop("hello\r\n");
    assert(s == "hello");
    s = chop("hello\n\r");
    assert(s == "hello\n");
}


/*******************************************
 * Left justify, right justify, or center string s[]
 * in field width chars wide.
 */

char[] ljustify(char[] s, ptrdiff_t width)
{
    if (s.length >= width)
	return s;
    char[] r = new char[width];
    r[0..s.length] = s;
    r[s.length .. width] = cast(char)' ';
    return r;
}

/// ditto
char[] rjustify(char[] s, ptrdiff_t width)
{
    if (s.length >= width)
	return s;
    char[] r = new char[width];
    r[0 .. width - s.length] = cast(char)' ';
    r[width - s.length .. width] = s;
    return r;
}

/// ditto
char[] center(char[] s, ptrdiff_t width)
{
    if (s.length >= width)
	return s;
    char[] r = new char[width];
    ptrdiff_t left = (width - s.length) / 2;
    r[0 .. left] = cast(char)' ';
    r[left .. left + s.length] = s;
    r[left + s.length .. width] = cast(char)' ';
    return r;
}

unittest
{
    debug(string) printf("string.justify.unittest\n");

    char[] s = "hello";
    char[] r;
    int i;

    r = ljustify(s, 8);
    i = cmp(r, "hello   ");
    assert(i == 0);

    r = rjustify(s, 8);
    i = cmp(r, "   hello");
    assert(i == 0);

    r = center(s, 8);
    i = cmp(r, " hello  ");
    assert(i == 0);

    r = zfill(s, 8);
    i = cmp(r, "000hello");
    assert(i == 0);
}


/*****************************************
 * Same as rjustify(), but fill with '0's.
 */

char[] zfill(char[] s, ptrdiff_t width)
{
    if (s.length >= width)
	return s;
    char[] r = new char[width];
    r[0 .. width - s.length] = cast(char)'0';
    r[width - s.length .. width] = s;
    return r;
}

/********************************************
 * Replace occurrences of from[] with to[] in s[].
 */

char[] replace(char[] s, char[] from, char[] to)
{
    char[] p;
    ptrdiff_t i;
    size_t istart;

    //printf("replace('%.*s','%.*s','%.*s')\n", s, from, to);
    if (from.length == 0)
	return s;
    istart = 0;
    while (istart < s.length)
    {
	i = find(s[istart .. s.length], from);
	if (i == -1)
	{
	    p ~= s[istart .. s.length];
	    break;
	}
	p ~= s[istart .. istart + i];
	p ~= to;
	istart += i + from.length;
    }
    return p;
}

unittest
{
    debug(string) printf("string.replace.unittest\n");

    char[] s = "This is a foo foo list";
    char[] from = "foo";
    char[] to = "silly";
    char[] r;
    int i;

    r = replace(s, from, to);
    i = cmp(r, "This is a silly silly list");
    assert(i == 0);

    r = replace(s, "", to);
    i = cmp(r, "This is a foo foo list");
    assert(i == 0);
}

/*****************************
 * Return a _string that is string[] with slice[] replaced by replacement[].
 */

char[] replaceSlice(char[] string, char[] slice, char[] replacement)
in
{
    // Verify that slice[] really is a slice of string[]
    ptrdiff_t so = cast(char*)slice - cast(char*)string;
    assert(so >= 0);
    //printf("string.length = %d, so = %d, slice.length = %d\n", string.length, so, slice.length);
    assert(string.length >= so + slice.length);
}
body
{
    char[] result;
    ptrdiff_t so = cast(char*)slice - cast(char*)string;

    result.length = string.length - slice.length + replacement.length;

    result[0 .. so] = string[0 .. so];
    result[so .. so + replacement.length] = replacement;
    result[so + replacement.length .. result.length] = string[so + slice.length .. string.length];

    return result;
}

unittest
{
    debug(string) printf("string.replaceSlice.unittest\n");

    char[] string = "hello";
    char[] slice = string[2 .. 4];

    char[] r = replaceSlice(string, slice, "bar");
    int i;
    i = cmp(r, "hebaro");
    assert(i == 0);
}

/**********************************************
 * Insert sub[] into s[] at location index.
 */

char[] insert(char[] s, size_t index, char[] sub)
in
{
    assert(0 <= index && index <= s.length);
}
body
{
    if (sub.length == 0)
	return s;

    if (s.length == 0)
	return sub;

    ptrdiff_t newlength = s.length + sub.length;
    char[] result = new char[newlength];

    result[0 .. index] = s[0 .. index];
    result[index .. index + sub.length] = sub;
    result[index + sub.length .. newlength] = s[index .. s.length];
    return result;
}

unittest
{
    debug(string) printf("string.insert.unittest\n");

    char[] r;
    int i;

    r = insert("abcd", 0, "e");
    i = cmp(r, "eabcd");
    assert(i == 0);

    r = insert("abcd", 4, "e");
    i = cmp(r, "abcde");
    assert(i == 0);

    r = insert("abcd", 2, "ef");
    i = cmp(r, "abefcd");
    assert(i == 0);

    r = insert(null, 0, "e");
    i = cmp(r, "e");
    assert(i == 0);

    r = insert("abcd", 0, null);
    i = cmp(r, "abcd");
    assert(i == 0);
}

/***********************************************
 * Count up all instances of sub[] in s[].
 */

size_t count(char[] s, char[] sub)
{
    size_t i;
    ptrdiff_t j;
    int count = 0;

    for (i = 0; i < s.length; i += j + sub.length)
    {
	j = find(s[i .. s.length], sub);
	if (j == -1)
	    break;
	count++;
    }
    return count;
}

unittest
{
    debug(string) printf("string.count.unittest\n");

    char[] s = "This is a fofofof list";
    char[] sub = "fof";
    int i;

    i = count(s, sub);
    assert(i == 2);
}


/************************************************
 * Replace tabs with the appropriate number of spaces.
 * tabsize is the distance between tab stops.
 */

char[] expandtabs(char[] string, ptrdiff_t tabsize = 8)
{
    bool changes = false;
    char[] result = string;
    ptrdiff_t column;
    ptrdiff_t nspaces;

    foreach (size_t i, dchar c; string)
    {
	switch (c)
	{
	    case '\t':
		nspaces = tabsize - (column % tabsize);
		if (!changes)
		{
		    changes = true;
		    result = null;
		    result.length = string.length + nspaces - 1;
		    result.length = i + nspaces;
		    result[0 .. i] = string[0 .. i];
		    result[i .. i + nspaces] = ' ';
		}
		else
		{   ptrdiff_t j = result.length;
		    result.length = j + nspaces;
		    result[j .. j + nspaces] = ' ';
		}
		column += nspaces;
		break;

	    case '\r':
	    case '\n':
	    case PS:
	    case LS:
		column = 0;
		goto L1;

	    default:
		column++;
	    L1:
		if (changes)
		{
		    if (c <= 0x7F)
			result ~= cast(char)c;
		    else
			std.utf.encode(result, c);
		}
		break;
	}
    }

    return result;
}

unittest
{
    debug(string) printf("string.expandtabs.unittest\n");

    char[] s = "This \tis\t a fofof\tof list";
    char[] r;
    int i;

    r = expandtabs(s, 8);
    i = cmp(r, "This    is       a fofof        of list");
    assert(i == 0);

    r = expandtabs(null);
    assert(r == null);
    r = expandtabs("");
    assert(r.length == 0);
    r = expandtabs("a");
    assert(r == "a");
    r = expandtabs("\t");
    assert(r == "        ");
    r = expandtabs(  "  ab\tasdf ");
    //writefln("r = '%s'", r);
    assert(r == "  ab    asdf ");
    // TODO: need UTF test case
}


/*******************************************
 * Replace spaces in string with the optimal number of tabs.
 * Trailing spaces or tabs in a line are removed.
 * Params:
 *	string = String to convert.
 *	tabsize = Tab columns are tabsize spaces apart. tabsize defaults to 8.
 */

char[] entab(char[] string, ptrdiff_t tabsize = 8)
{
    bool changes = false;
    char[] result = string;

    ptrdiff_t nspaces = 0;
    ptrdiff_t nwhite = 0;
    ptrdiff_t column = 0;			// column number

    foreach (size_t i, dchar c; string)
    {   

	void change()
	{
	    changes = true;
	    result = null;
	    result.length = string.length;
	    result.length = i;
	    result[0 .. i] = string[0 .. i];
	}

	switch (c)
	{   
	    case '\t':
		nwhite++;
		if (nspaces)
		{
		    if (!changes)
			change();

		    ptrdiff_t j = result.length - nspaces;
		    ptrdiff_t ntabs = (((column - nspaces) % tabsize) + nspaces) / tabsize;
		    result.length = j + ntabs;
		    result[j .. j + ntabs] = '\t';
		    nwhite += ntabs - nspaces;
		    nspaces = 0;
		}
		column = (column + tabsize) / tabsize * tabsize;
		break;

	    case '\r':
	    case '\n':
	    case PS:
	    case LS:
		// Truncate any trailing spaces or tabs
		if (nwhite)
		{
		    if (!changes)
			change();
		    result = result[0 .. result.length - nwhite];
		}
		break;

	    default:
		if (nspaces >= 2 && (column % tabsize) == 0)
		{
		    if (!changes)
			change();

		    ptrdiff_t j = result.length - nspaces;
		    ptrdiff_t ntabs = (nspaces + tabsize - 1) / tabsize;
		    result.length = j + ntabs;
		    result[j .. j + ntabs] = '\t';
		    nwhite += ntabs - nspaces;
		    nspaces = 0;
		}
		if (c == ' ')
		{   nwhite++;
		    nspaces++;
		}
		else
		{   nwhite = 0;
		    nspaces = 0;
		}
		column++;
		break;
	}
	if (changes)
	{
	    if (c <= 0x7F)
		result ~= cast(char)c;
	    else
		std.utf.encode(result, c);
	}
    }

    // Truncate any trailing spaces or tabs
    if (nwhite)
	result = result[0 .. result.length - nwhite];

    return result;
}

unittest
{
    debug(string) printf("string.entab.unittest\n");

    char[] r;

    r = entab(null);
    assert(r == null);
    r = entab("");
    assert(r.length == 0);
    r = entab("a");
    assert(r == "a");
    r = entab("        ");
    assert(r == "");
    r = entab("        x");
    assert(r == "\tx");
    r = entab("  ab    asdf ");
    assert(r == "  ab\tasdf");
    r = entab("  ab     asdf ");
    assert(r == "  ab\t asdf");
    r = entab("  ab \t   asdf ");
    assert(r == "  ab\t   asdf");
    r = entab("1234567 \ta");
    assert(r == "1234567\t\ta");
    r = entab("1234567  \ta");
    assert(r == "1234567\t\ta");
    r = entab("1234567   \ta");
    assert(r == "1234567\t\ta");
    r = entab("1234567    \ta");
    assert(r == "1234567\t\ta");
    r = entab("1234567     \ta");
    assert(r == "1234567\t\ta");
    r = entab("1234567      \ta");
    assert(r == "1234567\t\ta");
    r = entab("1234567       \ta");
    assert(r == "1234567\t\ta");
    r = entab("1234567        \ta");
    assert(r == "1234567\t\ta");
    r = entab("1234567         \ta");
    assert(r == "1234567\t\t\ta");
    // TODO: need UTF test case
}



/************************************
 * Construct translation table for translate().
 * BUG: only works with ASCII
 */

char[] maketrans(char[] from, char[] to)
    in
    {
	assert(from.length == to.length);
	assert(from.length <= 128);
	foreach (char c; from)
	{
	    assert(c <= 0x7F);
	}
	foreach (char c; to)
	{
	    assert(c <= 0x7F);
	}
    }
    body
    {
	char[] t = new char[256];
	ptrdiff_t i;

	for (i = 0; i < t.length; i++)
	    t[i] = cast(char)i;

	for (i = 0; i < from.length; i++)
	    t[from[i]] = to[i];

	return t;
    }

/******************************************
 * Translate characters in s[] using table created by maketrans().
 * Delete chars in delchars[].
 * BUG: only works with ASCII
 */

char[] translate(char[] s, char[] transtab, char[] delchars)
    in
    {
	assert(transtab.length == 256);
    }
    body
    {
	char[] r;
	ptrdiff_t count;
	bool[256] deltab;

	deltab[] = false;
	foreach (char c; delchars)
	{
	    deltab[c] = true;
	}

	count = 0;
	foreach (char c; s)
	{
	    if (!deltab[c])
		count++;
	    //printf("s[%d] = '%c', count = %d\n", i, s[i], count);
	}

	r = new char[count];
	count = 0;
	foreach (char c; s)
	{
	    if (!deltab[c])
	    {
		r[count] = transtab[c];
		count++;
	    }
	}

	return r;
    }

unittest
{
    debug(string) printf("string.translate.unittest\n");

    char[] from = "abcdef";
    char[] to   = "ABCDEF";
    char[] s    = "The quick dog fox";
    char[] t;
    char[] r;
    int i;

    t = maketrans(from, to);
    r = translate(s, t, "kg");
    //printf("r = '%.*s'\n", r);
    i = cmp(r, "ThE quiC Do Fox");
    assert(i == 0);
}

/***********************************************
 * Convert to char[].
 */

char[] toString(bool b)
{
    return b ? "true" : "false";
}

/// ditto
char[] toString(char c)
{
    char[] result = new char[2];
    result[0] = c;
    result[1] = 0;
    return result[0 .. 1];
}

unittest
{
    debug(string) printf("string.toString(char).unittest\n");

    char[] s = "foo";
    char[] s2;
    foreach (char c; s)
    {
	s2 ~= std.string.toString(c);
    }
    //printf("%.*s", s2);
    assert(s2 == "foo");
}

char[] toString(ubyte ub)  { return toString(cast(uint) ub); } /// ditto
char[] toString(ushort us) { return toString(cast(uint) us); } /// ditto

/// ditto
char[] toString(uint u)
{   char[uint.sizeof * 3] buffer = void;
    int ndigits;
    char[] result;

    ndigits = 0;
    if (u < 10)
	// Avoid storage allocation for simple stuff
	result = digits[u .. u + 1];
    else
    {
	while (u)
	{
	    uint c = (u % 10) + '0';
	    u /= 10;
	    ndigits++;
	    buffer[buffer.length - ndigits] = cast(char)c;
	}
	result = new char[ndigits];
	result[] = buffer[buffer.length - ndigits .. buffer.length];
    }
    return result;
}

unittest
{
    debug(string) printf("string.toString(uint).unittest\n");

    char[] r;
    int i;

    r = toString(0u);
    i = cmp(r, "0");
    assert(i == 0);

    r = toString(9u);
    i = cmp(r, "9");
    assert(i == 0);

    r = toString(123u);
    i = cmp(r, "123");
    assert(i == 0);
}

/// ditto
char[] toString(ulong u)
{   char[ulong.sizeof * 3] buffer;
    int ndigits;
    char[] result;

    if (u < 0x1_0000_0000)
	return toString(cast(uint)u);
    ndigits = 0;
    while (u)
    {
	char c = cast(char)((u % 10) + '0');
	u /= 10;
	ndigits++;
	buffer[buffer.length - ndigits] = c;
    }
    result = new char[ndigits];
    result[] = buffer[buffer.length - ndigits .. buffer.length];
    return result;
}

unittest
{
    debug(string) printf("string.toString(ulong).unittest\n");

    char[] r;
    int i;

    r = toString(0uL);
    i = cmp(r, "0");
    assert(i == 0);

    r = toString(9uL);
    i = cmp(r, "9");
    assert(i == 0);

    r = toString(123uL);
    i = cmp(r, "123");
    assert(i == 0);
}

char[] toString(byte b)  { return toString(cast(int) b); } /// ditto
char[] toString(short s) { return toString(cast(int) s); } /// ditto

/// ditto
char[] toString(int i)
{   char[1 + int.sizeof * 3] buffer;
    char[] result;

    if (i >= 0)
	return toString(cast(uint)i);

    uint u = -i;
    int ndigits = 1;
    while (u)
    {
	char c = cast(char)((u % 10) + '0');
	u /= 10;
	buffer[buffer.length - ndigits] = c;
	ndigits++;
    }
    buffer[buffer.length - ndigits] = '-';
    result = new char[ndigits];
    result[] = buffer[buffer.length - ndigits .. buffer.length];
    return result;
}

unittest
{
    debug(string) printf("string.toString(int).unittest\n");

    char[] r;
    int i;

    r = toString(0);
    i = cmp(r, "0");
    assert(i == 0);

    r = toString(9);
    i = cmp(r, "9");
    assert(i == 0);

    r = toString(123);
    i = cmp(r, "123");
    assert(i == 0);

    r = toString(-0);
    i = cmp(r, "0");
    assert(i == 0);

    r = toString(-9);
    i = cmp(r, "-9");
    assert(i == 0);

    r = toString(-123);
    i = cmp(r, "-123");
    assert(i == 0);
}

/// ditto
char[] toString(long i)
{   char[1 + long.sizeof * 3] buffer;
    char[] result;

    if (i >= 0)
	return toString(cast(ulong)i);
    if (cast(int)i == i)
	return toString(cast(int)i);

    ulong u = cast(ulong)(-i);
    int ndigits = 1;
    while (u)
    {
	char c = cast(char)((u % 10) + '0');
	u /= 10;
	buffer[buffer.length - ndigits] = c;
	ndigits++;
    }
    buffer[buffer.length - ndigits] = '-';
    result = new char[ndigits];
    result[] = buffer[buffer.length - ndigits .. buffer.length];
    return result;
}

unittest
{
    debug(string) printf("string.toString(long).unittest\n");

    char[] r;
    int i;

    r = toString(0L);
    i = cmp(r, "0");
    assert(i == 0);

    r = toString(9L);
    i = cmp(r, "9");
    assert(i == 0);

    r = toString(123L);
    i = cmp(r, "123");
    assert(i == 0);

    r = toString(-0L);
    i = cmp(r, "0");
    assert(i == 0);

    r = toString(-9L);
    i = cmp(r, "-9");
    assert(i == 0);

    r = toString(-123L);
    i = cmp(r, "-123");
    assert(i == 0);
}

/// ditto
char[] toString(float f) { return toString(cast(double) f); }

/// ditto
char[] toString(double d)
{
    char[20] buffer;

    int len = sprintf(buffer.ptr, "%g", d);
    return buffer[0 .. len].dup;
}

/// ditto
static if (real.sizeof != double.sizeof)
    private static const char[] _longDoubleFormat = "L";
else
    private static const char[] _longDoubleFormat = "";
    
char[] toString(real r)
{
    char[20] buffer;

    int len = sprintf(buffer.ptr, ("%"~_longDoubleFormat~"g").ptr, r);
    return buffer[0 .. len].dup;
}

/// ditto
char[] toString(ifloat f) { return toString(cast(idouble) f); }

/// ditto
char[] toString(idouble d)
{
    char[21] buffer;

    int len = sprintf(buffer.ptr, "%gi", d);
    return buffer[0 .. len].dup;
}

/// ditto
char[] toString(ireal r)
{
    char[21] buffer;

    int len = sprintf(buffer.ptr, ("%"~_longDoubleFormat~"gi").ptr, r);
    return buffer[0 .. len].dup;
}

/// ditto
char[] toString(cfloat f) { return toString(cast(cdouble) f); }

/// ditto
char[] toString(cdouble d)
{
    char[20 + 1 + 20 + 1] buffer;

    int len = sprintf(buffer.ptr, "%g+%gi", d.re, d.im);
    return buffer[0 .. len].dup;
}

/// ditto
char[] toString(creal r)
{
    char[20 + 1 + 20 + 1] buffer;

    int len = sprintf(buffer.ptr, ("%"~_longDoubleFormat~"g+%"~_longDoubleFormat~"gi").ptr, r.re, r.im);
    return buffer[0 .. len].dup;
}

/******************************************
 * Convert value to string in _radix radix.
 *
 * radix must be a value from 2 to 36.
 * value is treated as a signed value only if radix is 10.
 * The characters A through Z are used to represent values 10 through 36.
 */
char[] toString(long value, uint radix)
in
{
    assert(radix >= 2 && radix <= 36);
}
body
{
    if (radix == 10)
	return toString(value);		// handle signed cases only for radix 10
    return toString(cast(ulong)value, radix);
}

/// ditto
char[] toString(ulong value, uint radix)
in
{
    assert(radix >= 2 && radix <= 36);
}
body
{
    char[value.sizeof * 8] buffer;
    size_t i = buffer.length;

    if (value < radix && value < hexdigits.length)
	return hexdigits[cast(size_t)value .. cast(size_t)value + 1];

    do
    {	ubyte c;

	c = cast(ubyte)(value % radix);
	value = value / radix;
	i--;
	buffer[i] = cast(char)((c < 10) ? c + '0' : c + 'A' - 10);
    } while (value);
    return buffer[i .. length].dup;
}

unittest
{
    debug(string) printf("string.toString(ulong, uint).unittest\n");

    char[] r;
    int i;

    r = toString(-10L, 10u);
    assert(r == "-10");

    r = toString(15L, 2u);
    //writefln("r = '%s'", r);
    assert(r == "1111");

    r = toString(1L, 2u);
    //writefln("r = '%s'", r);
    assert(r == "1");

    r = toString(0x1234AFL, 16u);
    //writefln("r = '%s'", r);
    assert(r == "1234AF");
}

/*************************************************
 * Convert C-style 0 terminated string s to char[] string.
 */

char[] toString(char *s)
{
    return s ? s[0 .. strlen(s)] : cast(char[])null;
}

unittest
{
    debug(string) printf("string.toString(char*).unittest\n");

    char[] r;
    int i;

    r = toString(null);
    i = cmp(r, "");
    assert(i == 0);

    r = toString("foo\0");
    i = cmp(r, "foo");
    assert(i == 0);
}


/*****************************************************
 * Format arguments into a string.
 */


char[] format(...)
{
    char[] s;

    void putc(dchar c)
    {
	std.utf.encode(s, c);
    }

    std.format.doFormat(&putc, _arguments, _argptr);
    return s;
}


/*****************************************************
 * Format arguments into string <i>s</i> which must be large
 * enough to hold the result. Throws ArrayBoundsError if it is not.
 * Returns: s
 */
char[] sformat(char[] s, ...)
{   size_t i;

    void putc(dchar c)
    {
	if (c <= 0x7F)
	{
	    if (i >= s.length)
		throw new ArrayBoundsError("std.string.sformat", 0);
	    s[i] = cast(char)c;
	    ++i;
	}
	else
	{   char[4] buf;
	    char[] b;

	    b = std.utf.toUTF8(buf, c);
	    if (i + b.length > s.length)
		throw new ArrayBoundsError("std.string.sformat", 0);
	    s[i..i+b.length] = b[];
	    i += b.length;
	}
    }

    std.format.doFormat(&putc, _arguments, _argptr);
    return s[0 .. i];
}


unittest
{
    debug(string) printf("std.string.format.unittest\n");

    char[] r;
    int i;
/+
    r = format(null);
    i = cmp(r, "");
    assert(i == 0);
+/
    r = format("foo");
    i = cmp(r, "foo");
    assert(i == 0);

    r = format("foo%%");
    i = cmp(r, "foo%");
    assert(i == 0);

    r = format("foo%s", 'C');
    i = cmp(r, "fooC");
    assert(i == 0);

    r = format("%s foo", "bar");
    i = cmp(r, "bar foo");
    assert(i == 0);

    r = format("%s foo %s", "bar", "abc");
    i = cmp(r, "bar foo abc");
    assert(i == 0);

    r = format("foo %d", -123);
    i = cmp(r, "foo -123");
    assert(i == 0);

    r = format("foo %d", 123);
    i = cmp(r, "foo 123");
    assert(i == 0);
}


/***********************************************
 * See if character c is in the pattern.
 * Patterns:
 *
 *	A <i>pattern</i> is an array of characters much like a <i>character
 *	class</i> in regular expressions. A sequence of characters
 *	can be given, such as "abcde". The '-' can represent a range
 *	of characters, as "a-e" represents the same pattern as "abcde".
 *	"a-fA-F0-9" represents all the hex characters.
 *	If the first character of a pattern is '^', then the pattern
 *	is negated, i.e. "^0-9" means any character except a digit.
 *	The functions inPattern, <b>countchars</b>, <b>removeschars</b>,
 *	and <b>squeeze</b>
 *	use patterns.
 *
 * Note: In the future, the pattern syntax may be improved
 *	to be more like regular expression character classes.
 */

bool inPattern(dchar c, char[] pattern)
{
    bool result = false;
    int range = 0;
    dchar lastc;

    foreach (size_t i, dchar p; pattern)
    {
	if (p == '^' && i == 0)
	{   result = true;
	    if (i + 1 == pattern.length)
		return (c == p);	// or should this be an error?
	}
	else if (range)
	{
	    range = 0;
	    if (lastc <= c && c <= p || c == p)
		return !result;
	}
	else if (p == '-' && i > result && i + 1 < pattern.length)
	{
	    range = 1;
	    continue;
	}
	else if (c == p)
	    return !result;
	lastc = p;
    }
    return result;
}


unittest
{
    debug(string) printf("std.string.inPattern.unittest\n");

    int i;

    i = inPattern('x', "x");
    assert(i == 1);
    i = inPattern('x', "y");
    assert(i == 0);
    i = inPattern('x', cast(char[])null);
    assert(i == 0);
    i = inPattern('x', "^y");
    assert(i == 1);
    i = inPattern('x', "yxxy");
    assert(i == 1);
    i = inPattern('x', "^yxxy");
    assert(i == 0);
    i = inPattern('x', "^abcd");
    assert(i == 1);
    i = inPattern('^', "^^");
    assert(i == 0);
    i = inPattern('^', "^");
    assert(i == 1);
    i = inPattern('^', "a^");
    assert(i == 1);
    i = inPattern('x', "a-z");
    assert(i == 1);
    i = inPattern('x', "A-Z");
    assert(i == 0);
    i = inPattern('x', "^a-z");
    assert(i == 0);
    i = inPattern('x', "^A-Z");
    assert(i == 1);
    i = inPattern('-', "a-");
    assert(i == 1);
    i = inPattern('-', "^A-");
    assert(i == 0);
    i = inPattern('a', "z-a");
    assert(i == 1);
    i = inPattern('z', "z-a");
    assert(i == 1);
    i = inPattern('x', "z-a");
    assert(i == 0);
}


/***********************************************
 * See if character c is in the intersection of the patterns.
 */

int inPattern(dchar c, char[][] patterns)
{   int result;

    foreach (char[] pattern; patterns)
    {
	if (!inPattern(c, pattern))
	{   result = 0;
	    break;
	}
	result = 1;
    }
    return result;
}


/********************************************
 * Count characters in s that match pattern.
 */

size_t countchars(char[] s, char[] pattern)
{
    size_t count;

    foreach (dchar c; s)
    {
	count += inPattern(c, pattern);
    }
    return count;
}


unittest
{
    debug(string) printf("std.string.count.unittest\n");

    size_t c;

    c = countchars("abc", "a-c");
    assert(c == 3);
    c = countchars("hello world", "or");
    assert(c == 3);
}


/********************************************
 * Return string that is s with all characters removed that match pattern.
 */

char[] removechars(char[] s, char[] pattern)
{
    char[] r = s;
    int changed;
    size_t j;

    foreach (size_t i, dchar c; s)
    {
	if (!inPattern(c, pattern))
	{
	    if (changed)
	    {
		if (r is s)
		    r = s[0 .. j].dup;
		std.utf.encode(r, c);
	    }
	}
	else if (!changed)
	{   changed = 1;
	    j = i;
	}
    }
    if (changed && r is s)
	r = s[0 .. j].dup;
    return r;
}


unittest
{
    debug(string) printf("std.string.remove.unittest\n");

    char[] r;

    r = removechars("abc", "a-c");
    assert(r is null);
    r = removechars("hello world", "or");
    assert(r == "hell wld");
    r = removechars("hello world", "d");
    assert(r == "hello worl");
}


/***************************************************
 * Return string where sequences of a character in s[] from pattern[]
 * are replaced with a single instance of that character.
 * If pattern is null, it defaults to all characters.
 */

char[] squeeze(char[] s, char[] pattern = null)
{
    char[] r = s;
    dchar lastc;
    size_t lasti;
    int run;
    bool changed;

    foreach (size_t i, dchar c; s)
    {
	if (run && lastc == c)
	{
	    changed = true;
	}
	else if (pattern is null || inPattern(c, pattern))
	{
	    run = 1;
	    if (changed)
	    {	if (r is s)
		    r = s[0 .. lasti].dup;
		std.utf.encode(r, c);
	    }
	    else
		lasti = i + std.utf.stride(s, i);
	    lastc = c;
	}
	else
	{
	    run = 0;
	    if (changed)
	    {	if (r is s)
		    r = s[0 .. lasti].dup;
		std.utf.encode(r, c);
	    }
	}
    }
    if (changed)
    {
	if (r is s)
	    r = s[0 .. lasti];
    }
    return r;
}


unittest
{
    debug(string) printf("std.string.squeeze.unittest\n");
    char[] s,r;

    r = squeeze("hello");
    //writefln("r = '%s'", r);
    assert(r == "helo");
    s = "abcd";
    r = squeeze(s);
    assert(r is s);
    s = "xyzz";
    r = squeeze(s);
    assert(r.ptr == s.ptr);	// should just be a slice
    r = squeeze("hello goodbyee", "oe");
    assert(r == "hello godbye");
}


/**********************************************
 * Return string that is the 'successor' to s[].
 * If the rightmost character is a-zA-Z0-9, it is incremented within
 * its case or digits. If it generates a carry, the process is
 * repeated with the one to its immediate left.
 */

char[] succ(char[] s)
{
    if (s.length && isalnum(s[length - 1]))
    {
	char[] r = s.dup;
	size_t i = r.length - 1;

	while (1)
	{   dchar c = s[i];
	    dchar carry;

	    switch (c)
	    {
		case '9':
		    c = '0';
		    carry = '1';
		    goto Lcarry;
		case 'z':
		case 'Z':
		    c -= 'Z' - 'A';
		    carry = c;
		Lcarry:
		    r[i] = cast(char)c;
		    if (i == 0)
		    {
			char[] t = new char[r.length + 1];
			t[0] = cast(char)carry;
			t[1 .. length] = r[];
			return t;
		    }
		    i--;
		    break;

		default:
		    if (std.ctype.isalnum(c))
			r[i]++;
		    return r;
	    }
	}
    }
    return s;
}

unittest
{
    debug(string) printf("std.string.succ.unittest\n");

    char[] r;

    r = succ(null);
    assert(r is null);
    r = succ("!@#$%");
    assert(r == "!@#$%");
    r = succ("1");
    assert(r == "2");
    r = succ("9");
    assert(r == "10");
    r = succ("999");
    assert(r == "1000");
    r = succ("zz99");
    assert(r == "aaa00");
}


/***********************************************
 * Replaces characters in str[] that are in from[]
 * with corresponding characters in to[] and returns the resulting
 * string.
 * Params:
 *	modifiers = a string of modifier characters
 * Modifiers:
		<table border=1 cellspacing=0 cellpadding=5>
		<tr> <th>Modifier <th>Description
		<tr> <td><b>c</b> <td>Complement the list of characters in from[]
		<tr> <td><b>d</b> <td>Removes matching characters with no corresponding replacement in to[]
		<tr> <td><b>s</b> <td>Removes adjacent duplicates in the replaced characters
		</table>

	If modifier <b>d</b> is present, then the number of characters
	in to[] may be only 0 or 1.

	If modifier <b>d</b> is not present and to[] is null,
	then to[] is taken _to be the same as from[].

	If modifier <b>d</b> is not present and to[] is shorter
	than from[], then to[] is extended by replicating the
	last character in to[].

	Both from[] and to[] may contain ranges using the <b>-</b>
	character, for example <b>a-d</b> is synonymous with <b>abcd</b>.
	Neither accept a leading <b>^</b> as meaning the complement of
	the string (use the <b>c</b> modifier for that).
 */

char[] tr(char[] str, char[] from, char[] to, char[] modifiers = null)
{
    int mod_c;
    int mod_d;
    int mod_s;

    foreach (char c; modifiers)
    {
	switch (c)
	{
	    case 'c':	mod_c = 1; break;	// complement
	    case 'd':	mod_d = 1; break;	// delete unreplaced chars
	    case 's':	mod_s = 1; break;	// squeeze duplicated replaced chars
	    default:	assert(0);
	}
    }

    if (to is null && !mod_d)
	to = from;

    char[] result = new char[str.length];
    result.length = 0;
    int m;
    dchar lastc;

    foreach (dchar c; str)
    {	dchar lastf;
	dchar lastt;
	dchar newc;
	ptrdiff_t n = 0;

	for (size_t i = 0; i < from.length; )
	{
	    dchar f = std.utf.decode(from, i);
	    //writefln("\tf = '%s', c = '%s', lastf = '%x', '%x', i = %d, %d", f, c, lastf, dchar.init, i, from.length);
	    if (f == '-' && lastf != dchar.init && i < from.length)
	    {
		dchar nextf = std.utf.decode(from, i);
		//writefln("\tlastf = '%s', c = '%s', nextf = '%s'", lastf, c, nextf);
		if (lastf <= c && c <= nextf)
		{
		    n += c - lastf - 1;
		    if (mod_c)
			goto Lnotfound;
		    goto Lfound;
		}
		n += nextf - lastf;
		lastf = lastf.init;
		continue;
	    }

	    if (c == f)
	    {	if (mod_c)
		    goto Lnotfound;
		goto Lfound;
	    }
	    lastf = f;
	    n++;
	}
	if (!mod_c)
	    goto Lnotfound;
	n = 0;			// consider it 'found' at position 0

    Lfound:

	// Find the nth character in to[]
	//writefln("\tc = '%s', n = %d", c, n);
	dchar nextt;
	for (size_t i = 0; i < to.length; )
	{   dchar t = std.utf.decode(to, i);
	    if (t == '-' && lastt != dchar.init && i < to.length)
	    {
		nextt = std.utf.decode(to, i);
		//writefln("\tlastt = '%s', c = '%s', nextt = '%s', n = %d", lastt, c, nextt, n);
		n -= nextt - lastt;
		if (n < 0)
		{
		    newc = nextt + n + 1;
		    goto Lnewc;
		}
		lastt = dchar.init;
		continue;
	    }
	    if (n == 0)
	    {	newc = t;
		goto Lnewc;
	    }
	    lastt = t;
	    nextt = t;
	    n--;
	}
	if (mod_d)
	    continue;
	newc = nextt;

      Lnewc:
	if (mod_s && m && newc == lastc)
	    continue;
	std.utf.encode(result, newc);
	m = 1;
	lastc = newc;
	continue;

      Lnotfound:
	std.utf.encode(result, c);
	lastc = c;
	m = 0;
    }
    return result;
}

unittest
{
    debug(string) printf("std.string.tr.unittest\n");

    char[] r;
    //writefln("r = '%s'", r);

    r = tr("abcdef", "cd", "CD");
    assert(r == "abCDef");

    r = tr("abcdef", "b-d", "B-D");
    assert(r == "aBCDef");

    r = tr("abcdefgh", "b-dh", "B-Dx");
    assert(r == "aBCDefgx");

    r = tr("abcdefgh", "b-dh", "B-CDx");
    assert(r == "aBCDefgx");

    r = tr("abcdefgh", "b-dh", "B-BCDx");
    assert(r == "aBCDefgx");

    r = tr("abcdef", "ef", "*", "c");
    assert(r == "****ef");

    r = tr("abcdef", "ef", "", "d");
    assert(r == "abcd");

    r = tr("hello goodbye", "lo", null, "s");
    assert(r == "helo godbye");

    r = tr("hello goodbye", "lo", "x", "s");
    assert(r == "hex gxdbye");

    r = tr("14-Jul-87", "a-zA-Z", " ", "cs");
    assert(r == " Jul ");

    r = tr("Abc", "AAA", "XYZ");
    assert(r == "Xbc");
}


/* ************************************************
 * Version       : v0.3
 * Author        : David L. 'SpottedTiger' Davis
 * Date Created  : 31.May.05 Compiled and Tested with dmd v0.125
 * Date Modified : 01.Jun.05 Modified the function to handle the
 *               :           imaginary and complex float-point 
 *               :           datatypes.
 *               :
 * Licence       : Public Domain / Contributed to Digital Mars
 */

/**
 * [in] char[] s can be formatted in the following ways:
 *
 * Integer Whole Number:
 * (for byte, ubyte, short, ushort, int, uint, long, and ulong)
 * ['+'|'-']digit(s)[U|L|UL]
 *
 * examples: 123, 123UL, 123L, +123U, -123L
 *
 * Floating-Point Number:
 * (for float, double, real, ifloat, idouble, and ireal)
 * ['+'|'-']digit(s)[.][digit(s)][[e-|e+]digit(s)][i|f|L|Li|fi]]
 *      or [nan|nani|inf|-inf]
 *
 * examples: +123., -123.01, 123.3e-10f, 123.3e-10fi, 123.3e-10L
 * 
 * (for cfloat, cdouble, and creal)
 * ['+'|'-']digit(s)[.][digit(s)][[e-|e+]digit(s)][+]
 *         [digit(s)[.][digit(s)][[e-|e+]digit(s)][i|f|L|Li|fi]]
 *      or [nan|nani|nan+nani|inf|-inf]
 *
 * examples: nan, -123e-1+456.9e-10Li, +123e+10+456i, 123+456
 *
 * [in] bool bAllowSep 
 * False by default, but when set to true it will accept the 
 * separator characters "," and "_" within the string, but these  
 * characters should be stripped from the string before using any 
 * of the conversion functions like toInt(), toFloat(), and etc 
 * else an error will occur.
 *
 * Also please note, that no spaces are allowed within the string  
 * anywhere whether it's a leading, trailing, or embedded space(s), 
 * thus they too must be stripped from the string before using this
 * function, or any of the conversion functions.
 */

final bool isNumeric(in char[] s, in bool bAllowSep = false)
{
    ptrdiff_t iLen = s.length;
    bool   bDecimalPoint = false;
    bool   bExponent = false;
    bool   bComplex = false;
    char[] sx = std.string.tolower(s); 
    int    j  = 0;
    char   c;

    //writefln("isNumeric(char[], bool = false) called!");
    // Empty string, return false
    if (iLen == 0)
        return false;
    
    // Check for NaN (Not a Number)
    if (sx == "nan" || sx == "nani" || sx == "nan+nani")
        return true;
        
    // Check for Infinity
    if (sx == "inf" || sx == "-inf")
        return true;
     
    // A sign is allowed only in the 1st character   
    if (sx[0] == '-' || sx[0] == '+')
        j++;
            
    for (ptrdiff_t i = j; i < iLen; i++)
    {
        c = sx[i];
    
        // Digits are good, continue checking 
        // with the next character... ;)
        if (c >= '0' && c <= '9') 
            continue;

        // Check for the complex type, and if found 
        // reset the flags for checking the 2nd number.  
        else if (c == '+')
            if (i > 0) 
            {
                bDecimalPoint = false;
                bExponent = false;
                bComplex = true;
                continue;
            }
            else
                return false;
                
        // Allow only one exponent per number   
        else if (c == 'e')  
        {
            // A 2nd exponent found, return not a number
            if (bExponent)
                return false;
                
            if (i + 1 < iLen)
            {
                // Look forward for the sign, and if 
                // missing then this is not a number.
                if (sx[i + 1] != '-' && sx[i + 1] != '+')
                    return false;
                else
                {
                    bExponent = true;
                    i++;    
                }    
            }        
            else
                // Ending in "E", return not a number
                return false;        
        }  
        // Allow only one decimal point per number to be used
        else if (c == '.' )
        {
            // A 2nd decimal point found, return not a number
            if (bDecimalPoint)
                return false;
            
            bDecimalPoint = true;
            continue;
        }   
        // Check for ending literal characters: "f,u,l,i,ul,fi,li",
        // and wheater they're being used with the correct datatype.
        else if (i == iLen - 2)
        {
            // Integer Whole Number
            if (sx[i..iLen] == "ul" && 
               (!bDecimalPoint && !bExponent && !bComplex))
                return true;
            // Floating-Point Number
            else if ((sx[i..iLen] == "fi" || sx[i..iLen] == "li") &&
                     (bDecimalPoint || bExponent || bComplex))
                return true;
            else if (sx[i..iLen] == "ul" && 
                    (bDecimalPoint || bExponent || bComplex))
                return false;    
            // Could be a Integer or a Float, thus
            // all these suffixes are valid for both  
            else if (sx[i..iLen] == "ul" || 
                     sx[i..iLen] == "fi" || 
                     sx[i..iLen] == "li")
                return true;
            else    
                return false;
        }
        else if (i == iLen - 1)
        {
            // Integer Whole Number
            if ((c == 'u' || c == 'l') && 
                (!bDecimalPoint && !bExponent && !bComplex))
                return true;
            // Check to see if the last character in the string 
            // is the required 'i' character
            else if (bComplex)
                if (c == 'i')
                    return true;
                else 
                    return false;        
            // Floating-Point Number
            else if ((c == 'l' || c == 'f' || c == 'i') &&
                     (bDecimalPoint || bExponent))
                return true;
            // Could be a Integer or a Float, thus  
            // all these suffixes are valid for both 
            else if (c == 'l' || c == 'f' || c == 'i')
                return true;
            else
                return false;
        }
        else
            // Check if separators are allow  
            // to be in the numeric string
            if (bAllowSep == true && (c == '_' || c == ','))
                continue;
            else    
                return false;       
    }     
    
    return true;
}

/// Allow any object as a parameter
bool isNumeric(...)
{
    return isNumeric(_arguments, _argptr);
}

/// Check only the first parameter, all others will be ignored. 
bool isNumeric(TypeInfo[] _arguments, va_list _argptr)
{
    char[]  s  = "";
    wchar[] ws = "";
    dchar[] ds = "";

    //writefln("isNumeric(...) called!");
    if (_arguments.length == 0)
        return false;

    if (_arguments[0] == typeid(char[]))
        return isNumeric(va_arg!(char[])(_argptr));
    else if (_arguments[0] == typeid(wchar[]))
        return isNumeric(std.utf.toUTF8(va_arg!(wchar[])(_argptr)));
    else if (_arguments[0] == typeid(dchar[]))
        return isNumeric(std.utf.toUTF8(va_arg!(dchar[])(_argptr)));
    else if (_arguments[0] == typeid(real))
        return true;
    else if (_arguments[0] == typeid(double)) 
        return true;   
    else if (_arguments[0] == typeid(float)) 
        return true;  
    else if (_arguments[0] == typeid(ulong)) 
        return true; 
    else if (_arguments[0] == typeid(long)) 
        return true;   
    else if (_arguments[0] == typeid(uint)) 
        return true;  
    else if (_arguments[0] == typeid(int)) 
        return true;   
    else if (_arguments[0] == typeid(ushort)) 
        return true;   
    else if (_arguments[0] == typeid(short)) 
        return true;   
    else if (_arguments[0] == typeid(ubyte)) 
    {
       s.length = 1;
       s[0]= va_arg!(ubyte)(_argptr);
       return isNumeric(cast(char[])s);
    }
    else if (_arguments[0] == typeid(byte)) 
    {
       s.length = 1;
       s[0] = va_arg!(byte)(_argptr);
       return isNumeric(cast(char[])s);
    }
    else if (_arguments[0] == typeid(ireal))
        return true;
    else if (_arguments[0] == typeid(idouble)) 
        return true;   
    else if (_arguments[0] == typeid(ifloat)) 
        return true;  
    else if (_arguments[0] == typeid(creal))
        return true;
    else if (_arguments[0] == typeid(cdouble)) 
        return true;   
    else if (_arguments[0] == typeid(cfloat)) 
        return true;  
    else if (_arguments[0] == typeid(char))
    {
        s.length = 1;
        s[0] = va_arg!(char)(_argptr);
        return isNumeric(s);
    }
    else if (_arguments[0] == typeid(wchar))
    {
        ws.length = 1;
        ws[0] = va_arg!(wchar)(_argptr);
        return isNumeric(std.utf.toUTF8(ws));
    }
    else if (_arguments[0] == typeid(dchar))
    { 
        ds.length =  1;
        ds[0] = va_arg!(dchar)(_argptr);
        return isNumeric(std.utf.toUTF8(ds));
    }
    //else if (_arguments[0] == typeid(cent)) 
    //    return true;   
    //else if (_arguments[0] == typeid(ucent)) 
    //    return true;  
    else       
       return false; 
}

unittest
{
    debug (string) printf("isNumeric(in char[], bool = false).unittest\n");
    char[] s;

    // Test the isNumeric(in char[]) function
    assert(isNumeric("1") == true );
    assert(isNumeric("1.0") == true );
    assert(isNumeric("1e-1") == true );
    assert(isNumeric("12345xxxx890") == false );
    assert(isNumeric("567L") == true );
    assert(isNumeric("23UL") == true );
    assert(isNumeric("-123..56f") == false );
    assert(isNumeric("12.3.5.6") == false );
    assert(isNumeric(" 12.356") == false );
    assert(isNumeric("123 5.6") == false );
    assert(isNumeric("1233E-1+1.0e-1i") == true );
 
    assert(isNumeric("123.00E-5+1234.45E-12Li") == true);
    assert(isNumeric("123.00e-5+1234.45E-12iL") == false);
    assert(isNumeric("123.00e-5+1234.45e-12uL") == false);
    assert(isNumeric("123.00E-5+1234.45e-12lu") == false);
  
    assert(isNumeric("123fi") == true);
    assert(isNumeric("123li") == true);
    assert(isNumeric("--123L") == false);
    assert(isNumeric("+123.5UL") == false);
    assert(isNumeric("123f") == true);
    assert(isNumeric("123.u") == false);

    assert(isNumeric(std.string.toString(real.nan)) == true);
    assert(isNumeric(std.string.toString(-real.infinity)) == true);
    assert(isNumeric(std.string.toString(123e+2+1234.78Li)) == true);

    s = "$250.99-";
    assert(isNumeric(s[1..s.length - 2]) == true);
    assert(isNumeric(s) == false);
    assert(isNumeric(s[0..s.length - 1]) == false);

    // These test calling the isNumeric(...) function
    assert(isNumeric(1,123UL) == true);
    assert(isNumeric('2') == true);
    assert(isNumeric('x') == false);
    assert(isNumeric(cast(byte)0x57) == false); // 'W'
    assert(isNumeric(cast(byte)0x37) == true);  // '7'
    assert(isNumeric(cast(wchar[])"145.67") == true);
    assert(isNumeric(cast(dchar[])"145.67U") == false);
    assert(isNumeric(123_000.23fi) == true);
    assert(isNumeric(123.00E-5+1234.45E-12Li) == true);
    assert(isNumeric(real.nan) == true);
    assert(isNumeric(-real.infinity) == true);
}


/*****************************
 * Soundex algorithm.
 *
 * The Soundex algorithm converts a word into 4 characters
 * based on how the word sounds phonetically. The idea is that
 * two spellings that sound alike will have the same Soundex
 * value, which means that Soundex can be used for fuzzy matching
 * of names.
 *
 * Params:
 *	string = String to convert to Soundex representation.
 *	buffer = Optional 4 char array to put the resulting Soundex
 *		characters into. If null, the return value
 *		buffer will be allocated on the heap.
 * Returns:
 *	The four character array with the Soundex result in it.
 *	Returns null if there is no Soundex representation for the string.
 *
 * See_Also:
 *	$(LINK2 http://en.wikipedia.org/wiki/Soundex, Wikipedia),
 *	$(LINK2 http://www.archives.gov/publications/general-info-leaflets/55.html, The Soundex Indexing System)
 *
 * Bugs:
 *	Only works well with English names.
 *	There are other arguably better Soundex algorithms,
 *	but this one is the standard one.
 */

char[] soundex(char[] string, char[] buffer = null)
in
{
    assert(!buffer || buffer.length >= 4);
}
out (result)
{
    if (result)
    {
	assert(result.length == 4);
	assert(result[0] >= 'A' && result[0] <= 'Z');
	foreach (char c; result[1 .. 4])
	    assert(c >= '0' && c <= '6');
    }
}
body
{
    static char[26] dex =
    // ABCDEFGHIJKLMNOPQRSTUVWXYZ
      "01230120022455012623010202";

    int b = 0;
    char lastc;
    foreach (char c; string)
    {
	if (c >= 'a' && c <= 'z')
	    c -= 'a' - 'A';
	else if (c >= 'A' && c <= 'Z')
	{
	    ;
	}
	else
	{   lastc = lastc.init;
	    continue;
	}
	if (b == 0)
	{
	    if (!buffer)
		buffer = new char[4];
	    buffer[0] = c;
	    b++;
	    lastc = dex[c - 'A'];
	}
	else
	{
	    if (c == 'H' || c == 'W')
		continue;
	    if (c == 'A' || c == 'E' || c == 'I' || c == 'O' || c == 'U')
		lastc = lastc.init;
	    c = dex[c - 'A'];
	    if (c != '0' && c != lastc)
	    {
		buffer[b] = c;
		b++;
		lastc = c;
	    }
	}
	if (b == 4)
	    goto Lret;
    }
    if (b == 0)
	buffer = null;
    else
	buffer[b .. 4] = '0';
Lret:
    return buffer;
}

unittest
{   char[4] buffer;

    assert(soundex(null) == null);
    assert(soundex("") == null);
    assert(soundex("0123^&^^**&^") == null);
    assert(soundex("Euler") == "E460");
    assert(soundex(" Ellery ") == "E460");
    assert(soundex("Gauss") == "G200");
    assert(soundex("Ghosh") == "G200");
    assert(soundex("Hilbert") == "H416");
    assert(soundex("Heilbronn") == "H416");
    assert(soundex("Knuth") == "K530");
    assert(soundex("Kant", buffer) == "K530");
    assert(soundex("Lloyd") == "L300");
    assert(soundex("Ladd") == "L300");
    assert(soundex("Lukasiewicz", buffer) == "L222");
    assert(soundex("Lissajous") == "L222");
    assert(soundex("Robert") == "R163");
    assert(soundex("Rupert") == "R163");
    assert(soundex("Rubin") == "R150");
    assert(soundex("Washington") == "W252");
    assert(soundex("Lee") == "L000");
    assert(soundex("Gutierrez") == "G362");
    assert(soundex("Pfister") == "P236");
    assert(soundex("Jackson") == "J250");
    assert(soundex("Tymczak") == "T522");
    assert(soundex("Ashcraft") == "A261");

    assert(soundex("Woo") == "W000");
    assert(soundex("Pilgrim") == "P426");
    assert(soundex("Flingjingwaller") == "F452");
    assert(soundex("PEARSE") == "P620");
    assert(soundex("PIERCE") == "P620");
    assert(soundex("Price") == "P620");
    assert(soundex("CATHY") == "C300");
    assert(soundex("KATHY") == "K300");
    assert(soundex("Jones") == "J520");
    assert(soundex("johnsons") == "J525");
    assert(soundex("Hardin") == "H635");
    assert(soundex("Martinez") == "M635");
}


/***************************************************
 * Construct an associative array consisting of all
 * abbreviations that uniquely map to the strings in values.
 *
 * This is useful in cases where the user is expected to type
 * in one of a known set of strings, and the program will helpfully
 * autocomplete the string once sufficient characters have been
 * entered that uniquely identify it.
 * Example:
 * ---
 * import std.stdio;
 * import std.string;
 * 
 * void main()
 * {
 *    static char[][] list = [ "food", "foxy" ];
 * 
 *    auto abbrevs = std.string.abbrev(list);
 * 
 *    foreach (key, value; abbrevs)
 *    {
 *       writefln("%s => %s", key, value);
 *    }
 * }
 * ---
 * produces the output:
 * <pre>
 * fox =&gt; foxy
 * food =&gt; food
 * foxy =&gt; foxy
 * foo =&gt; food
 * </pre>
 */

char[][char[]] abbrev(char[][] values)
{
    char[][char[]] result;

    // Make a copy when sorting so we follow COW principles.
    values = values.dup.sort;

    size_t values_length = values.length;
    size_t lasti = values_length;
    size_t nexti;

    char[] nv;
    char[] lv;

    for (size_t i = 0; i < values_length; i = nexti)
    {	char[] value = values[i];

	// Skip dups
	for (nexti = i + 1; nexti < values_length; nexti++)
	{   nv = values[nexti];
	    if (value != values[nexti])
		break;
	}

	for (size_t j = 0; j < value.length; j += std.utf.stride(value, j))
	{   char[] v = value[0 .. j];

	    if ((nexti == values_length || j > nv.length || v != nv[0 .. j]) &&
		(lasti == values_length || j > lv.length || v != lv[0 .. j]))
		result[v] = value;
	}
	result[value] = value;
	lasti = i;
	lv = value;
    }

    return result;
}

unittest
{
    debug(string) printf("string.abbrev.unittest\n");

    char[][] values;
    values ~= "hello";
    values ~= "hello";
    values ~= "he";

    char[][char[]] r;

    r = abbrev(values);
    char[][] keys = r.keys.dup;
    keys.sort;

    assert(keys.length == 4);
    assert(keys[0] == "he");
    assert(keys[1] == "hel");
    assert(keys[2] == "hell");
    assert(keys[3] == "hello");

    assert(r[keys[0]] == "he");
    assert(r[keys[1]] == "hello");
    assert(r[keys[2]] == "hello");
    assert(r[keys[3]] == "hello");
}


/******************************************
 * Compute column number after string if string starts in the
 * leftmost column, which is numbered starting from 0.
 */

size_t column(char[] string, ptrdiff_t tabsize = 8)
{
    size_t column;

    foreach (dchar c; string)
    {
	switch (c)
	{
	    case '\t':
		column = (column + tabsize) / tabsize * tabsize;
		break;

	    case '\r':
	    case '\n':
	    case PS:
	    case LS:
		column = 0;
		break;

	    default:
		column++;
		break;
	}
    }
    return column;
}

unittest
{
    debug(string) printf("string.column.unittest\n");

    assert(column(null) == 0);
    assert(column("") == 0);
    assert(column("\t") == 8);
    assert(column("abc\t") == 8);
    assert(column("12345678\t") == 16);
}

/******************************************
 * Wrap text into a paragraph.
 *
 * The input text string s is formed into a paragraph
 * by breaking it up into a sequence of lines, delineated
 * by \n, such that the number of columns is not exceeded
 * on each line.
 * The last line is terminated with a \n.
 * Params:
 *	s = text string to be wrapped
 *	columns = maximum number of _columns in the paragraph
 *	firstindent = string used to _indent first line of the paragraph
 *	indent = string to use to _indent following lines of the paragraph
 *	tabsize = column spacing of tabs
 * Returns:
 *	The resulting paragraph.
 */

char[] wrap(char[] s, ptrdiff_t columns = 80, char[] firstindent = null,
	char[] indent = null, ptrdiff_t tabsize = 8)
{
    char[] result;
    ptrdiff_t col;
    ptrdiff_t spaces;
    bool inword;
    bool first = true;
    size_t wordstart;

    result.length = firstindent.length + s.length;
    result.length = firstindent.length;
    result[] = firstindent[];
    col = column(result, tabsize);
    foreach (size_t i, dchar c; s)
    {
	if (iswhite(c))
	{
	    if (inword)
	    {
		if (first)
		{
		    ;
		}
		else if (col + 1 + (i - wordstart) > columns)
		{
		    result ~= '\n';
		    result ~= indent;
		    col = column(indent, tabsize);
		}
		else
		{   result ~= ' ';
		    col += 1;
		}
		result ~= s[wordstart .. i];
		col += i - wordstart;
		inword = false;
		first = false;
	    }
	}
	else
	{
	    if (!inword)
	    {
		wordstart = i;
		inword = true;
	    }
	}
    }

    if (inword)
    {
	if (col + 1 + (s.length - wordstart) >= columns)
	{
	    result ~= '\n';
	    result ~= indent;
	}
	else if (result.length != firstindent.length)
	    result ~= ' ';
	result ~= s[wordstart .. s.length];
    }
    result ~= '\n';

    return result;
}

unittest
{
    debug(string) printf("string.wrap.unittest\n");

    assert(wrap(null) == "\n");
    assert(wrap(" a b   df ") == "a b df\n");
    //writefln("'%s'", wrap(" a b   df ",3));
    assert(wrap(" a b   df ", 3) == "a b\ndf\n");
    assert(wrap(" a bc   df ", 3) == "a\nbc\ndf\n");
    //writefln("'%s'", wrap(" abcd   df ",3));
    assert(wrap(" abcd   df ", 3) == "abcd\ndf\n");
    assert(wrap("x") == "x\n");
    assert(wrap("u u") == "u u\n");
}


/***************************
 * Does string s[] start with an email address?
 * Returns:
 *	null	it does not
 *	char[]	it does, and this is the slice of s[] that is that email address
 * References:
 *	RFC2822
 */
char[] isEmail(char[] s)
{   size_t i;

    if (!isalpha(s[0]))
	goto Lno;

    for (i = 1; 1; i++)
    {
	if (i == s.length)
	    goto Lno;
	auto c = s[i];
	if (isalnum(c))
	    continue;
	if (c == '-' || c == '_' || c == '.')
	    continue;
	if (c != '@')
	    goto Lno;
	i++;
	break;
    }
    //writefln("test1 '%s'", s[0 .. i]);

    /* Now do the part past the '@'
     */
    size_t lastdot;
    for (; i < s.length; i++)
    {
	auto c = s[i];
	if (isalnum(c))
	    continue;
	if (c == '-' || c == '_')
	    continue;
	if (c == '.')
	{
	    lastdot = i;
	    continue;
	}
	break;
    }
    if (!lastdot || (i - lastdot != 3 && i - lastdot != 4))
	goto Lno;

    return s[0 .. i];

Lno:
    return null;
}


/***************************
 * Does string s[] start with a URL?
 * Returns:
 *	null	it does not
 *	char[]	it does, and this is the slice of s[] that is that URL
 */

char[] isURL(char[] s)
{
    /* Must start with one of:
     *	http://
     *	https://
     *	www.
     */

    size_t i;

    if (s.length <= 4)
	goto Lno;

    //writefln("isURL(%s)", s);
    if (s.length > 7 && std.string.icmp(s[0 .. 7], "http://") == 0)
	i = 7;
    else if (s.length > 8 && std.string.icmp(s[0 .. 8], "https://") == 0)
	i = 8;
//    if (icmp(s[0 .. 4], "www.") == 0)
//	i = 4;
    else
	goto Lno;

    size_t lastdot;
    for (; i < s.length; i++)
    {
	auto c = s[i];
	if (isalnum(c))
	    continue;
	if (c == '-' || c == '_' || c == '?' ||
	    c == '=' || c == '%' || c == '&' ||
	    c == '/' || c == '+' || c == '#' ||
	    c == '~')
	    continue;
	if (c == '.')
	{
	    lastdot = i;
	    continue;
	}
	break;
    }
    //if (!lastdot || (i - lastdot != 3 && i - lastdot != 4))
    if (!lastdot)
	goto Lno;

    return s[0 .. i];

Lno:
    return null;
}


