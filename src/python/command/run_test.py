from command import BaseCommand
from util.exceptions import FLANNException
from pyflann import *

from io.dataset import read,write
import sys




class RunTestCommand(BaseCommand):
    
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
        self.parser.add_option("-m", "--match-file", 
                  help="File with ground truth matches", metavar="FILE")
        self.parser.add_option("-n", "--nn", type="int", default=1,
                  help="Number of nearest neighbors to search for")
        self.parser.add_option("-c", "--checks", type="int", default=32,
                  help="Number of times to restart search (in best-bin-first manner)")
        self.parser.add_option("-P", "--precision", type="float", default=-1,
                  help="Run the test until reaching this precision")
        self.parser.add_option("-K", "--skip-matches", type="int", default=0,
                  help="Skip the first NUM matches at test phase", metavar="NUM")

    def execute(self):
        
        if self.options.input_file == None:
            raise FLANNException("No input file given.")
        if self.options.algorithm == None:
            raise FLANNException("No algorithm specified")
        if self.options.test_file == None:
            raise FLANNException("No test file given.")
        if self.options.match_file == None:
            raise FLANNException("No match file given.")
        
        print 'Reading input dataset from', self.options.input_file
        dataset = read(self.options.input_file)
        
        flann = FLANN(log_level=self.options.log_level)
        flann.build_index(dataset, algorithm = self.options.algorithm,
                trees=self.options.trees, branching=self.options.branching,
                iterations=self.options.max_iterations, centers_init=self.options.centers_init)        
        
        print 'Reading test dataset from', self.options.test_file
        testset = read(self.options.test_file)
        
        print 'Reading ground truth from matches from', self.options.test_file
        matches = read(self.options.match_file, dtype = int)
        
        if self.options.precision>0:
            checks, time = test_with_precision(flann, dataset, testset, matches, self.options.precision, self.options.nn)
        else:
            precision, time = test_with_checks(flann, dataset, testset, matches, self.options.checks, self.options.nn)
