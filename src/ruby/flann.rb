require 'ffi'
require 'nmatrix'

require "./index.rb"

module Flann
  extend FFI::Library
  ffi_lib "libflann"

  # Some of these may not work properly. Depends on system's size for int.
  DTYPE_TO_FLANN = {:float32 => :float, :float64 => :double, :byte => :byte, :int8 => :int, :int64 => :int, :int32 => :int}

protected

  # byte: unsigned char*dataset, int rows, int cols, float* speedup, FLANNParameters* flann_params
  # only thing that changes is the pointer type for the first arg.
  attach_function :flann_build_index_byte,   [:pointer, :int, :int, :pointer, :pointer], :pointer
  attach_function :flann_build_index_int,    [:pointer, :int, :int, :pointer, :pointer], :pointer
  attach_function :flann_build_index_float,  [:pointer, :int, :int, :pointer, :pointer], :pointer
  attach_function :flann_build_index_double, [:pointer, :int, :int, :pointer, :pointer], :pointer
end
