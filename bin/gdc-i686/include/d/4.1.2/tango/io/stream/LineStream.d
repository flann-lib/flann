/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2007

        author:         Kris

*******************************************************************************/

module tango.io.stream.LineStream;

private import tango.io.model.IConduit;

private import tango.text.stream.LineIterator;

/*******************************************************************************

        Simple way to hook up a line-tokenizer to an arbitrary InputStream,
        such as a file conduit:
        ---
        auto input = new LineInput (new FileInput("path"));
        foreach (line; input)
                 ...
        input.close;
        ---

        Note that this is just a simple wrapper around LineIterator, and
        supports utf8 lines only. Use LineIterator directly for utf16/32
        support, or use the other tango.text.stream classes directly for 
        other tokenizing needs.

        Note that this class is a true instance of InputStream, by way of
        inheritance via the Iterator superclass.

*******************************************************************************/

class LineInput : LineIterator!(char)
{
        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (InputStream stream)
        {
                super (stream);
        }
}


/*******************************************************************************


*******************************************************************************/

debug (LineStream)
{
        import tango.io.Stdout;
        import tango.io.stream.FileStream;

        void main()
        {
                auto input = new LineInput (new FileInput("LineStream.d"));
                foreach (line; input)
                         Stdout(line).newline;
                input.close;
        }
}