/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.arpa.inet;

private import tango.stdc.posix.config;
public import tango.stdc.inttypes : uint32_t, uint16_t;
public import tango.stdc.posix.sys.socket : socklen_t;

extern (C):

//
// Required
//
/*
in_port_t // from tango.stdc.posix.netinet.in_
in_addr_t // from tango.stdc.posix.netinet.in_

struct in_addr  // from tango.stdc.posix.netinet.in_
INET_ADDRSTRLEN // from tango.stdc.posix.netinet.in_

uint32_t // from tango.stdc.inttypes
uint16_t // from tango.stdc.inttypes

uint32_t htonl(uint32_t);
uint16_t htons(uint16_t);
uint32_t ntohl(uint32_t);
uint16_t ntohs(uint16_t);

in_addr_t inet_addr(char*);
char*     inet_ntoa(in_addr);
char*     inet_ntop(int, void*, char*, socklen_t);
int       inet_pton(int, char*, void*);
*/

version( linux )
{
    alias uint16_t in_port_t;
    alias uint32_t in_addr_t;

    struct in_addr
    {
        in_addr_t s_addr;;
    }

    const INET_ADDRSTRLEN = 16;

    uint32_t htonl(uint32_t);
    uint16_t htons(uint16_t);
    uint32_t ntohl(uint32_t);
    uint16_t ntohs(uint16_t);

    in_addr_t inet_addr(char*);
    char*     inet_ntoa(in_addr);
    char*     inet_ntop(int, void*, char*, socklen_t);
    int       inet_pton(int, char*, void*);
}
else version( darwin )
{

}


//
// IPV6 (IP6)
//
/*
INET6_ADDRSTRLEN // from tango.stdc.posix.netinet.in_
*/

version( linux )
{
    const INET6_ADDRSTRLEN = 46;
}
else version( darwin )
{

}
