/* GDC -- D front-end for GCC
   Copyright (C) 2004 David Friedman
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
 
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
 
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

module std.c.unix.unix;

/* This module imports the unix module for the currect
   target system.  Currently, all targets can be
   handled with the autoconf'd version. */

public import gcc.config.libc : tm, time_t;
private import gcc.config.libc : Clong_t, Culong_t;
public import gcc.config.unix;
public import gcc.config.errno;

extern (C):

// DMD linux.d has dirent.h declarations
public import std.c.dirent;
int dirfd(DIR*);

public import std.c.stdio;
int fseeko(FILE*, off_t, int);
off_t ftello(FILE*);

int open(in char*, int, ...);
ssize_t read(int, void*, size_t);
ssize_t write(int, in void*, size_t);
int close(int);
off_t lseek(int, off_t, int);
int access(in char *path, int mode);
int utime(char *path, utimbuf *buf);
int fstat(int, struct_stat*);
int stat(in char*, struct_stat*);
int	lstat(in char *, struct_stat *);
int	chmod(in char *, mode_t);
int chdir(in char*);
int mkdir(in char*, mode_t);
int rmdir(in char*);
char* getcwd(char*, size_t);

pid_t fork();
int dup(int);
int dup2(int, int);
int pipe(int[2]);
pid_t wait(int*);
pid_t waitpid(pid_t, int*, int);
int kill(pid_t, int);

int gettimeofday(timeval*, void*);
int settimeofday(in timeval *, in void *);
time_t time(time_t*);
tm *localtime(time_t*);

int sem_init (sem_t *, int, uint);
int sem_destroy (sem_t *);
sem_t * sem_open (char *, int, ...);
int sem_close(sem_t *);
int sem_wait(sem_t*);
int sem_post(sem_t*);
int sem_trywait(sem_t*);
int sem_getvalue(sem_t*, int*);

int sigemptyset(sigset_t*);
int sigfillset(sigset_t*);
int sigdelset(sigset_t*, int);
int sigismember(sigset_t *set, int);
int sigaction(int, sigaction_t*, sigaction_t*);
int sigsuspend(sigset_t*);

Clong_t sysconf(int name);

// version ( Unix_Pthread )...
int pthread_attr_init(pthread_attr_t *);
int pthread_attr_destroy(pthread_attr_t *);
int pthread_attr_setdetachstate(pthread_attr_t *, int);
int pthread_attr_getdetachstate(pthread_attr_t *, int *);
int pthread_attr_setguardsize(pthread_attr_t*, size_t);
int pthread_attr_getguardsize(pthread_attr_t*, size_t *);
int pthread_attr_setinheritsched(pthread_attr_t *, int);
int pthread_attr_getinheritsched(pthread_attr_t *, int *);
int pthread_attr_setschedparam(pthread_attr_t *, sched_param *);
int pthread_attr_getschedparam(pthread_attr_t *, sched_param *);
int pthread_attr_setschedpolicy(pthread_attr_t *, int);
int pthread_attr_getschedpolicy(pthread_attr_t *, int*);
int pthread_attr_setscope(pthread_attr_t *, int);
int pthread_attr_getscope(pthread_attr_t *, int*);
int pthread_attr_setstack(pthread_attr_t *, void*, size_t);
int pthread_attr_getstack(pthread_attr_t *, void**, size_t *);
int pthread_attr_setstackaddr(pthread_attr_t *, void *);
int pthread_attr_getstackaddr(pthread_attr_t *, void **);
int pthread_attr_setstacksize(pthread_attr_t *, size_t);
int pthread_attr_getstacksize(pthread_attr_t *, size_t *);

int pthread_create(pthread_t*, pthread_attr_t*, void* (*)(void*), void*);
int pthread_join(pthread_t, void**);
int pthread_kill(pthread_t, int);
pthread_t pthread_self();
int pthread_equal(pthread_t, pthread_t);
int pthread_suspend_np(pthread_t);
int pthread_continue_np(pthread_t);
int pthread_cancel(pthread_t);
int pthread_setcancelstate(int state, int *oldstate);
int pthread_setcanceltype(int type, int *oldtype);
void pthread_testcancel();    
int pthread_detach(pthread_t);
void pthread_exit(void*);
int pthread_getattr_np(pthread_t, pthread_attr_t*);
int pthread_getconcurrency();
int pthread_getcpuclockid(pthread_t, clockid_t*);

int pthread_cond_init(pthread_cond_t *, pthread_condattr_t *);
int pthread_cond_destroy(pthread_cond_t *);
int pthread_cond_signal(pthread_cond_t *);
int pthread_cond_broadcast(pthread_cond_t *);
int pthread_cond_wait(pthread_cond_t *, pthread_mutex_t *);
int pthread_cond_timedwait(pthread_cond_t *, pthread_mutex_t *, timespec *);
int pthread_condattr_init(pthread_condattr_t *);
int pthread_condattr_destroy(pthread_condattr_t *);
int pthread_condattr_getpshared(pthread_condattr_t *, int *);
int pthread_condattr_setpshared(pthread_condattr_t *, int);

int pthread_mutex_init(pthread_mutex_t *, pthread_mutexattr_t *);
int pthread_mutex_lock(pthread_mutex_t *);
int pthread_mutex_trylock(pthread_mutex_t *);
int pthread_mutex_unlock(pthread_mutex_t *);
int pthread_mutex_destroy(pthread_mutex_t *);
int pthread_mutexattr_init(pthread_mutexattr_t *);
int pthread_mutexattr_destroy(pthread_mutexattr_t *);
int pthread_mutexattr_getpshared(pthread_mutexattr_t *, int *);
int pthread_mutexattr_setpshared(pthread_mutexattr_t *, int);

int pthread_barrierattr_init(pthread_barrierattr_t*);
int pthread_barrierattr_getpshared(pthread_barrierattr_t*, int*);
int pthread_barrierattr_destroy(pthread_barrierattr_t*);
int pthread_barrierattr_setpshared(pthread_barrierattr_t*, int);

int pthread_barrier_init(pthread_barrier_t*, pthread_barrierattr_t*, uint);
int pthread_barrier_destroy(pthread_barrier_t*);
int pthread_barrier_wait(pthread_barrier_t*);

// version ( Unix_Sched )
void sched_yield();

// from <sys/mman.h>
void* mmap(void* addr, size_t len, int prot, int flags, int fd, off_t offset);
int munmap(void* addr, size_t len);
int msync(void* start, size_t length, int flags);
int madvise(void*, size_t, int);
int mlock(void*, size_t);
int munlock(void*, size_t);
int mlockall(int);
int munlockall();
void* mremap(void*, size_t, size_t, Culong_t); // Linux specific
int mincore(void*, size_t, ubyte*);
int remap_file_pages(void*, size_t, int, ssize_t, int); // Linux specific
int shm_open(in char*, int, mode_t);
int shm_unlink(in char*);

// from <fcntl.h>
int fcntl(int fd, int cmd, ...);

int select(int n, fd_set *, fd_set *, fd_set *, timeval *);

// could probably rewrite fd_set stuff in D, but for now...
private void _d_gnu_fd_set(int n, fd_set * p);
private void _d_gnu_fd_clr(int n, fd_set * p);
private int  _d_gnu_fd_isset(int n, fd_set * p);
private void _d_gnu_fd_copy(fd_set * f, fd_set * t);
private void _d_gnu_fd_zero(fd_set * p);
// maybe these should go away in favor of fd_set methods
version (none)
{
    void FD_SET(int n, inout fd_set p) { return _d_gnu_fd_set(n, & p); }
    void FD_CLR(int n, inout fd_set p) { return _d_gnu_fd_clr(n, & p); }
    int FD_ISSET(int n, inout fd_set p) { return _d_gnu_fd_isset(n, & p); }
    void FD_COPY(inout fd_set f, inout fd_set t) { return _d_gnu_fd_copy(& f, & t); }
    void FD_ZERO(inout fd_set p) { return _d_gnu_fd_zero(& p); }
}
void FD_SET(int n,  fd_set * p) { return _d_gnu_fd_set(n, p); }
void FD_CLR(int n,  fd_set * p) { return _d_gnu_fd_clr(n, p); }
int FD_ISSET(int n, fd_set * p) { return _d_gnu_fd_isset(n, p); }
void FD_COPY(fd_set * f, inout fd_set * t) { return _d_gnu_fd_copy(f, t); }
void FD_ZERO(fd_set * p) { return _d_gnu_fd_zero(p); }

// from <pwd.h>
passwd *getpwnam(in char *name);
passwd *getpwuid(uid_t uid);
int getpwnam_r(char *name, passwd *pwbuf, char *buf, size_t buflen, passwd **pwbufp);
int getpwuid_r(uid_t uid, passwd *pwbuf, char *buf, size_t buflen, passwd **pwbufp);

// std/socket.d
enum: int
{
    SD_RECEIVE =  0,
    SD_SEND =     1,
    SD_BOTH =     2,
}

int socket(int af, int type, int protocol);
int bind(int s, sockaddr* name, int namelen);
int connect(int s, sockaddr* name, int namelen);
int listen(int s, int backlog);
int accept(int s, sockaddr* addr, int* addrlen);
int shutdown(int s, int how);
int getpeername(int s, sockaddr* name, int* namelen);
int getsockname(int s, sockaddr* name, int* namelen);
ssize_t send(int s, void* buf, size_t len, int flags);
ssize_t sendto(int s, void* buf, size_t len, int flags, sockaddr* to, int tolen);
ssize_t recv(int s, void* buf, size_t len, int flags);
ssize_t recvfrom(int s, void* buf, size_t len, int flags, sockaddr* from, int* fromlen);
int getsockopt(int s, int level, int optname, void* optval, int* optlen);
int setsockopt(int s, int level, int optname, void* optval, int optlen);
uint inet_addr(char* cp);
char* inet_ntoa(in_addr ina);
hostent* gethostbyname(char* name);
int gethostbyname_r(char* name, hostent* ret, void* buf, size_t buflen, hostent** result, int* h_errnop);
int gethostbyname2_r(char* name, int af, hostent* ret, void* buf, size_t buflen, hostent** result, int* h_errnop);
hostent* gethostbyaddr(void* addr, int len, int type);
protoent* getprotobyname(char* name);
protoent* getprotobynumber(int number);
servent* getservbyname(char* name, char* proto);
servent* getservbyport(int port, char* proto);
int gethostname(char* name, int namelen);
int getaddrinfo(char* nodename, char* servname, addrinfo* hints, addrinfo** res);
void freeaddrinfo(addrinfo* ai);
int getnameinfo(sockaddr* sa, socklen_t salen, char* node, socklen_t nodelen, char* service, socklen_t servicelen, int flags);

private import std.stdint;

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
		return (x >> 8) | (x << 8);
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

alias htons ntohs;
alias htonl ntohl;

// from <time.h>
char* asctime_r(in tm* t, char* buf);
char* ctime_r(in time_t* timep, char* buf);
tm* gmtime_r(in time_t* timep, tm* result);
tm* localtime_r(in time_t* timep, tm* result);

// misc.
uint alarm(uint);
char* basename(char*);
//wint_t btowc(int);
int chown(in char*, uid_t, gid_t);
int chroot(in char*);
size_t confstr(int, char*, size_t);
int creat(in char*, mode_t);
char* ctermid(char*);
char* dirname(char*);
int fattach(int, char*);
int fchmod(int, mode_t);
int fdatasync(int);
int ffs(int);
int fmtmsg(int, char*, int, char*, char*, char*);
int fpathconf(int, int);

extern char** environ;
