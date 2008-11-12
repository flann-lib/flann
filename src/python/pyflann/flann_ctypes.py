from ctypes import *
#from ctypes.util import find_library
from numpy import float32, float64, int32, matrix, array, empty, reshape, require
from numpy.ctypeslib import load_library, ndpointer
import numpy.random as _rn
import os
from util.exceptions import *

STRING = c_char_p


class CustomStructure(Structure):
    """
        This class extends the functionality of the ctype's structure
        class by adding custom default values to the fields and a way of translating
        field types.
    """
    _defaults_ = {}
    _translation_ = {}
    
    def __init__(self):
        Structure.__init__(self)
        self.__field_names = [ f for (f,t) in self._fields_]
        self.update(self._defaults_)    
    
    def update(self, dict):
        for k,v in dict.iteritems():
            if k in self.__field_names:
                setattr(self,k,self.__translate(k,v))
    
    def __getitem__(self, k):
        if k in self.__field_names:
            return self.__translate_back(k,getattr(self,k))
        
    def __setitem__(self, k, v):
        if k in self.__field_names:
            setattr(self,k,self.__translate(k,v))
        else:
            raise KeyError("No such member: "+k)
    
    def keys(self):
        return self.__field_names 

    def __translate(self,k,v):
        if k in self._translation_:
            if v in self._translation_[k]:
                return self._translation_[k][v]
        return v        

    def __translate_back(self,k,v):
        if k in self._translation_:
            for tk,tv in self._translation_[k].iteritems():
                if tv==v:
                    return tk
        return v        

class IndexParameters(CustomStructure):
    _fields_ = [
        ('algorithm', c_int),
        ('checks', c_int),
        ('cb_index', c_float),
        ('trees', c_int),
        ('branching', c_int),
        ('iterations', c_int),
        ('centers_init', c_int),
        ('target_precision', c_float),
        ('build_weight', c_float),
        ('memory_weight', c_float),
        ('sample_fraction', c_float),
    ]
    _defaults_ = {
        'algorithm' : 'kdtree',
        'checks' : 32,
        'cb_index' : 0.5,
        'trees' : 1,
        'branching' : 32,
        'iterations' : 5,
        'centers_init' : 'random',
        'target_precision' : -1,
        'build_weight' : 0.01,
        'memory_weight' : 0.0,
        'sample_fraction' : 0.1
    }
    _translation_ = {
        "algorithm"     : {"linear"    : 0, "kdtree"    : 1, "kmeans"    : 2, "composite" : 3, "default"   : 1},
        "centers_init"  : {"random"    : 0, "gonzales"  : 1, "kmeanspp"  : 2, "default"   : 0},
    }


class FLANNParameters(CustomStructure):
    _fields_ = [
        ('log_level', c_int),
        ('log_destination', STRING),
        ('random_seed', c_long),
    ]
    _defaults_ = {
        'log_level' : "warning",
        'log_destination' : None,
    }
    _translation_ = {
        "log_level"     : {"none"      : 0, "fatal"     : 1, "error"     : 2, "warning"   : 3, "info"      : 4, "default"   : 2}
    }

    
    
default_flags = ['C_CONTIGUOUS', 'ALIGNED']
   
    
    
def find_root(directory = None):
    if directory == None:
        directory = os.path.dirname(__file__)
    if os.path.isfile(directory+"/flann.py"):
        return os.path.abspath(directory+"/..")
    else:
        return find_root(os.path.abspath(directory+"/.."))

root_dir = find_root()
    
FLANN_INDEX = c_int


flann = load_library('libflann', root_dir+"/python")
#CDLL(root_dir+'/python/libflann.so')

flann.flann_init.restype = None
flann.flann_init.argtypes = []

flann.flann_term.restype = None
flann.flann_term.argtypes = []

flann.flann_log_verbosity.restype = None
flann.flann_log_verbosity.argtypes = [ 
        c_int # level
]

flann.flann_log_destination.restype = None
flann.flann_log_destination.argtypes = [ 
        STRING # destination
]

flann.flann_build_index.restype = FLANN_INDEX
flann.flann_build_index.argtypes = [ 
        ndpointer(float32, flags='aligned, c_contiguous'), # dataset
        c_int, # rows
        c_int, # cols
        POINTER(c_float), # speedup 
        POINTER(IndexParameters), # index_params
        POINTER(FLANNParameters)  # flann_params
]
                                   
flann.flann_find_nearest_neighbors.restype = c_int
flann.flann_find_nearest_neighbors.argtypes = [ 
        ndpointer(float32, flags='aligned, c_contiguous'), # dataset
        c_int, # rows
        c_int, # cols
        ndpointer(float32, flags='aligned, c_contiguous'), # testset
        c_int,  # tcount
        ndpointer(int32, flags='aligned, c_contiguous, writeable'), # result
        c_int, # nn
        POINTER(IndexParameters), # index_params 
        POINTER(FLANNParameters)  # flann_params
]


flann.flann_find_nearest_neighbors_index.restype = c_int
flann.flann_find_nearest_neighbors_index.argtypes = [ 
        FLANN_INDEX, # index_id
        ndpointer(float32, flags='aligned, c_contiguous'), # testset
        c_int,  # tcount
        ndpointer(int32, flags='aligned, c_contiguous, writeable'), # result
        c_int, # nn
        c_int, # checks
        POINTER(FLANNParameters) # flann_params
]


flann.flann_free_index.restype = None
flann.flann_free_index.argtypes = [ 
        FLANN_INDEX,  # index_id
        POINTER(FLANNParameters) # flann_params
]

flann.flann_compute_cluster_centers.restype = c_int
flann.flann_compute_cluster_centers.argtypes = [ 
        ndpointer(float32, flags='aligned, c_contiguous'), # dataset
        c_int,  # rows
        c_int,  # cols
        c_int,  # clusters 
        ndpointer(float32, flags='aligned, c_contiguous, writeable'), # result
        POINTER(IndexParameters), # index_params
        POINTER(FLANNParameters)  # flann_params
]

flann.compute_ground_truth_float.restype = None
flann.compute_ground_truth_float.argtypes = [ 
        ndpointer(float32, flags='aligned, c_contiguous'), # dataset
        c_int, # rows
        c_int,  #cols
        ndpointer(float32, flags='aligned, c_contiguous'), # cols
        c_int, # trows
        ndpointer(int32, flags='aligned, c_contiguous, writeable'), # matches
        c_int, # nn
        c_int # skip
]


def compute_ground_truth(dataset, testset, nn, skip = 0):
    
    dataset = require(dataset,float32,default_flags) 
    testset = require(testset,float32,default_flags) 
    
    rows, cols = dataset.shape
    trows, tcols = testset.shape
    assert( cols == tcols )
    
    match = empty((trows,nn), dtype=int32)
    
    flann.compute_ground_truth_float(dataset, rows, cols, testset, trows, match, nn, skip)
    return match




index_type = int32

class FLANN:
    """
    This class defines a python interface to the FLANN lirary.
    """
    __rn_gen = _rn.RandomState()


    def __init__(self, **kwargs):
        """
        Constructor for the class and returns a class that can bind to
        the flann libraries.  Any keyword arguments passed to __init__
        override the global defaults given.
        """

        self.__curindex = None
        self.__curindex_data = None
        
        self.__flann_parameters = FLANNParameters()        
        self.__index_parameters = IndexParameters()
        
        self.__flann_parameters.update(kwargs)
        self.__index_parameters.update(kwargs)

    def __del__(self):
        self.delete_index()

        
    ################################################################################
    # actual workhorse functions

    def nn(self, pts, qpts, num_neighbors = 1, **kwargs):
        """
        Returns the num_neighbors nearest points in dataset for each point
        in testset.
        """
        
        
        pts = require(pts,float32,default_flags) 
        qpts = require(qpts,float32,default_flags) 

        npts, dim = pts.shape
        nqpts = qpts.shape[0]

        assert(qpts.shape[1] == dim)
        assert(npts >= num_neighbors)

        result = empty( (nqpts, num_neighbors), dtype=index_type)
                
        self.__flann_parameters.update(kwargs)
        self.__index_parameters.update(kwargs)
        
        flann.flann_find_nearest_neighbors(pts, npts, dim, 
            qpts, nqpts, result, num_neighbors, 
            pointer(self.__index_parameters), pointer(self.__flann_parameters))

        if num_neighbors == 1:
            return result.reshape( nqpts )
        else:
            return result


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

        pts = require(pts,float32,default_flags) 
        npts, dim = pts.shape
        
        self.__getRandomSeed(kwargs)
        
        self.__flann_parameters.update(kwargs)
        self.__index_parameters.update(kwargs)

        if self.__curindex != None:
            flann.flann_free_index(self.__curindex, pointer(flann_params))
                
        speedup = c_float(0)
        self.__curindex = flann.flann_build_index(pts, npts, dim, pointer(speedup), pointer(self.__index_parameters), pointer(self.__flann_parameters))
        self.__curindex_data = pts
        
        params = dict(self.__index_parameters)
        params["speedup"] = speedup.value
        
        return params


    def nn_index(self, qpts, num_neighbors = 1, **kwargs):
        """
        For each point in querypts, (which may be a single point), it
        returns the num_neighbors nearest points in the index built by
        calling build_index.

        """

        if self.__curindex == None:
            raise FLANNException("build_index(...) method not called first or current index deleted.")

        npts, dim = self.__curindex_data.shape

        if qpts.size == dim:
            qpts.reshape(1, dim)

        qpts = require(qpts,float32,default_flags) 

        nqpts = qpts.shape[0]

        assert(qpts.shape[1] == dim)
        assert(npts >= num_neighbors)
        
        result = empty( (nqpts, num_neighbors), dtype=index_type)

        self.__flann_parameters.update(kwargs)
        self.__index_parameters.update(kwargs)

        checks = self.__index_parameters['checks']

        flann.flann_find_nearest_neighbors_index(self.__curindex, 
                    qpts, nqpts,
                    result, num_neighbors,
                    checks, pointer(self.__flann_parameters))

        if num_neighbors == 1:
            return result.reshape( nqpts )
        else:
            return result

    def delete_index(self, **kwargs):
        """
        Deletes the current index freeing all the momory it uses. 
        The memory used by the dataset that was indexed is not freed.
        """

        self.__flann_parameters.update(kwargs)
        
        if self.__curindex != None:
            flann.flann_free_index(self.__curindex, pointer(self.__flann_parameters))
            self.__curindex = None
            self.__curindex_data = None

    ##########################################################################################
    # Clustering functions

    def kmeans(self, pts, num_clusters, centers_init = "random", 
               max_iterations = None,
               dtype = None, **kwargs):
        """
        Runs kmeans on pts with num_clusters centroids.  Returns a
        numpy array of size num_clusters x dim.  

        If max_iterations is not None, the algorithm terminates after
        the given number of iterations regardless of convergence.  The
        default is to run until convergence.

        If dtype is None (the default), the array returned is the same
        type as pts.  Otherwise, the returned array is of type dtype.  

        """
        
        if int(num_clusters) != num_clusters or num_clusters < 1:
            raise FLANNException('num_clusters must be an integer >= 1')
        
        if num_clusters == 1:
            if dtype == None or dtype == pts.dtype:
                return mean(pts, 0).reshape(1, pts.shape[1])
            else:
                return dtype.type(mean(pts, 0).reshape(1, pts.shape[1]))

        return self.hierarchical_kmeans(pts, int(num_clusters), 1, 
                                        max_iterations, 
                                        dtype, **kwargs)
        
    def hierarchical_kmeans(self, pts, branch_size, num_branches,
                            max_iterations = None, 
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
        
        """
        
        # First verify the paremeters are sensible.

        if int(branch_size) != branch_size or branch_size < 2:
            raise FLANNException('branch_size must be an integer >= 2.')

        branch_size = int(branch_size)

        if int(num_branches) != num_branches or num_branches < 1:
            raise FLANNException('num_branches must be an integer >= 1.')

        num_branches = int(num_branches)

        if max_iterations == None: 
            max_iterations = -1
        else:
            max_iterations = int(max_iterations)


        # init the arrays and starting values
        pts = require(pts,float32,default_flags) 
        npts, dim = pts.shape
        num_clusters = (branch_size-1)*num_branches+1;
        
        result = empty( (num_clusters, dim), dtype=float32)

        # set all the parameters appropriately
        
        params = {"iterations"       : max_iterations,
                    "algorithm"        : 'kmeans',
                    "branching"        : branch_size,
                    "random_seed"      : self.__getRandomSeed(kwargs)}
        
        self.__index_parameters.update(params)
        self.__flann_parameters.update(params)
        
        numclusters = flann.flann_compute_cluster_centers(pts, npts, dim,
                                        num_clusters, result, 
                                        pointer(self.__index_parameters), pointer(self.__flann_parameters))
        if numclusters <= 0:
            raise FLANNException('Error occured during clustering procedure.')

        if dtype == None:
            return result
        else:
            return dtype.type(result)
        
    ##########################################################################################
    # internal bookkeeping functions

        
    def __getRandomSeed(self, kwargs):
        try:
            return kwargs['random_seed']
        except KeyError:
            return self.__rn_gen.randint(2**30)
        
