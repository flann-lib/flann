#ifndef NN_H
#define NN_H


/* Nearest neighbor index algorithms */
const int LINEAR 	= 0;
const int KDTREE 	= 1;
const int KMEANS 	= 2;
const int COMPOSITE = 3;

const int CENTERS_RANDOM = 0;
const int CENTERS_GONZALES = 1;

const int LOG_NONE	= 0;
const int LOG_FATAL	= 1;
const int LOG_ERROR	= 2;
const int LOG_WARN	= 3;
const int LOG_INFO	= 4;


struct IndexParameters {
	int algorithm;
	int checks;
	int trees;
	int branching;
	int iterations;
	int centers_init;
	float target_precision;
};

struct FANNParameters {
	int log_level;
	char* log_destination;
	long random_seed;
};


typedef int FANN_INDEX;

#ifdef __cplusplus
extern "C" {
#endif

void fann_init();

void fann_term();

FANN_INDEX fann_build_index(float* dataset, int rows, int cols, float* speedup, IndexParameters* index_params, FANNParameters* fann_params);

int fann_find_nearest_neighbors(float* dataset, int count, int length, float* testset, int tcount, int* result, int nn, IndexParameters* index_params, FANNParameters* fann_params);

int fann_find_nearest_neighbors_index(FANN_INDEX index_id, float* testset, int tcount, int* result, int nn, int checks, FANNParameters* fann_params);

void fann_free_index(FANN_INDEX index_id, FANNParameters* fann_params);

int fann_compute_cluster_centers(float* dataset, int count, int length, int clusters, float* result, IndexParameters* index_params, FANNParameters* fann_params);

#ifdef __cplusplus
}
#endif


#endif /* NN_H */
