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
        data    = rand(5000, 10)
        centers = rand(50, 10)

        labels1 = ut.getLabels(data, centers)

        dm = ut.getDistanceMatrix(data, centers)

        labels2 = ut.getLabels(distance_matrix = dm)
        labels3 = ut.getLabels(data, centers, dm)

        self.assert_(all(labels1 == labels2))
        self.assert_(all(labels2 == labels3))

    def test03_labels_setistrue(self):
        data    = rand(5000, 10)
        centers = rand(50, 10)

        dm = ut.getDistanceMatrix(data, centers)

        setlabels = randint(50, size = 5000)

        for i, j in enumerate(setlabels):
            dm[i, j] = 0

        findlabels = ut.getLabels(distance_matrix = dm)

        self.assert_(all(setlabels == findlabels))
        
    def test04_kMeansObjective(self):
        data    = rand(5000, 10)
        centers = rand(50, 10)

        dm = ut.getDistance2Matrix(data, centers) + 1

        setlabels = randint(50, size = 5000)

        d2 = rand(5000)

        for i, j in enumerate(setlabels):
            dm[i, j] = d2[i]

        self.assertAlmostEqual(ut.getKMeansObjective(distance2_matrix = dm), sum(d2), 8)

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

        self.assertAlmostEqual(ut.getKMeansObjective(distance2_matrix = dm), sum(d2), 5)

if __name__ == '__main__':
    unittest.main()
