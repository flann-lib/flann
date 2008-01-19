#ifndef NN_H
#define NN_H



enum Algorithm {
	LINEAR=0,
	KDTREE,
	KMEANS,
	COMPOSITE
};

struct Parameters {
	Algorithm algo;
	int checks;
	int trees;
	int branching;
	int iterations;
};


typedef int NN_INDEX;

#ifdef __cplusplus
extern "C" {
#endif

void nn_init();

void nn_term();

Parameters estimate_index_parameters(float* dataset, int count, int length, float target_precision);

NN_INDEX build_index(float* dataset, int count, int length, float target_precision, Parameters* parameters);

void find_nearest_neighbors(float* dataset, int count, int length, float* testset, int tcount, int* result, int nn, float target_precision, Parameters* parameters);

void find_nearest_neighbors_index(NN_INDEX index_id, float* testset, int tcount, int* result, int nn, float target_precision, int checks);

void free_index(NN_INDEX indexID);



#ifdef __cplusplus
}
#endif


#endif // NN_H
