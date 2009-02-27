#!/usr/bin/env python

from distutils.core import setup

setup(name='flann',
      version='1.2',
      description='Fast Library for Approximate Nearest Neighbors',
      author='Marius Muja',
      author_email='mariusm@cs.ubc.ca',
      url='http://www.cs.ubc.ca/~mariusm/flann/',
      packages=['pyflann','pyflann.command', 'pyflann.io', 'pyflann.bindings', 'pyflann.util'],
      scripts=['flann'],
      package_data={'pyflann.bindings' : ['libflann.so','flann.dll', 'libflann.dylib']},
)
