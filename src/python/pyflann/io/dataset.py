from __future__ import with_statement

from pyflann.exceptions import FLANNException
import binary_dataset
import dat_dataset
import npy_dataset

from numpy import float32

def read(filename, dtype = float32):
    with open(filename,"rb") as fd:
        header = fd.read(10)
    
    if header[0:6]=="BINARY":
        return binary_dataset.read(filename, dtype)
    elif header[1:6]=="NUMPY":
        return npy_dataset.read(filename,dtype)
    else:
        import string
        try:
            value = float(string.split(header)[0])
            return dat_dataset.read(filename, dtype)
        except:
            raise FLANNException("Error: Unknown dataset format")
    
    
def write(dataset, filename, format = "bin"):
    if format=="bin":
        binary_dataset.write(dataset,filename)
    elif format=="dat":
        dat_dataset.write(dataset,filename)
    elif format=="npy":
        npy_dataset.write(dataset,filename)
    else:
        raise FLANNException("Error: Unknown dataset format")