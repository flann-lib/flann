require File.dirname(__FILE__) + "/spec_helper.rb"

describe Flann do
  it "handles the example script without error" do
    dataset = NMatrix.random([1000,128])
    testset = NMatrix.random([100,128])

    Flann.nearest_neighbors dataset, testset, 5
  end

  it "#nearest_neighbors_by_index runs without error" do
    dataset = NMatrix.random([1000,128])
    testset = NMatrix.random([100,128])

    index = Flann::Index.new(:dataset => dataset) do |t|
      t[:algorithm] = :kdtree
      t[:trees]     = 4
    end
    index.build!

    Flann.nearest_neighbors_by_index index, testset, 5
  end
end


describe Flann::Index do
  context "#new" do
    it "creates a kdtree index" do
      Flann::Index.new do |t|
        t[:algorithm] = :kdtree
        t[:trees]     = 4
      end
    end
  end


  context "#build!" do
    it "builds a kdtree index with block parameters" do
      dataset = NMatrix.random([1000,128])
      index = Flann::Index.new(dataset: dataset) do |t|
        t[:algorithm] = :kdtree
        t[:trees]     = 4
      end

      index.build!
    end
  end
end