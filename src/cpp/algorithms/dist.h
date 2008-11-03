/************************************************************************
 * Distance functions
 *
 * This module contains the distance computations used in the library.
 * For now just the stantard euclidian distance (L_2 norm) is used.
 * 
 * Authors: David Lowe, lowe@cs.ubc.ca
            Marius Muja, mariusm@cs.ubc.ca
 * 
 * Version: 1.0
 * 
 * History:
 * 
 * License: LGPL
 * 
 *************************************************************************/

#ifndef DIST_H
#define DIST_H



/**
 *  Compute the squared distance between two vectors. 
 *
 *	This is highly optimized, with loop unrolling, as it is one
 *	of the most expensive inner loops.
 */
template <typename T, typename U>
double squared_dist(T* a, U* b, int length) 
{
	double distsq = 0.0;
	double diff0, diff1, diff2, diff3;
	T* v1 = a;
	U* v2 = b;
	
	T* final_ = v1 + length;
	T* finalgroup = final_ - 3;

	/* Process 4 items with each loop for efficiency. */
	while (v1 < finalgroup) {
		diff0 = v1[0] - v2[0];	
		diff1 = v1[1] - v2[1];
		diff2 = v1[2] - v2[2];
		diff3 = v1[3] - v2[3];
		distsq += diff0 * diff0 + diff1 * diff1 + diff2 * diff2 + diff3 * diff3;
		v1 += 4;
		v2 += 4;
	}
	/* Process last 0-3 pixels.  Not needed for standard vector lengths. */
	while (v1 < final_) {
		diff0 = *v1++ - *v2++;
		distsq += diff0 * diff0;
	}
	return distsq;
}

/**
 *  Compute the squared distance between one vector and the origin.
 *
 */
template <typename T>
double squared_dist(T* a, int length) 
{
	
	double distsq = 0.0;
	double diff0, diff1, diff2, diff3;
	T* v1 = a;
	
	T* final_ = v1 + length;
	T* finalgroup = final_ - 3;

	/* Process 4 items with each loop for efficiency. */
	while (v1 < finalgroup) {
		diff0 = v1[0];
		diff1 = v1[1];
		diff2 = v1[2];
		diff3 = v1[3];
		distsq += diff0 * diff0 + diff1 * diff1 + diff2 * diff2 + diff3 * diff3;
		v1 += 4;
	}
	/* Process last 0-3 items.  Not needed for standard vector lengths. */
	while (v1 < final_) {
		diff0 = *v1++;
		distsq += diff0 * diff0;
	}
	return distsq;
}

#endif //DIST_H
