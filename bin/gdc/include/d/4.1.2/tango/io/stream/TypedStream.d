/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Nov 2007

        author:         Kris

        Streams to expose simple native types as discrete elements. I/O
        is buffered and should yield fair performance.

*******************************************************************************/

module tango.io.stream.TypedStream;

private import  tango.io.Buffer,
                tango.io.Conduit;

/*******************************************************************************

        Type T is the target or destination type

*******************************************************************************/

class TypedInput(T) : InputFilter, Buffered
{       
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

                Override this to give back a useful chaining reference

        ***********************************************************************/

        final override TypedInput clear ()
        {
                host.clear;
                return this;
        }

        /***********************************************************************

                Read a value from the stream. Returns false when all 
                content has been consumed

        ***********************************************************************/

        final bool read (inout T x)
        {
                return input.read((&x)[0..1]) is T.sizeof;
        }

        /***********************************************************************

                Iterate over all content

        ***********************************************************************/

        final int opApply (int delegate(ref T x) dg)
        {
                T x;
                int ret;

                while ((input.read((&x)[0..1]) is T.sizeof))
                        if ((ret = dg (x)) != 0)
                             break;
                return ret;
        }
}



/*******************************************************************************
        
        Type T is the target or destination type.

*******************************************************************************/

class TypedOutput (T) : OutputFilter, Buffered
{       
        private IBuffer output;

        /***********************************************************************

        ***********************************************************************/

        this (OutputStream stream)
        {
                super (output = Buffer.share (stream));
        }

        /***********************************************************************

                Buffered interface 

        ***********************************************************************/

        final IBuffer buffer ()
        {
                return output;
        }

        /***********************************************************************
        
                Append a value to the output stream

        ***********************************************************************/

        final void write (T x)
        {
                output.append (&x, T.sizeof);
        }
}


/*******************************************************************************
        
*******************************************************************************/
        
debug (UnitTest)
{
        import tango.io.Stdout;
        import tango.io.stream.UtfStream;

        unittest
        {
                auto inp = new TypedInput!(char)(new Buffer("hello world"));
                auto oot = new TypedOutput!(char)(new Buffer(20));

                foreach (x; inp)
                         oot.write (x);
                assert (oot.buffer.slice == "hello world");

                auto xx = new TypedInput!(char)(new UtfInput!(char, dchar)(new Buffer("hello world"d)));
                char[] yy;
                foreach (x; xx)
                         yy ~= x;
                assert (yy == "hello world");
        }
}
