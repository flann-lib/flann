/***********************************************************************
 * Software License Agreement (BSD License)
 *
 * Copyright 2010-2011  Nick Vanbaelen (nickon@acm.org). All rights reserved.
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

#ifndef FLANN_TBB_BODIES_H
#define FLANN_TBB_BODIES_H

#include <tbb/blocked_range.h>
#include <tbb/atomic.h>

#include "flann/util/matrix.h"
#include "flann/util/params.h"
#include "flann/util/result_set.h"

namespace flann
{

template <typename Distance> class NNIndex;


template<typename Distance>
class parallel_knnSearch
{
public:
  typedef typename Distance::ElementType ElementType;
  typedef typename Distance::ResultType DistanceType;

  parallel_knnSearch(const Matrix<ElementType>& queries,
                           Matrix<int>& indices,
                           Matrix<DistanceType>& distances,
                           size_t knn,
                     const SearchParams& params,
                           NNIndex<Distance>* nnIndex,
                           tbb::atomic<int>& count)
    : queries_(queries),
      indices_(indices),
      distances_(distances),
      knn_(knn),
      params_(params),
      nnIndex_(nnIndex),
      count_(count)

  {}

  /* default destructor will do */

  /* default copy constructor will do,
     parallel for will use this to create a separate parallel_knnSearch object
     for each worker thread (pointers will be copied, which is OK) */

  /**
   * Perform knnSearch for the query points assigned to this worker thread
   * \param r query point range assigned for this worker thread to operate on
   */
  void operator()( const tbb::blocked_range<size_t>& r ) const
  {
    if (params_.use_heap==FLANN_True)
    {
      KNNResultSet2<DistanceType> resultSet(knn_);
      for (size_t i=r.begin(); i!=r.end(); ++i)
      {
        resultSet.clear();
        nnIndex_->findNeighbors(resultSet, queries_[i], params_);
        resultSet.copy(indices_[i], distances_[i], knn_, params_.sorted);
        count_ += resultSet.size();
      }
    }
    else
    {
      KNNSimpleResultSet<DistanceType> resultSet(knn_);
      for (size_t i=r.begin(); i!=r.end(); ++i)
      {
        resultSet.clear();
        nnIndex_->findNeighbors(resultSet, queries_[i], params_);
        resultSet.copy(indices_[i], distances_[i], knn_, params_.sorted);
        count_ += resultSet.size();
      }
    }
  }

private:
  //! All query points to perform search on
  //! \note each worker thread only operates on a specified range
  const Matrix<ElementType>& queries_;

  //! Matrix for storing the indices of the nearest neighbors
  //! \note no need for this to be a parallel container, each worker thread
  //!       solely operates on its specified range!
  Matrix<int>& indices_;

  //! Matrix for storing the distances to the nearest neighbors
  //! \note no need for this to be a parallel container, each worker thread
  //!       solely operates on its specified range!
  Matrix<DistanceType>& distances_;

  //! Number of nearest neighbors to search for
  size_t knn_;

  //! The search parameters to take into account
  const SearchParams& params_;

  //! The nearest neighbor index to perform the search with
  NNIndex<Distance>* nnIndex_;

  //! Atomic count variable to keep track of the number of neighbors found
  //! \note must be mutable because body will be casted as const in parallel_for
  tbb::atomic<int>& count_;
};


template<typename Distance>
class parallel_knnSearch2
{
public:
  typedef typename Distance::ElementType ElementType;
  typedef typename Distance::ResultType DistanceType;

  parallel_knnSearch2(const Matrix<ElementType>& queries,
                            std::vector< std::vector<int> >& indices,
                            std::vector<std::vector<DistanceType> >& distances,
                            size_t knn,
                      const SearchParams& params,
                            NNIndex<Distance>* nnIndex,
                            tbb::atomic<int>& count)
    : queries_(queries),
      indices_(indices),
      distances_(distances),
      knn_(knn),
      params_(params),
      nnIndex_(nnIndex),
      count_(count)

  {}

  /* default destructor will do */

  /* default copy constructor will do,
     parallel for will use this to create a separate parallel_knnSearch object
     for each worker thread (pointers will be copied, which is OK) */

  /**
   * Perform knnSearch for the query points assigned to this worker thread
   * (specified by the blocked_range parameter)
   */
  void operator()( const tbb::blocked_range<size_t>& r ) const
  {
    if (params_.use_heap==FLANN_True) {
        KNNResultSet2<DistanceType> resultSet(knn_);
        for (size_t i=r.begin(); i!=r.end(); ++i)
        {
            resultSet.clear();
            nnIndex_->findNeighbors(resultSet, queries_[i], params_);
            size_t n = std::min(resultSet.size(), knn_);
            indices_[i].resize(n);
            distances_[i].resize(n);
            resultSet.copy(&indices_[i][0], &distances_[i][0], n, params_.sorted);
            count_ += n;
        }
    }
    else {
        KNNSimpleResultSet<DistanceType> resultSet(knn_);
        for (size_t i=r.begin(); i!=r.end(); ++i)
        {
            resultSet.clear();
            nnIndex_->findNeighbors(resultSet, queries_[i], params_);
            size_t n = std::min(resultSet.size(), knn_);
            indices_[i].resize(n);
            distances_[i].resize(n);
            resultSet.copy(&indices_[i][0], &distances_[i][0], n, params_.sorted);
            count_ += n;
        }
    }
  }

private:
  //! All query points to perform search on
  //! \note each worker thread only operates on a specified range
  const Matrix<ElementType>& queries_;

  //! Vector for storing the indices of the nearest neighbors
  //! \note no need for this to be a parallel container, each worker thread
  //!       solely operates on its specified range!
  std::vector< std::vector<int> >& indices_;

  //! Vector for storing the distances to the nearest neighbors
  //! \note no need for this to be a parallel container, each worker thread
  //!       solely operates on its specified range!
  std::vector< std::vector<DistanceType> >& distances_;

  //! Number of nearest neighbors to search for
  size_t knn_;

  //! The search parameters to take into account
  const SearchParams& params_;

  //! The nearest neighbor index to perform the search with
  NNIndex<Distance>* nnIndex_;

  //! Atomic count variable to keep track of the number of neighbors found
  //! \note must be mutable because body will be casted as const in parallel_for
  tbb::atomic<int>& count_;
};


template<typename Distance>
class parallel_radiusSearch
{
public:
  typedef typename Distance::ElementType ElementType;
  typedef typename Distance::ResultType DistanceType;

  /* default destructor will do */

  /* default copy constructor will do,
     parallel for will use this to create a separate parallel_knnSearch object
     for each worker thread (pointers will be copied, which is OK) */

  /**
   * Perform radiusSearch for the query points assigned to this worker thread
   * (specified by the blocked_range parameter)
   */
  parallel_radiusSearch(const Matrix<ElementType>& queries,
                              Matrix<int>& indices,
                              Matrix<DistanceType>& distances,
                              float radius,
                        const SearchParams& params,
                              NNIndex<Distance>* nnIndex,
                              tbb::atomic<int>& count)
    : queries_(queries),
      indices_(indices),
      distances_(distances),
      radius_(radius),
      params_(params),
      nnIndex_(nnIndex),
      count_(count)

  {}

  void operator()( const tbb::blocked_range<size_t>& r ) const
  {
		size_t num_neighbors = std::min(indices_.cols, distances_.cols);
		int max_neighbors = params_.max_neighbors;
		if (max_neighbors<0) max_neighbors = num_neighbors;
		else max_neighbors = std::min(max_neighbors,(int)num_neighbors);

      if (max_neighbors==0) {
          CountRadiusResultSet<DistanceType> resultSet(radius_);
          for (size_t i=r.begin(); i!=r.end(); ++i)
          {
              resultSet.clear();
              nnIndex_->findNeighbors(resultSet, queries_[i], params_);
              count_ += resultSet.size();
          }
      }
      else {

          // explicitly indicated to use unbounded radius result set
          // or we know there'll be enough room for resulting indices and dists
          if (params_.max_neighbors<0 && (num_neighbors>=nnIndex_->size())) {
              RadiusResultSet<DistanceType> resultSet(radius_);
              for (size_t i=r.begin(); i!=r.end(); ++i)
              {
                  resultSet.clear();
                  nnIndex_->findNeighbors(resultSet, queries_[i], params_);
                  size_t n = resultSet.size();
                  count_ += n;
                  if (n>num_neighbors) n = num_neighbors;
                  resultSet.copy(indices_[i], distances_[i], n, params_.sorted);

                  // mark the next element in the output buffers as unused
                  if (n<indices_.cols) indices_[i][n] = -1;
                  if (n<distances_.cols) distances_[i][n] = std::numeric_limits<DistanceType>::infinity();
              }
          }
          else {
              // number of neighbors limited to max_neighbors
              KNNRadiusResultSet<DistanceType> resultSet(radius_, max_neighbors);
              for (size_t i=r.begin(); i!=r.end(); ++i)
              {
                  resultSet.clear();
                  nnIndex_->findNeighbors(resultSet, queries_[i], params_);
                  size_t n = resultSet.size();
                  count_ += n ;
                  if ((int)n>max_neighbors) n = max_neighbors;
                  resultSet.copy(indices_[i], distances_[i], n, params_.sorted);

                  // mark the next element in the output buffers as unused
                  if (n<indices_.cols) indices_[i][n] = -1;
                  if (n<distances_.cols) distances_[i][n] = std::numeric_limits<DistanceType>::infinity();
              }
          }
      }
  }

private:
  //! All query points to perform search on
  //! \note each worker thread only operates on a specified range
  const Matrix<ElementType>& queries_;

  //! Matrix for storing the indices of the nearest neighbors
  //! \note no need for this to be a parallel container, each worker thread
  //!       solely operates on its specified range!
  Matrix<int>& indices_;

  //! Matrix for storing the distances to the nearest neighbors
  //! \note no need for this to be a parallel container, each worker thread
  //!       solely operates on its specified range!
  Matrix<DistanceType>& distances_;

  //! Radius size bound on the search for nearest neighbors
  float radius_;

  //! The search parameters to take into account
  const SearchParams& params_;

  //! The nearest neighbor index to perform the search with
  NNIndex<Distance>* nnIndex_;

  //! Atomic count variable to keep track of the number of neighbors found
  //! \note must be mutable because body will be casted as const in parallel_for
  tbb::atomic<int>& count_;
};


template<typename Distance>
class parallel_radiusSearch2
{
public:
  typedef typename Distance::ElementType ElementType;
  typedef typename Distance::ResultType DistanceType;

  /* default destructor will do */

  /* default copy constructor will do,
     parallel for will use this to create a separate parallel_knnSearch object
     for each worker thread (pointers will be copied, which is OK) */

  /**
   * Perform radiusSearch for the query points assigned to this worker thread
   * (specified by the blocked_range parameter)
   */
  parallel_radiusSearch2(const Matrix<ElementType>& queries,
                               std::vector< std::vector<int> >& indices,
                               std::vector<std::vector<DistanceType> >& distances,
                               float radius,
                         const SearchParams& params,
                               NNIndex<Distance>* nnIndex,
                               tbb::atomic<int>& count)
    : queries_(queries),
      indices_(indices),
      distances_(distances),
      radius_(radius),
      params_(params),
      nnIndex_(nnIndex),
      count_(count)

  {}

  void operator()( const tbb::blocked_range<size_t>& r ) const
  {
      int max_neighbors = params_.max_neighbors;
      // just count neighbors
      if (max_neighbors==0) {
          CountRadiusResultSet<DistanceType> resultSet(radius_);
          for (size_t i=r.begin(); i!=r.end(); ++i)
          {
            resultSet.clear();
            nnIndex_->findNeighbors(resultSet, queries_[i], params_);
            count_ += resultSet.size();
          }
      }
      else {
          if (indices_.size() < queries_.rows ) indices_.resize(queries_.rows);
          if (distances_.size() < queries_.rows ) distances_.resize(queries_.rows);

          if (max_neighbors<0) {
              // search for all neighbors
              RadiusResultSet<DistanceType> resultSet(radius_);
              for (size_t i=r.begin(); i!=r.end(); ++i)
              {
                  resultSet.clear();
                  nnIndex_->findNeighbors(resultSet, queries_[i], params_);
                  size_t n = resultSet.size();
                  count_ += n;
                  indices_[i].resize(n);
                  distances_[i].resize(n);
                  resultSet.copy(&indices_[i][0], &distances_[i][0], n, params_.sorted);
              }
          }
          else {
              // number of neighbors limited to max_neighbors
              KNNRadiusResultSet<DistanceType> resultSet(radius_, params_.max_neighbors);
              for (size_t i=r.begin(); i!=r.end(); ++i)
              {
                  resultSet.clear();
                  nnIndex_->findNeighbors(resultSet, queries_[i], params_);
                  size_t n = resultSet.size();
                  count_ += n;
                  if ((int)n>max_neighbors) n = max_neighbors;
                  indices_[i].resize(n);
                  distances_[i].resize(n);
                  resultSet.copy(&indices_[i][0], &distances_[i][0], n, params_.sorted);
              }
          }
      }
  }

private:
    //! All query points to perform search on
    //! \note each worker thread only operates on a specified range
    const Matrix<ElementType>& queries_;

    //! Vector for storing the indices of the nearest neighbors
    //! \note no need for this to be a parallel container, each worker thread
    //!       solely operates on its specified range!
    std::vector< std::vector<int> >& indices_;

    //! Vector for storing the distances to the nearest neighbors
    //! \note no need for this to be a parallel container, each worker thread
    //!       solely operates on its specified range!
    std::vector< std::vector<DistanceType> >& distances_;

    //! Radius size bound on the search for nearest neighbors
    float radius_;

    //! The search parameters to take into account
    const SearchParams& params_;

    //! The nearest neighbor index to perform the search with
    NNIndex<Distance>* nnIndex_;

    //! Atomic count variable to keep track of the number of neighbors found
    //! \note must be mutable because body will be casted as const in parallel_for
    tbb::atomic<int>& count_;
};

}

#endif //FLANN_TBB_BODIES_H
