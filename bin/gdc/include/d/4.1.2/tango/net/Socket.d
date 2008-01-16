/*
        Copyright (C) 2004 Christopher E. Miller

        This software is provided 'as-is', without any express or implied
        warranty.  In no event will the authors be held liable for any damages
        arising from the use of this software.

        Permission is granted to anyone to use this software for any purpose,
        including commercial applications, and to alter it and redistribute it
        freely, subject to the following restrictions:

        1. The origin of this software must not be misrepresented; you must not
           claim that you wrote the original software. If you use this software
           in a product, an acknowledgment in the product documentation would be
           appreciated but is not required.

        2. Altered source versions must be plainly marked as such, and must not be
           misrepresented as being the original software.

        3. This notice may not be removed or altered from any source distribution.

*/

/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004

        author:         Christopher Miller
                        Kris Bell
                        Anders F Bjorklund (Darwin patches)


        The original code has been modified in several ways:

        1) It has been altered to fit within the Tango environment, meaning
           that certain original classes have been reorganized, and/or have
           subclassed Tango base-classes. For example, the original Socket
           class has been wrapped with three distinct subclasses, and now
           derives from class tango.io.Resource.

        2) All exception instances now subclass the Tango IOException.

        3) Construction of new Socket instances via accept() is now
           overloadable.

        4) Constants and enums have been moved within a class boundary to
           ensure explicit namespace usage.

        5) changed Socket.select() to loop if it was interrupted.


        All changes within the main body of code all marked with "Tango:"

        For a good tutorial on socket-programming I highly recommend going
        here: http://www.ecst.csuchico.edu/~beej/guide/net/

*******************************************************************************/

module tango.net.Socket;

private import  tango.time.Time;

private import  tango.sys.Common;

private import  tango.core.Exception;


/*******************************************************************************


*******************************************************************************/

version=Tango;
version (Tango)
{
        private char[] toString (char[] tmp, int i)
        {
                int j = tmp.length;
                do {
                   tmp[--j] = i % 10 + '0';
                   } while (i /= 10);

                return tmp [j .. $];
        }
}

version (linux)
         version = BsdSockets;

version (darwin)
         version = BsdSockets;

version (Posix)
         version = BsdSockets;


/*******************************************************************************


*******************************************************************************/

version (Win32)
        {
        pragma(lib, "ws2_32.lib");

        private typedef int socket_t = ~0;

        private const int IOCPARM_MASK =  0x7f;
        private const int IOC_IN =        cast(int)0x80000000;
        private const int FIONBIO =       cast(int) (IOC_IN | ((int.sizeof & IOCPARM_MASK) << 16) | (102 << 8) | 126);

        private const int WSADESCRIPTION_LEN = 256;
        private const int WSASYS_STATUS_LEN = 128;
        private const int WSAEWOULDBLOCK =  10035;
        private const int WSAEINTR =        10004;


        struct WSADATA
        {
                        WORD wVersion;
                        WORD wHighVersion;
                        char szDescription[WSADESCRIPTION_LEN+1];
                        char szSystemStatus[WSASYS_STATUS_LEN+1];
                        ushort iMaxSockets;
                        ushort iMaxUdpDg;
                        char* lpVendorInfo;
        }
        alias WSADATA* LPWSADATA;

        extern  (Windows)
                {
                int WSAStartup(WORD wVersionRequested, LPWSADATA lpWSAData);
                int WSACleanup();
                socket_t socket(int af, int type, int protocol);
                int ioctlsocket(socket_t s, int cmd, uint* argp);
                uint inet_addr(char* cp);
                int bind(socket_t s, sockaddr* name, int namelen);
                int connect(socket_t s, sockaddr* name, int namelen);
                int listen(socket_t s, int backlog);
                socket_t accept(socket_t s, sockaddr* addr, int* addrlen);
                int closesocket(socket_t s);
                int shutdown(socket_t s, int how);
                int getpeername(socket_t s, sockaddr* name, int* namelen);
                int getsockname(socket_t s, sockaddr* name, int* namelen);
                int send(socket_t s, void* buf, int len, int flags);
                int sendto(socket_t s, void* buf, int len, int flags, sockaddr* to, int tolen);
                int recv(socket_t s, void* buf, int len, int flags);
                int recvfrom(socket_t s, void* buf, int len, int flags, sockaddr* from, int* fromlen);
                int select(int nfds, fd_set* readfds, fd_set* writefds, fd_set* errorfds, timeval* timeout);
                //int __WSAFDIsSet(socket_t s, fd_set* fds);
                int getsockopt(socket_t s, int level, int optname, void* optval, int* optlen);
                int setsockopt(socket_t s, int level, int optname, void* optval, int optlen);
                int gethostname(void* namebuffer, int buflen);
                char* inet_ntoa(uint ina);
                hostent* gethostbyname(char* name);
                hostent* gethostbyaddr(void* addr, int len, int type);
                int WSAGetLastError();
                }

        static this()
        {
                WSADATA wd;
                if (WSAStartup (0x0101, &wd))
                    throw new SocketException("Unable to initialize socket library");
        }


        static ~this()
        {
                WSACleanup();
        }

        }

version (BsdSockets)
        {
        private import tango.stdc.errno;

        private typedef int socket_t = -1;

        private const int F_GETFL       = 3;
        private const int F_SETFL       = 4;
        version (darwin)
                 private const int O_NONBLOCK = 0x0004;
           else
                 private const int O_NONBLOCK = 04000;  // OCTAL! Thx to volcore

        extern  (C)
                {
                socket_t socket(int af, int type, int protocol);
                int fcntl(socket_t s, int f, ...);
                uint inet_addr(char* cp);
                int bind(socket_t s, sockaddr* name, int namelen);
                int connect(socket_t s, sockaddr* name, int namelen);
                int listen(socket_t s, int backlog);
                socket_t accept(socket_t s, sockaddr* addr, int* addrlen);
                int close(socket_t s);
                int shutdown(socket_t s, int how);
                int getpeername(socket_t s, sockaddr* name, int* namelen);
                int getsockname(socket_t s, sockaddr* name, int* namelen);
                int send(socket_t s, void* buf, int len, int flags);
                int sendto(socket_t s, void* buf, int len, int flags, sockaddr* to, int tolen);
                int recv(socket_t s, void* buf, int len, int flags);
                int recvfrom(socket_t s, void* buf, int len, int flags, sockaddr* from, int* fromlen);
                int select(int nfds, fd_set* readfds, fd_set* writefds, fd_set* errorfds, timeval* timeout);
                int getsockopt(socket_t s, int level, int optname, void* optval, int* optlen);
                int setsockopt(socket_t s, int level, int optname, void* optval, int optlen);
                int gethostname(void* namebuffer, int buflen);
                char* inet_ntoa(uint ina);
                hostent* gethostbyname(char* name);
                hostent* gethostbyaddr(void* addr, int len, int type);
                }
        }


/*******************************************************************************


*******************************************************************************/

private const socket_t INVALID_SOCKET = socket_t.init;
private const int SOCKET_ERROR = -1;



/*******************************************************************************

        Internal structs:

*******************************************************************************/

struct timeval
{
        int tv_sec; //seconds
        int tv_usec; //microseconds
}


//transparent
struct fd_set
{
}


struct sockaddr
{
        ushort sa_family;
        char[14] sa_data = [0];
}


struct hostent
{
        char* h_name;
        char** h_aliases;
        version(Win32)
        {
                short h_addrtype;
                short h_length;
        }
        else version(BsdSockets)
        {
                int h_addrtype;
                int h_length;
        }
        char** h_addr_list;


        char* h_addr()
        {
                return h_addr_list[0];
        }
}


/*******************************************************************************

        conversions for network byte-order

*******************************************************************************/

version(BigEndian)
{
        ushort htons(ushort x)
        {
                return x;
        }


        uint htonl(uint x)
        {
                return x;
        }
}
else version(LittleEndian)
{
        import tango.core.BitManip;


        ushort htons(ushort x)
        {
                return cast(ushort) ((x >> 8) | (x << 8));
        }


        uint htonl(uint x)
        {
                return bswap(x);
        }
}
else
{
        static assert(0);
}


ushort ntohs(ushort x)
{
        return htons(x);
}


uint ntohl(uint x)
{
        return htonl(x);
}


/*******************************************************************************


*******************************************************************************/

private extern (C) int strlen(char*);

private static char[] toString(char* s)
{
        return s ? s[0 .. strlen(s)] : cast(char[])null;
}

private static char* convert2C (char[] input, char[] output)
{
        output [0 .. input.length] = input;
        output [input.length] = 0;
        return output.ptr;
}


/*******************************************************************************

        Public interface ...

*******************************************************************************/

public:


/*******************************************************************************


*******************************************************************************/

static int lastError ()
{
        version (Win32)
                {
                return WSAGetLastError();
                }
        version (Posix)
                {
                return errno;
                }
}


/***********************************************************************


***********************************************************************/

version (Win32)
{
        /***************************************************************


        ***************************************************************/

        enum SocketOption: int
        {
                //consistent
                SO_DEBUG =         0x1,

                //possibly Winsock-only values
                SO_BROADCAST =  0x20,
                SO_REUSEADDR =  0x4,
                SO_LINGER =     0x80,
                SO_DONTLINGER = ~(SO_LINGER),
                SO_OOBINLINE =  0x100,
                SO_SNDBUF =     0x1001,
                SO_RCVBUF =     0x1002,
                SO_ERROR =      0x1007,

                SO_ACCEPTCONN =    0x2, // ?
                SO_KEEPALIVE =     0x8, // ?
                SO_DONTROUTE =     0x10, // ?
                SO_TYPE =          0x1008, // ?

                // OptionLevel.IP settings
                IP_MULTICAST_TTL = 10,
                IP_MULTICAST_LOOP = 11,
                IP_ADD_MEMBERSHIP = 12,
                IP_DROP_MEMBERSHIP = 13,

                // OptionLevel.TCP settings
                TCP_NODELAY = 0x0001,
        }

        /***************************************************************


        ***************************************************************/

        union linger
        {
                struct {
                       ushort l_onoff;          // option on/off
                       ushort l_linger;         // linger time
                       };
                ushort[2]       array;          // combined
        }

        /***************************************************************


        ***************************************************************/

        enum SocketOptionLevel
        {
                SOCKET =  0xFFFF,
                IP =      0,
                TCP =     6,
                UDP =     17,
        }
}
else version (darwin)
{
        enum SocketOption: int
        {
                SO_DEBUG        = 0x0001,		/* turn on debugging info recording */
                SO_BROADCAST    = 0x0020,		/* permit sending of broadcast msgs */
                SO_REUSEADDR    = 0x0004,		/* allow local address reuse */
                SO_LINGER       = 0x0080,		/* linger on close if data present */
                SO_DONTLINGER   = ~(SO_LINGER),
                SO_OOBINLINE    = 0x0100,		/* leave received OOB data in line */
                SO_ACCEPTCONN   = 0x0002,		/* socket has had listen() */
                SO_KEEPALIVE    = 0x0008,		/* keep connections alive */
                SO_DONTROUTE    = 0x0010,		/* just use interface addresses */
                SO_TYPE         = 0x1008,               /* get socket type */

                /*
                 * Additional options, not kept in so_options.
                 */
                SO_SNDBUF       = 0x1001,		/* send buffer size */
                SO_RCVBUF       = 0x1002,		/* receive buffer size */
                SO_ERROR        = 0x1007,		/* get error status and clear */

                // OptionLevel.IP settings
                IP_MULTICAST_TTL = 10,
                IP_MULTICAST_LOOP = 11,
                IP_ADD_MEMBERSHIP = 12,
                IP_DROP_MEMBERSHIP = 13,

                // OptionLevel.TCP settings
                TCP_NODELAY = 0x0001,
        }

        /***************************************************************


        ***************************************************************/

        union linger
        {
                struct {
                       int l_onoff;             // option on/off
                       int l_linger;            // linger time
                       };
                int[2]          array;          // combined
        }

        /***************************************************************

                Question: are these correct for Darwin?

        ***************************************************************/

        enum SocketOptionLevel
        {
                SOCKET =  1,  // correct for linux on x86
                IP =      0,  // appears to be correct
                TCP =     6,  // appears to be correct
                UDP =     17, // appears to be correct
        }
}
else version (linux)
{
        /***************************************************************

                these appear to be compatible with x86 platforms,
                but not others!

        ***************************************************************/

        enum SocketOption: int
        {
                //consistent
                SO_DEBUG        = 1,
                SO_BROADCAST    = 6,
                SO_REUSEADDR    = 2,
                SO_LINGER       = 13,
                SO_DONTLINGER   = ~(SO_LINGER),
                SO_OOBINLINE    = 10,
                SO_SNDBUF       = 7,
                SO_RCVBUF       = 8,
                SO_ERROR        = 4,

                SO_ACCEPTCONN   = 30,
                SO_KEEPALIVE    = 9,
                SO_DONTROUTE    = 5,
                SO_TYPE         = 3,

                // OptionLevel.IP settings
                IP_MULTICAST_TTL = 33,
                IP_MULTICAST_LOOP = 34,
                IP_ADD_MEMBERSHIP = 35,
                IP_DROP_MEMBERSHIP = 36,

                // OptionLevel.TCP settings
                TCP_NODELAY = 0x0001,
        }

        /***************************************************************


        ***************************************************************/

        union linger
        {
                struct {
                       int l_onoff;             // option on/off
                       int l_linger;            // linger time
                       };
                int[2]          array;          // combined
        }

        /***************************************************************


        ***************************************************************/

        enum SocketOptionLevel
        {
                SOCKET =  1,  // correct for linux on x86
                IP =      0,  // appears to be correct
                TCP =     6,  // appears to be correct
                UDP =     17, // appears to be correct
        }
} // end versioning

/***********************************************************************


***********************************************************************/

enum SocketShutdown: int
{
        RECEIVE =  0,
        SEND =     1,
        BOTH =     2,
}

/***********************************************************************


***********************************************************************/

enum SocketFlags: int
{
        NONE =           0,
        OOB =            0x1, //out of band
        PEEK =           0x02, //only for receiving
        DONTROUTE =      0x04, //only for sending
}

/***********************************************************************

         Communication semantics

***********************************************************************/

enum SocketType: int
{
        STREAM =     1,       /// sequenced, reliable, two-way communication-based byte streams
        DGRAM =      2,        /// connectionless, unreliable datagrams with a fixed maximum length; data may be lost or arrive out of order
        RAW =        3,          /// raw protocol access
        RDM =        4,          /// reliably-delivered message datagrams
        SEQPACKET =  5,    /// sequenced, reliable, two-way connection-based datagrams with a fixed maximum length
}


/***********************************************************************

        Protocol

***********************************************************************/

enum ProtocolType: int
{
        IP =    0,     /// internet protocol version 4
        ICMP =  1,   /// internet control message protocol
        IGMP =  2,   /// internet group management protocol
        GGP =   3,    /// gateway to gateway protocol
        TCP =   6,    /// transmission control protocol
        PUP =   12,    /// PARC universal packet protocol
        UDP =   17,    /// user datagram protocol
        IDP =   22,    /// Xerox NS protocol
}


/***********************************************************************


***********************************************************************/

version(Win32)
{
        enum AddressFamily: int
        {
                UNSPEC =     0,
                UNIX =       1,
                INET =       2,
                IPX =        6,
                APPLETALK =  16,
                //INET6 =      ? // Need Windows XP ?
        }
}
else version(BsdSockets)
{
        version (darwin)
        {
                enum AddressFamily: int
                {
                        UNSPEC =     0,
                        UNIX =       1,
                        INET =       2,
                        IPX =        23,
                        APPLETALK =  16,
                        //INET6 =      10,
                }
        }
        else version (linux)
        {
                enum AddressFamily: int
                {
                        UNSPEC =     0,
                        UNIX =       1,
                        INET =       2,
                        IPX =        4,
                        APPLETALK =  5,
                        //INET6 =      10,
                }
        } // end version
}



/*******************************************************************************

*******************************************************************************/

class Socket
{
        socket_t        sock;
        SocketType      type;
        AddressFamily   family;
        ProtocolType    protocol;

        version(Win32)
                private bool _blocking = false;

        // For use with accept().
        package this()
        {
        }


        /**
         * Describe a socket flavor. If a single protocol type exists to support
         * this socket type within the address family, the ProtocolType may be
         * omitted.
         */
        this(AddressFamily family, SocketType type, ProtocolType protocol, bool create=true)
        {
                this.type = type;
                this.family = family;
                this.protocol = protocol;
                if (create)
                    initialize ();
        }


        /**
         * Create or assign a socket
         */
        private void initialize (socket_t sock = sock.init)
        {
                if (this.sock)
                    this.detach;

                if (sock is sock.init)
                   {
                   sock = cast(socket_t) socket(family, type, protocol);
                   if (sock is sock.init)
                       exception ("Unable to create socket: ");
                   }

                this.sock = sock;
        }

        /***********************************************************************

                Return the underlying OS handle of this Conduit

        ***********************************************************************/

        socket_t fileHandle ()
        {
                return sock;
        }

        /***********************************************************************

                Is this socket still alive? A closed socket is considered to
                be dead, but a shutdown socket is still alive.

        ***********************************************************************/

        bool isAlive()
        {
                int type, typesize = type.sizeof;
                return getsockopt (sock, SocketOptionLevel.SOCKET,
                                   SocketOption.SO_TYPE, cast(char*) &type,
                                   &typesize) != SOCKET_ERROR;
        }


        /***********************************************************************


        ***********************************************************************/

        override char[] toString()
        {
                return "Socket";
        }


        /***********************************************************************

                getter

        ***********************************************************************/

        bool blocking()
        {
                version(Win32)
                {
                        return _blocking;
                }
                else version(BsdSockets)
                {
                        return !(fcntl(sock, F_GETFL, 0) & O_NONBLOCK);
                }
        }


        /***********************************************************************

                setter

        ***********************************************************************/

        void blocking(bool byes)
        {
                version(Win32)
                {
                        uint num = !byes;
                        if(SOCKET_ERROR == ioctlsocket(sock, FIONBIO, &num))
                                goto err;
                        _blocking = byes;
                }
                else version(BsdSockets)
                {
                        int x = fcntl(sock, F_GETFL, 0);
                        if(byes)
                                x &= ~O_NONBLOCK;
                        else
                                x |= O_NONBLOCK;
                        if(SOCKET_ERROR == fcntl(sock, F_SETFL, x))
                                goto err;
                }
                return; //success

                err:
                exception("Unable to set socket blocking: ");
        }


        /***********************************************************************


        ***********************************************************************/

        AddressFamily addressFamily()
        {
                return family;
        }


        /***********************************************************************


        ***********************************************************************/

        Socket bind(Address addr)
        {
                if(SOCKET_ERROR == .bind (sock, addr.name(), addr.nameLen()))
                   exception ("Unable to bind socket: ");
                return this;
        }


        /***********************************************************************


        ***********************************************************************/

        Socket connect(Address to)
        {
                if(SOCKET_ERROR == .connect (sock, to.name(), to.nameLen()))
                {
                        if(!blocking)
                        {
                                version(Win32)
                                {
                                        if(WSAEWOULDBLOCK == WSAGetLastError())
                                                return this;
                                }
                                else version (Posix)
                                {
                                        if(EINPROGRESS == errno)
                                                return this;
                                }
                                else
                                {
                                        static assert(0);
                                }
                        }
                        exception ("Unable to connect socket: ");
                }
                return this;
        }


        /***********************************************************************

                need to bind() first

        ***********************************************************************/

        Socket listen(int backlog)
        {
                if(SOCKET_ERROR == .listen (sock, backlog))
                   exception ("Unable to listen on socket: ");
                return this;
        }

        /**
         * Accept an incoming connection. If the socket is blocking, accept
         * waits for a connection request. Throws SocketAcceptException if unable
         * to accept. See accepting for use with derived classes.
         */
        Socket accept ()
        {
                return accept (new Socket);
        }

        Socket accept (Socket target)
        {
                auto newsock = cast(socket_t).accept(sock, null, null); // DMD 0.101 error: found '(' when expecting ';' following 'statement
                if (socket_t.init == newsock)
                   throw new SocketAcceptException("Unable to accept socket connection: " ~ SysError.lookup(lastError));

                target.initialize (newsock);
                version(Win32)
                        target._blocking = _blocking;  //inherits blocking mode

                target.protocol = protocol;            //same protocol
                target.family = family;                //same family
                target.type = type;                    //same type

                return target;                         //return configured target
        }

        /***********************************************************************

                The shutdown function shuts down the connection of the socket.
                Depending on the argument value, it will:

                    -   stop receiving data for this socket. If further data
                        arrives, it is rejected.

                    -   stop trying to transmit data from this socket. Also
                        discards any data waiting to be sent. Stop looking for
                        acknowledgement of data already sent; don't retransmit
                        if any data is lost.

        ***********************************************************************/

        Socket shutdown(SocketShutdown how)
        {
                .shutdown (sock, how);
                return this;
        }


        /***********************************************************************

                Tango: added

        ***********************************************************************/

        Socket setLingerPeriod (int period)
        {
                linger l;

                l.l_onoff = 1;                          //option on/off
                l.l_linger = cast(ushort) period;       //linger time

                return setOption (SocketOptionLevel.SOCKET, SocketOption.SO_LINGER, l.array);
        }


        /***********************************************************************


                Tango: added

        ***********************************************************************/

        Socket setAddressReuse (bool enabled)
        {
                int[1] x = enabled;
                return setOption (SocketOptionLevel.SOCKET, SocketOption.SO_REUSEADDR, x);
        }


        /***********************************************************************


                Tango: added

        ***********************************************************************/

        Socket setNoDelay (bool enabled)
        {
                int[1] x = enabled;
                return setOption (SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, x);
        }


        /***********************************************************************

                Helper function to handle the adding and dropping of group
                membership.

                Tango: Added

        ***********************************************************************/

        void joinGroup (IPv4Address address, bool onOff)
        {
                assert (address, "Socket.joinGroup :: invalid null address");

                struct ip_mreq
                {
                uint  imr_multiaddr;  /* IP multicast address of group */
                uint  imr_interface;  /* local IP address of interface */
                };

                ip_mreq mrq;

                auto option = (onOff) ? SocketOption.IP_ADD_MEMBERSHIP : SocketOption.IP_DROP_MEMBERSHIP;
                mrq.imr_interface = 0;
                mrq.imr_multiaddr = address.sin.sin_addr;

                if (.setsockopt(sock, SocketOptionLevel.IP, option, &mrq, mrq.sizeof) == SOCKET_ERROR)
                    exception ("Unable to perform multicast join: ");
        }


        /***********************************************************************

                calling shutdown() before this is recommended for connection-
                oriented sockets

        ***********************************************************************/

        void detach ()
        {
                if (sock != sock.init)
                   {
                   version (TraceLinux)
                            printf ("closing socket handle ...\n");

                   version(Win32)
                           .closesocket (sock);
                   else
                   version(BsdSockets)
                           .close (sock);

                   version (TraceLinux)
                            printf ("socket handle closed\n");

                   sock = sock.init;
                   }
        }

        /***********************************************************************


        ***********************************************************************/

        Address newFamilyObject ()
        {
                Address result;
                switch(family)
                {
                        case AddressFamily.INET:
                                result = new IPv4Address;
                                break;

                        default:
                                result = new UnknownAddress;
                }
                return result;
        }


        /***********************************************************************

                Tango: added this to return the hostname

        ***********************************************************************/

        static char[] hostName ()
        {
                char[64] name;

                if(SOCKET_ERROR == .gethostname (name.ptr, name.length))
                   exception ("Unable to obtain host name: ");
                return name [0 .. strlen(name.ptr)].dup;
        }


        /***********************************************************************

                Tango: added this to return the default host address (IPv4)

        ***********************************************************************/

        static uint hostAddress ()
        {
                NetHost ih = new NetHost;

                char[] hostname = hostName();
                ih.getHostByName (hostname);
                assert (ih.addrList.length);
                return ih.addrList[0];
        }


        /***********************************************************************


        ***********************************************************************/

        Address remoteAddress ()
        {
                Address addr = newFamilyObject ();
                int nameLen = addr.nameLen ();
                if(SOCKET_ERROR == .getpeername (sock, addr.name(), &nameLen))
                   exception ("Unable to obtain remote socket address: ");
                assert (addr.addressFamily() == family);
                return addr;
        }


        /***********************************************************************


        ***********************************************************************/

        Address localAddress ()
        {
                Address addr = newFamilyObject ();
                int nameLen = addr.nameLen();
                if(SOCKET_ERROR == .getsockname (sock, addr.name(), &nameLen))
                   exception ("Unable to obtain local socket address: ");
                assert (addr.addressFamily() == family);
                return addr;
        }

        /// Send or receive error code.
        const int ERROR = SOCKET_ERROR;


        /**
         * Send data on the connection. Returns the number of bytes actually
         * sent, or ERROR on failure. If the socket is blocking and there is no
         * buffer space left, send waits.
         */
        //returns number of bytes actually sent, or -1 on error
        int send(void[] buf, SocketFlags flags=SocketFlags.NONE)
        {
                return .send(sock, buf.ptr, buf.length, cast(int)flags);
        }

        /**
         * Send data to a specific destination Address. If the destination address is not specified, a connection must have been made and that address is used. If the socket is blocking and there is no buffer space left, sendTo waits.
         */
        int sendTo(void[] buf, SocketFlags flags, Address to)
        {
                return .sendto(sock, buf.ptr, buf.length, cast(int)flags, to.name(), to.nameLen());
        }

        /// ditto
        int sendTo(void[] buf, Address to)
        {
                return sendTo(buf, SocketFlags.NONE, to);
        }


        //assumes you connect()ed
        /// ditto
        int sendTo(void[] buf, SocketFlags flags=SocketFlags.NONE)
        {
                return .sendto(sock, buf.ptr, buf.length, cast(int)flags, null, 0);
        }


        /**
         * Receive data on the connection. Returns the number of bytes actually
         * received, 0 if the remote side has closed the connection, or ERROR on
         * failure. If the socket is blocking, receive waits until there is data
         * to be received.
         */
        //returns number of bytes actually received, 0 on connection closure, or -1 on error
        int receive(void[] buf, SocketFlags flags=SocketFlags.NONE)
        {
                if (!buf.length)
                     badArg ("Socket.receive :: target buffer has 0 length");

                return .recv(sock, buf.ptr, buf.length, cast(int)flags);
        }

        /**
         * Receive data and get the remote endpoint Address. Returns the number of bytes actually received, 0 if the remote side has closed the connection, or ERROR on failure. If the socket is blocking, receiveFrom waits until there is data to be received.
         */
        int receiveFrom(void[] buf, SocketFlags flags, Address from)
        {
                if (!buf.length)
                     badArg ("Socket.receiveFrom :: target buffer has 0 length");

                assert(from.addressFamily() == family);
                int nameLen = from.nameLen();
                return .recvfrom(sock, buf.ptr, buf.length, cast(int)flags, from.name(), &nameLen);
        }


        /// ditto
        int receiveFrom(void[] buf, Address from)
        {
                return receiveFrom(buf, SocketFlags.NONE, from);
        }


        //assumes you connect()ed
        /// ditto
        int receiveFrom(void[] buf, SocketFlags flags = SocketFlags.NONE)
        {
                if (!buf.length)
                     badArg ("Socket.receiveFrom :: target buffer has 0 length");

                return .recvfrom(sock, buf.ptr, buf.length, cast(int)flags, null, null);
        }


        /***********************************************************************

                returns the length, in bytes, of the actual result - very
                different from getsockopt()

        ***********************************************************************/

        int getOption (SocketOptionLevel level, SocketOption option, void[] result)
        {
                int len = result.length;
                if(SOCKET_ERROR == .getsockopt (sock, cast(int)level, cast(int)option, result.ptr, &len))
                   exception ("Unable to get socket option: ");
                return len;
        }


        /***********************************************************************


        ***********************************************************************/

        Socket setOption (SocketOptionLevel level, SocketOption option, void[] value)
        {
                if(SOCKET_ERROR == .setsockopt (sock, cast(int)level, cast(int)option, value.ptr, value.length))
                   exception ("Unable to set socket option: ");
                return this;
        }


        /***********************************************************************

                Tango: added this common function

        ***********************************************************************/

        protected static void exception (char[] msg)
        {
                throw new SocketException (msg ~ SysError.lookup(lastError));
        }


        /***********************************************************************

                Tango: added this common function

        ***********************************************************************/

        protected static void badArg (char[] msg)
        {
                throw new IllegalArgumentException (msg);
        }


        /***********************************************************************

                SocketSet's are updated to include only those sockets which an
                event occured.

                Returns the number of events, 0 on timeout, or -1 on error

                for a connect()ing socket, writeability means connected
                for a listen()ing socket, readability means listening

                Winsock: possibly internally limited to 64 sockets per set

        ***********************************************************************/

        static int select (SocketSet checkRead, SocketSet checkWrite, SocketSet checkError, timeval* tv)
        in
        {
                //make sure none of the SocketSet's are the same object
                if(checkRead)
                {
                        assert(checkRead !is checkWrite);
                        assert(checkRead !is checkError);
                }
                if(checkWrite)
                {
                        assert(checkWrite !is checkError);
                }
        }
        body
        {
                fd_set* fr, fw, fe;

                version(Win32)
                {
                        //Windows has a problem with empty fd_set's that aren't null
                        fr = (checkRead && checkRead.count()) ? checkRead.toFd_set() : null;
                        fw = (checkWrite && checkWrite.count()) ? checkWrite.toFd_set() : null;
                        fe = (checkError && checkError.count()) ? checkError.toFd_set() : null;
                }
                else
                {
                        fr = checkRead ? checkRead.toFd_set() : null;
                        fw = checkWrite ? checkWrite.toFd_set() : null;
                        fe = checkError ? checkError.toFd_set() : null;
                }

                int result;

                // Tango: if select() was interrupted, we now try again
                version(Win32)
                {
                        while ((result = .select (socket_t.max - 1, fr, fw, fe, tv)) == -1)
                        {
                                if(WSAGetLastError() != WSAEINTR)
                                   break;
                        }
                }
                else version (Posix)
                {
                        socket_t maxfd = 0;

                        if (checkRead)
                                maxfd = checkRead.maxfd;

                        if (checkWrite && checkWrite.maxfd > maxfd)
                                maxfd = checkWrite.maxfd;

                        if (checkError && checkError.maxfd > maxfd)
                                maxfd = checkError.maxfd;

                        while ((result = .select (maxfd + 1, fr, fw, fe, tv)) == -1)
                        {
                                if(errno() != EINTR)
                                   break;
                        }
                }
                else
                {
                        static assert(0);
                }
                // Tango: don't throw an exception here ... wait until we get
                // a bit further back along the control path
                //if(SOCKET_ERROR == result)
                //   throw new SocketException("Socket select error.");

                return result;
        }

        /***********************************************************************

                select with specified timeout

        ***********************************************************************/

        static int select (SocketSet checkRead, SocketSet checkWrite, SocketSet checkError, TimeSpan time)
        {
                auto tv = toTimeval (time);
                return select (checkRead, checkWrite, checkError, &tv);
        }

        /***********************************************************************

                select with maximum timeout

        ***********************************************************************/

        static int select (SocketSet checkRead, SocketSet checkWrite, SocketSet checkError)
        {
                return select (checkRead, checkWrite, checkError, null);
        }

        /***********************************************************************

                Handy utility for converting TimeSpan into timeval

        ***********************************************************************/

        static timeval toTimeval (TimeSpan time)
        {
                timeval tv;
                tv.tv_sec = cast(uint) time.seconds;
                tv.tv_usec = cast(uint) time.micros % 1_000_000;
                return tv;
        }
}



/*******************************************************************************


*******************************************************************************/

abstract class Address
{
        protected sockaddr* name();
        protected int nameLen();
        AddressFamily addressFamily();
        char[] toString();

        /***********************************************************************

                Tango: added this common function

        ***********************************************************************/

        static void exception (char[] msg)
        {
                throw new AddressException (msg);
        }

}


/*******************************************************************************


*******************************************************************************/

class UnknownAddress: Address
{
        protected:
        sockaddr sa;


        /***********************************************************************


        ***********************************************************************/

        sockaddr* name()
        {
                return &sa;
        }


        /***********************************************************************


        ***********************************************************************/

        int nameLen()
        {
                return sa.sizeof;
        }


        public:
        /***********************************************************************


        ***********************************************************************/

        AddressFamily addressFamily()
        {
                return cast(AddressFamily) sa.sa_family;
        }


        /***********************************************************************


        ***********************************************************************/

        char[] toString()
        {
                return "Unknown";
        }
}


/*******************************************************************************


*******************************************************************************/

class NetHost
{
        char[] name;
        char[][] aliases;
        uint[] addrList;


        /***********************************************************************


        ***********************************************************************/

        protected void validHostent(hostent* he)
        {
                if(he.h_addrtype != cast(int)AddressFamily.INET || he.h_length != 4)
                        throw new HostException("Address family mismatch.");
        }


        /***********************************************************************


        ***********************************************************************/

        void populate(hostent* he)
        {
                int i;
                char* p;

                name = .toString(he.h_name);

                for(i = 0;; i++)
                {
                        p = he.h_aliases[i];
                        if(!p)
                                break;
                }

                if(i)
                {
                        aliases = new char[][i];
                        for(i = 0; i != aliases.length; i++)
                        {
                                aliases[i] = .toString(he.h_aliases[i]);
                        }
                }
                else
                {
                        aliases = null;
                }

                for(i = 0;; i++)
                {
                        p = he.h_addr_list[i];
                        if(!p)
                                break;
                }

                if(i)
                {
                        addrList = new uint[i];
                        for(i = 0; i != addrList.length; i++)
                        {
                                addrList[i] = ntohl(*(cast(uint*)he.h_addr_list[i]));
                        }
                }
                else
                {
                        addrList = null;
                }
        }


        /***********************************************************************


        ***********************************************************************/

        synchronized bool getHostByName(char[] name)
        {
                char[1024] tmp;

                hostent* he = gethostbyname(convert2C (name, tmp));
                if(!he)
                    return false;
                validHostent(he);
                populate(he);
                return true;
        }


        /***********************************************************************


        ***********************************************************************/

        synchronized bool getHostByAddr(uint addr)
        {
                uint x = htonl(addr);
                hostent* he = gethostbyaddr(&x, 4, cast(int)AddressFamily.INET);
                if(!he)
                    return false;
                validHostent(he);
                populate(he);
                return true;
        }


        /***********************************************************************


        ***********************************************************************/

        //shortcut
        synchronized bool getHostByAddr(char[] addr)
        {
                char[64] tmp;

                uint x = inet_addr(convert2C (addr, tmp));
                hostent* he = gethostbyaddr(&x, 4, cast(int)AddressFamily.INET);
                if(!he)
                    return false;
                validHostent(he);
                populate(he);
                return true;
        }
}


debug (UnitText)
{
extern (C) int printf(char*, ...);
unittest
{
        try
        {
        NetHost ih = new NetHost;
        ih.getHostByName(Socket.hostName());
        assert(ih.addrList.length > 0);
        IPv4Address ia = new IPv4Address(ih.addrList[0], IPv4Address.PORT_ANY);
        printf("IP address = %.*s\nname = %.*s\n", ia.toAddrString(), ih.name);
        foreach(int i, char[] s; ih.aliases)
        {
                printf("aliases[%d] = %.*s\n", i, s);
        }

        printf("---\n");

        assert(ih.getHostByAddr(ih.addrList[0]));
        printf("name = %.*s\n", ih.name);
        foreach(int i, char[] s; ih.aliases)
        {
                printf("aliases[%d] = %.*s\n", i, s);
                }
        }
        catch( Object o )
        {
            assert( false );
        }
}
}


/*******************************************************************************


*******************************************************************************/

class IPv4Address: Address
{
        protected:
        char[8] _port;

        /***********************************************************************


        ***********************************************************************/

        struct sockaddr_in
        {
                ushort sinfamily = AddressFamily.INET;
                ushort sin_port;
                uint sin_addr; //in_addr
                char[8] sin_zero = [0];
        }

        sockaddr_in sin;


        /***********************************************************************


        ***********************************************************************/

        sockaddr* name()
        {
                return cast(sockaddr*)&sin;
        }


        /***********************************************************************


        ***********************************************************************/

        int nameLen()
        {
                return sin.sizeof;
        }


        public:

        /***********************************************************************


        ***********************************************************************/

        this()
        {
        }


        const uint ADDR_ANY = 0;
        const uint ADDR_NONE = cast(uint)-1;
        const ushort PORT_ANY = 0;


        /***********************************************************************


        ***********************************************************************/

        AddressFamily addressFamily()
        {
                return AddressFamily.INET;
        }


        /***********************************************************************


        ***********************************************************************/

        ushort port()
        {
                return ntohs(sin.sin_port);
        }


        /***********************************************************************


        ***********************************************************************/

        uint addr()
        {
                return ntohl(sin.sin_addr);
        }


        /***********************************************************************

                -port- can be PORT_ANY
                -addr- is an IP address or host name

        ***********************************************************************/

        this(char[] addr, int port = PORT_ANY)
        {
                uint uiaddr = parse(addr);
                if(ADDR_NONE == uiaddr)
                {
                        NetHost ih = new NetHost;
                        if(!ih.getHostByName(addr))
                                exception ("Unable to resolve '"~addr~"': ");
                        uiaddr = ih.addrList[0];
                }
                sin.sin_addr = htonl(uiaddr);
                sin.sin_port = htons(cast(ushort) port);
        }


        /***********************************************************************


        ***********************************************************************/

        this(uint addr, ushort port)
        {
                sin.sin_addr = htonl(addr);
                sin.sin_port = htons(port);
        }


        /***********************************************************************


        ***********************************************************************/

        this(ushort port)
        {
                sin.sin_addr = 0; //any, "0.0.0.0"
                sin.sin_port = htons(port);
        }

        /***********************************************************************


        ***********************************************************************/

        synchronized char[] toAddrString()
        {
                return .toString(inet_ntoa(sin.sin_addr)).dup;
        }


        /***********************************************************************


        ***********************************************************************/

        char[] toPortString()
        {
                return .toString (_port, port());
        }


        /***********************************************************************


        ***********************************************************************/

        char[] toString()
        {
                return toAddrString() ~ ":" ~ toPortString();
        }


        /***********************************************************************

                -addr- is an IP address in the format "a.b.c.d"
                returns ADDR_NONE on failure

        ***********************************************************************/

        static uint parse(char[] addr)
        {
                char[64] tmp;

                return ntohl(inet_addr(convert2C (addr, tmp)));
        }
}

debug(Unittest)
{
unittest
{
        IPv4Address ia = new IPv4Address("63.105.9.61", 80);
        assert(ia.toString() == "63.105.9.61:80");
}
}

/*******************************************************************************


*******************************************************************************/

//a set of sockets for Socket.select()
class SocketSet
{
//        private:
        private uint nbytes; //Win32: excludes uint.size "count"
        private byte* buf;


        version(Win32)
        {
                uint count()
                {
                        return *(cast(uint*)buf);
                }


                void count(int setter)
                {
                        *(cast(uint*)buf) = setter;
                }


                socket_t* first()
                {
                        return cast(socket_t*)(buf + uint.sizeof);
                }
        }
        else version (Posix)
        {
                import tango.core.BitManip;


                uint nfdbits;
                socket_t _maxfd = 0;

                uint fdelt(socket_t s)
                {
                        return cast(uint)s / nfdbits;
                }


                uint fdmask(socket_t s)
                {
                        return 1 << cast(uint)s % nfdbits;
                }


                uint* first()
                {
                        return cast(uint*)buf;
                }

                public socket_t maxfd()
                {
                        return _maxfd;
                }
        }


        public:
        /***********************************************************************


        ***********************************************************************/

        this(uint max)
        {
                version(Win32)
                {
                        nbytes = max * socket_t.sizeof;
                        buf = (new byte[nbytes + uint.sizeof]).ptr;
                        count = 0;
                }
                else version (Posix)
                {
                        if(max <= 32)
                                nbytes = 32 * uint.sizeof;
                        else
                                nbytes = max * uint.sizeof;
                        buf = (new byte[nbytes]).ptr;
                        nfdbits = nbytes * 8;
                        //clear(); //new initializes to 0
                }
                else
                {
                        static assert(0);
                }
        }


        /***********************************************************************


        ***********************************************************************/

        this()
        {
                version(Win32)
                {
                        this(64);
                }
                else version (Posix)
                {
                        this(32);
                }
                else
                {
                        static assert(0);
                }
        }


        /***********************************************************************


        ***********************************************************************/

        void reset()
        {
                version(Win32)
                {
                        count = 0;
                }
                else version (Posix)
                {
                        buf[0 .. nbytes] = 0;
                        _maxfd = 0;
                }
                else
                {
                        static assert(0);
                }
        }


        /***********************************************************************


        ***********************************************************************/

        void add(socket_t s)
        in
        {
                version(Win32)
                {
                        assert(count < max); //added too many sockets; specify a higher max in the constructor
                }
        }
        body
        {
                version(Win32)
                {
                        uint c = count;
                        first[c] = s;
                        count = c + 1;
                }
                else version (Posix)
                {
                        if (s > _maxfd)
                                _maxfd = s;

                        bts(cast(uint*)&first[fdelt(s)], cast(uint)s % nfdbits);
                }
                else
                {
                        static assert(0);
                }
        }


        /***********************************************************************


        ***********************************************************************/

        void add(Socket s)
        {
                add(s.sock);
        }


        /***********************************************************************


        ***********************************************************************/

        void remove(socket_t s)
        {
                version(Win32)
                {
                        uint c = count;
                        socket_t* start = first;
                        socket_t* stop = start + c;

                        for(; start != stop; start++)
                        {
                                if(*start == s)
                                        goto found;
                        }
                        return; //not found

                        found:
                        for(++start; start != stop; start++)
                        {
                                *(start - 1) = *start;
                        }

                        count = c - 1;
                }
                else version (Posix)
                {
                        btr(cast(uint*)&first[fdelt(s)], cast(uint)s % nfdbits);

                        // If we're removing the biggest file descriptor we've
                        // entered so far we need to recalculate this value
                        // for the socket set.
                        if (s == _maxfd)
                        {
                                while (--_maxfd >= 0)
                                {
                                        if (isSet(_maxfd))
                                        {
                                                break;
                                        }
                                }
                        }
                }
                else
                {
                        static assert(0);
                }
        }


        /***********************************************************************


        ***********************************************************************/

        void remove(Socket s)
        {
                remove(s.sock);
        }


        /***********************************************************************


        ***********************************************************************/

        int isSet(socket_t s)
        {
                version(Win32)
                {
                        socket_t* start = first;
                        socket_t* stop = start + count;

                        for(; start != stop; start++)
                        {
                                if(*start == s)
                                        return true;
                        }
                        return false;
                }
                else version (Posix)
                {
                        //return bt(cast(uint*)&first[fdelt(s)], cast(uint)s % nfdbits);
                        int index = cast(uint)s % nfdbits;
                        return (cast(uint*)&first[fdelt(s)])[index / (uint.sizeof*8)] & (1 << (index & ((uint.sizeof*8) - 1)));
                }
                else
                {
                        static assert(0);
                }
        }


        /***********************************************************************


        ***********************************************************************/

        int isSet(Socket s)
        {
                return isSet(s.sock);
        }


        /***********************************************************************

                max sockets that can be added, like FD_SETSIZE

        ***********************************************************************/

        uint max()
        {
                return nbytes / socket_t.sizeof;
        }


        /***********************************************************************


        ***********************************************************************/

        fd_set* toFd_set()
        {
                return cast(fd_set*)buf;
        }
}

