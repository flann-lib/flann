/**
 * Low-level Mathematical Functions which take advantage of the IEEE754 ABI.
 *
 * Copyright: Portions Copyright (C) 2001-2005 Digital Mars.
 * License:   BSD style: $(LICENSE), Digital Mars.
 * Authors:   Don Clugston, Walter Bright, Sean Kelly
 */
/* Portions of this code were taken from Phobos std.math, which has the following
 * copyright notice:
 *
 * Author:
 *  Walter Bright
 * Copyright:
 *  Copyright (c) 2001-2005 by Digital Mars,
 *  All Rights Reserved,
 *  www.digitalmars.com
 * License:
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, subject to the following restrictions:
 *
 *  <ul>
 *  <li> The origin of this software must not be misrepresented; you must not
 *       claim that you wrote the original software. If you use this software
 *       in a product, an acknowledgment in the product documentation would be
 *       appreciated but is not required.
 *  </li>
 *  <li> Altered source versions must be plainly marked as such, and must not
 *       be misrepresented as being the original software.
 *  </li>
 *  <li> This notice may not be removed or altered from any source
 *       distribution.
 *  </li>
 *  </ul>
 */
/**
 * Macros:
 *
 *  TABLE_SV = <table border=1 cellpadding=4 cellspacing=0>
 *      <caption>Special Values</caption>
 *      $0</table>
 *  SVH = $(TR $(TH $1) $(TH $2))
 *  SV  = $(TR $(TD $1) $(TD $2))
 *  SVH3 = $(TR $(TH $1) $(TH $2) $(TH $3))
 *  SV3  = $(TR $(TD $1) $(TD $2) $(TD $3))
 *  NAN = $(RED NAN)
 */
module tango.math.IEEE;

version(DigitalMars)
{
    version(D_InlineAsm_X86)
    {
        version = DigitalMars_D_InlineAsm_X86;
    }
}

version (X86){
    version = X86_Any;
}

version (X86_64){
    version = X86_Any;
}

version (DigitalMars_D_InlineAsm_X86) {
    // Don't include this extra dependency unless we need to.
    debug(UnitTest) {
        static import tango.stdc.math;
    }
} else {
    // Needed for cos(), sin(), tan() on GNU.
   static import tango.stdc.math;
}

// Standard Tango NaN payloads.
// NOTE: These values may change in future Tango releases
// The lowest three bits indicate the cause of the NaN:
// 0 = error other than those listed below:
// 1 = domain error
// 2 = singularity
// 3 = range
// 4-7 = reserved.
enum TANGO_NAN {
    // General errors
    DOMAIN_ERROR = 0x0101,
    SINGULARITY  = 0x0102,
    RANGE_ERROR  = 0x0103,
    // NaNs created by functions in the basic library
    TAN_DOMAIN   = 0x1001,
    POW_DOMAIN   = 0x1021,
    GAMMA_DOMAIN = 0x1101,
    GAMMA_POLE   = 0x1102,
    SGNGAMMA     = 0x1112,
    BETA_DOMAIN  = 0x1131,
    // NaNs from statistical functions
    NORMALDISTRIBUTION_INV_DOMAIN = 0x2001,
    STUDENTSDDISTRIBUTION_DOMAIN  = 0x2011
}

private:
/* Most of the functions depend on the format of the largest IEEE floating-point type.
 * These code will differ depending on whether 'real' is 64, 80, or 128 bits,
 * and whether it is a big-endian or little-endian architecture.
 * Only five 'real' ABIs are currently supported:
 * 64 bit Big-endian  'double' (eg PowerPC)
 * 128 bit Big-endian 'quadruple' (eg SPARC)
 * 64 bit Little-endian 'double' (eg x86-SSE2)
 * 80 bit Little-endian, with implied bit 'real80' (eg x87, Itanium).
 * 128 bit Little-endian 'quadruple' (not implemented on any known processor!)
 *
 * There is also an unsupported ABI which does not follow IEEE; several of its functions
 *  will generate run-time errors if used.
 * 128 bit Big-endian 'doubledouble' (used by GDC <= 0.23 for PowerPC)
 */

version(LittleEndian) {
    static assert(real.mant_dig == 53 || real.mant_dig==64 || real.mant_dig == 113,
        "Only 64-bit, 80-bit, and 128-bit reals are supported for LittleEndian CPUs");
} else {
    static assert(real.mant_dig == 53 || real.mant_dig==106 || real.mant_dig == 113,
     "Only 64-bit and 128-bit reals are supported for BigEndian CPUs. double-double reals have partial support");
}

// Constants used for extracting the components of the representation.
// They supplement the built-in floating point properties.
template floatTraits(T) {
 // EXPMASK is a ushort mask to select the exponent portion (without sign)
 // POW2MANTDIG = pow(2, real.mant_dig) is the value such that
 //  (smallest_denormal)*POW2MANTDIG == real.min
 // EXPPOS_SHORT is the index of the exponent when represented as a ushort array.
 // SIGNPOS_BYTE is the index of the sign when represented as a ubyte array.
 static if (T.mant_dig == 24) { // float
    const ushort EXPMASK = 0x7F80;
    const ushort EXPBIAS = 0x3F00;
    const uint EXPMASK_INT = 0x7F80_0000;
    const uint MANTISSAMASK_INT = 0x007F_FFFF;
    const real POW2MANTDIG = 0x1p+24;
    version(LittleEndian) {        
      const EXPPOS_SHORT = 1;
    } else {
      const EXPPOS_SHORT = 0;
    }
 } else static if (T.mant_dig==53) { // double, or real==double
    const ushort EXPMASK = 0x7FF0;
    const ushort EXPBIAS = 0x3FE0;
    const uint EXPMASK_INT = 0x7FF0_0000;
    const uint MANTISSAMASK_INT = 0x000F_FFFF; // for the MSB only
    const real POW2MANTDIG = 0x1p+53;
    version(LittleEndian) {
      const EXPPOS_SHORT = 3;
      const SIGNPOS_BYTE = 7;
    } else {
      const EXPPOS_SHORT = 0;
      const SIGNPOS_BYTE = 0;
    }
 } else static if (T.mant_dig==64) { // real80
    const ushort EXPMASK = 0x7FFF;
    const ushort EXPBIAS = 0x3FFE;
    const real POW2MANTDIG = 0x1p+63;    
//    const ulong QUIETNANMASK = 0xC000_0000_0000_0000; // Converts a signaling NaN to a quiet NaN.
    version(LittleEndian) {
      const EXPPOS_SHORT = 4;
      const SIGNPOS_BYTE = 9;
    } else {
      const EXPPOS_SHORT = 0;
      const SIGNPOS_BYTE = 0;
    }
 } else static if (real.mant_dig==113){ // quadruple
    const ushort EXPMASK = 0x7FFF;
    const real POW2MANTDIG = 0x1p+113;
    version(LittleEndian) {
      const EXPPOS_SHORT = 7;
      const SIGNPOS_BYTE = 15;
    } else {
      const EXPPOS_SHORT = 0;
      const SIGNPOS_BYTE = 0;
    }
 } else static if (real.mant_dig==106) { // doubledouble
    const ushort EXPMASK = 0x7FF0;
    const real POW2MANTDIG = 0x1p+53;  // doubledouble denormals are strange
    // and the exponent byte is not unique
    version(LittleEndian) {
      const EXPPOS_SHORT = 7; // 3 is also an exp short
      const SIGNPOS_BYTE = 15;
    } else {
      const EXPPOS_SHORT = 0; // 4 is also an exp short
      const SIGNPOS_BYTE = 0;
    }
 }
}

// These apply to all floating-point types
version(LittleEndian) {
    const MANTISSA_LSB = 0;
    const MANTISSA_MSB = 1;    
} else {
    const MANTISSA_LSB = 1;
    const MANTISSA_MSB = 0;
}

public:

/** IEEE exception status flags

 These flags indicate that an exceptional floating-point condition has occured.
 They indicate that a NaN or an infinity has been generated, that a result
 is inexact, or that a signalling NaN has been encountered.
 The return values of the properties should be treated as booleans, although
 each is returned as an int, for speed.

 Example:
 ----
    real a=3.5;
    // Set all the flags to zero
    resetIeeeFlags();
    assert(!ieeeFlags.divByZero);
    // Perform a division by zero.
    a/=0.0L;
    assert(a==real.infinity);
    assert(ieeeFlags.divByZero);
    // Create a NaN
    a*=0.0L;
    assert(ieeeFlags.invalid);
    assert(isNaN(a));

    // Check that calling func() has no effect on the
    // status flags.
    IeeeFlags f = ieeeFlags;
    func();
    assert(ieeeFlags == f);

 ----
 */
struct IeeeFlags
{
private:
    // The x87 FPU status register is 16 bits.
    // The Pentium SSE2 status register is 32 bits.
    int m_flags;
    version (X86_Any) {
        // Applies to both x87 status word (16 bits) and SSE2 status word(32 bits).
        enum : int {
            INEXACT_MASK   = 0x20,
            UNDERFLOW_MASK = 0x10,
            OVERFLOW_MASK  = 0x08,
            DIVBYZERO_MASK = 0x04,
            INVALID_MASK   = 0x01
        }
        // Don't bother about denormals, they are not supported on most CPUs.
        //  DENORMAL_MASK = 0x02;
    } else version (PPC) {
        // PowerPC FPSCR is a 32-bit register.
        enum : int {
            INEXACT_MASK   = 0x600,
            UNDERFLOW_MASK = 0x010,
            OVERFLOW_MASK  = 0x008,
            DIVBYZERO_MASK = 0x020,
            INVALID_MASK   = 0xF80
        }
    } else { // SPARC FSR is a 32bit register
             //(64 bits for Sparc 7 & 8, but high 32 bits are uninteresting).
        enum : int {
            INEXACT_MASK   = 0x020,
            UNDERFLOW_MASK = 0x080,
            OVERFLOW_MASK  = 0x100,
            DIVBYZERO_MASK = 0x040,
            INVALID_MASK   = 0x200
        }
    }
private:
    static IeeeFlags getIeeeFlags()
    {
        // This is a highly time-critical operation, and
        // should really be an intrinsic.
       version(D_InlineAsm_X86) {
           version(Posix) {
             IeeeFlags tmp1;
             asm {
                 fstsw AX;
                 // NOTE: If compiler supports SSE2, need to OR the result with
                 // the SSE2 status register.
                 // Clear all irrelevant bits
                 and EAX, 0x03D;
                 mov tmp1, EAX;
             }
             return tmp1;
           }
           else { // DMD-Windows
             // In this case, we
             // take advantage of the fact that for DMD-Windows
             // a struct containing only a int is returned in EAX.
             asm {
                 fstsw AX;
                 // NOTE: If compiler supports SSE2, need to OR the result with
                 // the SSE2 status register.
                 // Clear all irrelevant bits
                 and EAX, 0x03D;
             }
           }
       } else version (PPC) {
           assert(0, "Not yet supported");
       } else {
           /*   SPARC:
               int retval;
               asm { st %fsr, retval; }
               return retval;
            */
           assert(0, "Not yet supported");
       }
    }
    static void resetIeeeFlags()
    {
       version(D_InlineAsm_X86) {
            asm {
                fnclex;
            }
        } else {
            /* SPARC:
              int tmpval;
              asm { st %fsr, tmpval; }
              tmpval &=0xFFFF_FC00;
              asm { ld tmpval, %fsr; }
            */
           assert(0, "Not yet supported");
        }
    }
public:
    /// The result cannot be represented exactly, so rounding occured.
    /// (example: x = sin(0.1); }
    int inexact() { return m_flags & INEXACT_MASK; }
    /// A zero was generated by underflow (example: x = real.min*real.epsilon/2;)
    int underflow() { return m_flags & UNDERFLOW_MASK; }
    /// An infinity was generated by overflow (example: x = real.max*2;)
    int overflow() { return m_flags & OVERFLOW_MASK; }
    /// An infinity was generated by division by zero (example: x = 3/0.0; )
    int divByZero() { return m_flags & DIVBYZERO_MASK; }
    /// A machine NaN was generated. (example: x = real.infinity * 0.0; )
    int invalid() { return m_flags & INVALID_MASK; }
}

/// Return a snapshot of the current state of the floating-point status flags.
IeeeFlags ieeeFlags() { return IeeeFlags.getIeeeFlags(); }

/// Set all of the floating-point status flags to false.
void resetIeeeFlags() { IeeeFlags.resetIeeeFlags; }

/** IEEE rounding modes.
 * The default mode is ROUNDTONEAREST.
 */
enum RoundingMode : short {
    ROUNDTONEAREST = 0x0000,
    ROUNDDOWN      = 0x0400,
    ROUNDUP        = 0x0800,
    ROUNDTOZERO    = 0x0C00
};

/** Change the rounding mode used for all floating-point operations.
 *
 * Returns the old rounding mode.
 *
 * When changing the rounding mode, it is almost always necessary to restore it
 * at the end of the function. Typical usage:
---
    auto oldrounding = setIeeeRounding(RoundingMode.ROUNDDOWN);
    scope (exit) setIeeeRounding(oldrounding);
---
 */
RoundingMode setIeeeRounding(RoundingMode roundingmode) {
   version(D_InlineAsm_X86) {
        // TODO: For SSE/SSE2, do we also need to set the SSE rounding mode?
        short cont;
        asm {
            fstcw cont;
            mov CX, cont;
            mov AX, cont;
            and EAX, 0x0C00; // Form the return value
            and CX, 0xF3FF;
            or CX, roundingmode;
            mov cont, CX;
            fldcw cont;
        }
    } else {
           assert(0, "Not yet supported");
    }
}

/** Get the IEEE rounding mode which is in use.
 *
 */
RoundingMode getIeeeRounding() {
   version(D_InlineAsm_X86) {
        // TODO: For SSE/SSE2, do we also need to check the SSE rounding mode?
        short cont;
        asm {
            mov EAX, 0x0C00;
            fstcw cont;
            and AX, cont;
        }
    } else {
           assert(0, "Not yet supported");
    }
}

debug(UnitTest) {
   version(D_InlineAsm_X86) { // Won't work for anything else yet
unittest {
    real a = 3.5;
    resetIeeeFlags();
    assert(!ieeeFlags.divByZero);
    a /= 0.0L;
    assert(ieeeFlags.divByZero);
    assert(a == real.infinity);
    a *= 0.0L;
    assert(ieeeFlags.invalid);
    assert(isNaN(a));
    a = real.max;
    a *= 2;
    assert(ieeeFlags.overflow);
    a = real.min * real.epsilon;
    a /= 99;
    assert(ieeeFlags.underflow);
    assert(ieeeFlags.inexact);

    int r = getIeeeRounding;
    assert(r == RoundingMode.ROUNDTONEAREST);
}
}
}

// Note: Itanium supports more precision options than this. SSE/SSE2 does not support any.
enum PrecisionControl : short {
    PRECISION80 = 0x300,
    PRECISION64 = 0x200,
    PRECISION32 = 0x000
};

/** Set the number of bits of precision used by 'real'.
 *
 * Returns: the old precision.
 * This is not supported on all platforms.
 */
PrecisionControl reduceRealPrecision(PrecisionControl prec) {
   version(D_InlineAsm_X86) {
        short cont;
        asm {
            fstcw cont;
            mov CX, cont;
            mov AX, cont;
            and EAX, 0x0300; // Form the return value
            and CX,  0xFCFF;
            or  CX,  prec;
            mov cont, CX;
            fldcw cont;
        }
    } else {
           assert(0, "Not yet supported");
    }
}

/**
 * Separate floating point value into significand and exponent.
 *
 * Returns:
 *  Calculate and return <i>x</i> and exp such that
 *  value =<i>x</i>*2$(SUP exp) and
 *  .5 &lt;= |<i>x</i>| &lt; 1.0<br>
 *  <i>x</i> has same sign as value.
 *
 *  $(TABLE_SV
 *  <tr> <th> value          <th> returns        <th> exp
 *  <tr> <td> &plusmn;0.0    <td> &plusmn;0.0    <td> 0
 *  <tr> <td> +&infin;       <td> +&infin;       <td> int.max
 *  <tr> <td> -&infin;       <td> -&infin;       <td> int.min
 *  <tr> <td> &plusmn;$(NAN) <td> &plusmn;$(NAN) <td> int.min
 *  )
 */
real frexp(real value, out int exp)
{
    ushort* vu = cast(ushort*)&value;
    long* vl = cast(long*)&value;
    uint ex;
    alias floatTraits!(real) F;

    ex = vu[F.EXPPOS_SHORT] & F.EXPMASK;
  static if (real.mant_dig == 64) { // real80
    if (ex) { // If exponent is non-zero
        if (ex == F.EXPMASK) {   // infinity or NaN
            if (*vl &  0x7FFF_FFFF_FFFF_FFFF) {  // NaN
                *vl |= 0xC000_0000_0000_0000;  // convert $(NAN)S to $(NAN)Q
                exp = int.min;
            } else if (vu[F.EXPPOS_SHORT] & 0x8000) {   // negative infinity
                exp = int.min;
            } else {   // positive infinity
                exp = int.max;
            }
        } else {
            exp = ex - F.EXPBIAS;
            vu[F.EXPPOS_SHORT] = cast(ushort)((0x8000 & vu[F.EXPPOS_SHORT]) | 0x3FFE);
        }
    } else if (!*vl) {
        // value is +-0.0
        exp = 0;
    } else {
        // denormal
        value *= F.POW2MANTDIG;
        ex = vu[F.EXPPOS_SHORT] & F.EXPMASK;
        exp = ex - F.EXPBIAS - 63;
        vu[F.EXPPOS_SHORT] = cast(ushort)((0x8000 & vu[F.EXPPOS_SHORT]) | 0x3FFE);
    }
    return value;
  } else static if (real.mant_dig == 113) { // quadruple      
        if (ex) { // If exponent is non-zero
            if (ex == F.EXPMASK) {   // infinity or NaN
                if (vl[MANTISSA_LSB] |( vl[MANTISSA_MSB]&0x0000_FFFF_FFFF_FFFF)) {  // NaN
                    vl[MANTISSA_MSB] |= 0x0000_8000_0000_0000;  // convert $(NAN)S to $(NAN)Q
                    exp = int.min;
                } else if (vu[F.EXPPOS_SHORT] & 0x8000) {   // negative infinity
                    exp = int.min;
                } else {   // positive infinity
                    exp = int.max;
                }
            } else {
                exp = ex - F.EXPBIAS;
                vu[F.EXPPOS_SHORT] = cast(ushort)((0x8000 & vu[F.EXPPOS_SHORT]) | 0x3FFE);
            }
        } else if ((vl[MANTISSA_LSB] |(vl[MANTISSA_MSB]&0x0000_FFFF_FFFF_FFFF))==0) {
            // value is +-0.0
            exp = 0;
    } else {
        // denormal
        value *= F.POW2MANTDIG;
        ex = vu[F.EXPPOS_SHORT] & F.EXPMASK;
        exp = ex - F.EXPBIAS - 113;
        vu[F.EXPPOS_SHORT] = cast(ushort)((0x8000 & vu[F.EXPPOS_SHORT]) | 0x3FFE);
    }
    return value;
  } else static if (real.mant_dig==53) { // real is double
    if (ex) { // If exponent is non-zero
        if (ex == F.EXPMASK) {   // infinity or NaN
            if (*vl==0x7FF0_0000_0000_0000) {  // positive infinity
                exp = int.max;
            } else if (*vl==0xFFF0_0000_0000_0000) { // negative infinity
                exp = int.min;
            } else { // NaN
                *vl |= 0x0008_0000_0000_0000;  // convert $(NAN)S to $(NAN)Q
                exp = int.min;
            }
        } else {
            exp = (ex - F.EXPBIAS) >>> 4;
            ve[F.EXPPOS_SHORT] = (0x8000 & ve[F.EXPPOS_SHORT]) | 0x3FE0;
        }
    } else if (!(*vl & 0x7FFF_FFFF_FFFF_FFFF)) {
        // value is +-0.0
        exp = 0;
    } else {
        // denormal
        ushort sgn;
        sgn = (0x8000 & ve[F.EXPPOS_SHORT])| 0x3FE0;
        *vl &= 0x7FFF_FFFF_FFFF_FFFF;

        int i = -0x3FD+11;
        do {
            i--;
            *vl <<= 1;
        } while (*vl > 0);
        exp = i;
        ve[F.EXPPOS_SHORT] = sgn;
    }
    return value;
  }else { //static if(real.mant_dig==106) // doubledouble
        assert(0, "Unsupported");
  }
}

debug(UnitTest) {

unittest
{
    static real vals[][3] = // x,frexp,exp
    [
        [0.0,   0.0,    0],
        [-0.0,  -0.0,   0],
        [1.0,   .5, 1],
        [-1.0,  -.5,    1],
        [2.0,   .5, 2],
        [double.min/2.0, .5, -1022],
        [real.infinity,real.infinity,int.max],
        [-real.infinity,-real.infinity,int.min],
        [real.nan,real.nan,int.min],
        [-real.nan,-real.nan,int.min],
    ];

    int i;

    for (i = 0; i < vals.length; i++) {
        real x = vals[i][0];
        real e = vals[i][1];
        int exp = cast(int)vals[i][2];
        int eptr;
        real v = frexp(x, eptr);
//        printf("frexp(%La) = %La, should be %La, eptr = %d, should be %d\n", x, v, e, eptr, exp);
        assert(isIdentical(e, v));
        assert(exp == eptr);

    }
   static if (real.mant_dig == 64) {
     static real extendedvals[][3] = [ // x,frexp,exp
        [0x1.a5f1c2eb3fe4efp+73, 0x1.A5F1C2EB3FE4EFp-1,   74],    // normal
        [0x1.fa01712e8f0471ap-1064,  0x1.fa01712e8f0471ap-1,     -1063],
        [real.min,  .5,     -16381],
        [real.min/2.0L, .5,     -16382]    // denormal
     ];

    for (i = 0; i < extendedvals.length; i++) {
        real x = extendedvals[i][0];
        real e = extendedvals[i][1];
        int exp = cast(int)extendedvals[i][2];
        int eptr;
        real v = frexp(x, eptr);
        assert(isIdentical(e, v));
        assert(exp == eptr);

    }
  }
}
}

/**
 * Compute n * 2$(SUP exp)
 * References: frexp
 */
real ldexp(real n, int exp) /* intrinsic */
{
    version(DigitalMars_D_InlineAsm_X86)
    {
        asm {
            fild exp;
            fld n;
            fscale;
            fstp ST(1), ST(0);
        }
    }
    else
    {
        return tango.stdc.math.ldexpl(n, exp);
    }
}

/**
 * Extracts the exponent of x as a signed integral value.
 *
 * If x is not a special value, the result is the same as
 * <tt>cast(int)logb(x)</tt>.
 *
 * Remarks: This function is consistent with IEEE754R, but it
 * differs from the C function of the same name
 * in the return value of infinity. (in C, ilogb(real.infinity)== int.max).
 * Note that the special return values may all be equal.
 *
 *  $(TABLE_SV
 *  <tr> <th> x               <th>ilogb(x)           <th>invalid?
 *  <tr> <td> 0               <td> FP_ILOGB0         <th> yes
 *  <tr> <td> &plusmn;&infin; <td> FP_ILOGBINFINITY  <th> yes
 *  <tr> <td> $(NAN)          <td> FP_ILOGBNAN       <th> yes
 *  )
 */
int ilogb(real x)
{
        version(DigitalMars_D_InlineAsm_X86)
        {
            int y;
            asm {
                fld x;
                fxtract;
                fstp ST(0), ST; // drop significand
                fistp y, ST(0); // and return the exponent
            }
            return y;
        } else static if (real.mant_dig==64) { // 80-bit reals
            alias floatTraits!(real) F;
            short e = cast(short)((cast(short *)&x)[F.EXPPOS_SHORT] & F.EXPMASK);
            if (e == F.EXPMASK) {
                // BUG: should also set the invalid exception
                ulong s = *cast(ulong *)&x;
                if (s == 0x8000_0000_0000_0000) {
                    return FP_ILOGBINFINITY;
                }
                else return FP_ILOGBNAN;
            }
            if (e==0) {
                ulong s = *cast(ulong *)&x;
                if (s == 0x0000_0000_0000_0000) {
                    // BUG: should also set the invalid exception
                    return FP_ILOGB0;
                }
                // Denormals
                x *= F.POW2MANTDIG;
                short f = (cast(short *)&x)[F.EXPPOS_SHORT];
                return -0x3FFF - (63-f);
            }
            return e - 0x3FFF;
        } else {
        return tango.stdc.math.ilogbl(x);
    }
}

version (X86)
{
    const int FP_ILOGB0        = -int.max-1;
    const int FP_ILOGBNAN      = -int.max-1;
    const int FP_ILOGBINFINITY = -int.max-1;
} else {
    alias tango.stdc.math.FP_ILOGB0   FP_ILOGB0;
    alias tango.stdc.math.FP_ILOGBNAN FP_ILOGBNAN;
    const int FP_ILOGBINFINITY = int.max;
}

debug(UnitTest) {
unittest {
    assert(ilogb(1.0) == 0);
    assert(ilogb(65536) == 16);
    assert(ilogb(-65536) == 16);
    assert(ilogb(1.0 / 65536) == -16);
    assert(ilogb(real.nan) == FP_ILOGBNAN);
    assert(ilogb(0.0) == FP_ILOGB0);
    assert(ilogb(-0.0) == FP_ILOGB0);
    // denormal
    assert(ilogb(0.125 * real.min) == real.min_exp - 4);
    assert(ilogb(real.infinity) == FP_ILOGBINFINITY);
}
}

/**
 * Extracts the exponent of x as a signed integral value.
 *
 * If x is subnormal, it is treated as if it were normalized.
 * For a positive, finite x:
 *
 * -----
 * 1 <= $(I x) * FLT_RADIX$(SUP -logb(x)) < FLT_RADIX
 * -----
 *
 *  $(TABLE_SV
 *  <tr> <th> x               <th> logb(x)  <th> Divide by 0?
 *  <tr> <td> &plusmn;&infin; <td> +&infin; <td> no
 *  <tr> <td> &plusmn;0.0     <td> -&infin; <td> yes
 *  )
 */
real logb(real x)
{
    version(DigitalMars_D_InlineAsm_X86)
    {
        asm {
            fld x;
            fxtract;
            fstp ST(0), ST; // drop significand
        }
    } else {
        return tango.stdc.math.logbl(x);
    }
}

debug(UnitTest) {
unittest {
    assert(logb(real.infinity)== real.infinity);
    assert(isIdentical(logb(NaN(0xFCD)), NaN(0xFCD)));
    assert(logb(1.0)== 0.0);
    assert(logb(-65536) == 16);
    assert(logb(0.0)== -real.infinity);
    assert(ilogb(0.125*real.min) == real.min_exp-4);
}
}

/**
 * Efficiently calculates x * 2$(SUP n).
 *
 * scalbn handles underflow and overflow in
 * the same fashion as the basic arithmetic operators.
 *
 *  $(TABLE_SV
 *  <tr> <th> x                <th> scalb(x)
 *  <tr> <td> &plusmn;&infin; <td> &plusmn;&infin;
 *  <tr> <td> &plusmn;0.0      <td> &plusmn;0.0
 *  )
 */
real scalbn(real x, int n)
{
    version(DigitalMars_D_InlineAsm_X86)
    {
        asm {
            fild n;
            fld x;
            fscale;
            fstp ST(1), ST;
        }
    } else {
        // NOTE: Not implemented in DMD
        return tango.stdc.math.scalbnl(x, n);
    }
}

debug(UnitTest) {
unittest {
    assert(scalbn(-real.infinity, 5) == -real.infinity);
    assert(isIdentical(scalbn(NaN(0xABC),7), NaN(0xABC)));
}
}

/**
 * Returns the positive difference between x and y.
 *
 * If either of x or y is $(NAN), it will be returned.
 * Returns:
 * $(TABLE_SV
 *  $(SVH Arguments, fdim(x, y))
 *  $(SV x &gt; y, x - y)
 *  $(SV x &lt;= y, +0.0)
 * )
 */
real fdim(real x, real y)
{
    return (x !<= y) ? x - y : +0.0;
}

debug(UnitTest) {
unittest {
    assert(isIdentical(fdim(NaN(0xABC), 58.2), NaN(0xABC)));
}
}

/**
 * Returns |x|
 *
 *  $(TABLE_SV
 *  <tr> <th> x               <th> fabs(x)
 *  <tr> <td> &plusmn;0.0     <td> +0.0
 *  <tr> <td> &plusmn;&infin; <td> +&infin;
 *  )
 */
real fabs(real x) /* intrinsic */
{
    version(D_InlineAsm_X86)
    {
        asm {
            fld x;
            fabs;
        }
    }
    else
    {
        return tango.stdc.math.fabsl(x);
    }
}

unittest {
    assert(isIdentical(fabs(NaN(0xABC)), NaN(0xABC)));
}

/**
 * Returns (x * y) + z, rounding only once according to the
 * current rounding mode.
 *
 * BUGS: Not currently implemented - rounds twice.
 */
real fma(float x, float y, float z)
{
    return (x * y) + z;
}

/**
 * Calculate cos(y) + i sin(y).
 *
 * On x86 CPUs, this is a very efficient operation;
 * almost twice as fast as calculating sin(y) and cos(y)
 * seperately, and is the preferred method when both are required.
 */
creal expi(real y)
{
    version(DigitalMars_D_InlineAsm_X86)
    {
        asm {
            fld y;
            fsincos;
            fxch ST(1), ST(0);
        }
    }
    else
    {
        return tango.stdc.math.cosl(y) + tango.stdc.math.sinl(y)*1i;
    }
}

debug(UnitTest) {
unittest
{
    assert(expi(1.3e5L) == tango.stdc.math.cosl(1.3e5L) + tango.stdc.math.sinl(1.3e5L) * 1i);
    assert(expi(0.0L) == 1L + 0.0Li);
}
}

/*********************************
 * Returns !=0 if e is a NaN.
 */

int isNaN(real x)
{
  alias floatTraits!(real) F;
  static if (real.mant_dig==53) { // double
        ulong*  p = cast(ulong *)&x;
        return (*p & 0x7FF0_0000_0000_0000 == 0x7FF0_0000_0000_0000) && *p & 0x000F_FFFF_FFFF_FFFF;
  } else static if (real.mant_dig==64) {     // real80
        // Prevent a ridiculous warning (why does (ushort | ushort) get promoted to int???)
        ushort e = cast(ushort)(F.EXPMASK & (cast(ushort *)&x)[F.EXPPOS_SHORT]);
        ulong*  ps = cast(ulong *)&x;
        return e == F.EXPMASK &&
            *ps & 0x7FFF_FFFF_FFFF_FFFF; // not infinity
  } else static if (real.mant_dig==113) {  // quadruple
        ushort e = cast(ushort)(F.EXPMASK & (cast(ushort *)&x)[F.EXPPOS_SHORT]);
        ulong*  ps = cast(ulong *)&x;
        return e == F.EXPMASK &&
           (ps[MANTISSA_LSB] | (ps[MANTISSA_MSB]& 0x0000_FFFF_FFFF_FFFF))!=0;
  } else {
      return x!=x;
  }
}


debug(UnitTest) {
unittest
{
    assert(isNaN(float.nan));
    assert(isNaN(-double.nan));
    assert(isNaN(real.nan));

    assert(!isNaN(53.6));
    assert(!isNaN(float.infinity));
}
}

/**
 * Returns !=0 if x is normalized.
 *
 * (Need one for each format because subnormal
 *  floats might be converted to normal reals)
 */
int isNormal(X)(X x)
{
    alias floatTraits!(X) F;
    
    static if(real.mant_dig==106) { // doubledouble
    // doubledouble is normal if the least significant part is normal.
        return isNormal((cast(double*)&x)[MANTISSA_LSB]);
    } else {
        // ridiculous DMD warning
        ushort e = cast(ushort)(F.EXPMASK & (cast(ushort *)&x)[F.EXPPOS_SHORT]);
        return (e != F.EXPMASK && e!=0);
    }
}

debug(UnitTest) {
unittest
{
    float f = 3;
    double d = 500;
    real e = 10e+48;

    assert(isNormal(f));
    assert(isNormal(d));
    assert(isNormal(e));
    f=d=e=0;
    assert(!isNormal(f));
    assert(!isNormal(d));
    assert(!isNormal(e));
    assert(!isNormal(real.infinity));
    assert(isNormal(-real.max));
    assert(!isNormal(real.min/4));
    
}
}

/*********************************
 * Is the binary representation of x identical to y?
 *
 * Same as ==, except that positive and negative zero are not identical,
 * and two $(NAN)s are identical if they have the same 'payload'.
 */

bool isIdentical(real x, real y)
{
    // We're doing a bitwise comparison so the endianness is irrelevant.
    long*   pxs = cast(long *)&x;
    long*   pys = cast(long *)&y;
  static if (real.mant_dig == 53){ //double
    return pxs[0] == pys[0];
  } else static if (real.mant_dig == 113 || real.mant_dig==106) {
      // quadruple or doubledouble
    return pxs[0] == pys[0] && pxs[1] == pys[1];
  } else { // real80
    ushort* pxe = cast(ushort *)&x;
    ushort* pye = cast(ushort *)&y;
    return pxe[4] == pye[4] && pxs[0] == pys[0];
  }
}

/** ditto */
bool isIdentical(ireal x, ireal y) {
    return isIdentical(x.im, y.im);
}

/** ditto */
bool isIdentical(creal x, creal y) {
    return isIdentical(x.re, y.re) && isIdentical(x.im, y.im);
}

debug(UnitTest) {
unittest {
    assert(isIdentical(0.0, 0.0));
    assert(!isIdentical(0.0, -0.0));
    assert(isIdentical(NaN(0xABC), NaN(0xABC)));
    assert(!isIdentical(NaN(0xABC), NaN(218)));
    assert(isIdentical(1.234e56, 1.234e56));
    assert(isNaN(NaN(0x12345)));
    assert(isIdentical(3.1 + NaN(0xDEF) * 1i, 3.1 + NaN(0xDEF)*1i));
    assert(!isIdentical(3.1+0.0i, 3.1-0i));
    assert(!isIdentical(0.0i, 2.5e58i));
}
}

/*********************************
 * Is number subnormal? (Also called "denormal".)
 * Subnormals have a 0 exponent and a 0 most significant significand bit,
 * but are non-zero.
 */

/* Need one for each format because subnormal floats might
 * be converted to normal reals.
 */

int isSubnormal(float f)
{
    uint *p = cast(uint *)&f;
    return (*p & 0x7F80_0000) == 0 && *p & 0x007F_FFFF;
}

debug(UnitTest) {
unittest
{
    float f = -float.min;
    assert(!isSubnormal(f));
    f/=4;
    assert(isSubnormal(f));
}
}

/// ditto

int isSubnormal(double d)
{
    uint *p = cast(uint *)&d;
    return (p[MANTISSA_MSB] & 0x7FF0_0000) == 0 && (p[MANTISSA_LSB] || p[MANTISSA_MSB] & 0x000F_FFFF);
}

debug(UnitTest) {
unittest
{
    double f;

    for (f = 1; !isSubnormal(f); f /= 2)
    assert(f != 0);
}
}

/// ditto

int isSubnormal(real x)
{
    alias floatTraits!(real) F;
    static if (real.mant_dig == 53) { // double
        return isSubnormal(cast(double)x);
    } else static if (real.mant_dig == 113) { // quadruple        
        ushort e = F.EXPMASK & (cast(ushort *)&x)[F.EXPPOS_SHORT];
        long*   ps = cast(long *)&x;
        return (e == 0 && (((ps[MANTISSA_LSB]|(ps[MANTISSA_MSB]& 0x0000_FFFF_FFFF_FFFF))) !=0));
    } else static if (real.mant_dig==64) { // real80
        ushort* pe = cast(ushort *)&x;
        long*   ps = cast(long *)&x;

        return (pe[F.EXPPOS_SHORT] & F.EXPMASK) == 0 && *ps > 0;
    } else { // double double
        return isSubnormal(cast(double*)(&x)[MANTISSA_MSB]);
    }
}

debug(UnitTest) {
unittest
{
    real f;

    for (f = 1; !isSubnormal(f); f /= 2)
    assert(f != 0);
}
}

/*********************************
 * Return !=0 if x is &plusmn;0.
 *
 * Does not affect any floating-point flags
 */
int isZero(real x)
{
    alias floatTraits!(real) F;
    static if (real.mant_dig == 53) { // double
        return ((*cast(ulong *)&x) & 0x7FFF_FFFF_FFFF_FFFF) == 0;
    } else static if (real.mant_dig == 113) { // quadruple   
        long*   ps = cast(long *)&x;
        return (ps[MANTISSA_LSB] | (ps[MANTISSA_MSB]& 0x7FFF_FFFF_FFFF_FFFF)) == 0;
    } else { // real80
        ushort* pe = cast(ushort *)&x;
        ulong*  ps = cast(ulong  *)&x;
        return (pe[F.EXPPOS_SHORT] & F.EXPMASK) == 0 && *ps == 0;
    }
}

debug(UnitTest) {
unittest
{
    assert(isZero(0.0));
    assert(isZero(-0.0));
    assert(!isZero(2.5));
    assert(!isZero(real.min / 1000));
}
}

/*********************************
 * Return !=0 if e is &plusmn;&infin;.
 */

int isInfinity(real x)
{
    alias floatTraits!(real) F;
    static if (real.mant_dig == 53) { // double
        return ((*cast(ulong *)&x) & 0x7FFF_FFFF_FFFF_FFFF) == 0x7FF8_0000_0000_0000;
    } else static if(real.mant_dig == 106) { //doubledouble
        return (((cast(ulong *)&x)[MANTISSA_MSB]) & 0x7FFF_FFFF_FFFF_FFFF) == 0x7FF8_0000_0000_0000;   
    } else static if (real.mant_dig == 113) { // quadruple   
        long*   ps = cast(long *)&x;
        return (ps[MANTISSA_LSB] == 0) 
         && (ps[MANTISSA_MSB] & 0x7FFF_FFFF_FFFF_FFFF) == 0x7FFF_0000_0000_0000;
    } else { // real80
        ushort e = cast(ushort)(F.EXPMASK & (cast(ushort *)&x)[F.EXPPOS_SHORT]);
        ulong*  ps = cast(ulong *)&x;

        return e == F.EXPMASK && *ps == 0x8000_0000_0000_0000;
   }
}

debug(UnitTest) {
unittest
{
    assert(isInfinity(float.infinity));
    assert(!isInfinity(float.nan));
    assert(isInfinity(double.infinity));
    assert(isInfinity(-real.infinity));

    assert(isInfinity(-1.0 / 0.0));
}
}

/**
 * Calculate the next largest floating point value after x.
 *
 * Return the least number greater than x that is representable as a real;
 * thus, it gives the next point on the IEEE number line.
 * This function is included in the forthcoming IEEE 754R standard.
 *
 *  $(TABLE_SV
 *    $(SVH x,             nextup(x)   )
 *    $(SV  -&infin;,      -real.max   )
 *    $(SV  &plusmn;0.0,   real.min*real.epsilon )
 *    $(SV  real.max,      real.infinity )
 *    $(SV  real.infinity, real.infinity )
 *    $(SV  $(NAN),        $(NAN)        )
 * )
 *
 * nextDoubleUp and nextFloatUp are the corresponding functions for
 * the IEEE double and IEEE float number lines.
 */
real nextUp(real x)
{
    alias floatTraits!(real) F;
    static if (real.mant_dig == 53) { // double
        return nextDoubleUp(x);
    } else static if(real.mant_dig==113) {  // quadruple
        ushort e = F.EXPMASK & (cast(ushort *)&x)[F.EXPPOS_SHORT];
        if (e == F.EXPMASK) { // NaN or Infinity
             if (x == -real.infinity) return -real.max;
             return x; // +Inf and NaN are unchanged.
        }     
        ulong*   ps = cast(ulong *)&e;
        if (ps[MANTISSA_LSB] & 0x8000_0000_0000_0000)  { // Negative number
            if (ps[MANTISSA_LSB]==0 && ps[MANTISSA_MSB] == 0x8000_0000_0000_0000) { // it was negative zero
                ps[MANTISSA_LSB] = 0x0000_0000_0000_0001; // change to smallest subnormal
                ps[MANTISSA_MSB] = 0;
                return x;
            }
            --*ps;
            if (ps[MANTISSA_LSB]==0) --ps[MANTISSA_MSB];
        } else { // Positive number
            ++ps[MANTISSA_LSB];
            if (ps[MANTISSA_LSB]==0) ++ps[MANTISSA_MSB];
        }
        return x;
          
    } else static if(real.mant_dig==64){ // real80
        // For 80-bit reals, the "implied bit" is a nuisance...
        ushort *pe = cast(ushort *)&x;
        ulong  *ps = cast(ulong  *)&x;

        if ((pe[F.EXPPOS_SHORT] & F.EXPMASK) == F.EXPMASK) {
            // First, deal with NANs and infinity
            if (x == -real.infinity) return -real.max;
            return x; // +Inf and NaN are unchanged.
        }
        if (pe[F.EXPPOS_SHORT] & 0x8000)  { // Negative number -- need to decrease the significand
            --*ps;
            // Need to mask with 0x7FFF... so subnormals are treated correctly.
            if ((*ps & 0x7FFF_FFFF_FFFF_FFFF) == 0x7FFF_FFFF_FFFF_FFFF) {
                if (pe[F.EXPPOS_SHORT] == 0x8000) { // it was negative zero
                    *ps = 1;
                    pe[F.EXPPOS_SHORT] = 0; // smallest subnormal.
                    return x;
                }
                --pe[F.EXPPOS_SHORT];
                if (pe[F.EXPPOS_SHORT] == 0x8000) {
                    return x; // it's become a subnormal, implied bit stays low.
                }
                *ps = 0xFFFF_FFFF_FFFF_FFFF; // set the implied bit
                return x;
            }
            return x;
        } else {
            // Positive number -- need to increase the significand.
            // Works automatically for positive zero.
            ++*ps;
            if ((*ps & 0x7FFF_FFFF_FFFF_FFFF) == 0) {
                // change in exponent
                ++pe[F.EXPPOS_SHORT];
                *ps = 0x8000_0000_0000_0000; // set the high bit
            }
        }
        return x;
    } else { // doubledouble
        assert(0, "Not implemented");
    }
}

/** ditto */
double nextDoubleUp(double x)
{
    ulong *ps = cast(ulong *)&x;

    if ((*ps & 0x7FF0_0000_0000_0000) == 0x7FF0_0000_0000_0000) {
        // First, deal with NANs and infinity
        if (x == -x.infinity) return -x.max;
        return x; // +INF and NAN are unchanged.
    }
    if (*ps & 0x8000_0000_0000_0000)  { // Negative number
        if (*ps == 0x8000_0000_0000_0000) { // it was negative zero
            *ps = 0x0000_0000_0000_0001; // change to smallest subnormal
            return x;
        }
        --*ps;
    } else { // Positive number
        ++*ps;
    }
    return x;
}

/** ditto */
float nextFloatUp(float x)
{
    uint *ps = cast(uint *)&x;

    if ((*ps & 0x7F80_0000) == 0x7F80_0000) {
        // First, deal with NANs and infinity
        if (x == -x.infinity) return -x.max;
        return x; // +INF and NAN are unchanged.
    }
    if (*ps & 0x8000_0000)  { // Negative number
        if (*ps == 0x8000_0000) { // it was negative zero
            *ps = 0x0000_0001; // change to smallest subnormal
            return x;
        }
        --*ps;
    } else { // Positive number
        ++*ps;
    }
    return x;
}

debug(UnitTest) {
unittest {
 static if (real.mant_dig == 64) {

  // Tests for 80-bit reals

    assert(isIdentical(nextUp(NaN(0xABC)), NaN(0xABC)));
    // negative numbers
    assert( nextUp(-real.infinity) == -real.max );
    assert( nextUp(-1-real.epsilon) == -1.0 );
    assert( nextUp(-2) == -2.0 + real.epsilon);
    // denormals and zero
    assert( nextUp(-real.min) == -real.min*(1-real.epsilon) );
    assert( nextUp(-real.min*(1-real.epsilon) == -real.min*(1-2*real.epsilon)) );
    assert( isIdentical(-0.0L, nextUp(-real.min*real.epsilon)) );
    assert( nextUp(-0.0) == real.min*real.epsilon );
    assert( nextUp(0.0) == real.min*real.epsilon );
    assert( nextUp(real.min*(1-real.epsilon)) == real.min );
    assert( nextUp(real.min) == real.min*(1+real.epsilon) );
    // positive numbers
    assert( nextUp(1) == 1.0 + real.epsilon );
    assert( nextUp(2.0-real.epsilon) == 2.0 );
    assert( nextUp(real.max) == real.infinity );
    assert( nextUp(real.infinity)==real.infinity );
 }

    assert(isIdentical(nextDoubleUp(NaN(0xABC)), NaN(0xABC)));
    // negative numbers
    assert( nextDoubleUp(-double.infinity) == -double.max );
    assert( nextDoubleUp(-1-double.epsilon) == -1.0 );
    assert( nextDoubleUp(-2) == -2.0 + double.epsilon);
    // denormals and zero

    assert( nextDoubleUp(-double.min) == -double.min*(1-double.epsilon) );
    assert( nextDoubleUp(-double.min*(1-double.epsilon) == -double.min*(1-2*double.epsilon)) );
    assert( isIdentical(-0.0, nextDoubleUp(-double.min*double.epsilon)) );
    assert( nextDoubleUp(0.0) == double.min*double.epsilon );
    assert( nextDoubleUp(-0.0) == double.min*double.epsilon );
    assert( nextDoubleUp(double.min*(1-double.epsilon)) == double.min );
    assert( nextDoubleUp(double.min) == double.min*(1+double.epsilon) );
    // positive numbers
    assert( nextDoubleUp(1) == 1.0 + double.epsilon );
    assert( nextDoubleUp(2.0-double.epsilon) == 2.0 );
    assert( nextDoubleUp(double.max) == double.infinity );

    assert(isIdentical(nextFloatUp(NaN(0xABC)), NaN(0xABC)));
    assert( nextFloatUp(-float.min) == -float.min*(1-float.epsilon) );
    assert( nextFloatUp(1.0) == 1.0+float.epsilon );
    assert( nextFloatUp(-0.0) == float.min*float.epsilon);
    assert( nextFloatUp(float.infinity)==float.infinity );

    assert(nextDown(1.0+real.epsilon)==1.0);
    assert(nextDoubleDown(1.0+double.epsilon)==1.0);
    assert(nextFloatDown(1.0+float.epsilon)==1.0);
    assert(nextafter(1.0+real.epsilon, -real.infinity)==1.0);
}
}

package {
/** Reduces the magnitude of x, so the bits in the lower half of its significand
 * are all zero. Returns the amount which needs to be added to x to restore its
 * initial value; this amount will also have zeros in all bits in the lower half
 * of its significand.
 */
X splitSignificand(X)(inout X x)
{
    if (fabs(x) !< X.infinity) return 0; // don't change NaN or infinity
    X y = x; // copy the original value
    static if (X.mant_dig == float.mant_dig) {
        uint *ps = cast(uint *)&x;
        (*ps) &= 0xFFFF_FC00;
    } else static if (X.mant_dig == 53) {
        ulong *ps = cast(ulong *)&x;
        (*ps) &= 0xFFFF_FFFF_FC00_0000L;
    } else static if (X.mant_dig == 64){ // 80-bit real
        // An x87 real80 has 63 bits, because the 'implied' bit is stored explicitly.
        // This is annoying, because it means the significand cannot be
        // precisely halved. Instead, we split it into 31+32 bits.
        ulong *ps = cast(ulong *)&x;
        (*ps) &= 0xFFFF_FFFF_0000_0000L;
    } else static if (X.mant_dig==113) { // quadruple
        ulong *ps = cast(ulong *)&x;
        ps[MANTISSA_LSB] &= 0xFF00_0000_0000_0000L;
    }
    //else static assert(0, "Unsupported size");

    return y - x;
}

unittest {
    double x = -0x1.234_567A_AAAA_AAp+250;
    double y = splitSignificand(x);
    assert(x == -0x1.234_5678p+250);
    assert(y == -0x0.000_000A_AAAA_A8p+248);
    assert(x + y == -0x1.234_567A_AAAA_AAp+250);
}
}

/**
 * Calculate the next smallest floating point value before x.
 *
 * Return the greatest number less than x that is representable as a real;
 * thus, it gives the previous point on the IEEE number line.
 * Note: This function is included in the forthcoming IEEE 754R standard.
 *
 * Special values:
 * real.infinity   real.max
 * real.min*real.epsilon 0.0
 * 0.0             -real.min*real.epsilon
 * -0.0            -real.min*real.epsilon
 * -real.max        -real.infinity
 * -real.infinity    -real.infinity
 * NAN              NAN
 *
 * nextDoubleDown and nextFloatDown are the corresponding functions for
 * the IEEE double and IEEE float number lines.
 */
real nextDown(real x)
{
    return -nextUp(-x);
}

/** ditto */
double nextDoubleDown(double x)
{
    return -nextDoubleUp(-x);
}

/** ditto */
float nextFloatDown(float x)
{
    return -nextFloatUp(-x);
}

debug(UnitTest) {
unittest {
    assert( nextDown(1.0 + real.epsilon) == 1.0);
}
}

/**
 * Calculates the next representable value after x in the direction of y.
 *
 * If y > x, the result will be the next largest floating-point value;
 * if y < x, the result will be the next smallest value.
 * If x == y, the result is y.
 *
 * Remarks:
 * This function is not generally very useful; it's almost always better to use
 * the faster functions nextUp() or nextDown() instead.
 *
 * IEEE 754 requirements not implemented:
 * The FE_INEXACT and FE_OVERFLOW exceptions will be raised if x is finite and
 * the function result is infinite. The FE_INEXACT and FE_UNDERFLOW
 * exceptions will be raised if the function value is subnormal, and x is
 * not equal to y.
 */
real nextafter(real x, real y)
{
    if (x==y) return y;
    return (y>x) ? nextUp(x) : nextDown(x);
}

/**************************************
 * To what precision is x equal to y?
 *
 * Returns: the number of significand bits which are equal in x and y.
 * eg, 0x1.F8p+60 and 0x1.F1p+60 are equal to 5 bits of precision.
 *
 *  $(TABLE_SV
 *    $(SVH3 x,      y,         feqrel(x, y)  )
 *    $(SV3  x,      x,         real.mant_dig )
 *    $(SV3  x,      &gt;= 2*x, 0 )
 *    $(SV3  x,      &lt;= x/2, 0 )
 *    $(SV3  $(NAN), any,       0 )
 *    $(SV3  any,    $(NAN),    0 )
 *  )
 *
 * Remarks:
 * This is a very fast operation, suitable for use in speed-critical code.
 */
int feqrel(X)(X x, X y)
{
    /* Public Domain. Author: Don Clugston, 18 Aug 2005.
     */
  static assert(is(X==real) || is(X==double) || is(X==float), "Only float, double, and real are supported by feqrel");
  
  static if (X.mant_dig == 106) { // doubledouble.
     int a = feqrel(cast(double*)(&x)[MANTISSA_MSB], cast(double*)(&y)[MANTISSA_MSB]);
     if (a != double.mant_dig) return a;
     return double.mant_dig + feqrel(cast(double*)(&x)[MANTISSA_LSB], cast(double*)(&y)[MANTISSA_LSB]);     
  } else static if (X.mant_dig==64 || X.mant_dig==113 || X.mant_dig==53) {
      
    if (x == y) return X.mant_dig; // ensure diff!=0, cope with INF.

    X diff = fabs(x - y);

    ushort *pa = cast(ushort *)(&x);
    ushort *pb = cast(ushort *)(&y);
    ushort *pd = cast(ushort *)(&diff);

    alias floatTraits!(X) F;

    // The difference in abs(exponent) between x or y and abs(x-y)
    // is equal to the number of significand bits of x which are
    // equal to y. If negative, x and y have different exponents.
    // If positive, x and y are equal to 'bitsdiff' bits.
    // AND with 0x7FFF to form the absolute value.
    // To avoid out-by-1 errors, we subtract 1 so it rounds down
    // if the exponents were different. This means 'bitsdiff' is
    // always 1 lower than we want, except that if bitsdiff==0,
    // they could have 0 or 1 bits in common.

 static if (X.mant_dig==64 || X.mant_dig==113) { // real80 or quadruple
    int bitsdiff = ( ((pa[F.EXPPOS_SHORT]&0x7FFF) + (pb[F.EXPPOS_SHORT]&0x7FFF)-1)>>1) 
                - pd[F.EXPPOS_SHORT];
 } else static if (X.mant_dig==53) { // double
    int bitsdiff = (( ((pa[F.EXPPOS_SHORT]&0x7FF0) + (pb[F.EXPPOS_SHORT]&0x7FF0)-0x10)>>1) 
                 - (pd[F.EXPPOS_SHORT]&0x7FF0))>>4;
 }
    if (pd[F.EXPPOS_SHORT] == 0)
    {   // Difference is denormal
        // For denormals, we need to add the number of zeros that
        // lie at the start of diff's significand.
        // We do this by multiplying by 2^real.mant_dig
        diff *= F.POW2MANTDIG;
        return bitsdiff + X.mant_dig - pd[F.EXPPOS_SHORT];
    }

    if (bitsdiff > 0)
        return bitsdiff + 1; // add the 1 we subtracted before
        
    // Avoid out-by-1 errors when factor is almost 2.    
     static if (X.mant_dig==64 || X.mant_dig==113) { // real80 or quadruple    
        return (bitsdiff == 0) ? (pa[F.EXPPOS_SHORT] == pb[F.EXPPOS_SHORT]) : 0;
     } else static if (X.mant_dig==53) { // double
        if (bitsdiff == 0 && !((pa[F.EXPPOS_SHORT] ^ pb[F.EXPPOS_SHORT])& F.EXPMASK)) return 1;
        else return 0;
     }  
 } else {
    assert(0, "Unsupported");
 }
}

debug(UnitTest) {
unittest
{
   // Exact equality
   assert(feqrel(real.max,real.max)==real.mant_dig);
   assert(feqrel(0.0L,0.0L)==real.mant_dig);
   assert(feqrel(7.1824L,7.1824L)==real.mant_dig);
   assert(feqrel(real.infinity,real.infinity)==real.mant_dig);

   // a few bits away from exact equality
   real w=1;
   for (int i=1; i<real.mant_dig-1; ++i) {
      assert(feqrel(1+w*real.epsilon,1.0L)==real.mant_dig-i);
      assert(feqrel(1-w*real.epsilon,1.0L)==real.mant_dig-i);
      assert(feqrel(1.0L,1+(w-1)*real.epsilon)==real.mant_dig-i+1);
      w*=2;
   }
   assert(feqrel(1.5+real.epsilon,1.5L)==real.mant_dig-1);
   assert(feqrel(1.5-real.epsilon,1.5L)==real.mant_dig-1);
   assert(feqrel(1.5-real.epsilon,1.5+real.epsilon)==real.mant_dig-2);
   
   assert(feqrel(real.min/8,real.min/17)==3);;
   
   // Numbers that are close
   assert(feqrel(0x1.Bp+84, 0x1.B8p+84)==5);
   assert(feqrel(0x1.8p+10, 0x1.Cp+10)==2);
   assert(feqrel(1.5*(1-real.epsilon), 1.0L)==2);
   assert(feqrel(1.5, 1.0)==1);
   assert(feqrel(2*(1-real.epsilon), 1.0L)==1);

   // Factors of 2
   assert(feqrel(real.max,real.infinity)==0);
   assert(feqrel(2*(1-real.epsilon), 1.0L)==1);
   assert(feqrel(1.0, 2.0)==0);
   assert(feqrel(4.0, 1.0)==0);

   // Extreme inequality
   assert(feqrel(real.nan,real.nan)==0);
   assert(feqrel(0.0L,-real.nan)==0);
   assert(feqrel(real.nan,real.infinity)==0);
   assert(feqrel(real.infinity,-real.infinity)==0);
   assert(feqrel(-real.max,real.infinity)==0);
   assert(feqrel(real.max,-real.max)==0);
}
}

/*********************************
 * Return 1 if sign bit of e is set, 0 if not.
 */

int signbit(real x)
{
    return ((cast(ubyte *)&x)[floatTraits!(real).SIGNPOS_BYTE] & 0x80) != 0;
}

debug(UnitTest) {
unittest
{
    assert(!signbit(float.nan));
    assert(signbit(-float.nan));
    assert(!signbit(168.1234));
    assert(signbit(-168.1234));
    assert(!signbit(0.0));
    assert(signbit(-0.0));
}
}


/*********************************
 * Return a value composed of to with from's sign bit.
 */

real copysign(real to, real from)
{
    ubyte* pto   = cast(ubyte *)&to;
    ubyte* pfrom = cast(ubyte *)&from;
    
    alias floatTraits!(real) F;
    pto[F.SIGNPOS_BYTE] &= 0x7F;
    pto[F.SIGNPOS_BYTE] |= pfrom[F.SIGNPOS_BYTE] & 0x80;
    return to;
}

debug(UnitTest) {
unittest
{
    real e;

    e = copysign(21, 23.8);
    assert(e == 21);

    e = copysign(-21, 23.8);
    assert(e == 21);

    e = copysign(21, -23.8);
    assert(e == -21);

    e = copysign(-21, -23.8);
    assert(e == -21);

    e = copysign(real.nan, -23.8);
    assert(isNaN(e) && signbit(e));
}
}

/** Return the value that lies halfway between x and y on the IEEE number line.
 *
 * Formally, the result is the arithmetic mean of the binary significands of x
 * and y, multiplied by the geometric mean of the binary exponents of x and y.
 * x and y must have the same sign, and must not be NaN.
 * Note: this function is useful for ensuring O(log n) behaviour in algorithms
 * involving a 'binary chop'.
 *
 * Special cases:
 * If x and y are within a factor of 2, (ie, feqrel(x, y) > 0), the return value
 * is the arithmetic mean (x + y) / 2.
 * If x and y are even powers of 2, the return value is the geometric mean,
 *   ieeeMean(x, y) = sqrt(x * y).
 *
 */
T ieeeMean(T)(T x, T y)
in {
    // both x and y must have the same sign, and must not be NaN.
    assert(signbit(x) == signbit(y)); 
    assert(x<>=0 && y<>=0);
}
body {
    // Runtime behaviour for contract violation:
    // If signs are opposite, or one is a NaN, return 0.
    if (!((x>=0 && y>=0) || (x<=0 && y<=0))) return 0.0;

    // The implementation is simple: cast x and y to integers,
    // average them (avoiding overflow), and cast the result back to a floating-point number.

    alias floatTraits!(real) F;
    T u;
    static if (T.mant_dig==64) { // real80
        // There's slight additional complexity because they are actually
        // 79-bit reals...
        ushort *ue = cast(ushort *)&u;
        ulong *ul = cast(ulong *)&u;
        ushort *xe = cast(ushort *)&x;
        ulong *xl = cast(ulong *)&x;
        ushort *ye = cast(ushort *)&y;
        ulong *yl = cast(ulong *)&y;
        // Ignore the useless implicit bit. (Bonus: this prevents overflows)
        ulong m = ((*xl) & 0x7FFF_FFFF_FFFF_FFFFL) + ((*yl) & 0x7FFF_FFFF_FFFF_FFFFL);

        ushort e = cast(ushort)((xe[F.EXPPOS_SHORT] & 0x7FFF) + (ye[F.EXPPOS_SHORT] & 0x7FFF));
        if (m & 0x8000_0000_0000_0000L) {
            ++e;
            m &= 0x7FFF_FFFF_FFFF_FFFFL;
        }
        // Now do a multi-byte right shift
        uint c = e & 1; // carry
        e >>= 1;
        m >>>= 1;
        if (c) m |= 0x4000_0000_0000_0000L; // shift carry into significand
        if (e) *ul = m | 0x8000_0000_0000_0000L; // set implicit bit...
        else *ul = m; // ... unless exponent is 0 (denormal or zero).
        // Prevent a ridiculous warning (why does (ushort | ushort) get promoted to int???)
        ue[4]= cast(ushort)( e | (xe[F.EXPPOS_SHORT]& 0x8000)); // restore sign bit
    } else static if(T.mant_dig == 113) { //quadruple
        // This would be trivial if 'ucent' were implemented...
        ulong *ul = cast(ulong *)&u;
        ulong *xl = cast(ulong *)&x;
        ulong *yl = cast(ulong *)&y;
        // Multi-byte add, then multi-byte right shift.        
        ulong mh = ((xl[MANTISSA_MSB] & 0x7FFF_FFFF_FFFF_FFFFL) 
                  + (yl[MANTISSA_MSB] & 0x7FFF_FFFF_FFFF_FFFFL));
        // Discard the lowest bit (to avoid overflow)
        ulong ml = (xl[MANTISSA_LSB]>>>1) + (yl[MANTISSA_LSB]>>>1);
        // add the lowest bit back in, if necessary.
        if (xl[MANTISSA_LSB] & yl[MANTISSA_LSB] & 1) {
            ++ml;
            if (ml==0) ++mh;
        }
        mh >>>=1;
        ul[MANTISSA_MSB] = mh | (xl[MANTISSA_MSB] & 0x8000_0000_0000_0000);
        ul[MANTISSA_LSB] = ml;
    } else static if (T.mant_dig == double.mant_dig) {
        ulong *ul = cast(ulong *)&u;
        ulong *xl = cast(ulong *)&x;
        ulong *yl = cast(ulong *)&y;
        ulong m = (((*xl) & 0x7FFF_FFFF_FFFF_FFFFL) + ((*yl) & 0x7FFF_FFFF_FFFF_FFFFL)) >>> 1;
        m |= ((*xl) & 0x8000_0000_0000_0000L);
        *ul = m;
    } else static if (T.mant_dig == float.mant_dig) {
        uint *ul = cast(uint *)&u;
        uint *xl = cast(uint *)&x;
        uint *yl = cast(uint *)&y;
        uint m = (((*xl) & 0x7FFF_FFFF) + ((*yl) & 0x7FFF_FFFF)) >>> 1;
        m |= ((*xl) & 0x8000_0000);
        *ul = m;
    } else {
        assert(0, "Not implemented");
    }
    return u;
}

debug(UnitTest) {
unittest {
    assert(ieeeMean(-0.0,-1e-20)<0);
    assert(ieeeMean(0.0,1e-20)>0);

    assert(ieeeMean(1.0L,4.0L)==2L);
    assert(ieeeMean(2.0*1.013,8.0*1.013)==4*1.013);
    assert(ieeeMean(-1.0L,-4.0L)==-2L);
    assert(ieeeMean(-1.0,-4.0)==-2);
    assert(ieeeMean(-1.0f,-4.0f)==-2f);
    assert(ieeeMean(-1.0,-2.0)==-1.5);
    assert(ieeeMean(-1*(1+8*real.epsilon),-2*(1+8*real.epsilon))==-1.5*(1+5*real.epsilon));
    assert(ieeeMean(0x1p60,0x1p-10)==0x1p25);
    static if (real.mant_dig==64) { // x87, 80-bit reals
      assert(ieeeMean(1.0L,real.infinity)==0x1p8192L);
      assert(ieeeMean(0.0L,real.infinity)==1.5);
    }
    assert(ieeeMean(0.5*real.min*(1-4*real.epsilon),0.5*real.min)==0.5*real.min*(1-2*real.epsilon));
}
}

// Functions for NaN payloads
/*
 * A 'payload' can be stored in the significand of a $(NAN). One bit is required
 * to distinguish between a quiet and a signalling $(NAN). This leaves 22 bits
 * of payload for a float; 51 bits for a double; 62 bits for an 80-bit real;
 * and 111 bits for a 128-bit quad.
*/
/**
 * Create a $(NAN), storing an integer inside the payload.
 *
 * For 80-bit or 128-bit reals, the largest possible payload is 0x3FFF_FFFF_FFFF_FFFF.
 * For doubles, it is 0x3_FFFF_FFFF_FFFF.
 * For floats, it is 0x3F_FFFF.
 */
real NaN(ulong payload)
{
    static if (real.mant_dig == 64) { //real80
      ulong v = 3; // implied bit = 1, quiet bit = 1
    } else {
      ulong v = 2; // no implied bit. quiet bit = 1
    }

    ulong a = payload;

    // 22 Float bits
    ulong w = a & 0x3F_FFFF;
    a -= w;

    v <<=22;
    v |= w;
    a >>=22;

    // 29 Double bits
    v <<=29;
    w = a & 0xFFF_FFFF;
    v |= w;
    a -= w;
    a >>=29;

    static if (real.mant_dig == 53) { // double
        v |=0x7FF0_0000_0000_0000;
        real x;
        * cast(ulong *)(&x) = v;
        return x;
    } else {
        v <<=11;
        a &= 0x7FF;
        v |= a;
        real x = real.nan;
        // Extended real bits
        static if (real.mant_dig==113) { //quadruple
          v<<=1; // there's no implicit bit
          version(LittleEndian) {
            *cast(ulong*)(6+cast(ubyte*)(&x)) = v;
          } else {
            *cast(ulong*)(2+cast(ubyte*)(&x)) = v;
          }        
        } else { // real80
            * cast(ulong *)(&x) = v;
        }
        return x;
    }
}

/**
 * Extract an integral payload from a $(NAN).
 *
 * Returns:
 * the integer payload as a ulong.
 *
 * For 80-bit or 128-bit reals, the largest possible payload is 0x3FFF_FFFF_FFFF_FFFF.
 * For doubles, it is 0x3_FFFF_FFFF_FFFF.
 * For floats, it is 0x3F_FFFF.
 */
ulong getNaNPayload(real x)
{
    assert(isNaN(x));
    static if (real.mant_dig == 53) {
        ulong m = *cast(ulong *)(&x);
        // Make it look like an 80-bit significand.
        // Skip exponent, and quiet bit
        m &= 0x0007_FFFF_FFFF_FFFF;
        m <<= 10;
    } else static if (real.mant_dig==113) { // quadruple
        version(LittleEndian) {
            ulong m = *cast(ulong*)(6+cast(ubyte*)(&x));
        } else {
            ulong m = *cast(ulong*)(2+cast(ubyte*)(&x));
        }
        m>>=1; // there's no implicit bit
    } else {
        ulong m = *cast(ulong *)(&x);
    }
    // ignore implicit bit and quiet bit
    ulong f = m & 0x3FFF_FF00_0000_0000L;
    ulong w = f >>> 40;
    w |= (m & 0x00FF_FFFF_F800L) << (22 - 11);
    w |= (m & 0x7FF) << 51;
    return w;
}

debug(UnitTest) {
unittest {
  real nan4 = NaN(0x789_ABCD_EF12_3456);
  static if (real.mant_dig == 64 || real.mant_dig==113) {
      assert (getNaNPayload(nan4) == 0x789_ABCD_EF12_3456);
  } else {
      assert (getNaNPayload(nan4) == 0x1_ABCD_EF12_3456);
  }
  double nan5 = nan4;
  assert (getNaNPayload(nan5) == 0x1_ABCD_EF12_3456);
  float nan6 = nan4;
  assert (getNaNPayload(nan6) == 0x12_3456);
  nan4 = NaN(0xFABCD);
  assert (getNaNPayload(nan4) == 0xFABCD);
  nan6 = nan4;
  assert (getNaNPayload(nan6) == 0xFABCD);
  nan5 = NaN(0x100_0000_0000_3456);
  assert(getNaNPayload(nan5) == 0x0000_0000_3456);
}
}

