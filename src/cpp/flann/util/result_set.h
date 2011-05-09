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

#ifndef RESULTSET_H
#define RESULTSET_H


#include <algorithm>
#include <limits>
#include <vector>


namespace flann
{

/* This record represents a branch point when finding neighbors in
    the tree.  It contains a record of the minimum distance to the query
    point, as well as the node at which the search resumes.
 */

template <typename T, typename DistanceType>
struct BranchStruct
{
    T node;           /* Tree node at which search resumes */
    DistanceType mindist;     /* Minimum distance to query for all nodes below. */

    BranchStruct() {}
    BranchStruct(const T& aNode, DistanceType dist) : node(aNode), mindist(dist) {}

    bool operator<(const BranchStruct<T, DistanceType>& rhs) const
    {
        return mindist<rhs.mindist;
    }
};


template <typename DistanceType>
class ResultSet
{
public:
    virtual ~ResultSet() {}

    virtual bool full() const = 0;

    virtual void addPoint(DistanceType dist, int index) = 0;

    virtual DistanceType worstDist() const = 0;

};

template <typename DistanceType>
class KNNResultSet : public ResultSet<DistanceType>
{
    int* indices;
    DistanceType* dists;
    int capacity;
    int count;

public:
    KNNResultSet(int capacity_) : capacity(capacity_), count(0)
    {
    }

    void init(int* indices_, DistanceType* dists_)
    {
        indices = indices_;
        dists = dists_;
        count = 0;
        dists[capacity-1] = (std::numeric_limits<DistanceType>::max)();
    }

    size_t size() const
    {
        return count;
    }

    bool full() const
    {
        return count == capacity;
    }


    void addPoint(DistanceType dist, int index)
    {
        int i;
        for (i=count; i>0; --i) {
#ifdef FLANN_FIRST_MATCH
            if ( (dists[i-1]>dist) || ((dist==dists[i-1])&&(indices[i-1]>index)) ) {
#else
            if (dists[i-1]>dist) {
#endif
                if (i<capacity) {
                    dists[i] = dists[i-1];
                    indices[i] = indices[i-1];
                }
            }
            else break;
        }
        if (i<capacity) {
            dists[i] = dist;
            indices[i] = index;
        }
        if (count<capacity) count++;
    }

    DistanceType worstDist() const
    {
        return dists[capacity-1];
    }
};


/**
 * A result-set class used when performing a radius based search.
 */
template <typename DistanceType>
class RadiusResultSet : public ResultSet<DistanceType>
{
    DistanceType radius;
    int* indices;
    DistanceType* dists;
    size_t capacity;
    size_t count;

public:
    RadiusResultSet(DistanceType radius_, int* indices_, DistanceType* dists_, int capacity_) :
        radius(radius_), indices(indices_), dists(dists_), capacity(capacity_)
    {
        init();
    }

    ~RadiusResultSet()
    {
    }

    void init()
    {
        count = 0;
    }

    size_t size() const
    {
        return count;
    }

    bool full() const
    {
        return true;
    }

    void addPoint(DistanceType dist, int index)
    {
        if (dist<radius) {
            if ((capacity>0)&&(count < capacity)) {
                dists[count] = dist;
                indices[count] = index;
            }
            count++;
        }
    }

    DistanceType worstDist() const
    {
        return radius;
    }

};


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/** Class that holds the k NN neighbors
 * Faster than KNNResultSet as it uses a binary heap and does not maintain two arrays
 */
template<typename DistanceType>
  class ResultVector : public ResultSet<DistanceType>
  {
  public:
    typedef std::pair<float, unsigned int> DistIndexPair;

    /** Check the status of the set
     * @return true if we have k NN
     */
    inline bool full() const
    {
      return is_full_;
    }

    /** Remove all elements in the set
     */
    virtual void clear() = 0;

    /** Copy the set to two C arrays
     * @param indices pointer to a C array of indices
     * @param dist pointer to a C array of distances
     */
    void copy(int * indices, DistanceType * dist, size_t size)
    {
      size_t count = 0;
      for (std::vector<DistIndexPair>::const_iterator dist_index = dist_indices_.begin(); 
              (dist_index != dist_indices_.end()) && (count < size); ++dist_index, ++count)
      {
        *dist = dist_index->first;
        *indices = dist_index->second;
        ++indices;
        ++dist;
      }
    }

    /** Copy the set to two C arrays but sort it according to the distance first
     * @param indices pointer to a C array of indices
     * @param dist pointer to a C array of distances
     */
    void sortAndCopy(int * indices, DistanceType * dist, size_t size)
    {
      // First, sort the array (which may be a heap if it is full)
      if (is_full_)
        std::sort_heap(dist_indices_.begin(), dist_indices_.end());
      else
        std::sort(dist_indices_.begin(), dist_indices_.end());
      // Then copy the data
      copy(indices, dist, size);
    }

  protected:
    /** Flag to say if the set is full */
    bool is_full_;

    /** The nearest neighbors */
    std::vector<DistIndexPair> dist_indices_;
  };

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/** Class that holds the k NN neighbors
 * Faster than KNNResultSet as it uses a binary heap and does not maintain two arrays
 */
template<typename DistanceType>
  class KNNResultVector : public ResultVector<DistanceType>
  {
  public:
    /** Constructor
     * @param capacity the number of neighbors to store at max
     */
    KNNResultVector(unsigned int capacity)
    {
      this->capacity_ = capacity;
      this->is_full_ = false;
      dist_indices_.reserve(capacity_);
      this->clear();
    }

    /** Add a possible candidate to the best neighbors
     * @param dist distance for that neighbor
     * @param index index of that neighbor
     */
    inline void addPoint(DistanceType dist, int index)
    {
      if (is_full_)
      {
        // Don't do anything if we are worse than the worst
        if (dist > worst_distance_)
          return;
        // Remove the worst element
        std::pop_heap(dist_indices_.begin(), dist_indices_.end());
        // Insert the new element
        dist_indices_.back() = typename ResultVector<DistanceType>::DistIndexPair(dist, index);
        std::push_heap(dist_indices_.begin(), dist_indices_.end());
        worst_distance_ = dist_indices_.front().first;
      }
      else {
        dist_indices_.push_back(typename ResultVector<DistanceType>::DistIndexPair(dist, index));
        // Once we are full, make sure it is a heap
        if (dist_indices_.size()==capacity_) {
          std::make_heap(dist_indices_.begin(), dist_indices_.end());
          is_full_ = true;
          worst_distance_ = dist_indices_.front().first;
        }
      }
    }

    /** Remove all elements in the set
     */
    void clear() {
      dist_indices_.clear();
      worst_distance_ = std::numeric_limits<DistanceType>::max();
      is_full_ = false;
    }

    /** Check the status of the set
     * @return true if we have k NN
     */
    inline bool full() const
    {
      return is_full_;
    }

    /** The distance of the furthest neighbor
     * If we don't have enough neighbors, it returns the max float
     * @return
     */
    inline DistanceType worstDist() const
    {
      return worst_distance_;
    }
  protected:
    using ResultVector<DistanceType>::dist_indices_;
    using ResultVector<DistanceType>::is_full_;

    /** The maximum number of neighbors to consider */
    unsigned int capacity_;

    /** The worst distance found so far */
    DistanceType worst_distance_;
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/** Class that holds the radius nearest neighbors
 * It is more accurate than RadiusResult as it is not limited in the number of neighbors
 */
template<typename DistanceType>
  class RadiusResultVector : public ResultVector<DistanceType>
  {
  public:
    /** Constructor
     * @param capacity the number of neighbors to store at max
     */
    RadiusResultVector(float radius, float store_neighbors =  true) :
      radius_(radius), store_neighbors_(store_neighbors)
    {
      is_full_ = false;
    }

    /** Add a possible candidate to the best neighbors
     * @param dist distance for that neighbor
     * @param index index of that neighbor
     */
    void addPoint(DistanceType dist, int index)
    {
        if (dist <= radius_) {
            if (store_neighbors_) { 
                dist_indices_.push_back(typename ResultVector<DistanceType>::DistIndexPair(dist, index));
            }
            else {
                count_++;
            }
        }
        
    }

    /** Remove all elements in the set
     */
    inline void clear() {
      dist_indices_.clear();
      count_ = 0;
    }


    /** Check the status of the set
     * @return alwys false
     */
    inline bool full() const
    {
      return false;
    }

    /** Returns the number of points in the set
     * @return 
     */
    inline size_t size() const
    {
        if (store_neighbors_) {
            return dist_indices_.size();
        }
        else {
            return count_;
        }
    }

    /** The distance of the furthest neighbor
     * If we don't have enough neighbors, it returns the max float
     * @return
     */
    inline DistanceType worstDist() const
    {
      return radius_;
    }
  private:
    using ResultVector<DistanceType>::dist_indices_;
    using ResultVector<DistanceType>::is_full_;

    /** The furthest distance a neighbor can be */
    float radius_;
    /** Should we store the neighbors (or just cuont them) */
    bool store_neighbors_;
    /** Number of neighbors in radius */
    size_t count_;
  };

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/** Class that holds the k NN neighbors within a radius distance
 */
template<typename DistanceType>
  class KNNRadiusResultVector : public KNNResultVector<DistanceType>
  {
  public:
    /** Constructor
     * @param capacity the number of neighbors to store at max
     */
    KNNRadiusResultVector(unsigned int capacity, float radius)
    {
      this->capacity_ = capacity;
      this->radius_ = radius;
      this->dist_indices_.reserve(capacity_);
      this->clear();
    }

    /** Remove all elements in the set
     */
    void clear() {
      dist_indices_.clear();
      worst_distance_ = radius_;
      is_full_ = false;
    }
  private:
    using KNNResultVector<DistanceType>::dist_indices_;
    using KNNResultVector<DistanceType>::is_full_;
    using KNNResultVector<DistanceType>::worst_distance_;

    /** The maximum number of neighbors to consider */
    unsigned int capacity_;

    /** The maximum distance of a neighbor */
    float radius_;
  };




}

#endif //RESULTSET_H
