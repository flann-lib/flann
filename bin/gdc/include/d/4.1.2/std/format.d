
// Written in the D programming language.

/**
 * This module implements the workhorse functionality for string and I/O formatting.
 * It's comparable to C99's vsprintf().
 *
 * Macros:
 *	WIKI = Phobos/StdFormat
 */

/*
 *  Copyright (C) 2004-2006 by Digital Mars, www.digitalmars.com
 *  Written by Walter Bright
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

module std.format;

//debug=format;		// uncomment to turn on debugging printf's

import std.stdarg;	// caller will need va_list

private import std.utf;
private import std.c.stdlib;
private import std.c.string;
private import std.string;

version (Windows)
{
    version (DigitalMars)
    {
	version = DigitalMarsC;
    }
    version (GNU)
    {
	version = GNU_MinGW_MSVCRT;
    }
}

version (DigitalMarsC)
{
    // This is DMC's internal floating point formatting function
    extern (C)
    {
	extern char* function(int c, int flags, int precision, real* pdval,
	    char* buf, int* psl, int width) __pfloatfmt;
    }
}
else
{
    // Use C99 snprintf
    extern (C) int snprintf(char* s, size_t n, char* format, ...);
}

/**********************************************************************
 * Signals a mismatch between a format and its corresponding argument.
 */
class FormatError : Error
{
  private:

    this()
    {
	super("std.format");
    }

    this(char[] msg)
    {
	super("std.format " ~ msg);
    }
}


enum Mangle : char
{
    Tvoid     = 'v',
    Tbool     = 'b',
    Tbyte     = 'g',
    Tubyte    = 'h',
    Tshort    = 's',
    Tushort   = 't',
    Tint      = 'i',
    Tuint     = 'k',
    Tlong     = 'l',
    Tulong    = 'm',
    Tfloat    = 'f',
    Tdouble   = 'd',
    Treal     = 'e',

    Tifloat   = 'o',
    Tidouble  = 'p',
    Tireal    = 'j',
    Tcfloat   = 'q',
    Tcdouble  = 'r',
    Tcreal    = 'c',

    Tchar     = 'a',
    Twchar    = 'u',
    Tdchar    = 'w',

    Tarray    = 'A',
    Tsarray   = 'G',
    Taarray   = 'H',
    Tpointer  = 'P',
    Tfunction = 'F',
    Tident    = 'I',
    Tclass    = 'C',
    Tstruct   = 'S',
    Tenum     = 'E',
    Ttypedef  = 'T',
    Tdelegate = 'D',

    Tconst    = 'x',
    Tinvariant = 'y',
}

// return the TypeInfo for a primitive type and null otherwise.
// This is required since for arrays of ints we only have the mangled
// char to work from. If arrays always subclassed TypeInfo_Array this
// routine could go away.
private TypeInfo primitiveTypeInfo(Mangle m) 
{
  TypeInfo ti;

  switch (m)
    {
    case Mangle.Tvoid:
      ti = typeid(void);break;
    case Mangle.Tbool:
      ti = typeid(bool);break;
    case Mangle.Tbyte:
      ti = typeid(byte);break;
    case Mangle.Tubyte:
      ti = typeid(ubyte);break;
    case Mangle.Tshort:
      ti = typeid(short);break;
    case Mangle.Tushort:
      ti = typeid(ushort);break;
    case Mangle.Tint:
      ti = typeid(int);break;
    case Mangle.Tuint:
      ti = typeid(uint);break;
    case Mangle.Tlong:
      ti = typeid(long);break;
    case Mangle.Tulong:
      ti = typeid(ulong);break;
    case Mangle.Tfloat:
      ti = typeid(float);break;
    case Mangle.Tdouble:
      ti = typeid(double);break;
    case Mangle.Treal:
      ti = typeid(real);break;
    case Mangle.Tifloat:
      ti = typeid(ifloat);break;
    case Mangle.Tidouble:
      ti = typeid(idouble);break;
    case Mangle.Tireal:
      ti = typeid(ireal);break;
    case Mangle.Tcfloat:
      ti = typeid(cfloat);break;
    case Mangle.Tcdouble:
      ti = typeid(cdouble);break;
    case Mangle.Tcreal:
      ti = typeid(creal);break;
    case Mangle.Tchar:
      ti = typeid(char);break;
    case Mangle.Twchar:
      ti = typeid(wchar);break;
    case Mangle.Tdchar:
      ti = typeid(dchar);
    default:
      ti = null;
    }
  return ti;
}

/************************************
 * Interprets variadic argument list pointed to by argptr whose types are given
 * by arguments[], formats them according to embedded format strings in the
 * variadic argument list, and sends the resulting characters to putc.
 *
 * The variadic arguments are consumed in order.
 * Each is formatted into a sequence of chars, using the default format
 * specification for its type, and the
 * characters are sequentially passed to putc.
 * If a char[], wchar[], or dchar[]
 * argument is encountered, it is interpreted as a format string. As many
 * arguments as specified in the format string are consumed and formatted
 * according to the format specifications in that string and passed to putc. If
 * there are too few remaining arguments, a FormatError is thrown. If there are
 * more remaining arguments than needed by the format specification, the default
 * processing of arguments resumes until they are all consumed.
 *
 * Params:
 *	putc =	Output is sent do this delegate, character by character.
 *	arguments = Array of TypeInfo's, one for each argument to be formatted.
 *	argptr = Points to variadic argument list.
 *
 * Throws:
 *	Mismatched arguments and formats result in a FormatError being thrown.
 *
 * Format_String:
 *	<a name="format-string">$(I Format strings)</a>
 *	consist of characters interspersed with
 *	$(I format specifications). Characters are simply copied
 *	to the output (such as putc) after any necessary conversion
 *	to the corresponding UTF-8 sequence.
 *
 *	A $(I format specification) starts with a '%' character,
 *	and has the following grammar:

<pre>
$(I FormatSpecification):
    $(B '%%')
    $(B '%') $(I Flags) $(I Width) $(I Precision) $(I FormatChar)

$(I Flags):
    $(I empty)
    $(B '-') $(I Flags)
    $(B '+') $(I Flags)
    $(B '#') $(I Flags)
    $(B '0') $(I Flags)
    $(B ' ') $(I Flags)

$(I Width):
    $(I empty)
    $(I Integer)
    $(B '*')

$(I Precision):
    $(I empty)
    $(B '.')
    $(B '.') $(I Integer)
    $(B '.*')

$(I Integer):
    $(I Digit)
    $(I Digit) $(I Integer)

$(I Digit):
    $(B '0')
    $(B '1')
    $(B '2')
    $(B '3')
    $(B '4')
    $(B '5')
    $(B '6')
    $(B '7')
    $(B '8')
    $(B '9')

$(I FormatChar):
    $(B 's')
    $(B 'b')
    $(B 'd')
    $(B 'o')
    $(B 'x')
    $(B 'X')
    $(B 'e')
    $(B 'E')
    $(B 'f')
    $(B 'F')
    $(B 'g')
    $(B 'G')
    $(B 'a')
    $(B 'A')
</pre>
    <dl>
    <dt>$(I Flags)
    <dl>
	<dt>$(B '-')
	<dd>
	Left justify the result in the field.
	It overrides any $(B 0) flag.

	<dt>$(B '+')
	<dd>Prefix positive numbers in a signed conversion with a $(B +).
	It overrides any $(I space) flag.

	<dt>$(B '#')
	<dd>Use alternative formatting:
	<dl>
	    <dt>For $(B 'o'):
	    <dd> Add to precision as necessary so that the first digit
	    of the octal formatting is a '0', even if both the argument
	    and the $(I Precision) are zero.
	    <dt> For $(B 'x') ($(B 'X')):
	    <dd> If non-zero, prefix result with $(B 0x) ($(B 0X)).
	    <dt> For floating point formatting:
	    <dd> Always insert the decimal point.
	    <dt> For $(B 'g') ($(B 'G')):
	    <dd> Do not elide trailing zeros.
	</dl>

	<dt>$(B '0')
	<dd> For integer and floating point formatting when not nan or
	infinity, use leading zeros
	to pad rather than spaces.
	Ignore if there's a $(I Precision).

	<dt>$(B ' ')
	<dd>Prefix positive numbers in a signed conversion with a space.
    </dl>

    <dt>$(I Width)
    <dd>
    Specifies the minimum field width.
    If the width is a $(B *), the next argument, which must be
    of type $(B int), is taken as the width.
    If the width is negative, it is as if the $(B -) was given
    as a $(I Flags) character.

    <dt>$(I Precision)
    <dd> Gives the precision for numeric conversions.
    If the precision is a $(B *), the next argument, which must be
    of type $(B int), is taken as the precision. If it is negative,
    it is as if there was no $(I Precision).

    <dt>$(I FormatChar)
    <dd>
    <dl>
	<dt>$(B 's')
	<dd>The corresponding argument is formatted in a manner consistent
	with its type:
	<dl>
	    <dt>$(B bool)
	    <dd>The result is <tt>'true'</tt> or <tt>'false'</tt>.
	    <dt>integral types
	    <dd>The $(B %d) format is used.
	    <dt>floating point types
	    <dd>The $(B %g) format is used.
	    <dt>string types
	    <dd>The result is the string converted to UTF-8.
	    A $(I Precision) specifies the maximum number of characters
	    to use in the result.
	    <dt>classes derived from $(B Object)
	    <dd>The result is the string returned from the class instance's
	    $(B .toString()) method.
	    A $(I Precision) specifies the maximum number of characters
	    to use in the result.
	    <dt>non-string static and dynamic arrays
	    <dd>The result is [s<sub>0</sub>, s<sub>1</sub>, ...]
	    where s<sub>k</sub> is the kth element 
	    formatted with the default format.
	</dl>

	<dt>$(B 'b','d','o','x','X')
	<dd> The corresponding argument must be an integral type
	and is formatted as an integer. If the argument is a signed type
	and the $(I FormatChar) is $(B d) it is converted to
	a signed string of characters, otherwise it is treated as
	unsigned. An argument of type $(B bool) is formatted as '1'
	or '0'. The base used is binary for $(B b), octal for $(B o),
	decimal
	for $(B d), and hexadecimal for $(B x) or $(B X).
	$(B x) formats using lower case letters, $(B X) uppercase.
	If there are fewer resulting digits than the $(I Precision),
	leading zeros are used as necessary.
	If the $(I Precision) is 0 and the number is 0, no digits
	result.

	<dt>$(B 'e','E')
	<dd> A floating point number is formatted as one digit before
	the decimal point, $(I Precision) digits after, the $(I FormatChar),
	&plusmn;, followed by at least a two digit exponent: $(I d.dddddd)e$(I &plusmn;dd).
	If there is no $(I Precision), six
	digits are generated after the decimal point.
	If the $(I Precision) is 0, no decimal point is generated.

	<dt>$(B 'f','F')
	<dd> A floating point number is formatted in decimal notation.
	The $(I Precision) specifies the number of digits generated
	after the decimal point. It defaults to six. At least one digit
	is generated before the decimal point. If the $(I Precision)
	is zero, no decimal point is generated.

	<dt>$(B 'g','G')
	<dd> A floating point number is formatted in either $(B e) or
	$(B f) format for $(B g); $(B E) or $(B F) format for
	$(B G).
	The $(B f) format is used if the exponent for an $(B e) format
	is greater than -5 and less than the $(I Precision).
	The $(I Precision) specifies the number of significant
	digits, and defaults to six.
	Trailing zeros are elided after the decimal point, if the fractional
	part is zero then no decimal point is generated.

	<dt>$(B 'a','A')
	<dd> A floating point number is formatted in hexadecimal
	exponential notation 0x$(I h.hhhhhh)p$(I &plusmn;d).
	There is one hexadecimal digit before the decimal point, and as
	many after as specified by the $(I Precision).
	If the $(I Precision) is zero, no decimal point is generated.
	If there is no $(I Precision), as many hexadecimal digits as
	necessary to exactly represent the mantissa are generated.
	The exponent is written in as few digits as possible,
	but at least one, is in decimal, and represents a power of 2 as in
	$(I h.hhhhhh)*2<sup>$(I &plusmn;d)</sup>.
	The exponent for zero is zero.
	The hexadecimal digits, x and p are in upper case if the
	$(I FormatChar) is upper case.
    </dl>

    Floating point NaN's are formatted as $(B nan) if the
    $(I FormatChar) is lower case, or $(B NAN) if upper.
    Floating point infinities are formatted as $(B inf) or
    $(B infinity) if the
    $(I FormatChar) is lower case, or $(B INF) or $(B INFINITY) if upper.
    </dl>

Example:

-------------------------
import std.c.stdio;
import std.format;

void formattedPrint(...)
{
    void putc(char c)
    {
	fputc(c, stdout);
    }

    std.format.doFormat(&putc, _arguments, _argptr);
}

...

int x = 27;
// prints 'The answer is 27:6'
formattedPrint("The answer is %s:", x, 6);
------------------------
 */

void doFormat(void delegate(dchar) putc, TypeInfo[] arguments, va_list argptr)
{
    doFormatPtr(putc, arguments, argptr, null);
}

void doFormatPtr(void delegate(dchar) putc, TypeInfo[] arguments, va_list argptr,
	      void * p_args)
{   int j;
    TypeInfo ti;
    Mangle m;
    uint flags;
    int field_width;
    int precision;

    enum : uint
    {
	FLdash = 1,
	FLplus = 2,
	FLspace = 4,
	FLhash = 8,
	FLlngdbl = 0x20,
	FL0pad = 0x40,
	FLprecision = 0x80,
    }

    static TypeInfo skipCI(TypeInfo valti)
    {
      while (1)
      {
	if (valti.classinfo.name.length == 18 &&
	    valti.classinfo.name[9..18] == "Invariant")
	    valti =	(cast(TypeInfo_Invariant)valti).next;
	else if (valti.classinfo.name.length == 14 &&
	    valti.classinfo.name[9..14] == "Const")
	    valti =	(cast(TypeInfo_Const)valti).next;
	else
	    break;
      }
      return valti;
    }

    void formatArg(char fc)
    {
	bool vbit;
	ulong vnumber;
	char vchar;
	dchar vdchar;
	Object vobject;
	real vreal;
	creal vcreal;
	Mangle m2;
	int signed = 0;
	uint base = 10;
	int uc;
	char[ulong.sizeof * 8] tmpbuf;	// long enough to print long in binary
	char* prefix = "";
	string s;

	void putstr(char[] s)
	{
	    //printf("flags = x%x\n", flags);
	    int prepad = 0;
	    int postpad = 0;
	    int padding = field_width - (strlen(prefix) + s.length);
	    if (padding > 0)
	    {
		if (flags & FLdash)
		    postpad = padding;
		else
		    prepad = padding;
	    }

	    if (flags & FL0pad)
	    {
		while (*prefix)
		    putc(*prefix++);
		while (prepad--)
		    putc('0');
	    }
	    else
	    {
		while (prepad--)
		    putc(' ');
		while (*prefix)
		    putc(*prefix++);
	    }

	    foreach (dchar c; s)
		putc(c);

	    while (postpad--)
		putc(' ');
	}

	void putreal(real v)
	{
	    //printf("putreal %Lg\n", vreal);

	    switch (fc)
	    {
		case 's':
		    fc = 'g';
		    break;

		case 'f', 'F', 'e', 'E', 'g', 'G', 'a', 'A':
		    break;

		default:
		    //printf("fc = '%c'\n", fc);
		Lerror:
		    throw new FormatError("floating");
	    }
	    version (DigitalMarsC)
	    {
		int sl;
		char[] fbuf = tmpbuf;
		if (!(flags & FLprecision))
		    precision = 6;
		while (1)
		{
		    sl = fbuf.length;
		    prefix = (*__pfloatfmt)(fc, flags | FLlngdbl,
			    precision, &v, cast(char*)fbuf, &sl, field_width);
		    if (sl != -1)
			break;
		    sl = fbuf.length * 2;
		    fbuf = (cast(char*)alloca(sl * char.sizeof))[0 .. sl];
		}
		putstr(fbuf[0 .. sl]);
	    }
	    else
	    {
		int sl;
		char[] fbuf = tmpbuf;
		char[12] format;
		format[0] = '%';
		int i = 1;
		if (flags & FLdash)
		    format[i++] = '-';
		if (flags & FLplus)
		    format[i++] = '+';
		if (flags & FLspace)
		    format[i++] = ' ';
		if (flags & FLhash)
		    format[i++] = '#';
		if (flags & FL0pad)
		    format[i++] = '0';
		format[i + 0] = '*';
		format[i + 1] = '.';
		format[i + 2] = '*';
		i += 3;
		version (GNU_MinGW_MSVCRT)
		    { /* nothing: no support for long double */ }
		else
		    static if (real.sizeof > double.sizeof)
			format[i++] = 'L';
		format[i++] = fc;
		format[i] = 0;
		if (!(flags & FLprecision))
		    precision = -1;
		while (1)
		{   int n;

		    sl = fbuf.length;
		    version (GNU_MinGW_MSVCRT)
			n = snprintf(fbuf.ptr, sl, format.ptr, field_width, precision, cast(double) v);
		    else
			n = snprintf(fbuf.ptr, sl, format.ptr, field_width, precision, v);
		    //printf("format = '%s', n = %d\n", cast(char*)format, n);
		    if (n >= 0 && n < sl)
		    {	sl = n;
			break;
		    }
		    if (n < 0)
			sl = sl * 2;
		    else
			sl = n + 1;
		    fbuf = (cast(char*)alloca(sl * char.sizeof))[0 .. sl];
		}
		putstr(fbuf[0 .. sl]);
	    }
	    return;
	}

	static Mangle getMan(TypeInfo ti)
	{
	  auto m = cast(Mangle)ti.classinfo.name[9];
	  if (ti.classinfo.name.length == 20 &&
	      ti.classinfo.name[9..20] == "StaticArray")
		m = cast(Mangle)'G';
	  return m;
	}

	void putArray(void* p, size_t len, TypeInfo valti)
	{
	  //printf("\nputArray(len = %u), tsize = %u\n", len, valti.tsize());
	  putc('[');
	  valti = skipCI(valti);
	  size_t tsize = valti.tsize();
	  auto argptrSave = p_args;
	  auto tiSave = ti;
	  auto mSave = m;
	  ti = valti;
	  //printf("\n%.*s\n", valti.classinfo.name);
	  m = getMan(valti);
	  while (len--)
	  {
	    //doFormat(putc, (&valti)[0 .. 1], p);
	    p_args = p;
	    formatArg('s');

	    p += tsize;
	    if (len > 0) putc(',');
	  }
	  m = mSave;
	  ti = tiSave;
	  p_args = argptrSave;
	  putc(']');
	}

	void putAArray(ubyte[long] vaa, TypeInfo valti, TypeInfo keyti)
	{
	    // Copied from aaA.d
	    size_t aligntsize(size_t tsize)
	    {
		// Is pointer alignment on the x64 4 bytes or 8?
		return (tsize + size_t.sizeof - 1) & ~(size_t.sizeof - 1);
	    }
	    
	  putc('[');
	  bool comma=false;
	  auto argptrSave = p_args;
	  auto tiSave = ti;
	  auto mSave = m;
	  valti = skipCI(valti);
	  keyti = skipCI(keyti);
	  foreach(inout fakevalue; vaa)
	  {
	    if (comma) putc(',');
	    comma = true;
	    // the key comes before the value
	    ubyte* key = &fakevalue - long.sizeof;

	    //doFormat(putc, (&keyti)[0..1], key);
	    p_args = key;
	    ti = keyti;
	    m = getMan(keyti);
	    formatArg('s');

	    putc(':');
	    ubyte* value = key + aligntsize(keyti.tsize);
	    //doFormat(putc, (&valti)[0..1], value);
	    p_args = value;
	    ti = valti;
	    m = getMan(valti);
	    formatArg('s');
	  }
	  m = mSave;
	  ti = tiSave;
	  p_args = argptrSave;
	  putc(']');
	}

	//printf("formatArg(fc = '%c', m = '%c')\n", fc, m);
	if (! p_args)
	switch (m)
	{
	    case Mangle.Tbool:
		vbit = va_arg!(bool)(argptr);
		if (fc != 's')
		{   vnumber = vbit;
		    goto Lnumber;
		}
		putstr(vbit ? "true" : "false");
		return;


	    case Mangle.Tchar:
		vchar = va_arg!(char)(argptr);
		if (fc != 's')
		{   vnumber = vchar;
		    goto Lnumber;
		}
	    L2:
		putstr((&vchar)[0 .. 1]);
		return;

	    case Mangle.Twchar:
		vdchar = va_arg!(wchar)(argptr);
		goto L1;

	    case Mangle.Tdchar:
		vdchar = va_arg!(dchar)(argptr);
	    L1:
		if (fc != 's')
		{   vnumber = vdchar;
		    goto Lnumber;
		}
		if (vdchar <= 0x7F)
		{   vchar = cast(char)vdchar;
		    goto L2;
		}
		else
		{   if (!isValidDchar(vdchar))
			throw new UtfException("invalid dchar in format", 0);
		    char[4] vbuf;
		    putstr(toUTF8(vbuf, vdchar));
		}
		return;


	    case Mangle.Tbyte:
		signed = 1;
		vnumber = va_arg!(byte)(argptr);
		goto Lnumber;

	    case Mangle.Tubyte:
		vnumber = va_arg!(ubyte)(argptr);
		goto Lnumber;

	    case Mangle.Tshort:
		signed = 1;
		vnumber = va_arg!(short)(argptr);
		goto Lnumber;

	    case Mangle.Tushort:
		vnumber = va_arg!(ushort)(argptr);
		goto Lnumber;

	    case Mangle.Tint:
		signed = 1;
		vnumber = va_arg!(int)(argptr);
		goto Lnumber;

	    case Mangle.Tuint:
	    Luint:
		vnumber = va_arg!(uint)(argptr);
		goto Lnumber;

	    case Mangle.Tlong:
		signed = 1;
		vnumber = cast(ulong)va_arg!(long)(argptr);
		goto Lnumber;

	    case Mangle.Tulong:
	    Lulong:
		vnumber = va_arg!(ulong)(argptr);
		goto Lnumber;

	    case Mangle.Tclass:
		vobject = va_arg!(Object)(argptr);
		if (vobject is null)
		    s = "null";
		else
		    s = vobject.toString();
		goto Lputstr;

	    case Mangle.Tpointer:
		vnumber = cast(size_t)va_arg!(void*)(argptr);
		uc = 1;
		flags |= FL0pad;
		if (!(flags & FLprecision))
		{   flags |= FLprecision;
		    precision = (void*).sizeof;
		}
		base = 16;
		goto Lnumber;


	    case Mangle.Tfloat:
	    case Mangle.Tifloat:
		if (fc == 'x' || fc == 'X')
		{
		    float f = va_arg!(float)(argptr);
		    vnumber = *cast(uint*)&f;
		    goto Lnumber;
		}
		vreal = va_arg!(float)(argptr);
		goto Lreal;

	    case Mangle.Tdouble:
	    case Mangle.Tidouble:
		if (fc == 'x' || fc == 'X')
		{
		    double f = va_arg!(double)(argptr);
		    vnumber = *cast(ulong*)&f;
		    goto Lnumber;
		}
		vreal = va_arg!(double)(argptr);
		goto Lreal;

	    case Mangle.Treal:
	    case Mangle.Tireal:
		vreal = va_arg!(real)(argptr);
		goto Lreal;


	    case Mangle.Tcfloat:
		vcreal = va_arg!(cfloat)(argptr);
		goto Lcomplex;

	    case Mangle.Tcdouble:
		vcreal = va_arg!(cdouble)(argptr);
		goto Lcomplex;

	    case Mangle.Tcreal:
		vcreal = va_arg!(creal)(argptr);
		goto Lcomplex;

	    case Mangle.Tsarray:
		/* Static arrays are converted to dynamic arrays when
		   passed as a variadic argument, so this code should
		   never be executed with GDC.  The case of an
		   embedded static array is handled below. */
		goto Lerror;

	    case Mangle.Tarray:
		int mi = 10;
	        if (ti.classinfo.name.length == 14 &&
		    ti.classinfo.name[9..14] == "Array") 
		{ // array of non-primitive types
		  TypeInfo tn = (cast(TypeInfo_Array)ti).next;
		  tn = skipCI(tn);
		  switch (cast(Mangle)tn.classinfo.name[9])
		  {
		    case Mangle.Tchar:  goto LarrayChar;
		    case Mangle.Twchar: goto LarrayWchar;
		    case Mangle.Tdchar: goto LarrayDchar;
		    default:
			break;
		  }
		  void[] va = va_arg!(void[])(argptr);
		  putArray(va.ptr, va.length, tn);
		  return;
		}
		if (ti.classinfo.name.length == 25 &&
		    ti.classinfo.name[9..25] == "AssociativeArray") 
		{ // associative array
		  ubyte[long] vaa = va_arg!(ubyte[long])(argptr);
		  putAArray(vaa,
			(cast(TypeInfo_AssociativeArray)ti).next,
			(cast(TypeInfo_AssociativeArray)ti).key);
		  return;
		}

		while (1)
		{
		    m2 = cast(Mangle)ti.classinfo.name[mi];
		    switch (m2)
		    {
			case Mangle.Tchar:
			LarrayChar:
			    s = va_arg!(char[])(argptr);
			    goto Lputstr;

			case Mangle.Twchar:
			LarrayWchar:
			    wchar[] sw = va_arg!(wchar[])(argptr);
			    s = toUTF8(sw);
			    goto Lputstr;

			case Mangle.Tdchar:
			LarrayDchar:
			    dchar[] sd = va_arg!(dchar[])(argptr);
			    s = toUTF8(sd);
			Lputstr:
			    if (fc != 's')
				throw new FormatError("string");
			    if (flags & FLprecision && precision < s.length)
				s = s[0 .. precision];
			    putstr(s);
			    break;

			case Mangle.Tconst:
			case Mangle.Tinvariant:
			    mi++;
			    continue;

			default:
			    TypeInfo ti2 = primitiveTypeInfo(m2);
			    if (!ti2)
			      goto Lerror;
			    void[] va = va_arg!(void[])(argptr);
			    putArray(va.ptr, va.length, ti2);
		    }
		    return;
		}
	    case Mangle.Ttypedef:
		ti = (cast(TypeInfo_Typedef)ti).base;
		m = cast(Mangle)ti.classinfo.name[9];
		formatArg(fc);
		return;

	    case Mangle.Tenum:
		ti = (cast(TypeInfo_Enum)ti).base;
		m = cast(Mangle)ti.classinfo.name[9];
		formatArg(fc);
		return;

	    case Mangle.Tstruct:
	    {	TypeInfo_Struct tis = cast(TypeInfo_Struct)ti;
		if (tis.xtoString is null)
		    throw new FormatError("Can't convert " ~ tis.toString() ~ " to string: \"string toString()\" not defined");
		static if
		    (
		     is( typeof(argptr): void[] ) ||
		     is( typeof(argptr) == struct ))
		{
		    version(PPC)
		    {
			// Structs are pass-by-reference in V4 ABI
			s = tis.xtoString(va_arg!(void*)(argptr));
		    }
		    else version(X86_64)
		    {
			throw new FormatError("cannot portably format a struct on this target");
		    }
		    else
		    {
			static assert(0, "unimplemented");
		    }
		}
		else
		{
		    s = tis.xtoString(argptr);
		    argptr += (tis.tsize() + 3) & ~3;
		}
		goto Lputstr;
	    }

	    default:
		goto Lerror;
	}
	else
	{
	    switch (m)
	    {
		case Mangle.Tbool:
		    vbit = *cast(bool*)(p_args); p_args += bool.sizeof; // int.sizeof, etc.?
		    if (fc != 's')
		    {   vnumber = vbit;
			goto Lnumber;
		    }
		    putstr(vbit ? "true" : "false");
		    return;
    
    
		case Mangle.Tchar:
		    vchar = *cast(char*)(p_args); p_args += char.sizeof;
		    if (fc != 's')
		    {   vnumber = vchar;
			goto Lnumber;
		    }
		PL2: // there is goto L2 outside of thise switch; it's okay to do that
		    putstr((&vchar)[0 .. 1]);
		    return;
    
		case Mangle.Twchar:
		    vdchar = *cast(wchar*)(p_args); p_args += wchar.sizeof;
		    goto PL1;
    
		case Mangle.Tdchar:
		    vdchar = *cast(dchar*)(p_args); p_args += dchar.sizeof;
		PL1:
		    if (fc != 's')
		    {   vnumber = vdchar;
			goto Lnumber;
		    }
		    if (vdchar <= 0x7F)
		    {   vchar = cast(char)vdchar;
			goto PL2;
		    }
		    else
		    {   if (!isValidDchar(vdchar))
			    throw new UtfException("invalid dchar in format", 0);
			char[4] vbuf;
			putstr(toUTF8(vbuf, vdchar));
		    }
		    return;
    
    
		case Mangle.Tbyte:
		    signed = 1;
		    vnumber = *cast(byte*)p_args; p_args += byte.sizeof;
		    goto Lnumber;
    
		case Mangle.Tubyte:
		    vnumber = *cast(ubyte*)p_args; p_args += ubyte.sizeof;
		    goto Lnumber;
    
		case Mangle.Tshort:
		    signed = 1;
		    vnumber = *cast(short*)p_args; p_args += short.sizeof;
		    goto Lnumber;
    
		case Mangle.Tushort:
		    vnumber = *cast(ushort*)p_args; p_args += ushort.sizeof;
		    goto Lnumber;
    
		case Mangle.Tint:
		    signed = 1;
		    vnumber = *cast(int*)p_args; p_args += int.sizeof;
		    goto Lnumber;
    
		case Mangle.Tuint:
		PLuint:
		    vnumber = *cast(uint*)p_args; p_args += uint.sizeof;
		    goto Lnumber;
    
		case Mangle.Tlong:
		    signed = 1;
		    vnumber = cast(ulong)*cast(long*)p_args; p_args += long.sizeof;
		    goto Lnumber;
    
		case Mangle.Tulong:
		PLulong:
		    vnumber = *cast(ulong*)p_args; p_args += ulong.sizeof;
		    goto Lnumber;
    
		case Mangle.Tclass:
		    vobject = *cast(Object*)p_args; p_args += Object.sizeof;
		    s = vobject.toString();
		    goto Lputstr;
    
		case Mangle.Tpointer:
		    alias void * void_ponter_t;
		    vnumber = cast(size_t)*cast(void**)p_args; p_args += void_ponter_t.sizeof;
		    uc = 1;
		    flags |= FL0pad;
		    if (!(flags & FLprecision))
		    {   flags |= FLprecision;
			precision = (void*).sizeof;
		    }
		    base = 16;
		    goto Lnumber;
    
    
		case Mangle.Tfloat:
		case Mangle.Tifloat:
		    if (fc == 'x' || fc == 'X')
			goto PLuint;
		    vreal = *cast(float*)p_args; p_args += float.sizeof;
		    goto Lreal;
    
		case Mangle.Tdouble:
		case Mangle.Tidouble:
		    if (fc == 'x' || fc == 'X')
			goto PLulong;
		    vreal = *cast(double*)p_args; p_args += double.sizeof;
		    goto Lreal;
    
		case Mangle.Treal:
		case Mangle.Tireal:
		    vreal = *cast(real*)p_args; p_args += real.sizeof;
		    goto Lreal;
    
    
		case Mangle.Tcfloat:
		    vcreal = *cast(cfloat*)p_args; p_args += cfloat.sizeof;
		    goto Lcomplex;
    
		case Mangle.Tcdouble:
		    vcreal = *cast(cdouble*)p_args; p_args += cdouble.sizeof;
		    goto Lcomplex;
    
		case Mangle.Tcreal:
		    vcreal = *cast(creal*)p_args; p_args += creal.sizeof;
		    goto Lcomplex;
    
		case Mangle.Tsarray:
		    putArray(p_args, (cast(TypeInfo_StaticArray)ti).len, (cast(TypeInfo_StaticArray)ti).next);
		    p_args += ti.tsize();
		    return;

		case Mangle.Tarray:
		    alias void[] array_t;
		    int mi = 10;
		    if (ti.classinfo.name.length == 14 &&
			ti.classinfo.name[9..14] == "Array") 
		    { // array of non-primitive types
		      TypeInfo tn = (cast(TypeInfo_Array)ti).next;
		      tn = skipCI(tn);
		      switch (cast(Mangle)tn.classinfo.name[9])
		      {
			case Mangle.Tchar:  goto LarrayChar_p;
			case Mangle.Twchar: goto LarrayWchar_p;
			case Mangle.Tdchar: goto LarrayDchar_p;
			default:
			    break;
		      }
		      void[] va = *cast(void[]*)p_args; p_args += array_t.sizeof;
		      putArray(va.ptr, va.length, tn);
		      return;
		    }
		    if (ti.classinfo.name.length == 25 &&
			ti.classinfo.name[9..25] == "AssociativeArray") 
		    { // associative array
		      ubyte[long] vaa = *cast(ubyte[long]*)p_args; p_args += vaa.sizeof;
		      putAArray(vaa,
			    (cast(TypeInfo_AssociativeArray)ti).next,
			    (cast(TypeInfo_AssociativeArray)ti).key);
		      return;
		    }

		    while (1)
		    {
			m2 = cast(Mangle)ti.classinfo.name[mi];
			switch (m2)
			{
			    case Mangle.Tchar:
			    LarrayChar_p:
				s = *cast(char[]*)p_args; p_args += array_t.sizeof;
				goto PLputstr;

			    case Mangle.Twchar:
			    LarrayWchar_p:
				wchar[] sw = *cast(wchar[]*)p_args; p_args += array_t.sizeof;
				s = toUTF8(sw);
				goto PLputstr;

			    case Mangle.Tdchar:
			    LarrayDchar_p:
				dchar[] sd = *cast(dchar[]*)p_args; p_args += array_t.sizeof;
				s = toUTF8(sd);
			    PLputstr:
				if (fc != 's')
				    throw new FormatError("string");
				if (flags & FLprecision && precision < s.length)
				    s = s[0 .. precision];
				putstr(s);
				break;

			    case Mangle.Tconst:
			    case Mangle.Tinvariant:
				mi++;
				continue;

			    default:
				TypeInfo ti2 = primitiveTypeInfo(m2);
				if (!ti2)
				  goto Lerror;
				void[] va = *cast(void[]*)p_args; p_args += array_t.sizeof;
				putArray(va.ptr, va.length, ti2);
			}
			return;
		    }
    
		case Mangle.Ttypedef:
		    ti = (cast(TypeInfo_Typedef)ti).base;
		    m = cast(Mangle)ti.classinfo.name[9];
		    formatArg(fc);
		    return;
    
		case Mangle.Tenum:
		    ti = (cast(TypeInfo_Enum)ti).base;
		    m = cast(Mangle)ti.classinfo.name[9];
		    formatArg(fc);
		    return;
		    
		case Mangle.Tstruct:
		{   TypeInfo_Struct tis = cast(TypeInfo_Struct)ti;
		    if (tis.xtoString is null)
			throw new FormatError("Can't convert " ~ tis.toString() ~ " to string: \"string toString()\" not defined");
		    s = tis.xtoString(p_args);
		    p_args += tis.tsize();
		    goto Lputstr;
		}

		default:
		    goto Lerror;
	    }
	}

    Lnumber:
	switch (fc)
	{
	    case 's':
	    case 'd':
		if (signed)
		{   if (cast(long)vnumber < 0)
		    {	prefix = "-";
			vnumber = -vnumber;
		    }
		    else if (flags & FLplus)
			prefix = "+";
		    else if (flags & FLspace)
			prefix = " ";
		}
		break;

	    case 'b':
		signed = 0;
		base = 2;
		break;

	    case 'o':
		signed = 0;
		base = 8;
		break;

	    case 'X':
		uc = 1;
		if (flags & FLhash && vnumber)
		    prefix = "0X";
		signed = 0;
		base = 16;
		break;

	    case 'x':
		if (flags & FLhash && vnumber)
		    prefix = "0x";
		signed = 0;
		base = 16;
		break;

	    default:
		goto Lerror;
	}

	if (!signed)
	{
	    switch (m)
	    {
		case Mangle.Tbyte:
		    vnumber &= 0xFF;
		    break;

		case Mangle.Tshort:
		    vnumber &= 0xFFFF;
		    break;

		case Mangle.Tint:
		    vnumber &= 0xFFFFFFFF;
		    break;

		default:
		    break;
	    }
	}

	if (flags & FLprecision && fc != 'p')
	    flags &= ~FL0pad;

	if (vnumber < base)
	{
	    if (vnumber == 0 && precision == 0 && flags & FLprecision &&
		!(fc == 'o' && flags & FLhash))
	    {
		putstr(null);
		return;
	    }
	    if (precision == 0 || !(flags & FLprecision))
	    {	vchar = cast(char)('0' + vnumber);
		if (vnumber < 10)
		    vchar = cast(char)('0' + vnumber);
		else
		    vchar = cast(char)((uc ? 'A' - 10 : 'a' - 10) + vnumber);
		goto L2;
	    }
	}

	int n = tmpbuf.length;
	char c;
	int hexoffset = uc ? ('A' - ('9' + 1)) : ('a' - ('9' + 1));

	while (vnumber)
	{
	    c = cast(char)((vnumber % base) + '0');
	    if (c > '9')
		c += hexoffset;
	    vnumber /= base;
	    tmpbuf[--n] = c;
	}
	if (tmpbuf.length - n < precision && precision < tmpbuf.length)
	{
	    int m = tmpbuf.length - precision;
	    tmpbuf[m .. n] = '0';
	    n = m;
	}
	else if (flags & FLhash && fc == 'o')
	    prefix = "0";
	putstr(tmpbuf[n .. tmpbuf.length]);
	return;

    Lreal:
	putreal(vreal);
	return;

    Lcomplex:
	putreal(vcreal.re);
	putc('+');
	putreal(vcreal.im);
	putc('i');
	return;

    Lerror:
	throw new FormatError("formatArg");
    }


    for (j = 0; j < arguments.length; )
    {	ti = arguments[j++];
	//printf("test1: '%.*s' %d\n", ti.classinfo.name, ti.classinfo.name.length);
	//ti.print();

	flags = 0;
	precision = 0;
	field_width = 0;

	ti = skipCI(ti);
	int mi = 9;
	do
	{
	    if (ti.classinfo.name.length <= mi)
		goto Lerror;
	    m = cast(Mangle)ti.classinfo.name[mi++];
	} while (m == Mangle.Tconst || m == Mangle.Tinvariant);

	if (m == Mangle.Tarray)
	{
	    if (ti.classinfo.name.length == 14 &&
		ti.classinfo.name[9..14] == "Array") 
	    {
	      TypeInfo tn = (cast(TypeInfo_Array)ti).next;
	      tn = skipCI(tn);
	      switch (cast(Mangle)tn.classinfo.name[9])
	      {
		case Mangle.Tchar:
		case Mangle.Twchar:
		case Mangle.Tdchar:
		    ti = tn;
		    mi = 9;
		    break;
		default:
		    break;
	      }
	    }
	L1:
	    Mangle m2 = cast(Mangle)ti.classinfo.name[mi];
	    string  fmt;			// format string
	    wstring wfmt;
	    dstring dfmt;

	    /* For performance reasons, this code takes advantage of the
	     * fact that most format strings will be ASCII, and that the
	     * format specifiers are always ASCII. This means we only need
	     * to deal with UTF in a couple of isolated spots.
	     */

	    if (! p_args)
	    switch (m2)
	    {
		case Mangle.Tchar:
		    fmt = va_arg!(char[])(argptr);
		    break;

		case Mangle.Twchar:
		    wfmt = va_arg!(wchar[])(argptr);
		    fmt = toUTF8(wfmt);
		    break;

		case Mangle.Tdchar:
		    dfmt = va_arg!(dchar[])(argptr);
		    fmt = toUTF8(dfmt);
		    break;

		case Mangle.Tconst:
		case Mangle.Tinvariant:
		    mi++;
		    goto L1;

		default:
		    formatArg('s');
		    continue;
	    }
	    else
	    {
		alias void[] array_t;
		switch (m2)
		{
		    case Mangle.Tchar:
			fmt = *cast(char[]*)p_args; p_args += array_t.sizeof;
			break;

		    case Mangle.Twchar:
			wfmt = *cast(wchar[]*)p_args; p_args += array_t.sizeof;
			fmt = toUTF8(wfmt);
			break;

		    case Mangle.Tdchar:
			dfmt = *cast(dchar[]*)p_args; p_args += array_t.sizeof;
			fmt = toUTF8(dfmt);
			break;

		    case Mangle.Tconst:
		    case Mangle.Tinvariant:
			mi++;
			goto L1;

		    default:
			formatArg('s');
			continue;
		}
	    }

	    for (size_t i = 0; i < fmt.length; )
	    {	dchar c = fmt[i++];

		dchar getFmtChar()
		{   // Valid format specifier characters will never be UTF
		    if (i == fmt.length)
			throw new FormatError("invalid specifier");
		    return fmt[i++];
		}

		int getFmtInt()
		{   int n;

		    while (1)
		    {
			n = n * 10 + (c - '0');
			if (n < 0)	// overflow
			    throw new FormatError("int overflow");
			c = getFmtChar();
			if (c < '0' || c > '9')
			    break;
		    }
		    return n;
		}

		int getFmtStar()
		{   Mangle m;
		    TypeInfo ti;

		    if (j == arguments.length)
			throw new FormatError("too few arguments");
		    ti = arguments[j++];
		    m = cast(Mangle)ti.classinfo.name[9];
		    if (m != Mangle.Tint)
			throw new FormatError("int argument expected");
		    if (! p_args)
		    return va_arg!(int)(argptr);
		    else
		    {
			int result = *cast(int*)(p_args); p_args += int.sizeof;
			return result;
		    }
		}

		if (c != '%')
		{
		    if (c > 0x7F)	// if UTF sequence
		    {
			i--;		// back up and decode UTF sequence
			c = std.utf.decode(fmt, i);
		    }
		Lputc:
		    putc(c);
		    continue;
		}

		// Get flags {-+ #}
		flags = 0;
		while (1)
		{
		    c = getFmtChar();
		    switch (c)
		    {
			case '-':	flags |= FLdash;	continue;
			case '+':	flags |= FLplus;	continue;
			case ' ':	flags |= FLspace;	continue;
			case '#':	flags |= FLhash;	continue;
			case '0':	flags |= FL0pad;	continue;

			case '%':	if (flags == 0)
					    goto Lputc;
			default:	break;
		    }
		    break;
		}

		// Get field width
		field_width = 0;
		if (c == '*')
		{
		    field_width = getFmtStar();
		    if (field_width < 0)
		    {   flags |= FLdash;
			field_width = -field_width;
		    }

		    c = getFmtChar();
		}
		else if (c >= '0' && c <= '9')
		    field_width = getFmtInt();

		if (flags & FLplus)
		    flags &= ~FLspace;
		if (flags & FLdash)
		    flags &= ~FL0pad;

		// Get precision
		precision = 0;
		if (c == '.')
		{   flags |= FLprecision;
		    //flags &= ~FL0pad;

		    c = getFmtChar();
		    if (c == '*')
		    {
			precision = getFmtStar();
			if (precision < 0)
			{   precision = 0;
			    flags &= ~FLprecision;
			}

			c = getFmtChar();
		    }
		    else if (c >= '0' && c <= '9')
			precision = getFmtInt();
		}

		if (j == arguments.length)
		    goto Lerror;
		ti = arguments[j++];
		ti = skipCI(ti);
		mi = 9;
		do
		{
		    m = cast(Mangle)ti.classinfo.name[mi++];
		} while (m == Mangle.Tconst || m == Mangle.Tinvariant);

		if (c > 0x7F)		// if UTF sequence
		    goto Lerror;	// format specifiers can't be UTF
		formatArg(cast(char)c);
	    }
	}
	else
	{
	    formatArg('s');
	}
    }
    return;

Lerror:
    throw new FormatError();
}

/* ======================== Unit Tests ====================================== */

version (skyos)
    version = no_hexfloat;

import std.stdio;//xx
unittest
{
    int i;
    string s;

    debug(format) printf("std.format.format.unittest\n");
 
    s = std.string.format("hello world! %s %s ", true, 57, 1_000_000_000, 'x', " foo");
    assert(s == "hello world! true 57 1000000000x foo");

    s = std.string.format(1.67, " %A ", -1.28, float.nan);
    /* The host C library is used to format floats.
     * C99 doesn't specify what the hex digit before the decimal point
     * is for %A.
     */
    /*
    printf("%.*s\n", s);
    printf("d:   %A\n",  -1.28);
    printf("r:   %LA\n", -1.28L);
    */
    version (no_hexfloat)
	{ /*nothing*/ }
    else
	assert(s == "1.67 -0XA.3D70A3D70A3D8P-3 nan" ||
	       s == "1.67 -0X1.47AE147AE147BP+0 nan");

    s = std.string.format("%x %X", 0x1234AF, 0xAFAFAFAF);
    assert(s == "1234af AFAFAFAF");

    s = std.string.format("%b %o", 0x1234AF, 0xAFAFAFAF);
    assert(s == "100100011010010101111 25753727657");

    s = std.string.format("%d %s", 0x1234AF, 0xAFAFAFAF);
    assert(s == "1193135 2947526575");

    s = std.string.format("%s", 1.2 + 3.4i);
    assert(s == "1.2+3.4i");

    s = std.string.format("%x %X", 1.32, 6.78f);
    assert(s == "3ff51eb851eb851f 40D8F5C3");

    s = std.string.format("%#06.*f",2,12.345);
    assert(s == "012.35");

    s = std.string.format("%#0*.*f",6,2,12.345);
    assert(s == "012.35");

    s = std.string.format("%7.4g:", 12.678);
    assert(s == "  12.68:");

    s = std.string.format("%7.4g:", 12.678L);
    assert(s == "  12.68:");

    s = std.string.format("%04f|%05d|%#05x|%#5x",-4.,-10,1,1);
    assert(s == "-4.000000|-0010|0x001|  0x1");

    i = -10;
    s = std.string.format("%d|%3d|%03d|%1d|%01.4f",i,i,i,i,cast(double) i);
    assert(s == "-10|-10|-10|-10|-10.0000");

    i = -5;
    s = std.string.format("%d|%3d|%03d|%1d|%01.4f",i,i,i,i,cast(double) i);
    assert(s == "-5| -5|-05|-5|-5.0000");

    i = 0;
    s = std.string.format("%d|%3d|%03d|%1d|%01.4f",i,i,i,i,cast(double) i);
    assert(s == "0|  0|000|0|0.0000");

    i = 5;
    s = std.string.format("%d|%3d|%03d|%1d|%01.4f",i,i,i,i,cast(double) i);
    assert(s == "5|  5|005|5|5.0000");

    i = 10;
    s = std.string.format("%d|%3d|%03d|%1d|%01.4f",i,i,i,i,cast(double) i);
    assert(s == "10| 10|010|10|10.0000");

    s = std.string.format("%.0d", 0);
    assert(s == "");

    s = std.string.format("%.g", .34);
    assert(s == "0.3");

    s = std.string.format("%.0g", .34);
    assert(s == "0.3");

    s = std.string.format("%.2g", .34);
    assert(s == "0.34");

    s = std.string.format("%0.0008f", 1e-08);
    assert(s == "0.00000001");

    s = std.string.format("%0.0008f", 1e-05);
    assert(s == "0.00001000");

    s = "helloworld";
    string r;
    r = std.string.format("%.2s", s[0..5]);
    assert(r == "he");
    r = std.string.format("%.20s", s[0..5]);
    assert(r == "hello");
    r = std.string.format("%8s", s[0..5]);
    assert(r == "   hello");

    byte[] arrbyte = new byte[4];
    arrbyte[0] = 100;
    arrbyte[1] = -99;
    arrbyte[3] = 0;
    r = std.string.format(arrbyte);
    assert(r == "[100,-99,0,0]");

    ubyte[] arrubyte = new ubyte[4];
    arrubyte[0] = 100;
    arrubyte[1] = 200;
    arrubyte[3] = 0;
    r = std.string.format(arrubyte);
    assert(r == "[100,200,0,0]");

    short[] arrshort = new short[4];
    arrshort[0] = 100;
    arrshort[1] = -999;
    arrshort[3] = 0;
    r = std.string.format(arrshort);
    assert(r == "[100,-999,0,0]");
    r = std.string.format("%s",arrshort);
    assert(r == "[100,-999,0,0]");

    ushort[] arrushort = new ushort[4];
    arrushort[0] = 100;
    arrushort[1] = 20_000;
    arrushort[3] = 0;
    r = std.string.format(arrushort);
    assert(r == "[100,20000,0,0]");

    int[] arrint = new int[4];
    arrint[0] = 100;
    arrint[1] = -999;
    arrint[3] = 0;
    r = std.string.format(arrint);
    assert(r == "[100,-999,0,0]");
    r = std.string.format("%s",arrint);
    assert(r == "[100,-999,0,0]");

    long[] arrlong = new long[4];
    arrlong[0] = 100;
    arrlong[1] = -999;
    arrlong[3] = 0;
    r = std.string.format(arrlong);
    assert(r == "[100,-999,0,0]");
    r = std.string.format("%s",arrlong);
    assert(r == "[100,-999,0,0]");

    ulong[] arrulong = new ulong[4];
    arrulong[0] = 100;
    arrulong[1] = 999;
    arrulong[3] = 0;
    r = std.string.format(arrulong);
    assert(r == "[100,999,0,0]");

    string[] arr2 = new string[4];
    arr2[0] = "hello";
    arr2[1] = "world";
    arr2[3] = "foo";
    r = std.string.format(arr2);
    assert(r == "[hello,world,,foo]");

    r = std.string.format("%.8d", 7);
    assert(r == "00000007");
    r = std.string.format("%.8x", 10);
    assert(r == "0000000a");

    r = std.string.format("%-3d", 7);
    assert(r == "7  ");

    r = std.string.format("%*d", -3, 7);
    assert(r == "7  ");

    r = std.string.format("%.*d", -3, 7);
    assert(r == "7");

    typedef int myint;
    myint m = -7;
    r = std.string.format(m);
    assert(r == "-7");

    r = std.string.format("abc"c);
    assert(r == "abc");
    r = std.string.format("def"w);
    assert(r == "def");
    r = std.string.format("ghi"d);
    assert(r == "ghi");

    void* p = cast(void*)0xDEADBEEF;
    r = std.string.format(p);
    assert(r == "DEADBEEF");

    r = std.string.format("%#x", 0xabcd);
    assert(r == "0xabcd");
    r = std.string.format("%#X", 0xABCD);
    assert(r == "0XABCD");

    r = std.string.format("%#o", 012345);
    assert(r == "012345");
    r = std.string.format("%o", 9);
    assert(r == "11");

    r = std.string.format("%+d", 123);
    assert(r == "+123");
    r = std.string.format("%+d", -123);
    assert(r == "-123");
    r = std.string.format("% d", 123);
    assert(r == " 123");
    r = std.string.format("% d", -123);
    assert(r == "-123");

    r = std.string.format("%%");
    assert(r == "%");

    r = std.string.format("%d", true);
    assert(r == "1");
    r = std.string.format("%d", false);
    assert(r == "0");

    r = std.string.format("%d", 'a');
    assert(r == "97");
    wchar wc = 'a';
    r = std.string.format("%d", wc);
    assert(r == "97");
    dchar dc = 'a';
    r = std.string.format("%d", dc);
    assert(r == "97");

    byte b = byte.max;
    r = std.string.format("%x", b);
    assert(r == "7f");
    r = std.string.format("%x", ++b);
    assert(r == "80");
    r = std.string.format("%x", ++b);
    assert(r == "81");

    short sh = short.max;
    r = std.string.format("%x", sh);
    assert(r == "7fff");
    r = std.string.format("%x", ++sh);
    assert(r == "8000");
    r = std.string.format("%x", ++sh);
    assert(r == "8001");

    i = int.max;
    r = std.string.format("%x", i);
    assert(r == "7fffffff");
    r = std.string.format("%x", ++i);
    assert(r == "80000000");
    r = std.string.format("%x", ++i);
    assert(r == "80000001");

    r = std.string.format("%x", 10);
    assert(r == "a");
    r = std.string.format("%X", 10);
    assert(r == "A");
    r = std.string.format("%x", 15);
    assert(r == "f");
    r = std.string.format("%X", 15);
    assert(r == "F");

    Object c = null;
    r = std.string.format(c);
    assert(r == "null");

    enum TestEnum
    {
	    Value1, Value2
    }
    r = std.string.format("%s", TestEnum.Value2);
    assert(r == "1");

    char[5][int] aa = ([3:"hello", 4:"betty"]);
    r = std.string.format("%s", aa.values);
    writefln(aa);
    assert(r == "[[h,e,l,l,o],[b,e,t,t,y]]");
    r = std.string.format("%s", aa);
    writefln(aa);
    assert(r == "[3:[h,e,l,l,o],4:[b,e,t,t,y]]");

    static const dchar[] ds = ['a','b'];
    for (int j = 0; j < ds.length; ++j)
    {
	r = std.string.format(" %d", ds[j]);
	if (j == 0)
	    assert(r == " 97");
	else
	    assert(r == " 98");
    }

    r = std.string.format(">%14d<, ", 15, [1,2,3]);
    assert(r == ">            15<, [1,2,3]");
}

