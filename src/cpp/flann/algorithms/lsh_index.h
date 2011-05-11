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
#include <cassert>
#include <cstring>
#include <map>
#include <vector>

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
  LshIndexParams(unsigned int table_number, unsigned int key_size, unsigned int multi_probe_level) :
    IndexParams(FLANN_INDEX_LSH), table_number_(table_number), key_size_(key_size),
        multi_probe_level_(multi_probe_level)
  {
  }

  void fromParameters(const FLANNParameters& p)
  {
    assert(p.algorithm==algorithm);
    table_number_ = p.table_number_;
    key_size_ = p.key_size_;
    multi_probe_level_ = p.multi_probe_level_;
  }

  void toParameters(FLANNParameters& p) const
  {
    p.algorithm = algorithm;
    p.table_number_ = table_number_;
    p.key_size_ = key_size_;
    p.multi_probe_level_ = multi_probe_level_;
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
  /** Number of levels to use in multi-probe (0 for standard LSH) */
  unsigned int multi_probe_level_;
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
      fill_xor_mask(0, index_params_.key_size_, index_params_.multi_probe_level_, xor_masks_);
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

        // Add the features to the table
        table.add(dataset_);
      }
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
      return feature_size_;
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
      getNeighbors(vec, result);
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

    /** Fills the different xor masks to use when getting the neighbors in multi-probe LSH
     * @param key the key we build neighbors from
     * @param lowest_index the lowest index of the bit set
     * @param level the multi-probe level we are at
     * @param xor_masks all the xor mask
     */
    void fill_xor_mask(lsh::BucketKey key, int lowest_index, unsigned int level,
                       std::vector<lsh::BucketKey> & xor_masks)
    {
      xor_masks.push_back(key);
      if (level == 0)
        return;
      for (int index = lowest_index - 1; index >= 0; --index)
      {
        // Create a new key
        lsh::BucketKey new_key = key | (1 << index);
        fill_xor_mask(new_key, index, level - 1, xor_masks);
      }
    }

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

      if (do_k)
      {
        unsigned int worst_score = std::numeric_limits<unsigned int>::max();
        typename std::vector<lsh::LshTable<ElementType> >::const_iterator table = tables_.begin();
        typename std::vector<lsh::LshTable<ElementType> >::const_iterator table_end = tables_.end();
        for (; table != table_end; ++table)
        {
          size_t key = table->getKey(vec);
          std::vector<lsh::BucketKey>::const_iterator xor_mask = xor_masks_.begin();
          std::vector<lsh::BucketKey>::const_iterator xor_mask_end = xor_masks_.end();
          for (; xor_mask != xor_mask_end; ++xor_mask)
          {
            size_t sub_key = key ^ (*xor_mask);
            const lsh::Bucket * bucket = table->getBucketFromKey(sub_key);
            if (bucket == 0)
              continue;

            // Go over each descriptor index
            std::vector<lsh::FeatureIndex>::const_iterator training_index = bucket->begin();
            std::vector<lsh::FeatureIndex>::const_iterator last_training_index = bucket->end();
            DistanceType hamming_distance;

            // Process the rest of the candidates
            for (; training_index < last_training_index; ++training_index)
            {
              hamming_distance = distance_(vec, dataset_[*training_index], dataset_.cols);

              if (hamming_distance < worst_score)
              {
                // Insert the new element
                score_index_heap.push_back(ScoreIndexPair(hamming_distance, training_index));
                std::push_heap(score_index_heap.begin(), score_index_heap.end());

                if (score_index_heap.size() > (unsigned int)k_nn)
                {
                  // Remove the highest distance value as we have too many elements
                  std::pop_heap(score_index_heap.begin(), score_index_heap.end());
                  score_index_heap.pop_back();
                  // Keep track of the worst score
                  worst_score = score_index_heap.front().first;
                }
              }
            }
          }
        }
      }
      else
      {
        typename std::vector<lsh::LshTable<ElementType> >::const_iterator table = tables_.begin();
        typename std::vector<lsh::LshTable<ElementType> >::const_iterator table_end = tables_.end();
        for (; table != table_end; ++table)
        {
          size_t key = table->getKey(vec);
          std::vector<lsh::BucketKey>::const_iterator xor_mask = xor_masks_.begin();
          std::vector<lsh::BucketKey>::const_iterator xor_mask_end = xor_masks_.end();
          for (; xor_mask != xor_mask_end; ++xor_mask)
          {
            size_t sub_key = key ^ (*xor_mask);
            const lsh::Bucket * bucket = table->getBucketFromKey(sub_key);
            if (bucket == 0)
              continue;

            // Go over each descriptor index
            std::vector<lsh::FeatureIndex>::const_iterator training_index = bucket->begin();
            std::vector<lsh::FeatureIndex>::const_iterator last_training_index = bucket->end();
            DistanceType hamming_distance;

            // Process the rest of the candidates
            for (; training_index < last_training_index; ++training_index)
            {
              // Compute the Hamming distance
              hamming_distance = distance_(vec, dataset_[*training_index], dataset_.cols);
              if (hamming_distance < radius)
                score_index_heap.push_back(ScoreIndexPair(hamming_distance, training_index));
            }
          }
        }
      }
    }

    /** Performs the approximate nearest-neighbor search.
     * This is a slower version than the above as it uses the ResultSet
     * @param vec the feature to analyze
     */
    void getNeighbors(const ElementType* vec, ResultSet<DistanceType>& result)
    {
      typename std::vector<lsh::LshTable<ElementType> >::const_iterator table = tables_.begin();
      typename std::vector<lsh::LshTable<ElementType> >::const_iterator table_end = tables_.end();
      for (; table != table_end; ++table)
      {
        size_t key = table->getKey(vec);
        std::vector<lsh::BucketKey>::const_iterator xor_mask = xor_masks_.begin();
        std::vector<lsh::BucketKey>::const_iterator xor_mask_end = xor_masks_.end();
        for (; xor_mask != xor_mask_end; ++xor_mask)
        {
          size_t sub_key = key ^ (*xor_mask);
          const lsh::Bucket * bucket = table->getBucketFromKey(sub_key);
          if (bucket == 0)
            continue;

          // Go over each descriptor index
          std::vector<lsh::FeatureIndex>::const_iterator training_index = bucket->begin();
          std::vector<lsh::FeatureIndex>::const_iterator last_training_index = bucket->end();
          DistanceType hamming_distance;

          // Process the rest of the candidates
          for (; training_index < last_training_index; ++training_index)
          {
            // Compute the Hamming distance
            hamming_distance = distance_(vec, dataset_[*training_index], dataset_.cols);
            result.addPoint(hamming_distance, *training_index);
          }
        }
      }
    }

    /** The different hash tables */
    std::vector<lsh::LshTable<ElementType> > tables_;

    /** The data the LSH tables where built from */
    Matrix<ElementType> dataset_;

    /** The size of the features (as ElementType[]) */
    unsigned int feature_size_;

    LshIndexParams index_params_;

    /** The XOR masks to apply to a key to get the neighboring buckets
     */
    std::vector<lsh::BucketKey> xor_masks_;

    /** How far should we look for neighbors in multi-probe LSH
     */
    unsigned int multi_probe_level_;

    Distance distance_;
  };
}

#endif //LSH_INDEX_H_
