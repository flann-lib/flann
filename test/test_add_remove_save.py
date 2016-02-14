#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import absolute_import, division, print_function
import os
import pyflann
import numpy as np
import unittest
from os.path import exists, isfile


class Test_PyFlann_add_remove_save(unittest.TestCase):

    def setUp(self):
        pass

    def test_remove_save(self):
        test_remove_save()


def delete_file(fpath):
    if exists(fpath) and isfile(fpath):
        os.remove(fpath)


def test_remove_save():
    """
    References:
        # Logic goes here
        ~/code/flann/src/cpp/flann/algorithms/kdtree_index.h

        ~/code/flann/src/cpp/flann/util/serialization.h
        ~/code/flann/src/cpp/flann/util/dynamic_bitset.h

        # Bindings go here
        ~/code/flann/src/cpp/flann/flann.cpp
        ~/code/flann/src/cpp/flann/flann.h

        # Contains stuff for the flann namespace like flann::log_level
        # Also has Index with
        # Matrix<ElementType> features; SEEMS USEFUL
        ~/code/flann/src/cpp/flann/flann.hpp


        # Wrappers go here
        ~/code/flann/src/python/pyflann/flann_ctypes.py
        ~/code/flann/src/python/pyflann/index.py

        ~/local/build_scripts/flannscripts/autogen_bindings.py
    """
    rng = np.random.RandomState(0)
    vecs = (rng.rand(400, 128) * 255).astype(np.uint8)
    vecs2 = (rng.rand(100, 128) * 255).astype(np.uint8)
    qvecs = (rng.rand(10, 128) * 255).astype(np.uint8)

    delete_file('test1.flann')
    delete_file('test2.flann')
    delete_file('test3.flann')
    delete_file('test4.flann')

    print('\nTest initial save load')
    flann_params = {
        'random_seed': 42,
        #'log_level': 'debug', 'info',
        #'log_level': 4,
        'cores': 1,
        #'log_level': 'debug',
    }

    #pyflann.flann_ctypes.flannlib.flann_log_verbosity(4)

    flann1 = pyflann.FLANN(**flann_params)
    params1 = flann1.build_index(vecs, **flann_params)  # NOQA
    idx1, dist = flann1.nn_index(qvecs, 3)
    flann1.save_index('test1.flann')

    flann1_ = pyflann.FLANN()
    flann1_.load_index('test1.flann', vecs)
    idx1_, dist = flann1.nn_index(qvecs, 3)
    assert np.all(idx1 == idx1_), 'initial save load fail'

    print('\nTEST ADD SAVE LOAD')
    flann2 = flann1
    flann2.add_points(vecs2)
    idx2, dist = flann2.nn_index(qvecs, 3)
    assert np.any(idx2 != idx1), 'something should change'
    flann2.save_index('test2.flann')

    # Load saved data with added vecs
    tmp = flann2.get_indexed_data()
    vecs_combined = np.vstack([tmp[0]] + tmp[1])

    flann2_ = pyflann.FLANN()
    flann2_.load_index('test2.flann', vecs_combined)
    idx2_, dist = flann2_.nn_index(qvecs, 3)
    assert np.all(idx2_ == idx2), 'loading saved added data fails'

    # Load saved data with remoed vecs
    print('\n\n---TEST REMOVE SAVE LOAD')
    flann1 = pyflann.FLANN()  # rebuild flann1
    _params1 = flann1.build_index(vecs, **flann_params)  # NOQA
    print('\n * CHECK NN')
    _idx1, dist = flann1.nn_index(qvecs, 3)
    idx1 = _idx1

    print('\n * REMOVE POINTS')
    remove_idx_list = np.unique(idx1.T[0][0:10])
    flann1.remove_points(remove_idx_list)
    flann3 = flann1
    print('\n * CHECK NN')
    idx3, dist = flann3.nn_index(qvecs, 3)
    assert len(np.intersect1d(idx3.ravel(), remove_idx_list)) == 0, 'points were not removed'
    print('\n * SAVE')
    flann3.save_index('test3.flann')

    HAVE_CLEAN_REMOVED = False
    if HAVE_CLEAN_REMOVED:
        # Have not implemented clean_removed_points yet
        print('\n\n---TEST LOAD SAVED INDEX 0 (with removed points)')
        clean_vecs = np.delete(vecs, remove_idx_list, axis=0)
        flann3.clean_removed_points()
        flann3.save_index('test4.flann')
        flann4 = pyflann.FLANN(**flann_params)
        # THIS CAUSES A SEGFAULT
        flann4.load_index('test4.flann', clean_vecs)
        idx4, dist = flann4.nn_index(qvecs, 3)
        assert np.all(idx4 == idx3), 'load failed'
        print('\nloaded succesfully (WITHOUT THE BAD DATA)')

    print('\n\n---TEST LOAD SAVED INDEX 1 (removed points given to load)')
    flann4 = pyflann.FLANN(**flann_params)
    flann4.load_index('test3.flann', vecs)
    idx4, dist = flann4.nn_index(qvecs, 3)
    assert np.all(idx4 == idx3), 'load failed'
    print('\nloaded succesfully (BUT NEED TO MAINTAIN BAD DATA)')

    TRY_LOAD_WITH_REMOVED = False
    TRY_LOAD_WITH_REMOVED = True
    if TRY_LOAD_WITH_REMOVED:
        print('\n\n---TEST LOAD SAVED INDEX 2 (removed points not given to load)')
        clean_vecs = np.delete(vecs, remove_idx_list, axis=0)
        flann4 = pyflann.FLANN(**flann_params)
        print('\n * CALL LOAD')
        flann4.load_index('test3.flann', clean_vecs)


if __name__ == '__main__':
    r"""
    CommandLine:
        python ~/code/flann/test/test_add_remove_save.py
    """
    test_remove_save()
