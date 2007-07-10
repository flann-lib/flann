
/************************************************************************
Project: aggnn

Module: balltree.d 
Author: Marius Muja (2007)

*************************************************************************/

import std.stdio;

import util;
import heap;
import resultset;
import features;
import nnindex;

import agglomerativetree2;


class LinearSearch : NNIndex {


	
	Features dataset;


	
	public this(Features inputData)
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