function result = nn_find(data, testset, n, params)
%NN_FIND  Find the approximate nearest neighbors
%

if isstruct(params)
    algorithm_id = get_algorithm_id(params.algorithm);
    p = [params.checks algorithm_id params.trees params.branching params.iterations];
else
    p = params;
end

if (size(data,1)==1 && size(data,2)==1)
    result = nearest_neighbors('index_find_nn', data, testset', n, p)';
else
    result = nearest_neighbors('find_nn', data', testset', n, p)';
end