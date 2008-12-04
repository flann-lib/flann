

from numpy import *
from numpy.random import *
from pyflann import *


flann = FLANN(log_level="info")

N,dim = 10000,50
x = random((N,dim))
y = random((1000,dim))

params = flann.build_index(x,target_precision=0.9)
print params
neighbors = flann.nn_index(y,1,**params)
