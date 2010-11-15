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

#ifndef KDTREE2_H
#define KDTREE2_H

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

using namespace std;


namespace flann
{

struct KDTreeIndex2Params : public IndexParams {
	KDTreeIndex2Params(int trees_ = 4, int leaf_max_size_ = 1) :
		IndexParams(KDTREE2), trees(trees_), leaf_max_size(leaf_max_size_) {};

	int trees;                 // number of randomized trees to use (for kdtree)
	int leaf_max_size;

	flann_algorithm_t getIndexType() const { return algorithm; }

	void fromParameters(const FLANNParameters& p)
	{
		assert(p.algorithm==algorithm);
		trees = p.trees;
	}

	void toParameters(FLANNParameters& p) const
	{
		p.algorithm = algorithm;
		p.trees = trees;
	}

	void print() const
	{
		logger.info("Index type: %d\n",(int)algorithm);
		logger.info("Trees: %d\n", trees);
	}

};


/**
 * Randomized kd-tree index
 *
 * Contains the k-d trees and other information for indexing a set of points
 * for nearest-neighbor matching.
 */
template <typename ELEM_TYPE, typename DIST_TYPE = typename DistType<ELEM_TYPE>::type >
class KDTreeIndex2 : public NNIndex<ELEM_TYPE>
{

	enum {
		/**
		 * To improve efficiency, only SAMPLE_MEAN random values are used to
		 * compute the mean and variance at each level when building a tree.
		 * A value of 100 seems to perform as well as using all values.
		 */
		SAMPLE_MEAN = 100,
		/**
		 * Top random dimensions to consider
		 *
		 * When creating random trees, the dimension on which to subdivide is
		 * selected at random from among the top RAND_DIM dimensions with the
		 * highest variance.  A value of 5 works well.
		 */
		RAND_DIM=5
	};


	/**
	 * Number of randomized trees that are used
	 */
	int numTrees;

	/**
	 *  Array of indices to vectors in the dataset.
	 */
	int* vind;

	int leaf_max_size_;


	/**
	 * The dataset used by this index
	 */
	const Matrix<ELEM_TYPE> dataset;

    const IndexParams& index_params;

	size_t size_;
	size_t veclen_;


    double* mean;
    double* var;


	/*--------------------- Internal Data Structures --------------------------*/

    enum CellType
    {
    	SPLIT,
    	LEAF
    };

//    struct Node{
//    	/**
//    	 * Type of node: SPLIT or LEAF
//    	 */
//    	CellType type;
//    };

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
		DIST_TYPE divlow, divhigh;
		/**
		 * Values indicating the borders of the cell in the splitting dimension
		 */
		DIST_TYPE lowval, highval;
		/**
		 * The child nodes.
		 */
		Node *child1, *child2;
    };

//	struct LeafNode : public Node {
//    	/**
//    	 * Array of indices
//    	 */
//    	int* indices;
//    	/**
//    	 * Number of indices
//    	 */
//    	int n;
//	};
	typedef Node* NodePtr;


	struct BoundingBox {

		ELEM_TYPE* low;
		ELEM_TYPE* high;
		size_t size;

		BoundingBox() {
			low = NULL;
			high = NULL;
		}

		~BoundingBox() {
			if (low!=NULL) delete[] low;
			if (high!=NULL) delete[] high;
		}

		void computeFromData(const Matrix<ELEM_TYPE>& data)
		{
			assert(data.rows>0);
			size = data.cols;
			low = new ELEM_TYPE[size];
			high = new ELEM_TYPE[size];

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
    NodePtr* trees;
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
	KDTreeIndex2(const Matrix<ELEM_TYPE>& inputData, const KDTreeIndex2Params& params = KDTreeIndex2Params() ) :
		dataset(inputData), index_params(params)
	{
        size_ = dataset.rows;
        veclen_ = dataset.cols;

        numTrees = params.trees;
        leaf_max_size_ = params.leaf_max_size;
        trees = new NodePtr[numTrees];

		// Create a permutable array of indices to the input vectors.
		vind = new int[size_];
		for (size_t i = 0; i < size_; i++) {
			vind[i] = i;
		}

		bbox.computeFromData(dataset);

        mean = new double[veclen_];
        var = new double[veclen_];

        count_leaf = 0;
	}

	/**
	 * Standard destructor
	 */
	~KDTreeIndex2()
	{
		delete[] vind;
		if (trees!=NULL) {
			delete[] trees;
		}
		delete[] mean;
        delete[] var;
	}


	/**
	 * Builds the index
	 */
	void buildIndex()
	{
		/* Construct the randomized trees. */
		for (int i = 0; i < numTrees; i++) {
			/* Randomize the order of vectors to allow for unbiased sampling. */
			for (int j = size_; j > 0; --j) {
				int rnd = rand_int(j);
				swap(vind[j-1], vind[rnd]);
			}
			trees[i] = divideTree(vind, size_ );
		}
	}



    void saveIndex(FILE* stream)
    {
    	save_value(stream, numTrees);
    	for (int i=0;i<numTrees;++i) {
    		save_tree(stream, trees[i]);
    	}
    }



    void loadIndex(FILE* stream)
    {
    	load_value(stream, numTrees);

    	if (trees!=NULL) {
    		delete[] trees;
    	}
    	trees = new NodePtr[numTrees];
    	for (int i=0;i<numTrees;++i) {
    		load_tree(stream,trees[i]);
    	}
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
    void findNeighbors(ResultSet<ELEM_TYPE>& result, const ELEM_TYPE* vec, const SearchParams& searchParams)
    {
        int maxChecks = searchParams.checks;
        float epsError = 1+searchParams.eps;

        if (maxChecks<0) {
            getExactNeighbors(result, vec, epsError);
        } else {
            getNeighbors(result, vec, maxChecks);
        }
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

		/* If only one exemplar remains, then make this a leaf node. */
		if ( count <= leaf_max_size_) {
			node->child1 = node->child2 = NULL;    /* Mark as leaf node. */
			node->ind = ind;    /* Store index of this vec. */
			node->count = count;
		}
		else {
			int idx;
			int cutfeat;
			DIST_TYPE cutval;

			middleSplit(ind, count, idx, cutfeat, cutval);

			node->divfeat = cutfeat;
			node->lowval = bbox.low[cutfeat];
			node->highval = bbox.high[cutfeat];

			ELEM_TYPE min_val, max_val;
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

	ELEM_TYPE computeSpead(int* ind, int count, int dim)
	{
		ELEM_TYPE min_elem = dataset[ind[0]][dim];
		ELEM_TYPE max_elem = dataset[ind[0]][dim];
		for (int i=1;i<count;++i) {
			ELEM_TYPE val = dataset[ind[i]][dim];
			if (val<min_elem) min_elem = val;
			if (val>max_elem) max_elem = val;
		}
		return max_elem-min_elem;
	}

	void computeMinMax(int* ind, int count, int dim, ELEM_TYPE& min_elem, ELEM_TYPE& max_elem)
	{
		min_elem = dataset[ind[0]][dim];
		max_elem = dataset[ind[0]][dim];
		for (int i=1;i<count;++i) {
			ELEM_TYPE val = dataset[ind[i]][dim];
			if (val<min_elem) min_elem = val;
			if (val>max_elem) max_elem = val;
		}
	}

	void middleSplit(int* ind, int count, int& index, int& cutfeat, DIST_TYPE& cutval)
	{
		const float EPS=0.0001;
		ELEM_TYPE max_span = bbox.high[0]-bbox.low[0];
		for (size_t i=1;i<veclen_;++i) {
			ELEM_TYPE span = bbox.high[i]-bbox.low[i];
			if (span>max_span) {
				max_span = span;
			}
		}

		ELEM_TYPE max_spread = -1;
		cutfeat = 0;
		for (size_t i=0;i<veclen_;++i) {
			ELEM_TYPE span = bbox.high[i]-bbox.low[i];
			if (span>(1-EPS)*max_span) {
				ELEM_TYPE spread = computeSpead(ind, count, i);
				if (spread>max_spread) {
					cutfeat = i;
					max_spread = spread;
				}
			}
		}
		// split in the middle
		DIST_TYPE split_val = (bbox.low[cutfeat]+bbox.high[cutfeat])/2;
		ELEM_TYPE min_elem, max_elem;
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
	 * Choose which feature to use in order to subdivide this set of vectors.
	 * Make a random choice among those with the highest variance, and use
	 * its variance as the threshold value.
	 */
	void meanSplit(int* ind, int count, int& index, int& cutfeat, DIST_TYPE& cutval)
	{
        memset(mean,0,veclen_*sizeof(double));
        memset(var,0,veclen_*sizeof(double));

		/* Compute mean values.  Only the first SAMPLE_MEAN values need to be
			sampled to get a good estimate.
		*/
        for (size_t k=0; k<veclen_; ++k) {
            mean[k] = 0;
        }

		int cnt = min((int)SAMPLE_MEAN, count);
		for (int j = 0; j < cnt; ++j) {
			ELEM_TYPE* v = dataset[ind[j]];
            for (size_t k=0; k<veclen_; ++k) {
                mean[k] += v[k];
            }
		}
        for (size_t k=0; k<veclen_; ++k) {
            mean[k] /= cnt;
        }

		/* Compute variances (no need to divide by count). */
		for (int j = 0; j < cnt; ++j) {
			ELEM_TYPE* v = dataset[ind[j]];
            for (size_t k=0; k<veclen_; ++k) {
                DIST_TYPE dist = v[k] - mean[k];
                var[k] += dist * dist;
            }
		}
		/* Select one of the highest variance indices at random. */
		cutfeat = selectDivision(var);
		cutval = mean[cutfeat];
		int lim1, lim2;
		planeSplit(ind, count, cutfeat, cutval, lim1, lim2);

		if (lim1>count/2) index = lim1;
		else if (lim2<count/2) index = lim2;
		else index = count/2;

		// in the unlikely case all values are equal
		if (lim1==cnt || lim2==0) index = count/2;
	}


	/**
	 * Select the top RAND_DIM largest values from v and return the index of
	 * one of these selected at random.
	 */
	int selectDivision(double* v)
	{
		int num = 0;
		int topind[RAND_DIM];

		/* Create a list of the indices of the top RAND_DIM values. */
		for (size_t i = 0; i < veclen_; ++i) {
			if (num < RAND_DIM  ||  v[i] > v[topind[num-1]]) {
				/* Put this element at end of topind. */
				if (num < RAND_DIM) {
					topind[num++] = i;            /* Add to list. */
				}
				else {
					topind[num-1] = i;         /* Replace last element. */
				}
				/* Bubble end value down to right location by repeated swapping. */
				int j = num - 1;
				while (j > 0  &&  v[topind[j]] > v[topind[j-1]]) {
					swap(topind[j], topind[j-1]);
					--j;
				}
			}
		}
		/* Select a random integer in range [0,num-1], and return that index. */
		int rnd = rand_int(num);
		return topind[rnd];
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
	void planeSplit(int* ind, int count, int cutfeat, DIST_TYPE cutval, int& lim1, int& lim2)
	{
		/* Move vector indices for left subtree to front of list. */
		int left = 0;
		int right = count-1;
		for (;;) {
			while (left<=right && dataset[ind[left]][cutfeat]<cutval) ++left;
			while (left<=right && dataset[ind[right]][cutfeat]>=cutval) --right;
			if (left>right) break;
			swap(ind[left], ind[right]); ++left; --right;
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
			swap(ind[left], ind[right]); ++left; --right;
		}
		lim2 = left;
	}



	float computeInitialDistance(const ELEM_TYPE* vec)
	{
		float distsq = 0.0;

		for (size_t i=0;i<veclen();++i) {
			if (vec[i]<bbox.low[i]) distsq += flann_dist(vec+i, vec+i+1, bbox.low+i);
			if (vec[i]>bbox.high[i]) distsq += flann_dist(vec+i, vec+i+1, bbox.high+i);
		}

		return distsq;
	}


	/**
	 * Performs an exact nearest neighbor search. The exact search performs a full
	 * traversal of the tree.
	 */
	void getExactNeighbors(ResultSet<ELEM_TYPE>& result, const ELEM_TYPE* vec, float epsError)
	{
//		checkID -= 1;  /* Set a different unique ID for each search. */

		if (numTrees > 1) {
            fprintf(stderr,"It doesn't make any sense to use more than one tree for exact search");
		}
		if (numTrees>0) {
			float distsq = computeInitialDistance(vec);
			searchLevelExact(result, vec, trees[0], distsq, epsError);
		}
		assert(result.full());
	}

	/**
	 * Performs the approximate nearest-neighbor search. The search is approximate
	 * because the tree traversal is abandoned after a given number of descends in
	 * the tree.
	 */
	void getNeighbors(ResultSet<ELEM_TYPE>& result, const ELEM_TYPE* vec, int maxCheck)
	{
		int i;
		BranchSt branch;

		int checkCount = 0;
		Heap<BranchSt>* heap = new Heap<BranchSt>(size_);
		vector<bool> checked(size_,false);

		/* Search once through each tree down to root. */
		for (i = 0; i < numTrees; ++i) {
			searchLevel(result, vec, trees[i], 0.0, checkCount, maxCheck, heap, checked);
		}

		/* Keep searching other branches from heap until finished. */
		while ( heap->popMin(branch) && (checkCount < maxCheck || !result.full() )) {
			searchLevel(result, vec, branch.node, branch.mindistsq, checkCount, maxCheck, heap, checked);
		}

		delete heap;

		assert(result.full());
	}


	/**
	 *  Search starting from a given node of the tree.  Based on any mismatches at
	 *  higher levels, all exemplars below this level must have a distance of
	 *  at least "mindistsq".
	*/
	void searchLevel(ResultSet<ELEM_TYPE>& result, const ELEM_TYPE* vec, NodePtr node, float mindistsq, int& checkCount, int maxCheck,
			Heap<BranchSt>* heap, vector<bool>& checked)
	{
		if (result.worstDist()<mindistsq) {
//			printf("Ignoring branch, too far\n");
			return;
		}

		/* If this is a leaf node, then do check and return. */
		if (node->child1 == NULL  &&  node->child2 == NULL) {

			/* Do not check same node more than once when searching multiple trees.
				Once a vector is checked, we set its location in vind to the
				current checkID.
			*/
			if (checked[node->divfeat] == true || checkCount>=maxCheck) {
				if (result.full()) return;
			}
            checkCount++;
			checked[node->divfeat] = true;

			result.addPoint(dataset[node->divfeat],node->divfeat);
			return;
		}

		/* Which child branch should be taken first? */
		ELEM_TYPE val = vec[node->divfeat];
		DIST_TYPE diff = val - node->divlow;
		NodePtr bestChild = (diff < 0) ? node->child1 : node->child2;
		NodePtr otherChild = (diff < 0) ? node->child2 : node->child1;

		/* Create a branch record for the branch not taken.  Add distance
			of this feature boundary (we don't attempt to correct for any
			use of this feature in a parent node, which is unlikely to
			happen and would have only a small effect).  Don't bother
			adding more branches to heap after halfway point, as cost of
			adding exceeds their value.
		*/

		DIST_TYPE new_distsq = flann_dist(&val, &val+1, &node->divlow, mindistsq);
//		if (2 * checkCount < maxCheck  ||  !result.full()) {
		if (new_distsq < result.worstDist() ||  !result.full()) {
			heap->insert( BranchSt::make_branch(otherChild, new_distsq) );
		}

		/* Call recursively to search next level down. */
		searchLevel(result, vec, bestChild, mindistsq, checkCount, maxCheck, heap, checked);
	}

	template <typename T>
	double accum_dist(double old_val, const T& a, const T& b)
	{
		return (a-b)*(a-b);
	}

	/**
	 * Performs an exact search in the tree starting from a node.
	 */
	void searchLevelExact(ResultSet<ELEM_TYPE>& result_set, const ELEM_TYPE* vec, const NodePtr node, float mindistsq, const float epsError)
	{
		/* If this is a leaf node, then do check and return. */
		if (node->child1 == NULL && node->child2 == NULL) {
//			printf("node: %d, cnt: %d, depth: %d\n", node->divfeat, cnt, depth);
			count_leaf++;
			for (int i=0;i<node->count;++i) {
				result_set.addPoint(dataset[node->ind[i]],node->ind[i]);
			}
			return;
		}

		/* Which child branch should be taken first? */
		ELEM_TYPE val = vec[node->divfeat];
		DIST_TYPE diff1 = val - node->divlow;
		DIST_TYPE diff2 = val - node->divhigh;

		NodePtr bestChild;
		NodePtr otherChild;
		float cut_dist = 0;
		if ((diff1+diff2)<0) {
			bestChild = node->child1;

			otherChild = node->child2;
			cut_dist = accum_dist(mindistsq, val, node->divhigh);
			if (val<node->lowval) {  // outside of cell, correct distance
				cut_dist -= accum_dist(mindistsq, val, node->lowval);
			}
		}
		else {
			bestChild = node->child2;

			otherChild = node->child1;
			cut_dist = accum_dist(mindistsq, val, node->divlow);
			if (val>node->highval) {  // outside of cell, correct distance
				cut_dist -= accum_dist(mindistsq, val, node->highval);
			}
		}

		/* Call recursively to search next level down. */
		searchLevelExact(result_set, vec, bestChild, mindistsq, epsError);

		mindistsq = mindistsq + cut_dist;
		if (mindistsq*epsError<=result_set.worstDist()) {
			searchLevelExact(result_set, vec, otherChild, mindistsq, epsError);
		}
	}

};   // class KDTree

}

#endif //KDTREE2_H
