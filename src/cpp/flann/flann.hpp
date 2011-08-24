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

#ifdef TBB
  #include <tbb/parallel_for.h>
  #include <tbb/blocked_range.h>
  #include <tbb/atomic.h>
  #include <tbb/task_scheduler_init.h>
#endif


#include "flann/general.h"
#include "flann/util/matrix.h"
#include "flann/util/params.h"
#include "flann/util/saving.h"

#include "flann/algorithms/all_indices.h"

#ifdef TBB
  #include "flann/tbb/bodies.hpp"
#endif

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
        (* this)["algorithm"] = FLANN_INDEX_SAVED;
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

#ifdef TBB
    Index(const Matrix<ElementType>& features, const IndexParams& params, Distance distance = Distance() )
        : index_params_(params), atomic_count_()
#else
    Index(const Matrix<ElementType>& features, const IndexParams& params, Distance distance = Distance() )
        : index_params_(params)
#endif
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

    /**
     * Builds the index.
     */
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
    int knnSearch(const Matrix<ElementType>& queries,
                                 Matrix<int>& indices,
                                 Matrix<DistanceType>& dists,
                                 size_t knn,
                           const SearchParams& params)
    {
        assert(queries.cols == veclen());
        assert(indices.rows >= queries.rows);
        assert(dists.rows >= queries.rows);
        assert(indices.cols >= knn);
        assert(dists.cols >= knn);
        bool sorted = get_param(params,"sorted",true);
        bool use_heap = get_param(params,"use_heap",false);
#ifdef TBB
        int cores = get_param(params,"cores",1);
        assert(cores >= 1 || cores == -1);
#endif

        int count = 0;

#ifdef TBB
        // Check if we need to do multicore search or stick with singlecore FLANN (less overhead)
        if(cores == 1)
        {
#endif
            if (use_heap) {
                  KNNResultSet2<DistanceType> resultSet(knn);
                  for (size_t i = 0; i < queries.rows; i++) {
                          resultSet.clear();
                          nnIndex_->findNeighbors(resultSet, queries[i], params);
                          resultSet.copy(indices[i], dists[i], knn, sorted);
                          count += resultSet.size();
                  }
            }
            else {
                  KNNSimpleResultSet<DistanceType> resultSet(knn);
                  for (size_t i = 0; i < queries.rows; i++) {
                          resultSet.clear();
                          nnIndex_->findNeighbors(resultSet, queries[i], params);
                          resultSet.copy(indices[i], dists[i], knn, sorted);
                          count += resultSet.size();
                  }
            }
#ifdef TBB
        }
        else
        {
            // Initialise the task scheduler for the use of Intel TBB parallel constructs
            tbb::task_scheduler_init task_sched(cores);

            // Make an atomic integer count, such that we can keep track of amount of neighbors found
            atomic_count_ = 0;

            // Use auto partitioner to choose the optimal grainsize for dividing the query points
            flann::parallel_knnSearch<Distance> parallel_knn(queries, indices, dists, knn, params, nnIndex_, atomic_count_);
            tbb::parallel_for(tbb::blocked_range<size_t>(0,queries.rows),
                              parallel_knn,
                              tbb::auto_partitioner());

            count = atomic_count_;
        }
#endif

        return count;
    }


    /**
     * \brief Perform k-nearest neighbor search
     * \param[in] queries The query points for which to find the nearest neighbors
     * \param[out] indices The indices of the nearest neighbors found
     * \param[out] dists Distances to the nearest neighbors found
     * \param[in] knn Number of nearest neighbors to return
     * \param[in] params Search parameters
     */
    int knnSearch(const Matrix<ElementType>& queries,
                                 std::vector< std::vector<int> >& indices,
                                 std::vector<std::vector<DistanceType> >& dists,
                                 size_t knn,
                           const SearchParams& params)
    {
        assert(queries.cols == veclen());
        bool sorted = get_param(params,"sorted",true);
        bool use_heap = get_param(params,"use_heap",false);
#ifdef TBB
        int cores = get_param(params,"cores",1);
        assert(cores >= 1 || cores == -1);
#endif

        if (indices.size() < queries.rows ) indices.resize(queries.rows);
        if (dists.size() < queries.rows ) dists.resize(queries.rows);

        int count = 0;

#ifdef TBB
        // Check if we need to do multicore search or stick with singlecore FLANN (less overhead)
        if(cores == 1)
        {
#endif
            if (use_heap) {
                KNNResultSet2<DistanceType> resultSet(knn);
                for (size_t i = 0; i < queries.rows; i++) {
                    resultSet.clear();
                    nnIndex_->findNeighbors(resultSet, queries[i], params);
                    size_t n = std::min(resultSet.size(), knn);
                    indices[i].resize(n);
                    dists[i].resize(n);
                    resultSet.copy(&indices[i][0], &dists[i][0], n, sorted);
                    count += n;
                }
            }
            else {
                KNNSimpleResultSet<DistanceType> resultSet(knn);
                for (size_t i = 0; i < queries.rows; i++) {
                    resultSet.clear();
                    nnIndex_->findNeighbors(resultSet, queries[i], params);
                    size_t n = std::min(resultSet.size(), knn);
                    indices[i].resize(n);
                    dists[i].resize(n);
                    resultSet.copy(&indices[i][0], &dists[i][0], n, sorted);
                    count += n;
                }
            }
#ifdef TBB
        }
        else
        {
            // Initialise the task scheduler for the use of Intel TBB parallel constructs
            tbb::task_scheduler_init task_sched(cores);

            // Make an atomic integer count, such that we can keep track of amount of neighbors found
            atomic_count_ = 0;

            // Use auto partitioner to choose the optimal grainsize for dividing the query points
            flann::parallel_knnSearch2<Distance> parallel_knn(queries, indices, dists, knn, params, nnIndex_, atomic_count_);
            tbb::parallel_for(tbb::blocked_range<size_t>(0,queries.rows),
                              parallel_knn,
                              tbb::auto_partitioner());

            count = atomic_count_;
        }
#endif

        return count;
    }


    /**
     * \brief Perform radius search
     * \param[in] queries The query points
     * \param[out] indices The indinces of the neighbors found within the given radius
     * \param[out] dists The distances to the nearest neighbors found
     * \param[in] radius The radius used for search
     * \param[in] params Search parameters
     * \returns Number of neighbors found
     */
    int radiusSearch(const Matrix<ElementType>& queries,
                                    Matrix<int>& indices,
                                    Matrix<DistanceType>& dists,
                                    float radius,
                              const SearchParams& params)
    {
        assert(queries.cols == veclen());
#ifdef TBB
        int cores = get_param(params,"cores",1);
        assert(cores >= 1 || cores == -1);
#endif

        int count = 0;

#ifdef TBB
        // Check if we need to do multicore search or stick with singlecore FLANN (less overhead)
        if(cores == 1)
        {
#endif
            int max_neighbors = get_param(params, "max_neighbors", -1);

            // just count neighbors
            if (max_neighbors==0) {
                CountRadiusResultSet<DistanceType> resultSet(radius);
                for (size_t i = 0; i < queries.rows; i++) {
                    resultSet.clear();
                    findNeighbors(resultSet, queries[i], params);
                    count += resultSet.size();
                }
            }
            else {
                size_t num_neighbors = std::min(indices.cols, dists.cols);
                bool sorted = get_param(params, "sorted", true);
                bool has_max_neighbors = has_param(params,"max_neighbors");

                // explicitly indicated to use unbounded radius result set
                // or we know there'll be enough room for resulting indices and dists
                if (max_neighbors<0 && (has_max_neighbors || num_neighbors>=size())) {
                    RadiusResultSet<DistanceType> resultSet(radius);
                    for (size_t i = 0; i < queries.rows; i++) {
                        resultSet.clear();
                        nnIndex_->findNeighbors(resultSet, queries[i], params);
                        size_t n = resultSet.size();
                        count += n;
                        if (n>num_neighbors) n = num_neighbors;
                        resultSet.copy(indices[i], dists[i], n, sorted);

                        // mark the next element in the output buffers as unused
                        if (n<indices.cols) indices[i][n] = -1;
                        if (n<dists.cols) dists[i][n] = std::numeric_limits<DistanceType>::infinity();
                    }
                }
                else {
                    if (max_neighbors<0) max_neighbors = num_neighbors;
                    else max_neighbors = std::min(max_neighbors,(int)num_neighbors);
                    // number of neighbors limited to max_neighbors
                    KNNRadiusResultSet<DistanceType> resultSet(radius, max_neighbors);
                    for (size_t i = 0; i < queries.rows; i++) {
                        resultSet.clear();
                        nnIndex_->findNeighbors(resultSet, queries[i], params);
                        size_t n = resultSet.size();
                        count += n;
                        if ((int)n>max_neighbors) n = max_neighbors;
                        resultSet.copy(indices[i], dists[i], n, sorted);

                        // mark the next element in the output buffers as unused
                        if (n<indices.cols) indices[i][n] = -1;
                        if (n<dists.cols) dists[i][n] = std::numeric_limits<DistanceType>::infinity();
                    }
                }
            }
#ifdef TBB
        }
        else
        {
            // Initialise the task scheduler for the use of Intel TBB parallel constructs
            tbb::task_scheduler_init task_sched(cores);

            // Make an atomic integer count, such that we can keep track of amount of neighbors found
            atomic_count_ = 0;

            // Use auto partitioner to choose the optimal grainsize for dividing the query points
            flann::parallel_radiusSearch<Distance> parallel_radius(queries, indices, dists, radius, params, nnIndex_, atomic_count_);
            tbb::parallel_for(tbb::blocked_range<size_t>(0,queries.rows),
                              parallel_radius,
                              tbb::auto_partitioner());

            count = atomic_count_;
        }
#endif

        return count;
    }


    /**
     * \brief Perform radius search
     * \param[in] queries The query points
     * \param[out] indices The indinces of the neighbors found within the given radius
     * \param[out] dists The distances to the nearest neighbors found
     * \param[in] radius The radius used for search
     * \param[in] params Search parameters
     * \returns Number of neighbors found
     */
    int radiusSearch(const Matrix<ElementType>& queries,
                                    std::vector< std::vector<int> >& indices,
                                    std::vector<std::vector<DistanceType> >& dists,
                                    float radius,
                              const SearchParams& params)
    {
        assert(queries.cols == veclen());
#ifdef TBB
        int cores = get_param(params,"cores",1);
        assert(cores >= 1 || cores == -1);
#endif

        int count = 0;

#ifdef TBB
        // Check if we need to do multicore search or stick with singlecore FLANN (less overhead)
        if(cores == 1)
        {
#endif
            int max_neighbors = get_param(params, "max_neighbors", -1);

            // just count neighbors
            if (max_neighbors==0) {
                    CountRadiusResultSet<DistanceType> resultSet(radius);
                for (size_t i = 0; i < queries.rows; i++) {
                    resultSet.clear();
                    findNeighbors(resultSet, queries[i], params);
                    count += resultSet.size();
                }
            }
            else {
                bool sorted = get_param(params, "sorted", true);
                if (indices.size() < queries.rows ) indices.resize(queries.rows);
                if (dists.size() < queries.rows ) dists.resize(queries.rows);

                if (max_neighbors<0) {
                    // search for all neighbors
                    RadiusResultSet<DistanceType> resultSet(radius);
                    for (size_t i = 0; i < queries.rows; i++) {
                        resultSet.clear();
                        findNeighbors(resultSet, queries[i], params);
                        size_t n = resultSet.size();
                        count += n;
                        indices[i].resize(n);
                        dists[i].resize(n);
                        resultSet.copy(&indices[i][0], &dists[i][0], n, sorted);
                    }
                }
                else {
                    // number of neighbors limited to max_neighbors
                    KNNRadiusResultSet<DistanceType> resultSet(radius, max_neighbors);
                    for (size_t i = 0; i < queries.rows; i++) {
                        resultSet.clear();
                        findNeighbors(resultSet, queries[i], params);
                        size_t n = resultSet.size();
                        count += n;
                        if ((int)n>max_neighbors) n = max_neighbors;
                        indices[i].resize(n);
                        dists[i].resize(n);
                        resultSet.copy(&indices[i][0], &dists[i][0], n, sorted);
                    }
                }
            }
#ifdef TBB
        }
        else
        {
          // Initialise the task scheduler for the use of Intel TBB parallel constructs
          tbb::task_scheduler_init task_sched(cores);

          // Reset atomic count before passing it on to the threads, such that we can keep track of amount of neighbors found
          atomic_count_ = 0;

          // Use auto partitioner to choose the optimal grainsize for dividing the query points
          flann::parallel_radiusSearch2<Distance> parallel_radius(queries, indices, dists, radius, params, nnIndex_, atomic_count_);
          tbb::parallel_for(tbb::blocked_range<size_t>(0,queries.rows),
                            parallel_radius,
                            tbb::auto_partitioner());

          count = atomic_count_;
        }
#endif

        return count;
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
    FLANN_DEPRECATED NNIndex<Distance>* getIndex()
    {
        return nnIndex_;
    }

    /**
     * \brief Returns index parameters.
     * \deprecated use getParameters() instead.
     */
    FLANN_DEPRECATED  const IndexParams* getIndexParameters()
    {
        return &index_params_;
    }

private:
    /** Pointer to actual index class */
    NNIndex<Distance>* nnIndex_;
    /** Indices if the index was loaded from a file */
    bool loaded_;
    /** Parameters passed to the index */
    IndexParams index_params_;
#ifdef TBB
    /** Atomic count variable, passed to the different threads for keeping track of the amount of neighbors found.
        \note Intel TBB 'catch': must be data member for correct initialization tbb::atomic<T> has no declared constructors !! */
    tbb::atomic<int> atomic_count_;
#endif
};

/**
 * Performs a hierarchical clustering of the points passed as argument and then takes a cut in the
 * the clustering tree to return a flat clustering.
 * @param[in] points Points to be clustered
 * @param centers The computed cluster centres. Matrix should be preallocated and centers.rows is the
 *  number of clusters requested.
 * @param params Clustering parameters (The same as for flann::KMeansIndex)
 * @param d Distance to be used for clustering (eg: flann::L2)
 * @return number of clusters computed (can be different than clusters.rows and is the highest number
 * of the form (branching-1)*K+1 smaller than clusters.rows).
 */
template <typename Distance>
int hierarchicalClustering(const Matrix<typename Distance::ElementType>& points, Matrix<typename Distance::ResultType>& centers,
                           const KMeansIndexParams& params, Distance d = Distance())
{
    KMeansIndex<Distance> kmeans(points, params, d);
    kmeans.buildIndex();

    int clusterNum = kmeans.getClusterCenters(centers);
    return clusterNum;
}

}
#endif /* FLANN_HPP_ */
