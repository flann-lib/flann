/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2007

        author:         Kris

        Simple serialization for text-based name/value pairs

*******************************************************************************/

module tango.io.stream.MapStream;

private import  tango.io.Buffer,
                tango.io.Conduit;

private import  Text = tango.text.Util;

private import  tango.text.stream.LineIterator;

/*******************************************************************************

        Provides load facilities for a properties stream. That is, a file
        or other medium containing lines of text with a name=value layout

*******************************************************************************/

class MapInput(T) : LineIterator!(T)
{
        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (InputStream stream)
        {
                super (stream);
        }

        /***********************************************************************

                Load properties from the provided stream, via a foreach.

                We use an iterator to sweep text lines, and extract lValue
                and rValue pairs from each one, The expected file format is
                as follows:

                ---
                x = y
                abc = 123
                x.y.z = this is a single property

                # this is a comment line
                ---

                Note that the provided name and value are actually slices
                and should be copied if you intend to retain them (using
                name.dup and value.dup where appropriate)

        ***********************************************************************/

        final int opApply (int delegate(ref T[] name, ref T[] value) dg)
        {
                int ret;

                foreach (line; super)
                        {
                        auto text = Text.trim (line);

                        // comments require '#' as the first non-whitespace char
                        if (text.length && (text[0] != '#'))
                           {
                           // find the '=' char
                           auto i = Text.locate (text, '=');

                           // ignore if not found ...
                           if (i < text.length)
                              {
                              auto name = Text.trim (text[0 .. i]);
                              auto value = Text.trim (text[i+1 .. $]);
                              if ((ret = dg (name, value)) != 0)
                                   break;
                              }
                           }
                        }
                return ret;
        }

        /***********************************************************************

                Load the input stream into an AA

        ***********************************************************************/

        final MapInput load (ref T[][T[]] properties)
        {
                foreach (name, value; this)
                         properties[name.dup] = value.dup;  
                return this;
        }
}


/*******************************************************************************

        Provides write facilities on a properties stream. That is, a file
        or other medium which will contain lines of text with a name=value 
        layout

*******************************************************************************/

class MapOutput(T) : OutputFilter, Buffered
{
        private IBuffer output;

        private const T[] equals = " = ";
        version (Win32)
                 private const T[] NL = "\r\n";
        version (Posix)
                 private const T[] NL = "\n";

        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (OutputStream stream, T[] newline = NL)
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

                Write name & value to the provided stream

        ***********************************************************************/

        final MapOutput append (T[] name, T[] value)
        {
                output (name) (equals) (value) (NL);
                return this;
        }

        /***********************************************************************

                Write AA properties to the provided stream

        ***********************************************************************/

        final MapOutput append (T[][T[]] properties)
        {
                foreach (key, value; properties)
                         append (key, value);
                return this;
        }
}



/*******************************************************************************
        
*******************************************************************************/
        
debug (UnitTest)
{
        import tango.io.Stdout;
        import tango.io.GrowBuffer;

        unittest
        {
                auto buf = new GrowBuffer;
                auto input = new MapInput!(char)(buf);
                auto output = new MapOutput!(char)(buf);

                char[][char[]] map;
                map["foo"] = "bar";
                map["foo2"] = "bar2";
                output.append (map);

                map = map.init;
                input.load (map);
                assert (map["foo"] == "bar");
                assert (map["foo2"] == "bar2");
        }
}
