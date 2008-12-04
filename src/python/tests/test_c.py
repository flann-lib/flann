from numpy import *
from numpy.random import *
from pyflann import *

x = array([[10,20],[11,89]])
dup = 10
xc = concatenate(tuple([x for i in xrange(dup)]))
xc += randn(xc.shape[0], xc.shape[1])*0.000001/2

flann = FLANN()

centroids = flann.kmeans(xc[permutation(len(xc))], 2, centers_init = "random", random_seed=3)

print centroids
