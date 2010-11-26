/***********************************************************************
 * Software License Agreement (BSD License)
 *
 * Copyright 2008-2009  Marius Muja (mariusm@cs.ubc.ca). All rights reserved.
 * Copyright 2008-2009  David G. Lowe (lowe@cs.ubc.ca). All rights reserved.
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


#ifndef ALL_INDICES_H_
#define ALL_INDICES_H_

#include "flann/general.h"

#include "flann/algorithms/nn_index.h"
#include "flann/algorithms/kdtree_index.h"
#include "flann/algorithms/kdtree_single_index.h"
#include "flann/algorithms/kmeans_index.h"
#include "flann/algorithms/composite_index.h"
#include "flann/algorithms/linear_index.h"
#include "flann/algorithms/autotuned_index.h"


namespace flann {

template<typename Distance>
NNIndex<Distance>* create_index_by_type(const Matrix<typename Distance::ElementType>& dataset, const IndexParams& params, const Distance& distance)
{
	flann_algorithm_t index_type = params.getIndexType();

	NNIndex<Distance>* nnIndex;
	switch (index_type) {
	case LINEAR:
		nnIndex = new LinearIndex<Distance>(dataset, (const LinearIndexParams&)params, distance);
		break;
	case KDTREE_SINGLE:
		nnIndex = new KDTreeSingleIndex<Distance>(dataset, (const KDTreeSingleIndexParams&)params, distance);
	    break;
    case KDTREE:
		nnIndex = new KDTreeIndex<Distance>(dataset, (const KDTreeIndexParams&)params, distance);
		break;
	case KMEANS:
		nnIndex = new KMeansIndex<Distance>(dataset, (const KMeansIndexParams&)params, distance);
		break;
	case COMPOSITE:
		nnIndex = new CompositeIndex<Distance>(dataset, (const CompositeIndexParams&) params, distance);
		break;
	case AUTOTUNED:
		nnIndex = new AutotunedIndex<Distance>(dataset, (const AutotunedIndexParams&) params, distance);
		break;
	default:
		throw FLANNException("Unknown index type");
	}

	return nnIndex;
}

}

#endif /* ALL_INDICES_H_ */
