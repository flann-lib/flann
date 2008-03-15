#!/usr/bin/python
import sys
from os.path import *
import pyfann.utils as ut
import os
from pyfann.index_type import index_type
from copy import copy
from numpy import *
from numpy.random import *
import unittest

class Test_PyFANN_utils(unittest.TestCase):

    ################################################################################

    def test01_dist(self):
        self.assert_(all(ut.getDistanceMatrix(array([[0,0], [1,1]], dtype = float32), 
                                              array([[1,0], [0,1]], dtype = float32))
                         == ones( (2,2) )))

        self.assert_(all(ut.getDistanceMatrix(array([[0,0], [1,1]], dtype = float64), 
                                              array([[1,0], [0,1]], dtype = float64))
                         == ones( (2,2) )))

        self.assert_(all(ut.getDistance2Matrix(array([[0,0], [1,1]], dtype = float32), 
                                               array([[1,0], [0,1]], dtype = float32))
                         == ones( (2,2) )))

        self.assert_(all(ut.getDistance2Matrix(array([[0,0], [1,1]], dtype = float64), 
                                               array([[1,0], [0,1]], dtype = float64))
                         == ones( (2,2) )))
        
    def test02_labels_allsame(self):
        data    = float64(rand(5000, 10))
        centers = float64(rand(50, 10))

        labels1 = ut.getLabels(data, centers)

        dm = ut.getDistanceMatrix(data, centers)

        labels2 = ut.getLabels(distance_matrix = dm)
        labels3 = ut.getLabels(data, centers, dm)

        self.assert_(all(labels1 == labels2))
        self.assert_(all(labels2 == labels3))

    def test03_labels_setistrue(self):
        data    = float64(rand(5000, 10))
        centers = float64(rand(50, 10))

        dm = ut.getDistanceMatrix(data, centers)

        setlabels = randint(50, size = 5000)

        for i, j in enumerate(setlabels):
            dm[i, j] = 0

        findlabels = ut.getLabels(distance_matrix = dm)

        self.assert_(all(setlabels == findlabels))
    
    def test03b_assignmentMatrix(self):
        K = 50
        nP = 1000
        data    = float64(rand(nP, 10))
        centers = float64(rand(K, 10))
        dm = ut.getDistance2Matrix(data, centers) + 1
        l = ut.getLabels(distance_matrix = dm)
        absa = ut.assignmentMatrix(data, centers)

        self.assert_(all(absa.shape == (nP, K)))
        self.assert_(all(absa == ut.assignmentMatrix(distance_matrix = dm)))
        self.assert_(all(absa == ut.assignmentMatrix(distance_matrix = dm, labels = l)))
        self.assert_(all(absa == ut.assignmentMatrix(labels = l)))
        self.assert_(all(absa == ut.assignmentMatrix(labels = l, K = K)))

    def test04_kMeansObjective(self):
        data    = float64(rand(5000, 10))
        centers = float64(rand(50, 10))

        dm = ut.getDistance2Matrix(data, centers) + 1

        setlabels = randint(50, size = 5000)

        d2 = float64(rand(5000))

        for i, j in enumerate(setlabels):
            dm[i, j] = d2[i]

        self.assertAlmostEqual(ut.getKMeansObjective(distance2_matrix = dm), sum(d2), 5)

    def test02b_labels_allsame(self):
        data    = float64(rand(5000, 10))
        centers = float32(rand(50, 10))

        labels1 = ut.getLabels(data, centers)

        dm = ut.getDistanceMatrix(data, centers)

        labels2 = ut.getLabels(distance_matrix = dm)
        labels3 = ut.getLabels(data, centers, dm)

        self.assert_(all(labels1 == labels2))
        self.assert_(all(labels2 == labels3))

    def test03b_labels_setistrue(self):
        data    = float64(rand(5000, 10))
        centers = float32(rand(50, 10))

        dm = ut.getDistanceMatrix(data, centers)

        setlabels = randint(50, size = 5000)

        for i, j in enumerate(setlabels):
            dm[i, j] = 0

        findlabels = ut.getLabels(distance_matrix = dm)

        self.assert_(all(setlabels == findlabels))
    
    def test04b_kMeansObjective(self):
        data    = float64(rand(5000, 10))
        centers = float32(rand(50, 10))

        dm = ut.getDistance2Matrix(data, centers) + 1

        setlabels = randint(50, size = 5000)

        d2 = float32(rand(5000))

        for i, j in enumerate(setlabels):
            dm[i, j] = d2[i]

        self.assertAlmostEqual(ut.getKMeansObjective(distance2_matrix = dm)/1000, sum(d2)/1000, 5)

    def test05_labels_allsame_float32(self):
        data    = float32(rand(5000, 10))
        centers = float32(rand(50, 10))

        labels1 = ut.getLabels(data, centers)

        dm = ut.getDistanceMatrix(data, centers)

        labels2 = ut.getLabels(distance_matrix = dm)

        labels3 = ut.getLabels(data, centers, dm)

        self.assert_(all(labels1 == labels2))
        self.assert_(all(labels2 == labels3))

    def test06_labels_setistrue_float32(self):
        data    = float32(rand(5000, 10))
        centers = float32(rand(50, 10))

        dm = ut.getDistanceMatrix(data, centers)

        setlabels = randint(50, size = 5000)

        for i, j in enumerate(setlabels):
            dm[i, j] = 0

        findlabels = ut.getLabels(distance_matrix = dm)

        self.assert_(all(setlabels == findlabels))
        
    def test07_kMeansObjective_float32(self):
        data    = float32(rand(5000, 10))
        centers = float32(rand(50, 10))

        dm = ut.getDistance2Matrix(data, centers) + 1

        setlabels = randint(50, size = 5000)

        d2 = rand(5000)

        for i, j in enumerate(setlabels):
            dm[i, j] = d2[i]

        self.assertAlmostEqual(ut.getKMeansObjective(distance2_matrix = dm)/1000, sum(d2)/1000, 5)

    def test08_clusterCounts_double(self):
        centers = float64(rand(50, 10))
        lb = randint(0, 50, size = 10000)

        X = array([centers[i] for i in lb], dtype = float64)
        
        dm = ut.getDistanceMatrix(X, centers)

        labels = ut.getLabels(distance_matrix = dm)
        
        lb1 = ut.getClusterSizes(X, centers)
        lb2 = ut.getClusterSizes(distance_matrix = dm)
        lb3 = ut.getClusterSizes(labels = labels)
        lb4 = ut.getClusterSizes(labels = labels, K = 50)

        for i in xrange(50):
            c = sum(lb == i)
            self.assert_(lb1[i] == c, 'lb1[i] = %d, true = %d' % (lb1[i], c))
            self.assert_(lb2[i] == c, 'lb2[i] = %d, true = %d' % (lb2[i], c))
            self.assert_(lb3[i] == c, 'lb3[i] = %d, true = %d' % (lb3[i], c))
            self.assert_(lb4[i] == c, 'lb4[i] = %d, true = %d' % (lb4[i], c))

    def test09_clusterCounts_double_float(self):
        centers = float64(rand(50, 10))
        lb = randint(0, 50, size = 10000)

        X = array([centers[i] for i in lb], dtype = float32)
        
        dm = ut.getDistanceMatrix(X, centers)

        labels = ut.getLabels(distance_matrix = dm)
        
        lb1 = ut.getClusterSizes(X, centers)
        lb2 = ut.getClusterSizes(distance_matrix = dm)
        lb3 = ut.getClusterSizes(labels = labels)
        lb4 = ut.getClusterSizes(labels = labels, K = 50)

        for i in xrange(50):
            c = sum(lb == i)
            self.assert_(lb1[i] == c, 'lb1[i] = %d, true = %d' % (lb1[i], c))
            self.assert_(lb2[i] == c, 'lb2[i] = %d, true = %d' % (lb2[i], c))
            self.assert_(lb3[i] == c, 'lb3[i] = %d, true = %d' % (lb3[i], c))
            self.assert_(lb4[i] == c, 'lb4[i] = %d, true = %d' % (lb4[i], c))

    def test10_clusterCounts_float(self):
        centers = float32(rand(50, 10))
        lb = randint(0, 50, size = 10000)

        X = array([centers[i] for i in lb], dtype=float32)
        
        dm = ut.getDistanceMatrix(X, centers)

        labels = ut.getLabels(distance_matrix = dm)
        
        lb1 = ut.getClusterSizes(X, centers)
        lb2 = ut.getClusterSizes(distance_matrix = dm)
        lb3 = ut.getClusterSizes(labels = labels)
        lb4 = ut.getClusterSizes(labels = labels, K = 50)

        for i in xrange(50):
            c = sum(lb == i)
            self.assert_(lb1[i] == c, 'lb1[i] = %d, true = %d' % (lb1[i], c))
            self.assert_(lb2[i] == c, 'lb2[i] = %d, true = %d' % (lb2[i], c))
            self.assert_(lb3[i] == c, 'lb3[i] = %d, true = %d' % (lb3[i], c))
            self.assert_(lb4[i] == c, 'lb4[i] = %d, true = %d' % (lb4[i], c))

    def test11_clusterHasEmpty_double(self):
        centers = float64(rand(50, 10))
        lb = randint(0, 50, size = 10000)

        lb2 = lb.copy()
        lb2[lb == 10] = 9
        
        X1 = array([centers[i] for i in lb],  dtype = float64)
        X2 = array([centers[i] for i in lb2], dtype = float64)

        dm1 = ut.getDistanceMatrix(X1, centers)
        dm2 = ut.getDistanceMatrix(X2, centers)

        labels1 = ut.getLabels(distance_matrix = dm1)
        labels2 = ut.getLabels(distance_matrix = dm2)
        
        counts1 = ut.getClusterSizes(labels = labels1)
        counts2 = ut.getClusterSizes(labels = labels2)

        self.assert_(ut.hasEmptyCluster(X1, centers) == False)
        self.assert_(ut.hasEmptyCluster(X2, centers) == True)

        self.assert_(ut.hasEmptyCluster(distance_matrix = dm1) == False)
        self.assert_(ut.hasEmptyCluster(distance_matrix = dm2) == True)

        self.assert_(ut.hasEmptyCluster(distance_matrix = dm1, labels = labels1) == False)
        self.assert_(ut.hasEmptyCluster(distance_matrix = dm2, labels = labels2) == True)

        self.assert_(ut.hasEmptyCluster(cluster_sizes = counts1) == False)
        self.assert_(ut.hasEmptyCluster(cluster_sizes = counts2) == True)

    def test12_clusterHasEmpty_double_float(self):
        centers = float32(rand(50, 10))
        lb = randint(0, 50, size = 10000)

        lb2 = lb.copy()
        lb2[lb == 10] = 9
        
        X1 = array([centers[i] for i in lb],  dtype = float64)
        X2 = array([centers[i] for i in lb2], dtype = float64)

        dm1 = ut.getDistanceMatrix(X1, centers)
        dm2 = ut.getDistanceMatrix(X2, centers)

        labels1 = ut.getLabels(distance_matrix = dm1)
        labels2 = ut.getLabels(distance_matrix = dm2)
        
        counts1 = ut.getClusterSizes(labels = labels1)
        counts2 = ut.getClusterSizes(labels = labels2)

        self.assert_(ut.hasEmptyCluster(X1, centers) == False)
        self.assert_(ut.hasEmptyCluster(X2, centers) == True)

        self.assert_(ut.hasEmptyCluster(distance_matrix = dm1) == False)
        self.assert_(ut.hasEmptyCluster(distance_matrix = dm2) == True)

        self.assert_(ut.hasEmptyCluster(distance_matrix = dm1, labels = labels1) == False)
        self.assert_(ut.hasEmptyCluster(distance_matrix = dm2, labels = labels2) == True)

        self.assert_(ut.hasEmptyCluster(cluster_sizes = counts1) == False)
        self.assert_(ut.hasEmptyCluster(cluster_sizes = counts2) == True)

    def test13_clusterHasEmpty_double(self):
        centers = float32(rand(50, 10))
        lb = randint(0, 50, size = 10000)

        lb2 = lb.copy()
        lb2[lb == 10] = 9
        
        X1 = array([centers[i] for i in lb],  dtype = float32)
        X2 = array([centers[i] for i in lb2], dtype = float32)

        dm1 = ut.getDistanceMatrix(X1, centers)
        dm2 = ut.getDistanceMatrix(X2, centers)

        labels1 = ut.getLabels(distance_matrix = dm1)
        labels2 = ut.getLabels(distance_matrix = dm2)
        
        counts1 = ut.getClusterSizes(labels = labels1)
        counts2 = ut.getClusterSizes(labels = labels2)

        self.assert_(ut.hasEmptyCluster(X1, centers) == False)
        self.assert_(ut.hasEmptyCluster(X2, centers) == True)

        self.assert_(ut.hasEmptyCluster(distance_matrix = dm1) == False)
        self.assert_(ut.hasEmptyCluster(distance_matrix = dm2) == True)

        self.assert_(ut.hasEmptyCluster(distance_matrix = dm1, labels = labels1) == False)
        self.assert_(ut.hasEmptyCluster(distance_matrix = dm2, labels = labels2) == True)

        self.assert_(ut.hasEmptyCluster(cluster_sizes = counts1) == False)
        self.assert_(ut.hasEmptyCluster(cluster_sizes = counts2) == True)
    

if __name__ == '__main__':
    unittest.main()
