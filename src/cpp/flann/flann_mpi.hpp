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


namespace flann
{

namespace mpi {


template<typename T>
class Index {
	flann::Index<T>* flann_index;
	flann::Matrix<T> dataset;

public:
	Index(const std::string& dataset_name, const IndexParams& params);

	~Index();

	void buildIndex();

	void knnSearch(const Matrix<T>& queries, Matrix<int>& indices, Matrix<float>& dists, int knn, const SearchParams& params);

	int radiusSearch(const Matrix<T>& query, Matrix<int>& indices, Matrix<float>& dists, float radius, const SearchParams& params);

//	void save(std::string filename);

	int veclen() const { return flann_index->veclen(); }

	int size() const { return flann_index->size(); }

	const IndexParams* getIndexParameters() { return flann_index->getParameters(); }
};




}


}


#endif /* FLANN_MPI_HPP_ */
