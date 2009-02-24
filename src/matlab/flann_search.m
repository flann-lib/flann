%Copyright 2008-2009  Marius Muja (mariusm@cs.ubc.ca). All rights reserved.
%Copyright 2008-2009  David G. Lowe (lowe@cs.ubc.ca). All rights reserved.
%
%THE BSD LICENSE
%
%Redistribution and use in source and binary forms, with or without
%modification, are permitted provided that the following conditions
%are met:
%
%1. Redistributions of source code must retain the above copyright
%   notice, this list of conditions and the following disclaimer.
%2. Redistributions in binary form must reproduce the above copyright
%   notice, this list of conditions and the following disclaimer in the
%   documentation and/or other materials provided with the distribution.
%
%THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
%IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
%OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
%IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
%INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
%NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
%DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
%THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
%(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
%THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

function [indices, dists] = flann_search(data, testset, n, search_params)
%NN_SEARCH  Fast approximate nearest neighbors search
%
% Performs a fast approximate nearest neighbor search using an
% index constructed using flann_build_index or directly a 
% dataset.

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

    if ~isstruct(search_params)
        error('The "search_params" argument must be a structure');
    end

    params = default_params;
    fn = fieldnames(search_params);
    for i = [1:length(fn)],
        name = cell2mat(fn(i));
        params.(name) = search_params.(name);
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

    if (size(data,1)==1 && size(data,2)==1)
        % we already have an index
        [indices,dists] = nearest_neighbors('index_find_nn', data, testset, n, params.checks);
    else
        % create the index now
        [indices,dists] = nearest_neighbors('find_nn', data, testset, n, params);
    end
end
