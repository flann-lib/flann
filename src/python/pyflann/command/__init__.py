
__all__ = [ "generate_random", "compute_gt", "compute_nn", "autotune", "sample_dataset", "cluster", "run_test" ]

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