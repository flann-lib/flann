/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.sys.uio;

private import tango.stdc.posix.config;
public import tango.stdc.posix.sys.types; // for ssize_t, size_t

extern (C):

//
// Required
//
/*
struct iovec
{
    void*  iov_base;
    size_t iov_len;
}

ssize_t // from tango.stdc.posix.sys.types
size_t  // from tango.stdc.posix.sys.types

ssize_t readv(int, iovec*, int);
ssize_t writev(int, iovec*, int);
*/

version( linux )
{
    struct iovec
    {
        void*  iov_base;
        size_t iov_len;
    }

    ssize_t readv(int, iovec*, int);
    ssize_t writev(int, iovec*, int);
}
