#!/usr/bin/env python2


import sys
import os.path as op
import unittest

if __name__ == "__main__":
    if len(sys.argv)==1:
        print "Usage: %s file"%sys.argv[0]
        sys.exit(1)

    python_path = op.abspath(op.join( op.dirname(__file__),"..","src","python"))
    sys.path.append(python_path)

    test_file = sys.argv[1]
    sys.argv = sys.argv[1:]
    execfile(test_file)
