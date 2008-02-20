function [index, params, speedup] = fann_build_index(dataset, params)
%NN_BUILD_INDEX  Builds an index for fast approximate nearest neighbors search
%
% [index, params] = nn_build_index(dataset, precision) - Constructs the
% index from the provided 'dataset' and computes the optimal parameters.
% The optimal parameters are computed such that the searches performed with
% this index return the nearest neighbors with a precision given by the
% 'precision' argument (if features beeing searched have a similar
% distribution to the features in the dataset)
%
% index = nn_build_index(dataset, params) - Constructs the index with the
% parameters given in the 'params' structure. 


if (isstruct(params)) 
    algorithm_id = get_algorithm_id(params.algorithm);
    p = [params.checks algorithm_id params.trees params.branching params.iterations];
else
    p = params;
end
[index, p2, speedup] = nearest_neighbors('build_index',dataset,p);

params.checks = p2(1);
params.algorithm = get_algorithm(p2(2));
params.trees = p2(3);
params.branching = p2(4);
params.iterations = p2(5);