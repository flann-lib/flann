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

#include <vector>

#ifdef TBB
#include <tbb/parallel_for.h>
#include <tbb/blocked_range.h>
#include <tbb/atomic.h>
#include <tbb/task_scheduler_init.h>
#endif


#include "flann/general.h"
#include "flann/util/matrix.h"
#include "flann/util/params.h"
#include "flann/util/result_set.h"
#include "flann/util/dynamic_bitset.h"
#ifdef TBB
#include "flann/tbb/bodies.hpp"
#endif

namespace flann
{

#define KNN_HEAP_THRESHOLD 250


/**
 * Nearest-neighbour index base class
 */
template <typename Index, typename ElementType, typename DistanceType>
class NNIndex
{
public:

	NNIndex()
	{
		ownDataset_ = false;
		removed_points_.clear();
	}

	NNIndex(const IndexParams& params) : index_params_(params)
	{
		ownDataset_ = false;
		removed_points_.clear();
	}


    void buildIndex(const Matrix<ElementType>& dataset)
    {
        bool copy_dataset = get_param(index_params_, "copy_dataset", false);
        setDataset(dataset, copy_dataset);
        removed_points_.clear();

        static_cast<Index*>(this)->buildIndex();
    }
    
	/**
	 * @brief Incrementally add points to the index.
	 * @param points Matrix with points to be added
	 * @param rebuild_threshold
	 */
    void addPoints(const Matrix<ElementType>& points, float rebuild_threshold = 2)
    {
        throw FLANNException("Functionality not supported by this index");
    }

    /**
     * Remove point from the index
     * @param index Index of point to be removed
     */
    void removePoint(size_t index)
    {
    	removed_points_.set(index);
    }

    /**
     * @return number of features in this index.
     */
    inline size_t size() const
    {
        return size_;
    }

    /**
     * @return The dimensionality of the features in this index.
     */
    inline size_t veclen() const
    {
        return veclen_;
    }

    /**
     * Returns the parameters used by the index.
     *
     * @return The index parameters
     */
    IndexParams getParameters() const
    {
        return index_params_;
    }
    
    /**
     * @brief Perform k-nearest neighbor search
     * @param[in] queries The query points for which to find the nearest neighbors
     * @param[out] indices The indices of the nearest neighbors found
     * @param[out] dists Distances to the nearest neighbors found
     * @param[in] knn Number of nearest neighbors to return
     * @param[in] params Search parameters
     */
    int knnSearch(const Matrix<ElementType>& queries, Matrix<int>& indices, Matrix<DistanceType>& dists, size_t knn, const SearchParams& params)
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
        			static_cast<Index*>(this)->findNeighbors(resultSet, queries[i], params);
        			resultSet.copy(indices[i], dists[i], knn, params.sorted);
        			count += resultSet.size();
        		}
        	}
        	else {
        		KNNSimpleResultSet<DistanceType> resultSet(knn);
        		for (size_t i = 0; i < queries.rows; i++) {
        			resultSet.clear();
        			static_cast<Index*>(this)->findNeighbors(resultSet, queries[i], params);
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
        flann::parallel_knnSearch<Index> parallel_knn(queries, indices, dists, knn, params, static_cast<Index*>(this), atomic_count);
        tbb::parallel_for(tbb::blocked_range<size_t>(0,queries.rows),
                          parallel_knn,
                          tbb::auto_partitioner());

        count = atomic_count;
    }
#endif

        return count;
    }



    /**
     * @brief Perform k-nearest neighbor search
     * @param[in] queries The query points for which to find the nearest neighbors
     * @param[out] indices The indices of the nearest neighbors found
     * @param[out] dists Distances to the nearest neighbors found
     * @param[in] knn Number of nearest neighbors to return
     * @param[in] params Search parameters
     */
    int knnSearch(const Matrix<ElementType>& queries,
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
        			static_cast<Index*>(this)->findNeighbors(resultSet, queries[i], params);
        			size_t n = std::min(resultSet.size(), knn);
        			indices[i].resize(n);
        			dists[i].resize(n);
                    if (n>0) {
            			resultSet.copy(&indices[i][0], &dists[i][0], n, params.sorted);
                    }
        			count += n;
        		}
        	}
        	else {
        		KNNSimpleResultSet<DistanceType> resultSet(knn);
        		for (size_t i = 0; i < queries.rows; i++) {
        			resultSet.clear();
        			static_cast<Index*>(this)->findNeighbors(resultSet, queries[i], params);
        			size_t n = std::min(resultSet.size(), knn);
        			indices[i].resize(n);
        			dists[i].resize(n);
                    if (n>0) {
            			resultSet.copy(&indices[i][0], &dists[i][0], n, params.sorted);
                    }
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
            flann::parallel_knnSearch2<Index> parallel_knn(queries, indices, dists, knn, params, static_cast<Index*>(this), atomic_count);
            tbb::parallel_for(tbb::blocked_range<size_t>(0,queries.rows),
                              parallel_knn,
                              tbb::auto_partitioner());

            count = atomic_count;
        }
#endif
		return count;
    }


    /**
     * @brief Perform radius search
     * @param[in] query The query point
     * @param[out] indices The indinces of the neighbors found within the given radius
     * @param[out] dists The distances to the nearest neighbors found
     * @param[in] radius The radius used for search
     * @param[in] params Search parameters
     * @return Number of neighbors found
     */
    int radiusSearch(const Matrix<ElementType>& queries, Matrix<int>& indices, Matrix<DistanceType>& dists,
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
    				static_cast<Index*>(this)->findNeighbors(resultSet, queries[i], params);
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
    					static_cast<Index*>(this)->findNeighbors(resultSet, queries[i], params);
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
    					static_cast<Index*>(this)->findNeighbors(resultSet, queries[i], params);
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
            flann::parallel_radiusSearch<Index> parallel_radius(queries, indices, dists, radius, params, static_cast<Index*>(this), atomic_count);
            tbb::parallel_for(tbb::blocked_range<size_t>(0,queries.rows),
                              parallel_radius,
                              tbb::auto_partitioner());

            count = atomic_count;
        }
#endif
        return count;
    }

    /**
     * @brief Perform radius search
     * @param[in] query The query point
     * @param[out] indices The indinces of the neighbors found within the given radius
     * @param[out] dists The distances to the nearest neighbors found
     * @param[in] radius The radius used for search
     * @param[in] params Search parameters
     * @return Number of neighbors found
     */
    int radiusSearch(const Matrix<ElementType>& queries, std::vector< std::vector<int> >& indices,
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
        			static_cast<Index*>(this)->findNeighbors(resultSet, queries[i], params);
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
        				static_cast<Index*>(this)->findNeighbors(resultSet, queries[i], params);
        				size_t n = resultSet.size();
        				count += n;
        				indices[i].resize(n);
        				dists[i].resize(n);
        				if (n > 0) {
	        				resultSet.copy(&indices[i][0], &dists[i][0], n, params.sorted);
        				}
        			}
        		}
        		else {
        			// number of neighbors limited to max_neighbors
        			KNNRadiusResultSet<DistanceType> resultSet(radius, params.max_neighbors);
        			for (size_t i = 0; i < queries.rows; i++) {
        				resultSet.clear();
        				static_cast<Index*>(this)->findNeighbors(resultSet, queries[i], params);
        				size_t n = resultSet.size();
        				count += n;
        				if ((int)n>params.max_neighbors) n = params.max_neighbors;
        				indices[i].resize(n);
        				dists[i].resize(n);
        				if (n > 0) {
	        				resultSet.copy(&indices[i][0], &dists[i][0], n, params.sorted);
        				}
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
          flann::parallel_radiusSearch2<Index> parallel_radius(queries, indices, dists, radius, params, static_cast<Index*>(this), atomic_count);
          tbb::parallel_for(tbb::blocked_range<size_t>(0,queries.rows),
                            parallel_radius,
                            tbb::auto_partitioner());

          count = atomic_count;
        }
#endif
        return count;
    }
    

protected:

    void setDataset(const Matrix<ElementType>& dataset, bool copyDataset = false)
    {
    	if (copyDataset) {
    		dataset_ = Matrix<ElementType>(new ElementType[dataset.rows * dataset.cols], dataset.rows, dataset.cols);
    		for (size_t i=0;i<dataset.rows;++i) {
    			std::copy(dataset[i], dataset[i]+dataset.cols, dataset_[i]);
    		}
    		ownDataset_ = true;
    	}
    	else {
    		dataset_ = dataset;
    	}
    	size_ = dataset.rows;
    	veclen_ = dataset.cols;
    	removed_points_.resize(dataset_.rows);
    }

    void extendDataset(const Matrix<ElementType>& points)
    {
    	size_t rows = dataset_.rows + points.rows;
    	Matrix<ElementType> new_dataset(new ElementType[rows * dataset_.cols], rows, dataset_.cols);
    	for (size_t i=0;i<dataset_.rows;++i) {
    		std::copy(dataset_[i], dataset_[i]+dataset_.cols, new_dataset[i]);
    	}
    	for (size_t i=0;i<points.rows;++i) {
    		std::copy(points[i], points[i]+points.cols, new_dataset[dataset_.rows+i]);
    	}

    	if (ownDataset_) {
    		delete[] dataset_.ptr();
    	}

    	setDataset(new_dataset, false);
    	ownDataset_ = true;
    }

protected:
    /**
     * The dataset used by this index
     */
    Matrix<ElementType> dataset_;

    /**
     * Number of points in the index (and database)
     */
    size_t size_;

    /**
     * Size of one point in the index (and database)
     */
    size_t veclen_;

    /**
     * Parameters of the index.
     */
    IndexParams index_params_;

    /**
     * Was the dataset allocated by the index
     */
    bool ownDataset_;

    /**
     *  Bitset used for marking the points removed from the index.
     */
    DynamicBitset removed_points_;

};

}

#endif //FLANN_NNINDEX_H
