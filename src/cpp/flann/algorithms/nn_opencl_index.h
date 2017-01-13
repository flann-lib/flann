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
#ifndef FLANN_NN_OPENCL_INDEX_H_
#define FLANN_NN_OPENCL_INDEX_H_

#ifdef __APPLE__
#include <OpenCL/OpenCL.h>
#else
#include <CL/opencl.h>
#endif

#include <cassert>

namespace flann
{

template <typename T>
class TypeInfo {
public:
    static std::string clName() { return "unknown"; }
    static size_t size() { return 0; }
};
#define TYPE_NAME_AND_SIZE(T, TN) template <> \
class TypeInfo<T> { \
public: \
    static std::string clName() { return TN; } \
    static size_t size() { return sizeof(T); } \
};

TYPE_NAME_AND_SIZE(float, "float");
TYPE_NAME_AND_SIZE(double, "double");
TYPE_NAME_AND_SIZE(bool, "bool");
TYPE_NAME_AND_SIZE(char, "char");
TYPE_NAME_AND_SIZE(unsigned char, "uchar");
TYPE_NAME_AND_SIZE(short, "short");
TYPE_NAME_AND_SIZE(unsigned short, "ushort");
TYPE_NAME_AND_SIZE(int, "int");
TYPE_NAME_AND_SIZE(unsigned int, "uint");
TYPE_NAME_AND_SIZE(long, "long");
TYPE_NAME_AND_SIZE(unsigned long, "ulong");
#undef TYPE_NAME_AND_SIZE

class OpenCLIndex
{
public:
    OpenCLIndex()
    {
        own_cq_ = false;
        cl_knn_search_kern_ = NULL;
        cl_cmd_queue_ = NULL;
    }

    virtual ~OpenCLIndex()
    {
        if (cl_knn_search_kern_)
        {
            clReleaseKernel(cl_knn_search_kern_);
            cl_knn_search_kern_ = NULL;
        }

        if (cl_cmd_queue_)
        {
            cl_context context = NULL;
            if (own_cq_)
            {
                cl_int err = CL_SUCCESS;
                // Get the context so we can release it later
                err = clGetCommandQueueInfo(cl_cmd_queue_, CL_QUEUE_CONTEXT,
                                            sizeof(context), &context, NULL);
                assert(err == CL_SUCCESS);
            }

            clReleaseCommandQueue(cl_cmd_queue_);
            cl_cmd_queue_ = NULL;

            if (own_cq_)
                clReleaseContext(context);
        }

    }

    /**
     *
     */
    void buildCLKnnSearch(size_t knn,
                          const SearchParams& params,
                          cl_command_queue cq = NULL)
    {
        cl_int err = CL_SUCCESS;
        if (!cq)
        {
            own_cq_ = true;

            // Make a default command queue
            cl_device_id device_id;
            err = clGetDeviceIDs(NULL, CL_DEVICE_TYPE_ALL, 1, &device_id, NULL);
            assert(err == CL_SUCCESS);
            cl_context context = clCreateContext(0, 1, &device_id, NULL, NULL, &err);
            assert(err == CL_SUCCESS);
            cq = clCreateCommandQueue(context, device_id, 0, &err);
            assert(err == CL_SUCCESS);
        }

        if (cl_cmd_queue_ != NULL && cl_cmd_queue_ != cq) {
            // Using a new command queue, reset everything!
            freeCLIndexMem();
        } else if (cl_cmd_queue_ == cq &&
                   cl_kern_knn_ == knn && cl_kern_max_checks_ == params.checks) {
            return;
        }

        cl_cmd_queue_ = cq;

        // Get the useful OpenCL environment info
        cl_context context;
        err = clGetCommandQueueInfo(cq, CL_QUEUE_CONTEXT, sizeof(context), &context, NULL);
        assert(err == CL_SUCCESS);
        cl_device_id dev;
        err = clGetCommandQueueInfo(cq, CL_QUEUE_DEVICE, sizeof(dev), &dev, NULL);
        assert(err == CL_SUCCESS);

        // Init the cl_mem index
        initCLIndexMem(context);

        // Update kernel if needed
        if (!cl_knn_search_kern_ || !clParamsMatch(knn, params)) {

            // Free old kernel first
            if (cl_knn_search_kern_)
                clReleaseKernel(cl_knn_search_kern_);

            // Build new one
            cl_knn_search_kern_ = buildCLknnSearchKernel(context, dev, knn, params.checks);
            cl_kern_knn_ = knn;
            cl_kern_max_checks_ = params.checks;
        }
    }

protected:

    virtual bool clParamsMatch(size_t knn, const SearchParams& params) const
    {
        // unimplemented in nn_index
        printf("in unimplemented clParamsMatch()!\n");
        return false;
    }

    /**
     * Format the index for, and copy the index into, OpenCL device memory.
     * The device memory format is not intended to be changeable, so if the
     * index changes, then the index device memory should be freed and rebuilt.
     *
     * @param[in] context The OpenCL context to use.
     */
    virtual void initCLIndexMem(cl_context context)
    {
        // unimplemented in nn_index
        printf("in unimplemented initCLIndexMem()!\n");
    }

    /**
     * Build the kernel for knnSearch() using the given params and save it.
     * Future calls to knnSearch() that use those params are elgible for OpenCL
     * accelleration.
     *
     * @param[in] context The OpenCL context to use.
     * @param[in] dev The device we're compiling for.
     * @param[in] knn The number of nearest neighbors we're expecting to retrieve.
     * @param[in] maxChecks The maximum number of checks we're expecting to make.
     * @return The compiled OpenCL kernel.
     */
    virtual cl_kernel buildCLknnSearchKernel(cl_context context, cl_device_id dev,
                                             size_t knn, int maxChecks)
    {
        // unimplemented in nn_index
        printf("in unimplemented buildCLknnSearchKernel()!\n");
        return NULL;
    }

    /**
     * Frees any OpenCL memory that has been allocated, and dependencies such
     * as kernel(s). To be called when the index changes, and thus must be
     * rebuilt or as a destructor.
     */
    virtual void freeCLIndexMem()
    {
        // unimplemented in nn_index
        printf("in unimplemented freeCLIndexMem()!\n");
    }

    /**
     * The number of threads and local size to use for the number of queries.
     * Should be a power of two, minimum of 32 on GPU, and within work group size.
     *
     * @param[in] dev The device we're targeting.
     * @param[in] numQueries The number of queries we expect to make.
     * @param[in] minLocSize The requested minimum local group size.
     * @param[out] numThreads The number of threads we'll want for the given number of queries and group size.
     * @param[out] locSize The number of threads per thread group. May actually be smaller than minLocSize depending on the device.
     */
    void getCLNumThreads(cl_device_id dev, int numQueries, int minLocSz,
                         size_t *numThreads, size_t *locSize) const
    {
        cl_int err = CL_SUCCESS;
        // Get the device type
        cl_device_type dev_type;
        err = clGetDeviceInfo(dev, CL_DEVICE_TYPE, sizeof(dev_type), &dev_type, NULL);
        assert(err == CL_SUCCESS);

        // Get the maximum group size
        size_t max_work_group_size;
        err = clGetDeviceInfo(dev, CL_DEVICE_MAX_WORK_GROUP_SIZE,
                              sizeof(size_t), &max_work_group_size, NULL);
        assert(err == CL_SUCCESS);

        // Maximum work group size per dimension
        size_t max_work_item_sizes[3];
        err = clGetDeviceInfo(dev, CL_DEVICE_MAX_WORK_ITEM_SIZES,
                              sizeof(max_work_item_sizes), &max_work_item_sizes, NULL);
        assert(err == CL_SUCCESS);

        if (max_work_group_size < max_work_item_sizes[0])
            max_work_group_size = max_work_item_sizes[0];

        // Doesn't seem to run on my CPU with a work group over 1, even though
        // max_work_group_size == 1024. Bug in Apple's OpenCL implementation?
        if ((minLocSz <= 1 && dev_type != CL_DEVICE_TYPE_GPU)
             || dev_type == CL_DEVICE_TYPE_CPU || max_work_group_size < 2) {
            (*locSize) = 1;
        } else if ((minLocSz <= 2 && dev_type != CL_DEVICE_TYPE_GPU)
                   || max_work_group_size < 4) {
            (*locSize) = 2;
        } else if ((minLocSz <= 4 && dev_type != CL_DEVICE_TYPE_GPU)
                    || max_work_group_size < 8) {
            (*locSize) = 4;
        } else if ((minLocSz <= 8 && dev_type != CL_DEVICE_TYPE_GPU)
                    || max_work_group_size < 16) {
            (*locSize) = 8;
        } else if ((minLocSz <= 16 && dev_type != CL_DEVICE_TYPE_GPU)
                    || max_work_group_size < 32) {
            (*locSize) = 16;
            // Should be at least 32 on GPU for hardware thread scheduler reasons
        } else if (minLocSz <= 32 || max_work_group_size < 64) {
            (*locSize) = 32;
        } else if (minLocSz <= 64 || max_work_group_size < 128) {
            (*locSize) = 64;
        } else if (minLocSz <= 128 || max_work_group_size < 256) {
            (*locSize) = 128;
        } else if (minLocSz <= 256 || max_work_group_size < 512) {
            (*locSize) = 256;
        } else if (minLocSz <= 512 || max_work_group_size < 1024) {
            (*locSize) = 512;
        } else if (minLocSz <= 1024 || max_work_group_size < 2048) {
            (*locSize) = 1024;
        }

        (*numThreads) = numQueries*(*locSize);
    }

    /**
     * Build the given program from the given source with the given flags.
     * Handle the multitude of kernel building compile errors with some
     * useful message.
     *
     * @param[in] context OpenCL context to use.
     * @param[in] dev OpenCL device to compile for.
     * @param[in] programSrc The source code for the OpenCL kernel.
     * @param[in] progName The name of the kernel to compile in the source code.
     * @param[in] buildStr The string to use to compile the kernel. May contain flags (such as -cl-fast-relaxed-math -Werror) or defined invarants.
     * @return The compiled OpenCL kernel.
     */
    cl_kernel buildCLKernel(cl_context context, cl_device_id dev, const char *programSrc,
                            const char *progName, char *buildStr) const
    {
        cl_program program;
        cl_kernel kernel;
        cl_int err = 0;

        program = clCreateProgramWithSource(context, 1, &programSrc, NULL, &err);

        err = clBuildProgram(program, 1, &dev, buildStr, NULL, NULL);

        //Detailed debugging info
        if (err != CL_SUCCESS)
        {
            size_t len;
            char *buffer = (char *)calloc(128000, sizeof(char));

            printf("Error: Failed to build program executable!\n");
            printf("clBuildProgram return:\n");
            if(err == CL_INVALID_PROGRAM)
                printf("CL_INVALID_PROGRAM\n");
            else if(err == CL_INVALID_VALUE)
                printf("CL_INVALID_VALUE\n");
            else if(err == CL_INVALID_BINARY)
                printf("CL_INVALID_BINARY\n");
            else if(err == CL_INVALID_BUILD_OPTIONS)
                printf("CL_INVALID_BUILD_OPTIONS\n");
            else if(err == CL_INVALID_OPERATION)
                printf("CL_INVALID_OPERATION\n");
            else if(err == CL_COMPILER_NOT_AVAILABLE)
                printf("CL_COMPILER_NOT_AVAILABLE\n");
            else if(err == CL_BUILD_PROGRAM_FAILURE)
                printf("CL_BUILD_PROGRAM_FAILURE\n");
            else if(err == CL_OUT_OF_HOST_MEMORY)
                printf("CL_OUT_OF_HOST_MEMORY\n");
            else
                printf("unrecognized: %d\n", err);

            err = clGetProgramBuildInfo(program, dev, CL_PROGRAM_BUILD_STATUS, 128000*sizeof(char), buffer, &len);
            assert(err == CL_SUCCESS);

            printf("Build Status:\n");
            if(buffer[0] == CL_BUILD_NONE)
                printf("CL_BUILD_NONE\n");
            else if(buffer[0] == CL_BUILD_ERROR)
                printf("CL_BUILD_ERROR\n");
            else if(buffer[0] == CL_BUILD_SUCCESS)
                printf("CL_BUILD_SUCCESS\n");
            else if(buffer[0] == CL_BUILD_IN_PROGRESS)
                printf("CL_BUILD_IN_PROGRESS\n");
            else
                printf("unrecognized\n");

            err = clGetProgramBuildInfo(program, dev, CL_PROGRAM_BUILD_LOG, 128000*sizeof(char), buffer, &len);
            printf("Get Build Info:\n");
            switch (err) {
                case CL_INVALID_DEVICE:
                    printf("CL_INVALID_DEVICE\n"); break;
                case CL_INVALID_VALUE:
                    printf("CL_INVALID_VALUE\n"); break;
                case CL_INVALID_PROGRAM:
                    printf("CL_INVALID_PROGRAM\n"); break;
            }

            printf("Build Info:\n%s\nProgram Source:\n%s\n", buffer, programSrc);

            free(buffer);
            exit(1);
        }

        kernel = clCreateKernel(program, progName, &err);
        assert(err == CL_SUCCESS);

        err = clReleaseProgram(program);
        assert(err == CL_SUCCESS);

        return kernel;
    }

    /**
     * Run the kernel with a default group size and print debug info if
     * profiling is enabled in the queue.
     *
     * @param[in] kern The compiled OpenCL kernel to run.
     * @param[in] numThreads Number of threads to run.
     * @param[in] locSize Size of the local thread group.
     * @return CL_SUCCESS
     */
    cl_int runKern(cl_kernel kern, size_t numThreads, size_t locSize) const
    {
        cl_int err = CL_SUCCESS;
        cl_event ev;
        cl_command_queue cmd_queue = this->cl_cmd_queue_;
        size_t loc_size_arr[3] = {locSize,1,1};
        size_t *loc_size_ptr;

        if (locSize != 0)
            loc_size_ptr = loc_size_arr;
        else
            loc_size_ptr = NULL;

        // Run the calculation by enqueuing it and forcing the
        // command queue to complete the task
        err = clEnqueueNDRangeKernel(cmd_queue, kern, 1, NULL,
                                     &numThreads, loc_size_ptr, 0, NULL, &ev);
        if (err == CL_INVALID_WORK_ITEM_SIZE)
            printf("CL_INVALID_WORK_ITEM_SIZE\n");
        else if (err == CL_INVALID_WORK_GROUP_SIZE)
            printf("CL_INVALID_WORK_GROUP_SIZE\n");
        else if (err == CL_INVALID_GLOBAL_WORK_SIZE)
            printf("CL_INVALID_GLOBAL_WORK_SIZE\n");
        else if (err == CL_INVALID_KERNEL_ARGS)
            printf("CL_INVALID_KERNEL_ARGS\n");
        else if (err == CL_INVALID_WORK_DIMENSION)
            printf("CL_INVALID_WORK_DIMENSION\n");
        else if (err == CL_INVALID_PROGRAM_EXECUTABLE)
            printf("CL_INVALID_PROGRAM_EXECUTABLE\n");
        else if (err == CL_INVALID_KERNEL)
            printf("CL_INVALID_KERNEL\n");
        assert(err == CL_SUCCESS);
        err = clFinish(cmd_queue);
        assert(err == CL_SUCCESS);

        cl_command_queue_properties prop;
        err = clGetCommandQueueInfo(cmd_queue, CL_QUEUE_PROPERTIES, sizeof(prop), &prop, NULL);
        assert(err == CL_SUCCESS);

        // Conditional on profiling enabled in the queue
        if (prop & CL_QUEUE_PROFILING_ENABLE) {
            size_t start_time = 0, end_time;

            err = clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_START,
                                          sizeof(size_t), &start_time, NULL);
            assert(err == CL_SUCCESS);
            err = clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_END,
                                          sizeof(size_t), &end_time, NULL);
            assert(err == CL_SUCCESS);

            err = clReleaseEvent(ev);
            assert(err == CL_SUCCESS);
            double totTime = (end_time-start_time)/1000000000.0;

            printf("NNIndex OpenCL Total Kernel Time:%12.4f\n", totTime);
        }

        return CL_SUCCESS;
    }

    /**
     * Allocate a block of OpenCL device memory to a location, and also allocate
     * the same sized block of pinned memory on the host. The pinned memory
     * makes for good temp memory to format data structures and for faster
     * device-to-host data transfer.
     *
     * @param[in] context The context to use for the allocation.
     * @param[in] sz The size of the allocation in bytes.
     * @param[in] mem_flags Allocate the device memory with these flags. (CL_MEM_READ_ONLY, etc)
     * @param[out] clPtr Pointer to where to store the device cl_mem.
     * @param[out] pinnedWorkCLPtr Pointer to the pinned host cl_mem.
     * @param[out] pinnedWorkPtr Pointer to the pinned host memory region. Cannot be used until the queue is finished.
     */
    template <typename CLAllocType>
    void allocCLDevPinnedWorkMem(cl_context context, size_t sz, cl_mem_flags mem_flags,
                                 cl_mem *clPtr, cl_mem *pinnedWorkCLPtr, CLAllocType **pinnedWorkPtr) const
    {
        cl_int err = CL_SUCCESS;
        assert(sz >= 0);
        assert((*clPtr) == NULL);

        (*clPtr) = clCreateBuffer(context, mem_flags, sz, NULL, &err);
        assert(err == CL_SUCCESS);
        (*pinnedWorkCLPtr) = clCreateBuffer(context, CL_MEM_READ_WRITE | CL_MEM_ALLOC_HOST_PTR, sz, NULL, &err);
        assert(err == CL_SUCCESS);
        (*pinnedWorkPtr) = (CLAllocType *)clEnqueueMapBuffer(this->cl_cmd_queue_, (*pinnedWorkCLPtr), CL_FALSE,
                                                             CL_MAP_READ|CL_MAP_WRITE, 0, sz, 0, NULL, NULL, &err);
        assert(err == CL_SUCCESS);
    }

    /**
     * Free a block of OpenCL memory, if it isn't NULL. Then
     * set it as NULL so no dangling pointers.
     *
     * @param[in] toFree Pointer to the cl_mem region to free.
     */
    inline void freeCLMem(cl_mem *toFree) const
    {
        if (*toFree) {
            cl_int err = clReleaseMemObject(*toFree);
            assert(err == CL_SUCCESS);
            (*toFree) = NULL;
        }
    }

    /**
     * Enable OpenCL with this queue
     */
    cl_command_queue cl_cmd_queue_;

    /**
     * Save the changeable variables when the kernel is built so we know if we
     * need to recompile with new constants
     */
    int cl_kern_max_checks_;
    size_t cl_kern_knn_;

    /**
     * OpenCL kernels are saved here when compiled
     */
    cl_kernel cl_knn_search_kern_;

    bool own_cq_;
};
}

#endif /* FLANN_NN_OPENCL_INDEX_H_ */
#endif /* FLANN_USE_OPENCL */
