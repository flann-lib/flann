/***********************************************************************
 * Software License Agreement (BSD License)
 *
 * Copyright 2017  Seth Price (seth@planet.com). All rights reserved.
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


#ifdef FLANN_USE_OPENCL
#ifndef FLANN_HIERARCHICAL_OPENCL_INDEX_H_
#define FLANN_HIERARCHICAL_OPENCL_INDEX_H_

#include <queue>

#include "flann/algorithms/nn_opencl_index.h"
#include "flann/algorithms/hierarchical_clustering_index.h"

namespace flann
{

/**
 * Hierarchical index
 *
 * Contains a tree constructed through a hierarchical clustering
 * and other information for indexing a set of points for nearest-neighbour matching.
 */
template <typename Distance>
class HierarchicalClusteringOpenCLIndex : public HierarchicalClusteringIndex<Distance>, public OpenCLIndex
{
public:
    typedef typename Distance::ElementType ElementType;
    typedef typename Distance::ResultType DistanceType;

    typedef HierarchicalClusteringIndex<Distance> BaseClass;

    flann_algorithm_t getType() const
    {
        return FLANN_INDEX_HIERARCHICAL_OPENCL;
    }

    /**
     * Index constructor
     *
     * Params:
     *          inputData = dataset with the input features
     *          params = parameters passed to the hierarchical clustering algorithm
     */
    HierarchicalClusteringOpenCLIndex(
        const Matrix<ElementType>& inputData,
        const IndexParams& params = HierarchicalClusteringIndexParams(),
        Distance d = Distance())
        : BaseClass(inputData, params, d)
    {
        // Init OpenCL members here
    }

protected:
    /**
     * Are the conditions right for an OpenCL search to actually be faster?
     *
     * @return Boolean of whether an OpenCL search is a good idea.
     */
    virtual int shouldCLKnnSearch(int numQueries, size_t knn, const SearchParams& params) const
    {
        return numQueries >= 1024 && this->size_ > this->branching_;
    }
};

}

#endif /* FLANN_HIERARCHICAL_OPENCL_INDEX_H_ */
#endif /* FLANN_USE_OPENCL */
