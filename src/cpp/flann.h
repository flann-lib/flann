#ifndef FLANN_H
#define FLANN_H


#include "constants.h"


#ifdef WIN32
/* win32 dll export/import directives */
#ifdef flann_EXPORTS
#define LIBSPEC __declspec(dllexport)
#else
#define LIBSPEC __declspec(dllimport)
#endif
#else
/* unix needs nothing */
#define LIBSPEC
#endif


struct IndexParameters {
	int algorithm;             // the algorithm to use (see constants.h)
	int checks;                // how many leafs (features) to check in one search
    float cb_index;            // cluster boundary index. Used when searching the kmeans tree
	int trees;                 // number of randomized trees to use (for kdtree)
	int branching;             // branching factor (for kmeans tree)
	int iterations;            // max iterations to perform in one kmeans cluetering (kmeans tree)
	int centers_init;          // algorithm used for picking the initial cluetr centers for kmeans tree
	float target_precision;    // precision desired (used for autotuning, -1 otherwise)
	float build_weight;        // build tree time weighting factor
	float memory_weight;       // index memory weigthing factor
    float sample_fraction;     // what fraction of the dataset to use for autotuning
};


/**
    Generic parameters
*/
struct FLANNParameters {
	int log_level;             // determines the verbosity of each flann function
	char* log_destination;     // file where the output should go, NULL for the console
	long random_seed;          // random seed to use
};


typedef void* FLANN_INDEX;

#ifdef __cplusplus
extern "C" {
#endif

/**
Sets the log level used for all flann functions (unless 
specified in FLANNParameters for each call

Params:
    level = verbosity level (defined in constants.h)
*/
LIBSPEC void flann_log_verbosity(int level);

/**
Configures where the log output should go

Params:
    destination = destination file, NULL for console
*/
LIBSPEC void flann_log_destination(char* destination);

/**
Builds and returns an index. It uses autotuning if the target_precision field of index_params
is between 0 and 1, or the parameters specified if it's -1.

Params:
    dataset = pointer to a data set stored in row major order
    rows = number of rows (features) in the dataset
    cols = number of columns in the dataset (feature dimensionality)
    speedup = speedup over linear search, estimated if using autotuning, output parameter
    index_params = index related parameters
    flann_params = generic flann parameters

Returns: the newly created index or a number <0 for error
*/
LIBSPEC FLANN_INDEX flann_build_index(float* dataset, int rows, int cols, float* speedup, struct IndexParameters* index_params, struct FLANNParameters* flann_params);


/**
Builds an index and uses it to find nearest neighbors.

Params:
    dataset = pointer to a data set stored in row major order
    rows = number of rows (features) in the dataset
    cols = number of columns in the dataset (feature dimensionality)
    testset = pointer to a query set stored in row major order
    trows = number of rows (features) in the query dataset (same dimensionality as features in the dataset)
    result = pointer to matrix for the indices of the nearest neighbors of the testset features in the dataset
            (must have trows number of rows and nn number of columns)
    nn = how many nearest neighbors to return
    index_params = index related parameters
    flann_params = generic flann parameters

Returns: zero or NULL for error    
*/
LIBSPEC int flann_find_nearest_neighbors(float* dataset, int rows, int cols, float* testset, int trows, int* result, int nn, struct IndexParameters* index_params, struct FLANNParameters* flann_params);

/**
Searches for nearest neighbors using the index provided 

Params:
    index_id = the index (constructed previously using flann_build_index).
    testset = pointer to a query set stored in row major order
    trows = number of rows (features) in the query dataset (same dimensionality as features in the dataset)
    result = pointer to matrix for the indices of the nearest neighbors of the testset features in the dataset
            (must have trows number of rows and nn number of columns)
    nn = how many nearest neighbors to return
    checks = number of checks to perform before the search is stopped
    flann_params = generic flann parameters

Returns: zero or a number <0 for error
*/
LIBSPEC int flann_find_nearest_neighbors_index(FLANN_INDEX index_id, float* testset, int trows, int* result, int nn, int checks, struct FLANNParameters* flann_params);

/**
Deletes an index and releases the memory used by it.

Params:
    index_id = the index (constructed previously using flann_build_index).
    flann_params = generic flann parameters

Returns: zero or a number <0 for error
*/
LIBSPEC int flann_free_index(FLANN_INDEX index_id, struct FLANNParameters* flann_params);

/**
Clusters the features in the dataset using a hierarchical kmeans clustering approach.
This is significantly faster than using a flat kmeans clustering for a large number
of clusters.

Params:
    dataset = pointer to a data set stored in row major order
    rows = number of rows (features) in the dataset
    cols = number of columns in the dataset (feature dimensionality)
    clusters = number of cluster to compute
    result = memory buffer where the output cluster centers are storred
    index_params = used to specify the kmeans tree parameters (branching factor, max number of iterations to use)
    flann_params = generic flann parameters
    
Returns: number of clusters computed or a number <0 for error. This number can be different than the number of clusters requested, due to the 
    way hierarchical clusters are computed. The number of clusters returned will be the highest number of the form
    (branch_size-1)*K+1 smaller than the number of clusters requested.
*/

LIBSPEC int flann_compute_cluster_centers(float* dataset, int rows, int cols, int clusters, float* result, struct IndexParameters* index_params, struct FLANNParameters* flann_params);


#ifdef __cplusplus
}
#endif


#endif /*FLANN_H*/
