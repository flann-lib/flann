class FFI::Pointer
  class << self
    def new_from_nmatrix nm
      ::FFI::Pointer.new(nm.data_pointer).tap { |p| p.autorelease = false }
    end
  end
end

module Flann
  class Index

    # Constructor takes a block where we set each of the parameters. We need to be careful to do this since
    # we're using the C API and not C++; so everything important needs to be initialized or there could be
    # a segfault. For reasonable default definitions, see:
    #
    # * https://github.com/mariusmuja/flann/tree/master/src/cpp/flann/algorithms
    #
    def initialize dataset: nil, dtype: :float64, parameters: Flann::DEFAULT_PARAMETERS
      @dataset        = dataset
      @dtype          = (!dataset.nil? && dataset.is_a?(NMatrix)) ? dataset.dtype : dtype
      @index_ptr      = nil

      @parameters_ptr, @parameters = Flann::handle_parameters(parameters)

      yield @parameters if block_given?
    end
    attr_reader :dtype, :dataset, :parameters, :parameters_ptr, :index_ptr

    # Build an index
    def build!
      raise("no dataset specified") if @dataset.nil?

      c_method = "flann_build_index_#{Flann::dtype_to_c(dtype)}".to_sym
      speedup_float_ptr = FFI::MemoryPointer.new(:float)
      @index_ptr = Flann.send(c_method, FFI::Pointer.new_from_nmatrix(@dataset), @dataset.shape[0], @dataset.shape[1], speedup_float_ptr, parameters_ptr)

      # Return the speedup
      speedup_float_ptr.read_float
    end

    # Get the nearest neighbors based on this index. Forces a build of the index if one hasn't been done yet.
    def nearest_neighbors testset, k, parameters: DEFAULT_PARAMETERS
      self.build! if index_ptr.nil?
      Flann::nearest_neighbors_by_index index_ptr, testset, k, parameters: parameters
    end

    # Perform a radius search on a single query point
    def radius_search query, radius, max_k: dataset.shape[1], parameters: DEFAULT_PARAMETERS
      self.build! if index_ptr.nil?
      parameters_ptr, parameters = handle_parameters(parameters)
      indices_int_ptr, distances_float_ptr = allocate_results_space(max_k)

      c_method = "flann_radius_search_#{Flann::dtype_to_c(dtype)}".to_sym
      Flann.send(c_method, FFI::Pointer.new_from_nmatrix(query), indices_int_ptr, distances_float_ptr, max_k, radius, parameters_ptr)

      # Return results: two arrays, one of indices and one of distances.
      [indices_int_ptr.read_array_of_int(result_size), distances_float_ptr.read_array_of_float(result_size)]
    end

    # Save an index to a file (without the dataset).
    def save filename
      raise(IOError, "Cannot write an unbuilt index") if self.index_ptr.nil?
      c_filename = FFI::MemoryPointer.from_string(filename)
      c_method = "flann_save_index_#{Flann::dtype_to_c(dtype)}".to_sym
      Flann.send(c_method, c_filename)
      self
    end

    # Load an index from a file (with the dataset already known!).
    #
    # FIXME: This needs to free the previous dataset first.
    def load! filename
      c_filename = FFI::MemoryPointer.from_string(filename)
      c_method = "flann_load_index_#{Flann::dtype_to_c(dtype)}".to_sym

      @index_ptr = Flann.send(c_method, c_filename, FFI::Pointer.new_from_nmatrix(@dataset), @dataset.shape[0], @dataset.shape[1])
      self
    end

    # Free an index
    def free! parameters = DEFAULT_PARAMETERS
      c_method = "flann_free_index_#{Flann::dtype_to_c(dtype)}".to_sym
      parameters_ptr, parameters = handle_parameters(parameters)
      Flann.send(c_method, @index_ptr, parameters_ptr)
      @index_ptr = nil
      self
    end

  end
end