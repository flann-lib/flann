/***********************************************************************
 * Software License Agreement (BSD License)
 *
 * Copyright 2008-2010  Marius Muja (mariusm@cs.ubc.ca). All rights reserved.
 * Copyright 2008-2010  David G. Lowe (lowe@cs.ubc.ca). All rights reserved.
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


#ifndef FLANN_MPI_HPP_
#define FLANN_MPI_HPP_

#include <boost/mpi.hpp>
#include <boost/serialization/array.hpp>
#include <flann/flann.hpp>
#include <flann/io/hdf5.h>

namespace flann
{
namespace mpi
{

struct SearchResults
{
	flann::Matrix<int> indices;
	flann::Matrix<float> dists;

	template<typename Archive>
	void serialize(Archive& ar, const unsigned int version)
	{
		ar & indices.rows;
		ar & indices.cols;
        if(Archive::is_loading::value) {
            indices.data = new int[indices.rows*indices.cols];
        }
		ar & boost::serialization::make_array(indices.data, indices.rows*indices.cols);
        if(Archive::is_saving::value) {
        	indices.free();
        }
		ar & dists.rows;
		ar & dists.cols;
        if(Archive::is_loading::value) {
            dists.data = new float[dists.rows*dists.cols];
        }
		ar & boost::serialization::make_array(dists.data, dists.rows*dists.cols);
        if(Archive::is_saving::value) {
        	dists.free();
        }
	}
};


struct ResultsMerger
{
	SearchResults operator()(SearchResults a, SearchResults b)
	{
		SearchResults results;
		results.indices.rows = a.indices.rows;
		results.indices.cols = a.indices.cols;
		results.indices.data = new int[results.indices.rows*results.indices.cols];
		results.dists.rows = a.dists.rows;
		results.dists.cols = a.dists.cols;
		results.dists.data = new float[results.dists.rows*results.dists.cols];


		for (size_t i=0;i<results.dists.rows;++i) {
			size_t idx = 0;
			size_t a_idx = 0;
			size_t b_idx = 0;
			while (idx<results.dists.cols) {
				if (a.dists[i][a_idx]<=b.dists[i][b_idx]) {
					results.dists[i][idx] = a.dists[i][a_idx];
					results.indices[i][idx] = a.indices[i][a_idx];
					idx++;
					a_idx++;
				}
				else {
					results.dists[i][idx] = b.dists[i][b_idx];
					results.indices[i][idx] = b.indices[i][b_idx];
					idx++;
					b_idx++;
				}
			}
		}

		a.indices.free();
		a.dists.free();
		b.indices.free();
		b.dists.free();
		return results;
	}
};



template<typename T>
class Index {
	flann::Index<T>* flann_index;
	flann::Matrix<T> dataset;
	int size_;
	int offset_;

public:
	Index(const std::string& file_name,
			const std::string& dataset_name,
			const IndexParams& params);

	~Index();

	void buildIndex() { flann_index->buildIndex(); }

	void knnSearch(const flann::Matrix<T>& queries,
			flann::Matrix<int>& indices,
			flann::Matrix<float>& dists,
			int knn, const
			SearchParams& params);

	int radiusSearch(const flann::Matrix<T>& query,
			flann::Matrix<int>& indices,
			flann::Matrix<float>& dists,
			float radius,
			const SearchParams& params);

//	void save(std::string filename);

	int veclen() const { return flann_index->veclen(); }

	int size() const { return size_; }

	const IndexParams* getIndexParameters() { return flann_index->getParameters(); }
};


template<typename T>
Index<T>::Index(const std::string& file_name, const std::string& dataset_name, const IndexParams& params)
{
	boost::mpi::communicator world;
	flann_algorithm_t index_type = params.getIndexType();
	if (index_type==SAVED) {
		throw FLANNException("Saving/loading of MPI indexes is not currently supported.");
	}
	flann::mpi::load_from_file(dataset,file_name, dataset_name);
	flann_index = new flann::Index<T>(dataset, params);

	std::vector<int> sizes;
	// get the sizes of all MPI indices
	all_gather(world, flann_index->size(), sizes);
	size_ = 0;
	offset_ = 0;
	for (size_t i=0;i<sizes.size();++i) {
		if (i<world.rank()) offset_ += sizes[i];
		size_ += sizes[i];
	}
}

template<typename T>
Index<T>::~Index()
{
	delete flann_index;
	dataset.free();
}

template<typename T>
void Index<T>::knnSearch(const flann::Matrix<T>& queries, flann::Matrix<int>& indices, flann::Matrix<float>& dists, int knn, const SearchParams& params)
{
	boost::mpi::communicator world;
	flann::Matrix<int> local_indices(new int[queries.rows*knn],queries.rows, knn);
	flann::Matrix<float> local_dists(new float[queries.rows*knn],queries.rows, knn);

	flann_index->knnSearch(queries, local_indices, local_dists, knn, params);
	for (size_t i=0;i<local_indices.rows;++i) {
		for (size_t j=0;j<local_indices.cols;++j) {
			local_indices[i][j] += offset_;
		}
	}
	SearchResults local_results;
	local_results.indices = local_indices;
	local_results.dists = local_dists;
	SearchResults results;

	// perform MPI reduce
	reduce(world, local_results, results, ResultsMerger(), 0);

	if (world.rank()==0) {
		for (int i=0;i<results.indices.rows;++i) {
			for (int j=0;j<results.indices.cols;++j) {
				indices[i][j] = results.indices[i][j];
				dists[i][j] = results.dists[i][j];
			}
		}
		results.indices.free();
		results.dists.free();
	}
}

template<typename T>
int Index<T>::radiusSearch(const flann::Matrix<T>& query, flann::Matrix<int>& indices, flann::Matrix<float>& dists, float radius, const SearchParams& params)
{
// TODO: fix this

//	mpi::communicator world;
//	flann::Matrix<int> local_indices(new int[indices.rows*indices.cols],indices.rows, indices.cols);
//	flann::Matrix<float> local_dists(new float[dists.rows*dists.cols],dists.rows, dists.cols);
//
//	int count_nn = flann_index->radiusSearch(query, local_indices, local_dists, radius, params);
//
//	SearchResults local_results;
//	local_results.indices = local_indices;
//	local_results.dists = local_dists;
//	SearchResults results;
//	reduce(world, local_results, results, ResultsMerger(), 0);
//
//	if (world.rank()==0) {
//		for (int i=0;i<knn;++i) {
//			indices[i] = results.indices[i];
//			dists[i] = results.dists[i];
//		}
//		results.indices.free();
//		results.dists.free();
//	}
//
//	// reduce the nearest neighbor
//	int all_count_nn = 0;
//	reduce(world, count_nn, all_count_nn, std::plus<int>(),0);

	return 0;
}

} } //namespace flann::mpi

namespace boost { namespace mpi {
  template<>
  struct is_commutative<flann::mpi::ResultsMerger, flann::mpi::SearchResults> : mpl::true_ { };
} } // end namespace boost::mpi


#endif /* FLANN_MPI_HPP_ */
