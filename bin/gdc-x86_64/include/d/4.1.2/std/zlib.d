/**
 * Compress/decompress data using the $(LINK2 http://www._zlib.net, zlib library).
 *
 * References:
 *	$(LINK2 http://en.wikipedia.org/wiki/Zlib, Wikipedia)
 * License:
 *	Public Domain
 *
 * Macros:
 *	WIKI = Phobos/StdZlib
 */

/* NOTE: This file has been patched from the original DMD distribution to
   work with the GDC compiler.

   Modified by David Friedman, February 2007
*/

module std.zlib;

 //debug=zlib;		// uncomment to turn on debugging printf's

private import etc.c.zlib, std.stdint;

// Values for 'mode'

enum
{
	Z_NO_FLUSH      = 0,
	Z_SYNC_FLUSH    = 2,
	Z_FULL_FLUSH    = 3,
	Z_FINISH        = 4,
}

/*************************************
 * Errors throw a ZlibException.
 */

class ZlibException : Exception
{
    this(int errnum)
    {	char[] msg;

	switch (errnum)
	{
	    case Z_STREAM_END:		msg = "stream end"; break;
	    case Z_NEED_DICT:		msg = "need dict"; break;
	    case Z_ERRNO:		msg = "errno"; break;
	    case Z_STREAM_ERROR:	msg = "stream error"; break;
	    case Z_DATA_ERROR:		msg = "data error"; break;
	    case Z_MEM_ERROR:		msg = "mem error"; break;
	    case Z_BUF_ERROR:		msg = "buf error"; break;
	    case Z_VERSION_ERROR:	msg = "version error"; break;
	    default:			msg = "unknown error";	break;
	}
	super(msg);
    }
}

/**************************************************
 * Compute the Adler32 checksum of the data in buf[]. adler is the starting
 * value when computing a cumulative checksum.
 */

uint adler32(uint adler, void[] buf)
{
    return etc.c.zlib.adler32(adler, cast(ubyte *)buf, buf.length);
}

unittest
{
    static ubyte[] data = [1,2,3,4,5,6,7,8,9,10];

    uint adler;

    debug(zlib) printf("D.zlib.adler32.unittest\n");
    adler = adler32(0u, cast(void[])data);
    debug(zlib) printf("adler = %x\n", adler);
    assert(adler == 0xdc0037);
}

/*********************************
 * Compute the CRC32 checksum of the data in buf[]. crc is the starting value
 * when computing a cumulative checksum.
 */

uint crc32(uint crc, void[] buf)
{
    return etc.c.zlib.crc32(crc, cast(ubyte *)buf, buf.length);
}

unittest
{
    static ubyte[] data = [1,2,3,4,5,6,7,8,9,10];

    uint crc;

    debug(zlib) printf("D.zlib.crc32.unittest\n");
    crc = crc32(0u, cast(void[])data);
    debug(zlib) printf("crc = %x\n", crc);
    assert(crc == 0x2520577b);
}

/*********************************************
 * Compresses the data in srcbuf[] using compression _level level.
 * The default value
 * for level is 6, legal values are 1..9, with 1 being the least compression
 * and 9 being the most.
 * Returns the compressed data.
 */

void[] compress(void[] srcbuf, int level)
in
{
    assert(-1 <= level && level <= 9);
}
body
{
    int err;
    ubyte[] destbuf;
    Culong_t destlen;

    destlen = srcbuf.length + ((srcbuf.length + 1023) / 1024) + 12;
    destbuf = new ubyte[destlen];
    err = etc.c.zlib.compress2(destbuf.ptr, &destlen, cast(ubyte *)srcbuf, srcbuf.length, level);
    if (err)
    {	delete destbuf;
	throw new ZlibException(err);
    }

    destbuf.length = destlen;
    return destbuf;
}

/*********************************************
 * ditto
 */

void[] compress(void[] buf)
{
    return compress(buf, Z_DEFAULT_COMPRESSION);
}

/*********************************************
 * Decompresses the data in srcbuf[].
 * Params: destlen = size of the uncompressed data.
 * It need not be accurate, but the decompression will be faster if the exact
 * size is supplied.
 * Returns: the decompressed data.
 */

void[] uncompress(void[] srcbuf, size_t destlen = 0u, int winbits = 15)
{
    int err;
    ubyte[] destbuf;

    if (!destlen)
	destlen = srcbuf.length * 2 + 1;

    while (1)
    {
	etc.c.zlib.z_stream zs;

	destbuf = new ubyte[destlen];
	
	zs.next_in = cast(ubyte*) srcbuf;
	zs.avail_in = srcbuf.length;

	zs.next_out = destbuf.ptr;
	zs.avail_out = destlen;

	err = etc.c.zlib.inflateInit2(&zs, winbits);
	if (err)
	{   delete destbuf;
	    throw new ZlibException(err);
	}
	err = etc.c.zlib.inflate(&zs, Z_NO_FLUSH);
	switch (err)
	{
	    case Z_OK:
		etc.c.zlib.inflateEnd(&zs);
		destlen = destbuf.length * 2;
		continue;

	    case Z_STREAM_END:
		destbuf.length = zs.total_out;
		err = etc.c.zlib.inflateEnd(&zs);
		if (err != Z_OK)
		    goto Lerr;
		return destbuf;

	    default:
		etc.c.zlib.inflateEnd(&zs);
	    Lerr:
		delete destbuf;
		throw new ZlibException(err);
	}
    }
    assert(0);
}

unittest
{
    ubyte[] src = cast(ubyte[])
"the quick brown fox jumps over the lazy dog\r
the quick brown fox jumps over the lazy dog\r
";
    ubyte[] dst;
    ubyte[] result;

    //arrayPrint(src);
    dst = cast(ubyte[])compress(cast(void[])src);
    //arrayPrint(dst);
    result = cast(ubyte[])uncompress(cast(void[])dst);
    //arrayPrint(result);
    assert(result == src);
}

/+
void arrayPrint(ubyte[] array)
{
    //printf("array %p,%d\n", (void*)array, array.length);
    for (int i = 0; i < array.length; i++)
    {
	printf("%02x ", array[i]);
	if (((i + 1) & 15) == 0)
	    printf("\n");
    }
    printf("\n\n");
}
+/

/*********************************************
 * Used when the data to be compressed is not all in one buffer.
 */

class Compress
{
  private:
    z_stream zs;
    int level = Z_DEFAULT_COMPRESSION;
    int inited;

    void error(int err)
    {
	if (inited)
	{   deflateEnd(&zs);
	    inited = 0;
	}
	throw new ZlibException(err);
    }

  public:

    /**
     * Construct. level is the same as for D.zlib.compress().
     */
    this(int level)
    in
    {
	assert(1 <= level && level <= 9);
    }
    body
    {
	this.level = level;
    }

    /// ditto
    this()
    {
    }

    ~this()
    {	int err;

	if (inited)
	{
	    inited = 0;
	    err = deflateEnd(&zs);
	    if (err)
		error(err);
	}
    }

    /**
     * Compress the data in buf and return the compressed data.
     * The buffers
     * returned from successive calls to this should be concatenated together.
     */
    void[] compress(void[] buf)
    {	int err;
	ubyte[] destbuf;

	if (buf.length == 0)
	    return null;

	if (!inited)
	{
	    err = deflateInit(&zs, level);
	    if (err)
		error(err);
	    inited = 1;
	}

	destbuf = new ubyte[zs.avail_in + buf.length];
	zs.next_out = destbuf.ptr;
	zs.avail_out = destbuf.length;

	if (zs.avail_in)
	    buf = cast(void[])zs.next_in[0 .. zs.avail_in] ~ buf;

	zs.next_in = cast(ubyte*) buf.ptr;
	zs.avail_in = buf.length;

	err = deflate(&zs, Z_NO_FLUSH);
	if (err != Z_STREAM_END && err != Z_OK)
	{   delete destbuf;
	    error(err);
	}
	destbuf.length = destbuf.length - zs.avail_out;
	return destbuf;
    }

    /***
     * Compress and return any remaining data.
     * The returned data should be appended to that returned by compress().
     * Params:
     *	mode = one of the following: 
     *		$(DL
		    $(DT Z_SYNC_FLUSH )
		    $(DD Syncs up flushing to the next byte boundary.
			Used when more data is to be compressed later on.)
		    $(DT Z_FULL_FLUSH )
		    $(DD Syncs up flushing to the next byte boundary.
			Used when more data is to be compressed later on,
			and the decompressor needs to be restartable at this
			point.)
		    $(DT Z_FINISH)
		    $(DD (default) Used when finished compressing the data. )
		)
     */
    void[] flush(int mode = Z_FINISH)
    in
    {
	assert(mode == Z_FINISH || mode == Z_SYNC_FLUSH || mode == Z_FULL_FLUSH);
    }
    body
    {
	void[] destbuf;
	ubyte[512] tmpbuf = void;
	int err;

	if (!inited)
	    return null;

	/* may be  zs.avail_out+<some constant>
	 * zs.avail_out is set nonzero by deflate in previous compress()
	 */
	//tmpbuf = new void[zs.avail_out];
	zs.next_out = tmpbuf.ptr;
	zs.avail_out = tmpbuf.length;

	while( (err = deflate(&zs, mode)) != Z_STREAM_END)
	{
	    if (err == Z_OK)
	    {
		if (zs.avail_out != 0 && mode != Z_FINISH)
		    break;
		else if(zs.avail_out == 0)
		{
		    destbuf ~= tmpbuf;
		    zs.next_out = tmpbuf.ptr;
		    zs.avail_out = tmpbuf.length;
		    continue;
		}
		err = Z_BUF_ERROR;
	    }
	    delete destbuf;
	    error(err);
	}
	destbuf ~= tmpbuf[0 .. (tmpbuf.length - zs.avail_out)];

	if (mode == Z_FINISH)
	{
	    err = deflateEnd(&zs);
	    inited = 0;
	    if (err)
		error(err);
	}
	return destbuf;
    }
}

/******
 * Used when the data to be decompressed is not all in one buffer.
 */

class UnCompress
{
  private:
    z_stream zs;
    int inited;
    int done;
    uint destbufsize;

    void error(int err)
    {
	if (inited)
	{   inflateEnd(&zs);
	    inited = 0;
	}
	throw new ZlibException(err);
    }

  public:

    /**
     * Construct. destbufsize is the same as for D.zlib.uncompress().
     */
    this(uint destbufsize)
    {
	this.destbufsize = destbufsize;
    }

    /** ditto */
    this()
    {
    }

    ~this()
    {	int err;

	if (inited)
	{
	    inited = 0;
	    err = inflateEnd(&zs);
	    if (err)
		error(err);
	}
	done = 1;
    }

    /**
     * Decompress the data in buf and return the decompressed data.
     * The buffers returned from successive calls to this should be concatenated
     * together.
     */
    void[] uncompress(void[] buf)
    in
    {
	assert(!done);
    }
    body
    {	int err;
	ubyte[] destbuf;

	if (buf.length == 0)
	    return null;

	if (!inited)
	{
	    err = inflateInit(&zs);
	    if (err)
		error(err);
	    inited = 1;
	}

	if (!destbufsize)
	    destbufsize = buf.length * 2;
	destbuf = new ubyte[zs.avail_in * 2 + destbufsize];
	zs.next_out = destbuf.ptr;
	zs.avail_out = destbuf.length;

	if (zs.avail_in)
	    buf = cast(void[])zs.next_in[0 .. zs.avail_in] ~ buf;

	zs.next_in = cast(ubyte*) buf;
	zs.avail_in = buf.length;

	err = inflate(&zs, Z_NO_FLUSH);
	if (err != Z_STREAM_END && err != Z_OK)
	{   delete destbuf;
	    error(err);
	}
	destbuf.length = destbuf.length - zs.avail_out;
	return destbuf;
    }

    /**
     * Decompress and return any remaining data.
     * The returned data should be appended to that returned by uncompress().
     * The UnCompress object cannot be used further.
     */
    void[] flush()
    in
    {
	assert(!done);
    }
    out
    {
	assert(done);
    }
    body
    {
	ubyte[] extra;
	ubyte[] destbuf;
	int err;

	done = 1;
	if (!inited)
	    return null;

      L1:
	destbuf = new ubyte[zs.avail_in * 2 + 100];
	zs.next_out = destbuf.ptr;
	zs.avail_out = destbuf.length;

	err = etc.c.zlib.inflate(&zs, Z_NO_FLUSH);
	if (err == Z_OK && zs.avail_out == 0)
	{
	    extra ~= destbuf;
	    goto L1;
	}
	if (err != Z_STREAM_END)
	{
	    delete destbuf;
	    if (err == Z_OK)
		err = Z_BUF_ERROR;
	    error(err);
	}
	destbuf = destbuf.ptr[0 .. zs.next_out - destbuf.ptr];
	err = etc.c.zlib.inflateEnd(&zs);
	inited = 0;
	if (err)
	    error(err);
	if (extra.length)
	    destbuf = extra ~ destbuf;
	return destbuf;
    }
}

/* ========================== unittest ========================= */

private import std.stdio;
private import std.random;

unittest // by Dave
{
    debug(zlib) printf("std.zlib.unittest\n");

    bool CompressThenUncompress (ubyte[] src)
    {
      try {
	ubyte[] dst = cast(ubyte[])std.zlib.compress(cast(void[])src);
	double ratio = (dst.length / cast(double)src.length);
	debug(zlib) writef("src.length:  ", src.length, ", dst: ", dst.length, ", Ratio = ", ratio);
	ubyte[] uncompressedBuf;
	uncompressedBuf = cast(ubyte[])std.zlib.uncompress(cast(void[])dst);
	assert(src.length == uncompressedBuf.length);
	assert(src == uncompressedBuf);
      }
      catch {
	debug(zlib) writefln(" ... Exception thrown when src.length = ", src.length, ".");
	return false;
      }
      return true;
    }


    // smallish buffers
    for(int idx = 0; idx < 25; idx++) {
        char[] buf = new char[rand() % 100];

        // Alternate between more & less compressible
        foreach(inout char c; buf) c = ' ' + (rand() % (idx % 2 ? 91 : 2));

        if(CompressThenUncompress(cast(ubyte[])buf)) {
            debug(zlib) printf("; Success.\n");
        } else {
            return;
        }
    }

    // larger buffers
    for(int idx = 0; idx < 25; idx++) {
        char[] buf = new char[rand() % 1000/*0000*/];

        // Alternate between more & less compressible
        foreach(inout char c; buf) c = ' ' + (rand() % (idx % 2 ? 91 : 10));

        if(CompressThenUncompress(cast(ubyte[])buf)) {
            debug(zlib) printf("; Success.\n");
        } else {
            return;
        }
    }

    debug(zlib) printf("PASSED std.zlib.unittest\n");
}


unittest // by Artem Rebrov
{
    Compress cmp = new Compress;
    UnCompress decmp = new UnCompress;

    void[] input;
    input = "tesatdffadf";

    void[] buf = cmp.compress(input);
    buf ~= cmp.flush();
    void[] output = decmp.uncompress(buf);

    //writefln("input = '%s'", cast(char[])input);
    //writefln("output = '%s'", cast(char[])output);
    assert( output[] == input[] );
}

