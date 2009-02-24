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

__all__ = [ "generate_random", "compute_gt", "compute_nn", "autotune", "sample_dataset", "cluster", "run_test", "convert" ]

from optparse import OptionParser
from string import split

from pyflann.exceptions import *

_commands = {}

def get_command(name):
    exec "import %s"%name
    try:
        return _commands[name]()
    except KeyError:
        raise CommandException("Invalid command")


class CommandMetaClass(type):
    def __new__(meta, classname, bases, classDict):
        #print
        #print 'Class Name:', classname
        #print 'Bases:', bases
        #print 'Class Attributes', classDict
        new_class = type.__new__(meta, classname, bases, classDict)        
        if bases != ():
            _commands[split(new_class.__module__,'.')[-1]] = new_class
        return new_class

class BaseCommand:
    
    __metaclass__ = CommandMetaClass
    
    parser = OptionParser(usage="Usage: %prog [command command_args]")
    
    def execute_command(self,args):
        (self.options, remaining_args) = self.parser.parse_args(args)
        self.execute()
    
    def print_help():
        self.parser.print_help()