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
from pyflann import *
from pyflann.io.dataset import read,write

from os.path import isfile
import numpy
import time
import sys
import pickle
from ConfigParser import *



class AutotuneCommand(BaseCommand):
    
    def __init__(self):
        
        self.parser.add_option("-i", "--input-file", 
                  help="Name of file with input dataset", metavar="FILE")
        self.parser.add_option("-p", "--params-file",
                  help="Name of file where to save the params", metavar="FILE")
        self.parser.add_option("-P", "--precision", type="float", default=0.95,
                  help="The desired search precision (default: 0.95)" )
        self.parser.add_option("-b", "--build-weight", type="float", default=0.01,
                  help="Index build time weight (relative to search time) (default: 0.01)" )
        self.parser.add_option("-m", "--memory-weight", type="float", default=0,
                  help="Index memory weight (default: 0)" )
        self.parser.add_option("-s", "--sample-fraction", type="float", default=0.1,
                  help="Fraction of the input dataset to use for parameter tunning( default: 0.1)" )
        self.parser.add_option("-l", "--log-level", default="info",
                  help="Log level (none < fatal < error < warning < info) (Default: info)")

    def execute(self):
        self.nn = FLANN(log_level=self.options.log_level)
        
        if self.options.input_file == None:
            raise FLANNException("No input file given.")
        print 'Reading input dataset from', self.options.input_file
        self.dataset = read(self.options.input_file)
        
        if self.options.precision<0 or self.options.precision>1:
            raise FLANNException("The precision argument must be between 0 and 1.")
        params = self.nn.build_index(self.dataset, target_precision=self.options.precision, build_weight=self.options.build_weight,
                memory_weight=self.options.memory_weight, sample_fraction=self.options.sample_fraction)
        
        if self.options.params_file != None:
            params_stream = open(self.options.params_file,"w")
        else:
            params_stream = sys.stdout
        configdict = ConfigParser();
        configdict.add_section('params')
        for (k,v) in params.items():
            configdict.set('params',k,v)
        configdict.write(params_stream)
