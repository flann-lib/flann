function test_flann
data_path = '../../../data/';
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


    function test_load_data
        % load the datasets and testsets
        % use single precision for better memory efficiency
        % store the features one per column because MATLAB
        % uses column major ordering
        dataset = single(load([data_path 'dataset.dat']))';
        testset = single(load([data_path 'testset.dat']))';

        assert(size(dataset,1) == size(testset,1));
    end
    run_test('Load data',@test_load_data);
    % variables form the test that we want in the outer scope
    dataset;
    testset;

    function test_linear_search
        match = flann_search(dataset, testset, 10, struct('algorithm','linear'));
        assert(size(match,1) ==10 && size(match,2) == size(testset,2));
    end
    run_test('Linear search',@test_linear_search);
    match;

    function test_kdtree_search
        result = flann_search(dataset, testset, 10, struct('algorithm','kdtree',...
                                                          'trees',8,...
                                                          'checks',64));
        n = size(match,2);
        precision = (n-sum(abs(result(1,:)-match(1,:))>0))/n;
        assert(precision>0.9);
    end
    run_test('kd-tree search',@test_kdtree_search);
    
    function test_kmeans_search
        result = flann_search(dataset, testset, 10, struct('algorithm','kmeans',...
                                                          'branching',32,...
                                                          'iterations',3,...
                                                          'checks',16));
        n = size(match,2);
        precision = (n-sum(abs(result(1,:)-match(1,:))>0))/n;
        assert(precision>0.9);
    end
    run_test('k-means search',@test_kmeans_search);

    function test_composite_search
        result = flann_search(dataset, testset, 10, struct('algorithm','composite',...
                                                          'branching',32,...
                                                          'iterations',3,...
                                                          'trees', 1,...
                                                          'checks',16));
        n = size(match,2);
        precision = (n-sum(abs(result(1,:)-match(1,:))>0))/n;
        assert(precision>0.9);
    end
    run_test('composite search',@test_composite_search);
    
    function test_autotune_search
        result = flann_search(dataset, testset, 10, struct('precision',0.95,...
                                                          'build_weight',0.01,...
                                                          'memory_weight',0));
        n = size(match,2);
        precision = (n-sum(abs(result(1,:)-match(1,:))>0))/n;
        assert(precision>0.9);
    end
    run_test('search with autotune',@test_autotune_search);
    
    
    
    
    
    
    status();
end