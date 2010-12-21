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

template <typename T>
struct BranchStruct {
	T node;           /* Tree node at which search resumes */
	float mindistsq;     /* Minimum distance to query for all nodes below. */

	BranchStruct() {};
	BranchStruct(const T& aNode, float dist) : node(aNode), mindistsq(dist) {};

	bool operator<(const BranchStruct<T>& rhs)
	{
        return mindistsq<rhs.mindistsq;
	}
};


template <typename DistanceType>
class ResultSet
{
public:
	virtual ~ResultSet() {};

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
		dists[capacity-1] = (std::numeric_limits<DistanceType>::max) ();
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
		for (i=count; i>0;--i) {
#ifdef FLANN_FIRST_MATCH 
			if ( (dists[i-1]>dist) || (dist==dists[i-1] && indices[i-1]>index) ) {
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
			if (capacity>0 && count < capacity) {
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


}

#endif //RESULTSET_H
