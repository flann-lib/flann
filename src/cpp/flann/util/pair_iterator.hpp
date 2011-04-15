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


#ifndef PAIR_ITERATOR_HPP_
#define PAIR_ITERATOR_HPP_

#include <algorithm>
#include <functional>

/**
 * This file contains a pair iterator that can be used to sort in parallel
 * two arrays (or iterators), such as it sorts one array and permutes the
 * second one accordingly.
 */

namespace flann
{

template<typename First, typename Second>
class pair
{
public:
    First first;
    Second second;

    pair(First a, Second b) : first(a), second(b) {}

    template<typename U, typename V>
    pair(const pair<U,V>& x) : first(x.first), second(x.second) {}

    template<typename U, typename V>
    pair& operator=(const pair<U,V>& x) { first = x.first; second = x.second; return *this; }

    pair& operator=(const pair& x) { first = x.first; second = x.second; return *this; }
};

template<typename SortIterator, typename PermuteIterator>
struct pair_iterator_traits
{
    typedef std::random_access_iterator_tag iterator_category;
    typedef pair<
        typename std::iterator_traits<SortIterator>::value_type,
        typename std::iterator_traits<PermuteIterator>::value_type > value_type;
    typedef pair<
        typename std::iterator_traits<SortIterator>::value_type&,
        typename std::iterator_traits<PermuteIterator>::value_type& > reference;
    typedef typename std::iterator_traits<SortIterator>::difference_type difference_type;
    typedef value_type* pointer;
};

template<typename SortIterator, typename PermuteIterator>
class pair_iterator
{
public:
    // public typedefs
    typedef typename pair_iterator_traits<SortIterator, PermuteIterator>::iterator_category iterator_category;
    typedef typename pair_iterator_traits<SortIterator, PermuteIterator>::value_type value_type;
    typedef typename pair_iterator_traits<SortIterator, PermuteIterator>::reference reference;
    typedef typename pair_iterator_traits<SortIterator, PermuteIterator>::difference_type difference_type;
    typedef typename pair_iterator_traits<SortIterator, PermuteIterator>::pointer pointer;
    typedef pair_iterator self;

    // constructors
    pair_iterator(){ }
    pair_iterator(SortIterator si, PermuteIterator pi) : si_(si), pi_(pi) { }

    // operators
    inline self& operator++( ) { ++si_; ++pi_; return *this; }
    inline self operator++(int) { self tmp = *this; si_++; pi_++; return tmp; }
    inline self& operator--( ) { --si_; --pi_; return *this; }
    inline self operator--(int) { self tmp = *this; si_--; pi_--; return tmp; }
    inline self& operator+=(difference_type x) { si_ += x; pi_ += x; return *this; }
    inline self& operator-=(difference_type x) {si_ -= x; pi_ -= x; return *this; }
    inline reference operator[](difference_type n) { return reference(*(si_+n),*(si_+n)); }
    inline reference operator*() const { return reference(*si_,*pi_); }
    inline self operator+(difference_type y) { return self(si_+y, pi_+y); }
    inline self operator-(difference_type y) { return self(si_-y, pi_-y); }
    inline bool operator==(const self& y) { return si_ == y.si_; }
    inline bool operator!=(const self& y) { return si_ != y.si_; }
    inline bool operator<(const self& y) { return si_ < y.si_;  }
    inline difference_type operator-(const self& y) { return si_ - y.si_;   }

    // friend operators
    friend inline self operator+(difference_type x, const self& y) { return y + x;  }
    friend inline self operator-(difference_type x, const self& y) { return y - x; }
private:
    SortIterator si_;
    PermuteIterator pi_;
};

template <class SortIterator, class PermuteIterator>
struct pair_iterator_compare : std::binary_function<
        typename pair_iterator_traits<SortIterator, PermuteIterator>::value_type,
        typename pair_iterator_traits<SortIterator, PermuteIterator>::value_type,
        bool>
{
    typedef typename pair_iterator_traits<SortIterator, PermuteIterator>::value_type T;
    inline bool operator()(const  T& t1, const T& t2)
    {
        return t1.first < t2.first;
    }
};

template <class SortIterator, class PermuteIterator>
inline pair_iterator<SortIterator, PermuteIterator> make_pair_iterator(SortIterator si, PermuteIterator pi)
{
    return pair_iterator<SortIterator, PermuteIterator>(si, pi);
}

} // namespace flann

#endif /* PAIR_ITERATOR_HPP_ */
