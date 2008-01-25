/*********************************************************************
	Module: simulator.c (A MATLAB C module that performs an RPC call)
	Author: Marius Muja (2007)
	Input: a real matrix
	Output: a real row vector
***********************************************************************/

#include "mex.h"
#include "nn.h"
#include <stdio.h>
#include <string.h>

extern "C" {
int __data_start;  // hack to solve unresolved symbol problem
}


void _find_nearest_neighbors(int nOutArray, mxArray *OutArray[], int nInArray, const mxArray *InArray[])
{
	/* Check the number of input arguments */ 
	if(nInArray != 4) {
		mexErrMsgTxt("Incorrect number of input arguments, expecting:\n"
		"dataset, testset, neighbors_number, params");
	}

	/* Check if there is one Output matrix */ 
	if(nOutArray != 1) {
		mexErrMsgTxt("One output required.");
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
	
	if (mxGetM(nnMat)!=1 || mxGetN(nnMat)!=1) {
		mexErrMsgTxt("Number of nearest neighbors should be a scalar.");
	}
	int nn = (int)(*mxGetPr(nnMat));		

	float* dataset = (float*) mxGetData(datasetMat);
	float* testset = (float*) mxGetData(testsetMat);
	int* result = (int*)malloc(tcount*nn*sizeof(int));
	
	
	const mxArray* pMat = InArray[3];

	int pSize = mxGetN(pMat)*mxGetM(pMat);
	if ( pSize>1 && pSize != 5) {
		mexErrMsgTxt("Expecting params in the form: [checks algorithm_id trees branching max_iterations]");
	}
	
	double* pp = mxGetPr(pMat);

	if (pSize==1) { 
		/* pp contains desired precision */
		find_nearest_neighbors(dataset,dcount,length,testset, tcount, result, nn, pp[0], NULL);
	}
	else {
		/* pp contains index & search parameters */
		Parameters p;
		p.checks=(int)pp[0];
		p.algo = (Algorithm)pp[1];
		p.trees=(int)pp[2];
		p.branching=(int)pp[3];
		p.iterations=(int)pp[4];
		find_nearest_neighbors(dataset,dcount,length,testset, tcount, result, nn, -1, &p);			
	}	
		
	/* Allocate memory for Output Matrix */ 
	OutArray[0] = mxCreateDoubleMatrix(tcount, nn, mxREAL);	
	
	/* Get pointer to Output matrix and store result*/ 
	double* pOut = mxGetPr(OutArray[0]);
	for (int i=0;i<tcount*nn;++i) {
		pOut[i] = result[i];
	}
}

void _find_nearest_neighbors_index(int nOutArray, mxArray *OutArray[], int nInArray, const mxArray *InArray[])
{
	/* Check the number of input arguments */ 
	if(nInArray != 4) {
		mexErrMsgTxt("Incorrect number of input arguments");
	}

	/* Check if there is one Output matrix */ 
	if(nOutArray != 1) {
		mexErrMsgTxt("One output required.");
	}
		
	const mxArray* indexMat = InArray[0];
	NN_INDEX indexID = (NN_INDEX) *mxGetPr(indexMat);
	
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
	
	const mxArray* pMat = InArray[3];

	int ppSize = mxGetN(pMat)*mxGetM(pMat);
	double* pp = mxGetPr(pMat);

	find_nearest_neighbors_index(indexID,testset, tcount, result, nn, (int)pp[0]);
		
	/* Allocate memory for Output Matrix */ 
	OutArray[0] = mxCreateDoubleMatrix(tcount, nn, mxREAL);	
	
	/* Get pointer to Output matrix and store result*/ 
	double* pOut = mxGetPr(OutArray[0]);
	for (int i=0;i<tcount*nn;++i) {
		pOut[i] = result[i];
	}
}

static void _build_index(int nOutArray, mxArray *OutArray[], int nInArray, const mxArray *InArray[])
{
	/* Check the number of input arguments */ 
	if(nInArray != 2) {
		mexErrMsgTxt("Incorrect number of input arguments");
	}

	/* Check if there is one Output matrix */ 
	if(nOutArray != 1) {
		mexErrMsgTxt("One output required.");
	}
		
	const mxArray* datasetMat = InArray[0];
	
	if (!mxIsSingle(datasetMat)) {
		mexErrMsgTxt("Need single precision datasets for now...");
	}	 

	int dcount = mxGetN(datasetMat);
	int length = mxGetM(datasetMat);	
	float* dataset = (float*) mxGetData(datasetMat);
	
	const mxArray* pMat = InArray[1];
	int pSize = mxGetN(pMat)*mxGetM(pMat);
	
	if ( pSize>1 && pSize != 5) {
		mexErrMsgTxt("Expecting params in the form: [checks algorithm_id trees branching max_iterations]");
	}
	double* pp = mxGetPr(pMat);

	NN_INDEX indexID;
	if (pSize==1) { 
		/* pp contains desired precision */
		indexID = build_index(dataset,dcount,length, pp[0], NULL);
	}
	else {
		/* pp contains index & search parameters */
		Parameters p;
		p.checks=(int)pp[0];
		p.algo = (Algorithm)pp[1];
		p.trees=(int)pp[2];
		p.branching=(int)pp[3];
		p.iterations=(int)pp[4];
		indexID = build_index(dataset,dcount,length, -1, &p);
	}	
		
	/* Allocate memory for Output Matrix */ 
	OutArray[0] = mxCreateDoubleMatrix(1, 1, mxREAL);	
	
	/* Get pointer to Output matrix and store result*/ 
	double* pOut = mxGetPr(OutArray[0]);
	pOut[0] = indexID;
}

static void _estimate_parameters(int nOutArray, mxArray *OutArray[], int nInArray, const mxArray *InArray[])
{
	/* Check the number of input arguments */ 
	if(nInArray != 2) {
		mexErrMsgTxt("Incorrect number of input arguments, expecting:\n"
		"dataset, target_precision");
	}

	/* Check if there is one Output matrix */ 
	if(nOutArray != 1) {
		mexErrMsgTxt("One output required.");
	}
		
	const mxArray* datasetMat = InArray[0];
	const mxArray* precisionMat = InArray[1];
	
	if (!mxIsSingle(datasetMat)) {
		mexErrMsgTxt("Need single precision datasets for now...");
	}	 

	int dcount = mxGetN(datasetMat);
	int length = mxGetM(datasetMat);
	float* dataset = (float*) mxGetData(datasetMat);
	float target_precision = *mxGetPr(precisionMat);
	
	estimate_index_parameters(dataset, dcount, length, target_precision);


}

static void _free_index(int nOutArray, mxArray *OutArray[], int nInArray, const mxArray *InArray[])
{
	/* Check the number of input arguments */ 
	if(! (nInArray == 1 && (mxGetN(InArray[0])*mxGetM(InArray[0]))==1)) {
		mexErrMsgTxt("Expecting a single scalar argument: the index ID");
	}
	double* indexPtr = mxGetPr(InArray[0]);
	free_index((NN_INDEX)indexPtr[0]);
}

void mexFunction(int nOutArray, mxArray *OutArray[], int nInArray, const mxArray *InArray[])
{
	static int started = 0;
	if (!started) {
   		nn_init();
   		started = 1;
   	}
	
	if(nInArray == 0 || !mxIsChar(InArray[0])) {
		mexErrMsgTxt("Expecting first argument to be one of:\n"
		"find_nn\n"
		"build_index\n"
		"index_find_nn\n"
		"estimate_parameters\n"
		"free_index");
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
	else if (strcmp(selector,"estimate_parameters")==0) {
		_estimate_parameters(nOutArray,OutArray, nInArray-1, InArray+1);
	}
	else if (strcmp(selector,"free_index")==0) {
		_free_index(nOutArray,OutArray, nInArray-1, InArray+1);
	}
	
}
