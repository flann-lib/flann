#include "NNIndex.h"


namespace {
    map<string,IndexCreator> index_registry;
}

void register_index_creator(const char* name, IndexCreator creator)
{
    index_registry[name] = creator;
}

NNIndex* create_index(const char* name, Dataset<float>& dataset, Params params)
{
    if (index_registry.find(name)==index_registry.end()) {
        throw FLANNException("Unknown index");
    }
    return index_registry[name](dataset,params);
}
