/**
 * D header file for C99.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly, Walter Bright
 * Standards: ISO/IEC 9899:1999 (E)
 */
module tango.stdc.stdio;

private
{
    import tango.stdc.stdarg;
    import tango.stdc.stddef;
    import tango.stdc.config;
}

extern (C):

version( Win32 )
{
    const int BUFSIZ         = 0x4000;
    const int EOF            = -1;
    const int FOPEN_MAX      = 20;
    const int FILENAME_MAX   = 256; // 255 plus NULL
    const int TMP_MAX        = 32767;
    const int _SYS_OPEN      = 20;
    const int SYS_OPEN       = _SYS_OPEN;

    const int     _NFILE     = 60;
    const char[]  _P_tmpdir  = "\\";
    const wchar[] _wP_tmpdir = "\\";
    const int     L_tmpnam   = _P_tmpdir.length + 12;
}
else version( linux )
{
    //const int BUFSIZ      = 0x4000;
    const int EOF           = -1;
    const int FOPEN_MAX     = 16;
    const int FILENAME_MAX  = 4095;
    const int TMP_MAX       = 238328;
    const int L_tmpnam      = 20;
}
else version( darwin )
{
    const int EOF           = -1;
    const int FOPEN_MAX     = 20;
    const int FILENAME_MAX  = 1024;
    const int TMP_MAX       = 308915776;
    const int L_tmpnam      = 1024;

    private
    {
        struct __sbuf
        {
            ubyte*  _base;
            int     _size;
        }

        struct __sFILEX
        {

        }
    }
}
else
{
    static assert( false );
}

enum
{
    SEEK_SET,
    SEEK_CUR,
    SEEK_END
}

struct _iobuf
{
    align (1):
    version( Win32 )
    {
        char* _ptr;
        int   _cnt;
        char* _base;
        int   _flag;
        int   _file;
        int   _charbuf;
        int   _bufsiz;
        int   __tmpnum;
    }
    else version( linux )
    {
        char*   _read_ptr;
        char*   _read_end;
        char*   _read_base;
        char*   _write_base;
        char*   _write_ptr;
        char*   _write_end;
        char*   _buf_base;
        char*   _buf_end;
        char*   _save_base;
        char*   _backup_base;
        char*   _save_end;
        void*   _markers;
        _iobuf* _chain;
        int     _fileno;
        int     _blksize;
        int     _old_offset;
        ushort  _cur_column;
        byte    _vtable_offset;
        char[1] _shortbuf;
        void*   _lock;
    }
    else version( darwin )
    {
        ubyte*    _p;
        int       _r;
        int       _w;
        short     _flags;
        short     _file;
        __sbuf    _bf;
        int       _lbfsize;

        int* function(void*)                    _close;
        int* function(void*, char*, int)        _read;
        fpos_t* function(void*, fpos_t, int)    _seek;
        int* function(void*, char *, int)       _write;

        __sbuf    _ub;
        __sFILEX* _extra;
        int       _ur;

        ubyte[3]  _ubuf;
        ubyte[1]  _nbuf;

        __sbuf    _lb;

        int       _blksize;
        fpos_t    _offset;
    }
}

alias _iobuf FILE;

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

version( Win32 )
{
    enum
    {
        _IOFBF   = 0,
        _IOREAD  = 1,
        _IOWRT   = 2,
        _IONBF   = 4,
        _IOMYBUF = 8,
        _IOEOF   = 0x10,
        _IOERR   = 0x20,
        _IOLBF   = 0x40,
        _IOSTRG  = 0x40,
        _IORW    = 0x80,
        _IOTRAN  = 0x100,
        _IOAPP   = 0x200,
    }

	extern void function() _fcloseallp;

	version (GNU) {
		extern FILE[_NFILE]* _imp___iob;

		const FILE* stdin;
		const FILE* stdout;
		const FILE* stderr;
		const FILE* stdaux;
		const FILE* stdprn;
		
		static this() {
			stdin  = &(*_imp___iob)[0];
			stdout = &(*_imp___iob)[1];
			stderr = &(*_imp___iob)[2];
			stdaux = &(*_imp___iob)[3];
			stdprn = &(*_imp___iob)[4];
		}
	} else {
		extern FILE[_NFILE] _iob;

		const FILE* stdin  = &_iob[0];
		const FILE* stdout = &_iob[1];
		const FILE* stderr = &_iob[2];
		const FILE* stdaux = &_iob[3];
		const FILE* stdprn = &_iob[4];
	}
}
else version( linux )
{
    enum
    {
        _IOFBF = 0,
        _IOLBF = 1,
        _IONBF = 2,
    }

    extern FILE* stdin;
    extern FILE* stdout;
    extern FILE* stderr;
}
else version( darwin )
{
    extern FILE[3] __sF;
    const FILE* stdin  = &__sF[0];
    const FILE* stdout = &__sF[1];
    const FILE* stderr = &__sF[2];
}
else
{
    static assert( false );
}

alias int fpos_t;

int remove(char* filename);
int rename(char* from, char* to);

FILE* tmpfile();
char* tmpnam(char* s);

int   fclose(FILE* stream);
int   fflush(FILE* stream);
FILE* fopen(char* filename, char* mode);
FILE* freopen(char* filename, char* mode, FILE* stream);

void setbuf(FILE* stream, char* buf);
int  setvbuf(FILE* stream, char* buf, int mode, size_t size);

int fprintf(FILE* stream, char* format, ...);
int fscanf(FILE* stream, char* format, ...);
int sprintf(char* s, char* format, ...);
int sscanf(char* s, char* format, ...);
int vfprintf(FILE* stream, char* format, va_list arg);
int vfscanf(FILE* stream, char* format, va_list arg);
int vsprintf(char* s, char* format, va_list arg);
int vsscanf(char* s, char* format, va_list arg);
int vprintf(char* format, va_list arg);
int vscanf(char* format, va_list arg);
int printf(char* format, ...);
int scanf(char* format, ...);

int fgetc(FILE* stream);
int fputc(int c, FILE* stream);

char* fgets(char* s, int n, FILE* stream);
int   fputs(char* s, FILE* stream);
char* gets(char* s);
int   puts(char* s);

extern (D)
{
    int getchar()                 { return getc(stdin);     }
    int putchar(int c)            { return putc(c,stdout);  }
    int getc(FILE* stream)        { return fgetc(stream);   }
    int putc(int c, FILE* stream) { return fputc(c,stream); }
}

int ungetc(int c, FILE* stream);

size_t fread(void* ptr, size_t size, size_t nmemb, FILE* stream);
size_t fwrite(void* ptr, size_t size, size_t nmemb, FILE* stream);

int fgetpos(FILE* stream, fpos_t * pos);
int fsetpos(FILE* stream, fpos_t* pos);

int    fseek(FILE* stream, c_long offset, int whence);
c_long ftell(FILE* stream);

version( Win32 )
{
  extern (D)
  {
    void rewind(FILE* stream)   { fseek(stream,0L,SEEK_SET); stream._flag&=~_IOERR; }
    void clearerr(FILE* stream) { stream._flag &= ~(_IOERR|_IOEOF);                 }
    int  feof(FILE* stream)     { return stream._flag&_IOEOF;                       }
    int  ferror(FILE* stream)   { return stream._flag&_IOERR;                       }
  }
    int   _snprintf(char*,size_t,char*,...);
    alias _snprintf snprintf;

    int   _vsnprintf(char* s, size_t n, char* format, va_list arg);
    alias _vsnprintf vsnprintf;
}
else version( linux )
{
    void rewind(FILE* stream);
    void clearerr(FILE* stream);
    int  feof(FILE* stream);
    int  ferror(FILE* stream);
    int  fileno(FILE *);

    int  snprintf(char* s, size_t n, char* format, ...);
    int  vsnprintf(char* s, size_t n, char* format, va_list arg);
}
else version( darwin )
{
    void rewind(FILE*);
    void clearerr(FILE*);
    int  feof(FILE*);
    int  ferror(FILE*);
    int  fileno(FILE*);

    int  snprintf(char*, size_t, char*, ...);
    int  vsnprintf(char*, size_t, char*, va_list);
}
else
{
    static assert( false );
}

void perror(char* s);

int fwprintf(FILE* stream, wchar_t* format, ...);
int fwscanf(FILE* stream, wchar_t* format, ...);
int swprintf(wchar_t* s, size_t n, wchar_t* format, ...);
int swscanf(wchar_t* s, wchar_t* format, ...);
int vfwprintf(FILE* stream, wchar_t* format, va_list arg);
int vfwscanf(FILE* stream, wchar_t* format, va_list arg);
int vswprintf(wchar_t* s, size_t n, wchar_t* format, va_list arg);
int vswscanf(wchar_t* s, wchar_t* format, va_list arg);
int vwprintf(wchar_t* format, va_list arg);
int vwscanf(wchar_t* format, va_list arg);
int wprintf(wchar_t* format, ...);
int wscanf(wchar_t* format, ...);

wint_t fgetwc(FILE* stream);
wint_t fputwc(wchar_t c, FILE* stream);

wchar_t* fgetws(wchar_t* s, int n, FILE* stream);
int      fputws(wchar_t* s, FILE* stream);

extern (D)
{
    wint_t getwchar()                     { return fgetwc(stdin);     }
    wint_t putwchar(wchar_t c)            { return fputwc(c,stdout);  }
    wint_t getwc(FILE* stream)            { return fgetwc(stream);    }
    wint_t putwc(wchar_t c, FILE* stream) { return fputwc(c, stream); }
}

wint_t ungetwc(wint_t c, FILE* stream);
int    fwide(FILE* stream, int mode);
