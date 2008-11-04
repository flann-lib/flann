from compute_index import *
from util.exceptions import FLANNException

from io.dataset import read,write
from os.path import isfile
import numpy
import time



class ComputeNearestNeighborsCommand(ComputeIndexCommand):
    
    def __init__(self):
        
        ComputeIndexCommand.__init__(self)
        
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
        if self.options.test_file == None:
            raise FLANNException("No test file given.")
        if self.options.output_file == None:
            raise FLANNException("No output file given.")
        
        ComputeIndexCommand.execute(self)
        
        print 'Reading test dataset from', self.options.test_file
        testset = read(self.options.test_file)
        
        print "Searching for nearest neighbors"
        matches = self.nn.nn_index(testset, self.options.nn, checks = self.options.checks)

        print "Writing matches to", self.options.output_file
        write(matches, self.options.output_file, format="dat")
