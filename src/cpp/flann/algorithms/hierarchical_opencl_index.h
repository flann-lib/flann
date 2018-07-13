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
#ifndef FLANN_HIERARCHICAL_OPENCL_INDEX_H_
#define FLANN_HIERARCHICAL_OPENCL_INDEX_H_

#include <queue>

#include "flann/algorithms/nn_opencl_index.h"
#include "flann/algorithms/hierarchical_clustering_index.h"

namespace flann
{

struct HierarchicalClusteringOpenCLIndexParams : public HierarchicalClusteringIndexParams
{
    HierarchicalClusteringOpenCLIndexParams(
        int branching = 32,
        flann_centers_init_t centers_init = FLANN_CENTERS_RANDOM,
        int trees = 4, int leaf_max_size = 100) :
    HierarchicalClusteringIndexParams(branching, centers_init, trees, leaf_max_size)
    {
        // Override parent param's algorithm
        (*this)["algorithm"] = FLANN_INDEX_HIERARCHICAL_OPENCL;
    }
};

/**
 * Hierarchical index
 *
 * Contains a tree constructed through a hierarchical clustering
 * and other information for indexing a set of points for nearest-neighbour matching.
 */
template <typename Distance>
class HierarchicalClusteringOpenCLIndex : public HierarchicalClusteringIndex<Distance>, public OpenCLIndex
{
public:
    typedef typename Distance::ElementType ElementType;
    typedef typename Distance::ResultType DistanceType;

    typedef HierarchicalClusteringIndex<Distance> BaseClass;

    flann_algorithm_t getType() const
    {
        return FLANN_INDEX_HIERARCHICAL_OPENCL;
    }

    /**
     * Index constructor
     *
     * Params:
     *          inputData = dataset with the input features
     *          params = parameters passed to the hierarchical clustering algorithm
     */
    HierarchicalClusteringOpenCLIndex(
        const Matrix<ElementType>& inputData,
        const IndexParams& params = HierarchicalClusteringOpenCLIndexParams(),
        Distance d = Distance())
        : BaseClass(inputData, params, d)
    {
        cl_node_index_arr_ = NULL;
        cl_node_pivots_ = NULL;
        cl_node_radii_ = NULL;
        cl_node_variance_ = NULL;
        cl_dataset_ = NULL;
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
        if (this->cl_node_index_arr_ && this->cl_node_pivots_ && this->cl_dataset_)
            return;

        cl_int err = CL_SUCCESS;

        // Figure out the sizes we need to allocate mem for...
        this->cl_num_nodes_ = 0;
        this->cl_num_parents_ = 0;
        this->cl_num_leaves_ = 0;
        int maxDepth = 0;
        int minDepth = 9999;

        // Count nodes in all trees
        for (int i = 0; i < this->trees_; i++)
            countNodes(this->tree_roots_[i], &this->cl_num_nodes_,
                       &this->cl_num_parents_, &this->cl_num_leaves_,
                       1, &minDepth, &maxDepth);

        // Check that our assumptions about the structure of the tree is correct
        assert(this->size_ == this->cl_num_leaves_);
        assert(this->cl_num_nodes_ % this->branching_ == 1);
        assert(this->cl_num_parents_*this->branching_ + 1 == this->cl_num_nodes_);
        cl_command_queue cmd_queue = this->cl_cmd_queue_;

        // Allocate working vars
        cl_mem index_arr_work_cl, node_pivots_work_cl, dataset_work_cl;
        int *index_arr_work;
        ElementType *node_pivots_work;
        ElementType *dataset_work;
        int n_veclen = 4*((this->veclen_+3)/4);

        // Find the sizes of the blocks of memory are that we will be using
        size_t sz_index = sizeof(int)*(this->cl_num_parents_*this->branching_+this->cl_num_leaves_+
                                       this->cl_num_nodes_-this->cl_num_parents_);
        size_t sz_pivots = sizeof(ElementType)*this->cl_num_nodes_*n_veclen;
        size_t sz_dataset = sizeof(ElementType)*this->size_*n_veclen;

        // Alloc device & pinned working memory
        this->allocCLDevPinnedWorkMem(context, sz_index, CL_MEM_READ_ONLY,
                                      &this->cl_node_index_arr_, &index_arr_work_cl, &index_arr_work);
        this->allocCLDevPinnedWorkMem(context, sz_pivots, CL_MEM_READ_ONLY,
                                      &this->cl_node_pivots_, &node_pivots_work_cl, &node_pivots_work);
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
        int next_index = this->trees_;

        // Init with all roots
        for (int i = 0; i < this->trees_; i++)
            nodeQueue.push(this->tree_roots_[i]);

        for (int i = -1; !nodeQueue.empty(); ++i) {
            copyNodeData(nodeQueue.front(), i, &next_index, 0, &nodeQueue,
                         index_arr_work, node_pivots_work );
            nodeQueue.pop();
        }

        // Shift from storing parent nodes to storing leaf indicies (indexing into the dataset)
        for (int i = 0; i < this->trees_; i++)
            nodeQueue.push(this->tree_roots_[i]);

        for (int i = -1; !nodeQueue.empty(); ++i) {
            copyNodeData(nodeQueue.front(), i, &next_index, 1, &nodeQueue,
                         index_arr_work, node_pivots_work );
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
        err = clFinish(cmd_queue);
        assert(err == CL_SUCCESS);

        // Release working resources
        clReleaseMemObject(index_arr_work_cl);
        clReleaseMemObject(node_pivots_work_cl);
        clReleaseMemObject(dataset_work_cl);

        // Create dummy arrays for calculations that we won't be doing.
        this->cl_node_radii_ = clCreateBuffer(context, CL_MEM_READ_ONLY, 256, NULL, &err);
        assert(err == CL_SUCCESS);
        this->cl_node_variance_ = clCreateBuffer(context, CL_MEM_READ_ONLY, 256, NULL, &err);
        assert(err == CL_SUCCESS);
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
        char *program_src;

        int heapSize = std::max(getAvgNodesNeeded(maxChecks), getCLknn(knn));
        size_t numThreads, locSize;

        const char *initResultStr =
"void initResult(__global ELEMENT_TYPE *vec, __global ELEMENT_TYPE *dataset,\n"
                "__global DISTANCE_TYPE *resultDist, __global int *resultId )\n"
"{\n"
    "for (int i = 0; i < N_TREES; i++) {\n"
        // Unsure how important this distance is
        "resultDist[i] = vecDist(vec, dataset, 0);\n"
        "resultId[i] = i*BRANCHING;\n"
    "}\n"
"}\n";

        const char *initHeapStr =
"void initHeap(__local DISTANCE_TYPE *heapDist, __local int *heapId)\n"
"{\n"
    "for (int i = 0; i < N_TREES; i++) {\n"
        "heapDist[i] = 0;\n"
        "heapId[i] = i*BRANCHING;\n"
    "}\n"
"}\n";

        // See if we can use local thread groups to speed computation (GPU-likely optimization)
        this->getCLNumThreads(dev, 0, heapSize, &numThreads, &locSize);

        // Find the appropriate vars for the requested kernel
        if (maxChecks == FLANN_CHECKS_UNLIMITED) {
            prog_name = "findNeighborsExact";
            program_src = getCLSrc(false, true, initResultStr, Distance::type());
        } else if (heapSize <= locSize) {
            prog_name = "findNeighborsLocal";

            // Use (GPU) local mem for the heap
            heapSize = locSize*2;

            // Set the source to use the local thread group optimization
            program_src = getCLSrc(true, false, initHeapStr, Distance::type());
        } else {
            prog_name = "findNeighbors";

            // Set source as vectorized CPU implementation
            program_src = getCLSrc(false, true, initResultStr, Distance::type());
        }

        std::string distTypeName = TypeInfo<DistanceType>::clName();
        std::string elmTypeName = TypeInfo<ElementType>::clName();
#ifndef NDEBUG
        size_t distTypeSize =
#endif
        TypeInfo<DistanceType>::size();

        // Assume that the distance size is 4 because I think it's always float
        assert(distTypeSize == 4);

        // Compile in all invariants for better optimization opportunity and less complexity
        char *build_str = (char *)calloc(128000, sizeof(char));
        sprintf(build_str,  "-cl-fast-relaxed-math -Werror "
                "-DDISTANCE_TYPE=%s -DELEMENT_TYPE=%s -DDISTANCE_TYPE_VEC=%s "
                "-DN_RESULT=%d -DN_HEAP=%d -DMAX_DIST=%15.15lf "
                "-DN_VECLEN=%ld -DBRANCHING=%d -DN_TREES=%d "
                "-DMAX_CHECKS=%d -DN_NODES=%d -DLOC_SIZE=%ld",
                distTypeName.c_str(), elmTypeName.c_str(), (distTypeName + "4").c_str(),
                getCLknn(knn), heapSize, TypeInfo<DistanceType>::max(),
                4*((this->veclen_+3)/4), this->branching_, this->trees_,
                maxChecks, this->cl_num_nodes_-1, locSize);

        kern = this->buildCLKernel(context, dev, program_src, prog_name, build_str);
        free(build_str);

        delete[] program_src;
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
        assert(clParamsMatch(knn, params));
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
        runCLHierarchicalKern(kern, numThreads, locSize,
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
            (*numLeaves) += node->points.size();
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
     * Flatten and save the hierarchical trees. This allows us to
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
     */
    void copyNodeData(struct BaseClass::Node* node, int thisNodeId, int *nextPtr,
                      int saveLeaves, std::queue<struct BaseClass::Node*> *nodeQueue,
                      int *indexArrWork, ElementType *nodePivotsWork)
    {
        int n_veclen = 4*((this->veclen_+3)/4);

        // childNodePtr only valid if there are children nodes
        int childNodePtr = 0;
        if (thisNodeId >= 0) {
            childNodePtr = indexArrWork[thisNodeId];
        }

        if (node->childs.empty()) {
            // Wait until the end of the flattening before saving the leaves
            if (saveLeaves) {
                // Save pointer to the list of point indices
                indexArrWork[thisNodeId] = (*nextPtr);

                // Mark as the final element
                indexArrWork[(*nextPtr)++] = node->points.size();
                assert(node->points.size() > 0);

                // Add point leaves to the index & dataset
                for (int i=0; i < node->points.size(); ++i) {
                    // Save point index
                    size_t index = node->points[i].index;

                    if (this->removed_ && this->removed_points_.test(index))
                        continue;

                    // Inc for the next index
                    indexArrWork[(*nextPtr)++] = index;
                    assert(index < this->size_);
                    assert(index >= 0);
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
    cl_int runCLHierarchicalKern(cl_kernel kern, size_t numThreads, size_t locSize,
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
                size_t idx = rsId[r*n_knn + c];
                this->indices_to_ids(&idx, &idx, 1);
                indices[r][c] = idx;
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

#endif /* FLANN_HIERARCHICAL_OPENCL_INDEX_H_ */
#endif /* FLANN_USE_OPENCL */
