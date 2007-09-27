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
module pyd.func_wrap;

import python;

import pyd.class_wrap;
import pyd.dg_convert;
import pyd.exception;
import pyd.make_object;
import pyd.lib_abstract :
    toString,
    ParameterTypeTuple,
    ReturnType
;

//import meta.Default;
//import meta.Nameof;

//import std.string;
//import std.traits;
//import std.stdio;

// Builds a callable Python object from a delegate or function pointer.
void PydWrappedFunc_Ready(T)() {
    alias wrapped_class_type!(T) type;
    alias wrapped_class_object!(T) obj;
    if (!is_wrapped!(T)) {
        type.ob_type = PyType_Type_p;
        type.tp_basicsize = obj.sizeof;
        type.tp_name = "PydFunc";
        type.tp_flags = Py_TPFLAGS_DEFAULT;

        type.tp_call = &wrapped_func_call!(T).call;

        PyType_Ready(&type);
        is_wrapped!(T) = true;
        //wrapped_classes[typeid(T)] = true;
    }
}

void setWrongArgsError(int gotArgs, uint minArgs, uint maxArgs, string funcName="") {
    char[] str;
    if (funcName == "") {
        str ~= "function takes ";
    } else {
        str ~= funcName ~ "() takes ";
    }

    char[] argStr(int args) {
        char[] temp = toString(args) ~ " argument";
        if (args > 1) {
            temp ~= "s";
        }
        return temp;
    }

    if (minArgs == maxArgs) {
        if (minArgs == 0) {
            str ~= "no arguments";
        } else {
            str ~= "exactly " ~ argStr(minArgs);
        }
    }
    else if (gotArgs < minArgs) {
        str ~= "at least " ~ argStr(minArgs);
    } else {
        str ~= "at most " ~ argStr(maxArgs);
    }
    str ~= " (" ~ toString(gotArgs) ~ " given)";

    PyErr_SetString(PyExc_TypeError, (str ~ \0).ptr);
}

// Calls callable alias fn with PyTuple args.
ReturnType!(fn_t) applyPyTupleToAlias(alias fn, fn_t, uint MIN_ARGS) (PyObject* args) {
    alias ParameterTypeTuple!(fn_t) T;
    const uint MAX_ARGS = T.length;
    alias ReturnType!(fn_t) RT;

    int argCount = 0;
    // This can make it more convenient to call this with 0 args.
    if (args !is null) {
        argCount = PyObject_Length(args);
    }

    // Sanity check!
    if (argCount < MIN_ARGS || argCount > MAX_ARGS) {
        setWrongArgsError(argCount, MIN_ARGS, MAX_ARGS);
        handle_exception();
    }

    static if (MIN_ARGS == 0) {
        if (argCount == 0) {
            return fn();
        }
    }
    T t;
    foreach(i, arg; t) {
        const uint argNum = i+1;
        if (i < argCount) {
            t[i] = d_type!(typeof(arg))(PyTuple_GetItem(args, i));
        }
        static if (argNum >= MIN_ARGS && argNum <= MAX_ARGS) {
            if (argNum == argCount) {
                return fn(t[0 .. argNum]);
                break;
            }
        }
    }
    // This should never get here.
    throw new Exception("applyPyTupleToAlias reached end! argCount = " ~ toString(argCount));
    static if (!is(RT == void))
        return RT.init;
}

// wraps applyPyTupleToAlias to return a PyObject*
PyObject* pyApplyToAlias(alias fn, fn_t, uint MIN_ARGS) (PyObject* args) {
    static if (is(ReturnType!(fn_t) == void)) {
        applyPyTupleToAlias!(fn, fn_t, MIN_ARGS)(args);
        Py_INCREF(Py_None);
        return Py_None;
    } else {
        return _py( applyPyTupleToAlias!(fn, fn_t, MIN_ARGS)(args) );
    }
}

ReturnType!(dg_t) applyPyTupleToDelegate(dg_t) (dg_t dg, PyObject* args) {
    alias ParameterTypeTuple!(dg_t) T;
    const uint ARGS = T.length;
    alias ReturnType!(dg_t) RT;

    int argCount = 0;
    // This can make it more convenient to call this with 0 args.
    if (args !is null) {
        argCount = PyObject_Length(args);
    }

    // Sanity check!
    if (argCount != ARGS) {
        setWrongArgsError(argCount, ARGS, ARGS);
        handle_exception();
    }

    static if (ARGS == 0) {
        if (argCount == 0) {
            return dg();
        }
    }
    T t;
    foreach(i, arg; t) {
        t[i] = d_type!(typeof(arg))(PyTuple_GetItem(args, i));
    }
    return dg(t);
}

// wraps applyPyTupleToDelegate to return a PyObject*
PyObject* pyApplyToDelegate(dg_t) (dg_t dg, PyObject* args) {
    static if (is(ReturnType!(dg_t) == void)) {
        applyPyTupleToDelegate(dg, args);
        Py_INCREF(Py_None);
        return Py_None;
    } else {
        return _py( applyPyTupleToDelegate(dg, args) );
    }
}

template wrapped_func_call(fn_t) {
    const uint ARGS = ParameterTypeTuple!(fn_t).length;
    alias ReturnType!(fn_t) RT;
    // The entry for the tp_call slot of the PydFunc types.
    // (Or: What gets called when you pass a delegate or function pointer to
    // Python.)
    extern(C)
    PyObject* call(PyObject* self, PyObject* args, PyObject* kwds) {
        if (self is null) {
            PyErr_SetString(PyExc_TypeError, "Wrapped method didn't get a function pointer.");
            return null;
        }

        fn_t fn = (cast(wrapped_class_object!(fn_t)*)self).d_obj;

        return exception_catcher(delegate PyObject*() {
            return pyApplyToDelegate(fn, args);
        });
    }
}

// Wraps a function alias with a PyCFunction.
template function_wrap(alias real_fn, uint MIN_ARGS, fn_t=typeof(&real_fn)) {
    alias ParameterTypeTuple!(fn_t) Info;
    const uint MAX_ARGS = Info.length;
    alias ReturnType!(fn_t) RT;

    extern (C)
    PyObject* func(PyObject* self, PyObject* args) {
        return exception_catcher(delegate PyObject*() {
            return pyApplyToAlias!(real_fn, fn_t, MIN_ARGS)(args);
        });
    }
}

// Wraps a member function alias with a PyCFunction.
template method_wrap(C, alias real_fn, fn_t=typeof(&real_fn)) {
    alias ParameterTypeTuple!(fn_t) Info;
    const uint ARGS = Info.length;
    alias ReturnType!(fn_t) RT;
    extern(C)
    PyObject* func(PyObject* self, PyObject* args) {
        return exception_catcher(delegate PyObject*() {
            // Didn't pass a "self" parameter! Ack!
            if (self is null) {
                PyErr_SetString(PyExc_TypeError, "Wrapped method didn't get a 'self' parameter.");
                return null;
            }
            C instance = WrapPyObject_AsObject!(C)(self);//(cast(wrapped_class_object!(C)*)self).d_obj;
            if (instance is null) {
                PyErr_SetString(PyExc_ValueError, "Wrapped class instance is null!");
                return null;
            }
            fn_to_dg!(fn_t) dg = dg_wrapper!(C, fn_t)(instance, cast(fn_t)&real_fn);
            return pyApplyToDelegate(dg, args);
        });
    }
}

//-----------------------------------------------------------------------------
// And now the reverse operation: wrapping a Python callable with a delegate.
// These rely on a whole collection of nasty templates, but the result is both
// flexible and pretty fast.
// (Sadly, wrapping a Python callable with a regular function is not quite
// possible.)
//-----------------------------------------------------------------------------
// The steps involved when calling this function are as follows:
// 1) An instance of PydWrappedFunc is made, and the callable placed within.
// 2) The delegate type Dg is broken into its constituent parts.
// 3) These parts are used to get the proper overload of PydWrappedFunc.fn
// 4) A delegate to PydWrappedFunc.fn is returned.
// 5) When fn is called, it attempts to cram the arguments into the callable.
//    If Python objects to this, an exception is raised. Note that this means
//    any error in converting the callable to a given delegate can only be
//    detected at runtime.

Dg PydCallable_AsDelegate(Dg) (PyObject* c) {
    return _pycallable_asdgT!(Dg).func(c);
}

private template _pycallable_asdgT(Dg) {
    alias ParameterTypeTuple!(Dg) Info;
    alias ReturnType!(Dg) Tr;

    Dg func(PyObject* c) {
        auto f = new PydWrappedFunc(c);

        return &f.fn!(Tr, Info);
    }
}

private
class PydWrappedFunc {
    PyObject* callable;

    this(PyObject* c) { callable = c; Py_INCREF(c); }
    ~this() { Py_DECREF(callable); }

    Tr fn(Tr, T ...) (T t) {
        PyObject* ret = call(t);
        if (ret is null) handle_exception();
        scope(exit) Py_DECREF(ret);
        return d_type!(Tr)(ret);
    }

    PyObject* call(T ...) (T t) {
        const uint ARGS = T.length;
        PyObject* pyt = PyTuple_FromItems(t);
        if (pyt is null) return null;
        scope(exit) Py_DECREF(pyt);
        return PyObject_CallObject(callable, pyt);
    }
}
