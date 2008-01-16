/**
 * Cumulative Probability Distribution Functions
 *
 * Copyright: Based on the CEPHES math library, which is
 *            Copyright (C) 1994 Stephen L. Moshier (moshier@world.std.com).
 * License:   BSD style: $(LICENSE)
 * Authors:   Stephen L. Moshier (original C code), Don Clugston
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

module tango.math.Probability;
static import tango.math.ErrorFunction;
private import tango.math.GammaFunction;
private import tango.math.Math;
private import tango.math.IEEE;


/***
Cumulative distribution function for the Normal distribution, and its complement.

The normal (or Gaussian, or bell-shaped) distribution is
defined as:

normalDist(x) = 1/$(SQRT) &pi; $(INTEGRAL -$(INFINITY), x) exp( - $(POWER t, 2)/2) dt
    = 0.5 + 0.5 * erf(x/sqrt(2))
    = 0.5 * erfc(- x/sqrt(2))

Note that
normalDistribution(x) = 1 - normalDistribution(-x).

Accuracy:
Within a few bits of machine resolution over the entire
range.

References:
$(LINK http://www.netlib.org/cephes/ldoubdoc.html),
G. Marsaglia, "Evaluating the Normal Distribution",
Journal of Statistical Software <b>11</b>, (July 2004).
*/
real normalDistribution(real a)
{
    return tango.math.ErrorFunction.normalDistributionImpl(a);
}

/** ditto */
real normalDistributionCompl(real a)
{
    return -tango.math.ErrorFunction.normalDistributionImpl(-a);
}

/******************************
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
real normalDistributionInv(real p)
{
    return tango.math.ErrorFunction.normalDistributionInvImpl(p);
}

/** ditto */
real normalDistributionComplInv(real p)
{
    return -tango.math.ErrorFunction.normalDistributionInvImpl(-p);
}

debug(UnitTest) {
unittest {
    assert(feqrel(normalDistributionInv(normalDistribution(0.1)),0.1)>=real.mant_dig-4);
    assert(feqrel(normalDistributionComplInv(normalDistributionCompl(0.1)),0.1)>=real.mant_dig-4);
}
}

/** Student's t cumulative distribution function
 *
 * Computes the integral from minus infinity to t of the Student
 * t distribution with integer nu > 0 degrees of freedom:
 *
 *   $(GAMMA)( (nu+1)/2) / ( sqrt(nu &pi;) $(GAMMA)(nu/2) ) *
 * $(INTEGRATE -&infin;, t) $(POWER (1+$(POWER x, 2)/nu), -(nu+1)/2) dx
 *
 * Can be used to test whether the means of two normally distributed populations
 * are equal.
 *
 * It is related to the incomplete beta integral:
 *        1 - studentsDistribution(nu,t) = 0.5 * betaDistribution( nu/2, 1/2, z )
 * where
 *        z = nu/(nu + t<sup>2</sup>).
 *
 * For t < -1.6, this is the method of computation.  For higher t,
 * a direct method is derived from integration by parts.
 * Since the function is symmetric about t=0, the area under the
 * right tail of the density is found by calling the function
 * with -t instead of t.
 */
real studentsTDistribution(int nu, real t)
in{
   assert(nu>0);
}
body{
  /* Based on code from Cephes Math Library Release 2.3:  January, 1995
     Copyright 1984, 1995 by Stephen L. Moshier
 */

    if ( nu <= 0 ) return NaN(TANGO_NAN.STUDENTSDDISTRIBUTION_DOMAIN); // domain error -- or should it return 0?
    if ( t == 0.0 )  return 0.5;

    real rk, z, p;

    if ( t < -1.6 ) {
        rk = nu;
        z = rk / (rk + t * t);
        return 0.5L * betaIncomplete( 0.5L*rk, 0.5L, z );
    }

    /*  compute integral from -t to + t */

    rk = nu;    /* degrees of freedom */

    real x;
    if (t < 0) x = -t; else x = t;
    z = 1.0L + ( x * x )/rk;

    real f, tz;
    int j;

    if ( nu & 1)    {
        /*  computation for odd nu  */
        real xsqk = x/sqrt(rk);
        p = atan( xsqk );
        if ( nu > 1 )   {
            f = 1.0L;
            tz = 1.0L;
            j = 3;
            while(  (j<=(nu-2)) && ( (tz/f) > real.epsilon )  ) {
                tz *= (j-1)/( z * j );
                f += tz;
                j += 2;
            }
            p += f * xsqk/z;
            }
        p *= 2.0L/PI;
    } else {
        /*  computation for even nu */
        f = 1.0L;
        tz = 1.0L;
        j = 2;

        while ( ( j <= (nu-2) ) && ( (tz/f) > real.epsilon )  ) {
            tz *= (j - 1)/( z * j );
            f += tz;
            j += 2;
        }
        p = f * x/sqrt(z*rk);
    }
    if ( t < 0.0L )
        p = -p; /* note destruction of relative accuracy */

    p = 0.5L + 0.5L * p;
    return p;
}

/** Inverse of Student's t distribution
 *
 * Given probability p and degrees of freedom nu,
 * finds the argument t such that the one-sided
 * studentsDistribution(nu,t) is equal to p.
 *
 * Params:
 * nu = degrees of freedom. Must be >1
 * p  = probability. 0 < p < 1
 */
real studentsTDistributionInv(int nu, real p )
in {
   assert(nu>0);
   assert(p>=0.0L && p<=1.0L);
}
body
{
    if (p==0) return -real.infinity;
    if (p==1) return real.infinity;

    real rk, z;
    rk =  nu;

    if ( p > 0.25L && p < 0.75L ) {
        if ( p == 0.5L ) return 0;
        z = 1.0L - 2.0L * p;
        z = betaIncompleteInv( 0.5L, 0.5L*rk, fabs(z) );
        real t = sqrt( rk*z/(1.0L-z) );
        if( p < 0.5L )
            t = -t;
        return t;
    }
    int rflg = -1; // sign of the result
    if (p >= 0.5L) {
        p = 1.0L - p;
        rflg = 1;
    }
    z = betaIncompleteInv( 0.5L*rk, 0.5L, 2.0L*p );

    if (z<0) return rflg * real.infinity;
    return rflg * sqrt( rk/z - rk );
}

debug(UnitTest) {
unittest {

// There are simple forms for nu = 1 and nu = 2.

// if (nu == 1), tDistribution(x) = 0.5 + atan(x)/PI
//              so tDistributionInv(p) = tan( PI * (p-0.5) );
// nu==2: tDistribution(x) = 0.5 * (1 + x/ sqrt(2+x*x) )

assert(studentsTDistribution(1, -0.4)== 0.5 + atan(-0.4)/PI);
assert(studentsTDistribution(2, 0.9) == 0.5L * (1 + 0.9L/sqrt(2.0L + 0.9*0.9)) );
assert(studentsTDistribution(2, -5.4) == 0.5L * (1 - 5.4L/sqrt(2.0L + 5.4*5.4)) );

// return true if a==b to given number of places.
bool isfeqabs(real a, real b, real diff)
{
  return fabs(a-b) < diff;
}

// Check a few spot values with statsoft.com (Mathworld values are wrong!!)
// According to statsoft.com, studentsDistributionInv(10, 0.995)= 3.16927.

// The remaining values listed here are from Excel, and are unlikely to be accurate
// in the last decimal places. However, they are helpful as a sanity check.

//  Microsoft Excel 2003 gives TINV(2*(1-0.995), 10) == 3.16927267160917
assert(isfeqabs(studentsTDistributionInv(10, 0.995), 3.169_272_67L, 0.000_000_005L));


assert(isfeqabs(studentsTDistributionInv(8, 0.6), 0.261_921_096_769_043L,0.000_000_000_05L));
// -TINV(2*0.4, 18) ==  -0.257123042655869

assert(isfeqabs(studentsTDistributionInv(18, 0.4), -0.257_123_042_655_869L, 0.000_000_000_05L));
assert( feqrel(studentsTDistribution(18, studentsTDistributionInv(18, 0.4L)),0.4L)
 > real.mant_dig-2 );
assert( feqrel(studentsTDistribution(11, studentsTDistributionInv(11, 0.9L)),0.9L)
  > real.mant_dig-2);
}
}

/** The F distribution, its complement, and inverse.
 *
 * The F density function (also known as Snedcor's density or the
 * variance ratio density) is the density
 * of x = (u1/df1)/(u2/df2), where u1 and u2 are random
 * variables having $(POWER &chi;,2) distributions with df1
 * and df2 degrees of freedom, respectively.
 *
 * fDistribution returns the area from zero to x under the F density
 * function.   The complementary function,
 * fDistributionCompl, returns the area from x to &infin; under the F density function.
 *
 * The inverse of the complemented F distribution,
 * fDistributionComplInv, finds the argument x such that the integral
 * from x to infinity of the F density is equal to the given probability y.
 *
 * Can be used to test whether the means of multiple normally distributed
 * populations, all with the same standard deviation, are equal;
 * or to test that the standard deviations of two normally distributed
 * populations are equal.
 *
 * Params:
 *  df1 = Degrees of freedom of the first variable. Must be >= 1
 *  df2 = Degrees of freedom of the second variable. Must be >= 1
 *  x  = Must be >= 0
 */
real fDistribution(int df1, int df2, real x)
in {
 assert(df1>=1 && df2>=1);
 assert(x>=0);
}
body{
    real a = cast(real)(df1);
    real b = cast(real)(df2);
    real w = a * x;
    w = w/(b + w);
    return betaIncomplete(0.5L*a, 0.5L*b, w);
}

/** ditto */
real fDistributionCompl(int df1, int df2, real x)
in {
 assert(df1>=1 && df2>=1);
 assert(x>=0);
}
body{
    real a = cast(real)(df1);
    real b = cast(real)(df2);
    real w = b / (b + a * x);
    return betaIncomplete( 0.5L*b, 0.5L*a, w );
}

/*
 * Inverse of complemented F distribution
 *
 * Finds the F density argument x such that the integral
 * from x to infinity of the F density is equal to the
 * given probability p.
 *
 * This is accomplished using the inverse beta integral
 * function and the relations
 *
 *      z = betaIncompleteInv( df2/2, df1/2, p ),
 *      x = df2 (1-z) / (df1 z).
 *
 * Note that the following relations hold for the inverse of
 * the uncomplemented F distribution:
 *
 *      z = betaIncompleteInv( df1/2, df2/2, p ),
 *      x = df2 z / (df1 (1-z)).
*/

/** ditto */
real fDistributionComplInv(int df1, int df2, real p )
in {
 assert(df1>=1 && df2>=1);
 assert(p>=0 && p<=1.0);
}
body{
    real a = df1;
    real b = df2;
    /* Compute probability for x = 0.5.  */
    real w = betaIncomplete( 0.5L*b, 0.5L*a, 0.5L );
    /* If that is greater than p, then the solution w < .5.
       Otherwise, solve at 1-p to remove cancellation in (b - b*w).  */
    if ( w > p || p < 0.001L) {
        w = betaIncompleteInv( 0.5L*b, 0.5L*a, p );
        return (b - b*w)/(a*w);
    } else {
        w = betaIncompleteInv( 0.5L*a, 0.5L*b, 1.0L - p );
        return b*w/(a*(1.0L-w));
    }
}

debug(UnitTest) {
unittest {
// fDistCompl(df1, df2, x) = Excel's FDIST(x, df1, df2)
  assert(fabs(fDistributionCompl(6, 4, 16.5) - 0.00858719177897249L)< 0.0000000000005L);
  assert(fabs((1-fDistribution(12, 23, 0.1)) - 0.99990562845505L)< 0.0000000000005L);
  assert(fabs(fDistributionComplInv(8, 34, 0.2) - 1.48267037661408L)< 0.0000000005L);
  assert(fabs(fDistributionComplInv(4, 16, 0.008) - 5.043_537_593_48596L)< 0.0000000005L);
  // Regression test: This one used to fail because of a bug in the definition of MINLOG.
  assert(feqrel(fDistributionCompl(4, 16, fDistributionComplInv(4,16, 0.008)), 0.008)>=real.mant_dig-3);
}
}

/** $(POWER &chi;,2) cumulative distribution function and its complement.
 *
 * Returns the area under the left hand tail (from 0 to x)
 * of the Chi square probability density function with
 * v degrees of freedom. The complement returns the area under
 * the right hand tail (from x to &infin;).
 *
 *  chiSqrDistribution(x | v) = ($(INTEGRATE 0, x)
 *          $(POWER t, v/2-1) $(POWER e, -t/2) dt )
 *             / $(POWER 2, v/2) $(GAMMA)(v/2)
 *
 *  chiSqrDistributionCompl(x | v) = ($(INTEGRATE x, &infin;)
 *          $(POWER t, v/2-1) $(POWER e, -t/2) dt )
 *             / $(POWER 2, v/2) $(GAMMA)(v/2)
 *
 * Params:
 *  v  = degrees of freedom. Must be positive.
 *  x  = the $(POWER &chi;,2) variable. Must be positive.
 *
 */
real chiSqrDistribution(real v, real x)
in {
 assert(x>=0);
 assert(v>=1.0);
}
body{
   return gammaIncomplete( 0.5*v, 0.5*x);
}

/** ditto */
real chiSqrDistributionCompl(real v, real x)
in {
 assert(x>=0);
 assert(v>=1.0);
}
body{
    return gammaIncompleteCompl( 0.5L*v, 0.5L*x );
}

/**
 *  Inverse of complemented $(POWER &chi;, 2) distribution
 *
 * Finds the $(POWER &chi;, 2) argument x such that the integral
 * from x to &infin; of the $(POWER &chi;, 2) density is equal
 * to the given cumulative probability p.
 *
 * Params:
 * p = Cumulative probability. 0<= p <=1.
 * v = Degrees of freedom. Must be positive.
 *
 */
real chiSqrDistributionComplInv(real v, real p)
in {
  assert(p>=0 && p<=1.0L);
  assert(v>=1.0L);
}
body
{
   return  2.0 * gammaIncompleteComplInv( 0.5*v, p);
}

debug(UnitTest) {
unittest {
  assert(feqrel(chiSqrDistributionCompl(3.5L, chiSqrDistributionComplInv(3.5L, 0.1L)), 0.1L)>=real.mant_dig-3);
  assert(chiSqrDistribution(19.02L, 0.4L) + chiSqrDistributionCompl(19.02L, 0.4L) ==1.0L);
}
}

/**
 * The &Gamma; distribution and its complement
 *
 * The &Gamma; distribution is defined as the integral from 0 to x of the
 * gamma probability density function. The complementary function returns the
 * integral from x to &infin;
 *
 * gammaDistribution = ($(INTEGRATE 0, x) $(POWER t, b-1)$(POWER e, -at) dt) $(POWER a, b)/&Gamma;(b)
 *
 * x must be greater than 0.
 */
real gammaDistribution(real a, real b, real x)
in {
   assert(x>=0);
}
body {
   return gammaIncomplete(b, a*x);
}

/** ditto */
real gammaDistributionCompl(real a, real b, real x )
in {
   assert(x>=0);
}
body {
   return gammaIncompleteCompl( b, a * x );
}

debug(UnitTest) {
unittest {
    assert(gammaDistribution(7,3,0.18)+gammaDistributionCompl(7,3,0.18)==1);
}
}

/**********************
 *  Beta distribution and its inverse
 *
 * Returns the incomplete beta integral of the arguments, evaluated
 * from zero to x.  The function is defined as
 *
 * betaDistribution = &Gamma;(a+b)/(&Gamma;(a) &Gamma;(b)) *
 * $(INTEGRATE 0, x) $(POWER t, a-1)$(POWER (1-t),b-1) dt
 *
 * The domain of definition is 0 <= x <= 1.  In this
 * implementation a and b are restricted to positive values.
 * The integral from x to 1 may be obtained by the symmetry
 * relation
 *
 *    betaDistributionCompl(a, b, x )  =  betaDistribution( b, a, 1-x )
 *
 * The integral is evaluated by a continued fraction expansion
 * or, when b*x is small, by a power series.
 *
 * The inverse finds the value of x for which betaDistribution(a,b,x) - y = 0
 */
real betaDistribution(real a, real b, real x )
{
   return betaIncomplete(a, b, x );
}

/** ditto */
real betaDistributionCompl(real a, real b, real x)
{
    return betaIncomplete(b, a, 1-x);
}

/** ditto */
real betaDistributionInv(real a, real b, real y)
{
    return betaIncompleteInv(a, b, y);
}

/** ditto */
real betaDistributionComplInv(real a, real b, real y)
{
    return 1-betaIncompleteInv(b, a, y);
}

debug(UnitTest) {
unittest {
    assert(feqrel(betaDistributionInv(2, 6, betaDistribution(2,6, 0.7L)),0.7L)>=real.mant_dig-3);
    assert(feqrel(betaDistributionComplInv(1.3, 8, betaDistributionCompl(1.3,8, 0.01L)),0.01L)>=real.mant_dig-4);
}
}

/**
 * The Poisson distribution, its complement, and inverse
 *
 * k is the number of events. m is the mean.
 * The Poisson distribution is defined as the sum of the first k terms of
 * the Poisson density function.
 * The complement returns the sum of the terms k+1 to &infin;.
 *
 * poissonDistribution = $(BIGSUM j=0, k) $(POWER e, -m) $(POWER m, j)/j!
 *
 * poissonDistributionCompl = $(BIGSUM j=k+1, &infin;) $(POWER e, -m) $(POWER m, j)/j!
 *
 * The terms are not summed directly; instead the incomplete
 * gamma integral is employed, according to the relation
 *
 * y = poissonDistribution( k, m ) = gammaIncompleteCompl( k+1, m ).
 *
 * The arguments must both be positive.
 */
real poissonDistribution(int k, real m )
in {
  assert(k>=0);
  assert(m>0);
}
body {
    return gammaIncompleteCompl( k+1.0, m );
}

/** ditto */
real poissonDistributionCompl(int k, real m )
in {
  assert(k>=0);
  assert(m>0);
}
body {
  return gammaIncomplete( k+1.0, m );
}

/** ditto */
real poissonDistributionInv( int k, real p )
in {
  assert(k>=0);
  assert(p>=0.0 && p<=1.0);
}
body {
    return gammaIncompleteComplInv(k+1, p);
}

debug(UnitTest) {
unittest {
// = Excel's POISSON(k, m, TRUE)
    assert( fabs(poissonDistribution(5, 6.3)
                - 0.398771730072867L) < 0.000000000000005L);
    assert( feqrel(poissonDistributionInv(8, poissonDistribution(8, 2.7e3L)), 2.7e3L)>=real.mant_dig-2);
    assert( poissonDistribution(2, 8.4e-5) + poissonDistributionCompl(2, 8.4e-5) == 1.0L);
}
}

/***********************************
 *  Binomial distribution and complemented binomial distribution
 *
 * The binomial distribution is defined as the sum of the terms 0 through k
 * of the Binomial probability density.
 * The complement returns the sum of the terms k+1 through n.
 *
 binomialDistribution = $(BIGSUM j=0, k) $(CHOOSE n, j) $(POWER p, j) $(POWER (1-p), n-j)

 binomialDistributionCompl = $(BIGSUM j=k+1, n) $(CHOOSE n, j) $(POWER p, j) $(POWER (1-p), n-j)
 *
 * The terms are not summed directly; instead the incomplete
 * beta integral is employed, according to the formula
 *
 * y = binomialDistribution( k, n, p ) = betaDistribution( n-k, k+1, 1-p ).
 *
 * The arguments must be positive, with p ranging from 0 to 1, and k<=n.
 */
real binomialDistribution(int k, int n, real p )
in {
   assert(p>=0 && p<=1.0); // domain error
   assert(k>=0 && k<=n);
}
body{
    real dk, dn, q;
    if( k == n )
        return 1.0L;

    q = 1.0L - p;
    dn = n - k;
    if ( k == 0 ) {
        return pow( q, dn );
    } else {
        return betaIncomplete( dn, k + 1, q );
    }
}

debug(UnitTest) {
unittest {
    // = Excel's BINOMDIST(k, n, p, TRUE)
    assert( fabs(binomialDistribution(8, 12, 0.5)
                - 0.927001953125L) < 0.0000000000005L);
    assert( fabs(binomialDistribution(0, 3, 0.008L)
                - 0.976191488L) < 0.00000000005L);
    assert(binomialDistribution(7,7, 0.3)==1.0);
}
}

 /** ditto */
real binomialDistributionCompl(int k, int n, real p )
in {
   assert(p>=0 && p<=1.0); // domain error
   assert(k>=0 && k<=n);
}
body{
    if ( k == n ) {
        return 0;
    }
    real dn = n - k;
    if ( k == 0 ) {
        if ( p < .01L )
            return -expm1( dn * log1p(-p) );
        else
            return 1.0L - pow( 1.0L-p, dn );
    } else {
        return betaIncomplete( k+1, dn, p );
    }
}

debug(UnitTest){
unittest {
    // = Excel's (1 - BINOMDIST(k, n, p, TRUE))
    assert( fabs(1.0L-binomialDistributionCompl(0, 15, 0.003)
                - 0.955932824838906L) < 0.0000000000000005L);
    assert( fabs(1.0L-binomialDistributionCompl(0, 25, 0.2)
                - 0.00377789318629572L) < 0.000000000000000005L);
    assert( fabs(1.0L-binomialDistributionCompl(8, 12, 0.5)
                - 0.927001953125L) < 0.00000000000005L);
    assert(binomialDistributionCompl(7,7, 0.3)==0.0);
}
}

/** Inverse binomial distribution
 *
 * Finds the event probability p such that the sum of the
 * terms 0 through k of the Binomial probability density
 * is equal to the given cumulative probability y.
 *
 * This is accomplished using the inverse beta integral
 * function and the relation
 *
 * 1 - p = betaDistributionInv( n-k, k+1, y ).
 *
 * The arguments must be positive, with 0 <= y <= 1, and k <= n.
 */
real binomialDistributionInv( int k, int n, real y )
in {
   assert(y>=0 && y<=1.0); // domain error
   assert(k>=0 && k<=n);
}
body{
    real dk, p;
    real dn = n - k;
    if ( k == 0 ) {
        if( y > 0.8L )
            p = -expm1( log1p(y-1.0L) / dn );
        else
            p = 1.0L - pow( y, 1.0L/dn );
    } else {
        dk = k + 1;
        p = betaIncomplete( dn, dk, y );
        if( p > 0.5 )
            p = betaIncompleteInv( dk, dn, 1.0L-y );
        else
            p = 1.0 - betaIncompleteInv( dn, dk, y );
    }
    return p;
}

debug(UnitTest){
unittest {
    real w = binomialDistribution(9, 15, 0.318L);
    assert(feqrel(binomialDistributionInv(9, 15, w), 0.318L)>=real.mant_dig-3);
    w = binomialDistribution(5, 35, 0.718L);
    assert(feqrel(binomialDistributionInv(5, 35, w), 0.718L)>=real.mant_dig-3);
    w = binomialDistribution(0, 24, 0.637L);
    assert(feqrel(binomialDistributionInv(0, 24, w), 0.637L)>=real.mant_dig-3);
    w = binomialDistributionInv(0, 59, 0.962L);
    assert(feqrel(binomialDistribution(0, 59, w), 0.962L)>=real.mant_dig-5);
}
}

/** Negative binomial distribution and its inverse
 *
 * Returns the sum of the terms 0 through k of the negative
 * binomial distribution:
 *
 * $(BIGSUM j=0, k) $(CHOOSE n+j-1, j-1) $(POWER p, n) $(POWER (1-p), j)
 *
 * In a sequence of Bernoulli trials, this is the probability
 * that k or fewer failures precede the n-th success.
 *
 * The arguments must be positive, with 0 < p < 1 and r>0.
 *
 * The inverse finds the argument y such
 * that negativeBinomialDistribution(k,n,y) is equal to p.
 *
 * The Geometric Distribution is a special case of the negative binomial
 * distribution.
 * -----------------------
 * geometricDistribution(k, p) = negativeBinomialDistribution(k, 1, p);
 * -----------------------
 * References:
 * $(LINK http://mathworld.wolfram.com/NegativeBinomialDistribution.html)
 */

real negativeBinomialDistribution(int k, int n, real p )
in {
   assert(p>=0 && p<=1.0); // domain error
   assert(k>=0);
}
body{
    if ( k == 0 ) return pow( p, n );
    return betaIncomplete( n, k + 1, p );
}

/** ditto */
real negativeBinomialDistributionInv(int k, int n, real p )
in {
   assert(p>=0 && p<=1.0); // domain error
   assert(k>=0);
}
body{
    return betaIncompleteInv(n, k + 1, p);
}

debug(UnitTest) {
unittest {
  // Value obtained by sum of terms of MS Excel 2003's NEGBINOMDIST.
  assert( fabs(negativeBinomialDistribution(10, 20, 0.2) - 3.830_52E-08)< 0.000_005e-08);
  assert(feqrel(negativeBinomialDistributionInv(14, 208, negativeBinomialDistribution(14, 208, 1e-4L)), 1e-4L)>=real.mant_dig-3);
}
}