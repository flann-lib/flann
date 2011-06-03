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

struct KDTreeSingleIndexParams : public IndexParams
{
    KDTreeSingleIndexParams(int leaf_max_size_ = 10, bool reorder_ = true, int dim_ = -1) :
        IndexParams(FLANN_INDEX_KDTREE_SINGLE), leaf_max_size(leaf_max_size_),
        reorder(reorder_), dim(dim_) {}

    int leaf_max_size;
    bool reorder;
    int dim;

    flann_algorithm_t getIndexType() const { return algorithm; }

    void fromParameters(const FLANNParameters& p)
    {
        assert(p.algorithm==algorithm);
    }

    void toParameters(FLANNParameters& p) const
    {
        p.algorithm = algorithm;
    }

    void print() const
    {
        logger.info("Index type: %d\n",(int)algorithm);
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
    std::vector<int> vind;

    int leaf_max_size_;
    bool reorder_;


    /**
     * The dataset used by this index
     */
    const Matrix<ElementType> dataset;
    Matrix<ElementType> data;
    const KDTreeSingleIndexParams index_params;

    size_t size_;
    size_t dim;


    /*--------------------- Internal Data Structures --------------------------*/
    struct Node
    {
        union {
            struct
            {
                /**
                 * Indices of points in leaf node
                 */
                int left, right;
            };
            struct
            {
                /**
                 * Dimension used for subdivision.
                 */
                int divfeat;
                /**
                 * The values used for subdivision.
                 */
                DistanceType divlow, divhigh;
            };
        };
        /**
         * The child nodes.
         */
        Node* child1, * child2;
    };
    typedef Node* NodePtr;


    struct Interval
    {
        ElementType low, high;
    };

    typedef std::vector<Interval> BoundingBox;

    /**
     * Array of k-d trees used to find neighbours.
     */
    NodePtr root_node;
    typedef BranchStruct<NodePtr, DistanceType> BranchSt;
    typedef BranchSt* Branch;

    BoundingBox root_bbox;

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
        return FLANN_INDEX_KDTREE_SINGLE;
    }

    /**
     * KDTree constructor
     *
     * Params:
     *          inputData = dataset with the input features
     *          params = parameters passed to the kdtree algorithm
     */
    KDTreeSingleIndex(const Matrix<ElementType>& inputData, const KDTreeSingleIndexParams& params = KDTreeSingleIndexParams(),
                      Distance d = Distance() ) :
        dataset(inputData), index_params(params), distance(d)
    {
        size_ = dataset.rows;
        dim = dataset.cols;
        if (params.dim>0) dim = params.dim;
        leaf_max_size_ = params.leaf_max_size;
        reorder_ = params.reorder;

        // Create a permutable array of indices to the input vectors.
        vind.resize(size_);
        for (size_t i = 0; i < size_; i++) {
            vind[i] = i;
        }

        count_leaf = 0;
    }

    /**
     * Standard destructor
     */
    ~KDTreeSingleIndex()
    {
        if (reorder_) data.free();
    }

    /**
     * Builds the index
     */
    void buildIndex()
    {
        computeBoundingBox(root_bbox);
        root_node = divideTree(0, size_, root_bbox );   // construct the tree

        if (reorder_) {
            data.free();
            data = flann::Matrix<ElementType>(new ElementType[size_*dim], size_, dim);
            for (size_t i=0; i<size_; ++i) {
                for (size_t j=0; j<dim; ++j) {
                    data[i][j] = dataset[vind[i]][j];
                }
            }
        }
        else {
            data = dataset;
        }
    }

    void saveIndex(FILE* stream)
    {
        save_value(stream, size_);
        save_value(stream, dim);
        save_value(stream, root_bbox);
        save_value(stream, reorder_);
        save_value(stream, leaf_max_size_);
        save_value(stream, vind);
        if (reorder_) {
            save_value(stream, data);
        }
        save_tree(stream, root_node);
    }


    void loadIndex(FILE* stream)
    {
        load_value(stream, size_);
        load_value(stream, dim);
        load_value(stream, root_bbox);
        load_value(stream, reorder_);
        load_value(stream, leaf_max_size_);
        load_value(stream, vind);
        if (reorder_) {
            load_value(stream, data);
        }
        else {
            data = dataset;
        }
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
        return dim;
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
        float epsError = 1+searchParams.eps;

        std::vector<DistanceType> dists(dim,0);
        DistanceType distsq = computeInitialDistances(vec, dists);
        searchLevel(result, vec, root_node, distsq, dists, epsError);
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


    void computeBoundingBox(BoundingBox& bbox)
    {
        bbox.resize(dim);
        for (size_t i=0; i<dim; ++i) {
            bbox[i].low = dataset[0][i];
            bbox[i].high = dataset[0][i];
        }
        for (size_t k=1; k<dataset.rows; ++k) {
            for (size_t i=0; i<dim; ++i) {
                if (dataset[k][i]<bbox[i].low) bbox[i].low = dataset[k][i];
                if (dataset[k][i]>bbox[i].high) bbox[i].high = dataset[k][i];
            }
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
    NodePtr divideTree(int left, int right, BoundingBox& bbox)
    {
        NodePtr node = pool.allocate<Node>(); // allocate memory

        /* If too few exemplars remain, then make this a leaf node. */
        if ( (right-left) <= leaf_max_size_) {
            node->child1 = node->child2 = NULL;    /* Mark as leaf node. */
            node->left = left;
            node->right = right;

            // compute bounding-box of leaf points
            for (size_t i=0; i<dim; ++i) {
                bbox[i].low = dataset[vind[left]][i];
                bbox[i].high = dataset[vind[left]][i];
            }
            for (int k=left+1; k<right; ++k) {
                for (size_t i=0; i<dim; ++i) {
                    if (bbox[i].low>dataset[vind[k]][i]) bbox[i].low=dataset[vind[k]][i];
                    if (bbox[i].high<dataset[vind[k]][i]) bbox[i].high=dataset[vind[k]][i];
                }
            }
        }
        else {
            int idx;
            int cutfeat;
            DistanceType cutval;
            middleSplit_(&vind[0]+left, right-left, idx, cutfeat, cutval, bbox);

            node->divfeat = cutfeat;

            BoundingBox left_bbox(bbox);
            left_bbox[cutfeat].high = cutval;
            node->child1 = divideTree(left, left+idx, left_bbox);

            BoundingBox right_bbox(bbox);
            right_bbox[cutfeat].low = cutval;
            node->child2 = divideTree(left+idx, right, right_bbox);

            node->divlow = left_bbox[cutfeat].high;
            node->divhigh = right_bbox[cutfeat].low;

            for (size_t i=0; i<dim; ++i) {
                bbox[i].low = std::min(left_bbox[i].low, right_bbox[i].low);
                bbox[i].high = std::max(left_bbox[i].high, right_bbox[i].high);
            }
        }

        return node;
    }

    void computeMinMax(int* ind, int count, int dim, ElementType& min_elem, ElementType& max_elem)
    {
        min_elem = dataset[ind[0]][dim];
        max_elem = dataset[ind[0]][dim];
        for (int i=1; i<count; ++i) {
            ElementType val = dataset[ind[i]][dim];
            if (val<min_elem) min_elem = val;
            if (val>max_elem) max_elem = val;
        }
    }

    void middleSplit(int* ind, int count, int& index, int& cutfeat, DistanceType& cutval, const BoundingBox& bbox)
    {
        // find the largest span from the approximate bounding box
        ElementType max_span = bbox[0].high-bbox[0].low;
        cutfeat = 0;
        cutval = (bbox[0].high+bbox[0].low)/2;
        for (size_t i=1; i<dim; ++i) {
            ElementType span = bbox[i].low-bbox[i].low;
            if (span>max_span) {
                max_span = span;
                cutfeat = i;
                cutval = (bbox[i].high+bbox[i].low)/2;
            }
        }

        // compute exact span on the found dimension
        ElementType min_elem, max_elem;
        computeMinMax(ind, count, cutfeat, min_elem, max_elem);
        cutval = (min_elem+max_elem)/2;
        max_span = max_elem - min_elem;

        // check if a dimension of a largest span exists
        size_t k = cutfeat;
        for (size_t i=0; i<dim; ++i) {
            if (i==k) continue;
            ElementType span = bbox[i].high-bbox[i].low;
            if (span>max_span) {
                computeMinMax(ind, count, i, min_elem, max_elem);
                span = max_elem - min_elem;
                if (span>max_span) {
                    max_span = span;
                    cutfeat = i;
                    cutval = (min_elem+max_elem)/2;
                }
            }
        }
        int lim1, lim2;
        planeSplit(ind, count, cutfeat, cutval, lim1, lim2);

        if (lim1>count/2) index = lim1;
        else if (lim2<count/2) index = lim2;
        else index = count/2;
    }


    void middleSplit_(int* ind, int count, int& index, int& cutfeat, DistanceType& cutval, const BoundingBox& bbox)
    {
        const float EPS=0.00001;
        ElementType max_span = bbox[0].high-bbox[0].low;
        for (size_t i=1;i<dim;++i) {
            ElementType span = bbox[i].high-bbox[i].low;
            if (span>max_span) {
                max_span = span;
            }
        }
        ElementType max_spread = -1;
        cutfeat = 0;
        for (size_t i=0;i<dim;++i) {
            ElementType span = bbox[i].high-bbox[i].low;
            if (span>(1-EPS)*max_span) {
                ElementType min_elem, max_elem;
                computeMinMax(ind, count, cutfeat, min_elem, max_elem);
                ElementType spread = max_elem-min_elem;;
                if (spread>max_spread) {
                    cutfeat = i;
                    max_spread = spread;
                }
            }
        }
        // split in the middle
        DistanceType split_val = (bbox[cutfeat].low+bbox[cutfeat].high)/2;
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
        for (;; ) {
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
        for (;; ) {
            while (left<=right && dataset[ind[left]][cutfeat]<=cutval) ++left;
            while (left<=right && dataset[ind[right]][cutfeat]>cutval) --right;
            if (left>right) break;
            std::swap(ind[left], ind[right]); ++left; --right;
        }
        lim2 = left;
    }

    DistanceType computeInitialDistances(const ElementType* vec, std::vector<DistanceType>& dists)
    {
        DistanceType distsq = 0.0;

        for (size_t i = 0; i < dim; ++i) {
            if (vec[i] < root_bbox[i].low) {
                dists[i] = distance.accum_dist(vec[i], root_bbox[i].low, i);
                distsq += dists[i];
            }
            if (vec[i] > root_bbox[i].high) {
                dists[i] = distance.accum_dist(vec[i], root_bbox[i].high, i);
                distsq += dists[i];
            }
        }

        return distsq;
    }

    /**
     * Performs an exact search in the tree starting from a node.
     */
    void searchLevel(ResultSet<DistanceType>& result_set, const ElementType* vec, const NodePtr node, DistanceType mindistsq,
                     std::vector<DistanceType>& dists, const float epsError)
    {
        /* If this is a leaf node, then do check and return. */
        if ((node->child1 == NULL)&&(node->child2 == NULL)) {
            count_leaf += (node->right-node->left);
            DistanceType worst_dist = result_set.worstDist();
            for (int i=node->left; i<node->right; ++i) {
                int index = reorder_ ? i : vind[i];
                DistanceType dist = distance(vec, data[index], dim, worst_dist);
                if (dist<worst_dist) {
                    result_set.addPoint(dist,vind[i]);
                }
            }
            return;
        }

        /* Which child branch should be taken first? */
        int idx = node->divfeat;
        ElementType val = vec[idx];
        DistanceType diff1 = val - node->divlow;
        DistanceType diff2 = val - node->divhigh;

        NodePtr bestChild;
        NodePtr otherChild;
        DistanceType cut_dist;
        if ((diff1+diff2)<0) {
            bestChild = node->child1;
            otherChild = node->child2;
            cut_dist = distance.accum_dist(val, node->divhigh, idx);
        }
        else {
            bestChild = node->child2;
            otherChild = node->child1;
            cut_dist = distance.accum_dist( val, node->divlow, idx);
        }

        /* Call recursively to search next level down. */
        searchLevel(result_set, vec, bestChild, mindistsq, dists, epsError);

        DistanceType dst = dists[idx];
        mindistsq = mindistsq + cut_dist - dst;
        dists[idx] = cut_dist;
        if (mindistsq*epsError<=result_set.worstDist()) {
            searchLevel(result_set, vec, otherChild, mindistsq, dists, epsError);
        }
        dists[idx] = dst;
    }

};   // class KDTree

}

#endif //KDTREESINGLE_H
