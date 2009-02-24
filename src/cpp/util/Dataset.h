/*
Copyright 2008-2009  Marius Muja (mariusm@cs.ubc.ca). All rights reserved.
Copyright 2008-2009  David G. Lowe (lowe@cs.ubc.ca). All rights reserved.

THE BSD LICENSE

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#ifndef DATASET_H
#define DATASET_H

#include <stdio.h>
#include <Random.h>

/**
* Class implementing a generic rectangular dataset.
*/
template <typename T>
class Dataset {

    /**
    * Flag showing if the class owns its data storage.
    */
    bool ownData;

    void shallow_copy(const Dataset& rhs)
    {
        data = rhs.data;
        rows = rhs.rows;
        cols = rhs.cols;
        ownData = false;
    }

public:
    long rows;
    long cols;
    T* data;


	Dataset(long rows_, long cols_, T* data_ = NULL) :
        rows(rows_), cols(cols_), data(data_), ownData(false)
	{
        if (data_==NULL) {
		    data = new T[rows*cols];
            ownData = true;
        }
	}

    Dataset(const Dataset& d)
    {
        shallow_copy(d);
    }

    const Dataset& operator=(const Dataset& rhs)
    {
        if (this!=&rhs) {
            shallow_copy(rhs);
        }
        return *this;
    }

	~Dataset()
	{
        if (ownData) {
		  delete[] data;
        }
	}

    /**
    * Operator that return a (pointer to a) row of the data.
    */
    T* operator[](long index)
    {
        return data+index*cols;
    }

    T* operator[](long index) const
    {
        return data+index*cols;
    }



    Dataset<T>* sample(long size, bool remove = false)
    {
        UniqueRandom rand(rows);
        Dataset<T> *newSet = new Dataset<T>(size,cols);

        T *src,*dest;
        for (long i=0;i<size;++i) {
            long r = rand.next();
            dest = (*newSet)[i];
            src = (*this)[r];
            for (long j=0;j<cols;++j) {
                dest[j] = src[j];
            }
            if (remove) {
                dest = (*this)[rows-i-1];
                src = (*this)[r];
                for (long j=0;j<cols;++j) {
                    swap(*src,*dest);
                    src++;
                    dest++;
                }
            }
        }

        if (remove) {
            rows -= size;
        }

        return newSet;
    }

    Dataset<T>* sample(long size) const
    {
        UniqueRandom rand(rows);
        Dataset<T> *newSet = new Dataset<T>(size,cols);

        T *src,*dest;
        for (long i=0;i<size;++i) {
            long r = rand.next();
            dest = (*newSet)[i];
            src = (*this)[r];
            for (long j=0;j<cols;++j) {
                dest[j] = src[j];
            }
        }

        return newSet;
    }

};


#endif //DATASET_H
