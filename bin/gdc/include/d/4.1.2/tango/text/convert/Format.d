/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Sep 2007: Initial release
        version:        Nov 2007: Added stream wrappers

        author:         Kris

*******************************************************************************/

module tango.text.convert.Format;

private import tango.io.model.IConduit;

private import tango.text.convert.Layout;

/******************************************************************************

        Constructs a global utf8 instance of Layout

******************************************************************************/

public Layout!(char) Format;

static this()
{
        Format = new Layout!(char);
}

/******************************************************************************

        Global function to format into a stream

******************************************************************************/

deprecated void format (OutputStream output, char[] fmt, ...)
{
        Format.convert ((char[] s){return output.write(s);}, _arguments, _argptr, fmt);
}

/******************************************************************************

        Global function to format into a stream, and add a newline

******************************************************************************/

deprecated void formatln (OutputStream output, char[] fmt, ...)
{
        version (Win32)
                 const char[] Eol = "\r\n";
           else
              const char[] Eol = "\n";

        Format.convert ((char[] s){return output.write(s);}, _arguments, _argptr, fmt);
        output.write (Eol);
}


/******************************************************************************

******************************************************************************/

debug (Format)
{
        import tango.io.Console;

        void main()
        {
                formatln (Cout.stream, "hello {}", "world");
        }
}
