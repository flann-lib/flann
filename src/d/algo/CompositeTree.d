module algo.CompositeTree;

import util.defines;
import algo.NNIndex;
import algo.KMeansTree;
import algo.KDTree;
import dataset.Dataset;
import util.Logger;
import util.Utils;


class CompositeTree(T) : NNIndex
{	
	static const NAME = "composite";
	
	private KMeansTree!(T) kmeans;
	private KDTree!(T) kdtree;
		
	private T[][] vecs;
	private int flength;
	
	private int numTrees_;	
	
	public this(Dataset!(T) inputData, Params params)
	{
		this.vecs = inputData.vecs;
		this.flength = inputData.cols;
		
		numTrees_ = params["trees"].get!(int);
		
		kdtree = new KDTree!(T)(inputData,params);
		kmeans = new KMeansTree!(T)(inputData,params);
	}
	
	public ~this()
	{
		delete kdtree;
		delete kmeans;
	}


	public int size() 
	{
		return vecs.length;
	}
	
	public int veclen() 
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
