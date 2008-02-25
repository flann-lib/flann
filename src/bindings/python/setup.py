#!/usr/bin/env python

from create_python_base import createPythonBase
from create_utils_c import createUtilsC
import os

def configuration(parent_package='',top_path=None):
    from numpy.distutils.misc_util import Configuration
    config = Configuration('pyfann', parent_package, top_path)

    config.add_data_files('fann_python_base.so')
    config.add_data_files('utils_c.so')
    config.add_data_dir('tests')
    return config

if __name__ == '__main__':
    from numpy.distutils.core import setup

    createUtilsC()
    createPythonBase()

    setup(**configuration(top_path='').todict())

    def try_remove(f):
        try:
            os.remove(f)
        except OSError:
            pass
    
    # Clean up
    try_remove('utils_c.cpp')
    try_remove('utils_c.so')
    try_remove('fann_python_base.cpp')
    try_remove('fann_python_base.so')
        


