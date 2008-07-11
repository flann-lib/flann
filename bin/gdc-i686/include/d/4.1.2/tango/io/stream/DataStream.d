/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2007

        author:         Kris

*******************************************************************************/

module tango.io.stream.DataStream;

private import tango.io.Buffer;

private import tango.io.Conduit;

private import tango.core.ByteSwap;

/*******************************************************************************

        A simple way to read binary data from an arbitrary InputStream,
        such as a file:
        ---
        auto input = new DataInput (new FileInput("path"));
        auto x = input.readInt;
        auto y = input.readDouble;
        input.read (new char[10]);
        input.close;
        ---

*******************************************************************************/

class DataInput : InputFilter, Buffered
{       
        private bool    flip;
        private IBuffer input;

        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (InputStream stream, uint buffer=uint.max, bool flip=false)
        {
                this.flip = flip;
                super (input = Buffer.share (stream, buffer));
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

        final override DataInput clear ()
        {
                host.clear;
                return this;
        }

        /***********************************************************************

                Read an array back into a user-provided workspace. The
                space must be sufficiently large enough to house all of
                the array, and the actual number of bytes is returned.

                Note that the size of the array is written as an integer
                prefixing the array content itself.  Use read(void[]) to 
                eschew this prefix.

        ***********************************************************************/

        final override uint get (void[] dst)
        {
                auto len = getInt;
                if (len > dst.length)
                    conduit.error ("DataInput.readArray :: dst array is too small");
                input.readExact (dst.ptr, len);
                return len;
        }

        /***********************************************************************

        ***********************************************************************/

        final bool getBool ()
        {
                bool x;
                input.readExact (&x, x.sizeof);
                return x;
        }

        /***********************************************************************

        ***********************************************************************/

        final byte getByte ()
        {
                byte x;
                input.readExact (&x, x.sizeof);
                return x;
        }

        /***********************************************************************

        ***********************************************************************/

        final short getShort ()
        {
                short x;
                input.readExact (&x, x.sizeof);
                if (flip)
                    ByteSwap.swap16(&x, x.sizeof);
                return x;
        }

        /***********************************************************************

        ***********************************************************************/

        final int getInt ()
        {
                int x;
                input.readExact (&x, x.sizeof);
                if (flip)
                    ByteSwap.swap32(&x, x.sizeof);
                return x;
        }

        /***********************************************************************

        ***********************************************************************/

        final long getLong ()
        {
                long x;
                input.readExact (&x, x.sizeof);
                if (flip)
                    ByteSwap.swap64(&x, x.sizeof);
                return x;
        }

        /***********************************************************************

        ***********************************************************************/

        final float getFloat ()
        {
                float x;
                input.readExact (&x, x.sizeof);
                if (flip)
                    ByteSwap.swap32(&x, x.sizeof);
                return x;
        }

        /***********************************************************************

        ***********************************************************************/

        final double getDouble ()
        {
                double x;
                input.readExact (&x, x.sizeof);
                if (flip)
                    ByteSwap.swap64(&x, x.sizeof);
                return x;
        }

}


/*******************************************************************************

        A simple way to write binary data to an arbitrary OutputStream,
        such as a file:
        ---
        auto output = new DataOutput (new FileOutput("path"));
        output.writeInt (1024);
        output.writeDouble (3.14159);
        output.write ("hello world");
        output.flush.close;
        ---

*******************************************************************************/

class DataOutput : OutputFilter, Buffered
{       
        private bool    flip;
        private IBuffer output;

        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (OutputStream stream, uint buffer=uint.max, bool flip = false)
        {
                this.flip = flip;
                super (output = Buffer.share (stream, buffer));
        }

        /***********************************************************************
        
                Buffered interface

        ***********************************************************************/

        final IBuffer buffer ()
        {
                return output;
        }

        /***********************************************************************

                Write an array to the target stream. Note that the size 
                of the array is written as an integer prefixing the array 
                content itself. Use write(void[]) to eschew this prefix.

        ***********************************************************************/

        final uint put (void[] src)
        {
                auto len = src.length;
                putInt (len);
                output.append (src.ptr, len);
                return len;
        }

        /***********************************************************************

        ***********************************************************************/

        final void putBool (bool x)
        {
                output.append (&x, x.sizeof);
        }

        /***********************************************************************

        ***********************************************************************/

        final void putByte (byte x)
        {
                output.append (&x, x.sizeof);
        }

        /***********************************************************************

        ***********************************************************************/

        final void putShort (short x)
        {
                if (flip)
                    ByteSwap.swap16 (&x, x.sizeof);
                output.append (&x, x.sizeof);
        }

        /***********************************************************************

        ***********************************************************************/

        final void putInt (int x)
        {
                if (flip)
                    ByteSwap.swap32 (&x, x.sizeof);
                output.append (&x, uint.sizeof);
        }

        /***********************************************************************

        ***********************************************************************/

        final void putLong (long x)
        {
                if (flip)
                    ByteSwap.swap64 (&x, x.sizeof);
                output.append (&x, x.sizeof);
        }

        /***********************************************************************

        ***********************************************************************/

        final void putFloat (float x)
        {
                if (flip)
                    ByteSwap.swap32 (&x, x.sizeof);
                output.append (&x, x.sizeof);
        }

        /***********************************************************************

        ***********************************************************************/

        final void putDouble (double x)
        {
                if (flip)
                    ByteSwap.swap64 (&x, x.sizeof);
                output.append (&x, x.sizeof);
        }
}

/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{
        import tango.io.Buffer;

        unittest
        {
                auto buf = new Buffer(32);

                auto output = new DataOutput (buf);
                output.put ("blah blah");
                output.putInt (1024);

                auto input = new DataInput (buf);
                assert (input.get(new char[9]) is 9);
                assert (input.getInt is 1024);
        }
}
