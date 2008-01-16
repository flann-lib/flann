/*********************************************************************
	Module: simulator.c (A MATLAB C module that performs an RPC call)
	Author: Marius Muja (2007)
	Input: a real matrix
	Output: a real row vector
***********************************************************************/

#include "mex.h"
#include "nn.h"
#include <stdio.h>

extern "C" {
int __data_start;  // hack to solve unresolved symbol problem
}

void mexFunction(int nOutArray, mxArray *OutArray[], int nInArray, const mxArray *InArray[])
{
	/* Check if there is one Input matrix     */ 
	if(nInArray != 4) {
		mexErrMsgTxt("Incorrect number of input arguments");
	}

	/* Check if there is one Output matrix     */ 
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
	
	
	const mxArray* paramMat = InArray[3];

	double* pp = mxGetPr(paramMat);

	Parameters p;
	p.checks=(int)pp[0];
	p.algo = (Algorithm)pp[1];
	p.trees=(int)pp[2];
	p.branching=(int)pp[3];
	p.iterations=(int)pp[4];
	
	static int started = 0;
	if (!started) {
   		nn_init();
   		started = 1;
   	}
	find_nearest_neighbors(dataset,dcount,length,testset, tcount, result, nn, 95, &p);
		
	/* Allocate memory for Output Matrix */ 
	OutArray[0] = mxCreateDoubleMatrix(tcount, nn, mxREAL);	
	
/* 	OutArray[0] = mxCreateDoubleMatrix(dcount, length, mxREAL);	*/
	/* Get pointer to Output matrix */ 
	double* pOut = mxGetPr(OutArray[0]);
	
	for (int i=0;i<tcount*nn;++i) {
		pOut[i] = result[i];
	}
/*	for (int i=0;i<dcount*length;++i) {
		pOut[i] = dataset[i];
	}*/
}
