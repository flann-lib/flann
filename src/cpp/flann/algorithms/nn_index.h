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

#ifndef FLANN_NNINDEX_H
#define FLANN_NNINDEX_H

#include <string>

#ifdef TBB
  #include <tbb/parallel_for.h>
  #include <tbb/blocked_range.h>
  #include <tbb/atomic.h>
  #include <tbb/task_scheduler_init.h>
#endif


#include "flann/general.h"
#include "flann/util/matrix.h"
#include "flann/util/result_set.h"
#include "flann/util/params.h"
#ifdef TBB
  #include "flann/tbb/bodies.hpp"
#endif

namespace flann
{

#define KNN_HEAP_THRESHOLD 250

/**
 * Nearest-neighbour index base class
 */
template <typename Distance>
class NNIndex
{
    typedef typename Distance::ElementType ElementType;
    typedef typename Distance::ResultType DistanceType;

public:

    virtual ~NNIndex() {}

    /**
     * \brief Builds the index
     */
    virtual void buildIndex() = 0;

    /**
     * \brief Perform k-nearest neighbor search
     * \param[in] queries The query points for which to find the nearest neighbors
     * \param[out] indices The indices of the nearest neighbors found
     * \param[out] dists Distances to the nearest neighbors found
     * \param[in] knn Number of nearest neighbors to return
     * \param[in] params Search parameters
     */
    virtual int knnSearch(const Matrix<ElementType>& queries, Matrix<int>& indices, Matrix<DistanceType>& dists, size_t knn, const SearchParams& params)
    {
        assert(queries.cols == veclen());
        assert(indices.rows >= queries.rows);
        assert(dists.rows >= queries.rows);
        assert(indices.cols >= knn);
        assert(dists.cols >= knn);
        bool use_heap;

        if (params.use_heap==FLANN_Undefined) {
        	use_heap = (knn>KNN_HEAP_THRESHOLD)?true:false;
        }
        else {
        	use_heap = (params.use_heap==FLANN_True)?true:false;
        }
        int count = 0;

#ifdef TBB
        // Check if we need to do multicore search or stick with single core FLANN (less overhead)
        if(params.cores == 1)
        {
#endif
        	if (use_heap) {
        		KNNResultSet2<DistanceType> resultSet(knn);
        		for (size_t i = 0; i < queries.rows; i++) {
        			resultSet.clear();
        			findNeighbors(resultSet, queries[i], params);
        			resultSet.copy(indices[i], dists[i], knn, params.sorted);
        			count += resultSet.size();
        		}
        	}
        	else {
        		KNNSimpleResultSet<DistanceType> resultSet(knn);
        		for (size_t i = 0; i < queries.rows; i++) {
        			resultSet.clear();
        			findNeighbors(resultSet, queries[i], params);
        			resultSet.copy(indices[i], dists[i], knn, params.sorted);
        			count += resultSet.size();
        		}
        	}
#ifdef TBB
    }
    else
    {
        // Initialise the task scheduler for the use of Intel TBB parallel constructs
        tbb::task_scheduler_init task_sched(params.cores);

        // Make an atomic integer count, such that we can keep track of amount of neighbors found
        tbb::atomic<int> atomic_count;
        atomic_count = 0;
        // Use auto partitioner to choose the optimal grainsize for dividing the query points
        flann::parallel_knnSearch<Distance> parallel_knn(queries, indices, dists, knn, params, this, atomic_count);
        tbb::parallel_for(tbb::blocked_range<size_t>(0,queries.rows),
                          parallel_knn,
                          tbb::auto_partitioner());

        count = atomic_count;
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
    virtual int knnSearch(const Matrix<ElementType>& queries,
					std::vector< std::vector<int> >& indices,
					std::vector<std::vector<DistanceType> >& dists,
    				size_t knn,
    				const SearchParams& params)
    {
        assert(queries.cols == veclen());
        bool use_heap;
        if (params.use_heap==FLANN_Undefined) {
        	use_heap = (knn>KNN_HEAP_THRESHOLD)?true:false;
        }
        else {
        	use_heap = (params.use_heap==FLANN_True)?true:false;
        }

        if (indices.size() < queries.rows ) indices.resize(queries.rows);
		if (dists.size() < queries.rows ) dists.resize(queries.rows);

		int count = 0;
#ifdef TBB
        // Check if we need to do multicore search or stick with single core FLANN (less overhead)
        if(params.cores == 1)
        {
#endif
        	if (use_heap) {
        		KNNResultSet2<DistanceType> resultSet(knn);
        		for (size_t i = 0; i < queries.rows; i++) {
        			resultSet.clear();
        			findNeighbors(resultSet, queries[i], params);
        			size_t n = std::min(resultSet.size(), knn);
        			indices[i].resize(n);
        			dists[i].resize(n);
        			resultSet.copy(&indices[i][0], &dists[i][0], n, params.sorted);
        			count += n;
        		}
        	}
        	else {
        		KNNSimpleResultSet<DistanceType> resultSet(knn);
        		for (size_t i = 0; i < queries.rows; i++) {
        			resultSet.clear();
        			findNeighbors(resultSet, queries[i], params);
        			size_t n = std::min(resultSet.size(), knn);
        			indices[i].resize(n);
        			dists[i].resize(n);
        			resultSet.copy(&indices[i][0], &dists[i][0], n, params.sorted);
        			count += n;
        		}
        	}
#ifdef TBB
        }
        else
        {
            // Initialise the task scheduler for the use of Intel TBB parallel constructs
            tbb::task_scheduler_init task_sched(params.cores);

            // Make an atomic integer count, such that we can keep track of amount of neighbors found
            tbb::atomic<int> atomic_count;
            atomic_count = 0;

            // Use auto partitioner to choose the optimal grainsize for dividing the query points
            flann::parallel_knnSearch2<Distance> parallel_knn(queries, indices, dists, knn, params, this, atomic_count);
            tbb::parallel_for(tbb::blocked_range<size_t>(0,queries.rows),
                              parallel_knn,
                              tbb::auto_partitioner());

            count = atomic_count;
        }
#endif
		return count;
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
    virtual int radiusSearch(const Matrix<ElementType>& queries, Matrix<int>& indices, Matrix<DistanceType>& dists,
    		float radius, const SearchParams& params)
    {
        assert(queries.cols == veclen());
        int count = 0;
#ifdef TBB
        // Check if we need to do multicore search or stick with single core FLANN (less overhead)
        if(params.cores == 1)
        {
#endif
			size_t num_neighbors = std::min(indices.cols, dists.cols);
			int max_neighbors = params.max_neighbors;
			if (max_neighbors<0) max_neighbors = num_neighbors;
			else max_neighbors = std::min(max_neighbors,(int)num_neighbors);

    		if (max_neighbors==0) {
    			CountRadiusResultSet<DistanceType> resultSet(radius);
    			for (size_t i = 0; i < queries.rows; i++) {
    				resultSet.clear();
    				findNeighbors(resultSet, queries[i], params);
    				count += resultSet.size();
    			}
    		}
    		else {

    			// explicitly indicated to use unbounded radius result set
    			// or we know there'll be enough room for resulting indices and dists
    			if (params.max_neighbors<0 && (num_neighbors>=size())) {
    				RadiusResultSet<DistanceType> resultSet(radius);
    				for (size_t i = 0; i < queries.rows; i++) {
    					resultSet.clear();
    					findNeighbors(resultSet, queries[i], params);
    					size_t n = resultSet.size();
    					count += n;
    					if (n>num_neighbors) n = num_neighbors;
    					resultSet.copy(indices[i], dists[i], n, params.sorted);

    					// mark the next element in the output buffers as unused
    					if (n<indices.cols) indices[i][n] = -1;
    					if (n<dists.cols) dists[i][n] = std::numeric_limits<DistanceType>::infinity();
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
    					resultSet.copy(indices[i], dists[i], n, params.sorted);

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
            tbb::task_scheduler_init task_sched(params.cores);

            // Make an atomic integer count, such that we can keep track of amount of neighbors found
            tbb::atomic<int> atomic_count;
            atomic_count = 0;

            // Use auto partitioner to choose the optimal grainsize for dividing the query points
            flann::parallel_radiusSearch<Distance> parallel_radius(queries, indices, dists, radius, params, this, atomic_count);
            tbb::parallel_for(tbb::blocked_range<size_t>(0,queries.rows),
                              parallel_radius,
                              tbb::auto_partitioner());

            count = atomic_count;
        }
#endif
        return count;
    }

    virtual int radiusSearch(const Matrix<ElementType>& queries, std::vector< std::vector<int> >& indices,
    		std::vector<std::vector<DistanceType> >& dists, float radius, const SearchParams& params)
    {
        assert(queries.cols == veclen());
    	int count = 0;
#ifdef TBB
        // Check if we need to do multicore search or stick with single core FLANN (less overhead)
        if(params.cores == 1)
        {
#endif
        	// just count neighbors
        	if (params.max_neighbors==0) {
        		CountRadiusResultSet<DistanceType> resultSet(radius);
        		for (size_t i = 0; i < queries.rows; i++) {
        			resultSet.clear();
        			findNeighbors(resultSet, queries[i], params);
        			count += resultSet.size();
        		}
        	}
        	else {
        		if (indices.size() < queries.rows ) indices.resize(queries.rows);
        		if (dists.size() < queries.rows ) dists.resize(queries.rows);

        		if (params.max_neighbors<0) {
        			// search for all neighbors
        			RadiusResultSet<DistanceType> resultSet(radius);
        			for (size_t i = 0; i < queries.rows; i++) {
        				resultSet.clear();
        				findNeighbors(resultSet, queries[i], params);
        				size_t n = resultSet.size();
        				count += n;
        				indices[i].resize(n);
        				dists[i].resize(n);
        				resultSet.copy(&indices[i][0], &dists[i][0], n, params.sorted);
        			}
        		}
        		else {
        			// number of neighbors limited to max_neighbors
        			KNNRadiusResultSet<DistanceType> resultSet(radius, params.max_neighbors);
        			for (size_t i = 0; i < queries.rows; i++) {
        				resultSet.clear();
        				findNeighbors(resultSet, queries[i], params);
        				size_t n = resultSet.size();
        				count += n;
        				if ((int)n>params.max_neighbors) n = params.max_neighbors;
        				indices[i].resize(n);
        				dists[i].resize(n);
        				resultSet.copy(&indices[i][0], &dists[i][0], n, params.sorted);
        			}
        		}
        	}
#ifdef TBB
        }
        else
        {
          // Initialise the task scheduler for the use of Intel TBB parallel constructs
          tbb::task_scheduler_init task_sched(params.cores);

          // Reset atomic count before passing it on to the threads, such that we can keep track of amount of neighbors found
          tbb::atomic<int> atomic_count;
          atomic_count = 0;

          // Use auto partitioner to choose the optimal grainsize for dividing the query points
          flann::parallel_radiusSearch2<Distance> parallel_radius(queries, indices, dists, radius, params, this, atomic_count);
          tbb::parallel_for(tbb::blocked_range<size_t>(0,queries.rows),
                            parallel_radius,
                            tbb::auto_partitioner());

          count = atomic_count;
        }
#endif
        return count;
    }


    /**
     * \brief Saves the index to a stream
     * \param stream The stream to save the index to
     */
    virtual void saveIndex(FILE* stream) = 0;

    /**
     * \brief Loads the index from a stream
     * \param stream The stream from which the index is loaded
     */
    virtual void loadIndex(FILE* stream) = 0;

    /**
     * \returns number of features in this index.
     */
    virtual size_t size() const = 0;

    /**
     * \returns The dimensionality of the features in this index.
     */
    virtual size_t veclen() const = 0;

    /**
     * \returns The amount of memory (in bytes) used by the index.
     */
    virtual int usedMemory() const = 0;

    /**
     * \returns The index type (kdtree, kmeans,...)
     */
    virtual flann_algorithm_t getType() const = 0;

    /**
     * \returns The index parameters
     */
    virtual IndexParams getParameters() const = 0;


    /**
     * \brief Method that searches for nearest-neighbours
     */
    virtual void findNeighbors(ResultSet<DistanceType>& result, const ElementType* vec, const SearchParams& searchParams) = 0;
};

}

#endif //FLANN_NNINDEX_H
