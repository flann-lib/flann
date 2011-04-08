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

#ifndef LINEARSEARCH_H
#define LINEARSEARCH_H

#include "flann/general.h"
#include "flann/algorithms/nn_index.h"

namespace flann
{

struct LinearIndexParams : public IndexParams
{
    LinearIndexParams() : IndexParams(FLANN_INDEX_LINEAR) {}

    void fromParameters(const FLANNParameters& p)
    {
        assert(p.algorithm==algorithm);
    }

    void toParameters(FLANNParameters& p) const
    {
        p.algorithm = algorithm;
    }

    void print() const
    {
        logger.info("Index type: %d\n",(int)algorithm);
    }
};

template <typename Distance>
class LinearIndex : public NNIndex<Distance>
{
    typedef typename Distance::ElementType ElementType;
    typedef typename Distance::ResultType DistanceType;

    const Matrix<ElementType> dataset;
    const LinearIndexParams index_params;

    Distance distance;

public:

    LinearIndex(const Matrix<ElementType>& inputData, const LinearIndexParams& params = LinearIndexParams(),
                Distance d = Distance()) :
        dataset(inputData), index_params(params), distance(d)
    {
    }

    flann_algorithm_t getType() const
    {
        return FLANN_INDEX_LINEAR;
    }


    size_t size() const
    {
        return dataset.rows;
    }

    size_t veclen() const
    {
        return dataset.cols;
    }


    int usedMemory() const
    {
        return 0;
    }

    void buildIndex()
    {
        /* nothing to do here for linear search */
    }

    void saveIndex(FILE* stream)
    {
        /* nothing to do here for linear search */
    }


    void loadIndex(FILE* stream)
    {
        /* nothing to do here for linear search */
    }

    void findNeighbors(ResultSet<DistanceType>& resultSet, const ElementType* vec, const SearchParams& searchParams)
    {
        for (size_t i=0; i<dataset.rows; ++i) {
            DistanceType dist = distance(dataset[i],vec, dataset.cols);
            resultSet.addPoint(dist,i);
        }
    }

    const IndexParams* getParameters() const
    {
        return &index_params;
    }

};

}

#endif // LINEARSEARCH_H
