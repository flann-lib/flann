module bindings.exports;

import tango.core.Memory;
import tango.util.log.Log;
import tango.util.log.ConsoleAppender;
import tango.util.log.FileAppender;
import tango.stdc.stringz;
import tango.stdc.stdio;


import algo.all;
import dataset.Dataset;
import util.Allocator;
import util.Utils;
import nn.Autotune;
import util.Logger;
import util.Random;
import util.defines;
import util.Profile;

extern(C):

const int LINEAR 	= 0;
const int KDTREE 	= 1;
const int KMEANS 	= 2;
const int COMPOSITE = 3;

const int CENTERS_RANDOM = 0;
const int CENTERS_GONZALES = 1;
const int CENTERS_KMEANSPP = 2;

const int LOG_NONE	= 0;
const int LOG_FATAL	= 1;
const int LOG_ERROR	= 2;
const int LOG_WARN	= 3;
const int LOG_INFO	= 4;


struct IndexParameters {
	int algorithm;
	int checks;
	int trees;
	int branching;
	int iterations;
	int centers_init;
	float target_precision;
	float build_weight;
	float memory_weight;
};

struct FLANNParameters {
	int log_level;
	char* log_destination;
	long random_seed;
};

alias int FLANN_INDEX;

Object nn_ids[];
Object features[];
int nn_ids_count;
private static bool initialized;

static this()
{
	GC.disable(); // disable garbage collector and do manual memory allocation
	
	initialized = false;
	nn_ids_count = 0;
}

private {
	char[][] algos = [ "linear","kdtree", "kmeans", "composite" ];
	char[][] centers_algos = [ "random", "gonzales", "kmeanspp" ];
	
	Params parametersToParams(IndexParameters parameters)
	{
		Params p;
		p["checks"] = parameters.checks;
		p["trees"] = parameters.trees;
		p["max-iterations"] = parameters.iterations;
		p["branching"] = parameters.branching;
		p["target-precision"] = parameters.target_precision;
		
		if (parameters.centers_init >=0 && parameters.centers_init<centers_algos.length) {
			p["centers-init"] = centers_algos[parameters.centers_init];
		}
		else {
			p["centers-init"] = "random";
		}
		
		if (parameters.algorithm >=0 && parameters.algorithm<algos.length) {
			p["algorithm"] = algos[parameters.algorithm];
		}
		
		return p;
	}
	
	IndexParameters paramsToParameters(Params params)
	{
		IndexParameters p;
		
		try {
			p.checks = params["checks"].get!(int);
		} catch (Exception e) {
			p.checks = -1;
		}
		try {
			p.trees = params["trees"].get!(int);
		} catch (Exception e) {
			p.trees = -1;
		}
		try {
			p.iterations = params["max-iterations"].get!(int);
		} catch (Exception e) {
			p.iterations = -1;
		}
		try {
			p.branching = params["branching"].get!(int);
		} catch (Exception e) {
			p.branching = -1;
		}
		try {
  			p.target_precision = params["target-precision"].get!(float);
		} catch (Exception e) {
			p.target_precision = -1;
		}
		foreach (algo_id,algo; centers_algos) {
			try {
				if (algo == params["centers-init"] ) {
					p.centers_init = algo_id;
					break;
				}
			} catch (Exception e) {}
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

bool rt_init( void delegate( Exception ) dg = null );
bool rt_term( void delegate( Exception ) dg = null ); 


void flann_init()
{
	if (!initialized) {
		rt_init();
		initLogger();
		
		nn_ids = new Object[64];
		features = new Object[64];
		
		initialized = true;
	}
}

void flann_term()
{
	if (initialized) {
		
		delete nn_ids;
		delete features;	

		rt_term();
		initialized = false;
	}
}

private void init_flann_parameters(FLANNParameters* p)
{
	if (p !is null) {
 		flann_log_verbosity(p.log_level);
		flann_log_destination(p.log_destination);
		seed_random(p.random_seed);
	}
}


void flann_log_verbosity(int level)
{
	flann_init();
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

void flann_log_destination(char* destination)
{
	flann_init();

	logger.clearAppenders();

	if (destination is null) {
		logger.addAppender(new ConsoleAppender());
	} else {
		logger.addAppender(new FileAppender(fromStringz(destination)));
	}
}


FLANN_INDEX flann_build_index(float* dataset, int rows, int cols, float* speedup, IndexParameters* index_params, FLANNParameters* flann_params)
{	
	try {
		flann_init();
		init_flann_parameters(flann_params);
				
		if (nn_ids_count==nn_ids.length) {
			// extended indices and features arrays
			Object[] tmp = new Object[2*nn_ids_count];
			tmp[0..nn_ids_count] = nn_ids;
			delete nn_ids;
			nn_ids = tmp;
			tmp = new Object[2*nn_ids_count];
			tmp[0..nn_ids_count] = features;
			delete features;
			features = tmp;
		}
		
		auto inputData = new Dataset!(float)(dataset,rows,cols);
		
		if (index_params is null) {
			throw new FLANNException("The index_params agument must be non-null");
		}
		
		float target_precision = index_params.target_precision;
		
		NNIndex index;
		if (target_precision < 0) {
			Params params = parametersToParams(*index_params);
			logger.info(sprint("Building index using params: {}",params));
			char[] algorithm = params["algorithm"].get!(char[]);		
			index = indexRegistry!(float)[algorithm](inputData, params);
			float time = profile({index.buildIndex();});
            logger.info(sprint("Building index took: {}",time));
		}
		else {
			Params params = estimateBuildIndexParams!(float)(inputData, target_precision, index_params.build_weight, index_params.memory_weight);
			char[] algorithm = params["algorithm"].get!(char[]);		
			index = indexRegistry!(float)[algorithm](inputData, params);
			index.buildIndex();
			estimateSearchParams(index,inputData,target_precision,params);
			
			*index_params = paramsToParameters(params);
			index_params.target_precision = target_precision;
			if (speedup !is null) {
				*speedup = params["speedup"].get!(float);
			}
		}
		
		FLANN_INDEX indexID = nn_ids_count++;
		nn_ids[indexID] = index;
		features[indexID] = inputData;
		return indexID;
	}
	catch (Exception e) {
		logger.error("Caught exception: "~e.toString());
		return -1;
	}
}


int flann_find_nearest_neighbors(float* dataset, int count, int length, float* testset, int tcount, int* result, int nn, IndexParameters* index_params, FLANNParameters* flann_params)
{
	try {
		flann_init();
		init_flann_parameters(flann_params);
		
		auto inputData = new Dataset!(float)(dataset,count,length);

		float target_precision = index_params.target_precision;
				
		NNIndex index;
		if (target_precision < 0) {
			Params params = parametersToParams(*index_params);
			logger.info(sprint("Building index using params: {}",params));
			char[] algorithm = params["algorithm"].get!(char[]);
			index = indexRegistry!(float)[algorithm](inputData, params);
 			index.buildIndex();
		}
		else {	
			Params params = estimateBuildIndexParams!(float)(inputData, target_precision, index_params.build_weight, index_params.memory_weight);
			char[] algorithm = params["algorithm"].get!(char[]);		
			index = indexRegistry!(float)[algorithm](inputData, params);
			index.buildIndex();
			estimateSearchParams(index,inputData,target_precision,params);
			*index_params = paramsToParameters(params);
		}
		logger.info("Index created.");
		
		logger.info("Searching for nearest neighbors.");
		int skipMatches = 0;
		ResultSet resultSet = new ResultSet(nn+skipMatches);
		
		int resultIndex = 0;
		for (int i = 0; i < tcount; i++) {
			resultSet.init(testset[0..length]);
	
			index.findNeighbors(resultSet,testset[0..length], index_params.checks);			
			
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
}

int flann_find_nearest_neighbors_index(FLANN_INDEX index_id, float* testset, int tcount, int* result, int nn, int checks, FLANNParameters* flann_params)
{
	try {
		flann_init();
		init_flann_parameters(flann_params);
		
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
				throw new FLANNException("Invalid index ID");
			}
		} 
		else {
			throw new FLANNException("Invalid index ID");
		}
		return 0;
	}
	catch(Exception e) {
		logger.error("Caught exception: "~e.toString());
		return -1;
	}
	
}

void flann_free_index(FLANN_INDEX index_id, FLANNParameters* flann_params)
{
	try {
		flann_init();
		init_flann_parameters(flann_params);
		
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
//  	GC.collect();
}

int flann_compute_cluster_centers(float* dataset, int count, int length, int clusters, float* result, IndexParameters* index_params, FLANNParameters* flann_params)
{
	try {
		flann_init();
		init_flann_parameters(flann_params);
		
		auto inputData = new Dataset!(float)(dataset,count,length);
		scope(exit) delete inputData;

		Params params = parametersToParams(*index_params);
		char[] algorithm = params["algorithm"].get!(char[]);		
		logger.info(sprint("Algorithm={}",algorithm));
		NNIndex index = indexRegistry!(float)[algorithm](inputData, params);
		scope(exit) delete index;
		index.buildIndex();

		float[][] centers = index.getClusterCenters(clusters);

		int clusterNum = centers.length;

		foreach(c;centers) {
			result[0..length] = c;
			result+=length;
		}

		delete centers;

		return clusterNum;
	} catch (Exception e) {
		logger.error("Caught exception: "~e.toString());
		return -1;
	}
}


struct KMeansNodeSt {
        /**
         * The cluster center.
         */
        float[] pivot;
        /**
         * The cluster radius.
         */
        float radius;
        /**
         * The cluster mean radius.
         */
        float mean_radius;
        /**
         * The cluster variance.
         */
        float variance;
        /**
         * The cluster size (number of points in the cluster)
         */
        int size;
        /**
         * Child nodes (only for non-terminal nodes)
         */
        KMeansNode[] childs;
        /**
         * Node points (only for terminal nodes)
         */
        int[] indices;
        /**
         * Level
         */
        int level;
}
alias KMeansNodeSt* KMeansNode;

KMeansNode get_kmeans_hierarchical_tree(FLANN_INDEX index_id)
{
    try {
        flann_init();
        
        if (index_id < nn_ids_count) {
            Object indexObj = nn_ids[index_id];
            if (indexObj !is null) {
                KMeansTree!(float) tree = cast(KMeansTree!(float)) indexObj;
    
                return tree.root;
            }
            else {
                throw new FLANNException("Invalid index ID");
            }
        } 
        else {
            throw new FLANNException("Invalid index ID");
        }
    }
    catch(Exception e) {
        logger.error("Caught exception: "~e.toString());
        return null;
    }
}