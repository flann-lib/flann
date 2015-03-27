import pyflann
import numpy as np


def add_points_example():
    dataset = np.random.rand(1000, 128)
    testset = np.random.rand(100, 128)
    #testset2 = np.random.rand(100, 128)
    flann = pyflann.FLANN()
    params = flann.build_index(dataset, algorithm="kdtree")
    print('params = ' + str(params))
    result1, dists = flann.nn_index(testset, 5, checks=params["checks"])

    flann.add_points(testset, 2)

    result2, _ = flann.nn_index(testset, 5, checks=params["checks"])

    print("Should be all over the place")
    print(",".join([str(r1[0]) for r1 in result1]))
    print("Should be between 1000 and 1100")
    print(",".join([str(r2[0]) for r2 in result2]))
    assert np.all(result2.T[0] >= 1000), 'new points should be found first'
    assert (result2.T[1] == result1.T[0]).sum() > result1.shape[0] / 2, 'most old points should be found next'

if __name__ == '__main__':
    """
    CommandLine:
        python examples/example.py
    """
    add_points_example()
