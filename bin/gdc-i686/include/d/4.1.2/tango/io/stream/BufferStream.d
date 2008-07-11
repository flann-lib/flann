/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2007

        author:         Kris

*******************************************************************************/

module tango.io.stream.BufferStream;

private import tango.io.Buffer;

/*******************************************************************************

        Buffers the flow of data from a upstream input. A downstream 
        neighbour can locate and use this buffer instead of creating 
        another instance of their own. 

        (note that upstream is closer to the source, and downstream is
        further away)

*******************************************************************************/

class BufferInput : Buffer
{
        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (InputStream stream, uint size = 16 * 1024)
        {
                super (size);
                super.input = stream;
        }
}


/*******************************************************************************
        
        Buffers the flow of data from a upstream output. A downstream 
        neighbour can locate and use this buffer instead of creating 
        another instance of their own.

        (note that upstream is closer to the source, and downstream is
        further away)

        Don't forget to flush() buffered content before closing.

*******************************************************************************/

class BufferOutput : Buffer
{
        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (OutputStream stream, uint size = 16 * 1024)
        {
                super (size);
                super.output = stream;
        }
}


