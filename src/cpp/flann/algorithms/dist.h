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
#include <string.h>

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

// Forward declaration
template<typename ElementType>
  class ZeroIterator;


class True {};

class False {};


/**
 * Squared Euclidean distance functor.
 *
 * This is the simpler, unrolled version. This is preferable for
 * very low dimensionality data (eg 3D points)
 */
template<class T>
struct L2_Simple
{
	typedef True is_kdtree_distance;

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
	typedef True is_kdtree_distance;

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
	typedef True is_kdtree_distance;

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
	typedef True is_kdtree_distance;

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
	typedef False is_kdtree_distance;

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

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Hamming distance functor - counts the bit differences between two strings - useful for the Brief descriptor
 * bit count of A exclusive XOR'ed with B
 */
struct HammingLUT
{
	typedef False is_kdtree_distance;

  typedef unsigned char ValueType;
  typedef int ResultType;

  /** this will count the bits in a ^ b
   */
  ResultType operator()(const unsigned char* a, const unsigned char* b, int size) const
  {
    ResultType result = 0;
    for (int i = 0; i < size; i++)
    {
      result += byteBitsLookUp(a[i] ^ b[i]);
    }
    return result;
  }

  /** this will count the bits in a
   */
  ResultType operator()(const unsigned char* a, int size) const
  {
    ResultType result = 0;
    for (int i = 0; i < size; i++)
    {
      result += byteBitsLookUp(a[i]);
    }
    return result;
  }


  /** \brief given a byte, count the bits using a compile time generated look up table
   *  \param b the byte to count bits.  The look up table has an entry for all
   *  values of b, where that entry is the number of bits.
   *  \return the number of bits in byte b
   */
  static unsigned char byteBitsLookUp(unsigned char b)
  {
    static const unsigned char table[256] = {ByteBits<0>::COUNT, ByteBits<1>::COUNT, ByteBits<2>::COUNT,
                                             ByteBits<3>::COUNT, ByteBits<4>::COUNT, ByteBits<5>::COUNT,
                                             ByteBits<6>::COUNT, ByteBits<7>::COUNT, ByteBits<8>::COUNT,
                                             ByteBits<9>::COUNT, ByteBits<10>::COUNT, ByteBits<11>::COUNT,
                                             ByteBits<12>::COUNT, ByteBits<13>::COUNT, ByteBits<14>::COUNT,
                                             ByteBits<15>::COUNT, ByteBits<16>::COUNT, ByteBits<17>::COUNT,
                                             ByteBits<18>::COUNT, ByteBits<19>::COUNT, ByteBits<20>::COUNT,
                                             ByteBits<21>::COUNT, ByteBits<22>::COUNT, ByteBits<23>::COUNT,
                                             ByteBits<24>::COUNT, ByteBits<25>::COUNT, ByteBits<26>::COUNT,
                                             ByteBits<27>::COUNT, ByteBits<28>::COUNT, ByteBits<29>::COUNT,
                                             ByteBits<30>::COUNT, ByteBits<31>::COUNT, ByteBits<32>::COUNT,
                                             ByteBits<33>::COUNT, ByteBits<34>::COUNT, ByteBits<35>::COUNT,
                                             ByteBits<36>::COUNT, ByteBits<37>::COUNT, ByteBits<38>::COUNT,
                                             ByteBits<39>::COUNT, ByteBits<40>::COUNT, ByteBits<41>::COUNT,
                                             ByteBits<42>::COUNT, ByteBits<43>::COUNT, ByteBits<44>::COUNT,
                                             ByteBits<45>::COUNT, ByteBits<46>::COUNT, ByteBits<47>::COUNT,
                                             ByteBits<48>::COUNT, ByteBits<49>::COUNT, ByteBits<50>::COUNT,
                                             ByteBits<51>::COUNT, ByteBits<52>::COUNT, ByteBits<53>::COUNT,
                                             ByteBits<54>::COUNT, ByteBits<55>::COUNT, ByteBits<56>::COUNT,
                                             ByteBits<57>::COUNT, ByteBits<58>::COUNT, ByteBits<59>::COUNT,
                                             ByteBits<60>::COUNT, ByteBits<61>::COUNT, ByteBits<62>::COUNT,
                                             ByteBits<63>::COUNT, ByteBits<64>::COUNT, ByteBits<65>::COUNT,
                                             ByteBits<66>::COUNT, ByteBits<67>::COUNT, ByteBits<68>::COUNT,
                                             ByteBits<69>::COUNT, ByteBits<70>::COUNT, ByteBits<71>::COUNT,
                                             ByteBits<72>::COUNT, ByteBits<73>::COUNT, ByteBits<74>::COUNT,
                                             ByteBits<75>::COUNT, ByteBits<76>::COUNT, ByteBits<77>::COUNT,
                                             ByteBits<78>::COUNT, ByteBits<79>::COUNT, ByteBits<80>::COUNT,
                                             ByteBits<81>::COUNT, ByteBits<82>::COUNT, ByteBits<83>::COUNT,
                                             ByteBits<84>::COUNT, ByteBits<85>::COUNT, ByteBits<86>::COUNT,
                                             ByteBits<87>::COUNT, ByteBits<88>::COUNT, ByteBits<89>::COUNT,
                                             ByteBits<90>::COUNT, ByteBits<91>::COUNT, ByteBits<92>::COUNT,
                                             ByteBits<93>::COUNT, ByteBits<94>::COUNT, ByteBits<95>::COUNT,
                                             ByteBits<96>::COUNT, ByteBits<97>::COUNT, ByteBits<98>::COUNT,
                                             ByteBits<99>::COUNT, ByteBits<100>::COUNT, ByteBits<101>::COUNT, 
                                             ByteBits<102>::COUNT, ByteBits<103>::COUNT, ByteBits<104>::COUNT,
                                             ByteBits<105>::COUNT, ByteBits<106>::COUNT, ByteBits<107>::COUNT,
                                             ByteBits<108>::COUNT, ByteBits<109>::COUNT, ByteBits<110>::COUNT,
                                             ByteBits<111>::COUNT, ByteBits<112>::COUNT, ByteBits<113>::COUNT,
                                             ByteBits<114>::COUNT, ByteBits<115>::COUNT, ByteBits<116>::COUNT,
                                             ByteBits<117>::COUNT, ByteBits<118>::COUNT, ByteBits<119>::COUNT,
                                             ByteBits<120>::COUNT, ByteBits<121>::COUNT, ByteBits<122>::COUNT,
                                             ByteBits<123>::COUNT, ByteBits<124>::COUNT, ByteBits<125>::COUNT,
                                             ByteBits<126>::COUNT, ByteBits<127>::COUNT, ByteBits<128>::COUNT,
                                             ByteBits<129>::COUNT, ByteBits<130>::COUNT, ByteBits<131>::COUNT,
                                             ByteBits<132>::COUNT, ByteBits<133>::COUNT, ByteBits<134>::COUNT,
                                             ByteBits<135>::COUNT, ByteBits<136>::COUNT, ByteBits<137>::COUNT,
                                             ByteBits<138>::COUNT, ByteBits<139>::COUNT, ByteBits<140>::COUNT,
                                             ByteBits<141>::COUNT, ByteBits<142>::COUNT, ByteBits<143>::COUNT,
                                             ByteBits<144>::COUNT, ByteBits<145>::COUNT, ByteBits<146>::COUNT,
                                             ByteBits<147>::COUNT, ByteBits<148>::COUNT, ByteBits<149>::COUNT,
                                             ByteBits<150>::COUNT, ByteBits<151>::COUNT, ByteBits<152>::COUNT,
                                             ByteBits<153>::COUNT, ByteBits<154>::COUNT, ByteBits<155>::COUNT,
                                             ByteBits<156>::COUNT, ByteBits<157>::COUNT, ByteBits<158>::COUNT,
                                             ByteBits<159>::COUNT, ByteBits<160>::COUNT, ByteBits<161>::COUNT,
                                             ByteBits<162>::COUNT, ByteBits<163>::COUNT, ByteBits<164>::COUNT,
                                             ByteBits<165>::COUNT, ByteBits<166>::COUNT, ByteBits<167>::COUNT,
                                             ByteBits<168>::COUNT, ByteBits<169>::COUNT, ByteBits<170>::COUNT,
                                             ByteBits<171>::COUNT, ByteBits<172>::COUNT, ByteBits<173>::COUNT,
                                             ByteBits<174>::COUNT, ByteBits<175>::COUNT, ByteBits<176>::COUNT,
                                             ByteBits<177>::COUNT, ByteBits<178>::COUNT, ByteBits<179>::COUNT,
                                             ByteBits<180>::COUNT, ByteBits<181>::COUNT, ByteBits<182>::COUNT,
                                             ByteBits<183>::COUNT, ByteBits<184>::COUNT, ByteBits<185>::COUNT,
                                             ByteBits<186>::COUNT, ByteBits<187>::COUNT, ByteBits<188>::COUNT,
                                             ByteBits<189>::COUNT, ByteBits<190>::COUNT, ByteBits<191>::COUNT,
                                             ByteBits<192>::COUNT, ByteBits<193>::COUNT, ByteBits<194>::COUNT,
                                             ByteBits<195>::COUNT, ByteBits<196>::COUNT, ByteBits<197>::COUNT,
                                             ByteBits<198>::COUNT, ByteBits<199>::COUNT, ByteBits<200>::COUNT,
                                             ByteBits<201>::COUNT, ByteBits<202>::COUNT, ByteBits<203>::COUNT,
                                             ByteBits<204>::COUNT, ByteBits<205>::COUNT, ByteBits<206>::COUNT,
                                             ByteBits<207>::COUNT, ByteBits<208>::COUNT, ByteBits<209>::COUNT,
                                             ByteBits<210>::COUNT, ByteBits<211>::COUNT, ByteBits<212>::COUNT,
                                             ByteBits<213>::COUNT, ByteBits<214>::COUNT, ByteBits<215>::COUNT,
                                             ByteBits<216>::COUNT, ByteBits<217>::COUNT, ByteBits<218>::COUNT,
                                             ByteBits<219>::COUNT, ByteBits<220>::COUNT, ByteBits<221>::COUNT,
                                             ByteBits<222>::COUNT, ByteBits<223>::COUNT, ByteBits<224>::COUNT,
                                             ByteBits<225>::COUNT, ByteBits<226>::COUNT, ByteBits<227>::COUNT,
                                             ByteBits<228>::COUNT, ByteBits<229>::COUNT, ByteBits<230>::COUNT,
                                             ByteBits<231>::COUNT, ByteBits<232>::COUNT, ByteBits<233>::COUNT,
                                             ByteBits<234>::COUNT, ByteBits<235>::COUNT, ByteBits<236>::COUNT,
                                             ByteBits<237>::COUNT, ByteBits<238>::COUNT, ByteBits<239>::COUNT,
                                             ByteBits<240>::COUNT, ByteBits<241>::COUNT, ByteBits<242>::COUNT,
                                             ByteBits<243>::COUNT, ByteBits<244>::COUNT, ByteBits<245>::COUNT,
                                             ByteBits<246>::COUNT, ByteBits<247>::COUNT, ByteBits<248>::COUNT,
                                             ByteBits<249>::COUNT, ByteBits<250>::COUNT, ByteBits<251>::COUNT,
                                             ByteBits<252>::COUNT, ByteBits<253>::COUNT, ByteBits<254>::COUNT,
                                             ByteBits<255>::COUNT};

    return table[b];
  }
  ;

  /**
   *  \brief template meta programming struct that gives number of bits in a byte
   *  @TODO Maybe unintuitive and should just use python to generate the entries in the LUT
   */
  template<unsigned char b>
    struct ByteBits
    {
      /**
       * number of bits in the byte given by the template constant
       */
      enum
      {
        COUNT = ((b >> 0) & 1) + ((b >> 1) & 1) + ((b >> 2) & 1) + ((b >> 3) & 1) + ((b >> 4) & 1) + ((b >> 5) & 1)
            + ((b >> 6) & 1) + ((b >> 7) & 1)
      };
    };
};

  /**
 * Hamming distance functor (pop count between two binary vectors, i.e. xor them and count the number of bits set)
 * That code was taken from brief.cpp in OpenCV
 */
template<class T>
  struct Hamming
  {
	typedef False is_kdtree_distance;

    typedef T ElementType;
    typedef typename Accumulator<T>::Type ResultType;

    template<typename Iterator1, typename Iterator2>
      ResultType operator()(Iterator1 a, Iterator2 b, size_t size, ResultType worst_dist = -1) const
      {
        ResultType result = 0;
#if __GNUC__
#if ANDROID && HAVE_NEON
        static uint64_t features = android_getCpuFeatures();
        if ((features & ANDROID_CPU_ARM_FEATURE_NEON))
        {
          for (size_t i = 0; i < size; i += 16)
          {
            uint8x16_t A_vec = vld1q_u8 (a + i);
            uint8x16_t B_vec = vld1q_u8 (b + i);
            //uint8x16_t veorq_u8 (uint8x16_t, uint8x16_t)
            uint8x16_t AxorB = veorq_u8 (A_vec, B_vec);

            uint8x16_t bitsSet += vcntq_u8 (AxorB);
            //uint16x8_t vpadalq_u8 (uint16x8_t, uint8x16_t)
            uint16x8_t bitSet8 = vpaddlq_u8 (bitsSet);
            uint32x4_t bitSet4 = vpaddlq_u16 (bitSet8);

            uint64x2_t bitSet2 = vpaddlq_u32 (bitSet4);
            result += vgetq_lane_u64 (bitSet2,0);
            result += vgetq_lane_u64 (bitSet2,1);
          }
        }
        else
#endif
        //for portability just use unsigned long -- and use the __builtin_popcountll (see docs for __builtin_popcountll)
        typedef unsigned long long pop_t;
        const size_t modulo = size % sizeof(pop_t);
        const pop_t * a2 = reinterpret_cast<const pop_t*> (a);
        const pop_t * b2 = reinterpret_cast<const pop_t*> (b);
        const pop_t * a2_end = a2 + (size / sizeof(pop_t));

        for (; a2 != a2_end; ++a2, ++b2)
          result += __builtin_popcountll((*a2) ^ (*b2));

        if (modulo)
        {
          //in the case where size is not dividable by sizeof(size_t)
          //need to mask off the bits at the end
          pop_t a_final = 0, b_final = 0;
          memcpy(&a_final, a2, modulo);
          memcpy(&b_final, b2, modulo);
          result += __builtin_popcountll(a_final ^ b_final);
        }
#else
        HammingLUT lut;
        result = lut(reinterpret_cast<const unsigned char*> (a),
            reinterpret_cast<const unsigned char*> (b), size * sizeof(pop_t));
#endif
        return result;
      }

    template<typename Iterator>
      ResultType operator()(Iterator a, ZeroIterator<ElementType> b, size_t size, ResultType worst_dist = -1) const
      {
      ResultType result = 0;
#if __GNUC__
#if ANDROID && HAVE_NEON
      static uint64_t features = android_getCpuFeatures();
      if ((features & ANDROID_CPU_ARM_FEATURE_NEON))
      {
        for (size_t i = 0; i < size; i += 16)
        {
          uint8x16_t A_vec = vld1q_u8 (a + i);

          uint8x16_t bitsSet += vcntq_u8 (A_vec);
          //uint16x8_t vpadalq_u8 (uint16x8_t, uint8x16_t)
          uint16x8_t bitSet8 = vpaddlq_u8 (bitsSet);
          uint32x4_t bitSet4 = vpaddlq_u16 (bitSet8)s;

          uint64x2_t bitSet2 = vpaddlq_u32 (bitSet4);
          result += vgetq_lane_u64 (bitSet2,0);
          result += vgetq_lane_u64 (bitSet2,1);
        }
      }
      else
#endif
      //for portability just use unsigned long -- and use the __builtin_popcountll (see docs for __builtin_popcountll)
      typedef unsigned long long pop_t;
      const size_t modulo = size % sizeof(pop_t);
      const pop_t * a2 = reinterpret_cast<const pop_t*> (a);
      const pop_t * a2_end = a2 + (size / sizeof(pop_t));

      for (; a2 != a2_end; ++a2)
        result += __builtin_popcountll(*a2);

        if (modulo)
        {
          //in the case where size is not dividable by sizeof(size_t)
          //need to mask off the bits at the end
          pop_t a_final = 0;
          memcpy(&a_final, a2, modulo);
          result += __builtin_popcountll(a_final);
        }
#else
        result = HammingLUT()(reinterpret_cast<const unsigned char*> (a), size * sizeof(pop_t));
#endif
        return result;
      }
  };

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

template<class T>
struct HistIntersectionDistance
{
	typedef True is_kdtree_distance;

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
	typedef True is_kdtree_distance;

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
	typedef True is_kdtree_distance;

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
	typedef True is_kdtree_distance;

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

    const ZeroIterator<T>& operator ++()
    {
        return *this;
    }

    ZeroIterator<T> operator ++(int)
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
