#!/usr/bin/env python

from distutils.core import setup
import os.path
import sys

setup_path = os.path.dirname(os.path.abspath(sys.argv[0]))
lib_path = os.path.abspath(os.path.join(setup_path,'../../../lib'))

setup(name='flann',
      version='1.6.3',
      description='Fast Library for Approximate Nearest Neighbors',
      author='Marius Muja',
      author_email='mariusm@cs.ubc.ca',
      license='BSD',
      url='http://www.cs.ubc.ca/~mariusm/flann/',
      packages=['pyflann','pyflann.command', 'pyflann.io', 'pyflann.bindings', 'pyflann.util', 'pyflann.lib'],
      scripts=['flann'],
      package_dir={'pyflann.lib':lib_path},
      package_data={'pyflann.lib': ['libflann.so','flann.dll', 'libflann.dylib']}, 
)
