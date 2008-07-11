
/*
 * Placed in public domain.
 * Written by Hauke Duden and Walter Bright
 */

/* This is for use with variable argument lists with extern(D) linkage. */

/* NOTE: This file has been patched from the original DMD distribution to
   work with the GDC compiler.

   Modified by David Friedman, September 2004
*/

module std.stdarg;

version (GNU) {
    // va_list might be a pointer, but assuming so is not portable.
    private import gcc.builtins;
    alias __builtin_va_list va_list;
    
    // va_arg is handled magically by the compiler
} else {
    alias void* va_list;
}

template va_arg(T)
{
    T va_arg(inout va_list _argptr)
    {
	/*
	T arg = *cast(T*)_argptr;
	_argptr = _argptr + ((T.sizeof + int.sizeof - 1) & ~(int.sizeof - 1));
	return arg;
	*/
	T t; return t;
    }
}

private import std.c.stdarg;
/* The existence of std.stdarg.va_copy isn't standard.  Prevent
   conflicts by using '__'. */
alias std.c.stdarg.va_copy __va_copy;
