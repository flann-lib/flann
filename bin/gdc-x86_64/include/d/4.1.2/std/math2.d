
/* This module is obsolete and will be removed eventually */

/*
 * Copyright (c) 2002
 * Pavel "EvilOne" Minayev
 *
 * Permission to use, copy, modify, distribute and sell this software
 * and its documentation for any purpose is hereby granted without fee,
 * provided that the above copyright notice appear in all copies and
 * that both that copyright notice and this permission notice appear
 * in supporting documentation.  Author makes no representations about
 * the suitability of this software for any purpose. It is provided
 * "as is" without express or implied warranty.
 */

/* NOTE: This file has been patched from the original DMD distribution to
   work with the GDC compiler.

   Modified by David Friedman, September 2007
*/
 
module std.math2;
private import std.math, std.string, std.c.stdlib, std.c.stdio;
version(GNU)
    static import std.c.math;

//debug=math2;

/****************************************
 * compare floats with given precision
 */

bool feq(real a, real b)
{
	return feq(a, b, 0.000001);
} 
 
bool feq(real a, real b, real eps)
{
	return abs(a - b) <= eps;
}

/*********************************
 * Modulus
 */
 
int abs(int n)
{
	return n > 0 ? n : -n;
}
 
long abs(long n)
{
	return n > 0 ? n : -n;
}

real abs(real n)
{
	// just let the compiler handle it
	return std.math.fabs(n);
}

/*********************************
 * Square
 */

int sqr(int n)
{
	return n * n;
}
 
long sqr(long n)
{
	return n * n;
} 
 
real sqr(real n)
{
	return n * n;
}

unittest
{
	assert(sqr(sqr(3)) == 81);
}

private ushort fp_cw_chop = 7999;

/*********************************
 * Integer part
 */
 
version (GNU)
{
    version (GNU_Need_trunc) {
	real trunc(real n) {
	    return n >= 0 ? std.math.floor(n) : std.math.ceil(n);
	}
    } else {
	alias std.c.math.truncl trunc;
    }
}
else
{
    real trunc(real n)
    {
	    ushort cw;
	    asm
	    {
		    fstcw cw;
		    fldcw fp_cw_chop;
		    fld n;
		    frndint;
		    fldcw cw;
	    }	
    }
}

unittest
{
	assert(feq(trunc(+123.456), +123.0L));
	assert(feq(trunc(-123.456), -123.0L));
}

/*********************************
 * Fractional part
 */
 
real frac(real n)
{
	return n - trunc(n);
}

unittest
{
	assert(feq(frac(+123.456), +0.456L));
	assert(feq(frac(-123.456), -0.456L));
}

/*********************************
 * Sign
 */

int sign(int n)
{
	return (n > 0 ? +1 : (n < 0 ? -1 : 0));
}

unittest
{
	assert(sign(0) == 0);
	assert(sign(+666) == +1);
	assert(sign(-666) == -1);
}
 
int sign(long n)
{
	return (n > 0 ? +1 : (n < 0 ? -1 : 0));
}

unittest
{
	assert(sign(0) == 0);
	assert(sign(+666L) == +1);
	assert(sign(-666L) == -1);
}
 
int sign(real n)
{
	return (n > 0 ? +1 : (n < 0 ? -1 : 0));
}

unittest
{
	assert(sign(0.0L) == 0);
	assert(sign(+123.456L) == +1);
	assert(sign(-123.456L) == -1);
}

/**********************************************************
 * Cycles <-> radians <-> grads <-> degrees conversions
 */
 
real cycle2deg(real c)
{
	return c * 360;
}

real cycle2rad(real c)
{
	return c * PI * 2;
}

real cycle2grad(real c)
{
	return c * 400;
}

real deg2cycle(real d)
{
	return d / 360;
}

real deg2rad(real d)
{
	return d / 180 * PI;
}

real deg2grad(real d)
{
	return d / 90 * 100;
}

real rad2deg(real r)
{
	return r / PI * 180;
}

real rad2cycle(real r)
{
	return r / (PI * 2);
}

real rad2grad(real r)
{
	return r / PI * 200;
}

real grad2deg(real g)
{
	return g / 100 * 90;
}

real grad2cycle(real g)
{
	return g / 400;
}

real grad2rad(real g)
{
	return g / 200 * PI;
}

unittest
{
	assert(feq(cycle2deg(0.5), 180));
	assert(feq(cycle2rad(0.5), PI));
	assert(feq(cycle2grad(0.5), 200));
	assert(feq(deg2cycle(180), 0.5));
	assert(feq(deg2rad(180), PI));
	assert(feq(deg2grad(180), 200));
	assert(feq(rad2deg(PI), 180));
	assert(feq(rad2cycle(PI), 0.5));
	assert(feq(rad2grad(PI), 200));
	assert(feq(grad2deg(200), 180));
	assert(feq(grad2cycle(200), 0.5));
	assert(feq(grad2rad(200), PI));
}

/************************************
 * Arithmetic average of values
 */
 
real avg(real[] n)
{
	real result = 0;
	for (size_t i = 0; i < n.length; i++)
		result += n[i];
	return result / n.length;
}

unittest
{
	static real[4] n = [ 1, 2, 4, 5 ];
	assert(feq(avg(n), 3));
}

/*************************************
 * Sum of values
 */

int sum(int[] n)
{
	long result = 0;
	for (size_t i = 0; i < n.length; i++)
	    result += n[i];
	return cast(int)result;
}

unittest
{
	static int[3] n = [ 1, 2, 3 ];
	assert(sum(n) == 6);
}
 
long sum(long[] n)
{
	long result = 0;
	for (size_t i = 0; i < n.length; i++)
		result += n[i];
	return result;
}

unittest
{
	static long[3] n = [ 1, 2, 3 ];
	assert(sum(n) == 6);
}
 
real sum(real[] n)
{
	real result = 0;
	for (size_t i = 0; i < n.length; i++)
		result += n[i];
	return result;
}

unittest
{
	static real[3] n = [ 1, 2, 3 ];
	assert(feq(sum(n), 6));
}

/*************************************
 * The smallest value
 */

int min(int[] n)
{
	int result = int.max;
	for (size_t i = 0; i < n.length; i++)
		if (n[i] < result)
			result = n[i];
	return result;
}

unittest
{
	static int[3] n = [ 2, -1, 0 ];
	assert(min(n) == -1);
}
 
long min(long[] n)
{
	long result = long.max;
	for (size_t i = 0; i < n.length; i++)
		if (n[i] < result)
			result = n[i];
	return result;
}

unittest
{
	static long[3] n = [ 2, -1, 0 ];
	assert(min(n) == -1);
}

real min(real[] n)
{
	real result = real.max;
	for (size_t i = 0; i < n.length; i++)
	{
		if (n[i] < result)
			result = n[i];
	}
	return result;
}

unittest
{
	static real[3] n = [ 2.0, -1.0, 0.0 ];
	assert(feq(min(n), -1));
}

int min(int a, int b)
{
	return a < b ? a : b;
}

unittest
{
	assert(min(1, 2) == 1);
}

long min(long a, long b)
{
	return a < b ? a : b;
}

unittest
{
	assert(min(1L, 2L) == 1);
}

real min(real a, real b)
{
	return a < b ? a : b;
}

unittest
{
	assert(feq(min(1.0L, 2.0L), 1.0L));
}

/*************************************
 * The largest value
 */

int max(int[] n)
{
	int result = int.min;
	for (size_t i = 0; i < n.length; i++)
		if (n[i] > result)
			result = n[i];
	return result;
}

unittest
{
	static int[3] n = [ 0, 2, -1 ];
	assert(max(n) == 2);
}
 
long max(long[] n)
{
	long result = long.min;
	for (size_t i = 0; i < n.length; i++)
		if (n[i] > result)
			result = n[i];
	return result;
}

unittest
{
	static long[3] n = [ 0, 2, -1 ];
	assert(max(n) == 2);
}

real max(real[] n)
{
	real result = real.min;
	for (size_t i = 0; i < n.length; i++)
		if (n[i] > result)
			result = n[i];
	return result;
}

unittest
{
	static real[3] n = [ 0.0, 2.0, -1.0 ];
	assert(feq(max(n), 2));
}

int max(int a, int b)
{
	return a > b ? a : b;
}

unittest
{
	assert(max(1, 2) == 2);
}

long max(long a, long b)
{
	return a > b ? a : b;
}

unittest
{
	assert(max(1L, 2L) == 2);
}

real max(real a, real b)
{
	return a > b ? a : b;
}

unittest
{
	assert(feq(max(1.0L, 2.0L), 2.0L));
}

/*************************************
 * Arccotangent
 */

real acot(real x)
{
	return std.math.tan(1.0 / x);
}

unittest
{
	assert(feq(acot(cot(0.000001)), 0.000001));
}

/*************************************
 * Arcsecant
 */

real asec(real x)
{
	return std.math.cos(1.0 / x);
}


/*************************************
 * Arccosecant
 */

real acosec(real x)
{
	return std.math.sin(1.0 / x);
}

/*************************************
 * Tangent
 */

/+
real tan(real x)
{
	asm
	{
		fld x;
		fptan;
		fstp ST(0);
		fwait;
	}
}

unittest
{
	assert(feq(tan(PI / 3), std.math.sqrt(3)));
}
+/

/*************************************
 * Cotangent
 */

real cot(real x)
{
    version(GNU) {
	// %% is the asm below missing fld1?
	return 1/std.c.math.tanl(x);
    } else {
	asm
	{
		fld x;
		fptan;
		fdivrp;
		fwait;
	}
    }
}

unittest
{
	assert(feq(cot(PI / 6), std.math.sqrt(3.0L)));
}

/*************************************
 * Secant
 */

real sec(real x)
{
    version(GNU) {
	return 1/std.c.math.cosl(x);
    } else {
	asm
	{
		fld x;
		fcos;
		fld1;
		fdivrp;
		fwait;
	}
    }
}


/*************************************
 * Cosecant
 */

real cosec(real x)
{
    version(GNU) {
	// %% is the asm below missing fld1?
	return 1/std.c.math.sinl(x);
    } else {
	asm
	{
		fld x;
		fsin;
		fld1;
		fdivrp;
		fwait;
	}
    }
}

/*********************************************
 * Extract mantissa and exponent from float
 */

/+
real frexp(real x, out int exponent)
{
    version (GNU) {
	return std.c.math.frexpl(x, & exponent);
    } else {
	asm
	{
		fld x;
		mov EDX, exponent;
		mov dword ptr [EDX], 0;
		ftst;
		fstsw AX;
		fwait;
		sahf;
		jz done;
		fxtract;
		fxch;	
		fistp dword ptr [EDX];
		fld1;
		fchs;
		fxch;
		fscale;
		inc dword ptr [EDX];
		fstp ST(1);
done:
		fwait;
	}
    }
}

unittest
{
	int exponent;
	real mantissa = frexp(123.456, exponent);
	assert(feq(mantissa * std.math.pow(2.0L, cast(real)exponent), 123.456));
}
+/

/*************************************
 * Hyperbolic cotangent
 */

real coth(real x)
{
	return 1 / std.math.tanh(x);
}

unittest
{
    real r1 = coth(1);
    real r2 = std.math.sinh(1);
    real r3 = std.math.tanh(1);
    real r4 = coth(1);
    printf("%0.5Lg   %0.5Lg   %0.5Lg   %0.5Lg\n", r1, r2, r3, r4);
    printf("%0.5g   %0.5g   %0.5g   %0.5g\n",
	coth(1), std.math.sinh(1), std.math.tanh(1), coth(1));
    assert(feq(coth(1), std.math.cosh(1) / std.math.sinh(1)));
}

/*************************************
 * Hyperbolic secant
 */

real sech(real x)
{
	return 1 / std.math.cosh(x);
}

/*************************************
 * Hyperbolic cosecant
 */

real cosech(real x)
{
	return 1 / std.math.sinh(x);
}

/*************************************
 * Hyperbolic arccosine
 */

/+
real acosh(real x)
{
	if (x <= 1)
		return 0;
	else if (x > 1.0e10)
		return log(2) + log(x);
	else
		return log(x + std.math.sqrt((x - 1) * (x + 1)));
}

unittest
{
	assert(acosh(0.5) == 0);
	assert(feq(acosh(std.math.cosh(3)), 3));
}
+/

/*************************************
 * Hyperbolic arcsine
 */

/+
real asinh(real x)
{
	if (!x)
		return 0;
	else if (x > 1.0e10)
		return log(2) + log(1.0e10);
	else if (x < -1.0e10)
		return -log(2) - log(1.0e10);
	else
	{
		real z = x * x;
		return x > 0 ? 
			std.math.log1p(x + z / (1.0 + std.math.sqrt(1.0 + z))) :
			-std.math.log1p(-x + z / (1.0 + std.math.sqrt(1.0 + z)));
	}
}

unittest
{
	assert(asinh(0) == 0);
	assert(feq(asinh(std.math.sinh(3)), 3));
}
+/

/*************************************
 * Hyperbolic arctangent
 */
/+
real atanh(real x)
{
	if (!x)
		return 0;
	else
	{
		if (x >= 1)
			return real.max;
		else if (x <= -1)
			return -real.max;
		else
			return x > 0 ?
				0.5 * std.math.log1p((2.0 * x) / (1.0 - x)) :
				-0.5 * std.math.log1p((-2.0 * x) / (1.0 + x));
	}
}

unittest
{
	assert(atanh(0) == 0);
	assert(feq(atanh(std.math.tanh(0.5)), 0.5));
}
+/

/*************************************
 * Hyperbolic arccotangent
 */

real acoth(real x)
{
	return 1 / acot(x);
}

unittest
{
	assert(feq(acoth(coth(0.01)), 100));
}

/*************************************
 * Hyperbolic arcsecant
 */

real asech(real x)
{
	return 1 / asec(x);
}

/*************************************
 * Hyperbolic arccosecant
 */

real acosech(real x)
{
	return 1 / acosec(x);
}

/*************************************
 * Convert string to float
 */

real atof(char[] s)
{
	if (!s.length)
		return real.nan;
	real result = 0;
	size_t i = 0;
	while (s[i] == '\t' || s[i] == ' ')
		if (++i >= s.length)
			return real.nan;
	bool neg = false;
	if (s[i] == '-')
	{
		neg = true;
		i++;
	}
	else if (s[i] == '+')
		i++;
	if (i >= s.length)
		return real.nan;
	bool hex;
	if (s[s.length - 1] == 'h')
	{
		hex = true;
		s.length = s.length - 1;
	}
	else if (i + 1 < s.length && s[i] == '0' && s[i+1] == 'x')
	{
		hex = true;
		i += 2;
		if (i >= s.length)
			return real.nan;
	}
	else
		hex = false;
	while (s[i] != '.')
	{
		if (hex)
		{
			if ((s[i] == 'p' || s[i] == 'P'))
				break;
			result *= 0x10;
		}
		else
		{
			if ((s[i] == 'e' || s[i] == 'E'))
				break;
			result *= 10;
		}
		if (s[i] >= '0' && s[i] <= '9')
			result += s[i] - '0';
		else if (hex)
		{
			if (s[i] >= 'a' && s[i] <= 'f')
				result += s[i] - 'a' + 10;
			else if (s[i] >= 'A' && s[i] <= 'F')
				result += s[i] - 'A' + 10;
			else
				return real.nan;
		}
		else
			return real.nan;
		if (++i >= s.length)
			goto done;
	}
	if (s[i] == '.')
	{
		if (++i >= s.length)
			goto done;
		ulong k = 1;
		while (true)
		{
			if (hex)
			{
				if ((s[i] == 'p' || s[i] == 'P'))
					break;
				result *= 0x10;
			}
			else
			{
				if ((s[i] == 'e' || s[i] == 'E'))
					break;
				result *= 10;
			}
			k *= (hex ? 0x10 : 10);
			if (s[i] >= '0' && s[i] <= '9')
				result += s[i] - '0';
			else if (hex)
			{
				if (s[i] >= 'a' && s[i] <= 'f')
					result += s[i] - 'a' + 10;
				else if (s[i] >= 'A' && s[i] <= 'F')
					result += s[i] - 'A' + 10;
				else
					return real.nan;
			}
			else
				return real.nan;
			if (++i >= s.length)
			{
				result /= k;
				goto done;
			}
		}
		result /= k;
	}
	if (++i >= s.length)
		return real.nan;
	bool eneg = false;
	if (s[i] == '-')
	{
		eneg = true;
		i++;
	}
	else if (s[i] == '+')
		i++;
	if (i >= s.length)
		return real.nan;
	int e = 0;
	while (i < s.length)
	{
		e *= 10;
		if (s[i] >= '0' && s[i] <= '9')
			e += s[i] - '0';
		else
			return real.nan;
		i++;
	}
	if (eneg)
		e = -e;
	result *= std.math.pow(hex ? 2.0L : 10.0L, cast(real)e);
done:	
	return neg ? -result : result;
}

unittest
{
	assert(feq(atof("123"), 123));
	assert(feq(atof("+123"), +123));
	assert(feq(atof("-123"), -123));
	assert(feq(atof("123e2"), 12300));
	assert(feq(atof("123e+2"), 12300));
	assert(feq(atof("123e-2"), 1.23));
	assert(feq(atof("123."), 123));
	assert(feq(atof("123.E-2"), 1.23));
	assert(feq(atof(".456"), .456));
	assert(feq(atof("123.456"), 123.456));
	assert(feq(atof("1.23456E+2"), 123.456));
	//assert(feq(atof("1A2h"), 1A2h));
	//assert(feq(atof("1a2h"), 1a2h));
	assert(feq(atof("0x1A2"), 0x1A2));
	assert(feq(atof("0x1a2p2"), 0x1a2p2));
	assert(feq(atof("0x1a2p+2"), 0x1a2p+2));
	assert(feq(atof("0x1a2p-2"), 0x1a2p-2));
	assert(feq(atof("0x1A2.3B4"), 0x1A2.3B4p0));
	assert(feq(atof("0x1a2.3b4P2"), 0x1a2.3b4P2));
}

