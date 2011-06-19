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
#include "flann/util/params.h"
#include "flann/util/saving.h"

#include "flann/algorithms/all_indices.h"

namespace flann
{

/**
 * Sets the log level used for all flann functions
 * @param level Verbosity level
 */
inline void log_verbosity(int level)
{
    if (level >= 0) {
        Logger::setLevel(level);
    }
}

/**
 * (Deprecated) Index parameters for creating a saved index.
 */
struct SavedIndexParams : public IndexParams
{
    SavedIndexParams(std::string filename)
    {
        (*this)["algorithm"] = FLANN_INDEX_SAVED;
        (*this)["filename"] = filename;
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

    IndexParams params;
    params["algorithm"] = header.index_type;
    NNIndex<Distance>* nnIndex = create_index_by_type<Distance>(dataset, params, distance);
    nnIndex->loadIndex(fin);
    fclose(fin);

    return nnIndex;
}


template<typename Distance>
class Index : public NNIndex<Distance>
{
public:
    typedef typename Distance::ElementType ElementType;
    typedef typename Distance::ResultType DistanceType;

    Index(const Matrix<ElementType>& features, const IndexParams& params, Distance distance = Distance() )
    	: index_params_(params)
    {
        flann_algorithm_t index_type = get_param<flann_algorithm_t>(params,"algorithm");
        loaded_ = false;

        if (index_type == FLANN_INDEX_SAVED) {
            nnIndex_ = load_saved_index<Distance>(features, get_param<std::string>(params,"filename"), distance);
            loaded_ = true;
        }
        else {
            nnIndex_ = create_index_by_type<Distance>(features, params, distance);
        }
    }

    ~Index()
    {
    	delete nnIndex_;
    }

    void buildIndex()
    {
        if (!loaded_) {
            nnIndex_->buildIndex();
        }
    }

    void save(std::string filename)
    {
        FILE* fout = fopen(filename.c_str(), "wb");
        if (fout == NULL) {
            throw FLANNException("Cannot open file");
        }
        save_header(fout, *nnIndex_);
        saveIndex(fout);
        fclose(fout);
    }

    /**
     * \brief Saves the index to a stream
     * \param stream The stream to save the index to
     */
    virtual void saveIndex(FILE* stream)
    {
    	nnIndex_->saveIndex(stream);
    }

    /**
     * \brief Loads the index from a stream
     * \param stream The stream from which the index is loaded
     */
    virtual void loadIndex(FILE* stream)
    {
    	nnIndex_->loadIndex(stream);
    }

    /**
     * \returns number of features in this index.
     */
    size_t veclen() const
    {
    	return nnIndex_->veclen();
    }

    /**
     * \returns The dimensionality of the features in this index.
     */
    size_t size() const
    {
    	return nnIndex_->size();
    }

    /**
     * \returns The index type (kdtree, kmeans,...)
     */
    flann_algorithm_t getType() const
    {
    	return nnIndex_->getType();
    }

    /**
     * \returns The amount of memory (in bytes) used by the index.
     */
    virtual int usedMemory() const
    {
    	return nnIndex_->usedMemory();
    }


    /**
     * \returns The index parameters
     */
    IndexParams getParameters() const
    {
        return nnIndex_->getParameters();
    }

    /**
     * \brief Perform k-nearest neighbor search
     * \param[in] queries The query points for which to find the nearest neighbors
     * \param[out] indices The indices of the nearest neighbors found
     * \param[out] dists Distances to the nearest neighbors found
     * \param[in] knn Number of nearest neighbors to return
     * \param[in] params Search parameters
     */
    void knnSearch(const Matrix<ElementType>& queries, Matrix<int>& indices, Matrix<DistanceType>& dists, int knn, const SearchParams& params)
    {
    	 nnIndex_->knnSearch(queries, indices, dists, knn, params);
    }

    /**
     * \brief Perform radius search
     * \param[in] query The query point
     * \param[out] indices The indinces of the neighbors found within the given radius
     * \param[out] dists The distances to the nearest neighbors found
     * \param[in] radius The radius used for search
     * \param[in] params Search parameters
     * \returns Number of neighbors found
     */
    int radiusSearch(const Matrix<ElementType>& query, Matrix<int>& indices, Matrix<DistanceType>& dists, float radius, const SearchParams& params)
    {
    	return nnIndex_->radiusSearch(query, indices, dists, radius, params);
    }

    /**
     * \brief Method that searches for nearest-neighbours
     */
    void findNeighbors(ResultSet<DistanceType>& result, const ElementType* vec, const SearchParams& searchParams)
    {
    	nnIndex_->findNeighbors(result, vec, searchParams);
    }

    /**
     * \brief Returns actual index
     */
    DEPRECATED NNIndex<Distance>* getIndex()
    {
        return nnIndex_;
    }

    /**
     * \brief Returns index parameters.
     * Deprecated. Use getParameters() instead.
     */
    DEPRECATED  const IndexParams* getIndexParameters()
    {
        return &index_params_;
    }

private:
    NNIndex<Distance>* nnIndex_;
    bool loaded_;
    IndexParams index_params_;
};

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
