/*
Project: nn
*/

module algo.NNIndex;

import dataset.Dataset;
import algo.dist;
import util.Utils;
import util.defines;


template IndexConstructor(T) {
	alias NNIndex function(Dataset!(T), Params) IndexConstructor;
}

template indexRegistry(T) {
	IndexConstructor!(T)[char[]] indexRegistry;
}


/*------------------- module constructor template--------------------*/

template AlgorithmRegistry(alias ALG,T)
{
	static this() 
	{
		indexRegistry!(T)[ALG.NAME] = function(Dataset!(T) inputData, Params params) {return cast(NNIndex) new ALG(inputData, params);};
	}
}



/* This record represents a branch point when finding neighbors in
	the tree.  It contains a record of the minimum distance to the query
	point, as well as the node at which the search resumes.
*/
struct BranchStruct(T) {
	T node;           /* Tree node at which search resumes */
	float mindistsq;     /* Minimum distance to query for all nodes below. */
	
	int opCmp(BranchStruct!(T) rhs) 
	{ 
		if (mindistsq < rhs.mindistsq) {
			return -1;
		} if (mindistsq > rhs.mindistsq) {
			return 1;
		} else {
			return 0;
		}
	}
}; 






class ResultSet 
{
	int[] indices;
	float[] dists;
	
	float[] target;
	
	int count;
	
	public this(int capacity) 
	{
		indices = new int[capacity];
		dists = new float[capacity];
	}
	
	public this(float[] target, int capacity)
	{
		this(capacity);
		init(target);
	}
	
	public void init(float[] target) 
	{
		this.target = target;
		count = 0;
	}
	
	
	public int[] getNeighbors() 
	{	
		return indices;
	}
	
	public bool full() 
	{	
		return count == indices.length;
	}
	
	public bool addPoint(T)(T[] point, int index) 
	{
		for (int i=0;i<count;++i) {
			if (indices[i]==index) return false;
		}
		float dist = target.squaredDist(point);
		
		if (count<indices.length) {
			indices[count] = index;
			dists[count] = dist;	
			++count;
		} 
		else if (dist < dists[count-1]) {
			indices[count-1] = index;
			dists[count-1] = dist;
		} 
		else { 
			return false;
		}
		
		int i = count-1;
		// bubble up
		while (i>=1 && dists[i]<dists[i-1]) {
			swap(indices[i],indices[i-1]);
			swap(dists[i],dists[i-1]);
			i--;
		}
		
		return true;
	}
	
	public float worstDist()
	{
		return (count<dists.length) ? float.max : dists[count-1];
	}
	
}



/**
 * Nearest-neighbor index base class 
 */
abstract class NNIndex 
{
	/**
		Method responsible with building the index.
	*/
	void buildIndex();	


	/**
		Method that searches for NN
	*/
	void findNeighbors(ResultSet resultSet, float[] vec, int maxCheck);
	
	
	/**
	 * Compute the number of checks required to reach a certain precison,
	 * for the given test set with teh given precision.
	 */ 
	int[] findCheckForPrecision(float[][] vecs, int[][] groundTruth, float[] precisions)
 	{
 		throw new FANNException("Not implemented");
 	} 	
	
	/**
		Number of features in this index.
	*/
	int size();
	
	/**
		The length of each vector in this index.
	*/
	int veclen();
	
	/**
	 The number of trees in this index 
	*/
 	int numTrees();
 	
	/**
	 The amount of memory (in bytes) this index uses.
	*/
 	int usedMemory();
 	
 	float[][] getClusterCenters(int number) 
 	{
 		throw new FANNException("Not implemented");
 	} 	
}
