// Written in the D programming language

/**
 * Macros:
 *      WIKI = Phobos/StdMath
 *
 *      TABLE_SV = <table border=1 cellpadding=4 cellspacing=0>
 *              <caption>Special Values</caption>
 *              $0</table>
 *      SVH = $(TR $(TH $1) $(TH $2))
 *      SV  = $(TR $(TD $1) $(TD $2))
 *
 *      NAN = $(RED NAN)
 *      SUP = <span style="vertical-align:super;font-size:smaller">$0</span>
 *      GAMMA =  &#915;
 *      INTEGRAL = &#8747;
 *      INTEGRATE = $(BIG &#8747;<sub>$(SMALL $1)</sub><sup>$2</sup>)
 *      POWER = $1<sup>$2</sup>
 *      SUB = $1<sub>$2</sub>
 *      BIGSUM = $(BIG &Sigma; <sup>$2</sup><sub>$(SMALL $1)</sub>)
 *      CHOOSE = $(BIG &#40;) <sup>$(SMALL $1)</sup><sub>$(SMALL $2)</sub> $(BIG &#41;)
 *      PLUSMN = &plusmn;
 *      INFIN = &infin;
 *      PLUSMNINF = &plusmn;&infin;
 *      PI = &pi;
 *      LT = &lt;
 *      GT = &gt;
 */

/*
 * Authors:
 *      Walter Bright, Don Clugston
 * Copyright:
 *      Copyright (c) 2001-2005 by Digital Mars,
 *      All Rights Reserved,
 *      www.digitalmars.com
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

/* NOTE: This file has been patched from the original DMD distribution to
   work with the GDC compiler.

   Modified by David Friedman, September 2007
*/


module std.math;

//debug=math;           // uncomment to turn on debugging printf's

private import std.stdio;
private import std.c.stdio;
private import std.string;
private import std.c.math;
private import std.traits;

version (GNU)
{
    // Some functions are missing from msvcrt...
    version (Windows)
	version = GNU_msvcrt_math;

    // Use extended asm for x86
    version(X86)
	version = GCC_ExtAsm_X86;
}


private:
/*
 * The following IEEE 'real' formats are currently supported:
 * 64 bit Big-endian  'double' (eg PowerPC)
 * 128 bit Big-endian 'quadruple' (eg SPARC)
 * 64 bit Little-endian 'double' (eg x86-SSE2)
 * 80 bit Little-endian, with implied bit 'real80' (eg x87, Itanium).
 * 128 bit Little-endian 'quadruple' (not implemented on any known processor!)
 *
 * Non-IEEE 128 bit Big-endian 'doubledouble' (eg PowerPC) has partial support
 */
version(LittleEndian) {
    static assert(real.mant_dig == 53 || real.mant_dig==64 
               || real.mant_dig == 113,
      "Only 64-bit, 80-bit, and 128-bit reals"
      " are supported for LittleEndian CPUs");
} else {
    static assert(real.mant_dig == 53 || real.mant_dig==106
               || real.mant_dig == 113,
    "Only 64-bit and 128-bit reals are supported for BigEndian CPUs."
    " double-double reals have partial support");
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
 } else static if (T.mant_dig == 53) { // double, or real==double
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
 } else static if (T.mant_dig == 64) { // real80
    const ushort EXPMASK = 0x7FFF;
    const ushort EXPBIAS = 0x3FFE;
    const real POW2MANTDIG = 0x1p+63;    
    version(LittleEndian) {
      const EXPPOS_SHORT = 4;
      const SIGNPOS_BYTE = 9;
    } else {
      const EXPPOS_SHORT = 0;
      const SIGNPOS_BYTE = 0;
    }
 } else static if (real.mant_dig == 113){ // quadruple
    const ushort EXPMASK = 0x7FFF;
    const real POW2MANTDIG = 0x1p+113;
    version(LittleEndian) {
      const EXPPOS_SHORT = 7;
      const SIGNPOS_BYTE = 15;
    } else {
      const EXPPOS_SHORT = 0;
      const SIGNPOS_BYTE = 0;
    }
 } else static if (real.mant_dig == 106) { // doubledouble
    const ushort EXPMASK = 0x7FF0;
    const real POW2MANTDIG = 0x1p+53;  // doubledouble denormals are strange
    // and the exponent byte is not unique
    version(LittleEndian) {
      const EXPPOS_SHORT = 7; // [3] is also an exp short
      const SIGNPOS_BYTE = 15;
    } else {
      const EXPPOS_SHORT = 0; // [4] is also an exp short
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

class NotImplemented : Error
{
    this(string msg)
    {
        super(msg ~ " not implemented");
    }
}

const real E =          2.7182818284590452354L;  /** e */
 // 3.32193 fldl2t
const real LOG2T =      0x1.a934f0979a3715fcp+1; /** log<sub>2</sub>10 */
 // 1.4427 fldl2e
const real LOG2E =      0x1.71547652b82fe178p+0; /** log<sub>2</sub>e */
 // 0.30103 fldlg2
const real LOG2 =       0x1.34413509f79fef32p-2; /** log<sub>10</sub>2 */
const real LOG10E =     0.43429448190325182765;  /** log<sub>10</sub>e */
const real LN2 =        0x1.62e42fefa39ef358p-1; /** ln 2 */  // 0.693147 fldln2
const real LN10 =       2.30258509299404568402;  /** ln 10 */
const real PI =         0x1.921fb54442d1846ap+1; /** $(_PI) */ // 3.14159 fldpi
const real PI_2 =       1.57079632679489661923;  /** $(PI) / 2 */
const real PI_4 =       0.78539816339744830962;  /** $(PI) / 4 */
const real M_1_PI =     0.31830988618379067154;  /** 1 / $(PI) */
const real M_2_PI =     0.63661977236758134308;  /** 2 / $(PI) */
const real M_2_SQRTPI = 1.12837916709551257390;  /** 2 / &radic;$(PI) */
const real SQRT2 =      1.41421356237309504880;  /** &radic;2 */
const real SQRT1_2 =    0.70710678118654752440;  /** &radic;&frac12; */

/*
        Octal versions:
        PI/64800        0.00001 45530 36176 77347 02143 15351 61441 26767
        PI/180          0.01073 72152 11224 72344 25603 54276 63351 22056
        PI/8            0.31103 75524 21026 43021 51423 06305 05600 67016
        SQRT(1/PI)      0.44067 27240 41233 33210 65616 51051 77327 77303
        2/PI            0.50574 60333 44710 40522 47741 16537 21752 32335
        PI/4            0.62207 73250 42055 06043 23046 14612 13401 56034
        SQRT(2/PI)      0.63041 05147 52066 24106 41762 63612 00272 56161

        PI              3.11037 55242 10264 30215 14230 63050 56006 70163
        LOG2            0.23210 11520 47674 77674 61076 11263 26013 37111
 */


/***********************************
 * Calculates the absolute value
 *
 * For complex numbers, abs(z) = sqrt( $(POWER z.re, 2) + $(POWER z.im, 2) )
 * = hypot(z.re, z.im).
 */
real abs(real x)
{
    return fabs(x);
}

/** ditto */
long abs(long x)
{
    return x>=0 ? x : -x;
}

/** ditto */
int abs(int x)
{
    return x>=0 ? x : -x;
}

/** ditto */
real abs(creal z)
{
    return hypot(z.re, z.im);
}

/** ditto */
real abs(ireal y)
{
    return fabs(y.im);
}


unittest
{
    assert(isIdentical(abs(-0.0L), 0.0L));
    assert(isnan(abs(real.nan)));
    assert(abs(-real.infinity) == real.infinity);
    assert(abs(-3.2Li) == 3.2L);
    assert(abs(71.6Li) == 71.6L);
    assert(abs(-56) == 56);
    assert(abs(2321312L)  == 2321312L);
    assert(mfeq(abs(-1+1i), sqrt(2.0), .0000001));
}

/***********************************
 * Complex conjugate
 *
 *  conj(x + iy) = x - iy
 *
 * Note that z * conj(z) = $(POWER z.re, 2) - $(POWER z.im, 2)
 * is always a real number
 */
creal conj(creal z)
{
    return z.re - z.im*1i;
}

/** ditto */
ireal conj(ireal y)
{
    return -y;
}

unittest
{
    assert(conj(7 + 3i) == 7-3i);
    ireal z = -3.2Li;
    assert(conj(z) == -z);
}

/***********************************
 * Returns cosine of x. x is in radians.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                 $(TH cos(x)) $(TH invalid?))
 *      $(TR $(TD $(NAN))            $(TD $(NAN)) $(TD yes)     )
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD $(NAN)) $(TD yes)     )
 *      )
 * Bugs:
 *      Results are undefined if |x| >= $(POWER 2,64).
 */

version(GNU) alias std.c.math.cosl cos; else
real cos(real x);       /* intrinsic */

/***********************************
 * Returns sine of x. x is in radians.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)               $(TH sin(x))      $(TH invalid?))
 *      $(TR $(TD $(NAN))          $(TD $(NAN))      $(TD yes))
 *      $(TR $(TD $(PLUSMN)0.0)    $(TD $(PLUSMN)0.0) $(TD no))
 *      $(TR $(TD $(PLUSMNINF))    $(TD $(NAN))      $(TD yes))
 *      )
 * Bugs:
 *      Results are undefined if |x| >= $(POWER 2,64).
 */

version(GNU) alias std.c.math.sinl sin; else
real sin(real x);	/* intrinsic */


/***********************************
 *  sine, complex and imaginary
 *
 *  sin(z) = sin(z.re)*cosh(z.im) + cos(z.re)*sinh(z.im)i
 *
 * If both sin(&theta;) and cos(&theta;) are required,
 * it is most efficient to use expi(&theta).
 */
creal sin(creal z)
{
  creal cs = expi(z.re);
  return cs.im * cosh(z.im) + cs.re * sinh(z.im) * 1i;
}

/** ditto */
ireal sin(ireal y)
{
  return cosh(y.im)*1i;
}

unittest {
  assert(sin(0.0+0.0i) == 0.0);
  assert(sin(2.0+0.0i) == sin(2.0L) );
}

/***********************************
 *  cosine, complex and imaginary
 *
 *  cos(z) = cos(z.re)*cosh(z.im) + sin(z.re)*sinh(z.im)i
 */
creal cos(creal z)
{
  creal cs = expi(z.re);
  return cs.re * cosh(z.im) + cs.im * sinh(z.im) * 1i;
}
 
/** ditto */
real cos(ireal y)
{
  return cosh(y.im);
}
 
unittest{
  assert(cos(0.0+0.0i)==1.0);
  assert(cos(1.3L+0.0i)==cos(1.3L));
  assert(cos(5.2Li)== cosh(5.2L));
}

/****************************************************************************
 * Returns tangent of x. x is in radians.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)             $(TH tan(x))       $(TH invalid?))
 *      $(TR $(TD $(NAN))        $(TD $(NAN))       $(TD yes))
 *      $(TR $(TD $(PLUSMN)0.0)  $(TD $(PLUSMN)0.0) $(TD no))
 *      $(TR $(TD $(PLUSMNINF))  $(TD $(NAN))       $(TD yes))
 *      )
 */

version(GNU) alias std.c.math.tanl tan; else
real tan(real x)
{
    asm
    {
        fld     x[EBP]                  ; // load theta
        fxam                            ; // test for oddball values
        fstsw   AX                      ;
        sahf                            ;
        jc      trigerr                 ; // x is NAN, infinity, or empty
                                          // 387's can handle denormals
SC18:   fptan                           ;
        fstp    ST(0)                   ; // dump X, which is always 1
        fstsw   AX                      ;
        sahf                            ;
        jnp     Lret                    ; // C2 = 1 (x is out of range)

        // Do argument reduction to bring x into range
        fldpi                           ;
        fxch                            ;
SC17:   fprem1                          ;
        fstsw   AX                      ;
        sahf                            ;
        jp      SC17                    ;
        fstp    ST(1)                   ; // remove pi from stack
        jmp     SC18                    ;

trigerr:
        jnp     Lret                    ; // if theta is NAN, return theta
        fstp    ST(0)                   ; // dump theta
    }
    return real.nan;

Lret:
    ;
}

unittest
{
    static real vals[][2] =     // angle,tan
    [
            [   0,   0],
            [   .5,  .5463024898],
            [   1,   1.557407725],
            [   1.5, 14.10141995],
            [   2,  -2.185039863],
            [   2.5,-.7470222972],
            [   3,  -.1425465431],
            [   3.5, .3745856402],
            [   4,   1.157821282],
            [   4.5, 4.637332055],
            [   5,  -3.380515006],
            [   5.5,-.9955840522],
            [   6,  -.2910061914],
            [   6.5, .2202772003],
            [   10,  .6483608275],

            // special angles
            [   PI_4,   1],
            //[ PI_2,   real.infinity],
            [   3*PI_4, -1],
            [   PI,     0],
            [   5*PI_4, 1],
            //[ 3*PI_2, -real.infinity],
            [   7*PI_4, -1],
            [   2*PI,   0],

            // overflow
            [   real.infinity,  real.nan],
            [   real.nan,       real.nan],
            //[   1e+100,       real.nan],
    ];
    int i;

    for (i = 0; i < vals.length; i++)
    {
        /* Library tanl does not have the same limit as the fptan
           instruction. */
        version (GNU)
            if (i == vals.length - 1)
	        continue;

        real x = vals[i][0];
        real r = vals[i][1];
        real t = tan(x);

        //printf("tan(%Lg) = %Lg, should be %Lg\n", x, t, r);
        assert(mfeq(r, t, .0000001));

        x = -x;
        r = -r;
        t = tan(x);
        //printf("tan(%Lg) = %Lg, should be %Lg\n", x, t, r);
        assert(mfeq(r, t, .0000001));
    }
}

/***************
 * Calculates the arc cosine of x,
 * returning a value ranging from -$(PI)/2 to $(PI)/2.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)         $(TH acos(x)) $(TH invalid?))
 *      $(TR $(TD $(GT)1.0)  $(TD $(NAN))  $(TD yes))
 *      $(TR $(TD $(LT)-1.0) $(TD $(NAN))  $(TD yes))
 *      $(TR $(TD $(NAN))    $(TD $(NAN))  $(TD yes))
 *  )
 */
real acos(real x)               { return std.c.math.acosl(x); }

/***************
 * Calculates the arc sine of x,
 * returning a value ranging from -$(PI)/2 to $(PI)/2.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)            $(TH asin(x))      $(TH invalid?))
 *      $(TR $(TD $(PLUSMN)0.0) $(TD $(PLUSMN)0.0) $(TD no))
 *      $(TR $(TD $(GT)1.0)     $(TD $(NAN))       $(TD yes))
 *      $(TR $(TD $(LT)-1.0)    $(TD $(NAN))       $(TD yes))
 *  )
 */
real asin(real x)               { return std.c.math.asinl(x); }

/***************
 * Calculates the arc tangent of x,
 * returning a value ranging from -$(PI)/2 to $(PI)/2.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                 $(TH atan(x))      $(TH invalid?))
 *  $(TR $(TD $(PLUSMN)0.0)      $(TD $(PLUSMN)0.0) $(TD no))
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD $(NAN))       $(TD yes))
 *  )
 */
real atan(real x)               { return std.c.math.atanl(x); }

/***************
 * Calculates the arc tangent of y / x,
 * returning a value ranging from -$(PI) to $(PI).
 *
 *      $(TABLE_SV
 *      $(TR $(TH y)                 $(TH x)            $(TH atan(y, x)))
 *      $(TR $(TD $(NAN))            $(TD anything)     $(TD $(NAN)) )
 *      $(TR $(TD anything)          $(TD $(NAN))       $(TD $(NAN)) )
 *      $(TR $(TD $(PLUSMN)0.0)      $(TD $(GT)0.0)     $(TD $(PLUSMN)0.0) )
 *      $(TR $(TD $(PLUSMN)0.0)      $(TD +0.0)         $(TD $(PLUSMN)0.0) )
 *      $(TR $(TD $(PLUSMN)0.0)      $(TD $(LT)0.0)     $(TD $(PLUSMN)$(PI)))
 *      $(TR $(TD $(PLUSMN)0.0)      $(TD -0.0)         $(TD $(PLUSMN)$(PI)))
 *      $(TR $(TD $(GT)0.0)          $(TD $(PLUSMN)0.0) $(TD $(PI)/2) )
 *      $(TR $(TD $(LT)0.0)          $(TD $(PLUSMN)0.0) $(TD -$(PI)/2) )
 *      $(TR $(TD $(GT)0.0)          $(TD $(INFIN))     $(TD $(PLUSMN)0.0) )
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD anything)     $(TD $(PLUSMN)$(PI)/2))
 *      $(TR $(TD $(GT)0.0)          $(TD -$(INFIN))    $(TD $(PLUSMN)$(PI)) )
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD $(INFIN))     $(TD $(PLUSMN)$(PI)/4))
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD -$(INFIN))    $(TD $(PLUSMN)3$(PI)/4))
 *      )
 */
real atan2(real y, real x)      { return std.c.math.atan2l(y,x); }

/***********************************
 * Calculates the hyperbolic cosine of x.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                 $(TH cosh(x))      $(TH invalid?))
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD $(PLUSMN)0.0) $(TD no) )
 *      )
 */
real cosh(real x)               { return std.c.math.coshl(x); }

/***********************************
 * Calculates the hyperbolic sine of x.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                 $(TH sinh(x))           $(TH invalid?))
 *      $(TR $(TD $(PLUSMN)0.0)      $(TD $(PLUSMN)0.0)      $(TD no))
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD $(PLUSMN)$(INFIN)) $(TD no))
 *      )
 */
real sinh(real x)               { return std.c.math.sinhl(x); }

/***********************************
 * Calculates the hyperbolic tangent of x.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                 $(TH tanh(x))      $(TH invalid?))
 *      $(TR $(TD $(PLUSMN)0.0)      $(TD $(PLUSMN)0.0) $(TD no) )
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD $(PLUSMN)1.0) $(TD no))
 *      )
 */
real tanh(real x)               { return std.c.math.tanhl(x); }

//real acosh(real x)            { return std.c.math.acoshl(x); }
//real asinh(real x)            { return std.c.math.asinhl(x); }
//real atanh(real x)            { return std.c.math.atanhl(x); }

/***********************************
 * Calculates the inverse hyperbolic cosine of x.
 *
 *  Mathematically, acosh(x) = log(x + sqrt( x*x - 1))
 *
 * $(TABLE_DOMRG
 *  $(DOMAIN 1..$(INFIN))
 *  $(RANGE  1..log(real.max), $(INFIN)) )
 *      $(TABLE_SV
 *    $(SVH  x,     acosh(x) )
 *    $(SV  $(NAN), $(NAN) )
 *    $(SV  <1,     $(NAN) )
 *    $(SV  1,      0       )
 *    $(SV  +$(INFIN),+$(INFIN))
 *  )
 */   
real acosh(real x)
{
    if (x > 1/real.epsilon)
        return LN2 + log(x);
    else
        return log(x + sqrt(x*x - 1));
}

unittest
{
    assert(isnan(acosh(0.9)));
    assert(isnan(acosh(real.nan)));
    assert(acosh(1)==0.0);
    assert(acosh(real.infinity) == real.infinity);
}

/***********************************
 * Calculates the inverse hyperbolic sine of x.
 *
 *  Mathematically,
 *  ---------------
 *  asinh(x) =  log( x + sqrt( x*x + 1 )) // if x >= +0
 *  asinh(x) = -log(-x + sqrt( x*x + 1 )) // if x <= -0
 *  -------------
 *
 *    $(TABLE_SV
 *    $(SVH x,                asinh(x)       )
 *    $(SV  $(NAN),           $(NAN)         )
 *    $(SV  $(PLUSMN)0,       $(PLUSMN)0      )
 *    $(SV  $(PLUSMN)$(INFIN),$(PLUSMN)$(INFIN))
 *    )
 */
real asinh(real x)
{   
    if (fabs(x) > 1 / real.epsilon) {   // beyond this point, x*x + 1 == x*x
            return copysign(LN2 + log(fabs(x)), x);
    } else {
            // sqrt(x*x + 1) ==  1 + x * x / ( 1 + sqrt(x*x + 1) )
            return copysign(log1p(fabs(x) + x*x / (1 + sqrt(x*x + 1)) ), x);
    }
}

unittest
{
    assert(isIdentical(asinh(0.0), 0.0));
    assert(isIdentical(asinh(-0.0), -0.0));
    assert(asinh(real.infinity) == real.infinity);
    assert(asinh(-real.infinity) == -real.infinity);
    assert(isnan(asinh(real.nan)));
}

/***********************************
 * Calculates the inverse hyperbolic tangent of x,
 * returning a value from ranging from -1 to 1.
 *  
 * Mathematically, atanh(x) = log( (1+x)/(1-x) ) / 2
 *  
 *
 * $(TABLE_DOMRG
 *  $(DOMAIN -$(INFIN)..$(INFIN))
 *  $(RANGE  -1..1) )
 * $(TABLE_SV
 *    $(SVH  x,     acosh(x) )
 *    $(SV  $(NAN), $(NAN) )
 *    $(SV  $(PLUSMN)0, $(PLUSMN)0)
 *    $(SV  -$(INFIN), -0)
 * )
 */   
real atanh(real x)
{
    // log( (1+x)/(1-x) ) == log ( 1 + (2*x)/(1-x) )
    return copysign(0.5 * log1p( 2 * x / (1 - x) ), x);
}

unittest
{
    assert(isIdentical(atanh(0.0), 0.0));
    assert(isIdentical(atanh(-0.0),-0.0));
    assert(isnan(atanh(real.nan)));
    assert(isnan(atanh(-real.infinity))); 
}

/*****************************************
 * Returns x rounded to a long value using the current rounding mode.
 * If the integer value of x is
 * greater than long.max, the result is
 * indeterminate.
 */
long rndtol(real x);    /* intrinsic */


/*****************************************
 * Returns x rounded to a long value using the FE_TONEAREST rounding mode.
 * If the integer value of x is
 * greater than long.max, the result is
 * indeterminate.
 */
extern (C) real rndtonl(real x);

/***************************************
 * Compute square root of x.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)         $(TH sqrt(x))   $(TH invalid?))
 *      $(TR $(TD -0.0)      $(TD -0.0)      $(TD no))
 *      $(TR $(TD $(LT)0.0)  $(TD $(NAN))    $(TD yes))
 *      $(TR $(TD +$(INFIN)) $(TD +$(INFIN)) $(TD no))
 *      )
 */

version(GNU) float sqrt(float x) { return std.c.math.sqrtf(x); } else
float sqrt(float x);    /* intrinsic */
version(GNU) double sqrt(double x) { return std.c.math.sqrt(x); } else /// ditto
double sqrt(double x);  /* intrinsic */ /// ditto
version(GNU) real sqrt(real x) { return std.c.math.sqrtl(x); } else /// ditto
real sqrt(real x);      /* intrinsic */ /// ditto

creal sqrt(creal z)
{
    creal c;
    real x,y,w,r;

    if (z == 0)
    {
        c = 0 + 0i;
    }
    else
    {
        real z_re = z.re;
        real z_im = z.im;

        x = fabs(z_re);
        y = fabs(z_im);
        if (x >= y)
        {
            r = y / x;
            w = sqrt(x) * sqrt(0.5 * (1 + sqrt(1 + r * r)));
        }
        else
        {
            r = x / y;
            w = sqrt(y) * sqrt(0.5 * (r + sqrt(1 + r * r)));
        }

        if (z_re >= 0)
        {
            c = w + (z_im / (w + w)) * 1.0i;
        }
        else
        {
            if (z_im < 0)
                w = -w;
            c = z_im / (w + w) + w * 1.0i;
        }
    }
    return c;
}

/**********************
 * Calculates e$(SUP x).
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)         $(TH exp(x)))
 *      $(TR $(TD +$(INFIN)) $(TD +$(INFIN)) )
 *      $(TR $(TD -$(INFIN)) $(TD +0.0) )
 *      )
 */
real exp(real x)                { return std.c.math.expl(x); }

/**********************
 * Calculates 2$(SUP x).
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)         $(TH exp2(x)))
 *      $(TR $(TD +$(INFIN)) $(TD +$(INFIN)))
 *      $(TR $(TD -$(INFIN)) $(TD +0.0))
 *      )
 */
version (GNU_Need_exp2_log2) real exp2(real x) { return std.c.math.powl(2, x); } else
real exp2(real x)               { return std.c.math.exp2l(x); }

/******************************************
 * Calculates the value of the natural logarithm base (e)
 * raised to the power of x, minus 1.
 *
 * For very small x, expm1(x) is more accurate 
 * than exp(x)-1. 
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)            $(TH e$(SUP x)-1))
 *      $(TR $(TD $(PLUSMN)0.0) $(TD $(PLUSMN)0.0))
 *      $(TR $(TD +$(INFIN))    $(TD +$(INFIN)))
 *      $(TR $(TD -$(INFIN))    $(TD -1.0))
 *      )
 */

version (GNU_msvcrt_math) { /* nothing */ } else
real expm1(real x)              { return std.c.math.expm1l(x); }

/**
 * Calculate cos(y) + i sin(y).
 *
 * On many CPUs (such as x86), this is a very efficient operation;
 * almost twice as fast as calculating sin(y) and cos(y) separately,
 * and is the preferred method when both are required.
 */
creal expi(real y)
{
    version(GCC_ExtAsm_X86)
    {
	real re = void, im = void;
	asm { "fsincos" : "=&t" im , "=u" re : "0" y; }
	return re + im * 1i;
    }
    else version(D_InlineAsm_X86)
    {
        asm
        {
            fld y;
            fsincos;
            fxch ST(1), ST(0);
        }
    }
    else
    {
        return cos(y) + sin(y)*1i;
    }
}

unittest
{
    assert(expi(1.3e5L) == cos(1.3e5L) + sin(1.3e5L) * 1i);
    assert(expi(0.0L) == 1L + 0.0Li);
}

/*********************************************************************
 * Separate floating point value into significand and exponent.
 *
 * Returns:
 *      Calculate and return <i>x</i> and exp such that
 *      value =<i>x</i>*2$(SUP exp) and
 *      .5 $(LT)= |<i>x</i>| $(LT) 1.0<br>
 *      <i>x</i> has same sign as value.
 *
 *      $(TABLE_SV
 *      $(TR $(TH value)           $(TH returns)         $(TH exp))
 *      $(TR $(TD $(PLUSMN)0.0)    $(TD $(PLUSMN)0.0)    $(TD 0))
 *      $(TR $(TD +$(INFIN))       $(TD +$(INFIN))       $(TD int.max))
 *      $(TR $(TD -$(INFIN))       $(TD -$(INFIN))       $(TD int.min))
 *      $(TR $(TD $(PLUSMN)$(NAN)) $(TD $(PLUSMN)$(NAN)) $(TD int.min))
 *      )
 */


real frexp(real value, out int exp)
{
    version (DMD) {

    ushort* vu = cast(ushort*)&value;
    long* vl = cast(long*)&value;
    uint ex;
    alias floatTraits!(real) F;

    ex = vu[F.EXPPOS_SHORT] & F.EXPMASK;
  static if (real.mant_dig == 64) { // real80
    if (ex) { // If exponent is non-zero
        if (ex == F.EXPMASK) {   // infinity or NaN
            if (*vl &  0x7FFF_FFFF_FFFF_FFFF) {  // NaN
                *vl |= 0xC000_0000_0000_0000;  // convert NaNS to NaNQ
                exp = int.min;
            } else if (vu[F.EXPPOS_SHORT] & 0x8000) {   // negative infinity
                exp = int.min;
            } else {   // positive infinity
                exp = int.max;
            }
        } else {
            exp = ex - F.EXPBIAS;
            vu[F.EXPPOS_SHORT] =
                cast(ushort)((0x8000 & vu[F.EXPPOS_SHORT]) | 0x3FFE);
        }
    } else if (!*vl) {
        // value is +-0.0
        exp = 0;
    } else {
        // denormal
        int i = -0x3FFD;
        do {
            i--;
            *vl <<= 1;
        } while (*vl > 0);
        exp = i;
        vu[F.EXPPOS_SHORT] =
            cast(ushort)((0x8000 & vu[F.EXPPOS_SHORT]) | 0x3FFE);
    }
  } else static if (real.mant_dig == 113) { // quadruple      
        if (ex) { // If exponent is non-zero
            if (ex == F.EXPMASK) {   // infinity or NaN
                if (vl[MANTISSA_LSB] |
                    ( vl[MANTISSA_MSB] & 0x0000_FFFF_FFFF_FFFF)) {  // NaN
                    // convert NaNS to NaNQ
                    vl[MANTISSA_MSB] |= 0x0000_8000_0000_0000;
                    exp = int.min;
                } else if (vu[F.EXPPOS_SHORT] & 0x8000) {   // negative infinity
                    exp = int.min;
                } else {   // positive infinity
                    exp = int.max;
                }
            } else {
                exp = ex - F.EXPBIAS;
                vu[F.EXPPOS_SHORT] =
                   cast(ushort)((0x8000 & vu[F.EXPPOS_SHORT]) | 0x3FFE);
            }
        } else if ((vl[MANTISSA_LSB] 
                  |(vl[MANTISSA_MSB] & 0x0000_FFFF_FFFF_FFFF)) == 0) {
            // value is +-0.0
            exp = 0;
    } else {
        // denormal
        value *= F.POW2MANTDIG;
        ex = vu[F.EXPPOS_SHORT] & F.EXPMASK;
        exp = ex - F.EXPBIAS - 113;
        vu[F.EXPPOS_SHORT] = 
                  cast(ushort)((0x8000 & vu[F.EXPPOS_SHORT]) | 0x3FFE);
    }
  } else static if (real.mant_dig==53) { // real is double
    if (ex) { // If exponent is non-zero
        if (ex == F.EXPMASK) {   // infinity or NaN
            if (*vl == 0x7FF0_0000_0000_0000) {  // positive infinity
                exp = int.max;
            } else if (*vl == 0xFFF0_0000_0000_0000) { // negative infinity
                exp = int.min;
            } else { // NaN
                *vl |= 0x0008_0000_0000_0000;  // convert NaNS to NaNQ
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
  } else { //static if(real.mant_dig==106) // doubledouble
    throw new NotImplemented("frexp");
  }
  return value;

    }
    else version(GNU)
    {
	switch (gcc.fpcls.fpclassify(value)) {
	case gcc.fpcls.FP_NORMAL:
	case gcc.fpcls.FP_ZERO:
	case gcc.fpcls.FP_SUBNORMAL: // I can only hope the library frexp normalizes the value...
	    return std.c.math.frexpl(value, & exp);
	case gcc.fpcls.FP_INFINITE:
	    exp = gcc.fpcls.signbit(value) ? int.min : int.max;
	    return value;
	case gcc.fpcls.FP_NAN:
	    exp = int.min;
	    return value;
	}
    }
}


unittest
{
    static real vals[][3] =	// x,frexp,exp
    [
        [0.0,   0.0,    0],
        [-0.0,  -0.0,   0],
        [1.0,   .5,     1],
        [-1.0,  -.5,    1],
        [2.0,   .5,     2],
        [double.min/2.0, .5, -1022],
        [real.infinity,real.infinity,int.max],
        [-real.infinity,-real.infinity,int.min],
        [real.nan,real.nan,int.min],
        [-real.nan,-real.nan,int.min],
    ];

    int i;

    for (i = 0; i < vals.length; i++) {
	if (real.min_exp > -16381)
	    continue;
        real x = vals[i][0];
        real e = vals[i][1];
        int exp = cast(int)vals[i][2];
        int eptr;
        real v = frexp(x, eptr);
//        printf("frexp(%La) = %La, should be %La, eptr = %d, should be %d\n", 
//                x, v, e, eptr, exp);
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

/******************************************
 * Extracts the exponent of x as a signed integral value.
 *
 * If x is not a special value, the result is the same as
 * <tt>cast(int)logb(x)</tt>.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                $(TH ilogb(x))     $(TH Range error?))
 *      $(TR $(TD 0)                 $(TD FP_ILOGB0)   $(TD yes))
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD int.max)     $(TD no))
 *      $(TR $(TD $(NAN))            $(TD FP_ILOGBNAN) $(TD no))
 *      )
 */
int ilogb(real x)               { return std.c.math.ilogbl(x); }

alias std.c.math.FP_ILOGB0   FP_ILOGB0;
alias std.c.math.FP_ILOGBNAN FP_ILOGBNAN;


/*******************************************
 * Compute n * 2$(SUP exp)
 * References: frexp
 */

version(GNU) alias std.c.math.ldexpl ldexp; else
real ldexp(real n, int exp);    /* intrinsic */

/**************************************
 * Calculate the natural logarithm of x.
 *
 *    $(TABLE_SV
 *    $(TR $(TH x)            $(TH log(x))    $(TH divide by 0?) $(TH invalid?))
 *    $(TR $(TD $(PLUSMN)0.0) $(TD -$(INFIN)) $(TD yes)          $(TD no))
 *    $(TR $(TD $(LT)0.0)     $(TD $(NAN))    $(TD no)           $(TD yes))
 *    $(TR $(TD +$(INFIN))    $(TD +$(INFIN)) $(TD no)           $(TD no))
 *    )
 */

real log(real x)                { return std.c.math.logl(x); }

/**************************************
 * Calculate the base-10 logarithm of x.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)            $(TH log10(x))  $(TH divide by 0?) $(TH invalid?))
 *      $(TR $(TD $(PLUSMN)0.0) $(TD -$(INFIN)) $(TD yes)          $(TD no))
 *      $(TR $(TD $(LT)0.0)     $(TD $(NAN))    $(TD no)           $(TD yes))
 *      $(TR $(TD +$(INFIN))    $(TD +$(INFIN)) $(TD no)           $(TD no))
 *      )
 */

real log10(real x)              { return std.c.math.log10l(x); }

/******************************************
 *      Calculates the natural logarithm of 1 + x.
 *
 *      For very small x, log1p(x) will be more accurate than 
 *      log(1 + x). 
 *
 *  $(TABLE_SV
 *  $(TR $(TH x)            $(TH log1p(x))     $(TH divide by 0?) $(TH invalid?))
 *  $(TR $(TD $(PLUSMN)0.0) $(TD $(PLUSMN)0.0) $(TD no)           $(TD no))
 *  $(TR $(TD -1.0)         $(TD -$(INFIN))    $(TD yes)          $(TD no))
 *  $(TR $(TD $(LT)-1.0)    $(TD $(NAN))       $(TD no)           $(TD yes))
 *  $(TR $(TD +$(INFIN))    $(TD -$(INFIN))    $(TD no)           $(TD no))
 *  )
 */

real log1p(real x)              { return std.c.math.log1pl(x); }

/***************************************
 * Calculates the base-2 logarithm of x:
 * log<sub>2</sub>x
 *
 *  $(TABLE_SV
 *  $(TR $(TH x)            $(TH log2(x))   $(TH divide by 0?) $(TH invalid?))
 *  $(TR $(TD $(PLUSMN)0.0) $(TD -$(INFIN)) $(TD yes)          $(TD no) )
 *  $(TR $(TD $(LT)0.0)     $(TD $(NAN))    $(TD no)           $(TD yes) )
 *  $(TR $(TD +$(INFIN))    $(TD +$(INFIN)) $(TD no)           $(TD no) )
 *  )
 */
version (GNU_Need_exp2_log2) real log2(real x) { return std.c.math.logl(x) / LOG2; } else
real log2(real x)               { return std.c.math.log2l(x); }

/*****************************************
 * Extracts the exponent of x as a signed integral value.
 *
 * If x is subnormal, it is treated as if it were normalized.
 * For a positive, finite x: 
 *
 * 1 $(LT)= $(I x) * FLT_RADIX$(SUP -logb(x)) $(LT) FLT_RADIX 
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                 $(TH logb(x))   $(TH divide by 0?) )
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD +$(INFIN)) $(TD no))
 *      $(TR $(TD $(PLUSMN)0.0)      $(TD -$(INFIN)) $(TD yes) )
 *      )
 */
real logb(real x)               { return std.c.math.logbl(x); }

/************************************
 * Calculates the remainder from the calculation x/y.
 * Returns:
 * The value of x - i * y, where i is the number of times that y can 
 * be completely subtracted from x. The result has the same sign as x. 
 *
 * $(TABLE_SV
 *  $(TR $(TH x)              $(TH y)             $(TH modf(x, y))   $(TH invalid?))
 *  $(TR $(TD $(PLUSMN)0.0)   $(TD not 0.0)       $(TD $(PLUSMN)0.0) $(TD no))
 *  $(TR $(TD $(PLUSMNINF))   $(TD anything)      $(TD $(NAN))       $(TD yes))
 *  $(TR $(TD anything)       $(TD $(PLUSMN)0.0)  $(TD $(NAN))       $(TD yes))
 *  $(TR $(TD !=$(PLUSMNINF)) $(TD $(PLUSMNINF))  $(TD x)            $(TD no))
 * )
 */
real modf(real x, inout real y) { return std.c.math.modfl(x,&y); }

/*************************************
 * Efficiently calculates x * 2$(SUP n).
 *
 * scalbn handles underflow and overflow in 
 * the same fashion as the basic arithmetic operators. 
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                 $(TH scalb(x)))
 *      $(TR $(TD $(PLUSMNINF))      $(TD $(PLUSMNINF)) )
 *      $(TR $(TD $(PLUSMN)0.0)      $(TD $(PLUSMN)0.0) )
 *      )
 */
real scalbn(real x, int n)
{
    version(D_InlineAsm_X86) {
        // scalbnl is not supported on DMD-Windows, so use asm.
        asm {
            fild n;
            fld x;
            fscale;
            fstp ST(1)/*, ST*/;
        }
    } else {
        return std.c.math.scalbnl(x, n);
    }
}

unittest {
    assert(scalbn(-real.infinity, 5) == -real.infinity);
}

/***************
 * Calculates the cube root of x.
 *
 *      $(TABLE_SV
 *      $(TR $(TH $(I x))            $(TH cbrt(x))           $(TH invalid?))
 *      $(TR $(TD $(PLUSMN)0.0)      $(TD $(PLUSMN)0.0)      $(TD no) )
 *      $(TR $(TD $(NAN))            $(TD $(NAN))            $(TD yes) )
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD $(PLUSMN)$(INFIN)) $(TD no) )
 *      )
 */
real cbrt(real x)               { return std.c.math.cbrtl(x); }


/*******************************
 * Returns |x|
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                 $(TH fabs(x)))
 *      $(TR $(TD $(PLUSMN)0.0)      $(TD +0.0) )
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD +$(INFIN)) )
 *      )
 */
version (GNU) alias std.c.math.fabsl fabs; else
real fabs(real x);      /* intrinsic */


/***********************************************************************
 * Calculates the length of the 
 * hypotenuse of a right-angled triangle with sides of length x and y. 
 * The hypotenuse is the value of the square root of 
 * the sums of the squares of x and y:
 *
 *      sqrt($(POW x, 2) + $(POW y, 2))
 *
 * Note that hypot(x, y), hypot(y, x) and
 * hypot(x, -y) are equivalent.
 *
 *  $(TABLE_SV
 *  $(TR $(TH x)            $(TH y)            $(TH hypot(x, y)) $(TH invalid?))
 *  $(TR $(TD x)            $(TD $(PLUSMN)0.0) $(TD |x|)         $(TD no))
 *  $(TR $(TD $(PLUSMNINF)) $(TD y)            $(TD +$(INFIN))   $(TD no))
 *  $(TR $(TD $(PLUSMNINF)) $(TD $(NAN))       $(TD +$(INFIN))   $(TD no))
 *  )
 */

real hypot(real x, real y)
{
    /*
     * This is based on code from:
     * Cephes Math Library Release 2.1:  January, 1989
     * Copyright 1984, 1987, 1989 by Stephen L. Moshier
     * Direct inquiries to 30 Frost Street, Cambridge, MA 02140
     */

    const int PRECL = 32;
    const int MAXEXPL = real.max_exp; //16384;
    const int MINEXPL = real.min_exp; //-16384;

    real xx, yy, b, re, im;
    int ex, ey, e;

    // Note, hypot(INFINITY, NAN) = INFINITY.
    if (isinf(x) || isinf(y))
        return real.infinity;

    if (isnan(x))
        return x;
    if (isnan(y))
        return y;

    re = fabs(x);
    im = fabs(y);

    if (re == 0.0)
        return im;
    if (im == 0.0)
        return re;

    // Get the exponents of the numbers
    xx = frexp(re, ex);
    yy = frexp(im, ey);

    // Check if one number is tiny compared to the other
    e = ex - ey;
    if (e > PRECL)
        return re;
    if (e < -PRECL)
        return im;

    // Find approximate exponent e of the geometric mean.
    e = (ex + ey) >> 1;

    // Rescale so mean is about 1
    xx = ldexp(re, -e);
    yy = ldexp(im, -e);

    // Hypotenuse of the right triangle
    b = sqrt(xx * xx  +  yy * yy);

    // Compute the exponent of the answer.
    yy = frexp(b, ey);
    ey = e + ey;

    // Check it for overflow and underflow.
    if (ey > MAXEXPL + 2)
    {
        //return __matherr(_OVERFLOW, INFINITY, x, y, "hypotl");
        return real.infinity;
    }
    if (ey < MINEXPL - 2)
        return 0.0;

    // Undo the scaling
    b = ldexp(b, e);
    return b;
}

unittest
{
    static real vals[][3] =     // x,y,hypot
    [
        [ 0,      0,      0],
        [ 0,      -0,     0],
        [ 3,      4,      5],
        [ -300,   -400,   500],
        [ real.min, real.min, 4.75473e-4932L],
        [ real.max/2, real.max/2, 0x1.6a09e667f3bcc908p+16383L],
        [ real.infinity, real.nan, real.infinity],
        [ real.nan, real.nan, real.nan],
    ];

    for (int i = 0; i < vals.length; i++)
    {
	if (i == 5 && real.max_exp < 16383)
	    continue;

        real x = vals[i][0];
        real y = vals[i][1];
        real z = vals[i][2];
        real h = hypot(x, y);

        assert(mfeq(z, h, .0000001));
    }
}

/**********************************
 * Returns the error function of x.
 *
 * <img src="erf.gif" alt="error function">
 */
version (GNU_msvcrt_math) { /* nothing */ } else
real erf(real x)                { return std.c.math.erfl(x); }

/**********************************
 * Returns the complementary error function of x, which is 1 - erf(x).
 *
 * <img src="erfc.gif" alt="complementary error function">
 */
version (GNU_msvcrt_math) { /* nothing */ } else
real erfc(real x)               { return std.c.math.erfcl(x); }

/***********************************
 * Natural logarithm of gamma function.
 *
 * Returns the base e (2.718...) logarithm of the absolute
 * value of the gamma function of the argument.
 *
 * For reals, lgamma is equivalent to log(fabs(gamma(x))).
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)                 $(TH lgamma(x)) $(TH invalid?))
 *      $(TR $(TD $(NAN))            $(TD $(NAN))    $(TD yes))
 *      $(TR $(TD integer <= 0)      $(TD +$(INFIN)) $(TD yes))
 *      $(TR $(TD $(PLUSMN)$(INFIN)) $(TD +$(INFIN)) $(TD no))
 *      )
 */
/* Documentation prepared by Don Clugston */
real lgamma(real x)
{
    return std.c.math.lgammal(x);

    // Use etc.gamma.lgamma for those C systems that are missing it
}

/***********************************
 *  The Gamma function, $(GAMMA)(x)
 *
 *  $(GAMMA)(x) is a generalisation of the factorial function
 *  to real and complex numbers.
 *  Like x!, $(GAMMA)(x+1) = x*$(GAMMA)(x).
 *
 *  Mathematically, if z.re > 0 then
 *   $(GAMMA)(z) = $(INTEGRATE 0, &infin;) $(POWER t, z-1)$(POWER e, -t) dt
 *
 *    $(TABLE_SV
 *      $(TR $(TH x)              $(TH $(GAMMA)(x))       $(TH invalid?))
 *      $(TR $(TD $(NAN))         $(TD $(NAN))            $(TD yes))
 *      $(TR $(TD $(PLUSMN)0.0)   $(TD $(PLUSMNINF))      $(TD yes))
 *      $(TR $(TD integer $(GT)0) $(TD (x-1)!)            $(TD no))
 *      $(TR $(TD integer $(LT)0) $(TD $(NAN))            $(TD yes))
 *      $(TR $(TD +$(INFIN))      $(TD +$(INFIN))         $(TD no))
 *      $(TR $(TD -$(INFIN))      $(TD $(NAN))            $(TD yes))
 *    )
 *
 *  References:
 *      $(LINK http://en.wikipedia.org/wiki/Gamma_function),
 *      $(LINK http://www.netlib.org/cephes/ldoubdoc.html#gamma)
 */
version (GNU_Need_tgamma)
{
    private import etc.gamma;
    alias etc.gamma.tgamma tgamma;
}
else
real tgamma(real x)
{
    return std.c.math.tgammal(x);

    // Use etc.gamma.tgamma for those C systems that are missing it
}

/**************************************
 * Returns the value of x rounded upward to the next integer
 * (toward positive infinity).
 */
real ceil(real x)               { return std.c.math.ceill(x); }

/**************************************
 * Returns the value of x rounded downward to the next integer
 * (toward negative infinity).
 */
real floor(real x)              { return std.c.math.floorl(x); }

/******************************************
 * Rounds x to the nearest integer value, using the current rounding 
 * mode.
 *
 * Unlike the rint functions, nearbyint does not raise the 
 * FE_INEXACT exception. 
 */
version (GNU_Need_nearbyint)
{
    // not implemented yet
}
else
real nearbyint(real x) { return std.c.math.nearbyintl(x); }

/**********************************
 * Rounds x to the nearest integer value, using the current rounding
 * mode.
 * If the return value is not equal to x, the FE_INEXACT
 * exception is raised.
 * <b>nearbyint</b> performs
 * the same operation, but does not set the FE_INEXACT exception.
 */
version(GNU) alias std.c.math.rintl rint; else
real rint(real x);      /* intrinsic */

/***************************************
 * Rounds x to the nearest integer value, using the current rounding
 * mode.
 *
 * This is generally the fastest method to convert a floating-point number
 * to an integer. Note that the results from this function
 * depend on the rounding mode, if the fractional part of x is exactly 0.5.
 * If using the default rounding mode (ties round to even integers)
 * lrint(4.5) == 4, lrint(5.5)==6.
 */
long lrint(real x)
{
    version (linux)
        return std.c.math.llrintl(x);
    else version(D_InlineAsm_X86)
    {
        long n;
        asm
        {
            fld x;
            fistp n;
        }
        return n;
    }
    else
        throw new NotImplemented("lrint");
}

/*******************************************
 * Return the value of x rounded to the nearest integer.
 * If the fractional part of x is exactly 0.5, the return value is rounded to
 * the even integer. 
 */
version (GNU_Need_round)
{
    real round(real x)
    {
	real y = floor(x);
	real r = x - y;
	if (r > 0.5)
	    return y + 1;
	else if (r == 0.5)
	{
	    r = y - 2.0 * floor(0.5 * y);
	    if (r == 1.0)
		return y + 1;
	}
	return y;
    }
    unittest {
	real r;
	assert(isnan(round(real.nan)));
	r = round(real.infinity);
	assert(isinf(r) && r > 0);
	r = round(-real.infinity);
	assert(isinf(r) && r < 0);
	assert(round(3.4) == 3);
	assert(round(3.5) == 4);
	assert(round(3.6) == 4);
	assert(round(-3.4) == -3);
	assert(round(-3.5) == -4);
	assert(round(-3.6) == -4);
    }
}
else
real round(real x) { return std.c.math.roundl(x); }

/**********************************************
 * Return the value of x rounded to the nearest integer.
 *
 * If the fractional part of x is exactly 0.5, the return value is rounded
 * away from zero.
 *
 * Note: Not supported on windows
 */
long lround(real x)
{
    version (linux)
        return std.c.math.llroundl(x);
    else
        throw new NotImplemented("lround");
}

/****************************************************
 * Returns the integer portion of x, dropping the fractional portion. 
 *
 * This is also known as "chop" rounding. 
 */
version (GNU_Need_trunc)
{
    real trunc(real n) { return n >= 0 ? std.math.floor(n) : std.c.matheil(n); }
    unittest
    {
	real r;
	r = trunc(real.infinity);
	assert(isinf(r) && r > 0);
	r = trunc(-real.infinity);
	assert(isinf(r) && r < 0);
	assert(isnan(trunc(real.nan)));
	assert(trunc(3.3) == 3);
	assert(trunc(3.6) == 3);
	assert(trunc(-3.3) == -3);
	assert(trunc(-3.6) == -3);
    }
}
else
real trunc(real x) { return std.c.math.truncl(x); }

/****************************************************
 * Calculate the remainder x REM y, following IEC 60559.
 *
 * REM is the value of x - y * n, where n is the integer nearest the exact 
 * value of x / y.
 * If |n - x / y| == 0.5, n is even.
 * If the result is zero, it has the same sign as x.
 * Otherwise, the sign of the result is the sign of x / y.
 * Precision mode has no effect on the remainder functions.
 *
 * remquo returns n in the parameter n.
 *
 * $(TABLE_SV
 *  $(TR $(TH x)               $(TH y)            $(TH remainder(x, y)) $(TH n)   $(TH invalid?))
 *  $(TR $(TD $(PLUSMN)0.0)    $(TD not 0.0)      $(TD $(PLUSMN)0.0)    $(TD 0.0) $(TD no))
 *  $(TR $(TD $(PLUSMNINF))    $(TD anything)     $(TD $(NAN))          $(TD ?)   $(TD yes))
 *  $(TR $(TD anything)        $(TD $(PLUSMN)0.0) $(TD $(NAN))          $(TD ?)   $(TD yes))
 *  $(TR $(TD != $(PLUSMNINF)) $(TD $(PLUSMNINF)) $(TD x)               $(TD ?)   $(TD no))
 * )
 *
 * Note: remquo not supported on windows
 */
real remainder(real x, real y) { return std.c.math.remainderl(x, y); }

real remquo(real x, real y, out int n)  /// ditto
{
    version (linux)
        return std.c.math.remquol(x, y, &n);
    else
        throw new NotImplemented("remquo");
}


import gcc.fpcls;

/*********************************
 * Returns !=0 if e is a NaN.
 */

int isnan(real x) { return fpclassify(x)==FP_NAN; }
/*
int isnan(real x)
{
  alias floatTraits!(real) F;
  static if (real.mant_dig==53) { // double
        ulong*  p = cast(ulong *)&x;
        return (*p & 0x7FF0_0000_0000_0000 == 0x7FF0_0000_0000_0000) 
             && *p & 0x000F_FFFF_FFFF_FFFF;
  } else static if (real.mant_dig==64) {     // real80
        // Prevent a ridiculous warning
        // (why does (ushort | ushort) get promoted to int???)
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
*/

unittest
{
    assert(isnan(float.nan));
    assert(isnan(-double.nan));
    assert(isnan(real.nan));

    assert(!isnan(53.6));
    assert(!isnan(float.infinity));
}

/*********************************
 * Returns !=0 if e is finite (not infinite or $(NAN)).
 */

int isfinite(real x)
{
    int r = fpclassify(x);
    return r != FP_NAN && r != FP_INFINITE;
}
/*
int isfinite(real e)
{
    alias floatTraits!(real) F;
    ushort* pe = cast(ushort *)&e;
    return (pe[F.EXPPOS_SHORT] & F.EXPMASK) != F.EXPMASK;
}
*/

unittest
{
    assert(isfinite(1.23));
    assert(!isfinite(double.infinity));
    assert(!isfinite(float.nan));
}


/*********************************
 * Returns !=0 if x is normalized (not zero, subnormal, infinite, or $(NAN)).
 */

/* Need one for each format because subnormal floats might
 * be converted to normal reals.
 */

int isnormal(float x) { return fpclassify(x)==FP_NORMAL; }

/// ditto

int isnormal(double x) { return fpclassify(x)==FP_NORMAL; }

/// ditto

int isnormal(real x) { return fpclassify(x)==FP_NORMAL; }

/*
int isnormal(X)(X x)
{
    alias floatTraits!(X) F;
    
    static if(real.mant_dig==106) { // doubledouble
        // doubledouble is normal if the least significant part is normal.
        return isnormal((cast(double*)&x)[MANTISSA_LSB]);
    } else {
        // ridiculous DMD warning
        ushort e = cast(ushort)(F.EXPMASK & (cast(ushort *)&x)[F.EXPPOS_SHORT]);
        return (e != F.EXPMASK && e!=0);
    }
}
*/

unittest
{
    float f = 3;
    double d = 500;
    real e = 10e+48;

    assert(isnormal(f));
    assert(isnormal(d));
    assert(isnormal(e));
    f = d = e = 0;
    assert(!isnormal(f));
    assert(!isnormal(d));
    assert(!isnormal(e));
    assert(!isnormal(real.infinity));
    assert(isnormal(-real.max));
    assert(!isnormal(real.min/4));

}

/*********************************
 * Is number subnormal? (Also called "denormal".)
 * Subnormals have a 0 exponent and a 0 most significant mantissa bit.
 */

/* Need one for each format because subnormal floats might
 * be converted to normal reals.
 */

int issubnormal(float x) { return fpclassify(x) == FP_SUBNORMAL; }

unittest
{
    float f = 3.0;

    for (f = 1.0; !issubnormal(f); f /= 2)
        assert(f != 0);
}

/// ditto

int issubnormal(double x) { return fpclassify(x) == FP_SUBNORMAL; }

/*
int issubnormal(double d)
{
    uint *p = cast(uint *)&d;
    return (p[MANTISSA_MSB] & 0x7FF0_0000) == 0
        && (p[MANTISSA_LSB] || p[MANTISSA_MSB] & 0x000F_FFFF);
}
*/

unittest
{
    double f;

    for (f = 1; !issubnormal(f); f /= 2)
        assert(f != 0);
}

/// ditto

int issubnormal(real x) { return fpclassify(x) == FP_SUBNORMAL; }

/*
int issubnormal(real x)
{
    alias floatTraits!(real) F;
    static if (real.mant_dig == 53) { // double
        return issubnormal(cast(double)x);
    } else static if (real.mant_dig == 113) { // quadruple        
        ushort e = F.EXPMASK & (cast(ushort *)&x)[F.EXPPOS_SHORT];
        long*   ps = cast(long *)&x;
        return (e == 0 &&
          (((ps[MANTISSA_LSB]|(ps[MANTISSA_MSB]& 0x0000_FFFF_FFFF_FFFF))) !=0));
    } else static if (real.mant_dig==64) { // real80
        ushort* pe = cast(ushort *)&x;
        long*   ps = cast(long *)&x;

        return (pe[F.EXPPOS_SHORT] & F.EXPMASK) == 0 && *ps > 0;
    } else { // double double
        return issubnormal((cast(double*)&x)[MANTISSA_MSB]);
    }
}
*/

unittest
{
    real f;

    for (f = 1; !issubnormal(f); f /= 2)
        assert(f != 0);
}

/*********************************
 * Return !=0 if e is $(PLUSMN)$(INFIN).
 */

int isinf(real x) { return fpclassify(x)==FP_INFINITE; }

/*
int isinf(real x)
{
    alias floatTraits!(real) F;
    static if (real.mant_dig == 53) { // double
        return ((*cast(ulong *)&x) & 0x7FFF_FFFF_FFFF_FFFF)
                == 0x7FF8_0000_0000_0000;
    } else static if(real.mant_dig == 106) { //doubledouble
        return (((cast(ulong *)&x)[MANTISSA_MSB]) & 0x7FFF_FFFF_FFFF_FFFF)
                    == 0x7FF8_0000_0000_0000;   
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
*/
    
unittest
{
    assert(isinf(float.infinity));
    assert(!isinf(float.nan));
    assert(isinf(double.infinity));
    assert(isinf(-real.infinity));

    assert(isinf(-1.0 / 0.0));
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

/*********************************
 * Return 1 if sign bit of e is set, 0 if not.
 */

alias gcc.fpcls.signbit signbit;

/*
int signbit(real x)
{
    return ((cast(ubyte *)&x)[floatTraits!(real).SIGNPOS_BYTE] & 0x80) != 0;
}
*/

unittest
{
    debug (math) printf("math.signbit.unittest\n");
    assert(!signbit(float.nan));
    assert(signbit(-float.nan));
    assert(!signbit(168.1234));
    assert(signbit(-168.1234));
    assert(!signbit(0.0));
    assert(signbit(-0.0));
}

/*********************************
 * Return a value composed of to with from's sign bit.
 */

version (X86)
real copysign(real to, real from)
{
    ubyte* pto   = cast(ubyte *)&to;
    ubyte* pfrom = cast(ubyte *)&from;
    
    alias floatTraits!(real) F;
    pto[F.SIGNPOS_BYTE] &= 0x7F;
    pto[F.SIGNPOS_BYTE] |= pfrom[F.SIGNPOS_BYTE] & 0x80;
    return to;
}
else version (GNU)
    alias std.c.math.copysignl copysign;

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
    assert(isnan(e) && signbit(e));
}



/******************************************
 * Creates a quiet NAN with the information from tagp[] embedded in it.
 *
 * BUGS: DMD always returns real.nan, ignoring the payload.
 */
version (GNU_Need_nan)
real nan(char[] tagp) { return real.nan; } // could implement with strtod, but need test if THAT works first
else
real nan(char[] tagp) { return std.c.math.nanl(toStringz(tagp)); }

/**
 * Calculate the next largest floating point value after x.
 *
 * Return the least number greater than x that is representable as a real;
 * thus, it gives the next point on the IEEE number line.
 *
 *  $(TABLE_SV
 *    $(SVH x,            nextUp(x)   )
 *    $(SV  -$(INFIN),    -real.max   )
 *    $(SV  $(PLUSMN)0.0, real.min*real.epsilon )
 *    $(SV  real.max,     $(INFIN) )
 *    $(SV  $(INFIN),     $(INFIN) )
 *    $(SV  $(NAN),       $(NAN)   )
 * )
 *
 * Remarks:
 * This function is included in the forthcoming IEEE 754R standard.
 */
real nextUp(real x)
{
    alias floatTraits!(real) F;
    static if (real.mant_dig == 53) { // double
        return nextUp(cast(double)x);
    } else static if(real.mant_dig==113) {  // quadruple
        ushort e = F.EXPMASK & (cast(ushort *)&x)[F.EXPPOS_SHORT];
        if (e == F.EXPMASK) { // NaN or Infinity
             if (x == -real.infinity) return -real.max;
             return x; // +Inf and NaN are unchanged.
        }     
        ulong*   ps = cast(ulong *)&e;
        if (ps[MANTISSA_LSB] & 0x8000_0000_0000_0000)  { // Negative number
            if (ps[MANTISSA_LSB] == 0
             && ps[MANTISSA_MSB] == 0x8000_0000_0000_0000) {
                // it was negative zero, change to smallest subnormal
                ps[MANTISSA_LSB] = 0x0000_0000_0000_0001;
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
        if (pe[F.EXPPOS_SHORT] & 0x8000)  {
            // Negative number -- need to decrease the significand
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
double nextUp(double x)
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
float nextUp(float x)
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

/**
 * Calculate the next smallest floating point value before x.
 *
 * Return the greatest number less than x that is representable as a real;
 * thus, it gives the previous point on the IEEE number line.
 *
 *  $(TABLE_SV
 *    $(SVH x,            nextDown(x)   )
 *    $(SV  $(INFIN),     real.max  )
 *    $(SV  $(PLUSMN)0.0, -real.min*real.epsilon )
 *    $(SV  -real.max,    -$(INFIN) )
 *    $(SV  -$(INFIN),    -$(INFIN) )
 *    $(SV  $(NAN),       $(NAN)    )
 * )
 *
 * Remarks:
 * This function is included in the forthcoming IEEE 754R standard.
 */
real nextDown(real x)
{
    return -nextUp(-x);
}

/** ditto */
double nextDown(double x)
{
    return -nextUp(-x);
}

/** ditto */
float nextDown(float x)
{
    return -nextUp(-x);
}

unittest {
    assert( nextDown(1.0 + real.epsilon) == 1.0);
}


/******************************************
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
 * IEEE 754 requirements not implemented on Windows:
 * The FE_INEXACT and FE_OVERFLOW exceptions will be raised if x is finite and
 * the function result is infinite. The FE_INEXACT and FE_UNDERFLOW
 * exceptions will be raised if the function value is subnormal, and x is
 * not equal to y.
 */
real nextafter(real x, real y)
{
    version (Windows) {
        if (x==y) return y;
        return (y>x) ? nextUp(x) : nextDown(x);
    } else {
        return std.c.math.nextafterl(x, y);
    }
}

/// ditto
float nextafter(float x, float y)
{
    version (Windows) {
        if (x==y) return y;
        return (y>x) ? nextUp(x) : nextDown(x);
    } else {
        return std.c.math.nextafterf(x, y);
    }
}

/// ditto
double nextafter(double x, double y)
{
    version (Windows) {
        if (x==y) return y;
        return (y>x) ? nextUp(x) : nextDown(x);
    } else {
        return std.c.math.nextafter(x, y);
    }
}

unittest
{
    float a = 1;
    assert(is(typeof(nextafter(a, a)) == float));
    assert(nextafter(a, a.infinity) > a);

    double b = 2;
    assert(is(typeof(nextafter(b, b)) == double));
    assert(nextafter(b, b.infinity) > b);

    real c = 3;
    assert(is(typeof(nextafter(c, c)) == real));
    assert(nextafter(c, c.infinity) > c);
}

//real nexttoward(real x, real y) { return std.c.math.nexttowardl(x, y); }

/*******************************************
 * Returns the positive difference between x and y.
 * Returns:
 *      $(TABLE_SV
 *      $(TR $(TH x, y)       $(TH fdim(x, y)))
 *      $(TR $(TD x $(GT) y)  $(TD x - y))
 *      $(TR $(TD x $(LT)= y) $(TD +0.0))
 *      )
 */
real fdim(real x, real y) { return (x > y) ? x - y : +0.0; }

/****************************************
 * Returns the larger of x and y.
 */
real fmax(real x, real y) { return x > y ? x : y; }

/****************************************
 * Returns the smaller of x and y.
 */
real fmin(real x, real y) { return x < y ? x : y; }

/**************************************
 * Returns (x * y) + z, rounding only once according to the
 * current rounding mode.
 *
 * BUGS: Not currently implemented - rounds twice.
 */
real fma(real x, real y, real z) { return (x * y) + z; }

/*******************************************************************
 * Fast integral powers.
 */

real pow(real x, uint n)
{
    real p;

    switch (n)
    {
        case 0:
            p = 1.0;
            break;

        case 1:
            p = x;
            break;

        case 2:
            p = x * x;
            break;

        default:
            p = 1.0;
            while (1)
            {
                if (n & 1)
                    p *= x;
                n >>= 1;
                if (!n)
                    break;
                x *= x;
            }
            break;
    }
    return p;
}

/// ditto

real pow(real x, int n)
{
    if (n < 0)
        return pow(x, cast(real)n);
    else
        return pow(x, cast(uint)n);
}

/*********************************************
 * Calculates x$(SUP y).
 *
 * $(TABLE_SV
 * $(TR $(TH x) $(TH y) $(TH pow(x, y))
 *      $(TH div 0) $(TH invalid?))
 * $(TR $(TD anything)      $(TD $(PLUSMN)0.0)                $(TD 1.0)
 *      $(TD no)        $(TD no) )
 * $(TR $(TD |x| $(GT) 1)    $(TD +$(INFIN))                  $(TD +$(INFIN))
 *      $(TD no)        $(TD no) )
 * $(TR $(TD |x| $(LT) 1)    $(TD +$(INFIN))                  $(TD +0.0)
 *      $(TD no)        $(TD no) )
 * $(TR $(TD |x| $(GT) 1)    $(TD -$(INFIN))                  $(TD +0.0)
 *      $(TD no)        $(TD no) )
 * $(TR $(TD |x| $(LT) 1)    $(TD -$(INFIN))                  $(TD +$(INFIN))
 *      $(TD no)        $(TD no) )
 * $(TR $(TD +$(INFIN))      $(TD $(GT) 0.0)                  $(TD +$(INFIN))
 *      $(TD no)        $(TD no) )
 * $(TR $(TD +$(INFIN))      $(TD $(LT) 0.0)                  $(TD +0.0)
 *      $(TD no)        $(TD no) )
 * $(TR $(TD -$(INFIN))      $(TD odd integer $(GT) 0.0)      $(TD -$(INFIN))
 *      $(TD no)        $(TD no) )
 * $(TR $(TD -$(INFIN))      $(TD $(GT) 0.0, not odd integer) $(TD +$(INFIN))
 *      $(TD no)        $(TD no))
 * $(TR $(TD -$(INFIN))      $(TD odd integer $(LT) 0.0)      $(TD -0.0)
 *      $(TD no)        $(TD no) )
 * $(TR $(TD -$(INFIN))      $(TD $(LT) 0.0, not odd integer) $(TD +0.0)
 *      $(TD no)        $(TD no) )
 * $(TR $(TD $(PLUSMN)1.0)   $(TD $(PLUSMN)$(INFIN))          $(TD $(NAN))
 *      $(TD no)        $(TD yes) )
 * $(TR $(TD $(LT) 0.0)      $(TD finite, nonintegral)        $(TD $(NAN))
 *      $(TD no)        $(TD yes))
 * $(TR $(TD $(PLUSMN)0.0)   $(TD odd integer $(LT) 0.0)      $(TD $(PLUSMNINF))
 *      $(TD yes)       $(TD no) )
 * $(TR $(TD $(PLUSMN)0.0)   $(TD $(LT) 0.0, not odd integer) $(TD +$(INFIN))
 *      $(TD yes)       $(TD no))
 * $(TR $(TD $(PLUSMN)0.0)   $(TD odd integer $(GT) 0.0)      $(TD $(PLUSMN)0.0)
 *      $(TD no)        $(TD no) )
 * $(TR $(TD $(PLUSMN)0.0)   $(TD $(GT) 0.0, not odd integer) $(TD +0.0)
 *      $(TD no)        $(TD no) )
 * )
 */

real pow(real x, real y)
{
    //version (linux) // C pow() often does not handle special values correctly
    version (GNU) // ...assume the same for all GCC targets
    {
        if (isnan(y))
            return y;

        if (y == 0)
            return 1;           // even if x is $(NAN)
        if (isnan(x) && y != 0)
            return x;
        if (isinf(y))
        {
            if (fabs(x) > 1)
            {
                if (signbit(y))
                    return +0.0;
                else
                    return real.infinity;
            }
            else if (fabs(x) == 1)
            {
                return real.nan;
            }
            else // < 1
            {
                if (signbit(y))
                    return real.infinity;
                else
                    return +0.0;
            }
        }
        if (isinf(x))
        {
            if (signbit(x))
            {   long i;

                i = cast(long)y;
                if (y > 0)
                {
                    if (i == y && i & 1)
                        return -real.infinity;
                    else
                        return real.infinity;
                }
                else if (y < 0)
                {
                    if (i == y && i & 1)
                        return -0.0;
                    else
                        return +0.0;
                }
            }
            else
            {
                if (y > 0)
                    return real.infinity;
                else if (y < 0)
                    return +0.0;
            }
        }

        if (x == 0.0)
        {
            if (signbit(x))
            {   long i;

                i = cast(long)y;
                if (y > 0)
                {
                    if (i == y && i & 1)
                        return -0.0;
                    else
                        return +0.0;
                }
                else if (y < 0)
                {
                    if (i == y && i & 1)
                        return -real.infinity;
                    else
                        return real.infinity;
                }
            }
            else
            {
                if (y > 0)
                    return +0.0;
                else if (y < 0)
                    return real.infinity;
            }
        }
    }
    return std.c.math.powl(x, y);
}

unittest
{
    real x = 46;

    assert(pow(x,0) == 1.0);
    assert(pow(x,1) == x);
    assert(pow(x,2) == x * x);
    assert(pow(x,3) == x * x * x);
    assert(pow(x,8) == (x * x) * (x * x) * (x * x) * (x * x));
}

/****************************************
 * Simple function to compare two floating point values
 * to a specified precision.
 * Returns:
 *      1       match
 *      0       nomatch
 */

private int mfeq(real x, real y, real precision)
{
    if (x == y)
        return 1;
    if (isnan(x))
        return isnan(y);
    if (isnan(y))
        return 0;
    return fabs(x - y) <= precision;
}

version (X86)
{
// These routines assume Intel 80-bit floating point format

/**************************************
 * To what precision is x equal to y?
 *
 * Returns: the number of mantissa bits which are equal in x and y.
 * eg, 0x1.F8p+60 and 0x1.F1p+60 are equal to 5 bits of precision.
 *
 *      $(TABLE_SV
 *      $(TR $(TH x)      $(TH y)          $(TH feqrel(x, y)))
 *      $(TR $(TD x)      $(TD x)          $(TD real.mant_dig))
 *      $(TR $(TD x)      $(TD $(GT)= 2*x) $(TD 0))
 *      $(TR $(TD x)      $(TD $(LT)= x/2) $(TD 0))
 *      $(TR $(TD $(NAN)) $(TD any)        $(TD 0))
 *      $(TR $(TD any)    $(TD $(NAN))     $(TD 0))
 *      )
 */
int feqrel(X)(X x, X y)
{
    /* Public Domain. Author: Don Clugston, 18 Aug 2005.
     */
  static assert(is(X==real) || is(X==double) || is(X==float), 
        "Only float, double, and real are supported by feqrel");
  
  static if (X.mant_dig == 106) { // doubledouble.
     if (cast(double*)(&x)[MANTISSA_MSB] == cast(double*)(&y)[MANTISSA_MSB]) {
         return double.mant_dig
         + feqrel(cast(double*)(&x)[MANTISSA_LSB],
                  cast(double*)(&y)[MANTISSA_LSB]);
     } else {
         return feqrel(cast(double*)(&x)[MANTISSA_MSB],
                       cast(double*)(&y)[MANTISSA_MSB]);
     }
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
    int bitsdiff = ( ((pa[F.EXPPOS_SHORT]&0x7FFF) 
                    + (pb[F.EXPPOS_SHORT]&0x7FFF)-1)>>1) 
                    - pd[F.EXPPOS_SHORT];
 } else static if (X.mant_dig==53) { // double
    int bitsdiff = (( ((pa[F.EXPPOS_SHORT]&0x7FF0) 
                     + (pb[F.EXPPOS_SHORT]&0x7FF0)-0x10)>>1) 
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
        if (bitsdiff == 0 
          && !((pa[F.EXPPOS_SHORT] ^ pb[F.EXPPOS_SHORT])& F.EXPMASK)) {
              return 1;
        } else return 0;
     }  
 } else {
    throw new NotImplemented("feqrel");
 }
}

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

} // version(X86)
else
{
    // not implemented
}

package: // Not public yet
/* Return the value that lies halfway between x and y on the IEEE number line.
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

        // Avoid ridiculous warning
        ushort e = cast(ushort)((xe[F.EXPPOS_SHORT] & 0x7FFF)
                              + (ye[F.EXPPOS_SHORT] & 0x7FFF));
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
        // Avoid ridiculous warning
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
        ulong m = (((*xl) & 0x7FFF_FFFF_FFFF_FFFFL)
                 + ((*yl) & 0x7FFF_FFFF_FFFF_FFFFL)) >>> 1;
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

unittest {
    assert(ieeeMean(-0.0,-1e-20)<0);
    assert(ieeeMean(0.0,1e-20)>0);

    assert(ieeeMean(1.0L,4.0L)==2L);
    assert(ieeeMean(2.0*1.013,8.0*1.013)==4*1.013);
    assert(ieeeMean(-1.0L,-4.0L)==-2L);
    assert(ieeeMean(-1.0,-4.0)==-2);
    assert(ieeeMean(-1.0f,-4.0f)==-2f);
    assert(ieeeMean(-1.0,-2.0)==-1.5);
    assert(ieeeMean(-1*(1+8*real.epsilon),-2*(1+8*real.epsilon))
                 ==-1.5*(1+5*real.epsilon));
    assert(ieeeMean(0x1p60,0x1p-10)==0x1p25);
    static if (real.mant_dig==64) { // x87, 80-bit reals
      assert(ieeeMean(1.0L,real.infinity)==0x1p8192L);
      assert(ieeeMean(0.0L,real.infinity)==1.5);
    }
    assert(ieeeMean(0.5*real.min*(1-4*real.epsilon),0.5*real.min)
           == 0.5*real.min*(1-2*real.epsilon));
}

public:

    
// The space allocated for real varies across targets.
version (D_InlineAsm_X86)
{
    static if (real.sizeof == 10)
	{ version = poly_10; }
    else static if (real.sizeof == 12)
	{ version = poly_12; }
}

/***********************************
 * Evaluate polynomial A(x) = $(SUB a, 0) + $(SUB a, 1)x + $(SUB a, 2)&sup2;
 *                          + $(SUB a,3)x&sup3; ...
 * Uses Horner's rule A(x) = $(SUB a, 0) + x($(SUB a, 1) + x($(SUB a, 2) 
 *                         + x($(SUB a, 3) + ...)))
 * Params:
 *      A =     array of coefficients $(SUB a, 0), $(SUB a, 1), etc.
 */ 
real poly(real x, real[] A)
in
{
    assert(A.length > 0);
}
body
{
    version (poly_10)
    {
        // BUG: This code assumes a frame pointer in EBP.
        asm    // assembler by W. Bright
        {
            // EDX = (A.length - 1) * real.sizeof
            mov     ECX,A[EBP]              ; // ECX = A.length
            dec     ECX                     ;
            lea     EDX,[ECX][ECX*8]        ;
            add     EDX,ECX                 ;
            add     EDX,A+4[EBP]            ;
            fld     real ptr [EDX]          ; // ST0 = coeff[ECX]
            jecxz   return_ST               ;
            fld     x[EBP]                  ; // ST0 = x
            fxch    ST(1)                   ; // ST1 = x, ST0 = r
            align   4                       ;
            L2:     fmul    ST,ST(1)        ; // r *= x
            fld     real ptr -10[EDX]       ;
            sub     EDX,10                  ; // deg--
            faddp   ST(1),ST                ;
            dec     ECX                     ;
            jne     L2                      ;
            fxch    ST(1)                   ; // ST1 = r, ST0 = x
            fstp    ST(0)                   ; // dump x
            align   4                       ;
            return_ST:                      ;
            ;
        }
    }
    else version (poly_12)
    {
        asm    // above code with modifications for GCC
        {
            // EDX = (A.length - 1) * real.sizeof
            mov     ECX,A[EBP]              ; // ECX = A.length
            dec     ECX                     ;
            lea     EDX,[ECX][ECX*2]        ;
            lea     EDX,[EDX*4]             ;
            add     EDX,A+4[EBP]            ;
            fld     real ptr [EDX]          ; // ST0 = coeff[ECX]
            jecxz   return_ST               ;
            fld     x                       ; // ST0 = x
            fxch    ST(1)                   ; // ST1 = x, ST0 = r
            align   4                       ;
        L2:     fmul    ST,ST(1)            ; // r *= x
            fld     real ptr -12[EDX]       ;
            sub     EDX,12                  ; // deg--
            faddp   ST(1),ST                ;
            dec     ECX                     ;
            jne     L2                      ;
            fxch    ST(1)                   ; // ST1 = r, ST0 = x
            fstp    ST(0)                   ; // dump x
            align   4                       ;
        return_ST:                          ;
            ;
        }
    }
    else
    {
        ptrdiff_t i = A.length - 1;
        real r = A[i];
        while (--i >= 0)
        {
            r *= x;
            r += A[i];
        }
        return r;
    }
}

unittest
{
    debug (math) printf("math.poly.unittest\n");
    real x = 3.1;
    static real pp[] = [56.1, 32.7, 6];

    assert( poly(x, pp) == (56.1L + (32.7L + 6L * x) * x) );
}
