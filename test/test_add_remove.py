#!/usr/bin/env python
# -*- coding: utf-8 -*-
import pyflann
import sys
import numpy as np
import unittest

VALID_INT_TYPES = (np.typeDict['int64'],
                   np.typeDict['int32'],
                   np.typeDict['uint8'],
                   np.dtype('int32'),
                   np.dtype('uint8'),
                   np.dtype('int64'),)


def is_int_type(dtype):
    return dtype in VALID_INT_TYPES


def rand_vecs(num, dim, rng=np.random, dtype=np.uint8):
    if is_int_type(dtype):
        return (rng.rand(num, dim) * 255).astype(dtype)
    else:
        return (rng.rand(num, dim)).astype(dtype)


class Test_PyFlann_add_remove(unittest.TestCase):
    def setUp(self):
        pass

    def test_add_loop(self):
        """
        Test add_points using a loop when the added data goes out of scope.
        """
        data_dim = 128
        num_qpts = 100
        num_dpts = 1000
        random_seed = 42
        rng = np.random.RandomState(0)

        dataset = rand_vecs(num_dpts, data_dim, rng)
        testset = rand_vecs(num_qpts, data_dim, rng)

        # Build determenistic flann object
        flann = pyflann.FLANN()
        params = flann.build_index(dataset, algorithm='kdtree', trees=4, random_seed=random_seed)

        # Add points in a loop where new_pts goes out of scope
        num_iters = 100
        for count in range(num_iters):
            new_pts = rand_vecs(200, data_dim, rng)
            flann.add_points(new_pts, 2)

        # query to ensure that at least some of the new points are in the results
        num_extra = 200
        num_neighbs = num_dpts + num_extra
        result1, _ = flann.nn_index(testset, num_neighbs, checks=params['checks'])
        self.assertTrue((result1 > num_dpts).sum() >= num_qpts * num_extra, 'at least some of the returned points should be from the added set')

    def test_add(self):
        """
        Test simple case of add_points
        """
        data_dim = 128
        num_dpts = 1000
        num_qpts = 100
        num_neighbs = 5
        random_seed = 42
        rng = np.random.RandomState(0)

        dataset = rand_vecs(num_dpts, data_dim, rng)
        testset = rand_vecs(num_qpts, data_dim, rng)
        # Build determenistic flann object
        flann = pyflann.FLANN()
        params = flann.build_index(dataset, algorithm='kdtree', trees=4, random_seed=random_seed)

        # check nearest neighbor search before add, should be all over the place
        result1, _ = flann.nn_index(testset, num_neighbs, checks=params['checks'])

        # Add points
        flann.add_points(testset, 2)

        # check nearest neighbor search after add
        result2, _ = flann.nn_index(testset, num_neighbs, checks=params['checks'])

        #print('Neighbor results should be between %d and %d' % (num_dpts, num_dpts + num_qpts))
        self.assertTrue(np.all(result2.T[0] >= num_dpts), 'new points should be found first')
        self.assertTrue((result2.T[1] == result1.T[0]).sum() > result1.shape[0] / 2, 'most old points should be found next')

    def test_remove(self):
        """
        Test simple case of remove points
        """
        data_dim = 128
        num_dpts = 1000
        num_neighbs = 5
        random_seed = 42
        rng = np.random.RandomState(0)
        dataset = rand_vecs(num_dpts, data_dim, rng)
        rng = np.random.RandomState(0)

        # Build determenistic flann object
        flann = pyflann.FLANN()
        params = flann.build_index(dataset, algorithm='kdtree', trees=4, random_seed=random_seed)

        # check nearest neighbor search before add, should be all over the place
        result1, _ = flann.nn_index(dataset, num_neighbs, checks=params['checks'])

        data_ids = np.arange(0, dataset.shape[0])

        check1 = result1.T[0] == data_ids
        self.assertTrue(np.all(check1), 'self query should result in consecutive results')

        # Remove half of the data points
        for id_ in range(0, num_dpts, 2):
            flann.remove_point(id_)

        result2, _ = flann.nn_index(dataset, num_neighbs, checks=params['checks'])

        check2_odd = result2.T[0][1::2] == data_ids[1::2]
        check2_even = result2.T[0][0::2] == data_ids[0::2]
        self.assertTrue(np.all(check2_odd), 'unremoved points should have unchanged neighbors')
        self.assertTrue(not np.any(check2_even), 'removed points should have different neighbors')

    def test_used_memory(self):
        """
        Simple test to make sure the used_memory binding works
        """
        data_dim = 128
        num_dpts = 1000
        num_qpts = 100
        num_neighbs = 5
        random_seed = 42
        rng = np.random.RandomState(0)

        dataset = rand_vecs(num_dpts, data_dim, rng)
        testset = rand_vecs(num_qpts, data_dim, rng)
        # Build determenistic flann object
        flann = pyflann.FLANN()
        params = flann.build_index(dataset, algorithm='kdtree', trees=4, random_seed=random_seed)

        # check nearest neighbor search before add, should be all over the place
        result1, _ = flann.nn_index(testset, num_neighbs, checks=params['checks'])

        prev_index_memory = flann.used_memory()
        prev_data_memory = flann.used_memory_dataset()

        # Add points
        flann.add_points(testset, 2)

        # check memory after add points
        post_index_memory = flann.used_memory()
        post_data_memory = flann.used_memory_dataset()

        index_memory_diff = post_index_memory - prev_index_memory
        data_memory_diff = post_data_memory - prev_data_memory

        self.assertTrue(index_memory_diff > 0, 'add points should increase memory usage')
        self.assertTrue(data_memory_diff > 0, 'add points should increase memory usage')


if __name__ == '__main__':
    """
    CommandLine:
        python test/test_add_remove.py
    """
    unittest.main()
