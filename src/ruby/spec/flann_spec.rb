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
