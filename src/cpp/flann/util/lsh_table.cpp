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

#include <boost/foreach.hpp>
#include <boost/functional/hash.hpp>
#include <iostream>
#include <iomanip>
#include <list>
#include <map>
#include <set>
#include <sstream>
#include <vector>

#include "flann/util/lsh_table.h"

namespace flann
{
namespace lsh
{

std::ostream& operator <<(std::ostream& out, const LshStats & stats)
{
  size_t w = 20;
  out << "Lsh Table Stats:\n" << std::setw(w) << std::setiosflags(std::ios::right) << "N buckets : "
      << stats.n_buckets_ << "\n" << std::setw(w) << std::setiosflags(std::ios::right) << "mean size : "
      << std::setiosflags(std::ios::left) << stats.bucket_size_mean_ << "\n" << std::setw(w)
      << std::setiosflags(std::ios::right) << "median size : " << stats.bucket_size_median_ << "\n" << std::setw(w)
      << std::setiosflags(std::ios::right) << "min size : " << std::setiosflags(std::ios::left)
      << stats.bucket_size_min_ << "\n" << std::setw(w) << std::setiosflags(std::ios::right) << "max size : "
      << std::setiosflags(std::ios::left) << stats.bucket_size_max_;

  // Display the histogram
  out << std::endl << std::setw(w) << std::setiosflags(std::ios::right) << "histogram : "
      << std::setiosflags(std::ios::left);
  for (std::vector<std::vector<unsigned int> >::const_iterator iterator = stats.size_histogram_.begin(), end =
      stats.size_histogram_.end(); iterator != end; ++iterator)
    out << (*iterator)[0] << "-" << (*iterator)[1] << ": " << (*iterator)[2] << ",  ";

  return out;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Specialization for unsigned char

template<>
  LshTable<unsigned char>::LshTable(unsigned int feature_size, unsigned int subsignature_size)
  {
    initialize(subsignature_size);
    // Allocate the mask
    mask_ = std::vector<size_t>(ceil((float)(feature_size * sizeof(char)) / (float)sizeof(size_t)), 0);

    // Generate a random set of order of subsignature_size_ bits
    boost::dynamic_bitset<> allocated_bits(feature_size * CHAR_BIT);
    while (allocated_bits.count() < key_size_)
    {
      size_t index = std::rand() % allocated_bits.size();
      if (allocated_bits.test(index))
        continue;
      allocated_bits.set(index);

      // Set that bit in the mask
      size_t divisor = CHAR_BIT * sizeof(size_t);
      size_t idx = index / divisor; //pick the right size_t index
      mask_[idx] += size_t(1) << (index % divisor); //use modulo to find the bit offset
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
  size_t LshTable<unsigned char>::computeKey(const unsigned char* feature) const
  {
    // no need to check if T is dividable by sizeof(size_t) like in the Hamming
    // distance computation as we have a mask
    const size_t *feature_block_ptr = reinterpret_cast<const size_t*> (feature);

    // Figure out the subsignature of the feature
    // Given the feature ABCDEF, and the mask 001011, the output will be
    // 000CEF
    size_t subsignature = 0;
    size_t bit_index = 1;

    BOOST_FOREACH(size_t mask_block, mask_)
          {
            // get the mask and signature blocks
            size_t feature_block = *feature_block_ptr;
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
  LshStats LshTable<unsigned char>::getStats() const
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
      BOOST_FOREACH(const Bucket& bucket, buckets_speed_)
            {
              stats.bucket_sizes_.push_back(bucket.size());
              stats.bucket_size_mean_ += bucket.size();
            }
      stats.bucket_size_mean_ /= buckets_speed_.size();
      stats.n_buckets_ = buckets_speed_.size();
    }
    else
    {
      BOOST_FOREACH(const BucketsSpace::value_type& x, buckets_space_)
            {
              stats.bucket_sizes_.push_back(x.second.size());
              stats.bucket_size_mean_ += x.second.size();
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
    float mean, stddev;
    stats.bucket_size_std_dev = stddev;

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

}
}
