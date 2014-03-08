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