/**
 * Elliptic integrals.
 * The functions are named similarly to the names used in Mathematica. 
 *
 * License:   BSD style: $(LICENSE)
 * Copyright: Based on the CEPHES math library, which is
 *            Copyright (C) 1994 Stephen L. Moshier (moshier@world.std.com).
 * Authors:   Stephen L. Moshier (original C code). Conversion to D by Don Clugston
 *
 * References:
 * $(LINK http://en.wikipedia.org/wiki/Elliptic_integral)
 *
 * Eric W. Weisstein. "Elliptic Integral of the First Kind." From MathWorld--A Wolfram Web Resource. $(LINK http://mathworld.wolfram.com/EllipticIntegraloftheFirstKind.html)
 *
 * $(LINK http://www.netlib.org/cephes/ldoubdoc.html)
 *
 * Macros:
 *  TABLE_SV = <table border=1 cellpadding=4 cellspacing=0>
 *      <caption>Special Values</caption>
 *      $0</table>
 *  SVH = $(TR $(TH $1) $(TH $2))
 *  SV  = $(TR $(TD $1) $(TD $2))
 *  GAMMA =  &#915;
 *  INTEGRATE = $(BIG &#8747;<sub>$(SMALL $1)</sub><sup>$2</sup>)
 *  POWER = $1<sup>$2</sup>
 *  NAN = $(RED NAN)
 */
/**
 * Macros:
 *  TABLE_SV = <table border=1 cellpadding=4 cellspacing=0>
 *      <caption>Special Values</caption>
 *      $0</table>
 *  SVH = $(TR $(TH $1) $(TH $2))
 *  SV  = $(TR $(TD $1) $(TD $2))
 *
 *  NAN = $(RED NAN)
 *  SUP = <span style="vertical-align:super;font-size:smaller">$0</span>
 *  GAMMA =  &#915;
 *  INTEGRAL = &#8747;
 *  INTEGRATE = $(BIG &#8747;<sub>$(SMALL $1)</sub><sup>$2</sup>)
 *  POWER = $1<sup>$2</sup>
 *  BIGSUM = $(BIG &Sigma; <sup>$2</sup><sub>$(SMALL $1)</sub>)
 *  CHOOSE = $(BIG &#40;) <sup>$(SMALL $1)</sup><sub>$(SMALL $2)</sub> $(BIG &#41;)
 */

module tango.math.Elliptic;

import tango.math.Math;
import tango.math.IEEE;

/* These functions are based on code from:
Cephes Math Library, Release 2.3:  October, 1995
Copyright 1984, 1987, 1995 by Stephen L. Moshier
*/
 

/**
 *  Incomplete elliptic integral of the first kind
 *
 * Approximates the integral
 *   F(phi | m) = $(INTEGRATE 0, phi) dt/ (sqrt( 1- m $(POWER sin, 2) t))
 *
 * of amplitude phi and modulus m, using the arithmetic -
 * geometric mean algorithm.
 */

real ellipticF(real phi, real m )
{
    real a, b, c, e, temp, t, K;
    int d, mod, sign, npio2;

    if( m == 0.0L )
        return phi;
    a = 1.0L - m;
    if( a == 0.0L ) {
        if ( fabs(phi) >= PI_2 )  return real.infinity;
        return  log(  tan( 0.5L*(PI_2 + phi) )  );
    }
    npio2 = cast(int)floor( phi/PI_2 );
    if ( npio2 & 1 )
        npio2 += 1;
    if ( npio2 ) {
        K = ellipticKComplete( a );
        phi = phi - npio2 * PI_2;
    } else
        K = 0.0L;
    if( phi < 0.0L ){
        phi = -phi;
        sign = -1;
    } else
    sign = 0;
    b = sqrt(a);
    t = tan( phi );
    if( fabs(t) > 10.0L ) {
    /* Transform the amplitude */
    e = 1.0L/(b*t);
    /* ... but avoid multiple recursions.  */
    if( fabs(e) < 10.0L ){
        e = atan(e);
        if( npio2 == 0 )
            K = ellipticKComplete( a );
            temp = K - ellipticF( e, m );
            goto done;
        }
    }
    a = 1.0L;
    c = sqrt(m);
    d = 1;
    mod = 0;

    while( fabs(c/a) > real.epsilon ) {
        temp = b/a;
        phi = phi + atan(t*temp) + mod * PI;
        mod = cast(int)((phi + PI_2)/PI);
        t = t * ( 1.0L + temp )/( 1.0L - temp * t * t );
        c = 0.5L * ( a - b );
        temp = sqrt( a * b );
        a = 0.5L * ( a + b );
        b = temp;
        d += d;
    }
    temp = (atan(t) + mod * PI)/(d * a);

done:
    if ( sign < 0 )
        temp = -temp;
    temp += npio2 * K;
    return temp;
}


/**
 *  Incomplete elliptic integral of the second kind
 *
 * Approximates the integral
 *
 * E(phi | m) = $(INTEGRATE 0, phi) sqrt( 1- m $(POWER sin, 2) t) dt
 *
 * of amplitude phi and modulus m, using the arithmetic -
 * geometric mean algorithm.
 */

real ellipticE(real phi, real m )
{
    real a, b, c, e, temp, t, E;
    int d, mod, npio2, sign;

    if ( m == 0.0L ) return phi;
    real lphi = phi;
    npio2 = cast(int)floor( lphi/PI_2 );
    if( npio2 & 1 )
        npio2 += 1;
    lphi = lphi - npio2 * PI_2;
    if( lphi < 0.0L ){
        lphi = -lphi;
        sign = -1;
    } else  {
        sign = 1;
    }
    a = 1.0L - m;
    E = ellipticEComplete( a );
    if( a == 0.0L ) {
        temp = sin( lphi );
        goto done;
    }
    t = tan( lphi );
    b = sqrt(a);
    if ( fabs(t) > 10.0L ) {
        /* Transform the amplitude */
        e = 1.0L/(b*t);
        /* ... but avoid multiple recursions.  */
        if( fabs(e) < 10.0L ){
            e = atan(e);
            temp = E + m * sin( lphi ) * sin( e ) - ellipticE( e, m );
            goto done;
        }
    }
    c = sqrt(m);
    a = 1.0L;
    d = 1;
    e = 0.0L;
    mod = 0;

    while( fabs(c/a) > real.epsilon ) {
        temp = b/a;
        lphi = lphi + atan(t*temp) + mod * PI;
        mod = cast(int)((lphi + PI_2)/PI);
        t = t * ( 1.0L + temp )/( 1.0L - temp * t * t );
        c = 0.5L*( a - b );
        temp = sqrt( a * b );
        a = 0.5L*( a + b );
        b = temp;
        d += d;
        e += c * sin(lphi);
    }

    temp = E / ellipticKComplete( 1.0L - m );
    temp *= (atan(t) + mod * PI)/(d * a);
    temp += e;

done:
    if( sign < 0 )
        temp = -temp;
    temp += npio2 * E;
    return temp;
}


/**
 *  Complete elliptic integral of the first kind
 *
 * Approximates the integral
 *
 *   K(m) = $(INTEGRATE 0, &pi/2) dt/ (sqrt( 1- m $(POWER sin, 2) t))
 *
 * where m = 1 - x, using the approximation
 *
 *     P(x)  -  log x Q(x).
 *
 * The argument x is used rather than m so that the logarithmic
 * singularity at x = 1 will be shifted to the origin; this
 * preserves maximum accuracy. 
 *
 * x must be in the range
 *  0 <= x <= 1
 *
 * This is equivalent to ellipticF(PI_2, 1-x).
 *
 * K(0) = &pi/2.
 */

real ellipticKComplete(real x)
in {
//    assert(x>=0.0L && x<=1.0L);
}
body{

const real [] P = [
   0x1.62e42fefa39ef35ap+0, // 1.3862943611198906189
   0x1.8b90bfbe8ed811fcp-4, // 0.096573590279993142323
   0x1.fa05af797624c586p-6, // 0.030885144578720423267
   0x1.e979cdfac7249746p-7, // 0.01493761594388688915
   0x1.1f4cc8890cff803cp-7, // 0.0087676982094322259125
   0x1.7befb3bb1fa978acp-8, // 0.0057973684116620276454
   0x1.2c2566aa1d5fe6b8p-8, // 0.0045798659940508010431
   0x1.7333514e7fe57c98p-8, // 0.0056640695097481470287
   0x1.09292d1c8621348cp-7, // 0.0080920667906392630755
   0x1.b89ab5fe793a6062p-8, // 0.0067230886765842542487
   0x1.28e9c44dc5e26e66p-9, // 0.002265267575136470585
   0x1.c2c43245d445addap-13,    // 0.00021494216542320112406
   0x1.4ee247035a03e13p-20  // 1.2475397291548388385e-06
];

const real [] Q = [
   0x1p-1,  // 0.5
   0x1.fffffffffff635eap-4, // 0.12499999999999782631
   0x1.1fffffff8a2bea1p-4,  // 0.070312499993302227507
   0x1.8ffffe6f40ec2078p-5, // 0.04882812208418620146
   0x1.323f4dbf7f4d0c2ap-5, // 0.037383701182969303058
   0x1.efe8a028541b50bp-6,  // 0.030267864612427881354
   0x1.9d58c49718d6617cp-6, // 0.025228683455123323041
   0x1.4d1a8d2292ff6e2ep-6, // 0.020331037356569904872
   0x1.b637687027d664aap-7, // 0.013373304362459048444
   0x1.687a640ae5c71332p-8, // 0.0055004591221382442135
   0x1.0f9c30a94a1dcb4ep-10,    // 0.001036110372590318803
   0x1.d321746708e92d48p-15     // 5.568631677757315399e-05
];

    const real LOG4 = 0x1.62e42fefa39ef358p+0;  // log(4)

    if( x > real.epsilon )
        return poly(x,P) - log(x) * poly(x,Q);
    if ( x == 0.0L )
        return real.infinity;    
    return LOG4 - 0.5L * log(x);
}

/**
 *  Complete elliptic integral of the second kind
 *
 * Approximates the integral
 *
 * E(m) = $(INTEGRATE 0, &pi/2) sqrt( 1- m $(POWER sin, 2) t) dt
 *
 * Where m = 1 - m1, using the approximation
 *
 *      P(x)  -  x log x Q(x).
 *
 * Though there are no singularities, the argument m1 is used
 * rather than m for compatibility with ellipticKComplete().
 *
 * E(1) = 1; E(0) = &pi/2.
 * m must be in the range 0 <= m <= 1.
 */

real ellipticEComplete(real x)
in {
 assert(x>=0 && x<=1.0);
}
body {
const real [] P = [
   0x1.c5c85fdf473f78f2p-2, // 0.44314718055994670505
   0x1.d1591f9e9a66477p-5,  // 0.056805192715569305834
   0x1.65af6a7a61f587cp-6,  // 0.021831373198011179718
   0x1.7a4d48ed00d5745ap-7, // 0.011544857605264509506
   0x1.d4f5fe4f93b60688p-8, // 0.0071557756305783152481
   0x1.4cb71c73bac8656ap-8, // 0.0050768322432573952962
   0x1.4a9167859a1d0312p-8, // 0.0050440671671840438539
   0x1.dd296daa7b1f5b7ap-8, // 0.0072809117068399675418
   0x1.04f2c29224ba99b6p-7, // 0.0079635095646944542686
   0x1.0f5820e2d80194d8p-8, // 0.0041403847015715420009
   0x1.95ee634752ca69b6p-11,    // 0.00077425232385887751162
   0x1.0c58aa9ab404f4fp-15  // 3.1989378120323412946e-05
];

const real [] Q = [
   0x1.ffffffffffffb1cep-3, // 0.24999999999999986434
   0x1.7ffffffff29eaa0cp-4, // 0.093749999999239422678
   0x1.dfffffbd51eb098p-5,  // 0.058593749514839092674
   0x1.5dffd791cb834c92p-5, // 0.04272453406734691973
   0x1.1397b63c2f09a8ep-5,  // 0.033641677787700181541
   0x1.c567cde5931e75bcp-6, // 0.02767367465121309044
   0x1.75e0cae852be9ddcp-6, // 0.022819708015315777007
   0x1.12bb968236d4e434p-6, // 0.016768357258894633433
   0x1.1f6572c1c402d07cp-7, // 0.0087706384979640787504
   0x1.452c6909f88b8306p-9, // 0.0024808767529843311337
   0x1.1f7504e72d664054p-12,    // 0.00027414045912208516032
   0x1.ad17054dc46913e2p-18     // 6.3939381343012054851e-06
];
    if (x==0)
        return 1.0L;
    return 1.0L + x * poly(x,P) - log(x) * (x * poly(x,Q) );
}

unittest {
    assert( ellipticF(1, 0)==1);
    assert(ellipticEComplete(0)==1);
    assert(ellipticEComplete(1)==PI_2);
    assert(feqrel(ellipticKComplete(1),PI_2)>= real.mant_dig-1);
    assert(ellipticKComplete(0)==real.infinity);
//    assert(ellipticKComplete(1)==0); //-real.infinity);
    
    real x=0.5653L;
    assert(ellipticKComplete(1-x) == ellipticF(PI_2, x) );
    assert(ellipticEComplete(1-x) == ellipticE(PI_2, x) );
}
