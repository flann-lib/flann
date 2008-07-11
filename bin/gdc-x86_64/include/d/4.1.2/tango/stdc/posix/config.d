/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.config;

public import tango.stdc.config;

extern (C):

version( linux )
{
    const bool  __USE_FILE_OFFSET64 = false;
    const bool  __USE_LARGEFILE64   = false;
    const bool  __REDIRECT          = false;
}
