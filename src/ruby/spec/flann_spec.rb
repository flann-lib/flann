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

require File.dirname(__FILE__) + "/spec_helper.rb"

describe Flann do

  it "::VERSION::STRING matches #define FLANN_VERSION_ in config.h" do
    found = false
    File.open(File.dirname(__FILE__) + "/../../cpp/flann/config.h", "r") do |f|
      while line = f.gets
        next unless line =~ /#[\s]*define[\s]+FLANN_VERSION_[\s]+"\d.\d.\d"/
        fields = line.split
        found = true
        expect(fields.last[1...-1]).to eq(Flann::VERSION::STRING.split('.')[0...-1].join('.'))
      end
    end

    raise("could not find version string in config.h") unless found
  end

  it "works on the example given in the manual" do
    dataset = NMatrix.random([10000,128])
    testset = NMatrix.random([1000,128])

    index   = Flann::Index.new(dataset) do |params|
      params[:algorithm]  = :kmeans
      params[:branching]  = 32
      params[:iterations] = 7
      params[:checks]     = 16
    end
    speedup = index.build! # this is optional

    results, distances = index.nearest_neighbors(testset, 5)

    # Skip saving, as that's tested elsewhere, and I don't feel like cleaning up.
    # index.save "my_index.save"

    # Alternatively, without an index:
    results, distances = Flann.nearest_neighbors(dataset, testset, 5,
                          algorithm: :kmeans, branching: 32,
                          iterations: 7, checks: 16)
  end

  context "#set_distance_type!" do
    it "sets the distance functor without error" do
      Flann.set_distance_type! :euclidean

      # Version check needed before attempting get_distance_type
      if Flann.respond_to?(:flann_get_distance_type)
        d = Flann.get_distance_type
        expect(d).to eq(:euclidean)
      end
    end
  end

  [:byte, :int32, :float32, :float64].each do |dtype|
    before :each do
      scale = [:byte, :int32, :int64].include?(dtype) ? 255 : 1.0
      @dataset = NMatrix.random([1000,128], dtype: dtype, scale: scale)
      @testset = NMatrix.random([100,128],  dtype: dtype, scale: scale)
    end

    context "#nearest_neighbors" do
      it "computes the nearest neighbors without an index" do
        Flann.nearest_neighbors @dataset, @testset, 5
      end
    end

    context "#cluster" do
      it "calls flann_compute_cluster_centers_... properly" do
        Flann.cluster(@dataset, 5)
      end
    end


  end


end
