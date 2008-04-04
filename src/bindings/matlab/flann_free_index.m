function flann_free_index(index_id)
%NN_FREE_INDEX  Deletes the nearest-neighbors index
%
% nn_free_index(index_id) deletes the index referenced by the 'index_id'
% parameter. This index has to have been constructed by the nn_build_index
% function.

nearest_neighbors('free_index',index_id);