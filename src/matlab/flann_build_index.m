function [index, params, speedup] = flann_build_index(dataset, build_params)
%FLANN_BUILD_INDEX  Builds an index for fast approximate nearest neighbors search
%
% [index, params, speedup] = flann_build_index(dataset, build_params) - Constructs the
% index from the provided 'dataset' and (optionally) computes the optimal parameters.

% Marius Muja, January 2008



    algos = { 'linear', 'kdtree', 'kmeans', 'composite' };
    center_algos = {'random', 'gonzales', 'kmeanspp' };
    log_levels = {'none', 'fatal', 'error', 'warning', 'info'};
    function value = id2value(array, id)
        value = array(id+1);
    end
    function id = value2id(array,value)
        cnt = 0;
        for item = array,
            if strcmp(value,item)
                id = cnt;
                break;
            end
            cnt  = cnt + 1;
        end            
    end

    default_params = struct('target_precision', -1, 'algorithm', 'kdtree' ,'checks', 32,  'cb_index', 0.4, 'trees', 4, 'branching', 32, 'iterations', 5, 'centers_init', 'random', 'build_weight', 0.01, 'memory_weight', 0, 'sample_fraction', 0.1, 'log_level', 'warning', 'random_seed', 0);

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
