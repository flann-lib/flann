/*******************************************************************************

        copyright:      Copyright (c) 2007 Matthias Walter. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        June 2007 : initial release
        
        author:         Xammy

*******************************************************************************/

module tango.scrapple.io.protocol.PlainTextProtocol;

private import tango.io.protocol.model.IProtocol;
private import tango.io.Buffer;
private import tango.io.Conduit;
private import tango.text.Util;
private import tango.core.Exception;
private import Integer = tango.text.convert.Integer;
private import Float = tango.text.convert.Float;

private import tango.io.Stdout;

/*******************************************************************************

    This protocol is for compatibility to a widely used mechanism 
    for saving data to files and reading it back with methods
    like printf and scanf.

    Therefore, integer numbers and floats are converted to their
    string representations. Data is written in tokens
    which are seperated with whitespace.
    Except strings, which are written as one token,
    all arrays are writting as one token for one array element.
    
    The member prefix determines whether arrays are preceded 
    by their length. If not, the user must save it as a token of its own.

    Suppose you have a file of 4 integer vectors, each one
    containing 3 integers. One might save it this way:
    ---
    4 3

     1  2  3
     4  5  6
     7  8  9
    10 11 12
    ---
    To read them, simply attach an instance to a Buffer and your
    Reader / Writer to it.

    ---
    auto file = new FileConduit ("vectors.txt");
    auto buffer = new Buffer (file);

    // 2nd arg is false, because each vector is not preceeded by it's length
    auto protocol = new PlainTextProtocol (buffer, false);

    auto reader = new Reader (protocol);

    int numOfVectors, vectorSize;
    int[][] vectorArray;

    reader (numOfVectors) (vectorSize);

    for (int i = 0; i < numOfVectors; i++)
    {
        int[] vec = new int [vectorSize];

        // number of tokens to read is given via vec.length
        reader (vec);

        vectorArray ~= vec;
    }
    ---

*******************************************************************************/

class PlainTextProtocol : IProtocol
{
    protected IBuffer buffer_; // Buffer, we're  associated to
    uint precision = 6; /// Precision, floating point data is saved with.
    bool prefix; /// Whether arrays are preceeded by their size

    /***************************************************************************

        Construct a buffer upon the given buffer

    ***************************************************************************/

    this (Buffer buffer, bool _prefix = true)
    {
        buffer_ = buffer;
        prefix = _prefix;
    }
    
    /***************************************************************************

        Construct a buffer upon the given conduit, placing a buffer between

    ***************************************************************************/

    this (IConduit conduit, bool _prefix = true)
    {
        this (new Buffer (conduit), _prefix);
    }

    /***************************************************************************

        Return the buffer associated with this reader

    ***************************************************************************/

    IBuffer buffer ()
    {
        return buffer_;
    }

    /***************************************************************************

        Internal write method. You should not use it directly.
        Take a look at the Reader class instead.

    ***************************************************************************/

    void write (void* src, uint bytes, Type type)
    {
        char[] suffix = " ";

        switch (type)
        {
        case Type.Void: 
        case Type.Obj:
        case Type.Pointer:
            break;
        case Type.Utf8:
            if (! isSpace (* cast(char*) src))
                buffer_.append (src, bytes);
            else
                suffix = "\n";
            break;
        case Type.Utf16:
            if (! isSpace (* cast(wchar*) src))
                buffer_.append (src, bytes);
            else
                suffix = "\n";
            break;
        case Type.Utf32:
            if (! isSpace (* cast(dchar*) src))
                buffer_.append (src, bytes);
            else
                suffix = "\n";
            break;
        case Type.Bool:
            buffer_.append (*(cast(bool*)src) ? "true" : "false");
            break;
        case Type.Byte:
        case Type.UByte:
        case Type.Short:
        case Type.UShort:
        case Type.Int:
        case Type.UInt:
        case Type.Long:
        case Type.ULong:
            writeInteger (src, type);
        break;
        case Type.Float:
        case Type.Double:
        case Type.Real:
            writeFloat (src, type);
        break;
        }
        buffer_.append (suffix);
        buffer_.flush ();
    }

    /***************************************************************************

        Internal writeArray method. You should not use it directly.
        Take a look at the Reader class insteadt.

    ***************************************************************************/

    void writeArray (void* src, uint bytes, Type type)
    {
        switch (type)
        {
        case Type.Void: 
        case Type.Obj:
        case Type.Pointer:
            return;
        case Type.Utf8:
        case Type.Utf16:
        case Type.Utf32: 
            write (src, bytes, type);
            break;
        case Type.Bool:
        case Type.Byte:
        case Type.UByte:
        case Type.Short:
        case Type.UShort:
        case Type.Int:
        case Type.UInt:
        case Type.Long:
        case Type.ULong:
        case Type.Float:
        case Type.Double:
        case Type.Real:
            writeTokenArray (src, bytes, type);
        break;
        }
    }
    
    /***************************************************************************

        Internal read method. You should not use it directly.
        Take a look at the Reader class insteadt.

    ***************************************************************************/

    void[] read (void* dst, uint bytes, Type type)
    {
        switch (type)
        {
        case Type.Void: 
        case Type.Obj:
        case Type.Pointer:
            return null;
        case Type.Utf8:
        case Type.Utf16:
        case Type.Utf32:
            char[] temp = cast(char[]) dst[0 .. bytes];
            char[] token = readToken (temp);
            if (token.length != bytes)
                throw new IOException ("\"" ~ token ~ "\" is not a valid character");
            return token;
        case Type.Bool:
            char[5] temp = void;
            char[] token = readToken (temp);
            if (token == "true")
                *cast(bool*)dst = true;
            else if (token == "false")
                *cast(bool*)dst = false;
            else
                throw new IOException ("\"" ~ token ~ "\" is not a valid bool");
            return dst[0 .. bytes];
        case Type.Byte: 
        case Type.UByte:
        case Type.Short:
        case Type.UShort:
        case Type.Int:
        case Type.UInt:
        case Type.Long:
        case Type.ULong:
            return readInteger (dst, bytes, type);
        case Type.Float:
        case Type.Double:
        case Type.Real:
            return readFloat (dst, bytes, type);
        }
    }
    
    /***************************************************************************

        Internal readArray method. You should not use it directly.
        Take a look at the Reader class insteadt.

    ***************************************************************************/

    void[] readArray (void* dst, uint bytes, Type type, Allocator alloc)
    {
        char[] temp = cast(char[]) dst[0 .. bytes];
        char[] token = void;

        switch (type)
        {
        case Type.Void: 
            return null;
        case Type.Utf8:
        case Type.Utf16:
        case Type.Utf32:
        case Type.Obj:
        case Type.Pointer:
            return readToken (temp);
        case Type.Bool:
        case Type.Byte:
        case Type.UByte:
        case Type.Short:
        case Type.UShort:
        case Type.Int:
        case Type.UInt:
        case Type.Long:
        case Type.ULong:
        case Type.Float:
        case Type.Double:
        case Type.Real:
            return readTokenArray (dst, bytes, type);
        }
        return null;
    }

    /***************************************************************************

        Writes an integer *src of type to buffer.

    ***************************************************************************/

    protected void writeInteger (void* src, Type type)
    {
        char[66] temp;

        switch (type)
        {
            case Type.Byte:
                buffer_.append ( Integer.format (temp, * cast (byte *) src, Integer.Style.Signed) );
            break;
            case Type.UByte:
                buffer_.append ( Integer.format (temp, * cast (ubyte *) src, Integer.Style.Unsigned) );
            break;
            case Type.Short:
                buffer_.append ( Integer.format (temp, * cast (short *) src, Integer.Style.Signed) );
            break;
            case Type.UShort:
                buffer_.append ( Integer.format (temp, * cast (ushort *) src, Integer.Style.Unsigned) );
            break;
            case Type.Int:
                buffer_.append ( Integer.format (temp, * cast (int *) src, Integer.Style.Signed) );
            break;
            case Type.UInt:
                buffer_.append ( Integer.format (temp, * cast (uint *) src, Integer.Style.Unsigned) );
            break;
            case Type.Long:
                buffer_.append ( Integer.format (temp, * cast (long *) src, Integer.Style.Signed) );
            break;
            case Type.ULong:
                buffer_.append ( Integer.format (temp, * cast (ulong *) src, Integer.Style.Unsigned) );
            break;
            default:
                assert (false);
        }
    }
    
    /***************************************************************************

        Writes a float *src of type T to buffer.

    ***************************************************************************/

    protected void writeFloat (void* src, Type type)
    {
        char[66] temp;

        switch (type)
        {
            case Type.Float:
                buffer_.append ( Float.format (temp, * cast (float *) src, precision) );
            break;
            case Type.Double:
                buffer_.append ( Float.format (temp, * cast (double *) src, precision) );
            break;
            case Type.Real:
                buffer_.append ( Float.format (temp, * cast (real *) src, precision) );
            break;
            default:
                assert (false);
        }
    }
    
    /***************************************************************************

        Returns size of type.

    ***************************************************************************/

    protected ubyte typeSize (Type type)
    {
        switch (type)
        {
            case Type.Bool:
            case Type.Byte:
            case Type.UByte:
                return 1;
            case Type.Short:
            case Type.UShort:
                return 2;
            case Type.Int:
            case Type.UInt:
            case Type.Float:
                return 4;
            case Type.Long:
            case Type.ULong:
            case Type.Double:
                return 8;
            case Type.Real:
                return 12;
            default:
                assert (false);
                return 0;
        }
    }

    /***************************************************************************

        Writes an array token by token.

    ***************************************************************************/

    protected void writeTokenArray (void* src, uint bytes, Type type)
    {
        uint each = typeSize (type);
        uint size = bytes / each;
        if (prefix)
            write (&size, uint.sizeof, Type.UInt);
        for (int i = 0; i < size; i++)
        {
            write (src + i * each, each, type);
        }
    } 

    /***************************************************************************

        Reads one token by searching for whitespace / newline / eof

    ***************************************************************************/

    protected char[] readToken (char[] temp)
    {
        size_t position = 0;
        bool onHeap = false;
        char[1] s;

        while (buffer_.read (s) != IConduit.Eof)
        {
            char c = s[0];
            if (isSpace(c))
            {
                // token starts with whitespace - skip
                if (position == 0)
                    continue;
                return temp[0 .. position];
            }
            else
            {
                if (position >= temp.length)
                {
                    if (!onHeap)
                    {
                        temp = temp.dup;
                        onHeap = true;
                    }
                    temp.length = 2*temp.length+8;
                }
                temp[position++] = c;
            }
        }
        return temp[0 .. position];
    }
    
    /***************************************************************************

        Reads an integer from the buffer.

    ***************************************************************************/

    protected void[] readInteger (void* dst, uint bytes, Type type)
    {
        uint len;
        char[66] temp = void;
        char[] token = readToken (temp);

        switch (type)
        {
            case Type.Byte:
                *(cast (byte *) dst) = Integer.parse (token, 10, &len);
            break;
            case Type.UByte:
                *(cast (ubyte *) dst) = Integer.parse (token, 10, &len);
            break;
            case Type.Short:
                *(cast (short *) dst) = Integer.parse (token, 10, &len);
            break;
            case Type.UShort:
                *(cast (ushort *) dst) = Integer.parse (token, 10, &len);
            break;
            case Type.Int:
                *(cast (int *) dst) = Integer.parse (token, 10, &len);
            break;
            case Type.UInt:
                *(cast (uint *) dst) = Integer.parse (token, 10, &len);
            break;
            case Type.Long:
                *(cast (long *) dst) = Integer.parse (token, 10, &len);
            break;
            case Type.ULong:
                *(cast (ulong *) dst) = Integer.parse (token, 10, &len);
            break;
            default:
                assert (false);
        }
        if (len != token.length)
            throw new IOException ("\"" ~ token ~ "\" is not a valid integer");
        return dst[0 .. bytes];
    }
    
    /***************************************************************************

        Reads a float from the buffer.

    ***************************************************************************/

    protected void[] readFloat (void* dst, uint bytes, Type type)
    {
        uint len;
        char[66] temp = void;
        char[] token = readToken (temp);

        switch (type)
        {
            case Type.Float:
                * cast (float *) dst = Float.parse (token, &len);
            break;
            case Type.Double:
                * cast (double *) dst = Float.parse (token, &len);
            break;
            case Type.Real:
                * cast (real *) dst = Float.parse (token, &len);
            break;
            default:
                assert (false);
        }
        if (len != token.length)
            throw new IOException ("\"" ~ token ~ "\" is not a valid float");
        return dst[0 .. bytes];
    }
    
    /***************************************************************************

        Reads an array of tokens and calls read for each.
        The size is calculated by the formula  bytes / T.sizeof

    ***************************************************************************/

    protected void[] readTokenArray (void* dst, uint bytes, Type type)
    {
        uint each = typeSize (type);
        uint size = void;

        void[] result;
        if (prefix)
        {
            read (&size, uint.sizeof, Type.UInt);
            result = new void [size * each];
        }
        else
        {
            size = bytes / each;
            result = dst[0 .. bytes];
        }
            
        for (int i=0; i<size; i++)
        {
            read (result.ptr + (i * each), each, type);
        }

        return result;
    }
} 



/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{
    import tango.io.protocol.Reader;
    import tango.io.protocol.Writer;
    import tango.text.convert.Integer;

    unittest
    {
        byte b = byte.min;
        ubyte ub = ubyte.max;
        short s = short.min;
        ushort us = ushort.max;
        int i = int.min;
        uint ui = uint.max;
        long l = long.min;
        ulong ul = ulong.max;
        float f = 3.14159f;
        double d = 3.14159;
        real r = 3.14159;
        char c = 'c';
        wchar wc = 'w';
        dchar dc = 'd';
        char[] ac = "char[]";
        wchar[] awc = "wchar[]";
        dchar[] adc = "dchar[]";
        int[] ai = [1, 2, 3];

        auto buffer = new Buffer (1024);
        auto protocol = new PlainTextProtocol (buffer);
        auto output = new Writer (protocol);
        auto input = new Reader (protocol);

        output (b) (ub) (s) (us) (i) (ui) (l) (ul) ('\n') (f) (d) (r) ('\n') (c) (wc) (dc) ('\n') (ac) (awc) (adc) ('\n');
        assert (protocol.prefix == true);
        output (ai) ('\n');
        protocol.prefix = false;
        output (ai) ('\n');

        assert (buffer.slice[0 .. 118] == "-128 255 -32768 65535 -2147483648 4294967295 -9223372036854775808 18446744073709551615 \n3.141590 3.141590 3.141590 \nc "c);
        assert (buffer.slice[118 .. 120] == "w"w);
        assert (buffer.slice[120 .. 121] == " "c);
        assert (buffer.slice[121 .. 125] == "d"d);
        assert (buffer.slice[125 .. 134] == " \nchar[] "c);
        assert (buffer.slice[134 .. 148] == "wchar[]"w);
        assert (buffer.slice[148 .. 149] == " "c);
        assert (buffer.slice[149 .. 177] == "dchar[]"d);
        assert (buffer.slice[177 .. 179] == " \n"c);
        assert (buffer.slice[179 .. 195] == "3 1 2 3 \n1 2 3 \n"c);

        l = ul = i = ui = s = us = b = us = 0;
        r = d = f = 0.0;
        c = ' ';
        wc = ' ';
        dc = ' ';
        ac = "";
        awc = "";
        adc = "";
        ai = [4,5,6];
        int[] ai2 = [];
    
        input (b) (ub) (s) (us) (i) (ui) (l) (ul) (f) (d) (r) (c) (wc) (dc) (ac) (awc) (adc);
        protocol.prefix = true;
        input (ai2);
        protocol.prefix = false;
        input (ai);
    
        assert (b == byte.min);
        assert (ub == ubyte.max);
        assert (s == short.min);
        assert (us == ushort.max);
        assert (i == int.min);
        assert (ui == uint.max);
        assert (l == long.min);
        assert (ul == ulong.max);

        assert (f == 3.14159f);
        assert (d == 3.14159);
        assert (r == 3.14159);
        assert (c == 'c');
        assert (wc == 'w');
        assert (dc == 'd');
        assert (ac == "char[]"c);
        assert (awc == "wchar[]"w);
        assert (adc == "dchar[]"d);
        assert (ai2 == [1, 2, 3]);
        assert (ai == [1, 2, 3]);
    }
}
