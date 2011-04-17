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

/***********************************************************************
 * Author: Vincent Rabaud
 *************************************************************************/

#ifndef LSH_INDEX_H_
#define LSH_INDEX_H_

#include <algorithm>
#include <map>
#include <cassert>
#include <cstring>

#include "flann/general.h"
#include "flann/algorithms/nn_index.h"
#include "flann/util/matrix.h"
#include "flann/util/result_set.h"
#include "flann/util/heap.h"
#include "flann/util/logger.h"
#include "flann/util/lsh_table.h"
#include "flann/util/allocator.h"
#include "flann/util/random.h"
#include "flann/util/saving.h"

namespace flann
{

struct LshIndexParams : public IndexParams
{
  LshIndexParams(unsigned int table_number, unsigned int key_size, bool do_multi_probe = true) :
    IndexParams(FLANN_INDEX_LSH), table_number_(table_number), key_size_(key_size), do_multi_probe_(do_multi_probe)
  {
  }

  void fromParameters(const FLANNParameters& p)
  {
    assert(p.algorithm==algorithm);
    table_number_ = p.table_number_;
    key_size_ = p.key_size_;
    do_multi_probe_ = p.do_multi_probe_;
  }

  void toParameters(FLANNParameters& p) const
  {
    p.algorithm = algorithm;
    p.table_number_ = table_number_;
    p.key_size_ = key_size_;
    p.do_multi_probe_ = do_multi_probe_;
  }

  void print() const
  {
    logger.info("Index type: %d\n", (int)algorithm);
    logger.info("Number of hash tables: %d\n", table_number_);
    logger.info("Key size: %d\n", key_size_);
  }

  /** The number of hash tables to use */
  unsigned int table_number_;
  /** The length of the key in the hash tables */
  unsigned int key_size_;
  /** Flag indicating if we use multi-probe LSH */
  bool do_multi_probe_;
};

/**
 * Randomized kd-tree index
 *
 * Contains the k-d trees and other information for indexing a set of points
 * for nearest-neighbor matching.
 */
template<typename Distance>
  class LshIndex : public NNIndex<Distance>
  {
  public:
    typedef typename Distance::ElementType ElementType;
    typedef typename Distance::ResultType DistanceType;

    flann_algorithm_t getType() const
    {
      return FLANN_INDEX_KDTREE;
    }

    /** Constructor
     * @param input_data dataset with the input features
     * @param params parameters passed to the LSH algorithm
     * @param d the distance used
     */
    LshIndex(const Matrix<ElementType>& input_data, const LshIndexParams& params = LshIndexParams(),
             Distance d = Distance()) :
      dataset_(input_data), index_params_(params), distance_(d)
    {
      feature_size_ = dataset_.cols;
    }

    /**
     * Builds the index
     */
    void buildIndex()
    {
      tables_.resize(index_params_.table_number_);
      for (unsigned int i = 0; i < index_params_.table_number_; ++i)
      {
        lsh::LshTable<ElementType> & table = tables_[i];
        table = lsh::LshTable<ElementType>(feature_size_, index_params_.key_size_);
        if (!table.use_speed_)
          table.buckets_space_.rehash(dataset_.rows * 1.2);
        // Add the features to the table
        for (int i = 0; i < dataset_.rows; ++i)
          table.add(i, dataset_(i));
        // Now that the table is full, optimize it for speed/space
        table.optimize();
      }
      is_index_used_.resize(dataset_.rows);
    }

    void saveIndex(FILE* stream)
    {
      save_value(stream, index_params_.table_number_);
      save_value(stream, index_params_.key_size_);
      save_value(stream, dataset_);
    }

    void loadIndex(FILE* stream)
    {
      load_value(stream, index_params_.table_number_);
      load_value(stream, index_params_.key_size_);
      load_value(stream, dataset_);
      // Building the index is so fast we can afford not storing it
      buildIndex();
    }

    /**
     *  Returns size of index.
     */
    size_t size() const
    {
      return dataset_.rows;
    }

    /**
     * Returns the length of an index feature.
     */
    size_t veclen() const
    {
      return index_params_.key_size_;
    }

    /**
     * Computes the index memory usage
     * Returns: memory used by the index
     */
    int usedMemory() const
    {
      return dataset_.rows * sizeof(int);
    }

    /**
     * Find set of nearest neighbors to vec. Their indices are stored inside
     * the result object.
     *
     * Params:
     *     result = the result object in which the indices of the nearest-neighbors are stored
     *     vec = the vector for which to search the nearest neighbors
     *     maxCheck = the maximum number of restarts (in a best-bin-first manner)
     */
    void findNeighbors(ResultSet<DistanceType>& result, const ElementType* vec, const SearchParams& searchParams)
    {
      int maxChecks = searchParams.checks;
      float epsError = 1 + searchParams.eps;

      if (maxChecks == FLANN_CHECKS_UNLIMITED)
      {
        getExactNeighbors(result, vec, epsError);
      }
      else
      {
        getNeighbors(result, vec, maxChecks, epsError);
      }
    }

    const IndexParams* getParameters() const
    {
      return &index_params_;
    }

  private:
    /** Defines the comparator on score and index
     */
    typedef std::pair<float, unsigned int> ScoreIndexPair;
    struct SortScoreIndexPairOnSecond
    {
      bool operator()(const ScoreIndexPair &left, const ScoreIndexPair &right) const
      {
        return left.second < right.second;
      }
    };

    /** Performs the approximate nearest-neighbor search.
     * @param vec the feature to analyze
     * @param do_radius flag indicating if we check the radius too
     * @param radius the radius if it is a radius search
     * @param do_k flag indicating if we limit the number of nn
     * @param k_nn the number of nearest neighbors
     * @param checked_average used for debugging
     */
    void getNeighbors(const ElementType* vec, bool do_radius, float radius, bool do_k, unsigned int k_nn,
                      float &checked_average)
    {
      static std::vector<ScoreIndexPair> score_index_heap;
      static std::vector<lsh::FeatureIndex> unique_indices;

      unique_indices.clear();
      score_index_heap.clear();

      // Figure out a list of unique indices to query
      BOOST_FOREACH(const lsh::LshTable<ElementType> & table, tables_)
            {
              // First, insert the matching bucket if it is not empty
              table.add_to_unique_indices(vec, unique_indices, is_index_used_);

              // Checking neighboring buckets
              if (index_params_.do_multi_probe_)
                table.add_neighbors_to_unique_indices(vec, unique_indices, is_index_used_);
            }

      checked_average += unique_indices.size();

      // Go over each descriptor index
      std::vector<lsh::FeatureIndex>::const_iterator training_index = unique_indices.begin();
      std::vector<lsh::FeatureIndex>::const_iterator last_training_index = unique_indices.end();
      DistanceType worst_distance;
      DistanceType hamming_distance;

      if (do_k)
      {
        // Get at least k_nn nearest neighbors first
        score_index_heap.reserve(k_nn);
        for (; training_index < last_training_index; ++training_index)
        {
          // Reset the usage of the index
          is_index_used_.reset(*training_index);

          // Compute the Hamming distance
          hamming_distance = Distance(vec, dataset_ + (*training_index) * sizeof(ElementType), dataset_.cols);
          if ((!do_radius) || (hamming_distance < radius))
          {
            // Insert the new element
            score_index_heap.push_back(ScoreIndexPair(hamming_distance, training_index));

            if (score_index_heap.size() == k_nn)
              break;
          }
        }
        // if we are going to analyze more candidates, make sure we have a heap
        if (training_index != last_training_index)
        {
          std::make_heap(score_index_heap.begin(), score_index_heap.end());
          worst_distance = score_index_heap.front().first;
        }
      }
      else
        // In radius search only, no pre-filling, no heap
        worst_distance = radius;

      // Process the rest of the candidates
      for (; training_index < last_training_index; ++training_index)
      {
        // Reset the usage of the index
        is_index_used_.reset(*training_index);

        // Compute the Hamming distance
        hamming_distance = Distance(vec, dataset_ + (*training_index) * sizeof(ElementType), dataset_.cols);
        if (hamming_distance < worst_distance)
        {
          if (do_k)
          {
            // Remove the highest distance value as we will have too many elements
            std::pop_heap(score_index_heap.begin(), score_index_heap.end());
            // No need to do a pop_back as we replace the last element

            // Insert the new element
            score_index_heap.back() = ScoreIndexPair(hamming_distance, *training_index);
            std::push_heap(score_index_heap.begin(), score_index_heap.end());

            // Keep track of the worst score
            worst_distance = score_index_heap.front().first;
          } else
            // Insert the new element
            score_index_heap.push_back(ScoreIndexPair(hamming_distance, *training_index));
        }
      }
    }

    /** The different hash tables */
    std::vector<lsh::LshTable<ElementType> > tables_;

    /** The data the LSH tables where built from */
    Matrix<ElementType> dataset_;

    /** The size of the features (as ElementType[]) */
    unsigned int feature_size_;

    const LshIndexParams index_params_;

    /** Structure used when uniquifying indices */
    boost::dynamic_bitset<> is_index_used_;

    Distance distance_;
  };
}

#endif //LSH_INDEX_H_
