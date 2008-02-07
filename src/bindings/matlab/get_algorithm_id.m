function algorithmID = get_algorithm_id(algo)

if strcmp(algo,'linear')
    algorithmID = 0;
elseif strcmp(algo,'kdtree')
    algorithmID = 1;
elseif strcmp(algo,'kmeans') 
    algorithmID = 2;
elseif strcmp(algo,'composite')
    algorithmID = 3;
end