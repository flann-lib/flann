from pyflann import *
from numpy import *
from numpy.random import *

dataset = rand(10000, 128)
testset = rand(10000, 128)

flann = FLANN()
speedup = flann.build_index(dataset, precision=0.9);

nn_indices = nn_index(testset,5,);
print result