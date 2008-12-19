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
            
