"""
This module provides some basic utilites to help with FLANN.
Currently, the utils focus on the clustering solutions, but more
features are planned.
"""

import numpy, sys
from numpy import int32, float32, float64, uint32, bool_

try:
    import utils_c as __uc
except ImportError, ie:
    sys.stderr.write('\n\nError importing required utils_c module. \n')
    sys.stderr.write('Please create it by executing create_utils_c.py.\n\n')
    raise ie


def __ensure2dArray(a):
    return a

    if not isinstance(a, numpy.ndarray): 
        a = numpy.ndarray(a)

    assert(a.ndim == 2)
        
    return a


def getDistanceMatrix(data, centers):
    """
    For N data points and K centers, returns the the N x K matrix
    (numpy array) of the distances from points to centroids.  This
    calculates the distances using the L2 norm.
    """

    return numpy.sqrt(getDistance2Matrix(data, centers))

def getDistance2Matrix(data, centers):
    """
    For N data points and K centers, returns the the N x K matrix
    (numpy array) of the distances from points to centroids.  This
    calculates the distances using the squared L2 norm.
    """

    centers = __ensure2dArray(centers)
    data = __ensure2dArray(data)

    assert(centers.shape[1] == data.shape[1])
    
    if centers.dtype == float32 and data.dtype == float32:

        dm = numpy.empty( (data.shape[0], centers.shape[0]), dtype=float32)
        __uc.dists2_float(data, centers, dm)
    else:
        sys.stdout.flush()
        dm = numpy.empty( (data.shape[0], centers.shape[0]), dtype=float64)

        __uc.dists2_double(float64(data), float64(centers), dm)

    return dm



def getLabels(data=None, centers=None, distance_matrix = None):
    """
    For N data points and K clusters, returns a length N array of
    values between 0 and K giving the labels of each point to the
    clusters.  

    If distance_matrix is given, then that is used to calculate the
    labels.  Otherwise, data and centers are used.

    The former is faster given the distance_matrix, but the latter is
    faster than both calculating the distance matrix and calling this
    function.
    """

    if distance_matrix != None:
        
        distance_matrix = __ensure2dArray(distance_matrix)

        nP, K = distance_matrix.shape

        labels = numpy.empty(nP, dtype=int32)
        
        if distance_matrix.dtype == float64:
            __uc.dist_labels_double(distance_matrix,labels)
        else:
            __uc.dist_labels_float(float32(distance_matrix),labels)

        return labels

    elif data != None and centers != None:
        data = __ensure2dArray(data)
        centers = __ensure2dArray(centers)

        assert(data.shape[1] == centers.shape[1])

        K = len(centers)
        labels = numpy.empty(len(data), dtype=int32)
        
        if data.dtype == float64:
            if centers.dtype == float64:
                __uc.labels_direct_double_double(data, centers, labels)
            else:
                __uc.labels_direct_double_float(data, float32(centers), labels)
        else:
            __uc.labels_direct_float_float(float32(data), float32(centers), labels)
            
        return labels
    else:
        raise TypeError("getLabels(): Insufficient parameters to calculate labels.")


def getKMeansObjective(data=None, centers=None, distance2_matrix=None, labels=None):
    """
    Returns the final value of the kmeans objective function, defined as 
    sum_j sum_{x_i \in C_j} (x_i - \mu_j)^2.

    The objective function can be calculated by three methods (from
    slowest to fastest): data and centers together, by
    distance2_matrix alone, or by distance2_matrix and labels
    together.  The fastest one possible is chosen.
    """

    if distance2_matrix != None:
        distance2_matrix = __ensure2dArray(distance2_matrix)

        if labels != None:
            assert(distance2_matrix.shape[1] == len(labels))
            
            if type(labels) == list:
                labels = numpy.array(labels, dtype = int32)
            else:
                assert(labels.dtype == int32)

            if distance2_matrix.dtype == float64:
                return __uc.kmeansobj_dists_labels_double(distance2_matrix, labels)
            else:
                return __uc.kmeansobj_dists_labels_float(float32(distance2_matrix), labels)
            
        else:
            if distance2_matrix.dtype == float64:
                return __uc.kmeansobj_dists_double(distance2_matrix)
            else:
                return __uc.kmeansobj_dists_float(float32(distance2_matrix))
    elif data != None and centers != None:
        data = __ensure2dArray(data)
        centers = __ensure2dArray(centers)

        if data.dtype == float64:
            if centers.dtype == float64:
                return __uc.kmeansobj_direct_double_double(data, centers)
            else:
                return __uc.kmeansobj_direct_double_float(data, float32(centers))
        else:
            return __uc.kmeansobj_direct_float_float(float32(data), float32(centers))
    else:
        raise TypeError("kMeansObjective(): insufficient parameters to calculate objective value.")


def assignmentMatrix(data = None, centers = None, distance_matrix = None, labels = None, K = None, dtype = bool_):
    """
    Returns a binary 0-1 N x K assignment matrix of type dtype (default = bool_).
    
    The assignment matrix can be calculated by three methods (from
    slowest to fastest): data and centers together, by
    distance2_matrix alone, by labels along, by labels and K, or by distance2_matrix
    and labels together.  The fastest one possible is chosen.  If only
    labels is given, K is chosen to be the maximum value of labels + 1.
    
    """

    if labels != None:
        assert(labels.ndim == 1)
        assert(labels.shape[0] > 0)
    elif distance_matrix != None or (data != None and centers != None):
        labels = getLabels(data, centers, distance_matrix)
    else:
        raise TypeError("assignmentMatrix(): Not enough parameters given to calculate assignment Matrix.")

    if distance_matrix != None:
        distance_matrix = __ensure2dArray(distance_matrix)
        K = distance_matrix.shape[1]
    elif centers != None:
        K = centers.shape[0]
    elif K == None:
        K = labels.max() + 1
    
    am = numpy.zeros( (len(labels), K), dtype = dtype)

    if dtype == bool_:
        __uc.assignment_matrix_bool(labels, am)
    elif dtype == float64:
        __uc.assignment_matrix_double(labels, am)
    elif dtype == float32:
        __uc.assignment_matrix_float(labels, am)
    else:
        am_buf = zeros(length(labels), K, dtype = bool_)
        __uc.assignment_matrix_bool(labels, am_buf)
        am = dtype.type(am_buf)
        
    return am

def getClusterSizes(data = None, centers = None, distance_matrix = None, labels = None, K = None):
    """
    Returns an array of length K that gives the size of the clusters.
    The method can calculate this with any of the following
    combinations of imputs, from slowest to fastest: data and centers,
    distance_matrix, distance_matrix and labels, by labels along, or
    by labels and K together.  The function chooses the fastest
    possible.  If only labels is given, K is calculated to be the
    maximum value of labels + 1.  If K is given, it is up to the user to
    ensure that max(labels) < K.
    """

    if distance_matrix != None:
        distance_matrix = __ensure2dArray(distance_matrix)
        K = distance_matrix.shape[1]
    elif centers != None:
        K = centers.shape[0]
    elif labels != None and K == None:
        K = labels.max() + 1

    counts = numpy.empty(K, dtype=uint32)

    if labels != None:
        __uc.cluster_sizes_labels(labels, counts)

    elif distance_matrix != None:
        __ensure2dArray(distance_matrix)
        
        if distance_matrix.dtype == float64:
            __uc.cluster_sizes_dists_double(distance_matrix, counts)
        else:
            __uc.cluster_sizes_dists_float(float32(distance_matrix), counts)

    elif centers != None and data != None:
        __ensure2dArray(centers)
        __ensure2dArray(data)

        if data.dtype == float64:
            if centers.dtype == float64:
                __uc.cluster_sizes_direct_double_double(data, centers, counts)
            else:
                __uc.cluster_sizes_direct_double_float(data, float32(centers), counts)
        else:
            __uc.cluster_sizes_direct_float_float(float32(data), float32(centers), counts)
    else:
        raise TypeError("getClusterSizes(): insufficient parameters to calculate counts.")
    
    return counts
                          
def hasEmptyCluster(data = None, centers = None, distance_matrix = None, 
                    labels = None, K = None, cluster_sizes = None):
    """
    Returns true if the clustering has one or more centroids with no
    points assigned to them.  The method can calculate this with any
    of the following combinations of imputs, from slowest to fastest:
    data and centers, distance_matrix, labels alone, distance_matrix
    and labels, labels and K, and cluster_sizes.  The function chooses
    the fastest possible.  If only labels is given, K is set to be the
    maximum of labels + 1.  Note that if K is given, it is up to the
    user to ensure that max(labels) < K.  
    """

    if distance_matrix != None:
        distance_matrix = __ensure2dArray(distance_matrix)
        K = distance_matrix.shape[1]
    elif centers != None:
        centers = __ensure2dArray(centers)
        K = centers.shape[0]
    elif labels != None and K == None:
        K = labels.max() + 1

    if cluster_sizes != None:
        return __uc.cluster_completeness_counts(cluster_sizes)

    elif labels != None:
        assert( int(K) == K)

        return __uc.cluster_completeness_labels(labels, K)

    elif distance_matrix != None:
        if distance_matrix.dtype == float64:
            return __uc.cluster_completeness_dists_double(distance_matrix)
        else:
            return __uc.cluster_completeness_dists_float(float32(distance_matrix))

    elif centers != None and data != None:
        centers = __ensure2dArray(centers)
        data = __ensure2dArray(data)

        if data.dtype == float64:
            if centers.dtype == float64:
                return __uc.cluster_completeness_direct_double_double(data, centers)
            else:
                return __uc.cluster_completeness_direct_double_float(data, float32(centers))
        else:
            return __uc.cluster_completeness_direct_float_float(float32(data), float32(centers))
    else:
        raise TypeError("hasEmptyClusters(): insufficient parameters to calculate.")
    
    
