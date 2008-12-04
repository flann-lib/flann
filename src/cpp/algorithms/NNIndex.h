#ifndef NNINDEX_H
#define NNINDEX_H

#include "common.h"
#include "Dataset.h"
#include <map>
#include <string>

// #include <stdio.h>

using namespace std;


#define register_index(index_name,index_class) \
namespace {\
    NNIndex* index_class##_create_index(Dataset<float>& dataset, Params indexParams)\
    {\
        return new index_class(dataset,indexParams);\
    }\
    struct index_class##_index_init {\
    index_class##_index_init() { register_index_creator(index_name,index_class##_create_index); }\
    };\
    index_class##_index_init index_class##_init_var;\
}

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
		Method that searches for nearest-neighbors
	*/
	virtual void findNeighbors(ResultSet& result, float* vec, Params searchParams) = 0;

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



typedef NNIndex* (*IndexCreator)(Dataset<float>& dataset, Params indexParams);

struct IndexRegistryEntry
{
    const char* name;
    IndexCreator creator;
    IndexRegistryEntry* next;
};


IndexRegistryEntry* register_index_creator(const char* name, IndexCreator creator);

NNIndex* create_index(const char* name, Dataset<float>& dataset, Params params);


#endif //NNINDEX_H
