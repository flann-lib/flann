# This module defines a set of exceptions that are used through out
# the binding modules.

class FLANNException(Exception):
    def __init__(self, *args):
        Exception.__init__(self, *args)

