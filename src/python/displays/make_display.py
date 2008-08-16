##!/usr/bin/env python
from __future__ import with_statement
import sys
import string
import numpy

def project(vec):
    return vec[1:3]


class Node:
    def build(self,f):
        line = f.readline()
        (count,veclen,self.level,self.leaf) = map(int,string.split(line))
        self.vecs = numpy.empty((count,2),dtype=numpy.float32)
        for i in xrange(count):
            line = f.readline()
            self.vecs[i,:] = project(numpy.array(map(float,string.split(line))))
        
        if not self.leaf:
            self.childs = [None]*count
            for i in xrange(count):
                self.childs[i] = Node()
                self.childs[i].build(f)



def get_scaling_params(node):
    pass


def draw_node(node,points):
    pass




def read_tree(filename):
    f = open(filename,"r");
    root = Node()
    with f:
        root.build(f)



def main():
    read_tree(sys.argv[1])



if __name__ == '__main__':
    main()