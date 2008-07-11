/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2007

        author:         Kris

*******************************************************************************/

module tango.io.stream.FormatStream;

private import  tango.io.Print;

private import  tango.io.model.IConduit;

private import  tango.text.convert.Format;

/*******************************************************************************

        Simple way to hook up a utf8 formatter to an arbitrary OutputStream,
        such as a file:
        ---
        auto output = new FormatOutput (new FileOutput("path"));
        output.formatln ("{} green bottles", 10);
        output.close;
        ---

        This is a trivial wrapper around the Print class, and is limited
        to emitting utf8 output. Use the Print class directly in order to
        generate utf16/32 output instead.

        Note that this class is a true instance of OutputStream, by way of
        inheritance via the Print superclass.

*******************************************************************************/

class FormatOutput : Print!(char)
{
        /***********************************************************************

                Create a Layout instance and bind it to the given stream.
                The optional second argument controls implicit flushing of 
                newline(), where true enables flushing. An explicit flush() 
                will always flush the output.

        ***********************************************************************/

        this (OutputStream stream, bool flush=false)
        {
                super (Format, stream);
                super.flush = flush;
        }
}


