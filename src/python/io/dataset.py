from __future__ import with_statement

from util.exceptions import FLANNException
import binary_dataset
import dat_dataset

def read(filename):
    with open(filename,"rb") as fd:
        header = fd.read(10)
    
    if header[0:6]=="BINARY":
        return binary_dataset.read(filename)
    else:
        import string
        try:
            value = float(string.split(header)[0])
            return dat_dataset.read(filename)
        except:
            raise FLANNException("Error: Unknown dataset format")
    
    
def write(dataset, filename, format = "bin"):
    if format=="bin":
        binary_dataset.write(dataset,filename)
    elif format=="dat":
        dat_dataset.write(dataset,filename)
    else:
        raise FLANNException("Error: Unknown dataset format")