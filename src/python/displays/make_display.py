##!/usr/bin/env python
from __future__ import with_statement

import cPickle
import math
import os
import string
import sys

import numpy
from PIL import Image


def project(vec, T):
    return numpy.dot(vec,T)
    #return vec[:,:2]


def _(filename,code, local_scope):
    if os.path.isfile(filename):
        f = open(filename,"rb")
        result = cPickle.load(f)
    else:
        result = eval(code,globals(),local_scope)
        f = open(filename,"wb")
        cPickle.dump(result,f,-1)
        
    return result

class Node:
    
    def build(self,f):
        global full_vecs
        line = f.readline()
        (count,veclen,self.level,self.leaf) = map(int,string.split(line))
        self.vecs = numpy.empty((count,veclen),dtype=numpy.float32)
        for i in xrange(count):
            line = f.readline()
            self.vecs[i,:] = numpy.array(map(float,string.split(line)))
        
        if not self.leaf:
            self.childs = [None]*count
            for i in xrange(count):
                self.childs[i] = Node()
                self.childs[i].build(f)

    def get_scale(self,T,scale=None):
        vecs =  project(self.vecs, T)
        if scale == None:
             scale = [min(vecs[:,0]),max(vecs[:,0]),min(vecs[:,1]),max(vecs[:,1])]
        scale[0] = min(scale[0],min(vecs[:,0]))
        scale[1] = max(scale[1],max(vecs[:,0]))
        scale[2] = min(scale[2],min(vecs[:,1]))
        scale[3] = max(scale[3],max(vecs[:,1]))
        if not self.leaf:
            for n in self.childs:
                scale = n.get_scale(T,scale)
        return scale
        

def compute_pca_projection(root):
    def count_leafs(node):
        if node.leaf:
            return node.vecs.shape[0]
        else:
            count = 0
            for n in node.childs:
                count += count_leafs(n)            
            return count
    
    def collect_vecs(node,vecs,index):
        if node.leaf:
            new_index = index+node.vecs.shape[0]
            vecs[index:new_index] = node.vecs
            return new_index
        else:
            for n in node.childs:
                index = collect_vecs(n,vecs,index)
            return index
    
    size = count_leafs(root)
    full_vecs = numpy.empty((size,128), dtype=numpy.float32)
    size = collect_vecs(root,full_vecs,0)
    print "Computing SVD... ",
    sys.stdout.flush()
    U,S,Vh = numpy.linalg.svd(full_vecs)
    print "done"
    return Vh[:2,:].T

def dist(p,v):
    return sum((p-v)**2)



    

def draw_node(node,points, T, scale, level = 0):
    vecs = project(node.vecs, T)
    vecs[:,0] = vecs[:,0]-scale[1]
    vecs[:,0] = vecs[:,0]/scale[0]
    vecs[:,1] = vecs[:,1]-scale[3]
    vecs[:,1] = vecs[:,1]/scale[2]
    
    print "Level: ", level
    print vecs

    for point in points:
        p = point[0:2]
        d1 = dist(p,vecs[0])
        d2 = dist(p,vecs[1])
        i1, i2 = 0,1
        if d2<d1:
            t = d1; d1 = d2; d2 = t
            t = i1; i1 = i2; i2 = t
            
        for i,v in zip(xrange(2,len(vecs)),vecs[2:]):
            d = dist(p,v)
            if d<d1:
                d2 = d1; d1 = d
                i2 = i1; i1 = i
            elif d<d2:
                d2 = d
                i2 = i
        #print "(%d,%d) dist = %g = %g/%g  (%d/%d) (%s/%s)"% (point[0],point[1],d1/d2,d1,d2,i1,i2,vecs[i1],vecs[i2])
        point[2] *= math.sqrt(d1/d2)
        point[3] = i1

    for i,n in enumerate(node.childs):
        if not n.leaf:
            #child_points = [ a for a in points if a[3]==i ]
            #print len(child_points)
            draw_node(n,points, T, scale, level+1)
            break


def read_tree(filename):
    print 'Reading tree...',
    sys.stdout.flush()
    f = open(filename,"r");
    root = Node()
    with f:
        root.build(f)
    print 'done'
    return root

def create_tree_image(size, root, T):
    scale = root.get_scale(T)
    xd = scale[1]-scale[0]
    yd = scale[3]-scale[2]
    scale = (xd/size[0],scale[0],yd/size[1],scale[2])
    points = [[float(i),float(j),1.0, 0] for i in xrange(size[0]) for j in xrange(size[1])]
    print "Computing display"
    draw_node(root,points, T, scale)
    image = Image.new("L",size)
    for p in points:
        i = int(p[0])
        j = int(p[1])
        image.putpixel((i,j), 255*(1-p[2]))
    print "Saving image"
    image.save("display.png")

def usage():
    print "Usage: %s tree_file"%sys.argv[0]

def main():
    if len(sys.argv) != 2:
       usage()
       sys.exit(1)
    treefile = sys.argv[1]
    root = _(treefile+".pickle",'read_tree(sys.argv[1])',locals())
    T = _(treefile+"_pca.pickle",'compute_pca_projection(root)',locals())
    
    size = (512,512)
    image = create_tree_image(size, root,T)

if __name__ == '__main__':
    main()
