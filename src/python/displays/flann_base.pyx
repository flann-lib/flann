cimport flann_interface
import numpy


cdef class Node:

    cdef build(self, flann_interface.KMeansNode node):
        self.points = numpy.empty((node.childs.length,node.pivot.length),dtype=numpy.float32)



def get_hierarchical_kmeans(index):
    cdef flann_interface.KMeansNode kmeans_root = flann_interface.get_kmeans_hierarchical_tree(index)
    root = Node()
    root.build(kmeans_root)

    return root

