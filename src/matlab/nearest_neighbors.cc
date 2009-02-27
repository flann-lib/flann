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

#include "mex.h"
#include "flann.h"
#include <stdio.h>
#include <string.h>



template <typename T>
static mxArray* to_mx_array(T value)
{
    mxArray* mat = mxCreateDoubleMatrix(1,1,mxREAL);
    double* ptr = mxGetPr(mat);
    *ptr = value;

    return mat;
}

void _find_nearest_neighbors(int nOutArray, mxArray *OutArray[], int nInArray, const mxArray *InArray[])
{
	/* Check the number of input arguments */
	if(nInArray != 4) {
		mexErrMsgTxt("Incorrect number of input arguments, expecting:\n"
		"dataset, testset, nearest_neighbors, params");
	}

	/* Check the number of output arguments */
	if (nOutArray != 1 && nOutArray != 2) {
		mexErrMsgTxt("Incorrect number of outputs.");
	}

	const mxArray* datasetMat = InArray[0];
	const mxArray* testsetMat = InArray[1];

	if (!(mxIsSingle(datasetMat) && mxIsSingle(testsetMat))) {
		mexErrMsgTxt("Need single precision datasets for now...");
	}

	int dcount = mxGetN(datasetMat);
	int length = mxGetM(datasetMat);
	int tcount = mxGetN(testsetMat);

	if (mxGetM(testsetMat) != length) {
		mexErrMsgTxt("Dataset and testset features should have the same size.");
	}

	const mxArray* nnMat = InArray[2];

	if (mxGetM(nnMat)!=1 || mxGetN(nnMat)!=1 || !mxIsNumeric(nnMat)) {
		mexErrMsgTxt("Number of nearest neighbors should be a scalar.");
	}
	int nn = (int)(*mxGetPr(nnMat));

	float* dataset = (float*) mxGetData(datasetMat);
	float* testset = (float*) mxGetData(testsetMat);

	const mxArray* pStruct = InArray[3];

    if (!mxIsStruct(pStruct)) {
        mexErrMsgTxt("Params must be a struct object.");
    }

    // set parameters structure
    FLANNParameters p;
    p.target_precision = (float)*(mxGetPr(mxGetField(pStruct, 0,"target_precision")));
    p.build_weight = (float)*(mxGetPr(mxGetField(pStruct, 0,"build_weight")));
    p.memory_weight = (float)*(mxGetPr(mxGetField(pStruct, 0,"memory_weight")));
    p.sample_fraction = (float)*(mxGetPr(mxGetField(pStruct, 0,"sample_fraction")));
    p.checks = (int)*(mxGetPr(mxGetField(pStruct, 0,"checks")));
    p.algorithm = (flann_algorithm_t)(int)*(mxGetPr(mxGetField(pStruct, 0,"algorithm")));
    p.trees = (int)*(mxGetPr(mxGetField(pStruct, 0,"trees")));
    p.branching = (int)*(mxGetPr(mxGetField(pStruct, 0,"branching")));
    p.iterations = (int)*(mxGetPr(mxGetField(pStruct, 0,"iterations")));
    p.centers_init = (flann_centers_init_t)(int)*(mxGetPr(mxGetField(pStruct, 0,"centers_init")));

    /* get flann parameters */
    p.log_level = (flann_log_level_t)(int)*(mxGetPr(mxGetField(pStruct, 0,"log_level")));
    p.random_seed = (int)*(mxGetPr(mxGetField(pStruct, 0,"random_seed")));
    p.log_destination = NULL;

    int* result = (int*)malloc(tcount*nn*sizeof(int));
    float* dists = (float*)malloc(tcount*nn*sizeof(float));

    /* do the search */
    flann_find_nearest_neighbors(dataset,dcount,length,testset, tcount, result, dists, nn, &p);

    /* Allocate memory for Output Matrix */
    OutArray[0] = mxCreateDoubleMatrix(nn, tcount, mxREAL);

    /* Get pointer to Output matrix and store result*/
    double* pOut = mxGetPr(OutArray[0]);
    for (int i=0;i<tcount*nn;++i) {
        pOut[i] = result[i]+1; // matlab uses 1-based indexing
    }
    free(result);

    if (nOutArray > 1) {
        /* Allocate memory for Output Matrix */
        OutArray[1] = mxCreateDoubleMatrix(nn, tcount, mxREAL);

        /* Get pointer to Output matrix and store result*/
        double* pDists = mxGetPr(OutArray[1]);
        for (int i=0;i<tcount*nn;++i) {
            pDists[i] = dists[i]; // matlab uses 1-based indexing
        }
    }
    free(dists);

	if (nOutArray > 2) {

        const char *fieldnames[] = {"checks", "cb_index", "algorithm", "trees", "branching", "iterations", "centers_init"};

		OutArray[2] = mxCreateStructMatrix(1, 1, sizeof(fieldnames)/sizeof(const char*), fieldnames);

        int field_no = 0;
        mxSetField(OutArray[2], 0,  fieldnames[field_no++], to_mx_array(p.checks));
        mxSetField(OutArray[2], 0,  fieldnames[field_no++], to_mx_array(p.cb_index));
        mxSetField(OutArray[2], 0,  fieldnames[field_no++], to_mx_array(p.algorithm));
        mxSetField(OutArray[2], 0,  fieldnames[field_no++], to_mx_array(p.trees));
        mxSetField(OutArray[2], 0,  fieldnames[field_no++], to_mx_array(p.branching));
        mxSetField(OutArray[2], 0,  fieldnames[field_no++], to_mx_array(p.iterations));
        mxSetField(OutArray[2], 0,  fieldnames[field_no++], to_mx_array(p.centers_init));
	}
}

void _find_nearest_neighbors_index(int nOutArray, mxArray *OutArray[], int nInArray, const mxArray *InArray[])
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
	FLANN_INDEX indexID = *(FLANN_INDEX*)mxGetData(indexMat);

	const mxArray* testsetMat = InArray[1];

	if (!mxIsSingle(testsetMat)) {
		mexErrMsgTxt("Need single precision datasets for now...");
	}

	int tcount = mxGetN(testsetMat);

	const mxArray* nnMat = InArray[2];

	if (mxGetM(nnMat)!=1 || mxGetN(nnMat)!=1) {
		mexErrMsgTxt("Number of nearest neighbors should be a scalar.");
	}
	int nn = (int)(*mxGetPr(nnMat));

	float* testset = (float*) mxGetData(testsetMat);
	int* result = (int*)malloc(tcount*nn*sizeof(int));
    float* dists = (float*)malloc(tcount*nn*sizeof(float));

	const mxArray* pMat = InArray[3];

	int ppSize = mxGetN(pMat)*mxGetM(pMat);
	double* pp = mxGetPr(pMat);

	flann_find_nearest_neighbors_index(indexID,testset, tcount, result, dists, nn, (int)pp[0], NULL);

	/* Allocate memory for Output Matrix */
	OutArray[0] = mxCreateDoubleMatrix(nn, tcount, mxREAL);

	/* Get pointer to Output matrix and store result*/
	double* pOut = mxGetPr(OutArray[0]);
	for (int i=0;i<tcount*nn;++i) {
		pOut[i] = result[i]+1; // matlab uses 1-based indexing
	}
	free(result);
    if (nOutArray > 1) {
        /* Allocate memory for Output Matrix */
        OutArray[1] = mxCreateDoubleMatrix(nn, tcount, mxREAL);

        /* Get pointer to Output matrix and store result*/
        double* pDists = mxGetPr(OutArray[1]);
        for (int i=0;i<tcount*nn;++i) {
            pDists[i] = dists[i]; // matlab uses 1-based indexing
        }
    }
    free(dists);
}

static void _build_index(int nOutArray, mxArray *OutArray[], int nInArray, const mxArray *InArray[])
{
	/* Check the number of input arguments */
	if(nInArray != 2) {
		mexErrMsgTxt("Incorrect number of input arguments");
	}

	/* Check the number of output arguments */
	if (nOutArray == 0 || nOutArray > 3) {
		mexErrMsgTxt("Incorrect number of outputs.");
	}

	const mxArray* datasetMat = InArray[0];

	if (!mxIsSingle(datasetMat)) {
		mexErrMsgTxt("Need single precision datasets for now...");
	}

	int dcount = mxGetN(datasetMat);
	int length = mxGetM(datasetMat);
	float* dataset = (float*) mxGetData(datasetMat);

	const mxArray* pStruct = InArray[1];

	FLANN_INDEX indexID;

    /* get index parameters */
	FLANNParameters p;
    p.target_precision = (float)*(mxGetPr(mxGetField(pStruct, 0,"target_precision")));
    p.build_weight = (float)*(mxGetPr(mxGetField(pStruct, 0,"build_weight")));
    p.memory_weight = (float)*(mxGetPr(mxGetField(pStruct, 0,"memory_weight")));
    p.sample_fraction = (float)*(mxGetPr(mxGetField(pStruct, 0,"sample_fraction")));
    p.checks = (int)*(mxGetPr(mxGetField(pStruct, 0,"checks")));
    p.algorithm = (flann_algorithm_t)(int)*(mxGetPr(mxGetField(pStruct, 0,"algorithm")));
    p.trees = (int)*(mxGetPr(mxGetField(pStruct, 0,"trees")));
    p.branching = (int)*(mxGetPr(mxGetField(pStruct, 0,"branching")));
    p.iterations = (int)*(mxGetPr(mxGetField(pStruct, 0,"iterations")));
    p.centers_init = (flann_centers_init_t)(int)*(mxGetPr(mxGetField(pStruct, 0,"centers_init")));

    /* get flann parameters */
    p.log_level = (flann_log_level_t)(int)*(mxGetPr(mxGetField(pStruct, 0,"log_level")));
    p.random_seed = (int)*(mxGetPr(mxGetField(pStruct, 0,"random_seed")));
    p.log_destination = NULL;

    float speedup = -1;

	indexID = flann_build_index(dataset,dcount,length, &speedup, &p);


    mxClassID classID;
    if (sizeof(FLANN_INDEX)==4) {
        classID = mxUINT32_CLASS;
    }
    else if (sizeof(FLANN_INDEX)==8) {
        classID = mxUINT64_CLASS;
    }

	/* Allocate memory for Output Matrix */
	OutArray[0] = mxCreateNumericMatrix(1, 1, classID, mxREAL);

	/* Get pointer to Output matrix and store result*/
	FLANN_INDEX* pOut = (FLANN_INDEX*)mxGetData(OutArray[0]);
	pOut[0] = indexID;

	if (nOutArray > 1) {
        const char *fieldnames[] = {"checks", "cb_index", "algorithm", "trees", "branching", "iterations", "centers_init"};

        OutArray[1] = mxCreateStructMatrix(1, 1, sizeof(fieldnames)/sizeof(const char*), fieldnames);

        int field_no = 0;
        mxSetField(OutArray[1], 0,  fieldnames[field_no++], to_mx_array(p.checks));
        mxSetField(OutArray[1], 0,  fieldnames[field_no++], to_mx_array(p.cb_index));
        mxSetField(OutArray[1], 0,  fieldnames[field_no++], to_mx_array(p.algorithm));
        mxSetField(OutArray[1], 0,  fieldnames[field_no++], to_mx_array(p.trees));
        mxSetField(OutArray[1], 0,  fieldnames[field_no++], to_mx_array(p.branching));
        mxSetField(OutArray[1], 0,  fieldnames[field_no++], to_mx_array(p.iterations));
        mxSetField(OutArray[1], 0,  fieldnames[field_no++], to_mx_array(p.centers_init));

	}
	if (nOutArray > 2) {
		OutArray[2] = mxCreateDoubleMatrix(1, 1, mxREAL);
		double* pSpeedup = mxGetPr(OutArray[2]);

		*pSpeedup = speedup;

	}

}

static void _free_index(int nOutArray, mxArray *OutArray[], int nInArray, const mxArray *InArray[])
{
	/* Check the number of input arguments */
	if(! (nInArray == 1 && (mxGetN(InArray[0])*mxGetM(InArray[0]))==1)) {
		mexErrMsgTxt("Expecting a single scalar argument: the index ID");
	}
	FLANN_INDEX* indexPtr = (FLANN_INDEX*)mxGetData(InArray[0]);
	flann_free_index(indexPtr[0], NULL);
}

static void _log_level(int nOutArray, mxArray *OutArray[], int nInArray, const mxArray *InArray[])
{
    if (nInArray != 1) {
            mexErrMsgTxt("Incorrect number of input arguments: expecting log_level");
    }

	const mxArray* llMat = InArray[0];

	if (mxGetM(llMat)!=1 || mxGetN(llMat)!=1 || !mxIsNumeric(llMat)) {
		mexErrMsgTxt("Log Level should be a scalar.");
	}
	int log_level = (int)(*mxGetPr(llMat));

	flann_log_verbosity(log_level);

}

static void _set_distance_type(int nOutArray, mxArray *OutArray[], int nInArray, const mxArray *InArray[])
{
    if( (nInArray != 1 || nInArray != 2)) {
            mexErrMsgTxt("Incorrect number of input arguments");
    }

	const mxArray* distMat = InArray[0];

	if (mxGetM(distMat)!=1 || mxGetN(distMat)!=1 || !mxIsNumeric(distMat)) {
		mexErrMsgTxt("Distance type should be a scalar.");
	}
	int distance_type = (int)(*mxGetPr(distMat));

	int order = 0;
	if (nInArray==2) {
		const mxArray* ordMat = InArray[1];
		if (mxGetM(ordMat)!=1 || mxGetN(ordMat)!=1 || !mxIsNumeric(ordMat)) {
			mexErrMsgTxt("Distance order should be a scalar.");
		}

		order = (int)(*mxGetPr(ordMat));
	}

	flann_set_distance_type((flann_distance_t)distance_type, order);
}



void mexFunction(int nOutArray, mxArray *OutArray[], int nInArray, const mxArray *InArray[])
{

    flann_log_verbosity(LOG_ERROR);
    flann_log_destination(NULL);

	if(nInArray == 0 || !mxIsChar(InArray[0])) {
		mexErrMsgTxt("Expecting first argument to be one of:\n"
		"find_nn\n"
		"build_index\n"
		"index_find_nn\n"
		"free_index\n"
		"log_level\n"
		"set_distance_type");
	}

	char selector[64];
	mxGetString(InArray[0],selector,64);

	if (strcmp(selector,"find_nn")==0) {
		_find_nearest_neighbors(nOutArray,OutArray, nInArray-1, InArray+1);
	}
	else if (strcmp(selector,"build_index")==0) {
		_build_index(nOutArray,OutArray, nInArray-1, InArray+1);
	}
	else if (strcmp(selector,"index_find_nn")==0) {
		_find_nearest_neighbors_index(nOutArray,OutArray, nInArray-1, InArray+1);
	}
	else if (strcmp(selector,"free_index")==0) {
		_free_index(nOutArray,OutArray, nInArray-1, InArray+1);
	}
    else if (strcmp(selector,"log_level")==0) {
        _log_level(nOutArray,OutArray, nInArray-1, InArray+1);
    }
    else if (strcmp(selector,"set_distance_type")==0) {
    	_set_distance_type(nOutArray,OutArray, nInArray-1, InArray+1);
    }

}
