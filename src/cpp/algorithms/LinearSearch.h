#ifndef LINEARSEARCH_H
#define LINEARSEARCH_H

#include "NNIndex.h"

class LinearSearch : public NNIndex {
	
	Dataset<float>& dataset;

public:
	
	LinearSearch(Dataset<float>& inputData, Params params) : dataset(inputData)
	{
	}

    const char* name() const
    {
        return "linear";
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
		return 0;
	}

	void buildIndex() 
	{
		/* nothing to do here for linear search */
	}

	void findNeighbors(ResultSet& resultSet, float* vec, Params searchParams) 
	{
		for (int i=0;i<dataset.rows;++i) {
			resultSet.addPoint(dataset[i],i);
		}
	}

    Params estimateSearchParams(float precision, Dataset<float>* testset = NULL)
    {
        Params params;        
        return params;
    }

};

#endif // LINEARSEARCH_H
