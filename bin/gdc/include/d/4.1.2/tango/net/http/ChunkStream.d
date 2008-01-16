/*******************************************************************************

        copyright:      Copyright (c) Nov 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Nov 2007: Initial release

        author:         Kris

        Support for HTTP chunked I/O. 
        
        See http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html

*******************************************************************************/

module tango.net.http.ChunkStream;

private import  tango.io.Buffer,
                tango.io.Conduit;

private import  tango.text.stream.LineIterator;

private import  Integer = tango.text.convert.Integer;

/*******************************************************************************

        Prefix each block of data with its length (in hex digits) and add
        appropriate \r\n sequences. To write trailing headers you'll need
        to step around this stream (otherwise those headers will be chunk
        stamped also: use this.host or this.buffer to obtain the upstream
        sibling)

*******************************************************************************/

class ChunkOutput : OutputFilter, Buffered
{
        private IBuffer output;

        /***********************************************************************

                Use a buffer belonging to our sibling, if one is available

        ***********************************************************************/

        this (OutputStream stream)
        {
                super (output = Buffer.share(stream));
        }

        /***********************************************************************

                Buffered interface

        ***********************************************************************/

        IBuffer buffer ()
        {
                return output;
        }

        /***********************************************************************

                Write a chunk to the output, prefixed and postfixed in a 
                manner consistent with the HTTP chunked transfer coding

        ***********************************************************************/

        final override uint write (void[] src)
        {
                char[8] tmp = void;
                
                output.append (Integer.format (tmp, src.length, Integer.Style.Hex))
                      .append ("\r\n")
                      .append (src)
                      .append ("\r\n");
                return src.length;
        }
}


/*******************************************************************************

        Parse hex digits, and use the resultant size to modulate requests 
        for incoming data. A chunk size of 0 terminates the stream, so to
        read any trailing headers you'll need to reach into the upstream
        sibling instead (this.host or this.buffer, for example).

*******************************************************************************/

class ChunkInput : LineIterator!(char)
{
        private uint available;

        /***********************************************************************

                Prime the available chunk size by reading and parsing the
                first available line

        ***********************************************************************/

        this (InputStream stream)
        {
                super (stream);
                available = nextChunk;
        }

        /***********************************************************************

                Read and parse another chunk size

        ***********************************************************************/

        private final uint nextChunk ()
        {
                char[] tmp;

                if ((tmp = super.next).ptr)
                     return cast(uint) Integer.parse (tmp, 16);
                return 0;
        }

        /***********************************************************************

                Read content based on a previously parsed chunk size

        ***********************************************************************/

        final override uint read (void[] dst)
        {
                if (available is 0)
                    return IConduit.Eof;
                        
                auto size = dst.length > available ? available : dst.length;
                auto read = super.read (dst [0 .. size]);
                
                // check for next chunk header
                if (read != IConduit.Eof && (available -= read) is 0)
                   {
                   // consume trailing \r\n
                   super.buffer.skip (2);
                   available = nextChunk ();
                   }
                
                return read;
        }
}


/*******************************************************************************

*******************************************************************************/

debug (ChunkStream)
{
        import tango.io.Console;

        void main()
        {
                auto buf = new Buffer(20);
                auto chunk = new ChunkOutput (buf);
                chunk.write ("hello world");
                auto input = new ChunkInput (buf);
                Cout.stream.copy (input);
        }
}
