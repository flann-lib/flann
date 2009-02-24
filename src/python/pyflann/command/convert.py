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

from pyflann.command import BaseCommand
from pyflann.exceptions import FLANNException
from pyflann.io.dataset import read,write

from os.path import isfile
import numpy
import time


class ConvertCommand(BaseCommand):
    
    def __init__(self):
        
        self.parser.add_option("-i", "--input-file", dest="input_file",
                  help="The name of the file containing the dataset to convert", metavar="FILE")
        self.parser.add_option("-d", "--dtype", dest="dtype",
                  help="Input data type (when needed)")
        self.parser.add_option("-o", "--output-file", dest="output_file", 
                  help="The name of the output file.", metavar="FILE")
        self.parser.add_option("-F", "--format", type="string", default="npy",
                  help="Output format (npy, dat, bin) (Default: npy)")

    def execute(self):
        if self.options.input_file==None:
            raise FLANNException("Need an input file")
        if self.options.output_file==None:
            raise FLANNException("Need an output file")
        print "Reading input data from file "+self.options.input_file
        dataset = read(self.options.input_file, dtype=numpy.dtype(self.options.dtype))
        print "Writing to file %s"%self.options.output_file
        write(dataset,self.options.output_file, format=self.options.format)
            
