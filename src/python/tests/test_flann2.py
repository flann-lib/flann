from pyflann import *
from numpy import *
from numpy.random import *


print "Load data"
path = '../../data/';
dataset = loadtxt(path+'dataset.dat');
print dataset.shape
testset = loadtxt(path+'testset.dat');
print testset.shape
matches = loadtxt(path+'match.dat', dtype=int32);


flann = FLANN()
#params = flann.build_index(dataset, target_precision=0.9, log_level = "info");
#print params

#nn_indices = flann.nn_index(testset,5, checks=params["checks"]);
#print nn_indices

params = flann.nn(dataset, testset, precision=0.9, target_precision=0.9, log_level="info");
print params

import time
start = time.clock()
nn_indices = flann.nn_index(testset,5, checks=params["checks"]);

print "It took", (time.clock()-start)

#checks, time = test_with_precision(flann, dataset, testset, matches, 0.8)

print "Checks: ", checks
print "Time: ", time
