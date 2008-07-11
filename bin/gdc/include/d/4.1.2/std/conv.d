
// Written in the D programming language.

/*
 *  Copyright (C) 2002-2006 by Digital Mars, www.digitalmars.com
 *  Written by Walter Bright
 *  Some parts contributed by David L. Davis
 *
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, subject to the following restrictions:
 *
 *  o  The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  o  Altered source versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *  o  This notice may not be removed or altered from any source
 *     distribution.
 */

/***********
 * Conversion building blocks. These differ from the C equivalents
 * <tt>atoi()</tt> and <tt>atol()</tt> by
 * checking for overflow and not allowing whitespace.
 *
 * For conversion to signed types, the grammar recognized is:
 * <pre>
$(I Integer):
    $(I Sign UnsignedInteger)
    $(I UnsignedInteger)

$(I Sign):
    $(B +)
    $(B -)
 * </pre>
 * For conversion to signed types, the grammar recognized is:
 * <pre>
$(I UnsignedInteger):
    $(I DecimalDigit)
    $(I DecimalDigit) $(I UnsignedInteger)
 * </pre>
 * Macros:
 *	WIKI=Phobos/StdConv
 */

module std.conv;

private import std.string;  // for atof(), toString()
private import std.c.stdlib;
private import std.math;  // for fabs(), isnan()
private import std.stdio; // for writefln() and printf()


//debug=conv;		// uncomment to turn on debugging printf's

/* ************* Exceptions *************** */

/**
 * Thrown on conversion errors, which happens on deviation from the grammar.
 */
class ConvError : Error
{
    this(char[] s)
    {
	super("conversion " ~ s);
    }
}

private void conv_error(char[] s)
{
    throw new ConvError(s);
}

/**
 * Thrown on conversion overflow errors.
 */
class ConvOverflowError : Error
{
    this(char[] s)
    {
	super("Error: overflow " ~ s);
    }
}

private void conv_overflow(char[] s)
{
    throw new ConvOverflowError(s);
}

/***************************************************************
 * Convert character string to the return type.
 */

int toInt(char[] s)
{
    int length = s.length;

    if (!length)
	goto Lerr;

    int sign = 0;
    uint v = 0;

    for (int i = 0; i < length; i++)
    {
	char c = s[i];
	if (c >= '0' && c <= '9')
	{
	    if (v < int.max/10 || (v == int.max/10 && c + sign <= '7'))
		v = v * 10 + (c - '0');
	    else
		goto Loverflow;
	}
	else if (c == '-' && i == 0)
	{
	    sign = -1;
	    if (length == 1)
		goto Lerr;
	}
	else if (c == '+' && i == 0)
	{
	    if (length == 1)
		goto Lerr;
	}
	else
	    goto Lerr;
    }
    if (sign == -1)
    {
	if (v > 0x80000000)
	    goto Loverflow;
	v = -v;
    }
    else
    {
	if (v > 0x7FFFFFFF)
	    goto Loverflow;
    }
    return v;

Loverflow:
    conv_overflow(s);

Lerr:
    conv_error(s);
    return 0;
}

unittest
{
    debug(conv) printf("conv.toInt.unittest\n");

    int i;

    i = toInt("0");
    assert(i == 0);

    i = toInt("+0");
    assert(i == 0);

    i = toInt("-0");
    assert(i == 0);

    i = toInt("6");
    assert(i == 6);

    i = toInt("+23");
    assert(i == 23);

    i = toInt("-468");
    assert(i == -468);

    i = toInt("2147483647");
    assert(i == 0x7FFFFFFF);

    i = toInt("-2147483648");
    assert(i == 0x80000000);

    static char[][] errors =
    [
	"",
	"-",
	"+",
	"-+",
	" ",
	" 0",
	"0 ",
	"- 0",
	"1-",
	"xx",
	"123h",
	"2147483648",
	"-2147483649",
	"5656566565",
    ];

    for (int j = 0; j < errors.length; j++)
    {
	i = 47;
	try
	{
	    i = toInt(errors[j]);
	    printf("i = %d\n", i);
	}
	catch (Error e)
	{
	    debug(conv) e.print();
	    i = 3;
	}
	assert(i == 3);
    }
}


/*******************************************************
 * ditto
 */

uint toUint(char[] s)
{
    int length = s.length;

    if (!length)
	goto Lerr;

    uint v = 0;

    for (int i = 0; i < length; i++)
    {
	char c = s[i];
	if (c >= '0' && c <= '9')
	{
	    if (v < uint.max/10 || (v == uint.max/10 && c <= '5'))
		v = v * 10 + (c - '0');
	    else
		goto Loverflow;
	}
	else
	    goto Lerr;
    }
    return v;

Loverflow:
    conv_overflow(s);

Lerr:
    conv_error(s);
    return 0;
}

unittest
{
    debug(conv) printf("conv.toUint.unittest\n");

    uint i;

    i = toUint("0");
    assert(i == 0);

    i = toUint("6");
    assert(i == 6);

    i = toUint("23");
    assert(i == 23);

    i = toUint("468");
    assert(i == 468);

    i = toUint("2147483647");
    assert(i == 0x7FFFFFFF);

    i = toUint("4294967295");
    assert(i == 0xFFFFFFFF);

    static char[][] errors =
    [
	"",
	"-",
	"+",
	"-+",
	" ",
	" 0",
	"0 ",
	"- 0",
	"1-",
	"+5",
	"-78",
	"xx",
	"123h",
	"4294967296",
    ];

    for (int j = 0; j < errors.length; j++)
    {
	i = 47;
	try
	{
	    i = toUint(errors[j]);
	    printf("i = %d\n", i);
	}
	catch (Error e)
	{
	    debug(conv) e.print();
	    i = 3;
	}
	assert(i == 3);
    }
}

/*******************************************************
 * ditto
 */

long toLong(char[] s)
{
    int length = s.length;

    if (!length)
	goto Lerr;

    int sign = 0;
    ulong v = 0;

    for (int i = 0; i < length; i++)
    {
	char c = s[i];
	if (c >= '0' && c <= '9')
	{
	    if (v < long.max/10 || (v == long.max/10 && c + sign <= '7'))
		v = v * 10 + (c - '0');
	    else
		goto Loverflow;
	}
	else if (c == '-' && i == 0)
	{
	    sign = -1;
	    if (length == 1)
		goto Lerr;
	}
	else if (c == '+' && i == 0)
	{
	    if (length == 1)
		goto Lerr;
	}
	else
	    goto Lerr;
    }
    if (sign == -1)
    {
	if (v > 0x8000000000000000)
	    goto Loverflow;
	v = -v;
    }
    else
    {
	if (v > 0x7FFFFFFFFFFFFFFF)
	    goto Loverflow;
    }
    return v;

Loverflow:
    conv_overflow(s);

Lerr:
    conv_error(s);
    return 0;
}

unittest
{
    debug(conv) printf("conv.toLong.unittest\n");

    long i;

    i = toLong("0");
    assert(i == 0);

    i = toLong("+0");
    assert(i == 0);

    i = toLong("-0");
    assert(i == 0);

    i = toLong("6");
    assert(i == 6);

    i = toLong("+23");
    assert(i == 23);

    i = toLong("-468");
    assert(i == -468);

    i = toLong("2147483647");
    assert(i == 0x7FFFFFFF);

    i = toLong("-2147483648");
    assert(i == -0x80000000L);

    i = toLong("9223372036854775807");
    assert(i == 0x7FFFFFFFFFFFFFFF);

    i = toLong("-9223372036854775808");
    assert(i == 0x8000000000000000);

    static char[][] errors =
    [
	"",
	"-",
	"+",
	"-+",
	" ",
	" 0",
	"0 ",
	"- 0",
	"1-",
	"xx",
	"123h",
	"9223372036854775808",
	"-9223372036854775809",
    ];

    for (int j = 0; j < errors.length; j++)
    {
	i = 47;
	try
	{
	    i = toLong(errors[j]);
	    printf("l = %d\n", i);
	}
	catch (Error e)
	{
	    debug(conv) e.print();
	    i = 3;
	}
	assert(i == 3);
    }
}


/*******************************************************
 * ditto
 */

ulong toUlong(char[] s)
{
    int length = s.length;

    if (!length)
	goto Lerr;

    ulong v = 0;

    for (int i = 0; i < length; i++)
    {
	char c = s[i];
	if (c >= '0' && c <= '9')
	{
	    if (v < ulong.max/10 || (v == ulong.max/10 && c <= '5'))
		v = v * 10 + (c - '0');
	    else
		goto Loverflow;
	}
	else
	    goto Lerr;
    }
    return v;

Loverflow:
    conv_overflow(s);

Lerr:
    conv_error(s);
    return 0;
}

unittest
{
    debug(conv) printf("conv.toUlong.unittest\n");

    ulong i;

    i = toUlong("0");
    assert(i == 0);

    i = toUlong("6");
    assert(i == 6);

    i = toUlong("23");
    assert(i == 23);

    i = toUlong("468");
    assert(i == 468);

    i = toUlong("2147483647");
    assert(i == 0x7FFFFFFF);

    i = toUlong("4294967295");
    assert(i == 0xFFFFFFFF);

    i = toUlong("9223372036854775807");
    assert(i == 0x7FFFFFFFFFFFFFFF);

    i = toUlong("18446744073709551615");
    assert(i == 0xFFFFFFFFFFFFFFFF);


    static char[][] errors =
    [
	"",
	"-",
	"+",
	"-+",
	" ",
	" 0",
	"0 ",
	"- 0",
	"1-",
	"+5",
	"-78",
	"xx",
	"123h",
	"18446744073709551616",
    ];

    for (int j = 0; j < errors.length; j++)
    {
	i = 47;
	try
	{
	    i = toUlong(errors[j]);
	    printf("i = %d\n", i);
	}
	catch (Error e)
	{
	    debug(conv) e.print();
	    i = 3;
	}
	assert(i == 3);
    }
}


/*******************************************************
 * ditto
 */

short toShort(char[] s)
{
    int v = toInt(s);

    if (v != cast(short)v)
	goto Loverflow;

    return cast(short)v;

Loverflow:
    conv_overflow(s);
    return 0;
}

unittest
{
    debug(conv) printf("conv.toShort.unittest\n");

    short i;

    i = toShort("0");
    assert(i == 0);

    i = toShort("+0");
    assert(i == 0);

    i = toShort("-0");
    assert(i == 0);

    i = toShort("6");
    assert(i == 6);

    i = toShort("+23");
    assert(i == 23);

    i = toShort("-468");
    assert(i == -468);

    i = toShort("32767");
    assert(i == 0x7FFF);

    i = toShort("-32768");
    assert(i == cast(short)0x8000);

    static char[][] errors =
    [
	"",
	"-",
	"+",
	"-+",
	" ",
	" 0",
	"0 ",
	"- 0",
	"1-",
	"xx",
	"123h",
	"32768",
	"-32769",
    ];

    for (int j = 0; j < errors.length; j++)
    {
	i = 47;
	try
	{
	    i = toShort(errors[j]);
	    printf("i = %d\n", i);
	}
	catch (Error e)
	{
	    debug(conv) e.print();
	    i = 3;
	}
	assert(i == 3);
    }
}


/*******************************************************
 * ditto
 */

ushort toUshort(char[] s)
{
    uint v = toUint(s);

    if (v != cast(ushort)v)
	goto Loverflow;

    return cast(ushort)v;

Loverflow:
    conv_overflow(s);
    return 0;
}

unittest
{
    debug(conv) printf("conv.toUshort.unittest\n");

    ushort i;

    i = toUshort("0");
    assert(i == 0);

    i = toUshort("6");
    assert(i == 6);

    i = toUshort("23");
    assert(i == 23);

    i = toUshort("468");
    assert(i == 468);

    i = toUshort("32767");
    assert(i == 0x7FFF);

    i = toUshort("65535");
    assert(i == 0xFFFF);

    static char[][] errors =
    [
	"",
	"-",
	"+",
	"-+",
	" ",
	" 0",
	"0 ",
	"- 0",
	"1-",
	"+5",
	"-78",
	"xx",
	"123h",
	"65536",
    ];

    for (int j = 0; j < errors.length; j++)
    {
	i = 47;
	try
	{
	    i = toUshort(errors[j]);
	    printf("i = %d\n", i);
	}
	catch (Error e)
	{
	    debug(conv) e.print();
	    i = 3;
	}
	assert(i == 3);
    }
}


/*******************************************************
 * ditto
 */

byte toByte(char[] s)
{
    int v = toInt(s);

    if (v != cast(byte)v)
	goto Loverflow;

    return cast(byte)v;

Loverflow:
    conv_overflow(s);
    return 0;
}

unittest
{
    debug(conv) printf("conv.toByte.unittest\n");

    byte i;

    i = toByte("0");
    assert(i == 0);

    i = toByte("+0");
    assert(i == 0);

    i = toByte("-0");
    assert(i == 0);

    i = toByte("6");
    assert(i == 6);

    i = toByte("+23");
    assert(i == 23);

    i = toByte("-68");
    assert(i == -68);

    i = toByte("127");
    assert(i == 0x7F);

    i = toByte("-128");
    assert(i == cast(byte)0x80);

    static char[][] errors =
    [
	"",
	"-",
	"+",
	"-+",
	" ",
	" 0",
	"0 ",
	"- 0",
	"1-",
	"xx",
	"123h",
	"128",
	"-129",
    ];

    for (int j = 0; j < errors.length; j++)
    {
	i = 47;
	try
	{
	    i = toByte(errors[j]);
	    printf("i = %d\n", i);
	}
	catch (Error e)
	{
	    debug(conv) e.print();
	    i = 3;
	}
	assert(i == 3);
    }
}


/*******************************************************
 * ditto
 */

ubyte toUbyte(char[] s)
{
    uint v = toUint(s);

    if (v != cast(ubyte)v)
	goto Loverflow;

    return cast(ubyte)v;

Loverflow:
    conv_overflow(s);
    return 0;
}

unittest
{
    debug(conv) printf("conv.toUbyte.unittest\n");

    ubyte i;

    i = toUbyte("0");
    assert(i == 0);

    i = toUbyte("6");
    assert(i == 6);

    i = toUbyte("23");
    assert(i == 23);

    i = toUbyte("68");
    assert(i == 68);

    i = toUbyte("127");
    assert(i == 0x7F);

    i = toUbyte("255");
    assert(i == 0xFF);

    static char[][] errors =
    [
	"",
	"-",
	"+",
	"-+",
	" ",
	" 0",
	"0 ",
	"- 0",
	"1-",
	"+5",
	"-78",
	"xx",
	"123h",
	"256",
    ];

    for (int j = 0; j < errors.length; j++)
    {
	i = 47;
	try
	{
	    i = toUbyte(errors[j]);
	    printf("i = %d\n", i);
	}
	catch (Error e)
	{
	    debug(conv) e.print();
	    i = 3;
	}
	assert(i == 3);
    }
}


/*******************************************************
 * ditto
 */

version (skyos)
{
    float strtof(char * s, char ** ep) {
	return strtod(s, ep);
    }
}

static if (real.sizeof > double.sizeof)
    private alias strtold _conv_strtold;
else
    private alias strtod _conv_strtold;

float toFloat(in char[] s)
{
    float f;
    char* endptr;
    char* sz;

    //writefln("toFloat('%s')", s);
    version (aix)
	s = toupper(s);
    sz = toStringz(s);
    if (std.ctype.isspace(*sz))
	goto Lerr;

    // BUG: should set __locale_decpoint to "." for DMC

    setErrno(0);
    f = strtof(sz, &endptr);
    if (getErrno() == ERANGE)
	goto Lerr;
    if (endptr && (endptr == sz || *endptr != 0))
	goto Lerr;

    return f;
        
  Lerr:
    conv_error(s ~ " not representable as a float");
    assert(0);
}
 
unittest
{
    debug( conv ) writefln( "conv.toFloat.unittest" );
    float f;
    
    f = toFloat( "123" );
    assert( f == 123f );
    f = toFloat( "+123" );
    assert( f == +123f );
    f = toFloat( "-123" );
    assert( f == -123f );
    f = toFloat( "123e+2" );
    assert( f == 123e+2f );

    f = toFloat( "123e-2" );
    assert( f == 123e-2f );
    f = toFloat( "123." );
    assert( f == 123.f );
    f = toFloat( ".456" );
    assert( f == .456f );
    
    // min and max
    f = toFloat("1.17549e-38");
    assert(feq(cast(real)f, cast(real)1.17549e-38));
    assert(feq(cast(real)f, cast(real)float.min));
    f = toFloat("3.40282e+38");
    assert(toString(f) == toString(3.40282e+38));

    // nan
    f = toFloat("nan");
    assert(toString(f) == toString(float.nan));

    bool ok = false;
    try
    {
	toFloat("\x00");
    }
    catch (ConvError e)
    {
	ok = true;
    }
    assert(ok);
}

/*******************************************************
 * ditto
 */

double toDouble(in char[] s)
{
    double f;
    char* endptr;
    char* sz;

    //writefln("toDouble('%s')", s);
    version (aix)
	s = toupper(s);
    sz = toStringz(s);
    if (std.ctype.isspace(*sz))
	goto Lerr;

    // BUG: should set __locale_decpoint to "." for DMC

    setErrno(0);
    f = strtod(sz, &endptr);
    if (getErrno() == ERANGE)
	goto Lerr;
    if (endptr && (endptr == sz || *endptr != 0))
	goto Lerr;

    return f;
        
  Lerr:
    conv_error(s ~ " not representable as a double");
    assert(0);
}

unittest
{
    debug( conv ) writefln( "conv.toDouble.unittest" );
    double d;

    d = toDouble( "123" );
    assert( d == 123 );
    d = toDouble( "+123" );
    assert( d == +123 );
    d = toDouble( "-123" );
    assert( d == -123 );
    d = toDouble( "123e2" );
    assert( d == 123e2);
    d = toDouble( "123e-2" );
    assert( d == 123e-2 );
    d = toDouble( "123." );
    assert( d == 123. );
    d = toDouble( ".456" );
    assert( d == .456 );
    d = toDouble( "1.23456E+2" );
    assert( d == 1.23456E+2 );

    // min and max
    d = toDouble("2.22507e-308");
    assert(feq(cast(real)d, cast(real)2.22507e-308));
    assert(feq(cast(real)d, cast(real)double.min));
    d = toDouble("1.79769e+308");
    assert(toString(d) == toString(1.79769e+308));
    assert(toString(d) == toString(double.max));

    // nan
    d = toDouble("nan");
    assert(toString(d) == toString(double.nan));
    //assert(cast(real)d == cast(real)double.nan);

    bool ok = false;
    try
    {
	toDouble("\x00");
    }
    catch (ConvError e)
    {
	ok = true;
    }
    assert(ok);
}

/*******************************************************
 * ditto
 */
real toReal(in char[] s)
{
    real f;
    char* endptr;
    char* sz;

    //writefln("toReal('%s')", s);
    version (aix)
	s = toupper(s);
    sz = toStringz(s);
    if (std.ctype.isspace(*sz))
	goto Lerr;

    // BUG: should set __locale_decpoint to "." for DMC

    setErrno(0);
    f = _conv_strtold(sz, &endptr);
    if (getErrno() == ERANGE)
	goto Lerr;
    if (endptr && (endptr == sz || *endptr != 0))
	goto Lerr;

    return f;
        
  Lerr:
    conv_error(s ~ " not representable as a real");
    assert(0);
}

unittest
{
    debug(conv) writefln("conv.toReal.unittest");
    real r;

    r = toReal("123");
    assert(r == 123L);
    r = toReal("+123");
    assert(r == 123L);
    r = toReal("-123");
    assert(r == -123L);
    r = toReal("123e2");
    assert(feq(r, 123e2L));
    r = toReal("123e-2");
    assert(feq(r, 1.23L));
    r = toReal("123.");
    assert(r == 123L);
    r = toReal(".456");
    assert(r == .456L);

    r = toReal("1.23456e+2");
    assert(feq(r,  1.23456e+2L));
    r = toReal(toString(real.max / 2L));
    assert(toString(r) == toString(real.max / 2L));

    // min and max
    r = toReal(toString(real.min));
    assert(toString(r) == toString(real.min));
    r = toReal(toString(real.max));
    assert(toString(r) == toString(real.max));

    // nan
    r = toReal("nan");
    assert(toString(r) == toString(real.nan));
    //assert(r == real.nan);

    r = toReal(toString(real.nan));
    assert(toString(r) == toString(real.nan));
    //assert(r == real.nan);

    bool ok = false;
    try
    {
	toReal("\x00");
    }
    catch (ConvError e)
    {
	ok = true;
    }
    assert(ok);
}

version (none)
{   /* These are removed for the moment because of concern about
     * what to do about the 'i' suffix. Should it be there?
     * Should it not? What about 'nan', should it be 'nani'?
     * 'infinity' or 'infinityi'?
     * Should it match what toString(ifloat) does with the 'i' suffix?
     */

/*******************************************************
 * ditto
 */

ifloat toIfloat(in char[] s)
{
    return toFloat(s) * 1.0i;
}

unittest
{
    debug(conv) writefln("conv.toIfloat.unittest");
    ifloat ift;
    
    ift = toIfloat(toString(123.45));
    assert(toString(ift) == toString(123.45i));

    ift = toIfloat(toString(456.77i));
    assert(toString(ift) == toString(456.77i));

    // min and max
    ift = toIfloat(toString(ifloat.min));
    assert(toString(ift) == toString(ifloat.min) );
    assert(feq(cast(ireal)ift, cast(ireal)ifloat.min));

    ift = toIfloat(toString(ifloat.max));
    assert(toString(ift) == toString(ifloat.max));
    assert(feq(cast(ireal)ift, cast(ireal)ifloat.max));
   
    // nan
    ift = toIfloat("nani");
    assert(cast(real)ift == cast(real)ifloat.nan);

    ift = toIfloat(toString(ifloat.nan));
    assert(toString(ift) == toString(ifloat.nan));
    assert(feq(cast(ireal)ift, cast(ireal)ifloat.nan));
}

/*******************************************************
 * ditto
 */

idouble toIdouble(in char[] s)
{
    return toDouble(s) * 1.0i;
}

unittest
{
    debug(conv) writefln("conv.toIdouble.unittest");
    idouble id;

    id = toIdouble(toString("123.45"));
    assert(id == 123.45i);

    id = toIdouble(toString("123.45e+302i"));
    assert(id == 123.45e+302i);

    // min and max
    id = toIdouble(toString(idouble.min));
    assert(toString( id ) == toString(idouble.min));
    assert(feq(cast(ireal)id.re, cast(ireal)idouble.min.re));
    assert(feq(cast(ireal)id.im, cast(ireal)idouble.min.im));
    
    id = toIdouble(toString(idouble.max));
    assert(toString(id) == toString(idouble.max));
    assert(feq(cast(ireal)id.re, cast(ireal)idouble.max.re));
    assert(feq(cast(ireal)id.im, cast(ireal)idouble.max.im));
    
    // nan
    id = toIdouble("nani");
    assert(cast(real)id == cast(real)idouble.nan);

    id = toIdouble(toString(idouble.nan));
    assert(toString(id) == toString(idouble.nan));
}

/*******************************************************
 * ditto
 */

ireal toIreal(in char[] s)
{
    return toReal(s) * 1.0i;
}

unittest
{
    debug(conv) writefln("conv.toIreal.unittest");
    ireal ir;

    ir = toIreal(toString("123.45"));
    assert(feq(cast(real)ir.re, cast(real)123.45i)); 

    ir = toIreal(toString("123.45e+82i"));
    assert(toString(ir) == toString(123.45e+82i));
    //assert(ir == 123.45e+82i);

    // min and max
    ir = toIreal(toString(ireal.min));
    assert(toString(ir) == toString(ireal.min));
    assert(feq(cast(real)ir.re, cast(real)ireal.min.re));
    assert(feq(cast(real)ir.im, cast(real)ireal.min.im));

    ir = toIreal(toString(ireal.max));
    assert(toString(ir) == toString(ireal.max));
    assert(feq(cast(real)ir.re, cast(real)ireal.max.re));
    //assert(feq(cast(real)ir.im, cast(real)ireal.max.im));

    // nan
    ir = toIreal("nani");
    assert(cast(real)ir == cast(real)ireal.nan);

    ir = toIreal(toString(ireal.nan));
    assert(toString(ir) == toString(ireal.nan));
}


/*******************************************************
 * ditto
 */
cfloat toCfloat(in char[] s)
{
    char[] s1;
    char[] s2;
    real   r1;
    real   r2;
    cfloat cf;
    bool    b = 0;
    char*  endptr;

    if (!s.length)
        goto Lerr;
    
    b = getComplexStrings(s, s1, s2);

    if (!b)
        goto Lerr;
    
    // atof(s1);
    endptr = &s1[s1.length - 1];
    r1 = _conv_strtold(s1, &endptr); 

    // atof(s2);
    endptr = &s2[s2.length - 1];
    r2 = _conv_strtold(s2, &endptr); 

    cf = cast(cfloat)(r1 + (r2 * 1.0i));

    //writefln( "toCfloat() r1=%g, r2=%g, cf=%g, max=%g", 
    //           r1, r2, cf, cfloat.max);
    // Currently disabled due to a posted bug where a 
    // complex float greater-than compare to .max compares 
    // incorrectly.
    //if (cf > cfloat.max)
    //    goto Loverflow;

    return cf;

    Loverflow:
        conv_overflow(s);
        
    Lerr:
        conv_error(s);
        return cast(cfloat)0.0e-0+0i;   
}

unittest
{
    debug(conv) writefln("conv.toCfloat.unittest");
    cfloat cf;

    cf = toCfloat(toString("1.2345e-5+0i"));
    assert(toString(cf) == toString(1.2345e-5+0i));
    assert(feq(cf, 1.2345e-5+0i));

    // min and max
    cf = toCfloat(toString(cfloat.min));
    assert(toString(cf) == toString(cfloat.min));

    cf = toCfloat(toString(cfloat.max));
    assert(toString(cf) == toString(cfloat.max));
   
    // nan ( nan+nani )
    cf = toCfloat("nani");
    //writefln("toCfloat() cf=%g, cf=\"%s\", nan=%s", 
    //         cf, toString(cf), toString(cfloat.nan));
    assert(toString(cf) == toString(cfloat.nan));

    cf = toCdouble("nan+nani");
    assert(toString(cf) == toString(cfloat.nan));

    cf = toCfloat(toString(cfloat.nan));
    assert(toString(cf) == toString(cfloat.nan));
    assert(feq(cast(creal)cf, cast(creal)cfloat.nan));
}

/*******************************************************
 * ditto
 */
cdouble toCdouble(in char[] s)
{
    char[]  s1;
    char[]  s2;
    real    r1;
    real    r2;
    cdouble cd;
    bool     b = 0;
    char*   endptr;

    if (!s.length)
        goto Lerr;
    
    b = getComplexStrings(s, s1, s2);

    if (!b)
        goto Lerr;

    // atof(s1);
    endptr = &s1[s1.length - 1];
    r1 = _conv_strtold(s1, &endptr); 

    // atof(s2);
    endptr = &s2[s2.length - 1];
    r2 = _conv_strtold(s2, &endptr); //atof(s2);

    cd = cast(cdouble)(r1 + (r2 * 1.0i));
 
    //Disabled, waiting on a bug fix.
    //if (cd > cdouble.max)  //same problem the toCfloat() having
    //    goto Loverflow;

    return cd;

    Loverflow:
        conv_overflow(s);
        
    Lerr:
        conv_error(s);
        return cast(cdouble)0.0e-0+0i; 
}

unittest
{
    debug(conv) writefln("conv.toCdouble.unittest");
    cdouble cd;

    cd = toCdouble(toString("1.2345e-5+0i"));
    assert(toString( cd ) == toString(1.2345e-5+0i));
    assert(feq(cd, 1.2345e-5+0i));

    // min and max
    cd = toCdouble(toString(cdouble.min));
    assert(toString(cd) == toString(cdouble.min));
    assert(feq(cast(creal)cd, cast(creal)cdouble.min));

    cd = toCdouble(toString(cdouble.max));
    assert(toString( cd ) == toString(cdouble.max));
    assert(feq(cast(creal)cd, cast(creal)cdouble.max));

    // nan ( nan+nani )
    cd = toCdouble("nani");
    assert(toString(cd) == toString(cdouble.nan));

    cd = toCdouble("nan+nani");
    assert(toString(cd) == toString(cdouble.nan));

    cd = toCdouble(toString(cdouble.nan));
    assert(toString(cd) == toString(cdouble.nan));
    assert(feq(cast(creal)cd, cast(creal)cdouble.nan));
}

/*******************************************************
 * ditto
 */
creal toCreal(in char[] s)
{
    char[] s1;
    char[] s2;
    real   r1;
    real   r2;
    creal  cr;
    bool    b = 0;
    char*  endptr;

    if (!s.length)
        goto Lerr;

    b = getComplexStrings(s, s1, s2);

    if (!b)
        goto Lerr;
 
    // atof(s1);
    endptr = &s1[s1.length - 1];
    r1 = _conv_strtold(s1, &endptr); 

    // atof(s2);
    endptr = &s2[s2.length - 1];
    r2 = _conv_strtold(s2, &endptr); //atof(s2);

    //writefln("toCreal() r1=%g, r2=%g, s1=\"%s\", s2=\"%s\", nan=%g", 
    //          r1, r2, s1, s2, creal.nan);
   
    if (s1 =="nan" && s2 == "nani")
        cr = creal.nan;
    else if (r2 != 0.0)
        cr = cast(creal)(r1 + (r2 * 1.0i));
    else
        cr = cast(creal)(r1 + 0.0i);    
    
    return cr;

    Lerr:
        conv_error(s);
        return cast(creal)0.0e-0+0i;    
}

unittest
{
    debug(conv) writefln("conv.toCreal.unittest");
    creal cr;

    cr = toCreal(toString("1.2345e-5+0i"));
    assert(toString(cr) == toString(1.2345e-5+0i));
    assert(feq(cr, 1.2345e-5+0i));

    cr = toCreal(toString("0.0e-0+0i"));
    assert(toString(cr) == toString(0.0e-0+0i));
    assert(cr == 0.0e-0+0i);
    assert(feq(cr, 0.0e-0+0i));
    
    cr = toCreal("123");
    assert(cr == 123);

    cr = toCreal("+5");
    assert(cr == 5);
 
    cr = toCreal("-78");
    assert(cr == -78);

    // min and max
    cr = toCreal(toString(creal.min));
    assert(toString(cr) == toString(creal.min));
    assert(feq(cr, creal.min));
    
    cr = toCreal(toString(creal.max));
    assert(toString(cr) == toString(creal.max));
    assert(feq(cr, creal.max));

    // nan ( nan+nani )
    cr = toCreal("nani");
    assert(toString(cr) == toString(creal.nan));

    cr = toCreal("nan+nani");
    assert(toString(cr) == toString(creal.nan));

    cr = toCreal(toString(cdouble.nan));
    assert(toString(cr) == toString(creal.nan));
    assert(feq(cr, creal.nan));
}

}

/* **************************************************************
 * Splits a complex float (cfloat, cdouble, and creal) into two workable strings.
 * Grammar:
 * ['+'|'-'] string floating-point digit {digit}
 */
private bool getComplexStrings(in char[] s, out char[] s1, out char[] s2)
{
    int len = s.length;

    if (!len) 
        goto Lerr;

    // When "nan" or "nani" just return them.
    if (s == "nan" || s == "nani" || s == "nan+nani")
    {
        s1 = "nan";
        s2 = "nani";
        return 1;
    }
    
    // Split the original string out into two strings.
    for (int i = 1; i < len; i++)
        if ((s[i - 1] != 'e' && s[i - 1] != 'E') && s[i] == '+')
        {
            s1 = s[0..i];
            if (i + 1 < len - 1)
                s2 = s[i + 1..len - 1];
            else 
                s2 = "0e+0i";
            
            break;
        }   

    // Handle the case when there's only a single value 
    // to work with, and set the other string to zero.
    if (!s1.length)
    {
        s1 = s;
        s2 = "0e+0i";
    }
 
    //writefln( "getComplexStrings() s=\"%s\", s1=\"%s\", s2=\"%s\", len=%d", 
    //           s, s1, s2, len );
   
    return 1;

    Lerr:
        // Display the original string in the error message.
        conv_error("getComplexStrings() \"" ~ s ~ "\"" ~ " s1=\"" ~ s1 ~ "\"" ~ " s2=\"" ~ s2 ~ "\"");
        return 0;
}

// feq() functions now used only in unittesting

/* ***************************************
 * Main function to compare reals with given precision
 */
private bool feq(in real rx, in real ry, in real precision)
{
    if (rx == ry)
        return 1;
    
    if (isnan(rx))
        return cast(bool)isnan(ry);

    if (isnan(ry))
        return 0;
       
    return cast(bool)(fabs(rx - ry) <= precision);
}

/* ***************************************
 * (Note: Copied here from std.math's mfeq() function for unittesting)
 * Simple function to compare two floating point values
 * to a specified precision.
 * Returns:
 *  1   match
 *  0   nomatch
 */
private bool feq(in real r1, in real r2)
{
    if (r1 == r2)
        return 1;
    
    if (isnan(r1))
        return cast(bool)isnan(r2);

    if (isnan(r2))
        return 0;
        
    return cast(bool)(feq(r1, r2, 0.000001L));
} 
 
/* ***************************************
 * compare ireals with given precision
 */
private bool feq(in ireal r1, in ireal r2)
{
    real rx = cast(real)r1;
    real ry = cast(real)r2;

    if (rx == ry)
        return 1;
    
    if (isnan(rx)) 
        return cast(bool)isnan(ry);

    if (isnan(ry))
        return 0;
    
    return feq(rx, ry, 0.000001L);
} 

/* ***************************************
 * compare creals with given precision
 */
private bool feq(in creal r1, in creal r2)
{
    real r1a = fabs(cast(real)r1.re - cast(real)r2.re);
    real r2b = fabs(cast(real)r1.im - cast(real)r2.im);

    if ((cast(real)r1.re == cast(real)r2.re) &&
        (cast(real)r1.im == cast(real)r2.im))
        return 1;
    
    if (isnan(r1a))
        return cast(bool)isnan(r2b);

    if (isnan(r2b))
        return 0;

    return feq(r1a, r2b, 0.000001L);
}

