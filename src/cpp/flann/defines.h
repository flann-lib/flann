/***********************************************************************
 * Software License Agreement (BSD License)
 *
 * Copyright 2008-2011  Marius Muja (mariusm@cs.ubc.ca). All rights reserved.
 * Copyright 2008-2011  David G. Lowe (lowe@cs.ubc.ca). All rights reserved.
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

#ifndef FLANN_DEFINES_H_
#define FLANN_DEFINES_H_

#include "config.h"

#ifdef FLANN_EXPORT
#undef FLANN_EXPORT
#endif
#ifdef WIN32
/* win32 dll export/import directives */
 #ifdef FLANN_EXPORTS
  #define FLANN_EXPORT __declspec(dllexport)
 #elif defined(FLANN_STATIC)
  #define FLANN_EXPORT
 #else
  #define FLANN_EXPORT __declspec(dllimport)
 #endif
#else
/* unix needs nothing */
 #define FLANN_EXPORT
#endif

#ifdef FLANN_DEPRECATED
#undef FLANN_DEPRECATED
#endif
#ifdef __GNUC__
#define FLANN_DEPRECATED __attribute__ ((deprecated))
#elif defined(_MSC_VER)
#define FLANN_DEPRECATED __declspec(deprecated)
#else
#pragma message("WARNING: You need to implement FLANN_DEPRECATED for this compiler")
#define FLANN_DEPRECATED
#endif

#undef FLANN_PLATFORM_64_BIT
#undef FLANN_PLATFORM_32_BIT
#if __amd64__ || __x86_64__ || _WIN64 || _M_X64
#define FLANN_PLATFORM_64_BIT
#else
#define FLANN_PLATFORM_32_BIT
#endif

#undef FLANN_ARRAY_LEN
#define FLANN_ARRAY_LEN(a) (sizeof(a)/sizeof(a[0]))

#ifdef __cplusplus
namespace flann {
#endif

#ifndef FLANN_INDEXES
#ifdef FLANN_USE_CUDA
#define FLANN_INDEXES(X) \
	X(LINEAR,LinearIndex,0) \
	X(KDTREE,KDTreeIndex,1) \
	X(KMEANS,KMeansIndex,2) \
	X(COMPOSITE,CompositeIndex,3) \
	X(KDTREE_SINGLE,KDTreeSingleIndex,4) \
	X(HIERARCHICAL,HierarchicalClusteringIndex,5) \
	X(LSH,LshIndex,6) \
	X(KDTREE_CUDA,KDTreeCuda3dIndex,7) \
	X(AUTOTUNED,AutotunedIndex,255)
#else
#define FLANN_INDEXES(X) \
	X(LINEAR,LinearIndex,0) \
	X(KDTREE,KDTreeIndex,1) \
	X(KMEANS,KMeansIndex,2) \
	X(COMPOSITE,CompositeIndex,3) \
	X(KDTREE_SINGLE,KDTreeSingleIndex,4) \
	X(HIERARCHICAL,HierarchicalClusteringIndex,5) \
	X(LSH,LshIndex,6) \
	X(AUTOTUNED,AutotunedIndex,255)
#endif
#endif


#define FLANN_INDEX_ENUM(name,_,num) FLANN_INDEX_##name = num,
/* Nearest neighbour index algorithms */
enum flann_algorithm_t
{
	FLANN_INDEXES(FLANN_INDEX_ENUM)

	FLANN_INDEX_SAVED = 254,

	// the above X-Macro trick expands to:
	//	FLANN_INDEX_LINEAR = 0,
	//	FLANN_INDEX_KDTREE = 1,
	//	FLANN_INDEX_KMEANS = 2,
	//	FLANN_INDEX_COMPOSITE = 3,
	//	FLANN_INDEX_KDTREE_SINGLE = 4,
	//	FLANN_INDEX_HIERARCHICAL = 5,
	//	FLANN_INDEX_LSH = 6,
//		FLANN_INDEX_KDTREE_CUDA = 7,
// 		FLANN_INDEX_AUTOTUNED = 255,

};

enum flann_centers_init_t
{
    FLANN_CENTERS_RANDOM = 0,
    FLANN_CENTERS_GONZALES = 1,
    FLANN_CENTERS_KMEANSPP = 2,
};

enum flann_log_level_t
{
    FLANN_LOG_NONE = 0,
    FLANN_LOG_FATAL = 1,
    FLANN_LOG_ERROR = 2,
    FLANN_LOG_WARN = 3,
    FLANN_LOG_INFO = 4,
    FLANN_LOG_DEBUG = 5
};


#ifndef FLANN_DISTANCES
#define FLANN_DISTANCES(X) \
	X(L2,L2,1) \
	X(L1,L1,2) \
    X(MINKOWSKI,MinkowskiDistance,3) \
	X(MAX,MaxDistance,4) \
	X(HIST_INTERSECT,HistIntersectionDistance,5) \
	X(HELLINGER,HellingerDistance,6) \
	X(CHI_SQUARE,ChiSquareDistance,7) \
	X(KULLBACK_LEIBLER,KL_Divergence,8) \
	X(HAMMING,Hamming,9) \
	X(HAMMING_LUT,HammingLUT,10) \
	X(HAMMING_POPCNT,HammingPopcnt,11) \
	X(L2_SIMPLE,L2_Simple,12)
#endif


#define FLANN_DISTANCE_ENUM(name,_,num) FLANN_DIST_##name = num,
enum flann_distance_t
{
	FLANN_DISTANCES(FLANN_DISTANCE_ENUM)
	// duplicate distance constants
    FLANN_DIST_EUCLIDEAN = 1,
    FLANN_DIST_MANHATTAN = 2,
};

#ifndef FLANN_DATATYPES
#define FLANN_DATATYPES(X) \
	X(NONE, void,-1) \
	X(INT8, char,0) \
	X(INT16, short int,1) \
	X(INT32, int,2) \
	X(INT64, long int,3) \
	X(UINT8, unsigned char,4) \
	X(UINT16, unsigned short int,5) \
	X(UINT32, unsigned int,6) \
	X(UINT64, unsigned long int,7) \
	X(FLOAT32, float,8) \
	X(FLOAT64, double,9)
#endif


#define FLANN_DATATYPE_ENUM(name,_,value) FLANN_##name = value,
enum flann_datatype_t
{
	FLANN_DATATYPES(FLANN_DATATYPE_ENUM)
};

enum flann_checks_t {
    FLANN_CHECKS_UNLIMITED = -1,
    FLANN_CHECKS_AUTOTUNED = -2,
};

#ifdef __cplusplus
}
#endif


#endif /* FLANN_DEFINES_H_ */
