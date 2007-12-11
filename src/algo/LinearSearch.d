
/************************************************************************
Project: nn

Module: balltree.d 
Author: Marius Muja (2007)

*************************************************************************/
module algo.LinearSearch;

import dataset.Features;
import algo.NNIndex;
import util.defines;
import util.Utils;


class LinearSearch(T): NNIndex {

	void describe(T)(T ar)
	{
	}


	static string NAME = "linear";
	
	Features!(T) dataset;

	private this() 
	{
	}

	
	public this(Features!(T) inputData, Params params)
	{
		dataset = inputData;
		
	}
	
	public ~this() 
	{
	}
	
	public int size() 
	{
		return dataset.count;
	}
	
	public int numTrees()
	{
		return 1;
	}

	public void buildIndex() 
	{
		/* nothing to do here for linear search */
	}
	
	
	public void findNeighbors(ResultSet resultSet, float[] vec, int maxCheck) 
	{
		for (int i=0;i<dataset.count;++i) {
			resultSet.addPoint(dataset.vecs[i],i);
		}
	}
	

}

mixin AlgorithmRegistry!(LinearSearch!(float),float);
mixin AlgorithmRegistry!(LinearSearch!(ubyte),ubyte);
