
#include <stdexcept>
#include "flann.h"
#include "Timer.h"
#include "common.h"
#include "Logger.h"
#include "KDTree.h"
#include "KMeansTree.h"
#include "CompositeTree.h"
#include "LinearSearch.h"
#include "Autotune.h"
using namespace std;


namespace {

    typedef NNIndex* NNIndexPtr;
    typedef Dataset<float>* DatasetPtr;

    NNIndexPtr* nn_ids;
    int nn_ids_length = 0;
    int nn_ids_count = 0;
    
    bool initialized = false;

    const char* algos[] = { "linear","kdtree", "kmeans", "composite" };
    const char* centers_algos[] = { "random", "gonzales", "kmeanspp" };

	
	Params parametersToParams(IndexParameters parameters)
	{
		Params p;
		p["checks"] = parameters.checks;
		p["trees"] = parameters.trees;
		p["max-iterations"] = parameters.iterations;
		p["branching"] = parameters.branching;
		p["target-precision"] = parameters.target_precision;
		
		if (parameters.centers_init >=0 && parameters.centers_init<ARRAY_LEN(centers_algos)) {
			p["centers-init"] = centers_algos[parameters.centers_init];
		}
		else {
			p["centers-init"] = "random";
		}
		
		if (parameters.algorithm >=0 && parameters.algorithm<ARRAY_LEN(algos)) {
			p["algorithm"] = algos[parameters.algorithm];
		}
		
		return p;
	}
	
	IndexParameters paramsToParameters(Params params)
	{
		IndexParameters p;
		
		try {
			p.checks = (int)params["checks"];
		} catch (...) {
			p.checks = -1;
		}
		try {
			p.trees = (int)params["trees"];
		} catch (...) {
			p.trees = -1;
		}
		try {
			p.iterations = (int)params["max-iterations"];
		} catch (...) {
			p.iterations = -1;
		}
		try {
			p.branching = (int)params["branching"];
		} catch (...) {
			p.branching = -1;
		}
		try {
  			p.target_precision = (float)params["target-precision"];
		} catch (...) {
			p.target_precision = -1;
		}
        for (size_t algo_id =0; algo_id<ARRAY_LEN(centers_algos); ++algo_id) {
            const char* algo = centers_algos[algo_id];
            try {
				if (algo == params["centers-init"] ) {
					p.centers_init = algo_id;
					break;
				}
			} catch (...) {}
		}
        for (size_t algo_id =0; algo_id<ARRAY_LEN(algos); ++algo_id) {
            const char* algo = algos[algo_id];
			if (algo == params["algorithm"] ) {
				p.algorithm = algo_id;
				break;
			}
		}
		return p;
	}

    NNIndexPtr create_index(const char* name, Dataset<float>& dataset, Params params)
    {
        if (!strcmp(name,algos[KDTREE])) {
            return new KDTree(dataset,params);
        }
        else if (!strcmp(name,algos[KMEANS])) {
            return new KMeansTree(dataset,params);
        }
        else if (!strcmp(name,algos[COMPOSITE])) {
            return new CompositeTree(dataset,params);
        }
        else if (!strcmp(name,algos[LINEAR])) {
            return new LinearSearch(dataset,params);
        }

        return NULL;
    }

}


void flann_init()
{
    if (!initialized) {
        printf("Initializing flann\n");
        initialized = true;
        nn_ids = new NNIndexPtr[64];
        memset(nn_ids, 0, 64*sizeof(NNIndexPtr));
    }
}

void flann_term()
{
    if (initialized) {
        delete[] nn_ids;
    }
}

void init_flann_parameters(FLANNParameters* p)
{
	if (p != NULL) {
 		flann_log_verbosity(p->log_level);
		flann_log_destination(p->log_destination);
		seed_random(p->random_seed);
	}
}


void flann_log_verbosity(int level)
{
    if (level>=0) {
        logger.setLevel(level);
    }
}

void flann_log_destination(char* destination)
{
    logger.setDestination(destination);
}


FLANN_INDEX flann_build_index(float* dataset, int rows, int cols, float* speedup, IndexParameters* index_params, FLANNParameters* flann_params)
{	
	try {
		flann_init();
		init_flann_parameters(flann_params);
				
		if (nn_ids_count==nn_ids_length) {
			// extended indices arrays
            nn_ids_length = 2*nn_ids_count;
			NNIndexPtr* tmp = new NNIndexPtr[nn_ids_length];
            memset(tmp,0,nn_ids_length*sizeof(NNIndexPtr));
            memcpy(tmp, nn_ids, nn_ids_count*sizeof(NNIndexPtr));
			delete[] nn_ids;
			nn_ids = tmp;
		}
		
		DatasetPtr inputData = new Dataset<float>(rows,cols,dataset);
		
		if (index_params == NULL) {
			throw FLANNException("The index_params agument must be non-null");
		}

		
		float target_precision = index_params->target_precision;
        float build_weight = index_params->build_weight;
        float memory_weight = index_params->memory_weight;
		
		NNIndex* index = NULL;
		if (target_precision < 0) {
			Params params = parametersToParams(*index_params);
			logger.info("Building index\n");
			index = create_index((const char *)params["algorithm"],*inputData,params);
            StartStopTimer t;
            t.start();
            index->buildIndex();
            t.stop();
            logger.info("Building index took: %g\n",t.value);
		}
		else {
            if (index_params->build_weight < 0) {
                throw FLANNException("The index_params.build_weight must be positive.");
            }
            
            if (index_params->memory_weight < 0) {
                throw FLANNException("The index_params.memory_weight must be positive.");
            }
            Autotune autotuner(index_params->build_weight, index_params->memory_weight);    
			Params params = autotuner.estimateBuildIndexParams(*inputData, target_precision);
			index = create_index((const char *)params["algorithm"],*inputData,params);
			index->buildIndex();
			autotuner.estimateSearchParams(*index,*inputData,target_precision,params);
			
			*index_params = paramsToParameters(params);
			index_params->target_precision = target_precision;
            index_params->build_weight = build_weight;
            index_params->memory_weight = memory_weight;
			if (speedup != NULL) {
				*speedup = float(params["speedup"]);
			}
		}
		
		FLANN_INDEX indexID = nn_ids_count++;
		nn_ids[indexID] = index;
		return indexID;
	}
	catch (runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
		return -1;
	}
}


int flann_find_nearest_neighbors(float* dataset,  int rows, int cols, float* testset, int tcount, int* result, int nn, IndexParameters* index_params, FLANNParameters* flann_params)
{
	try {
		flann_init();
		init_flann_parameters(flann_params);
		
        DatasetPtr inputData = new Dataset<float>(rows,cols,dataset);
		float target_precision = index_params->target_precision;
				
		NNIndexPtr index;
		if (target_precision < 0) {
			Params params = parametersToParams(*index_params);
			logger.info("Building index");
            index = create_index((const char *)params["algorithm"],*inputData,params);
 			index->buildIndex();
		}
		else {
            logger.info("Build index: %g\n", index_params->build_weight);
            Autotune autotuner(index_params->build_weight, index_params->memory_weight);    
            Params params = autotuner.estimateBuildIndexParams(*inputData, target_precision);
            index = create_index((const char *)params["algorithm"],*inputData,params);
            index->buildIndex();
            autotuner.estimateSearchParams(*index,*inputData,target_precision,params);
			*index_params = paramsToParameters(params);
		}
		logger.info("Index created.\n");
		
		logger.info("Searching for nearest neighbors.\n");
        int skipMatches = 0;
        ResultSet resultSet(nn+skipMatches);
        
        for (int i = 0; i < tcount; i++) {
            resultSet.init(testset, cols);
                    
            index->findNeighbors(resultSet,testset, index_params->checks);
            
            int* neighbors = resultSet.getNeighbors();
            memcpy(result, neighbors+skipMatches, nn*sizeof(int));
            
            result += nn;
            testset += cols;
        }
		
		delete index;
		delete inputData;
		
		return 0;
	}
	catch(runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
		return -1;
	}
}

int flann_find_nearest_neighbors_index(FLANN_INDEX index_id, float* testset, int tcount, int* result, int nn, int checks, FLANNParameters* flann_params)
{
	try {
		flann_init();
		init_flann_parameters(flann_params);
		
		if (index_id < nn_ids_count) {
			NNIndexPtr index = nn_ids[index_id];
			if (index!=NULL) {
				int length = index->veclen();
				
				int skipMatches = 0;
				ResultSet resultSet(nn+skipMatches);
				
				for (int i = 0; i < tcount; i++) {
					resultSet.init(testset, length);
							
					index->findNeighbors(resultSet,testset, checks);					
					int* neighbors = resultSet.getNeighbors();
                    memcpy(result, neighbors+skipMatches, nn*sizeof(int));
					
					result += nn;
					testset += length;
				}
			}
			else {
				throw FLANNException("Invalid index ID");
			}
		} 
		else {
			throw FLANNException("Invalid index ID");
		}
		return 0;
	}
	catch(runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
		return -1;
	}
	
}

void flann_free_index(FLANN_INDEX index_id, FLANNParameters* flann_params)
{
	try {
		flann_init();
		init_flann_parameters(flann_params);
		
		if (index_id >= 0 && index_id < nn_ids_count) {
			NNIndexPtr index = nn_ids[index_id];
			nn_ids[index_id] = NULL;
			delete index;
		}
	}
	catch(runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
	}
}

int flann_compute_cluster_centers(float* dataset, int rows, int cols, int clusters, float* result, IndexParameters* index_params, FLANNParameters* flann_params)
{
	try {
 		flann_init();
		init_flann_parameters(flann_params);
		
        DatasetPtr inputData = new Dataset<float>(rows,cols,dataset);
        Params params = parametersToParams(*index_params);
        KMeansTree kmeans(*inputData, params);
		kmeans.buildIndex();

        int clusterNum = kmeans.getClusterCenters(clusters,result);

		return clusterNum;
	} catch (runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
		return -1;
	}
}


