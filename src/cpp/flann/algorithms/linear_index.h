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

#ifndef FLANN_LINEAR_INDEX_H_
#define FLANN_LINEAR_INDEX_H_

#include "flann/general.h"
#include "flann/algorithms/nn_index.h"

namespace flann
{

struct LinearIndexParams : public IndexParams
{
    LinearIndexParams()
    {
        (* this)["algorithm"] = FLANN_INDEX_LINEAR;
    }
};

template <typename Distance>
class LinearIndex : public NNIndex<LinearIndex<Distance>, typename Distance::ElementType, typename Distance::ResultType>
{
public:

    typedef typename Distance::ElementType ElementType;
    typedef typename Distance::ResultType DistanceType;
    typedef NNIndex<LinearIndex<Distance>, ElementType, DistanceType> BaseClass;


    LinearIndex(const IndexParams& params = LinearIndexParams(), Distance d = Distance()) :
                	BaseClass(params), distance_(d)
    {
    }

    LinearIndex(const Matrix<ElementType>& input_data, const IndexParams& params = LinearIndexParams(), Distance d = Distance()) :
                	BaseClass(params), distance_(d)
    {
        bool copy_dataset = get_param(index_params_, "copy_dataset", false);
        setDataset(input_data, copy_dataset);
    }

    ~LinearIndex()
    {
        if (ownDataset_) {
            delete[] dataset_.ptr();
        }
    }

    void addPoints(const Matrix<ElementType>& points, float rebuild_threshold = 2)
    {
        assert(points.cols==veclen_);
        extendDataset(points);
    }

    
    LinearIndex(const LinearIndex&);
    LinearIndex& operator=(const LinearIndex&);

    flann_algorithm_t getType() const
    {
        return FLANN_INDEX_LINEAR;
    }


    int usedMemory() const
    {
        return 0;
    }

    void buildIndex()
    {
        /* nothing to do here for linear search */
    }

    void saveIndex(FILE*)
    {
        /* nothing to do here for linear search */
    }


    void loadIndex(FILE*)
    {
        /* nothing to do here for linear search */

        index_params_["algorithm"] = getType();
    }

    template <typename ResultSet>
    void findNeighbors(ResultSet& resultSet, const ElementType* vec, const SearchParams& /*searchParams*/)
    {
        for (size_t i = 0; i < dataset_.rows; ++i) {
        	if (removed_points_.test(i)) continue;
            DistanceType dist = distance_(dataset_[i], vec, dataset_.cols);
            resultSet.addPoint(dist, i);
        }
    }


private:
    /** Index distance */
    Distance distance_;

    using BaseClass::removed_points_;
    using BaseClass::dataset_;
    using BaseClass::ownDataset_;
    using BaseClass::index_params_;
    using BaseClass::size_;
    using BaseClass::veclen_;
    using BaseClass::extendDataset;
    using BaseClass::setDataset;
};

}

#endif // FLANN_LINEAR_INDEX_H_
