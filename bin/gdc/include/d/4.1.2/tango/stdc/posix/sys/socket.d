/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.sys.socket;

private import tango.stdc.posix.config;
public import tango.stdc.posix.sys.types; // for ssize_t, size_t
public import tango.stdc.posix.sys.uio;   // for iovec

extern (C):

//
// Required
//
/*
socklen_t
sa_family_t

struct sockaddr
{
    sa_family_t sa_family;
    char        sa_data[];
}

struct sockaddr_storage
{
    sa_family_t ss_family;
}

struct msghdr
{
    void*         msg_name;
    socklen_t     msg_namelen;
    struct iovec* msg_iov;
    int           msg_iovlen;
    void*         msg_control;
    socklen_t     msg_controllen;
    int           msg_flags;
}

struct iovec {} // from tango.stdc.posix.sys.uio

struct cmsghdr
{
    socklen_t cmsg_len;
    int       cmsg_level;
    int       cmsg_type;
}

SCM_RIGHTS

CMSG_DATA(cmsg)
CMSG_NXTHDR(mhdr,cmsg)
CMSG_FIRSTHDR(mhdr)

struct linger
{
    int l_onoff;
    int l_linger;
}

SOCK_DGRAM
SOCK_SEQPACKET
SOCK_STREAM

SOL_SOCKET

SO_ACCEPTCONN
SO_BROADCAST
SO_DEBUG
SO_DONTROUTE
SO_ERROR
SO_KEEPALIVE
SO_LINGER
SO_OOBINLINE
SO_RCVBUF
SO_RCVLOWAT
SO_RCVTIMEO
SO_REUSEADDR
SO_SNDBUF
SO_SNDLOWAT
SO_SNDTIMEO
SO_TYPE

SOMAXCONN

MSG_CTRUNC
MSG_DONTROUTE
MSG_EOR
MSG_OOB
MSG_PEEK
MSG_TRUNC
MSG_WAITALL

AF_INET
AF_UNIX
AF_UNSPEC

SHUT_RD
SHUT_RDWR
SHUT_WR

int     accept(int, sockaddr*, socklen_t*);
int     bind(int, sockaddr*, socklen_t);
int     connect(int, sockaddr*, socklen_t);
int     getpeername(int, sockaddr*, socklen_t*);
int     getsockname(int, sockaddr*, socklen_t*);
int     getsockopt(int, int, int, void*, socklen_t*);
int     listen(int, int);
ssize_t recv(int, void*, size_t, int);
ssize_t recvfrom(int, void*, size_t, int, sockaddr*, socklen_t*);
ssize_t recvmsg(int, msghdr*, int);
ssize_t send(int, void*, size_t, int);
ssize_t sendmsg(int, msghdr*, int);
ssize_t sendto(int, void*, size_t, int, sockaddr*, socklen_t);
int     setsockopt(int, int, int, void*, socklen_t);
int     shutdown(int, int);
int     socket(int, int, int);
int     sockatmark(int);
int     socketpair(int, int, int, int[2]);
*/

version( linux )
{
    alias uint   socklen_t;
    alias ushort sa_family_t;

    struct sockaddr
    {
        sa_family_t sa_family;
        byte[14]    sa_data;
    }

    private enum : size_t
    {
        _SS_SIZE    = 128,
        _SS_PADSIZE = _SS_SIZE - (c_ulong.sizeof * 2)
    }

    struct sockaddr_storage
    {
        sa_family_t ss_family;
        c_ulong     __ss_align;
        byte[_SS_PADSIZE] __ss_padding;
    }

    struct msghdr
    {
        void*         msg_name;
        socklen_t     msg_namelen;
        iovec*        msg_iov;
        size_t        msg_iovlen;
        void*         msg_control;
        size_t        msg_controllen;
        int           msg_flags;
    }

    struct cmsghdr
    {
        size_t cmsg_len;
        int    cmsg_level;
        int    cmsg_type;
        static if( false /* (!is( __STRICT_ANSI__ ) && __GNUC__ >= 2) || __STDC_VERSION__ >= 199901L */ )
        {
            ubyte[1] __cmsg_data;
        }
    }

    enum : uint
    {
        SCM_RIGHTS = 0x01
    }

    static if( false /* (!is( __STRICT_ANSI__ ) && __GNUC__ >= 2) || __STDC_VERSION__ >= 199901L */ )
    {
        extern (D) ubyte[1] CMSG_DATA( cmsghdr* cmsg ) { return cmsg.__cmsg_data; }
    }
    else
    {
        extern (D) ubyte*   CMSG_DATA( cmsghdr* cmsg ) { return cast(ubyte*)( cmsg + 1 ); }
    }

    private cmsghdr* __cmsg_nxthdr(msghdr*, cmsghdr*);
    alias            __cmsg_nxthdr CMSG_NXTHDR;

    extern (D) size_t CMSG_FIRSTHDR( msghdr* mhdr )
    {
        return cast(size_t)( mhdr.msg_controllen >= cmsghdr.sizeof
                             ? cast(cmsghdr*) mhdr.msg_control
                             : cast(cmsghdr*) null );
    }

    struct linger
    {
        int l_onoff;
        int l_linger;
    }

    enum
    {
        SOCK_DGRAM      = 2,
        SOCK_SEQPACKET  = 5,
        SOCK_STREAM     = 1
    }

    enum
    {
        SOL_SOCKET      = 1
    }

    enum
    {
        SO_ACCEPTCONN   = 30,
        SO_BROADCAST    = 6,
        SO_DEBUG        = 1,
        SO_DONTROUTE    = 5,
        SO_ERROR        = 4,
        SO_KEEPALIVE    = 9,
        SO_LINGER       = 13,
        SO_OOBINLINE    = 10,
        SO_RCVBUF       = 8,
        SO_RCVLOWAT     = 18,
        SO_RCVTIMEO     = 20,
        SO_REUSEADDR    = 2,
        SO_SNDBUF       = 7,
        SO_SNDLOWAT     = 19,
        SO_SNDTIMEO     = 21,
        SO_TYPE         = 3
    }

    enum
    {
        SOMAXCONN       = 128
    }

    enum : uint
    {
        MSG_CTRUNC      = 0x08,
        MSG_DONTROUTE   = 0x04,
        MSG_EOR         = 0x80,
        MSG_OOB         = 0x01,
        MSG_PEEK        = 0x02,
        MSG_TRUNC       = 0x20,
        MSG_WAITALL     = 0x100
    }

    enum
    {
        AF_INET         = 2,
        AF_UNIX         = 1,
        AF_UNSPEC       = 0
    }

    enum
    {
        SHUT_RD,
        SHUT_WR,
        SHUT_RDWR
    }

    int     accept(int, sockaddr*, socklen_t*);
    int     bind(int, sockaddr*, socklen_t);
    int     connect(int, sockaddr*, socklen_t);
    int     getpeername(int, sockaddr*, socklen_t*);
    int     getsockname(int, sockaddr*, socklen_t*);
    int     getsockopt(int, int, int, void*, socklen_t*);
    int     listen(int, int);
    ssize_t recv(int, void*, size_t, int);
    ssize_t recvfrom(int, void*, size_t, int, sockaddr*, socklen_t*);
    ssize_t recvmsg(int, msghdr*, int);
    ssize_t send(int, void*, size_t, int);
    ssize_t sendmsg(int, msghdr*, int);
    ssize_t sendto(int, void*, size_t, int, sockaddr*, socklen_t);
    int     setsockopt(int, int, int, void*, socklen_t);
    int     shutdown(int, int);
    int     socket(int, int, int);
    int     sockatmark(int);
    int     socketpair(int, int, int, int[2]);
}
else version( darwin )
{
    alias uint   socklen_t;
}

//
// IPV6 (IP6)
//
/*
AF_INET6
*/

version( linux )
{
    enum
    {
        AF_INET6    = 10
    }
}

//
// Raw Sockets (RS)
//
/*
SOCK_RAW
*/

version( linux )
{
    enum
    {
        SOCK_RAW    = 3
    }
}
