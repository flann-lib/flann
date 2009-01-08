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
