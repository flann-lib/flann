from pyflann import *
from numpy import *
from numpy.random import *


print "Load data"
path = '../../../data/';
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

params = flann.build_index(dataset,  algorithm="kmeans", branching=17, iterations=0, log_level="info");
print params


checks, time = test_with_precision(flann, dataset, testset, matches, 0.8, 1)

print "Checks: ", checks
print "Time: ", time
