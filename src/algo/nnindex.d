/*
Project: aggnn
*/

module algo.nnindex;

import std.stream;
import serialization.serializer;

import util.resultset;

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
		Number of features in this index.
	*/
	int size();
	
	/**
	 The number of trees in this index 
	*/
 	int numTrees();
 	
 	float[][] getClusterCenters(int number) {
 		throw new Exception("Not implemented");
 	}
 	
 	void save(string file)
	{
		Serializer s = new Serializer(file, FileMode.Out);
		s.describe(this);
	}
}