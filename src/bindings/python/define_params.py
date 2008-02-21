"""
This module only defines the parameters used in the binding and what
their global defaults are.  Note that the type must be correct, as the
type is used to create the c binding code.
"""

def get_algorithm_enum_dict():
    return {"linear"    : 0,
            "kdtree"    : 1,
            "kmeans"    : 2,
            "composite" : 3,
            "default"   : 1}


def get_param_args():
    return [('algorithm', 1),
            ('checks', 32),
            ('trees',  1),
            ('branching', 32),
            ('iterations', 5),
            ('target_precision', -1.)]

def get_algorithms():
    return [k for k,v in get_algorithm_enum_dict().iteritems()]


def get_param_struct_name_list():
    """
    This defines the list of parameters (other than algo) stored in
    the params struct.
    """

    return ['algorithm', 'checks', 'trees', 'branching', 
            'iterations', 'target_precision']

