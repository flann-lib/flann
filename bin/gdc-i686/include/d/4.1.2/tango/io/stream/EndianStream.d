/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Nov 2007

        author:         Kris

        Streams for swapping endian-order. The stream is treated as a set
        of same-sized elements. Note that partial elements are not mutated

*******************************************************************************/

module tango.io.stream.EndianStream;

private import  tango.io.Buffer,
                tango.io.Conduit;

private import  tango.core.ByteSwap;

/*******************************************************************************

        Type T is the element type

*******************************************************************************/

class EndianInput(T) : InputFilter
{       
        static if ((T.sizeof != 2) && (T.sizeof != 4) && (T.sizeof != 8)) 
                    pragma (msg, "EndianInput :: type should be of length 2, 4, or 8 bytes");


        private IBuffer input;

        /***********************************************************************

        ***********************************************************************/

        this (InputStream stream)
        {
                super (input = Buffer.share (stream));
        }
        
        /***********************************************************************

                Buffered interface 

        ***********************************************************************/

        final IBuffer buffer ()
        {
                return input;
        }

        /***********************************************************************

                Read from conduit into a target array. The provided dst 
                will be populated with content from the conduit. 

                Returns the number of bytes read, which may be less than
                requested in dst (or IOStream.Eof for end-of-flow). Note
                that a trailing partial element will be placed into dst,
                but the returned length will effectively ignore it

        ***********************************************************************/

        final override uint read (void[] dst)
        {
                uint len = input.fill (dst[0 .. dst.length & ~(T.sizeof-1)]);
                if (len != Eof)
                   {
                   // the final read may be misaligned ...
                   len &= ~(T.sizeof - 1);

                   static if (T.sizeof == 2)
                              ByteSwap.swap16 (dst.ptr, len);

                   static if (T.sizeof == 4)
                              ByteSwap.swap32 (dst.ptr, len);

                   static if (T.sizeof == 8)
                              ByteSwap.swap64 (dst.ptr, len);
                   }
                return len;
        }
}



/*******************************************************************************
        
        Type T is the element type

*******************************************************************************/

class EndianOutput (T) : OutputFilter
{       
        static if ((T.sizeof != 2) && (T.sizeof != 4) && (T.sizeof != 8)) 
                    pragma (msg, "EndianOutput :: type should be of length 2, 4, or 8 bytes");

        private IBuffer output;

        /***********************************************************************

        ***********************************************************************/

        this (OutputStream stream)
        {
                super (output = Buffer.share (stream));
        }

        /***********************************************************************
        
                Write to output stream from a source array. The provided 
                src content will be consumed and left intact.

                Returns the number of bytes written from src, which may
                be less than the quantity provided. Note that any partial 
                elements will not be consumed

        ***********************************************************************/

        final override uint write (void[] src)
        {
                uint writer (void[] dst)
                {
                        auto len = dst.length;
                        if (len > src.length)
                            len = src.length;

                        len &= ~(T.sizeof - 1);
                        dst [0..len] = src [0..len];

                        static if (T.sizeof == 2)
                                   ByteSwap.swap16 (dst.ptr, len);

                        static if (T.sizeof == 4)
                                   ByteSwap.swap32 (dst.ptr, len);

                        static if (T.sizeof == 8)
                                   ByteSwap.swap64 (dst.ptr, len);

                        return len;
                }

                uint bytes = src.length;
                
                // flush if we used all buffer space
                if ((bytes -= output.write (&writer)) >= T.sizeof)
                     if (output.output)
                         output.drain (output.output);
                     else
                        return Eof;
                return src.length - bytes;
        }
}


/*******************************************************************************
        
*******************************************************************************/
        
debug (UnitTest)
{
        import tango.io.Stdout;

        unittest
        {
                auto inp = new EndianInput!(dchar)(new Buffer("hello world"d));
                auto oot = new EndianOutput!(dchar)(new Buffer(64));
                oot.copy (inp);
                assert (oot.output.slice == "hello world"d);
        }
}
