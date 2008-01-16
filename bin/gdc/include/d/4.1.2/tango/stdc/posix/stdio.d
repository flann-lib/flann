/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.stdio;

private import tango.stdc.posix.config;
public import tango.stdc.stdio;
public import tango.stdc.posix.sys.types; // for off_t

extern (C):

//
// Required (defined in tango.stdc.stdio)
//
/*
BUFSIZ
_IOFBF
_IOLBF
_IONBF
L_tmpnam
SEEK_CUR
SEEK_END
SEEK_SET
FILENAME_MAX
FOPEN_MAX
TMP_MAX
EOF
NULL
stderr
stdin
stdout
FILE
fpos_t
size_t

void   clearerr(FILE*);
int    fclose(FILE*);
int    feof(FILE*);
int    ferror(FILE*);
int    fflush(FILE*);
int    fgetc(FILE*);
int    fgetpos(FILE*, fpos_t *);
char*  fgets(char*, int, FILE*);
FILE*  fopen(char*, char*);
int    fprintf(FILE*, char*, ...);
int    fputc(int, FILE*);
int    fputs(char*, FILE*);
size_t fread(void *, size_t, size_t, FILE*);
FILE*  freopen(char*, char*, FILE*);
int    fscanf(FILE*, char*, ...);
int    fseek(FILE*, c_long, int);
int    fsetpos(FILE*, fpos_t *);
c_long ftell(FILE*);
size_t fwrite(void *, size_t, size_t, FILE*);
int    getc(FILE*);
int    getchar();
char*  gets(char*);
void   perror(char*);
int    printf(char*, ...);
int    putc(int, FILE*);
int    putchar(int);
int    puts(char*);
int    remove(char*);
int    rename(char*, char*);
void   rewind(FILE*);
int    scanf(char*, ...);
void   setbuf(FILE*, char*);
int    setvbuf(FILE*, char*, int, size_t);
int    snprintf(char*, size_t, char*, ...);
int    sprintf(char*, char*, ...);
int    sscanf(char*, char*, int ...);
FILE*  tmpfile();
char*  tmpnam(char*);
int    ungetc(int, FILE*);
int    vfprintf(FILE*, char*, va_list);
int    vfscanf(FILE*, char*, va_list);
int    vprintf(char*, va_list);
int    vscanf(char*, va_list);
int    vsnprintf(char*, size_t, char*, va_list);
int    vsprintf(char*, char*, va_list);
int    vsscanf(char*, char*, va_list arg);
*/

//
// C Extension (CX)
//
/*
L_ctermid

char*  ctermid(char*);
FILE*  fdopen(int, char*);
int    fileno(FILE*);
int    fseeko(FILE*, off_t, int);
off_t  ftello(FILE*);
char*  gets(char*);
FILE*  popen(char*, char*);
*/

version( linux )
{
    const L_ctermid = 9;
}

char*  ctermid(char*);
FILE*  fdopen(int, char*);
int    fileno(FILE*);
int    fseeko(FILE*, off_t, int);
off_t  ftello(FILE*);
char*  gets(char*);
FILE*  popen(char*, char*);

//
// Thread-Safe Functions (TSF)
//
/*
void   flockfile(FILE*);
int    ftrylockfile(FILE*);
void   funlockfile(FILE*);
int    getc_unlocked(FILE*);
int    getchar_unlocked();
int    putc_unlocked(int, FILE*);
int    putchar_unlocked(int);
*/

version( linux )
{
    void   flockfile(FILE*);
    int    ftrylockfile(FILE*);
    void   funlockfile(FILE*);
    int    getc_unlocked(FILE*);
    int    getchar_unlocked();
    int    putc_unlocked(int, FILE*);
    int    putchar_unlocked(int);
}

//
// XOpen (XSI)
//
/*
P_tmpdir
va_list (defined in tango.stdc.stdarg)

char*  tempnam(char*, char*);
*/

version( linux )
{
    const P_tmpdir  = "/tmp";

    char*  tempnam(char*, char*);
}
