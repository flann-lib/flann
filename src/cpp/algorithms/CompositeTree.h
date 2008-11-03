#ifndef COMPOSITETREE_H
#define COMPOSITETREE_H

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
	
	~CompositeTree()
	{
		delete kdtree;
		delete kmeans;
	}


    const char* name() const
    {
        return "composite";
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
	
	
	void findNeighbors(ResultSet& result, float* vec, int maxCheck)
	{
		kmeans->findNeighbors(result,vec,maxCheck);
		kdtree->findNeighbors(result,vec,maxCheck);
		
	}

};

#endif //COMPOSITETREE_H
