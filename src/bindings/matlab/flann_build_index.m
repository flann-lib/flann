function [index, params, speedup] = flann_build_index(dataset, build_params)
%FLANN_BUILD_INDEX  Builds an index for fast approximate nearest neighbors search
%
% [index, params, speedup] = flann_build_index(dataset, build_params) - Constructs the
% index from the provided 'dataset' and (optionally) computes the optimal parameters.

% Marius Muja, January 2008


if ~(isstruct(build_params)) 
	error('The "build_params" argument should be a structure');
end

if isfield(build_params,'target_precision')
	build_weigh = 0.01;
	if isfield(build_params,'build_weigh')
		build_weigh = build_params.build_weigh;
	end
	memory_weigh = 0;
	if isfield(build_params,'memory_weigh')
		memory_weigh = build_params.memory_weigh;
	end
    p = [-1 build_params.target_precision build_weigh memory_weigh];
elseif isfield(build_params,'algorithm')
	if strcmp(build_params.algorithm,'kdtree') && ~isfield(build_params,'trees')
		error('Missing "trees" parameter');
	end
	if strcmp(build_params.algorithm,'kmeans') && ~isfield(build_params,'branching')
		error('Missing "branching" parameter');
	end
	if strcmp(build_params.algorithm,'kmeans') && ~isfield(build_params,'iterations')
		error('Missing "iterations" parameter');
	end
	
	trees = -1;
	if isfield(build_params,'trees')
		trees = build_params.trees;
	end
	branching = -1;
	if isfield(build_params,'branching')
		branching = build_params.branching;
	end
	iterations = -2;
	if isfield(build_params,'iterations')
		iterations = build_params.iterations;
	end
	checks = 1;
	if isfield(build_params,'checks')
		checks = build_params.checks;
	end
	
    algorithm_id = get_algorithm_id(build_params.algorithm);

    p = [checks algorithm_id trees branching iterations];
else
    error('Incomplete "build_params" structure');
end
[index, search_params, speedup] = nearest_neighbors('build_index',dataset,p);

params.checks = search_params(1);
params.algorithm = get_algorithm(search_params(2));
params.trees = search_params(3);
params.branching = search_params(4);
params.iterations = search_params(5);