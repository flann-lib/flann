from command import BaseCommand
from util.exceptions import FLANNException

from io.dataset import read,write
from os.path import isfile
import numpy
import time

from nn.misc import *



class ComputeGroundTruthCommand(BaseCommand):
    
    def __init__(self):
        
        self.parser.add_option("-f", "--file", dest="input_file",
                  help="The name of the file containing the dataset to sample", metavar="FILE")
        self.parser.add_option("-s", "--save-file", dest="save_file", default="sampled",
                  help="The name of the file to save the sampled dataset to", metavar="FILE")
        self.parser.add_option("-c", "--count", type="int", default=1000,
                  help="Number of features to sample. (default: 1000)")
        self.parser.add_option("-F", "--format", type="string", default="bin",
                  help="Save format (dat, bin) (Default: bin)")

    def execute(self):
        if self.options.input_file==None:
            raise FLANNException("Need an input file")
        print "Reading input data from file "+self.options.input_file
        dataset = read(self.options.input_file)
        
        if count>0:
            print "Sampling %d features"%self.options.count
            sampledset = sample_dataset(dataset, self.options.count)
                
            print "Writing sampled dataset to file %s",self.options.save_file
            write(sampledset,self.options.save_file, format=self.options.format)
            
