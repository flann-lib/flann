"""
This module only defines the parameters used in the binding and what
their global defaults are.  Note that the type must be correct, as the
type is used to create the c binding code.
"""

from pyfann_exceptions import *

param_args = [('algorithm', "default"),
              ('checks', 32),
              ('trees',  1),
              ('branching', 32),
              ('iterations', 5),
              ('target_precision', -1.),
              ('centers_algorithm', "random"),
              ('speedup', -1)]

########################################
# dictionaries for the string parameters

algorithm_dict = {"linear"    : 0,
                  "kdtree"    : 1,
                  "kmeans"    : 2,
                  "composite" : 3,
                  "default"   : 1}

centers_init_dict = {"random" : 0,
                     "gonzales" : 1,
                     "default" : 0}


def get_param_args():
    return param_args

def get_param_compile_args():
    return [(k, process_param_dict({k:v})[k]) 
            for k,v in param_args]

def get_param_struct_name_list():
    return [k for k,v in get_param_args()]

def __make_type_translation_table():
    def TypeKey(v):
        if   type(v) == int:     return 'i'
        elif type(v) == float:   return 'f'
        

    return dict(filter(lambda (k,t): t != str, 
                       [(k, TypeKey(v)) for k, v in get_param_args()]))

########################################
# Centers algorithm.

def algorithm_names():
    return algorithm_dict().values()

def centers_init_names():
    return centers_init_dict().values()

########################################

type_translation_table = __make_type_translation_table()

##################################################

def process_param_dict(argdict):
    
    def string2value_replace(name, default, d_func):
        # Replace algorithm
        try:
            val = argdict[name]
        except KeyError:
            return

        if type(val) == str:
            try: 
                argdict[name] = d_func[val.lower()]
            except KeyError:
                raise FANNException("\'%s\' not a valid value for \'%s\'\n" % (val, name) 
                                    + "Possible values are " + ', '.join(sorted(d_func.keys())))
            

    string2value_replace("algorithm", "default", algorithm_dict)
    string2value_replace("centers_algorithm", "default", centers_init_dict)

    def ensureCorrectType(k, v):
        try:
            t = type_translation_table[k]
        except KeyError:
            return v
        
        if t == 'f': return float(v)
        if t == 'i': return int(v)
        return v

    for k, t in type_translation_table.iteritems():
        try:
            argdict[k] = ensureCorrectType(k, (argdict[k]))
        except KeyError:
            pass
    
    return argdict
