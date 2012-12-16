/*
   Copyright 2008-2009  Marius Muja (mariusm@cs.ubc.ca). All rights reserved.
   Copyright 2008-2009  David G. Lowe (lowe@cs.ubc.ca). All rights reserved.

   THE BSD LICENSE

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:

   1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
   2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

   THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
   IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
   OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
   IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
   INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
   NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
   THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/* Workaround for MSVC 10, Matlab incompatibility */
#if (_MSC_VER >= 1600)
#include <yvals.h>
#define __STDC_UTF_16__
#endif
#include <mex.h>
#include <flann/flann.h>
#include <stdio.h>
#include <string.h>



struct TypedIndex
{
    flann_index_t index;
    flann_datatype_t type;
};


template <typename T>
static mxArray* to_mx_array(T value)
{
    mxArray* mat = mxCreateDoubleMatrix(1,1,mxREAL);
    double* ptr = mxGetPr(mat);
    *ptr = value;

    return mat;
}


static void matlabStructToFlannStruct( const mxArray* mexParams, FLANNParameters& flannParams )
{
    flannParams.algorithm = (flann_algorithm_t)(int)*(mxGetPr(mxGetField(mexParams, 0,"algorithm")));

    // kdtree
    flannParams.trees = (int)*(mxGetPr(mxGetField(mexParams, 0,"trees")));

    // kmeans
    flannParams.branching = (int)*(mxGetPr(mxGetField(mexParams, 0,"branching")));
    flannParams.iterations = (int)*(mxGetPr(mxGetField(mexParams, 0,"iterations")));
    flannParams.centers_init = (flann_centers_init_t)(int)*(mxGetPr(mxGetField(mexParams, 0,"centers_init")));
    flannParams.cb_index = (float)*(mxGetPr(mxGetField(mexParams, 0,"cb_index")));

    // autotuned
    flannParams.target_precision = (float)*(mxGetPr(mxGetField(mexParams, 0,"target_precision")));
    flannParams.build_weight = (float)*(mxGetPr(mxGetField(mexParams, 0,"build_weight")));
    flannParams.memory_weight = (float)*(mxGetPr(mxGetField(mexParams, 0,"memory_weight")));
    flannParams.sample_fraction = (float)*(mxGetPr(mxGetField(mexParams, 0,"sample_fraction")));

    // misc
    flannParams.log_level = (flann_log_level_t)(int)*(mxGetPr(mxGetField(mexParams, 0,"log_level")));
    flannParams.random_seed = (int)*(mxGetPr(mxGetField(mexParams, 0,"random_seed")));

    // search
    flannParams.checks = (int)*(mxGetPr(mxGetField(mexParams, 0,"checks")));
    flannParams.eps = (float)*(mxGetPr(mxGetField(mexParams, 0,"eps")));
    flannParams.sorted = (int)*(mxGetPr(mxGetField(mexParams, 0,"sorted")));
    flannParams.max_neighbors = (int)*(mxGetPr(mxGetField(mexParams, 0,"max_neighbors")));
    flannParams.cores = (int)*(mxGetPr(mxGetField(mexParams, 0,"cores")));
}

static mxArray* flannStructToMatlabStruct( const FLANNParameters& flannParams )
{
    const char* fieldnames[] = {"algorithm", "checks", "eps", "sorted", "max_neighbors", "cores", "trees", "leaf_max_size", "branching", "iterations", "centers_init", "cb_index"};
    mxArray* mexParams = mxCreateStructMatrix(1, 1, sizeof(fieldnames)/sizeof(const char*), fieldnames);

    mxSetField(mexParams, 0, "algorithm", to_mx_array(flannParams.algorithm));
    mxSetField(mexParams, 0, "checks", to_mx_array(flannParams.checks));
    mxSetField(mexParams, 0, "eps", to_mx_array(flannParams.eps));
    mxSetField(mexParams, 0, "sorted", to_mx_array(flannParams.sorted));
    mxSetField(mexParams, 0, "max_neighbors", to_mx_array(flannParams.max_neighbors));
    mxSetField(mexParams, 0, "cores", to_mx_array(flannParams.cores));

    mxSetField(mexParams, 0, "trees", to_mx_array(flannParams.trees));
    mxSetField(mexParams, 0, "leaf_max_size", to_mx_array(flannParams.trees));
    
    mxSetField(mexParams, 0, "branching", to_mx_array(flannParams.branching));
    mxSetField(mexParams, 0, "iterations", to_mx_array(flannParams.iterations));
    mxSetField(mexParams, 0, "centers_init", to_mx_array(flannParams.centers_init));
    mxSetField(mexParams, 0, "cb_index", to_mx_array(flannParams.cb_index));

    return mexParams;
}


static void check_allowed_type(const mxArray* datasetMat)
{
    if (!mxIsSingle(datasetMat) &&
        !mxIsDouble(datasetMat) &&
        !mxIsUint8(datasetMat) &&
        !mxIsInt32(datasetMat)) {
        mexErrMsgTxt("Data type must be floating point single precision, floating point double precision, "
                     "8 bit unsigned integer or 32 bit signed integer");
    }
}


/**
 * Input arguments: dataset (matrix), testset (matrix), n (int),  params (struct)
 * Output arguments: indices(matrix), dists(matrix)
 */
static void _find_nn(int nOutArray, mxArray* OutArray[], int nInArray, const mxArray* InArray[])
{
    /* Check the number of input arguments */
    if(nInArray != 4) {
        mexErrMsgTxt("Incorrect number of input arguments, expecting:\n"
                     "dataset, testset, nearest_neighbors, params");
    }

    /* Check the number of output arguments */
    if(nOutArray > 2) {
        mexErrMsgTxt("One or two outputs required.");
    }
    const mxArray* datasetMat = InArray[0];
    const mxArray* testsetMat = InArray[1];
    check_allowed_type(datasetMat);
    check_allowed_type(testsetMat);

    int dcount = mxGetN(datasetMat);
    int length = mxGetM(datasetMat);
    int tcount = mxGetN(testsetMat);

    if (mxGetM(testsetMat) != length) {
        mexErrMsgTxt("Dataset and testset features should have the same size.");
    }

    const mxArray* nnMat = InArray[2];

    if ((mxGetM(nnMat)!=1)||(mxGetN(nnMat)!=1)|| !mxIsNumeric(nnMat)) {
        mexErrMsgTxt("Number of nearest neighbors should be a scalar.");
    }
    int nn = (int)(*mxGetPr(nnMat));

    const mxArray* pStruct = InArray[3];

    if (!mxIsStruct(pStruct)) {
        mexErrMsgTxt("Params must be a struct object.");
    }

    FLANNParameters p;
    matlabStructToFlannStruct(pStruct, p);

    int* result = (int*)malloc(tcount*nn*sizeof(int));
    float* dists = NULL;
    double* ddists = NULL;

    /* do the search */
    if (mxIsSingle(datasetMat)) {
        float* dataset = (float*) mxGetData(datasetMat);
        float* testset = (float*) mxGetData(testsetMat);
        dists = (float*)malloc(tcount*nn*sizeof(float));
        flann_find_nearest_neighbors_float(dataset,dcount,length,testset, tcount, result, dists, nn, &p);
    }
    else if (mxIsDouble(datasetMat)) {
        double* dataset = (double*) mxGetData(datasetMat);
        double* testset = (double*) mxGetData(testsetMat);
        ddists = (double*)malloc(tcount*nn*sizeof(double));
        flann_find_nearest_neighbors_double(dataset,dcount,length,testset, tcount, result, ddists, nn, &p);
    }
    else if (mxIsUint8(datasetMat)) {
        unsigned char* dataset = (unsigned char*) mxGetData(datasetMat);
        unsigned char* testset = (unsigned char*) mxGetData(testsetMat);
        dists = (float*)malloc(tcount*nn*sizeof(float));
        flann_find_nearest_neighbors_byte(dataset,dcount,length,testset, tcount, result, dists, nn, &p);
    }
    else if (mxIsInt32(datasetMat)) {
        int* dataset = (int*) mxGetData(datasetMat);
        int* testset = (int*) mxGetData(testsetMat);
        dists = (float*)malloc(tcount*nn*sizeof(float));
        flann_find_nearest_neighbors_int(dataset,dcount,length,testset, tcount, result, dists, nn, &p);
    }

    /* Allocate memory for Output Matrix */
    OutArray[0] = mxCreateDoubleMatrix(nn, tcount, mxREAL);

    /* Get pointer to Output matrix and store result */
    double* pOut = mxGetPr(OutArray[0]);
    for (int i=0; i<tcount*nn; ++i) {
        pOut[i] = result[i]+1; // matlab uses 1-based indexing
    }
    free(result);

    if (nOutArray > 1) {
        /* Allocate memory for Output Matrix */
        OutArray[1] = mxCreateDoubleMatrix(nn, tcount, mxREAL);

        /* Get pointer to Output matrix and store result*/
        double* pDists = mxGetPr(OutArray[1]);
        if (dists!=NULL) {
            for (int i=0; i<tcount*nn; ++i) {
                pDists[i] = dists[i];
            }
        }
        if (ddists!=NULL) {
            for (int i=0; i<tcount*nn; ++i) {
                pDists[i] = ddists[i];
            }
        }
    }
    if (dists!=NULL) free(dists);
    if (ddists!=NULL) free(ddists);
}

/**
 * Input arguments: index (pointer), testset (matrix), n (int),  params (struct)
 * Output arguments: indices(matrix), dists(matrix)
 */
static void _index_find_nn(int nOutArray, mxArray* OutArray[], int nInArray, const mxArray* InArray[])
{
    /* Check the number of input arguments */
    if(nInArray != 4) {
        mexErrMsgTxt("Incorrect number of input arguments");
    }
    /* Check if there is one Output matrix */
    if(nOutArray > 2) {
        mexErrMsgTxt("One or two outputs required.");
    }

    const mxArray* indexMat = InArray[0];
    TypedIndex* typedIndex = *(TypedIndex**)mxGetData(indexMat);

    const mxArray* testsetMat = InArray[1];
    check_allowed_type(testsetMat);

    int tcount = mxGetN(testsetMat);

    const mxArray* nnMat = InArray[2];

    if ((mxGetM(nnMat)!=1)||(mxGetN(nnMat)!=1)) {
        mexErrMsgTxt("Number of nearest neighbors should be a scalar.");
    }
    int nn = (int)(*mxGetPr(nnMat));

    int* result = (int*)malloc(tcount*nn*sizeof(int));
    float* dists = NULL;
    double* ddists = NULL;

    const mxArray* pStruct = InArray[3];

    FLANNParameters p;
    matlabStructToFlannStruct(pStruct, p);

    if (mxIsSingle(testsetMat)) {
        if (typedIndex->type != FLANN_FLOAT32) {
            mexErrMsgTxt("Index type must match testset type");
        }
        float* testset = (float*) mxGetData(testsetMat);
        dists = (float*)malloc(tcount*nn*sizeof(float));
        flann_find_nearest_neighbors_index_float(typedIndex->index,testset, tcount, result, dists, nn, &p);
    }
    else if (mxIsDouble(testsetMat)) {
        if (typedIndex->type != FLANN_FLOAT64) {
            mexErrMsgTxt("Index type must match testset type");
        }
        double* testset = (double*) mxGetData(testsetMat);
        ddists = (double*)malloc(tcount*nn*sizeof(double));
        flann_find_nearest_neighbors_index_double(typedIndex->index,testset, tcount, result, ddists, nn, &p);
    }
    else if (mxIsUint8(testsetMat)) {
        if (typedIndex->type != FLANN_UINT8) {
            mexErrMsgTxt("Index type must match testset type");
        }
        unsigned char* testset = (unsigned char*) mxGetData(testsetMat);
        dists = (float*)malloc(tcount*nn*sizeof(float));
        flann_find_nearest_neighbors_index_byte(typedIndex->index,testset, tcount, result, dists, nn, &p);
    }
    else if (mxIsInt32(testsetMat)) {
        if (typedIndex->type != FLANN_INT32) {
            mexErrMsgTxt("Index type must match testset type");
        }
        int* testset = (int*) mxGetData(testsetMat);
        dists = (float*)malloc(tcount*nn*sizeof(float));
        flann_find_nearest_neighbors_index_int(typedIndex->index,testset, tcount, result, dists, nn, &p);
    }

    /* Allocate memory for Output Matrix */
    OutArray[0] = mxCreateDoubleMatrix(nn, tcount, mxREAL);

    /* Get pointer to Output matrix and store result*/
    double* pOut = mxGetPr(OutArray[0]);
    for (int i=0; i<tcount*nn; ++i) {
        pOut[i] = result[i]+1; // matlab uses 1-based indexing
    }
    free(result);
    if (nOutArray > 1) {
        /* Allocate memory for Output Matrix */
        OutArray[1] = mxCreateDoubleMatrix(nn, tcount, mxREAL);

        /* Get pointer to Output matrix and store result*/
        double* pDists = mxGetPr(OutArray[1]);
        if (dists!=NULL) {
            for (int i=0; i<tcount*nn; ++i) {
                pDists[i] = dists[i];
            }
        }
        if (ddists!=NULL) {
            for (int i=0; i<tcount*nn; ++i) {
                pDists[i] = ddists[i];
            }
        }
    }
    if (dists!=NULL) free(dists);
    if (ddists!=NULL) free(ddists);
}


/**
 * Input arguments: dataset (matrix), params (struct)
 * Output arguments: index (pointer to index), params (struct), speedup(double)
 */
static void _build_index(int nOutArray, mxArray* OutArray[], int nInArray, const mxArray* InArray[])
{
    /* Check the number of input arguments */
    if(nInArray != 2) {
        mexErrMsgTxt("Incorrect number of input arguments");
    }
    /* Check the number of output arguments */
    if ((nOutArray == 0)||(nOutArray > 3)) {
        mexErrMsgTxt("Incorrect number of outputs.");
    }
    const mxArray* datasetMat = InArray[0];
    check_allowed_type(datasetMat);

    int dcount = mxGetN(datasetMat);
    int length = mxGetM(datasetMat);


    const mxArray* pStruct = InArray[1];

    /* get index parameters */
    FLANNParameters p;
    matlabStructToFlannStruct(pStruct, p);

    float speedup = -1;

    TypedIndex* typedIndex = new TypedIndex();

    if (mxIsSingle(datasetMat)) {
        float* dataset = (float*) mxGetData(datasetMat);
        typedIndex->index = flann_build_index_float(dataset,dcount,length, &speedup, &p);
        typedIndex->type = FLANN_FLOAT32;
    }
    else if (mxIsDouble(datasetMat)) {
        double* dataset = (double*) mxGetData(datasetMat);
        typedIndex->index = flann_build_index_double(dataset,dcount,length, &speedup, &p);
        typedIndex->type = FLANN_FLOAT64;
    }
    else if (mxIsUint8(datasetMat)) {
        unsigned char* dataset = (unsigned char*) mxGetData(datasetMat);
        typedIndex->index = flann_build_index_byte(dataset,dcount,length, &speedup, &p);
        typedIndex->type = FLANN_UINT8;
    }
    else if (mxIsInt32(datasetMat)) {
        int* dataset = (int*) mxGetData(datasetMat);
        typedIndex->index = flann_build_index_int(dataset,dcount,length, &speedup, &p);
        typedIndex->type = FLANN_INT32;
    }

    mxClassID classID;
    if (sizeof(flann_index_t)==4) {
        classID = mxUINT32_CLASS;
    }
    else if (sizeof(flann_index_t)==8) {
        classID = mxUINT64_CLASS;
    }

    /* Allocate memory for Output Matrix */
    OutArray[0] = mxCreateNumericMatrix(1, 1, classID, mxREAL);

    /* Get pointer to Output matrix and store result*/
    TypedIndex** pOut = (TypedIndex**)mxGetData(OutArray[0]);
    pOut[0] = typedIndex;

    if (nOutArray > 1) {
        OutArray[1] = flannStructToMatlabStruct(p);
    }
    if (nOutArray > 2) {
        OutArray[2] = mxCreateDoubleMatrix(1, 1, mxREAL);
        double* pSpeedup = mxGetPr(OutArray[2]);

        *pSpeedup = speedup;
    }
}

/**
 * Inputs: index (index pointer)
 */
static void _free_index(int nOutArray, mxArray* OutArray[], int nInArray, const mxArray* InArray[])
{
    /* Check the number of input arguments */
    if(!((nInArray == 1)&&((mxGetN(InArray[0])*mxGetM(InArray[0]))==1))) {
        mexErrMsgTxt("Expecting a single scalar argument: the index ID");
    }
    TypedIndex* typedIndex = *(TypedIndex**)mxGetData(InArray[0]);
    if (typedIndex->type==FLANN_FLOAT32) {
        flann_free_index_float(typedIndex->index, NULL);
    }
    else if (typedIndex->type==FLANN_FLOAT64) {
        flann_free_index_double(typedIndex->index, NULL);
    }
    else if (typedIndex->type==FLANN_UINT8) {
        flann_free_index_byte(typedIndex->index, NULL);
    }
    else if (typedIndex->type==FLANN_INT32) {
        flann_free_index_int(typedIndex->index, NULL);
    }
    delete typedIndex;
}

/**
 * Inputs: level
 */
static void _set_log_level(int nOutArray, mxArray* OutArray[], int nInArray, const mxArray* InArray[])
{
    if (nInArray != 1) {
        mexErrMsgTxt("Incorrect number of input arguments: expecting log_level");
    }

    const mxArray* llMat = InArray[0];

    if ((mxGetM(llMat)!=1)||(mxGetN(llMat)!=1)|| !mxIsNumeric(llMat)) {
        mexErrMsgTxt("Log Level should be a scalar.");
    }
    int log_level = (int)(*mxGetPr(llMat));

    flann_log_verbosity(log_level);

}

/**
 * Inputs: type (flann_distance_t), order(int)
 */
static void _set_distance_type(int nOutArray, mxArray* OutArray[], int nInArray, const mxArray* InArray[])
{
    if( ((nInArray != 1)&&(nInArray != 2))) {
        mexErrMsgTxt("Incorrect number of input arguments");
    }

    const mxArray* distMat = InArray[0];

    if ((mxGetM(distMat)!=1)||(mxGetN(distMat)!=1)|| !mxIsNumeric(distMat)) {
        mexErrMsgTxt("Distance type should be a scalar.");
    }
    int distance_type = (int)(*mxGetPr(distMat));

    int order = 0;
    if (nInArray==2) {
        const mxArray* ordMat = InArray[1];
        if ((mxGetM(ordMat)!=1)||(mxGetN(ordMat)!=1)|| !mxIsNumeric(ordMat)) {
            mexErrMsgTxt("Distance order should be a scalar.");
        }

        order = (int)(*mxGetPr(ordMat));
    }
    flann_set_distance_type((flann_distance_t)distance_type, order);
}


/**
 * Inputs: index (index pointer), filename (string)
 */
static void _save_index(int nOutArray, mxArray* OutArray[], int nInArray, const mxArray* InArray[])
{
    /* Check the number of input arguments */
    if(nInArray != 2) {
        mexErrMsgTxt("Incorrect number of input arguments");
    }

    const mxArray* indexMat = InArray[0];
    TypedIndex* typedIndex = *(TypedIndex**)mxGetData(indexMat);

    // get the selector
    if(!mxIsChar(InArray[1])) {
        mexErrMsgTxt("'filename' should be a string");
    }
    char filename[128];
    mxGetString(InArray[1],filename,128);

    if (typedIndex->type==FLANN_FLOAT32) {
        flann_save_index_float(typedIndex->index, filename);
    }
    else if (typedIndex->type==FLANN_FLOAT64) {
        flann_save_index_double(typedIndex->index, filename);
    }
    else if (typedIndex->type==FLANN_UINT8) {
        flann_save_index_byte(typedIndex->index, filename);
    }
    else if (typedIndex->type==FLANN_INT32) {
        flann_save_index_int(typedIndex->index, filename);
    }
}


/**
 * Inputs: filename (string), matrix
 */
static void _load_index(int nOutArray, mxArray* OutArray[], int nInArray, const mxArray* InArray[])
{
    if(nInArray != 2) {
        mexErrMsgTxt("Incorrect number of input arguments");
    }
    // get the selector
    if(!mxIsChar(InArray[0])) {
        mexErrMsgTxt("'filename' should be a string");
    }
    char filename[128];
    mxGetString(InArray[0],filename,128);

    const mxArray* datasetMat = InArray[1];
    check_allowed_type(datasetMat);

    int dcount = mxGetN(datasetMat);
    int length = mxGetM(datasetMat);

    TypedIndex* typedIndex = new TypedIndex();

    if (mxIsSingle(datasetMat)) {
        float* dataset = (float*) mxGetData(datasetMat);
        typedIndex->index = flann_load_index_float(filename, dataset,dcount,length);
        typedIndex->type = FLANN_FLOAT32;
    }
    else if (mxIsDouble(datasetMat)) {
        double* dataset = (double*) mxGetData(datasetMat);
        typedIndex->index = flann_load_index_double(filename, dataset,dcount,length);
        typedIndex->type = FLANN_FLOAT64;
    }
    else if (mxIsUint8(datasetMat)) {
        unsigned char* dataset = (unsigned char*) mxGetData(datasetMat);
        typedIndex->index = flann_load_index_byte(filename, dataset,dcount,length);
        typedIndex->type = FLANN_UINT8;
    }
    else if (mxIsInt32(datasetMat)) {
        int* dataset = (int*) mxGetData(datasetMat);
        typedIndex->index = flann_load_index_int(filename, dataset,dcount,length);
        typedIndex->type = FLANN_INT32;
    }

    mxClassID classID;
    if (sizeof(flann_index_t)==4) {
        classID = mxUINT32_CLASS;
    }
    else if (sizeof(flann_index_t)==8) {
        classID = mxUINT64_CLASS;
    }

    /* Allocate memory for Output Matrix */
    OutArray[0] = mxCreateNumericMatrix(1, 1, classID, mxREAL);

    /* Get pointer to Output matrix and store result*/
    TypedIndex** pOut = (TypedIndex**)mxGetData(OutArray[0]);
    pOut[0] = typedIndex;
}


struct mexFunctionEntry
{
    const char* name;
    void (* function)(int, mxArray**, int, const mxArray**);
};

static mexFunctionEntry __functionTable[] = {
    { "find_nn", &_find_nn},
    { "build_index", &_build_index},
    { "index_find_nn", &_index_find_nn},
    { "free_index", &_free_index},
    { "save_index", &_save_index},
    { "load_index", &_load_index},
    { "set_log_level", &_set_log_level},
    { "set_distance_type", &_set_distance_type},
};


static void print_selector_error()
{
    char buf[512];
    char* msg = buf;

    sprintf(msg, "%s", "Expecting first argument to be one of: ");
    msg = buf+strlen(buf);
    for (int i=0; i<sizeof(__functionTable)/sizeof(mexFunctionEntry); ++i) {
        if (i!=0) {
            sprintf(msg,", ");
            msg = buf+strlen(buf);
        }
        sprintf(msg, "%s", __functionTable[i].name);
        msg = buf+strlen(buf);
    }

    mexErrMsgTxt(buf);
}


void mexFunction(int nOutArray, mxArray* OutArray[], int nInArray, const mxArray* InArray[])
{
    // get the selector
    if((nInArray == 0)|| !mxIsChar(InArray[0])) {
        print_selector_error();
    }
    char selector[128];
    mxGetString(InArray[0],selector,128);

    // check if function with that name is present
    int idx = 0;
    for (idx = 0; idx<sizeof(__functionTable)/sizeof(mexFunctionEntry); ++idx) {
        if (strcmp(__functionTable[idx].name, selector)==0) {
            break;
        }
    }
    if (idx==sizeof(__functionTable)/sizeof(mexFunctionEntry)) {
        print_selector_error();
    }

    // now call the function
    __functionTable[idx].function(nOutArray,OutArray, nInArray-1, InArray+1);
}
