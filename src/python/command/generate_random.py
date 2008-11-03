
from command import BaseCommand
from util.exceptions import FLANNException

from numpy.random import random
from numpy import float32
from io.dataset import write
from sys import stdout


class GenerateRandomCommand(BaseCommand):

    def __init__(self):
        self.parser.add_option("-f", "--file", dest="filename",
                  help="write result to FILE", metavar="FILE")
        self.parser.add_option("-c", "--count", type="int", default=1000,
                  help="Size of the dataset to generate (number of features)")
        self.parser.add_option("-l", "--length", type="int", default=128,
                  help="Length of one feature")

    def execute(self):
        if self.options.count>0 and self.options.length>0 and self.options.filename!=None:
            print "Saving a random (%d,%d) matrix in file %s... "%(self.options.count,self.options.length, self.options.filename),
            stdout.flush()
            data = float32(random((self.options.count,self.options.length)))
            write(data,self.options.filename)
            print "done"
        else:
            raise FLANNException("Error: Incorrect arguments specified (a filename must be given and the count and length must be positive)")
