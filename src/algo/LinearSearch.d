
/************************************************************************
Project: nn

Module: balltree.d 
Author: Marius Muja (2007)

*************************************************************************/
module algo.LinearSearch;

import dataset.Dataset;
import algo.NNIndex;
import util.defines;
import util.Utils;


class LinearSearch(T): NNIndex {

	static string NAME = "linear";
	
	Dataset!(T) dataset;

	private this() 
	{
	}

	
	public this(Dataset!(T) inputData, Params params)
	{
		dataset = inputData;
		
	}
	
	public ~this() 
	{
	}
	
	public int size() 
	{
		return dataset.rows;
	}
	
	public int length() 
	{
		return dataset.cols;
	}
	
	public int numTrees()
	{
		return 0;
	}
	
	public int usedMemory()
	{
		return 0;
	}

	public void buildIndex() 
	{
		/* nothing to do here for linear search */
	}

	public void findNeighbors(ResultSet resultSet, float[] vec, int maxCheck) 
	{
		for (int i=0;i<dataset.rows;++i) {
			resultSet.addPoint(dataset.vecs[i],i);
		}
	}
}

mixin AlgorithmRegistry!(LinearSearch!(float),float);
mixin AlgorithmRegistry!(LinearSearch!(ubyte),ubyte);
