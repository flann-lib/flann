/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mar 2004: Initial release      
                        Dec 2006: Outback release
        
        author:         Kris
                        Ivan Senji (the "alias put" idea)

*******************************************************************************/

module tango.io.protocol.model.IWriter;

public import tango.io.model.IBuffer;

/*******************************************************************************

        IWriter interface. Writers provide the means to append formatted 
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

abstract class IWriter  // could be an interface, but that causes poor codegen
{
        alias put opCall;

        /***********************************************************************
        
                These are the basic writer methods

        ***********************************************************************/

        abstract IWriter put (bool x);
        abstract IWriter put (ubyte x);         ///ditto
        abstract IWriter put (byte x);          ///ditto
        abstract IWriter put (ushort x);        ///ditto
        abstract IWriter put (short x);         ///ditto
        abstract IWriter put (uint x);          ///ditto
        abstract IWriter put (int x);           ///ditto
        abstract IWriter put (ulong x);         ///ditto
        abstract IWriter put (long x);          ///ditto
        abstract IWriter put (float x);         ///ditto
        abstract IWriter put (double x);        ///ditto
        abstract IWriter put (real x);          ///ditto
        abstract IWriter put (char x);          ///ditto
        abstract IWriter put (wchar x);         ///ditto
        abstract IWriter put (dchar x);         ///ditto

        abstract IWriter put (bool[] x);
        abstract IWriter put (byte[] x);        ///ditto
        abstract IWriter put (short[] x);       ///ditto
        abstract IWriter put (int[] x);         ///ditto
        abstract IWriter put (long[] x);        ///ditto
        abstract IWriter put (ubyte[] x);       ///ditto
        abstract IWriter put (ushort[] x);      ///ditto
        abstract IWriter put (uint[] x);        ///ditto
        abstract IWriter put (ulong[] x);       ///ditto
        abstract IWriter put (float[] x);       ///ditto
        abstract IWriter put (double[] x);      ///ditto
        abstract IWriter put (real[] x);        ///ditto
        abstract IWriter put (char[] x);        ///ditto
        abstract IWriter put (wchar[] x);       ///ditto
        abstract IWriter put (dchar[] x);       ///ditto

        /***********************************************************************
        
                This is the mechanism used for binding arbitrary classes 
                to the IO system. If a class implements IWritable, it can
                be used as a target for IWriter put() operations. That is, 
                implementing IWritable is intended to transform any class 
                into an IWriter adaptor for the content held therein

        ***********************************************************************/

        abstract IWriter put (IWritable);

        alias void delegate (IWriter) Closure;

        abstract IWriter put (Closure);

        /***********************************************************************
        
                Emit a newline
                
        ***********************************************************************/

        abstract IWriter newline ();
        
        /***********************************************************************
        
                Flush the output of this writer. Throws an IOException 
                if the operation fails. These are aliases for each other

        ***********************************************************************/

        abstract IWriter flush ();
        abstract IWriter put ();        ///ditto

        /***********************************************************************
        
                Return the associated buffer

        ***********************************************************************/

        abstract IBuffer buffer ();
}


/*******************************************************************************

        Interface to make any class compatible with any IWriter

*******************************************************************************/

interface IWritable
{
        abstract void write (IWriter input);
}

