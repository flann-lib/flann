
/* Written by Walter Bright.
 * www.digitalmars.com
 * Placed into public domain.
 * Linux(R) is the registered trademark of Linus Torvalds in the U.S. and other
 * countries.
 */

/* These are all the globals defined by the linux C runtime library.
 * Put them separate so they'll be externed - do not link in linuxextern.o
 */

module std.c.linux.linuxextern;
private import std.stdint;

extern (C)
{
    void* __libc_stack_end;
    int __data_start;
    int _end;
    Clong_t timezone;

    void *_deh_beg;
    void *_deh_end;
}

