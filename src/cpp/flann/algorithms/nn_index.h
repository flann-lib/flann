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
template <typename Distance>
class NNIndex
{
    typedef typename Distance::ElementType ElementType;
    typedef typename Distance::ResultType DistanceType;

public:

	NNIndex()
	{
	}

	NNIndex(const IndexParams& params) : index_params_(params)
	{
	}

	/**
	 * Builds the index
	 */
	virtual void buildIndex() = 0;

	/**
	 * Builds th index using using the specified dataset
	 * @param dataset the dataset to use
	 */
    void buildIndex(const Matrix<ElementType>& dataset)
    {
        setDataset(dataset);
        buildIndex();
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
    void removePoint(size_t id)
    {
    	size_t point_index = id;
    	if (ids_[point_index]!=id) {
    		// binary search
    		size_t start = 0;
    		size_t end = size();

    		while (start<end) {
    			size_t mid = (start+end)/2;
    			if (ids_[mid]==id) {
    				point_index = mid;
    				break;
    			}
    			else if (ids_[mid]<id) {
    				start = mid + 1;
    			}
    			else {
    				end = mid;
    			}
    		}
    	}

    	removed_points_.set(point_index);
    	removed_ = true;
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
    /*
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
        			findNeighbors(resultSet, queries[i], params);
        			size_t n = std::min(resultSet.size(), knn);
        			resultSet.copy(indices[i], dists[i], n, params.sorted);
                    for (size_t j=0;j<n;++j) {
                    	indices[i][j] = ids_[indices[i][j]];
                    }
        			count += n;
        		}
        	}
        	else {
        		KNNSimpleResultSet<DistanceType> resultSet(knn);
        		for (size_t i = 0; i < queries.rows; i++) {
        			resultSet.clear();
        			findNeighbors(resultSet, queries[i], params);
        			size_t n = std::min(resultSet.size(), knn);
        			resultSet.copy(indices[i], dists[i], knn, params.sorted);
                    for (size_t j=0;j<n;++j) {
                    	indices[i][j] = ids_[indices[i][j]];
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
        flann::parallel_knnSearch<Distance> parallel_knn(queries, indices, dists, knn, params, static_cast<Index*>(this), atomic_count);
        tbb::parallel_for(tbb::blocked_range<size_t>(0,queries.rows),
                          parallel_knn,
                          tbb::auto_partitioner());

        count = atomic_count;
    }
#endif

        return count;
    }
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
        			findNeighbors(resultSet, queries[i], params);
        			size_t n = std::min(resultSet.size(), knn);
        			indices[i].resize(n);
        			dists[i].resize(n);
                    if (n>0) {
            			resultSet.copy(&indices[i][0], &dists[i][0], n, params.sorted);
                    }
                    for (size_t j=0;j<n;++j) {
                    	indices[i][j] = ids_[indices[i][j]];
                    }
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
                    if (n>0) {
            			resultSet.copy(&indices[i][0], &dists[i][0], n, params.sorted);
                    }
                    for (size_t j=0;j<n;++j) {
                    	indices[i][j] = ids_[indices[i][j]];
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
            flann::parallel_knnSearch2<Distance> parallel_knn(queries, indices, dists, knn, params, static_cast<Index*>(this), atomic_count);
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
                        for (size_t j=0;j<n;++j) {
                        	indices[i][j] = ids_[indices[i][j]];
                        }
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
                        for (size_t j=0;j<n;++j) {
                        	indices[i][j] = ids_[indices[i][j]];
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

            // Make an atomic integer count, such that we can keep track of amount of neighbors found
            tbb::atomic<int> atomic_count;
            atomic_count = 0;

            // Use auto partitioner to choose the optimal grainsize for dividing the query points
            flann::parallel_radiusSearch<Distance> parallel_radius(queries, indices, dists, radius, params, static_cast<Index*>(this), atomic_count);
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
        				if (n > 0) {
	        				resultSet.copy(&indices[i][0], &dists[i][0], n, params.sorted);
        				}
                        for (size_t j=0;j<n;++j) {
                        	indices[i][j] = ids_[indices[i][j]];
                        }
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
        				if (n > 0) {
	        				resultSet.copy(&indices[i][0], &dists[i][0], n, params.sorted);
        				}
                        for (size_t j=0;j<n;++j) {
                        	indices[i][j] = ids_[indices[i][j]];
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
          flann::parallel_radiusSearch2<Distance> parallel_radius(queries, indices, dists, radius, params, static_cast<Index*>(this), atomic_count);
          tbb::parallel_for(tbb::blocked_range<size_t>(0,queries.rows),
                            parallel_radius,
                            tbb::auto_partitioner());

          count = atomic_count;
        }
#endif
        return count;
    }


    virtual void findNeighbors(ResultSet<DistanceType>& result, const ElementType* vec, const SearchParams& searchParams) = 0;

protected:

    void setDataset(const Matrix<ElementType>& dataset)
    {
    	size_ = 0;
    	veclen_ = dataset.cols;
    	last_id_ = 0;

    	extendDataset(dataset);
    }

    void extendDataset(const Matrix<ElementType>& new_points)
    {
    	size_t new_size = size_ + new_points.rows;
    	removed_points_.resize(new_size);
    	ids_.resize(new_size);
    	points_.resize(new_size);
    	for (size_t i=size_;i<new_size;++i) {
    		ids_[i] = last_id_++;
    		points_[i] = new_points[i-size_];
    		removed_points_.reset(i);
    	}
    	size_ = new_size;
    }


    void cleanRemovedPoints()
    {
    	if (!removed_) return;

    	size_t last_idx = 0;
    	for (size_t i=0;i<size_;++i) {
    		if (!removed_points_.test(i)) {
    			points_[last_idx] = points_[i];
    			ids_[last_idx] = ids_[i];
    			removed_points_.reset(last_idx);
    			++last_idx;
    		}
    	}
    	points_.resize(last_idx);
    	ids_.resize(last_idx);
    	removed_points_.resize(last_idx);
    	size_ = last_idx;
    }



protected:

    struct PointInfo
    {
    	/** The point ID, returned by the nearest neighbour operations */
    	size_t id;
    	/** The point data */
    	ElementType* point;
    	/** Flag indicating the point was removed from the tree */
    	bool removed;
    };

    /**
     * Each index point has an associated ID. IDs are assigned sequentially in
     * increasing order. This indicates the ID assigned to the last point added to the
     * index.
     */
    size_t last_id_;

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
     * Array used to mark points removed from the index
     */
    DynamicBitset removed_points_;

    /**
     * Array of point IDs, returned by nearest-neighbour operations
     */
    std::vector<size_t> ids_;

    /**
     * Point data
     */
    std::vector<ElementType*> points_;

    /**
     * Flag indicating if at least a point was removed from the index
     */
    bool removed_;

};


#define USING_BASECLASS_SYMBOLS \
	using NNIndex<Distance>::size_;\
	using NNIndex<Distance>::veclen_;\
	using NNIndex<Distance>::index_params_;\
	using NNIndex<Distance>::removed_points_;\
	using NNIndex<Distance>::ids_;\
	using NNIndex<Distance>::removed_;\
	using NNIndex<Distance>::points_;\
	using NNIndex<Distance>::extendDataset;\
	using NNIndex<Distance>::setDataset;\
	using NNIndex<Distance>::cleanRemovedPoints;



}


#endif //FLANN_NNINDEX_H
