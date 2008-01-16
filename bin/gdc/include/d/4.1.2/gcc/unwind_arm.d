/* ARM unwind interface declarations for D.  This must match unwind-arm.h */
module gcc.unwind_arm;

private import gcc.builtins;

extern (C):

alias __builtin_machine_uint _Unwind_Word;
alias __builtin_machine_int _Unwind_Sword;
alias __builtin_pointer_uint _Unwind_Ptr;
alias __builtin_pointer_uint _Unwind_Internal_Ptr;
alias _Unwind_Word _uw;
alias ulong _uw64;
alias ushort _uw16;
alias ubyte _uw8;

typedef uint _Unwind_Reason_Code;
enum : _Unwind_Reason_Code
{
    _URC_OK = 0,       /* operation completed successfully */
    _URC_FOREIGN_EXCEPTION_CAUGHT = 1,
    _URC_END_OF_STACK = 5,
    _URC_HANDLER_FOUND = 6,
    _URC_INSTALL_CONTEXT = 7,
    _URC_CONTINUE_UNWIND = 8,
    _URC_FAILURE = 9   /* unspecified failure of some kind */
}

typedef int _Unwind_State;
enum : _Unwind_State
{
    _US_VIRTUAL_UNWIND_FRAME = 0,
    _US_UNWIND_FRAME_STARTING = 1,
    _US_UNWIND_FRAME_RESUME = 2,
    _US_ACTION_MASK = 3,
    _US_FORCE_UNWIND = 8,
    _US_END_OF_STACK = 16
}

  /* Provided only for for compatibility with existing code.  */
alias int _Unwind_Action;
enum : _Unwind_Action
{
    _UA_SEARCH_PHASE =	1,
    _UA_CLEANUP_PHASE =	2,
    _UA_HANDLER_FRAME =	4,
    _UA_FORCE_UNWIND =	8,
    _UA_END_OF_STACK =	16,
    _URC_NO_REASON = 	_URC_OK
}


struct _Unwind_Context;
alias _uw _Unwind_EHT_Header;

  /* UCB: */

struct _Unwind_Control_Block
{
  char exception_class[8] = '\0';
  extern(C) void function(_Unwind_Reason_Code, _Unwind_Control_Block *) exception_cleanup;
  
  /* Unwinder cache, private fields for the unwinder's use */
  struct _unwinder_cache
    {
      _uw reserved1;  /* Forced unwind stop fn, 0 if not forced */
      _uw reserved2;  /* Personality routine address */
      _uw reserved3;  /* Saved callsite address */
      _uw reserved4;  /* Forced unwind stop arg */
      _uw reserved5;
    }
  _unwinder_cache unwinder_cache;
  /* Propagation barrier cache (valid after phase 1): */
  struct _barrier_cache
    {
      _uw sp;
      _uw bitpattern[5];
    }
  _barrier_cache barrier_cache;
  /* Cleanup cache (preserved over cleanup): */
  struct _cleanup_cache
    {
      _uw bitpattern[4];
    }
  _cleanup_cache cleanup_cache;
  /* Pr cache (for pr's benefit): */
  struct _pr_cache
    {
      _uw fnstart;			/* function start address */
      _Unwind_EHT_Header *ehtp;	/* pointer to EHT entry header word */
      _uw additional;		/* additional data */
      _uw reserved1;
    }
  _pr_cache pr_cache;
  long[0] _force_alignment;	/* Force alignment to 8-byte boundary */
};

  /* Virtual Register Set*/
typedef int _Unwind_VRS_RegClass;
enum : _Unwind_VRS_RegClass
{
    _UVRSC_CORE = 0,      /* integer register */
    _UVRSC_VFP = 1,       /* vfp */
    _UVRSC_FPA = 2,       /* fpa */
    _UVRSC_WMMXD = 3,     /* Intel WMMX data register */
    _UVRSC_WMMXC = 4      /* Intel WMMX control register */
}

typedef int _Unwind_VRS_DataRepresentation;
enum : _Unwind_VRS_DataRepresentation
{
    _UVRSD_UINT32 = 0,
    _UVRSD_VFPX = 1,
    _UVRSD_FPAX = 2,
    _UVRSD_UINT64 = 3,
    _UVRSD_FLOAT = 4,
    _UVRSD_DOUBLE = 5
}

typedef int _Unwind_VRS_Result;
enum : _Unwind_VRS_Result
{
    _UVRSR_OK = 0,
    _UVRSR_NOT_IMPLEMENTED = 1,
    _UVRSR_FAILED = 2
}

/* Frame unwinding state.  */
struct __gnu_unwind_state
{
  /* The current word (bytes packed msb first).  */
  _uw data;
  /* Pointer to the next word of data.  */
  _uw *next;
  /* The number of bytes left in this word.  */
  _uw8 bytes_left;
  /* The number of words pointed to by ptr.  */
  _uw8 words_left;
}

alias extern(C) _Unwind_Reason_Code function(_Unwind_State,
    _Unwind_Control_Block *, _Unwind_Context *) personality_routine;

_Unwind_VRS_Result _Unwind_VRS_Set(_Unwind_Context *, _Unwind_VRS_RegClass,
                                     _uw, _Unwind_VRS_DataRepresentation,
                                     void *);

_Unwind_VRS_Result _Unwind_VRS_Get(_Unwind_Context *, _Unwind_VRS_RegClass,
                                     _uw, _Unwind_VRS_DataRepresentation,
                                     void *);

_Unwind_VRS_Result _Unwind_VRS_Pop(_Unwind_Context *, _Unwind_VRS_RegClass,
                                     _uw, _Unwind_VRS_DataRepresentation);


  /* Support functions for the PR.  */
alias _Unwind_Control_Block _Unwind_Exception ;
typedef char _Unwind_Exception_Class[8] = '\0';

void * _Unwind_GetLanguageSpecificData (_Unwind_Context *);
_Unwind_Ptr _Unwind_GetRegionStart (_Unwind_Context *);

/* These two should never be used.  */
_Unwind_Ptr _Unwind_GetDataRelBase (_Unwind_Context *);
_Unwind_Ptr _Unwind_GetTextRelBase (_Unwind_Context *);

/* Interface functions: */
_Unwind_Reason_Code _Unwind_RaiseException(_Unwind_Control_Block *ucbp);
pragma(GNU_attribute, noreturn)
    void _Unwind_Resume(_Unwind_Control_Block *ucbp);
_Unwind_Reason_Code _Unwind_Resume_or_Rethrow (_Unwind_Control_Block *ucbp);

alias extern(C) _Unwind_Reason_Code function(int, _Unwind_Action,
    _Unwind_Exception_Class, _Unwind_Control_Block *, _Unwind_Context *,
    void *) _Unwind_Stop_Fn;

_Unwind_Reason_Code _Unwind_ForcedUnwind (_Unwind_Control_Block *,
					    _Unwind_Stop_Fn, void *);
_Unwind_Word _Unwind_GetCFA (_Unwind_Context *);
void _Unwind_Complete(_Unwind_Control_Block *ucbp);
void _Unwind_DeleteException (_Unwind_Exception *);

_Unwind_Reason_Code __gnu_unwind_frame (_Unwind_Control_Block *,
    _Unwind_Context *);
_Unwind_Reason_Code __gnu_unwind_execute (_Unwind_Context *,
    __gnu_unwind_state *);

  /* Decode an R_ARM_TARGET2 relocation.  */
/*static inline*/
_Unwind_Word _Unwind_decode_target2 (_Unwind_Word ptr)
{
    _Unwind_Word tmp;

    tmp = *cast(_Unwind_Word *) ptr;
    /* Zero values are always NULL.  */
    if (!tmp)
	return 0;

    //#if defined(linux) || defined(__NetBSD__)
    version(linux)
	const bool pc_rel_ind = true;
    else version(netbsd) // TODO: name
	const bool pc_rel_ind = true;
    else
	const bool pc_rel_ind = false;
    static if (pc_rel_ind)
    {
      /* Pc-relative indirect.  */
      tmp += ptr;
      tmp = *cast(_Unwind_Word *) tmp;
    }
    else version (symbian) // TODO: name
    {
      /* Absolute pointer.  Nothing more to do.  */
    }
    else
    {
      /* Pc-relative pointer.  */
      tmp += ptr;
    }
    return tmp;
}

/*  static inline */
_Unwind_Word _Unwind_GetGR (_Unwind_Context *context, int regno)
{
    _uw val;
    _Unwind_VRS_Get (context, _UVRSC_CORE, regno, _UVRSD_UINT32, &val);
    return val;
}

/* Return the address of the instruction, not the actual IP value.  */
/*#define _Unwind_GetIP(context)			\
  (_Unwind_GetGR (context, 15) & ~(_Unwind_Word)1)*/
_Unwind_Word _Unwind_GetIP(_Unwind_Context *context)
{
    return _Unwind_GetGR (context, 15) & ~ cast(_Unwind_Word) 1;
}

/*  static inline */
void _Unwind_SetGR (_Unwind_Context *context, int regno, _Unwind_Word val)
{
    _Unwind_VRS_Set (context, _UVRSC_CORE, regno, _UVRSD_UINT32, &val);
}

/* The dwarf unwinder doesn't understand arm/thumb state.  We assume the
   landing pad uses the same instruction set as the call site.  */
/*#define _Unwind_SetIP(context, val)					\
  _Unwind_SetGR (context, 15, val | (_Unwind_GetGR (context, 15) & 1))*/
void _Unwind_SetIP(_Unwind_Context *context, _Unwind_Word val)
{
    return _Unwind_SetGR (context, 15, val | (_Unwind_GetGR (context, 15) & 1));
}
