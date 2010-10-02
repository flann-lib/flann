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


#ifndef IO_H_
#define IO_H_

#include <hdf5.h>

#include "flann/util/matrix.h"


namespace flann {

namespace {

template<typename T>
hid_t get_hdf5_type()
{
	throw FLANNException("Unsupported type for IO operations");
}

template<> hid_t get_hdf5_type<char>() { return H5T_NATIVE_CHAR; }
template<> hid_t get_hdf5_type<unsigned char>() { return H5T_NATIVE_UCHAR; }
template<> hid_t get_hdf5_type<short int>() { return H5T_NATIVE_SHORT; }
template<> hid_t get_hdf5_type<unsigned short int>() { return H5T_NATIVE_USHORT; }
template<> hid_t get_hdf5_type<int>() { return H5T_NATIVE_INT; }
template<> hid_t get_hdf5_type<unsigned int>() { return H5T_NATIVE_UINT; }
template<> hid_t get_hdf5_type<long>() { return H5T_NATIVE_LONG; }
template<> hid_t get_hdf5_type<unsigned long>() { return H5T_NATIVE_ULONG; }
template<> hid_t get_hdf5_type<float>() { return H5T_NATIVE_FLOAT; }
template<> hid_t get_hdf5_type<double>() { return H5T_NATIVE_DOUBLE; }
template<> hid_t get_hdf5_type<long double>() { return H5T_NATIVE_LDOUBLE; }
}


template<typename T>
void save_to_file(const flann::Matrix<T>& flann_dataset, const std::string& filename, const std::string& name)
{
	herr_t status;
	hid_t file_id = H5Fcreate(filename.c_str(), H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT);

	hsize_t     dimsf[2];              // dataset dimensions
	dimsf[0] = flann_dataset.rows;
	dimsf[1] = flann_dataset.cols;

	hid_t space_id = H5Screate_simple(2, dimsf, NULL);
	hid_t memspace_id = H5Screate_simple(2, dimsf, NULL);

	hid_t dataset_id = H5Dcreate(file_id, name.c_str(), get_hdf5_type<T>(), space_id, H5P_DEFAULT);

	status = H5Dwrite(dataset_id, get_hdf5_type<T>(), memspace_id, space_id, H5P_DEFAULT, flann_dataset.data );

	if (status>0) {
		throw FLANNException("Error writing to dataset");
	}
}


template<typename T>
void load_from_file(flann::Matrix<T>& flann_dataset, const std::string& filename, const std::string& name)
{
	herr_t status;
	hid_t file_id = H5Fopen(filename.c_str(), H5F_ACC_RDWR, H5P_DEFAULT);
	hid_t dataset_id = H5Dopen(file_id, name.c_str());

	hid_t space_id = H5Dget_space(dataset_id);

	hsize_t dims_out[2];
	H5Sget_simple_extent_dims(space_id, dims_out, NULL);

	flann_dataset.rows = dims_out[0];
	flann_dataset.cols = dims_out[1];
	flann_dataset.data = new T[flann_dataset.rows*flann_dataset.cols];

	status = H5Dread(dataset_id, get_hdf5_type<T>(), H5S_ALL, H5S_ALL, H5P_DEFAULT, flann_dataset.data);

	if (status>0) {
		throw FLANNException("Error reading dataset");
	}
}


}

#endif /* IO_H_ */
