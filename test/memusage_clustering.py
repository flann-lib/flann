#!/usr/bin/env python
import sys
from os.path import *
from pyflann import *
from guppy import hpy
from numpy.random import rand

import os, gc

_proc_status = '/proc/%d/status' % os.getpid()

_scale = {'kB': 1024.0, 'mB': 1024.0*1024.0,
          'KB': 1024.0, 'MB': 1024.0*1024.0}

def _VmB(VmKey):
    '''Private.
    '''
    global _proc_status, _scale
     # get pseudo file  /proc/<pid>/status
    try:
        t = open(_proc_status)
        v = t.read()
        t.close()
    except:
        return 0.0  # non-Linux?
     # get VmKey line e.g. 'VmRSS:  9999  kB\n ...'
    i = v.index(VmKey)
    v = v[i:].split(None, 3)  # whitespace
    if len(v) < 3:
        return 0.0  # invalid format?
     # convert Vm value to bytes
    return float(v[1]) * _scale[v[2]]


def memory(since=0.0):
    '''Return memory usage in bytes.
    '''
    return _VmB('VmSize:') - since


def resident(since=0.0):
    '''Return resident memory usage in bytes.
    '''
    return _VmB('VmRSS:') - since


def stacksize(since=0.0):
    '''Return stack size in bytes.
    '''
    return _VmB('VmStk:') - since



if __name__ == '__main__':

    print 'Profiling Memory usage for pyflann; CTRL-C to stop.'
    print 'Increasing total process memory, relative to the python memory, '
    print 'implies a memory leak in the external libs.'
    print 'Increasing python memory implies a memory leak in the python code.'
    
    h = hpy()

    while True:
        s = str(h.heap())

        print 'Python: %s;    Process Total: %s' % (s[:s.find('\n')], memory())
        
        X = rand(30000, 2)
        pf = FLANN()
        cl = pf.kmeans(X, 20)
        del X
        del cl
        del pf
        gc.collect()
        
