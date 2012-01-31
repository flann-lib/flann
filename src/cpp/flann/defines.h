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
#define FLANN_INDEXES \
	FLANN_INDEX(LINEAR,LinearIndex,0) \
	FLANN_INDEX(KDTREE,KDTreeIndex,1) \
	FLANN_INDEX(KMEANS,KMeansIndex,2) \
	FLANN_INDEX(COMPOSITE,CompositeIndex,3) \
	FLANN_INDEX(KDTREE_SINGLE,KDTreeSingleIndex,4) \
	FLANN_INDEX(HIERARCHICAL,HierarchicalClusteringIndex,5) \
	FLANN_INDEX(LSH,LshIndex,6) \
	FLANN_INDEX(KDTREE_CUDA,KDTreeCuda3dIndex,7) \
	FLANN_INDEX(AUTOTUNED,AutotunedIndex,255)
#endif




/* Nearest neighbour index algorithms */
enum flann_algorithm_t
{
#undef FLANN_INDEX
#define FLANN_INDEX(name,index,num) FLANN_INDEX_##name = num,
	FLANN_INDEXES
#undef FLANN_INDEX
	FLANN_INDEX_SAVED = 254,

	// the above X-Macro trick expands to:
	//	FLANN_INDEX_LINEAR = 0,
	//	FLANN_INDEX_KDTREE = 1,
	//	FLANN_INDEX_KMEANS = 2,
	//	FLANN_INDEX_COMPOSITE = 3,
	//	FLANN_INDEX_KDTREE_SINGLE = 4,
	//	FLANN_INDEX_HIERARCHICAL = 5,
	//	FLANN_INDEX_LSH = 6,
	//	FLANN_INDEX_KDTREE_CUDA = 7,
	//	FLANN_INDEX_AUTOTUNED = 255,

	// deprecated, provided for backwards compatibility
    LINEAR = 0,
    KDTREE = 1,
    KMEANS = 2,
    COMPOSITE = 3,
    KDTREE_SINGLE = 4,
    SAVED = 254,
    AUTOTUNED = 255
};



enum flann_centers_init_t
{
    FLANN_CENTERS_RANDOM = 0,
    FLANN_CENTERS_GONZALES = 1,
    FLANN_CENTERS_KMEANSPP = 2,

    // deprecated constants, should use the FLANN_CENTERS_* ones instead
    CENTERS_RANDOM = 0,
    CENTERS_GONZALES = 1,
    CENTERS_KMEANSPP = 2
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


//FLANN_DISTANCE(MINKOWSKI,MinkowskiDistance,3)
#ifndef FLANN_DISTANCES
#define FLANN_DISTANCES \
	FLANN_DISTANCE(L2,L2,1) \
	FLANN_DISTANCE(L1,L1,2) \
	FLANN_DISTANCE(MAX,MaxDistance,4) \
	FLANN_DISTANCE(HIST_INTERSECT,HistIntersectionDistance,5) \
	FLANN_DISTANCE(HELLINGER,HellingerDistance,6) \
	FLANN_DISTANCE(CHI_SQUARE,ChiSquareDistance,7) \
	FLANN_DISTANCE(KULLBACK_LEIBLER,KL_Divergence,8) \
	FLANN_DISTANCE(HAMMING,Hamming,9) \
	FLANN_DISTANCE(HAMMING_LUT,HammingLUT,10) \
	FLANN_DISTANCE(HAMMING_POPCNT,HammingPopcnt,11) \
	FLANN_DISTANCE(L2_SIMPLE,L2_Simple,12)
#endif


enum flann_distance_t
{
	// X-Macro trick
#undef FLANN_DISTANCE
#define FLANN_DISTANCE(name,distance,num) FLANN_DIST_##name = num,
	FLANN_DISTANCES
#undef FLANN_DISTANCE
	// duplicate distance constants
    FLANN_DIST_EUCLIDEAN = 1,
    FLANN_DIST_MANHATTAN = 2,

    // deprecated constants, use the FLANN_DIST_* ones instead
    EUCLIDEAN = 1,
    MANHATTAN = 2,
    MINKOWSKI = 3,
    MAX_DIST   = 4,
    HIST_INTERSECT   = 5,
    HELLINGER = 6,
    CS         = 7,
    KL         = 8,
    KULLBACK_LEIBLER  = 8
};

#ifndef FLANN_DATATYPES
#define FLANN_DATATYPES \
	FLANN_DATATYPE(NONE, void,-1) \
	FLANN_DATATYPE(INT8, char,0) \
	FLANN_DATATYPE(INT16, short int,1) \
	FLANN_DATATYPE(INT32, int,2) \
	FLANN_DATATYPE(INT64, long int,3) \
	FLANN_DATATYPE(UINT8, unsigned char,4) \
	FLANN_DATATYPE(UINT16, unsigned short int,5) \
	FLANN_DATATYPE(UINT32, unsigned int,6) \
	FLANN_DATATYPE(UINT64, unsigned long int,7) \
	FLANN_DATATYPE(FLOAT32, float,8) \
	FLANN_DATATYPE(FLOAT64, double,9)
#endif


enum flann_datatype_t
{
#undef FLANN_DATATYPE
#define FLANN_DATATYPE(name,type,value) FLANN_##name = value,
	FLANN_DATATYPES
#undef FLANN_DATATYPE
};

enum flann_checks_t {
    FLANN_CHECKS_UNLIMITED = -1,
    FLANN_CHECKS_AUTOTUNED = -2,
};

#ifdef __cplusplus
}
#endif


#endif /* FLANN_DEFINES_H_ */
