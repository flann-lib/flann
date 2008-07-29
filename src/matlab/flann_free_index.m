function flann_free_index(index_id)
%FLANN_FREE_INDEX  Deletes the nearest-neighbors index
%
% Deletes an index constructed using flann_build_index.
 
% Marius Muja, January 2008

nearest_neighbors('free_index',index_id);