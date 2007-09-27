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
module pyd.make_wrapper;

import python;

import pyd.class_wrap;
import pyd.dg_convert;
import pyd.exception;
import pyd.func_wrap;
import pyd.lib_abstract :
    ReturnType,
    ParameterTypeTuple,
    ToString
;

template T(A ...) {
    alias A T;
}
template opFuncs() {
    alias T!("opNeg", "opPos", "opCom", "opAdd", "opSub", "opMul", "opDiv", "opMod", "opAnd", "opOr", "opXor", "opShl", "opShr", "opCat", "opAddAssign", "opSubAssign", "opMulAssign", "opDivAssign", "opModAssign", "opAndAssign", "opOrAssign", "opXorAssign", "opShlAssign", "opShrAssign", "opCatAssign", "opIn_r", "opCmp", "opCall", "opApply", "opIndex", "opIndexAssign", "opSlice", "opSliceAssign", "length") opFuncs;
}

template funcTypes() {
    alias T!("UNI", "UNI", "UNI", "BIN", "BIN", "BIN", "BIN", "BIN", "BIN", "BIN", "BIN", "BIN", "BIN", "BIN", "BIN", "BIN", "BIN", "BIN", "BIN", "BIN", "BIN", "BIN", "BIN", "BIN", "BIN", "UNSUPPORTED", "CMP", "CALL", "APPLY", "INDEX", "INDEXASS", "SLICE", "SLICEASS", "LEN") funcTypes;
}
template pyOpFuncs() {
    alias T!("__neg__", "__pos__", "__invert__", "__add__", "__sub__", "__mul__", "__div__", "__mod__", "__and__", "__or__", "__xor__", "__lshift__", "__rshift__", "__add__", "__iadd__", "__isub__", "__imul__", "__idiv__", "__imod__", "__iand__", "__ior__", "__ixor__", "__ilshift__", "__irshift__", "__iadd__", "UNSUPPORTED", "__cmp__", "__call__", "__iter__", "__getitem__", "__setitem__", "UNSUPPORTED", "UNSUPPORTED", "__len__") pyOpFuncs;
}

template opFunc(uint i) {
    const char[] opFunc = opFuncs!()[i];
}

template funcType(uint i) {
    const char[] funcType = funcTypes!()[i];
}

template pyOpFunc(uint i) {
    const char[] pyOpFunc = pyOpFuncs!()[i];
}

template op_shim(uint i) {
    static if (funcType!(i) == "UNI" || funcType!(i) == "BIN" || funcType!(i) == "CMP" || funcType!("CALL")) {
        const char[] op_shim =
            "    ReturnType!(T."~opFunc!(i)~") "~opFunc!(i)~"(ParameterTypeTuple!(T."~opFunc!(i)~") t) {\n"
            "        return __pyd_get_overload!(\""~opFunc!(i)~"\", typeof(&T."~opFunc!(i)~")).func(\""~pyOpFunc!(i)~"\", t);\n"
            "    }\n";
    } else static if (funcType!(i) == "APPLY") {
        const char[] op_shim =
            "    int opApply(ParameterTypeTuple!(T.opApply)[0] dg) {\n"
            "        return __pyd_apply_wrapper(dg);\n"
            "    }\n";
    } else static assert(false, "Unsupported operator overload " ~ opFunc!(i));
}

template op_shims(uint i, T) {
    static if (i < opFuncs!().length) {
        static if (is(typeof(mixin("&T."~opFunc!(i)))) && opFunc!(i) != "UNSUPPORTED") {
            const char[] op_shims = op_shim!(i) ~ op_shims!(i+1, T);
        } else {
            const char[] op_shims = op_shims(i+1, T);
        }
    } else {
        const char[] op_shims = "";
    }
}

template OverloadShim() {
    // If this is actually an instance of a Python subclass, return the
    // PyObject associated with the object. Otherwise, return null.
    PyObject* __pyd_get_pyobj() {
        PyObject** _pyobj = cast(void*)this in wrapped_gc_objects;
        PyTypeObject** _pytype = this.classinfo in wrapped_classes;
        if (_pyobj is null || _pytype is null || (*_pyobj).ob_type != *_pytype) {
            return *_pyobj;
        } else {
            return null;
        }
    }
    template __pyd_abstract_call(fn_t) {
        ReturnType!(fn_t) func(T ...) (char[] name, T t) {
            PyObject* _pyobj = this.__pyd_get_pyobj();
            if (_pyobj !is null) {
                PyObject* method = PyObject_GetAttrString(_pyobj, (name ~ \0).ptr);
                if (method is null) handle_exception();
                auto pydg = PydCallable_AsDelegate!(fn_to_dg!(fn_t))(method);
                Py_DECREF(method);
                return pydg(t);
            } else {
                PyErr_SetNone(PyExc_NotImplementedError);
                handle_exception();
                //return ReturnType!(fn_t).init;
            }
        }
    }
    template __pyd_get_overload(string realname, fn_t) {
        ReturnType!(fn_t) func(T ...) (string name, T t) {
            PyObject* _pyobj = this.__pyd_get_pyobj();
            if (_pyobj !is null) {
                // If this object's type is not the wrapped class's type (that is,
                // if this object is actually a Python subclass of the wrapped
                // class), then call the Python object.
                PyObject* method = PyObject_GetAttrString(_pyobj, (name ~ \0).ptr);
                if (method is null) handle_exception();
                auto pydg = PydCallable_AsDelegate!(fn_to_dg!(fn_t))(method);
                Py_DECREF(method);
                return pydg(t);
            } else {
                mixin("return super."~realname~"(t);");
            }
        }
    }
    int __pyd_apply_wrapper(dg_t) (dg_t dg) {
        alias ParameterTypeTuple!(dg_t)[0] arg_t;
        const uint args = ParameterTypeTuple!(dg_t).length;
        PyObject* _pyobj = this.__pyd_get_pyobj();
        if (_pyobj !is null) {
            PyObject* iter = PyObject_GetIter(_pyobj);
            if (iter is null) handle_exception();
            PyObject* item;
            int result = 0;

            item = PyIter_Next(iter);
            while (item) {
                static if (args == 1 && is(arg_t == PyObject*)) {
                    result = dg(item);
                } else {
                    if (PyTuple_Check(item)) {
                        result = applyPyTupleToDelegate(dg, item);
                    } else {
                        static if (args == 1) {
                            arg_t t = d_type!(typeof(arg_t))(item);
                            result = dg(t);
                        } else {
                            throw new Exception("Tried to override opApply with wrong number of args...");
                        }
                    }
                }
                Py_DECREF(item);
                if (result) break;
                item = PyIter_Next(iter);
            }
            Py_DECREF(iter);
            handle_exception();
            return result;
        } else {
            return super.opApply(dg);
        }
    }
}

template class_decls(uint i, Params...) {
    static if (i < Params.length) {
        const char[] class_decls = Params[i].shim!(i) ~ class_decls!(i+1, Params);
    } else {
        const char[] class_decls = "";
    }
}

template make_wrapper(T, Params...) {
    const char[] cls = 
    "class wrapper : T {\n"~
    "    mixin OverloadShim;\n"~
    pyd.make_wrapper.class_decls!(0, Params)~"\n"~
//    op_shims!(0, T)~
    "}\n";
    pragma(msg, cls);
    mixin(cls);
}

