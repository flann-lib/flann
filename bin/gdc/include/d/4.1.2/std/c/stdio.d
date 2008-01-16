
/**
 * C's &lt;stdio.h&gt;
 * Authors: Walter Bright, Digital Mars, www.digitalmars.com
 * License: Public Domain
 * Macros:
 *	WIKI=Phobos/StdCStdio
 */

/* NOTE: This file has been patched from the original DMD distribution to
   work with the GDC compiler.

   Modified by David Friedman, September 2004
*/



module std.c.stdio;

private import std.stdint;
import std.c.stddef;
private import std.c.stdarg;

extern (C):

version (GNU)
{
    private import gcc.builtins;
    private import gcc.config.libc;
    alias gcc.config.libc.EOF EOF;
    alias gcc.config.libc.FOPEN_MAX FOPEN_MAX;
    alias gcc.config.libc.FILENAME_MAX FILENAME_MAX;
    alias gcc.config.libc.TMP_MAX TMP_MAX;
    alias gcc.config.libc.L_tmpnam L_tmpnam;
}
else version (Win32)
{
    const int _NFILE = 60;	///
    const int BUFSIZ = 0x4000;	///
    const int EOF = -1;		///
    const int FOPEN_MAX = 20;	///
    const int FILENAME_MAX = 256;  /// 255 plus NULL
    const int TMP_MAX = 32767;	///
    const int _SYS_OPEN = 20;	///
    const int SYS_OPEN = _SYS_OPEN;	///
    const wchar WEOF = 0xFFFF;		///
}
else version (linux)
{
    const int EOF = -1;
    const int FOPEN_MAX = 16;
    const int FILENAME_MAX = 4095;
    const int TMP_MAX = 238328;
    const int L_tmpnam = 20;
}

enum { SEEK_SET, SEEK_CUR, SEEK_END }

struct _iobuf
{
    align (1):
    version (Win32)
    {
	char	*_ptr;
	int	_cnt;
	char	*_base;
	int	_flag;
	int	_file;
	int	_charbuf;
	int	_bufsiz;
	int	__tmpnum;
    }
    else version (linux)
    {
	char*	_read_ptr;
	char*	_read_end;
	char*	_read_base;
	char*	_write_base;
	char*	_write_ptr;
	char*	_write_end;
	char*	_buf_base;
	char*	_buf_end;
	char*	_save_base;
	char*	_backup_base;
	char*	_save_end;
	void*	_markers;
	_iobuf*	_chain;
	int	_fileno;
	int	_blksize;
	int	_old_offset;
	ushort	_cur_column;
	byte	_vtable_offset;
	char[1]	_shortbuf;
	void*	_lock;
    }
    else version (GNU) {
	byte[gcc.config.libc.FILE_struct_size] opaque;
    }
    
}

alias _iobuf FILE;	///

enum
{
    _F_RDWR = 0x0003,
    _F_READ = 0x0001,
    _F_WRIT = 0x0002,
    _F_BUF  = 0x0004,
    _F_LBUF = 0x0008,
    _F_ERR  = 0x0010,
    _F_EOF  = 0x0020,
    _F_BIN  = 0x0040,
    _F_IN   = 0x0080,
    _F_OUT  = 0x0100,
    _F_TERM = 0x0200,
}

version (Win32)
{
    version (GNU) {
	// _NFILE is not defined anywhere
	extern export FILE _iob[5];
    } else {
	extern FILE _iob[_NFILE];
	extern void function() _fcloseallp;
	extern ubyte __fhnd_info[_NFILE];

	enum
	{
	    FHND_APPEND	= 0x04,
	    FHND_DEVICE	= 0x08,
	    FHND_TEXT	= 0x10,
	    FHND_BYTE	= 0x20,
	    FHND_WCHAR	= 0x40,
	}
    }
}

version (Win32)
{
    enum
    {
	    _IOREAD	= 1,
	    _IOWRT	= 2,
	    _IONBF	= 4,
	    _IOMYBUF	= 8,
	    _IOEOF	= 0x10,
	    _IOERR	= 0x20,
	    _IOLBF	= 0x40,
	    _IOSTRG	= 0x40,
	    _IORW	= 0x80,
	    _IOFBF	= 0,
	    _IOAPP	= 0x200,
	    _IOTRAN	= 0x100,
    }
}

version (linux)
{
    enum
    {
	    _IOFBF = 0,
	    _IOLBF = 1,
	    _IONBF = 2,
    }
}


version (GNU_CBridge_Stdio)
{
    extern FILE * _d_gnu_cbridge_stdin;
    extern FILE * _d_gnu_cbridge_stdout;
    extern FILE * _d_gnu_cbridge_stderr;

    /* Call from dgccmain2.  Can't use a static constructor here
       because std.c.stdio is not compiled. */
    extern void _d_gnu_cbridge_init_stdio();
    
    alias _d_gnu_cbridge_stdin stdin;
    alias _d_gnu_cbridge_stdout stdout;
    alias _d_gnu_cbridge_stderr stderr;
}
else version (Win32)
{
    // This works for DMD/DMC and MinGW/msvcrt
    const FILE *stdin  = &_iob[0];	///
    const FILE *stdout = &_iob[1];	///
    const FILE *stderr = &_iob[2];	///
    const FILE *stdaux = &_iob[3];	///
    const FILE *stdprn = &_iob[4];	///
}
else version (aix)
{
    // 32- and 64-bit
    extern FILE _iob[16];
    const FILE *stdin  = &_iob[0];
    const FILE *stdout = &_iob[1];
    const FILE *stderr = &_iob[2];
}
else version (darwin)
{
    static if (size_t.sizeof == 4)
    {
	static assert(gcc.config.libc.FILE_struct_size != 0);
	extern FILE __sF[3];
	const FILE * stdin  = &__sF[0];
	const FILE * stdout = &__sF[1];
	const FILE * stderr = &__sF[2];
    }
    else static if (size_t.sizeof == 8)
    {
	extern FILE *__stdinp;
	extern FILE *__stdoutp;
	extern FILE *__stderrp;
	alias __stdinp  stdin;
	alias __stdoutp stdout;
	alias __stderrp stderr;
    }
}
else version (linux)
{
    extern FILE *stdin;
    extern FILE *stdout;
    extern FILE *stderr;
}

version (Win32)
{
    const char[] _P_tmpdir = "\\";
    const wchar[] _wP_tmpdir = "\\";
    version (GNU) { }
    else
    {
	const int L_tmpnam = _P_tmpdir.length + 12;
    }
}


alias gcc.config.libc.fpos_t fpos_t;

char *	 tmpnam(char *);	///
FILE *	 fopen(char *,char *);	///
FILE *	 _fsopen(char *,char *,int );	///
FILE *	 freopen(char *,char *,FILE *);	///
int	 fseek(FILE *,Clong_t,int);	///
Clong_t  ftell(FILE *);	///
char *	 fgets(char *,int,FILE *);	///
int	 fgetc(FILE *);	///
int	 _fgetchar();	///
int	 fflush(FILE *);	///
int	 fclose(FILE *);	///
int	 fputs(char *,FILE *);	///
char *	 gets(char *);	///
int	 fputc(int,FILE *);	///
int	 _fputchar(int);	///
int	 puts(char *);	///
int	 ungetc(int,FILE *);	///
size_t	 fread(void *,size_t,size_t,FILE *);	///
size_t	 fwrite(void *,size_t,size_t,FILE *);	///
//int	 printf(char *,...);	///
int	 fprintf(FILE *,char *,...);	///
int	 vfprintf(FILE *,char *,va_list);	///
int	 vprintf(char *,va_list);	///
int	 sprintf(char *,char *,...);	///
int	 vsprintf(char *,char *,va_list);	///
int	 scanf(char *,...);	///
int	 fscanf(FILE *,char *,...);	///
int	 sscanf(char *,char *,...);	///
void	 setbuf(FILE *,char *);	///
int	 setvbuf(FILE *,char *,int,size_t);	///
int	 remove(char *);	///
int	 rename(char *,char *);	///
void	 perror(char *);	///
int	 fgetpos(FILE *,fpos_t *);	///
int	 fsetpos(FILE *,fpos_t *);	///
FILE *	 tmpfile();	///
int	 _rmtmp();
int      _fillbuf(FILE *);
int      _flushbu(int, FILE *);

int  getw(FILE *FHdl);	///
int  putw(int Word, FILE *FilePtr);	///

int  getchar(); ///
int  putchar(int c); ///
int  getc(FILE *fp); ///
int  putc(int c,FILE *fp); ///

version(PPC)
    version(Linux)
	version=PPCLinux;

version (Win32)
{
    ///
    int  ferror(FILE *fp)	{ return fp._flag&_IOERR;	}
    ///
    int  feof(FILE *fp)	{ return fp._flag&_IOEOF;	}
    ///
    void clearerr(FILE *fp)	{ fp._flag &= ~(_IOERR|_IOEOF); }
    ///
    void rewind(FILE *fp)	{ fseek(fp,0L,SEEK_SET); fp._flag&=~_IOERR; }
    int  _bufsize(FILE *fp)	{ return fp._bufsiz; }
    ///
    int  fileno(FILE *fp)	{ return fp._file; }
    int  _snprintf(char *,size_t,char *,...);
    int  _vsnprintf(char *,size_t,char *,va_list);
}
else version (darwin)
{
    private import std.c.darwin.ldblcompat;
    
    extern (C) int ferror(FILE *);
    extern (C) int feof(FILE *);
    extern (C) void clearerr(FILE *);
    extern (C) void rewind(FILE *);
    extern (C) int _bufsize(FILE *);
    extern (C) int fileno(FILE *);
   
    int snprintf(char *, size_t, char *, ...);
    int vsnprintf(char *, size_t, char *, va_list);

    // printf is declared in object, but it won't be fixed unless std.c.stdio is imported...
    pragma(GNU_asm,printf,"printf" ~ __DARWIN_LDBL_COMPAT);
    pragma(GNU_asm,fprintf,"fprintf" ~ __DARWIN_LDBL_COMPAT);
    pragma(GNU_asm,vfprintf,"vfprintf" ~ __DARWIN_LDBL_COMPAT);
    pragma(GNU_asm,vprintf,"vprintf" ~ __DARWIN_LDBL_COMPAT);
    pragma(GNU_asm,sprintf,"sprintf" ~ __DARWIN_LDBL_COMPAT);
    pragma(GNU_asm,vsprintf,"vsprintf" ~ __DARWIN_LDBL_COMPAT);
    pragma(GNU_asm,scanf,"scanf" ~ __DARWIN_LDBL_COMPAT);
    pragma(GNU_asm,fscanf,"fscanf" ~ __DARWIN_LDBL_COMPAT);
    pragma(GNU_asm,sscanf,"sscanf" ~ __DARWIN_LDBL_COMPAT);
    pragma(GNU_asm,snprintf,"snprintf" ~ __DARWIN_LDBL_COMPAT);
    pragma(GNU_asm,vsnprintf,"vsnprintf" ~ __DARWIN_LDBL_COMPAT);
}
else version (PPCLinux)
{
    private import std.c.linux.ldblcompat;
    
    extern (C) int ferror(FILE *);
    extern (C) int feof(FILE *);
    extern (C) void clearerr(FILE *);
    extern (C) void rewind(FILE *);
    extern (C) int _bufsize(FILE *);
    extern (C) int fileno(FILE *);
   
    int snprintf(char *, size_t, char *, ...);
    int vsnprintf(char *, size_t, char *, va_list);

    // printf is declared in object, but it won't be fixed unless std.c.stdio is imported...
    pragma(GNU_asm,printf,__LDBL_COMPAT_PFX ~ "printf");
    pragma(GNU_asm,fprintf,__LDBL_COMPAT_PFX ~ "fprintf");
    pragma(GNU_asm,vfprintf,__LDBL_COMPAT_PFX ~ "vfprintf");
    pragma(GNU_asm,vprintf,__LDBL_COMPAT_PFX ~ "vprintf");
    pragma(GNU_asm,sprintf,__LDBL_COMPAT_PFX ~ "sprintf");
    pragma(GNU_asm,vsprintf,__LDBL_COMPAT_PFX ~ "vsprintf");
    pragma(GNU_asm,scanf,__LDBL_COMPAT_PFX ~ "scanf");
    pragma(GNU_asm,fscanf,__LDBL_COMPAT_PFX ~ "fscanf");
    pragma(GNU_asm,sscanf,__LDBL_COMPAT_PFX ~ "sscanf");
    pragma(GNU_asm,snprintf,__LDBL_COMPAT_PFX ~ "snprintf");
    pragma(GNU_asm,vsnprintf,__LDBL_COMPAT_PFX ~ "vsnprintf");
}
else version (GNU)
{
    extern (C) int ferror(FILE *);
    extern (C) int feof(FILE *);
    extern (C) void clearerr(FILE *);
    extern (C) void rewind(FILE *);
    extern (C) int _bufsize(FILE *);
    extern (C) int fileno(FILE *);

    alias __builtin_snprintf snprintf;
    alias __builtin_vsnprintf vsnprintf;
}
else version (linux)
{
    int  ferror(FILE *fp);
    int  feof(FILE *fp);
    void clearerr(FILE *fp);
    void rewind(FILE *fp);
    int  _bufsize(FILE *fp);
    int  fileno(FILE *fp);
    int  snprintf(char *,size_t,char *,...);
    int  vsnprintf(char *,size_t,char *,va_list);
}

int      unlink(char *);	///
FILE *	 fdopen(int, char *);	///
int	 fgetchar();	///
int	 fputchar(int);	///
int	 fcloseall();	///
int	 filesize(char *);	///
int	 flushall();	///
int	 getch();	///
int	 getche();	///
int      kbhit();	///
char *   tempnam (char *dir, char *pfx);	///

wchar_t *  _wtmpnam(wchar_t *);	///
FILE *  _wfopen(wchar_t *, wchar_t *);
FILE *  _wfsopen(wchar_t *, wchar_t *, int);
FILE *  _wfreopen(wchar_t *, wchar_t *, FILE *);
wchar_t *  fgetws(wchar_t *, int, FILE *);	///
int  fputws(wchar_t *, FILE *);	///
wchar_t *  _getws(wchar_t *);
int  _putws(wchar_t *);
int  wprintf(wchar_t *, ...);	///
int  fwprintf(FILE *, wchar_t *, ...);	///
int  vwprintf(wchar_t *, va_list);	///
int  vfwprintf(FILE *, wchar_t *, va_list);	///
int  swprintf(wchar_t *, wchar_t *, ...);	///
int  vswprintf(wchar_t *, wchar_t *, va_list);	///
int  _snwprintf(wchar_t *, size_t, wchar_t *, ...);
int  _vsnwprintf(wchar_t *, size_t, wchar_t *, va_list);
int  wscanf(wchar_t *, ...);	///
int  fwscanf(FILE *, wchar_t *, ...);	///
int  swscanf(wchar_t *, wchar_t *, ...);	///
int  _wremove(wchar_t *);
void  _wperror(wchar_t *);
FILE *  _wfdopen(int, wchar_t *);
wchar_t *  _wtempnam(wchar_t *, wchar_t *);
wchar_t  fgetwc(FILE *);	///
wchar_t  _fgetwchar_t();
wchar_t  fputwc(wchar_t, FILE *);	///
wchar_t  _fputwchar_t(wchar_t);
wchar_t  ungetwc(wchar_t, FILE *);	///

wchar_t	 getwchar_t(); ///
wchar_t	 putwchar_t(wchar_t c); ///
wchar_t	 getwc(FILE *fp); ///
wchar_t	 putwc(wchar_t c, FILE *fp) ///;

int fwide(FILE* fp, int mode);	///
