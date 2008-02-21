from __future__ import with_statement

import sys

try:
    import fann_python_base as fann
except ImportError, ie:
    sys.stderr.write('\nError importing required fann_python_base module \n')
    sys.stderr.write('and/or fann_index_type.\n')
    sys.stderr.write('Please create them by executing create_python_base.py.\n')
    raise ie

from index_type import index_type


import threading
from numpy import float32, float64, int32, matrix, array, empty
from define_params import *
from copy import copy

class FANNException(Exception):
    def __init__(self, *args):
        Exception.__init__(self, *args)

class FANN:
    """
    This class defines a interface to Marius Muja's Fast Nearest
    Neighbor library.  The library uses one of several methods to both
    find nearest neighbors or efficiently cluster data using k-means.

    Imput points can be given as 1d or 2d numpy arrays or matrices,
    lists of lists, or lists.  If they are 1d or straight lists, the
    dimension of the Euclidian space is set to 1.  

    All the computation is done in float32 type, but the imput arrays
    may hold any type that is convertable to float32.
    """
    # This should ensure thread safety; the main thing is the 
    __nn_lock = threading.Lock()

    def __init__(self, **kwargs):
        """
        Constructor for the class and returns a class that can bind to
        the fann libraries.  Any keyword arguments passed to __init__
        override the global defaults given.
        """

        self.__curindex = None
        self.__curindex_data = None
        self.__curindex_data_shape = None
        self.__idx_lock = threading.Lock()
        
        self.__params_lock = threading.Lock()
        self.__param_dict = dict(get_param_args())

        self.setParamDefaults(**kwargs)

    def __del__(self):
        self.delete_index()            

    ################################################################################
    # Bookkeeping type functions

    def setParamDefaults(self, **kwargs):
        """
        Takes a set of keyword arguments and updates the default
        parameter set.  Throws an exception if a kwyword is not a
        possible parameter.
        """
        with self.__params_lock:
            self.__update_param_dict(self.__param_dict, kwargs)

    def getAlgorithmList(self):
        """
        Returns a list of the possible algorithms that can be used for
        doing the nearest neighbor matching.
        """
        return get_algorithms()

    def getDefaults(self):
        """
        Returns a copy of the dictionary of the current default
        arguments.
        """
        with self.__params_lock:
            return copy(self.__param_dict)

        
    ################################################################################
    # actual workhorse functions

    def nn(self, pts, querypts, num_neighbors = 1, **kwargs):
        """
        Returns the num_neighbors nearest points in pts for each point
        in querypts.

        If num_neighbors > 1, the result is a 2d array of indices of
        size len(querypts) x num_neighbors; otherwise, the result is a
        1d array of the indices of the closest points in pts.
        """

        pts      = self.__ensure2dArray(pts)
        querypts = self.__ensure2dArray(querypts)

        npts, dim = pts.shape
        nqpts = querypts.shape[0]

        assert(querypts.shape[1] == dim)
        assert(npts >= num_neighbors)

        pts_flat = self.__getFlattenedArray(pts)
        querypts_flat = self.__getFlattenedArray(querypts)

        result = empty(nqpts * num_neighbors, dtype=index_type)

        params = self.__get_param_arg_list(kwargs)

        with self.__nn_lock:
            fann.find_nn(pts_flat, npts, dim,
                        querypts_flat, nqpts,
                        result, num_neighbors,
                        *params)

        if num_neighbors == 1:
            return result
        else:
            return result.reshape( (nqpts, num_neighbors) )


    def build_index(self, pts, **kwargs):
        """
        This builds and internally stores an index to be used for
        future nearest neighbor matchings.  It erases any previously
        stored indexes, so use multiple instances of this class to
        work with multiple stored indices.  Use nn_index(...) to find
        the nearest neighbors in this index.

        pts is a 2d numpy array or matrix. All the computation is done
        in float32 type, but pts may be any type that is convertable
        to float32.
        """

        pts = self.__ensure2dArray(pts)
        npts, dim = pts.shape
        pts_flat = self.__getFlattenedArray(pts)
        params = self.__get_param_arg_list(kwargs)

        with self.__idx_lock:
            if self.__curindex != None:
                with self.__nn_lock:
                    fann.del_index(self.__curindex)
            
            with self.__nn_lock:
                self.__curindex = fann.make_index(pts_flat, npts, dim, *params)

            self.__curindex_data = pts_flat
            self.__curindex_data_shape = pts.shape

    def nn_index(self, querypts, num_neighbors = 1, **kwargs):
        """
        For each point in querypts, returns the num_neighbors nearest
        points in the index built by calling build_index.

        If num_neighbors > 1, the result is a 2d array of indices of
        size len(querypts) x num_neighbors; otherwise, the result is a
        1d array of the indices of the closest points in pts.
        """

        if self.__curindex == None:
            raise Exception("build_index(...) method not called first or current index deleted.")

        querypts = self.__ensure2dArray(querypts)

        npts, dim = self.__curindex_data_shape
        nqpts = querypts.shape[0]

        assert(querypts.shape[1] == dim)
        assert(npts >= num_neighbors)
        
        querypts_flat = self.__getFlattenedArray(querypts)

        result = empty(nqpts * num_neighbors, dtype=index_type)

        checks = self.__get_one_param(kwargs, "checks")

        with self.__nn_lock:
            fann.find_nn_index(self.__curindex, 
                        querypts_flat, nqpts,
                        result, num_neighbors,
                        checks)

        if num_neighbors == 1:
            return result
        else:
            return result.reshape( (nqpts, num_neighbors) )

    def delete_index(self):
        """
        Deletes the current index and all the data associated with it.
        Useful for freeing up some memory, but not necessary to call
        otherwise.
        """
        
        with self.__idx_lock:
            if self.__curindex != None:
                with self.__nn_lock:
                    fann.del_index(self.__curindex)
                self.__curindex = None
                self.__curindex_data = None
                self.__curindex_data_shape = None

    ##########################################################################################
    # Clustering functions

    def kmeans(self, pts, num_clusters, max_iterations = None, dtype = None):
        """
        Runs kmeans on pts with num_clusters centroids.  Returns a
        numpy array of size num_clusters x dim.  

        If max_iterations is not None, the algorithm terminates after
        the given number of iterations regardless of convergence.  The
        default is to terminate until convergence.

        If dtype is None (the default), the array returned is the same
        type as pts.  Otherwise, the returned array is of type dtype.  
        """
        if int(num_clusters) != num_clusters or num_clusters < 1:
            raise FANNException('num_clusters must be an integer >= 1')
        
        if num_clusters == 1:
            if dtype == None or dtype == pts.dtype:
                return mean(pts, 0).reshape(1, pts.shape[1])
            else:
                return dtype.type(mean(pts, 0).reshape(1, pts.shape[1]))

        return self.hierarchical_kmeans(pts, int(num_clusters), 1, max_iterations, dtype)
        
    def hierarchical_kmeans(self, pts, branch_size, num_branches, max_iterations = None, dtype = None):
        """
        Clusters the data by using multiple runs of kmeans to
        recursively partition the dataset.  The number of resulting
        clusters is given by (branch_size-1)*num_branches+1.
        
        This method can be significantly faster when the number of
        desired clusters is quite large (e.g. a hundred or more).
        Higher branch sizes are slower but may give better results.

        If dtype is None (the default), the array returned is the same
        type as pts.  Otherwise, the returned array is of type dtype.  
        """
        
        if int(branch_size) != branch_size or branch_size < 2:
            raise FANNException('branch_size must be an integer >= 2.')

        if int(num_branches) != num_branches or num_branches < 1:
            raise FANNException('num_branches must be an integer >= 1.')

        pts = self.__ensure2dArray(pts)
        npts, dim = pts.shape
        
        pts_flat = self.__getFlattenedArray(pts)
        
        if max_iterations == None: 
            max_iterations = -1
        else:
            max_iterations = int(max_iterations)
        
        
        num_clusters = (branch_size-1)*num_branches+1;

        result = empty(num_clusters * dim, dtype=float32)
        
        params = self.__get_param_arg_list({"iterations"     : int(max_iterations),
                                            "algorithm"      : 'kmeans',
                                            "branching"      : int(branch_size)})

        with self.__nn_lock:
            numclusters = fann.run_kmeans(pts_flat, npts, dim,
                                          num_clusters,
                                          result,
                                          *params)
            
            if numclusters <= 0:
                raise FANNException('Error occured during clustering procedure.')

            sys.stdout.flush()

        if dtype == None:
            return pts.dtype.type(result.reshape( (num_clusters, dim) ) )
        else:
            return dtype.type(result.reshape( (num_clusters, dim) ) )
        
    ##########################################################################################
    # internal bookkeeping functions

    def __get_algo_num(self, name):
        d = get_algorithm_enum_dict()

        try:
            return d[name]
        except KeyError:
            raise KeyError('%s not a valid algorithm name' % str(name))

    def __get_params(self, newargs):
        pd = self.__update_param_dict(self.getDefaults(), newargs)

        if type(pd["algorithm"]) == str:
            pd["algorithm"] = self.__get_algo_num(pd["algorithm"])

        pd["target_precision"] = float(pd["target_precision"])
        
        return [(n, pd[n]) for n, v in get_param_args()]

    def __get_param_arg_list(self, newargs):
        return [v for n,v in self.__get_params(newargs)]

    def __print_param_arg_list(self, newargs):
        print 'params: ', self.__get_params(newargs)
        
    def __get_one_param(self, newargs, pname):
        try:
            return newargs[pname]
        except KeyError:
            with self.__params_lock:
                return self.__param_dict[pname]

    def __update_param_dict(self, pd, newargs):
        
        for k, v in dict(newargs).iteritems():
            if k not in self.__param_dict:
                raise KeyError('%s not a possible parameter.' % k)
            else:
                pd[k] = v

        return pd

    def __ensure2dArray(self, X):
        if isinstance(X, matrix):
            X = array(X)

        if type(X) == list or type(X) == tuple:
            X = array(X, dtype=float32)

        if X.ndim == 1:
            X = X.reshape(len(X), 1)
        
        assert(X.ndim == 2)
        assert(X.shape[0] > 0)
        assert(X.shape[1] > 0)

        return X

    
    def __getFlattenedArray(self, X):

        if X.dtype == float32:
            X_flat = X.flatten()
        elif X.dtype == float64:
            X_flat = empty( X.size, dtype = float32)
            fann.flatten_double2float(X, X_flat)
        else:
            X_flat = float32(X.flatten())

        return X_flat
        
