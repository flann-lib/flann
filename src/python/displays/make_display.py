##!/usr/bin/env python
from __future__ import with_statement

import cPickle
import math
import os
import string
import sys

import numpy
from PIL import Image
import scipy.weave


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
    U,S,Vh = numpy.linalg.svd(full_vecs[:1000])
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
    
    print "Level: %d\r"%level

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
        r = 7
        point[3+level] = math.exp(r*math.sqrt(d1/d2))/math.exp(r)
        
        #if point[2]>0:
            #point[2] = (9*point[2]+val)/10
        #else:
            #point[2] = val
        point[2] = i1

    global levels
    if level<levels-1:
        child_points = [None]*len(node.childs)
        for i,n in enumerate(node.childs):
            if not n.leaf:
                child_points[i] = [ a for a in points if a[2]==i ]

        for i,n in enumerate(node.childs):
            if not n.leaf:
                draw_node(n,child_points[i],T, scale, level+1)



def read_tree(filename):
    print 'Reading tree...',
    sys.stdout.flush()
    f = open(filename,"r");
    root = Node()
    with f:
        root.build(f)
    print 'done'
    return root

def create_tree_image(treefile, size, root, T):
    scale = root.get_scale(T)
    xd = scale[1]-scale[0]
    yd = scale[3]-scale[2]
    scale = (xd/size[0],scale[0],yd/size[1],scale[2])
    points = [[float(i),float(j),0] + [-1]*17  for i in xrange(size[0]) for j in xrange(size[1])]
    print "Computing display"
    draw_node(root,points, T, scale)
    image = Image.new("RGBA",size)
    global levels
    for level in xrange(levels):
        val = [ 0, 0, 0, 0 ]
        for p in points:
            i = int(p[0])
            j = int(p[1])
            val[3] = int(255*(p[3+level]))
            image.putpixel((i,j), tuple(val) )
        print "Saving image"
        image.save("display_"+treefile+"_level_%d.png"%level)

def usage():
    print "Usage: %s tree_file"%sys.argv[0]

def main():
    if len(sys.argv) != 2:
       usage()
       sys.exit(1)
    treefile = sys.argv[1]
    root = _(treefile+".pickle",'read_tree(sys.argv[1])',locals())
    T = _(treefile+"_pca.pickle",'compute_pca_projection(root)',locals())
    
    global levels
    levels = int(math.log(100000)/math.log(len(root.vecs))+0.5)
    levels = min(levels,13)
    #levels = 2
    print "Branching factor: %d, doing %d levels."%(len(root.vecs),levels)
    size = (512,512)
    image = create_tree_image(treefile, size, root,T)

if __name__ == '__main__':
    main()
