#include "dist.h"

/** Global variable indicating the distance metric
 * to be used.
 */
flann_distance_t flann_distance_type = EUCLIDEAN;

/**
 * Zero iterator that emulates a zero feature.
 */
ZeroIterator<float> zero;

/**
 * Order of Minkowski distance to use.
 */
int flann_minkowski_order;
