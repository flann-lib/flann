
// Written in the D programming language.

/*
 *  Copyright (C) 2002-2007 by Digital Mars, www.digitalmars.com
 *  Written by Walter Bright
 *  Some parts contributed by David L. Davis
 *  Major rewrite by Andrei Alexandrescu
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
 * A one-stop shop for converting values from one type to another.
 *
 */

module std2.conv;
//public import std.conv;

private import std.string;  // for atof(), toString()
private import std.c.stdlib;
private import std.math;  // for fabs(), isnan()
private import std.stdio; // for writefln() and printf()
private import std.typetuple; // for unittests
private import std.utf; // for string-to-string conversions
import std2.traits;
import std.ctype;
import std.c.string; // memcpy

//debug=conv;		// uncomment to turn on debugging printf's

/* ************* Exceptions *************** */

/**
 * Thrown on conversion errors.
 */
class ConvError : Error
{
    this(string s)
    {
	super("conversion " ~ s);
    }
}

private void conv_error(string s)
{
    throw new ConvError(s);
}

/**
 * Thrown on conversion overflow errors.
 */
class ConvOverflowError : Error
{
    this(string s)
    {
	super("Error: overflow " ~ s);
    }
}

private void conv_overflow(string s)
{
    throw new ConvOverflowError(s);
}

/***************************************************************

The $(D_PARAM to) family of functions converts a value from type
$(D_PARAM Source) to type $(D_PARAM Target). The source type is
deduced and the target type must be specified, for example the
expression $(D_PARAM to!(int)(42.0)) converts the number 42 from
$(D_PARAM double) to $(D_PARAM int). The conversion is "safe", i.e.,
it checks for overflow; $(D_PARAM to!(int)(4.2e10)) would throw the
$(D_PARAM ConvOverflowError) exception. Overflow checks are only
inserted when necessary, e.g., $(D_PARAM to!(double)(42)) does not do
any checking because any int fits in a double.

Converting a value to its own type (useful mostly for generic code)
simply returns its argument.
Example:
-------------------------
int a = 42;
auto b = to!(int)(a); // b is int with value 42
auto c = to!(double)(3.14); // c is double with value 3.14
-------------------------
Converting among numeric types is a safe way to cast them around.
Conversions from floating-point types to integral types allow loss of
precision (the fractional part of a floating-point number). The
conversion is truncating towards zero, the same way a cast would
truncate. (To round a floating point value when casting to an
integral, use $(D_PARAM roundTo).)
Examples:
-------------------------
int a = 420;
auto b = to!(long)(a); // same as long b = a;
auto c = to!(byte)(a / 10); // fine, c = 42
auto d = to!(byte)(a); // throw ConvOverflowError
double e = 4.2e6;
auto f = to!(int)(e); // f == 4200000
e = -3.14;
auto g = to!(uint)(e); // fails: floating-to-integral underflow
e = 3.14;
auto h = to!(uint)(e); // h = 3
e = 3.99;
h = to!(uint)(a); // h = 3
e = -3.99;
f = to!(int)(a); // f = -3
-------------------------

Conversions from integral types to floating-point types always
succeed, but might lose accuracy. The largest integers with a
predecessor representable in floating-point format are 2^24-1 for
float, 2^53-1 for double, and 2^64-1 for $(D_PARAM real) (when
$(D_PARAM real) is 80-bit, e.g. on Intel machines).

Example:
-------------------------
int a = 16_777_215; // 2^24 - 1, largest proper integer representable as float
assert(to!(int)(to!(float)(a)) == a);
assert(to!(int)(to!(float)(-a)) == -a);
a += 2;
assert(to!(int)(to!(float)(a)) == a); // fails!
-------------------------

Conversions from string to numeric types differ from the C equivalents
$(D_PARAM atoi()) and $(D_PARAM atol()) by checking for overflow and
not allowing whitespace.

For conversion of strings to signed types, the grammar recognized is:
<pre>
$(I Integer): $(I Sign UnsignedInteger)
$(I UnsignedInteger)
$(I Sign):
    $(B +)
    $(B -)
</pre>
For conversion to unsigned types, the grammar recognized is:
<pre>
$(I UnsignedInteger):
    $(I DecimalDigit)
    $(I DecimalDigit) $(I UnsignedInteger)
</pre>

Converting an array to another array type works by converting each
element in turn. Associative arrays can be converted to associative
arrays as long as keys and values can in turn be converted.

Example:
-------------------------
int[] a = ([1, 2, 3]).dup;
auto b = to!(float[])(a);
assert(b == [1.0f, 2, 3]);
string str = "1 2 3 4 5 6";
auto numbers = to!(double[])(split(str));
assert(numbers == [1.0, 2, 3, 4, 5, 6]);
int[string] c;
c["a"] = 1;
c["b"] = 2;
auto d = to!(double[wstring])(c);
assert(d["a"w] == 1 && d["b"w] == 2);
-------------------------

Conversions operate transitively, meaning that they work on arrays and
associative arrays of any complexity:

-------------------------
int[string][double[int[]]] a;
...
auto b = to!(short[wstring][string[double[]]])(a);
-------------------------

This conversion works because $(D_PARAM to!(short)) applies to an
$(D_PARAM int), $(D_PARAM to!(wstring)) applies to a $(D_PARAM
string), $(D_PARAM to!(string)) applies to a $(D_PARAM double), and
$(D_PARAM to!(double[])) applies to an $(D_PARAM int[]). The
conversion might throw an exception because $(D_PARAM to!(short))
might fail the range check.

Macros: WIKI=Phobos/StdConv
*/

template to(Target)
{
    Target to(Source)(Source value)
    {
        // Need to forward because of problems when recursively invoking
        // a member with the same name as a template
        return toImpl!(Source, Target)(value);
    }
}

private T toSomeString(S, T)(S s)
{
  static const sIsString = is(S : char[]) || is(S : wchar[])
    || is(S : dchar[]);
  static if (sIsString) {
    // string-to-string conversion
    static if (s[0].sizeof == T[0].sizeof) {
      // same width, only qualifier conversion
      static const tIsConst = false;
      static const tIsInvariant = false;
      static assert(!is(S == T)); // should have been handled earlier
      static if (tIsConst) {
        return s;
      } else static if (tIsInvariant) {
         // conversion (mutable|const) -> invariant
         return s.idup;
      } else {
        // conversion (invariant|const) -> mutable
        return s.dup;
      }
    } else {
      // width conversion
      // we can cast because toUTFX always produces a fresh string
      static if (T[0].sizeof == 1) {
        return cast(T) toUTF8(s);
      } else static if (T[0].sizeof == 2) {
        return cast(T) toUTF16(s);
      } else {
        static assert(T[0].sizeof == 4);
        return cast(T) toUTF32(s);
      }
    }
  } else {
    static if (isArray!(S)) {
      // array-to-string conversion
        static if (is(S == void[])) {
            auto fake = cast(ubyte[]) s;
            static if (T[0].sizeof == 1)
                alias ubyte FakeT;
            else static if (T[0].sizeof == 2)
                alias ushort FakeT;
            else static if (T[0].sizeof == 4)
                alias uint FakeT;
            else static assert(false, T.stringof);
            FakeT[] result =
                new FakeT[(s.length + FakeT.sizeof - 1) / FakeT.sizeof];
            assert(result.length * FakeT.sizeof >= s.length);
            memcpy(result.ptr, s.ptr, s.length);
            return cast(T) result;
        } else {
            T result = to!(T)("[");
            foreach (i, e; s) {
                if (i) result ~= ',';
                result ~= to!(T)(e);
            }
            result ~= ']';
            return result;
        }
    } else static if (isAssociativeArray!(S)) {
      // hash-to-string conversion
      T result = "[";
      bool first = true;
      foreach (k, v; s) {
        if (!first) result ~= ',';
        else first = false;
        result ~= to!(T)(k);
        result ~= ':';
        result ~= to!(T)(v);
      }
      result ~= ']';
      return result;
    } else static if (is(S == enum)) {
       // enumerated type
       return to!(T)(to!(long)(s));
    } else static if (is(S : Object)) {
       // class
      return s is null ? "null" : to!(T)(s.toString);
    } else static if (is(S Original == typedef)) {
       // typedef
      return to!(T)(to!(Original)(s));
    } else {
      // source is not a string
      auto result = toString(s);
      static if (is(typeof(result) == T)) return result;
      else return to!(T)(result);
    }
  }
}

unittest
{
    auto a = "abcx"w;
    void[] b = a;
    assert(b.length == 8);
    auto c = to!(wchar[])(b);
    assert(c == "abcx");
}

private T toImpl(S, T)(S value) {
  static if (is(S == T)) {
    // Identity conversion
    return value;
  } else static if (is(T : char[]) || is(T : wchar[])
                    || is(T : dchar[])) {
    return toSomeString!(S, T)(value);
  } else static if (is(S : char[])) {
    return parseString!(T)(value);
  } else static if (is(S : wchar[]) || is(S : dchar[])) {
    // todo: improve performance
    return parseString!(T)(toUTF8(value));
  } else static if (std2.traits.isNumeric!(S) && std2.traits.isNumeric!(T)) {
    return numberToNumber!(S, T)(value);
  } else static if (isAssociativeArray!(S) && isAssociativeArray!(T)) {
    return hashToHash!(S, T)(value);
  } else static if (isArray!(S) && isArray!(S)) {
    return arrayToArray!(S, T)(value);
  } else static if (is(S : Object) && is(T : Object)) {
    return cast(T) value;
  } else {
    // Attempt an implicit conversion
    return value;
  }
}

private T numberToNumber(S, T)(S value) {
  static const
      sSmallest = isFloatingPoint!(S) ? -S.max : S.min,
      tSmallest = isFloatingPoint!(T) ? -T.max : T.min;
  static if (sSmallest < tSmallest) {
    // possible underflow
    if (value < tSmallest) conv_overflow("Conversion underflow");
  }
  static if (S.max > T.max) {
    // possible overflow
    if (value > T.max) conv_overflow("Conversion overflow");
  }
  return cast(T) value;
}

private T parseString(T)(char[] v)
{
    scope(exit) { if (v.length) conv_error(v.dup); }
    return parse!(T)(v);
}

private T[] arrayToArray(S : S[], T : T[])(S[] src) {
  T[] result;
  foreach (e; src) {
    result ~= to!(T)(e);
  }
  return result;
}

unittest {
  // array to array conversions
  uint[] a = ([ 1u, 2, 3 ]).dup;
  auto b = to!(float[])(a);
  assert(b == [ 1.0f, 2, 3 ]);
  auto c = to!(string[])(b);
  assert(c[0] == "1" && c[1] == "2" && c[2] == "3");
  int[3] d = [ 1, 2, 3 ];
  b = to!(float[])(d);
  assert(b == [ 1.0f, 2, 3 ]);
  uint[][] e = [ a, a ];
  auto f = to!(float[][])(e);
  assert(f[0] == b && f[1] == b);
}

private T hashToHash(S : V1[K1], T : V2[K2], K1, V1, K2, V2)(S src) {
  T result;
  foreach (k1, v1; src) {
    result[to!(K2)(k1)] = to!(V2)(v1);
  }
  return result;
}

unittest {
  // hash to hash conversions
  int[string] a;
  a["0"] = 1;
  a["1"] = 2;
  auto b = to!(double[dstring])(a);
  assert(b["0"d] == 1 && b["1"d] == 2);
  // hash to string conversion
  assert(to!(string)(a) == "[0:1,1:2]");
}

unittest {
  // string tests
  alias TypeTuple!(char, wchar, dchar) AllChars;
  foreach (T; AllChars) {
    foreach (U; AllChars) {
      T[] s1 = to!(T[])("Hello, world!");
      auto s2 = to!(U[])(s1);
      assert(s1 == to!(T[])(s2));
      auto s3 = to!(U[])(s1);
      assert(s1 == to!(T[])(s3));
      auto s4 = to!(U[])(s1);
      assert(s1 == to!(T[])(s4));
    }
  }
}

private bool convFails(Source, Target, E)(Source src) {
  try {
    auto t = to!(Target)(src);
  } catch (E) {
    return true;
  }
  return false;
}

private void testIntegralToFloating(Integral, Floating)() {
  Integral a = 42;
  auto b = to!(Floating)(a);
  assert(a == b);
  assert(a == to!(Integral)(b));
}

private void testFloatingToIntegral(Floating, Integral)() {
  // convert some value
  Floating a = 4.2e1;
  auto b = to!(Integral)(a);
  assert(is(typeof(b) == Integral) && b == 42);
  // convert some negative value (if applicable)
  a = -4.2e1;
  static if (Integral.min < 0) {
    b = to!(Integral)(a);
    assert(is(typeof(b) == Integral) && b == -42);
  } else {
    // no go for unsigned types
    assert(convFails!(Floating, Integral, ConvOverflowError)(a));
  }
  // convert to the smallest integral value
  a = 0.0 + Integral.min;
  static if (Integral.min < 0) {
    a = -a; // -Integral.min not representable as an Integral
    assert(convFails!(Floating, Integral, ConvOverflowError)(a)
           || Floating.sizeof <= Integral.sizeof);
  }
  a = 0.0 + Integral.min;
  assert(to!(Integral)(a) == Integral.min);
  --a; // no more representable as an Integral
  assert(convFails!(Floating, Integral, ConvOverflowError)(a)
         || Floating.sizeof <= Integral.sizeof);
  a = 0.0 + Integral.max;
//   fwritefln(stderr, "%s a=%g, %s conv=%s", Floating.stringof, a,
//             Integral.stringof, to!(Integral)(a));
  assert(to!(Integral)(a) == Integral.max || Floating.sizeof <= Integral.sizeof);
  ++a; // no more representable as an Integral
  assert(convFails!(Floating, Integral, ConvOverflowError)(a)
         || Floating.sizeof <= Integral.sizeof);
  // convert a value with a fractional part
  a = 3.14;
  assert(to!(Integral)(a) == 3);
  a = 3.99;
  assert(to!(Integral)(a) == 3);
  static if (Integral.min < 0) {
    a = -3.14;
    assert(to!(Integral)(a) == -3);
    a = -3.99;
    assert(to!(Integral)(a) == -3);
  }
}

unittest {
  alias TypeTuple!(byte, ubyte, short, ushort, int, uint, long, ulong)
    AllInts;
  alias TypeTuple!(float, double, real) AllFloats;
  alias TypeTuple!(AllInts, AllFloats) AllNumerics;
  // test with same type
  {
    foreach (T; AllNumerics) {
      T a = 42;
      auto b = to!(T)(a);
      assert(is(typeof(a) == typeof(b)) && a == b);
    }
  }
  // test that floating-point numbers convert properly to largest ints
  // see http://oregonstate.edu/~peterseb/mth351/docs/351s2001_fp80x87.html
  // look for "largest fp integer with a predecessor"
  {
    // float
    int a = 16_777_215; // 2^24 - 1
    assert(to!(int)(to!(float)(a)) == a);
    assert(to!(int)(to!(float)(-a)) == -a);
    // double
    long b = 9_007_199_254_740_991; // 2^53 - 1
    assert(to!(long)(to!(double)(b)) == b);
    assert(to!(long)(to!(double)(-b)) == -b);
    // real
    // @@@ BUG IN COMPILER @@@
//     ulong c = 18_446_744_073_709_551_615UL; // 2^64 - 1
//     assert(to!(ulong)(to!(real)(c)) == c);
//     assert(to!(ulong)(-to!(real)(c)) == c);
  }
  // test conversions floating => integral
  {
    // AllInts[0 .. $ - 1] should be AllInts
    // @@@ BUG IN COMPILER @@@
    foreach (Integral; AllInts[0 .. $ - 1]) {
      foreach (Floating; AllFloats) {
        testFloatingToIntegral!(Floating, Integral);
      }
    }
  }
  // test conversion integral => floating
  {
    foreach (Integral; AllInts[0 .. $ - 1]) {
      foreach (Floating; AllFloats) {
        testIntegralToFloating!(Integral, Floating);
      }
    }
  }
  // test parsing
  {
    foreach (T; AllNumerics) {
      // from type invariant(char)[2]
      auto a = to!(T)("42");
      assert(a == 42);
      // from type char[]
      char[] s1 = "42".dup;
      a = to!(T)(s1);
      assert(a == 42);
      // from type char[2]
      char[2] s2;
      s2[] = "42";
      a = to!(T)(s2);
      assert(a == 42);
      // from type invariant(wchar)[2]
      a = to!(T)("42"w);
      assert(a == 42);
    }
  }
  // test conversions to string
  {
    foreach (T; AllNumerics) {
      T a = 42;
      assert(to!(string)(a) == "42");
      //assert(to!(wstring)(a) == "42"w);
      //assert(to!(dstring)(a) == "42"d);
      // array test
//       T[] b = new T[2];
//       b[0] = 42;
//       b[1] = 33;
//       assert(to!(string)(b) == "[42,33]");
    }
  }
  // test array to string conversion
  foreach (T ; AllNumerics) {
    auto a = [to!(T)(1), 2, 3];
    assert(to!(string)(a) == "[1,2,3]");
  }
  // test enum to int conversion
  enum Testing { Test1, Test2 };
  Testing t;
  auto a = to!(string)(t);
  assert(a == "0");
}

/***************************************************************
 Rounded conversion from floating point to integral.

Example:
---------------
  assert(roundTo!(int)(3.14) == 3);
  assert(roundTo!(int)(3.49) == 3);
  assert(roundTo!(int)(3.5) == 4);
  assert(roundTo!(int)(3.999) == 4);
  assert(roundTo!(int)(-3.14) == -3);
  assert(roundTo!(int)(-3.49) == -3);
  assert(roundTo!(int)(-3.5) == -4);
  assert(roundTo!(int)(-3.999) == -4);
---------------
Rounded conversions do not work with non-integral target types.
 */

template roundTo(Target) {
  Target roundTo(Source)(Source value) {
    static assert(is(Source == float) || is(Source == double)
                  || is(Source == real));
    static assert(is(Target == byte) || is(Target == ubyte)
                  || is(Target == short) || is(Target == ushort)
                  || is(Target == int) || is(Target == uint)
                  || is(Target == long) || is(Target == ulong));
    return to!(Target)(value + (value < 0 ? -0.5 : 0.5));
  }
}

unittest {
  assert(roundTo!(int)(3.14) == 3);
  assert(roundTo!(int)(3.49) == 3);
  assert(roundTo!(int)(3.5) == 4);
  assert(roundTo!(int)(3.999) == 4);
  assert(roundTo!(int)(-3.14) == -3);
  assert(roundTo!(int)(-3.49) == -3);
  assert(roundTo!(int)(-3.5) == -4);
  assert(roundTo!(int)(-3.999) == -4);
}

/***************************************************************
 * The $(D_PARAM parse) family of functions works quite like the
 * $(D_PARAM to) family, except that (1) it only works with strings as
 * input, (2) takes the input string by reference and advances it to
 * the position following the conversion, and (3) does not throw if it
 * could not convert the entire string. It still throws if an overflow
 * occurred during conversion or if no character of the input string
 * was meaningfully converted.
 *
 * Example:
--------------
string test = "123 \t  76.14";
auto a = parse!(uint)(test);
assert(a == 123);
assert(test == " \t  76.14"); // parse bumps string
munch(test, " \t\n\r"); // skip ws
assert(test == "76.14");
auto b = parse!(double)(test);
assert(b == 76.14);
assert(test == "");
--------------
 */

template parse(Target)
{
    Target parse(Source)(ref Source s)
    {
        //alias const(Char)[] Source;
        static assert(is(Source : char[]) || is(Source : wchar[])
                      || is(Source : dchar[]),
                      "parse requires a string upon input, not a "
                      ~ Source.stringof);
        static if (isIntegral!(Target))
        {
            return parseIntegral!(Source, Target)(s);
        }
        else static if (isFloatingPoint!(Target))
        {
            return parseFloating!(Source, Target)(s);
        }
        else
        {
            static assert(false, "Dunno how to parse a " ~ Target.stringof);
        }
    }
}

// Customizable integral parse

private N parseIntegral(S, N)(ref S s)
{
    static if (N.sizeof < int.sizeof)
    {
        // smaller types are handled like integers
        static if (N.min < 0) // signed small integer
            alias int N1;
        else
            alias uint N1;
        auto v = parseIntegral!(S, N1)(s);
        auto result = cast(N) v;
        if (result != v) conv_error(to!(string)(s));
        return result;
    }
    else
    {
        auto length = s.length;
        if (!length)
            goto Lerr;

        static if (N.min < 0)
            int sign = 0;
        else
            static const int sign = 0;
        N v = 0;
        size_t i = 0;
        static const char maxLastDigit = N.min < 0 ? '7' : '5';
        for (; i < length; i++)
        {
            auto c = s[i];
            if (c >= '0' && c <= '9')
            {
                if (v < N.max/10 || (v == N.max/10 && c + sign <= maxLastDigit))
                    v = v * 10 + (c - '0');
                else
                    goto Loverflow;
            }
            else static if (N.min < 0)
            {
                if (c == '-' && i == 0)
                {
                    sign = -1;
                    if (length == 1)
                        goto Lerr;
                }
                else if (c == '+' && i == 0)
                {
                    if (length == 1)
                        goto Lerr;
                } else
                    break;
            }
            else
                break;
        }
        if (i == 0) goto Lerr;
        s = s[i .. $];
        static if (N.min < 0)
        {
            if (sign == -1)
            {
                v = -v;
            }
        }
        return v;
    Loverflow:
        conv_overflow(to!(string)(s));
    Lerr:
        conv_error(to!(string)(s));
        return 0;
    }
}

/***************************************************************
 Convert character string to the return type. These functions will be
 deprecated because $(D_PARAM to!(T)) supersedes them.
 */

int toInt(string s)
{
    scope(exit) { if (s.length) conv_error(s); }
    return parseIntegral!(string, int)(s);
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

    static string[] errors =
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
uint toUint(string s)
{
    scope(exit) if (s.length) conv_error(s);
    return parseIntegral!(string, uint)(s);
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

    static string[] errors =
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

long toLong(string s)
{
    scope(exit) if (s.length) conv_error(s);
    return parseIntegral!(string, long)(s);
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

    static string[] errors =
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

ulong toUlong(string s)
{
    scope(exit) if (s.length) conv_error(s);
    return parseIntegral!(string, ulong)(s);
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


    static string[] errors =
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

short toShort(string s)
{
    scope(exit) if (s.length) conv_error(s);
    return parseIntegral!(string, short)(s);
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

    static string[] errors =
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

ushort toUshort(string s)
{
    scope(exit) if (s.length) conv_error(s);
    return parseIntegral!(string, ushort)(s);
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

    static string[] errors =
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

byte toByte(string s)
{
    scope(exit) if (s.length) conv_error(s);
    return parseIntegral!(string, byte)(s);
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

    static string[] errors =
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

ubyte toUbyte(string s)
{
    scope(exit) if (s.length) conv_error(s);
    return parseIntegral!(string, ubyte)(s);
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

    static string[] errors =
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

float toFloat(Char)(Char[] s)
{
    scope(exit) if (s.length) conv_error(s);
    return parseFloating!(Char[], float)(s);
}

// @@@ BUG IN COMPILER
// lvalue of type invariant(T)[] should be implicitly convertible to
// ref const(T)[].
F parseFloating(S : S[], F)(ref S[] s)
{
    //writefln("toFloat('%s')", s);
    auto sz = toStringz(s);
    if (std.ctype.isspace(*sz))
	goto Lerr;

    // BUG: should set __locale_decpoint to "." for DMC

    setErrno(0);
    char* endptr;
    static if (is(F == float))
        auto f = strtof(sz, &endptr);
    else static if (is(F == double))
        auto f = strtod(sz, &endptr);
    else static if (is(F == real))
        auto f = strtold(sz, &endptr);
    else
        static assert(false);
    if (getErrno() == ERANGE)
	goto Lerr;
    assert(endptr);
    if (endptr == s.ptr)
    {
        // no progress
	goto Lerr;
    }
    s = s[endptr - sz .. $];
    return f;
  Lerr:
    conv_error(to!(string)(s) ~ " not representable as a " ~ F.stringof);
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
    version(none) {
    f = toFloat("nan");
    assert(toString(f) == toString(float.nan));
    }
}

/*******************************************************
 * ditto
 */

double toDouble(Char)(Char[] s)
{
    scope(exit) if (s.length) conv_error(s);
    return parseFloating!(Char[], double)(s);
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
    version(none) {
    d = toDouble("nan");
    assert(toString(d) == toString(double.nan));
    //assert(cast(real)d == cast(real)double.nan);
    }
}

/*******************************************************
 * ditto
 */
real toReal(Char)(Char[] s)
{
    scope(exit) if (s.length) conv_error(s);
    return parseFloating!(Char[], real)(s);
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

    version(none) {
    // nan
    r = toReal("nan");
    assert(toString(r) == toString(real.nan));
    //assert(r == real.nan);

    r = toReal(toString(real.nan));
    assert(toString(r) == toString(real.nan));
    //assert(r == real.nan);
    }
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

ifloat toIfloat(in string s)
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

idouble toIdouble(in string s)
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

ireal toIreal(in string s)
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
cfloat toCfloat(in string s)
{
    string s1;
    string s2;
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
    r1 = strtold(s1, &endptr); 

    // atof(s2);
    endptr = &s2[s2.length - 1];
    r2 = strtold(s2, &endptr); 

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
cdouble toCdouble(in string s)
{
    string  s1;
    string  s2;
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
    r1 = strtold(s1, &endptr); 

    // atof(s2);
    endptr = &s2[s2.length - 1];
    r2 = strtold(s2, &endptr); //atof(s2);

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
creal toCreal(in string s)
{
    string s1;
    string s2;
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
    r1 = strtold(s1, &endptr); 

    // atof(s2);
    endptr = &s2[s2.length - 1];
    r2 = strtold(s2, &endptr); //atof(s2);

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
// @@@ BUG IN COMPILER: writing "in string s" instead of "string s" changes its
// type from invariant(char)[] to const(char)[] !!!
private bool getComplexStrings(string s, out string s1, out string s2)
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
            //s1 = s[0..i]; should work, doesn't
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
    conv_error("getComplexStrings() \"" ~ s ~ "\"" ~ " s1=\""
                             ~ s1 ~ "\"" ~ " s2=\"" ~ s2 ~ "\"");
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

