/*
Project: nn
*/

module algo.CompositeTree;

import util.defines;
import algo.NNIndex;
import algo.KMeansTree;
import algo.KDTree;
import dataset.Features;
import util.Logger;
import util.Utils;


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
		this.flength = inputData.cols;
		
		
		kdtree = new KDTree!(T)(inputData,params);
		params["trees"] = 1u;
		kmeans = new KMeansTree!(T)(inputData,params);
	}


	public int size() 
	{
		return vecs.length;
	}
	
	public int length() 
	{
		return flength;
	}
	
	public int numTrees()
	{
		return numTrees_;
	}
	
	public int usedMemory()
	{
		return kmeans.usedMemory+kdtree.usedMemory;
	}

	public void buildIndex() 
	{	
		logger.info("Building kmeans tree...");
		kmeans.buildIndex();
		logger.info("Building kdtree tree...");
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
