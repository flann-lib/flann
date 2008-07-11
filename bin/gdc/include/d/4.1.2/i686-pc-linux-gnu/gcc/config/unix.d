module gcc.config.unix;
private import gcc.config.config;
private import gcc.config.libc;
struct dirent
{
    ubyte[10] __pad1;
    char d_type;
    char[256] d_name;
   ubyte[1] __pad2;
}

alias void DIR;
enum
{
  DT_WHT = 14,
  DT_SOCK = 12,
  DT_BLK = 6,
  DT_CHR = 2,
  DT_REG = 8,
  DT_UNKNOWN = 0,
  DT_DIR = 4,
  DT_LNK = 10,
  DT_FIFO = 1,
}

const int PATH_MAX = 4096;
const int NFDBITS = 32;
const int FD_SETSIZE = 1024;
struct fd_set
{
    byte[128] __opaque;
}

alias uint mode_t;
alias int pid_t;
alias uint uid_t;
alias uint gid_t;
alias int off_t;
alias int ssize_t;
enum
{
  O_NOCTTY = 256,
  O_ACCMODE = 3,
  O_NDELAY = 2048,
  O_WRONLY = 1,
  O_APPEND = 1024,
  O_NONBLOCK = 2048,
  O_RSYNC = 4096,
  O_DSYNC = 4096,
  O_RDWR = 2,
  O_NOATIME = 262144,
  O_SYNC = 4096,
  O_CREAT = 64,
  O_DIRECT = 16384,
  O_FSYNC = 4096,
  O_ASYNC = 8192,
  O_LARGEFILE = 32768,
  O_RDONLY = 0,
  O_TRUNC = 512,
  O_EXCL = 128,
  O_NOFOLLOW = 131072,
  O_DIRECTORY = 65536,
}

enum
{
  F_RDLCK = 0,
  F_GETLK = 5,
  F_DUPFD = 0,
  F_SETLEASE = 1024,
  F_UNLCK = 2,
  F_GETFL = 3,
  F_LOCK = 1,
  F_SETLKW64 = 14,
  F_GETSIG = 11,
  F_SETOWN = 8,
  F_ULOCK = 0,
  F_SETFL = 4,
  F_SHLCK = 8,
  F_GETOWN = 9,
  F_SETLK = 6,
  F_SETLK64 = 13,
  F_TLOCK = 2,
  F_GETLEASE = 1025,
  F_TEST = 3,
  F_SETSIG = 10,
  F_NOTIFY = 1026,
  F_WRLCK = 1,
  F_GETLK64 = 12,
  F_SETLKW = 7,
  F_GETFD = 1,
  F_EXLCK = 4,
  F_SETFD = 2,
}

enum
{
  F_OK = 0,
  W_OK = 2,
  R_OK = 4,
  X_OK = 1,
}

struct timespec
{
    int tv_sec;
    int tv_nsec;
}

struct timeval
{
    int tv_sec;
    int tv_usec;
}

struct timezone
{
    int tz_minuteswest;
    int tz_dsttime;
}

alias int clockid_t;
struct utimbuf
{
    int actime;
    int modtime;
}

enum
{
  S_ISGID = 1024,
  S_IFBLK = 24576,
  S_IXOTH = 1,
  S_IRWXG = 56,
  S_IRWXO = 7,
  S_IRWXU = 448,
  S_IFMT = 61440,
  S_ISVTX = 512,
  S_IFCHR = 8192,
  S_IWUSR = 128,
  S_IFREG = 32768,
  S_IWGRP = 16,
  S_IRUSR = 256,
  S_IFDIR = 16384,
  S_IFSOCK = 49152,
  S_IEXEC = 64,
  S_IXUSR = 64,
  S_IWOTH = 2,
  S_IRGRP = 32,
  S_IFLNK = 40960,
  S_IWRITE = 128,
  S_IXGRP = 8,
  S_ISUID = 2048,
  S_IREAD = 256,
  S_IROTH = 4,
  S_IFIFO = 4096,
}

struct struct_stat
{
    ulong st_dev;
    ubyte[4] __pad1;
    uint st_ino;
    uint st_mode;
    uint st_nlink;
    uint st_uid;
    uint st_gid;
    ulong st_rdev;
    ubyte[4] __pad2;
    int st_size;
    int st_blksize;
    int st_blocks;
    int st_atime;
    ubyte[4] __pad3;
    int st_mtime;
    ubyte[4] __pad4;
    int st_ctime;
   ubyte[12] __pad5;
}

enum
{
  SIGBUS = 7,
  SIGTTIN = 21,
  SIGPROF = 27,
  SIGFPE = 8,
  SIGTTOU = 22,
  SIGSTKFLT = 16,
  SIGUSR1 = 10,
  SIGURG = 23,
  SIGIO = 29,
  SIGQUIT = 3,
  SIGEV_NONE = 1,
  SIGCLD = 17,
  SIGABRT = 6,
  SIGSTKSZ = 8192,
  SIGTRAP = 5,
  SIGEV_THREAD = 2,
  SIGVTALRM = 26,
  SIGPOLL = 29,
  SIGHUP = 1,
  SIGSEGV = 11,
  SIGCONT = 18,
  SIGEV_THREAD_ID = 4,
  SIGPIPE = 13,
  SIGWINCH = 28,
  SIGXFSZ = 25,
  SIGCHLD = 17,
  SIGSYS = 31,
  SIGSTOP = 19,
  SIGALRM = 14,
  SIGUSR2 = 12,
  SIGTSTP = 20,
  SIGKILL = 9,
  SIGXCPU = 24,
  SIGILL = 4,
  SIGEV_SIGNAL = 0,
  SIGUNUSED = 31,
  SIGPWR = 30,
  SIGINT = 2,
  SIGIOT = 6,
  SIGTERM = 15,
}

enum
{
  SA_SIGINFO = 4,
  SA_ONSTACK = 134217728,
  SA_NODEFER = 1073741824,
  SA_RESETHAND = -2147483648,
  SA_NOMASK = 1073741824,
  SA_NOCLDSTOP = 1,
  SA_INTERRUPT = 536870912,
  SA_STACK = 134217728,
  SA_ONESHOT = -2147483648,
  SA_RESTART = 268435456,
  SA_NOCLDWAIT = 2,
}

struct sigset_t
{
    byte[128] __opaque;
}

alias extern(C) void function(int) __sighandler_t;
const __sighandler_t SIG_DFL = cast(__sighandler_t) 0;
const __sighandler_t SIG_IGN = cast(__sighandler_t) 1;
const __sighandler_t SIG_ERR = cast(__sighandler_t) 4294967295;
struct siginfo_t
{
    int si_signo;
    int si_errno;
    int si_code;
   ubyte[116] __pad1;
}

struct sigaction_t
{
    union {
        extern(C) void function(int) sa_handler;
        extern(C) void function(int, siginfo_t *, void *) sa_sigaction;
    }
    sigset_t sa_mask;
    int sa_flags;
   ubyte[4] __pad1;
}

const void * MAP_FAILED = cast(void *) 4294967295;
enum
{
  PROT_NONE = 0,
  PROT_GROWSDOWN = 16777216,
  PROT_EXEC = 4,
  PROT_WRITE = 2,
  PROT_READ = 1,
  PROT_GROWSUP = 33554432,
}

enum
{
  MAP_TYPE = 15,
  MAP_EXECUTABLE = 4096,
  MAP_PRIVATE = 2,
  MAP_ANON = 32,
  MAP_LOCKED = 8192,
  MAP_FIXED = 16,
  MAP_NORESERVE = 16384,
  MAP_POPULATE = 32768,
  MAP_FILE = 0,
  MAP_DENYWRITE = 2048,
  MAP_SHARED = 1,
  MAP_GROWSDOWN = 256,
  MAP_ANONYMOUS = 32,
  MAP_NONBLOCK = 65536,
}

enum
{
  MS_ASYNC = 1,
  MS_SYNC = 4,
  MS_INVALIDATE = 2,
}

enum
{
  MCL_CURRENT = 1,
  MCL_FUTURE = 2,
}

enum
{
  MREMAP_MAYMOVE = 1,
  MREMAP_FIXED = 2,
}

enum
{
  MADV_REMOVE = 9,
  MADV_NORMAL = 0,
  MADV_DONTFORK = 10,
  MADV_WILLNEED = 3,
  MADV_DONTNEED = 4,
  MADV_DOFORK = 11,
  MADV_SEQUENTIAL = 2,
  MADV_RANDOM = 1,
}

struct sem_t
{
    byte[16] __opaque;
}

alias uint pthread_t;
struct pthread_attr_t
{
    byte[36] __opaque;
}

struct pthread_cond_t
{
    byte[48] __opaque;
}

struct pthread_condattr_t
{
    byte[4] __opaque;
}

struct pthread_mutex_t
{
    byte[24] __opaque;
}

struct pthread_mutexattr_t
{
    byte[4] __opaque;
}

struct sched_param
{
    int sched_priority;
}

struct pthread_barrier_t
{
    byte[20] __opaque;
}

struct pthread_barrierattr_t
{
    byte[4] __opaque;
}

struct pthread_rwlock_t
{
    byte[32] __opaque;
}

struct pthread_rwlockattr_t
{
    byte[8] __opaque;
}

alias int pthread_spinlock_t;
enum
{
  PTHREAD_CANCEL_DEFERRED = 0,
  PTHREAD_CANCEL_ASYNCHRONOUS = 1,
  PTHREAD_CANCEL_ENABLE = 0,
  PTHREAD_CANCEL_DISABLE = 1,
}

alias uint socklen_t;
enum
{
  SOL_ATM = 264,
  SOL_PACKET = 263,
  SOL_IPV6 = 41,
  SOL_TCP = 6,
  SOL_X25 = 262,
  SOL_IP = 0,
  SOL_ICMPV6 = 58,
  SOL_SOCKET = 1,
  SOL_DECNET = 261,
  SOL_RAW = 255,
  SOL_IRDA = 266,
  SOL_AAL = 265,
}

enum
{
  SO_KEEPALIVE = 9,
  SO_PEERCRED = 17,
  SO_SECURITY_AUTHENTICATION = 22,
  SO_REUSEADDR = 2,
  SO_LINGER = 13,
  SO_BINDTODEVICE = 25,
  SO_SECURITY_ENCRYPTION_TRANSPORT = 23,
  SO_BROADCAST = 6,
  SO_ACCEPTCONN = 30,
  SO_TYPE = 3,
  SO_SECURITY_ENCRYPTION_NETWORK = 24,
  SO_DONTROUTE = 5,
  SO_PEERNAME = 28,
  SO_ATTACH_FILTER = 26,
  SO_PASSCRED = 16,
  SO_RCVLOWAT = 18,
  SO_SNDTIMEO = 21,
  SO_PEERSEC = 31,
  SO_OOBINLINE = 10,
  SO_NO_CHECK = 11,
  SO_SNDBUFFORCE = 32,
  SO_TIMESTAMP = 29,
  SO_DETACH_FILTER = 27,
  SO_SNDBUF = 7,
  SO_DEBUG = 1,
  SO_RCVBUF = 8,
  SO_RCVBUFFORCE = 33,
  SO_SNDLOWAT = 19,
  SO_ERROR = 4,
  SO_PRIORITY = 12,
  SO_RCVTIMEO = 20,
}

enum
{
  SOCK_RAW = 3,
  SOCK_RDM = 4,
  SOCK_SEQPACKET = 5,
  SOCK_DGRAM = 2,
  SOCK_PACKET = 10,
  SOCK_STREAM = 1,
}

enum
{
  MSG_NOSIGNAL = 16384,
  MSG_MORE = 32768,
  MSG_WAITALL = 256,
  MSG_PEEK = 2,
  MSG_ERRQUEUE = 8192,
  MSG_FIN = 512,
  MSG_CTRUNC = 8,
  MSG_PROXY = 16,
  MSG_DONTROUTE = 4,
  MSG_TRYHARD = 4,
  MSG_RST = 4096,
  MSG_CONFIRM = 2048,
  MSG_TRUNC = 32,
  MSG_OOB = 1,
  MSG_SYN = 1024,
  MSG_DONTWAIT = 64,
  MSG_EOR = 128,
}

static if (!is(typeof(MSG_NOSIGNAL))) enum { MSG_NOSIGNAL = 0 } // for std/socket.d
enum
{
  AF_MAX = 32,
  AF_APPLETALK = 5,
  AF_INET6 = 10,
  AF_NETLINK = 16,
  AF_FILE = 1,
  AF_ROSE = 11,
  AF_NETROM = 6,
  AF_ATMPVC = 8,
  AF_WANPIPE = 25,
  AF_UNSPEC = 0,
  AF_BRIDGE = 7,
  AF_X25 = 9,
  AF_BLUETOOTH = 31,
  AF_ROUTE = 16,
  AF_SECURITY = 14,
  AF_AX25 = 3,
  AF_KEY = 15,
  AF_ECONET = 19,
  AF_INET = 2,
  AF_ATMSVC = 20,
  AF_PPPOX = 24,
  AF_PACKET = 17,
  AF_IRDA = 23,
  AF_NETBEUI = 13,
  AF_SNA = 22,
  AF_LOCAL = 1,
  AF_ASH = 18,
  AF_UNIX = 1,
  AF_DECnet = 12,
  AF_IPX = 4,
}

enum
{
  PF_DECnet = 12,
  PF_SECURITY = 14,
  PF_BLUETOOTH = 31,
  PF_SNA = 22,
  PF_WANPIPE = 25,
  PF_UNIX = 1,
  PF_ASH = 18,
  PF_NETLINK = 16,
  PF_UNSPEC = 0,
  PF_X25 = 9,
  PF_BRIDGE = 7,
  PF_IPX = 4,
  PF_IRDA = 23,
  PF_MAX = 32,
  PF_ROSE = 11,
  PF_INET6 = 10,
  PF_FILE = 1,
  PF_KEY = 15,
  PF_ROUTE = 16,
  PF_NETBEUI = 13,
  PF_PPPOX = 24,
  PF_ECONET = 19,
  PF_AX25 = 3,
  PF_ATMSVC = 20,
  PF_PACKET = 17,
  PF_APPLETALK = 5,
  PF_NETROM = 6,
  PF_INET = 2,
  PF_ATMPVC = 8,
  PF_LOCAL = 1,
}

struct linger
{
    int l_onoff;
    int l_linger;
}

enum
{
  IPPROTO_IP = 0,
  IPPROTO_ROUTING = 43,
  IPPROTO_EGP = 8,
  IPPROTO_PIM = 103,
  IPPROTO_ENCAP = 98,
  IPPROTO_ESP = 50,
  IPPROTO_PUP = 12,
  IPPROTO_IDP = 22,
  IPPROTO_IPIP = 4,
  IPPROTO_TCP = 6,
  IPPROTO_IPV6 = 41,
  IPPROTO_SCTP = 132,
  IPPROTO_AH = 51,
  IPPROTO_MTP = 92,
  IPPROTO_TP = 29,
  IPPROTO_UDP = 17,
  IPPROTO_HOPOPTS = 0,
  IPPROTO_RAW = 255,
  IPPROTO_ICMP = 1,
  IPPROTO_GGP = 3,
  IPPROTO_FRAGMENT = 44,
  IPPROTO_GRE = 47,
  IPPROTO_DSTOPTS = 60,
  IPPROTO_NONE = 59,
  IPPROTO_RSVP = 46,
  IPPROTO_IGMP = 2,
  IPPROTO_ICMPV6 = 58,
  IPPROTO_COMP = 108,
}

enum
{
  IPV6_RTHDR_TYPE_0 = 0,
  IPV6_LEAVE_GROUP = 21,
  IPV6_PMTUDISC_WANT = 1,
  IPV6_NEXTHOP = 9,
  IPV6_2292HOPOPTS = 3,
  IPV6_HOPOPTS = 54,
  IPV6_2292DSTOPTS = 4,
  IPV6_MTU_DISCOVER = 23,
  IPV6_IPSEC_POLICY = 34,
  IPV6_AUTHHDR = 10,
  IPV6_ADD_MEMBERSHIP = 20,
  IPV6_DSTOPTS = 59,
  IPV6_2292PKTOPTIONS = 6,
  IPV6_RECVHOPOPTS = 53,
  IPV6_XFRM_POLICY = 35,
  IPV6_RXHOPOPTS = 54,
  IPV6_UNICAST_HOPS = 16,
  IPV6_V6ONLY = 26,
  IPV6_RECVRTHDR = 56,
  IPV6_RECVHOPLIMIT = 51,
  IPV6_RECVTCLASS = 66,
  IPV6_RTHDR_STRICT = 1,
  IPV6_MTU = 24,
  IPV6_RECVDSTOPTS = 58,
  IPV6_MULTICAST_IF = 17,
  IPV6_RECVERR = 25,
  IPV6_RXDSTOPTS = 59,
  IPV6_2292PKTINFO = 2,
  IPV6_MULTICAST_HOPS = 18,
  IPV6_HOPLIMIT = 52,
  IPV6_PMTUDISC_DO = 2,
  IPV6_PKTINFO = 50,
  IPV6_RTHDRDSTOPTS = 55,
  IPV6_JOIN_ANYCAST = 27,
  IPV6_TCLASS = 67,
  IPV6_2292RTHDR = 5,
  IPV6_RTHDR_LOOSE = 0,
  IPV6_ADDRFORM = 1,
  IPV6_JOIN_GROUP = 20,
  IPV6_RTHDR = 57,
  IPV6_RECVPKTINFO = 49,
  IPV6_DROP_MEMBERSHIP = 21,
  IPV6_ROUTER_ALERT = 22,
  IPV6_MULTICAST_LOOP = 19,
  IPV6_2292HOPLIMIT = 8,
  IPV6_LEAVE_ANYCAST = 28,
  IPV6_PMTUDISC_DONT = 0,
  IPV6_CHECKSUM = 7,
}

enum : uint
{
  INADDR_ALLRTRS_GROUP = -536870910,
  INADDR_MAX_LOCAL_GROUP = -536870657,
  INADDR_ALLHOSTS_GROUP = -536870911,
  INADDR_ANY = 0,
  INADDR_UNSPEC_GROUP = -536870912,
  INADDR_NONE = -1,
  INADDR_LOOPBACK = 2130706433,
  INADDR_BROADCAST = -1,
}

enum { ADDR_ANY = INADDR_ANY }
enum
{
  TCP_KEEPCNT = 6,
  TCP_CORK = 3,
  TCP_WINDOW_CLAMP = 10,
  TCP_MSS = 512,
  TCP_DEFER_ACCEPT = 9,
  TCP_KEEPIDLE = 4,
  TCP_MAX_WINSHIFT = 14,
  TCP_SYNCNT = 7,
  TCP_MAXSEG = 2,
  TCP_QUICKACK = 12,
  TCP_MAXWIN = 65535,
  TCP_KEEPINTVL = 5,
  TCP_INFO = 11,
  TCP_LINGER2 = 8,
  TCP_NODELAY = 1,
}

struct in_addr
{
    uint s_addr;
}

struct sockaddr
{
    ushort sa_family;
    byte[14] sa_data;
}

struct sockaddr_in
{
    ushort sin_family = AF_INET;
    ushort sin_port;
    in_addr sin_addr;
    ubyte[8] sin_zero;
}

struct protoent
{
    char* p_name;
    char** p_aliases;
    int p_proto;
}

struct servent
{
    char* s_name;
    char** s_aliases;
    int s_port;
    char* s_proto;
}

struct hostent
{
    char* h_name;
    char** h_aliases;
    int h_addrtype;
    int h_length;
    char** h_addr_list;

  char* h_addr()
  {
      return h_addr_list[0];
  }

}

struct addrinfo { }
struct passwd
{
    char* pw_name;
    char* pw_passwd;
    uint pw_uid;
    uint pw_gid;
    char* pw_gecos;
    char* pw_dir;
    char* pw_shell;
}

