require File.dirname(__FILE__) + "/spec_helper.rb"

describe Flann do
  context "#set_distance_type!" do
    it "sets the distance functor without error" do
      pending "distance type unsupported in the C bindings, use the C++ bindings instead"
      Flann.set_distance_type! :euclidean
    end
  end

  [:byte, :int32, :float32, :float64].each do |dtype|
    before :each do
      @dataset = NMatrix.random([1000,128], dtype: dtype)
      @testset = NMatrix.random([100,128],  dtype: dtype)
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
