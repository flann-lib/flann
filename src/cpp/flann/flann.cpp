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

// include flann_cpp stuff
#include "flann_cpp.cpp"

using namespace std;

#ifdef WIN32
#define EXPORTED extern "C" __declspec(dllexport)
#else
#define EXPORTED extern "C"
#endif


struct FLANNParameters DEFAULT_FLANN_PARAMETERS = { 
    KDTREE, 
    32, 0.2, 0.0,
    4, 
    32, 11, CENTERS_RANDOM, 
    0.9, 0.01, 0, 0.1, 
    LOG_NONE, 0 
};


using namespace flann;


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
    flann::log_verbosity(level);
}

EXPORTED void flann_set_distance_type(flann_distance_t distance_type, int order)
{
    flann::set_distance_type(distance_type, order);
}


template<typename T>
flann_index_t _flann_build_index(T* dataset, int rows, int cols, float* speedup, FLANNParameters* flann_params)
{
	try {

		init_flann_parameters(flann_params);
		if (flann_params == NULL) {
			throw FLANNException("The flann_params argument must be non-null");
		}
		IndexParams* params = IndexParams::createFromParameters(*flann_params);
		Index<T>* index = new Index<T>(Matrix<T>(dataset,rows,cols), *params);
		index->buildIndex();
		const IndexParams* index_params = index->getIndexParameters();
		index_params->toParameters(*flann_params);

		return index;
	}
	catch (runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
		return NULL;
	}
}

EXPORTED flann_index_t flann_build_index(float* dataset, int rows, int cols, float* speedup, FLANNParameters* flann_params)
{
	return _flann_build_index(dataset, rows, cols, speedup, flann_params);
}

EXPORTED flann_index_t flann_build_index_float(float* dataset, int rows, int cols, float* speedup, FLANNParameters* flann_params)
{
	return _flann_build_index(dataset, rows, cols, speedup, flann_params);
}

EXPORTED flann_index_t flann_build_index_double(double* dataset, int rows, int cols, float* speedup, FLANNParameters* flann_params)
{
	return _flann_build_index(dataset, rows, cols, speedup, flann_params);
}

EXPORTED flann_index_t flann_build_index_byte(unsigned char* dataset, int rows, int cols, float* speedup, FLANNParameters* flann_params)
{
	return _flann_build_index(dataset, rows, cols, speedup, flann_params);
}

EXPORTED flann_index_t flann_build_index_int(int* dataset, int rows, int cols, float* speedup, FLANNParameters* flann_params)
{
	return _flann_build_index(dataset, rows, cols, speedup, flann_params);
}

template<typename T>
int _flann_save_index(flann_index_t index_ptr, char* filename)
{
	try {
		if (index_ptr==NULL) {
			throw FLANNException("Invalid index");
		}

		Index<T>* index = (Index<T>*)index_ptr;
		index->save(filename);

		return 0;
	}
	catch(runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
		return -1;
	}
}

EXPORTED int flann_save_index(flann_index_t index_ptr, char* filename)
{
	return _flann_save_index<float>(index_ptr, filename);
}

EXPORTED int flann_save_index_float(flann_index_t index_ptr, char* filename)
{
	return _flann_save_index<float>(index_ptr, filename);
}

EXPORTED int flann_save_index_double(flann_index_t index_ptr, char* filename)
{
	return _flann_save_index<double>(index_ptr, filename);
}

EXPORTED int flann_save_index_byte(flann_index_t index_ptr, char* filename)
{
	return _flann_save_index<unsigned char>(index_ptr, filename);
}

EXPORTED int flann_save_index_int(flann_index_t index_ptr, char* filename)
{
	return _flann_save_index<int>(index_ptr, filename);
}


template<typename T>
flann_index_t _flann_load_index(char* filename, T* dataset, int rows, int cols)
{
	try {
		Index<T>* index = new Index<T>(Matrix<T>(dataset,rows,cols), SavedIndexParams(filename));
		return index;
	}
	catch(runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
		return NULL;
	}
}

EXPORTED flann_index_t flann_load_index(char* filename, float* dataset, int rows, int cols)
{
	return _flann_load_index(filename, dataset, rows, cols);
}

EXPORTED flann_index_t flann_load_index_float(char* filename, float* dataset, int rows, int cols)
{
	return _flann_load_index(filename, dataset, rows, cols);
}

EXPORTED flann_index_t flann_load_index_double(char* filename, double* dataset, int rows, int cols)
{
	return _flann_load_index(filename, dataset, rows, cols);
}

EXPORTED flann_index_t flann_load_index_byte(char* filename, unsigned char* dataset, int rows, int cols)
{
	return _flann_load_index(filename, dataset, rows, cols);
}

EXPORTED flann_index_t flann_load_index_int(char* filename, int* dataset, int rows, int cols)
{
	return _flann_load_index(filename, dataset, rows, cols);
}



template<typename T>
int _flann_find_nearest_neighbors(T* dataset,  int rows, int cols, T* testset, int tcount, int* result, float* dists, int nn, FLANNParameters* flann_params)
{
	try {
		init_flann_parameters(flann_params);

		IndexParams* params = IndexParams::createFromParameters(*flann_params);
		Index<T>* index = new Index<T>(Matrix<T>(dataset,rows,cols), *params);
		index->buildIndex();
		Matrix<int> m_indices(result,tcount, nn);
		Matrix<float> m_dists(dists,tcount, nn);
		index->knnSearch(Matrix<T>(testset, tcount, index->veclen()),
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

EXPORTED int flann_find_nearest_neighbors(float* dataset,  int rows, int cols, float* testset, int tcount, int* result, float* dists, int nn, FLANNParameters* flann_params)
{
	return _flann_find_nearest_neighbors(dataset, rows, cols, testset, tcount, result, dists, nn, flann_params);
}

EXPORTED int flann_find_nearest_neighbors_float(float* dataset,  int rows, int cols, float* testset, int tcount, int* result, float* dists, int nn, FLANNParameters* flann_params)
{
	return _flann_find_nearest_neighbors(dataset, rows, cols, testset, tcount, result, dists, nn, flann_params);
}

EXPORTED int flann_find_nearest_neighbors_double(double* dataset,  int rows, int cols, double* testset, int tcount, int* result, float* dists, int nn, FLANNParameters* flann_params)
{
	return _flann_find_nearest_neighbors(dataset, rows, cols, testset, tcount, result, dists, nn, flann_params);
}

EXPORTED int flann_find_nearest_neighbors_byte(unsigned char* dataset,  int rows, int cols, unsigned char* testset, int tcount, int* result, float* dists, int nn, FLANNParameters* flann_params)
{
	return _flann_find_nearest_neighbors(dataset, rows, cols, testset, tcount, result, dists, nn, flann_params);
}

EXPORTED int flann_find_nearest_neighbors_int(int* dataset,  int rows, int cols, int* testset, int tcount, int* result, float* dists, int nn, FLANNParameters* flann_params)
{
	return _flann_find_nearest_neighbors(dataset, rows, cols, testset, tcount, result, dists, nn, flann_params);
}


template<typename T>
int _flann_find_nearest_neighbors_index(flann_index_t index_ptr, T* testset, int tcount, int* result, float* dists, int nn, FLANNParameters* flann_params)
{
	try {
		init_flann_parameters(flann_params);
		if (index_ptr==NULL) {
			throw FLANNException("Invalid index");
		}
		Index<T>* index = (Index<T>*) index_ptr;

		Matrix<int> m_indices(result,tcount, nn);
		Matrix<float> m_dists(dists, tcount, nn);

		index->knnSearch(Matrix<T>(testset, tcount, index->veclen()),
						m_indices,
						m_dists, nn, SearchParams(flann_params->checks) );
	}
	catch(runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
		return -1;
	}

	return -1;
}

EXPORTED int flann_find_nearest_neighbors_index(flann_index_t index_ptr, float* testset, int tcount, int* result, float* dists, int nn, FLANNParameters* flann_params)
{
	return _flann_find_nearest_neighbors_index(index_ptr, testset, tcount, result, dists, nn, flann_params);
}

EXPORTED int flann_find_nearest_neighbors_index_float(flann_index_t index_ptr, float* testset, int tcount, int* result, float* dists, int nn, FLANNParameters* flann_params)
{
	return _flann_find_nearest_neighbors_index(index_ptr, testset, tcount, result, dists, nn, flann_params);
}

EXPORTED int flann_find_nearest_neighbors_index_double(flann_index_t index_ptr, double* testset, int tcount, int* result, float* dists, int nn, FLANNParameters* flann_params)
{
	return _flann_find_nearest_neighbors_index(index_ptr, testset, tcount, result, dists, nn, flann_params);
}

EXPORTED int flann_find_nearest_neighbors_index_byte(flann_index_t index_ptr, unsigned char* testset, int tcount, int* result, float* dists, int nn, FLANNParameters* flann_params)
{
	return _flann_find_nearest_neighbors_index(index_ptr, testset, tcount, result, dists, nn, flann_params);
}

EXPORTED int flann_find_nearest_neighbors_index_int(flann_index_t index_ptr, int* testset, int tcount, int* result, float* dists, int nn, FLANNParameters* flann_params)
{
	return _flann_find_nearest_neighbors_index(index_ptr, testset, tcount, result, dists, nn, flann_params);
}


template<typename T>
int _flann_radius_search(flann_index_t index_ptr,
										T* query,
										int* indices,
										float* dists,
										int max_nn,
										float radius,
										FLANNParameters* flann_params)
{
	try {
		init_flann_parameters(flann_params);
		if (index_ptr==NULL) {
			throw FLANNException("Invalid index");
		}
		Index<T>* index = (Index<T>*) index_ptr;

		Matrix<int> m_indices(indices, 1, max_nn);
		Matrix<float> m_dists(dists, 1, max_nn);
		int count = index->radiusSearch(Matrix<T>(query, 1, index->veclen()),
						m_indices,
						m_dists, radius, SearchParams(flann_params->checks) );


		return count;
	}
	catch(runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
		return -1;
	}

}

EXPORTED int flann_radius_search(flann_index_t index_ptr,
										float* query,
										int* indices,
										float* dists,
										int max_nn,
										float radius,
										FLANNParameters* flann_params)
{
	return _flann_radius_search(index_ptr, query, indices, dists, max_nn, radius, flann_params);
}

EXPORTED int flann_radius_search_float(flann_index_t index_ptr,
										float* query,
										int* indices,
										float* dists,
										int max_nn,
										float radius,
										FLANNParameters* flann_params)
{
	return _flann_radius_search(index_ptr, query, indices, dists, max_nn, radius, flann_params);
}

EXPORTED int flann_radius_search_double(flann_index_t index_ptr,
										double* query,
										int* indices,
										float* dists,
										int max_nn,
										float radius,
										FLANNParameters* flann_params)
{
	return _flann_radius_search(index_ptr, query, indices, dists, max_nn, radius, flann_params);
}

EXPORTED int flann_radius_search_byte(flann_index_t index_ptr,
										unsigned char* query,
										int* indices,
										float* dists,
										int max_nn,
										float radius,
										FLANNParameters* flann_params)
{
	return _flann_radius_search(index_ptr, query, indices, dists, max_nn, radius, flann_params);
}

EXPORTED int flann_radius_search_int(flann_index_t index_ptr,
										int* query,
										int* indices,
										float* dists,
										int max_nn,
										float radius,
										FLANNParameters* flann_params)
{
	return _flann_radius_search(index_ptr, query, indices, dists, max_nn, radius, flann_params);
}


template<typename T>
int _flann_free_index(flann_index_t index_ptr, FLANNParameters* flann_params)
{
	try {
		init_flann_parameters(flann_params);
        if (index_ptr==NULL) {
            throw FLANNException("Invalid index");
        }
        Index<T>* index = (Index<T>*) index_ptr;
        delete index;

        return 0;
	}
	catch(runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
        return -1;
	}
}

EXPORTED int flann_free_index(flann_index_t index_ptr, FLANNParameters* flann_params)
{
	return _flann_free_index<float>(index_ptr, flann_params);
}

EXPORTED int flann_free_index_float(flann_index_t index_ptr, FLANNParameters* flann_params)
{
	return _flann_free_index<float>(index_ptr, flann_params);
}

EXPORTED int flann_free_index_double(flann_index_t index_ptr, FLANNParameters* flann_params)
{
	return _flann_free_index<double>(index_ptr, flann_params);
}

EXPORTED int flann_free_index_byte(flann_index_t index_ptr, FLANNParameters* flann_params)
{
	return _flann_free_index<unsigned char>(index_ptr, flann_params);
}

EXPORTED int flann_free_index_int(flann_index_t index_ptr, FLANNParameters* flann_params)
{
	return _flann_free_index<int>(index_ptr, flann_params);
}



template<typename ElEM_TYPE, typename DIST_TYPE>
int _flann_compute_cluster_centers(ElEM_TYPE* dataset, int rows, int cols, int clusters, DIST_TYPE* result, FLANNParameters* flann_params)
{
	try {
		init_flann_parameters(flann_params);

		Matrix<ElEM_TYPE> inputData(dataset,rows,cols);
        KMeansIndexParams params(flann_params->branching, flann_params->iterations, flann_params->centers_init, flann_params->cb_index);
		Matrix<DIST_TYPE> centers(result,clusters, cols);
        int clusterNum = hierarchicalClustering<ElEM_TYPE,DIST_TYPE>(inputData,centers, params);

		return clusterNum;
	} catch (runtime_error& e) {
		logger.error("Caught exception: %s\n",e.what());
		return -1;
	}
}

EXPORTED int flann_compute_cluster_centers(float* dataset, int rows, int cols, int clusters, float* result, FLANNParameters* flann_params)
{
	return _flann_compute_cluster_centers(dataset, rows, cols, clusters, result, flann_params);
}

EXPORTED int flann_compute_cluster_centers_float(float* dataset, int rows, int cols, int clusters, float* result, FLANNParameters* flann_params)
{
	return _flann_compute_cluster_centers(dataset, rows, cols, clusters, result, flann_params);
}

EXPORTED int flann_compute_cluster_centers_double(double* dataset, int rows, int cols, int clusters, double* result, FLANNParameters* flann_params)
{
	return _flann_compute_cluster_centers(dataset, rows, cols, clusters, result, flann_params);
}

EXPORTED int flann_compute_cluster_centers_byte(unsigned char* dataset, int rows, int cols, int clusters, float* result, FLANNParameters* flann_params)
{
	return _flann_compute_cluster_centers(dataset, rows, cols, clusters, result, flann_params);
}

EXPORTED int flann_compute_cluster_centers_int(int* dataset, int rows, int cols, int clusters, float* result, FLANNParameters* flann_params)
{
	return _flann_compute_cluster_centers(dataset, rows, cols, clusters, result, flann_params);
}


/**
 * Functions exported to the python ctypes interface.
 */

EXPORTED void compute_ground_truth_float(float* dataset, int dataset_rows, int dataset_cols, 
                                        float* testset, int testset_rows, int testset_cols, 
                                        int* match, int match_rows, int match_cols, int skip)
{
    assert(dataset_cols==testset_cols);
    assert(testset_rows==match_rows);

    Matrix<int> _match(match, match_rows, match_cols);
    compute_ground_truth(Matrix<float>(dataset, dataset_rows, dataset_cols), Matrix<float>(testset,testset_rows, testset_cols), _match, skip);
}


EXPORTED float test_with_precision(flann_index_t index_ptr, 
                                    float* dataset, int dataset_rows, int dataset_cols, 
                                    float* testset, int testset_rows, int testset_cols, 
                                    int* matches, int matches_rows, int matches_cols,
                                    int nn, float precision, int* checks, int skip = 0)
{
    assert(dataset_cols==testset_cols);
    assert(testset_rows==matches_rows);

    try {
        if (index_ptr==NULL) {
            throw FLANNException("Invalid index");
        }

        Index<float>* index = (Index<float>*)index_ptr;
        NNIndex<float>* nn_index = index->getIndex();
        return test_index_precision(*nn_index, Matrix<float>(dataset, dataset_rows, dataset_cols), Matrix<float>(testset, testset_rows, testset_cols),
                Matrix<int>(matches, matches_rows,matches_cols), precision, *checks, nn, skip);
    } catch (runtime_error& e) {
        logger.error("Caught exception: %s\n",e.what());
        return -1;
    }
}

EXPORTED float test_with_checks(flann_index_t index_ptr, 
                                float* dataset, int dataset_rows, int dataset_cols, 
                                float* testset, int testset_rows, int testset_cols, 
                                int* matches, int matches_rows, int matches_cols,
                                int nn, int checks, float* precision, int skip = 0)
{
    assert(dataset_cols==testset_cols);
    assert(testset_rows==matches_rows);

    try {
        if (index_ptr==NULL) {
            throw FLANNException("Invalid index");
        }
        Index<float>* index = (Index<float>*)index_ptr;
        NNIndex<float>* nn_index = index->getIndex();
        return test_index_checks(*nn_index, Matrix<float>(dataset, dataset_rows, dataset_cols), Matrix<float>(testset, testset_rows, testset_cols), Matrix<int>(matches, matches_rows,matches_cols), checks, *precision, nn, skip);
    } catch (runtime_error& e) {
        logger.error("Caught exception: %s\n",e.what());
        return -1;
    }
}
