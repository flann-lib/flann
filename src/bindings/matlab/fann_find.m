function result = fann_find(data, testset, n, params)
%NN_FIND  Fast approximate nearest neighbors search
%
%   result = nn_find(dataset,features,n,params)  - performs an approximate
%   nearest neighbors search for each row of FEATURES in the DATASET. For
%   each row of FEATURES it returns the N indices of the nearest neighbor
%   features for the DATASET. 


% Marius Muja, January 2008

if isstruct(params)
    algorithm_id = get_algorithm_id(params.algorithm);
    p = [params.checks algorithm_id params.trees params.branching params.iterations];
else
    p = params;
end

if (size(data,1)==1 && size(data,2)==1)
    result = nearest_neighbors('index_find_nn', data, testset, n, p)';
else
    result = nearest_neighbors('find_nn', data, testset, n, p)';
end