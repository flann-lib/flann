from command import BaseCommand
from util.exceptions import FLANNException
from pyflann import *

from io.dataset import read,write
from os.path import isfile
import numpy
import time
import sys


class ComputeIndexCommand(BaseCommand):
    
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

    def execute(self):
        self.nn = FLANN(log_level=self.options.log_level)
        
        if self.options.input_file == None:
            raise FLANNException("No input file given.")
        if self.options.algorithm == None:
            raise FLANNException("No algorithm specified")
        print 'Reading input dataset from', self.options.input_file
        self.dataset = read(self.options.input_file)
        self.nn.build_index(self.dataset, algorithm = self.options.algorithm,
                trees=self.options.trees, branching=self.options.branching,
                iterations=self.options.max_iterations, centers_init=self.options.centers_init)