require 'ffi'
require 'nmatrix'

require_relative "flann/version.rb"
require_relative "flann/index.rb"


module Flann
  extend FFI::Library
  ffi_lib "libflann"

  # Declare enumerators
  Algorithm   = enum(:linear, :kdtree, :kmeans, :composite, :kdtree_single, :saved, :autotuned)
  CentersInit = enum(:random, :gonzales, :kmeanspp)
  LogLevel    = enum(:none, :fatal, :error, :warn, :info)
  DistanceType = enum(:euclidean, :manhattan, :minkowski, :hist_intersect, :hellinger, :chi_square, :kullback_leibler)

  DEFAULT_PARAMETERS = [:kdtree,
                        32, 0.0,
                        0, -1, 0,
                        4, 4,
                        32, 11, :random, 0.2,
                        0.9, 0.01, 0, 0.1,
                        :none, 0
                       ]

  # For NMatrix compatibility
  typedef :float,  :float32
  typedef :double, :float64
  typedef :pointer, :index_params_ptr
  typedef :pointer, :index_ptr

  # A nearest neighbor search index for a given dataset.
  class Parameters < FFI::Struct
    layout :algorithm, Flann::Algorithm,    # The algorithm to use (linear, kdtree, kmeans, composite, kdtree_single, saved, autotuned)
           :checks, :int,                   # How many leaves (features) to use (for kdtree)
           :cluster_boundary_index, :float, # aka cb_tree, used when searching the kmeans tree
           :trees, :int,                    # Number of randomized trees to use (for kdtree)
           :branching, :int,                # Branching factor (for kmeans tree)
           :iterations, :int,               # Max iterations to perform in one kmeans clustering (kmeans tree)
           :centers_init, Flann::CentersInit, # Algorithm used (random, gonzales, kmeanspp)
           :target_precision, :float,       # Precision desired (used for auto-tuning, -1 otherwise)
           :build_weight, :float,           # Build tree time weighting factor
           :memory_weight, :float,          # Index memory weighting factor
           :sample_fraction, :float,        # What fraction of the dataset to use for autotuning

           :table_number, :uint,            # The number of hash tables to use
           :key_size, :uint,                # The length of the key to use in the hash tables
           :multi_probe_level, :uint,       # Number of levels to use in multi-probe LSH, 0 for standard LSH
           :log_level, Flann::LogLevel,     # Determines the verbosity of each flann function
           :random_seed, :long              # Random seed to use
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
    def allocate_results_space result_size #:nodoc:
      [FFI::MemoryPointer.new(:int, result_size), FFI::MemoryPointer.new(:float, result_size)]
    end


    # Don't know if these will be a hash, a static struct, or a pointer to a struct. Return the pointer and the struct.
    def handle_parameters parameters #:nodoc:
      parameters ||= DEFAULT_PARAMETERS unless block_given?

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
    # If no index parameters are given, FLANN_DEFAULT_PARAMETERS are used. A block is accepted as well.
    def nearest_neighbors dataset, testset, k, parameters: DEFAULT_PARAMETERS
      # Get a pointer and a struct regardless of how the arguments are supplied.
      parameters_ptr, parameters = handle_parameters(parameters)
      result_size = testset.shape[0] * k
      indices_int_ptr, distances_float_ptr = allocate_results_space(result_size)

      Flann.flann_find_nearest_neighbors FFI::Pointer.new_from_nmatrix(dataset), dataset.shape[0], dataset.shape[1],
                                         FFI::Pointer.new_from_nmatrix(testset), testset.shape[0],
                                         indices_int_ptr, distances_float_ptr, k, parameters_ptr

      # Return results: two arrays, one of indices and one of distances.
      [indices_int_ptr.read_array_of_int(result_size), distances_float_ptr.read_array_of_float(result_size)]
    end
    alias :nn :nearest_neighbors

    # Set the distance function to use when computing distances between data points.
    def set_distance_type! distance_function, order = 0
      Flann.send(:flann_set_distance_type, distance_function, order)
      self
    end

    # Perform hierarchical clustering of a set of points.
    def cluster dataset, clusters, parameters: DEFAULT_PARAMETERS
      c_method = "flann_compute_cluster_centers_#{Flann::dtype_to_c(dataset.dtype)}".to_sym

      result = dataset.clone_structure
      parameters_ptr, parameters = handle_parameters(parameters)
      Flann.send(c_method, FFI::Pointer.new_from_nmatrix(dataset), dataset.shape[0], dataset.shape[1], clusters, FFI::Pointer.new_from_nmatrix(result), parameters_ptr)

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
  attach_function :flann_find_nearest_neighbors_index, [:index_ptr, :pointer, :int, :pointer, :pointer, :int, :index_params_ptr], :int

  # dataset, rows, cols, testset, trows, indices, dists, nn, flann_params
  attach_function :flann_find_nearest_neighbors, [:pointer, :int, :int, :pointer, :int, :pointer, :pointer, :int, :index_params_ptr], :int

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

  attach_function :flann_set_distance_type, [DistanceType, :int], :void

  attach_function :flann_compute_cluster_centers_byte,    [:pointer, :int, :int, :int, :pointer, :index_params_ptr], :int
  attach_function :flann_compute_cluster_centers_int,     [:pointer, :int, :int, :int, :pointer, :index_params_ptr], :int
  attach_function :flann_compute_cluster_centers_float,   [:pointer, :int, :int, :int, :pointer, :index_params_ptr], :int
  attach_function :flann_compute_cluster_centers_double,  [:pointer, :int, :int, :int, :pointer, :index_params_ptr], :int

end
