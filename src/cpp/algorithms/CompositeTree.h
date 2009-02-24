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

#ifndef COMPOSITETREE_H
#define COMPOSITETREE_H

#include "constants.h"
#include "NNIndex.h"


class CompositeTree : public NNIndex
{
	KMeansTree* kmeans;
	KDTree* kdtree;

    Dataset<float>& dataset;


public:

	CompositeTree(Dataset<float>& inputData, Params params) : dataset(inputData)
	{
		kdtree = new KDTree(inputData,params);
		kmeans = new KMeansTree(inputData,params);
	}

	virtual ~CompositeTree()
	{
		delete kdtree;
		delete kmeans;
	}


    flann_algorithm_t getType() const
    {
        return COMPOSITE;
    }


	int size() const
	{
		return dataset.rows;
	}

	int veclen() const
	{
		return dataset.cols;
	}


	int usedMemory() const
	{
		return kmeans->usedMemory()+kdtree->usedMemory();
	}

	void buildIndex()
	{
		logger.info("Building kmeans tree...\n");
		kmeans->buildIndex();
		logger.info("Building kdtree tree...\n");
		kdtree->buildIndex();
	}


	void findNeighbors(ResultSet& result, float* vec, Params searchParams)
	{
		kmeans->findNeighbors(result,vec,searchParams);
		kdtree->findNeighbors(result,vec,searchParams);
	}


    Params estimateSearchParams(float precision, Dataset<float>* testset = NULL)
    {
        Params params;

        return params;
    }


};

register_index(COMPOSITE,CompositeTree)

#endif //COMPOSITETREE_H
