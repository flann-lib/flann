from util.weave_tools import *

from scipy.weave import inline

from struct import *
from numpy import *


module = CModule()

module.include("<stdio.h>")


class Foo:
    name = "test_foo_class"
    int_value = 10
    float_value = 12.3


module.add_support_code (r'''
struct TestStruct 
{
    int int_value;
    float float_value;
    char msg[10];
};
''')


@module
def test_method(str_arg = ""):
    r'''
    TestStruct* s = py_to_struct<TestStruct>(py_str_arg);
    
    printf("Testing struct: int_value=%d, float_value=%g, msg=%s\n", s->int_value, s->float_value, s->msg);
    s->int_value = 323;
    s->float_value = 89.7;
    strcpy(s->msg,"MoreTest");
    '''
   
   


exec module._import()







index_params = CStruct( [ ('i', ('algorithm', 'kdtree') , {"linear" : 0, "kdtree" : 1, "kmeans" : 2, "composite" : 3, "default"   : 1}),
                ('i', ('checks', 32), None),
                ('i', ('trees',  1), None),
                ('i', ('branching', 32), None),
                ('i', ('iterations', 5), None),
                ('i', ('target_precision', -1.), None),
                ('i', ('centers_init', "random"), {"random" : 0, "gonzales"  : 1, "kmeanspp"  : 2, "default"   : 0}),
                ('f', ('build_weight', 0.01), None),
                ('f', ('memory_weight', 0.0), None) ] )
                
                
print index_params.pack()



s = Struct('lf10s')
val = s.pack(122.712,33.4,"Test")
test_method(val)
print s.unpack(val)
