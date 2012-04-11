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


    LinearIndex(const Matrix<ElementType>& input_data, const IndexParams& params = LinearIndexParams(),
                Distance d = Distance()) :
        dataset_(input_data), index_params_(params), distance_(d)
    {
        ownDataset_ = get_param(index_params_, "copy_dataset", false);
        if (ownDataset_) {
            dataset_ = Matrix<ElementType>(new ElementType[input_data.rows * input_data.cols], input_data.rows, input_data.cols);
            for (size_t i=0;i<input_data.rows;++i) {
                std::copy(input_data[i], input_data[i]+input_data.cols, dataset_[i]);
            }        
        }
    }
    
    ~LinearIndex()
    {
        if (ownDataset_) {
            delete[] dataset_.ptr();
        }
    }

    void addPoints(const Matrix<ElementType>& points, float rebuild_threshold = 2)
    {
        assert(points.cols==veclen());

        size_t rows = dataset_.rows + points.rows;
        Matrix<ElementType> new_dataset(new ElementType[rows * veclen()], rows, veclen());
        for (size_t i=0;i<dataset_.rows;++i) {
            std::copy(dataset_[i], dataset_[i]+dataset_.cols, new_dataset[i]);
        }
        for (size_t i=0;i<points.rows;++i) {
            std::copy(points[i], points[i]+points.cols, new_dataset[dataset_.rows+i]);
        }
        
        if (ownDataset_) {
            delete[] dataset_.ptr();
        }
        dataset_ = new_dataset;
        ownDataset_ = true;
    }

    
    LinearIndex(const LinearIndex&);
    LinearIndex& operator=(const LinearIndex&);

    flann_algorithm_t getType() const
    {
        return FLANN_INDEX_LINEAR;
    }


    size_t size() const
    {
        return dataset_.rows;
    }

    size_t veclen() const
    {
        return dataset_.cols;
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
            DistanceType dist = distance_(dataset_[i], vec, dataset_.cols);
            resultSet.addPoint(dist, i);
        }
    }

    IndexParams getParameters() const
    {
        return index_params_;
    }

private:
    /** The dataset */
    Matrix<ElementType> dataset_;
    /** Index parameters */
    IndexParams index_params_;
    /**  Does the index have a copy of the dataset? */
    bool ownDataset_;    
    /** Index distance */
    Distance distance_;
};

}

#endif // FLANN_LINEAR_INDEX_H_
