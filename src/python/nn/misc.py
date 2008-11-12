
import numpy
from pyflann.pyflann_base import compute_ground_truth_float

def compute_ground_truth(dataset, testset, nn):
    match = numpy.empty((testset.shape[0],nn), dtype=numpy.int32)
    compute_ground_truth_float(dataset,testset,match, 0)
    return match


def swap_array(array1,array2):
    for i in xrange(min(len(array1),len(array2))):
        array1[i],array2[i] = array2[i],array1[i]


def sample_dataset(dataset, count, remove=False):
    index = numpy.arange(dataset.shape[0])
    numpy.random.shuffle(index)    
    sampledset=dataset[index[0:count]]
    
    if remove:
        n = dataset.shape[0]-1
        for i in index[0:count]:
            swap_array(dataset[i],dataset[n])
            n = n-1
    
    return sampledset
