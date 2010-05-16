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
import tables
import numpy


def check(filename):
    f = open(filename,"r")
    header = f.read(4)
    if header[1:4]=="HDF": return True
    return False
        

def save(dataset, filename, **kwargs):
    if not isinstance(dataset,numpy.ndarray):
        raise FLANNException("Dataset must be in numpy format")
    try:
        if 'title' in kwargs:
            title_name = kwargs['title']
        else:
            title_name = "Dataset saved by pyflann"
        if 'dataset_name' in kwargs:
            dataset_name = kwargs['dataset_name']
        else:
            dataset_name = 'dataset'
        h5file = tables.openFile(filename, mode = "a", title = title_name)
        h5file.createArray(h5file.root, dataset_name, dataset)
        h5file.close()
    except Exception as e:
        h5file.close()
        raise FLANNException(e)


def load(filename, rows = -1, cols = -1, dtype = numpy.float32, **kwargs):
    try:
        h5file = tables.openFile(filename, mode = 'r')
        if 'dataset_name' in kwargs:
            dataset_name = kwargs['dataset_name']
        else:
            dataset_name = 'dataset'
        
        for node in h5file.walkNodes("/", "Array"):
            if node.name == dataset_name:
                data = node.read()
        h5file.close()
        return data
    except Exception as e:
        h5file.close()
        raise FLANNException(e)
        
    