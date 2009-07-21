/***********************************************************************
 * Software License Agreement (BSD License)
 *
 * Copyright 2008-2009  Marius Muja (mariusm@cs.ubc.ca). All rights reserved.
 * Copyright 2008-2009  David G. Lowe (lowe@cs.ubc.ca). All rights reserved.
 *
 * THE BSD LICENSE
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *************************************************************************/

#include <stdexcept>
#include <vector>
#include "flann.h"
#include "timer.h"
#include "common.h"
#include "logger.h"
#include "index_testing.h"
#include "saving.h"
// index types
#include "kdtree_index.h"
#include "kmeans_index.h"
#include "composite_index.h"
#include "linear_index.h"
#include "autotuned_index.h"
using namespace std;



#include "flann.h"

#ifdef WIN32
#define EXPORTED extern "C" __declspec(dllexport)
#else
#define EXPORTED extern "C"
#endif


namespace FLANN
{



NNIndex* KDTreeIndexParams::create(const Matrix<float>& dataset)
{
	return new KDTreeIndex(dataset, *this);
}

NNIndex* HierarchicalKMeansIndexParams::create(const Matrix<float>& dataset)
{
	return new HierarchicalKMeansIndex(dataset, *this);
}

NNIndex* CompositeIndexParams::create(const Matrix<float>& dataset)
{
	return new CompositeIndex(dataset, *this);
}

NNIndex* AutotunedIndexParams::create(const Matrix<float>& dataset)
{
	return new AutotunedIndex(dataset, *this);
}

NNIndex* SavedIndexParams::create(const Matrix<float>& dataset)
{
	return NULL;
	//return new AutotunedTree(dataset, *this);
}




Index::Index(const Matrix<float>& dataset, const IndexParams& params)
{
	nnIndex = params.create(dataset);
	nnIndex->buildIndex();
}

void Index::knnSearch(float* queries, int rows, vector<int>& indices, vector<float>& dists, int knn, const SearchParams& params)
{

    int length = nnIndex->veclen();
    Dataset<int> result_set(tcount, nn, result);
    Dataset<float> dists_set(tcount, nn, dists);
    search_for_neighbors(*index, Dataset<float>(tcount, length, testset), result_set, dists_set, searchParams);
    t.stop();
    logger.info("Searching took %g seconds\n",t.value);


}

void Index::radiusSearch(float* query, vector<int> indices, vector<float> dists, float radius, const SearchParams& params)
{

}

void Index::save(string filename)
{
	FILE* fout = fopen(filename, "wb");
	if (fout==NULL) {
		logger.error("Cannot open file: %s", filename.c_str());
		throw FLANNException("Cannot open file");
	}
	nnIndex->saveIndex(fout);
	fclose(fout);
}



} // namespace FLANN



using namespace FLANN;

typedef NNIndex* NNIndexPtr;
typedef Matrix<float>* MatrixPtr;



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

EXPORTED void flann_set_distance_type(flann_distance_t distance_type, int order)
{
	flann_distance_type = distance_type;
	flann_minkowski_order = order;
}


EXPORTED FLANN_INDEX flann_build_index(float* dataset, int rows, int cols, float* speedup, FLANNParameters* flann_params)
{
	try {
		if (flann_params == NULL) {
			throw FLANNException("The index_params agument must be non-null");
		}
		init_flann_parameters(flann_params);

		MatrixPtr inputData = new Dataset<float>(rows,cols,dataset);
		float target_precision = flann_params->target_precision;

		NNIndex* index = NULL;
		if (flann_params->target_precision < 0) {
			Params params = parametersToParams(*flann_params);
			logger.info("Building index\n");
			index = create_index((flann_algorithm_t)(int)params["algorithm"],*inputData,params);
            StartStopTimer t;
            t.start();
            index->buildIndex();
            t.stop();
            logger.info("Building index took: %g\n",t.value);
		}
		else {
            if (flann_params->build_weight < 0) {
                throw FLANNException("The index_params.build_weight must be positive.");
            }

            if (flann_params->memory_weight < 0) {
                throw FLANNException("The index_params.memory_weight must be positive.");
            }
//            Autotune autotuner(flann_params->build_weight, flann_params->memory_weight, flann_params->sample_fraction);
//			Params params = autotuner.estimateBuildIndexParams(*inputData, target_precision);
//			index = create_index((flann_algorithm_t)(int)params["algorithm"],*inputData,params);
//			index->buildIndex();
//			autotuner.estimateSearchParams(*index,*inputData,target_precision,params);
//			paramsToParameters(params, flann_params);

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



EXPORTED int flann_save_index(FLANN_INDEX index_ptr, char* filename)
{
	try {
		if (index_ptr==NULL) {
			throw FLANNException("Invalid index");
		}
		NNIndexPtr index = NNIndexPtr(index_ptr);

		FILE* fout = fopen(filename, "wb");
		if (fout==NULL) {
			return -2;   // if cannot open file return error code
		}
		index->saveIndex(fout);
		fclose(fout);

		return 0;
	}
	catch(runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
		return -1;
	}
}


EXPORTED FLANN_INDEX flann_load_index(char* filename, float* dataset, int rows, int cols)
{
	try {
		MatrixPtr inputData = new Dataset<float>(rows,cols,dataset);
		NNIndex* index = NULL;

		FILE* fin = fopen(filename, "rb");
		if (fin==NULL) {
			return NULL;
		}
		IndexHeader header = load_header(fin);
		rewind(fin);
		Params params;
		index = create_index(header.index_type,*inputData,params);
		index->loadIndex(fin);
		fclose(fin);

		return index;
	}
	catch(runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
		return NULL;
	}
}



EXPORTED int flann_find_nearest_neighbors(float* dataset,  int rows, int cols, float* testset, int tcount, int* result, float* dists, int nn, FLANNParameters* flann_params)
{
	try {
		init_flann_parameters(flann_params);

        MatrixPtr inputData = new Dataset<float>(rows,cols,dataset);
		float target_precision = flann_params->target_precision;

        StartStopTimer t;
		NNIndexPtr index;
		if (target_precision < 0) {
			Params params = parametersToParams(*flann_params);
			logger.info("Building index\n");
            index = create_index((flann_algorithm_t)(int)params["algorithm"],*inputData,params);
            t.start();
 			index->buildIndex();
            t.stop();
            logger.info("Building index took: %g\n",t.value);
		}
		else {
            logger.info("Build index: %g\n", flann_params->build_weight);
            Autotune autotuner(flann_params->build_weight, flann_params->memory_weight, flann_params->sample_fraction);
            Params params = autotuner.estimateBuildIndexParams(*inputData, target_precision);
            index = create_index((flann_algorithm_t)(int)params["algorithm"],*inputData,params);
            index->buildIndex();
            autotuner.estimateSearchParams(*index,*inputData,target_precision,params);
			paramsToParameters(params, flann_params);
		}
		logger.info("Finished creating the index.\n");

		logger.info("Searching for nearest neighbors.\n");
        Params searchParams;
        searchParams["checks"] = flann_params->checks;
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


EXPORTED int flann_radius_search(FLANN_INDEX index_ptr,
										float* query,
										int* indices,
										float* dists,
										int max_nn,
										float radius,
										int checks,
										FLANNParameters* flann_params)
{
	try {
		init_flann_parameters(flann_params);

        if (index_ptr==NULL) {
            throw FLANNException("Invalid index");
        }
        NNIndexPtr index = NNIndexPtr(index_ptr);

        int length = index->veclen();
        Params searchParams;
        searchParams["checks"] = checks;
        RadiusResultSet resultSet(radius);
        resultSet.init(query, index->veclen());
        index->findNeighbors(resultSet,query,searchParams);

        int* neighbors = resultSet.getNeighbors();
        float* distances = resultSet.getDistances();

        int count_nn = resultSet.size();

        for (int i=0;i<count_nn;++i) {
        	indices[i] = neighbors[i];
        	dists[i] = distances[i];
        }
		return count_nn;
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

