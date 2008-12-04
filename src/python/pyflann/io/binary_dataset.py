from __future__ import with_statement

from pyflann.exceptions import FLANNException
import numpy
from scipy.io.numpyio import fwrite


def write(dataset, filename):
    if not isinstance(dataset,numpy.ndarray):
        raise FLANNException("Can only save numpy arrays")
    
    with open(filename, 'w') as fd_meta:
        fd_meta.write(\
"""BINARY
%s
%d
%d
%s"""%(filename+".bin",dataset.shape[1],dataset.shape[0],dataset.dtype.name))
    with open(filename+".bin", 'wb') as fd:
        fwrite(fd, dataset.size, dataset)


def read(filename, dtype = numpy.float32):
    
    with open(filename,"rb") as fd:
        header = fd.readline()
        assert( header[0:6] == "BINARY")
        bin_filename = fd.readline().strip()
        length = int(fd.readline())
        count = int(fd.readline())
        thetype = fd.readline().strip()
    data = numpy.fromfile(file=bin_filename, dtype=numpy.dtype(thetype), count=count*length)
    data.shape = (count,length)
    return data
    