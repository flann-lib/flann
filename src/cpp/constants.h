#ifndef CONSTANTS_H
#define CONSTANTS_H


/* Nearest neighbour index algorithms */
enum flann_algorithm_t {
	LINEAR = 0,
	KDTREE = 1,
	KMEANS = 2,
	COMPOSITE = 3,
    VPTREE = 4,
    BFSEARCH = 5
};

enum flann_centers_init_t {
	CENTERS_RANDOM = 0,
	CENTERS_GONZALES = 1,
	CENTERS_KMEANSPP = 2
};


enum flann_log_level_t {
	LOG_NONE = 0,
	LOG_FATAL = 1,
	LOG_ERROR = 2,
	LOG_WARN = 3,
	LOG_INFO = 4
};

enum flann_distance_t {
	EUCLIDEAN = 1,
	MANHATTAN = 2,
	MINKOWSKI = 3
};

#endif  // CONSTANTS_H
