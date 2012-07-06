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
        self.nn = FLANN(log_level="warning")

    ################################################################################
    # The typical
    
    def test_nn_2d_10pt(self):
        self.__nd_random_test_autotune(2, 2)
        
    def test_nn_autotune_2d_1000pt(self):
        self.__nd_random_test_autotune(2, 1000)

    def test_nn_autotune_100d_1000pt(self):
        self.__nd_random_test_autotune(100, 1000)
    
    def test_nn_autotune_500d_100pt(self):
        self.__nd_random_test_autotune(500, 100)
    
    #
    #    ##########################################################################################
    #    # Stress it should handle
    #
    def test_nn_stress_1d_1pt_kmeans_autotune(self):
        self.__nd_random_test_autotune(1, 1)
    
    def __ensure_list(self,arg):
        if type(arg)!=list:
            return [arg]
        else:
            return arg


    def __nd_random_test_autotune(self, dim, N, num_neighbors = 1, **kwargs):
        """
        Make a set of random points, then pass the same ones to the
        query points.  Each point should be closest to itself.
        """
        seed(0)
        x = rand(N, dim)
        xq = rand(N, dim)
        perm = permutation(N)

        # compute ground truth nearest neighbors
        gt_idx, gt_dist = self.nn.nn(x,xq, 
                algorithm='linear', 
                num_neighbors=num_neighbors)
        
        for tp in [0.70, 0.80, 0.90]:
            nidx,ndist = self.nn.nn(x, xq, 
                    algorithm='autotuned', 
                    sample_fraction=1.0, 
                    num_neighbors = num_neighbors, 
                    target_precision = tp, checks=-2, **kwargs)

            correctness = 0.0
            for i in range(N):
                l1 = self.__ensure_list(nidx[i])
                l2 = self.__ensure_list(gt_idx[i])
                correctness += float(len(set(l1).intersection(l2)))/num_neighbors
            correctness /= N
            self.assertTrue(correctness >= tp*0.9,
                         'failed #1: targ_prec=%f, N=%d,correctness=%f' % (tp, N, correctness))
        
if __name__ == '__main__':
    unittest.main()
