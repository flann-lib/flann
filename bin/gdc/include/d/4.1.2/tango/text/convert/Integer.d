/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: Nov 2005
        
        author:         Kris

        A set of functions for converting between string and integer 
        values. 

        Applying the D "import alias" mechanism to this module is highly
        recommended, in order to limit namespace pollution:
        ---
        import Integer = tango.text.convert.Integer;

        auto i = Integer.parse ("32767");
        ---
        
*******************************************************************************/

module tango.text.convert.Integer;

private import tango.core.Exception;

/******************************************************************************

        Style identifiers 

******************************************************************************/

enum Style
{
        Signed = 'd',                   /// signed decimal
        Binary = 'b',                   /// binary output
        Octal = 'o',                    /// octal output
        Hex = 'x',                      /// lowercase hexadecimal
        HexUpper = 'X',                 /// uppercase hexadecimal
        Unsigned = 'u',                 /// unsigned integer
}

/******************************************************************************

        Style flags 

******************************************************************************/

enum Flags
{
        None    = 0x00,                    /// no flags
        Prefix  = 0x01,                    /// prefix value with type
        Zero    = 0x02,                    /// prefix value with zeroes
        Plus    = 0x04,                    /// prefix decimal with '+'
        Space   = 0x08,                    /// prefix decimal with space
        Throw   = 0x10,                    /// throw on output truncation
}

/******************************************************************************

        Parse an integer value from the provided 'digits' string. 

        The string is inspected for a sign and an optional radix 
        prefix. A radix may be provided as an argument instead, 
        whereupon it must match the prefix (where present). When
        radix is set to zero, conversion will default to decimal.

        Throws an exception where the input text is not parsable
        in its entirety.
        
******************************************************************************/

int toInt(T, U=uint) (T[] digits, U radix=0)
{return toInt!(T)(digits, radix);}

int toInt(T) (T[] digits, uint radix=0)
{
        auto x = toLong (digits, radix);
        if (x > int.max)
            throw new IllegalArgumentException ("Integer.toInt :: integer overflow");
        return cast(int) x;
}

/******************************************************************************

        Parse an integer value from the provided 'digits' string.       
        
        The string is inspected for a sign and an optional radix 
        prefix. A radix may be provided as an argument instead, 
        whereupon it must match the prefix (where present). When
        radix is set to zero, conversion will default to decimal.

        Throws an exception where the input text is not parsable
        in its entirety.
        
******************************************************************************/

long toLong(T, U=uint) (T[] digits, U radix=0)
{return toLong!(T)(digits, radix);}

long toLong(T) (T[] digits, uint radix=0)
{
        uint len;

        auto x = parse (digits, radix, &len);
        if (len < digits.length)
            throw new IllegalArgumentException ("Integer.toLong :: invalid literal");
        return x;
}

/******************************************************************************

        Template wrapper to make life simpler. Returns a text version
        of the provided value.

        See format() for details

******************************************************************************/

char[] toString (long i, Style t=Style.Signed, Flags f=Flags.None)
{
        char[66] tmp = void;
        
        return format (tmp, i, t, f).dup;
}
               
/******************************************************************************

        Template wrapper to make life simpler. Returns a text version
        of the provided value.

        See format() for details

******************************************************************************/

wchar[] toString16 (long i, Style t=Style.Signed, Flags f=Flags.None)
{
        wchar[66] tmp = void;
        
        return format (tmp, i, t, f).dup;
}
               
/******************************************************************************

        Template wrapper to make life simpler. Returns a text version
        of the provided value.

        See format() for details

******************************************************************************/

dchar[] toString32 (long i, Style t=Style.Signed, Flags f=Flags.None)
{
        dchar[66] tmp = void;
        
        return format (tmp, i, t, f).dup;
}
               
/*******************************************************************************

        Style numeric values into the provided output buffer. The
        following types are supported:

        Unsigned        - unsigned decimal
        Signed          - signed decimal
        Octal           - octal
        Hex             - lowercase hexadecimal
        HexUpper        - uppercase hexadecimal
        Binary          - binary

        Modifiers supported include:

        Prefix          - prefix the conversion with a type identifier
        Plus            - prefix positive decimals with a '+'
        Space           - prefix positive decimals with one space
        Zero            - left-pad the number with zeros
        Throw           - throw an exception when output would be truncated

        The provided 'dst' buffer should be sufficiently large
        enough to house the output. A 64-element array is often
        the maximum required (for a padded binary 64-bit string)

*******************************************************************************/

T[] format(T, U=long) (T[] dst, U i, Style fmt=Style.Signed, Flags flags=Flags.None)
{return format!(T)(dst, i, fmt, flags);}

T[] format(T) (T[] dst, long i, Style fmt=Style.Signed, Flags flags=Flags.None)
{
        T[]     prefix;
        auto    len = dst.length;
        
        static T[] error (T[] msg)
        {
                if (1 & Flags.Throw)
                    throw new IllegalArgumentException ("Integer.format :: invalid arguments");
                 return msg;
        }

        // must have some buffer space to operate within! 
        if (len)
           {
           uint radix;
           T[]  numbers = "0123456789abcdef";

           // pre-conversion setup
           switch (cast(byte) fmt)
                  {
                  case 'd':
                  case 'D':
                       if (i < 0)
                          {
                          prefix = "-";
                          i = -i;
                          }
                       else
                          if (flags & Flags.Space)
                              prefix = " ";
                          else
                             if (flags & Flags.Plus)
                                 prefix = "+";
                       // fall through!
                  case 'u':
                  case 'U':
                       radix = 10;
                       break;

                  case 'b':
                  case 'B':
                       radix = 2;
                       if (flags & Flags.Prefix)
                           prefix = "0b";
                       break;

                  case 'o':
                  case 'O':
                       radix = 8;
                       if (flags & Flags.Prefix)
                           prefix = "0o";
                       break;

                  case 'x':
                       radix = 16;
                       if (flags & Flags.Prefix)
                           prefix = "0x";
                       break;

                  case 'X':
                       radix = 16;
                       numbers = "0123456789ABCDEF";
                       if (flags & Flags.Prefix)
                           prefix = "0X";
                       break;

                  default:
                        return error (cast(T[])"{unknown format '"~cast(T)fmt~"'}");
                  }

           // convert number to text
           T* p = dst.ptr + len;
           if (uint.max >= cast(ulong) i)
              {
              uint v = cast (uint) i;
              do {
                 *--p = numbers[v % radix];
                 } while ((v /= radix) && --len);
              }
           else
              {
              ulong v = cast (ulong) i;
              do {
                 *--p = numbers[cast(uint) (v % radix)];
                 } while ((v /= radix) && --len);
              }
           }
        
        // are we about to overflow?
        if (len > prefix.length)
           {
           len -= prefix.length + 1;

           // prefix number with zeros? 
           if (flags & Flags.Zero)
              {
              dst [prefix.length .. len + prefix.length] = '0';
              len = 0;
              }

           // write optional prefix string ...
           dst [len .. len + prefix.length] = prefix[];
           }
        else
           return error ("{output width too small}");

        // return slice of provided output buffer
        return dst [len .. $];                               
} 


/******************************************************************************

        Parse an integer value from the provided 'digits' string. 

        The string is inspected for a sign and an optional radix 
        prefix. A radix may be provided as an argument instead, 
        whereupon it must match the prefix (where present). When
        radix is set to zero, conversion will default to decimal.

        A non-null 'ate' will return the number of characters used
        to construct the returned value.

******************************************************************************/

long parse(T, U=uint) (T[] digits, U radix=0, uint* ate=null)
{return parse!(T)(digits, radix, ate);}

long parse(T) (T[] digits, uint radix=0, uint* ate=null)
{
        bool sign;

        auto eaten = trim (digits, sign, radix);
        auto value = convert (digits[eaten..$], radix, ate);

        if (ate)
            *ate += eaten;

        return cast(long) (sign ? -value : value);
}

/******************************************************************************

        Convert the provided 'digits' into an integer value,
        without checking for a sign or radix. The radix defaults
        to decimal (10).

        Returns the value and updates 'ate' with the number of
        characters consumed.

******************************************************************************/

ulong convert(T, U=uint) (T[] digits, U radix=10, uint* ate=null)
{return convert!(T)(digits, radix, ate);}

ulong convert(T) (T[] digits, uint radix=10, uint* ate=null)
{
        uint  eaten;
        ulong value;

        foreach (c; digits)
                {
                if (c >= '0' && c <= '9')
                   {}
                else
                   if (c >= 'a' && c <= 'f')
                       c -= 39;
                   else
                      if (c >= 'A' && c <= 'F')
                          c -= 7;
                      else
                         break;

                if ((c -= '0') < radix)
                   {
                   value = value * radix + c;
                   ++eaten;
                   }
                else
                   break;
                }

        if (ate)
            *ate = eaten;

        return value;
}


/******************************************************************************

        Strip leading whitespace, extract an optional +/- sign,
        and an optional radix prefix. If the radix value matches
        an optional prefix, or the radix is zero, the prefix will
        be consumed and assigned. Where the radix is non zero and
        does not match an explicit prefix, the latter will remain 
        unconsumed. Otherwise, radix will default to 10.

        Returns the number of characters consumed.

******************************************************************************/

uint trim(T, U=uint) (T[] digits, inout bool sign, inout U radix)
{return trim!(T)(digits, sign, radix);}

uint trim(T) (T[] digits, inout bool sign, inout uint radix)
{
        T       c;
        T*      p = digits.ptr;
        int     len = digits.length;

        if (len)
           {
           // strip off whitespace and sign characters
           for (c = *p; len; c = *++p, --len)
                if (c is ' ' || c is '\t')
                   {}
                else
                   if (c is '-')
                       sign = true;
                   else
                      if (c is '+')
                          sign = false;
                   else
                      break;

           // strip off a radix specifier also?
           auto r = radix;
           if (c is '0' && len > 1)
               switch (*++p)
                      {
                      case 'x':
                      case 'X':
                           r = 16, ++p;
                           break;
 
                      case 'b':
                      case 'B':
                           r = 2, ++p;
                           break;
 
                      case 'o':
                      case 'O':
                           r = 8, ++p;
                           break;
 
                      default: 
                           break;
                      } 

           // default the radix to 10
           if (r is 0)
               radix = 10;
           else
              // explicit radix must match (optional) prefix
              if (radix != r)
                  if (radix)
                      --p;
                  else
                     radix = r;
           }

        // return number of characters eaten
        return (p - digits.ptr);
}


/******************************************************************************

        quick & dirty text-to-unsigned int converter. Use only when you
        know what the content is, or use parse() or convert() instead.

        Return the parsed uint
        
******************************************************************************/

uint atoi(T) (T[] s)
{
        uint value;

        foreach (c; s)
                 if (c >= '0' && c <= '9')
                     value = value * 10 + (c - '0');
                 else
                    break;
        return value;
}


/******************************************************************************

        quick & dirty unsigned to text converter, where the provided output
        must be large enough to house the result (10 digits in the largest
        case). For mainstream use, consider utilizing format() instead.

        Returns a populated slice of the provided output
        
******************************************************************************/

T[] itoa(T, U=uint) (T[] output, U value)
{return itoa!(T)(output, value);}

T[] itoa(T) (T[] output, uint value)
{
        T* p = output.ptr + output.length;

        do {
           *--p = value % 10 + '0';
           } while (value /= 10);
        return output[p-output.ptr .. $];
}


/******************************************************************************

******************************************************************************/

debug (UnitTest)
{
        unittest
        {
        char[64] tmp;
        
        assert (toInt("1") is 1);
        assert (toLong("1") is 1);
        assert (toInt("1", 10) is 1);
        assert (toLong("1", 10) is 1);

        assert (atoi ("12345") is 12345);
        assert (itoa (tmp, 12345) == "12345");

        assert(parse( "0"w ) ==  0 );
        assert(parse( "1"w ) ==  1 );
        assert(parse( "-1"w ) ==  -1 );
        assert(parse( "+1"w ) ==  1 );

        // numerical limits
        assert(parse( "-2147483648" ) == int.min );
        assert(parse(  "2147483647" ) == int.max );
        assert(parse(  "4294967295" ) == uint.max );

        assert(parse( "-9223372036854775808" ) == long.min );
        assert(parse( "9223372036854775807" ) == long.max );
        assert(parse( "18446744073709551615" ) == ulong.max );

        // hex
        assert(parse( "a", 16) == 0x0A );
        assert(parse( "b", 16) == 0x0B );
        assert(parse( "c", 16) == 0x0C );
        assert(parse( "d", 16) == 0x0D );
        assert(parse( "e", 16) == 0x0E );
        assert(parse( "f", 16) == 0x0F );
        assert(parse( "A", 16) == 0x0A );
        assert(parse( "B", 16) == 0x0B );
        assert(parse( "C", 16) == 0x0C );
        assert(parse( "D", 16) == 0x0D );
        assert(parse( "E", 16) == 0x0E );
        assert(parse( "F", 16) == 0x0F );
        assert(parse( "FFFF", 16) == ushort.max );
        assert(parse( "ffffFFFF", 16) == uint.max );
        assert(parse( "ffffFFFFffffFFFF", 16u ) == ulong.max );
        // oct
        assert(parse( "55", 8) == 055 );
        assert(parse( "100", 8) == 0100 );
        // bin
        assert(parse( "10000", 2) == 0x10 );
        // trim
        assert(parse( "    \t20") == 20 );
        assert(parse( "    \t-20") == -20 );
        assert(parse( "-    \t 20") == -20 );
        // recognise radix prefix
        assert(parse( "0xFFFF" ) == ushort.max );
        assert(parse( "0XffffFFFF" ) == uint.max );
        assert(parse( "0o55") == 055 );
        assert(parse( "0O55" ) == 055 );
        assert(parse( "0b10000") == 0x10 );
        assert(parse( "0B10000") == 0x10 );

        // prefix tests
        char[] str = "0x";
        assert(parse( str[0..1] ) ==  0 );
        assert(parse("0x10", 10) == 0);
        assert(parse("0b10", 10) == 0);
        assert(parse("0o10", 10) == 0);
        assert(parse("0b10") == 0b10);
        assert(parse("0o10") == 010);
        assert(parse("0b10", 2) == 0b10);
        assert(parse("0o10", 8) == 010);

        // format tests
        assert (format (tmp, 12345L) == "12345");
        assert (format (tmp, 0) == "0");
        assert (format (tmp, 0x10101L, Style.Hex) == "10101");
        assert (format (tmp, 0xfafaL, Style.Hex) == "fafa");
        assert (format (tmp, 0xfafaL, Style.HexUpper, Flags.Prefix) == "0XFAFA");
        assert (format (tmp, -1L, Style.HexUpper, Flags.Prefix) == "0XFFFFFFFFFFFFFFFF");
        assert (format (tmp, -101L) == "-101");
        assert (format (tmp, 101L, Style.Signed, Flags.Plus) == "+101");
        assert (format (tmp, 101L, Style.Signed, Flags.Space) == " 101");
        assert (format (tmp[0..8], 0x5L, Style.Binary, Flags.Prefix | Flags.Zero) == "0b000101");

        assert (format (tmp[0..8], -1, Style.Binary, Flags.Prefix | Flags.Zero) == "{output width too small}");
        assert (format (tmp[0..2], 0x3, Style.Binary, Flags.Throw) == "11");
        assert (format (tmp[0..4], 0x3, Style.Binary, Flags.Prefix | Flags.Zero | Flags.Throw) == "0b11");
        assert (format (tmp[0..5], 0x3, Style.Binary, Flags.Prefix | Flags.Zero | Flags.Throw) == "0b011");
        assert (format (tmp[0..5], 0x3, Style.Binary, Flags.Zero | Flags.Throw) == "00011");
        }
}

