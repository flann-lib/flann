module tango.sys.linux.socket;

private import tango.stdc.stdint;
public import tango.stdc.posix.fcntl;
public import tango.stdc.posix.unistd; // for gethostname

extern(C):

alias int socklen_t;

int socket(int af, int type, int protocol);
int bind(int s, sockaddr* name, int namelen);
int connect(int s, sockaddr* name, int namelen);
int listen(int s, int backlog);
int accept(int s, sockaddr* addr, int* addrlen);
int shutdown(int s, int how);
int getpeername(int s, sockaddr* name, int* namelen);
int getsockname(int s, sockaddr* name, int* namelen);
int send(int s, void* buf, int len, int flags);
int sendto(int s, void* buf, int len, int flags, sockaddr* to, int tolen);
int recv(int s, void* buf, int len, int flags);
int recvfrom(int s, void* buf, int len, int flags, sockaddr* from, int* fromlen);
int getsockopt(int s, int level, int optname, void* optval, int* optlen);
int setsockopt(int s, int level, int optname, void* optval, int optlen);
uint inet_addr(char* cp);
char* inet_ntoa(in_addr ina);
hostent* gethostbyname(char* name);
hostent* gethostbyaddr(void* addr, int len, int type);
protoent* getprotobyname(char* name);
protoent* getprotobynumber(int number);
servent* getservbyname(char* name, char* proto);
servent* getservbyport(int port, char* proto);
int getaddrinfo(char* nodename, char* servname, addrinfo* hints, addrinfo** res);
void freeaddrinfo(addrinfo* ai);
int getnameinfo(sockaddr* sa, socklen_t salen, char* node, socklen_t nodelen, char* service, socklen_t servicelen, int flags);


enum: int
{
	AF_UNSPEC =     0,
	AF_UNIX =       1,
	AF_INET =       2,
	AF_IPX =        4,
	AF_APPLETALK =  5,
	AF_INET6 =      10,
	// ...

	PF_UNSPEC =     AF_UNSPEC,
	PF_UNIX =       AF_UNIX,
	PF_INET =       AF_INET,
	PF_IPX =        AF_IPX,
	PF_APPLETALK =  AF_APPLETALK,
	PF_INET6 =      AF_INET6,
}


version( X86 )
{
	enum: int
	{
		SOL_SOCKET =  1,
	}
}
else version( X86_64 )
{
	enum: int
	{
		SOL_SOCKET =  1,
	}
}else
{
	// Different values on other platforms.
	static assert(0);
}


enum: int
{
	SO_DEBUG =       1,
	SO_BROADCAST =   6,
	SO_REUSEADDR =   2,
	SO_LINGER =      13,
	SO_DONTLINGER =  ~SO_LINGER,
	SO_OOBINLINE =   10,
	SO_SNDBUF =      7,
	SO_RCVBUF =      8,
	SO_ACCEPTCONN =  30,
	SO_DONTROUTE =   5,
	SO_TYPE =        3,

	TCP_NODELAY =    1,

	IP_MULTICAST_LOOP =  34,
	IP_ADD_MEMBERSHIP =  35,
	IP_DROP_MEMBERSHIP = 36,

	// ...

	IPV6_ADDRFORM =        1,
	IPV6_PKTINFO =         2,
	IPV6_HOPOPTS =         3,
	IPV6_DSTOPTS =         4,
	IPV6_RTHDR =           5,
	IPV6_PKTOPTIONS =      6,
	IPV6_CHECKSUM =        7,
	IPV6_HOPLIMIT =        8,
	IPV6_NEXTHOP =         9,
	IPV6_AUTHHDR =         10,
	IPV6_UNICAST_HOPS =    16,
	IPV6_MULTICAST_IF =    17,
	IPV6_MULTICAST_HOPS =  18,
	IPV6_MULTICAST_LOOP =  19,
	IPV6_JOIN_GROUP =      20,
	IPV6_LEAVE_GROUP =     21,
	IPV6_ROUTER_ALERT =    22,
	IPV6_MTU_DISCOVER =    23,
	IPV6_MTU =             24,
	IPV6_RECVERR =         25,
	IPV6_V6ONLY =          26,
	IPV6_JOIN_ANYCAST =    27,
	IPV6_LEAVE_ANYCAST =   28,
	IPV6_IPSEC_POLICY =    34,
	IPV6_XFRM_POLICY =     35,
}


struct linger
{
	int32_t l_onoff;
	int32_t l_linger;
}


struct protoent
{
	char* p_name;
	char** p_aliases;
	int32_t p_proto;
}


struct servent
{
	char* s_name;
	char** s_aliases;
	int32_t s_port;
	char* s_proto;
}


version( BigEndian )
{
	uint16_t htons(uint16_t x)
	{
		return x;
	}


	uint32_t htonl(uint32_t x)
	{
		return x;
	}
}
else version( LittleEndian )
{
	private import tango.core.BitManip;


	uint16_t htons(uint16_t x)
	{
		return cast(uint16_t) ((x >> 8) | (x << 8));
	}


	uint32_t htonl(uint32_t x)
	{
		return bswap(x);
	}
}
else
{
	static assert(0);
}


uint16_t ntohs(uint16_t x)
{
	return htons(x);
}


uint32_t ntohl(uint32_t x)
{
	return htonl(x);
}


enum: int
{
	SOCK_STREAM =     1,
	SOCK_DGRAM =      2,
	SOCK_RAW =        3,
	SOCK_RDM =        4,
	SOCK_SEQPACKET =  5,
}


enum: int
{
	IPPROTO_IP =    0,
	IPPROTO_ICMP =  1,
	IPPROTO_IGMP =  2,
	IPPROTO_GGP =   3,
	IPPROTO_TCP =   6,
	IPPROTO_PUP =   12,
	IPPROTO_UDP =   17,
	IPPROTO_IDP =   22,
	IPPROTO_IPV6 =  41,
	IPPROTO_ND =    77,
	IPPROTO_RAW =   255,

	IPPROTO_MAX =   256,
}


enum: int
{
	MSG_OOB =        0x1,
	MSG_PEEK =       0x2,
	MSG_DONTROUTE =  0x4,
}


enum: int
{
	SD_RECEIVE =  0,
	SD_SEND =     1,
	SD_BOTH =     2,
}


enum: uint
{
	INADDR_ANY =        0,
	INADDR_LOOPBACK =   0x7F000001,
	INADDR_BROADCAST =  0xFFFFFFFF,
	INADDR_NONE =       0xFFFFFFFF,
	ADDR_ANY =          INADDR_ANY,
}


enum: int
{
	AI_PASSIVE = 0x1,
	AI_CANONNAME = 0x2,
	AI_NUMERICHOST = 0x4,
}


union in_addr
{
	private union _S_un_t
	{
		private struct _S_un_b_t
		{
			uint8_t s_b1, s_b2, s_b3, s_b4;
		}
		_S_un_b_t S_un_b;

		private struct _S_un_w_t
		{
			uint16_t s_w1, s_w2;
		}
		_S_un_w_t S_un_w;

		uint32_t S_addr;
	}
	_S_un_t S_un;

	uint32_t s_addr;

	struct
	{
		uint8_t s_net, s_host;

		union
		{
			uint16_t s_imp;

			struct
			{
				uint8_t s_lh, s_impno;
			}
		}
	}
}


union in6_addr
{
	private union _in6_u_t
	{
		uint8_t[16] u6_addr8;
		uint16_t[8] u6_addr16;
		uint32_t[4] u6_addr32;
	}
	_in6_u_t in6_u;

	uint8_t[16] s6_addr8;
	uint16_t[8] s6_addr16;
	uint32_t[4] s6_addr32;
}


const in6_addr IN6ADDR_ANY = { s6_addr8: [0] };
const in6_addr IN6ADDR_LOOPBACK = { s6_addr8: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1] };
//alias IN6ADDR_ANY IN6ADDR_ANY_INIT;
//alias IN6ADDR_LOOPBACK IN6ADDR_LOOPBACK_INIT;

const uint INET_ADDRSTRLEN = 16;
const uint INET6_ADDRSTRLEN = 46;


struct sockaddr
{
	int16_t sa_family;
	ubyte[14] sa_data;
}


struct sockaddr_in
{
	int16_t sin_family = AF_INET;
	uint16_t sin_port;
	in_addr sin_addr;
	ubyte[8] sin_zero;
}


struct sockaddr_in6
{
	int16_t sin6_family = AF_INET6;
	uint16_t sin6_port;
	uint32_t sin6_flowinfo;
	in6_addr sin6_addr;
	uint32_t sin6_scope_id;
}


struct addrinfo
{
	int32_t ai_flags;
	int32_t ai_family;
	int32_t ai_socktype;
	int32_t ai_protocol;
	size_t ai_addrlen;
	sockaddr* ai_addr;
	char* ai_canonname;
	addrinfo* ai_next;
}


struct hostent
{
	char* h_name;
	char** h_aliases;
	int32_t h_addrtype;
	int32_t h_length;
	char** h_addr_list;


	char* h_addr()
	{
		return h_addr_list[0];
	}
}

