#!/usr/bin/python
import sys
from os.path import *
from pyflann import *
from pyflann.utils import *
import os
from pyflann.index_type import index_type
from copy import copy
from numpy import *
from numpy.random import *
import unittest, time

class Test_PyFLANN_clustering(unittest.TestCase):

    def setUp(self):
        self.nn = FLANN()

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
        self.__nd_random_clustering_test(10,2,10)

    def test500d(self):
        self.__nd_random_clustering_test(500,2, 10)

    def __nd_random_clustering_test(self, dim, N, dup=1):
        """
        Make a set of random points, then pass the same ones to the
        query points.  Each point should be closest to itself.
        """
        seed(0)
        x = rand(N, dim)
        xc = concatenate(tuple([x for i in xrange(dup)]))

        if dup > 1: xc += randn(xc.shape[0], xc.shape[1])*0.000001/dim

        centroids = self.nn.kmeans(xc[permutation(len(xc))], N, centers_init = "random", random_seed=3)
        mindists = array([[ sum((d1-d2)**2) for d1 in x] for d2 in centroids]).min(0)
        for m in mindists: self.assertAlmostEqual(m, 0.0, 1)

        centroids = self.nn.kmeans(xc[permutation(len(xc))], N, centers_init = "gonzales", random_seed=2)
        mindists = array([[ sum((d1-d2)**2) for d1 in x] for d2 in centroids]).min(0)
        for m in mindists: self.assertAlmostEqual(m, 0.0, 1)
        

    def testbest_of_n(self):
        data = rand(1000,2) # Random, so we can get a lot of local minima

        cl1 = self.nn.kmeans(data, 50)
        cl2 = self.nn.kmeans(data, 50, best_of_n = 100)

        self.assert_(getKMeansObjective(data, cl1) >= getKMeansObjective(data, cl2))

    def testensure_none_empty(self):

        for i in xrange(100):
            data = rand(1000,2) # Random, so we can get a lot of local minima
            cl2 = self.nn.kmeans(data, 50, ensure_none_empty = True)
            self.assert_(hasEmptyCluster(data, cl2) == False)

    def testrandomnumber_same(self):
        
        data = rand(1000,2) # Random, so we can get a lot of local minima

        rnseed = int(time.time())
        cl1 = self.nn.kmeans(data, 50, random_seed = rnseed)
        cl2 = self.nn.kmeans(data, 50, random_seed = rnseed)

        self.assert_(all(cl1 == cl2))

        cl1 = self.nn.kmeans(data, 50, random_seed = rnseed, best_of_n = 20)
        cl2 = self.nn.kmeans(data, 50, random_seed = rnseed, best_of_n = 20)

        self.assert_(all(cl1 == cl2))

        cl1 = self.nn.kmeans(data, 50, random_seed = rnseed, ensure_none_empty = True)
        cl2 = self.nn.kmeans(data, 50, random_seed = rnseed, ensure_none_empty = True)

        self.assert_(all(cl1 == cl2))

        cl1 = self.nn.kmeans(data, 50, random_seed = rnseed, best_of_n = 20, ensure_none_empty = True)
        cl2 = self.nn.kmeans(data, 50, random_seed = rnseed, best_of_n = 20, ensure_none_empty = True)

        self.assert_(all(cl1 == cl2))

    def testrandnumber_different(self):
        
        data = rand(1000,2) # Random, so we can get a lot of local minima

        rnseed = int(time.time())
        cl1 = self.nn.kmeans(data, 50)
        cl2 = self.nn.kmeans(data, 50)

        self.assert_(any(cl1 != cl2))

        cl1 = self.nn.kmeans(data, 50, best_of_n = 20)
        cl2 = self.nn.kmeans(data, 50, best_of_n = 20)

        self.assert_(any(cl1 != cl2))

        cl1 = self.nn.kmeans(data, 50, ensure_none_empty = True)
        cl2 = self.nn.kmeans(data, 50, ensure_none_empty = True)

        self.assert_(any(cl1 != cl2))

        cl1 = self.nn.kmeans(data, 50, best_of_n = 20, ensure_none_empty = True)
        cl2 = self.nn.kmeans(data, 50, best_of_n = 20, ensure_none_empty = True)

        self.assert_(any(cl1 != cl2))
        

        
if __name__ == '__main__':
    unittest.main()
