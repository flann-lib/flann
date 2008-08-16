cdef extern from "flann.h":
    cdef struct KMeansNodeSt
    ctypedef KMeansNodeSt* KMeansNode

    cdef struct _pivot:
        int length
        float* ptr
    cdef struct _childs:
        int length
        KMeansNodeSt** ptr
    cdef struct _indices:
        int length
        int* ptr
    cdef struct KMeansNodeSt:
        _pivot pivot
        float radius
        float mean_radius
        float variance
        int size
        _childs childs
        _indices indices
        int level


    ctypedef int FLANN_INDEX

    KMeansNode get_kmeans_hierarchical_tree(FLANN_INDEX index_id)
