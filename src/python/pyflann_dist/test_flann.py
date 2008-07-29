from pyflann import *
from numpy import *
from numpy.random import *

path = '../data/';
dataset = loadtxt(path+'dataset.dat');
print dataset.shape
testset = loadtxt(path+'testset.dat');
print testset.shape


flann = FLANN()
#params = flann.build_index(dataset, target_precision=0.9, log_level = "info");
#print params

#nn_indices = flann.nn_index(testset,5, checks=params["checks"]);
#print nn_indices

params = flann.build_index(dataset, algorithm="kmeans", branching=32, iterations=7, log_level="info");
print params
nn_indices = flann.nn_index(testset,5, checks=params["checks"]);
print nn_indices
