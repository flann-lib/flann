/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.utime;

private import tango.stdc.posix.config;
public import tango.stdc.posix.sys.types; // for time_t

extern (C):

//
// Required
//
/*
struct utimbuf
{
    time_t  actime;
    time_t  modtime;
}

int utime(char*, utimbuf*);
*/

version( linux )
{
    struct utimbuf
    {
        time_t  actime;
        time_t  modtime;
    }

    int utime(char*, utimbuf*);
}
else version( darwin )
{
    struct utimbuf
    {
        time_t  actime;
        time_t  modtime;
    }

    int utime(char*, utimbuf*);
}
