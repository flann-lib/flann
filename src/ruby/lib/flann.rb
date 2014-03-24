# Copyright 2014 John O. Woods (john.o.woods@gmail.com), West Virginia
#   University's Applied Space Exploration Lab, and West Virginia Robotic
#   Technology Center. All rights reserved.
#
# THE BSD LICENSE
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'ffi'
require 'nmatrix'

require_relative "flann/version.rb"
require_relative "flann/index.rb"


module Flann
  extend FFI::Library
  ffi_lib "libflann"

  # Declare enumerators
  Algorithm    = enum(:algorithm, [:linear, :kdtree, :kmeans, :composite, :kdtree_single, :hierarchical, :lsh, :kdtree_cuda, :saved, 254, :autotuned, 255])
  CentersInit  = enum(:centers_init, [:random, :gonzales, :kmeanspp])
  LogLevel     = enum(:log_level, [:none, :fatal, :error, :warn, :info, :debug])

  # Note that Hamming and beyond are not supported in the C API. We include them here just in case of future improvements.
  DistanceType = enum(:distance_type, [:undefined, :euclidean, :l2, :manhattan, :l1, :minkowski, :max, :hist_intersect, :hellinger, :chi_square, :kullback_leibler, :hamming, :hamming_lut, :hamming_popcnt, :l2_simple])

  # For NMatrix compatibility
  typedef :float,   :float32
  typedef :double,  :float64
  typedef :char,    :byte
  typedef :pointer, :index_params_ptr
  typedef :pointer, :index_ptr


  class InitializableStruct < FFI::Struct
    def initialize pointer=nil, *layout, &block
      if pointer.respond_to?(:each_pair)
        options = pointer
        pointer = nil
      else
        options
      end

      super(pointer, *layout, &block)

      if defined?(self.class::DEFAULTS)
        options = self.class::DEFAULTS.merge(options)
      end

      options.each_pair do |key, value|
        self[key] = value
      end unless options.nil?
    end
  end


  # A nearest neighbor search index for a given dataset.
  class Parameters < InitializableStruct
    layout :algorithm, Flann::Algorithm,    # The algorithm to use (linear, kdtree, kmeans, composite, kdtree_single, saved, autotuned)
           :checks, :int,                   # How many leaves (features) to use (for kdtree)
           :eps, :float,                    # eps parameter for eps-knn search
           :sorted, :int,                   # indicates if results returned by radius search should be sorted or not
           :max_neighbors, :int,            # limits the maximum number of neighbors returned
           :cores, :int,                    # number of parallel cores to use for searching

           :trees, :int,                    # Number of randomized trees to use (for kdtree)
           :leaf_max_size, :int,            # ?

           :branching, :int,                # Branching factor (for kmeans tree)
           :iterations, :int,               # Max iterations to perform in one kmeans clustering (kmeans tree)
           :centers_init, Flann::CentersInit, # Algorithm used (random, gonzales, kmeanspp)
           :cluster_boundary_index, :float, # Cluster boundary index. Used when searching the kmeans tree

           :target_precision, :float,       # Precision desired (used for auto-tuning, -1 otherwise)
           :build_weight, :float,           # Build tree time weighting factor
           :memory_weight, :float,          # Index memory weighting factor
           :sample_fraction, :float,        # What fraction of the dataset to use for autotuning

           :table_number, :uint,            # The number of hash tables to use
           :key_size, :uint,                # The length of the key to use in the hash tables
           :multi_probe_level, :uint,       # Number of levels to use in multi-probe LSH, 0 for standard LSH

           :log_level, Flann::LogLevel,     # Determines the verbosity of each flann function
           :random_seed, :long              # Random seed to use

    DEFAULT       = {algorithm: :kdtree,
                     checks: 32, eps: 0.0,
                     sorted: 1, max_neighbors: -1, cores: 0,
                     trees: 1, leaf_max_size: 4,
                     branching: 32, iterations: 5,
                     centers_init: :random,
                     cluster_boundary_index: 0.5,
                     target_precision: 0.9,
                     build_weight: 0.01,
                     memory_weight: 0.0,
                     sample_fraction: 0.1,
                     table_number: 12,
                     key_size: 20,
                     multi_probe_level: 2,
                     log_level: :warn, random_seed: -1}


  end

  class << self


    DTYPE_TO_C = {:float32 => :float, :float64 => :double, :int32 => :int, :byte => :byte, :int8 => :byte}

    def dtype_to_c d #:nodoc:
      return DTYPE_TO_C[d] if DTYPE_TO_C.has_key?(d)
      raise(NMatrix::DataTypeError, "FLANN does not support this dtype")
    end


    # Allocates index space and distance space for storing results from various searches. For a k-nearest neighbors
    # search, for example, you want trows (the number of rows in the testset) times k (the number of nearest neighbors
    # being searched for).
    #
    # Note that c_type will produce float for everything except double, which produces double.
    def allocate_results_space result_size, c_type #:nodoc:
      [FFI::MemoryPointer.new(:int, result_size), FFI::MemoryPointer.new(c_type == :double ? :double : :float, result_size)]
    end


    # Don't know if these will be a hash, a static struct, or a pointer to a struct. Return the pointer and the struct.
    def handle_parameters parameters #:nodoc:
      parameters ||= Parameters::DEFAULT unless block_given?

      if parameters.is_a?(FFI::MemoryPointer) # User supplies us with the necessary parameters already in the correct form.
        c_parameters_ptr = parameters
        c_parameters = Flann::Parameters.new(c_parameters_ptr)
      elsif parameters.is_a?(Flann::Parameters)
        c_parameters = parameters
        c_parameters_ptr = parameters.pointer
      else
        # Set the old fasioned way
        c_parameters_ptr = FFI::MemoryPointer.new(Flann::Parameters.size)
        c_parameters = Flann::Parameters.new(c_parameters_ptr)
        if parameters.is_a?(Hash)
          parameters.each_pair do |key, value|
            c_parameters[key] = value
          end
        end
      end

      # There may also be a block.
      yield c_parameters if block_given?

      [c_parameters_ptr, c_parameters]
    end


    # Find the k nearest neighbors.
    #
    # If no index parameters are given, FLANN_Parameters::DEFAULT are used. A block is accepted as well.
    def nearest_neighbors dataset, testset, k, parameters = {}
      parameters = Parameters.new(Flann::Parameters::DEFAULT.merge(parameters))
      # Get a pointer and a struct regardless of how the arguments are supplied.
      parameters_ptr, parameters = handle_parameters(parameters)
      result_size = testset.shape[0] * k

      c_type = Flann::dtype_to_c(dataset.dtype)
      c_method = "flann_find_nearest_neighbors_#{c_type}".to_sym
      indices_int_ptr, distances_t_ptr = allocate_results_space(result_size, c_type)

      # dataset, rows, cols, testset, trows, indices, dists, nn, flann_params
      Flann.send c_method,   FFI::Pointer.new_from_nmatrix(dataset), dataset.shape[0], dataset.shape[1],
                             FFI::Pointer.new_from_nmatrix(testset), testset.shape[0],
                             indices_int_ptr, distances_t_ptr, k, parameters_ptr

      # Return results: two arrays, one of indices and one of distances.
      [indices_int_ptr.read_array_of_int(result_size),
       c_type == :double ? distances_t_ptr.read_array_of_double(result_size) : distances_t_ptr.read_array_of_float(result_size)]
    end
    alias :nn :nearest_neighbors

    # Set the distance function to use when computing distances between data points.
    def set_distance_type! distance_function
      Flann.send(:flann_set_distance_type, distance_function, get_distance_order)
      self
    end
    alias :set_distance_type_and_order! :set_distance_type!

    # Get the distance type and order
    def get_distance_type_and_order
      [Flann.flann_get_distance_type, Flann.flann_get_distance_order]
    end
    def get_distance_type
      Flann.flann_get_distance_type
    end
    def get_distance_order
      Flann.flann_get_distance_order
    end
    alias :distance_type :get_distance_type
    alias :distance_order :get_distance_order


    # Perform hierarchical clustering of a set of points.
    #
    # Arguments:
    # * dataset: NMatrix of points
    # * parameters:
    def cluster dataset, clusters, parameters = {}
      parameters = Parameters.new(Flann::Parameters::DEFAULT.merge(parameters))
      c_method = "flann_compute_cluster_centers_#{Flann::dtype_to_c(dataset.dtype)}".to_sym

      result = dataset.clone_structure
      parameters_ptr, parameters = handle_parameters(parameters)

      #err_code =
      Flann.send(c_method, FFI::Pointer.new_from_nmatrix(dataset), dataset.shape[0], dataset.shape[1], clusters, FFI::Pointer.new_from_nmatrix(result), parameters_ptr)
      #raise("unknown error in cluster") if err_code < 0

      result
    end
    alias :compute_cluster_centers :cluster
  end


protected

  # byte: unsigned char*dataset, int rows, int cols, float* speedup, FLANNParameters* flann_params
  # only thing that changes is the pointer type for the first arg.
  attach_function :flann_build_index_byte,   [:pointer, :int, :int, :pointer, :index_params_ptr], :index_ptr
  attach_function :flann_build_index_int,    [:pointer, :int, :int, :pointer, :index_params_ptr], :index_ptr
  attach_function :flann_build_index_float,  [:pointer, :int, :int, :pointer, :index_params_ptr], :index_ptr
  attach_function :flann_build_index_double, [:pointer, :int, :int, :pointer, :index_params_ptr], :index_ptr

  # index, testset, trows, indices, dists, nn, flann_params
  attach_function :flann_find_nearest_neighbors_index_byte,   [:index_ptr, :pointer, :int, :pointer, :pointer, :int, :index_params_ptr], :int
  attach_function :flann_find_nearest_neighbors_index_int,    [:index_ptr, :pointer, :int, :pointer, :pointer, :int, :index_params_ptr], :int
  attach_function :flann_find_nearest_neighbors_index_float,  [:index_ptr, :pointer, :int, :pointer, :pointer, :int, :index_params_ptr], :int
  attach_function :flann_find_nearest_neighbors_index_double, [:index_ptr, :pointer, :int, :pointer, :pointer, :int, :index_params_ptr], :int

  # dataset, rows, cols, testset, trows, indices, dists, nn, flann_params
  attach_function :flann_find_nearest_neighbors_byte,   [:pointer, :int, :int, :pointer, :int, :pointer, :pointer, :int, :index_params_ptr], :int
  attach_function :flann_find_nearest_neighbors_int,    [:pointer, :int, :int, :pointer, :int, :pointer, :pointer, :int, :index_params_ptr], :int
  attach_function :flann_find_nearest_neighbors_float,  [:pointer, :int, :int, :pointer, :int, :pointer, :pointer, :int, :index_params_ptr], :int
  attach_function :flann_find_nearest_neighbors_double, [:pointer, :int, :int, :pointer, :int, :pointer, :pointer, :int, :index_params_ptr], :int

  # index, query point, result indices, result distances, max_nn, radius, flann_params
  attach_function :flann_radius_search_byte,   [:index_ptr, :pointer, :pointer, :pointer, :int, :float, :index_params_ptr], :int
  attach_function :flann_radius_search_int,    [:index_ptr, :pointer, :pointer, :pointer, :int, :float, :index_params_ptr], :int
  attach_function :flann_radius_search_float,  [:index_ptr, :pointer, :pointer, :pointer, :int, :float, :index_params_ptr], :int
  attach_function :flann_radius_search_double, [:index_ptr, :pointer, :pointer, :pointer, :int, :float, :index_params_ptr], :int

  attach_function :flann_save_index_byte,   [:index_ptr, :string], :int
  attach_function :flann_save_index_int,    [:index_ptr, :string], :int
  attach_function :flann_save_index_float,  [:index_ptr, :string], :int
  attach_function :flann_save_index_double, [:index_ptr, :string], :int

  attach_function :flann_load_index_byte,   [:string, :pointer, :int, :int], :index_ptr
  attach_function :flann_load_index_int,    [:string, :pointer, :int, :int], :index_ptr
  attach_function :flann_load_index_float,  [:string, :pointer, :int, :int], :index_ptr
  attach_function :flann_load_index_double, [:string, :pointer, :int, :int], :index_ptr

  attach_function :flann_free_index_byte,   [:index_ptr, :index_params_ptr], :int
  attach_function :flann_free_index_int,    [:index_ptr, :index_params_ptr], :int
  attach_function :flann_free_index_float,  [:index_ptr, :index_params_ptr], :int
  attach_function :flann_free_index_double, [:index_ptr, :index_params_ptr], :int

  attach_function :flann_set_distance_type, [:distance_type, :int], :void

  attach_function :flann_get_distance_type, [], :distance_type
  attach_function :flann_get_distance_order, [], :int

  attach_function :flann_compute_cluster_centers_byte,    [:pointer, :int, :int, :int, :pointer, :index_params_ptr], :int
  attach_function :flann_compute_cluster_centers_int,     [:pointer, :int, :int, :int, :pointer, :index_params_ptr], :int
  attach_function :flann_compute_cluster_centers_float,   [:pointer, :int, :int, :int, :pointer, :index_params_ptr], :int
  attach_function :flann_compute_cluster_centers_double,  [:pointer, :int, :int, :int, :pointer, :index_params_ptr], :int

end
