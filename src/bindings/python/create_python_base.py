#!/usr/bin/python

# This script uses weave to create the code bindings that

import sys
from index_type import index_type

# Import the required non-standard libraries
try:
    from numpy import *
except ImportError:
    sys.stderr.write('\nNumPy is required to generate the python bindings.\n')
    sys.stderr.write('See numpy.scipy.org for more information.\n')
    sys.exit(1)

try:
    from scipy.weave import *
except ImportError:
    try:
        from weave import *
    except ImportError:
        sys.stderr.write('Weave is required to generate the python bindings.\n')
        sys.stderr.write('It is included as a standalone package or as part of scipy.\n')
        sys.stderr.write('See www.scipy.org/Weave for more information.')
        sys.exit(1)

from os import *
from os.path import *

# This contains the program defaults; centralized to make adding features easier
from define_params import *

# remove the old bindings so it recompiles if needed


def getBaseDir():
    subpath = ['src', 'bindings', 'python']

    def toRoot(p):
        basepath, curdir = path.split(p)
        if curdir in subpath:   return toRoot(basepath)
        else:                   return p

    return toRoot(getcwd())

def getIncludeDirs():
    basedir = getBaseDir()
    return [join(basedir, 'src/bindings/c')]

def getLibDirs():
    basedir = getBaseDir()
    return [join(basedir, 'build/lib'),
            join(basedir, 'bin/gdc/lib/gcc/i686-pc-linux-gnu/4.1.2')]

def getLibs():
    return ['fann', 'gphobos']


###################################################################################
# The main execution starts here

def createPythonBase(*args):

    # Make sure we are in the correct directory
    cwd = getcwd()

    basedir = getBaseDir()
    
    chdir(abspath(join(basedir, 'src/bindings/python/')))

    try:
        remove("fann_python_base.cpp")
    except OSError:
        pass

    print "Creating extension module."

    fci = ext_tools.ext_module('fann_python_base')

    # Add in the required headers
    fci.customize.add_header('\"fann.h\"')
    fci.customize.add_header('<stdio.h>')

    for d in getLibDirs():
        fci.customize.add_library_dir(d)
    for d in getIncludeDirs():
        fci.customize.add_include_dir(d)
    for l in getLibs():
        fci.customize.add_library(l)    
    fci.customize.add_extra_compile_arg('-Wno-unused-variable')
    fci.customize.add_extra_compile_arg('-Wno-deprecated')
    
    # A helper function to make the code more concise
    def addFunc(name, code, *varlist):
        """
        varlist is list of pairs of (name, value).
        """

        for t in varlist:
            assert(type(t) == tuple)
            assert(len(t) == 2)
            assert(type(t[0]) == str)

        args = [n for n, v in varlist]
        vardict = dict(varlist)

        code = (code
                .replace('\n         ', '\n')
                .replace('\n        ', '\n')
                .replace('\n       ', '\n')
                .replace('\n      ', '\n')
                .replace('\n     ', '\n')
                .replace('\n    ', '\n')
                .replace('\n   ', '\n')
                .replace('\n  ', '\n')
                .replace('\n ', '\n'))
                
        fci.add_function(ext_tools.ext_function(name, code, args, local_dict = vardict))


    ################################################################################
    # Bookkeeping functions

    # Index stuff (we can just use flatten() if it's already in
    # float32, but if we're converting from float64 we avoid copying
    # twice by doing it this way.

    addFunc('flatten_double2float',
            r"""
            size_t loc = 0;
            for(size_t i = 0; i < Npts[0]; ++i)
            {
              for(size_t p = 0; p < Npts[1]; ++p)
              {
                pts_flat[loc] = float( PTS2(i,p) );
                ++loc;
              }
            }
            """,
            ('pts', empty( (1,1), dtype = float64)),
            ('pts_flat', empty(1, dtype = float32)))
            

    ##################################################
    # Ways to streamline the handling of optional parameters
    # Have to treat algorithm as special, since it's an enum.

    params_set_code = \
    ("Parameters params;\n"
     + ''.join(['params.%s = %s; // printf("%s = %s\\n", %s);\n'
                % (n, n,n,'%f','float(' + n + ')')
                for n in get_param_struct_name_list()]))

    param_ptr_code = r"(&params)"

    #################################################################################
    # Functions that do the actual interfacing. 

    addFunc('make_index',
            params_set_code + 
            r"""
            return_val = fann_build_index(dataset, npts, dim, %s);
            """ % param_ptr_code,
            ('dataset', empty(1, dtype=float32)),
            ('npts', int(0)),
            ('dim', int(0)),
            *get_param_args())

    addFunc('del_index', r"fann_free_index(FANN_INDEX(i));", ('i', int(0)))
            
    addFunc('find_nn_index',
            r'fann_find_nearest_neighbors_index(FANN_INDEX(nn_index), testset, tcount, (int*)result, num_neighbors, checks);',
            ('nn_index', int(0)),
            ('testset', empty(1, dtype=float32)),
            ('tcount', int(0)),
            ('result', empty(1, dtype=index_type)),
            ('num_neighbors', int(0)),
            ('checks', int(0)))

    addFunc('find_nn',
            params_set_code + 
            r"""
            fann_find_nearest_neighbors(dataset, npts, dim, testset, tcount,
            (int*)result, num_neighbors, %s);
            """ % param_ptr_code,
            ('dataset', empty(1, dtype=float32)),
            ('npts', int(0)),
            ('dim', int(0)),
            ('testset', empty(1, dtype=float32)),
            ('tcount', int(0)),
            ('result', empty(1, dtype=index_type )),
            ('num_neighbors', int(0)),
            *get_param_args())

    addFunc('run_kmeans',
            params_set_code + 
            r"""
            // A few commands to make sure we set the parameters correctly.
            return_val = fann_compute_cluster_centers(dataset, npts, dim, num_clusters, (float*)result, %s);
            """ % param_ptr_code,
            ('dataset', empty(1, dtype=float32)),
            ('npts', int(0)),
            ('dim', int(0)),
            ('num_clusters', int(0)),
            ('result', empty(1, dtype=float32)),
            *get_param_args())


    ##########################################################################################
    # We're ready to go!!!

    fci.customize.add_extra_compile_arg('-g')
    fci.compile()
    chmod('fann_python_base.so', 420)  # oct 644
    
    basemodule = join(cwd, 'fann_python_base.so')
    
    chdir(cwd)
    
    print '\nDone creating fann_python_base.\n'

    return basemodule
    
if __name__ == '__main__':
    createPythonBase()
