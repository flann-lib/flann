function result = flann_search(data, testset, n, search_params)
%NN_SEARCH  Fast approximate nearest neighbors search
%
% Performs a fast approximate nearest neighbor search using an
% index constructed using flann_build_index or directly a 
% dataset.

% Marius Muja, January 2008


if (size(data,1)==1 && size(data,2)==1)
	% we already have an index
	if ~isfield(search_params,'checks')
		error('Missing the "checks" parameter');
	end
	result = nearest_neighbors('index_find_nn', data, testset, n, search_params.checks);
else
	% create the index now
	if isfield(search_params,'target_precision')
		build_weigh = 0.01;
		if isfield(search_params,'build_weigh')
			build_weigh = search_params.build_weigh;
		end
		memory_weigh = 0;
		if isfield(search_params,'memory_weigh')
			memory_weigh = search_params.memory_weigh;
		end
		p = [-1 search_params.target_precision build_weigh memory_weigh];
	elseif isfield(search_params,'algorithm')
		if strcmp(search_params.algorithm,'kdtree') && ~isfield(search_params,'trees')
			error('Missing "trees" parameter');
		end
		if strcmp(search_params.algorithm,'kmeans') && ~isfield(search_params,'branching')
			error('Missing "branching" parameter');
		end
		if strcmp(search_params.algorithm,'kmeans') && ~isfield(search_params,'iterations')
			error('Missing "iterations" parameter');
		end
		
		trees = -1;
		if isfield(search_params,'trees')
			trees = search_params.trees;
		end
		branching = -1;
		if isfield(search_params,'branching')
			branching = search_params.branching;
		end
		iterations = -2;
		if isfield(search_params,'iterations')
			iterations = search_params.iterations;
		end
		checks = 1;
		if isfield(search_params,'checks')
			checks = search_params.checks;
		end
		
		algorithm_id = get_algorithm_id(search_params.algorithm);
	
		p = [checks algorithm_id trees branching iterations];
	else
		error('Incomplete "build_params" structure');
	end
	result = nearest_neighbors('find_nn', data, testset, n, p);
end
