#ifndef NN_H
#define NN_H


/* Nearest neighbor index algorithms */
const int LINEAR 	= 0;
const int KDTREE 	= 1;
const int KMEANS 	= 2;
const int COMPOSITE = 3;

const int CENTERS_RANDOM = 0;
const int CENTERS_GONZALES = 1;
const int CENTERS_KMEANSPP = 2;


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
	float build_weight;
	float memory_weight;
};

struct FLANNParameters {
	int log_level;
	char* log_destination;
	long random_seed;
};


typedef int FLANN_INDEX;

#ifdef __cplusplus
extern "C" {
#endif

void flann_init();

void flann_term();

void flann_log_verbosity(int level);

void flann_log_destination(char* destination);

FLANN_INDEX flann_build_index(float* dataset, int rows, int cols, float* speedup, IndexParameters* index_params, FLANNParameters* flann_params);

int flann_find_nearest_neighbors(float* dataset, int count, int length, float* testset, int tcount, int* result, int nn, IndexParameters* index_params, FLANNParameters* flann_params);

int flann_find_nearest_neighbors_index(FLANN_INDEX index_id, float* testset, int tcount, int* result, int nn, int checks, FLANNParameters* flann_params);

void flann_free_index(FLANN_INDEX index_id, FLANNParameters* flann_params);

int flann_compute_cluster_centers(float* dataset, int count, int length, int clusters, float* result, IndexParameters* index_params, FLANNParameters* flann_params);







struct KMeansNodeSt {
        /**
         * The cluster center.
         */
        struct {
            int length;
            float* ptr;
        } pivot;
        /**
         * The cluster radius.
         */
        float radius;
        /**
         * The cluster mean radius.
         */
        float mean_radius;
        /**
         * The cluster variance.
         */
        float variance;
        /**
         * The cluster size (number of points in the cluster)
         */
        int size;
        /**
         * Child nodes (only for non-terminal nodes)
         */
        struct {
            int ptr;
            KMeansNode* ptr;
        } childs;
        /**
         * Node points (only for terminal nodes)
         */
        struct {
            int length;
            int* ptr;
        } indices;
        /**
         * Level
         */
        int level;
}
typedef KMeansNodeSt* KMeansNode;

KMeansNode get_kmeans_hierarchical_tree(FLANN_INDEX index_id)









#ifdef __cplusplus
}
#endif


#endif /* NN_H */
