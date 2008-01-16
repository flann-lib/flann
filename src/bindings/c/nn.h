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

#ifdef __cplusplus
extern "C" {
#endif

void nn_init();

void nn_term();

void find_nearest_neighbors(float* dataset, int count, int length, float* testset, int tcount, int* result, int nn, float target_precision, Parameters* parameters);

#ifdef __cplusplus
}
#endif


#endif // NN_H
