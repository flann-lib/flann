#!/usr/bin/env python

from create_python_base import createPythonBase
import os

def configuration(parent_package='',top_path=None):
    from numpy.distutils.misc_util import Configuration
    config = Configuration('pyflann', parent_package, top_path)

    config.add_data_files('flann_python_base.so')
    config.add_data_dir('tests')
    return config

if __name__ == '__main__':
    from numpy.distutils.core import setup

    createPythonBase()

    setup(**configuration(top_path='').todict())

    def try_remove(f):
        try:
            os.remove(f)
        except OSError:
            pass
    
    # Clean up
    try_remove('flann_python_base.cpp')
    try_remove('flann_python_base.so')
        


