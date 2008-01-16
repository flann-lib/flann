/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.stdlib;

private import tango.stdc.posix.config;
public import tango.stdc.stdlib;
public import tango.stdc.posix.sys.wait;

extern (C):

//
// Required (defined in tango.stdc.stdlib)
//
/*
EXIT_FAILURE
EXIT_SUCCESS
NULL
RAND_MAX
MB_CUR_MAX
div_t
ldiv_t
lldiv_t
size_t
wchar_t

void    _Exit(int);
void    abort();
int     abs(int);
int     atexit(void function());
double  atof(char*);
int     atoi(char*);
c_long  atol(char*);
long    atoll(char*);
void*   bsearch(void*, void*, size_t, size_t, int function(void*, void*));
void*   calloc(size_t, size_t);
div_t   div(int, int);
void    exit(int);
void    free(void*);
char*   getenv(char*);
c_long  labs(c_long);
ldiv_t  ldiv(c_long, c_long);
long    llabs(long);
lldiv_t lldiv(long, long);
void*   malloc(size_t);
int     mblen(char*, size_t);
size_t  mbstowcs(wchar_t*, char*, size_t);
int     mbtowc(wchar_t*, char*, size_t);
void    qsort(void*, size_t, size_t, int function(void*, void*));
int     rand();
void*   realloc(void*, size_t);
void    srand(uint);
double  strtod(char*, char**);
float   strtof(char*, char**);
c_long  strtol(char*, char**, int);
real    strtold(char*, char**);
long    strtoll(char*, char**, int);
c_ulong strtoul(char*, char**, int);
ulong   strtoull(char*, char**, int);
int     system(char*);
size_t  wcstombs(char*, wchar_t*, size_t);
int     wctomb(char*, wchar_t);
*/

//
// Advisory Information (ADV)
//
/*
int posix_memalign(void**, size_t, size_t);
*/

version( linux )
{
    int posix_memalign(void**, size_t, size_t);
}

//
// C Extension (CX)
//
/*
int setenv(char*, char*, int);
int unsetenv(char*);
*/

version( linux )
{
    int setenv(char*, char*, int);
    int unsetenv(char*);

    void* valloc(size_t); // LEGACY non-standard
}
else version( darwin )
{
    int setenv(char*, char*, int);
    int unsetenv(char*);

    void* valloc(size_t); // LEGACY non-standard
}

//
// Thread-Safe Functions (TSF)
//
/*
int rand_r(uint*);
*/

version( linux )
{
    int rand_r(uint*);
}
else version( darwin )
{
    int rand_r(uint*);
}

//
// XOpen (XSI)
//
/*
WNOHANG     (defined in tango.stdc.posix.sys.wait)
WUNTRACED   (defined in tango.stdc.posix.sys.wait)
WEXITSTATUS (defined in tango.stdc.posix.sys.wait)
WIFEXITED   (defined in tango.stdc.posix.sys.wait)
WIFSIGNALED (defined in tango.stdc.posix.sys.wait)
WIFSTOPPED  (defined in tango.stdc.posix.sys.wait)
WSTOPSIG    (defined in tango.stdc.posix.sys.wait)
WTERMSIG    (defined in tango.stdc.posix.sys.wait)

c_long a64l(char*);
double drand48();
char*  ecvt(double, int, int *, int *); // LEGACY
double erand48(ushort[3]);
char*  fcvt(double, int, int *, int *); // LEGACY
char*  gcvt(double, int, char*); // LEGACY
int    getsubopt(char**, char**, char**);
int    grantpt(int);
char*  initstate(uint, char*, size_t);
c_long jrand48(ushort[3]);
char*  l64a(c_long);
void   lcong48(ushort[7]);
c_long lrand48();
char*  mktemp(char*); // LEGACY
int    mkstemp(char*);
c_long mrand48();
c_long nrand48(ushort[3]);
int    posix_openpt(int);
char*  ptsname(int);
int    putenv(char*);
c_long random();
char*  realpath(char*, char*);
ushort seed48(ushort[3]);
void   setkey(char*);
char*  setstate(char*);
void   srand48(c_long);
void   srandom(uint);
int    unlockpt(int);
*/

version( linux )
{
    //WNOHANG     (defined in tango.stdc.posix.sys.wait)
    //WUNTRACED   (defined in tango.stdc.posix.sys.wait)
    //WEXITSTATUS (defined in tango.stdc.posix.sys.wait)
    //WIFEXITED   (defined in tango.stdc.posix.sys.wait)
    //WIFSIGNALED (defined in tango.stdc.posix.sys.wait)
    //WIFSTOPPED  (defined in tango.stdc.posix.sys.wait)
    //WSTOPSIG    (defined in tango.stdc.posix.sys.wait)
    //WTERMSIG    (defined in tango.stdc.posix.sys.wait)

    c_long a64l(char*);
    double drand48();
    char*  ecvt(double, int, int *, int *); // LEGACY
    double erand48(ushort[3]);
    char*  fcvt(double, int, int *, int *); // LEGACY
    char*  gcvt(double, int, char*); // LEGACY
    int    getsubopt(char**, char**, char**);
    int    grantpt(int);
    char*  initstate(uint, char*, size_t);
    c_long jrand48(ushort[3]);
    char*  l64a(c_long);
    void   lcong48(ushort[7]);
    c_long lrand48();
    char*  mktemp(char*); // LEGACY
    int    mkstemp(char*);
    c_long mrand48();
    c_long nrand48(ushort[3]);
    int    posix_openpt(int);
    char*  ptsname(int);
    int    putenv(char*);
    c_long random();
    char*  realpath(char*, char*);
    ushort seed48(ushort[3]);
    void   setkey(char*);
    char*  setstate(char*);
    void   srand48(c_long);
    void   srandom(uint);
    int    unlockpt(int);
}
else version( darwin )
{
    //WNOHANG     (defined in tango.stdc.posix.sys.wait)
    //WUNTRACED   (defined in tango.stdc.posix.sys.wait)
    //WEXITSTATUS (defined in tango.stdc.posix.sys.wait)
    //WIFEXITED   (defined in tango.stdc.posix.sys.wait)
    //WIFSIGNALED (defined in tango.stdc.posix.sys.wait)
    //WIFSTOPPED  (defined in tango.stdc.posix.sys.wait)
    //WSTOPSIG    (defined in tango.stdc.posix.sys.wait)
    //WTERMSIG    (defined in tango.stdc.posix.sys.wait)

    c_long a64l(char*);
    double drand48();
    char*  ecvt(double, int, int *, int *); // LEGACY
    double erand48(ushort[3]);
    char*  fcvt(double, int, int *, int *); // LEGACY
    char*  gcvt(double, int, char*); // LEGACY
    int    getsubopt(char**, char**, char**);
    int    grantpt(int);
    char*  initstate(uint, char*, size_t);
    c_long jrand48(ushort[3]);
    char*  l64a(c_long);
    void   lcong48(ushort[7]);
    c_long lrand48();
    char*  mktemp(char*); // LEGACY
    int    mkstemp(char*);
    c_long mrand48();
    c_long nrand48(ushort[3]);
    int    posix_openpt(int);
    char*  ptsname(int);
    int    putenv(char*);
    c_long random();
    char*  realpath(char*, char*);
    ushort seed48(ushort[3]);
    void   setkey(char*);
    char*  setstate(char*);
    void   srand48(c_long);
    void   srandom(uint);
    int    unlockpt(int);
}
