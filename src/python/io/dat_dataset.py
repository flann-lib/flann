from __future__ import with_statement

from util.exceptions import FLANNException
import numpy
from scipy.io.numpyio import fwrite


def write(dataset, filename):
    if not isinstance(dataset,numpy.ndarray):
        raise FLANNException("Can only save numpy arrays")    
    numpy.savetxt(filename,dataset, fmt="%g")

def read(filename):
    dataset = numpy.loadtxt(filename, dtype=numpy.float32)
    return dataset