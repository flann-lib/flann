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

/**
 * This module provides the support for wrapping opApply with Python's
 * iteration interface using Mikola Lysenko's StackThreads package.
 */
module pyd.iteration;

import python;

import pyd.class_wrap;
import pyd.dg_convert;
import pyd.exception;
import pyd.make_object;

import std.traits;

import st.stackcontext;

// This exception is for yielding a PyObject* from within a StackContext.
class PydYield : Exception {
    PyObject* m_py;
    this(PyObject* py) {
        super("");
        m_py = py;
    }
    PyObject* item() { return m_py; }
}

// Creates an iterator object from an object.
PyObject* PydStackContext_FromWrapped(T, alias Iter = T.opApply, iter_t = typeof(&Iter)) (T obj) {
    // Get the number of args the opApply's delegate argument takes
    alias ParameterTypeTuple!(iter_t) IInfo;
    alias ParameterTypeTuple!(IInfo[0]) Info;
    const uint ARGS = Info.length;
    auto sc = new StackContext(delegate void() {
        T o = obj;
        fn_to_dg!(iter_t) t = dg_wrapper!(T, iter_t)(o, &Iter);
        // We yield so we can be sure to get the local variables in the
        // enclosing function's stack frame.
        StackContext.yield();

        t(delegate int(inout Info i) {
            StackContext.throwYield(new PydYield(PyTuple_FromItems(i)));
            return 0;
        });
    });
    // Initialize the StackContext
    sc.run();
    return WrapPyObject_FromObject(sc);
}

template wrapped_iter(T, alias Iter, iter_t = typeof(&Iter)) {
    alias wrapped_class_object!(T) wrap_object;

    // Returns an iterator object for this class
    extern (C)
    PyObject* iter(PyObject* _self) {
        return exception_catcher({
            wrap_object* self = cast(wrap_object*)_self;

            return PydStackContext_FromWrapped!(T, Iter, iter_t)(self.d_obj);
        });
    }
}

// Advances an iterator object
extern (C)
PyObject* sc_iternext(PyObject* _self) {
    return exception_catcher(delegate PyObject*() {
        alias wrapped_class_object!(StackContext) PydSC_object;
        PydSC_object* self = cast(PydSC_object*)_self;

        try {
            // If the StackContext is done, cease iteration.
            if (!self.d_obj.ready()) {
                return null;
            }
            self.d_obj.run();
        }
        // The StackContext class yields values by throwing an exception.
        // We catch it and pass the converted value into Python.
        catch (PydYield y) {
            return y.item();
        }
        return null;
    });
}

/// Readies the iterator class if it hasn't been already.
void PydStackContext_Ready() {
    alias wrapped_class_type!(StackContext) type;
    alias wrapped_class_object!(StackContext) PydSC_object;
    
    if (!is_wrapped!(StackContext)) {
        type.ob_type = PyType_Type_p;
        type.tp_basicsize = PydSC_object.sizeof;
        type.tp_flags     = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
        type.tp_name = "PydOpApplyWrapper";

        type.tp_iter = &PyObject_SelfIter;
        type.tp_iternext = &sc_iternext;

        PyType_Ready(&type);
        is_wrapped!(StackContext) = true;
        //wrapped_classes[typeid(StackContext)] = true;
    }
}

