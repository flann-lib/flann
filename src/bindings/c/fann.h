#ifndef NN_H
#define NN_H


/* Nearest neighbor index algorithms */
const int LINEAR 	= 0;
const int KDTREE 	= 1;
const int KMEANS 	= 2;
const int COMPOSITE = 3;



const int LOG_NONE	= 0;
const int LOG_FATAL	= 1;
const int LOG_ERROR	= 2;
const int LOG_WARN	= 3;
const int LOG_INFO	= 4;


struct Parameters {
	int algorithm;
	int checks;
	int trees;
	int branching;
	int iterations;
	float target_precision;
	float speedup;
};



typedef int FANN_INDEX;

#ifdef __cplusplus
extern "C" {
#endif

void fann_init();

void fann_term();

void fann_log_verbosity(int level);

void fann_log_destination(char* destination);

FANN_INDEX fann_build_index(float* dataset, int rows, int cols, Parameters* parameters);

void fann_find_nearest_neighbors(float* dataset, int rows, int cols, float* testset, int tcount, int* result, int nn, Parameters* parameters);

void fann_find_nearest_neighbors_index(FANN_INDEX index_id, float* testset, int tcount, int* result, int nn, int checks);

void fann_free_index(FANN_INDEX index_id);

int fann_compute_cluster_centers(float* dataset, int rows, int cols, int clusters, float* result, Parameters* parameters);

#ifdef __cplusplus
}
#endif


#endif /* NN_H */
