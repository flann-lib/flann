/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Feb 2007: Separated from Stdout 
                
        author:         Kris

*******************************************************************************/

module tango.io.Print;

private import  tango.io.model.IBuffer,
                tango.io.model.IConduit;

private import  tango.text.convert.Layout;

/*******************************************************************************

        A bridge between a Layout instance and a Buffer. This is used for
        the Stdout & Stderr globals, but can be used for general purpose
        buffer-formatting as desired. The Template type 'T' dictates the
        text arrangement within the target buffer ~ one of char, wchar or
        dchar (utf8, utf16, or utf32). 
        
        Print exposes this style of usage:
        ---
        auto print = new Print!(char) (...);

        print ("hello");                        => hello
        print (1);                              => 1
        print (3.14);                           => 3.14
        print ('b');                            => b
        print (1, 2, 3);                        => 1, 2, 3         
        print ("abc", 1, 2, 3);                 => abc, 1, 2, 3        
        print ("abc", 1, 2) ("foo");            => abc, 1, 2foo        
        print ("abc") ("def") (3.14);           => abcdef3.14

        print.format ("abc {}", 1);             => abc 1
        print.format ("abc {}:{}", 1, 2);       => abc 1:2
        print.format ("abc {1}:{0}", 1, 2);     => abc 2:1
        print.format ("abc ", 1);               => abc
        ---

        Note that the last example does not throw an exception. There
        are several use-cases where dropping an argument is legitimate,
        so we're currently not enforcing any particular trap mechanism.

        Flushing the output is achieved through the flush() method, or
        via an empty pair of parens: 
        ---
        print ("hello world") ();
        print ("hello world").flush;

        print.format ("hello {}", "world") ();
        print.format ("hello {}", "world").flush;
        ---
        
        Special character sequences, such as "\n", are written directly to
        the output without any translation (though an output-filter could
        be inserted to perform translation as required). Platform-specific 
        newlines are generated instead via the newline() method, which also 
        flushes the output when configured to do so:
        ---
        print ("hello ") ("world").newline;
        print.format ("hello {}", "world").newline;
        print.formatln ("hello {}", "world");
        ---

        The format() method supports the range of formatting options 
        exposed by tango.text.convert.Layout and extensions thereof; 
        including the full I18N extensions where configured in that 
        manner. To create a French instance of Print:
        ---
        import tango.text.locale.Locale;

        auto locale = new Locale (Culture.getCulture ("fr-FR"));
        auto print = new Print!(char) (locale, ...);
        ---

        Note that Print is *not* intended to be thread-safe. Use either
        tango.util.log.Trace or the standard logging facilities in order 
        to enable atomic console I/O
        
*******************************************************************************/

class Print(T) : OutputStream
{
        private T[]             eol;
        private OutputStream    output;
        private Layout!(T)      convert;
        private bool            flushLines;

        public alias print      opCall;

        version (Win32)
                 private const T[] Eol = "\r\n";
             else
                private const T[] Eol = "\n";

        /**********************************************************************

                Construct a Print instance, tying the provided stream
                to a layout formatter

        **********************************************************************/

        this (Layout!(T) convert, OutputStream output, T[] eol = Eol)
        {
                assert (convert);
                assert (output);

                this.eol = eol;
                this.output = output;
                this.convert = convert;
        }

        /**********************************************************************

                Layout using the provided formatting specification

        **********************************************************************/

        final Print format (T[] fmt, ...)
        {
                convert (&sink, _arguments, _argptr, fmt);
                return this;
        }

        /**********************************************************************

                Layout using the provided formatting specification

        **********************************************************************/

        final Print formatln (T[] fmt, ...)
        {
                convert (&sink, _arguments, _argptr, fmt);
                return newline;
        }

        /**********************************************************************

                Unformatted layout, with commas inserted between args. 
                Currently supports a maximum of 24 arguments

        **********************************************************************/

        final Print print (...)
        {
                static  T[] slice =  "{}, {}, {}, {}, {}, {}, {}, {}, "
                                     "{}, {}, {}, {}, {}, {}, {}, {}, "
                                     "{}, {}, {}, {}, {}, {}, {}, {}, ";

                assert (_arguments.length <= slice.length/4, "Print :: too many arguments");

                if (_arguments.length is 0)
                    output.flush;
                else
                   convert (&sink, _arguments, _argptr, slice[0 .. _arguments.length * 4 - 2]);
                         
                return this;
        }

        /***********************************************************************

                Output a newline and optionally flush

        ***********************************************************************/

        final Print newline ()
        {
                output.write (eol);
                if (flushLines)
                    output.flush;
                return this;
        }

        /**********************************************************************

                Control implicit flushing of newline(), where true enables
                flushing. An explicit flush() will always flush the output.

        **********************************************************************/

        final Print flush (bool yes)
        {
                flushLines = yes;
                return this;
        }

        /**********************************************************************

                Return the associated output stream

        **********************************************************************/

        final OutputStream stream ()
        {
                return output;
        }

        /**********************************************************************

                Set the associated output stream

        **********************************************************************/

        final Print stream (OutputStream output)
        {
                this.output = output;
                return this;
        }

        /**********************************************************************

                Return the associated Layout

        **********************************************************************/

        final Layout!(T) layout ()
        {
                return convert;
        }

        /**********************************************************************

                Set the associated Layout

        **********************************************************************/

        final Print layout (Layout!(T) layout)
        {
                convert = layout;
                return this;
        }

        /**********************************************************************

                Sink for passing to the formatter

        **********************************************************************/

        private final uint sink (T[] s)
        {
                return output.write (s);
        }

        /**********************************************************************/
        /********************* OutputStream Interface *************************/
        /**********************************************************************/


        /***********************************************************************
        
                Return the host conduit

        ***********************************************************************/

        IConduit conduit ()
        {
                return output.conduit;
        }

        /***********************************************************************
        
                Write to conduit from a source array. The provided src
                content will be written to the conduit.

                Returns the number of bytes written from src, which may
                be less than the quantity provided

        ***********************************************************************/

        uint write (void[] src)
        {
                return output.write (src);
        }              
                             
        /**********************************************************************

               Flush the output stream

        **********************************************************************/

        final OutputStream flush ()
        {
                output.flush;
                return this;
        }

        /***********************************************************************

                Transfer the content of another conduit to this one. Returns
                a reference to this class, and throws IOException on failure.

        ***********************************************************************/

        OutputStream copy (InputStream src)
        {               
                output.copy (src);
                return this;
        }
                          
        /***********************************************************************
        
                Close the output

        ***********************************************************************/

        void close ()
        {       
                output.close;
        }
}


debug (Print)
{
        import tango.io.GrowBuffer;
        import tango.text.convert.Layout;

        void main()
        {
                auto print = new Print!(char) (new Layout!(char), new GrowBuffer);

                for (int i=0;i < 1000; i++)
                     print(i).newline;
        }
}
