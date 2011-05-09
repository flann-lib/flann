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

#ifndef FLANN_HPP_
#define FLANN_HPP_

#include <vector>
#include <string>
#include <cassert>
#include <cstdio>

#include "flann/flann.h"
#include "flann/general.h"
#include "flann/util/matrix.h"
#include "flann/util/result_set.h"
#include "flann/nn/index_testing.h"
#include "flann/util/object_factory.h"
#include "flann/util/saving.h"
#include "flann/util/pair_iterator.hpp"

#include "flann/algorithms/all_indices.h"

namespace flann
{


/**
   Sets the log level used for all flann functions

   Params:
    level = verbosity level
 */
FLANN_EXPORT void log_verbosity(int level);


struct SavedIndexParams : public IndexParams
{
    SavedIndexParams(std::string filename_) : IndexParams(FLANN_INDEX_SAVED), filename(filename_) {}

    std::string filename;  // filename of the stored index

    void fromParameters(const FLANNParameters& p)
    {
        assert(p.algorithm == algorithm);
        //filename = p.filename;
    }

    void toParameters(FLANNParameters& p) const
    {
        p.algorithm = algorithm;
        //p.filename = filename.c_str();
    }

    void print() const
    {
        logger.info("Index type: %d\n", (int)algorithm);
        logger.info("Filename: %s\n", filename.c_str());
    }
};


template<typename Distance>
class Index
{
    typedef typename Distance::ElementType ElementType;
    typedef typename Distance::ResultType DistanceType;
    Distance distance;
    NNIndex<Distance>* nnIndex;
    bool built;

public:
    Index(const Matrix<ElementType>& features, const IndexParams& params, Distance d = Distance() );

    ~Index();

    void buildIndex();

    void knnSearch(const Matrix<ElementType>& queries, Matrix<int>& indices, Matrix<DistanceType>& dists, int knn, const SearchParams& params);

    int radiusSearch(const Matrix<ElementType>& query, Matrix<int>& indices, Matrix<DistanceType>& dists, float radius, const SearchParams& params);

    void save(std::string filename);

    int veclen() const;

    int size() const;

    NNIndex<Distance>* getIndex()
    {
        return nnIndex;
    }

    const IndexParams* getIndexParameters()
    {
        return nnIndex->getParameters();
    }
};


template<typename Distance>
NNIndex<Distance>* load_saved_index(const Matrix<typename Distance::ElementType>& dataset, const std::string& filename, Distance distance)
{
    typedef typename Distance::ElementType ElementType;

    FILE* fin = fopen(filename.c_str(), "rb");
    if (fin == NULL) {
        return NULL;
    }
    IndexHeader header = load_header(fin);
    if (header.data_type != Datatype<ElementType>::type()) {
        throw FLANNException("Datatype of saved index is different than of the one to be created.");
    }
    if ((size_t(header.rows) != dataset.rows)||(size_t(header.cols) != dataset.cols)) {
        throw FLANNException("The index saved belongs to a different dataset");
    }

    IndexParams* params = ParamsFactory::instance().create(header.index_type);
    NNIndex<Distance>* nnIndex = create_index_by_type<Distance>(dataset, *params, distance);
    nnIndex->loadIndex(fin);
    fclose(fin);

    return nnIndex;
}


template<typename Distance>
Index<Distance>::Index(const Matrix<ElementType>& dataset, const IndexParams& params, Distance d ) : distance (d)
{
    flann_algorithm_t index_type = params.getIndexType();
    built = false;

    if (index_type == FLANN_INDEX_SAVED) {
        nnIndex = load_saved_index<Distance>(dataset, ((const SavedIndexParams&)params).filename, distance);
        built = true;
    }
    else {
        nnIndex = create_index_by_type<Distance>(dataset, params, distance);
    }
}

template<typename Distance>
Index<Distance>::~Index()
{
    delete nnIndex;
}

template<typename Distance>
void Index<Distance>::buildIndex()
{
    if (!built) {
        nnIndex->buildIndex();
        built = true;
    }
}

template<typename Distance>
void Index<Distance>::knnSearch(const Matrix<ElementType>& queries, Matrix<int>& indices, Matrix<DistanceType>& dists, int knn, const SearchParams& searchParams)
{
    if (!built) {
        throw FLANNException("You must build the index before searching.");
    }
    assert(queries.cols == nnIndex->veclen());
    assert(indices.rows >= queries.rows);
    assert(dists.rows >= queries.rows);
    assert(int(indices.cols) >= knn);
    assert(int(dists.cols) >= knn);


    KNNResultSet<DistanceType> resultSet(knn);
    for (size_t i = 0; i < queries.rows; i++) {
        resultSet.init(indices[i], dists[i]);
        nnIndex->findNeighbors(resultSet, queries[i], searchParams);
    }

}


template<typename Distance>
int Index<Distance>::radiusSearch(const Matrix<ElementType>& query, Matrix<int>& indices, Matrix<DistanceType>& dists, float radius, const SearchParams& searchParams)
{
    if (!built) {
        throw FLANNException("You must build the index before searching.");
    }
    if (query.rows != 1) {
        fprintf(stderr, "I can only search one feature at a time for range search\n");
        return -1;
    }
    assert(query.cols == nnIndex->veclen());
    assert(indices.cols == dists.cols);

    int n = 0;
    int* indices_ptr = NULL;
    DistanceType* dists_ptr = NULL;
    if (indices.cols > 0) {
        n = indices.cols;
        indices_ptr = indices[0];
        dists_ptr = dists[0];
    }

    RadiusResultVector<DistanceType> resultSet(radius, (n>0));
    resultSet.clear();
    nnIndex->findNeighbors(resultSet, query[0], searchParams);
    if (n>0) {
        if (searchParams.sorted)
            resultSet.sortAndCopy(indices_ptr, dists_ptr, n);
        else
            resultSet.copy(indices_ptr, dists_ptr, n);
    }

    return resultSet.size();
}


template<typename Distance>
void Index<Distance>::save(std::string filename)
{
    FILE* fout = fopen(filename.c_str(), "wb");
    if (fout == NULL) {
        throw FLANNException("Cannot open file");
    }
    save_header(fout, *nnIndex);
    nnIndex->saveIndex(fout);
    fclose(fout);
}


template<typename Distance>
int Index<Distance>::size() const
{
    return nnIndex->size();
}

template<typename Distance>
int Index<Distance>::veclen() const
{
    return nnIndex->veclen();
}


template <typename Distance>
int hierarchicalClustering(const Matrix<typename Distance::ElementType>& features, Matrix<typename Distance::ResultType>& centers,
                           const KMeansIndexParams& params, Distance d = Distance())
{
    KMeansIndex<Distance> kmeans(features, params, d);
    kmeans.buildIndex();

    int clusterNum = kmeans.getClusterCenters(centers);
    return clusterNum;
}

}
#endif /* FLANN_HPP_ */
