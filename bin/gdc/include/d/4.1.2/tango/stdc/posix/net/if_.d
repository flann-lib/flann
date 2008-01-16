/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.net.if_;

private import tango.stdc.posix.config;

extern (C):

//
// Required
//
/*
struct if_nameindex // renamed to if_nameindex_t
{
    uint    if_index;
    char*   if_name;
}

IF_NAMESIZE

uint            if_nametoindex(char*);
char*           if_indextoname(uint, char*);
if_nameindex_t* if_nameindex();
void            if_freenameindex(if_nameindex_t*);
*/

version( linux )
{
    struct if_nameindex_t
    {
        uint    if_index;
        char*   if_name;
    }

    const IF_NAMESIZE = 16;

    uint            if_nametoindex(char*);
    char*           if_indextoname(uint, char*);
    if_nameindex_t* if_nameindex();
    void            if_freenameindex(if_nameindex_t*);
}
else version( darwin )
{

}
