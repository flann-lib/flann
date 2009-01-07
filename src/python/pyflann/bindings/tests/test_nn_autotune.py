#!/usr/bin/python
import sys
from os.path import *
import os
from pyflann import *
from copy import copy
from numpy import *
from numpy.random import *
import unittest

class Test_PyFLANN_nn(unittest.TestCase):

    def setUp(self):
        self.nn = FLANN(log_level="warning")

    ################################################################################
    # The typical
    
    def test_nn_2d_10pt_kmeans(self):
        self.__nd_random_test_autotune(2, 2, algorithm='kdtree')
        
    def test_nn_autotune_2d_1000pt_kmeans(self):
        self.__nd_random_test_autotune(2, 1000, algorithm='kmeans')

    def test_nn_autotune_100d_1000pt_kmeans(self):
        self.__nd_random_test_autotune(100, 1000, algorithm='kmeans')
    
    def test_nn_autotune_500d_100pt_kmeans(self):
        self.__nd_random_test_autotune(500, 100, algorithm='kmeans')
    
    def test_nn_autotune_2d_1000pt_kdtree(self):
        self.__nd_random_test_autotune(2, 1000, algorithm='kdtree')
    
    def test_nn_autotune_100d_1000pt_kdtree(self):
        self.__nd_random_test_autotune(100, 1000, algorithm='kdtree')
    
    def test_nn_autotune_500d_100pt_kdtree(self):
        self.__nd_random_test_autotune(500, 100, algorithm='kdtree')
    
    def test_nn_autotune_2d_1000pt_composite(self):
        self.__nd_random_test_autotune(2, 1000, algorithm='composite')
    
    def test_nn_autotune_100d_1000pt_composite(self):
        self.__nd_random_test_autotune(100, 1000, algorithm='composite')
    
    def test_nn_autotune_500d_100pt_composite(self):
        self.__nd_random_test_autotune(500, 100, algorithm='composite')
    
    #
    #    ##########################################################################################
    #    # Stress it should handle
    #
    def test_nn_stress_1d_1pt_kmeans_autotune(self):
        self.__nd_random_test_autotune(1, 1, algorithm='kmeans')
    
    def test_nn_stress_1d_1pt_kmeans_autotune(self):
        self.__nd_random_test_autotune(1, 1, algorithm='linear')
    
    def test_nn_stress_1d_1pt_kdtree_autotune(self):
        self.__nd_random_test_autotune(1, 1, algorithm='kdtree')
    
    def test_nn_stress_1d_1pt_composite_autotune(self):
        self.__nd_random_test_autotune(1, 1, algorithm='composite')
    
    

    def __nd_random_test_autotune(self, dim, N, num_neighbors = 10, **kwargs):
        """
        Make a set of random points, then pass the same ones to the
        query points.  Each point should be closest to itself.
        """
        seed(0)
        x = rand(N, dim)
        perm = permutation(N)
        
        idx, dist = self.nn.nn(x, x[perm], **kwargs)
        self.assert_(all(idx == perm))

        for tp in [0.70, 0.80, 0.90, 0.99, 1]:

            # Make sure it's okay if we do make all the points equal
            x_mult_nn = concatenate([x for i in xrange(num_neighbors)])
            #savetxt('dataset_%d_%d.dat'%(N,dim),x_mult_nn);
            #savetxt('testset_%d_%d.dat'%(N,dim),x);
            nidx,ndist = self.nn.nn(x_mult_nn, x, num_neighbors = num_neighbors, target_precision = tp, **kwargs)

            correctness = 0.0

            for i in xrange(N):
                correctness += float(len(set(nidx[i]).intersection([i + n*N for n in xrange(num_neighbors)])))/num_neighbors

            self.assert_(correctness / N >= float(tp-1)/100,
                         'failed #1: targ_prec=%f, N=%d,correctness=%f' % (tp, N, correctness/N))

            # now what happens if they are slightly off
            x_mult_nn += randn(x_mult_nn.shape[0], x_mult_nn.shape[1])*0.00001/dim
            n2idx,n2dist = self.nn.nn(x_mult_nn, x, num_neighbors = num_neighbors, **kwargs)

            for i in xrange(N):
                correctness += float(len(set(n2idx[i]).intersection([i + n*N for n in xrange(num_neighbors)])))/num_neighbors

            self.assert_(correctness / N >= float(tp-1)/100,
                         'failed #2: targ_prec=%f, N=%d,correctness=%f' % (tp, N, correctness/N))

        
if __name__ == '__main__':
    unittest.main()
