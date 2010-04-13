/***********************************************************************
 * Software License Agreement (BSD License)
 *
 * Copyright 2008-2009  Marius Muja (mariusm@cs.ubc.ca). All rights reserved.
 * Copyright 2008-2009  David G. Lowe (lowe@cs.ubc.ca). All rights reserved.
 *
 * THE BSD LICENSE
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *************************************************************************/

#include "flann/algorithms/dist.h"

#include <cstdio>

namespace flann
{

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

template <>
double euclidean_dist(unsigned char* first1, unsigned char* last1, unsigned char* first2, double acc)
{
	printf("byte\n");
	int distsq = acc;
	int diff0, diff1, diff2, diff3;
	unsigned char* lastgroup = last1 - 3;

	/* Process 4 items with each loop for efficiency. */
	while (first1 < lastgroup) {
		diff0 = first1[0] - first2[0];
		diff1 = first1[1] - first2[1];
		diff2 = first1[2] - first2[2];
		diff3 = first1[3] - first2[3];
		distsq += diff0 * diff0 + diff1 * diff1 + diff2 * diff2 + diff3 * diff3;
		first1 += 4;
		first2 += 4;
	}
	/* Process last 0-3 pixels.  Not needed for standard vector lengths. */
	while (first1 < last1) {
		diff0 = *first1++ - *first2++;
		distsq += diff0 * diff0;
	}
	return distsq;
}

}
