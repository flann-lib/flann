module bindings.exports;

import tango.core.Memory;
import tango.util.log.Log;
import tango.util.log.ConsoleAppender;
import tango.util.log.FileAppender;
import tango.stdc.stringz;	

import algo.all;
import dataset.Dataset;
import util.Allocator;
import util.Utils;
import nn.Autotune;

import util.Logger;
import tango.stdc.stdio;

extern(C):

const int LINEAR 	= 0;
const int KDTREE 	= 1;
const int KMEANS 	= 2;
const int COMPOSITE = 3;


const int LOG_NONE	= 0;
const int LOG_FATAL	= 1;
const int LOG_ERROR	= 2;
const int LOG_WARN	= 3;
const int LOG_INFO	= 4;


struct Parameters {
	int algorithm;
	int checks;
	int trees;
	int branching;
	int iterations;
	float target_precision;
	float speedup;
};

alias int NN_INDEX;

Object nn_ids[64];
Object features[64];
int nn_ids_count;
private static bool initialized;

static this()
{
	GC.disable(); // disable garbage collector and do manual memory allocation
	
	initialized = false;
	nn_ids_count = 0;
}

private {
	char[][] algos = [ "linear","kmeans", "kdtree", "composite" ];

	Params parametersToParams(Parameters parameters)
	{
		Params p;
		p["checks"] = parameters.checks;
		p["trees"] = parameters.trees;
		p["max-iterations"] = parameters.iterations;
		p["branching"] = parameters.branching;
		p["centers-algorithm"] = "random";
		p["target-precision"] = parameters.target_precision;
		p["speedup"] = parameters.speedup;
		
		if (parameters.algorithm >=0 && parameters.algorithm<algos.length) {
			p["algorithm"] = algos[parameters.algorithm];
		}
		
		return p;
	}
	
	Parameters paramsToParameters(Params params)
	{
		Parameters p;
		
		try {
			p.checks = params["checks"].get!(int);
		} catch (Exception e) {
			p.checks = -1;
		}
		try {
			p.trees = params["trees"].get!(int);
		} catch (Exception e) {
			p.trees = 1;
		}
		try {
			p.iterations = params["max-iterations"].get!(int);
		} catch (Exception e) {
			p.iterations = -1;
		}
		try {
			p.branching = params["branching"].get!(int);
		} catch (Exception e) {
			p.branching = 32;
		}
		try {
  			p.target_precision = params["target-precision"].get!(float);
		} catch (Exception e) {
			p.target_precision = -1;
		}
		try {
 			p.speedup = params["speedup"].get!(float);
		} catch (Exception e) {
			p.speedup = -1;
		}
		foreach (algo_id,algo; algos) {
			if (algo == params["algorithm"] ) {
				p.algorithm = algo_id;
				break;
			}
		}
		return p;
	}
}

void rt_init();
void rt_term();

void fann_init()
{
// 	printf("dcode: nn_init()\n");
	if (!initialized) {
// 		printf("doing initialization\n");
		rt_init();
		initLogger();
		initialized = true;
	}
}

void fann_term()
{
// 	printf("dcode: nn_term()\n");
	if (initialized) {
		rt_term();
		initialized = false;
	}
}


void fann_log_verbosity(int level)
{
	Logger.Level logLevel = Logger.Level.Trace;
	switch (level) {
		case LOG_NONE:
			logLevel = Logger.Level.None;
			break;
		case LOG_FATAL:
			logLevel = Logger.Level.Fatal;
			break;
		case LOG_ERROR:
			logLevel = Logger.Level.Error;
			break;
		case LOG_WARN:
			logLevel = Logger.Level.Warn;
			break;
		case LOG_INFO:
			logLevel = Logger.Level.Info;
			break;
	}
	logger.setLevel(logLevel);
}

void fann_log_destination(char* destination)
{
	logger.clearAppenders();

	if (destination is null) {
		logger.addAppender(new ConsoleAppender());
	} else {
		logger.addAppender(new FileAppender(fromUtf8z(destination)));
	}
}


private Dataset!(T) makeFeatures(T)(T* dataset, int count, int length)
{
	T[][] vecs = allocate!(T[][])(count);
	for (int i=0;i<count;++i) {
		vecs[i] = dataset[0..length];
		dataset += length;
	}
	auto inputData = new Dataset!(T)(vecs);
	
	return inputData;
}

NN_INDEX fann_build_index(float* dataset, int rows, int cols, Parameters* parameters)
{	
	try {
		fann_init();
		auto inputData = makeFeatures(dataset,rows,cols);
		
		if (parameters is null) {
			throw new Exception("The parameters agument must be non-null");
		}
		
		float target_precision = parameters.target_precision;
		
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
			estimateSearchParams(index,inputData,target_precision,params);
			
			*parameters = paramsToParameters(params);
			parameters.target_precision = target_precision;
		}
		
		
		NN_INDEX indexID = nn_ids_count++;
		nn_ids[indexID] = index;
		features[indexID] = inputData;
		return indexID;
	}
	catch (Exception e) {
		logger.error("Caught exception: "~e.toString());
		return -1;
	}
/+	GC.setAttr(nn_ids.ptr,GC.BlkAttr.NO_SCAN);
	GC.collect();+/
}


int fann_find_nearest_neighbors(float* dataset, int count, int length, float* testset, int tcount, int* result, int nn, Parameters* parameters)
{
	try {
		fann_init();
		auto inputData = makeFeatures(dataset,count,length);

		float target_precision = parameters.target_precision;
		
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
			estimateSearchParams(index,inputData,target_precision,params);
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
		
		return 0;
	}
	catch(Exception e) {
		logger.error("Caught exception: "~e.toString());
		return -1;
	}
// 	GC.collect();
}

int fann_find_nearest_neighbors_index(NN_INDEX index_id, float* testset, int tcount, int* result, int nn, int checks)
{
	try {
		fann_init();
		if (index_id < nn_ids_count) {
			Object indexObj = nn_ids[index_id];
			if (indexObj !is null) {
				NNIndex index = cast(NNIndex) indexObj;
				int length = index.veclen;
				
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
		return 0;
	}
	catch(Exception e) {
		logger.error("Caught exception: "~e.toString());
		return -1;
	}
	
// 	GC.collect();
}

void fann_free_index(NN_INDEX index_id)
{
	try {
		fann_init();
		if (index_id < nn_ids_count) {
			Object index = nn_ids[index_id];
			Object inputData = features[index_id];
			nn_ids[index_id] = null;
			features[index_id] = null;
			delete index;
			delete inputData;
		}
	}
	catch(Exception e) {
		logger.error("Caught exception: "~e.toString());
	}
// 	GC.collect();
}

int fann_compute_cluster_centers(float* dataset, int count, int length, int clusters, float* result, Parameters* parameters)
{
	try {
		fann_init();
		auto inputData = makeFeatures(dataset,count,length);

		Params params = parametersToParams(*parameters);
		char[] algorithm = params["algorithm"].get!(char[]);		
		algorithm = "kmeans";
		logger.info(sprint("Algorithm={}",algorithm));
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
// 		GC.collect();

		return clusterNum;
	} catch (Exception e) {
		logger.error("Caught exception: "~e.toString());
		return -1;
	}
}
