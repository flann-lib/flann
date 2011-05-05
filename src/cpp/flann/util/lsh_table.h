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

#ifndef LSH_TABLE_H_
#define LSH_TABLE_H_

#include <algorithm>
#include <iostream>
#include <limits.h>
// TODO as soon as we use C++0x, use the code in USE_UNORDERED_MAP
#if USE_UNORDERED_MAP
#include <unordered_map>
#else
#include <map>
#endif
#include <math.h>
#include <stdint.h>

#include "flann/util/dynamic_bitset.h"
#include "flann/util/matrix.h"

namespace flann
{

namespace lsh
{

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/** What is stored in an LSH bucket
 */
typedef uint32_t FeatureIndex;
/** The id from which we can get a bucket back in an LSH table
 */
typedef unsigned int BucketKey;

/** A bucket in an LSH table
 */
typedef std::vector<FeatureIndex> Bucket;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/** POD for stats about an LSH table
 */
struct LshStats
{
  std::vector<unsigned int> bucket_sizes_;
  size_t n_buckets_;
  size_t bucket_size_mean_;
  size_t bucket_size_median_;
  size_t bucket_size_min_;
  size_t bucket_size_max_;
  size_t bucket_size_std_dev;
  /** Each contained vector contains three value: beginning/end for interval, number of elements in the bin
   */
  std::vector<std::vector<unsigned int> > size_histogram_;
};

/** Overload the << operator for LshStats
 * @param out the streams
 * @param stats the stats to display
 * @return the streams
 */
std::ostream& operator <<(std::ostream& out, const LshStats & stats);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/** Lsh hash table. As its key is a sub-feature, and as usually
 * the size of it is pretty small, we keep it as a continuous memory array.
 * The value is an index in the corpus of features (we keep it as an unsigned
 * int for pure memory reasons, it could be a size_t)
 */
template<typename ElementType>
  class LshTable
  {
  public:
    /** A container of all the feature indices. Optimized for space
     */
#if USE_UNORDERED_MAP
    typedef std::unordered_map<BucketKey, Bucket> BucketsSpace;
#else
    typedef std::map<BucketKey, Bucket> BucketsSpace;
#endif

    /** A container of all the feature indices. Optimized for speed
     */
    typedef std::vector<Bucket> BucketsSpeed;

    /** Default constructor
     */
    LshTable()
    {
    }

    /** Default constructor
     * Create the mask and allocate the memory
     * @param feature_size is the size of the feature (considered as a ElementType[])
     * @param key_size is the number of bits that are turned on in the feature
     */
    LshTable(unsigned int feature_size, unsigned int key_size)
    {
      std::cerr << "LSH is not implemented for that type" << std::endl;
      throw;
    }

    /** Add a feature to the table
     * @param value the value to store for that feature
     * @param feature the feature itself
     */
    void add(unsigned int value, const ElementType * feature)
    {
      // Add the value to the corresponding bucket
      BucketKey key = computeKey(feature);
      if (use_speed_)
        buckets_speed_[key].push_back(value);
      else
        buckets_space_[key].push_back(value);
    }

    /** Add a set of features to the table
     * @param dataset the values to store
     */
    void add(Matrix<ElementType> dataset)
    {
#if USE_UNORDERED_MAP
      if (!use_speed_)
      buckets_space_.rehash((buckets_space_.size() + dataset.rows) * 1.2);
#endif
      // Add the features to the table
      for (unsigned int i = 0; i < dataset.rows; ++i)
        add(i, dataset[i]);
      // Now that the table is full, optimize it for speed/space
      optimize();
    }

    /** Return the bucket matching the feature
     */
    const Bucket & operator()(const ElementType * feature) const
    {
      if (use_speed_)
      {
        const Bucket & bucket = buckets_speed_[computeKey(feature)];
        if (bucket.empty())
          return EMPTY_BUCKET;
        else
          return bucket;
      }
      else
      {
        BucketsSpace::const_iterator bucket = buckets_space_.find(computeKey(feature));
        if (bucket != buckets_space_.end())
          // If we have the bucket return it
          return bucket->second;
        else
          return EMPTY_BUCKET;
      }
    }

    /** Get statistics about the table
     * @return
     */
    LshStats getStats() const;

    /** Add the neighboring buckets of a feature to a unique list of indices
     * @param key the key to get neighboring keys from
     * @param unique_indices list of indice to which we add neighboring buckets
     * @param is_index_used mask indicating whether an index is used or not
     */
    void addNeighborsToUniqueIndices(const ElementType * feature, Bucket & unique_indices,
                                     DynamicBitset & is_index_used) const
    {
      size_t key = computeKey(feature);
      // Generate other buckets
      if (use_speed_)
      {
        // That means we get the buckets from an array
        for (std::vector<BucketKey>::const_iterator xor_mask = xor_masks_.begin(); xor_mask != xor_masks_.end(); ++xor_mask)
          // Insert this new bucket as a neighbor
          addBucketToUniqueIndices(buckets_speed_[key ^ (*xor_mask)], unique_indices, is_index_used);
      }
      else
      {
        if (key_bitset_.empty())
        {
          // That means we have to check for the hash table for the presence of a key
          BucketsSpace::const_iterator bucket_it, bucket_end = buckets_space_.end();
          for (std::vector<BucketKey>::const_iterator xor_mask = xor_masks_.begin(); xor_mask != xor_masks_.end(); ++xor_mask)
          {
            bucket_it = buckets_space_.find(key ^ (*xor_mask));
            // Stop here if that bucket does not exist
            if (bucket_it != bucket_end)
              // Insert this new bucket as a neighbor
              addBucketToUniqueIndices(bucket_it->second, unique_indices, is_index_used);
          }
        }
        else
        {
          // That means we can check the bitset for the presence of a key
          for (std::vector<BucketKey>::const_iterator xor_mask = xor_masks_.begin(); xor_mask != xor_masks_.end(); ++xor_mask)
          {
            size_t sub_key = key ^ (*xor_mask);
            if (key_bitset_.test(sub_key))
              // Insert this new bucket as a neighbor
              addBucketToUniqueIndices(buckets_space_.at(sub_key), unique_indices, is_index_used);
          }
        }
      }
    }

    /** Add the bucket of a feature to a unique list of indices
     * @param key the key to get neighboring keys from
     * @param unique_indices list of indice to which we add neighboring buckets
     * @param is_index_used mask indicating whether an index is used or not
     */
    void addToUniqueIndices(const ElementType * feature, Bucket & unique_indices, DynamicBitset & is_index_used) const
    {
      addBucketToUniqueIndices(this->operator ()(feature), unique_indices, is_index_used);
    }

  private:
    /** Perform merge sort on several lists of indices
     * This code is much faster than trying to do a k-wy merge on the different buckets
     * @param indices
     * @param unique_indices
     */
    void addBucketToUniqueIndices(const Bucket & bucket, Bucket & unique_indices, DynamicBitset & is_index_used) const
    {
      for (Bucket::const_iterator pindex = bucket.begin(); pindex != bucket.end(); ++pindex)
      {
        FeatureIndex index = *pindex;
        if (is_index_used.test(index))
          continue;
        is_index_used.set(index);
        unique_indices.push_back(index);
      }
    }

    /** Compute the sub-signature of a feature
     */
    size_t computeKey(const ElementType* feature) const
    {
      std::cerr << "LSH is not implemented for that type" << std::endl;
      throw;
      return 1;
    }

    /** Initialize some variables
     */
    void initialize(size_t key_size)
    {
      use_speed_ = false;
      key_size_ = key_size;

      // Fill the XOR mask
      xor_masks_.reserve(key_size_ * (key_size_ + 1) / 2);
      for (unsigned int i = 0; i < key_size_; ++i)
      {
        size_t sub_signature_1 = (1 << i);
        xor_masks_.push_back(sub_signature_1);
        for (unsigned int j = i + 1; j < key_size_; ++j)
        {
          size_t sub_signature_2 = sub_signature_1 ^ (1 << j);
          xor_masks_.push_back(sub_signature_2);
        }
      }
    }

    /** Optimize the table for speed/space
     */
    void optimize()
    {
      // If the bitset is going to use less than 10% of the RAM of the hash map (at least 1 size_t for the key and two
      // for the vector) or less than 8MB (key_size_ <= 26)
      if (((std::max(buckets_space_.size(), buckets_speed_.size()) * CHAR_BIT * 3 * sizeof(BucketKey)) / 10
          >= ((size_t)1 << key_size_)) || (key_size_ <= 26))
      {
        key_bitset_.resize(1 << key_size_);
        key_bitset_.reset();
        // Try with the BucketsSpace
        for (BucketsSpace::const_iterator key_bucket = buckets_space_.begin(); key_bucket != buckets_space_.end(); ++key_bucket)
          key_bitset_.set(key_bucket->first);
        // Try with the BucketsSpeed
        for (unsigned int i = 0; i < buckets_speed_.size(); ++i)
          if (!buckets_speed_[i].empty())
            key_bitset_.set(i);
      }

      // Use an array if it will be more than half full
      bool is_speed_appropriate = buckets_space_.size() > (unsigned int)((1 << key_size_) / 2);

      if ((buckets_speed_.empty()) && (is_speed_appropriate))
      {
        use_speed_ = true;
        // Fill the array version of it
        buckets_speed_.resize(1 << key_size_);
        for (BucketsSpace::const_iterator key_bucket = buckets_space_.begin(); key_bucket != buckets_space_.end(); ++key_bucket)
          buckets_speed_[key_bucket->first] = key_bucket->second;

        // Empty the hash table
        buckets_space_.clear();
      }
      else if ((buckets_space_.empty()) && (!is_speed_appropriate))
      {
        use_speed_ = false;
        // Fill the hash table version of it
        buckets_space_.clear();
        for (size_t i = 0; i < key_bitset_.size(); ++i)
          if (key_bitset_.test(i))
            buckets_space_[i] = buckets_speed_[i];

        // Empty the array
        buckets_speed_.clear();
      }
    }

    /** Empty bucket
     */
    static const Bucket EMPTY_BUCKET;

    /** The vector of all the buckets if they are held for speed
     */
    BucketsSpeed buckets_speed_;

    /** The hash table of all the buckets in case we cannot use the speed version
     */
    BucketsSpace buckets_space_;

    /** True if it uses buckets_speed_ instead of buckets_space_
     */
    bool use_speed_;

    /** If the subkey is small enough, it will keep track of which subkeys are set through that bitset
     * That is just a speedup so that we don't look in the hash table (which can be mush slower that checking a bitset)
     */
    DynamicBitset key_bitset_;

    /** The XOR masks to apply to a key to get the neighboring buckets
     */
    std::vector<BucketKey> xor_masks_;

    /** The size of the sub-signature in bits
     */
    unsigned int key_size_;

    // Members only used for the unsigned char specialization
    /** The mask to apply to a feature to get the hash key
     * Only used in the unsigned char case
     */
    std::vector<size_t> mask_;
  };

template<typename ElementType>
  const Bucket LshTable<ElementType>::EMPTY_BUCKET = Bucket();

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Specialization for unsigned char

template<>
  inline LshTable<unsigned char>::LshTable(unsigned int feature_size, unsigned int subsignature_size)
  {
    initialize(subsignature_size);
    // Allocate the mask
    mask_ = std::vector<size_t>(ceil((float)(feature_size * sizeof(char)) / (float)sizeof(size_t)), 0);

    // A bit brutal but fast to code
    std::vector<size_t> indices(feature_size * CHAR_BIT);
    for (size_t i = 0; i < feature_size * CHAR_BIT; ++i)
      indices[i] = i;
    std::random_shuffle(indices.begin(), indices.end());

    // Generate a random set of order of subsignature_size_ bits
    for (unsigned int i = 0; i < key_size_; ++i)
    {
      size_t index = indices[i];

      // Set that bit in the mask
      size_t divisor = CHAR_BIT * sizeof(size_t);
      size_t idx = index / divisor; //pick the right size_t index
      mask_[idx] |= size_t(1) << (index % divisor); //use modulo to find the bit offset
    }

    // Set to 1 if you want to display the mask for debug
#if 0
    {
      size_t bcount = 0;
      BOOST_FOREACH(size_t mask_block, mask_)
      {
        out << std::setw(sizeof(size_t) * CHAR_BIT / 4) << std::setfill('0') << std::hex << mask_block
        << std::endl;
        bcount += __builtin_popcountll(mask_block);
      }
      out << "bit count : " << std::dec << bcount << std::endl;
      out << "mask size : " << mask_.size() << std::endl;
      return out;
    }
#endif
  }

/** Return the Subsignature of a feature
 * @param feature the feature to analyze
 */
template<>
  inline size_t LshTable<unsigned char>::computeKey(const unsigned char* feature) const
  {
    // no need to check if T is dividable by sizeof(size_t) like in the Hamming
    // distance computation as we have a mask
    const size_t *feature_block_ptr = reinterpret_cast<const size_t*> (feature);

    // Figure out the subsignature of the feature
    // Given the feature ABCDEF, and the mask 001011, the output will be
    // 000CEF
    size_t subsignature = 0;
    size_t bit_index = 1;

    for (std::vector<size_t>::const_iterator pmask_block = mask_.begin(); pmask_block != mask_.end(); ++pmask_block)
    {
      // get the mask and signature blocks
      size_t feature_block = *feature_block_ptr;
      size_t mask_block = *pmask_block;
      while (mask_block)
      {
        // Get the lowest set bit in the mask block
        size_t lowest_bit = mask_block & (-mask_block);
        // Add it to the current subsignature if necessary
        subsignature += (feature_block & lowest_bit) ? bit_index : 0;
        // Reset the bit in the mask block
        mask_block ^= lowest_bit;
        // increment the bit index for the subsignature
        bit_index <<= 1;
      }
      // Check the next feature block
      ++feature_block_ptr;
    }
    return subsignature;
  }

template<>
  inline LshStats LshTable<unsigned char>::getStats() const
  {
    LshStats stats;
    stats.bucket_size_mean_ = 0;
    if ((buckets_speed_.empty()) && (buckets_space_.empty()))
    {
      stats.n_buckets_ = 0;
      stats.bucket_size_median_ = 0;
      stats.bucket_size_min_ = 0;
      stats.bucket_size_max_ = 0;
      return stats;
    }

    if (!buckets_speed_.empty())
    {
      for (BucketsSpeed::const_iterator pbucket = buckets_speed_.begin(); pbucket != buckets_speed_.end(); ++pbucket)
      {
        stats.bucket_sizes_.push_back(pbucket->size());
        stats.bucket_size_mean_ += pbucket->size();
      }
      stats.bucket_size_mean_ /= buckets_speed_.size();
      stats.n_buckets_ = buckets_speed_.size();
    }
    else
    {
      for (BucketsSpace::const_iterator x = buckets_space_.begin(); x != buckets_space_.end(); ++x)
      {
        stats.bucket_sizes_.push_back(x->second.size());
        stats.bucket_size_mean_ += x->second.size();
      }
      stats.bucket_size_mean_ /= buckets_space_.size();
      stats.n_buckets_ = buckets_space_.size();
    }

    std::sort(stats.bucket_sizes_.begin(), stats.bucket_sizes_.end());

    //  BOOST_FOREACH(int size, stats.bucket_sizes_)
    //          std::cout << size << " ";
    //  std::cout << std::endl;
    stats.bucket_size_median_ = stats.bucket_sizes_[stats.bucket_sizes_.size() / 2];
    stats.bucket_size_min_ = stats.bucket_sizes_.front();
    stats.bucket_size_max_ = stats.bucket_sizes_.back();

    // TODO compute mean and std
    /*float mean, stddev;
     stats.bucket_size_mean_ = mean;
     stats.bucket_size_std_dev = stddev;*/

    // Include a histogram of the buckets
    unsigned int bin_start = 0;
    unsigned int bin_end = 20;
    bool is_new_bin = true;
    for (std::vector<unsigned int>::iterator iterator = stats.bucket_sizes_.begin(), end = stats.bucket_sizes_.end(); iterator
        != end;)
      if (*iterator < bin_end)
      {
        if (is_new_bin)
        {
          stats.size_histogram_.push_back(std::vector<unsigned int>(3, 0));
          stats.size_histogram_.back()[0] = bin_start;
          stats.size_histogram_.back()[1] = bin_end - 1;
          is_new_bin = false;
        }
        ++stats.size_histogram_.back()[2];
        ++iterator;
      }
      else
      {
        bin_start += 20;
        bin_end += 20;
        is_new_bin = true;
      }

    return stats;
  }

// End the two namespaces
}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#endif /* LSH_TABLE_H_ */
