from pyflann import *
from numpy import *
from numpy.random import *

path = './';
dataset = loadtxt(path+'dataset.dat');
print dataset.shape
testset = loadtxt(path+'testset.dat');
print testset.shape


flann = FLANN()
#params = flann.build_index(dataset, target_precision=0.9, log_level = "info");
#print params

#nn_indices = flann.nn_index(testset,5, checks=params["checks"]);
#print nn_indices

params = flann.build_index(dataset, algorithm='linear', trees='8', checks=65536, log_level="info");
print params

import time
start = time.clock()
for i in xrange(10):
    nn_indices = flann.nn_index(testset,5, checks=params["checks"]);
print "It took", (time.clock()-start)/10
print nn_indices
savetxt('matches.dat',nn_indices, fmt="%g");
