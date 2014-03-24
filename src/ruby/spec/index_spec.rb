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


describe Flann::Index do
  [:byte, :int32, :float32, :float64].each do |dtype|
    context dtype.inspect do
      before :each do
        scale = [:byte, :int32, :int64].include?(dtype) ? 255 : 1.0

        @dataset = NMatrix.random([1000,128], dtype: dtype, scale: scale)
        @testset = NMatrix.random([100,128],  dtype: dtype, scale: scale)
        @index   = Flann::Index.new(@dataset) do |t|
          t[:algorithm] = :kdtree
          t[:trees]     = 4
        end
        @index.build!
      end


      context "#nearest_neighbors" do
        it "runs without error" do
          @index.nearest_neighbors @testset, 5
        end

        if dtype == :float32
          it "runs a :kdtree_single search correctly" do
            @dataset = read_dataset "test.dataset"
            @testset = @dataset[0,:*].clone
            @index   = Flann::Index.new(@dataset) do |t|
              t[:algorithm] = :kdtree_single
            end
            @index.build!
            indices, distances = @index.nearest_neighbors @testset, 11
            #expect(indices).to eq([0,1,256,257,2,512,258,513,514,3,768])
            expect(indices[0]).to eq(0)
            expect(indices[1..2].sort).to eq([1,256])
            expect(indices[3]).to eq(257)
            expect(indices[4..5].sort).to eq([2,512])
            expect(indices[6..7].sort).to eq([258,513])
            expect(indices[8]).to eq(514)
            expect(indices[9..10].sort).to eq([3,768])

            expect(distances[0]).to be_within(1E-16).of(0.0)
            expect(distances[1]).to be_within(1E-4).of(2.614689)
            expect(distances[2]).to be_within(1E-4).of(2.614689)
            expect(distances[3]).to be_within(1E-4).of(5.229378)
            expect(distances[4]).to be_within(1E-4).of(10.465225)
            expect(distances[5]).to be_within(1E-4).of(10.465225)
            expect(distances[6]).to be_within(1E-4).of(13.079914)
            expect(distances[7]).to be_within(1E-4).of(13.079914)
            expect(distances[8]).to be_within(1E-4).of(20.93045)
            expect(distances[9]).to be_within(1E-4).of(23.541904)
          end
        end
      end


      context "#radius_search" do
        it "runs without error" do
          query = NMatrix.random([1,128])
          @index.radius_search query, 0.4
        end
      end


      context "#save" do
        it "saves an index to a file which can be loaded again" do
          FileUtils.rm("temp_index.save_file", :force => true)
          @index.save("temp_index.save_file")

          raise(IOError, "save failed") unless File.exists?("temp_index.save_file")

          post_index = Flann::Index.new(@dataset)
          post_index.load!("temp_index.save_file")
          FileUtils.rm("temp_index.save_file", :force => true)
        end
      end


      context "#free!" do
        it "frees an index" do
          @index.free!
        end
      end
    end
  end
end