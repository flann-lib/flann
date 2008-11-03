#ifndef NNINDEX_H
#define NNINDEX_H

class ResultSet;

/**
 * Nearest-neighbor index base class 
 */
class NNIndex 
{
public:    
	/**
		Method responsible with building the index.
	*/
	virtual void buildIndex() = 0;

	/**
		Method that searches for NN
	*/
	virtual void findNeighbors(ResultSet& resultSet, float* vec, int maxCheck) = 0;
	
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
};

#endif //NNINDEX_H
