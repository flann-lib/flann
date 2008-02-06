module bindings.exports;

import tango.core.Memory;

import algo.all;
import dataset.Features;
import util.Allocator;
import util.Utils;
import nn.Autotune;

debug import util.Logger;

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

alias int NN_INDEX;

Object nn_ids[64];
Object features[64];
int nn_ids_count;

static this()
{
	GC.disable(); // disable garbage collector and do manual memory allocation
	
	nn_ids_count = 0;
}

private {
	struct AlgoMapping {
		Algorithm algo;
		char[] algoName;
	};
	AlgoMapping[] algoMappings = [ 
		{Algorithm.LINEAR, "linear"},
		{Algorithm.KMEANS, "kmeans"},
		{Algorithm.KDTREE, "kdtree"},
		{Algorithm.COMPOSITE, "composite"}
	];

	Params parametersToParams(Parameters parameters)
	{
		Params p;
		p["checks"] = parameters.checks;
		p["trees"] = parameters.trees;
		p["max-iterations"] = parameters.iterations;
		p["branching"] = parameters.branching;
		p["centers-algorithm"] = "random";
		foreach (mapping; algoMappings) {
			if (mapping.algo == parameters.algo) {
				p["algorithm"] = mapping.algoName;
				break;
			}
		}
		
		return p;
	}
	
	Parameters paramsToParameters(Params params)
	{
		Parameters p;
		
		p.checks = params["checks"].get!(int);
		p.trees = params["trees"].get!(int);
		p.iterations = params["max-iterations"].get!(int);
		p.branching = params["branching"].get!(int);
		foreach (mapping; algoMappings) {
			if (mapping.algoName == params["algorithm"] ) {
				p.algo = mapping.algo;
				break;
			}
		}
		return p;
	}
}

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


private Features!(T) makeFeatures(T)(T* dataset, int count, int length)
{
	T[][] vecs = allocate!(T[][])(count);
	for (int i=0;i<count;++i) {
		vecs[i] = dataset[0..length];
		dataset += length;
	}
	auto inputData = new Features!(T)(vecs);
	
	return inputData;
}

NN_INDEX build_index(float* dataset, int count, int length, float target_precision, Parameters* parameters)
{	
	auto inputData = makeFeatures(dataset,count,length);
	
	
	NNIndex index;
	if (target_precision < 0) {
		Params params = parametersToParams(*parameters);
		char[] algorithm = params["algorithm"].get!(char[]);		
		index = indexRegistry!(float)[algorithm](inputData, params);
		index.buildIndex();
	}
	else {
		Params params = estimateBuildIndexParams!(float)(inputData, target_precision);
		char[] algorithm = params["algorithm"].get!(char[]);		
		index = indexRegistry!(float)[algorithm](inputData, params);
		index.buildIndex();
		params["checks"] = estimateSearchParams(index,inputData,target_precision);
		
		*parameters = paramsToParameters(params);
	}
	
	
	NN_INDEX indexID = nn_ids_count++;
	nn_ids[indexID] = index;
	features[indexID] = inputData;
		
/+	GC.setAttr(nn_ids.ptr,GC.BlkAttr.NO_SCAN);
	GC.collect();+/
	return indexID;
}


void find_nearest_neighbors(float* dataset, int count, int length, float* testset, int tcount, int* result, int nn, float target_precision, Parameters* parameters)
{
	auto inputData = makeFeatures(dataset,count,length);
	
	NNIndex index;
	if (target_precision < 0) {
		Params params = parametersToParams(*parameters);
		char[] algorithm = params["algorithm"].get!(char[]);		
		index = indexRegistry!(float)[algorithm](inputData, params);
		index.buildIndex();
	}
	else {	
		Params params = estimateBuildIndexParams!(float)(inputData, target_precision);
		char[] algorithm = params["algorithm"].get!(char[]);		
		index = indexRegistry!(float)[algorithm](inputData, params);
		index.buildIndex();
		params["checks"] = estimateSearchParams(index,inputData,target_precision);
		
		*parameters = paramsToParameters(params);
	}
	
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
	
	delete resultSet;
	delete index;
	delete inputData;
	GC.collect();
}

void find_nearest_neighbors_index(NN_INDEX index_id, float* testset, int tcount, int* result, int nn, int checks)
{
	if (index_id < nn_ids_count) {
		Object indexObj = nn_ids[index_id];
		if (indexObj !is null) {
			NNIndex index = cast(NNIndex) indexObj;
			int length = index.length;
			
			int skipMatches = 0;
			ResultSet resultSet = new ResultSet(nn+skipMatches);
			
			int resultIndex = 0;
			for (int i = 0; i < tcount; i++) {
				resultSet.init(testset[0..length]);
		
				index.findNeighbors(resultSet,testset[0..length], checks);
				
				int[] neighbors = resultSet.getNeighbors();
				result[resultIndex..resultIndex+nn] = neighbors[skipMatches..$];
				
				resultIndex += nn;
				testset += length;
			}
			delete resultSet;
		}
		else {
			throw new Exception("Invalid index ID");
		}
	} 
	else {
		throw new Exception("Invalid index ID");
	}
// 	GC.collect();
}

void free_index(NN_INDEX index_id)
{
	if (index_id < nn_ids_count) {
		Object index = nn_ids[index_id];
		Object inputData = features[index_id];
		nn_ids[index_id] = null;
		features[index_id] = null;
		delete index;
		delete inputData;
	}
	GC.collect();
}

int compute_cluster_centers(float* dataset, int count, int length, int clusters, float* result, Parameters* parameters)
{
	auto inputData = makeFeatures(dataset,count,length);
	
	Params params = parametersToParams(*parameters);
	char[] algorithm = params["algorithm"].get!(char[]);		
	NNIndex index = indexRegistry!(float)[algorithm](inputData, params);
	index.buildIndex();
	
	float[][] centers = index.getClusterCenters(clusters);
	
	int clusterNum = centers.length;
	
	foreach(c;centers) {
		result[0..length] = c;
		result+=length;
	}
	
	delete index;
	delete centers;
	GC.collect();
	
	return clusterNum;
}
