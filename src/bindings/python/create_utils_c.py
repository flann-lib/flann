#!/usr/bin/python

# This code compiles the utils_c module for the pyfann extension.

from numpy import *
from scipy.weave import *
import os, sys

def createUtilsC():
    
    try:
        os.remove('utils_c.cpp')
    except OSError:
        pass

    utils_c_ext = ext_tools.ext_module('utils_c')

    utils_c_ext.customize.add_header('<stdio.h>')

    #utils_c_ext.customize.add_extra_compile_arg('-g')
    #utils_c_ext.customize.add_extra_compile_arg('--debug')

    utils_c_ext.customize.add_extra_compile_arg('-O3')

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
        utils_c_ext.add_function(ext_tools.ext_function(name, code, args, local_dict = vardict))



    ##########################################################################################
    # dists2_double

    calccode_dists2_double = r"""

    // Takes centers and  pts (2-d), puts value into dm

    int K = Ncenters[0];
    int dim = Ncenters[1];
    int nP = Npts[0];

    for(int i = 0; i < nP; ++i)
    {
       for(int j = 0; j < K; ++j)
       {
          DM2(i, j) = 0;

          for(int p = 0; p < dim; ++p)
          {
            double ddiff = (PTS2(i, p) - CENTERS2(j, p));
            DM2(i, j) += ddiff*ddiff;
          }
       }
    }

    """

    addFunc('dists2_double', calccode_dists2_double,
            ('pts', empty( (1,1), dtype=float64)),
            ('centers',empty( (1,1), dtype=float64)),
            ('dm', empty( (1,1), dtype=float64)) )

    ##################################################
    # dists2_float

    calccode_dists2_float = calccode_dists2_double.replace('double', 'float')

    addFunc('dists2_float',calccode_dists2_float,
            ('pts', empty( (1,1), dtype=float32)),
            ('centers',empty( (1,1), dtype=float32)),
            ('dm', empty( (1,1), dtype=float32)) )

    ##########################################################################################
    # dist_labels

    calccode_dist_labels_double = r"""

    // Takes the distance matrix dm and puts the point assignments into labels.

    for(int i = 0; i < Ndm[0]; ++i)
    {
      double minval = DM2(i, 0);
      LABELS1(i) = 0;
 
      for(int j = 1; j < Ndm[1]; ++j)
      {
        if(DM2(i,j) < minval)
        {
          LABELS1(i) = j;
          minval = DM2(i,j);
        }
      }
    }

    """

    addFunc('dist_labels_double',calccode_dist_labels_double,
            ('dm', empty( (1,1), dtype=float64)),
            ('labels', empty(1, dtype=int32)) )

    addFunc('dist_labels_float',calccode_dist_labels_double.replace('double', 'float'),
            ('dm',  empty( (1,1), dtype=float32)),
            ('labels', empty(1, dtype=int32)) )


    calccode_labels_direct_double = r"""

    // Takes pts and centers and calculates the labels.

    size_t K = Ncenters[0];
    size_t dim = Ncenters[1];
    size_t nP = Npts[0];

    for(int i = 0; i < nP; ++i)
    {
       double best_so_far = 0;
       LABELS1(i) = 0;

       for(int p = 0; p < dim; ++p)
       {
          double ddiff = (PTS2(i, p) - CENTERS2(0, p));
          best_so_far += ddiff*ddiff;
       }

       for(int j = 1; j < K; ++j)
       {
         double d = 0;
          
         for(int p = 0; p < dim; ++p)
         {
           double ddiff = (PTS2(i, p) - CENTERS2(j, p));
           d += ddiff*ddiff;
         }

         if(d < best_so_far)
         {
           best_so_far = d;
           LABELS1(i) = j;
         }
       }
    }

    """

    addFunc('labels_direct_double_double',calccode_labels_direct_double,
            ('pts', empty( (1,1), dtype=float64)),
            ('centers',empty( (1,1), dtype=float64)),
            ('labels', empty(1, dtype=int32)) )

    addFunc('labels_direct_double_float',calccode_labels_direct_double,
            ('pts', empty( (1,1), dtype=float64)),
            ('centers',empty( (1,1), dtype=float32)),
            ('labels', empty(1, dtype=int32)) )

    addFunc('labels_direct_float_float',
            calccode_labels_direct_double.replace('double', 'float'),
            ('pts', empty( (1,1), dtype=float32)),
            ('centers',empty( (1,1), dtype=float32)),
            ('labels', empty(1, dtype=int32)) )



    ##########################################################################################
    # Functions to calculate the value of the kmeans objective function

    calccode_kmeansobj_dists_labels_code_double = r"""

    // Takes the distance matrix and labels and calculates the total
    // variance.  Very quick.

    double obj_val = 0.0;

    for(size_t i = 0; i < Nlabels[0]; ++i)
      obj_val += DM2(i, LABELS1(i)); 

    return_val = obj_val;
    """

    addFunc('kmeansobj_dists_labels_double', 
            calccode_kmeansobj_dists_labels_code_double,
            ('dm', empty( (1,1), dtype=float64)),
            ('labels', empty(1, dtype=int32)) )

    addFunc('kmeansobj_dists_labels_float', 
            calccode_kmeansobj_dists_labels_code_double.replace('double', 'float'),
            ('dm', empty( (1,1), dtype=float32)),
            ('labels', empty(1, dtype=int32)) )

    # With only the distance matrix

    calccode_kmeansobj_dists_code_double = r"""

    // Takes the distance matrix dm and puts the point assignments into labels.

    double objval = 0;
    for(int i = 0; i < Ndm[0]; ++i)
    {
      double minval = DM2(i, 0);

      for(int j = 1; j < Ndm[1]; ++j)
      {
        if(DM2(i,j) < minval)
          minval = DM2(i,j);
      }
      objval += minval;
    }
    
    return_val = objval;
    """

    addFunc('kmeansobj_dists_double', 
            calccode_kmeansobj_dists_code_double,
            ('dm', empty( (1,1), dtype=float64)))

    addFunc('kmeansobj_dists_float', 
            calccode_kmeansobj_dists_code_double.replace('double', 'float'),
            ('dm', empty( (1,1), dtype=float32)))

    # Direct

    calccode_kmeansobj_direct_code_double = r"""

    // Takes dm 

    int K = Ncenters[0];
    int dim = Ncenters[1];
    int nP = Npts[0];

    double objval = 0;

    for(int i = 0; i < nP; ++i)
    {
       double minval = 0;

       for(int p = 0; p < dim; ++p)
       {
          double ddiff = (PTS2(i, p) - CENTERS2(0, p));
          minval += ddiff*ddiff;
       }

       for(int j = 1; j < K; ++j)
       {
         double d = 0;
          
         for(int p = 0; p < dim; ++p)
         {
           double ddiff = (PTS2(i, p) - CENTERS2(j, p));
           d += ddiff*ddiff;
         }

         if(d < minval) minval = d;
       }
       objval += minval;
    }

    return_val = objval;
    """
    
    
    addFunc('kmeansobj_direct_double_double', 
            calccode_kmeansobj_direct_code_double,
            ('pts', empty( (1,1), dtype=float64)),
            ('centers',empty( (1,1), dtype=float64)))

    addFunc('kmeansobj_direct_double_float', 
            calccode_kmeansobj_direct_code_double,
            ('pts', empty( (1,1), dtype=float64)),
            ('centers',empty( (1,1), dtype=float32)))

    addFunc('kmeansobj_direct_float_float', 
            calccode_kmeansobj_direct_code_double.replace('double', 'float'),
            ('pts', empty( (1,1), dtype=float32)),
            ('centers',empty( (1,1), dtype=float32)))


    ##########################################################################################
    # assignment_matrix_double

    calccode_assignment_matrix = r"""

    // Takes the label list and fills the absolute assignment matrix assignment_matrix

    for(int i = 0; i < Nlabels[0]; ++i)
      ASSIGNMENT_MATRIX2(i,LABELS1(i)) = 1;
    """

    addFunc('assignment_matrix_double', calccode_assignment_matrix,
            ('labels', empty(1, dtype=int32)),
            ('assignment_matrix', empty( (1,1), dtype = float64)) )

    addFunc('assignment_matrix_float', calccode_assignment_matrix,
            ('labels', empty(1, dtype=int32)),
            ('assignment_matrix', empty( (1,1), dtype = float32)) )

    addFunc('assignment_matrix_bool', calccode_assignment_matrix,
            ('labels', empty(1, dtype=int32)),
            ('assignment_matrix', empty( (1,1), dtype = bool_)) )

    
    ##########################################################################################
    # Now compile it
            
    utils_c_ext.compile()

if __name__ == '__main__':
    createUtilsC()
