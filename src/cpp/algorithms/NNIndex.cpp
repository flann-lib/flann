#include "NNIndex.h"
#include <stdio.h>
#include <string.h>




IndexRegistryEntry* register_index_creator(const char* name, IndexCreator creator)
{
    static IndexRegistryEntry* root = NULL;

    if (name==NULL) {
        return root;
    }
    else {
        IndexRegistryEntry* node = new IndexRegistryEntry();
        node->name = name;
        node->creator = creator;
        node->next  = root;
        root = node;
    }
}

IndexRegistryEntry* find_by_name(IndexRegistryEntry* node, const char* name)
{
    
    for (; node!=NULL; node=node->next) {
        if (strcmp(node->name,name)==0) {
            return node;
        }
    }
    return NULL;    
}

NNIndex* create_index(const char* name, Dataset<float>& dataset, Params params)
{
    IndexRegistryEntry* root = register_index_creator(NULL,NULL);
            
    IndexRegistryEntry* node = find_by_name(root,name);
    if (node==NULL) {
        throw FLANNException("Unknown index");
    }
    return node->creator(dataset,params);
}
