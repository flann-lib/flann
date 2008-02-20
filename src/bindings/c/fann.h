#ifndef NN_H
#define NN_H



enum Algorithm {
	LINEAR=0,
	KDTREE,
	KMEANS,
	COMPOSITE
};

struct Parameters {
	Algorithm algorithm;
	int checks;
	int trees;
	int branching;
	int iterations;
	float target_precision;
	float speedup;
};


typedef int NN_INDEX;

#ifdef __cplusplus
extern "C" {
#endif

void nn_init();

void nn_term();

NN_INDEX build_index(float* dataset, int rows, int cols, Parameters* parameters);

void find_nearest_neighbors(float* dataset, int rows, int cols, float* testset, int tcount, int* result, int nn, Parameters* parameters);

void find_nearest_neighbors_index(NN_INDEX index_id, float* testset, int tcount, int* result, int nn, int checks);

void free_index(NN_INDEX index_id);

int compute_cluster_centers(float* dataset, int rows, int cols, int clusters, float* result, Parameters* parameters);

#ifdef __cplusplus
}
#endif


#endif /* NN_H */
