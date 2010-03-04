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

#ifndef FLANN_HPP_
#define FLANN_HPP_

#include <vector>
#include <string>
#include <cassert>

#include "flann/flann.h"
#include "flann/constants.h"
#include "flann/util/common.h"
#include "flann/util/matrix.h"
#include "algorithms/nn_index.h"
#include "flann/util/result_set.h"
#include "flann/nn/index_testing.h"

#include "flann/algorithms/kdtree_index.h"
#include "flann/algorithms/kdtree_mt_index.h"
#include "flann/algorithms/kmeans_index.h"
#include "flann/algorithms/composite_index.h"
#include "flann/algorithms/linear_index.h"
#include "flann/algorithms/autotuned_index.h"

namespace flann
{

class IndexFactory
{
public:
	virtual flann_algorithm_t getIndexType() const = 0;

	virtual NNIndex* createIndex(const Matrix<float>& dataset) const = 0;
};

struct IndexParams : public IndexFactory {
protected:
	IndexParams() {};

public:

	static IndexParams* createFromParameters(const FLANNParameters& p);

	virtual flann_algorithm_t getIndexType() const = 0;
	virtual NNIndex* createIndex(const Matrix<float>& dataset) const = 0;

	virtual void fromParameters(const FLANNParameters& p) {};
	virtual void toParameters(FLANNParameters& p) { };
};

struct LinearIndexParams : public IndexParams {
	LinearIndexParams() {};

	flann_algorithm_t getIndexType() { return LINEAR; }
};



struct KDTreeIndexParams : public IndexParams {
	KDTreeIndexParams(int trees_ = 4) : trees(trees_) {};

	int trees;                 // number of randomized trees to use (for kdtree)

	flann_algorithm_t getIndexType() const { return KDTREE; }

	NNIndex* createIndex(const Matrix<float>& dataset) const;

	void fromParameters(const FLANNParameters& p)
	{
		trees = p.trees;
	}

	void toParameters(FLANNParameters& p)
	{
		p.algorithm = KDTREE;
		p.trees = trees;
	};

};


struct KDTreeMTIndexParams : public IndexParams {
	KDTreeMTIndexParams(int trees_ = 4) : trees(trees_) {};

	int trees;                 // number of randomized trees to use (for kdtree)

	flann_algorithm_t getIndexType() const { return KDTREE_MT; }

	NNIndex* createIndex(const Matrix<float>& dataset) const;

	void fromParameters(const FLANNParameters& p)
	{
		trees = p.trees;
	}

	void toParameters(FLANNParameters& p)
	{
		p.algorithm = KDTREE_MT;
		p.trees = trees;
	};

};


struct KMeansIndexParams : public IndexParams {
	KMeansIndexParams(int branching_ = 32, int iterations_ = 11,
			flann_centers_init_t centers_init_ = CENTERS_RANDOM, float cb_index_ = 0.2 ) :
		branching(branching_),
		iterations(iterations_),
		centers_init(centers_init_),
		cb_index(cb_index_) {};

	int branching;             // branching factor (for kmeans tree)
	int iterations;            // max iterations to perform in one kmeans clustering (kmeans tree)
	flann_centers_init_t centers_init;          // algorithm used for picking the initial cluster centers for kmeans tree
    float cb_index;            // cluster boundary index. Used when searching the kmeans tree

	flann_algorithm_t getIndexType() const { return KMEANS; }

    NNIndex* createIndex(const Matrix<float>& dataset) const;

	void fromParameters(const FLANNParameters& p)
	{
		branching = p.branching;
		iterations = p.iterations;
		centers_init = p.centers_init;
		cb_index = p.cb_index;
	}

	void toParameters(FLANNParameters& p)
	{
		p.algorithm = KMEANS;
		p.branching = branching;
		p.iterations = iterations;
		p.centers_init = centers_init;
		p.cb_index = cb_index;
	};

};


struct CompositeIndexParams : public IndexParams {
	CompositeIndexParams(int trees_ = 4, int branching_ = 32, int iterations_ = 11,
			flann_centers_init_t centers_init_ = CENTERS_RANDOM, float cb_index_ = 0.2 ) :
		trees(trees_),
		branching(branching_),
		iterations(iterations_),
		centers_init(centers_init_),
		cb_index(cb_index_) {};

	int trees;                 // number of randomized trees to use (for kdtree)
	int branching;             // branching factor (for kmeans tree)
	int iterations;            // max iterations to perform in one kmeans clustering (kmeans tree)
	flann_centers_init_t centers_init;          // algorithm used for picking the initial cluster centers for kmeans tree
    float cb_index;            // cluster boundary index. Used when searching the kmeans tree

	flann_algorithm_t getIndexType() const { return COMPOSITE; }

    NNIndex* createIndex(const Matrix<float>& dataset) const;

	void fromParameters(const FLANNParameters& p)
	{
		trees = p.trees;
		branching = p.branching;
		iterations = p.iterations;
		centers_init = p.centers_init;
		cb_index = p.cb_index;
	}

	void toParameters(FLANNParameters& p)
	{
		p.algorithm = COMPOSITE;
		p.trees = trees;
		p.branching = branching;
		p.iterations = iterations;
		p.centers_init = centers_init;
		p.cb_index = cb_index;
	};
};


struct AutotunedIndexParams : public IndexParams {
	AutotunedIndexParams( float target_precision_ = 0.9, float build_weight_ = 0.01,
			float memory_weight_ = 0, float sample_fraction_ = 0.1) :
		target_precision(target_precision_),
		build_weight(build_weight_),
		memory_weight(memory_weight_),
		sample_fraction(sample_fraction_) {};

	float target_precision;    // precision desired (used for autotuning, -1 otherwise)
	float build_weight;        // build tree time weighting factor
	float memory_weight;       // index memory weighting factor
    float sample_fraction;     // what fraction of the dataset to use for autotuning

	flann_algorithm_t getIndexType() const { return AUTOTUNED; }

    NNIndex* createIndex(const Matrix<float>& dataset) const;

	void fromParameters(const FLANNParameters& p)
	{
		target_precision = p.target_precision;
		build_weight = p.build_weight;
		memory_weight = p.memory_weight;
		sample_fraction = p.sample_fraction;
	}

	void toParameters(FLANNParameters& p)
	{
		p.algorithm = AUTOTUNED;
		p.target_precision = target_precision;
		p.build_weight = build_weight;
		p.memory_weight = memory_weight;
		p.sample_fraction = sample_fraction;
	};
};


struct SavedIndexParams : public IndexParams {
	SavedIndexParams() {
		throw FLANNException("I don't know which index to load");
	}
	SavedIndexParams(std::string filename_) : filename(filename_) {}

	std::string filename;		// filename of the stored index

	flann_algorithm_t getIndexType() const { return SAVED; }

	NNIndex* createIndex(const Matrix<float>& dataset) const;
};


struct SearchParams {
	SearchParams(int checks_ = 32) :
		checks(checks_) {};

	int checks;
};


template<typename T>
class Index {
	NNIndex* nnIndex;

public:
	Index(const Matrix<T>& features, const IndexParams& params);

	~Index();

	void buildIndex();

	void knnSearch(const Matrix<T>& queries, Matrix<int>& indices, Matrix<float>& dists, int knn, const SearchParams& params);

	int radiusSearch(const Matrix<T>& query, Matrix<int>& indices, Matrix<float>& dists, float radius, const SearchParams& params);

	void save(std::string filename);

	int veclen() const;

	int size() const;

	NNIndex* index() { return nnIndex; }
};


template<typename T>
Index<T>::Index(const Matrix<T>& dataset, const IndexParams& params)
{
	flann_algorithm_t index_type = params.getIndexType();

	switch (index_type) {
	case LINEAR:
		nnIndex = new LinearIndex<T>(dataset, params);
		break;
	case KDTREE:
		nnIndex = new KDTreeIndex<T>(dataset, params);
		break;
	case KDTREE_MT:
		nnIndex = new KDTreeMTIndex<T>(dataset, params);
		break;
	case KMEANS:
		nnIndex = new KMeansIndex<T>(dataset, params);
		break;
	case COMPOSITE:
		nnIndex = new CompositeIndex<T>(dataset, params);
		break;
	case AUTOTUNED:
		nnIndex = new AutotunedIndex<T>(dataset, params);
		break;
	case SAVED:
		nnIndex = new SavedIndexParams<T>(dataset, params);
		break;
	default:
		throw FLANNException("Unknown index type");
	}
}

template<typename T>
Index<T>::~Index()
{
	delete nnIndex;
}

template<typename T>
void Index<T>::buildIndex()
{
	nnIndex->buildIndex();
}

template<typename T>
void Index<T>::knnSearch(const Matrix<T>& queries, Matrix<int>& indices, Matrix<float>& dists, int knn, const SearchParams& searchParams)
{
	assert(queries.cols==nnIndex->veclen());
	assert(indices.rows>=queries.rows);
	assert(dists.rows>=queries.rows);
	assert(indices.cols>=knn);
	assert(dists.cols>=knn);

    search_for_neighbors(*nnIndex, queries, indices, dists, searchParams);
}

template<typename T>
int Index<T>::radiusSearch(const Matrix<T>& query, Matrix<int>& indices, Matrix<float>& dists, float radius, const SearchParams& searchParams)
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


template<typename T>
void Index<T>::save(string filename)
{
	FILE* fout = fopen(filename.c_str(), "wb");
	if (fout==NULL) {
		throw FLANNException("Cannot open file");
	}
	nnIndex->saveIndex(fout);
	fclose(fout);
}


template<typename T>
int Index<T>::size() const
{
	return nnIndex->size();
}

template<typename T>
int Index<T>::veclen() const
{
	return nnIndex->veclen();
}



int hierarchicalClustering(const Matrix<float>& features, Matrix<float>& centers, const KMeansIndexParams& params);


}
#endif /* FLANN_HPP_ */
