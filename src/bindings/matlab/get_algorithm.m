function algorithm = get_algorithm(algorithm_id)

if algorithm_id == 0
    algorithm = 'linear';
elseif algorithm_id == 1
    algorithm = 'kdtree';
elseif algorithm_id == 2
    algorithm = 'kmeans';
elseif algorithm_id == 3
    algorithm = 'composite';
end