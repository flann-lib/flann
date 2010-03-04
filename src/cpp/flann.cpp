/***********************************************************************
 * Software License Agreement (BSD License)
 *
 * Copyright 2008-2009  Marius Muja (mariusm@cs.ubc.ca). All rights reserved.
 * Copyright 2008-2009  David G. Lowe (lowe@cs.ubc.ca). All rights reserved.
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

#include "flann/flann.h"
#include "flann/common.h"

#include "timer.h"
#include "logger.h"
#include "index_testing.h"
#include "saving.h"
#include "object_factory.h"
// index types
#include "kdtree_index.h"
#include "kdtree_mt_index.h"
#include "kmeans_index.h"
#include "composite_index.h"
#include "linear_index.h"
#include "autotuned_index.h"

using namespace std;

#ifdef WIN32
#define EXPORTED extern "C" __declspec(dllexport)
#else
#define EXPORTED extern "C"
#endif

struct FLANNParameters DEFAULT_FLANN_PARAMETERS = { KDTREE, 32, 0.2, 4, 32, 11, CENTERS_RANDOM, -1, 0.01, 0, 0.1, LOG_NONE, 0 };

namespace flann
{

typedef ObjectFactory<IndexParams, flann_algorithm_t> ParamsFactory;


IndexParams* IndexParams::createFromParameters(const FLANNParameters& p)
{
	IndexParams* params = ParamsFactory::instance().create(p.algorithm);
	params->fromParameters(p);

	return params;
}

NNIndex* LinearIndexParams::createIndex(const Matrix<float>& dataset) const
{
	return new LinearIndex<float>(dataset, *this);
}


NNIndex* KDTreeIndexParams::createIndex(const Matrix<float>& dataset) const
{
	return new KDTreeIndex<float>(dataset, *this);
}

NNIndex* KDTreeMTIndexParams::createIndex(const Matrix<float>& dataset) const
{
	return new KDTreeMTIndex<float>(dataset, *this);
}

NNIndex* KMeansIndexParams::createIndex(const Matrix<float>& dataset) const
{
	return new KMeansIndex<float>(dataset, *this);
}


NNIndex* CompositeIndexParams::createIndex(const Matrix<float>& dataset) const
{
	return new CompositeIndex<float>(dataset, *this);
}


NNIndex* AutotunedIndexParams::createIndex(const Matrix<float>& dataset) const
{
	return new AutotunedIndex<float>(dataset, *this);
}


NNIndex* SavedIndexParams::createIndex(const Matrix<float>& dataset) const
{

	FILE* fin = fopen(filename.c_str(), "rb");
	if (fin==NULL) {
		return NULL;
	}
	IndexHeader header = load_header(fin);
	rewind(fin);
	IndexParams* params = ParamsFactory::instance().create(header.index_type);
	NNIndex* nnIndex =  params->createIndex(dataset);
	nnIndex->loadIndex(fin);
	fclose(fin);
	delete params; //?

	return nnIndex;

}

class StaticInit
{
public:
	StaticInit()
	{
		ParamsFactory::instance().register_<LinearIndexParams>(LINEAR);
		ParamsFactory::instance().register_<KDTreeIndexParams>(KDTREE);
		ParamsFactory::instance().register_<KDTreeMTIndexParams>(KDTREE_MT);
		ParamsFactory::instance().register_<KMeansIndexParams>(KMEANS);
		ParamsFactory::instance().register_<CompositeIndexParams>(COMPOSITE);
		ParamsFactory::instance().register_<AutotunedIndexParams>(AUTOTUNED);
		ParamsFactory::instance().register_<SavedIndexParams>(SAVED);
	}
};
StaticInit __init;



Index::Index(const Matrix<float>& dataset, const IndexParams& params)
{
	nnIndex = params.createIndex(dataset);
}

Index::~Index()
{
	delete nnIndex;
}

void Index::buildIndex()
{
	nnIndex->buildIndex();
}

void Index::knnSearch(const Matrix<float>& queries, Matrix<int>& indices, Matrix<float>& dists, int knn, const SearchParams& searchParams)
{
	assert(queries.cols==nnIndex->veclen());
	assert(indices.rows>=queries.rows);
	assert(dists.rows>=queries.rows);
	assert(indices.cols>=knn);
	assert(dists.cols>=knn);


    search_for_neighbors(*nnIndex, queries, indices, dists, searchParams);
}

int Index::radiusSearch(const Matrix<float>& query, Matrix<int>& indices, Matrix<float>& dists, float radius, const SearchParams& searchParams)
{
	if (query.rows!=1) {
		printf("I can only search one feature at a time for range search\n");
		return -1;
	}
	assert(query.cols==nnIndex->veclen());

	RadiusResultSet resultSet(radius);
	resultSet.init(query.data, query.cols);
	nnIndex->findNeighbors(resultSet,query.data,searchParams);

	// TODO: optimize here
	int* neighbors = resultSet.getNeighbors();
	float* distances = resultSet.getDistances();
	int count_nn = min(resultSet.size(), indices.cols);

	assert (dists.cols>=count_nn);

	for (int i=0;i<count_nn;++i) {
		indices[0][i] = neighbors[i];
		dists[0][i] = distances[i];
	}

	return count_nn;
}


void Index::save(string filename)
{
	FILE* fout = fopen(filename.c_str(), "wb");
	if (fout==NULL) {
		logger.error("Cannot open file: %s", filename.c_str());
		throw FLANNException("Cannot open file");
	}
	nnIndex->saveIndex(fout);
	fclose(fout);
}

int Index::size() const
{
	return nnIndex->size();
}

int Index::veclen() const
{
	return nnIndex->veclen();
}


int hierarchicalClustering(const Matrix<float>& features, Matrix<float>& centers, const KMeansIndexParams& params)
{
    KMeansIndex<float> kmeans(features, params);
	kmeans.buildIndex();

    int clusterNum = kmeans.getClusterCenters(centers);
	return clusterNum;
}

} // namespace FLANN



using namespace flann;

typedef Index* IndexPtr;
typedef Matrix<float>* MatrixPtr;



void init_flann_parameters(FLANNParameters* p)
{
	if (p != NULL) {
 		flann_log_verbosity(p->log_level);
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

EXPORTED void flann_set_distance_type(flann_distance_t distance_type, int order)
{
	flann_distance_type = distance_type;
	flann_minkowski_order = order;
}


EXPORTED flann_index_t flann_build_index(float* dataset, int rows, int cols, float* speedup, FLANNParameters* flann_params)
{
	try {

		init_flann_parameters(flann_params);
		if (flann_params == NULL) {
			throw FLANNException("The flann_params argument must be non-null");
		}
		IndexParams* params = IndexParams::createFromParameters(*flann_params);
		Index* index = new Index(Matrix<float>(dataset,rows,cols), *params);
		index->buildIndex();

		return index;
	}
	catch (runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
		return NULL;
	}
}



EXPORTED int flann_save_index(flann_index_t index_ptr, char* filename)
{
	try {
		if (index_ptr==NULL) {
			throw FLANNException("Invalid index");
		}

		Index* index = (Index*)index_ptr;
		index->save(filename);

		return 0;
	}
	catch(runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
		return -1;
	}
}


EXPORTED flann_index_t flann_load_index(char* filename, float* dataset, int rows, int cols)
{
	try {
		Index* index = new Index(Matrix<float>(dataset,rows,cols), SavedIndexParams(filename));
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

		IndexParams* params = IndexParams::createFromParameters(*flann_params);
		Index* index = new Index(Matrix<float>(dataset,rows,cols), *params);
		index->buildIndex();
		Matrix<int> m_indices(result,tcount, nn);
		Matrix<float> m_dists(dists,tcount, nn);
		index->knnSearch(Matrix<float>(testset, tcount, index->veclen()),
						m_indices,
						m_dists, nn, SearchParams(flann_params->checks) );
		return 0;
	}
	catch(runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
		return -1;
	}

	return -1;
}


EXPORTED int flann_find_nearest_neighbors_index(flann_index_t index_ptr, float* testset, int tcount, int* result, float* dists, int nn, int checks, FLANNParameters* flann_params)
{
	try {
		init_flann_parameters(flann_params);
		if (index_ptr==NULL) {
			throw FLANNException("Invalid index");
		}
		Index* index = (Index*) index_ptr;

		Matrix<int> m_indices(result,tcount, nn);
		Matrix<float> m_dists(dists, tcount, nn);
		index->knnSearch(Matrix<float>(testset, tcount, index->veclen()),
						m_indices,
						m_dists, nn, SearchParams(checks) );

	}
	catch(runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
		return -1;
	}

	return -1;
}


EXPORTED int flann_radius_search(flann_index_t index_ptr,
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
		Index* index = (Index*) index_ptr;

		Matrix<int> m_indices(indices, 1, max_nn);
		Matrix<float> m_dists(dists, 1, max_nn);
		int count = index->radiusSearch(Matrix<float>(query, 1, index->veclen()),
						m_indices,
						m_dists, radius, SearchParams(checks) );


		return count;
	}
	catch(runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
		return -1;
	}

}


EXPORTED int flann_free_index(flann_index_t index_ptr, FLANNParameters* flann_params)
{
	try {
		init_flann_parameters(flann_params);
        if (index_ptr==NULL) {
            throw FLANNException("Invalid index");
        }
        Index* index = (Index*) index_ptr;
        delete index;

        return 0;
	}
	catch(runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
        return -1;
	}
}


EXPORTED int flann_compute_cluster_centers(float* dataset, int rows, int cols, int clusters, float* result, FLANNParameters* flann_params)
{
	try {
		init_flann_parameters(flann_params);

        MatrixPtr inputData = new Matrix<float>(dataset,rows,cols);
        KMeansIndexParams params(flann_params->branching, flann_params->iterations, flann_params->centers_init, flann_params->cb_index);
		Matrix<float> centers(result,clusters, cols);
        int clusterNum = hierarchicalClustering(*inputData,centers, params);

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

    Matrix<int> _match(match, mshape[0], mshape[1]);
    compute_ground_truth(Matrix<float>(dataset, dshape[0], dshape[1]), Matrix<float>(testset,tshape[0], tshape[1]), _match, skip);
}


EXPORTED float test_with_precision(flann_index_t index_ptr, float* dataset, int dshape[], float* testset, int tshape[], int* matches, int mshape[],
             int nn, float precision, int* checks, int skip = 0)
{
    assert(dshape[1]==tshape[1]);
    assert(tshape[0]==mshape[0]);

    try {
        if (index_ptr==NULL) {
            throw FLANNException("Invalid index");
        }

        IndexPtr index = (IndexPtr)index_ptr;
        NNIndex* nn_index = index->index();
        return test_index_precision(*nn_index, Matrix<float>(dataset, dshape[0], dshape[1]), Matrix<float>(testset, tshape[0], tshape[1]),
                Matrix<int>(matches, mshape[0],mshape[1]), precision, *checks, nn, skip);
    } catch (runtime_error& e) {
        logger.error("Caught exception: %s\n",e.what());
        return -1;
    }
}

EXPORTED float test_with_checks(flann_index_t index_ptr, float* dataset, int dshape[], float* testset, int tshape[], int* matches, int mshape[],
             int nn, int checks, float* precision, int skip = 0)
{
    assert(dshape[1]==tshape[1]);
    assert(tshape[0]==mshape[0]);

    try {
        if (index_ptr==NULL) {
            throw FLANNException("Invalid index");
        }
        IndexPtr index = (IndexPtr)index_ptr;
        NNIndex* nn_index = index->index();
        return test_index_checks(*nn_index, Matrix<float>(dataset, dshape[0], dshape[1]), Matrix<float>(testset, tshape[0], tshape[1]),
                Matrix<int>(matches, mshape[0],mshape[1]), checks, *precision, nn, skip);
    } catch (runtime_error& e) {
        logger.error("Caught exception: %s\n",e.what());
        return -1;
    }
}
