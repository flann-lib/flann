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

#ifndef GENERAL_H
#define GENERAL_H

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



#define ARRAY_LEN(a) (sizeof(a)/sizeof(a[0]))

/* Nearest neighbour index algorithms */
enum flann_algorithm_t
{
    FLANN_INDEX_LINEAR = 0,
    FLANN_INDEX_KDTREE = 1,
    FLANN_INDEX_KMEANS = 2,
    FLANN_INDEX_COMPOSITE = 3,
    FLANN_INDEX_KDTREE_SINGLE = 4,
    FLANN_INDEX_HIERARCHICAL = 5,
    FLANN_INDEX_SAVED = 254,
    FLANN_INDEX_AUTOTUNED = 255,

    // deprecated constants, should use the FLANN_INDEX_* ones instead
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
};

enum flann_distance_t
{
    FLANN_DIST_EUCLIDEAN = 1,
    FLANN_DIST_L2 = 1,
    FLANN_DIST_MANHATTAN = 2,
    FLANN_DIST_L1 = 2,
    FLANN_DIST_MINKOWSKI = 3,
    FLANN_DIST_MAX   = 4,
    FLANN_DIST_HIST_INTERSECT   = 5,
    FLANN_DIST_HELLINGER = 6,
    FLANN_DIST_CHI_SQUARE = 7,
    FLANN_DIST_CS         = 7,
    FLANN_DIST_KULLBACK_LEIBLER  = 8,
    FLANN_DIST_KL                = 8,

    // deprecated constants, should use the FLANN_DIST_* ones instead
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

enum flann_datatype_t
{
    FLANN_INT8 = 0,
    FLANN_INT16 = 1,
    FLANN_INT32 = 2,
    FLANN_INT64 = 3,
    FLANN_UINT8 = 4,
    FLANN_UINT16 = 5,
    FLANN_UINT32 = 6,
    FLANN_UINT64 = 7,
    FLANN_FLOAT32 = 8,
    FLANN_FLOAT64 = 9
};

const int FLANN_CHECKS_UNLIMITED = -1;
const int FLANN_CHECKS_AUTOTUNED = -2;


struct FLANNParameters
{
    enum flann_algorithm_t algorithm; /* the algorithm to use */

    /* search time parameters */
    int checks;                /* how many leafs (features) to check in one search */
    float cb_index;            /* cluster boundary index. Used when searching the kmeans tree */
    float eps;     /* eps parameter for eps-knn search */

    /*  kdtree index parameters */
    int trees;                 /* number of randomized trees to use (for kdtree) */
    int leaf_max_size;

    /* kmeans index parameters */
    int branching;             /* branching factor (for kmeans tree) */
    int iterations;            /* max iterations to perform in one kmeans cluetering (kmeans tree) */
    enum flann_centers_init_t centers_init;  /* algorithm used for picking the initial cluster centers for kmeans tree */

    /* autotuned index parameters */
    float target_precision;    /* precision desired (used for autotuning, -1 otherwise) */
    float build_weight;        /* build tree time weighting factor */
    float memory_weight;       /* index memory weigthing factor */
    float sample_fraction;     /* what fraction of the dataset to use for autotuning */

    /* other parameters */
    enum flann_log_level_t log_level;    /* determines the verbosity of each flann function */
    long random_seed;            /* random seed to use */
};



#ifdef __cplusplus

#include <stdexcept>
#include <cassert>

namespace flann
{

class FLANNException : public std::runtime_error
{
public:
    FLANNException(const char* message) : std::runtime_error(message) { }

    FLANNException(const std::string& message) : std::runtime_error(message) { }
};


struct IndexParams
{
protected:
    IndexParams(flann_algorithm_t algorithm_) : algorithm(algorithm_) {}

public:
    FLANN_EXPORT static IndexParams* createFromParameters(const FLANNParameters& p);

    virtual flann_algorithm_t getIndexType() const
    {
        return algorithm;
    }

    virtual ~IndexParams() {};

    virtual void fromParameters(const FLANNParameters& p) = 0;
    virtual void toParameters(FLANNParameters& p) const = 0;

    virtual void print() const = 0;

    flann_algorithm_t algorithm;
};


struct SearchParams
{
    SearchParams(int checks_ = 32, float eps_ = 0, bool sorted_ = true ) :
        checks(checks_), eps(eps_), sorted(sorted_) {}

    int checks;  // how many leafs to visit when searching for neighbours (-1 for unlimited)
    float eps;  // search for eps-approximate neighbours (default: 0)
    bool sorted; // only for radius search, require neighbours sorted by distance (default: true)
};

}

#endif

#endif  /* GENERAL_H */
