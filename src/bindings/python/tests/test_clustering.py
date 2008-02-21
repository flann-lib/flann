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
        centroids = self.nn.kmeans(x, N)

        x = concatenate(tuple([x for i in xrange(dup)]))

        dists = array([[ sum((d1-d2)**2) for d1 in x] for d2 in centroids])
        
        def isclose(a,b): return(abs(a-b) < 0.0000001)

        self.assert_(all([isclose(d, 0) for d in dists.min(0)]))
        
if __name__ == '__main__':
    unittest.main()
