/*
Project: aggnn
*/


import resultset;

interface NNIndex 
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
 	
 	
 	void save(string file);
}