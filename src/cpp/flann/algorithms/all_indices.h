/***********************************************************************
 * Software License Agreement (BSD License)
 *
 * Copyright 2008-2009  Marius Muja (mariusm@cs.ubc.ca). All rights reserved.
 * Copyright 2008-2009  David G. Lowe (lowe@cs.ubc.ca). All rights reserved.
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


#ifndef FLANN_ALL_INDICES_H_
#define FLANN_ALL_INDICES_H_

#include "flann/general.h"

#include "flann/algorithms/nn_index.h"
#include "flann/algorithms/kdtree_index.h"
#include "flann/algorithms/kdtree_single_index.h"
#include "flann/algorithms/kdtree_cuda_3d_index.h"
#include "flann/algorithms/kmeans_index.h"
#include "flann/algorithms/composite_index.h"
#include "flann/algorithms/linear_index.h"
#include "flann/algorithms/hierarchical_clustering_index.h"
#include "flann/algorithms/lsh_index.h"
#include "flann/algorithms/autotuned_index.h"


namespace flann
{



class IndexBase
{
public:
	virtual ~IndexBase() {};

    virtual void buildIndex() = 0;

    virtual size_t veclen() const = 0;

    virtual size_t size() const = 0;

    virtual flann_algorithm_t getType() const = 0;

    virtual int usedMemory() const = 0;

    virtual IndexParams getParameters() const = 0;

    virtual int knnSearch(const Matrix_& queries,
    		Matrix_& indices,
    		Matrix_& dists,
    		size_t knn,
    		const SearchParams& params) = 0;

    virtual int radiusSearch(const Matrix_& queries,
    		Matrix_& indices,
    		Matrix_& dists,
    		float radius,
    		const SearchParams& params) = 0;
};


template<typename ElementType, typename DistanceType = typename Accumulator<ElementType>::Type>
class IndexTyped : public IndexBase
{
public:
	virtual int knnSearch(const Matrix<ElementType>& queries,
			Matrix<int>& indices,
			Matrix<DistanceType>& dists,
			size_t knn,
			const SearchParams& params) = 0;

	virtual int knnSearch(const Matrix<ElementType>& queries,
			std::vector< std::vector<int> >& indices,
			std::vector<std::vector<DistanceType> >& dists,
			size_t knn,
			const SearchParams& params) = 0;

	virtual int radiusSearch(const Matrix<ElementType>& queries,
			Matrix<int>& indices,
			Matrix<DistanceType>& dists,
			float radius,
			const SearchParams& params) = 0;

	virtual int radiusSearch(const Matrix<ElementType>& queries,
			std::vector< std::vector<int> >& indices,
			std::vector<std::vector<DistanceType> >& dists,
			float radius,
			const SearchParams& params) = 0;
};


template<typename Algorithm>
class IndexWrapper : public IndexTyped<typename Algorithm::ElementType, typename Algorithm::DistanceType>
{
public:
	typedef typename Algorithm::ElementType ElementType;
	typedef typename Algorithm::DistanceType DistanceType;

	IndexWrapper(Algorithm* index) : index_(index)
	{
	};

	virtual ~IndexWrapper()
	{
		delete index_;
	}

    void buildIndex()
    {
    	index_->buildIndex();
    }

    size_t veclen() const
    {
    	return index_->veclen();
    }

    size_t size() const
    {
    	return index_->size();
    }

    flann_algorithm_t getType() const
    {
    	return index_->getType();
    }

    int usedMemory() const
    {
    	return index_->usedMemory();
    }

    IndexParams getParameters() const
    {
    	return index_->getParameters();
    }

    int knnSearch(const Matrix_& queries,
    		Matrix_& indices,
    		Matrix_& dists,
    		size_t knn,
    		const SearchParams& params)
    {
    	Matrix<ElementType> _queries(queries);
    	Matrix<int> _indices(indices);
    	Matrix<DistanceType> _dists(dists);
    	return index_->knnSearch(_queries, _indices,_dists, knn, params);
    }

	int knnSearch(const Matrix<ElementType>& queries,
			Matrix<int>& indices,
			Matrix<DistanceType>& dists,
			size_t knn,
			const SearchParams& params)
    {
    	return index_->knnSearch(queries, indices,dists, knn, params);
    }

	int knnSearch(const Matrix<ElementType>& queries,
			std::vector< std::vector<int> >& indices,
			std::vector<std::vector<DistanceType> >& dists,
			size_t knn,
			const SearchParams& params)
	{
    	return index_->knnSearch(queries, indices,dists, knn, params);
	}

    int radiusSearch(const Matrix_& queries,
    		Matrix_& indices,
    		Matrix_& dists,
    		float radius,
    		const SearchParams& params)
    {
    	Matrix<ElementType> _queries(queries);
    	Matrix<int> _indices(indices);
    	Matrix<DistanceType> _dists(dists);
    	return index_->radiusSearch(_queries, _indices, _dists, radius, params);
    }

	int radiusSearch(const Matrix<ElementType>& queries,
			Matrix<int>& indices,
			Matrix<DistanceType>& dists,
			float radius,
			const SearchParams& params)
	{
    	return index_->radiusSearch(queries, indices, dists, radius, params);
	}

	int radiusSearch(const Matrix<ElementType>& queries,
			std::vector< std::vector<int> >& indices,
			std::vector<std::vector<DistanceType> >& dists,
			float radius,
			const SearchParams& params)
	{
    	return index_->radiusSearch(queries, indices, dists, radius, params);
	}

private:
	Algorithm* index_;
};




/**
 * enable_if sfinae helper
 */
template<bool, typename T = void> struct enable_if{};
template<typename T> struct enable_if<true,T> { typedef T type; };

/**
 * disable_if sfinae helper
 */
template<bool, typename T> struct disable_if{ typedef T type; };
template<typename T> struct disable_if<true,T> { };

/**
 * Check if two type are the same
 */
template <typename T, typename U>
struct same_type
{
    enum {value = false};
};

template<typename T>
struct same_type<T,T>
{
    enum {value = true};
};


/**
 * Checks if an index and a distance can be used together
 */
template<template <typename> class Index, typename Distance, typename ElementType>
struct valid_combination
{

#define HAS_MEMBER(member) \
    template<typename T> \
    struct member { \
        typedef char No; \
        typedef long Yes; \
        template<typename C> static Yes test( typename C::member* ); \
        template<typename C> static No test( ... ); \
        enum { value = sizeof (test<T>(0))==sizeof(Yes) }; \
    };

	HAS_MEMBER(needs_kdtree_distance)
	HAS_MEMBER(needs_vector_space_distance)
	HAS_MEMBER(is_kdtree_distance)
	HAS_MEMBER(is_vector_space_distance)

    static const bool value = same_type<ElementType,typename Distance::ElementType>::value &&
    				(!needs_kdtree_distance<Index<Distance> >::value || is_kdtree_distance<Distance>::value) &&
    				(!needs_vector_space_distance<Index<Distance> >::value || is_kdtree_distance<Distance>::value || is_vector_space_distance<Distance>::value);

};


/*********************************************************
 * Create index
 **********************************************************/
template <template<typename> class Index, typename Distance, typename T>
inline IndexWrapper<Index<Distance> >* create_index_(flann::Matrix<T> data, const flann::IndexParams& params, const Distance& distance,
		typename enable_if<valid_combination<Index,Distance,T>::value,void>::type* = 0)
{
	typedef Index<Distance> IndexType;
    return new IndexWrapper<IndexType>(new IndexType(data, params,distance));
}

template <template<typename> class Index, typename Distance, typename T>
inline IndexWrapper<Index<Distance> >* create_index_(flann::Matrix<T> data, const flann::IndexParams& params, const Distance& distance,
		typename disable_if<valid_combination<Index,Distance,T>::value,void>::type* = 0)
{
    return NULL;
}


template<typename Distance>
inline IndexTyped<typename Distance::ElementType, typename Distance::ResultType>*
  create_index_by_type(const flann_algorithm_t index_type,
		const Matrix<typename Distance::ElementType>& dataset, const IndexParams& params, const Distance& distance = Distance())
{
	typedef typename Distance::ElementType ElementType;

	IndexTyped<typename Distance::ElementType, typename Distance::ResultType>* nnIndex;
    switch (index_type) {
    case FLANN_INDEX_LINEAR:
        nnIndex = create_index_<LinearIndex,Distance,ElementType>(dataset, params, distance);
        break;
    case FLANN_INDEX_KDTREE_SINGLE:
        nnIndex = create_index_<KDTreeSingleIndex,Distance,ElementType>(dataset, params, distance);
        break;
    case FLANN_INDEX_KDTREE:
        nnIndex = create_index_<KDTreeIndex,Distance,ElementType>(dataset, params, distance);
        break;
		//! #define this symbol before including flann.h to enable GPU search algorithms. But you have
		//! to link libflann_cuda then!
	#ifdef FLANN_USE_CUDA
	case FLANN_INDEX_KDTREE_CUDA:
        nnIndex = create_index_<KDTreeCuda3dIndex,Distance,ElementType>(dataset, params, distance);
        break;
	#endif

    case FLANN_INDEX_KMEANS:
        nnIndex = create_index_<KMeansIndex,Distance,ElementType>(dataset, params, distance);
        break;
    case FLANN_INDEX_COMPOSITE:
        nnIndex = create_index_<CompositeIndex,Distance,ElementType>(dataset, params, distance);
        break;
    case FLANN_INDEX_AUTOTUNED:
        nnIndex = create_index_<AutotunedIndex,Distance,ElementType>(dataset, params, distance);
        break;
    case FLANN_INDEX_HIERARCHICAL:
        nnIndex = create_index_<HierarchicalClusteringIndex,Distance,ElementType>(dataset, params, distance);
        break;
    case FLANN_INDEX_LSH:
        nnIndex = create_index_<LshIndex,Distance,ElementType>(dataset, params, distance);
        break;
    default:
        throw FLANNException("Unknown index type");
    }

    if (nnIndex==NULL) {
    	throw FLANNException("Invalid index/distance combination");
    }
    return nnIndex;
}


template<typename T>
inline IndexBase* create_index_by_type_and_distance(const flann_algorithm_t index_type, const flann_distance_t distance_type,
		flann::Matrix<T> data, const flann::IndexParams& params)
{
	switch (distance_type)
	{
	case FLANN_DIST_L1:
		return  create_index_by_type<L1,T>(index_type, data, params);
	break;
	case FLANN_DIST_L2:
		return  create_index_by_type<L2,T>(index_type, data, params);
	break;
	case FLANN_DIST_HAMMING:
		return  create_index_by_type<Hamming,T>(index_type, data, params);
	break;
	case FLANN_DIST_HAMMING_LUT:
		return  create_index_by_type<HammingLUT,T>(index_type, data, params);
	break;
	case FLANN_DIST_HAMMING_POPCNT:
		return  create_index_by_type<HammingPopcnt,T>(index_type, data, params);
	break;
	}
}


}

#endif /* FLANN_ALL_INDICES_H_ */
