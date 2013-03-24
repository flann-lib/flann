import pyflann
from pyflann import *
from numpy import *
from numpy.random import *
dataset = rand(1000, 128)
testset = rand(100, 128)
testset2 = rand(100, 128)
flann = FLANN()
params = flann.build_index(dataset, algorithm="kdtree")
print params
result, dists = flann.nn_index(testset,5, checks=params["checks"])

flann.add_points( testset, 2 )

result2, _ = flann.nn_index(testset,5, checks=params["checks"])

print("Should be all over the place")
print(",".join([str(r[0]) for r in result]))
print("Should be between 1000 and 1100")
print(",".join([str(r[0]) for r in result2]))
