from __future__ import with_statement

import sys

try:
    import flann_python_base as flann
except ImportError, ie:
    sys.stderr.write('\n\nError importing required flann_python_base module. \n')
    sys.stderr.write('Please create it by executing create_python_base.py.\n\n')
    raise ie

from index_type import index_type
from pyflann_exceptions import *

import threading
from numpy import float32, float64, int32, matrix, array, empty
import numpy.random as _rn
import pyflann_parameters as params
from copy import copy

class FLANN:
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
    
    __rn_lock = threading.Lock()
    __rn_gen = _rn.RandomState()
    __rn_params_idx = params.get_param_struct_name_list().index('random_seed')
    __rn_flannparams_idx = params.get_flann_param_struct_name_list().index('random_seed')

    def __init__(self, **kwargs):
        """
        Constructor for the class and returns a class that can bind to
        the flann libraries.  Any keyword arguments passed to __init__
        override the global defaults given.
        """

        self.__curindex = None
        self.__curindex_data = None
        self.__curindex_data_shape = None
        self.__idx_lock = threading.Lock()
        
        # Set param dict
        self.__initial_param_dict = {}
        self.__params_lock = threading.Lock()
        dp = dict(params.get_param_args())
        dp.update(kwargs)
        self.setParamDefault(**dp)

    def __del__(self):
        self.delete_index()            

    ################################################################################
    # Bookkeeping type functions

    def setParamDefault(self, **kwargs):
        """
        Takes a set of keyword arguments and updates the default
        parameter set.  Throws an exception if a kwyword is not a
        possible parameter.
        """
        
        with self.__params_lock:
            self.__update_param_dict(self.__initial_param_dict, kwargs)
            self.__processed_param_dict = copy(self.__initial_param_dict)
            params.process_param_dict(self.__processed_param_dict)
            self.__default_arg_list = [self.__processed_param_dict[n] 
                                       for n, v in params.get_param_args()]

            self.__default_flann_arg_list = [self.__processed_param_dict[n]
                                            for n, v in params.get_flann_param_args()]

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

        # It could be that querypts is only a single pt
        nqpts = querypts.shape[0]

        assert(querypts.shape[1] == dim)
        assert(npts >= num_neighbors)

        pts_flat = self.__getFlattenedArray(pts)
        querypts_flat = self.__getFlattenedArray(querypts)

        result = empty(nqpts * num_neighbors, dtype=index_type)

        params = self.__get_param_arg_list(kwargs)

        flann.find_nn(pts_flat, npts, dim,
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
        
        params_ = self.__get_param_arg_list(kwargs)
        flann_params = self.__get_flann_param_arg_list(kwargs)

        kwargs['random_seed'] = self.__getRandomSeed(kwargs)

        with self.__idx_lock:
            if self.__curindex != None:
                flann.del_index(self.__curindex, *flann_params)
            
            self.__curindex, index_params = flann.make_index(pts_flat, npts, dim, *params_)

            self.__curindex_data = pts_flat
            self.__curindex_data_shape = pts.shape
            
            params.translate_strings_back(index_params)
        
        return index_params


    def nn_index(self, querypts, num_neighbors = 1, **kwargs):
        """
        For each point in querypts, (which may be a single point), it
        returns the num_neighbors nearest points in the index built by
        calling build_index.

        If num_neighbors > 1, the result is a 2d array of indices of
        size len(querypts) x num_neighbors; otherwise, the result is a
        1d array of the indices of the closest points in pts.
        """

        if self.__curindex == None:
            raise FLANNException("build_index(...) method not called first or current index deleted.")

        npts, dim = self.__curindex_data_shape

        if querypts.size == dim:
            querypts.reshape(1, dim)

        querypts = self.__ensure2dArray(querypts)

        nqpts = querypts.shape[0]

        assert(querypts.shape[1] == dim)
        assert(npts >= num_neighbors)
        
        querypts_flat = self.__getFlattenedArray(querypts)

        result = empty(nqpts * num_neighbors, dtype=index_type)

        checks = self.__get_one_param(kwargs, "checks")
        flann_params = self.__get_flann_param_arg_list(kwargs)

        flann.find_nn_index(self.__curindex, 
                    querypts_flat, nqpts,
                    result, num_neighbors,
                    checks, *flann_params)

        if num_neighbors == 1:
            return result
        else:
            return result.reshape( (nqpts, num_neighbors) )

    def delete_index(self, **kwargs):
        """
        Deletes the current index and all the data associated with it.
        Useful for freeing up some memory, but not necessary to call
        otherwise.
        """

        flann_params = self.__get_flann_param_arg_list(kwargs)
        
        with self.__idx_lock:
            if self.__curindex != None:
                flann.del_index(self.__curindex, *flann_params)

                self.__curindex = None
                self.__curindex_data = None
                self.__curindex_data_shape = None

    ##########################################################################################
    # Clustering functions

    def kmeans(self, pts, num_clusters, centers_init = "random", 
               max_iterations = None, best_of_n = 1, 
               ensure_none_empty = False, max_retries = 100,
               dtype = None, **kwargs):
        """
        Runs kmeans on pts with num_clusters centroids.  Returns a
        numpy array of size num_clusters x dim.  

        If max_iterations is not None, the algorithm terminates after
        the given number of iterations regardless of convergence.  The
        default is to terminate until convergence.

        If dtype is None (the default), the array returned is the same
        type as pts.  Otherwise, the returned array is of type dtype.  

        If more accuracy is desired, you may optionally set best_of_n
        to n > 1.  In this case, it performs k-means n times and
        returns the result with the best value of the objective
        function.  Random number seeds are then generated by supplying
        the given seed as the first number, then generating the rest
        using numpy.random seeded with the given seed.  If random_seed is
        a list or array of length best_of_n, those seeds are used.
        
        Additionally, specifying ensure_none_empty to True rejects a
        clustering if any of the centroids have no associated points
        and retries up to max_retries times.  These rejected
        clusterings do not count towards the best_of_n count.
        If max_retries is exceeded, a FLANNException is raised.
        """
        
        if int(num_clusters) != num_clusters or num_clusters < 1:
            raise FLANNException('num_clusters must be an integer >= 1')
        
        if num_clusters == 1:
            if dtype == None or dtype == pts.dtype:
                return mean(pts, 0).reshape(1, pts.shape[1])
            else:
                return dtype.type(mean(pts, 0).reshape(1, pts.shape[1]))

        return self.hierarchical_kmeans(pts, int(num_clusters), 1, 
                                        max_iterations, best_of_n, 
                                        ensure_none_empty, max_retries,
                                        dtype, **kwargs)
        
    def hierarchical_kmeans(self, pts, branch_size, num_branches, 
                            max_iterations = None, best_of_n = 1, 
                            ensure_none_empty = False, max_retries = 100,
                            dtype = None, **kwargs):
        """
        Clusters the data by using multiple runs of kmeans to
        recursively partition the dataset.  The number of resulting
        clusters is given by (branch_size-1)*num_branches+1.
        
        This method can be significantly faster when the number of
        desired clusters is quite large (e.g. a hundred or more).
        Higher branch sizes are slower but may give better results.

        If dtype is None (the default), the array returned is the same
        type as pts.  Otherwise, the returned array is of type dtype.  

        If more accuracy is desired, you may optionally set best_of_n
        to n > 1.  In this case, it performs k-means n times and
        returns the result with the best value of the objective
        function.  In this case, random number seeds are then
        generated by supplying the given seed as the first number,
        then generating the rest using numpy.random seeded with the
        given seed.  If random_seed is a list or array of length
        best_of_n, those seeds are used.
        
        Additionally, specifying ensure_none_empty to True rejects a
        clustering if any of the centroids have no associated points
        and retries up to max_retries times.  These rejected
        clusterings do not count towards the best_of_n count.
        If max_retries is exceeded, a FLANNException is raised.
        """
        
        # First verify the paremeters are sensible.

        if int(branch_size) != branch_size or branch_size < 2:
            raise FLANNException('branch_size must be an integer >= 2.')

        branch_size = int(branch_size)

        if int(num_branches) != num_branches or num_branches < 1:
            raise FLANNException('num_branches must be an integer >= 1.')

        num_branches = int(num_branches)

        if int(best_of_n) != best_of_n or best_of_n < 1:
            raise FLANNException('best_of_n must be an integer >= 1.')
        
        best_of_n = int(best_of_n)

        if max_iterations == None: 
            max_iterations = -1
        else:
            max_iterations = int(max_iterations)


        #init the arrays and starting values
        pts = self.__ensure2dArray(pts)
        npts, dim = pts.shape
        pts_flat = self.__getFlattenedArray(pts)
        num_clusters = (branch_size-1)*num_branches+1;
        result = empty(num_clusters * dim, dtype=float32)

        # set all the parameters appropriately
        kwargs.update({"iterations"       : int(max_iterations),
                       "algorithm"        : 'kmeans',
                       "branching"        : int(branch_size),
                       "random_seed"         : self.__getRandomSeed(kwargs)})
        
        params = self.__get_param_arg_list(kwargs)

        pts_basis = pts_flat.reshape( (npts, dim) )

        # Set the random number seed in the argument
        

        def __RunKMeans(result_buf, random_seed = None):
            
            if random_seed != None:
                params[self.__rn_params_idx] = random_seed

            if ensure_none_empty:
                from utils import hasEmptyCluster as __hasEmpty

                for i in xrange(max_retries):
                    numclusters = flann.run_kmeans(pts_flat, npts, dim,
                                                    num_clusters, result_buf, *params)
                    if numclusters <= 0:
                        raise FLANNException('Error occured during clustering procedure, code = %d' % numclusters)
                    
                    if not __hasEmpty(pts_basis, result_buf.reshape( (num_clusters, dim) ) ):
                        return

                raise FLANNException('Finding cluster with no empty centroids: maximum number of tries exceeded.')
            else:
                numclusters = flann.run_kmeans(pts_flat, npts, dim,
                                                num_clusters, result_buf, *params)
                if numclusters <= 0:
                    raise FLANNException('Error occured during clustering procedure.')
                
        __RunKMeans(result)

        if best_of_n > 1:
            # Generate the random seeds 
            rnsgen = _rn.RandomState(kwargs['random_seed'])
            rnseeds = rnsgen.randint(0, 2**30, best_of_n - 1)

            from utils import getKMeansObjective as __kmobj

            result_best = result
            objval_best = __kmobj(pts_flat.reshape( (npts, dim) ),  
                                  result.reshape( (num_clusters, dim) ) )

            result_contender = empty(num_clusters *dim, dtype=float32)

            for i in xrange(best_of_n - 1):
                __RunKMeans(result_contender, rnseeds[i])
                
                objval_contender = __kmobj(pts_flat.reshape( (npts, dim) ), 
                                           result_contender.reshape( (num_clusters, dim) ) )

                if objval_contender < objval_best:
                    objval_best = objval_contender
                    r = result_best
                    result_best = result_contender
                    result_contender = r

                
            result = result_best

        if dtype == None:
            return pts.dtype.type(result.reshape( (num_clusters, dim) ) )
        else:
            return dtype.type(result.reshape( (num_clusters, dim) ) )
        
    ##########################################################################################
    # internal bookkeeping functions

    def __get_params(self, newargs = {}):
        params.process_param_dict(newargs)
        pd = self.__update_param_dict(self.__getProcessedDefaults(), newargs)
        return [(n, pd[n]) for n, v in params.get_param_args()]

    def __get_flann_params(self, newargs = {}):
        if len(newargs) == 0:
            return self.__default_flann_arg_list
        else:
            params.process_param_dict(newargs)
            pd = self.__update_param_dict(self.__getProcessedDefaults(), newargs)
            
            return [(n, pd[n]) for n, v in 
                    params.get_flann_param_args()]

    def __get_param_arg_list(self, newargs = {}):
        if len(newargs) == 0:
            return self.__default_arg_list
        else:
            return [v for n,v in self.__get_params(newargs)]

    def __get_flann_param_arg_list(self, newargs = {}):
        if len(newargs) == 0:
            return self.__default_flann_arg_list
        else:
            return [v for n,v in self.__get_flann_params(newargs)]

    def __print_param_arg_list(self, newargs = {}):
        print 'params: ', self.__get_params(newargs)
        
    def __get_one_param(self, newargs, pname):
        params.process_param_dict(newargs)
        
        try:
            return newargs[pname]
        except KeyError:
            return self.__getProcessedDefaults()[pname]

    def __getProcessedDefaults(self):
        with self.__params_lock:
            return self.__processed_param_dict

    def __update_param_dict(self, pd, newargs):
        for k, v in dict(newargs).iteritems():
            if k not in params.get_param_struct_name_list():
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
            X_flat = X.ravel()
        elif X.dtype == float64:
            X_flat = empty( X.size, dtype = float32)
            flann.flatten_double2float(X, X_flat)
        else:
            X_flat = float32(X.ravel())

        return X_flat
        
    def __getRandomSeed(self, kwargs):
        try:
            return kwargs['random_seed']
        except KeyError:
            with self.__rn_lock:
                return self.__rn_gen.randint(2**30)
        
