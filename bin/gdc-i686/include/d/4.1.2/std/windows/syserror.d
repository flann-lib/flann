
// Placed in public domain
// Convert Win32 error code to string
// Based on code written by Regan Heath

module std.windows.syserror;

private import std.windows.charset;
private import std.c.windows.windows;

char[] sysErrorString(uint errcode)
{
    char[] result;
    char* buffer;
    DWORD r;

    r = FormatMessageA( 
	    FORMAT_MESSAGE_ALLOCATE_BUFFER | 
	    FORMAT_MESSAGE_FROM_SYSTEM | 
	    FORMAT_MESSAGE_IGNORE_INSERTS,
	    null,
	    errcode,
	    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), // Default language
	    cast(LPTSTR)&buffer,
	    0,
	    null);

    /* Remove \r\n from error string */
    if (r >= 2)
	r -= 2;

    /* Create 0 terminated copy on GC heap because fromMBSz()
     * may return it.
     */
    result = new char[r + 1];
    result[0 .. r] = buffer[0 .. r];
    result[r] = 0;

    result = std.windows.charset.fromMBSz(result.ptr);

    LocalFree(cast(HLOCAL)buffer);
    return result;
}
