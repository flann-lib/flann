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

#ifndef KDTREESINGLE_H
#define KDTREESINGLE_H

#include <algorithm>
#include <map>
#include <cassert>
#include <cstring>

#include "flann/general.h"
#include "flann/algorithms/nn_index.h"
#include "flann/util/matrix.h"
#include "flann/util/result_set.h"
#include "flann/util/heap.h"
#include "flann/util/allocator.h"
#include "flann/util/random.h"
#include "flann/util/saving.h"

namespace flann
{

struct KDTreeSingleIndexParams : public IndexParams {
	KDTreeSingleIndexParams(int leaf_max_size_ = 10) :
		IndexParams(KDTREE_SINGLE), leaf_max_size(leaf_max_size_) {};

	int leaf_max_size;

	flann_algorithm_t getIndexType() const { return algorithm; }

	void fromParameters(const FLANNParameters& p)
	{
		assert(p.algorithm==algorithm);
//		trees = p.trees;
	}

	void toParameters(FLANNParameters& p) const
	{
		p.algorithm = algorithm;
//		p.trees = trees;
	}

	void print() const
	{
		logger.info("Index type: %d\n",(int)algorithm);
//		logger.info("Trees: %d\n", trees);
	}

};


/**
 * Randomized kd-tree index
 *
 * Contains the k-d trees and other information for indexing a set of points
 * for nearest-neighbor matching.
 */
template <typename Distance>
class KDTreeSingleIndex : public NNIndex<Distance>
{
	typedef typename Distance::ElementType ElementType;
	typedef typename Distance::ResultType DistanceType;

	/**
	 *  Array of indices to vectors in the dataset.
	 */
	int* vind;

	int leaf_max_size_;


	/**
	 * The dataset used by this index
	 */
	const Matrix<ElementType> dataset;

    const IndexParams& index_params;

	size_t size_;
	size_t veclen_;


	/*--------------------- Internal Data Structures --------------------------*/
    struct Node {
    	int *ind;
    	int count;
    	/**
    	 * Dimension used for subdivision.
    	 */
    	int divfeat;
		/**
		 * The values used for subdivision.
		 */
		DistanceType divlow, divhigh;
		/**
		 * Values indicating the borders of the cell in the splitting dimension
		 */
		DistanceType lowval, highval;
		/**
		 * The child nodes.
		 */
		Node *child1, *child2;
    };
	typedef Node* NodePtr;

	struct BoundingBox {
		ElementType* low;
		ElementType* high;
		size_t size;

		BoundingBox() {
			low = NULL;
			high = NULL;
		}

		~BoundingBox() {
			if (low!=NULL) delete[] low;
			if (high!=NULL) delete[] high;
		}

		void computeFromData(const Matrix<ElementType>& data)
		{
			assert(data.rows>0);
			size = data.cols;
			low = new ElementType[size];
			high = new ElementType[size];

			for (size_t i=0;i<size;++i) {
				low[i] = data[0][i];
				high[i] = data[0][i];
			}

			for (size_t k=1;k<data.rows;++k) {
				for (size_t i=0;i<size;++i) {
					if (data[k][i]<low[i]) low[i] = data[k][i];
					if (data[k][i]>high[i]) high[i] = data[k][i];
				}
			}
		}
	};

    /**
     * Array of k-d trees used to find neighbours.
     */
    NodePtr root_node;
    typedef BranchStruct<NodePtr> BranchSt;
    typedef BranchSt* Branch;

    BoundingBox bbox;

	/**
	 * Pooled memory allocator.
	 *
	 * Using a pooled memory allocator is more efficient
	 * than allocating memory directly when there is a large
	 * number small of memory allocations.
	 */
	PooledAllocator pool;

public:

	Distance distance;

	int count_leaf;


    flann_algorithm_t getType() const
    {
        return KDTREE;
    }

	/**
	 * KDTree constructor
	 *
	 * Params:
	 * 		inputData = dataset with the input features
	 * 		params = parameters passed to the kdtree algorithm
	 */
	KDTreeSingleIndex(const Matrix<ElementType>& inputData, const KDTreeSingleIndexParams& params = KDTreeSingleIndexParams(),
			Distance d = Distance() ) :
		dataset(inputData), index_params(params), distance(d)
	{
        size_ = dataset.rows;
        veclen_ = dataset.cols;
        leaf_max_size_ = params.leaf_max_size;

		// Create a permutable array of indices to the input vectors.
		vind = new int[size_];
		for (size_t i = 0; i < size_; i++) {
			vind[i] = i;
		}
		randomizeVector(vind, size_);
		bbox.computeFromData(dataset);

        count_leaf = 0;
	}

	/**
	 * Standard destructor
	 */
	~KDTreeSingleIndex()
	{
		delete[] vind;
	}


	template <typename Vector>
	void randomizeVector(Vector& vec, int vec_size)
	{
		for (int j = vec_size; j > 0; --j) {
			int rnd = rand_int(j);
			std::swap(vec[j-1], vec[rnd]);
		}
	}

	/**
	 * Builds the index
	 */
	void buildIndex()
	{
		root_node = divideTree(vind, size_ ); 	// construct the tree
	}

    void saveIndex(FILE* stream)
    {
    	save_tree(stream, root_node);
    }


    void loadIndex(FILE* stream)
    {
    	load_tree(stream, root_node);
    }

    /**
    *  Returns size of index.
    */
    size_t size() const
    {
        return size_;
    }

    /**
    * Returns the length of an index feature.
    */
    size_t veclen() const
    {
        return veclen_;
    }

	/**
	 * Computes the inde memory usage
	 * Returns: memory used by the index
	 */
	int usedMemory() const
	{
		return  pool.usedMemory+pool.wastedMemory+dataset.rows*sizeof(int);   // pool memory and vind array memory
	}

    /**
     * Find set of nearest neighbors to vec. Their indices are stored inside
     * the result object.
     *
     * Params:
     *     result = the result object in which the indices of the nearest-neighbors are stored
     *     vec = the vector for which to search the nearest neighbors
     *     maxCheck = the maximum number of restarts (in a best-bin-first manner)
     */
    void findNeighbors(ResultSet<DistanceType>& result, const ElementType* vec, const SearchParams& searchParams)
    {
//        int maxChecks = searchParams.checks;
        float epsError = 1+searchParams.eps;

		float distsq = computeInitialDistance(vec);
		searchLevel(result, vec, root_node, distsq, epsError);
    }

	const IndexParams* getParameters() const
	{
		return &index_params;
	}

private:


    void save_tree(FILE* stream, NodePtr tree)
    {
    	save_value(stream, *tree);
    	if (tree->child1!=NULL) {
    		save_tree(stream, tree->child1);
    	}
    	if (tree->child2!=NULL) {
    		save_tree(stream, tree->child2);
    	}
    }


    void load_tree(FILE* stream, NodePtr& tree)
    {
    	tree = pool.allocate<Node>();
    	load_value(stream, *tree);
    	if (tree->child1!=NULL) {
    		load_tree(stream, tree->child1);
    	}
    	if (tree->child2!=NULL) {
    		load_tree(stream, tree->child2);
    	}
    }


	/**
	 * Create a tree node that subdivides the list of vecs from vind[first]
	 * to vind[last].  The routine is called recursively on each sublist.
	 * Place a pointer to this new tree node in the location pTree.
	 *
	 * Params: pTree = the new node to create
	 * 			first = index of the first vector
	 * 			last = index of the last vector
	 */
	NodePtr divideTree(int* ind, int count)
	{
		NodePtr node = pool.allocate<Node>(); // allocate memory

		/* If too few exemplars remain, then make this a leaf node. */
		if ( count <= leaf_max_size_) {
			node->child1 = node->child2 = NULL;    /* Mark as leaf node. */
			node->ind = ind;    /* Store index of this vec. */
			node->count = count; /* and length */
		}
		else {
			int idx;
			int cutfeat;
			DistanceType cutval;
			ElementType min_val, max_val;

			middleSplit(ind, count, idx, cutfeat, cutval);

			node->divfeat = cutfeat;
			node->lowval = bbox.low[cutfeat];
			node->highval = bbox.high[cutfeat];

			computeMinMax(ind, idx, cutfeat, min_val, max_val);
			bbox.high[cutfeat] = max_val;
			node->divlow = max_val;
			node->child1 = divideTree(ind, idx);
			bbox.high[cutfeat] = node->highval;

			computeMinMax(ind+idx, count-idx, cutfeat, min_val, max_val);
			bbox.low[cutfeat] = min_val;
			node->divhigh = min_val;
			node->child2 = divideTree(ind+idx, count-idx);
			bbox.low[cutfeat] = node->lowval;
		}

		return node;
	}

	ElementType computeSpead(int* ind, int count, int dim)
	{
		ElementType min_elem, max_elem;
		computeMinMax(ind, count, dim, min_elem, max_elem);
		return max_elem-min_elem;
	}

	void computeMinMax(int* ind, int count, int dim, ElementType& min_elem, ElementType& max_elem)
	{
		min_elem = dataset[ind[0]][dim];
		max_elem = dataset[ind[0]][dim];
		for (int i=1;i<count;++i) {
			ElementType val = dataset[ind[i]][dim];
			if (val<min_elem) min_elem = val;
			if (val>max_elem) max_elem = val;
		}
	}

	void middleSplit(int* ind, int count, int& index, int& cutfeat, DistanceType& cutval)
	{
		const float EPS=0.00001;
		ElementType max_span = bbox.high[0]-bbox.low[0];
		for (size_t i=1;i<veclen_;++i) {
			ElementType span = bbox.high[i]-bbox.low[i];
			if (span>max_span) {
				max_span = span;
			}
		}
		ElementType max_spread = -1;
		cutfeat = 0;
		for (size_t i=0;i<veclen_;++i) {
			ElementType span = bbox.high[i]-bbox.low[i];
			if (span>(1-EPS)*max_span) {
				ElementType spread = computeSpead(ind, count, i);
				if (spread>max_spread) {
					cutfeat = i;
					max_spread = spread;
				}
			}
		}
		// split in the middle
		DistanceType split_val = (bbox.low[cutfeat]+bbox.high[cutfeat])/2;
		ElementType min_elem, max_elem;
		computeMinMax(ind, count, cutfeat, min_elem, max_elem);

		if (split_val<min_elem) cutval = min_elem;
		else if (split_val>max_elem) cutval = max_elem;
		else cutval = split_val;

		int lim1, lim2;
		planeSplit(ind, count, cutfeat, cutval, lim1, lim2);

		if (lim1>count/2) index = lim1;
		else if (lim2<count/2) index = lim2;
		else index = count/2;
	}


	/**
	 *  Subdivide the list of points by a plane perpendicular on axe corresponding
	 *  to the 'cutfeat' dimension at 'cutval' position.
	 *
	 *  On return:
	 *  dataset[ind[0..lim1-1]][cutfeat]<cutval
	 *  dataset[ind[lim1..lim2-1]][cutfeat]==cutval
	 *  dataset[ind[lim2..count]][cutfeat]>cutval
	*/
	void planeSplit(int* ind, int count, int cutfeat, DistanceType cutval, int& lim1, int& lim2)
	{
		/* Move vector indices for left subtree to front of list. */
		int left = 0;
		int right = count-1;
		for (;;) {
			while (left<=right && dataset[ind[left]][cutfeat]<cutval) ++left;
			while (left<=right && dataset[ind[right]][cutfeat]>=cutval) --right;
			if (left>right) break;
			std::swap(ind[left], ind[right]); ++left; --right;
		}
		/* If either list is empty, it means that all remaining features
		 * are identical. Split in the middle to maintain a balanced tree.
		*/
		lim1 = left;
		right = count-1;
		for (;;) {
			while (left<=right && dataset[ind[left]][cutfeat]<=cutval) ++left;
			while (left<=right && dataset[ind[right]][cutfeat]>cutval) --right;
			if (left>right) break;
			std::swap(ind[left], ind[right]); ++left; --right;
		}
		lim2 = left;
	}

	float computeInitialDistance(const ElementType* vec)
	{
		float distsq = 0.0;

		for (size_t i=0;i<veclen();++i) {
			if (vec[i]<bbox.low[i]) distsq += distance.accum_dist(vec[i], bbox.low[i]);
			if (vec[i]>bbox.high[i]) distsq += distance.accum_dist(vec[i], bbox.high[i]);
		}

		return distsq;
	}

	/**
	 * Performs an exact search in the tree starting from a node.
	 */
	void searchLevel(ResultSet<DistanceType>& result_set, const ElementType* vec, const NodePtr node, float mindistsq, const float epsError)
	{
		/* If this is a leaf node, then do check and return. */
		if (node->child1 == NULL && node->child2 == NULL) {
			count_leaf += node->count;
			float worst_dist = result_set.worstDist();
			for (int i=0;i<node->count;++i) {
				int index = node->ind[i];
				float dist = distance(vec, dataset[index], veclen_, worst_dist);
				if (dist<worst_dist) {
					result_set.addPoint(dist,index);
				}
			}
			return;
		}

		/* Which child branch should be taken first? */
		ElementType val = vec[node->divfeat];
		DistanceType diff1 = val - node->divlow;
		DistanceType diff2 = val - node->divhigh;

		NodePtr bestChild;
		NodePtr otherChild;
		float cut_dist = 0;
		if ((diff1+diff2)<0) {
			bestChild = node->child1;

			otherChild = node->child2;
			cut_dist = distance.accum_dist(val, node->divhigh);
			if (val<node->lowval) {  // outside of cell, correct distance
				cut_dist -= distance.accum_dist(val, node->lowval);
			}
		}
		else {
			bestChild = node->child2;

			otherChild = node->child1;
			cut_dist = distance.accum_dist( val, node->divlow);
			if (val>node->highval) {  // outside of cell, correct distance
				cut_dist -= distance.accum_dist(val, node->highval);
			}
		}

		/* Call recursively to search next level down. */
		searchLevel(result_set, vec, bestChild, mindistsq, epsError);

		mindistsq = mindistsq + cut_dist;
		if (mindistsq*epsError<=result_set.worstDist()) {
			searchLevel(result_set, vec, otherChild, mindistsq, epsError);
		}
	}

};   // class KDTree

}

#endif //KDTREESINGLE_H
