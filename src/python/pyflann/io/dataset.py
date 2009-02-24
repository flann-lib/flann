#Copyright 2008-2009  Marius Muja (mariusm@cs.ubc.ca). All rights reserved.
#Copyright 2008-2009  David G. Lowe (lowe@cs.ubc.ca). All rights reserved.
#
#THE BSD LICENSE
#
#Redistribution and use in source and binary forms, with or without
#modification, are permitted provided that the following conditions
#are met:
#
#1. Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
#2. Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
#
#THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
#IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
#OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
#IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
#INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
#NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
#THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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