require File.dirname(__FILE__) + "/spec_helper.rb"


describe Flann::Index do

  before :each do
    @dataset = NMatrix.random([1000,128])
    @testset = NMatrix.random([100,128])
    @index   = Flann::Index.new(dataset: @dataset) do |t|
      t[:algorithm] = :kdtree
      t[:trees]     = 4
    end
    @index.build!
  end


  context "#build!" do
    it "builds a kdtree index with block parameters" do
      # Empty: handled in :each, above
    end
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

      post_index = Flann::Index.new(dataset: @dataset)
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