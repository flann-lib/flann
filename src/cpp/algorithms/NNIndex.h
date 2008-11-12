#ifndef NNINDEX_H
#define NNINDEX_H

#include "common.h"
#include "Dataset.h"

class ResultSet;


/**
 * Nearest-neighbor index base class 
 */
class NNIndex 
{
public:

    virtual ~NNIndex() {};
    
	/**
		Method responsible with building the index.
	*/
	virtual void buildIndex() = 0;

	/**
		Method that searches for NN
	*/
	virtual void findNeighbors(ResultSet& resultSet, float* vec, Params searchParams) = 0;
	
	/**
		Number of features in this index.
	*/
	virtual int size() const = 0;
	
	/**
		The length of each vector in this index.
	*/
	virtual int veclen() const = 0;
	
	/**
	 The amount of memory (in bytes) this index uses.
	*/
 	virtual int usedMemory() const = 0;

    /**
    * Algorithm name
    */
    virtual const char* name() const = 0;


    /**
      Estimates the search parameters required in order to get a certain precision.
      If testset is not given it uses cross-validation.
    */
    virtual Params estimateSearchParams(float precision, Dataset<float>* testset = NULL) = 0;

};

#endif //NNINDEX_H
