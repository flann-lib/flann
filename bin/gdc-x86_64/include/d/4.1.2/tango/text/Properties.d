/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: May 2004

        author:         Kris

*******************************************************************************/

module tango.text.Properties;

private import  tango.io.Buffer,
                tango.io.FilePath,
                tango.io.FileConst,
                tango.io.FileConduit;

private import  Text = tango.text.Util;

private import  tango.text.stream.LineIterator;

/*******************************************************************************

        Provides load facilities for a properties file. That is, a file
        or other medium containing lines of text with a name=value layout.

*******************************************************************************/

class Properties(T)
{
        /***********************************************************************

                Load properties from the named file, and pass each of them
                to the provided delegate.

        ***********************************************************************/

        static void load (FilePath path, void delegate (T[] name, T[] value) dg)
        {
                auto fc = new FileConduit (path);
                scope (exit)
                       fc.close;

                load (fc, dg);
        }

        /***********************************************************************

                Load properties from the provided buffer, and pass them to
                the specified delegate.

                We use an iterator to sweep text lines, and extract lValue
                and rValue pairs from each one, The expected file format is
                as follows:

                ---
                x = y
                abc = 123
                x.y.z = this is a single property

                # this is a comment line
                ---

        ***********************************************************************/

        static void load (InputStream stream, void delegate (T[] name, T[] value) dg)
        {
                foreach (line; new LineIterator!(T) (stream))
                        {
                        auto text = Text.trim (line);

                        // comments require '#' as the first non-whitespace char
                        if (text.length && (text[0] != '#'))
                           {
                           // find the '=' char
                           auto i = Text.locate (text, '=');

                           // ignore if not found ...
                           if (i < text.length)
                               dg (Text.trim (text[0 .. i]), Text.trim (text[i+1 .. $]));
                           }
                        }
        }

        /***********************************************************************

                Write properties to the provided filepath

        ***********************************************************************/

        static void save (FilePath path, T[][T[]] properties)
        {
                auto fc = new FileConduit (path, FileConduit.WriteCreate);
                scope (exit)
                       fc.close;
                save (fc, properties);
        }

        /***********************************************************************

                Write properties to the provided stream

        ***********************************************************************/

        static void save (OutputStream stream, T[][T[]] properties)
        {
               const T[] equals = " = ";
                version (Win32)
                         const T[] NL = "\r\n";
                version (Posix)
                         const T[] NL = "\n";

                auto b = cast(Buffered) stream;
                auto emit = b ? b.buffer : new Buffer (stream.conduit);
                foreach (key, value; properties)
                         emit (key) (equals) (value) (NL);
                emit.flush;
        }
}


debug (Properties)
{
        import tango.io.Buffer;
        import tango.io.Console;

        void main() 
        {
                char[][char[]] aa;
                aa ["foo"] = "something";
                aa ["bar"] = "something else";
                aa ["wumpus"] = "";

                // write associative-array to a buffer; could use a file
                auto props = new Properties!(char);
                auto buffer = new Buffer (256);
                props.save (buffer, aa);

                // reset and repopulate AA from the buffer
                aa = null;
                props.load (buffer, (char[] name, char[] value){aa[name] = value;});

                // display result
                foreach (name, value; aa)
                         Cout (name) (" = ") (value).newline;
        }
}

