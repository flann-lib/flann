from __future__ import with_statement

from pyflann.exceptions import FLANNException
import numpy



def write(dataset, filename):
    if not isinstance(dataset,numpy.ndarray):
        raise FLANNException("Can only save numpy arrays")

    try:
        numpy.save(filename, dataset)
    except:
        raise FLANNException("Format not supported. You need at least numpy version 1.1")


def read(filename, dtype = numpy.float32):
    try:
        tmp = numpy.save
    except:
        raise FLANNException("Format not supported. You need at least numpy version 1.1")
    
    data = numpy.load(filename)    
    return data
    