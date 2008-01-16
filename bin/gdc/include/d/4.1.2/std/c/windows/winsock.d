/*
	Written by Christopher E. Miller
	Placed into public domain.
*/


module std.c.windows.winsock;

private import std.stdint;
private import std.c.windows.windows;


extern(Windows):

alias UINT SOCKET;
alias int socklen_t;

const SOCKET INVALID_SOCKET = cast(SOCKET)~0;
const int SOCKET_ERROR = -1;

const int WSADESCRIPTION_LEN = 256;
const int WSASYS_STATUS_LEN = 128;

struct WSADATA
{
	WORD wVersion;
	WORD wHighVersion;
	char szDescription[WSADESCRIPTION_LEN + 1];
	char szSystemStatus[WSASYS_STATUS_LEN + 1];
	USHORT iMaxSockets;
	USHORT iMaxUdpDg;
	char* lpVendorInfo;
}
alias WSADATA* LPWSADATA;


const int IOCPARM_MASK =  0x7F;
const int IOC_IN =        cast(int)0x80000000;
const int FIONBIO =       cast(int)(IOC_IN | ((UINT.sizeof & IOCPARM_MASK) << 16) | (102 << 8) | 126);


int WSAStartup(WORD wVersionRequested, LPWSADATA lpWSAData);
int WSACleanup();
SOCKET socket(int af, int type, int protocol);
int ioctlsocket(SOCKET s, int cmd, uint* argp);
int bind(SOCKET s, sockaddr* name, int namelen);
int connect(SOCKET s, sockaddr* name, int namelen);
int listen(SOCKET s, int backlog);
SOCKET accept(SOCKET s, sockaddr* addr, int* addrlen);
int closesocket(SOCKET s);
int shutdown(SOCKET s, int how);
int getpeername(SOCKET s, sockaddr* name, int* namelen);
int getsockname(SOCKET s, sockaddr* name, int* namelen);
int send(SOCKET s, void* buf, int len, int flags);
int sendto(SOCKET s, void* buf, int len, int flags, sockaddr* to, int tolen);
int recv(SOCKET s, void* buf, int len, int flags);
int recvfrom(SOCKET s, void* buf, int len, int flags, sockaddr* from, int* fromlen);
int getsockopt(SOCKET s, int level, int optname, void* optval, int* optlen);
int setsockopt(SOCKET s, int level, int optname, void* optval, int optlen);
uint inet_addr(char* cp);
int select(int nfds, fd_set* readfds, fd_set* writefds, fd_set* errorfds, timeval* timeout);
char* inet_ntoa(in_addr ina);
hostent* gethostbyname(char* name);
hostent* gethostbyaddr(void* addr, int len, int type);
protoent* getprotobyname(char* name);
protoent* getprotobynumber(int number);
servent* getservbyname(char* name, char* proto);
servent* getservbyport(int port, char* proto);
int gethostname(char* name, int namelen);
int getaddrinfo(char* nodename, char* servname, addrinfo* hints, addrinfo** res);
void freeaddrinfo(addrinfo* ai);
int getnameinfo(sockaddr* sa, socklen_t salen, char* host, DWORD hostlen, char* serv, DWORD servlen, int flags);

enum: int
{
	WSAEWOULDBLOCK =     10035,
	WSAEINTR =           10004,
	WSAHOST_NOT_FOUND =  11001,
}

int WSAGetLastError();


enum: int
{
	AF_UNSPEC =     0,
	
	AF_UNIX =       1,
	AF_INET =       2,
	AF_IMPLINK =    3,
	AF_PUP =        4,
	AF_CHAOS =      5,
	AF_NS =         6,
	AF_IPX =        AF_NS,
	AF_ISO =        7,
	AF_OSI =        AF_ISO,
	AF_ECMA =       8,
	AF_DATAKIT =    9,
	AF_CCITT =      10,
	AF_SNA =        11,
	AF_DECnet =     12,
	AF_DLI =        13,
	AF_LAT =        14,
	AF_HYLINK =     15,
	AF_APPLETALK =  16,
	AF_NETBIOS =    17,
	AF_VOICEVIEW =  18,
	AF_FIREFOX =    19,
	AF_UNKNOWN1 =   20,
	AF_BAN =        21,
	AF_ATM =        22,
	AF_INET6 =      23,
	AF_CLUSTER =    24,
	AF_12844 =      25,
	AF_IRDA =       26,
	AF_NETDES =     28,
	
	AF_MAX =        29,
	
	
	PF_UNSPEC     = AF_UNSPEC,
	
	PF_UNIX =       AF_UNIX,
	PF_INET =       AF_INET,
	PF_IMPLINK =    AF_IMPLINK,
	PF_PUP =        AF_PUP,
	PF_CHAOS =      AF_CHAOS,
	PF_NS =         AF_NS,
	PF_IPX =        AF_IPX,
	PF_ISO =        AF_ISO,
	PF_OSI =        AF_OSI,
	PF_ECMA =       AF_ECMA,
	PF_DATAKIT =    AF_DATAKIT,
	PF_CCITT =      AF_CCITT,
	PF_SNA =        AF_SNA,
	PF_DECnet =     AF_DECnet,
	PF_DLI =        AF_DLI,
	PF_LAT =        AF_LAT,
	PF_HYLINK =     AF_HYLINK,
	PF_APPLETALK =  AF_APPLETALK,
	PF_VOICEVIEW =  AF_VOICEVIEW,
	PF_FIREFOX =    AF_FIREFOX,
	PF_UNKNOWN1 =   AF_UNKNOWN1,
	PF_BAN =        AF_BAN,
	PF_INET6 =      AF_INET6,
	
	PF_MAX        = AF_MAX,
}


enum: int
{
	SOL_SOCKET = 0xFFFF,
}


enum: int
{
	SO_DEBUG =        0x0001,
	SO_ACCEPTCONN =   0x0002,
	SO_REUSEADDR =    0x0004,
	SO_KEEPALIVE =    0x0008,
	SO_DONTROUTE =    0x0010,
	SO_BROADCAST =    0x0020,
	SO_USELOOPBACK =  0x0040,
	SO_LINGER =       0x0080,
	SO_DONTLINGER =   ~SO_LINGER,
	SO_OOBINLINE =    0x0100,
	SO_SNDBUF =       0x1001,
	SO_RCVBUF =       0x1002,
	SO_SNDLOWAT =     0x1003,
	SO_RCVLOWAT =     0x1004,
	SO_SNDTIMEO =     0x1005,
	SO_RCVTIMEO =     0x1006,
	SO_ERROR =        0x1007,
	SO_TYPE =         0x1008,
	SO_EXCLUSIVEADDRUSE = ~SO_REUSEADDR,
	
	TCP_NODELAY =    1,
	
	IP_MULTICAST_LOOP =  0x4,
	IP_ADD_MEMBERSHIP =  0x5,
	IP_DROP_MEMBERSHIP = 0x6,
	
	IPV6_UNICAST_HOPS =    4,
	IPV6_MULTICAST_IF =    9,
	IPV6_MULTICAST_HOPS =  10,
	IPV6_MULTICAST_LOOP =  11,
	IPV6_ADD_MEMBERSHIP =  12,
	IPV6_DROP_MEMBERSHIP = 13,
	IPV6_JOIN_GROUP =      IPV6_ADD_MEMBERSHIP,
	IPV6_LEAVE_GROUP =     IPV6_DROP_MEMBERSHIP,
}


const uint FD_SETSIZE = 64;


struct fd_set
{
	UINT fd_count;
	SOCKET[FD_SETSIZE] fd_array;
}


// Removes.
void FD_CLR(SOCKET fd, fd_set* set)
{
	uint c = set.fd_count;
	SOCKET* start = set.fd_array.ptr;
	SOCKET* stop = start + c;
	
	for(; start != stop; start++)
	{
		if(*start == fd)
			goto found;
	}
	return; //not found
	
	found:
	for(++start; start != stop; start++)
	{
		*(start - 1) = *start;
	}
	
	set.fd_count = c - 1;
}


// Tests.
int FD_ISSET(SOCKET fd, fd_set* set)
{
	SOCKET* start = set.fd_array.ptr;
	SOCKET* stop = start + set.fd_count;
	
	for(; start != stop; start++)
	{
		if(*start == fd)
			return true;
	}
	return false;
}


// Adds.
void FD_SET(SOCKET fd, fd_set* set)
{
	uint c = set.fd_count;
	set.fd_array.ptr[c] = fd;
	set.fd_count = c + 1;
}


// Resets to zero.
void FD_ZERO(fd_set* set)
{
	set.fd_count = 0;
}


struct linger
{
	USHORT l_onoff;
	USHORT l_linger;
}


struct protoent
{
	char* p_name;
	char** p_aliases;
	SHORT p_proto;
}


struct servent
{
	char* s_name;
	char** s_aliases;
	SHORT s_port;
	char* s_proto;
}


/+
union in6_addr
{
	private union _u_t
	{
		BYTE[16] Byte;
		WORD[8] Word;
	}
	_u_t u;
}


struct in_addr6
{
	BYTE[16] s6_addr;
}
+/


version(BigEndian)
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
else version(LittleEndian)
{
	private import std.intrinsic;
	
	
	uint16_t htons(uint16_t x)
	{
		return cast(uint16_t)((x >> 8) | (x << 8));
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


struct timeval
{
	int32_t tv_sec;
	int32_t tv_usec;
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
	
	alias s6_addr8 s6_addr;
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
	char* ai_canonname;
	sockaddr* ai_addr;
	addrinfo* ai_next;
}


struct hostent
{
	char* h_name;
	char** h_aliases;
	int16_t h_addrtype;
	int16_t h_length;
	char** h_addr_list;
	
	
	char* h_addr()
	{
		return h_addr_list[0];
	}
}

