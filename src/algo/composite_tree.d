/*
Project: nn
*/

module algo.composite_tree;

// import std.c.time;
// import std.stdio;


import util.defines;
import algo.nnindex;
import algo.kmeans;
import algo.kdtree;
import util.resultset;
import util.heap;
import util.utils;
import dataset.features;
import util.logger;
import util.random;
import util.allocator;
import util.registry;	
import util.timer;


class CompositeTree(T) : NNIndex
{	
	static const NAME = "composite";
	
	private KMeansTree!(T) kmeans;
	private KDTree!(T) kdtree;
	
	
	public uint branching;
	private uint numTrees_;
	private uint max_iter;
	private string centersAlgorithm;
	
	private T[][] vecs;
	private int flength;
	
	

	private this()
	{
	}
	
	public this(Features!(T) inputData, Params params)
	{
		this.branching = params["branching"].get!(uint);
		this.numTrees_ = params["trees"].get!(uint);
		this.max_iter = params["max-iterations"].get!(uint);
		centersAlgorithm = params["centers-algorithm"].get!(string);
		numTrees_ = params["trees"].get!(uint);

		this.vecs = inputData.vecs;
		this.flength = inputData.veclen;
		
		
		kdtree = new KDTree!(T)(inputData,params);
		params["trees"] = 1u;
		kmeans = new KMeansTree!(T)(inputData,params);
	}


	public int size() 
	{
		return vecs.length;
	}
	
	public int numTrees()
	{
		return numTrees_;
	}
	

	public void buildIndex() 
	{	
	
		Logger.log(Logger.INFO,"Building kmeans tree...\n");
		kmeans.buildIndex();
		Logger.log(Logger.INFO,"Building kdtree tree...\n");
		kdtree.buildIndex();
	}
	
	
	void findNeighbors(ResultSet result, float[] vec, int maxCheck)
	{
		kmeans.findNeighbors(result,vec,maxCheck);
		kdtree.findNeighbors(result,vec,maxCheck);
		
	}

}

mixin AlgorithmRegistry!(CompositeTree!(float),float);
mixin AlgorithmRegistry!(CompositeTree!(ubyte),ubyte);
