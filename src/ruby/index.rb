module Flann
  # A nearest neighbor search index for a given dataset.
  class Index

    DEFAULTS =
    {:algorithm => :linear,         # The algorithm to use (linear, kdtree, kmeans, composite, kdtree_single, saved, autotuned)

     # Search parameters
     :checks => 64,                 # How many leaves (features) to use (for kdtree)
     :cluster_boundary_index => 0.0,# aka cb_tree, used when searching the kmeans tree

     # kdtree index parameters
     :trees => 4,                   # Number of randomized trees to use (for kdtree)

     # kmeans index parameters
     :branching => 32,              # Branching factor (for kmeans tree)
     :iterations => 11,             # Max iterations to perform in one kmeans clustering (kmeans tree)
     :centers_init => :random,      # Algorithm used (random, gonzales, kmeanspp)

     # Autotuned index parameters
     :target_precision => 1.0,      # Precision desired (used for auto-tuning, -1 otherwise)
     :build_weight => 1.0,          # Build tree time weighting factor
     :memory_weight => 1.0,         # Index memory weighting factor
     :sample_fraction => 1.0,       # What fraction of the dataset to use for autotuning

     # LSH parameters
     :table_number => 12,           # The number of hash tables to use
     :key_size => 20,               # The length of the key to use in the hash tables
     :multi_probe_level => 0,       # Number of levels to use in multi-probe LSH, 0 for standard LSH

    # Other parameters
     :log_level => :none,           # Determines the verbosity of each flann function
     :random_seed => nil            # Random seed to use
    }

    # This creates a bunch of getter and setter functions without any error checking. They can be overridden with
    # regular methods which do include some kind of error checking.
    DEFAULTS.each_pair do |key,value|
      self.class_eval <<EVAL

    def #{key}= val
      @parameters[:#{key}] = val
    end

    def #{key}
      @parameters.has_key?(:#{key}) ? @parameters[:#{key}] : DEFAULTS[:#{key}]
    end

EVAL
    end


    # Constructor takes a block where we set each of the parameters.
    def initialize distance, dataset: nil, dtype: :float64
      @dataset    = dataset
      @dtype      = (!dataset.nil? && dataset.is_a?(NMatrix)) ? dataset.dtype : dtype
      @parameters = {}
      yield self if block_given?
    end
    attr_reader :dtype, :dataset

    def build_index
      c_method = "flann_build_index_#{Flann::DTYPE_TO_FLANN[dtype]}".to_sym

      speedup_float_ptr = FFI::MemoryPointer.new(:pointer, 4)

      @index_ptr = Flann.send(c_method, @dataset.data_pointer, @dataset.shape[0], @dataset.shape[1], speedup_float_ptr)

      # Return the speedup
      speedup_float_ptr.read_float
    end

    class << self
    end
  end
end