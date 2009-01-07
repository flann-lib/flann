/************************************************************************
 * VPTree approximate nearest neighbor search
 *
 * This module finds the nearest-neighbors of vectors in high dimensional
 * spaces using a search of multiple randomized k-d trees.
 *
 * Authors: David Lowe, initial implementation
 * 			Marius Muja, further changes
 *
 * Version: 1.0
 *
 * License: LGPL
 *
 *************************************************************************/

#ifndef VPTREE_H
#define VPTREE_H

#include <algorithm>
#include <map>
#include <cassert>
#include "Heap.h"
#include "common.h"
#include "Allocator.h"
#include "Dataset.h"
#include "ResultSet.h"
#include "Random.h"
#include "NNIndex.h"

using namespace std;


float sqdist(float* a, float* b, int len)
{
	return flann_dist(a, a+len ,b);
}

/**
 * VP-tree index
 *
 * Contains the vp-trees and other information for indexing a set of points
 * for nearest-neighbor matching.
 */
class VPTree : public NNIndex
{
	/**
	 * Number of randomized trees that are used
	 */
	int numTrees;

	/**
	 *  Array of indices to vectors in the dataset.  When doing lookup,
	 *  this is used instead to mark checkID.
	 */
	int* vind;

	/**
	 * An unique ID for each lookup.
	 */
	int checkID;

	/**
	 * The dataset used by this index
	 */
	Dataset<float>& dataset;

    int size_;
    int veclen_;


    float* mean;
    float* var;


	/*--------------------- Internal Data Structures --------------------------*/

	/**
	 * A node of the binary k-d tree.
	 *
	 *  This is   All nodes that have vec[idx] < divval are placed in the
	 *   child1 subtree, else child2., A leaf node is indicated if both children are NULL.
	 */
	struct TreeSt {
		/**
		 * Index of the vector feature used for subdivision.
		 * If this is a leaf node (both children are NULL) then
		 * this holds vector index for this leaf.
		 */
		int idx;
		/**
		 * The value used for subdivision.
		 */
		float divval;
		/**
		 * The child nodes.
		 */
		TreeSt *child1, *child2;
	};
	typedef TreeSt* Tree;

    /**
     * Array of k-d trees used to find neighbors.
     */
    Tree root;
    typedef BranchStruct<Tree> BranchSt;
    typedef BranchSt* Branch;
    /**
     * Priority queue storing intermediate branches in the best-bin-first search
     */
    Heap<BranchSt>* heap;


	/**
	 * Pooled memory allocator.
	 *
	 * Using a pooled memory allocator is more efficient
	 * than allocating memory directly when there is a large
	 * number small of memory allocations.
	 */
	PooledAllocator pool;



public:

    const char* name() const
    {
        return "vptree";
    }

	/**
	 * VPTree constructor
	 *
	 * Params:
	 * 		inputData = dataset with the input features
	 * 		params = parameters passed to the kdtree algorithm
	 */
	VPTree(Dataset<float>& inputData, Params params) : dataset(inputData)
	{
        size_ = dataset.rows;
        veclen_ = dataset.cols;

		heap = new Heap<BranchSt>(size_);

		// Create a permutable array of indices to the input vectors.
		vind = new int[size_];
		for (int i = 0; i < size_; i++) {
			vind[i] = i;
		}

	}

	/**
	 * Standard destructor
	 */
	~VPTree()
	{
		delete[] vind;
		delete heap;
	}


	/**
	 * Builds the index
	 */
	void buildIndex()
	{
		divideTree(&root, 0, size_ - 1);
	}


    /**
    *  Returns size of index.
    */
    int size() const
    {
        return size_;
    }

    /**
    * Returns the length of an index feature.
    */
    int veclen() const
    {
        return veclen_;
    }


	/**
	 * Computes the index memory usage
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
    void findNeighbors(ResultSet& result, float* vec, Params searchParams)
    {
        int maxChecks;
        if (searchParams.find("checks") == searchParams.end()) {
            maxChecks = -1;
        }
        else {
            maxChecks = (int)searchParams["checks"];
        }

        if (maxChecks<0) {
            getExactNeighbors(result, vec);
        } else {
            getNeighbors(result, vec, maxChecks);
        }
    }


    Params estimateSearchParams(float precision, Dataset<float>* testset = NULL)
    {
        Params params;

        return params;
    }


private:

	/**
	 * Create a tree node that subdivides the list of vecs from vind[first]
	 * to vind[last].  The routine is called recursively on each sublist.
	 * Place a pointer to this new tree node in the location pTree.
	 *
	 * Params: pTree = the new node to create
	 * 			first = index of the first vector
	 * 			last = index of the last vector
	 */
	void divideTree(Tree* pTree, int first, int last)
	{
		Tree node;

		node = pool.allocate<TreeSt>(); // allocate memory
		*pTree = node;

		/* If only one exemplar remains, then make this a leaf node. */
		if (first == last) {
			node->child1 = node->child2 = NULL;    /* Mark as leaf node. */
			node->idx = vind[first];    /* Store index of this vec. */
		} else {
			subdivide(node, first, last);
		}
	}


	struct VPComparator {
		const Dataset<float>& d;
		int vp;

		VPComparator(const Dataset<float>& _dataset, int _vp): d(_dataset),vp(_vp) {};

		bool operator()(int lhs, int rhs) {
			return flann_dist(d[vp], d[vp]+d.cols, d[lhs])<flann_dist(d[vp], d[vp]+d.cols, d[rhs]);
		}
	};


	int select_vp(int first, int last)
	{
		// select a random VP
		return rand_int(last+1,first);
	}

	/**
	 *  Subdivide the list of exemplars using the feature and division
	 *  value given in this node.  Call divideTree recursively on each list.
	 *
	 *  Precondition: first < last
	*/
	void subdivide(Tree node, int first, int last)
	{
		assert(first<last);

		node->idx = vind[select_vp(first,last)];

		int middle = (first+last+1)/2;
		VPComparator comparator(dataset, node->idx);
		nth_element(vind+first, vind+middle, vind+last, comparator);

		node->divval = flann_dist(dataset[vind[middle]], dataset[vind[middle]] + veclen_, dataset[node->idx]);

		divideTree(& node->child1, first, middle - 1);
		divideTree(& node->child2, middle, last);
	}



	/**
	 * Performs an exact nearest neighbour search. The exact search performs a full
	 * traversal of the tree.
	 */
	void getExactNeighbors(ResultSet& result, float* vec)
	{
//		checkID -= 1;  /* Set a different unique ID for each search. */
//
//		if (numTrees > 1) {
//            fprintf(stderr,"Doesn't make any sense to use more than one tree for exact search");
//		}
//		if (numTrees>0) {
//			searchLevelExact(result, vec, trees[0], 0.0);
//		}
//		assert(result.full());
	}

	/**
	 * Performs the approximate nearest-neighbour search. The search is approximate
	 * because the tree traversal is abandoned after a given number of descends in
	 * the tree.
	 */
	void getNeighbors(ResultSet& result, float* vec, int maxCheck)
	{
		int i;
		BranchSt branch;

		int checkCount = 0;
		heap->clear();
		checkID -= 1;  /* Set a different unique ID for each search. */

		/* Search once through each tree down to root. */
		searchLevel(result, vec, root, 0.0, checkCount, maxCheck);

		/* Keep searching other branches from heap until finished. */
		while ( heap->popMin(branch) && (checkCount < maxCheck || !result.full() )) {
			searchLevel(result, vec, branch.node, branch.mindistsq, checkCount, maxCheck);
		}

		assert(result.full());
	}


	/**
	 *  Search starting from a given node of the tree.  Based on any mismatches at
	 *  higher levels, all exemplars below this level must have a distance of
	 *  at least "mindistsq".
	*/
	void searchLevel(ResultSet& result, float* vec, Tree node, float mindistsq, int& checkCount, int maxCheck)
	{
		float val, diff;
		Tree bestChild;

		/* If this is a leaf node, then do check and return. */
		if (node->child1 == NULL  &&  node->child2 == NULL) {

			/* Do not check same node more than once when searching multiple trees.
				Once a vector is checked, we set its location in vind to the
				current checkID.
			*/
			if (checkCount>=maxCheck) {
				if (result.full()) return;
			}
            checkCount++;

			result.addPoint(dataset[node->idx],node->idx);
			return;
		}

		/* Which child branch should be taken first? */
		float qdist = flann_dist(vec, vec+veclen_, dataset[node->idx]);

		if (qdist < node->divval) {
			bestChild = node->child1;
//			if (result.worstDist() > node->divval-qdist) {
				heap->insert(BranchSt::make_branch(node->child2, node->divval-qdist));
//			}
		}
		else {
			bestChild = node->child2;
//			if (result.worstDist() > qdist - node->divval) {
				heap->insert(BranchSt::make_branch(node->child1, qdist-node->divval));
//			}
		}

		/* Call recursively to search next level down. */
		searchLevel(result, vec, bestChild, mindistsq, checkCount, maxCheck);
	}

	/**
	 * Performs an exact search in the tree starting from a node.
	 */
	void searchLevelExact(ResultSet& result, float* vec, Tree node, float mindistsq)
	{

	}

};   // class VPTree

register_index("vptree",VPTree)

#endif //VPTREE_H
