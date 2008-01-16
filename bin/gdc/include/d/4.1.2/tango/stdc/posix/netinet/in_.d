/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.netinet.in_;

private import tango.stdc.posix.config;
public import tango.stdc.inttypes : uint32_t, uint16_t;
public import tango.stdc.posix.arpa.inet;

extern (C):

//
// Required
//
/*
NOTE: The following must must be defined in tango.stdc.posix.arpa.inet to break
      a circular import: in_port_t, in_addr_t, struct in_addr, INET_ADDRSTRLEN.

in_port_t
in_addr_t

sa_family_t
uint8_t  // from tango.stdc.inttypes
uint32_t // from tango.stdc.inttypes

struct in_addr
{
    in_addr_t   s_addr;
}

struct sockaddr_in
{
    sa_family_t sin_family;
    in_port_t   sin_port;
    in_addr     sin_addr;
}

IPPROTO_IP
IPPROTO_ICMP
IPPROTO_TCP
IPPROTO_UDP

INADDR_ANY
INADDR_BROADCAST

INET_ADDRSTRLEN

htonl() // from tango.stdc.posix.arpa.inet
htons() // from tango.stdc.posix.arpa.inet
ntohl() // from tango.stdc.posix.arpa.inet
ntohs() // from tango.stdc.posix.arpa.inet
*/

version( linux )
{
    alias ushort sa_family_t;

    private const __SOCK_SIZE__ = 16;

    struct sockaddr_in
    {
        sa_family_t sin_family;
        in_port_t   sin_port;
        in_addr     sin_addr;

        /* Pad to size of `struct sockaddr'. */
        ubyte[__SOCK_SIZE__ - sa_family_t.sizeof -
              in_port_t.sizeof - in_addr.sizeof] __pad;
    }

    enum
    {
        IPPROTO_IP   = 0,
        IPPROTO_ICMP = 1,
        IPPROTO_TCP  = 6,
        IPPROTO_UDP  = 17
    }

    const c_ulong INADDR_ANY        = 0x00000000;
    const c_ulong INADDR_BROADCAST  = 0xffffffff;
}
else version( darwin )
{

}


//
// IPV6 (IP6)
//
/*
NOTE: The following must must be defined in tango.stdc.posix.arpa.inet to break
      a circular import: INET6_ADDRSTRLEN.

uint8_t[16] s6_addr;

struct sockaddr_in6
{
    sa_family_t sin6_family;
    in_port_t   sin6_port;
    uint32_t    sin6_flowinfo;
    in6_addr    sin6_addr;
    uint32_t    sin6_scope_id;
}

extern in6_addr in6addr_any;
extern in6_addr in6addr_loopback;

struct ipv6_mreq
{
    in6_addr    ipv6mr_multiaddr;
    uint        ipv6mr_interface;
}

IPPROTO_IPV6

INET6_ADDRSTRLEN

IPV6_JOIN_GROUP
IPV6_LEAVE_GROUP
IPV6_MULTICAST_HOPS
IPV6_MULTICAST_IF
IPV6_MULTICAST_LOOP
IPV6_UNICAST_HOPS
IPV6_V6ONLY

// macros
int IN6_IS_ADDR_UNSPECIFIED(in6_addr*)
int IN6_IS_ADDR_LOOPBACK(in6_addr*)
int IN6_IS_ADDR_MULTICAST(in6_addr*)
int IN6_IS_ADDR_LINKLOCAL(in6_addr*)
int IN6_IS_ADDR_SITELOCAL(in6_addr*)
int IN6_IS_ADDR_V4MAPPED(in6_addr*)
int IN6_IS_ADDR_V4COMPAT(in6_addr*)
int IN6_IS_ADDR_MC_NODELOCAL(in6_addr*)
int IN6_IS_ADDR_MC_LINKLOCAL(in6_addr*)
int IN6_IS_ADDR_MC_SITELOCAL(in6_addr*)
int IN6_IS_ADDR_MC_ORGLOCAL(in6_addr*)
int IN6_IS_ADDR_MC_GLOBAL(in6_adddr*)
*/


//
// Raw Sockets (RS)
//
/*
IPPROTO_RAW
*/
