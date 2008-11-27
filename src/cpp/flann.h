#ifndef FLANN_H
#define FLANN_H


#include "constants.h"


struct IndexParameters {
	int algorithm;
	int checks;
    float cb_index;
	int trees;
	int branching;
	int iterations;
	int centers_init;
	float target_precision;
	float build_weight;
	float memory_weight;
    float sample_fraction;
};


struct FLANNParameters {
	int log_level;
	char* log_destination;
	long random_seed;
};


typedef void* FLANN_INDEX;

#ifdef __cplusplus
extern "C" {
#endif

void flann_log_verbosity(int level);

void flann_log_destination(char* destination);

FLANN_INDEX flann_build_index(float* dataset, int rows, int cols, float* speedup, struct IndexParameters* index_params, struct FLANNParameters* flann_params);

int flann_find_nearest_neighbors(float* dataset, int count, int length, float* testset, int tcount, int* result, int nn, struct IndexParameters* index_params, struct FLANNParameters* flann_params);

int flann_find_nearest_neighbors_index(FLANN_INDEX index_id, float* testset, int tcount, int* result, int nn, int checks, struct FLANNParameters* flann_params);

void flann_free_index(FLANN_INDEX index_id, struct FLANNParameters* flann_params);

int flann_compute_cluster_centers(float* dataset, int count, int length, int clusters, float* result, struct IndexParameters* index_params, struct FLANNParameters* flann_params);


#ifdef __cplusplus
}
#endif


#endif /*FLANN_H*/
