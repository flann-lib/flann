/*******************************************************************************

    copyright:  Copyright (C) 2007 Daniel Keep.  All rights reserved.

    license:    BSD style: $(LICENSE)

    version:    Initial release: July 2007

    author:     Daniel Keep

*******************************************************************************/

module tango.io.compress.BzipStream;

private import tango.io.compress.c.bzlib;

private import tango.core.Exception : IOException;

private import tango.io.Conduit : InputFilter, OutputFilter;

private import tango.io.model.IConduit : InputStream, OutputStream, IConduit;

private
{
    /* This constant controls the size of the input/output buffers we use
     * internally.  There's no particular reason to pick this size.  It might
     * be an idea to run some benchmarks to work out what a good number is.
     */
    const BUFFER_SIZE = 4*1024;

    const DEFAULT_BLOCKSIZE = 9;
    const DEFAULT_WORKFACTOR = 0;
}

/*******************************************************************************
  
    This output filter can be used to perform compression of data into a bzip2
    stream.

*******************************************************************************/

class BzipOutput : OutputFilter
{
    /***************************************************************************

        This enumeration represents several pre-defined compression block
        sizes, measured in hundreds of kilobytes.  See the documentation for
        the BzipOutput class' constructor for more details.

    ***************************************************************************/

    enum BlockSize : int
    {
        Normal = 9,
        Fast = 1,
        Best = 9,
    }

    private
    {
        bool bzs_valid = false;
        bz_stream bzs;
        ubyte[] out_chunk;
        size_t _written = 0;
    }

    /***************************************************************************

        Constructs a new bzip2 compression filter.  You need to pass in the
        stream that the compression filter will write to.  If you are using
        this filter with a conduit, the idiom to use is:

        ---
        auto output = new BzipOutput(myConduit.output);
        output.write(myContent);
        ---

        blockSize relates to the size of the window bzip2 uses when
        compressing data and determines how much memory is required to
        decompress a stream.  It is measured in hundreds of kilobytes.
        
        ccording to the bzip2 documentation, there is no dramatic difference
        between the various block sizes, so the default should suffice in most
        cases.

        BlockSize.Normal (the default) is the same as BlockSize.Best
        (or 9).  The blockSize may be any integer between 1 and 9 inclusive.

    ***************************************************************************/

    this(OutputStream stream, int blockSize = BlockSize.Normal)
    {
        if( blockSize < 1 || blockSize > 9 )
            throw new BzipException("bzip2 block size must be between"
                    " 1 and 9");

        super(stream);
        out_chunk = new ubyte[BUFFER_SIZE];
        
        auto ret = BZ2_bzCompressInit(&bzs, blockSize, 0, DEFAULT_WORKFACTOR);
        if( ret != BZ_OK )
            throw new BzipException(ret);

        bzs_valid = true;
    }

    ~this()
    {
        if( bzs_valid )
            kill_bzs();
    }

    /***************************************************************************

        Compresses the given data to the underlying conduit.

        Returns the number of bytes from src that were compressed, which may
        be less than given.

    ***************************************************************************/

    uint write(void[] src)
    {
        check_valid();
        scope(failure) kill_bzs();

        bzs.avail_in = src.length;
        bzs.next_in = cast(ubyte*)src.ptr;

        do
        {
            bzs.avail_out = out_chunk.length;
            bzs.next_out = out_chunk.ptr;

            auto ret = BZ2_bzCompress(&bzs, BZ_RUN);
            if( ret != BZ_RUN_OK )
                throw new BzipException(ret);

            // Push the compressed bytes out to the stream, until it's either
            // written them all, or choked.
            auto have = out_chunk.length-bzs.avail_out;
            auto out_buffer = out_chunk[0..have];
            do
            {
                auto w = host.write(out_buffer);
                if( w == IConduit.Eof )
                    return w;

                out_buffer = out_buffer[w..$];
                _written += w;
            }
            while( out_buffer.length > 0 );
        }
        // Loop while we are still using up the whole output buffer
        while( bzs.avail_out == 0 );

        assert( bzs.avail_in == 0, "failed to compress all provided data" );

        return src.length;
    }

    /***************************************************************************

        This read-only property returns the number of compressed bytes that
        have been written to the underlying stream.  Following a call to
        either close or commit, this will contain the total compressed size of
        the input data stream.

    ***************************************************************************/

    size_t written()
    {
        return _written;
    }

    /***************************************************************************

        commit the output

    ***************************************************************************/

    void close()
    {
        if( bzs_valid ) commit;
        super.close;
    }

    /***************************************************************************

        Purge any buffered content.  Calling this will implicitly end the
        bzip2 stream, so it should not be called until you are finished
        compressing data.  Any calls to either write or commit after a
        compression filter has been committed will throw an exception.

    ***************************************************************************/

    void commit()
    {
        check_valid();
        scope(failure) kill_bzs();

        bzs.avail_in = 0;
        bzs.next_in = null;

        bool finished = false;

        do
        {
            bzs.avail_out = out_chunk.length;
            bzs.next_out = out_chunk.ptr;

            auto ret = BZ2_bzCompress(&bzs, BZ_FINISH);
            switch( ret )
            {
                case BZ_FINISH_OK:
                    break;

                case BZ_STREAM_END:
                    finished = true;
                    break;

                default:
                    throw new BzipException(ret);
            }

            auto have = out_chunk.length - bzs.avail_out;
            auto out_buffer = out_chunk[0..have];
            if( have > 0 )
            {
                do
                {
                    auto w = host.write(out_buffer);
                    if( w == IConduit.Eof )
                        return w;

                    out_buffer = out_buffer[w..$];
                    _written += w;
                }
                while( out_buffer.length > 0 );
            }
        }
        while( !finished );

        kill_bzs();
    }

    // This function kills the stream: it deallocates the internal state, and
    // unsets the bzs_valid flag.
    private void kill_bzs()
    {
        check_valid();

        BZ2_bzCompressEnd(&bzs);
        bzs_valid = false;
    }

    // Asserts that the stream is still valid and usable (except that this
    // check doesn't get elided with -release).
    private void check_valid()
    {
        if( !bzs_valid )
            throw new BzipClosedException;
    }
}

/*******************************************************************************
  
    This input filter can be used to perform decompression of bzip2 streams.

*******************************************************************************/

class BzipInput : InputFilter
{
    private
    {
        bool bzs_valid = false;
        bz_stream bzs;
        ubyte[] in_chunk;
    }

    /***************************************************************************

        Constructs a new bzip2 decompression filter.  You need to pass in the
        stream that the decompression filter will read from.  If you are using
        this filter with a conduit, the idiom to use is:

        ---
        auto input = new BzipInput(myConduit.input);
        input.read(myContent);
        ---

        The small argument, if set to true, instructs bzip2 to perform
        decompression using half the regular amount of memory, at the cost of
        running at half speed.

    ***************************************************************************/

    this(InputStream stream, bool small=false)
    {
        super(stream);
        in_chunk = new ubyte[BUFFER_SIZE];

        auto ret = BZ2_bzDecompressInit(&bzs, 0, small?1:0);
        if( ret != BZ_OK )
            throw new BzipException(ret);

        bzs_valid = true;
    }

    ~this()
    {
        if( bzs_valid )
            kill_bzs();
    }

    /***************************************************************************

        Decompresses data from the underlying conduit into a target array.

        Returns the number of bytes stored into dst, which may be less than
        requested.

    ***************************************************************************/ 

    uint read(void[] dst)
    {
        check_valid();
        scope(failure) kill_bzs();

        bool finished = false;

        bzs.avail_out = dst.length;
        bzs.next_out = cast(ubyte*)dst.ptr;

        do
        {
            if( bzs.avail_in == 0 )
            {
                auto len = host.read(in_chunk);
                if( len == IConduit.Eof )
                    return IConduit.Eof;

                bzs.avail_in = len;
                bzs.next_in = in_chunk.ptr;
            }

            auto ret = BZ2_bzDecompress(&bzs);
            if( ret == BZ_STREAM_END )
            {
                kill_bzs();
                finished = true;
            }
            else if( ret != BZ_OK )
                throw new BzipException(ret);
        }
        while( !finished && bzs.avail_out > 0 );

        return dst.length - bzs.avail_out;
    }

    /***************************************************************************

        Clear any buffered content.  No-op.

    ***************************************************************************/ 

    InputStream clear()
    {
        check_valid();

        // TODO: What should this method do?  We don't do any heap allocation,
        // so there's really nothing to clear...  For now, just invalidate the
        // stream...
        kill_bzs();
        super.clear();
        return this;
    }

    // This function kills the stream: it deallocates the internal state, and
    // unsets the bzs_valid flag.
    private void kill_bzs()
    {
        check_valid();

        BZ2_bzDecompressEnd(&bzs);
        bzs_valid = false;
    }

    // Asserts that the stream is still valid and usable (except that this
    // check doesn't get elided with -release).
    private void check_valid()
    {
        if( !bzs_valid )
            throw new BzipClosedException;
    }
}

/*******************************************************************************
  
    This exception is thrown when an error occurs in the underlying bzip2
    library.

*******************************************************************************/

class BzipException : IOException
{
    this(in int code)
    {
        super(codeName(code));
    }

    this(char[] msg)
    {
        super(msg);
    }

    private char[] codeName(in int code)
    {
        char[] name;

        switch( code )
        {
            case BZ_OK:                 name = "BZ_OK";                 break;
            case BZ_RUN_OK:             name = "BZ_RUN_OK";             break;
            case BZ_FLUSH_OK:           name = "BZ_FLUSH_OK";           break;
            case BZ_STREAM_END:         name = "BZ_STREAM_END";         break;
            case BZ_SEQUENCE_ERROR:     name = "BZ_SEQUENCE_ERROR";     break;
            case BZ_PARAM_ERROR:        name = "BZ_PARAM_ERROR";        break;
            case BZ_MEM_ERROR:          name = "BZ_MEM_ERROR";          break;
            case BZ_DATA_ERROR:         name = "BZ_DATA_ERROR";         break;
            case BZ_DATA_ERROR_MAGIC:   name = "BZ_DATA_ERROR_MAGIC";   break;
            case BZ_IO_ERROR:           name = "BZ_IO_ERROR";           break;
            case BZ_UNEXPECTED_EOF:     name = "BZ_UNEXPECTED_EOF";     break;
            case BZ_OUTBUFF_FULL:       name = "BZ_OUTBUFF_FULL";       break;
            case BZ_CONFIG_ERROR:       name = "BZ_CONFIG_ERROR";       break;
            default:                    name = "BZ_UNKNOWN";
        }

        return name;
    }
}

/*******************************************************************************
  
    This exception is thrown if you attempt to perform a read, write or flush
    operation on a closed bzip2 filter stream.  This can occur if the input
    stream has finished, or an output stream was flushed.

*******************************************************************************/

class BzipClosedException : IOException
{
    this()
    {
        super("cannot operate on closed bzip2 stream");
    }
}

/* *****************************************************************************

    This section contains a simple unit test for this module.  It is hidden
    behind a version statement because it introduces additional dependencies.

***************************************************************************** */

debug(UnitTest):

import tango.io.GrowBuffer : GrowBuffer;

unittest
{
    const char[] message =
        "All dwarfs are by nature dutiful, serious, literate, obedient "
        "and thoughtful people whose only minor failing is a tendency, "
        "after one drink, to rush at enemies screaming \"Arrrrrrgh!\" and "
        "axing their legs off at the knee.";

    const ubyte[] message_z = [
        0x42, 0x5a, 0x68, 0x39, 0x31, 0x41, 0x59, 0x26,
        0x53, 0x59, 0x40, 0x98, 0xbe, 0xaa, 0x00, 0x00,
        0x16, 0xd5, 0x80, 0x10, 0x00, 0x70, 0x05, 0x20,
        0x00, 0x3f, 0xef, 0xde, 0xe0, 0x30, 0x00, 0xac,
        0xd8, 0x8a, 0x3d, 0x34, 0x6a, 0x6d, 0x4c, 0x4f,
        0x24, 0x31, 0x0d, 0x08, 0x98, 0x9b, 0x48, 0x9a,
        0x7a, 0x80, 0x00, 0x06, 0xa6, 0xd2, 0xa7, 0xe9,
        0xaa, 0x37, 0xa8, 0xd4, 0xf5, 0x3f, 0x54, 0x63,
        0x51, 0xe9, 0x2d, 0x4b, 0x99, 0xe1, 0xcc, 0xca,
        0xda, 0x75, 0x04, 0x42, 0x14, 0xc8, 0x6a, 0x8e,
        0x23, 0xc1, 0x3e, 0xb1, 0x8a, 0x16, 0xd2, 0x55,
        0x9a, 0x3e, 0x56, 0x1a, 0xb1, 0x83, 0x11, 0xa6,
        0x50, 0x4f, 0xd3, 0xed, 0x21, 0x40, 0xaa, 0xd1,
        0x95, 0x2c, 0xda, 0xcb, 0xb7, 0x0e, 0xce, 0x65,
        0xfc, 0x63, 0xf2, 0x88, 0x5b, 0x36, 0xda, 0xf0,
        0xf5, 0xd2, 0x9c, 0xe6, 0xf1, 0x87, 0x12, 0x87,
        0xce, 0x56, 0x0c, 0xf5, 0x65, 0x4d, 0x2e, 0xd6,
        0x27, 0x61, 0x2b, 0x74, 0xcd, 0x5e, 0x3b, 0x02,
        0x42, 0x4e, 0x0b, 0x80, 0xa8, 0x70, 0x04, 0x48,
        0xfb, 0x93, 0x4c, 0x41, 0xa8, 0x2a, 0xdf, 0xf2,
        0x67, 0x37, 0x28, 0xad, 0x38, 0xd4, 0x5c, 0xd6,
        0x34, 0x8b, 0x49, 0x5e, 0x90, 0xb2, 0x06, 0xce,
        0x0a, 0x83, 0x29, 0x84, 0x20, 0xd7, 0x5f, 0xc5,
        0xdc, 0x91, 0x4e, 0x14, 0x24, 0x10, 0x26, 0x2f,
        0xaa, 0x80];

    scope cond = new GrowBuffer;
    scope comp = new BzipOutput(cond);
    comp.write(message);
    comp.close;

    assert( comp.written == message_z.length );

    assert( message_z == cast(ubyte[])(cond.slice) );

    scope decomp = new BzipInput(cond);
    auto buffer = new ubyte[256];
    buffer = buffer[0 .. decomp.read(buffer)];

    assert( cast(ubyte[])message == buffer );
}

