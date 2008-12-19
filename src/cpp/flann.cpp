#include <stdexcept>
#include <vector>
#include "flann.h"
#include "Timer.h"
#include "common.h"
#include "Logger.h"
#include "KDTree.h"
#include "KMeansTree.h"
#include "CompositeTree.h"
#include "LinearSearch.h"
#include "Autotune.h"
#include "Testing.h"
using namespace std;



#include "flann.h"

#ifdef WIN32
#define EXPORTED extern "C" __declspec(dllexport)
#else
#define EXPORTED extern "C"
#endif


namespace {

    typedef NNIndex* NNIndexPtr;
    typedef Dataset<float>* DatasetPtr;

    const char* algos[] = { "linear","kdtree", "kmeans", "composite" };
    const char* centers_algos[] = { "random", "gonzales", "kmeanspp" };


	Params parametersToParams(IndexParameters parameters)
	{
		Params p;
		p["checks"] = parameters.checks;
        p["cb_index"] = parameters.cb_index;
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
            p.cb_index = (float)params["cb_index"];
        } catch (...) {
            p.cb_index = 0.4;
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
        p.centers_init = CENTERS_RANDOM;
        for (size_t algo_id =0; algo_id<ARRAY_LEN(centers_algos); ++algo_id) {
            const char* algo = centers_algos[algo_id];
            try {
				if (algo == params["centers-init"] ) {
					p.centers_init = algo_id;
					break;
				}
			} catch (...) {}
		}
        p.algorithm = LINEAR;
        for (size_t algo_id =0; algo_id<ARRAY_LEN(algos); ++algo_id) {
            const char* algo = algos[algo_id];
			if (algo == params["algorithm"] ) {
				p.algorithm = algo_id;
				break;
			}
		}
		return p;
	}
}



void init_flann_parameters(FLANNParameters* p)
{
	if (p != NULL) {
 		flann_log_verbosity(p->log_level);
		flann_log_destination(p->log_destination);
        if (p->random_seed>0) {
		  seed_random(p->random_seed);
        }
	}
}


EXPORTED void flann_log_verbosity(int level)
{
    if (level>=0) {
        logger.setLevel(level);
    }
}

EXPORTED void flann_log_destination(char* destination)
{
    logger.setDestination(destination);
}


EXPORTED FLANN_INDEX flann_build_index(float* dataset, int rows, int cols, float* speedup, IndexParameters* index_params, FLANNParameters* flann_params)
{
	try {
		init_flann_parameters(flann_params);

		DatasetPtr inputData = new Dataset<float>(rows,cols,dataset);

		if (index_params == NULL) {
			throw FLANNException("The index_params agument must be non-null");
		}


		float target_precision = index_params->target_precision;
        float build_weight = index_params->build_weight;
        float memory_weight = index_params->memory_weight;
        float sample_fraction = index_params->sample_fraction;

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
            Autotune autotuner(index_params->build_weight, index_params->memory_weight, index_params->sample_fraction);
			Params params = autotuner.estimateBuildIndexParams(*inputData, target_precision);
			index = create_index((const char *)params["algorithm"],*inputData,params);
			index->buildIndex();
			autotuner.estimateSearchParams(*index,*inputData,target_precision,params);

			*index_params = paramsToParameters(params);
			index_params->target_precision = target_precision;
            index_params->build_weight = build_weight;
            index_params->memory_weight = memory_weight;
            index_params->sample_fraction = sample_fraction;

			if (speedup != NULL) {
				*speedup = float(params["speedup"]);
			}
		}

		return index;
	}
	catch (runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
		return NULL;
	}
}


EXPORTED int flann_find_nearest_neighbors(float* dataset,  int rows, int cols, float* testset, int tcount, int* result, float* dists, int nn, IndexParameters* index_params, FLANNParameters* flann_params)
{
	try {
		init_flann_parameters(flann_params);

        DatasetPtr inputData = new Dataset<float>(rows,cols,dataset);
		float target_precision = index_params->target_precision;

        StartStopTimer t;
		NNIndexPtr index;
		if (target_precision < 0) {
			Params params = parametersToParams(*index_params);
			logger.info("Building index\n");
            index = create_index((const char *)params["algorithm"],*inputData,params);
            t.start();
 			index->buildIndex();
            t.stop();
            logger.info("Building index took: %g\n",t.value);
		}
		else {
            logger.info("Build index: %g\n", index_params->build_weight);
            Autotune autotuner(index_params->build_weight, index_params->memory_weight, index_params->sample_fraction);
            Params params = autotuner.estimateBuildIndexParams(*inputData, target_precision);
            index = create_index((const char *)params["algorithm"],*inputData,params);
            index->buildIndex();
            autotuner.estimateSearchParams(*index,*inputData,target_precision,params);
			*index_params = paramsToParameters(params);
		}
		logger.info("Finished creating the index.\n");

		logger.info("Searching for nearest neighbors.\n");
        Params searchParams;
        searchParams["checks"] = index_params->checks;
        Dataset<int> result_set(tcount, nn, result);
        Dataset<float> dists_set(tcount, nn, dists);
        search_for_neighbors(*index, Dataset<float>(tcount, cols, testset), result_set, dists_set, searchParams);

		delete index;
		delete inputData;

		return 0;
	}
	catch(runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
		return -1;
	}
}

EXPORTED int flann_find_nearest_neighbors_index(FLANN_INDEX index_ptr, float* testset, int tcount, int* result, float* dists, int nn, int checks, FLANNParameters* flann_params)
{
	try {
		init_flann_parameters(flann_params);

        if (index_ptr==NULL) {
            throw FLANNException("Invalid index");
        }
        NNIndexPtr index = NNIndexPtr(index_ptr);

        int length = index->veclen();
        StartStopTimer t;
        t.start();
        Params searchParams;
        searchParams["checks"] = checks;
        Dataset<int> result_set(tcount, nn, result);
        Dataset<float> dists_set(tcount, nn, dists);
        search_for_neighbors(*index, Dataset<float>(tcount, length, testset), result_set, dists_set, searchParams);
        t.stop();
        logger.info("Searching took %g seconds\n",t.value);

		return 0;
	}
	catch(runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
		return -1;
	}

}

EXPORTED int flann_free_index(FLANN_INDEX index_ptr, FLANNParameters* flann_params)
{
	try {
		init_flann_parameters(flann_params);

        if (index_ptr==NULL) {
            throw FLANNException("Invalid index");
        }
        NNIndexPtr index = NNIndexPtr(index_ptr);
        delete index;

        return 0;
	}
	catch(runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
        return -1;
	}
}

EXPORTED int flann_compute_cluster_centers(float* dataset, int rows, int cols, int clusters, float* result, IndexParameters* index_params, FLANNParameters* flann_params)
{
	try {
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


EXPORTED void compute_ground_truth_float(float* dataset, int dshape[], float* testset, int tshape[], int* match, int mshape[], int skip)
{
    assert(dshape[1]==tshape[1]);
    assert(tshape[0]==mshape[0]);

    Dataset<int> _match(mshape[0], mshape[1], match);
    compute_ground_truth(Dataset<float>(dshape[0], dshape[1], dataset), Dataset<float>(tshape[0], tshape[1], testset), _match, skip);
}


EXPORTED float test_with_precision(FLANN_INDEX index_ptr, float* dataset, int dshape[], float* testset, int tshape[], int* matches, int mshape[],
             int nn, float precision, int* checks, int skip = 0)
{
    assert(dshape[1]==tshape[1]);
    assert(tshape[0]==mshape[0]);

    try {
        if (index_ptr==NULL) {
            throw FLANNException("Invalid index");
        }
        NNIndexPtr index = (NNIndexPtr)index_ptr;
        return test_index_precision(*index, Dataset<float>(dshape[0], dshape[1],dataset), Dataset<float>(tshape[0], tshape[1], testset),
                Dataset<int>(mshape[0],mshape[1],matches), precision, *checks, nn, skip);
    } catch (runtime_error& e) {
        logger.error("Caught exception: %s\n",e.what());
        return -1;
    }
}

EXPORTED float test_with_checks(FLANN_INDEX index_ptr, float* dataset, int dshape[], float* testset, int tshape[], int* matches, int mshape[],
             int nn, int checks, float* precision, int skip = 0)
{
    assert(dshape[1]==tshape[1]);
    assert(tshape[0]==mshape[0]);

    try {
        if (index_ptr==NULL) {
            throw FLANNException("Invalid index");
        }
        NNIndexPtr index = (NNIndexPtr)index_ptr;
        return test_index_checks(*index, Dataset<float>(dshape[0], dshape[1],dataset), Dataset<float>(tshape[0], tshape[1], testset),
                Dataset<int>(mshape[0],mshape[1],matches), checks, *precision, nn, skip);
    } catch (runtime_error& e) {
        logger.error("Caught exception: %s\n",e.what());
        return -1;
    }
}
