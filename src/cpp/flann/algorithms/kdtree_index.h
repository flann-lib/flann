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

#ifndef KDTREE_H
#define KDTREE_H

#include <algorithm>
#include <map>
#include <cassert>
#include <cstring>

#include "flann/general.h"
#include "flann/algorithms/nn_index.h"
#include "flann/util/matrix.h"
#include "flann/util/result_set.h"
#include "flann/util/heap.h"
#include "flann/util/logger.h"
#include "flann/util/allocator.h"
#include "flann/util/random.h"
#include "flann/util/saving.h"


namespace flann
{

struct KDTreeIndexParams : public IndexParams
{
    KDTreeIndexParams(int trees_ = 4) :
        IndexParams(FLANN_INDEX_KDTREE), trees(trees_) {}

    int trees;                 // number of randomized trees to use (for kdtree)

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
template <typename Distance>
class KDTreeIndex : public NNIndex<Distance>
{
public:
    typedef typename Distance::ElementType ElementType;
    typedef typename Distance::ResultType DistanceType;
private:

    enum
    {
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

    /**
     * The dataset used by this index
     */
    const Matrix<ElementType> dataset;

    const KDTreeIndexParams index_params;

    size_t size_;
    size_t veclen_;


    DistanceType* mean;
    DistanceType* var;


    /*--------------------- Internal Data Structures --------------------------*/
    struct Node
    {
        /**
         * Dimension used for subdivision.
         */
        int divfeat;
        /**
         * The values used for subdivision.
         */
        DistanceType divval;
        /**
         * The child nodes.
         */
        Node* child1, * child2;
    };
    typedef Node* NodePtr;



    /**
     * Array of k-d trees used to find neighbours.
     */
    NodePtr* trees;
    typedef BranchStruct<NodePtr, DistanceType> BranchSt;
    typedef BranchSt* Branch;

    /**
     * Pooled memory allocator.
     *
     * Using a pooled memory allocator is more efficient
     * than allocating memory directly when there is a large
     * number small of memory allocations.
     */
    PooledAllocator pool;

    Distance distance;

public:

    flann_algorithm_t getType() const
    {
        return FLANN_INDEX_KDTREE;
    }

    /**
     * KDTree constructor
     *
     * Params:
     *          inputData = dataset with the input features
     *          params = parameters passed to the kdtree algorithm
     */
    KDTreeIndex(const Matrix<ElementType>& inputData, const KDTreeIndexParams& params = KDTreeIndexParams(),
                Distance d = Distance() ) :
        dataset(inputData), index_params(params), distance(d)
    {
        size_ = dataset.rows;
        veclen_ = dataset.cols;

        numTrees = params.trees;
        trees = new NodePtr[numTrees];

        // Create a permutable array of indices to the input vectors.
        vind = new int[size_];
        for (size_t i = 0; i < size_; i++) {
            vind[i] = i;
        }

        mean = new DistanceType[veclen_];
        var = new DistanceType[veclen_];
    }

    /**
     * Standard destructor
     */
    ~KDTreeIndex()
    {
        delete[] vind;
        if (trees!=NULL) {
            delete[] trees;
        }
        delete[] mean;
        delete[] var;
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
        /* Construct the randomized trees. */
        for (int i = 0; i < numTrees; i++) {
            /* Randomize the order of vectors to allow for unbiased sampling. */
            randomizeVector(vind, size_);
            trees[i] = divideTree(vind, size_ );
        }
    }

    void saveIndex(FILE* stream)
    {
        save_value(stream, numTrees);
        for (int i=0; i<numTrees; ++i) {
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
        for (int i=0; i<numTrees; ++i) {
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
        return pool.usedMemory+pool.wastedMemory+dataset.rows*sizeof(int);  // pool memory and vind array memory
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
        int maxChecks = searchParams.checks;
        float epsError = 1+searchParams.eps;

        if (maxChecks==FLANN_CHECKS_UNLIMITED) {
            getExactNeighbors(result, vec, epsError);
        }
        else {
            getNeighbors(result, vec, maxChecks, epsError);
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
     *                  first = index of the first vector
     *                  last = index of the last vector
     */
    NodePtr divideTree(int* ind, int count)
    {
        NodePtr node = pool.allocate<Node>(); // allocate memory

        /* If too few exemplars remain, then make this a leaf node. */
        if ( count == 1) {
            node->child1 = node->child2 = NULL;    /* Mark as leaf node. */
            node->divfeat = *ind;    /* Store index of this vec. */
        }
        else {
            int idx;
            int cutfeat;
            DistanceType cutval;
            meanSplit(ind, count, idx, cutfeat, cutval);

            node->divfeat = cutfeat;
            node->divval = cutval;
            node->child1 = divideTree(ind, idx);
            node->child2 = divideTree(ind+idx, count-idx);
        }

        return node;
    }


    /**
     * Choose which feature to use in order to subdivide this set of vectors.
     * Make a random choice among those with the highest variance, and use
     * its variance as the threshold value.
     */
    void meanSplit(int* ind, int count, int& index, int& cutfeat, DistanceType& cutval)
    {
        memset(mean,0,veclen_*sizeof(DistanceType));
        memset(var,0,veclen_*sizeof(DistanceType));

        /* Compute mean values.  Only the first SAMPLE_MEAN values need to be
            sampled to get a good estimate.
         */
        int cnt = std::min((int)SAMPLE_MEAN+1, count);
        for (int j = 0; j < cnt; ++j) {
            ElementType* v = dataset[ind[j]];
            for (size_t k=0; k<veclen_; ++k) {
                mean[k] += v[k];
            }
        }
        for (size_t k=0; k<veclen_; ++k) {
            mean[k] /= cnt;
        }

        /* Compute variances (no need to divide by count). */
        for (int j = 0; j < cnt; ++j) {
            ElementType* v = dataset[ind[j]];
            for (size_t k=0; k<veclen_; ++k) {
                DistanceType dist = v[k] - mean[k];
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

        /* If either list is empty, it means that all remaining features
         * are identical. Split in the middle to maintain a balanced tree.
         */
        if ((lim1==count)||(lim2==0)) index = count/2;
    }


    /**
     * Select the top RAND_DIM largest values from v and return the index of
     * one of these selected at random.
     */
    int selectDivision(DistanceType* v)
    {
        int num = 0;
        int topind[RAND_DIM];

        /* Create a list of the indices of the top RAND_DIM values. */
        for (size_t i = 0; i < veclen_; ++i) {
            if ((num < RAND_DIM)||(v[i] > v[topind[num-1]])) {
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
                    std::swap(topind[j], topind[j-1]);
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
    void planeSplit(int* ind, int count, int cutfeat, DistanceType cutval, int& lim1, int& lim2)
    {
        /* Move vector indices for left subtree to front of list. */
        int left = 0;
        int right = count-1;
        for (;; ) {
            while (left<=right && dataset[ind[left]][cutfeat]<cutval) ++left;
            while (left<=right && dataset[ind[right]][cutfeat]>=cutval) --right;
            if (left>right) break;
            std::swap(ind[left], ind[right]); ++left; --right;
        }
        lim1 = left;
        right = count-1;
        for (;; ) {
            while (left<=right && dataset[ind[left]][cutfeat]<=cutval) ++left;
            while (left<=right && dataset[ind[right]][cutfeat]>cutval) --right;
            if (left>right) break;
            std::swap(ind[left], ind[right]); ++left; --right;
        }
        lim2 = left;
    }

    /**
     * Performs an exact nearest neighbor search. The exact search performs a full
     * traversal of the tree.
     */
    void getExactNeighbors(ResultSet<DistanceType>& result, const ElementType* vec, float epsError)
    {
        //		checkID -= 1;  /* Set a different unique ID for each search. */

        if (numTrees > 1) {
            fprintf(stderr,"It doesn't make any sense to use more than one tree for exact search");
        }
        if (numTrees>0) {
            searchLevelExact(result, vec, trees[0], 0.0, epsError);
        }
        assert(result.full());
    }

    /**
     * Performs the approximate nearest-neighbor search. The search is approximate
     * because the tree traversal is abandoned after a given number of descends in
     * the tree.
     */
    void getNeighbors(ResultSet<DistanceType>& result, const ElementType* vec, int maxCheck, float epsError)
    {
        int i;
        BranchSt branch;

        int checkCount = 0;
        Heap<BranchSt>* heap = new Heap<BranchSt>(size_);
        std::vector<bool> checked(size_,false);

        /* Search once through each tree down to root. */
        for (i = 0; i < numTrees; ++i) {
            searchLevel(result, vec, trees[i], 0, checkCount, maxCheck, epsError, heap, checked);
        }

        /* Keep searching other branches from heap until finished. */
        while ( heap->popMin(branch) && (checkCount < maxCheck || !result.full() )) {
            searchLevel(result, vec, branch.node, branch.mindist, checkCount, maxCheck, epsError, heap, checked);
        }

        delete heap;

        assert(result.full());
    }


    /**
     *  Search starting from a given node of the tree.  Based on any mismatches at
     *  higher levels, all exemplars below this level must have a distance of
     *  at least "mindistsq".
     */
    void searchLevel(ResultSet<DistanceType>& result_set, const ElementType* vec, NodePtr node, DistanceType mindist, int& checkCount, int maxCheck,
                     float epsError, Heap<BranchSt>* heap, std::vector<bool>& checked)
    {
        if (result_set.worstDist()<mindist) {
            //			printf("Ignoring branch, too far\n");
            return;
        }

        /* If this is a leaf node, then do check and return. */
        if ((node->child1 == NULL)&&(node->child2 == NULL)) {
            /*  Do not check same node more than once when searching multiple trees.
                Once a vector is checked, we set its location in vind to the
                current checkID.
             */
            DistanceType worst_dist = result_set.worstDist();
            int index = node->divfeat;
            if ( checked[index] || ((checkCount>=maxCheck)&& result_set.full()) ) return;
            checked[index] = true;
            checkCount++;

            DistanceType dist = distance(dataset[index], vec, veclen_);
            if (dist<worst_dist) {
                result_set.addPoint(dist,index);
            }
            return;
        }

        /* Which child branch should be taken first? */
        ElementType val = vec[node->divfeat];
        DistanceType diff = val - node->divval;
        NodePtr bestChild = (diff < 0) ? node->child1 : node->child2;
        NodePtr otherChild = (diff < 0) ? node->child2 : node->child1;

        /* Create a branch record for the branch not taken.  Add distance
            of this feature boundary (we don't attempt to correct for any
            use of this feature in a parent node, which is unlikely to
            happen and would have only a small effect).  Don't bother
            adding more branches to heap after halfway point, as cost of
            adding exceeds their value.
         */

        DistanceType new_distsq = mindist + distance.accum_dist(val, node->divval, node->divfeat);
        //		if (2 * checkCount < maxCheck  ||  !result.full()) {
        if ((new_distsq*epsError < result_set.worstDist())||  !result_set.full()) {
            heap->insert( BranchSt(otherChild, new_distsq) );
        }

        /* Call recursively to search next level down. */
        searchLevel(result_set, vec, bestChild, mindist, checkCount, maxCheck, epsError, heap, checked);
    }

    /**
     * Performs an exact search in the tree starting from a node.
     */
    void searchLevelExact(ResultSet<DistanceType>& result_set, const ElementType* vec, const NodePtr node, DistanceType mindist, const float epsError)
    {
        /* If this is a leaf node, then do check and return. */
        if ((node->child1 == NULL)&&(node->child2 == NULL)) {
            DistanceType worst_dist = result_set.worstDist();
            int index = node->divfeat;
            DistanceType dist = distance(dataset[index], vec, veclen_);
            if (dist<worst_dist) {
                result_set.addPoint(dist,index);
            }
            return;
        }

        /* Which child branch should be taken first? */
        ElementType val = vec[node->divfeat];
        DistanceType diff = val - node->divval;
        NodePtr bestChild = (diff < 0) ? node->child1 : node->child2;
        NodePtr otherChild = (diff < 0) ? node->child2 : node->child1;

        /* Create a branch record for the branch not taken.  Add distance
            of this feature boundary (we don't attempt to correct for any
            use of this feature in a parent node, which is unlikely to
            happen and would have only a small effect).  Don't bother
            adding more branches to heap after halfway point, as cost of
            adding exceeds their value.
         */

        DistanceType new_distsq = mindist + distance.accum_dist(val, node->divval, node->divfeat);

        /* Call recursively to search next level down. */
        searchLevelExact(result_set, vec, bestChild, mindist, epsError);

        if (new_distsq*epsError<=result_set.worstDist()) {
            searchLevelExact(result_set, vec, otherChild, new_distsq, epsError);
        }
    }

};   // class KDTreeForest

}

#endif //KDTREE_H
