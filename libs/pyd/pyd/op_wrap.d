/*
Copyright 2006, 2007 Kirk McDonald

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
module pyd.op_wrap;

import python;

import pyd.class_wrap;
import pyd.dg_convert;
import pyd.func_wrap;
import pyd.exception;
import pyd.make_object;
import pyd.lib_abstract :
    prettytypeof,
    symbolnameof,
    ParameterTypeTuple,
    ReturnType
;

//import meta.Nameof;
//import std.traits;

version(Python_2_5_Or_Later) {
    alias Py_ssize_t index_t;
    alias lenfunc lenfunc_t;
    alias ssizeargfunc idxargfunc;
    alias ssizessizeargfunc idxidxargfunc;
    alias ssizeobjargproc idxobjargproc;
    alias ssizessizeobjargproc idxidxobjargproc;
} else {
    alias int index_t;
    alias inquiry lenfunc_t;
    alias intargfunc idxargfunc;
    alias intintargfunc idxidxargfunc;
    alias intobjargproc idxobjargproc;
    alias intintobjargproc idxidxobjargproc;
}

template wrapped_class_as_number(T) {
    static PyNumberMethods wrapped_class_as_number = {
        opAdd_wrap!(T),       /*nb_add*/
        opSub_wrap!(T),       /*nb_subtract*/
        opMul_wrap!(T),       /*nb_multiply*/
        opDiv_wrap!(T),       /*nb_divide*/
        opMod_wrap!(T),       /*nb_remainder*/
        null,                 /*nb_divmod*/
        null,                 /*nb_power*/
        opNeg_wrap!(T),       /*nb_negative*/
        opPos_wrap!(T),       /*nb_positive*/
        null,                 /*nb_absolute*/
        null,                 /*nb_nonzero*/
        opCom_wrap!(T),       /*nb_invert*/
        opShl_wrap!(T),       /*nb_lshift*/
        opShr_wrap!(T),       /*nb_rshift*/
        opAnd_wrap!(T),       /*nb_and*/
        opXor_wrap!(T),       /*nb_xor*/
        opOr_wrap!(T),        /*nb_or*/
        null,                 /*nb_coerce*/
        null,                 /*nb_int*/
        null,                 /*nb_long*/
        null,                 /*nb_float*/
        null,                 /*nb_oct*/
        null,                 /*nb_hex*/
        opAddAssign_wrap!(T), /*nb_inplace_add*/
        opSubAssign_wrap!(T), /*nb_inplace_subtract*/
        opMulAssign_wrap!(T), /*nb_inplace_multiply*/
        opDivAssign_wrap!(T), /*nb_inplace_divide*/
        opModAssign_wrap!(T), /*nb_inplace_remainder*/
        null,                 /*nb_inplace_power*/
        opShlAssign_wrap!(T), /*nb_inplace_lshift*/
        opShrAssign_wrap!(T), /*nb_inplace_rshift*/
        opAndAssign_wrap!(T), /*nb_inplace_and*/
        opXorAssign_wrap!(T), /*nb_inplace_xor*/
        opOrAssign_wrap!(T),  /*nb_inplace_or*/
        null,                 /* nb_floor_divide */
        null,                 /* nb_true_divide */
        null,                 /* nb_inplace_floor_divide */
        null,                 /* nb_inplace_true_divide */
    };
}

template wrapped_class_as_sequence(T) {
    static PySequenceMethods wrapped_class_as_sequence = {
        length_wrap!(T),                 /*sq_length*/
        opCat_wrap!(T),                  /*sq_concat*/
        null,                            /*sq_repeat*/
        opIndex_sequence_wrap!(T),       /*sq_item*/
        opSlice_wrap!(T),                /*sq_slice*/
        opIndexAssign_sequence_wrap!(T), /*sq_ass_item*/
        opSliceAssign_wrap!(T),          /*sq_ass_slice*/
        opIn_wrap!(T),                   /*sq_contains*/
        opCatAssign_wrap!(T),            /*sq_inplace_concat*/
        null,                            /*sq_inplace_repeat*/
    };
}

template wrapped_class_as_mapping(T) {
    static PyMappingMethods wrapped_class_as_mapping = {
        null,                           /*mp_length*/
        opIndex_mapping_wrap!(T),       /*mp_subscript*/
        opIndexAssign_mapping_wrap!(T), /*mp_ass_subscript*/
    };
}

//----------------//
// Implementation //
//----------------//
template opfunc_binary_wrap(T, alias opfn) {
    alias wrapped_class_object!(T) wrap_object;
    alias ParameterTypeTuple!(opfn) Info;
    alias ReturnType!(opfn) Ret;
    alias dg_wrapper!(T, typeof(&opfn)) get_dg;
    extern(C)
    PyObject* func(PyObject* self, PyObject* o) {
        return exception_catcher(delegate PyObject*() {
            auto dg = get_dg((cast(wrap_object*)self).d_obj, &opfn);
            pragma(msg, prettytypeof!(typeof(dg)));
            pragma(msg, symbolnameof!(opfn));
            static if (is(Ret == void)) {
                dg(d_type!(Info[0])(o));
                Py_INCREF(Py_None);
                return Py_None;
            } else {
                return _py(
                    dg(
                        d_type!(Info[0])(o)
                    )
                );
            }
        });
    }
}

template opfunc_unary_wrap(T, alias opfn) {
    extern(C)
    PyObject* func(PyObject* self) {
        // method_wrap takes care of exception handling
        return method_wrap!(T, opfn, typeof(&opfn)).func(self, null);
    }
}

template opindex_sequence_pyfunc(T) {
    alias wrapped_class_object!(T) wrap_object;
    
    extern(C)
    PyObject* func(PyObject* self, index_t i) {
        return exception_catcher(delegate PyObject*() {
            return _py((cast(wrap_object*)self).d_obj.opIndex(i));
        });
    }
}

template opindexassign_sequence_pyfunc(T) {
    alias wrapped_class_object!(T) wrap_object;
    alias ParameterTypeTuple!(T.opIndexAssign) Info;
    alias Info[0] AssignT;

    extern(C)
    int func(PyObject* self, index_t i, PyObject* o) {
        return exception_catcher(delegate int() {
            (cast(wrap_object*)self).d_obj.opIndexAssign(d_type!(AssignT)(o), i);
            return 0;
        });
    }
}

template opindex_mapping_pyfunc(T) {
    alias wrapped_class_object!(T) wrap_object;
    alias ParameterTypeTuple!(T.opIndex) Info;
    const uint ARGS = Info.length;

    // Multiple arguments are converted into tuples, and thus become a standard
    // wrapped member function call. A single argument is passed directly.
    static if (ARGS == 1) {
        alias Info[0] KeyT;
        extern(C)
        PyObject* func(PyObject* self, PyObject* key) {
            return exception_catcher(delegate PyObject*() {
                return _py((cast(wrap_object*)self).d_obj.opIndex(d_type!(KeyT)(key)));
            });
        }
    } else {
        alias method_wrap!(T, T.opIndex, typeof(&T.opIndex)) opindex_methodT;
        extern(C)
        PyObject* func(PyObject* self, PyObject* key) {
            int args;
            if (!PyTuple_CheckExact(key)) {
                args = 1;
            } else {
                args = PySequence_Length(key);
            }
            if (ARGS != args) {
                setWrongArgsError(args, ARGS, ARGS);
                return null;
            }
            return opindex_methodT.func(self, key);
        }
    }
}

template opindexassign_mapping_pyfunc(T) {
    alias wrapped_class_object!(T) wrap_object;
    alias ParameterTypeTuple!(T.opIndexAssign) Info;
    const uint ARGS = Info.length;

    static if (ARGS > 2) {
        extern(C)
        int func(PyObject* self, PyObject* key, PyObject* val) {
            int args;
            if (!PyTuple_CheckExact(key)) {
                args = 2;
            } else {
                args = PySequence_Length(key) + 1;
            }
            if (ARGS != args) {
                setWrongArgsError(args, ARGS, ARGS);
                return -1;
            }
            // Build a new tuple with the value at the front.
            PyObject* temp = PyTuple_New(ARGS);
            if (temp is null) return -1;
            scope(exit) Py_DECREF(temp);
            PyTuple_SetItem(temp, 0, val);
            for (int i=1; i<ARGS; ++i) {
                Py_INCREF(PyTuple_GetItem(key, i-1));
                PyTuple_SetItem(temp, i, PyTuple_GetItem(key, i-1));
            }
            method_wrap!(T, T.opIndexAssign, typeof(&T.opIndexAssign)).func(self, temp);
            return 0;
        }
    } else {
        alias Info[0] ValT;
        alias Info[1] KeyT;

        extern(C)
        int func(PyObject* self, PyObject* key, PyObject* val) {
            return exception_catcher(delegate int() {
                (cast(wrap_object*)self).d_obj.opIndexAssign(d_type!(ValT)(val), d_type!(KeyT)(key));
                return 0;
            });
        }
    }
}

template opslice_pyfunc(T) {
    alias wrapped_class_object!(T) wrap_object;

    extern(C)
    PyObject* func(PyObject* self, index_t i1, index_t i2) {
        return exception_catcher(delegate PyObject*() {
            return _py((cast(wrap_object*)self).d_obj.opSlice(i1, i2));
        });
    }
}

template opsliceassign_pyfunc(T) {
    alias wrapped_class_object!(T) wrap_object;
    alias ParameterTypeTuple!(T.opSliceAssign) Info;
    alias Info[0] AssignT;

    extern(C)
    int func(PyObject* self, index_t i1, index_t i2, PyObject* o) {
        return exception_catcher(delegate int() {
            (cast(wrap_object*)self).d_obj.opSliceAssign(d_type!(AssignT)(o), i1, i2);
            return 0;
        });
    }
}

template opin_wrap(T) {
    alias wrapped_class_object!(T) wrap_object;
    alias ParameterTypeTuple!(T.opIn_r) Info;
    alias Info[0] OtherT;
    
    extern(C)
    int func(PyObject* self, PyObject* val) {
        return exception_catcher(delegate int() {
            if ((cast(wrap_object*)self).d_obj.opIn_r(d_type!(OtherT)(val)))
                return 1;
            else
                return 0;
        });
    }
}

template opcmp_wrap(T) {
    alias wrapped_class_object!(T) wrap_object;
    alias ParameterTypeTuple!(T.opCmp) Info;
    alias Info[0] OtherT;
    extern(C)
    int func(PyObject* self, PyObject* other) {
        return exception_catcher(delegate int() {
            int result = (cast(wrap_object*)self).d_obj.opCmp(d_type!(OtherT)(other));
            // The Python API reference specifies that tp_compare must return
            // -1, 0, or 1. The D spec says opCmp may return any integer value,
            // and just compares it with zero.
            if (result < 0) return -1;
            if (result == 0) return 0;
            if (result > 0) return 1;
        });
    }
}

template length_pyfunc(T) {
    alias wrapped_class_object!(T) wrap_object;

    extern(C)
    index_t func(PyObject* self) {
        return exception_catcher(delegate int() {
            return (cast(wrap_object*)self).d_obj.length();
        });
    }
}

//----------//
// Dispatch //
//----------//
template length_wrap(T) {
    static if (
        is(typeof(&T.length)) &&
        is(typeof(T.length()) : index_t)
    ) {
        const lenfunc_t length_wrap = &length_pyfunc!(T).func;
    } else {
        const lenfunc_t length_wrap = null;
    }
}

template opIndex_sequence_wrap(T) {
    static if (
        is(typeof(&T.opIndex)) &&
        ParameterTypeTuple!(T.opIndex).length == 1 &&
        is(ParameterTypeTuple!(T.opIndex)[0] : index_t)
    ) {
        const idxargfunc opIndex_sequence_wrap = &opindex_sequence_pyfunc!(T).func;
    } else {
        const idxargfunc opIndex_sequence_wrap = null;
    }
}

template opIndexAssign_sequence_wrap(T) {
    static if (
        is(typeof(&T.opIndexAssign)) &&
        ParameterTypeTuple!(T.opIndexAssign).length == 2 &&
        is(ParameterTypeTuple!(T.opIndexAssign)[1] : index_t)
    ) {
        const idxobjargproc opIndexAssign_sequence_wrap = &opindexassign_sequence_pyfunc!(T).func;
    } else {
        const idxobjargproc opIndexAssign_sequence_wrap = null;
    }
}

template opIndex_mapping_wrap(T) {
    static if (
        is(typeof(&T.opIndex)) &&
        (ParameterTypeTuple!(T.opIndex).length > 1 ||
        !is(ParameterTypeTuple!(T.opIndex)[0] : index_t))
    ) {
        const binaryfunc opIndex_mapping_wrap = &opindex_mapping_pyfunc!(T).func;
    } else {
        const binaryfunc opIndex_mapping_wrap = null;
    }
}

template opIndexAssign_mapping_wrap(T) {
    static if (
        is(typeof(&T.opIndexAssign)) &&
        (ParameterTypeTuple!(T.opIndex).length > 2 ||
        !is(ParameterTypeTuple!(T.opIndex)[1] : index_t))
    ) {
        const objobjargproc opIndexAssign_mapping_wrap = &opindexassign_mapping_pyfunc!(T).func;
    } else {
        const objobjargproc opIndexAssign_mapping_wrap = null;
    }
}

template opSlice_wrap(T) {
    static if (
        is(typeof(&T.opSlice)) &&
        ParameterTypeTuple!(T.opSlice).length == 2 &&
        is(ParameterTypeTuple!(T.opSlice)[0] : index_t) &&
        is(ParameterTypeTuple!(T.opSlice)[1] : index_t)
    ) {
        const idxidxargfunc opSlice_wrap = &opslice_pyfunc!(T).func;
    } else {
        const idxidxargfunc opSlice_wrap = null;
    }
}

template opSliceAssign_wrap(T) {
    static if (
        is(typeof(&T.opSlice)) &&
        ParameterTypeTuple!(T.opSlice).length == 3 &&
        is(ParameterTypeTuple!(T.opSlice)[1] : index_t) &&
        is(ParameterTypeTuple!(T.opSlice)[2] : index_t)
    ) {
        const idxidxobjargproc opSliceAssign_wrap = &opsliceassign_pyfunc!(T).func;
    } else {
        const idxidxobjargproc opSliceAssign_wrap = null;
    }
}

template opAdd_wrap(T) {
    static if (is(typeof(&T.opAdd))) {
        const binaryfunc opAdd_wrap = &opfunc_binary_wrap!(T, T.opAdd).func;
    } else {
        const binaryfunc opAdd_wrap = null;
    }
}

template opSub_wrap(T) {
    static if (is(typeof(&T.opSub))) {
        const binaryfunc opSub_wrap = &opfunc_binary_wrap!(T, T.opSub).func;
    } else {
        const binaryfunc opSub_wrap = null;
    }
}


template opMul_wrap(T) {
    static if (is(typeof(&T.opMul))) {
        const binaryfunc opMul_wrap = &opfunc_binary_wrap!(T, T.opMul).func;
    } else {
        const binaryfunc opMul_wrap = null;
    }
}


template opDiv_wrap(T) {
    static if (is(typeof(&T.opDiv))) {
        const binaryfunc opDiv_wrap = &opfunc_binary_wrap!(T, T.opDiv).func;
    } else {
        const binaryfunc opDiv_wrap = null;
    }
}


template opMod_wrap(T) {
    static if (is(typeof(&T.opMod))) {
        const binaryfunc opMod_wrap = &opfunc_binary_wrap!(T, T.opMod).func;
    } else {
        const binaryfunc opMod_wrap = null;
    }
}


template opAnd_wrap(T) {
    static if (is(typeof(&T.opAnd))) {
        const binaryfunc opAnd_wrap = &opfunc_binary_wrap!(T, T.opAnd).func;
    } else {
        const binaryfunc opAnd_wrap = null;
    }
}


template opOr_wrap(T) {
    static if (is(typeof(&T.opOr))) {
        const binaryfunc opOr_wrap = &opfunc_binary_wrap!(T, T.opOr).func;
    } else {
        const binaryfunc opOr_wrap = null;
    }
}


template opXor_wrap(T) {
    static if (is(typeof(&T.opXor))) {
        const binaryfunc opXor_wrap = &opfunc_binary_wrap!(T, T.opXor).func;
    } else {
        const binaryfunc opXor_wrap = null;
    }
}


template opShl_wrap(T) {
    static if (is(typeof(&T.opShl))) {
        const binaryfunc opShl_wrap = &opfunc_binary_wrap!(T, T.opShl).func;
    } else {
        const binaryfunc opShl_wrap = null;
    }
}


template opShr_wrap(T) {
    static if (is(typeof(&T.opShr))) {
        const binaryfunc opShr_wrap = &opfunc_binary_wrap!(T, T.opShr).func;
    } else {
        const binaryfunc opShr_wrap = null;
    }
}


template opUShr_wrap(T) {
    static if (is(typeof(&T.opUShr))) {
        const binaryfunc opUShr_wrap = &opfunc_binary_wrap!(T, T.opUShr).func;
    } else {
        const binaryfunc opUShr_wrap = null;
    }
}


template opCat_wrap(T) {
    static if (is(typeof(&T.opCat))) {
        const binaryfunc opCat_wrap = &opfunc_binary_wrap!(T, T.opCat).func;
    } else {
        const binaryfunc opCat_wrap = null;
    }
}


template opAddAssign_wrap(T) {
    static if (is(typeof(&T.opAddAssign))) {
        const binaryfunc opAddAssign_wrap = &opfunc_binary_wrap!(T, T.opAddAssign).func;
    } else {
        const binaryfunc opAddAssign_wrap = null;
    }
}


template opSubAssign_wrap(T) {
    static if (is(typeof(&T.opSubAssign))) {
        const binaryfunc opSubAssign_wrap = &opfunc_binary_wrap!(T, T.opSubAssign).func;
    } else {
        const binaryfunc opSubAssign_wrap = null;
    }
}


template opMulAssign_wrap(T) {
    static if (is(typeof(&T.opMulAssign))) {
        const binaryfunc opMulAssign_wrap = &opfunc_binary_wrap!(T, T.opMulAssign).func;
    } else {
        const binaryfunc opMulAssign_wrap = null;
    }
}


template opDivAssign_wrap(T) {
    static if (is(typeof(&T.opDivAssign))) {
        const binaryfunc opDivAssign_wrap = &opfunc_binary_wrap!(T, T.opDivAssign).func;
    } else {
        const binaryfunc opDivAssign_wrap = null;
    }
}


template opModAssign_wrap(T) {
    static if (is(typeof(&T.opModAssign))) {
        const binaryfunc opModAssign_wrap = &opfunc_binary_wrap!(T, T.opModAssign).func;
    } else {
        const binaryfunc opModAssign_wrap = null;
    }
}


template opAndAssign_wrap(T) {
    static if (is(typeof(&T.opAndAssign))) {
        const binaryfunc opAndAssign_wrap = &opfunc_binary_wrap!(T, T.opAndAssign).func;
    } else {
        const binaryfunc opAndAssign_wrap = null;
    }
}


template opOrAssign_wrap(T) {
    static if (is(typeof(&T.opOrAssign))) {
        const binaryfunc opOrAssign_wrap = &opfunc_binary_wrap!(T, T.opOrAssign).func;
    } else {
        const binaryfunc opOrAssign_wrap = null;
    }
}


template opXorAssign_wrap(T) {
    static if (is(typeof(&T.opXorAssign))) {
        const binaryfunc opXorAssign_wrap = &opfunc_binary_wrap!(T, T.opXorAssign).func;
    } else {
        const binaryfunc opXorAssign_wrap = null;
    }
}


template opShlAssign_wrap(T) {
    static if (is(typeof(&T.opShlAssign))) {
        const binaryfunc opShlAssign_wrap = &opfunc_binary_wrap!(T, T.opShlAssign).func;
    } else {
        const binaryfunc opShlAssign_wrap = null;
    }
}


template opShrAssign_wrap(T) {
    static if (is(typeof(&T.opShrAssign))) {
        const binaryfunc opShrAssign_wrap = &opfunc_binary_wrap!(T, T.opShrAssign).func;
    } else {
        const binaryfunc opShrAssign_wrap = null;
    }
}


template opUShrAssign_wrap(T) {
    static if (is(typeof(&T.opUShrAssign))) {
        const binaryfunc opUShrAssign_wrap = &opfunc_binary_wrap!(T, T.opUShrAssign).func;
    } else {
        const binaryfunc opUShrAssign_wrap = null;
    }
}


template opCatAssign_wrap(T) {
    static if (is(typeof(&T.opCatAssign))) {
        const binaryfunc opCatAssign_wrap = &opfunc_binary_wrap!(T, T.opCatAssign).func;
    } else {
        const binaryfunc opCatAssign_wrap = null;
    }
}


template opIn_wrap(T) {
    static if (is(typeof(&T.opIn_r))) {
        const objobjproc opIn_wrap = &opin_wrap.func;
    } else {
        const objobjproc opIn_wrap = null;
    }
}

template opNeg_wrap(T) {
    static if (is(typeof(&T.opNeg))) {
        const unaryfunc opNeg_wrap = &opfunc_unary_wrap!(T, T.opNeg).func;
    } else {
        const unaryfunc opNeg_wrap = null;
    }
}

template opPos_wrap(T) {
    static if (is(typeof(&T.opPos))) {
        const unaryfunc opPos_wrap = &opfunc_unary_wrap!(T, T.opPos).func;
    } else {
        const unaryfunc opPos_wrap = null;
    }
}

template opCom_wrap(T) {
    static if (is(typeof(&T.opCom))) {
        const unaryfunc opCom_wrap = &opfunc_unary_wrap!(T, T.opCom).func;
    } else {
        const unaryfunc opCom_wrap = null;
    }
}

