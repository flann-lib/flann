module bindings.exports;

import algo.all;
import dataset.Features;
import util.Allocator;
import util.Utils;

extern(C):

enum Algorithm {
	LINEAR=0,
	KDTREE,
	KMEANS,
	COMPOSITE
};

struct Parameters {
	Algorithm algo;
	int checks;
	int trees;
	int branching;
	int iterations;
};

void rt_init();
void rt_term();

void nn_init()
{
	rt_init();
}

void nn_term()
{
	rt_term();
}


void find_nearest_neighbors(float* dataset, int count, int length, float* testset, int tcount, int* result, int nn, float target_precision, Parameters* parameters)
{
	auto allocator = new Allocator();
	
	float[][] vecs = allocator.allocate!(float[][])(count);
	for (int i=0;i<count;++i) {
		vecs[i] = dataset[0..length];
		dataset += length;
	}
	auto inputData = new Features!(float)(vecs,allocator);
	
	char[][int] algo_map;
	algo_map[Algorithm.LINEAR] = "linear";
	algo_map[Algorithm.KDTREE] = "kdtree";
	algo_map[Algorithm.KMEANS] = "kmeans";
	algo_map[Algorithm.COMPOSITE] = "composite";
	
	Params params;
	params["trees"] = parameters.trees;
	params["branching"] = parameters.branching;
	params["centers-algorithm"] = "random";
	params["max-iterations"] = parameters.iterations;
	
	char[] algorithm = algo_map[parameters.algo];
	params["algorithm"] = algorithm;
	
	NNIndex index = indexRegistry!(float)[algorithm](inputData, params);
	index.buildIndex();
	
/+	float[][] test_vecs = allocator.allocate!(float[][])(tcount);
	for (int i=0;i<tcount;++i) {
		vecs[i] = testset[0..length];
		testset += length;
	}
	auto testData = new Features!(float)(test_vecs,allocator);+/
	
	int skipMatches = 0;
	ResultSet resultSet = new ResultSet(nn+skipMatches);
	
	int resultIndex = 0;
	for (int i = 0; i < tcount; i++) {
		resultSet.init(testset[0..length]);

		index.findNeighbors(resultSet,testset[0..length], parameters.checks);			
		
		int[] neighbors = resultSet.getNeighbors();
		result[resultIndex..resultIndex+nn] = neighbors[skipMatches..$];
		
		resultIndex += nn;
		testset += length;
	}
}