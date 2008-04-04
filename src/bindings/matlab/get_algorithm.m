function algorithm = get_algorithm(algorithm_id)

algos = { 'linear', 'kdtree', 'kmeans', 'composite' };
algorithm = algos(algorithm_id+1);

