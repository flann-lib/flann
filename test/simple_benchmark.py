#!/usr/bin/env python
# -*- coding: utf-8 -*-
import pyflann
import numpy as np


def rand_vecs(num, dim, rng=np.random, dtype=np.uint8):
    return (rng.rand(num, dim) * 255).astype(dtype)


def run_benchmark():
    import ubelt as ub
    data_dim = 128
    num_dpts = 1000000
    num_qpts = 25000
    num_neighbs = 5
    random_seed = 42
    rng = np.random.RandomState(0)

    dataset = rand_vecs(num_dpts, data_dim, rng)
    testset = rand_vecs(num_qpts, data_dim, rng)
    # Build determenistic flann object
    flann = pyflann.FLANN()
    print('building datset for %d vecs' % (len(dataset)))

    with ub.Timer(label='building kdtrees', verbose=True) as t:
        params = flann.build_index(dataset, algorithm='kdtree', trees=6,
                                   random_seed=random_seed, cores=6)

    print(params)

    qvec_chunks = list(ub.chunks(testset, 1000))
    times = []
    for qvecs in ub.ProgIter(qvec_chunks, label='find nn'):
        with ub.Timer(verbose=0) as t:
            _ = flann.nn_index(testset, num_neighbs)  # NOQA
        times.append(t.ellapsed)
    print(np.mean(times))

if __name__ == '__main__':
    run_benchmark()
