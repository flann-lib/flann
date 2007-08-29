
/************************************************************************
Project: nn

Module: balltree.d 
Author: Marius Muja (2007)

*************************************************************************/
module algo.linearsearch;

import util.utils;
import util.resultset;
import util.features;
import algo.nnindex;


mixin AlgorithmRegistry!(LinearSearch);

class LinearSearch : NNIndex {

	void describe(T)(T ar)
	{
	}


	static string NAME = "linear";
	
	Features dataset;

	private this() 
	{
	}

	
	public this(Features inputData, Params params)
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
