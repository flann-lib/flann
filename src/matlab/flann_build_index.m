function [index, params, speedup] = flann_build_index(dataset, build_params)
%FLANN_BUILD_INDEX  Builds an index for fast approximate nearest neighbors search
%
% [index, params, speedup] = flann_build_index(dataset, build_params) - Constructs the
% index from the provided 'dataset' and (optionally) computes the optimal parameters.

% Marius Muja, January 2008

    algos = struct( 'linear', 0, 'kdtree', 1, 'kmeans', 2, 'composite', 3, 'kdtree_single', 4, 'hierarchical', 5, 'lsh', 6, 'saved', 254, 'autotuned', 255 );
    center_algos = struct('random', 0, 'gonzales', 1, 'kmeanspp', 2 );
    log_levels = struct('none', 0, 'fatal', 1, 'error', 2, 'warning', 3, 'info', 4);
    function value = id2value(map, id)
        fields = fieldnames(map);
        for i = 1:length(fields),
            val = cell2mat(fields(i));
            if map.(val) == id
                value = val;
                break;
            end
        end
    end
    function id = value2id(map,value)
        id = map.(value);
    end

    default_params = struct('algorithm', 'kdtree' ,'checks', 32, 'eps', 0.0, 'sorted', 1, 'max_neighbors', -1, 'cores', 1, 'trees', 4, 'branching', 32, 'iterations', 5, 'centers_init', 'random', 'cb_index', 0.4, 'target_precision', 0.9,'build_weight', 0.01, 'memory_weight', 0, 'sample_fraction', 0.1, 'log_level', 'warning', 'random_seed', 0);

    if ~isstruct(build_params)
        error('The "build_params" argument must be a structure');
    end

    params = default_params;
    fn = fieldnames(build_params);
    for i = [1:length(fn)],
        name = cell2mat(fn(i));
        params.(name) = build_params.(name);
    end
    if ~isnumeric(params.algorithm),
        params.algorithm = value2id(algos,params.algorithm);
    end
    if ~isnumeric(params.centers_init),
        params.centers_init = value2id(center_algos,params.centers_init);
    end
    if ~isnumeric(params.log_level),
        params.log_level = value2id(log_levels,params.log_level);
    end

    [index, params, speedup] = nearest_neighbors('build_index',dataset, params);

    if isnumeric(params.algorithm),
        params.algorithm = id2value(algos,params.algorithm);
    end
    if isnumeric(params.centers_init),
        params.centers_init = id2value(center_algos,params.centers_init);
    end
end
