/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Oct 2004: Initial release      
                        Dec 2006: Outback release
        
        author:         Kris 

*******************************************************************************/

module tango.io.protocol.Writer;

private import  tango.io.Buffer,
                tango.io.FileConst;

public  import  tango.io.model.IBuffer,
                tango.io.model.IConduit;

public  import  tango.io.protocol.model.IWriter;

private import  tango.io.protocol.model.IProtocol;

/*******************************************************************************

        Writer base-class. Writers provide the means to append formatted 
        data to an IBuffer, and expose a convenient method of handling a
        variety of data types. In addition to writing native types such
        as integer and char[], writers also process any class which has
        implemented the IWritable interface (one method).

        All writers support the full set of native data types, plus their
        fundamental array variants. Operations may be chained back-to-back.

        Writers support a Java-esque put() notation. However, the Tango style
        is to place IO elements within their own parenthesis, like so:

        ---
        write (count) (" green bottles");
        ---

        Note that each written element is distict; this style is affectionately
        known as "whisper". The code below illustrates basic operation upon a
        memory buffer:
        
        ---
        auto buf = new Buffer (256);

        // map same buffer into both reader and writer
        auto read = new Reader (buf);
        auto write = new Writer (buf);

        int i = 10;
        long j = 20;
        double d = 3.14159;
        char[] c = "fred";

        // write data types out
        write (c) (i) (j) (d);

        // read them back again
        read (c) (i) (j) (d);


        // same thing again, but using put() syntax instead
        write.put(c).put(i).put(j).put(d);
        read.get(c).get(i).get(j).get(d);
        ---

        Writers may also be used with any class implementing the IWritable
        interface, along with any struct implementing an equivalent function.

*******************************************************************************/

class Writer : IWriter
{     
        // the buffer associated with this writer. Note that this
        // should not change over the lifetime of the reader, since
        // it is assumed to be immutable elsewhere 
        package IBuffer                 buffer_;
        
        package IProtocol.ArrayWriter   arrays;
        package IProtocol.Writer        elements;

        // end of line sequence
        package char[]                  eol = FileConst.NewlineString;

        /***********************************************************************
        
                Construct a Writer on the provided Protocol

        ***********************************************************************/

        this (IProtocol protocol)
        {
                buffer_ = protocol.buffer;
                elements = &protocol.write;
                arrays = &protocol.writeArray;
        }

        /***********************************************************************
        
                Construct a Writer on the given OutputStream. We do our own
                protocol handling, equivalent to the NativeProtocol.

        ***********************************************************************/

        this (OutputStream stream)
        {
                auto b = cast(Buffered) stream;
                buffer_ = (b ? b.buffer : new Buffer (stream.conduit));

                arrays = &writeArray;
                elements = &writeElement;
        }

        /***********************************************************************
        
                Return the associated buffer

        ***********************************************************************/

        final IBuffer buffer ()
        {     
                return buffer_;
        }

        /***********************************************************************
        
                Emit a newline
                
        ***********************************************************************/

        IWriter newline ()
        {  
                return put (eol);
        }

        /***********************************************************************
        
                set the newline sequence
                
        ***********************************************************************/

        IWriter newline (char[] eol)
        {  
                this.eol = eol;
                return this;
        }

        /***********************************************************************
        
                Flush the output of this writer and return a chaining ref

        ***********************************************************************/

        final IWriter flush ()
        {  
                buffer_.flush;
                return this;
        }

        /***********************************************************************
        
                Flush this writer. This is a convenience method used by
                the "whisper" syntax.
                
        ***********************************************************************/

        final IWriter put () 
        {
                return flush;
        }

        /***********************************************************************
        
                Write via a delegate to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (IWriter.Closure dg) 
        {
                dg (this);
                return this;
        }

        /***********************************************************************
        
                Write a class to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (IWritable x) 
        {
                if (x is null)
                    buffer_.error ("Writer.put :: attempt to write a null IWritable object");

                return put (&x.write);
        }

        /***********************************************************************
        
                Write a boolean value to the current buffer-position    
                
        ***********************************************************************/

        final IWriter put (bool x)
        {
                elements (&x, x.sizeof, IProtocol.Type.Bool);
                return this;
        }

        /***********************************************************************
        
                Write an unsigned byte value to the current buffer-position     
                                
        ***********************************************************************/

        final IWriter put (ubyte x)
        {
                elements (&x, x.sizeof, IProtocol.Type.UByte);
                return this;
        }

        /***********************************************************************
        
                Write a byte value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (byte x)
        {
                elements (&x, x.sizeof, IProtocol.Type.Byte);
                return this;
        }

        /***********************************************************************
        
                Write an unsigned short value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (ushort x)
        {
                elements (&x, x.sizeof, IProtocol.Type.UShort);
                return this;
        }

        /***********************************************************************
        
                Write a short value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (short x)
        {
                elements (&x, x.sizeof, IProtocol.Type.Short);
                return this;
        }

        /***********************************************************************
        
                Write a unsigned int value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (uint x)
        {
                elements (&x, x.sizeof, IProtocol.Type.UInt);
                return this;
        }

        /***********************************************************************
        
                Write an int value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (int x)
        {
                elements (&x, x.sizeof, IProtocol.Type.Int);
                return this;
        }

        /***********************************************************************
        
                Write an unsigned long value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (ulong x)
        {
                elements (&x, x.sizeof, IProtocol.Type.ULong);
                return this;
        }

        /***********************************************************************
        
                Write a long value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (long x)
        {
                elements (&x, x.sizeof, IProtocol.Type.Long);
                return this;
        }

        /***********************************************************************
        
                Write a float value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (float x)
        {
                elements (&x, x.sizeof, IProtocol.Type.Float);
                return this;
        }

        /***********************************************************************
        
                Write a double value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (double x)
        {
                elements (&x, x.sizeof, IProtocol.Type.Double);
                return this;
        }

        /***********************************************************************
        
                Write a real value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (real x)
        {
                elements (&x, x.sizeof, IProtocol.Type.Real);
                return this;
        }

        /***********************************************************************
        
                Write a char value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (char x)
        {
                elements (&x, x.sizeof, IProtocol.Type.Utf8);
                return this;
        }

        /***********************************************************************
        
                Write a wchar value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (wchar x)
        {
                elements (&x, x.sizeof, IProtocol.Type.Utf16);
                return this;
        }

        /***********************************************************************
        
                Write a dchar value to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (dchar x)
        {
                elements (&x, x.sizeof, IProtocol.Type.Utf32);
                return this;
        }

        /***********************************************************************
        
                Write a boolean array to the current buffer-position     
                                
        ***********************************************************************/

        final IWriter put (bool[] x)
        {
                arrays (x.ptr, x.length * bool.sizeof, IProtocol.Type.Bool);
                return this;
        }

        /***********************************************************************
        
                Write a byte array to the current buffer-position     
                                
        ***********************************************************************/

        final IWriter put (byte[] x)
        {
                arrays (x.ptr, x.length * byte.sizeof, IProtocol.Type.Byte);
                return this;
        }

        /***********************************************************************
        
                Write an unsigned byte array to the current buffer-position     
                                
        ***********************************************************************/

        final IWriter put (ubyte[] x)
        {
                arrays (x.ptr, x.length * ubyte.sizeof, IProtocol.Type.UByte);
                return this;
        }

        /***********************************************************************
        
                Write a short array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (short[] x)
        {
                arrays (x.ptr, x.length * short.sizeof, IProtocol.Type.Short);
                return this;
        }

        /***********************************************************************
        
                Write an unsigned short array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (ushort[] x)
        {
                arrays (x.ptr, x.length * ushort.sizeof, IProtocol.Type.UShort);
                return this;
        }

        /***********************************************************************
        
                Write an int array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (int[] x)
        {
                arrays (x.ptr, x.length * int.sizeof, IProtocol.Type.Int);
                return this;
        }

        /***********************************************************************
        
                Write an unsigned int array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (uint[] x)
        {
                arrays (x.ptr, x.length * uint.sizeof, IProtocol.Type.UInt);
                return this;
        }

        /***********************************************************************
        
                Write a long array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (long[] x)
        {
                arrays (x.ptr, x.length * long.sizeof, IProtocol.Type.Long);
                return this;
        }

        /***********************************************************************
         
                Write an unsigned long array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (ulong[] x)
        {
                arrays (x.ptr, x.length * ulong.sizeof, IProtocol.Type.ULong);
                return this;
        }

        /***********************************************************************
        
                Write a float array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (float[] x)
        {
                arrays (x.ptr, x.length * float.sizeof, IProtocol.Type.Float);
                return this;
        }

        /***********************************************************************
        
                Write a double array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (double[] x)
        {
                arrays (x.ptr, x.length * double.sizeof, IProtocol.Type.Double);
                return this;
        }

        /***********************************************************************
        
                Write a real array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (real[] x)
        {
                arrays (x.ptr, x.length * real.sizeof, IProtocol.Type.Real);
                return this;
        }

        /***********************************************************************
        
                Write a char array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (char[] x) 
        {
                arrays (x.ptr, x.length * char.sizeof, IProtocol.Type.Utf8);
                return this;
        }

        /***********************************************************************
        
                Write a wchar array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (wchar[] x) 
        {
                arrays (x.ptr, x.length * wchar.sizeof, IProtocol.Type.Utf16);
                return this;
        }

        /***********************************************************************
        
                Write a dchar array to the current buffer-position
                
        ***********************************************************************/

        final IWriter put (dchar[] x)
        {
                arrays (x.ptr, x.length * dchar.sizeof, IProtocol.Type.Utf32);
                return this;
        }

        /***********************************************************************
        
                Dump array content into the buffer. Note that the default
                behaviour is to prefix with the array byte count 

        ***********************************************************************/

        private void writeArray (void* src, uint bytes, IProtocol.Type type)
        {
                put (bytes);
                writeElement (src, bytes, type);
        }

        /***********************************************************************
        
                Dump content into the buffer

        ***********************************************************************/

        private void writeElement (void* src, uint bytes, IProtocol.Type type)
        {
                buffer_.append (src [0 .. bytes]);
        }
}
