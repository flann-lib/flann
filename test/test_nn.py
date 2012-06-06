#!/usr/bin/env python
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
        self.nn = FLANN()

    ################################################################################
    # The typical
    
    def test_nn_2d_10pt_kmeans(self):
        self.__nd_random_test(2, 2, algorithm='kdtree')

    def test_nn_2d_1000pt_kmeans(self):
        self.__nd_random_test(2, 1000, algorithm='kmeans')

    def test_nn_100d_1000pt_kmeans(self):
        self.__nd_random_test(100, 1000, algorithm='kmeans')

    def test_nn_500d_100pt_kmeans(self):
        self.__nd_random_test(500, 100, algorithm='kmeans')

    def test_nn_2d_1000pt_kdtree(self):
        self.__nd_random_test(2, 1000, algorithm='kdtree')

    def test_nn_100d_1000pt_kdtree(self):
        self.__nd_random_test(100, 1000, algorithm='kdtree')

    def test_nn_500d_100pt_kdtree(self):
        self.__nd_random_test(500, 100, algorithm='kdtree')

    def test_nn_2d_1000pt_linear(self):
        self.__nd_random_test(2, 1000, algorithm='linear')

    def test_nn_100d_50pt_linear(self):
        self.__nd_random_test(100, 50, algorithm='linear')


    def test_nn_2d_1000pt_composite(self):
        self.__nd_random_test(2, 1000, algorithm='composite')

    def test_nn_100d_1000pt_composite(self):
        self.__nd_random_test(100, 1000, algorithm='composite')

    def test_nn_500d_100pt_composite(self):
        self.__nd_random_test(500, 100, algorithm='composite')


    def test_nn_multtrees_2d_1000pt_kmeans(self):
        self.__nd_random_test(2, 1000, algorithm='kmeans', trees=8)

    def test_nn_multtrees_100d_1000pt_kmeans(self):
        self.__nd_random_test(100, 1000, algorithm='kmeans', trees=8)

    def test_nn_multtrees_500d_100pt_kmeans(self):
        self.__nd_random_test(500, 100, algorithm='kmeans', trees=8)



    ##########################################################################################
    # Stress it should handle

    def test_nn_stress_1d_1pt_kmeans(self):
        self.__nd_random_test(1, 1, algorithm='kmeans')

    def test_nn_stress_1d_1pt_linear(self):
        self.__nd_random_test(1, 1, algorithm='linear')

    def test_nn_stress_1d_1pt_kdtree(self):
        self.__nd_random_test(1, 1, algorithm='kdtree')

    def test_nn_stress_1d_1pt_composite(self):
        self.__nd_random_test(1, 1, algorithm='composite')

    def __nd_random_test(self, dim, N, type=float32, num_neighbors = 10, **kwargs):
        """
        Make a set of random points, then pass the same ones to the
        query points.  Each point should be closest to itself.
        """
        seed(0)
        x = array(rand(N, dim), dtype=type)
        perm = permutation(N)
        
        idx,dists = self.nn.nn(x, x[perm], **kwargs)
        self.assertTrue(all(idx == perm))

        # Make sure it's okay if we do make all the points equal
        x_mult_nn = concatenate([x for i in range(num_neighbors)])
        nidx,ndists = self.nn.nn(x_mult_nn, x, num_neighbors = num_neighbors, **kwargs)

        correctness = 0.0

        for i in range(N):
            correctness += float(len(set(nidx[i]).intersection([i + n*N for n in range(num_neighbors)])))/num_neighbors

        self.assertTrue(correctness / N >= 0.99,
                     'failed #1: N=%d,correctness=%f' % (N, correctness/N))

        # now what happens if they are slightly off
        x_mult_nn += randn(x_mult_nn.shape[0], x_mult_nn.shape[1])*0.0001/dim
        n2idx,n2dists = self.nn.nn(x_mult_nn, x, num_neighbors = num_neighbors, **kwargs)

        for i in range(N):
            correctness += float(len(set(n2idx[i]).intersection([i + n*N for n in range(num_neighbors)])))/num_neighbors

        self.assertTrue(correctness / N >= 0.99,
                     'failed #2: N=%d,correctness=%f' % (N, correctness/N))
        
if __name__ == '__main__':
    unittest.main()
