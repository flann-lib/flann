/**
 * Error Functions and Normal Distribution.
 *
 * Copyright: Copyright (C) 1984, 1995, 2000 Stephen L. Moshier
 *   Code taken from the Cephes Math Library Release 2.3:  January, 1995
 * License:   BSD style: $(LICENSE)
 * Authors:   Stephen L. Moshier, ported to D by Don Clugston
 */
/**
 * Macros:
 *  NAN = $(RED NAN)
 *  SUP = <span style="vertical-align:super;font-size:smaller">$0</span>
 *  GAMMA =  &#915;
 *  INTEGRAL = &#8747;
 *  INTEGRATE = $(BIG &#8747;<sub>$(SMALL $1)</sub><sup>$2</sup>)
 *  POWER = $1<sup>$2</sup>
 *  BIGSUM = $(BIG &Sigma; <sup>$2</sup><sub>$(SMALL $1)</sub>)
 *  CHOOSE = $(BIG &#40;) <sup>$(SMALL $1)</sup><sub>$(SMALL $2)</sub> $(BIG &#41;)
 *  TABLE_SV = <table border=1 cellpadding=4 cellspacing=0>
 *      <caption>Special Values</caption>
 *      $0</table>
 *  SVH = $(TR $(TH $1) $(TH $2))
 *  SV  = $(TR $(TD $1) $(TD $2))
 */
module tango.math.ErrorFunction;

import tango.math.Math;
import tango.math.IEEE;  // only required for unit tests

version(Windows) { // Some tests only pass on DMD Windows
    version(DigitalMars) {
    version = FailsOnLinux;
}
}

const real SQRT2PI = 0x1.40d931ff62705966p+1L;    // 2.5066282746310005024
const real EXP_2  = 0.13533528323661269189L; /* exp(-2) */

private {
    
/* erfc(x) = exp(-x^2) P(1/x)/Q(1/x)
   1/8 <= 1/x <= 1
   Peak relative error 5.8e-21  */
const real [] P = [ -0x1.30dfa809b3cc6676p-17, 0x1.38637cd0913c0288p+18,
   0x1.2f015e047b4476bp+22, 0x1.24726f46aa9ab08p+25, 0x1.64b13c6395dc9c26p+27,
   0x1.294c93046ad55b5p+29, 0x1.5962a82f92576dap+30, 0x1.11a709299faba04ap+31,
   0x1.11028065b087be46p+31, 0x1.0d8ef40735b097ep+30
];

const real [] Q = [ 0x1.14d8e2a72dec49f4p+19, 0x1.0c880ff467626e1p+23,
   0x1.04417ef060b58996p+26, 0x1.404e61ba86df4ebap+28, 0x1.0f81887bc82b873ap+30,
   0x1.4552a5e39fb49322p+31, 0x1.11779a0ceb2a01cep+32, 0x1.3544dd691b5b1d5cp+32,
   0x1.a91781f12251f02ep+31, 0x1.0d8ef3da605a1c86p+30, 1.0
];


/* erfc(x) = exp(-x^2) 1/x R(1/x^2) / S(1/x^2)
   1/128 <= 1/x < 1/8
   Peak relative error 1.9e-21  */
const real [] R = [ 0x1.b9f6d8b78e22459ep-6, 0x1.1b84686b0a4ea43ap-1,
   0x1.b8f6aebe96000c2ap+1, 0x1.cb1dbedac27c8ec2p+2, 0x1.cf885f8f572a4c14p+1
];

const real [] S = [
   0x1.87ae3cae5f65eb5ep-5, 0x1.01616f266f306d08p+0, 0x1.a4abe0411eed6c22p+2,
   0x1.eac9ce3da600abaap+3, 0x1.5752a9ac2faebbccp+3, 1.0
];

/* erf(x)  = x P(x^2)/Q(x^2)
   0 <= x <= 1
   Peak relative error 7.6e-23  */
const real [] T = [ 0x1.0da01654d757888cp+20, 0x1.2eb7497bc8b4f4acp+17,
   0x1.79078c19530f72a8p+15, 0x1.4eaf2126c0b2c23p+11, 0x1.1f2ea81c9d272a2ep+8,
   0x1.59ca6e2d866e625p+2, 0x1.c188e0b67435faf4p-4 
];

const real [] U = [ 0x1.dde6025c395ae34ep+19, 0x1.c4bc8b6235df35aap+18,
   0x1.8465900e88b6903ap+16, 0x1.855877093959ffdp+13, 0x1.e5c44395625ee358p+9,
   0x1.6a0fed103f1c68a6p+5, 1.0
];

}

/**
 *  Complementary error function
 *
 * erfc(x) = 1 - erf(x), and has high relative accuracy for
 * values of x far from zero. (For values near zero, use erf(x)).
 *
 *  1 - erf(x) =  2/ $(SQRT)(&pi;)
 *     $(INTEGRAL x, $(INFINITY)) exp( - $(POWER t, 2)) dt
 *
 *
 * For small x, erfc(x) = 1 - erf(x); otherwise rational
 * approximations are computed.
 *
 * A special function expx2(x) is used to suppress error amplification
 * in computing exp(-x^2).
 */
real erfc(real a)
{
    if (a == real.infinity)
        return 0.0;
    if (a == -real.infinity)
        return 2.0;

    real x;

    if (a < 0.0L )
        x = -a;
    else
        x = a;
    if (x < 1.0)
        return 1.0 - erf(a);

    real z = -a * a;

    if (z < -MAXLOG){
//    mtherr( "erfcl", UNDERFLOW );
        if (a < 0) return 2.0;
        else return 0.0;
    }

    /* Compute z = exp(z).  */
    z = expx2(a, -1);
    real y = 1.0/x;

    real p, q;

    if( x < 8.0 ) y = z * rationalPoly(y, P, Q);
    else          y = z * y * rationalPoly(y * y, R, S);

    if (a < 0.0L)
        y = 2.0L - y;

    if (y == 0.0) {
//    mtherr( "erfcl", UNDERFLOW );
        if (a < 0) return 2.0;
        else return 0.0;
    }

    return y;
}


private {
/* Exponentially scaled erfc function
   exp(x^2) erfc(x)
   valid for x > 1.
   Use with normalDistribution and expx2.  */

real erfce(real x)
{
    real p, q;

    real y = 1.0/x;

    if (x < 8.0) {
        return rationalPoly( y, P, Q);
    } else {
        return y * rationalPoly(y*y, R, S);
    }
}

}

/**
 *  Error function
 *
 * The integral is
 *
 *  erf(x) =  2/ $(SQRT)(&pi;)
 *     $(INTEGRAL 0, x) exp( - $(POWER t, 2)) dt
 *
 * The magnitude of x is limited to about 106.56 for IEEE 80-bit
 * arithmetic; 1 or -1 is returned outside this range.
 *
 * For 0 <= |x| < 1, a rational polynomials are used; otherwise
 * erf(x) = 1 - erfc(x).
 *
 * ACCURACY:
 *                      Relative error:
 * arithmetic   domain     # trials      peak         rms
 *    IEEE      0,1         50000       2.0e-19     5.7e-20
 */
real erf(real x)
{
    if (x == 0.0)
        return x; // deal with negative zero
    if (x == -real.infinity)
        return -1.0;
    if (x == real.infinity)
        return 1.0;
    if (abs(x) > 1.0L)
        return 1.0L - erfc(x);

    real z = x * x;
    return x * rationalPoly(z, T, U);
}

debug(UnitTest) {
unittest {
   // High resolution test points.
    const real erfc0_250 = 0.723663330078125 + 1.0279753638067014931732235184287934646022E-5;
    const real erfc0_375 = 0.5958709716796875 + 1.2118885490201676174914080878232469565953E-5;
    const real erfc0_500 = 0.4794921875 + 7.9346869534623172533461080354712635484242E-6;
    const real erfc0_625 = 0.3767547607421875 + 4.3570693945275513594941232097252997287766E-6;
    const real erfc0_750 = 0.2888336181640625 + 1.0748182422368401062165408589222625794046E-5;
    const real erfc0_875 = 0.215911865234375 + 1.3073705765341685464282101150637224028267E-5;
    const real erfc1_000 = 0.15728759765625 + 1.1609394035130658779364917390740703933002E-5;
    const real erfc1_125 = 0.111602783203125 + 8.9850951672359304215530728365232161564636E-6;

    const real erf0_875  = (1-0.215911865234375) - 1.3073705765341685464282101150637224028267E-5;


    assert(feqrel(erfc(0.250L), erfc0_250 )>=real.mant_dig-1);
    assert(feqrel(erfc(0.375L), erfc0_375 )>=real.mant_dig-0);
    assert(feqrel(erfc(0.500L), erfc0_500 )>=real.mant_dig-1);
    assert(feqrel(erfc(0.625L), erfc0_625 )>=real.mant_dig-1);
    assert(feqrel(erfc(0.750L), erfc0_750 )>=real.mant_dig-1);
    assert(feqrel(erfc(0.875L), erfc0_875 )>=real.mant_dig-4);
    version(FailsOnLinux) assert(feqrel(erfc(1.000L), erfc1_000 )>=real.mant_dig-0);
    assert(feqrel(erfc(1.125L), erfc1_125 )>=real.mant_dig-2);
    assert(feqrel(erf(0.875L), erf0_875 )>=real.mant_dig-1);
    // The DMC implementation of erfc() fails this next test (just)
    assert(feqrel(erfc(4.1L),0.67000276540848983727e-8L)>=real.mant_dig-4);

    assert(isIdentical(erf(0.0),0.0));
    assert(isIdentical(erf(-0.0),-0.0));
    assert(erf(real.infinity) == 1.0);
    assert(erf(-real.infinity) == -1.0);
    assert(isIdentical(erf(NaN(0xDEF)),NaN(0xDEF)));
    assert(isIdentical(erfc(NaN(0xDEF)),NaN(0xDEF)));
    assert(isIdentical(erfc(real.infinity),0.0));
    assert(erfc(-real.infinity) == 2.0);
    assert(erfc(0) == 1.0);
}
}

/*
 *  Exponential of squared argument
 *
 * Computes y = exp(x*x) while suppressing error amplification
 * that would ordinarily arise from the inexactness of the
 * exponential argument x*x.
 *
 * If sign < 0, the result is inverted; i.e., y = exp(-x*x) .
 *
 * ACCURACY:
 *                      Relative error:
 * arithmetic      domain        # trials      peak         rms
 *   IEEE     -106.566, 106.566    10^5       1.6e-19     4.4e-20
 */

real expx2(real x, int sign)
{
    /*
    Cephes Math Library Release 2.9:  June, 2000
    Copyright 2000 by Stephen L. Moshier
    */
    const real M = 32768.0;
    const real MINV = 3.0517578125e-5L;

    x = abs(x);
    if (sign < 0)
        x = -x;

  /* Represent x as an exact multiple of M plus a residual.
     M is a power of 2 chosen so that exp(m * m) does not overflow
     or underflow and so that |x - m| is small.  */
    real m = MINV * floor(M * x + 0.5L);
    real f = x - m;

    /* x^2 = m^2 + 2mf + f^2 */
    real u = m * m;
    real u1 = 2 * m * f  +  f * f;

    if (sign < 0) {
        u = -u;
        u1 = -u1;
    }

    if ((u+u1) > MAXLOG)
        return real.infinity;

    /* u is exact, u1 is small.  */
    return exp(u) * exp(u1);
}


package {
/*
Computes the normal distribution function.

The normal (or Gaussian, or bell-shaped) distribution is
defined as:

normalDist(x) = 1/$(SQRT) &pi; $(INTEGRAL -$(INFINITY), x) exp( - $(POWER t, 2)/2) dt
    = 0.5 + 0.5 * erf(x/sqrt(2))
    = 0.5 * erfc(- x/sqrt(2))

To maintain accuracy at high values of x, use
normalDistribution(x) = 1 - normalDistribution(-x).

Accuracy:
Within a few bits of machine resolution over the entire
range.

References:
$(LINK http://www.netlib.org/cephes/ldoubdoc.html),
G. Marsaglia, "Evaluating the Normal Distribution",
Journal of Statistical Software <b>11</b>, (July 2004).
*/
real normalDistributionImpl(real a)
{
    real x = a * SQRT1_2;
    real z = abs(x);

    if( z < 1.0 )
        return 0.5L + 0.5L * erf(x);
    else {
        /* See below for erfce. */
        real y = 0.5L * erfce(z);
        /* Multiply by exp(-x^2 / 2)  */
        z = expx2(a, -1);
        y = y * sqrt(z);
        if( x > 0.0L )
            y = 1.0L - y;
        return y;
    }
}

}

debug(UnitTest) {
unittest {
assert(fabs(normalDistributionImpl(1L) - (0.841344746068543))< 0.0000000000000005);
assert(isIdentical(normalDistributionImpl(NaN(0x325)), NaN(0x325)));
}
}

package {
/*
 * Inverse of Normal distribution function
 *
 * Returns the argument, x, for which the area under the
 * Normal probability density function (integrated from
 * minus infinity to x) is equal to p.
 *
 * For small arguments 0 < p < exp(-2), the program computes
 * z = sqrt( -2 log(p) );  then the approximation is
 * x = z - log(z)/z  - (1/z) P(1/z) / Q(1/z) .
 * For larger arguments,  x/sqrt(2 pi) = w + w^3 R(w^2)/S(w^2)) ,
 * where w = p - 0.5 .
 */
real normalDistributionInvImpl(real p)
in {
  assert(p>=0.0L && p<=1.0L, "Domain error");
}
body
{
const real P0[] = [ -0x1.758f4d969484bfdcp-7, 0x1.53cee17a59259dd2p-3,
   -0x1.ea01e4400a9427a2p-1,  0x1.61f7504a0105341ap+1, -0x1.09475a594d0399f6p+2,
    0x1.7c59e7a0df99e3e2p+1, -0x1.87a81da52edcdf14p-1,  0x1.1fb149fd3f83600cp-7
];

const real Q0[] = [ -0x1.64b92ae791e64bb2p-7, 0x1.7585c7d597298286p-3,
   -0x1.40011be4f7591ce6p+0, 0x1.1fc067d8430a425ep+2, -0x1.21008ffb1e7ccdf2p+3,
   0x1.3d1581cf9bc12fccp+3, -0x1.53723a89fd8f083cp+2, 1.0
];

const real P1[] = [ 0x1.20ceea49ea142f12p-13, 0x1.cbe8a7267aea80bp-7,
   0x1.79fea765aa787c48p-2, 0x1.d1f59faa1f4c4864p+1, 0x1.1c22e426a013bb96p+4,
   0x1.a8675a0c51ef3202p+5, 0x1.75782c4f83614164p+6, 0x1.7a2f3d90948f1666p+6,
   0x1.5cd116ee4c088c3ap+5, 0x1.1361e3eb6e3cc20ap+2
];

const real Q1[] = [ 0x1.3a4ce1406cea98fap-13, 0x1.f45332623335cda2p-7,
   0x1.98f28bbd4b98db1p-2, 0x1.ec3b24f9c698091cp+1, 0x1.1cc56ecda7cf58e4p+4,
   0x1.92c6f7376bf8c058p+5, 0x1.4154c25aa47519b4p+6, 0x1.1b321d3b927849eap+6,
   0x1.403a5f5a4ce7b202p+4, 1.0
];

const real P2[] = [ 0x1.8c124a850116a6d8p-21, 0x1.534abda3c2fb90bap-13, 
   0x1.29a055ec93a4718cp-7, 0x1.6468e98aad6dd474p-3, 0x1.3dab2ef4c67a601cp+0,
   0x1.e1fb3a1e70c67464p+1, 0x1.b6cce8035ff57b02p+2, 0x1.9f4c9e749ff35f62p+1
];

const real Q2[] = [ 0x1.af03f4fc0655e006p-21, 0x1.713192048d11fb2p-13,
   0x1.4357e5bbf5fef536p-7, 0x1.7fdac8749985d43cp-3, 0x1.4a080c813a2d8e84p+0,
   0x1.c3a4b423cdb41bdap+1, 0x1.8160694e24b5557ap+2, 1.0
];

const real P3[] = [ -0x1.55da447ae3806168p-34, -0x1.145635641f8778a6p-24,
 -0x1.abf46d6b48040128p-17, -0x1.7da550945da790fcp-11, -0x1.aa0b2a31157775fap-8,
   0x1.b11d97522eed26bcp-3, 0x1.1106d22f9ae89238p+1, 0x1.029a358e1e630f64p+1
];

const real Q3[] = [ -0x1.74022dd5523e6f84p-34, -0x1.2cb60d61e29ee836p-24,
   -0x1.d19e6ec03a85e556p-17, -0x1.9ea2a7b4422f6502p-11, -0x1.c54b1e852f107162p-8,
   0x1.e05268dd3c07989ep-3, 0x1.239c6aff14afbf82p+1, 1.0
];

  if(p<=0.0L || p>=1.0L) {
        if (p == 0.0L) {
            return -real.infinity;
        }
        if( p == 1.0L ) {
            return real.infinity;
        }
        return NaN(TANGO_NAN.NORMALDISTRIBUTION_INV_DOMAIN);
    }
    int code = 1;
    real y = p;
    if( y > (1.0L - EXP_2) ) {
        y = 1.0L - y;
        code = 0;
    }

    real x, z, y2, x0, x1;

    if ( y > EXP_2 ) {
        y = y - 0.5L;
        y2 = y * y;
        x = y + y * (y2 * rationalPoly( y2, P0, Q0));
        return x * SQRT2PI;
    }

    x = sqrt( -2.0L * log(y) );
    x0 = x - log(x)/x;
    z = 1.0L/x;
    if ( x < 8.0L ) {
        x1 = z * rationalPoly( z, P1, Q1);
    } else if( x < 32.0L ) {
        x1 = z * rationalPoly( z, P2, Q2);
    } else {
        x1 = z * rationalPoly( z, P3, Q3);
    }
    x = x0 - x1;
    if ( code != 0 ) {
        x = -x;
    }
    return x;
}

}


debug(UnitTest) {
unittest {
    // TODO: Use verified test points.
    // The values below are from Excel 2003.
assert(fabs(normalDistributionInvImpl(0.001) - (-3.09023230616779))< 0.00000000000005);
assert(fabs(normalDistributionInvImpl(1e-50) - (-14.9333375347885))< 0.00000000000005);
assert(feqrel(normalDistributionInvImpl(0.999), -normalDistributionInvImpl(0.001))>real.mant_dig-6);

// Excel 2003 gets all the following values wrong!
assert(normalDistributionInvImpl(0.0)==-real.infinity);
assert(normalDistributionInvImpl(1.0)==real.infinity);
assert(normalDistributionInvImpl(0.5)==0);
// (Excel 2003 returns norminv(p) = -30 for all p < 1e-200).
// The value tested here is the one the function returned in Jan 2006.
real unknown1 = normalDistributionInvImpl(1e-250L);
assert( fabs(unknown1 -(-33.79958617269L) ) < 0.00000005);
}
}