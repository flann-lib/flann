#!/usr/bin/python
import sys
from os.path import *
import os
from pyfann import *
from copy import copy
from numpy import *
from numpy.random import *
import unittest

class Test_PyFANN_nn(unittest.TestCase):

    def setUp(self):
        self.nn = FANN()

    ################################################################################
    # The typical
    
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
    # Autotune stuff

    def test_nn_autotune_2d_1000pt_kmeans(self):
        self.__nd_random_test(2, 1000, algorithm='kmeans', target_precision = 90)

    def test_nn_autotune_100d_1000pt_kmeans(self):
        self.__nd_random_test(100, 1000, algorithm='kmeans', target_precision = 90)

    def test_nn_autotune_500d_100pt_kmeans(self):
        self.__nd_random_test(500, 100, algorithm='kmeans', target_precision = 90)

    def test_nn_autotune_2d_1000pt_kdtree(self):
        self.__nd_random_test(2, 1000, algorithm='kdtree', target_precision = 90)

    def test_nn_autotune_100d_1000pt_kdtree(self):
        self.__nd_random_test(100, 1000, algorithm='kdtree', target_precision = 90)

    def test_nn_autotune_500d_100pt_kdtree(self):
        self.__nd_random_test(500, 100, algorithm='kdtree', target_precision = 90)

    def test_nn_autotune_2d_1000pt_composite(self):
        self.__nd_random_test(2, 1000, algorithm='composite', target_precision = 90)

    def test_nn_autotune_100d_1000pt_composite(self):
        self.__nd_random_test(100, 1000, algorithm='composite', target_precision = 90)

    def test_nn_autotune_500d_100pt_composite(self):
        self.__nd_random_test(500, 100, algorithm='composite', target_precision = 90)


    ##########################################################################################
    # Stress it should handle

    def test_nn_stress_1d_1pt_kmeans_autotune(self):
        self.__nd_random_test(1, 1, algorithm='kmeans', target_precision = 90)

    def test_nn_stress_1d_1pt_kmeans_autotune(self):
        self.__nd_random_test(1, 1, algorithm='linear', target_precision = 90)

    def test_nn_stress_1d_1pt_kdtree_autotune(self):
        self.__nd_random_test(1, 1, algorithm='kdtree', target_precision = 90)

    def test_nn_stress_1d_1pt_composite_autotune(self):
        self.__nd_random_test(1, 1, algorithm='composite', target_precision = 90)

    def test_nn_stress_1d_1pt_kmeans(self):
        self.__nd_random_test(1, 1, algorithm='kmeans')

    def test_nn_stress_1d_1pt_kmeans(self):
        self.__nd_random_test(1, 1, algorithm='linear')

    def test_nn_stress_1d_1pt_kdtree(self):
        self.__nd_random_test(1, 1, algorithm='kdtree')

    def test_nn_stress_1d_1pt_composite(self):
        self.__nd_random_test(1, 1, algorithm='composite')

    def __nd_random_test(self, dim, N, **kwargs):
        """
        Make a set of random points, then pass the same ones to the
        query points.  Each point should be closest to itself.
        """
        seed(0)
        x = rand(N, dim)
        idx = self.nn.nn(x, x, **kwargs)
        self.assert_(all(idx == arange(N, dtype = index_type)))

if __name__ == '__main__':
    unittest.main()
