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

class FFI::Pointer
  class << self
    def new_from_nmatrix nm
      raise(StorageError, "dense storage expected") unless nm.dense?
      c_type = Flann::dtype_to_c(nm.dtype)
      c_type = :uchar if c_type == :byte
      ::FFI::Pointer.new(c_type, nm.data_pointer).tap { |p| p.autorelease = false }
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
    def initialize index_dataset = nil, dtype: :float64, parameters: Flann::Parameters::DEFAULT
      @dataset        = index_dataset
      #require 'pry'
      #binding.pry if @dataset.nil?
      @dtype          = (!index_dataset.nil? && index_dataset.is_a?(NMatrix)) ? index_dataset.dtype : dtype
      @index_ptr      = nil

      @parameters_ptr, @parameters = Flann::handle_parameters(parameters)

      yield @parameters if block_given?
    end
    attr_reader :dtype, :dataset, :parameters, :parameters_ptr, :index_ptr

    # Assign a new dataset. Requires that the old index be freed.
    def dataset= index_dataset
      free!
      @dataset = index_dataset
    end

    # Build an index
    def build!
      raise("no dataset specified") if dataset.nil?
      c_type   = Flann::dtype_to_c(dtype)
      c_method = "flann_build_index_#{c_type}".to_sym
      speedup_float_ptr = FFI::MemoryPointer.new(:float)
      @index_ptr = Flann.send(c_method, FFI::Pointer.new_from_nmatrix(dataset), dataset.shape[0], dataset.shape[1], speedup_float_ptr, parameters_ptr)
      if index_ptr.address == 0
        require 'pry'
        binding.pry
        raise("failed to allocate index_ptr")
      end


      # Return the speedup
      speedup_float_ptr.read_float
    end

    # Get the nearest neighbors based on this index. Forces a build of the index if one hasn't been done yet.
    def nearest_neighbors testset, k, parameters = {}
      parameters = Parameters.new(Flann::Parameters::DEFAULT.merge(parameters))

      self.build! if index_ptr.nil?

      parameters_ptr, parameters = Flann::handle_parameters(parameters)
      result_size = testset.shape[0] * k

      c_type = Flann::dtype_to_c(dataset.dtype)
      c_method = "flann_find_nearest_neighbors_index_#{c_type}".to_sym
      indices_int_ptr, distances_t_ptr = Flann::allocate_results_space(result_size, c_type)

      Flann.send c_method, index_ptr,
                           FFI::Pointer.new_from_nmatrix(testset),
                           testset.shape[0],
                           indices_int_ptr, distances_t_ptr,
                           k,
                           parameters_ptr


      [indices_int_ptr.read_array_of_int(result_size),
       c_type == :double ? distances_t_ptr.read_array_of_double(result_size) : distances_t_ptr.read_array_of_float(result_size)]
    end

    # Perform a radius search on a single query point
    def radius_search query, radius, max_k=nil, parameters = {}
      max_k    ||= dataset.shape[0]
      parameters = Parameters.new(Flann::Parameters::DEFAULT.merge(parameters))

      self.build! if index_ptr.nil?
      parameters_ptr, parameters = Flann::handle_parameters(parameters)

      c_type = Flann::dtype_to_c(dataset.dtype)
      c_method = "flann_radius_search_#{c_type}".to_sym
      indices_int_ptr, distances_t_ptr = Flann::allocate_results_space(max_k, c_type)

      Flann.send(c_method, index_ptr, FFI::Pointer.new_from_nmatrix(query), indices_int_ptr, distances_t_ptr, max_k, radius, parameters_ptr)

      # Return results: two arrays, one of indices and one of distances.
      indices   = indices_int_ptr.read_array_of_int(max_k)
      distances = c_type == :double ? distances_t_ptr.read_array_of_double(max_k) : distances_t_ptr.read_array_of_float(max_k)

      # Stop where indices == -1
      cutoff = indices.find_index(-1)
      cutoff.nil? ? [indices, distances] : [indices[0...cutoff], distances[0...cutoff]]
    end

    # Save an index to a file (without the dataset).
    def save filename
      raise(IOError, "Cannot write an unbuilt index") if index_ptr.nil?     # FIXME: This should probably have its own exception type.
      c_method = "flann_save_index_#{Flann::dtype_to_c(dtype)}".to_sym
      Flann.send(c_method, index_ptr, filename)
      self
    end

    # Load an index from a file (with the dataset already known!).
    #
    # FIXME: This needs to free the previous dataset first.
    def load! filename
      c_method = "flann_load_index_#{Flann::dtype_to_c(dtype)}".to_sym

      @index_ptr = Flann.send(c_method, filename, FFI::Pointer.new_from_nmatrix(dataset), dataset.shape[0], dataset.shape[1])
      self
    end

    # Free an index
    def free! parameters = {}
      parameters = Parameters.new(Flann::Parameters::DEFAULT.merge(parameters))
      c_method = "flann_free_index_#{Flann::dtype_to_c(dtype)}".to_sym
      parameters_ptr, parameters = Flann::handle_parameters(parameters)
      Flann.send(c_method, index_ptr, parameters_ptr)
      @index_ptr = nil
      self
    end

  end
end