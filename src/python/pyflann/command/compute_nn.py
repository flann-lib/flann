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

import sys




class ComputeNearestNeighborsCommand(BaseCommand):
    
    def __init__(self):
        
        self.parser.add_option("-i", "--input-file", dest="input_file",
                  help="Name of file with input dataset", metavar="FILE")
        self.parser.add_option("-a", "--algorithm", 
                  help="The algorithm to use when constructing the index (kdtree, kmeans...)")
        self.parser.add_option("-r", "--trees", type="int", default=1,
                  help="Number of parallel trees to use (where available, for example kdtree)")
        self.parser.add_option("-b", "--branching", type="int", default=2,
                  help="Branching factor (where applicable, for example kmeans) (default: 2)")
        self.parser.add_option("-C", "--centers-init", default="random",
                  help="How to choose the initial cluster centers for kmeans (random, gonzales) (default: random)")
        self.parser.add_option("-M", "--max-iterations", type="int", default=sys.maxint,
                  help="Max iterations to perform for kmeans (default: until convergence)")
        self.parser.add_option("-l", "--log-level", default="info",
                  help="Log level (none < fatal < error < warning < info) (Default: info)")
        self.parser.add_option("-t", "--test-file", 
                  help="Name of file with test dataset", metavar="FILE")
        self.parser.add_option("-o", "--output-file", 
                  help="Output file to save the features to", metavar="FILE")
        self.parser.add_option("-n", "--nn", type="int", default=1,
                  help="Number of nearest neighbors to search for")
        self.parser.add_option("-c", "--checks", type="int", default=32,
                  help="Number of times to restart search (in best-bin-first manner)")
        self.parser.add_option("-K", "--skip-matches", type="int", default=0,
                  help="Skip the first NUM matches at test phase", metavar="NUM")

    def execute(self):
        
        if self.options.input_file == None:
            raise FLANNException("No input file given.")
        if self.options.algorithm == None:
            raise FLANNException("No algorithm specified")
        if self.options.test_file == None:
            raise FLANNException("No test file given.")
        if self.options.output_file == None:
            raise FLANNException("No output file given.")
        
        print 'Reading input dataset from', self.options.input_file
        dataset = read(self.options.input_file)
        
        flann = FLANN(log_level=self.options.log_level)
        flann.build_index(dataset, algorithm = self.options.algorithm,
                trees=self.options.trees, branching=self.options.branching,
                iterations=self.options.max_iterations, centers_init=self.options.centers_init)        
        
        print 'Reading test dataset from', self.options.test_file
        testset = read(self.options.test_file)
        
        print "Searching for nearest neighbors"
        matches,dists = flann.nn_index(testset, self.options.nn, checks = self.options.checks)

        print "Writing matches to", self.options.output_file
        write(matches, self.options.output_file, format="dat")
