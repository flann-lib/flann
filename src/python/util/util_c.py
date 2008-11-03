import numpy
import os
import sys

from weave_tools import *


module = CModule(__name__)
module.include('"util.h"')


@module
def compute_ground_truth_cpp(dataset = float32_2d, testset = float32_2d, match = int32_2d):
    r'''
    compute_ground_truth_float(dataset, Ndataset[0], Ndataset[1], testset,Ntestset[0], match, Nmatch[1]);
    '''




exec module._import()


