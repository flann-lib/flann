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
    int rows;
    int cols;
    T* data;


	Dataset(int rows_, int cols_, T* data_ = NULL) : 
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
    T* operator[](int index) 
    {
        return data+index*cols;
    }	

    T* operator[](int index) const
    {
        return data+index*cols;
    }   



    Dataset<T>* sample(int size, bool remove = false)
    {
        UniqueRandom rand(rows);
        Dataset<T> *newSet = new Dataset<T>(size,cols);
        
        T *src,*dest;
        for (int i=0;i<size;++i) {
            int r = rand.next();
            dest = (*newSet)[i];
            src = (*this)[r];
            for (int j=0;j<cols;++j) {
                dest[j] = src[j];
            }
            if (remove) {
                dest = (*this)[rows-i-1];
                src = (*this)[r];
                for (int j=0;j<cols;++j) {
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

    Dataset<T>* sample(int size) const
    {
        UniqueRandom rand(rows);
        Dataset<T> *newSet = new Dataset<T>(size,cols);
        
        T *src,*dest;
        for (int i=0;i<size;++i) {
            int r = rand.next();
            dest = (*newSet)[i];
            src = (*this)[r];
            for (int j=0;j<cols;++j) {
                dest[j] = src[j];
            }
        }
                
        return newSet;
    }

};


#endif //DATASET_H
