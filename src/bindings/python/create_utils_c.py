#!/usr/bin/python

# This code compiles the utils_c module for the pyflann extension.

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
    utils_c_ext.customize.add_header('<vector>')
    utils_c_ext.customize.add_header('<set>')
    utils_c_ext.customize.add_header('<algorithm>')


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

    size_t K = Ncenters[0];
    size_t dim = Ncenters[1];
    size_t nP = Npts[0];

    for(size_t i = 0; i < nP; ++i)
    {
       for(size_t j = 0; j < K; ++j)
       {
          DM2(i, j) = 0;

          for(size_t p = 0; p < dim; ++p)
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

    for(size_t i = 0; i < Ndm[0]; ++i)
    {
      double minval = DM2(i, 0);
      LABELS1(i) = 0;
 
      for(size_t j = 1; j < Ndm[1]; ++j)
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

    for(size_t i = 0; i < nP; ++i)
    {
       double best_so_far = 0;
       LABELS1(i) = 0;

       for(size_t p = 0; p < dim; ++p)
       {
          double ddiff = (PTS2(i, p) - CENTERS2(0, p));
          best_so_far += ddiff*ddiff;
       }

       for(size_t j = 1; j < K; ++j)
       {
         double d = 0;
          
         for(size_t p = 0; p < dim; ++p)
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
    for(size_t i = 0; i < Ndm[0]; ++i)
    {
      double minval = DM2(i, 0);

      for(size_t j = 1; j < Ndm[1]; ++j)
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

    size_t K = Ncenters[0];
    size_t dim = Ncenters[1];
    size_t nP = Npts[0];

    double objval = 0;

    for(size_t i = 0; i < nP; ++i)
    {
       double minval = 0;

       for(size_t p = 0; p < dim; ++p)
       {
          double ddiff = (PTS2(i, p) - CENTERS2(0, p));
          minval += ddiff*ddiff;
       }

       for(size_t j = 1; j < K; ++j)
       {
         double d = 0;
          
         for(size_t p = 0; p < dim; ++p)
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

    for(size_t i = 0; i < Nlabels[0]; ++i)
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
    # calculates the size of the clusters.
    
    calccode_cluster_sizes_direct = r"""
    
    // Takes centers and  pts (2-d), puts counts into counts (type uint32)

    size_t K = Ncenters[0];
    size_t dim = Ncenters[1];
    size_t nP = Npts[0];

    std::fill(counts, counts + K, 0);

    for(size_t i = 0; i < nP; ++i)
    {
       double best_dist = 0;
       size_t best_so_far = 0;

       for(size_t p = 0; p < dim; ++p)
       {
         double ddiff = (PTS2(i, p) - CENTERS2(0, p));
         best_dist += ddiff*ddiff;
       }
       
       for(size_t j = 1; j < K; ++j)
       {
          double cur_dist = 0;

          for(size_t p = 0; p < dim; ++p)
          {
            double ddiff = (PTS2(i, p) - CENTERS2(j, p));
            cur_dist += ddiff*ddiff;
          }
         
          if(cur_dist < best_dist) 
          {
             best_dist = cur_dist;
             best_so_far = j;
          }
       }

       ++counts[best_so_far];
    }
    """

    addFunc('cluster_sizes_direct_double_double', calccode_cluster_sizes_direct,
            ('pts', empty( (1,1), dtype=float64)),
            ('centers', empty( (1,1), dtype=float64)),
            ('counts', empty(1, dtype=uint32)))

    addFunc('cluster_sizes_direct_double_float', calccode_cluster_sizes_direct,
            ('pts', empty( (1,1), dtype=float64)),
            ('centers', empty( (1,1), dtype=float32)),
            ('counts', empty(1, dtype=uint32)))

    addFunc('cluster_sizes_direct_float_float', 
            calccode_cluster_sizes_direct.replace('double', 'float'),
            ('pts', empty( (1,1), dtype=float32)),
            ('centers', empty( (1,1), dtype=float32)),
            ('counts', empty(1, dtype=uint32)))


    calccode_cluster_sizes_dists = r"""

    // Takes the distance matrix dm and counts the number of points
    // per cluster (given in counts).
   
    size_t K = Ndm[1];

    std::fill(counts, counts + K, 0);

    for(size_t i = 0; i < Ndm[0]; ++i)
    {
      double minval = DM2(i, 0);
      size_t best = 0;
 
      for(size_t j = 1; j < K; ++j)
      {
        if(DM2(i,j) < minval)
        {
          best = j;
          minval = DM2(i,j);
        }
      }
      ++counts[best];
    }

    """

    addFunc('cluster_sizes_dists_double', 
            calccode_cluster_sizes_dists,
            ('dm', empty( (1,1), dtype=float64)),
            ('counts', empty(1, dtype=uint32)))

    addFunc('cluster_sizes_dists_float', 
            calccode_cluster_sizes_dists.replace('double', 'float'),
            ('dm', empty( (1,1), dtype=float32)),
            ('counts', empty(1, dtype=uint32)))


    calccode_cluster_sizes_labels = r"""
    
    // Assume we have K passed as a parameter.

    std::fill(counts, counts + Ncounts[0], 0);
    
    for(size_t i = 0; i < Nlabels[0]; ++i)
      ++counts[labels[i]];

    """

    addFunc('cluster_sizes_labels', 
            calccode_cluster_sizes_labels,
            ('labels', empty(1, dtype=int32)),
            ('counts', empty(1, dtype=uint32)))

    
    ################################################################################
    # Now all the stuff about cluster completeness

    calccode_cluster_completeness_direct = r"""
    
    // Takes centers and pts (2-d), returns true if all the clusters
    // are nonempty.

    size_t K = Ncenters[0];
    size_t dim = Ncenters[1];
    size_t nP = Npts[0];

    static std::vector<bool> hit;
    hit.resize(K);
    std::fill(hit.begin(), hit.end(), false);

    static std::vector<size_t> set_constructor(0);
      
    if(set_constructor.size() < K)
      {
         set_constructor.reserve(K);
         for(size_t i = set_constructor.size(); i < K; ++i)
            set_constructor.push_back(i);
      }

    std::set<size_t> empty_clusters(set_constructor.begin(), set_constructor.begin()+K);

    return_val = true;

    for(size_t i = 0; i < nP; ++i)
    {
       double best_dist = 0;
       size_t best_so_far = 0;

       for(size_t p = 0; p < dim; ++p)
       {
         double ddiff = (PTS2(i, p) - CENTERS2(0, p));
         best_dist += ddiff*ddiff;
       }
       
       for(size_t j = 1; j < K; ++j)
       {
          double cur_dist = 0;

          for(size_t p = 0; p < dim; ++p)
          {
            double ddiff = (PTS2(i, p) - CENTERS2(j, p));
            cur_dist += ddiff*ddiff;
          }
         
          if(cur_dist < best_dist) 
          {
             best_dist = cur_dist;
             best_so_far = j;
          }
       }

       if(!hit[best_so_far])
       {
          hit[best_so_far] = true;
          empty_clusters.erase(best_so_far);
          
          if(empty_clusters.empty())
          {
             return_val = false;
             break;
          }
       }
    }
    """

    addFunc('cluster_completeness_direct_double_double', 
            calccode_cluster_completeness_direct,
            ('pts', empty( (1,1), dtype=float64)),
            ('centers', empty( (1,1), dtype=float64)))

    addFunc('cluster_completeness_direct_double_float', 
            calccode_cluster_completeness_direct,
            ('pts', empty( (1,1), dtype=float64)),
            ('centers', empty( (1,1), dtype=float32)))

    addFunc('cluster_completeness_direct_float_float', 
            calccode_cluster_completeness_direct.replace('double', 'float'),
            ('pts', empty( (1,1), dtype=float32)),
            ('centers', empty( (1,1), dtype=float32)))


    calccode_cluster_completeness_dists = r"""

    // Takes the distance matrix dm and counts the number of points
    // per cluster (given in counts).
   
    size_t K = Ndm[1];

    static std::vector<bool> hit;
    hit.resize(K);
    std::fill(hit.begin(), hit.end(), false);
    
    static std::vector<size_t> set_constructor(0);
    if(set_constructor.size() < K)
      {
         set_constructor.reserve(K);
         for(size_t i = set_constructor.size(); i < K; ++i)
            set_constructor.push_back(i);
      }

    std::set<size_t> empty_clusters(set_constructor.begin(), set_constructor.begin()+K);

    return_val = true;

    for(size_t i = 0; i < Ndm[0]; ++i)
    {
      double minval = DM2(i, 0);
      size_t best = 0;
 
      for(size_t j = 1; j < K; ++j)
      {
        if(DM2(i,j) < minval)
        {
          best = j;
          minval = DM2(i,j);
        }
      }
      
       if(!hit[best])
       {
          hit[best] = true;
          empty_clusters.erase(best);
          
          if(empty_clusters.empty())
          {
             return_val = false;
             break;
          }
       }
    }

    """

    addFunc('cluster_completeness_dists_double', 
            calccode_cluster_completeness_dists,
            ('dm', empty( (1,1), dtype=float64)))

    addFunc('cluster_completeness_dists_float', 
            calccode_cluster_completeness_dists.replace('double', 'float'),
            ('dm', empty( (1,1), dtype=float32)))

    
    calccode_cluster_completeness_labels = r"""
    
    // Assume we have K passed as a parameter.
    size_t N = Nlabels[0];
    size_t K = int(Kgiven);

    static std::vector<bool> hit;
    hit.resize(K);
    std::fill(hit.begin(), hit.end(), false);
    
    static std::vector<size_t> set_constructor(0);
    if(set_constructor.size() < K)
      {
         set_constructor.reserve(K);
         for(size_t i = set_constructor.size(); i < K; ++i)
            set_constructor.push_back(i);
      }

    std::set<size_t> empty_clusters(set_constructor.begin(), set_constructor.begin()+K);

    return_val = true;
    
    for(size_t i = 0; i < N; ++i)
    { 
      size_t k = labels[i];

      if(!hit[k])
      {
         hit[k] = true;
         empty_clusters.erase(k);

         if(empty_clusters.empty())
         {
            return_val = false;
            break;
         }
      }
    }

    """

    addFunc('cluster_completeness_labels', 
            calccode_cluster_completeness_labels,
            ('labels', empty(1, dtype=int32)),
            ('Kgiven', uint(0)))

    calccode_cluster_completeness_counts = r"""
    
    return_val = false;

    for(size_t i = 0; i < Ncounts[0]; ++i)
    {
       if(counts[i] == 0)
       {
         return_val = true;
         break;
       }
    }
    """

    addFunc('cluster_completeness_counts', 
            calccode_cluster_completeness_counts,
            ('counts', empty(1, dtype=uint32)))
    ##########################################################################################
    # Now compile it
            
    utils_c_ext.compile()

if __name__ == '__main__':
    createUtilsC()
