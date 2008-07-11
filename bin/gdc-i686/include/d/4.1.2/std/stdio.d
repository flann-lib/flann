
// Written in the D programming language.

/* Written by Walter Bright and Andrei Alexandrescu
 * www.digitalmars.com
 * Placed in the Public Domain.
 */

/* NOTE: This file has been patched from the original DMD distribution to
   work with the GDC compiler.

   Modified by David Friedman, April 2007
*/

/********************************
 * Standard I/O functions that extend $(B std.c.stdio).
 * $(B std.c.stdio) is automatically imported when importing
 * $(B std.stdio).
 * Macros:
 *	WIKI=Phobos/StdStdio
 */

module std.stdio;

public import std.c.stdio;

import std.format;
import std.utf;
import std.string;
import std.gc;
import std.c.stdlib;
import std.c.string;
import std.c.stddef;

import std.stdarg;

version (GNU)
{
    static import gcc.config.config;
    import gcc.config.config : Have_getdelim, Have_Unlocked_Stdio,
	Have_Unlocked_Wide_Stdio, Have_fwide, Have_fgetln,
	Have_fgetline;

    extern(C)
    {
	char * fgetln(FILE *stream, size_t *len);
	char * fgetline(FILE *stream, size_t *len);
	int putc_unlocked(int, FILE*);
	int putwc_unlocked(wchar_t, FILE*);
	int getc_unlocked(FILE*);
	int getwc_unlocked(FILE*);
	void flockfile(FILE*);
	void funlockfile(FILE*);
    }
    
    static if (Have_getdelim)
    {
	import gcc.config.unix;
	extern(C) ssize_t getdelim(char **lineptr, size_t *n, int delim, FILE *stream);
    }

    static if (Have_Unlocked_Stdio)
    {
	alias flockfile FLOCK;
	alias funlockfile FUNLOCK;
	alias putc_unlocked FPUTC;
	alias getc_unlocked FGETC;
	static if (Have_Unlocked_Wide_Stdio)
	{
	    alias putwc_unlocked FPUTWC;
	    alias getwc_unlocked FGETWC;
	}
	else
	{
	    alias fputwc FPUTWC;
	    alias fgetwc FGETWC;
	}
    }
    else
    {
	private void fnop(FILE *) { }
	alias fnop FLOCK;
	alias fnop FUNLOCK;
	alias fputc FPUTC;
	alias fgetc FGETC;
	alias fputwc FPUTWC;
	alias fgetwc FGETWC;
    }
}
else
    static assert(0);


/*********************
 * Thrown if I/O errors happen.
 */
class StdioException : Exception
{
    uint errno;			// operating system error code

    this(char[] msg)
    {
	super(msg);
    }

    this(uint errno)
    {
	version (Unix)
	{   char[80] buf = void;
	    auto s = std.string._d_gnu_cbridge_strerror(errno, buf.ptr, buf.length);
	}
	else
	{
	    auto s = std.string.strerror(errno);
	}
	super(std.string.toString(s).dup);
    }

    static void opCall(char[] msg)
    {
	throw new StdioException(msg);
    }

    static void opCall()
    {
	throw new StdioException(getErrno());
    }
}

private
void writefx(FILE* fp, TypeInfo[] arguments, va_list argptr, int newline=false)
{   int orientation;

    static if (Have_fwide)
	orientation = fwide(fp, 0);

    if (orientation <= 0)		// byte orientation or no orientation
    {
	static if (Have_Unlocked_Stdio)
	{
	    /* Do the file stream locking at the outermost level
	     * rather than character by character.
	     */
	    FLOCK(fp);
	    scope(exit) FUNLOCK(fp);
	}
	
	void putc(dchar c)
	{
	    if (c <= 0x7F)
	    {
		FPUTC(c, fp);
	    }
	    else
	    {   char[4] buf;
		char[] b;

		b = std.utf.toUTF8(buf, c);
		for (size_t i = 0; i < b.length; i++)
		    FPUTC(b[i], fp);
	    }
	}

	std.format.doFormat(&putc, arguments, argptr);
	if (newline)
	    FPUTC('\n', fp);
    }
    else if (orientation > 0)		// wide orientation
    {
	static if (Have_fwide)
	{
	    
	static if (Have_Unlocked_Wide_Stdio)
	{
	    /* Do the file stream locking at the outermost level
	     * rather than character by character.
	     */
	    FLOCK(fp);
	    scope(exit) FUNLOCK(fp);
	}

	static if (wchar_t.sizeof == 2)
	{
	    void putcw(dchar c)
	    {
		assert(isValidDchar(c));
		if (c <= 0xFFFF)
		{
		    FPUTWC(c, fp);
		}
		else
		{   wchar[2] buf;

		    buf[0] = cast(wchar) ((((c - 0x10000) >> 10) & 0x3FF) + 0xD800);
		    buf[1] = cast(wchar) (((c - 0x10000) & 0x3FF) + 0xDC00);
		    FPUTWC(buf[0], fp);
		    FPUTWC(buf[1], fp);
		}
	    }
	}
	else static if (wchar_t.sizeof == 4)
	{
	    void putcw(dchar c)
	    {
		FPUTWC(c, fp);
	    }
	}
	else
	{
	    static assert(0);
	}

	std.format.doFormat(&putcw, arguments, argptr);
	if (newline)
	    FPUTWC('\n', fp);

	}
    }
}


/***********************************
 * Arguments are formatted per the
 * $(LINK2 std_format.html#format-string, format strings)
 * and written to $(B stdout).
 */

void writef(...)
{
    writefx(stdout, _arguments, _argptr, 0);
}

/***********************************
 * Same as $(B writef), but a newline is appended
 * to the output.
 */

void writefln(...)
{
    writefx(stdout, _arguments, _argptr, 1);
}

/***********************************
 * Same as $(B writef), but output is sent to the
 * stream fp instead of $(B stdout).
 */

void fwritef(FILE* fp, ...)
{
    writefx(fp, _arguments, _argptr, 0);
}

/***********************************
 * Same as $(B writefln), but output is sent to the
 * stream fp instead of $(B stdout).
 */

void fwritefln(FILE* fp, ...)
{
    writefx(fp, _arguments, _argptr, 1);
}

/**********************************
 * Read line from stream fp.
 * Returns:
 *	null for end of file,
 *	char[] for line read from fp, including terminating '\n'
 * Params:
 *	fp = input stream
 * Throws:
 *	$(B StdioException) on error
 * Example:
 *	Reads $(B stdin) and writes it to $(B stdout).
---
import std.stdio;

int main()
{
    char[] buf;
    while ((buf = readln()) != null)
	writef("%s", buf);
    return 0;
}
---
 */
char[] readln(FILE* fp = stdin)
{
    char[] buf;
    readln(fp, buf);
    return buf;
}

/**********************************
 * Read line from stream fp and write it to buf[],
 * including terminating '\n'.
 *
 * This is often faster than readln(FILE*) because the buffer
 * is reused each call. Note that reusing the buffer means that
 * the previous contents of it need to be copied if needed.
 * Params:
 *	fp = input stream
 *	buf = buffer used to store the resulting line data. buf
 *		is resized as necessary.
 * Returns:
 *	0 for end of file, otherwise
 *	number of characters read
 * Throws:
 *	$(B StdioException) on error
 * Example:
 *	Reads $(B stdin) and writes it to $(B stdout).
---
import std.stdio;

int main()
{
    char[] buf;
    while (readln(stdin, buf))
	writef("%s", buf);
    return 0;
}
---
 */
size_t readln(FILE* fp, inout char[] buf)
{
    version (GNU)
    {
	int orientation;
	static if (Have_fwide)
	    orientation = fwide(fp, 0);

	if (orientation > 0)
	{   /* Stream is in wide characters.
	     * Read them and convert to chars.
	     */
	    static if (Have_fwide)
	    {

	    static if (Have_Unlocked_Wide_Stdio)
	    {
		FLOCK(fp);
		scope(exit) FUNLOCK(fp);
	    }

	    static if (wchar_t.sizeof == 2)
	    {
		buf.length = 0;
		int c2;
		for (int c; (c = FGETWC(fp)) != -1; )
		{
		    if ((c & ~0x7F) == 0)
		    {   buf ~= c;
			if (c == '\n')
			    break;
		    }
		    else
		    {
			if (c >= 0xD800 && c <= 0xDBFF)
			{
			    if ((c2 = FGETWC(fp)) != -1 ||
				c2 < 0xDC00 && c2 > 0xDFFF)
			    {
				StdioException("unpaired UTF-16 surrogate");
			    }
			    c = ((c - 0xD7C0) << 10) + (c2 - 0xDC00);
			}
			std.utf.encode(buf, c);
		    }
		}
		if (ferror(fp))
		    StdioException();
		return buf.length;
	    }
	    else static if (wchar_t.sizeof == 4)
	    {
		buf.length = 0;
		for (int c; (c = FGETWC(fp)) != -1; )
		{
		    if ((c & ~0x7F) == 0)
			buf ~= c;
		    else
			std.utf.encode(buf, cast(dchar)c);
		    if (c == '\n')
			break;
		}
		if (ferror(fp))
		    StdioException();
		return buf.length;
	    }
	    else
	    {
		static assert(0);
	    }

	    }
	}

	char *lineptr = null;
	size_t s;
	static if (Have_getdelim)
	{
	    size_t n = 0;
	    s = getdelim(&lineptr, &n, '\n', fp);
	    scope(exit) free(lineptr);
	    if (cast(ssize_t) s == -1)
	    {
		if (ferror(fp))
		    StdioException();
		buf.length = 0;		// end of file
		return 0;
	    }
	}
	else static if (Have_fgetln || Have_fgetline)
	{
	    static if (Have_fgetln)
		lineptr = fgetln(fp, & s);
	    else
		lineptr = fgetline(fp, & s);
	    if (lineptr is null)
	    {
		if (ferror(fp))
		    StdioException();
		buf.length = 0;		// end of file
		return 0;
	    }
	}
	else
	{
	    {
		static if (Have_Unlocked_Stdio)
		{
		    FLOCK(fp);
		    scope(exit) FUNLOCK(fp);
		}

		buf.length = 0;
		for (int c; (c = FGETC(fp)) != -1; )
		{
		    buf ~= c;
		    if (c == '\n')
			break;
		}
	    }
	    if (ferror(fp))
		StdioException();
	    return buf.length;
	}
	buf = buf.ptr[0 .. std.gc.capacity(buf.ptr)];
	if (s <= buf.length)
	{
	    buf.length = s;
	    buf[] = lineptr[0 .. s];
	}
	else
	{
	    buf = lineptr[0 .. s].dup;
	}
	return s;
    }
    else
    {
	static assert(0);
    }
}

/** ditto */
size_t readln(inout char[] buf)
{
    return readln(stdin, buf);
}

