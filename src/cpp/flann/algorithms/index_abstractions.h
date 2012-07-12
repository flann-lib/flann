/***********************************************************************
 * Software License Agreement (BSD License)
 *
 * Copyright 2008-2009  Marius Muja (mariusm@cs.ubc.ca). All rights reserved.
 * Copyright 2008-2009  David G. Lowe (lowe@cs.ubc.ca). All rights reserved.
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

#ifndef INDEX_ABSTRACTIONS_H
#define INDEX_ABSTRACTIONS_H


#include "flann/util/matrix.h"
#include "flann/util/params.h"
#include "flann/algorithms/dist.h"


namespace flann {


class IndexBase
{
public:
    virtual ~IndexBase() {};

    virtual void buildIndex() = 0;

    virtual size_t veclen() const = 0;

    virtual size_t size() const = 0;

    virtual flann_algorithm_t getType() const = 0;

    virtual int usedMemory() const = 0;

    virtual IndexParams getParameters() const = 0;
    
    virtual void loadIndex(FILE* stream) = 0;
    
    virtual void saveIndex(FILE* stream) = 0;

};


template<typename ElementType_, typename DistanceType_ = typename Accumulator<ElementType_>::Type>
class TypedIndexBase : public IndexBase
{
public:
    typedef ElementType_ ElementType;
    typedef DistanceType_ DistanceType;

    virtual void addPoints(const Matrix<ElementType>& points, float rebuild_threshold) = 0;
    
    virtual void removePoint(size_t index) = 0;

    virtual int knnSearch(const Matrix<ElementType>& queries,
            Matrix<int>& indices,
            Matrix<DistanceType>& dists,
            size_t knn,
            const SearchParams& params) = 0;

    virtual int knnSearch(const Matrix<ElementType>& queries,
            std::vector< std::vector<int> >& indices,
            std::vector<std::vector<DistanceType> >& dists,
            size_t knn,
            const SearchParams& params) = 0;

    virtual int radiusSearch(const Matrix<ElementType>& queries,
            Matrix<int>& indices,
            Matrix<DistanceType>& dists,
            DistanceType radius,
            const SearchParams& params) = 0;

    virtual int radiusSearch(const Matrix<ElementType>& queries,
            std::vector< std::vector<int> >& indices,
            std::vector<std::vector<DistanceType> >& dists,
            DistanceType radius,
            const SearchParams& params) = 0;
};

/**
 * Class that wraps an index and makes it a polymorphic object.
 */
template<typename Index>
class IndexWrapper : public TypedIndexBase<typename Index::ElementType, typename Index::DistanceType>
{
public:
    typedef typename Index::ElementType ElementType;
    typedef typename Index::DistanceType DistanceType;

    IndexWrapper(Index* index) : index_(index)
    {
    };

    virtual ~IndexWrapper()
    {
        delete index_;
    }

    void buildIndex()
    {
        index_->buildIndex();
    }

    void buildIndex(const Matrix<ElementType>& dataset)
    {
        index_->buildIndex(dataset);
    }
    
    void addPoints(const Matrix<ElementType>& points, float rebuild_threshold = 2)
    {
        index_->addPoints(points, rebuild_threshold);
    }

    void removePoint(size_t index)
    {
        index_->removePoint(index);
    }

    size_t veclen() const
    {
        return index_->veclen();
    }

    size_t size() const
    {
        return index_->size();
    }

    flann_algorithm_t getType() const
    {
        return index_->getType();
    }

    int usedMemory() const
    {
        return index_->usedMemory();
    }

    IndexParams getParameters() const
    {
        return index_->getParameters();
    }
    
    void loadIndex(FILE* stream)
    {
        index_->loadIndex(stream);        
    }
    
    void saveIndex(FILE* stream)
    {
        index_->saveIndex(stream);
    }

    Index* getIndex() const
    {
        return index_;
    }
    

    int knnSearch(const Matrix<ElementType>& queries,
            Matrix<int>& indices,
            Matrix<DistanceType>& dists,
            size_t knn,
            const SearchParams& params)
    {
        return index_->knnSearch(queries, indices,dists, knn, params);
    }

    int knnSearch(const Matrix<ElementType>& queries,
            std::vector< std::vector<int> >& indices,
            std::vector<std::vector<DistanceType> >& dists,
            size_t knn,
            const SearchParams& params)
    {
        return index_->knnSearch(queries, indices,dists, knn, params);
    }

    int radiusSearch(const Matrix<ElementType>& queries,
            Matrix<int>& indices,
            Matrix<DistanceType>& dists,
            DistanceType radius,
            const SearchParams& params)
    {
        return index_->radiusSearch(queries, indices, dists, radius, params);
    }

    int radiusSearch(const Matrix<ElementType>& queries,
            std::vector< std::vector<int> >& indices,
            std::vector<std::vector<DistanceType> >& dists,
            DistanceType radius,
            const SearchParams& params)
    {
        return index_->radiusSearch(queries, indices, dists, radius, params);
    }

private:
    Index* index_;
};

}

#endif
