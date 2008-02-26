#!/usr/bin/python
import sys
from os.path import *
from pyfann import *
import os
from index_type import index_type
from copy import copy
from numpy import *
from numpy.random import *
import unittest

class Test_PyFANN_clustering(unittest.TestCase):

    def setUp(self):
        self.nn = FANN()

    ################################################################################

    def test_Rand(self):
        x = rand(100, 10000)
        nK = 10
        centroids = self.nn.kmeans(x, nK)
        self.assert_(len(centroids) == nK)
        

    def test2d_small(self):
        self.__nd_random_clustering_test(2,2)

    def test3d_small(self):
        self.__nd_random_clustering_test(3,3)

    def test4d_small(self):
        self.__nd_random_clustering_test(4,4)

    def test3d_large(self):
        self.__nd_random_clustering_test(3,3, 1000)

    def test10d_large(self):
        self.__nd_random_clustering_test(10,50, 100)

    def test500d(self):
        self.__nd_random_clustering_test(500,10, 25)

    def __nd_random_clustering_test(self, dim, N, dup=1):
        """
        Make a set of random points, then pass the same ones to the
        query points.  Each point should be closest to itself.
        """
        seed(0)
        x = rand(N, dim)
        xc = concatenate(tuple([x for i in xrange(dup)]))

        if dup > 1: xc += randn(xc.shape[0], xc.shape[1])*0.00001/dim

        centroids = self.nn.kmeans(xc[permutation(len(xc))], N, centers_init = "random")
        mindists = array([[ sum((d1-d2)**2) for d1 in x] for d2 in centroids]).min(0)
        for m in mindists: self.assertAlmostEqual(m, 0.0, 2)

        centroids = self.nn.kmeans(xc[permutation(len(xc))], N, centers_init = "gonzales")
        mindists = array([[ sum((d1-d2)**2) for d1 in x] for d2 in centroids]).min(0)
        for m in mindists: self.assertAlmostEqual(m, 0.0, 2)
        
        
if __name__ == '__main__':
    unittest.main()
