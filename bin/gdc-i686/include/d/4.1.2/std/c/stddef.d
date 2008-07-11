
/**
 * C's &lt;stdarg.h&gt;
 * Authors: Hauke Duden and Walter Bright, Digital Mars, www.digitalmars.com
 * License: Public Domain
 * Macros:
 *	WIKI=Phobos/StdCStdarg
 */

module std.c.stddef;

version (GNU)
{
    import gcc.config.libc;
    alias gcc.config.libc.wchar_t wchar_t;
} 
else version (Win32)
{
    alias wchar wchar_t;
}
else version (linux)
{
    alias dchar wchar_t;
}
else version (Unix)
{
    alias dchar wchar_t;
}
else
{
    static assert(0);
}
