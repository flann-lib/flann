/** Algorithms for finding roots and extrema of one-argument real functions
 * using bracketing.
 *
 * Copyright: Copyright (C) 2008 Don Clugston.
 * License:   BSD style: $(LICENSE), Digital Mars.
 * Authors:   Don Clugston.
 *
 */
module tango.math.Bracket;
import tango.math.Math;
import tango.math.IEEE;

private:

// return true if a and b have opposite sign
bool oppositeSigns(T)(T a, T b)
{    
    return (signbit(a) ^ signbit(b))!=0;
}

// TODO: This should be exposed publically, but needs a better name.
struct BracketResult(T, R)
{
    T xlo;
    T xhi;
    R fxlo;
    R fxhi;
}

public:

/**  Find a real root of the real function f(x) via bracketing.
 *
 * Given a range [a..b] such that f(a) and f(b) have opposite sign,
 * returns the value of x in the range which is closest to a root of f(x).
 * If f(x) has more than one root in the range, one will be chosen arbitrarily.
 * If f(x) returns $(NAN), $(NAN) will be returned; otherwise, this algorithm
 * is guaranteed to succeed. 
 *  
 * Uses an algorithm based on TOMS748, which uses inverse cubic interpolation 
 * whenever possible, otherwise reverting to parabolic or secant
 * interpolation. Compared to TOMS748, this implementation improves worst-case
 * performance by a factor of more than 100, and typical performance by a factor
 * of 2. For 80-bit reals, most problems require 8 - 15 calls to f(x) to achieve
 * full machine precision. The worst-case performance (pathological cases) is 
 * approximately twice the number of bits. 
 *
 * References: 
 * "On Enclosing Simple Roots of Nonlinear Equations", G. Alefeld, F.A. Potra, 
 *   Yixun Shi, Mathematics of Computation 61, pp733-744 (1993).
 *   Fortran code available from www.netlib.org as algorithm TOMS478.
 *
 */
T findRoot(T, R)(R delegate(T) f, T ax, T bx)
{
    auto r = findRoot(f, ax, bx, f(ax), f(bx), (BracketResult!(T,R) r){ 
         return r.xhi==nextUp(r.xlo); });
    return fabs(r.fxlo)<=fabs(r.fxhi) ? r.xlo : r.xhi;
}

private:

/** Find root by bracketing, allowing termination condition to be specified
 *
 * Params:
 * tolerance   Defines the termination condition. Return true when acceptable
 *             bounds have been obtained.
 */
BracketResult!(T, R) findRoot(T,R)(R delegate(T) f, T ax, T bx, R fax, R fbx,
    bool delegate(BracketResult!(T,R) r) tolerance)
in {
    assert(ax<=bx, "Parameters ax and bx out of order.");
    assert(ax<>=0 && bx<>=0, "Limits must not be NaN");
    assert(oppositeSigns(fax,fbx), "Parameters must bracket the root.");
}
body {   
// This code is (heavily) modified from TOMS748 (www.netlib.org). Some ideas
// were borrowed from the Boost Mathematics Library.

    T a = ax, b = bx, d;  // [a..b] is our current bracket.
    R fa = fax, fb = fbx, fd; // d is the third best guess.       

    // Test the function at point c; update brackets accordingly
    void bracket(T c)
    {
        T fc = f(c);        
        if (fc == 0) { // Exact solution
            a = c;
            fa = fc;
            d = c;
            fd = fc;
            return;
        }
        // Determine new enclosing interval
        if (oppositeSigns(fa, fc)) {
            d = b;
            fd = fb;
            b = c;
            fb = fc;
        } else {
            d = a;
            fd = fa;
            a = c;
            fa = fc;
        }
    }

   /* Perform a secant interpolation. If the result would lie on a or b, or if
     a and b differ so wildly in magnitude that the result would be meaningless,
     perform a bisection instead.
    */
    T secant_interpolate(T a, T b, T fa, T fb)
    {
        if (( ((a - b) == a) && b!=0) || (a!=0 && ((b - a) == b))) {
            // Catastrophic cancellation
            if (a == 0) a = copysign(0.0L, b);
            else if (b == 0) b = copysign(0.0L, a);
            else if (oppositeSigns(a, b)) return 0;
            T c = ieeeMean(a, b); 
            return c;
        }
       // avoid overflow
       if (b - a > T.max)    return b / 2.0 + a / 2.0;
       if (fb - fa > T.max)  return a - (b - a) / 2;
       T c = a - (fa / (fb - fa)) * (b - a);
       if (c == a || c == b) return (a + b) / 2;
       return c;
    }
    
    /* Uses 'numsteps' newton steps to approximate the zero in [a..b] of the
       quadratic polynomial interpolating f(x) at a, b, and d.
       Returns:         
         The approximate zero in [a..b] of the quadratic polynomial.
    */
    T newtonQuadratic(int numsteps)
    {
        // Find the coefficients of the quadratic polynomial.
        T a0 = fa;
        T a1 = (fb - fa)/(b - a);
        T a2 = ((fd - fb)/(d - b) - a1)/(d - a);
    
        // Determine the starting point of newton steps.
        T c = oppositeSigns(a2, fa) ? a  : b;
     
        // start the safeguarded newton steps.
        for (int i = 0; i<numsteps; ++i) {        
            T pc = a0 + (a1 + a2 * (c - b))*(c - a);
            T pdc = a1 + a2*((2.0 * c) - (a + b));
            if (pdc == 0) return a - a0 / a1;
            else c = c - pc / pdc;        
        }
        return c;    
    }
    
    // On the first iteration we take a secant step:
    if(fa != 0) {
        bracket(secant_interpolate(a, b, fa, fb));
    }
    // Starting with the second iteration, higher-order interpolation can
    // be used.
    int itnum = 1;   // Iteration number    
    int baditer = 1; // Num bisections to take if an iteration is bad.
    T c, e;  // e is our fourth best guess
    R fe;   
whileloop:
    while((fa != 0) && !tolerance(BracketResult!(T,R)(a, b, fa, fb))) {        
        T a0 = a, b0 = b; // record the brackets
      
        // Do two higher-order (cubic or parabolic) interpolation steps.
        for (int QQ = 0; QQ < 2; ++QQ) {      
            // Cubic inverse interpolation requires that 
            // all four function values fa, fb, fd, and fe are distinct; 
            // otherwise use quadratic interpolation.
            bool distinct = (fa != fb) && (fa != fd) && (fa != fe) 
                         && (fb != fd) && (fb != fe) && (fd != fe);
            // The first time, cubic interpolation is impossible.
            if (itnum<2) distinct = false;
            bool ok = distinct;
            if (distinct) {                
                // Cubic inverse interpolation of f(x) at a, b, d, and e
                real q11 = (d - e) * fd / (fe - fd);
                real q21 = (b - d) * fb / (fd - fb);
                real q31 = (a - b) * fa / (fb - fa);
                real d21 = (b - d) * fd / (fd - fb);
                real d31 = (a - b) * fb / (fb - fa);
                      
                real q22 = (d21 - q11) * fb / (fe - fb);
                real q32 = (d31 - q21) * fa / (fd - fa);
                real d32 = (d31 - q21) * fd / (fd - fa);
                real q33 = (d32 - q22) * fa / (fe - fa);
                c = a + (q31 + q32 + q33);
                if (c!<>=0 || (c <= a) || (c >= b)) {
                    // DAC: If the interpolation predicts a or b, it's 
                    // probable that it's the actual root. Only allow this if
                    // we're already close to the root.                
                    if (c == a && a - b != a) {
                        c = nextUp(a);
                    }
                    else if (c == b && a - b != -b) {
                        c = nextDown(b);
                    } else {
                        ok = false;
                    }
                }
            }
            if (!ok) {
               c = newtonQuadratic(distinct ? 3 : 2);
               if(c!<>=0 || (c <= a) || (c >= b)) {
                  // Failure, try a secant step:
                  c = secant_interpolate(a, b, fa, fb);
               }
            }
            ++itnum;                
            e = d;
            fe = fd;
            bracket(c);
            if((fa == 0) || tolerance(BracketResult!(T,R)(a, b, fa, fb)))
                break whileloop;
            if (itnum == 2)
                continue whileloop;
        }
        // Now we take a double-length secant step:
        T u;
        R fu;
        if(fabs(fa) < fabs(fb)) {
             u = a;
             fu = fa;
        } else {
             u = b;
             fu = fb;
        }
        c = u - 2 * (fu / (fb - fa)) * (b - a);
        // DAC: If the secant predicts a value equal to an endpoint, it's
        // probably false.      
        if(c==a || c==b || c!<>=0 || fabs(c - u) > (b - a) / 2) {
            if ((a-b) == a || (b-a) == b) {
                if ( (a>0 && b<0) || (a<0 && b>0) ) c = 0;
                else {
                   if (a==0) c = ieeeMean(copysign(0.0L, b), b);
                   else if (b==0) c = ieeeMean(copysign(0.0L, a), a);
                   else c = ieeeMean(a, b);
                }
            } else {
                c = a + (b - a) / 2;
            }       
        }
        e = d;
        fe = fd;
        bracket(c);
        if((fa == 0) || tolerance(BracketResult!(T,R)(a, b, fa, fb)))
            break;
            
        // We must ensure that the bounds reduce by a factor of 2 
        // (DAC: in binary space!) every iteration. If we haven't achieved this
        // yet (DAC: or if we don't yet know what the exponent is),
        // perform a binary chop.

        if( (a==0 || b==0 || 
            (fabs(a) >= 0.5 * fabs(b) && fabs(b) >= 0.5 * fabs(a))) 
            &&  (b - a) < 0.25 * (b0 - a0))  {
                baditer = 1;        
                continue;
            }
        // DAC: If this happens on consecutive iterations, we probably have a
        // pathological function. Perform a number of bisections equal to the
        // total number of consecutive bad iterations.
        
        if ((b - a) < 0.25 * (b0 - a0)) baditer=1;
        for (int QQ = 0; QQ < baditer ;++QQ) {
            e = d;
            fe = fd;
    
            T w;
            if ((a>0 && b<0) ||(a<0 && b>0)) w = 0;
            else {
                T usea = a;
                T useb = b;
                if (a == 0) usea = copysign(0.0L, b);
                else if (b == 0) useb = copysign(0.0L, a);
                w = ieeeMean(usea, useb);
            }
            bracket(w);
        }
        ++baditer;
    }

    if (fa == 0) return BracketResult!(T, R)(a, a, fa, fa);
    else if (fb == 0) return BracketResult!(T, R)(b, b, fb, fb);
    else return BracketResult!(T, R)(a, b, fa, fb);
}

public:
/**
 * Find the minimum value of the function func().
 *
 * Returns the value of x such that func(x) is minimised. Uses Brent's method, 
 * which uses a parabolic fit to rapidly approach the minimum but reverts to a
 * Golden Section search where necessary.
 *
 * The minimum is located to an accuracy of feqrel(min, truemin) < 
 * real.mant_dig/2.
 *
 * Parameters:
 *     func         The function to be minimized
 *     xinitial     Initial guess to be used.
 *     xlo, xhi     Upper and lower bounds on x.
 *                  func(xinitial) <= func(x1) and func(xinitial) <= func(x2)
 *     funcMin      The minimum value of func(x).
 */
T findMinimum(T,R)(R delegate(T) func, T xlo, T xhi, T xinitial, 
     out R funcMin)
in {
    assert(xlo <= xhi);
    assert(xinitial >= xlo);
    assert(xinitial <= xhi);
    assert(func(xinitial) <= func(xlo) && func(xinitial) <= func(xhi));
}
body{
    // Based on the original Algol code by R.P. Brent.
    const real GOLDENRATIO = 0.3819660112501051; // (3 - sqrt(5))/2 = 1 - 1/phi

    T stepBeforeLast = 0.0;
    T lastStep;
    T bestx = xinitial; // the best value so far (min value for f(x)).
    R fbest = func(bestx);
    T second = xinitial;  // the point with the second best value of f(x)
    R fsecond = fbest;
    T third = xinitial;  // the previous value of second.
    R fthird = fbest;
    int numiter = 0;
    for (;;) {
        ++numiter;
        T xmid = 0.5 * (xlo + xhi);
        const real SQRTEPSILON = 3e-10L; // sqrt(real.epsilon)
        T tol1 = SQRTEPSILON * fabs(bestx);
        T tol2 = 2.0 * tol1;
        if (fabs(bestx - xmid) <= (tol2 - 0.5*(xhi - xlo)) ) {
            funcMin = fbest;
            return bestx;
        }
        if (fabs(stepBeforeLast) > tol1) {
            // trial parabolic fit
            real r = (bestx - second) * (fbest - fthird);
            // DAC: This can be infinite, in which case lastStep will be NaN.
            real denom = (bestx - third) * (fbest - fsecond);
            real numerator = (bestx - third) * denom - (bestx - second) * r;
            denom = 2.0 * (denom-r);
            if ( denom > 0) numerator = -numerator;
            denom = fabs(denom);
            // is the parabolic fit good enough?
            // it must be a step that is less than half the movement
            // of the step before last, AND it must fall
            // into the bounding interval [xlo,xhi].
            if (fabs(numerator) >= fabs(0.5 * denom * stepBeforeLast)
                || numerator <= denom*(xlo-bestx) 
                || numerator >= denom*(xhi-bestx)) {
                // No, use a golden section search instead.
                // Step into the larger of the two segments.
                stepBeforeLast = (bestx >= xmid) ? xlo - bestx : xhi - bestx;
                lastStep = GOLDENRATIO * stepBeforeLast;
            } else {
                // parabola is OK
                stepBeforeLast = lastStep;
                lastStep = numerator/denom;
                real xtest = bestx + lastStep;
                if (xtest-xlo < tol2 || xhi-xtest < tol2) {
                    if (xmid-bestx > 0)
                        lastStep = tol1;
                    else lastStep = -tol1;
                }
            }
        } else {
            // Use a golden section search instead
            stepBeforeLast = bestx >= xmid ? xlo - bestx : xhi - bestx;
            lastStep = GOLDENRATIO * stepBeforeLast;
        }
        T xtest;
        if (fabs(lastStep) < tol1 || lastStep !<>= 0) {
            if (lastStep > 0) lastStep = tol1;
            else lastStep = - tol1;
        }
        xtest = bestx + lastStep;
        // Evaluate the function at point xtest.
        R ftest = func(xtest);

        if (ftest <= fbest) {
            // We have a new best point!
            // The previous best point becomes a limit.
            if (xtest >= bestx) xlo = bestx; else xhi = bestx;
            third = second;  fthird = fsecond;
            second = bestx;  fsecond = fbest;
            bestx = xtest;  fbest = ftest;
        } else {
            // This new point is now one of the limits.
            if (xtest < bestx)  xlo = xtest; else xhi = xtest;
            // Is it a new second best point?
            if (ftest < fsecond || second == bestx) {
                third = second;  fthird = fsecond;
                second = xtest;  fsecond = ftest;
            } else if (ftest <= fthird || third == bestx || third == second) {
                // At least it's our third best point!
                third = xtest;  fthird = ftest;
            }
        }
    }
}

private:
debug(UnitTest) {
unittest{
    
    int numProblems = 0;
    int numCalls;
    
    void testFindRoot(real delegate(real) f, real x1, real x2) {
        numCalls=0;
        ++numProblems;
        assert(x1<>=0 && x2<>=0);
        auto result = findRoot(f, x1, x2, f(x1), f(x2),
            (BracketResult!(real, real) r){ return r.xhi==nextUp(r.xlo); });
        
        auto flo = f(result.xlo);
        auto fhi = f(result.xhi);
        if (flo!=0) {
            assert(oppositeSigns(flo, fhi));
        }
    }
    
    // Test functions
    real cubicfn (real x) {
       ++numCalls;
       if (x>float.max) x = float.max;
       if (x<-double.max) x = -double.max;
       // This has a single real root at -59.286543284815
       return 0.386*x*x*x + 23*x*x + 15.7*x + 525.2;
    }
    // Test a function with more than one root.
    real multisine(real x) { ++numCalls; return sin(x); }
    testFindRoot( &multisine, 6, 90);
    testFindRoot(&cubicfn, -100, 100);    
    testFindRoot( &cubicfn, -double.max, real.max);
    
    
/* Tests from the paper:
 * "On Enclosing Simple Roots of Nonlinear Equations", G. Alefeld, F.A. Potra, 
 *   Yixun Shi, Mathematics of Computation 61, pp733-744 (1993).
 */
    // Parameters common to many alefeld tests.
    int n;
    real ale_a, ale_b;

    int powercalls = 0;
    
    real power(real x) {
        ++powercalls;
        ++numCalls;
        return pow(x, n) + double.min;
    }
    int [] power_nvals = [3, 5, 7, 9, 19, 25];
    // Alefeld paper states that pow(x,n) is a very poor case, where bisection
    // outperforms his method, and gives total numcalls = 
    // 921 for bisection (2.4 calls per bit), 1830 for Alefeld (4.76/bit), 
    // 2624 for brent (6.8/bit)
    // ... but that is for double, not real80.
    // This poor performance seems mainly due to catastrophic cancellation, 
    // which is avoided here by the use of ieeeMean().
    // I get: 231 (0.48/bit).
    // IE this is 10X faster in Alefeld's worst case
    numProblems=0;
    foreach(k; power_nvals) {
        n = k;
        testFindRoot(&power, -1, 10);
    }
    
    int powerProblems = numProblems;

    // Tests from Alefeld paper
        
    int [9] alefeldSums;
    real alefeld0(real x){
        ++alefeldSums[0];
        ++numCalls;
        real q =  sin(x) - x/2;
        for (int i=1; i<20; ++i)
            q+=(2*i-5.0)*(2*i-5.0)/((x-i*i)*(x-i*i)*(x-i*i));
        return q;
    }
   real alefeld1(real x) {
        ++numCalls;
       ++alefeldSums[1];
       return ale_a*x + exp(ale_b * x);
   }
   real alefeld2(real x) {
        ++numCalls;
       ++alefeldSums[2];
       return pow(x, n) - ale_a;
   }
   real alefeld3(real x) {
        ++numCalls;
       ++alefeldSums[3];
       return (1.0 +pow(1.0L-n, 2))*x - pow(1.0L-n*x, 2);
   }
   real alefeld4(real x) {
        ++numCalls;
       ++alefeldSums[4];
       return x*x - pow(1-x, n);
   }
   
   real alefeld5(real x) {
        ++numCalls;
       ++alefeldSums[5];
       return (1+pow(1.0L-n, 4))*x - pow(1.0L-n*x, 4);
   }
   
   real alefeld6(real x) {
        ++numCalls;
       ++alefeldSums[6];
       return exp(-n*x)*(x-1.01L) + pow(x, n);
   }
   
   real alefeld7(real x) {
        ++numCalls;
       ++alefeldSums[7];
       return (n*x-1)/((n-1)*x);
   }
   numProblems=0;
   testFindRoot(&alefeld0, PI_2, PI);
   for (n=1; n<=10; ++n) {
    testFindRoot(&alefeld0, n*n+1e-9L, (n+1)*(n+1)-1e-9L);
   }
   ale_a = -40; ale_b = -1;
   testFindRoot(&alefeld1, -9, 31);
   ale_a = -100; ale_b = -2;
   testFindRoot(&alefeld1, -9, 31);
   ale_a = -200; ale_b = -3;
   testFindRoot(&alefeld1, -9, 31);
   int [] nvals_3 = [1, 2, 5, 10, 15, 20];
   int [] nvals_5 = [1, 2, 4, 5, 8, 15, 20];
   int [] nvals_6 = [1, 5, 10, 15, 20];
   int [] nvals_7 = [2, 5, 15, 20];
  
    for(int i=4; i<12; i+=2) {
       n = i;
       ale_a = 0.2;
       testFindRoot(&alefeld2, 0, 5);
       ale_a=1;
       testFindRoot(&alefeld2, 0.95, 4.05);
       testFindRoot(&alefeld2, 0, 1.5);       
    }
    foreach(i; nvals_3) {
        n=i;
        testFindRoot(&alefeld3, 0, 1);
    }
    foreach(i; nvals_3) {
        n=i;
        testFindRoot(&alefeld4, 0, 1);
    }
    foreach(i; nvals_5) {
        n=i;
        testFindRoot(&alefeld5, 0, 1);
    }
    foreach(i; nvals_6) {
        n=i;
        testFindRoot(&alefeld6, 0, 1);
    }
    foreach(i; nvals_7) {
        n=i;
        testFindRoot(&alefeld7, 0.01L, 1);
    }   
    real worstcase(real x) { ++numCalls;
        return x<0.3*real.max? -0.999e-3 : 1.0;
    }
    testFindRoot(&worstcase, -real.max, real.max);
       
/*   
   int grandtotal=0;
   foreach(calls; alefeldSums) {
       grandtotal+=calls;
   }
   grandtotal-=2*numProblems;
   printf("\nALEFELD TOTAL = %d avg = %f (alefeld avg=19.3 for double)\n", 
   grandtotal, (1.0*grandtotal)/numProblems);
   powercalls -= 2*powerProblems;
   printf("POWER TOTAL = %d avg = %f ", powercalls, 
        (1.0*powercalls)/powerProblems);
*/        
}

unittest {
    int numcalls=-4;
    // Extremely well-behaved function.
    real parab(real bestx) {
        ++numcalls;
        return 3 * (bestx-7.14L) * (bestx-7.14L) + 18;
    }
    real minval;
    real minx;
    // Note, performs extremely poorly if we have an overflow, so that the
    // function returns infinity. It might be better to explicitly deal with 
    // that situation (all parabolic fits will fail whenever an infinity is
    // present).
    minx = findMinimum(&parab, -sqrt(real.max), sqrt(real.max), 
        cast(real)(float.max), minval);
    assert(minval==18);
    assert(feqrel(minx,7.14L)>=float.mant_dig);
   
     // Problems from Jack Crenshaw's "World's Best Root Finder"
    // http://www.embedded.com/columns/programmerstoolbox/9900609
   // This has a minimum of cbrt(0.5).
   real crenshawcos(real x) { return cos(2*PI*x*x*x); }
   minx = findMinimum(&crenshawcos, 0.0L, 1.0L, 0.1L, minval);
   assert(feqrel(minx*minx*minx, 0.5L)<=real.mant_dig-4);
   
}
}
