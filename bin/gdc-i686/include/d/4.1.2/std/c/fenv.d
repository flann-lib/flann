
/**
 * C's &lt;fenv.h&gt;
 * Authors: Walter Bright, Digital Mars, www.digitalmars.com
 * License: Public Domain
 * Macros:
 *	WIKI=Phobos/StdCFenv
 */

module std.c.fenv;

extern (C):

/// Entire floating point environment

struct fenv_t
{
    version (Windows)
    {
	ushort status;
	ushort control;
	ushort round;
	ushort reserved[2];
    }
    else version (linux)
    {
	ushort __control_word;
	ushort __unused1;
	ushort __status_word;
	ushort __unused2;
	ushort __tags;
	ushort __unused3;
	uint __eip;
	ushort __cs_selector;
	ushort __opcode;
	uint __data_offset;
	ushort __data_selector;
	ushort __unused5;
	static if (size_t.sizeof == 8)
	    uint __mxcsr;
    }
    else
    {
	static assert(0);
    }
}

alias int fexcept_t;	/// Floating point status flags

/// The various floating point exceptions
enum
{
    FE_INVALID		= 1,		///
    FE_DENORMAL		= 2,		///
    FE_DIVBYZERO	= 4,		///
    FE_OVERFLOW		= 8,		///
    FE_UNDERFLOW	= 0x10,		///
    FE_INEXACT		= 0x20,		///
    FE_ALL_EXCEPT	= 0x3F,		/// Mask of all the exceptions
}

/// Rounding modes
enum
{
    FE_TONEAREST	= 0,		///
    FE_UPWARD		= 0x800,	///
    FE_DOWNWARD		= 0x400,	///
    FE_TOWARDZERO	= 0xC00,	///
}

version (Windows)
{
    extern fenv_t _FE_DFL_ENV;

    /// Default floating point environment
    fenv_t* FE_DFL_ENV = &_FE_DFL_ENV;
}
else version (linux)
{
    /// Default floating point environment
    fenv_t* FE_DFL_ENV = cast(fenv_t*)(-1);
}
else
{
    static assert(0);
}

/// Floating point precision
enum
{
    FE_FLTPREC	= 0,			///
    FE_DBLPREC	= 0x200,		///
    FE_LDBLPREC	= 0x300,		///
}

int fetestexcept(int excepts);		///
int feraiseexcept(int excepts);		///
int feclearexcept(int excepts);		///
//int fegetexcept(fexcept_t *flagp,int excepts);	///
//int fesetexcept(fexcept_t *flagp,int excepts);	///
int fegetround();			///
int fesetround(int round);		///
int fegetprec();			///
int fesetprec(int prec);		///
int fegetenv(fenv_t *envp);		///
int fesetenv(fenv_t *envp);		///
//void feprocentry(fenv_t *envp);	///
//void feprocexit(const fenv_t *envp);	///

int fegetexceptflag(fexcept_t *flagp,int excepts);	///
int fesetexceptflag(fexcept_t *flagp,int excepts);	///
int feholdexcept(fenv_t *envp);		///
int feupdateenv(fenv_t *envp);		///

