/***********************************************************************
 * Software License Agreement (BSD License)
 *
 * Copyright 2017  Seth Price (seth@planet.com). All rights reserved.
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


#ifdef FLANN_USE_OPENCL
#ifndef FLANN_KMEANS_OPENCL_INDEX_H_
#define FLANN_KMEANS_OPENCL_INDEX_H_

#include <queue>

#include "flann/algorithms/nn_opencl_index.h"
#include "flann/algorithms/kmeans_index.h"

namespace flann
{

struct KMeansOpenCLIndexParams : public KMeansIndexParams
{
    KMeansOpenCLIndexParams(
        int branching = 32, int iterations = 11,
        flann_centers_init_t centers_init = FLANN_CENTERS_RANDOM, float cb_index = 0.2 ) :
    KMeansIndexParams(branching, iterations, centers_init, cb_index)
    {
        // Override parent param's algorithm
        (*this)["algorithm"] = FLANN_INDEX_KMEANS_OPENCL;
    }
};

/**
 * Hierarchical kmeans index
 *
 * Contains a tree constructed through a hierarchical kmeans clustering
 * and other information for indexing a set of points for nearest-neighbour matching.
 */
template <typename Distance>
class KMeansOpenCLIndex : public KMeansIndex<Distance>, public OpenCLIndex
{
public:
    typedef typename Distance::ElementType ElementType;
    typedef typename Distance::ResultType DistanceType;

    typedef KMeansIndex<Distance> BaseClass;

    flann_algorithm_t getType() const
    {
        return FLANN_INDEX_KMEANS_OPENCL;
    }

    /**
     * Index constructor
     *
     * Params:
     *          inputData = dataset with the input features
     *          params = parameters passed to the hierarchical k-means algorithm
     */
    KMeansOpenCLIndex(
        const Matrix<ElementType>& inputData,
        const IndexParams& params = KMeansIndexParams(),
        Distance d = Distance())
        : BaseClass(inputData, params, d)
    {
        cl_node_index_arr_ = NULL;
        cl_node_pivots_ = NULL;
        cl_node_radii_ = NULL;
        cl_node_variance_ = NULL;
        cl_dataset_ = NULL;
        this->cl_knn_search_kern_ = NULL;
        this->cl_cmd_queue_ = NULL;
    }

    /**
     *
     */
    void buildCLKnnSearch(size_t knn,
                          const SearchParams& params,
                          cl_command_queue cq = NULL)
    {
        OpenCLIndex::buildCLKnnSearch(knn, params, cq);
    }

protected:
    /**
     * Format the index for, and copy the index into, OpenCL device memory.
     * The device memory format is not intended to be changeable, so if the
     * index changes, then the index device memory must be freed and rebuilt.
     *
     * Params:
     *     context = the OpenCL context
     */
    void initCLIndexMem(cl_context context)
    {
        if (this->cl_node_index_arr_ && this->cl_node_pivots_ && this->cl_node_radii_ &&
            this->cl_node_variance_ && this->cl_dataset_)
            return;

        cl_int err = CL_SUCCESS;

        // Figure out the sizes we need to allocate mem for...
        this->cl_num_nodes_ = 0;
        this->cl_num_parents_ = 0;
        this->cl_num_leaves_ = 0;
        int maxDepth = 0;
        int minDepth = 9999;

        countNodes(this->root_, &this->cl_num_nodes_, &this->cl_num_parents_, &this->cl_num_leaves_,
                   1, &minDepth, &maxDepth);

        // Check that our assumptions about the structure of the tree is correct
        assert(this->size_ == this->cl_num_leaves_);
        assert(this->cl_num_nodes_ % this->branching_ == 1);
        assert(this->cl_num_parents_*this->branching_ + 1 == this->cl_num_nodes_);
        cl_command_queue cmd_queue = this->cl_cmd_queue_;

        // Allocate working vars
        cl_mem index_arr_work_cl, node_pivots_work_cl, node_radii_work_cl,
        node_variance_work_cl, dataset_work_cl;
        int *index_arr_work;
        ElementType *node_pivots_work;
        DistanceType *node_radii_work;
        DistanceType *node_variance_work;
        ElementType *dataset_work;
        int n_veclen = 4*((this->veclen_+3)/4);

        // Find the sizes of the blocks of memory are that we will be using
        size_t sz_index = sizeof(int)*(this->cl_num_parents_*this->branching_+this->cl_num_leaves_+
                                       this->cl_num_nodes_-this->cl_num_parents_);
        size_t sz_pivots = sizeof(ElementType)*this->cl_num_nodes_*n_veclen;
        size_t sz_radii = sizeof(DistanceType)*this->cl_num_nodes_;
        size_t sz_variance = sizeof(DistanceType)*this->cl_num_nodes_;
        size_t sz_dataset = sizeof(ElementType)*this->size_*n_veclen;

        // Alloc device & pinned working memory
        this->allocCLDevPinnedWorkMem(context, sz_index, CL_MEM_READ_ONLY,
                                      &this->cl_node_index_arr_, &index_arr_work_cl, &index_arr_work);
        this->allocCLDevPinnedWorkMem(context, sz_pivots, CL_MEM_READ_ONLY,
                                      &this->cl_node_pivots_, &node_pivots_work_cl, &node_pivots_work);
        this->allocCLDevPinnedWorkMem(context, sz_radii, CL_MEM_READ_ONLY,
                                      &this->cl_node_radii_, &node_radii_work_cl, &node_radii_work);
        this->allocCLDevPinnedWorkMem(context, sz_variance, CL_MEM_READ_ONLY,
                                      &this->cl_node_variance_, &node_variance_work_cl, &node_variance_work);
        this->allocCLDevPinnedWorkMem(context, sz_dataset, CL_MEM_READ_ONLY,
                                      &this->cl_dataset_, &dataset_work_cl, &dataset_work);
        err = clFinish(cmd_queue);
        assert(err == CL_SUCCESS);

        // Copy dataset
        for (int i = 0; i < this->size_; ++i) {
            // Save point data (& pad with zeros for alignment & SIMD operations)
            for (int v = 0; v < n_veclen; ++v)
                if (v < this->veclen_) {
                    assert(std::isfinite(this->points_[i][v]));
                    dataset_work[i*n_veclen+v] = this->points_[i][v];
                } else
                    dataset_work[i*n_veclen+v] = 0;
        }

        // Copy from host to device memory
        err = clEnqueueWriteBuffer(cmd_queue, this->cl_dataset_, CL_FALSE, 0,
                                   sz_dataset, (void*)dataset_work, 0, NULL, NULL);
        assert(err == CL_SUCCESS);

        // Copy data to working memory in a breadth-first search
        std::queue<NodePtr> nodeQueue;
        int next_index = this->branching_;

        nodeQueue.push(this->root_);
        for (int i = -1; !nodeQueue.empty(); ++i) {
            copyNodeData(nodeQueue.front(), i, &next_index, 0, &nodeQueue,
                         index_arr_work, node_pivots_work, node_radii_work,
                         node_variance_work );
            nodeQueue.pop();
        }

        // Shift from storing parent nodes to storing leaf indicies (indexing into the dataset)
        nodeQueue.push(this->root_);
        for (int i = -1; !nodeQueue.empty(); ++i) {
            copyNodeData(nodeQueue.front(), i, &next_index, 1, &nodeQueue,
                         index_arr_work, node_pivots_work, node_radii_work,
                         node_variance_work );
            nodeQueue.pop();
        }

        // Remove edge case
        index_arr_work[next_index] = 0;

        // Copy from host to device memory
        err = clEnqueueWriteBuffer(cmd_queue, this->cl_node_index_arr_, CL_FALSE, 0,
                                   sz_index, (void*)index_arr_work, 0, NULL, NULL);
        assert(err == CL_SUCCESS);
        err = clEnqueueWriteBuffer(cmd_queue, this->cl_node_pivots_, CL_FALSE, 0,
                                   sz_pivots, (void*)node_pivots_work, 0, NULL, NULL);
        assert(err == CL_SUCCESS);
        err = clEnqueueWriteBuffer(cmd_queue, this->cl_node_radii_, CL_FALSE, 0,
                                   sz_radii, (void*)node_radii_work, 0, NULL, NULL);
        assert(err == CL_SUCCESS);
        err = clEnqueueWriteBuffer(cmd_queue, this->cl_node_variance_, CL_FALSE, 0,
                                   sz_variance, (void*)node_variance_work, 0, NULL, NULL);
        assert(err == CL_SUCCESS);
        err = clFinish(cmd_queue);
        assert(err == CL_SUCCESS);

        // Release working resources
        clReleaseMemObject(index_arr_work_cl);
        clReleaseMemObject(node_pivots_work_cl);
        clReleaseMemObject(node_radii_work_cl);
        clReleaseMemObject(node_variance_work_cl);
        clReleaseMemObject(dataset_work_cl);
    }

    /**
     * Build the kernel for knnSearch() using the given params and save it.
     * Future calls to knnSearch() that use those params are elgible for OpenCL
     * accelleration.
     *
     * @param[in] context The context that will be used by this kernel.
     * @param[in] dev The device that will run this kernel.
     * @param[in] knn The number of nearest neighbors we will be searching for (will be compiled in).
     * @param[in] maxChecks The maximum check parameter to compile for.
     * @return The OpenCL kernel compiled for the given parameters and current tree structure.
     */
    cl_kernel buildCLknnSearchKernel(cl_context context, cl_device_id dev, size_t knn, int maxChecks)
    {
        const char *prog_name;
        cl_kernel kern;

        // FIXME - removed points not currently implemented
        const char *program_src_general =
"int findNN(__global int *nodeIndexArr, __global ELEMENT_TYPE *nodePivots,\n"
           "__global DISTANCE_TYPE *nodeRadii,\n"
           "__global DISTANCE_TYPE *nodeVariance, __global ELEMENT_TYPE *dataset,\n"
           "int idx,\n"
           "__global DISTANCE_TYPE *resultDist, __global int *resultId,\n"
           "__global ELEMENT_TYPE *vec, int *checks,\n"
           "__private DISTANCE_TYPE *heapDist, __private int *heapId,\n"
           "int *heapStart, int *heapEnd);\n"

"int tooFar(__global ELEMENT_TYPE *nodePivots, __global DISTANCE_TYPE *nodeRadii,\n"
           "int nodeId, __global ELEMENT_TYPE *vec, int *checks,\n"
           "__global DISTANCE_TYPE *resultDist, __global int *resultId );\n"

"int exploreNodeBranches (__global int *nodeIndexArr, __global ELEMENT_TYPE *nodePivots,\n"
                         "__global DISTANCE_TYPE *nodeVariance,\n"
                         "int nodeId,\n"
                         "__global ELEMENT_TYPE *q,\n"
                         "__private DISTANCE_TYPE *heapDist, __private int *heapId,\n"
                         "int *heapStart, int *heapEnd);\n"

"DISTANCE_TYPE vecDist (__global ELEMENT_TYPE *v1, __global ELEMENT_TYPE *v2, int off);\n"

"void heapInsert(DISTANCE_TYPE nodeDist, int nodeId,\n"
                "__private DISTANCE_TYPE *heapDist, __private int *heapId,\n"
                "int *heapStart, int *heapEnd);\n"

"int heapPopMin(__private DISTANCE_TYPE *heapDist, __private int *heapId,\n"
               "int *heapStart, int *heapEnd);\n"

"void resultAddPoint(DISTANCE_TYPE rsDist, int rsId, int *checks,\n"
                    "__global DISTANCE_TYPE *resultDist, __global int *resultId );\n"

// Kernel intended for CPU operation. It plays a bit more fast and loose with branches, random
// accesses to global memory, and amount of memory used. Operations are vectorized when
// possible. The actual logic is very similar to the non-OpenCL code. One thread per query.
"__kernel void findNeighbors (__global int *nodeIndexArr, __global ELEMENT_TYPE *nodePivots,\n"
                             "__global DISTANCE_TYPE *nodeVariance, __global DISTANCE_TYPE *nodeRadii,\n"
                             "__global ELEMENT_TYPE *dataset,\n"
                             "__global DISTANCE_TYPE *resultDistArr, __global int *resultIdArr,\n"
                             "__global ELEMENT_TYPE *vecArr, int numQueries )\n"
"{\n"
    "int gid = get_global_id(0);\n"
    // In case we are operating with a group size
    "if (gid >= numQueries)\n"
        "return;\n"

    // Set pointers to global memory that are constant for this kernel
    "__global ELEMENT_TYPE *vec = &vecArr[gid*N_VECLEN];\n"
    "__global DISTANCE_TYPE *resultDist = &resultDistArr[gid*N_RESULT];\n"
    "__global int *resultId = &resultIdArr[gid*N_RESULT];\n"

    "__private DISTANCE_TYPE heapDist[N_HEAP];\n"
    "__private int heapId[N_HEAP];\n"

    // Set up initial variables so we have something to compare against (one less edge case)
    "resultDist[0] = vecDist(vec, dataset, 0);\n"
    "resultId[0] = 0;\n"
    "int checks = 1;\n"
    "int heapStart = 0;\n"
    "int heapEnd = 0;\n"

    // Find the first node to search starting from the root
    "int nextNode = exploreNodeBranches(nodeIndexArr, nodePivots, nodeVariance,\n"
                                       "0, vec, heapDist, heapId, &heapStart, &heapEnd);\n"

    // Iterate through all suggested nodes until we're done or have nothing else to search
    "do {\n"
        // Find the next nearest neighbor
        "nextNode = findNN(nodeIndexArr, nodePivots, nodeRadii, nodeVariance, dataset,\n"
                          "nextNode, resultDist, resultId, vec,\n"
                          "&checks, heapDist, heapId, &heapStart, &heapEnd);\n"
        // If we've hit the end of this branch, pop the next one off the heap
        "if (nextNode == -1)\n"
            "nextNode = heapPopMin(heapDist, heapId, &heapStart, &heapEnd);\n"

    "} while ((nextNode != -1) && (checks < MAX_CHECKS || checks < N_RESULT));\n"
"}\n"

// Kernel intended for finding the exact set of neighbors. As of writing this comment, it hasn't
// been tested. Uses vector commands when possible, and likely optimized for CPU.
"__kernel void findNeighborsExact (__global int *nodeIndexArr, __global ELEMENT_TYPE *nodePivots,\n"
                                  "__global DISTANCE_TYPE *nodeRadii,\n"
                                  "__global ELEMENT_TYPE *dataset,\n"
                                  "__global DISTANCE_TYPE *resultDistArr, __global int *resultIdArr,\n"
                                  "__global ELEMENT_TYPE *vecArr, int numQueries )\n"
"{\n"
    "int gid = get_global_id(0);\n"
    "if (gid >= numQueries)\n"
        "return;\n"

    "__global ELEMENT_TYPE *vec = &vecArr[gid*N_VECLEN];\n"

    // Each search has its own result array
    "__global DISTANCE_TYPE *resultDist = &resultDistArr[gid*N_RESULT];\n"
    "__global int *resultId = &resultIdArr[gid*N_RESULT];\n"

    // Add the first point now to remove the case of not having an
    // existing point to compare against (less flow control overall)
    "resultDist[0] = vecDist(vec, dataset, 0);\n"
    "resultId[0] = 0;\n"
    "int checks = 1;\n"

    // Iterate through all nodes that reference leaves
    "for (int nodeId = 0; nodeId < N_NODES; ++nodeId) {\n"
        "int nodePtr = nodeIndexArr[nodeId];\n"

        // Check that the current node references leaves and it's not too far away to be valid
        "if (nodePtr < N_NODES ||\n"
            "tooFar(nodePivots, nodeRadii, nodeId, vec, &checks, resultDist, resultId))\n"
            "continue;\n"

        // Iterate through leaves of this node
        "int lastPtr = nodeIndexArr[nodePtr] + nodePtr;\n"
        "do {\n"
            "int datasetI = nodeIndexArr[++nodePtr];\n"
            // Add them all. They will be sorted within the point adding code
            "resultAddPoint(vecDist(vec, dataset, datasetI*N_VECLEN), datasetI,\n"
                           "&checks, resultDist, resultId);\n"
        "} while (nodePtr < lastPtr);\n"
    "}\n"
"}\n"

// Finds the nearest neighbor from the given node
"int findNN(__global int *nodeIndexArr, __global ELEMENT_TYPE *nodePivots,\n"
           "__global DISTANCE_TYPE *nodeRadii,\n"
           "__global DISTANCE_TYPE *nodeVariance, __global ELEMENT_TYPE *dataset,\n"
           "int nodeId,\n"
           "__global DISTANCE_TYPE *resultDist, __global int *resultId,\n"
           "__global ELEMENT_TYPE *vec, int *checks,\n"
           "__private DISTANCE_TYPE *heapDist, __private int *heapId,\n"
           "int *heapStart, int *heapEnd)\n"
"{\n"
    // Check if the point is too far to be useful
    "if (tooFar(nodePivots, nodeRadii, nodeId, vec, checks, resultDist, resultId))\n"
        "return -1;\n"
    "int nodePtr = nodeIndexArr[nodeId];\n"

    // Either the node references children or other nodes
    "if (nodePtr >= N_NODES) {\n"
        // Iterate through all child leaves
        "int lastPtr = nodeIndexArr[nodePtr] + nodePtr;\n"
        "do {\n"
            "int datasetI = nodeIndexArr[++nodePtr];\n"

            // (Attempt to) add to the result array
            "resultAddPoint(vecDist(vec, dataset, datasetI*N_VECLEN), datasetI,\n"
                           "checks, resultDist, resultId);\n"
        "} while (lastPtr > nodePtr);\n"
        "return -1;\n"
    "} else {\n"
        // If we're a parent node, find the closest child node
        "return exploreNodeBranches(nodeIndexArr, nodePivots, nodeVariance,\n"
                                     "nodePtr, vec, heapDist, heapId, heapStart, heapEnd);\n"
    "}\n"
"}\n"

// Ignore those clusters that are too far away
"int tooFar(__global ELEMENT_TYPE *nodePivots, __global DISTANCE_TYPE *nodeRadii,\n"
           "int nodeId, __global ELEMENT_TYPE *vec, int *checks,\n"
           "__global DISTANCE_TYPE *resultDist, __global int *resultId )\n"
"{\n"
    "DISTANCE_TYPE bsq = vecDist(vec, nodePivots, nodeId*N_VECLEN);\n"
    "DISTANCE_TYPE rsq = nodeRadii[nodeId];\n"
    "DISTANCE_TYPE wsq = resultDist[min(N_RESULT, (*checks))-1];\n"
    "DISTANCE_TYPE val = bsq-rsq-wsq;\n"
    "return ((val > (DISTANCE_TYPE)0.0) && ((val*val-4*rsq*wsq) > (DISTANCE_TYPE)0.0));\n"
"}\n"

// Explore child nodes for the closest. Add the rest to the heap
"int exploreNodeBranches (__global int *nodeIndexArr, __global ELEMENT_TYPE *nodePivots,\n"
                         "__global DISTANCE_TYPE *nodeVariance,\n"
                         "int nodePtr, __global ELEMENT_TYPE *q,\n"
                         "__private DISTANCE_TYPE *heapDist, __private int *heapId,\n"
                         "int *heapStart, int *heapEnd )\n"
"{\n"
    "int bestI = 0;\n"
    "DISTANCE_TYPE distArr[BRANCHING];\n"
    "distArr[0] = vecDist(q, nodePivots, nodePtr*N_VECLEN);\n"

    // Find the best branch to take
    "for (int i = 1; i < BRANCHING; ++i) {\n"
        "DISTANCE_TYPE d = distArr[i] = vecDist(q, nodePivots, (nodePtr+i)*N_VECLEN);\n"
        "if (d < distArr[bestI])\n"
            "bestI = i;\n"
    "}\n"

    // Add the remaining branches to the heap
    "for (int i = 0; i < BRANCHING; ++i) {\n"
        "if (i == bestI)\n"
            "continue;\n"
        "heapInsert(distArr[i] - CB_INDEX*nodeVariance[nodePtr+i],\n"
                   "nodePtr+i, heapDist, heapId, heapStart, heapEnd);\n"
    "}\n"

    // Follow best branch for now...
    "return nodePtr+bestI;\n"
"}\n"

// Calculates the square of the euclidian distance between two vectors
"DISTANCE_TYPE vecDist (__global ELEMENT_TYPE *v1, __global ELEMENT_TYPE *v2, int off2)\n"
"{\n"
    "DISTANCE_TYPE_VEC sum = (DISTANCE_TYPE_VEC)0.0f;\n"
    "for (int i = 0; i < N_VECLEN; i += 4) {\n"
        // Vector instructions FTW!
        "DISTANCE_TYPE_VEC diff = vload4(0,v1+i) - vload4(0,v2+i+off2);\n"
        "sum = mad(diff, diff, sum);\n"
    "}\n"
    "return sum.s0+sum.s1+sum.s2+sum.s3;\n"
"}\n"

// Adds a node to the heap array. The heap should be large enough that when it's full there
// are enough leaves to perform the expected number of checks (MAX_CHECKS). If the heap is
// full, the furthest distance is discarded.
"void heapInsert(DISTANCE_TYPE nodeDist, int nodeId,\n"
                "__private DISTANCE_TYPE *heapDist, __private int *heapId,\n"
                "int *heapStart, int *heapEnd )\n"
"{\n"
    // If not full, inc the number of elements in the array
    "if ((*heapEnd) < N_HEAP)\n"
        "++(*heapEnd);\n"
    // Don't add nodes that are already worse than the worst one (if full)
    "else if (nodeDist >= heapDist[N_HEAP-1])\n"
        "return;\n"

    // Move all larger distance nodes back
    "int i = (*heapEnd)-1;\n"
    "for (; i > (*heapStart)+3; i -= 4) {\n"
        "DISTANCE_TYPE_VEC hd = vload4(0, heapDist+i-4);\n"
        "if (any(islessequal(hd, nodeDist)))\n"
            "break;\n"
        "vstore4(hd, 0, heapDist+i-3);\n"
        "vstore4(vload4(0, heapId+i-4), 0, heapId+i-3);\n"
    "}\n"
    "for (; i > (*heapStart) && nodeDist < heapDist[i-1]; --i) {\n"
        "heapDist[i] = heapDist[i-1];\n"
        "heapId[i] = heapId[i-1];\n"
    "}\n"

    // Insert new result
    "heapDist[i] = nodeDist;\n"
    "heapId[i] = nodeId;\n"
"}\n"

// Pop the minimum value off of the front of the heap
"int heapPopMin(__private DISTANCE_TYPE *heapDist, __private int *heapId,\n"
               "int *heapStart, int *heapEnd)\n"
"{\n"
    "if ((*heapStart) == (*heapEnd))\n"
        "return -1;\n"

    // Check if we should shift numbers back...
    "if ((*heapStart) == 8) {\n"
        "(*heapEnd) = (*heapEnd)-8;\n"
        // Move one vector at a time
        "int i = 0;\n"
        "for (; i < (*heapEnd)-3; i += 4) {\n"
            "vstore4(vload4(0, heapDist+i+8), 0, heapDist+i);\n"
            "vstore4(vload4(0, heapId+i+8), 0, heapId+i);\n"
        "}\n"
        "for (; i < (*heapEnd); ++i) {\n"
            "heapDist[i] = heapDist[i+8];\n"
            "heapId[i] = heapId[i+8];\n"
        "}\n"
        "(*heapStart) = 0;\n"
    "}\n"

    "return heapId[(*heapStart)++];\n"
"}\n"

// Adds a point to the result array.
// If it's full, the furthest result distance is discarded.
"void resultAddPoint(DISTANCE_TYPE rsDist, int rsId, int *checks,\n"
                    "__global DISTANCE_TYPE *resultDist, __global int *resultId )\n"
"{\n"
    // Don't add results that are already worse than the worst one
    "if ((*checks) < N_RESULT || rsDist < resultDist[N_RESULT-1]) {\n"
        "int i = min((*checks), N_RESULT-1);\n"
        // Move all larger distance results back
        "for (; i > 0 && rsDist < resultDist[i-1]; --i) {\n"
            "resultDist[i] = resultDist[i-1];\n"
            "resultId[i] = resultId[i-1];\n"
        "}\n"
        "resultDist[i] = rsDist;\n"
        "resultId[i] = rsId;\n"
    "}\n"

    // Inc the number of checks done. This is also the maximum number of elements in the array.
    "++(*checks);\n"
"}\n";

// **************** Implementation that takes advantage of thread groups on GPUs ****************
        const char *program_src_local =
"void findLeaves(__global int *nodeIndex, __local ELEMENT_TYPE *query,\n"
                "__global ELEMENT_TYPE *dataset, __local int *locDone, __local int *locPtr,\n"
                "__local DISTANCE_TYPE *heapDist, __local int *heapId);\n"

"void findNodes(__global int *nodeIndex, __global ELEMENT_TYPE *nodePivots,\n"
               "__global DISTANCE_TYPE *nodeVariance,\n"
               "__local int *locDone, __local ELEMENT_TYPE *query,\n"
               "__local DISTANCE_TYPE *heapDist, __local int *heapId);\n"

"void findNewNodeDist(__global int *nodeIndex, __global ELEMENT_TYPE *nodePivots,\n"
                     "__global DISTANCE_TYPE *nodeVariance, __local ELEMENT_TYPE *vec,\n"
                     "__local DISTANCE_TYPE *heapDist, __local int *heapId);\n"

"void sortHeap(__local DISTANCE_TYPE *heapDist, __local int *heapId);\n"

"void bitonicMerge(__local DISTANCE_TYPE *heapDist, __local int *heapId,\n"
                  "int size, int dir);\n"

"void checkDone(int privDone, __local int *locDone);\n"

"void initLoc (__local DISTANCE_TYPE *heapDist, __local int *heapId);\n"

"void storeResult (__global DISTANCE_TYPE *resultDistArr, __global int *resultIdArr,\n"
                  "__local DISTANCE_TYPE *heapDist, __local int *heapId);\n"

"DISTANCE_TYPE vecDistLoc (__local ELEMENT_TYPE *v1, __global ELEMENT_TYPE *v2, int off2);\n"

// Kernel for finding k-nearest-neighbors using thread groups and local memory. This makes it work
// well for execution on GPU processors. Thus it has been optimized for fewer branches. There
// is one query performed per thread group, each thread group is large enough to check pointers
// from the first half of the heap, save the reults in the other half, and then sort them all for
// the next pass. This algorithm uses an index of the same structure, but the logic is completely
// different.
"#pragma OPENCL EXTENSION cl_khr_local_int32_base_atomics : enable\n"
"__kernel __attribute__((reqd_work_group_size(LOC_SIZE, 1, 1)))\n"
"void findNeighborsLocal (__global int *nodeIndex, __global ELEMENT_TYPE *nodePivots,\n"
                         "__global DISTANCE_TYPE *nodeVariance, __global DISTANCE_TYPE *nodeRadii,\n"
                         "__global ELEMENT_TYPE *dataset,\n"
                         "__global DISTANCE_TYPE *resultDistArr, __global int *resultIdArr,\n"
                         "__global ELEMENT_TYPE *queryArr, int numQueries )\n"
"{\n"
    // N_HEAP == get_local_size(0) *2 == (avg checks per node needed for MAX_CHECKS) *2
    // == LOC_SIZE *2 >= N_RESULT *2 >= 32 (min GPU hardware thread group size, I think) *2
    "__local int heapId[N_HEAP];\n"
    "__local DISTANCE_TYPE heapDist[N_HEAP];\n"
    "__local ELEMENT_TYPE query[N_VECLEN];\n"
    "__local int locPtr;\n"
    "__local int locDone;\n"

    // All threads in a group preform (approx) MAX_CHECKS in parallel
    // for one query (one query per thread group)
    // Copy vec to __local space because all threads are using it.
    "for (int i = get_local_id(0); i < N_VECLEN; i += LOC_SIZE)\n"
        "query[i] = queryArr[i + get_group_id(0)*N_VECLEN];\n"

    // Find the child nodes that are closest to the query point
    "findNodes(nodeIndex, nodePivots, nodeVariance, &locDone, query, heapDist, heapId);\n"

    // Go from leaf pointers in the heap to a sorted set of leaves
    "findLeaves(nodeIndex, query, dataset, &locDone, &locPtr, heapDist, heapId);\n"

    // After inserting, sorting, and checking leaves, the results are in the lower part of the heap
    "storeResult(resultDistArr, resultIdArr, heapDist, heapId);\n"
"}\n"

// Start with the root node, search through all parent nodes in the lower half of the
// heap and add their children to the top half of the heap. Then sort the heap by priority
// (adjusted distance). After each pass, check if there are any parent nodes left in the bottom
// half of the heap. (Otherwise they are all nodes pointing to groups of leaves.)
"void findNodes(__global int *nodeIndex, __global ELEMENT_TYPE *nodePivots,\n"
               "__global DISTANCE_TYPE *nodeVariance,\n"
               "__local int *locDone, __local ELEMENT_TYPE *query,\n"
               "__local DISTANCE_TYPE *heapDist, __local int *heapId)\n"
"{\n"
    "initLoc(heapDist, heapId);\n"

    // Init the node query array with a pointer to root_'s children
    "heapId[0] = 0;\n"
    "barrier(CLK_LOCAL_MEM_FENCE);\n"

    // Find the closest children to the root
    "findNewNodeDist(nodeIndex, nodePivots, nodeVariance, query, heapDist, heapId);\n"

    // Sort to mix the new nodes into the correct positions in the heap
    "sortHeap(heapDist, heapId);\n"
    "do {\n"
        // Use the closest parent nodes to discover additional nodes
        "findNewNodeDist(nodeIndex, nodePivots, nodeVariance, query, heapDist, heapId);\n"

        // Init shared vars
        "if (get_local_id(0) == 0) {\n"
            // Set this as if it's our last pass, will be flipped back if not done
            "(*locDone) = 1;\n"
        "}\n"

        // Sort to mix the new nodes into the correct positions in the heap
        "sortHeap(heapDist, heapId);\n"

        // While there is a pointer to a parent node in the heap, keep going
        "checkDone((heapId[get_local_id(0)] >= N_NODES), locDone);\n"
    "} while (!(*locDone));\n"
"}\n"

// The bottom half of the heap are pointers to groups of leaves. We have one thread per leaf
// group, so store the pointer in private memory and fill the heap with candidate leaf points.
// After each pass, sort the leaves. After all leaf groups are checked and sorted, we have
// preformed approximately MAX_CHECKS and the bottom of the heap are the closest points.
"void findLeaves(__global int *nodeIndex, __local ELEMENT_TYPE *query,\n"
                "__global ELEMENT_TYPE *dataset, __local int *locDone, __local int *locPtr,\n"
                "__local DISTANCE_TYPE *heapDist, __local int *heapId)\n"
"{\n"
    // Store pointer to list before init local mem
    "int leafPtr = heapId[get_local_id(0)];\n"
    "int lastPtr = nodeIndex[leafPtr] + leafPtr;\n"

    // Reset heap
    "initLoc(heapDist, heapId);\n"

    // Fill the first half of the heap with leaves.
    // 'Unroll' this ahead of the main loop to fill both halves of the heap before
    // first sort, and because we don't really need to checkDone() so soon.
    "int datasetI = nodeIndex[++leafPtr];\n"
    "heapDist[get_local_id(0)] = vecDistLoc(query, dataset, datasetI*N_VECLEN);\n"
    "heapId[get_local_id(0)] = datasetI;\n"

    // Find the next dataset index to check
    "heapId[LOC_SIZE + get_local_id(0)] = nodeIndex[++leafPtr];\n"
    "do {\n"
        // Set the leaf distances for the given IDs
        "heapDist[LOC_SIZE + get_local_id(0)] = vecDistLoc(query, dataset, heapId[LOC_SIZE + get_local_id(0)]*N_VECLEN);\n"

        // Sort heap to leave the closest distances in the bottom of the heap
        "sortHeap(heapDist, heapId);\n"
        // Init shared vars
        "if (get_local_id(0) == 0) {\n"
            // Pointer starts in the middle of the heap
            "(*locPtr) = LOC_SIZE;\n"

            // Assume we're done until proven otherwise
            "(*locDone) = 1;\n"
        "}\n"
        "barrier(CLK_LOCAL_MEM_FENCE);\n"

        // Find the next dataset index to check
        "int i = 0;\n"
        "while (leafPtr < lastPtr && (i = atomic_inc(locPtr)) < N_HEAP)\n"
            "heapId[i] = nodeIndex[++leafPtr];\n"

        // We're done if there's no more leaf indicies to search
        "checkDone(i == 0, locDone);\n"
    "} while (!(*locDone));\n"
"}\n"

// Find a new set of nodes given the parent nodes already in the heap.
"void findNewNodeDist(__global int *nodeIndex, __global ELEMENT_TYPE *nodePivots,\n"
                     "__global DISTANCE_TYPE *nodeVariance, __local ELEMENT_TYPE *vec,\n"
                     "__local DISTANCE_TYPE *heapDist, __local int *heapId)\n"
"{\n"
    // Find the next valid node pointer
    "unsigned int locId = get_local_id(0) / BRANCHING;\n"

    // Skip ids marked as pointers to leaves
    "while (locId < N_HEAP && heapId[locId] >= N_NODES)\n"
        "locId += LOC_SIZE / BRANCHING;\n"

    // Check if we were able to find a valid node ptr
    // Go from pointer-in-heap to actual node ID
    "int nodeId = (locId < N_HEAP) ? (heapId[locId] + get_local_id(0) % BRANCHING) : 0;\n"

    // Ensure all node IDs are retrieved before adjusting the heap
    "barrier(CLK_LOCAL_MEM_FENCE);\n"
    "if (locId < N_HEAP) {\n"
        // Invalidate this pointer if it's been used
        "heapDist[locId] = MAX_DIST;\n"
        "heapId[locId] = N_NODES;\n"

        // Store adjusted distance to node and its pointer
        "int i = LOC_SIZE + get_local_id(0);\n"
        "heapDist[i] = vecDistLoc(vec, nodePivots, nodeId*N_VECLEN) - CB_INDEX*nodeVariance[nodeId];\n"
        "heapId[i] = nodeIndex[nodeId];\n"
    "}\n"
"}\n"

// Sort the local heap by ascending distance using a bitonic sort
"void sortHeap(__local DISTANCE_TYPE *heapDist, __local int *heapId)\n"
"{\n"
    // Iterate from small sizes to N_HEAP
    "for (int size = 2; size < N_HEAP; size <<= 1) {\n"
        //Bitonic merge
        "int ddd = (get_local_id(0) & (size / 2)) != 0;\n"
        "bitonicMerge(heapDist, heapId, size, ddd);\n"
    "}\n"
    "bitonicMerge(heapDist, heapId, N_HEAP, 0);\n"
    "barrier(CLK_LOCAL_MEM_FENCE);\n"
"}\n"

"void bitonicMerge(__local DISTANCE_TYPE *heapDist, __local int *heapId,\n"
                  "int size, int dir)\n"
"{\n"
    "for (int stride = size / 2; stride > 0; stride >>= 1)\n"
    "{\n"
        "barrier(CLK_LOCAL_MEM_FENCE);\n"
        "int pos = 2 * get_local_id(0) - (get_local_id(0) & (stride - 1));\n"
        "DISTANCE_TYPE keyA = heapDist[pos];\n"
        "DISTANCE_TYPE keyB = heapDist[pos + stride];\n"
        // Swap items if out of order
        "if ((keyA < keyB) == dir)\n"
        "{\n"
            "int valA = heapId[pos];\n"
            "int valB = heapId[pos + stride];\n"
            "heapDist[pos] = keyB;\n"
            "heapDist[pos + stride] = keyA;\n"
            "heapId[pos] = valB;\n"
            "heapId[pos + stride] = valA;\n"
        "}\n"
    "}\n"
"}\n"

// Check if all threads are done (as signaled by the 'done' parameter)
"void checkDone(int done, __local int *locDone)\n"
"{\n"
    // Assume all threads are done in local mem and the bit has already been set...
    // Until proven otherwise by private mem
    "if (!done)\n"
        "(*locDone) = 0;\n"
    "barrier(CLK_LOCAL_MEM_FENCE);\n"
"}\n"

// Init both halves of the local heap to be invalid (maximum distance and a node ID of a leaf node)
"void initLoc (__local DISTANCE_TYPE *heapDist, __local int *heapId)\n"
"{\n"
    // Init our position
    "heapDist[get_local_id(0)] = MAX_DIST;\n"
    "heapId[get_local_id(0)] = N_NODES;\n"
    "heapDist[get_local_id(0)+LOC_SIZE] = MAX_DIST;\n"
    "heapId[get_local_id(0)+LOC_SIZE] = N_NODES;\n"
"}\n"

// Store the bottom points of the heap as results in global memory
"void storeResult (__global DISTANCE_TYPE *resultDistArr, __global int *resultIdArr,\n"
                  "__local DISTANCE_TYPE *heapDist, __local int *heapId)\n"
"{\n"
    "__global DISTANCE_TYPE *resultDist = &resultDistArr[get_group_id(0)*N_RESULT];\n"
    "__global int *resultId = &resultIdArr[get_group_id(0)*N_RESULT];\n"

    // Copy from heap to global result mem
    "for (int i = get_local_id(0); i < N_RESULT; i += LOC_SIZE) {\n"
        "resultDist[i] = heapDist[i];\n"
        "resultId[i] = heapId[i];\n"
    "}\n"
"}\n"

// Compare the local query point against a global point and return the euclidian distance
// between them.
"DISTANCE_TYPE vecDistLoc (__local ELEMENT_TYPE *v1, __global ELEMENT_TYPE *v2, int off2)\n"
"{\n"
    "DISTANCE_TYPE_VEC sum = (DISTANCE_TYPE_VEC)0.0f;\n"
    "for (int i = 0; i < N_VECLEN; i += 4) {\n"
        // Use vector instructions because, why not? (And make better use of global latency.)
        "DISTANCE_TYPE_VEC diff = vload4(0,v1+i) - vload4(0,v2+i+off2);\n"
        "sum = mad(diff, diff, sum);\n"
    "}\n"

    // return the sum of all vector components
    "return sum.s0+sum.s1+sum.s2+sum.s3;\n"
"}\n";

        const char *program_src;

        int heapSize = std::max(getAvgNodesNeeded(maxChecks), getCLknn(knn));
        size_t numThreads, locSize;

        // See if we can use local thread groups to speed computation (GPU-likely optimization)
        this->getCLNumThreads(dev, 0, heapSize, &numThreads, &locSize);

        // Find the appropriate vars for the requested kernel
        if (maxChecks == FLANN_CHECKS_UNLIMITED) {
            prog_name = "findNeighborsExact";
            program_src = program_src_general;
        } else if (heapSize <= locSize) {
            prog_name = "findNeighborsLocal";

            // Use (GPU) local mem for the heap
            heapSize = locSize*2;

            // Set the source to use the local thread group optimization
            program_src = program_src_local;
        } else {
            prog_name = "findNeighbors";

            // Set source as vectorized CPU implementation
            program_src = program_src_general;
        }

        std::string distTypeName = TypeInfo<DistanceType>::clName();
        std::string elmTypeName = TypeInfo<ElementType>::clName();
        size_t distTypeSize = TypeInfo<DistanceType>::size();

        // Assume that the distance size is 4 because I think it's always float
        assert(distTypeSize == 4);

        // Compile in all invariants for better optimization opportunity and less complexity
        char *build_str = (char *)calloc(128000, sizeof(char));
        sprintf(build_str,  "-cl-fast-relaxed-math -Werror "
                "-DDISTANCE_TYPE=%s -DELEMENT_TYPE=%s -DDISTANCE_TYPE_VEC=%s "
                "-DN_RESULT=%d -DN_HEAP=%d -DMAX_DIST=%15.15lf "
                "-DN_VECLEN=%ld -DBRANCHING=%d -DCB_INDEX=%15.15lf "
                "-DMAX_CHECKS=%d -DN_NODES=%d -DLOC_SIZE=%ld",
                distTypeName.c_str(), elmTypeName.c_str(), (distTypeName + "4").c_str(),
                getCLknn(knn), heapSize, this->root_->radius,
                4*((this->veclen_+3)/4), this->branching_, this->cb_index_,
                maxChecks, this->cl_num_nodes_-1, locSize);

        kern = this->buildCLKernel(context, dev, program_src, prog_name, build_str);
        free(build_str);

        return kern;
    }

    /**
     * Frees any OpenCL memory that has been allocated, and dependencies such
     * as kernel(s). To be called when the index changes, and thus must be
     * rebuilt or as a destructor.
     */
    void freeCLIndexMem()
    {
        this->freeCLMem(&(this->cl_node_index_arr_));
        this->freeCLMem(&(this->cl_node_pivots_));
        this->freeCLMem(&(this->cl_node_radii_));
        this->freeCLMem(&(this->cl_node_variance_));
        this->freeCLMem(&(this->cl_dataset_));

        // Assume any kernel is now invalid
        if (this->cl_knn_search_kern_) {
            clReleaseKernel(this->cl_knn_search_kern_);
            this->cl_knn_search_kern_ = NULL;
        }
    }

    void freeIndex()
    {
        BaseClass::freeIndex();
        freeCLIndexMem();
    }

    /**
     * Perform a set of queries using the (previously built) query kernel. The knn
     * and params arguments must match the arguments used to build the kernel.
     *
     * @param[in] queries The query points for which to find the nearest neighbors
     * @param[out] indices The indices of the nearest neighbors found
     * @param[out] dists Distances to the nearest neighbors found
     * @param[in] knn Number of nearest neighbors to return
     * @param[in] params Search parameters
     */
    void knnSearchCL(const Matrix<ElementType>& queries,
                     Matrix<size_t>& indices,
                     Matrix<DistanceType>& dists,
                     size_t knn,
                     const SearchParams& params ) const
    {
        // Unable to init inside of fxn due to `const`
        assert(this->cl_cmd_queue_);
        assert(knn == this->cl_kern_knn_);
        assert(params.checks == this->cl_kern_max_checks_);
        cl_int err = CL_SUCCESS;

        // Get the context and device ID from the queue
        cl_context context;
        err = clGetCommandQueueInfo(this->cl_cmd_queue_, CL_QUEUE_CONTEXT,
                                    sizeof(context), &context, NULL);
        assert(err == CL_SUCCESS);
        cl_device_id dev;
        err = clGetCommandQueueInfo(this->cl_cmd_queue_, CL_QUEUE_DEVICE,
                                    sizeof(dev), &dev, NULL);
        assert(err == CL_SUCCESS);

        // Get the kernel
        cl_kernel kern = this->cl_knn_search_kern_;

        // Figure out the threads per local group
        int heapSize = std::max(getAvgNodesNeeded(params.checks), getCLknn(knn));
        size_t numThreads, locSize;
        this->getCLNumThreads(dev, queries.rows, heapSize, &numThreads, &locSize);

        if (heapSize > locSize) {
            numThreads = numThreads/locSize;
            locSize = 0;
        }

        // Get the query & temp device memory
        cl_mem resultDistArr_cl = NULL, resultIdArr_cl = NULL, queryArr_cl = NULL;

        initCLQueryMem(context, queries, knn,
                       &resultDistArr_cl, &resultIdArr_cl, &queryArr_cl);

        // Run the kernel
        runCLKMeansKern(kern, numThreads, locSize,
                        queries.rows, resultDistArr_cl, resultIdArr_cl,
                        queryArr_cl);

        // This won't be needed again
        this->freeCLMem(&queryArr_cl);

        // Copy results back
        getCLQueryMem(indices, dists, knn, resultDistArr_cl, resultIdArr_cl);

        // Release memory
        this->freeCLMem(&resultDistArr_cl);
        this->freeCLMem(&resultIdArr_cl);
    }

    virtual bool clParamsMatch(size_t knn, const SearchParams& params) const
    {
        return cl_kern_knn_ == knn && cl_kern_max_checks_ == params.checks;
    }

    /**
     * Are the conditions right for an OpenCL search to actually be faster?
     *
     * Don't OpenCL search if the number of queries is too small. Assume that
     * a GPU has roughly, 4k shaders. Each query is one work group. A work
     * group size is, at minimum, 32-64 depending on the architecture. That
     * means that the minimum query size should be at least 128 to have a
     * chance of filling a GPU's shaders. (To say nothing of occupancy
     * calculations.)
     *
     * @return Boolean of whether an OpenCL search is a good idea.
     */
    virtual int shouldCLKnnSearch(int numQueries, size_t knn, const SearchParams& params) const
    {
        return numQueries >= 128 && this->size_ > this->branching_ && clParamsMatch(knn, params);
    }


    /**
     * Traverse the node tree and figure out how many nodes we need to allocate
     * space for.
     *
     * @param[in] node The current node that we're traversing.
     * @param[out] num_nodes Pointer to the current count of nodes we've traversed.
     * @prarm[out] num_parents Pointer to the number of parent nodes we've traversed.
     * @param[out] num_leaves Pointer to the number of leaves we've traversed.
     * @param[in] depth Current depth of the tree traversal.
     * @param[out] minDepth Minimum depth that we've reached leaves at.
     * @param[out] maxDepth Maximum depth that we've reached leaves at.
     */
    void countNodes(struct BaseClass::Node* node, int *numNodes, int *numParents, int *numLeaves,
                    int depth, int *minDepth, int *maxDepth) const
    {
        // Count this one
        (*numNodes)++;

        if (node->childs.empty()) {
            (*numLeaves) += node->size;
            if ((*minDepth) > depth)
                (*minDepth) = depth;
            if ((*maxDepth) < depth)
                (*maxDepth) = depth;
        } else {
            (*numParents)++;
            for (int i = 0; i < this->branching_; ++i)
                countNodes(node->childs[i], numNodes, numParents, numLeaves,
                           depth+1, minDepth, maxDepth);
        }
    }

    /**
     * Flatten and save the k-means tree at a given depth. This allows us to
     * save the nodes as a breadth-first traversal which will give us some
     * locality in the index, which will be useful for cache utilization. Each
     * index location is located at a node id and stores an integer which points
     * to the index of the list of children (of length branching_). The pointers
     * to the leaves are lists of indices in the dataset. Each leaf list starts
     * with a count of the leaves in the list, and continues with the indices.
     *
     * @param[in] node The current node that we are traversing.
     * @param[in] thisNodeId The ID that this node has been assigned by the traversal.
     * @param nextPtr The pointer to the next free position in the index array.
     * @param[in] saveLeaves Should we save leaves on this pass? (Leaves are saved at the end of the array for simplicity)
     * @param nodeQueue Manage the breadth-first traversal through this queue.
     * @param indexArrWork Save the flattened index into this array.
     * @param[out] nodePivotsWork Save the pivots for each node here.
     * @param[out] nodeRadiiWork Save the radii for each node here.
     * @param[out] nodeVarianceWork Save the variance for each node here.
     */
    void copyNodeData(struct BaseClass::Node* node, int thisNodeId, int *nextPtr,
                      int saveLeaves, std::queue<struct BaseClass::Node*> *nodeQueue,
                      int *indexArrWork, ElementType *nodePivotsWork,
                      DistanceType *nodeRadiiWork, DistanceType *nodeVarianceWork )
    {
        int n_veclen = 4*((this->veclen_+3)/4);

        // childNodePtr only valid if there are children nodes
        int childNodePtr = 0;
        if (thisNodeId >= 0) {
            childNodePtr = indexArrWork[thisNodeId];
            assert(node->radius == nodeRadiiWork[thisNodeId]);
            assert(node->variance == nodeVarianceWork[thisNodeId]);
        }

        if (node->childs.empty()) {
            // Wait until the end of the flattening before saving the leaves
            if (saveLeaves) {
                // Save pointer to the list of point indices
                indexArrWork[thisNodeId] = (*nextPtr);

                // Mark as the final element
                indexArrWork[(*nextPtr)++] = node->size;
                assert(node->size > 0);

                // Add point leaves to the index & dataset
                for (int i=0; i < node->size; ++i) {
                    // Save point index
                    int index = node->points[i].index;
                    // Inc for the next index
                    indexArrWork[(*nextPtr)++] = index;
                    assert(index < this->size_);
                    assert(index >= 0);
/*
                int index = point_info.index;
                if (with_removed) {
                    if (removed_points_.test(index)) continue;
 */
                }
            }
        } else {
            for (int i = 0; i < this->branching_; ++i) {
                NodePtr childNode = node->childs[i];

                // Enqueue the children
                nodeQueue->push(childNode);

                if (!saveLeaves) {
                    // Add the nodes to the index, pivots, radii, & variance

                    int childNodeId = childNodePtr+i;

                    // Make pointers to additional parent nodes (because they're in the front of the index)
                    if (!(childNode->childs.empty())) {
                        indexArrWork[childNodeId] = (*nextPtr);
                        (*nextPtr) += this->branching_;
                    }

                    // Save pivot vector (& pad with zeros for alignment & SIMD operations)
                    for (int v = 0; v < n_veclen; ++v)
                        if (v < this->veclen_) {
                            assert(std::isfinite(childNode->pivot[v]));
                            nodePivotsWork[n_veclen*childNodeId+v] = childNode->pivot[v];
                        } else
                            nodePivotsWork[n_veclen*childNodeId+v] = 0;

                    // Save radius and variance
                    nodeRadiiWork[childNodeId] = childNode->radius;
                    nodeVarianceWork[childNodeId] = childNode->variance;

                    assert(std::isfinite(childNode->radius));
                    assert(std::isfinite(childNode->variance));
                    assert(childNode->radius >= 0.0);
                    assert(childNode->variance >= 0.0);
                }
            }
        }
    }

    /**
     * Init and format the device memory used to preform a query. We need each
     * query vector to be passed in and a structure for the results to be saved.
     *
     * @param[in] context The OpenCL context that we're working in.
     * @param[in] queries The matrix of queries.
     * @param[in] knn The number of nearest neighbors we're searching for.
     * @param[out] resultDistArr Pointer to the CL device memory the result distances are saved into.
     * @param[out] resultIdArr Pointer to the CL device memory the result indices are saved into.
     * @param[out] queryArr Pointer to the CL device memory the query points are saved into.
     */
    void initCLQueryMem(cl_context context,
                        const Matrix<ElementType>& queries, size_t knn,
                        cl_mem *resultDistArr, cl_mem *resultIdArr,
                        cl_mem *queryArr) const
    {
        cl_int err = CL_SUCCESS;

        // The vector length is rounded up to the next multiple of 4
        // for alignment and SIMD operations
        int n_veclen = 4*((this->veclen_+3)/4);
        int n_knn = getCLknn(knn);

        // How much memory will we need for the queries?
        size_t sz_query = sizeof(ElementType)*n_veclen*queries.rows;
        cl_mem query_arr_work_cl;
        ElementType *query_arr_work;
        cl_command_queue cmd_queue = this->cl_cmd_queue_;

        // Use pinned memory as working space because the host-device transfer is faster
        this->allocCLDevPinnedWorkMem(context, sz_query, CL_MEM_READ_ONLY,
                                      queryArr, &query_arr_work_cl, &query_arr_work);
        err = clFinish(cmd_queue);
        assert(err == CL_SUCCESS);

        // Copy queries into the working memory
        for (int r = 0; r < queries.rows; r++)
            for (int v = 0; v < n_veclen; v++)
                // (& pad with zeros for alignment & SIMD operations)
                if (v < this->veclen_) {
                    assert(std::isfinite(queries[r][v]));
                    query_arr_work[r*n_veclen + v] = queries[r][v];
                } else
                    query_arr_work[r*n_veclen + v] = 0.0;

        // Start query copy from host to device memory
        err = clEnqueueWriteBuffer(cmd_queue, *queryArr, CL_FALSE, 0,
                                   sz_query, (void*)query_arr_work, 0, NULL, NULL);
        assert(err == CL_SUCCESS);

        // Alloc results arrays
        size_t sz_result_id = sizeof(int)*queries.rows*n_knn;
        size_t sz_result_dist = sizeof(DistanceType)*queries.rows*n_knn;

        (*resultIdArr) = clCreateBuffer(context, CL_MEM_READ_WRITE, sz_result_id, NULL, &err);
        assert(err == CL_SUCCESS);
        (*resultDistArr) = clCreateBuffer(context, CL_MEM_READ_WRITE, sz_result_dist, NULL, &err);
        assert(err == CL_SUCCESS);

        // Finish the query copy
        err = clFinish(cmd_queue);
        assert(err == CL_SUCCESS);

        // Release the (pinned) working resources for the query memory
        clReleaseMemObject(query_arr_work_cl);
    }

    /**
     * Set the arguments and run the search kernel
     *
     * @param[in] kern Compiled OpenCL search kernel.
     * @param[in] numThreads Number of threads to execute appropriate for this device. Should be at least numQueries and divisible by locSize.
     * @param[in] locSize The size of each thread group.
     * @param[in] numQueries Actual number of queries to perform.
     * @param[in] resultDistArr Use this CL memory for the result distance kernel argument.
     * @param[in] resultIdArr Use this CL memory for the result ID kernel argument.
     * @param[in] queryArr Use this CL memory for the query point kernel argument.
     * @return An OpenCL error code.
     */
    cl_int runCLKMeansKern(cl_kernel kern, size_t numThreads, size_t locSize,
                           int numQueries, cl_mem resultDistArr, cl_mem resultIdArr,
                           cl_mem queryArr) const
    {
        cl_int err = CL_SUCCESS;

        err = clSetKernelArg(kern, 0, sizeof(cl_mem), &this->cl_node_index_arr_);
        assert(err == CL_SUCCESS);
        err = clSetKernelArg(kern, 1, sizeof(cl_mem), &this->cl_node_pivots_);
        assert(err == CL_SUCCESS);
        err = clSetKernelArg(kern, 2, sizeof(cl_mem), &this->cl_node_variance_);
        assert(err == CL_SUCCESS);
        err = clSetKernelArg(kern, 3, sizeof(cl_mem), &this->cl_node_radii_);
        assert(err == CL_SUCCESS);
        err = clSetKernelArg(kern, 4, sizeof(cl_mem), &this->cl_dataset_);
        assert(err == CL_SUCCESS);
        err = clSetKernelArg(kern, 5, sizeof(cl_mem), &resultDistArr);
        assert(err == CL_SUCCESS);
        err = clSetKernelArg(kern, 6, sizeof(cl_mem), &resultIdArr);
        assert(err == CL_SUCCESS);
        err = clSetKernelArg(kern, 7, sizeof(cl_mem), &queryArr);
        assert(err == CL_SUCCESS);
        err = clSetKernelArg(kern, 8, sizeof(int), &numQueries);
        assert(err == CL_SUCCESS);

        return this->runKern(kern, numThreads, locSize);
    }

    /**
     * Retrieve the results from device memory for this query and save them in
     * the output arrays.
     *
     * @param[out] indices The dataset indices from the result array.
     * @param[out] dists The dataset distances from the result array.
     * @param[in] knn The number of neighbors requested per query point.
     * @param[in] resultDistArr_cl The CL device memory containing the distances.
     * @param[in] resultIdArr_cl The CL device memory containing the indices.
     */
    void getCLQueryMem(Matrix<size_t>& indices, Matrix<DistanceType>& dists, size_t knn,
                       cl_mem resultDistArr_cl, cl_mem resultIdArr_cl) const
    {
        cl_int err = CL_SUCCESS;
        int n_knn = getCLknn(knn);
        size_t sz_result_id = sizeof(int)*indices.rows*n_knn;
        size_t sz_result_dist = sizeof(DistanceType)*indices.rows*n_knn;

        // Make a buffer for the output memory & copy it
        // FIXME: Said buffer should be pinned for best performance
        int *rsId = (int *)malloc(sz_result_id);
        err = clEnqueueReadBuffer(this->cl_cmd_queue_, resultIdArr_cl, CL_FALSE, 0, sz_result_id,
                                  (void *)rsId, 0, NULL, NULL);
        assert(err == CL_SUCCESS);
        DistanceType *rsDist = (DistanceType *)malloc(sz_result_dist);
        err = clEnqueueReadBuffer(this->cl_cmd_queue_, resultDistArr_cl, CL_FALSE, 0, sz_result_dist,
                                  (void *)rsDist, 0, NULL, NULL);
        assert(err == CL_SUCCESS);
        err = clFinish(this->cl_cmd_queue_);
        assert(err == CL_SUCCESS);

        // Copy all results
        for (int r = 0; r < indices.rows; ++r) {
            for (int c = 0; c < knn; ++c) {
                indices[r][c] = rsId[r*n_knn + c];
                dists[r][c] = rsDist[r*n_knn + c];
                assert(std::isfinite(dists[r][c]));
            }
        }

        // Free buffer mem
        free(rsId);
        free(rsDist);
    }

    /**
     * On average, this many nodes will fill MAX_CHECKS. This is useful so the OpenCL code
     * can predict and/or play fast-and-loose with the node/memory requirements. We assume
     * that the variables this->cl_num_nodes_, this->cl_num_parents_, and this->cl_num_leaves_
     * are valid.
     *
     * @param[in] maxChecks Expected total checks to aim for.
     * @return Number of nodes needed (on average) to fill maxChecks.
     */
    int getAvgNodesNeeded(int maxChecks) const
    {
        return maxChecks*(this->cl_num_nodes_-this->cl_num_parents_)/
                                    (this->cl_num_leaves_);
    }

    /**
     * Calculate the adjusted number of columns of in the knn result array. Make a size that
     * works well with vector instructions.
     *
     * @param[in] knn The requested number of nearest neighbors to retrieve.
     * @return The number of nearest neighbors to actually use.
     */
    int getCLknn(size_t knn) const
    {
        // Each full set of results is a multiple of four plus one result to be replaced
        // when a new result is added
        return 4*((knn+2)/4)+1;
    }

    typedef typename BaseClass::Node* NodePtr;

    /**
     * Node structure (used by the OpenCL implementation). Counts the size of the current index tree.
     */
    int cl_num_nodes_;
    int cl_num_parents_;
    int cl_num_leaves_;

    /**
     * Saved OpenCL memory structures resident on the device.
     */
    cl_mem cl_node_index_arr_;
    cl_mem cl_node_pivots_;
    cl_mem cl_node_radii_;
    cl_mem cl_node_variance_;
    cl_mem cl_dataset_;
};
}

#endif /* FLANN_KMEANS_OPENCL_INDEX_H_ */
#endif /* FLANN_USE_OPENCL */
