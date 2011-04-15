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

#define FLANN_FIRST_MATCH


struct FLANNParameters DEFAULT_FLANN_PARAMETERS = {
    FLANN_INDEX_KDTREE,
    32, 0.2, 0.0,
    4, 4,
    32, 11, FLANN_CENTERS_RANDOM,
    0.9, 0.01, 0, 0.1,
    FLANN_LOG_NONE, 0
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


void flann_log_verbosity(int level)
{
    flann::log_verbosity(level);
}

flann_distance_t flann_distance_type = FLANN_DIST_EUCLIDEAN;
int flann_distance_order = 3;

void flann_set_distance_type(flann_distance_t distance_type, int order)
{
    flann_distance_type = distance_type;
    flann_distance_order = order;
}


template<typename Distance>
flann_index_t __flann_build_index(typename Distance::ElementType* dataset, int rows, int cols, float* speedup,
                                  FLANNParameters* flann_params, Distance d = Distance())
{
    typedef typename Distance::ElementType ElementType;
    try {

        init_flann_parameters(flann_params);
        if (flann_params == NULL) {
            throw FLANNException("The flann_params argument must be non-null");
        }
        IndexParams* params = IndexParams::createFromParameters(*flann_params);
        Index<Distance>* index = new Index<Distance>(Matrix<ElementType>(dataset,rows,cols), *params, d);
        index->buildIndex();
        const IndexParams* index_params = index->getIndexParameters();
        index_params->toParameters(*flann_params);

        if (index->getIndex()->getType()==FLANN_INDEX_AUTOTUNED) {
            AutotunedIndex<Distance>* autotuned_index = (AutotunedIndex<Distance>*)index->getIndex();
            flann_params->checks = autotuned_index->getSearchParameters()->checks;
            *speedup = autotuned_index->getSpeedup();
        }

        delete params;
        return index;
    }
    catch (std::runtime_error& e) {
        logger.error("Caught exception: %s\n",e.what());
        return NULL;
    }
}

template<typename T>
flann_index_t _flann_build_index(T* dataset, int rows, int cols, float* speedup, FLANNParameters* flann_params)
{
    if (flann_distance_type==FLANN_DIST_EUCLIDEAN) {
        return __flann_build_index<L2<T> >(dataset, rows, cols, speedup, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_MANHATTAN) {
        return __flann_build_index<L1<T> >(dataset, rows, cols, speedup, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_MINKOWSKI) {
        return __flann_build_index<MinkowskiDistance<T> >(dataset, rows, cols, speedup, flann_params, MinkowskiDistance<T>(flann_distance_order));
    }
    else if (flann_distance_type==FLANN_DIST_HIST_INTERSECT) {
        return __flann_build_index<HistIntersectionDistance<T> >(dataset, rows, cols, speedup, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_HELLINGER) {
        return __flann_build_index<HellingerDistance<T> >(dataset, rows, cols, speedup, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_CHI_SQUARE) {
        return __flann_build_index<ChiSquareDistance<T> >(dataset, rows, cols, speedup, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_KULLBACK_LEIBLER) {
        return __flann_build_index<KL_Divergence<T> >(dataset, rows, cols, speedup, flann_params);
    }
    else {
        logger.error( "Distance type unsupported in the C bindings, use the C++ bindings instead\n");
        return NULL;
    }
}

flann_index_t flann_build_index(float* dataset, int rows, int cols, float* speedup, FLANNParameters* flann_params)
{
    return _flann_build_index<float>(dataset, rows, cols, speedup, flann_params);
}

flann_index_t flann_build_index_float(float* dataset, int rows, int cols, float* speedup, FLANNParameters* flann_params)
{
    return _flann_build_index<float>(dataset, rows, cols, speedup, flann_params);
}

flann_index_t flann_build_index_double(double* dataset, int rows, int cols, float* speedup, FLANNParameters* flann_params)
{
    return _flann_build_index<double>(dataset, rows, cols, speedup, flann_params);
}

flann_index_t flann_build_index_byte(unsigned char* dataset, int rows, int cols, float* speedup, FLANNParameters* flann_params)
{
    return _flann_build_index<unsigned char>(dataset, rows, cols, speedup, flann_params);
}

flann_index_t flann_build_index_int(int* dataset, int rows, int cols, float* speedup, FLANNParameters* flann_params)
{
    return _flann_build_index<int>(dataset, rows, cols, speedup, flann_params);
}

template<typename Distance>
int __flann_save_index(flann_index_t index_ptr, char* filename)
{
    try {
        if (index_ptr==NULL) {
            throw FLANNException("Invalid index");
        }

        Index<Distance>* index = (Index<Distance>*)index_ptr;
        index->save(filename);

        return 0;
    }
    catch (std::runtime_error& e) {
        logger.error("Caught exception: %s\n",e.what());
        return -1;
    }
}

template<typename T>
int _flann_save_index(flann_index_t index_ptr, char* filename)
{
    if (flann_distance_type==FLANN_DIST_EUCLIDEAN) {
        return __flann_save_index<L2<T> >(index_ptr, filename);
    }
    else if (flann_distance_type==FLANN_DIST_MANHATTAN) {
        return __flann_save_index<L1<T> >(index_ptr, filename);
    }
    else if (flann_distance_type==FLANN_DIST_MINKOWSKI) {
        return __flann_save_index<MinkowskiDistance<T> >(index_ptr, filename);
    }
    else if (flann_distance_type==FLANN_DIST_HIST_INTERSECT) {
        return __flann_save_index<HistIntersectionDistance<T> >(index_ptr, filename);
    }
    else if (flann_distance_type==FLANN_DIST_HELLINGER) {
        return __flann_save_index<HellingerDistance<T> >(index_ptr, filename);
    }
    else if (flann_distance_type==FLANN_DIST_CHI_SQUARE) {
        return __flann_save_index<ChiSquareDistance<T> >(index_ptr, filename);
    }
    else if (flann_distance_type==FLANN_DIST_KULLBACK_LEIBLER) {
        return __flann_save_index<KL_Divergence<T> >(index_ptr, filename);
    }
    else {
        logger.error( "Distance type unsupported in the C bindings, use the C++ bindings instead\n");
        return -1;
    }
}

int flann_save_index(flann_index_t index_ptr, char* filename)
{
    return _flann_save_index<float>(index_ptr, filename);
}

int flann_save_index_float(flann_index_t index_ptr, char* filename)
{
    return _flann_save_index<float>(index_ptr, filename);
}

int flann_save_index_double(flann_index_t index_ptr, char* filename)
{
    return _flann_save_index<double>(index_ptr, filename);
}

int flann_save_index_byte(flann_index_t index_ptr, char* filename)
{
    return _flann_save_index<unsigned char>(index_ptr, filename);
}

int flann_save_index_int(flann_index_t index_ptr, char* filename)
{
    return _flann_save_index<int>(index_ptr, filename);
}


template<typename Distance>
flann_index_t __flann_load_index(char* filename, typename Distance::ElementType* dataset, int rows, int cols,
                                 Distance d = Distance())
{
    try {
        Index<Distance>* index = new Index<Distance>(Matrix<typename Distance::ElementType>(dataset,rows,cols), SavedIndexParams(filename), d);
        return index;
    }
    catch (std::runtime_error& e) {
        logger.error("Caught exception: %s\n",e.what());
        return NULL;
    }
}

template<typename T>
flann_index_t _flann_load_index(char* filename, T* dataset, int rows, int cols)
{
    if (flann_distance_type==FLANN_DIST_EUCLIDEAN) {
        return __flann_load_index<L2<T> >(filename, dataset, rows, cols);
    }
    else if (flann_distance_type==FLANN_DIST_MANHATTAN) {
        return __flann_load_index<L1<T> >(filename, dataset, rows, cols);
    }
    else if (flann_distance_type==FLANN_DIST_MINKOWSKI) {
        return __flann_load_index<MinkowskiDistance<T> >(filename, dataset, rows, cols, MinkowskiDistance<T>(flann_distance_order));
    }
    else if (flann_distance_type==FLANN_DIST_HIST_INTERSECT) {
        return __flann_load_index<HistIntersectionDistance<T> >(filename, dataset, rows, cols);
    }
    else if (flann_distance_type==FLANN_DIST_HELLINGER) {
        return __flann_load_index<HellingerDistance<T> >(filename, dataset, rows, cols);
    }
    else if (flann_distance_type==FLANN_DIST_CHI_SQUARE) {
        return __flann_load_index<ChiSquareDistance<T> >(filename, dataset, rows, cols);
    }
    else if (flann_distance_type==FLANN_DIST_KULLBACK_LEIBLER) {
        return __flann_load_index<KL_Divergence<T> >(filename, dataset, rows, cols);
    }
    else {
        logger.error( "Distance type unsupported in the C bindings, use the C++ bindings instead\n");
        return NULL;
    }
}


flann_index_t flann_load_index(char* filename, float* dataset, int rows, int cols)
{
    return _flann_load_index<float>(filename, dataset, rows, cols);
}

flann_index_t flann_load_index_float(char* filename, float* dataset, int rows, int cols)
{
    return _flann_load_index<float>(filename, dataset, rows, cols);
}

flann_index_t flann_load_index_double(char* filename, double* dataset, int rows, int cols)
{
    return _flann_load_index<double>(filename, dataset, rows, cols);
}

flann_index_t flann_load_index_byte(char* filename, unsigned char* dataset, int rows, int cols)
{
    return _flann_load_index<unsigned char>(filename, dataset, rows, cols);
}

flann_index_t flann_load_index_int(char* filename, int* dataset, int rows, int cols)
{
    return _flann_load_index<int>(filename, dataset, rows, cols);
}



template<typename Distance>
int __flann_find_nearest_neighbors(typename Distance::ElementType* dataset,  int rows, int cols, typename Distance::ElementType* testset, int tcount,
                                   int* result, typename Distance::ResultType* dists, int nn, FLANNParameters* flann_params, Distance d = Distance())
{
    typedef typename Distance::ElementType ElementType;
    typedef typename Distance::ResultType DistanceType;
    try {
        init_flann_parameters(flann_params);

        IndexParams* params = IndexParams::createFromParameters(*flann_params);
        Index<Distance>* index = new Index<Distance>(Matrix<ElementType>(dataset,rows,cols), *params, d);
        index->buildIndex();
        Matrix<int> m_indices(result,tcount, nn);
        Matrix<DistanceType> m_dists(dists,tcount, nn);
        index->knnSearch(Matrix<ElementType>(testset, tcount, index->veclen()),
                         m_indices,
                         m_dists, nn, SearchParams(flann_params->checks) );
        delete index;
        delete params;
        return 0;
    }
    catch (std::runtime_error& e) {
        logger.error("Caught exception: %s\n",e.what());
        return -1;
    }

    return -1;
}

template<typename T, typename R>
int _flann_find_nearest_neighbors(T* dataset,  int rows, int cols, T* testset, int tcount,
                                  int* result, R* dists, int nn, FLANNParameters* flann_params)
{
    if (flann_distance_type==FLANN_DIST_EUCLIDEAN) {
        return __flann_find_nearest_neighbors<L2<T> >(dataset, rows, cols, testset, tcount, result, dists, nn, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_MANHATTAN) {
        return __flann_find_nearest_neighbors<L1<T> >(dataset, rows, cols, testset, tcount, result, dists, nn, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_MINKOWSKI) {
        return __flann_find_nearest_neighbors<MinkowskiDistance<T> >(dataset, rows, cols, testset, tcount, result, dists, nn, flann_params, MinkowskiDistance<T>(flann_distance_order));
    }
    else if (flann_distance_type==FLANN_DIST_HIST_INTERSECT) {
        return __flann_find_nearest_neighbors<HistIntersectionDistance<T> >(dataset, rows, cols, testset, tcount, result, dists, nn, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_HELLINGER) {
        return __flann_find_nearest_neighbors<HellingerDistance<T> >(dataset, rows, cols, testset, tcount, result, dists, nn, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_CHI_SQUARE) {
        return __flann_find_nearest_neighbors<ChiSquareDistance<T> >(dataset, rows, cols, testset, tcount, result, dists, nn, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_KULLBACK_LEIBLER) {
        return __flann_find_nearest_neighbors<KL_Divergence<T> >(dataset, rows, cols, testset, tcount, result, dists, nn, flann_params);
    }
    else {
        logger.error( "Distance type unsupported in the C bindings, use the C++ bindings instead\n");
        return -1;
    }
}

int flann_find_nearest_neighbors(float* dataset,  int rows, int cols, float* testset, int tcount, int* result, float* dists, int nn, FLANNParameters* flann_params)
{
    return _flann_find_nearest_neighbors(dataset, rows, cols, testset, tcount, result, dists, nn, flann_params);
}

int flann_find_nearest_neighbors_float(float* dataset,  int rows, int cols, float* testset, int tcount, int* result, float* dists, int nn, FLANNParameters* flann_params)
{
    return _flann_find_nearest_neighbors(dataset, rows, cols, testset, tcount, result, dists, nn, flann_params);
}

int flann_find_nearest_neighbors_double(double* dataset,  int rows, int cols, double* testset, int tcount, int* result, double* dists, int nn, FLANNParameters* flann_params)
{
    return _flann_find_nearest_neighbors(dataset, rows, cols, testset, tcount, result, dists, nn, flann_params);
}

int flann_find_nearest_neighbors_byte(unsigned char* dataset,  int rows, int cols, unsigned char* testset, int tcount, int* result, float* dists, int nn, FLANNParameters* flann_params)
{
    return _flann_find_nearest_neighbors(dataset, rows, cols, testset, tcount, result, dists, nn, flann_params);
}

int flann_find_nearest_neighbors_int(int* dataset,  int rows, int cols, int* testset, int tcount, int* result, float* dists, int nn, FLANNParameters* flann_params)
{
    return _flann_find_nearest_neighbors(dataset, rows, cols, testset, tcount, result, dists, nn, flann_params);
}


template<typename Distance>
int __flann_find_nearest_neighbors_index(flann_index_t index_ptr, typename Distance::ElementType* testset, int tcount,
                                         int* result, typename Distance::ResultType* dists, int nn, FLANNParameters* flann_params)
{
    typedef typename Distance::ElementType ElementType;
    typedef typename Distance::ResultType DistanceType;

    try {
        init_flann_parameters(flann_params);
        if (index_ptr==NULL) {
            throw FLANNException("Invalid index");
        }
        Index<Distance>* index = (Index<Distance>*)index_ptr;

        Matrix<int> m_indices(result,tcount, nn);
        Matrix<DistanceType> m_dists(dists, tcount, nn);

        index->knnSearch(Matrix<ElementType>(testset, tcount, index->veclen()),
                         m_indices,
                         m_dists, nn, SearchParams(flann_params->checks) );

        return 0;
    }
    catch (std::runtime_error& e) {
        logger.error("Caught exception: %s\n",e.what());
        return -1;
    }

    return -1;
}

template<typename T, typename R>
int _flann_find_nearest_neighbors_index(flann_index_t index_ptr, T* testset, int tcount,
                                        int* result, R* dists, int nn, FLANNParameters* flann_params)
{
    if (flann_distance_type==FLANN_DIST_EUCLIDEAN) {
        return __flann_find_nearest_neighbors_index<L2<T> >(index_ptr, testset, tcount, result, dists, nn, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_MANHATTAN) {
        return __flann_find_nearest_neighbors_index<L1<T> >(index_ptr, testset, tcount, result, dists, nn, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_MINKOWSKI) {
        return __flann_find_nearest_neighbors_index<MinkowskiDistance<T> >(index_ptr, testset, tcount, result, dists, nn, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_HIST_INTERSECT) {
        return __flann_find_nearest_neighbors_index<HistIntersectionDistance<T> >(index_ptr, testset, tcount, result, dists, nn, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_HELLINGER) {
        return __flann_find_nearest_neighbors_index<HellingerDistance<T> >(index_ptr, testset, tcount, result, dists, nn, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_CHI_SQUARE) {
        return __flann_find_nearest_neighbors_index<ChiSquareDistance<T> >(index_ptr, testset, tcount, result, dists, nn, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_KULLBACK_LEIBLER) {
        return __flann_find_nearest_neighbors_index<KL_Divergence<T> >(index_ptr, testset, tcount, result, dists, nn, flann_params);
    }
    else {
        logger.error( "Distance type unsupported in the C bindings, use the C++ bindings instead\n");
        return -1;
    }
}


int flann_find_nearest_neighbors_index(flann_index_t index_ptr, float* testset, int tcount, int* result, float* dists, int nn, FLANNParameters* flann_params)
{
    return _flann_find_nearest_neighbors_index(index_ptr, testset, tcount, result, dists, nn, flann_params);
}

int flann_find_nearest_neighbors_index_float(flann_index_t index_ptr, float* testset, int tcount, int* result, float* dists, int nn, FLANNParameters* flann_params)
{
    return _flann_find_nearest_neighbors_index(index_ptr, testset, tcount, result, dists, nn, flann_params);
}

int flann_find_nearest_neighbors_index_double(flann_index_t index_ptr, double* testset, int tcount, int* result, double* dists, int nn, FLANNParameters* flann_params)
{
    return _flann_find_nearest_neighbors_index(index_ptr, testset, tcount, result, dists, nn, flann_params);
}

int flann_find_nearest_neighbors_index_byte(flann_index_t index_ptr, unsigned char* testset, int tcount, int* result, float* dists, int nn, FLANNParameters* flann_params)
{
    return _flann_find_nearest_neighbors_index(index_ptr, testset, tcount, result, dists, nn, flann_params);
}

int flann_find_nearest_neighbors_index_int(flann_index_t index_ptr, int* testset, int tcount, int* result, float* dists, int nn, FLANNParameters* flann_params)
{
    return _flann_find_nearest_neighbors_index(index_ptr, testset, tcount, result, dists, nn, flann_params);
}


template<typename Distance>
int __flann_radius_search(flann_index_t index_ptr,
                          typename Distance::ElementType* query,
                          int* indices,
                          typename Distance::ResultType* dists,
                          int max_nn,
                          float radius,
                          FLANNParameters* flann_params)
{
    typedef typename Distance::ElementType ElementType;
    typedef typename Distance::ResultType DistanceType;

    try {
        init_flann_parameters(flann_params);
        if (index_ptr==NULL) {
            throw FLANNException("Invalid index");
        }
        Index<Distance>* index = (Index<Distance>*)index_ptr;

        Matrix<int> m_indices(indices, 1, max_nn);
        Matrix<DistanceType> m_dists(dists, 1, max_nn);
        int count = index->radiusSearch(Matrix<ElementType>(query, 1, index->veclen()),
                                        m_indices,
                                        m_dists, radius, SearchParams(flann_params->checks) );


        return count;
    }
    catch (std::runtime_error& e) {
        logger.error("Caught exception: %s\n",e.what());
        return -1;
    }
}

template<typename T, typename R>
int _flann_radius_search(flann_index_t index_ptr,
                         T* query,
                         int* indices,
                         R* dists,
                         int max_nn,
                         float radius,
                         FLANNParameters* flann_params)
{
    if (flann_distance_type==FLANN_DIST_EUCLIDEAN) {
        return __flann_radius_search<L2<T> >(index_ptr, query, indices, dists, max_nn, radius, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_MANHATTAN) {
        return __flann_radius_search<L1<T> >(index_ptr, query, indices, dists, max_nn, radius, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_MINKOWSKI) {
        return __flann_radius_search<MinkowskiDistance<T> >(index_ptr, query, indices, dists, max_nn, radius, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_HIST_INTERSECT) {
        return __flann_radius_search<HistIntersectionDistance<T> >(index_ptr, query, indices, dists, max_nn, radius, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_HELLINGER) {
        return __flann_radius_search<HellingerDistance<T> >(index_ptr, query, indices, dists, max_nn, radius, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_CHI_SQUARE) {
        return __flann_radius_search<ChiSquareDistance<T> >(index_ptr, query, indices, dists, max_nn, radius, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_KULLBACK_LEIBLER) {
        return __flann_radius_search<KL_Divergence<T> >(index_ptr, query, indices, dists, max_nn, radius, flann_params);
    }
    else {
        logger.error( "Distance type unsupported in the C bindings, use the C++ bindings instead\n");
        return -1;
    }
}

int flann_radius_search(flann_index_t index_ptr,
                        float* query,
                        int* indices,
                        float* dists,
                        int max_nn,
                        float radius,
                        FLANNParameters* flann_params)
{
    return _flann_radius_search(index_ptr, query, indices, dists, max_nn, radius, flann_params);
}

int flann_radius_search_float(flann_index_t index_ptr,
                              float* query,
                              int* indices,
                              float* dists,
                              int max_nn,
                              float radius,
                              FLANNParameters* flann_params)
{
    return _flann_radius_search(index_ptr, query, indices, dists, max_nn, radius, flann_params);
}

int flann_radius_search_double(flann_index_t index_ptr,
                               double* query,
                               int* indices,
                               double* dists,
                               int max_nn,
                               float radius,
                               FLANNParameters* flann_params)
{
    return _flann_radius_search(index_ptr, query, indices, dists, max_nn, radius, flann_params);
}

int flann_radius_search_byte(flann_index_t index_ptr,
                             unsigned char* query,
                             int* indices,
                             float* dists,
                             int max_nn,
                             float radius,
                             FLANNParameters* flann_params)
{
    return _flann_radius_search(index_ptr, query, indices, dists, max_nn, radius, flann_params);
}

int flann_radius_search_int(flann_index_t index_ptr,
                            int* query,
                            int* indices,
                            float* dists,
                            int max_nn,
                            float radius,
                            FLANNParameters* flann_params)
{
    return _flann_radius_search(index_ptr, query, indices, dists, max_nn, radius, flann_params);
}


template<typename Distance>
int __flann_free_index(flann_index_t index_ptr, FLANNParameters* flann_params)
{
    try {
        init_flann_parameters(flann_params);
        if (index_ptr==NULL) {
            throw FLANNException("Invalid index");
        }
        Index<Distance>* index = (Index<Distance>*)index_ptr;
        delete index;

        return 0;
    }
    catch (std::runtime_error& e) {
        logger.error("Caught exception: %s\n",e.what());
        return -1;
    }
}

template<typename T>
int _flann_free_index(flann_index_t index_ptr, FLANNParameters* flann_params)
{
    if (flann_distance_type==FLANN_DIST_EUCLIDEAN) {
        return __flann_free_index<L2<T> >(index_ptr, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_MANHATTAN) {
        return __flann_free_index<L1<T> >(index_ptr, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_MINKOWSKI) {
        return __flann_free_index<MinkowskiDistance<T> >(index_ptr, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_HIST_INTERSECT) {
        return __flann_free_index<HistIntersectionDistance<T> >(index_ptr, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_HELLINGER) {
        return __flann_free_index<HellingerDistance<T> >(index_ptr, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_CHI_SQUARE) {
        return __flann_free_index<ChiSquareDistance<T> >(index_ptr, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_KULLBACK_LEIBLER) {
        return __flann_free_index<KL_Divergence<T> >(index_ptr, flann_params);
    }
    else {
        logger.error( "Distance type unsupported in the C bindings, use the C++ bindings instead\n");
        return -1;
    }
}

int flann_free_index(flann_index_t index_ptr, FLANNParameters* flann_params)
{
    return _flann_free_index<float>(index_ptr, flann_params);
}

int flann_free_index_float(flann_index_t index_ptr, FLANNParameters* flann_params)
{
    return _flann_free_index<float>(index_ptr, flann_params);
}

int flann_free_index_double(flann_index_t index_ptr, FLANNParameters* flann_params)
{
    return _flann_free_index<double>(index_ptr, flann_params);
}

int flann_free_index_byte(flann_index_t index_ptr, FLANNParameters* flann_params)
{
    return _flann_free_index<unsigned char>(index_ptr, flann_params);
}

int flann_free_index_int(flann_index_t index_ptr, FLANNParameters* flann_params)
{
    return _flann_free_index<int>(index_ptr, flann_params);
}


template<typename Distance>
int __flann_compute_cluster_centers(typename Distance::ElementType* dataset, int rows, int cols, int clusters,
                                    typename Distance::ResultType* result, FLANNParameters* flann_params, Distance d = Distance())
{
    typedef typename Distance::ElementType ElementType;
    typedef typename Distance::ResultType DistanceType;

    try {
        init_flann_parameters(flann_params);

        Matrix<ElementType> inputData(dataset,rows,cols);
        KMeansIndexParams params(flann_params->branching, flann_params->iterations, flann_params->centers_init, flann_params->cb_index);
        Matrix<DistanceType> centers(result,clusters,cols);
        int clusterNum = hierarchicalClustering<Distance>(inputData, centers, params, d);

        return clusterNum;
    }
    catch (std::runtime_error& e) {
        logger.error("Caught exception: %s\n",e.what());
        return -1;
    }
}


template<typename T, typename R>
int _flann_compute_cluster_centers(T* dataset, int rows, int cols, int clusters, R* result, FLANNParameters* flann_params)
{
    if (flann_distance_type==FLANN_DIST_EUCLIDEAN) {
        return __flann_compute_cluster_centers<L2<T> >(dataset, rows, cols, clusters, result, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_MANHATTAN) {
        return __flann_compute_cluster_centers<L1<T> >(dataset, rows, cols, clusters, result, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_MINKOWSKI) {
        return __flann_compute_cluster_centers<MinkowskiDistance<T> >(dataset, rows, cols, clusters, result, flann_params, MinkowskiDistance<T>(flann_distance_order));
    }
    else if (flann_distance_type==FLANN_DIST_HIST_INTERSECT) {
        return __flann_compute_cluster_centers<HistIntersectionDistance<T> >(dataset, rows, cols, clusters, result, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_HELLINGER) {
        return __flann_compute_cluster_centers<HellingerDistance<T> >(dataset, rows, cols, clusters, result, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_CHI_SQUARE) {
        return __flann_compute_cluster_centers<ChiSquareDistance<T> >(dataset, rows, cols, clusters, result, flann_params);
    }
    else if (flann_distance_type==FLANN_DIST_KULLBACK_LEIBLER) {
        return __flann_compute_cluster_centers<KL_Divergence<T> >(dataset, rows, cols, clusters, result, flann_params);
    }
    else {
        logger.error( "Distance type unsupported in the C bindings, use the C++ bindings instead\n");
        return -1;
    }
}

int flann_compute_cluster_centers(float* dataset, int rows, int cols, int clusters, float* result, FLANNParameters* flann_params)
{
    return _flann_compute_cluster_centers(dataset, rows, cols, clusters, result, flann_params);
}

int flann_compute_cluster_centers_float(float* dataset, int rows, int cols, int clusters, float* result, FLANNParameters* flann_params)
{
    return _flann_compute_cluster_centers(dataset, rows, cols, clusters, result, flann_params);
}

int flann_compute_cluster_centers_double(double* dataset, int rows, int cols, int clusters, double* result, FLANNParameters* flann_params)
{
    return _flann_compute_cluster_centers(dataset, rows, cols, clusters, result, flann_params);
}

int flann_compute_cluster_centers_byte(unsigned char* dataset, int rows, int cols, int clusters, float* result, FLANNParameters* flann_params)
{
    return _flann_compute_cluster_centers(dataset, rows, cols, clusters, result, flann_params);
}

int flann_compute_cluster_centers_int(int* dataset, int rows, int cols, int clusters, float* result, FLANNParameters* flann_params)
{
    return _flann_compute_cluster_centers(dataset, rows, cols, clusters, result, flann_params);
}

