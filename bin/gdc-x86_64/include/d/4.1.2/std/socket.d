// Written in the D programming language

/*
	Copyright (C) 2004-2005 Christopher E. Miller
	
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
	2. Altered source versions must be plainly marked as such, and must not
	   be misrepresented as being the original software.
	3. This notice may not be removed or altered from any source
	   distribution.
	
	socket.d 1.3
	Jan 2005
	
	Thanks to Benjamin Herr for his assistance.
*/

/* NOTE: This file has been patched from the original DMD distribution to
   work with the GDC compiler.

   Modified by David Friedman, April 2005
*/

/**
 * Notes: For Win32 systems, link with ws2_32.lib. 
 * Example: See /dmd/samples/d/listener.d.
 * Authors: Christopher E. Miller 
 * Macros:
 *	WIKI=Phobos/StdSocket
 */

module std.socket;

private import std.string, std.stdint, std.c.string, std.c.stdlib;


version(Unix)
{
	version = BsdSockets;
}

version (skyos) { /* nothging */ }
else
{
    version = have_getservbyport;
    version = have_getprotobynumber;
}

    
version(Win32)
{
	private import std.c.windows.windows, std.c.windows.winsock;
	private alias std.c.windows.winsock.timeval _ctimeval;
	
	typedef SOCKET socket_t = INVALID_SOCKET;
	private const int _SOCKET_ERROR = SOCKET_ERROR;
	
	
	private int _lasterr()
	{
		return WSAGetLastError();
	}
}
else version(BsdSockets)
{
	version (Unix)
	{
		private import std.c.unix.unix;
		private alias std.c.unix.unix.timeval _ctimeval;
	}
	
	typedef int32_t socket_t = -1;
	private const int _SOCKET_ERROR = -1;
	
	
	private int _lasterr()
	{
		return getErrno();
	}
}
else
{
	static assert(0); // No socket support yet.
}


/// Base exception thrown from a Socket.
class SocketException: Exception
{
	int errorCode; /// Platform-specific error code.
	
	this(string msg, int err = 0)
	{
		errorCode = err;
		
		version(Unix)
		{
			if(errorCode > 0)
			{
				char* cs;
				size_t len;
				
				cs = strerror(errorCode);
				len = strlen(cs);
				
				if(cs[len - 1] == '\n')
					len--;
				if(cs[len - 1] == '\r')
					len--;
				msg = msg ~ ": " ~ cs[0 .. len];
			}
		}
		
		super(msg);
	}
}


static this()
{
	version(Win32)
	{
		WSADATA wd;
		
		// Winsock will still load if an older version is present.
		// The version is just a request.
		int val;
		val = WSAStartup(0x2020, &wd);
		if(val) // Request Winsock 2.2 for IPv6.
			throw new SocketException("Unable to initialize socket library", val);
	}
}


static ~this()
{
	version(Win32)
	{
		WSACleanup();
	}
}

/**
 * The communication domain used to resolve an address.
 */
enum AddressFamily: int
{
	UNSPEC =     AF_UNSPEC,	///
	UNIX =       AF_UNIX,	/// local communication
	INET =       AF_INET,	/// internet protocol version 4
	IPX =        AF_IPX,	/// novell IPX
	APPLETALK =  AF_APPLETALK,	/// appletalk
	INET6 =      AF_INET6,	// internet protocol version 6
}


/**
 * Communication semantics
 */
enum SocketType: int
{
	STREAM =     SOCK_STREAM,	/// sequenced, reliable, two-way communication-based byte streams
	DGRAM =      SOCK_DGRAM,	/// connectionless, unreliable datagrams with a fixed maximum length; data may be lost or arrive out of order
	RAW =        SOCK_RAW,		/// raw protocol access
	RDM =        SOCK_RDM,		/// reliably-delivered message datagrams
	SEQPACKET =  SOCK_SEQPACKET,	/// sequenced, reliable, two-way connection-based datagrams with a fixed maximum length
}


/**
 * Protocol
 */
enum ProtocolType: int
{
	IP =    IPPROTO_IP,	/// internet protocol version 4
	ICMP =  IPPROTO_ICMP,	/// internet control message protocol
	IGMP =  IPPROTO_IGMP,	/// internet group management protocol
	GGP =   IPPROTO_GGP,	/// gateway to gateway protocol
	TCP =   IPPROTO_TCP,	/// transmission control protocol
	PUP =   IPPROTO_PUP,	/// PARC universal packet protocol
	UDP =   IPPROTO_UDP,	/// user datagram protocol
	IDP =   IPPROTO_IDP,	/// Xerox NS protocol
	IPV6 =  IPPROTO_IPV6,	/// internet protocol version 6
}


/**
 * Protocol is a class for retrieving protocol information.
 */
class Protocol
{
	ProtocolType type;	/// These members are populated when one of the following functions are called without failure:
	string name;		/// ditto
	string[] aliases;	/// ditto
	
	
	void populate(protoent* proto)
	{
		type = cast(ProtocolType)proto.p_proto;
		name = std.string.toString(proto.p_name).dup;
		
		int i;
		for(i = 0;; i++)
		{
			if(!proto.p_aliases[i])
				break;
		}
		
		if(i)
		{
			aliases = new string[i];
			for(i = 0; i != aliases.length; i++)
			{
				aliases[i] = std.string.toString(proto.p_aliases[i]).dup;
			}
		}
		else
		{
			aliases = null;
		}
	}
	
	/** Returns false on failure */
	bool getProtocolByName(string name)
	{
		protoent* proto;
		proto = getprotobyname(toStringz(name));
		if(!proto)
			return false;
		populate(proto);
		return true;
	}
	
	
	/** Returns false on failure */
	// Same as getprotobynumber().
	bool getProtocolByType(ProtocolType type)
	{
	    version (have_getprotobynumber)
	    {
		protoent* proto;
		proto = getprotobynumber(type);
		if(!proto)
			return false;
		populate(proto);
		return true;
	    }
	    else
		return false;
	}
}


unittest
{
	Protocol proto = new Protocol;
	assert(proto.getProtocolByType(ProtocolType.TCP));
	printf("About protocol TCP:\n\tName: %.*s\n",
	    cast(int) proto.name.length, proto.name.ptr);
	foreach(string s; proto.aliases)
	{
	        printf("\tAlias: %.*s\n", cast(int) s.length, s.ptr);
	}
}


/**
 * Service is a class for retrieving service information.
 */
class Service
{
	/** These members are populated when one of the following functions are called without failure: */
	string name;
	string[] aliases;	/// ditto
	ushort port;		/// ditto
	string protocolName;	/// ditto
	
	
	void populate(servent* serv)
	{
		name = std.string.toString(serv.s_name).dup;
		port = ntohs(cast(ushort)serv.s_port);
		protocolName = std.string.toString(serv.s_proto).dup;
		
		int i;
		for(i = 0;; i++)
		{
			if(!serv.s_aliases[i])
				break;
		}
		
		if(i)
		{
			aliases = new string[i];
			for(i = 0; i != aliases.length; i++)
			{
				aliases[i] = std.string.toString(serv.s_aliases[i]).dup;
			}
		}
		else
		{
			aliases = null;
		}
	}
	
	/**
	 * If a protocol name is omitted, any protocol will be matched.
	 * Returns: false on failure.
	 */
	bool getServiceByName(string name, string protocolName)
	{
		servent* serv;
		serv = getservbyname(toStringz(name), toStringz(protocolName));
		if(!serv)
			return false;
		populate(serv);
		return true;
	}
	
	
	// Any protocol name will be matched.
	/// ditto
	bool getServiceByName(string name)
	{
		servent* serv;
		serv = getservbyname(toStringz(name), null);
		if(!serv)
			return false;
		populate(serv);
		return true;
	}
	
	
	/// ditto
	bool getServiceByPort(ushort port, string protocolName)
	{
	    version (have_getservbyport)
	    {
		servent* serv;
		serv = getservbyport(port, toStringz(protocolName));
		if(!serv)
			return false;
		populate(serv);
		return true;
	    }
	    else
		return false;
	}
	
	
	// Any protocol name will be matched.
	/// ditto
	bool getServiceByPort(ushort port)
	{
	    version (have_getservbyport)
	    {
		servent* serv;
		serv = getservbyport(port, null);
		if(!serv)
			return false;
		populate(serv);
		return true;
	    }
	    else
		return false;
	}
}


unittest
{
	Service serv = new Service;
	if(serv.getServiceByName("epmap", "tcp"))
	{
		printf("About service epmap:\n\tService: %.*s\n\tPort: %d\n\tProtocol: %.*s\n",
		        cast(int) serv.name.length, serv.name.ptr, serv.port,
		        cast(int) serv.protocolName.length, serv.protocolName.ptr);
		foreach(char[] s; serv.aliases)
		{
		        printf("\tAlias: %.*s\n", cast(int) s.length, s.ptr);
		}
	}
	else
	{
		printf("No service for epmap.\n");
	}
}


/**
 * Base exception thrown from an InternetHost.
 */
class HostException: Exception
{
	int errorCode;	/// Platform-specific error code.
	
	
	this(string msg, int err = 0)
	{
		errorCode = err;
		super(msg);
	}
}

/**
 * InternetHost is a class for resolving IPv4 addresses.
 */
class InternetHost
{
	/** These members are populated when one of the following functions are called without failure: */
	string name;
	string[] aliases;	/// ditto
	uint32_t[] addrList;	/// ditto
	
	
	void validHostent(hostent* he)
	{
		if(he.h_addrtype != cast(int)AddressFamily.INET || he.h_length != 4)
			throw new HostException("Address family mismatch", _lasterr());
	}
	
	
	void populate(hostent* he)
	{
		int i;
		char* p;
		
		name = std.string.toString(he.h_name).dup;
		
		for(i = 0;; i++)
		{
			p = he.h_aliases[i];
			if(!p)
				break;
		}
		
		if(i)
		{
			aliases = new string[i];
			for(i = 0; i != aliases.length; i++)
			{
				aliases[i] = std.string.toString(he.h_aliases[i]).dup;
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
			addrList = new uint32_t[i];
			for(i = 0; i != addrList.length; i++)
			{
				addrList[i] = ntohl(*(cast(uint32_t*)he.h_addr_list[i]));
			}
		}
		else
		{
			addrList = null;
		}
	}
	
	/**
	 * Resolve host name. Returns false if unable to resolve.
	 */	
	bool getHostByName(string name)
	{
		hostent* he;
                synchronized(this.classinfo) he = gethostbyname(toStringz(name));
		if(!he)
			return false;
		validHostent(he);
		populate(he);
		return true;
	}
	
	
	/**
	 * Resolve IPv4 address number. Returns false if unable to resolve.
	 */	
	bool getHostByAddr(uint addr)
	{
		uint x = htonl(addr);
		hostent* he;
                synchronized(this.classinfo) he = gethostbyaddr(&x, 4, cast(int)AddressFamily.INET);
		if(!he)
			return false;
		validHostent(he);
		populate(he);
		return true;
	}
	
	
	/**
	 * Same as previous, but addr is an IPv4 address string in the
	 * dotted-decimal form $(I a.b.c.d).
	 * Returns false if unable to resolve.
	 */	
	bool getHostByAddr(string addr)
	{
		uint x = inet_addr(std.string.toStringz(addr));
		hostent* he;
                synchronized(this.classinfo) he = gethostbyaddr(&x, 4, cast(int)AddressFamily.INET);
		if(!he)
			return false;
		validHostent(he);
		populate(he);
		return true;
	}
}


unittest
{
	InternetHost ih = new InternetHost;
	assert(ih.getHostByName("www.digitalmars.com"));
	printf("addrList.length = %d\n", ih.addrList.length);
	assert(ih.addrList.length);
	InternetAddress ia = new InternetAddress(ih.addrList[0], InternetAddress.PORT_ANY);
	char[] sia = ia.toAddrString();
	printf("IPaddress = %.*s\nname = %.*s\n", cast(int) sia.length, sia.ptr,
	    cast(int) ih.name.length, ih.name.ptr);
	foreach(int i, string s; ih.aliases)
	{
	        printf("aliases[%d] = %.*s\n", i, cast(int) s.length, s.ptr);
	}
	
	printf("---\n");
	
	assert(ih.getHostByAddr(ih.addrList[0]));
	printf("name = %.*s\n", cast(int) ih.name.length, ih.name.ptr);
	foreach(int i, string s; ih.aliases)
	{
	        printf("aliases[%d] = %.*s\n", i, cast(int) s.length, s.ptr);
	}
}


/**
 * Base exception thrown from an Address.
 */
class AddressException: Exception
{
	this(string msg)
	{
		super(msg);
	}
}


/**
 * Address is an abstract class for representing a network addresses.
 */
abstract class Address
{
	protected sockaddr* name();
	protected int nameLen();
	AddressFamily addressFamily();	/// Family of this address.
	string toString();		/// Human readable string representing this address.
}

/**
 *
 */
class UnknownAddress: Address
{
	protected:
	sockaddr sa;
	
	
	sockaddr* name()
	{
		return &sa;
	}
	
	
	int nameLen()
	{
		return sa.sizeof;
	}
	
	
	public:
	AddressFamily addressFamily()
	{
		return cast(AddressFamily)sa.sa_family;
	}
	
	
	string toString()
	{
		return "Unknown";
	}
}


/**
 * InternetAddress is a class that represents an IPv4 (internet protocol version
 * 4) address and port.
 */
class InternetAddress: Address
{
	protected:
	sockaddr_in sin;


	sockaddr* name()
	{
		return cast(sockaddr*)&sin;
	}
	
	
	int nameLen()
	{
		return sin.sizeof;
	}
	
	
	this()
	{
	}
	
	
	public:
	const uint ADDR_ANY = INADDR_ANY;	/// Any IPv4 address number.
	const uint ADDR_NONE = INADDR_NONE;	/// An invalid IPv4 address number.
	const ushort PORT_ANY = 0;		/// Any IPv4 port number.
	
	/// Overridden to return AddressFamily.INET.
	AddressFamily addressFamily()
	{
		return cast(AddressFamily)AddressFamily.INET;
	}
	
	/// Returns the IPv4 port number.
	ushort port()
	{
		return ntohs(sin.sin_port);
	}
	
	/// Returns the IPv4 address number.
	uint addr()
	{
		return ntohl(sin.sin_addr.s_addr);
	}
	
	/**
	 * Params:
	 *   addr = an IPv4 address string in the dotted-decimal form a.b.c.d,
	 *          or a host name that will be resolved using an InternetHost
	 *          object.
	 *   port = may be PORT_ANY as stated below.
	 */
	this(string addr, ushort port)
	{
		uint uiaddr = parse(addr);
		if(ADDR_NONE == uiaddr)
		{
			InternetHost ih = new InternetHost;
			if(!ih.getHostByName(addr))
				//throw new AddressException("Invalid internet address");
				throw new AddressException("Unable to resolve host '" ~ addr ~ "'");
			uiaddr = ih.addrList[0];
		}
		sin.sin_addr.s_addr = htonl(uiaddr);
		sin.sin_port = htons(port);
	}
	
	/**
	 * Construct a new Address. addr may be ADDR_ANY (default) and port may
	 * be PORT_ANY, and the actual numbers may not be known until a connection
	 * is made.
	 */
	this(uint addr, ushort port)
	{
		sin.sin_addr.s_addr = htonl(addr);
		sin.sin_port = htons(port);
	}
	
	/// ditto	
	this(ushort port)
	{
		sin.sin_addr.s_addr = 0; //any, "0.0.0.0"
		sin.sin_port = htons(port);
	}
	
	/// Human readable string representing the IPv4 address in dotted-decimal form.	
	string toAddrString()
	{
		return std.string.toString(inet_ntoa(sin.sin_addr)).dup;
	}
	
	/// Human readable string representing the IPv4 port.
	string toPortString()
	{
		return std.string.toString(port());
	}
	
	/// Human readable string representing the IPv4 address and port in the form $(I a.b.c.d:e).
	string toString()
	{
		return toAddrString() ~ ":" ~ toPortString();
	}
	
	/**
	 * Parse an IPv4 address string in the dotted-decimal form $(I a.b.c.d)
	 * and return the number.
	 * If the string is not a legitimate IPv4 address,
	 * ADDR_NONE is returned.
	 */
	static uint parse(string addr)
	{
		return ntohl(inet_addr(std.string.toStringz(addr)));
	}
}


unittest
{
	InternetAddress ia = new InternetAddress("63.105.9.61", 80);
	assert(ia.toString() == "63.105.9.61:80");
}


/** */
class SocketAcceptException: SocketException
{
	this(string msg, int err = 0)
	{
		super(msg, err);
	}
}

/// How a socket is shutdown:
enum SocketShutdown: int
{
	RECEIVE =  SD_RECEIVE,	/// socket receives are disallowed
	SEND =     SD_SEND,	/// socket sends are disallowed
	BOTH =     SD_BOTH,	/// both RECEIVE and SEND
}


/// Flags may be OR'ed together:
enum SocketFlags: int
{
	NONE =       0,             /// no flags specified 
	
	OOB =        MSG_OOB,       /// out-of-band stream data
	PEEK =       MSG_PEEK,      /// peek at incoming data without removing it from the queue, only for receiving
	DONTROUTE =  MSG_DONTROUTE, /// data should not be subject to routing; this flag may be ignored. Only for sending
        NOSIGNAL =   MSG_NOSIGNAL,  /// don't send SIGPIPE signal on socket write error and instead return EPIPE
}


/// Duration timeout value.
extern(C) struct timeval
{
	// D interface
	int seconds;		/// Number of seconds.
	int microseconds;	/// Number of additional microseconds.
	
	// C interface
	deprecated
	{
		alias seconds tv_sec;
		alias microseconds tv_usec;
	}
}


/// A collection of sockets for use with Socket.select.
class SocketSet
{
	private:
	uint maxsockets; /// max desired sockets, the fd_set might be capable of holding more
	fd_set set;
	
	
	version(Win32)
	{
		uint count()
		{
			return set.fd_count;
		}
	}
	else version(BsdSockets)
	{
		int maxfd;
		uint count;
	}
	
	
	public:

	/// Set the maximum amount of sockets that may be added.
	this(uint max)
	{
		maxsockets = max;
		reset();
	}
	
	/// Uses the default maximum for the system.
	this()
	{
		this(FD_SETSIZE);
	}
	
	/// Reset the SocketSet so that there are 0 Sockets in the collection.	
	void reset()
	{
		FD_ZERO(&set);
		
		version(BsdSockets)
 		{
 			maxfd = -1;
			count = 0;
 		}
	}
	
	
	void add(socket_t s)
	in
	{
		// Make sure too many sockets don't get added.
		assert(count < maxsockets);
		version(BsdSockets)
		{
			version(GNU)
			{
			    // Tries to account for little and big endian..er needs work
			    // assert((s/NFDBITS+1)*NFDBITS/8 <= nbytes);
			}
			else
			{
				assert(FDELT(s) < (FD_SETSIZE / NFDBITS));
			}
		}
	}
	body
	{
		FD_SET(s, &set);
		
		version(BsdSockets)
		{
			++count;
			if(s > maxfd)
				maxfd = s;
		}
	}
	
	/// Add a Socket to the collection. Adding more than the maximum has dangerous side affects.
	void add(Socket s)
	{
		add(s.sock);
	}
	
	void remove(socket_t s)
	{
		FD_CLR(s, &set);
		version(BsdSockets)
		{
			--count;
			// note: adjusting maxfd would require scanning the set, not worth it
		}
	}
	
	
	/// Remove this Socket from the collection.
	void remove(Socket s)
	{
		remove(s.sock);
	}
	
	int isSet(socket_t s)
	{
		return FD_ISSET(s, &set);
	}
	
	
	/// Returns nonzero if this Socket is in the collection.
	int isSet(Socket s)
	{
		return isSet(s.sock);
	}
	

	/// Return maximum amount of sockets that can be added, like FD_SETSIZE.
	uint max()
	{
		return maxsockets;
	}
	
	
	fd_set* toFd_set()
	{
		return &set;
	}
	
	
	int selectn()
	{
		version(Win32)
		{
			return count;
		}
		else version(BsdSockets)
		{
			return maxfd + 1;
		}
	}
}


/// The level at which a socket option is defined:
enum SocketOptionLevel: int
{
	SOCKET =  SOL_SOCKET,		/// socket level
	IP =      ProtocolType.IP,	/// internet protocol version 4 level
	ICMP =    ProtocolType.ICMP,	///
	IGMP =    ProtocolType.IGMP,	///
	GGP =     ProtocolType.GGP,	///
	TCP =     ProtocolType.TCP,	/// transmission control protocol level
	PUP =     ProtocolType.PUP,	///
	UDP =     ProtocolType.UDP,	/// user datagram protocol level
	IDP =     ProtocolType.IDP,	///
	IPV6 =    ProtocolType.IPV6,	/// internet protocol version 6 level
}


/// Linger information for use with SocketOption.LINGER.
extern(C) struct linger
{
	version (BsdSockets)
	    version (GNU)
	    {
		private alias std.c.unix.unix.linger __unix_linger;
		static assert(linger.sizeof == __unix_linger.sizeof);
	    }
	// D interface
	version(Win32)
	{
		uint16_t on;	/// Nonzero for on.
		uint16_t time;	/// Linger time.
	}
	else version(BsdSockets)
	{
		version (GNU)
		{
		    
		    typeof(__unix_linger.l_onoff) on;
		    typeof(__unix_linger.l_linger) time;
		    
		}
		else
		{
		    int32_t on;
		    int32_t time;
		}
	}
	
	// C interface
	deprecated
	{
		alias on l_onoff;
		alias time l_linger;
	}
}


/// Specifies a socket option:
enum SocketOption: int
{
	DEBUG =                SO_DEBUG,	/// record debugging information
	BROADCAST =            SO_BROADCAST,	/// allow transmission of broadcast messages
	REUSEADDR =            SO_REUSEADDR,	/// allow local reuse of address
	LINGER =               SO_LINGER,	/// linger on close if unsent data is present
	OOBINLINE =            SO_OOBINLINE,	/// receive out-of-band data in band
	SNDBUF =               SO_SNDBUF,	/// send buffer size
	RCVBUF =               SO_RCVBUF,	/// receive buffer size
	DONTROUTE =            SO_DONTROUTE,	/// do not route
	
	// SocketOptionLevel.TCP:
	TCP_NODELAY =          .TCP_NODELAY,	/// disable the Nagle algorithm for send coalescing
	
	// SocketOptionLevel.IPV6:
	IPV6_UNICAST_HOPS =    .IPV6_UNICAST_HOPS,	///
	IPV6_MULTICAST_IF =    .IPV6_MULTICAST_IF,	///
	IPV6_MULTICAST_LOOP =  .IPV6_MULTICAST_LOOP,	///
	IPV6_JOIN_GROUP =      .IPV6_JOIN_GROUP,	///
	IPV6_LEAVE_GROUP =     .IPV6_LEAVE_GROUP,	///
}


/**
 *  Socket is a class that creates a network communication endpoint using the
 * Berkeley sockets interface.
 */
class Socket
{
	private:
	socket_t sock;
	AddressFamily _family;
	
	version(Win32)
	    bool _blocking = false;	/// Property to get or set whether the socket is blocking or nonblocking.
	
	
	// For use with accepting().
	protected this()
	{
	}
	
	
	public:

	/**
	 * Create a blocking socket. If a single protocol type exists to support
	 * this socket type within the address family, the ProtocolType may be
	 * omitted.
	 */
	this(AddressFamily af, SocketType type, ProtocolType protocol)
	{
		sock = cast(socket_t)socket(af, type, protocol);
		if(sock == socket_t.init)
			throw new SocketException("Unable to create socket", _lasterr());
		_family = af;
	}
	
	
	// A single protocol exists to support this socket type within the
	// protocol family, so the ProtocolType is assumed.
	/// ditto
	this(AddressFamily af, SocketType type)
	{
		this(af, type, cast(ProtocolType)0); // Pseudo protocol number.
	}
	
	
	/// ditto
	this(AddressFamily af, SocketType type, string protocolName)
	{
		protoent* proto;
		proto = getprotobyname(toStringz(protocolName));
		if(!proto)
			throw new SocketException("Unable to find the protocol", _lasterr());
		this(af, type, cast(ProtocolType)proto.p_proto);
	}
	
	
	~this()
	{
		close();
	}
	
	
	/// Get underlying socket handle.
	socket_t handle()
	{
		return sock;
	}

	/**
	 * Get/set socket's blocking flag.
	 *
	 * When a socket is blocking, calls to receive(), accept(), and send()
	 * will block and wait for data/action.
	 * A non-blocking socket will immediately return instead of blocking. 
	 */
	bool blocking()
	{
		version(Win32)
		{
			return _blocking;
		}
		else version(BsdSockets)
		{
			return !(fcntl(handle, F_GETFL, 0) & O_NONBLOCK);
		}
	}
	
	/// ditto
	void blocking(bool byes)
	{
		version(Win32)
		{
			uint num = !byes;
			if(_SOCKET_ERROR == ioctlsocket(sock, FIONBIO, &num))
				goto err;
			_blocking = byes;
		}
		else version(BsdSockets)
		{
			int x = fcntl(sock, F_GETFL, 0);
			if(-1 == x)
				goto err;
			if(byes)
				x &= ~O_NONBLOCK;
			else
				x |= O_NONBLOCK;
			if(-1 == fcntl(sock, F_SETFL, x))
				goto err;
		}
		return; // Success.
		
		err:
		throw new SocketException("Unable to set socket blocking", _lasterr());
	}
	

	/// Get the socket's address family.	
	AddressFamily addressFamily() // getter
	{
		return _family;
	}
	
	/// Property that indicates if this is a valid, alive socket.
	bool isAlive() // getter
	{
		int type, typesize = type.sizeof;
		return !getsockopt(sock, SOL_SOCKET, SO_TYPE, cast(char*)&type, &typesize);
	}
	
	/// Associate a local address with this socket.
	void bind(Address addr)
	{
		if(_SOCKET_ERROR == .bind(sock, addr.name(), addr.nameLen()))
			throw new SocketException("Unable to bind socket", _lasterr());
	}
	
	/**
	 * Establish a connection. If the socket is blocking, connect waits for
	 * the connection to be made. If the socket is nonblocking, connect
	 * returns immediately and the connection attempt is still in progress.
	 */
	void connect(Address to)
	{
		if(_SOCKET_ERROR == .connect(sock, to.name(), to.nameLen()))
		{
			int err;
			err = _lasterr();
			
			if(!blocking)
			{
				version(Win32)
				{
					if(WSAEWOULDBLOCK == err)
						return;
				}
				else version(Unix)
				{
					if(EINPROGRESS == err)
						return;
				}
				else
				{
					static assert(0);
				}
			}
			throw new SocketException("Unable to connect socket", err);
		}
	}
	
	/**
	 * Listen for an incoming connection. bind must be called before you can
	 * listen. The backlog is a request of how many pending incoming
	 * connections are queued until accept'ed.
	 */
	void listen(int backlog)
	{
		if(_SOCKET_ERROR == .listen(sock, backlog))
			throw new SocketException("Unable to listen on socket", _lasterr());
	}
	
	/**
	 * Called by accept when a new Socket must be created for a new
	 * connection. To use a derived class, override this method and return an
	 * instance of your class. The returned Socket's handle must not be set;
	 * Socket has a protected constructor this() to use in this situation.
	 */
	// Override to use a derived class.
	// The returned socket's handle must not be set.
	protected Socket accepting()
	{
		return new Socket;
	}
	
	/**
	 * Accept an incoming connection. If the socket is blocking, accept
	 * waits for a connection request. Throws SocketAcceptException if unable
	 * to accept. See accepting for use with derived classes.
	 */
	Socket accept()
	{
		socket_t newsock;
		//newsock = cast(socket_t).accept(sock, null, null); // DMD 0.101 error: found '(' when expecting ';' following 'statement
		alias .accept topaccept;
		newsock = cast(socket_t)topaccept(sock, null, null);
		if(socket_t.init == newsock)
			throw new SocketAcceptException("Unable to accept socket connection", _lasterr());
		
		Socket newSocket;
		try
		{
			newSocket = accepting();
			assert(newSocket.sock == socket_t.init);
			
			newSocket.sock = newsock;
			version(Win32)
				newSocket._blocking = _blocking; //inherits blocking mode
			newSocket._family = _family; //same family
		}
		catch(Object o)
		{
			_close(newsock);
			throw o;
		}
		
		return newSocket;
	}
	
	/// Disables sends and/or receives.
	void shutdown(SocketShutdown how)
	{
		.shutdown(sock, cast(int)how);
	}
	
	
	private static void _close(socket_t sock)
	{
		version(Win32)
		{
			.closesocket(sock);
		}
		else version(BsdSockets)
		{
			.close(sock);
		}
	}
	

	/**
	 * Immediately drop any connections and release socket resources.
	 * Calling shutdown before close is recommended for connection-oriented
	 * sockets. The Socket object is no longer usable after close.
	 */
	//calling shutdown() before this is recommended
	//for connection-oriented sockets
	void close()
	{
		_close(sock);
		sock = socket_t.init;
	}
	
	
	private Address newFamilyObject()
	{
		Address result;
		switch(_family)
		{
			case cast(AddressFamily)AddressFamily.INET:
				result = new InternetAddress;
				break;
			
			default:
				result = new UnknownAddress;
		}
		return result;
	}
	
	
	/// Returns the local machine's host name. Idea from mango.
	static string hostName() // getter
	{
		char[256] result; // Host names are limited to 255 chars.
		if(_SOCKET_ERROR == .gethostname(result.ptr, result.length))
			throw new SocketException("Unable to obtain host name", _lasterr());
		return std.string.toString(cast(char*)result).dup;
	}
	
	/// Remote endpoint Address.
	Address remoteAddress()
	{
		Address addr = newFamilyObject();
		int nameLen = addr.nameLen();
		if(_SOCKET_ERROR == .getpeername(sock, addr.name(), &nameLen))
			throw new SocketException("Unable to obtain remote socket address", _lasterr());
		assert(addr.addressFamily() == _family);
		return addr;
	}
	
	/// Local endpoint Address.
	Address localAddress()
	{
		Address addr = newFamilyObject();
		int nameLen = addr.nameLen();
		if(_SOCKET_ERROR == .getsockname(sock, addr.name(), &nameLen))
			throw new SocketException("Unable to obtain local socket address", _lasterr());
		assert(addr.addressFamily() == _family);
		return addr;
	}
	
	/// Send or receive error code.
	const int ERROR = _SOCKET_ERROR;
	
	/**
	 * Send data on the connection. Returns the number of bytes actually
	 * sent, or ERROR on failure. If the socket is blocking and there is no
	 * buffer space left, send waits.
	 */
	//returns number of bytes actually sent, or -1 on error
	int send(void[] buf, SocketFlags flags)
	{
                flags |= SocketFlags.NOSIGNAL;
		int sent = .send(sock, buf.ptr, buf.length, cast(int)flags);
		return sent;
	}
	
	/// ditto
	int send(void[] buf)
	{
		return send(buf, SocketFlags.NOSIGNAL);
	}
	
	/**
	 * Send data to a specific destination Address. If the destination address is not specified, a connection must have been made and that address is used. If the socket is blocking and there is no buffer space left, sendTo waits.
	 */
	int sendTo(void[] buf, SocketFlags flags, Address to)
	{
                flags |= SocketFlags.NOSIGNAL;
		int sent = .sendto(sock, buf.ptr, buf.length, cast(int)flags, to.name(), to.nameLen());
		return sent;
	}
	
	/// ditto
	int sendTo(void[] buf, Address to)
	{
		return sendTo(buf, SocketFlags.NONE, to);
	}
	
	
	//assumes you connect()ed
	/// ditto
	int sendTo(void[] buf, SocketFlags flags)
	{
                flags |= SocketFlags.NOSIGNAL;
		int sent = .sendto(sock, buf.ptr, buf.length, cast(int)flags, null, 0);
		return sent;
	}
	
	
	//assumes you connect()ed
	/// ditto
	int sendTo(void[] buf)
	{
		return sendTo(buf, SocketFlags.NONE);
	}
	

	/**
	 * Receive data on the connection. Returns the number of bytes actually
	 * received, 0 if the remote side has closed the connection, or ERROR on
	 * failure. If the socket is blocking, receive waits until there is data
	 * to be received.
	 */
	//returns number of bytes actually received, 0 on connection closure, or -1 on error
	int receive(void[] buf, SocketFlags flags)
	{
		if(!buf.length) //return 0 and don't think the connection closed
			return 0;
		int read = .recv(sock, buf.ptr, buf.length, cast(int)flags);
		// if(!read) //connection closed
		return read;
	}
	
	/// ditto
	int receive(void[] buf)
	{
		return receive(buf, SocketFlags.NONE);
	}
	
	/**
	 * Receive data and get the remote endpoint Address.
	 * If the socket is blocking, receiveFrom waits until there is data to
	 * be received.
	 * Returns: the number of bytes actually received,
	 * 0 if the remote side has closed the connection, or ERROR on failure.
	 */
	int receiveFrom(void[] buf, SocketFlags flags, out Address from)
	{
		if(!buf.length) //return 0 and don't think the connection closed
			return 0;
		from = newFamilyObject();
		int nameLen = from.nameLen();
		int read = .recvfrom(sock, buf.ptr, buf.length, cast(int)flags, from.name(), &nameLen);
		assert(from.addressFamily() == _family);
		// if(!read) //connection closed
		return read;
	}
	
	
	/// ditto
	int receiveFrom(void[] buf, out Address from)
	{
		return receiveFrom(buf, SocketFlags.NONE, from);
	}
	
	
	//assumes you connect()ed
	/// ditto
	int receiveFrom(void[] buf, SocketFlags flags)
	{
		if(!buf.length) //return 0 and don't think the connection closed
			return 0;
		int read = .recvfrom(sock, buf.ptr, buf.length, cast(int)flags, null, null);
		// if(!read) //connection closed
		return read;
	}
	
	
	//assumes you connect()ed
	/// ditto
	int receiveFrom(void[] buf)
	{
		return receiveFrom(buf, SocketFlags.NONE);
	}
	

	/// Get a socket option. Returns the number of bytes written to result.	
	//returns the length, in bytes, of the actual result - very different from getsockopt()
	int getOption(SocketOptionLevel level, SocketOption option, void[] result)
	{
		int len = result.length;
		if(_SOCKET_ERROR == .getsockopt(sock, cast(int)level, cast(int)option, result.ptr, &len))
			throw new SocketException("Unable to get socket option", _lasterr());
		return len;
	}
	

	/// Common case of getting integer and boolean options.	
	int getOption(SocketOptionLevel level, SocketOption option, out int32_t result)
	{
		return getOption(level, option, (&result)[0 .. 1]);
	}


	/// Get the linger option.	
	int getOption(SocketOptionLevel level, SocketOption option, out linger result)
	{
		//return getOption(cast(SocketOptionLevel)SocketOptionLevel.SOCKET, SocketOption.LINGER, (&result)[0 .. 1]);
		return getOption(level, option, (&result)[0 .. 1]); 
	}
	
	// Set a socket option.
	void setOption(SocketOptionLevel level, SocketOption option, void[] value)
	{
		if(_SOCKET_ERROR == .setsockopt(sock, cast(int)level, cast(int)option, value.ptr, value.length))
			throw new SocketException("Unable to set socket option", _lasterr());
	}
	
	
	/// Common case for setting integer and boolean options.
	void setOption(SocketOptionLevel level, SocketOption option, int32_t value)
	{
		setOption(level, option, (&value)[0 .. 1]);
	}


	/// Set the linger option.
	void setOption(SocketOptionLevel level, SocketOption option, linger value)
	{
		//setOption(cast(SocketOptionLevel)SocketOptionLevel.SOCKET, SocketOption.LINGER, (&value)[0 .. 1]);
		setOption(level, option, (&value)[0 .. 1]);
	}
	

	/**
	 * Wait for a socket to change status. A wait timeout timeval or int microseconds may be specified; if a timeout is not specified or the timeval is null, the maximum timeout is used. The timeval timeout has an unspecified value when select returns. Returns the number of sockets with status changes, 0 on timeout, or -1 on interruption. If the return value is greater than 0, the SocketSets are updated to only contain the sockets having status changes. For a connecting socket, a write status change means the connection is established and it's able to send. For a listening socket, a read status change means there is an incoming connection request and it's able to accept.
	 */
	//SocketSet's updated to include only those sockets which an event occured
	//returns the number of events, 0 on timeout, or -1 on interruption
	//for a connect()ing socket, writeability means connected
	//for a listen()ing socket, readability means listening
	//Winsock: possibly internally limited to 64 sockets per set
	static int select(SocketSet checkRead, SocketSet checkWrite, SocketSet checkError, timeval* tv)
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
		int n = 0;
		
		version(Win32)
		{
			// Windows has a problem with empty fd_set`s that aren't null.
			fr = (checkRead && checkRead.count()) ? checkRead.toFd_set() : null;
			fw = (checkWrite && checkWrite.count()) ? checkWrite.toFd_set() : null;
			fe = (checkError && checkError.count()) ? checkError.toFd_set() : null;
		}
		else
		{
			if(checkRead)
			{
				fr = checkRead.toFd_set();
				n = checkRead.selectn();
			}
			else
			{
				fr = null;
			}
			
			if(checkWrite)
			{
				fw = checkWrite.toFd_set();
				int _n;
				_n = checkWrite.selectn();
				if(_n > n)
					n = _n;
			}
			else
			{
				fw = null;
			}
			
			if(checkError)
			{
				fe = checkError.toFd_set();
				int _n;
				_n = checkError.selectn();
				if(_n > n)
					n = _n;
			}
			else
			{
				fe = null;
			}
		}
		
		int result = .select(n, fr, fw, fe, cast(_ctimeval*)tv);
		
		version(Win32)
		{
			if(_SOCKET_ERROR == result && WSAGetLastError() == WSAEINTR)
				return -1;
		}
		else version(Unix)
		{
			if(_SOCKET_ERROR == result && getErrno() == EINTR)
				return -1;
		}
		else
		{
			static assert(0);
		}
		
		if(_SOCKET_ERROR == result)
			throw new SocketException("Socket select error", _lasterr());
		
		return result;
	}


	/// ditto
	static int select(SocketSet checkRead, SocketSet checkWrite, SocketSet checkError, int microseconds)
	{
		timeval tv;
		tv.seconds = 0;
		tv.microseconds = microseconds;
		return select(checkRead, checkWrite, checkError, &tv);
	}
	
	
	/// ditto
	//maximum timeout
	static int select(SocketSet checkRead, SocketSet checkWrite, SocketSet checkError)
	{
		return select(checkRead, checkWrite, checkError, null);
	}
	
	
	/+
	bool poll(events)
	{
		int WSAEventSelect(socket_t s, WSAEVENT hEventObject, int lNetworkEvents); // Winsock 2 ?
		int poll(pollfd* fds, int nfds, int timeout); // Unix ?
	}
	+/
}


/// TcpSocket is a shortcut class for a TCP Socket.
class TcpSocket: Socket
{
	/// Constructs a blocking TCP Socket.
	this(AddressFamily family)
	{
		super(family, SocketType.STREAM, ProtocolType.TCP);
	}
	
	/// Constructs a blocking TCP Socket.
	this()
	{
		this(cast(AddressFamily)AddressFamily.INET);
	}
	
	
	//shortcut
	/// Constructs a blocking TCP Socket and connects to an InternetAddress.
	this(Address connectTo)
	{
		this(connectTo.addressFamily());
		connect(connectTo);
	}
}


/// UdpSocket is a shortcut class for a UDP Socket.
class UdpSocket: Socket
{
	/// Constructs a blocking UDP Socket.
	this(AddressFamily family)
	{
		super(family, SocketType.DGRAM, ProtocolType.UDP);
	}
	
	
	/// Constructs a blocking UDP Socket.
	this()
	{
		this(cast(AddressFamily)AddressFamily.INET);
	}
}

