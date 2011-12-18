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

function test_flann
data_path = './';
outcome = {'FAILED!!!!!!!!!', 'PASSED'};

failed = 0;
passed = 0;
cnt = 0;
ok = 1;

    function assert(condition)
        if (~condition)
            ok = 0;
        end
    end

    function run_test(name, test)
        ok = 1;
        cnt = cnt + 1;
        tic;
        fprintf('Test %d: %s...',cnt,name);
        test();
        time = toc;
        if (ok)
            passed = passed + 1;
        else
            failed = failed + 1;
        end
        fprintf('done (%g sec) : %s\n',time,cell2mat(outcome(ok+1)))
    end

    function status
        fprintf('-----------------\n');
        fprintf('Passed: %d/%d\nFailed: %d/%d\n',passed,cnt,failed,cnt);
    end


    dataset = [];
    testset = [];
    function test_load_data
        % load the datasets and testsets
        % use single precision for better memory efficiency
        % store the features one per column because MATLAB
        % uses column major ordering
        % The dataset.dat and testset.dat files can be downloaded from:
        % http://people.cs.ubc.ca/~mariusm/uploads/FLANN/datasets/dataset.dat
        % http://people.cs.ubc.ca/~mariusm/uploads/FLANN/datasets/testset.dat
        dataset = single(load([data_path 'dataset.dat']))';
        testset = single(load([data_path 'testset.dat']))';

        assert(size(dataset,1) == size(testset,1));
    end
    run_test('Load data',@test_load_data);

	match = [];
    dists = [];
    function test_linear_search
        [match,dists] = flann_search(dataset, testset, 10, struct('algorithm','linear'));
        assert(size(match,1) ==10 && size(match,2) == size(testset,2));
    end
    run_test('Linear search',@test_linear_search);

    function test_kdtree_search
        [result, ndists] = flann_search(dataset, testset, 10, struct('algorithm','kdtree',...
                                                          'trees',8,...
                                                          'checks',64));
        n = size(match,2);
        precision = (n-sum(abs(result(1,:)-match(1,:))>0))/n;
        assert(precision>0.9);
        assert(sum(~(match(1,:)-result(1,:)).*(dists(1,:)-ndists(1,:)))==0);
    end
    run_test('kd-tree search',@test_kdtree_search);
    
    function test_kmeans_search
        [result, ndists] = flann_search(dataset, testset, 10, struct('algorithm','kmeans',...
                                                          'branching',32,...
                                                          'iterations',3,...
                                                          'checks',120));
        n = size(match,2);
        precision = (n-sum(abs(result(1,:)-match(1,:))>0))/n;
        assert(precision>0.9);
        assert(sum(~(match(1,:)-result(1,:)).*(dists(1,:)-ndists(1,:)))==0);
    end
    run_test('k-means search',@test_kmeans_search);

    
    
    function test_composite_search
        [result, ndists] = flann_search(dataset, testset, 10, struct('algorithm','composite',...
                                                          'branching',32,...
                                                          'iterations',3,...
                                                          'trees', 1,...
                                                          'checks',64));
        n = size(match,2);
        precision = (n-sum(abs(result(1,:)-match(1,:))>0))/n;
        assert(precision>0.9);
        assert(sum(~(match(1,:)-result(1,:)).*(dists(1,:)-ndists(1,:)))==0);
    end
    run_test('composite search',@test_composite_search);
    
    function test_autotune_search
        [result, ndists] = flann_search(dataset, testset, 10, struct('algorithm','autotuned',...
                                                          'target_precision',0.95,...
                                                          'build_weight',0.01,...
                                                          'memory_weight',0));
        n = size(match,2);
        precision = (n-sum(abs(result(1,:)-match(1,:))>0))/n;
        assert(precision>0.9);
        assert(sum(~(match(1,:)-result(1,:)).*(dists(1,:)-ndists(1,:)))==0);
    end
    run_test('search with autotune',@test_autotune_search);
    
    function test_index_kdtree_search
        [index, search_params ] = flann_build_index(dataset, struct('algorithm','kdtree', 'trees',8,...
                                                          'checks',64));                                             
        [result, ndists] = flann_search(index, testset, 10, search_params);
        n = size(match,2);      
        precision = (n-sum(abs(result(1,:)-match(1,:))>0))/n;
        assert(precision>0.9);
        assert(sum(~(match(1,:)-result(1,:)).*(dists(1,:)-ndists(1,:)))==0);
    end
    run_test('index kd-tree search',@test_index_kdtree_search);
    
    function test_index_kmeans_search
        [index, search_params ] = flann_build_index(dataset, struct('algorithm','kmeans',...
                                                          'branching',32,...
                                                          'iterations',3,...
                                                          'checks',120));                                             
        [result, ndists] = flann_search(index, testset, 10, search_params);
        n = size(match,2);      
        precision = (n-sum(abs(result(1,:)-match(1,:))>0))/n;
        assert(precision>0.9);
        assert(sum(~(match(1,:)-result(1,:)).*(dists(1,:)-ndists(1,:)))==0);
    end
    run_test('index kmeans search',@test_index_kmeans_search);
    
    function test_index_kmeans_search_gonzales
        [index, search_params ] = flann_build_index(dataset, struct('algorithm','kmeans',...
                                                          'branching',32,...
                                                          'iterations',3,...
                                                          'checks',120,...
                                                          'centers_init','gonzales'));                                             
        [result, ndists] = flann_search(index, testset, 10, search_params);
        n = size(match,2);      
        precision = (n-sum(abs(result(1,:)-match(1,:))>0))/n;
        assert(precision>0.9);
        assert(sum(~(match(1,:)-result(1,:)).*(dists(1,:)-ndists(1,:)))==0);
    end
    run_test('index kmeans search gonzales',@test_index_kmeans_search_gonzales);
    
    function test_index_kmeans_search_kmeanspp
        [index, search_params ] = flann_build_index(dataset, struct('algorithm','kmeans',...
                                                          'branching',32,...
                                                          'iterations',3,...
                                                          'checks',120,...
                                                          'centers_init','kmeanspp'));                                             
        [result, ndists] = flann_search(index, testset, 10, search_params);
        n = size(match,2);      
        precision = (n-sum(abs(result(1,:)-match(1,:))>0))/n;
        assert(precision>0.9);
        assert(sum(~(match(1,:)-result(1,:)).*(dists(1,:)-ndists(1,:)))==0);
    end
    run_test('index kmeans search kmeanspp',@test_index_kmeans_search_kmeanspp);

    function test_index_composite_search
        [index, search_params ] = flann_build_index(dataset,struct('algorithm','composite',...
                                                          'branching',32,...
                                                          'iterations',3,...
                                                          'trees', 1,...
                                                          'checks',64));                                             
        [result, ndists] = flann_search(index, testset, 10, search_params);
        n = size(match,2);      
        precision = (n-sum(abs(result(1,:)-match(1,:))>0))/n;
        assert(precision>0.9);
        assert(sum(~(match(1,:)-result(1,:)).*(dists(1,:)-ndists(1,:)))==0);
    end
    run_test('index composite search',@test_index_composite_search);
    
   function test_index_autotune_search
        [index, search_params, speedup ] = flann_build_index(dataset,struct('algorithm','autotuned',...
                                                          'target_precision',0.95,...
                                                          'build_weight',0.01,...
                                                          'memory_weight',0));
        [result, ndists] = flann_search(index, testset, 10, search_params);
        n = size(match,2);      
        precision = (n-sum(abs(result(1,:)-match(1,:))>0))/n;
        assert(precision>0.9);
        assert(sum(~(match(1,:)-result(1,:)).*(dists(1,:)-ndists(1,:)))==0);
    end
    run_test('index autotune search',@test_index_autotune_search);    
    
    status();
end
