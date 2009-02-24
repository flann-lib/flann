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
from pyflann.io.dataset import write

from numpy.random import random
from numpy import float32
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
