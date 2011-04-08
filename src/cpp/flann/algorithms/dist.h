/***********************************************************************
 * Software License Agreement (BSD License)
 *
 * Copyright 2008-2009  Marius Muja (mariusm@cs.ubc.ca). All rights reserved.
 * Copyright 2008-2009  David G. Lowe (lowe@cs.ubc.ca). All rights reserved.
 *
 * THE BSD LICENSE
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *************************************************************************/

#ifndef DIST_H
#define DIST_H

#include <cmath>
#include <cstdlib>

#include "flann/general.h"

namespace flann
{

template<typename T>
inline T abs(T x) { return (x<0) ? -x : x; }

template<>
inline int abs<int>(int x) { return ::abs(x); }

template<>
inline float abs<float>(float x) { return fabsf(x); }

template<>
inline double abs<double>(double x) { return fabs(x); }

template<>
inline long double abs<long double>(long double x) { return fabsl(x); }


template<typename T>
struct Accumulator { typedef T Type; };
template<>
struct Accumulator<unsigned char>  { typedef float Type; };
template<>
struct Accumulator<unsigned short> { typedef float Type; };
template<>
struct Accumulator<unsigned int> { typedef float Type; };
template<>
struct Accumulator<char>   { typedef float Type; };
template<>
struct Accumulator<short>  { typedef float Type; };
template<>
struct Accumulator<int> { typedef float Type; };

/**
 * Squared Euclidean distance functor.
 *
 * This is the simpler, unrolled version. This is preferable for
 * very low dimensionality data (eg 3D points)
 */
template<class T>
struct L2_Simple
{
    typedef T ElementType;
    typedef typename Accumulator<T>::Type ResultType;

    template <typename Iterator1, typename Iterator2>
    ResultType operator()(Iterator1 a, Iterator2 b, size_t size, ResultType worst_dist = -1) const
    {
        ResultType result = ResultType();
        ResultType diff;
        for(size_t i = 0; i < size; ++i ) {
            diff = *a++ - *b++;
            result += diff*diff;
        }
        return result;
    }

    template <typename U, typename V>
    inline ResultType accum_dist(const U& a, const V& b, int dim) const
    {
        return (a-b)*(a-b);
    }
};



/**
 * Squared Euclidean distance functor, optimized version
 */
template<class T>
struct L2
{
    typedef T ElementType;
    typedef typename Accumulator<T>::Type ResultType;

    /**
     *  Compute the squared Euclidean distance between two vectors.
     *
     *	This is highly optimised, with loop unrolling, as it is one
     *	of the most expensive inner loops.
     *
     *	The computation of squared root at the end is omitted for
     *	efficiency.
     */
    template <typename Iterator1, typename Iterator2>
    ResultType operator()(Iterator1 a, Iterator2 b, size_t size, ResultType worst_dist = -1) const
    {
        ResultType result = ResultType();
        ResultType diff0, diff1, diff2, diff3;
        Iterator1 last = a + size;
        Iterator1 lastgroup = last - 3;

        /* Process 4 items with each loop for efficiency. */
        while (a < lastgroup) {
            diff0 = a[0] - b[0];
            diff1 = a[1] - b[1];
            diff2 = a[2] - b[2];
            diff3 = a[3] - b[3];
            result += diff0 * diff0 + diff1 * diff1 + diff2 * diff2 + diff3 * diff3;
            a += 4;
            b += 4;

            if ((worst_dist>0)&&(result>worst_dist)) {
                return result;
            }
        }
        /* Process last 0-3 pixels.  Not needed for standard vector lengths. */
        while (a < last) {
            diff0 = *a++ - *b++;
            result += diff0 * diff0;
        }
        return result;
    }

    /**
     *	Partial euclidean distance, using just one dimension. This is used by the
     *	kd-tree when computing partial distances while traversing the tree.
     *
     *	Squared root is omitted for efficiency.
     */
    template <typename U, typename V>
    inline ResultType accum_dist(const U& a, const V& b, int dim) const
    {
        return (a-b)*(a-b);
    }
};


/*
 * Manhattan distance functor, optimized version
 */
template<class T>
struct L1
{
    typedef T ElementType;
    typedef typename Accumulator<T>::Type ResultType;

    /**
     *  Compute the Manhattan (L_1) distance between two vectors.
     *
     *	This is highly optimised, with loop unrolling, as it is one
     *	of the most expensive inner loops.
     */
    template <typename Iterator1, typename Iterator2>
    ResultType operator()(Iterator1 a, Iterator2 b, size_t size, ResultType worst_dist = -1) const
    {
        ResultType result = ResultType();
        ResultType diff0, diff1, diff2, diff3;
        Iterator1 last = a + size;
        Iterator1 lastgroup = last - 3;

        /* Process 4 items with each loop for efficiency. */
        while (a < lastgroup) {
            diff0 = abs(a[0] - b[0]);
            diff1 = abs(a[1] - b[1]);
            diff2 = abs(a[2] - b[2]);
            diff3 = abs(a[3] - b[3]);
            result += diff0 + diff1 + diff2 + diff3;
            a += 4;
            b += 4;

            if ((worst_dist>0)&&(result>worst_dist)) {
                return result;
            }
        }
        /* Process last 0-3 pixels.  Not needed for standard vector lengths. */
        while (a < last) {
            diff0 = abs(*a++ - *b++);
            result += diff0;
        }
        return result;
    }

    /**
     * Partial distance, used by the kd-tree.
     */
    template <typename U, typename V>
    inline ResultType accum_dist(const U& a, const V& b, int dim) const
    {
        return abs(a-b);
    }
};



template<class T>
struct MinkowskiDistance
{
    typedef T ElementType;
    typedef typename Accumulator<T>::Type ResultType;

    int order;

    MinkowskiDistance(int order_) : order(order_) {}

    /**
     *  Compute the Minkowsky (L_p) distance between two vectors.
     *
     *	This is highly optimised, with loop unrolling, as it is one
     *	of the most expensive inner loops.
     *
     *	The computation of squared root at the end is omitted for
     *	efficiency.
     */
    template <typename Iterator1, typename Iterator2>
    ResultType operator()(Iterator1 a, Iterator2 b, size_t size, ResultType worst_dist = -1) const
    {
        ResultType result = ResultType();
        ResultType diff0, diff1, diff2, diff3;
        Iterator1 last = a + size;
        Iterator1 lastgroup = last - 3;

        /* Process 4 items with each loop for efficiency. */
        while (a < lastgroup) {
            diff0 = abs(a[0] - b[0]);
            diff1 = abs(a[1] - b[1]);
            diff2 = abs(a[2] - b[2]);
            diff3 = abs(a[3] - b[3]);
            result += pow(diff0,order) + pow(diff1,order) + pow(diff2,order) + pow(diff3,order);
            a += 4;
            b += 4;

            if ((worst_dist>0)&&(result>worst_dist)) {
                return result;
            }
        }
        /* Process last 0-3 pixels.  Not needed for standard vector lengths. */
        while (a < last) {
            diff0 = abs(*a++ - *b++);
            result += pow(diff0,order);
        }
        return result;
    }

    /**
     * Partial distance, used by the kd-tree.
     */
    template <typename U, typename V>
    inline ResultType accum_dist(const U& a, const V& b, int dim) const
    {
        return pow(static_cast<ResultType>(abs(a-b)),order);
    }
};



template<class T>
struct MaxDistance
{
    typedef T ElementType;
    typedef typename Accumulator<T>::Type ResultType;

    /**
     *  Compute the max distance (L_infinity) between two vectors.
     *
     *  This distance is not a valid kdtree distance, it's not dimensionwise additive.
     */
    template <typename Iterator1, typename Iterator2>
    ResultType operator()(Iterator1 a, Iterator2 b, size_t size, ResultType worst_dist = -1) const
    {
        ResultType result = ResultType();
        ResultType diff0, diff1, diff2, diff3;
        Iterator1 last = a + size;
        Iterator1 lastgroup = last - 3;

        /* Process 4 items with each loop for efficiency. */
        while (a < lastgroup) {
            diff0 = abs(a[0] - b[0]);
            diff1 = abs(a[1] - b[1]);
            diff2 = abs(a[2] - b[2]);
            diff3 = abs(a[3] - b[3]);
            if (diff0>result) {result = diff0; }
            if (diff1>result) {result = diff1; }
            if (diff2>result) {result = diff2; }
            if (diff3>result) {result = diff3; }
            a += 4;
            b += 4;

            if ((worst_dist>0)&&(result>worst_dist)) {
                return result;
            }
        }
        /* Process last 0-3 pixels.  Not needed for standard vector lengths. */
        while (a < last) {
            diff0 = abs(*a++ - *b++);
            result = (diff0>result) ? diff0 : result;
        }
        return result;
    }

    /* This distance functor is not dimension-wise additive, which
     * makes it an invalid kd-tree distance, not implementing the accum_dist method */

};



template<class T>
struct HistIntersectionDistance
{
    typedef T ElementType;
    typedef typename Accumulator<T>::Type ResultType;

    /**
     *  Compute the histogram intersection distance
     */
    template <typename Iterator1, typename Iterator2>
    ResultType operator()(Iterator1 a, Iterator2 b, size_t size, ResultType worst_dist = -1) const
    {
        ResultType result = ResultType();
        ResultType min0, min1, min2, min3;
        Iterator1 last = a + size;
        Iterator1 lastgroup = last - 3;

        /* Process 4 items with each loop for efficiency. */
        while (a < lastgroup) {
            min0 = a[0] < b[0] ? a[0] : b[0];
            min1 = a[1] < b[1] ? a[1] : b[1];
            min2 = a[2] < b[2] ? a[2] : b[2];
            min3 = a[3] < b[3] ? a[3] : b[3];
            result += min0 + min1 + min2 + min3;
            a += 4;
            b += 4;
            if ((worst_dist>0)&&(result>worst_dist)) {
                return result;
            }
        }
        /* Process last 0-3 pixels.  Not needed for standard vector lengths. */
        while (a < last) {
            min0 = *a < *b ? *a : *b;
            result += min0;
        }
        return result;
    }

    /**
     * Partial distance, used by the kd-tree.
     */
    template <typename U, typename V>
    inline ResultType accum_dist(const U& a, const V& b, int dim) const
    {
        return a<b ? a : b;
    }
};



template<class T>
struct HellingerDistance
{
    typedef T ElementType;
    typedef typename Accumulator<T>::Type ResultType;

    /**
     *  Compute the histogram intersection distance
     */
    template <typename Iterator1, typename Iterator2>
    ResultType operator()(Iterator1 a, Iterator2 b, size_t size, ResultType worst_dist = -1) const
    {
        ResultType result = ResultType();
        ResultType diff0, diff1, diff2, diff3;
        Iterator1 last = a + size;
        Iterator1 lastgroup = last - 3;

        /* Process 4 items with each loop for efficiency. */
        while (a < lastgroup) {
            diff0 = sqrt(static_cast<ResultType>(a[0])) - sqrt(static_cast<ResultType>(b[0]));
            diff1 = sqrt(static_cast<ResultType>(a[1])) - sqrt(static_cast<ResultType>(b[1]));
            diff2 = sqrt(static_cast<ResultType>(a[2])) - sqrt(static_cast<ResultType>(b[2]));
            diff3 = sqrt(static_cast<ResultType>(a[3])) - sqrt(static_cast<ResultType>(b[3]));
            result += diff0 * diff0 + diff1 * diff1 + diff2 * diff2 + diff3 * diff3;
            a += 4;
            b += 4;
        }
        while (a < last) {
            diff0 = sqrt(static_cast<ResultType>(*a++)) - sqrt(static_cast<ResultType>(*b++));
            result += diff0 * diff0;
        }
        return result;
    }

    /**
     * Partial distance, used by the kd-tree.
     */
    template <typename U, typename V>
    inline ResultType accum_dist(const U& a, const V& b, int dim) const
    {
        return sqrt(static_cast<ResultType>(a)) - sqrt(static_cast<ResultType>(b));
    }
};


template<class T>
struct ChiSquareDistance
{
    typedef T ElementType;
    typedef typename Accumulator<T>::Type ResultType;

    /**
     *  Compute the chi-square distance
     */
    template <typename Iterator1, typename Iterator2>
    ResultType operator()(Iterator1 a, Iterator2 b, size_t size, ResultType worst_dist = -1) const
    {
        ResultType result = ResultType();
        ResultType sum, diff;
        Iterator1 last = a + size;

        while (a < last) {
            sum = *a + *b;
            if (sum>0) {
                diff = *a - *b;
                result += diff*diff/sum;
            }
            ++a;
            ++b;

            if ((worst_dist>0)&&(result>worst_dist)) {
                return result;
            }
        }
        return result;
    }

    /**
     * Partial distance, used by the kd-tree.
     */
    template <typename U, typename V>
    inline ResultType accum_dist(const U& a, const V& b, int dim) const
    {
        ResultType result = ResultType();
        ResultType sum, diff;

        sum = a+b;
        if (sum>0) {
            diff = a-b;
            result = diff*diff/sum;
        }
        return result;
    }
};


template<class T>
struct KL_Divergence
{
    typedef T ElementType;
    typedef typename Accumulator<T>::Type ResultType;

    /**
     *  Compute the Kullback–Leibler divergence
     */
    template <typename Iterator1, typename Iterator2>
    ResultType operator()(Iterator1 a, Iterator2 b, size_t size, ResultType worst_dist = -1) const
    {
        ResultType result = ResultType();
        Iterator1 last = a + size;

        while (a < last) {
            if (* a != 0) {
                ResultType ratio = *a / *b;
                if (ratio>0) {
                    result += *a * log(ratio);
                }
            }
            ++a;
            ++b;

            if ((worst_dist>0)&&(result>worst_dist)) {
                return result;
            }
        }
        return result;
    }

    /**
     * Partial distance, used by the kd-tree.
     */
    template <typename U, typename V>
    inline ResultType accum_dist(const U& a, const V& b, int dim) const
    {
        ResultType result = ResultType();
        ResultType ratio = a / b;
        if (ratio>0) {
            result = a * log(ratio);
        }
        return result;
    }
};



/*
 * This is a "zero iterator". It basically behaves like a zero filled
 * array to all algorithms that use arrays as iterators (STL style).
 * It's useful when there's a need to compute the distance between feature
 * and origin it and allows for better compiler optimisation than using a
 * zero-filled array.
 */
template <typename T>
struct ZeroIterator
{

    T operator*()
    {
        return 0;
    }

    T operator[](int index)
    {
        return 0;
    }

    ZeroIterator<T>& operator ++()
    {
        return *this;
    }

    ZeroIterator<T>& operator ++(int)
    {
        return *this;
    }

    ZeroIterator<T>& operator+=(int)
    {
        return *this;
    }

};

}

#endif //DIST_H
