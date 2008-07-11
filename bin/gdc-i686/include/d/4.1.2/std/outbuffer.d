// outbuffer.d

/**
 * Boilerplate:
 *	$(std_boilerplate.html)
 * Macros:
 *	WIKI = Phobos/StdOutbuffer
 * Copyright:
 *	Copyright (c) 2001-2005 by Digital Mars
 *	All Rights Reserved
 *	www.digitalmars.com
 */


// Written by Walter Bright

/* NOTE: This file has been patched from the original DMD distribution to
   work with the GDC compiler.

   Modified by David Friedman, September 2004
*/

module std.outbuffer;

private
{
    import std.string;
    import std.gc;
    import std.c.stdio;
    import std.c.stdlib;
    import std.c.stdarg;
}

/*********************************************
 * OutBuffer provides a way to build up an array of bytes out
 * of raw data. It is useful for things like preparing an
 * array of bytes to write out to a file.
 * OutBuffer's byte order is the format native to the computer.
 * To control the byte order (endianness), use a class derived
 * from OutBuffer.
 */

class OutBuffer
{
    ubyte data[];
    size_t offset;

    invariant
    {
	//printf("this = %p, offset = %x, data.length = %u\n", this, offset, data.length);
	assert(offset <= data.length);
	assert(data.length <= std.gc.capacity(data.ptr));
    }

    this()
    {
	//printf("in OutBuffer constructor\n");
    }

    /*********************************
     * Convert to array of bytes.
     */

    ubyte[] toBytes() { return data[0 .. offset]; }

    /***********************************
     * Preallocate nbytes more to the size of the internal buffer.
     *
     * This is a
     * speed optimization, a good guess at the maximum size of the resulting
     * buffer will improve performance by eliminating reallocations and copying.
     */


    void reserve(size_t nbytes)
	in
	{
	    assert(offset + nbytes >= offset);
	}
	out
	{
	    assert(offset + nbytes <= data.length);
	    assert(data.length <= std.gc.capacity(data.ptr));
	}
	body
	{
	    if (data.length < offset + nbytes)
	    {
		//std.c.stdio.printf("OutBuffer.reserve: ptr = %p, length = %d, offset = %d, nbytes = %d, capacity = %d\n", data.ptr, data.length, offset, nbytes, std.gc.capacity(data.ptr));
		data.length = (offset + nbytes) * 2;
		//std.c.stdio.printf("OutBuffer.reserve: ptr = %p, length = %d, capacity = %d\n", data.ptr, data.length, std.gc.capacity(data.ptr));
		std.gc.hasPointers(data.ptr);
	    }
	}

    /*************************************
     * Append data to the internal buffer.
     */

    void write(ubyte[] bytes)
	{
	    reserve(bytes.length);
	    data[offset .. offset + bytes.length] = bytes;
	    offset += bytes.length;
	}

    void write(ubyte b)		/// ditto
	{
	    reserve(ubyte.sizeof);
	    this.data[offset] = b;
	    offset += ubyte.sizeof;
	}

    void write(byte b) { write(cast(ubyte)b); }		/// ditto
    void write(char c) { write(cast(ubyte)c); }		/// ditto

    void write(ushort w)		/// ditto
    {
	reserve(ushort.sizeof);
	*cast(ushort *)&data[offset] = w;
	offset += ushort.sizeof;
    }

    void write(short s) { write(cast(ushort)s); }		/// ditto

    void write(wchar c)		/// ditto
    {
	reserve(wchar.sizeof);
	*cast(wchar *)&data[offset] = c;
	offset += wchar.sizeof;
    }

    void write(uint w)		/// ditto
    {
	reserve(uint.sizeof);
	*cast(uint *)&data[offset] = w;
	offset += uint.sizeof;
    }

    void write(int i) { write(cast(uint)i); }		/// ditto

    void write(ulong l)		/// ditto
    {
	reserve(ulong.sizeof);
	*cast(ulong *)&data[offset] = l;
	offset += ulong.sizeof;
    }

    void write(long l) { write(cast(ulong)l); }		/// ditto

    void write(float f)		/// ditto
    {
	reserve(float.sizeof);
	*cast(float *)&data[offset] = f;
	offset += float.sizeof;
    }

    void write(double f)		/// ditto
    {
	reserve(double.sizeof);
	*cast(double *)&data[offset] = f;
	offset += double.sizeof;
    }

    void write(real f)		/// ditto
    {
	reserve(real.sizeof);
	*cast(real *)&data[offset] = f;
	offset += real.sizeof;
    }

    void write(char[] s)		/// ditto
    {
	write(cast(ubyte[])s);
    }

    void write(OutBuffer buf)		/// ditto
    {
	write(buf.toBytes());
    }

    /****************************************
     * Append nbytes of 0 to the internal buffer.
     */

    void fill0(uint nbytes)
    {
	reserve(nbytes);
	data[offset .. offset + nbytes] = 0;
	offset += nbytes;
    }

    /**********************************
     * 0-fill to align on power of 2 boundary.
     */

    void alignSize(size_t alignsize)
    in
    {
	assert(alignsize && (alignsize & (alignsize - 1)) == 0);
    }
    out
    {
	assert((offset & (alignsize - 1)) == 0);
    }
    body
    {   size_t nbytes;

	nbytes = offset & (alignsize - 1);
	if (nbytes)
	    fill0(alignsize - nbytes);
    }

    /****************************************
     * Optimize common special case alignSize(2)
     */

    void align2()
    {
	if (offset & 1)
	    write(cast(byte)0);
    }

    /****************************************
     * Optimize common special case alignSize(4)
     */

    void align4()
    {
	if (offset & 3)
	{   size_t nbytes = (4 - offset) & 3;
	    fill0(nbytes);
	}
    }

    /**************************************
     * Convert internal buffer to array of chars.
     */

    char[] toString()
    {
	//printf("OutBuffer.toString()\n");
	return cast(char[])data[0 .. offset];
    }

    /*****************************************
     * Append output of C's vprintf() to internal buffer.
     */

    void vprintf(char[] format, va_list args)
    {
	char[128] buffer;
	char* p;
	char* f;
	uint psize;
	int count;
	va_list args_copy;

	f = toStringz(format);
	p = buffer.ptr;
	psize = buffer.length;
	for (;;)
	{
	    va_copy(args_copy, args);
	    version(Win32)
	    {
		count = _vsnprintf(p,psize,f,args_copy);
		if (count != -1)
		    break;
		psize *= 2;
		p = cast(char *) alloca(psize);	// buffer too small, try again with larger size
	    }
	    else version(GNU) {
		count = vsnprintf(p,psize,f,args_copy);
		if (count == -1)
		    psize *= 2;
		else if (count >= psize)
		    psize = count + 1;
		else
		    break;
		p = cast(char *) alloca(psize);	// buffer too small, try again with larger size
	    }
	    else version(linux)
	    {
		count = vsnprintf(p,psize,f,args_copy);
		if (count == -1)
		    psize *= 2;
		else if (count >= psize)
		    psize = count + 1;
		else
		    break;
		/+
		if (p != buffer)
		    c.stdlib.free(p);
		p = (char *) c.stdlib.malloc(psize);	// buffer too small, try again with larger size
		+/
		p = cast(char *) alloca(psize);	// buffer too small, try again with larger size
	    }
	}
	write(p[0 .. count]);
	/+
	version (linux)
	{
	    if (p != buffer)
		c.stdlib.free(p);
	}
	+/
    }

    /*****************************************
     * Append output of C's printf() to internal buffer.
     */

    void printf(char[] format, ...)
    {
	version (GNU)
	{
	    vprintf(format, _argptr);
	}
	else
	{
	    va_list ap;
	    ap = cast(va_list)&format;
	    ap += format.sizeof;
	    vprintf(format, ap);
	}
    }

    /*****************************************
     * At offset index into buffer, create nbytes of space by shifting upwards
     * all data past index.
     */

    void spread(size_t index, size_t nbytes)
	in
	{
	    assert(index <= offset);
	}
	body
	{
	    reserve(nbytes);

	    // This is an overlapping copy - should use memmove()
	    for (size_t i = offset; i > index; )
	    {
		--i;
		data[i + nbytes] = data[i];
	    }
	    offset += nbytes;
	}
}

unittest
{
    //printf("Starting OutBuffer test\n");

    OutBuffer buf = new OutBuffer();

    //printf("buf = %p\n", buf);
    //printf("buf.offset = %x\n", buf.offset);
    assert(buf.offset == 0);
    buf.write("hello");
    buf.write(cast(byte)0x20);
    buf.write("world");
    buf.printf(" %d", 6);
    //printf("buf = '%.*s'\n", buf.toString());
    assert(cmp(buf.toString(), "hello world 6") == 0);
}
