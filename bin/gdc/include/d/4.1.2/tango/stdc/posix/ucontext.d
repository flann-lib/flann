/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.ucontext;

private import tango.stdc.posix.config;
public import tango.stdc.posix.signal; // for sigset_t, stack_t

extern (C):

//
// XOpen (XSI)
//
/*
mcontext_t

struct ucontext_t
{
    ucontext_t* uc_link;
    sigset_t    uc_sigmask;
    stack_t     uc_stack;
    mcontext_t  uc_mcontext;
}
*/

version( linux )
{
    private
    {
        struct _libc_fpreg
        {
          ushort[4] significand;
          ushort    exponent;
        }

        struct _libc_fpstate
        {
          c_ulong           cw;
          c_ulong           sw;
          c_ulong           tag;
          c_ulong           ipoff;
          c_ulong           cssel;
          c_ulong           dataoff;
          c_ulong           datasel;
          _libc_fpreg[8]    _st;
          c_ulong           status;
        }

        const NGREG = 19;

        alias int               greg_t;
        alias greg_t[NGREG]     gregset_t;
        alias _libc_fpstate*    fpregset_t;
    }

    version( X86_64 )
    {

    }
    else version( X86 )
    {
        struct mcontext_t
        {
            gregset_t   gregs;
            fpregset_t  fpregs;
            c_ulong     oldmask;
            c_ulong     cr2;
        }

        struct ucontext_t
        {
            c_ulong         uc_flags;
            ucontext_t*     uc_link;
            stack_t         uc_stack;
            mcontext_t      uc_mcontext;
            sigset_t        uc_sigmask;
            _libc_fpstate   __fpregs_mem;
        }
    }
}

//
// Obsolescent (OB)
//
/*
int  getcontext(ucontext_t*);
void makecontext(ucontext_t*, void function(), int, ...);
int  setcontext(ucontext_t*);
int  swapcontext(ucontext_t*, ucontext_t*);
*/

static if( is( typeof( ucontext_t ) ) )
{
    int  getcontext(ucontext_t*);
    void makecontext(ucontext_t*, void function(), int, ...);
    int  setcontext(ucontext_t*);
    int  swapcontext(ucontext_t*, ucontext_t*);
}
