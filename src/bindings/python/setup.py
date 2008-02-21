#!/usr/bin/env python

from create_python_base import createPythonBase

createPythonBase()

def configuration(parent_package='',top_path=None):
    from numpy.distutils.misc_util import Configuration
    config = Configuration('pyfann', parent_package, top_path)

    config.add_data_files('fann_python_base.so')
    config.add_data_dir('tests')
    return config

if __name__ == '__main__':
    from numpy.distutils.core import setup
    setup(**configuration(top_path='').todict())




