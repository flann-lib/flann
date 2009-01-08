#include "NNIndex.h"
#include <stdio.h>
#include <string.h>


static IndexRegistryEntry* index_list = NULL;


IndexRegistryEntry* register_index_creator(flann_algorithm_t algorithm, IndexCreator creator)
{
    IndexRegistryEntry* node = new IndexRegistryEntry();
    node->algorithm = algorithm;
    node->creator = creator;
    node->next  = index_list;
    index_list = node;
}

IndexRegistryEntry* find_algorithm(flann_algorithm_t algorithm)
{

    for (IndexRegistryEntry* node = index_list; node!=NULL; node=node->next) {
        if (node->algorithm == algorithm) {
            return node;
        }
    }
    return NULL;
}

NNIndex* create_index(flann_algorithm_t algorithm, Dataset<float>& dataset, Params params)
{
    IndexRegistryEntry* node = find_algorithm(algorithm);
    if (node==NULL) {
    	printf("Algorithm: %d\n", algorithm);
        throw FLANNException("Unknown index type: algorithm is not registered");
    }
    return node->creator(dataset,params);
}
