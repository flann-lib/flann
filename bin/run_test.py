#!/usr/bin/env python2


import sys
import unittest

if __name__ == "__main__":
    if len(sys.argv) == 1:
        print("Usage: %s file" % sys.argv[0])
        sys.exit(1)

    test_file = sys.argv[1]
    sys.argv = sys.argv[1:]
    execfile(test_file)
