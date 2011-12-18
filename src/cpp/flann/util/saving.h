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
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE NNIndexGOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *************************************************************************/

#ifndef FLANN_SAVING_H_
#define FLANN_SAVING_H_

#include <cstring>
#include <vector>
#include <stdio.h>

#include "flann/general.h"
#include "flann/algorithms/nn_index.h"


#ifdef FLANN_SIGNATURE_
#undef FLANN_SIGNATURE_
#endif
#define FLANN_SIGNATURE_ "FLANN_INDEX"

namespace flann
{

/**
 * Structure representing the index header.
 */
struct IndexHeader
{
    char signature[16];
    char version[16];
    flann_datatype_t data_type;
    flann_algorithm_t index_type;
    size_t rows;
    size_t cols;
};

/**
 * Saves index header to stream
 *
 * @param stream - Stream to save to
 * @param index - The index to save
 */
template<typename Distance>
void save_header(FILE* stream, const NNIndex<Distance>& index)
{
    IndexHeader header;
    memset(header.signature, 0, sizeof(header.signature));
    strcpy(header.signature, FLANN_SIGNATURE_);
    memset(header.version, 0, sizeof(header.version));
    strcpy(header.version, FLANN_VERSION_);
    header.data_type = flann_datatype<typename Distance::ElementType>::value;
    header.index_type = index.getType();
    header.rows = index.size();
    header.cols = index.veclen();

    fwrite(&header, sizeof(header),1,stream);
}


/**
 *
 * @param stream - Stream to load from
 * @return Index header
 */
inline IndexHeader load_header(FILE* stream)
{
    IndexHeader header;
    int read_size = fread(&header,sizeof(header),1,stream);

    if (read_size!=1) {
        throw FLANNException("Invalid index file, cannot read");
    }

    if (strcmp(header.signature,FLANN_SIGNATURE_)!=0) {
        throw FLANNException("Invalid index file, wrong signature");
    }

    return header;
}


template<typename T>
void save_value(FILE* stream, const T& value, size_t count = 1)
{
    fwrite(&value, sizeof(value),count, stream);
}

template<typename T>
void save_value(FILE* stream, const flann::Matrix<T>& value)
{
    fwrite(&value, sizeof(value),1, stream);
    fwrite(value.ptr(), sizeof(T),value.rows*value.cols, stream);
}

template<typename T>
void save_value(FILE* stream, const std::vector<T>& value)
{
    size_t size = value.size();
    fwrite(&size, sizeof(size_t), 1, stream);
    fwrite(&value[0], sizeof(T), size, stream);
}

template<typename T>
void load_value(FILE* stream, T& value, size_t count = 1)
{
    size_t read_cnt = fread(&value, sizeof(value), count, stream);
    if (read_cnt != count) {
        throw FLANNException("Cannot read from file");
    }
}

template<typename T>
void load_value(FILE* stream, flann::Matrix<T>& value)
{
    size_t read_cnt = fread(&value, sizeof(value), 1, stream);
    if (read_cnt != 1) {
        throw FLANNException("Cannot read from file");
    }
    value = Matrix<T>(new T[value.rows*value.cols], value.rows, value.cols);
    read_cnt = fread(value.ptr(), sizeof(T), value.rows*value.cols, stream);
    if (read_cnt != value.rows*value.cols) {
        throw FLANNException("Cannot read from file");
    }
}


template<typename T>
void load_value(FILE* stream, std::vector<T>& value)
{
    size_t size;
    size_t read_cnt = fread(&size, sizeof(size_t), 1, stream);
    if (read_cnt!=1) {
        throw FLANNException("Cannot read from file");
    }
    value.resize(size);
    read_cnt = fread(&value[0], sizeof(T), size, stream);
    if (int(read_cnt)!=int(size)) {
        throw FLANNException("Cannot read from file");
    }
}

}

#endif /* FLANN_SAVING_H_ */
