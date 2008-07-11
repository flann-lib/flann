/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Nov 2007

        author:         Kris

        UTF conversion streams, supporting cross-translation of char, wchar 
        and dchar variants. For supporting endian variations, configure the
        appropriate EndianStream upstream of this one (closer to the source)

*******************************************************************************/

module tango.io.stream.UtfStream;

private import  tango.io.Buffer,
                tango.io.Conduit;

private import Utf = tango.text.convert.Utf;

/*******************************************************************************

        Streaming UTF converter. Type T is the target or destination type, 
        while S is the source type. Both types are either char/wchar/dchar.

*******************************************************************************/

class UtfInput(T, S) : InputFilter
{       
        static if (!is (S == char) && !is (S == wchar) && !is (S == dchar)) 
                    pragma (msg, "Source type must be char, wchar, or dchar");

        static if (!is (T == char) && !is (T == wchar) && !is (T == dchar)) 
                    pragma (msg, "Target type must be char, wchar, or dchar");

        private IBuffer buffer;

        /***********************************************************************

        ***********************************************************************/

        this (InputStream stream)
        {
                super (buffer = Buffer.share (stream));
        }
        
        /***********************************************************************

        ***********************************************************************/

        final override uint read (void[] dst)
        {
                static if (is (S == T))
                           return super.read (dst);
                else
                   {
                   // must have some space available for converting
                   if (dst.length < T.sizeof)
                       conduit.error ("UtfStream.read :: target array is too small");

                   uint produced,
                        consumed;
                   auto output = Buffer.convert!(T)(dst);
                   auto input  = Buffer.convert!(S)(buffer.slice);

                   static if (is (T == char))
                              produced = Utf.toString(input, output, &consumed).length;

                   static if (is (T == wchar))
                              produced = Utf.toString16(input, output, &consumed).length;

                   static if (is (T == dchar))
                              produced = Utf.toString32(input, output, &consumed).length;

                   // consume buffer content
                   buffer.skip (consumed * S.sizeof);

                   // fill buffer when nothing produced ...
                   if (produced is 0)
                       if (buffer.compress.fill(buffer.input) is Eof)
                           return Eof;

                   return produced * T.sizeof;
                   }
        }
}


/*******************************************************************************
        
        Streaming UTF converter. Type T is the target or destination type, 
        while S is the source type. Both types are either char/wchar/dchar.

        Note that the arguments are reversed from those of UtfInput

*******************************************************************************/

class UtfOutput (S, T) : OutputFilter
{       
        static if (!is (S == char) && !is (S == wchar) && !is (S == dchar)) 
                    pragma (msg, "Source type must be char, wchar, or dchar");

        static if (!is (T == char) && !is (T == wchar) && !is (T == dchar)) 
                    pragma (msg, "Target type must be char, wchar, or dchar");


        private IBuffer buffer;

        /***********************************************************************

        ***********************************************************************/

        this (OutputStream stream)
        {
                super (buffer = Buffer.share (stream));
                assert (buffer.capacity > 3, "UtfOutput :: output buffer is too small");
        }

        /***********************************************************************
        
                Write to the output stream from a source array. The provided 
                src content is converted as necessary. Note that an attached
                output buffer must be at least four bytes wide to accommodate
                a conversion.

                Returns the number of bytes consumed from src, which may be
                less than the quantity provided

        ***********************************************************************/

        final override uint write (void[] src)
        {
                static if (is (S == T))
                           return super.write (src);
                else
                   {
                   uint consumed,
                        produced;

                   uint writer (void[] dst)
                   {
                        auto input = Buffer.convert!(S)(src);
                        auto output = Buffer.convert!(T)(dst);

                        static if (is (T == char))
                                   produced = Utf.toString(input, output, &consumed).length;

                        static if (is (T == wchar))
                                   produced = Utf.toString16(input, output, &consumed).length;

                        static if (is (T == dchar))
                                   produced = Utf.toString32(input, output, &consumed).length;

                        return produced * T.sizeof;
                   }
                    
                   // write directly into the buffered content. A tad
                   // tricky to flush the output in an optimal manner.
                   // We could do this trivially via an internal work
                   // space conversion, but that would incur an extra
                   // memory copy
                   if (buffer.write(&writer) is 0)
                       // empty a connected buffer
                       if (buffer.output)
                           buffer.drain (buffer.output);
                       else
                          // buffer must be at least 4 bytes wide 
                          // to contain a generic conversion
                          if (buffer.writable < 4)
                              return Eof;
                    
                   return consumed * S.sizeof;
                   }
        }
}


/*******************************************************************************
        
*******************************************************************************/
        
debug (UtfStream)
{
        void main()
        {
                auto inp = new UtfInput!(dchar, char)(new Buffer("hello world"));
                auto oot = new UtfOutput!(dchar, char)(new Buffer(20));
                oot.copy(inp);
                assert (oot.buffer.slice == "hello world");
        }
}
