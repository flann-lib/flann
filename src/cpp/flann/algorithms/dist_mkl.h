#ifndef FLANN_DIST_MKL_H_
#define FLANN_DIST_MKL_H_

/**
 *  Compute the squared Euclidean distance between two vectors.
 *
 *	This is highly optimised, USING MKL
 *
 *	The computation of squared root at the end is omitted for
 *	efficiency.
 */


#include "flann/algorithms/dist.h"
#include "mkl.h"
namespace flann
{
    template<class T>
    struct L2_MKL
    {
        typedef bool is_kdtree_distance;

        typedef T ElementType;
        typedef typename Accumulator<T>::Type ResultType;

        template <typename Iterator1, typename Iterator2>
        ResultType operator()(Iterator1 a, Iterator2 b, size_t size, ResultType worst_dist = -1) const
        {
            ResultType result = ResultType();
            ResultType diff0, diff1, diff2, diff3;
            Iterator1 last = a + size;
            Iterator1 lastgroup = last - 3;

            /* Process 4 items with each loop for efficiency. */
            while (a < lastgroup) {
                diff0 = (ResultType)(a[0] - b[0]);
                diff1 = (ResultType)(a[1] - b[1]);
                diff2 = (ResultType)(a[2] - b[2]);
                diff3 = (ResultType)(a[3] - b[3]);
                result += diff0 * diff0 + diff1 * diff1 + diff2 * diff2 + diff3 * diff3;
                a += 4;
                b += 4;

                if ((worst_dist>0)&&(result>worst_dist)) {
                    return result;
                }
            }
            /* Process last 0-3 pixels.  Not needed for standard vector lengths. */
            while (a < last) {
                diff0 = (ResultType)(*a++ - *b++);
                result += diff0 * diff0;
            }
            return result;
        }
    };
    
    template<>
    struct L2_MKL<double>
    {
        typedef bool is_kdtree_distance;

        typedef double ElementType;
        typedef Accumulator<double>::Type ResultType;

        //template <typename Iterator1, typename Iterator2>
        //ResultType operator()(Iterator1 a, Iterator2 b, size_t size, ResultType /*worst_dist = -1*/) const
        //{
//            return cblas_ddot(size, (const double*)a, 1, (const double*)b, 1);
//        }
        ResultType operator()(double* const& a, double* const& b, size_t size, ResultType /*worst_dist = -1*/) const
        {
            return cblas_ddot(size, a, 1, b, 1);
        }
    };
    
    template<>
    struct L2_MKL<float>
    {
        typedef bool is_kdtree_distance;

        typedef float ElementType;
        typedef Accumulator<float>::Type ResultType;

        template <typename Iterator1, typename Iterator2>
        ResultType operator()(Iterator1 a, Iterator2 b, size_t size, ResultType /*worst_dist = -1*/) const
        {
            return cblas_sdot(size, (const float*)a, 1, (const float*)b, 1);
        }
    };
   
}

#endif
