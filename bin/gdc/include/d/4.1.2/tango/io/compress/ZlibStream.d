/*******************************************************************************

    copyright:  Copyright (C) 2007 Daniel Keep.  All rights reserved.

    license:    BSD style: $(LICENSE)

    version:    Initial release: July 2007

    author:     Daniel Keep

    history:    Added support for "window bits", needed for Zip support.

*******************************************************************************/

module tango.io.compress.ZlibStream;

private import tango.io.compress.c.zlib;

private import tango.stdc.stringz : fromUtf8z;

private import tango.core.Exception : IOException;

private import tango.io.Conduit : InputFilter, OutputFilter;

private import tango.io.model.IConduit : InputStream, OutputStream, IConduit;


/* This constant controls the size of the input/output buffers we use
 * internally.  This should be a fairly sane value (it's suggested by the zlib
 * documentation), that should only need changing for memory-constrained
 * platforms/use cases.
 *
 * An alternative would be to make the chunk size a template parameter to the
 * filters themselves, but Tango already has more than enough template
 * parameters getting in the way :)
 */

private const CHUNKSIZE = 256 * 1024;

/*******************************************************************************
  
    This input filter can be used to perform decompression of zlib streams.

*******************************************************************************/

class ZlibInput : InputFilter
{
    private
    {
        /* Used to make sure we don't try to perform operations on a dead
         * stream. */
        bool zs_valid = false;

        z_stream zs;
        ubyte[] in_chunk;
    }

    /***************************************************************************

        Constructs a new zlib decompression filter.  You need to pass in the
        stream that the decompression filter will read from.  If you are using
        this filter with a conduit, the idiom to use is:

        ---
        auto input = new ZlibInput(myConduit.input));
        input.read(myContent);
        ---

        The optional windowBits parameter is the base two logarithm of the
        window size, and should be in the range 8-15, defaulting to 15 if not
        specified.  Additionally, the windowBits parameter may be negative to
        indicate that zlib should omit the standard zlib header and trailer,
        with the window size being -windowBits.

    ***************************************************************************/

    this(InputStream stream)
    {
        super (stream);
        in_chunk = new ubyte[CHUNKSIZE];

        // Allocate inflate state
        with( zs )
        {
            zalloc = null;
            zfree = null;
            opaque = null;
            avail_in = 0;
            next_in = null;
        }

        auto ret = inflateInit(&zs);
        if( ret != Z_OK )
            throw new ZlibException(ret);

        zs_valid = true;
    }

    /// ditto
    this(InputStream stream, int windowBits)
    {
        super (stream);
        in_chunk = new ubyte[CHUNKSIZE];

        // Allocate inflate state
        with( zs )
        {
            zalloc = null;
            zfree = null;
            opaque = null;
            avail_in = 0;
            next_in = null;
        }

        auto ret = inflateInit2(&zs, windowBits);
        if( ret != Z_OK )
            throw new ZlibException(ret);

        zs_valid = true;
    }

    ~this()
    {
        if( zs_valid )
            kill_zs();
    }

    /***************************************************************************

        Decompresses data from the underlying conduit into a target array.

        Returns the number of bytes stored into dst, which may be less than
        requested.

    ***************************************************************************/ 

    override uint read(void[] dst)
    {
        if( !zs_valid )
            return IConduit.Eof;

        // Check to see if we've run out of input data.  If we have, get some
        // more.
        if( zs.avail_in == 0 )
        {
            auto len = host.read(in_chunk);
            if( len == IConduit.Eof )
                return IConduit.Eof;

            zs.avail_in = len;
            zs.next_in = in_chunk.ptr;
        }

        // We'll tell zlib to inflate straight into the target array.
        zs.avail_out = dst.length;
        zs.next_out = cast(ubyte*)dst.ptr;
        auto ret = inflate(&zs, Z_NO_FLUSH);

        switch( ret )
        {
            case Z_NEED_DICT:
                // Whilst not technically an error, this should never happen
                // for general-use code, so treat it as an error.
            case Z_DATA_ERROR:
            case Z_MEM_ERROR:
                kill_zs();
                throw new ZlibException(ret);

            case Z_STREAM_END:
                // zlib stream is finished; kill the stream so we don't try to
                // read from it again.
                kill_zs();
                break;

            default:
        }

        return dst.length - zs.avail_out;
    }

    /***************************************************************************

        Clear any buffered content.  No-op.

    ***************************************************************************/ 

    override InputStream clear()
    {
        check_valid();

        // TODO: What should this method do?  We don't do any heap allocation,
        // so there's really nothing to clear...  For now, just invalidate the
        // stream...
        kill_zs();

        super.clear();
        return this;
    }

    // This function kills the stream: it deallocates the internal state, and
    // unsets the zs_valid flag.
    private void kill_zs()
    {
        check_valid();

        inflateEnd(&zs);
        zs_valid = false;
    }

    // Asserts that the stream is still valid and usable (except that this
    // check doesn't get elided with -release).
    private void check_valid()
    {
        if( !zs_valid )
            throw new ZlibClosedException;
    }
}

/*******************************************************************************
  
    This output filter can be used to perform compression of data into a zlib
    stream.

*******************************************************************************/

class ZlibOutput : OutputFilter
{
    /***************************************************************************

        This enumeration represents several pre-defined compression levels.

        None instructs zlib to perform no compression whatsoever, and simply
        store the data stream.  Note that this actually expands the stream
        slightly to accommodate the zlib stream metadata.

        Fast instructs zlib to perform a minimal amount of compression, Best
        indicates that you want the maximum level of compression and Normal
        (the default level) is a compromise between the two.  The exact
        compression level Normal represents is determined by the underlying
        zlib library, but is typically level 6.

        Any integer between -1 and 9 inclusive may be used as a level,
        although the symbols in this enumeration should suffice for most
        use-cases.

    ***************************************************************************/

    enum Level : int
    {
        Normal = -1,
        None = 0,
        Fast = 1,
        Best = 9
    }

    private
    {
        bool zs_valid = false;
        z_stream zs;
        ubyte[] out_chunk;
        size_t _written = 0;
    }

    /***************************************************************************

        Constructs a new zlib compression filter.  You need to pass in the
        stream that the compression filter will write to.  If you are using
        this filter with a conduit, the idiom to use is:

        ---
        auto output = new ZlibOutput(myConduit.output);
        output.write(myContent);
        ---

        The optional windowBits parameter is the base two logarithm of the
        window size, and should be in the range 8-15, defaulting to 15 if not
        specified.  Additionally, the windowBits parameter may be negative to
        indicate that zlib should omit the standard zlib header and trailer,
        with the window size being -windowBits.

    ***************************************************************************/

    this(OutputStream stream, Level level = Level.Normal)
    {
        super(stream);
        out_chunk = new ubyte[CHUNKSIZE];

        // Allocate deflate state
        with( zs )
        {
            zalloc = null;
            zfree = null;
            opaque = null;
        }

        auto ret = deflateInit(&zs, level);
        if( ret != Z_OK )
            throw new ZlibException(ret);

        zs_valid = true;
    }

    /// ditto
    this(OutputStream stream, Level level, int windowBits)
    {
        super(stream);
        out_chunk = new ubyte[CHUNKSIZE];

        // Allocate deflate state
        with( zs )
        {
            zalloc = null;
            zfree = null;
            opaque = null;
        }

        auto ret = deflateInit2(&zs, level, Z_DEFLATED, windowBits, 8,
                Z_DEFAULT_STRATEGY);
        if( ret != Z_OK )
            throw new ZlibException(ret);

        zs_valid = true;
    }

    ~this()
    {
        if( zs_valid )
            kill_zs();
    }

    /***************************************************************************

        Compresses the given data to the underlying conduit.

        Returns the number of bytes from src that were compressed; write
        should always consume all data provided to it, although it may not be
        immediately written to the underlying output stream.

    ***************************************************************************/

    override uint write(void[] src)
    {
        check_valid();
        scope(failure) kill_zs();

        zs.avail_in = src.length;
        zs.next_in = cast(ubyte*)src.ptr;

        do
        {
            zs.avail_out = out_chunk.length;
            zs.next_out = out_chunk.ptr;

            auto ret = deflate(&zs, Z_NO_FLUSH);
            if( ret == Z_STREAM_ERROR )
                throw new ZlibException(ret);

            // Push the compressed bytes out to the stream, until it's either
            // written them all, or choked.
            auto have = out_chunk.length-zs.avail_out;
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
        while( zs.avail_out == 0 );

        assert( zs.avail_in == 0, "failed to compress all provided data" );

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

    override void close()
    {
        // Only commit if the stream is still open.
        if( zs_valid ) commit;

        super.close;
    }

    /***************************************************************************

        Purge any buffered content.  Calling this will implicitly end the zlib
        stream, so it should not be called until you are finished compressing
        data.  Any calls to either write or commit after a compression filter
        has been committed will throw an exception.

    ***************************************************************************/

    void commit()
    {
        check_valid();
        scope(failure) kill_zs();

        zs.avail_in = 0;
        zs.next_in = null;

        bool finished = false;

        do
        {
            zs.avail_out = out_chunk.length;
            zs.next_out = out_chunk.ptr;

            auto ret = deflate(&zs, Z_FINISH);
            switch( ret )
            {
                case Z_OK:
                    // Keep going
                    break;

                case Z_STREAM_END:
                    // We're done!
                    finished = true;
                    break;

                default:
                    throw new ZlibException(ret);
            }

            auto have = out_chunk.length - zs.avail_out;
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

        kill_zs();
    }

    // This function kills the stream: it deallocates the internal state, and
    // unsets the zs_valid flag.
    private void kill_zs()
    {
        check_valid();

        deflateEnd(&zs);
        zs_valid = false;
    }

    // Asserts that the stream is still valid and usable (except that this
    // check doesn't get elided with -release).
    private void check_valid()
    {
        if( !zs_valid )
            throw new ZlibClosedException;
    }
}

/*******************************************************************************
  
    This exception is thrown if you attempt to perform a read, write or flush
    operation on a closed zlib filter stream.  This can occur if the input
    stream has finished, or an output stream was flushed.

*******************************************************************************/

class ZlibClosedException : IOException
{
    this()
    {
        super("cannot operate on closed zlib stream");
    }
}

/*******************************************************************************
  
    This exception is thrown when an error occurs in the underlying zlib
    library.  Where possible, it will indicate both the name of the error, and
    any textural message zlib has provided.

*******************************************************************************/

class ZlibException : IOException
{
    this(int code)
    {
        super(codeName(code));
    }

    this(int code, char* msg)
    {
        super(codeName(code)~": "~fromUtf8z(msg));
    }

    protected char[] codeName(int code)
    {
        char[] name;

        switch( code )
        {
            case Z_OK:              name = "Z_OK";              break;
            case Z_STREAM_END:      name = "Z_STREAM_END";      break;
            case Z_NEED_DICT:       name = "Z_NEED_DICT";       break;
            case Z_ERRNO:           name = "Z_ERRNO";           break;
            case Z_STREAM_ERROR:    name = "Z_STREAM_ERROR";    break;
            case Z_DATA_ERROR:      name = "Z_DATA_ERROR";      break;
            case Z_MEM_ERROR:       name = "Z_MEM_ERROR";       break;
            case Z_BUF_ERROR:       name = "Z_BUF_ERROR";       break;
            case Z_VERSION_ERROR:   name = "Z_VERSION_ERROR";   break;
            default:                name = "Z_UNKNOWN";
        }

        return name;
    }
}

/* *****************************************************************************

    This section contains a simple unit test for this module.  It is hidden
    behind a version statement because it introduces additional dependencies.

***************************************************************************** */

debug(UnitTest) {

import tango.io.GrowBuffer : GrowBuffer;

unittest
{
    // One ring to rule them all, one ring to find them,
    // One ring to bring them all and in the darkness bind them.
    const char[] message = 
        "Ash nazg durbatulûk, ash nazg gimbatul, "
        "ash nazg thrakatulûk, agh burzum-ishi krimpatul.";

    // This compressed data was created using Python 2.5's built in zlib
    // module, with the default compression level.
    const ubyte[] message_z = [
        0x78,0x9c,0x73,0x2c,0xce,0x50,0xc8,0x4b,
        0xac,0x4a,0x57,0x48,0x29,0x2d,0x4a,0x4a,
        0x2c,0x29,0xcd,0x39,0xbc,0x3b,0x5b,0x47,
        0x21,0x11,0x26,0x9a,0x9e,0x99,0x0b,0x16,
        0x45,0x12,0x2a,0xc9,0x28,0x4a,0xcc,0x46,
        0xa8,0x4c,0xcf,0x50,0x48,0x2a,0x2d,0xaa,
        0x2a,0xcd,0xd5,0xcd,0x2c,0xce,0xc8,0x54,
        0xc8,0x2e,0xca,0xcc,0x2d,0x00,0xc9,0xea,
        0x01,0x00,0x1f,0xe3,0x22,0x99];

    scope cond_z = new GrowBuffer;
    scope comp = new ZlibOutput(cond_z);
    comp.write (message);
    comp.close;

    assert( comp.written == message_z.length );

    assert( message_z == cast(ubyte[])(cond_z.slice) );

    scope decomp = new ZlibInput(cond_z);
    auto buffer = new ubyte[256];
    buffer = buffer[0 .. decomp.read(buffer)];

    assert( cast(ubyte[])message == buffer );
}
}
