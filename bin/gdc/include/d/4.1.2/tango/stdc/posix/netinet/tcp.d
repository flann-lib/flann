/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.netinet.tcp;

private import tango.stdc.posix.config;

extern (C):

//
// Required
//
/*
TCP_NODELAY
*/

version( linux )
{
    const TCP_NODELAY = 1;
}
else version( darwin )
{

}
