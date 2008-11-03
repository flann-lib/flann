"""
This module only defines the parameters used in the binding and what
their global defaults are.  Note that the type must be correct, as the
type is used to create the c binding code.
"""


__index_param_args =[('algorithm', "default"),
                     ('checks', 32),
                     ('trees',  1),
                     ('branching', 32),
                     ('iterations', 5),
                     ('target_precision', -1.),
                     ('centers_init', "random"),
                     ('build_weight', 0.01),
                     ('memory_weight', 0.0) ]

__flann_param_args = [('log_level', 'default'),
                     ('random_seed', -1)]

__param_args = __flann_param_args + __index_param_args

########################################
# dictionaries for the string parameters

__translation_dicts = {"algorithm"     : {"linear"    : 0,
                                          "kdtree"    : 1,
                                          "kmeans"    : 2,
                                          "composite" : 3,
                                          "default"   : 1},
                       "centers_init"  : {"random"    : 0,
                                          "gonzales"  : 1,
                                          "kmeanspp"  : 2,
                                          "default"   : 0},
                       "log_level"     : {"none"      : 0,
                                          "fatal"     : 1,
                                          "error"     : 2,
                                          "warning"   : 3,
                                          "info"      : 4,
                                          "default"   : 2}}

__translatable_set = frozenset(__translation_dicts.keys())

def get_flann_param_args():
    return __flann_param_args

def get_param_args():
    return __param_args

def get_param_compile_args():
    return [(k, process_param_dict({k:v})[k]) 
            for k,v in get_param_args()]

def get_flann_param_compile_args():
    return [(k, process_param_dict({k:v})[k]) 
            for k,v in __flann_param_args]

def get_param_struct_name_list():
    return [k for k,v in __param_args]

def get_flann_param_struct_name_list():
    return [k for k,v in __flann_param_args]

def get_index_param_struct_name_list():
    return [k for k,v in __index_param_args]

########################################
# Centers algorithm.

def parameter_list():
    """
    Returns a list of all the possible parameters that can be passed
    as key word arguments to the methods in FLANN.
    """

    return sorted([n for n, v in __param_args])


def algorithm_names():
    """
    Returns a list of all the algorithm names that can be used as
    the value for the algorithm parameter.
    """

    return sorted(translation_dict["algorthm"].keys())

def centers_init_names():
    """
    Returns a list of all the algorithm names that can be used as
    the value for the centers_init parameter.
    """

    return sorted(translation_dict["centers_init"].keys())

def log_level_names():
    """
    Returns a list of all the names that can be used as the value for
    the log_level parameter.  A numerical value can also be used.
    """

    return sorted(translation_dict["log_level"].keys())

##################################################

def __translate_strings(argdict):

    for k in __translatable_set.intersection(argdict.keys()):
        val = argdict[k]
        if type(val) == str:
            try: 
                argdict[k] = __translation_dicts[k][val.lower()]
            except KeyError:
                raise FLANNException("\'%s\' not a valid value for \'%s\'\n" % (val, k) 
                                    + "Possible string values are " 
                                    + ', '.join(sorted(__translation_dict[k].keys())))


def translate_strings_back(argdict):

    for k in __translatable_set.intersection(argdict.keys()):
        val = argdict[k]
        
        for x in __translation_dicts[k]:
            if __translation_dicts[k][x] == val:
                argdict[k] = x

def __make_type_translation_table():
    def getCorrectType(k, v):
        d = {k : v}
        __translate_strings(d)
        return d[k]

    def typeFunction(v):
        if   type(v) == int:     return lambda x: int(x)
        elif type(v) == float:   return lambda x: float(x)
        else:                    return lambda x: x

    return dict([(k, typeFunction(getCorrectType(k, v))) for k, v in get_param_args()])

__type_translation_table = __make_type_translation_table()
__type_translation_set = frozenset(__type_translation_table.keys())

def __ensure_correct_types(argdict):

    def ensureCorrectType(k, v):
        try:
            t = __type_translation_table[k]
        except KeyError:
            return v
        
    for k in __type_translation_set.intersection(argdict.keys()):
        argdict[k] = __type_translation_table[k](argdict[k])
    
    return argdict

def process_param_dict(argdict):
    __translate_strings(argdict)
    __ensure_correct_types(argdict)
    return argdict
