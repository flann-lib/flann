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
 * This module contains some useful type conversion functions. There are two
 * interesting operations involved here:
 *
 * PyObject* -> D type
 *
 * D type -> PyObject*
 *
 * The former is handled by d_type, the latter by _py. The py function is
 * provided as a convenience to directly convert a D type into an instance of
 * PydObject.
 */
module pyd.make_object;

import python;

//import std.string;
//import std.stdio;

import pyd.pydobject;
import pyd.class_wrap;
import pyd.func_wrap;
import pyd.exception;
import pyd.lib_abstract :
    objToStr,
    toString,
    ParameterTypeTuple,
    ReturnType
;

package template isArray(T) {
    const bool isArray = is(typeof(T.init[0])[] == T);
}

// This relies on the fact that, for a static array type T,
//      typeof(T.init) != T
// But, rather, T.init is the type it is an array of. (For the dynamic array
// template above, this type is extracted with typeof(T.init[0])).
// Because this is only true for static arrays, it would work just as well to
// say "!is(typeof(T.init) == T)"; however, this template has the advantage of
// being easily fixable should this behavior for static arrays change.
package template isStaticArray(T) {
    const bool isStaticArray = is(typeof(T.init)[(T).sizeof / typeof(T.init).sizeof] == T);
}

package template isAA(T) {
    const bool isAA = is(typeof(T.init.values[0])[typeof(T.init.keys[0])] == T);
}

class to_conversion_wrapper(dg_t) {
    alias ParameterTypeTuple!(dg_t)[0] T;
    alias ReturnType!(dg_t) Intermediate;
    dg_t dg;
    this(dg_t fn) { dg = fn; }
    PyObject* opCall(T t) {
        static if (is(Intermediate == PyObject*)) {
            return dg(t);
        } else {
            return _py(dg(t));
        }
    }
}
class from_conversion_wrapper(dg_t) {
    alias ParameterTypeTuple!(dg_t)[0] Intermediate;
    alias ReturnType!(dg_t) T;
    dg_t dg;
    this(dg_t fn) { dg = fn; }
    T opCall(PyObject* o) {
        static if (is(Intermediate == PyObject*)) {
            return dg(o);
        } else {
            return dg(d_type!(Intermediate)(o));
        }
    }
}

template to_converter_registry(From) {
    PyObject* delegate(From) dg=null;
}
template from_converter_registry(To) {
    To delegate(PyObject*) dg=null;
}

void d_to_python(dg_t) (dg_t dg) {
    static if (is(dg_t == delegate) && is(ReturnType!(dg_t) == PyObject*)) {
        to_converter_registry!(ParameterTypeTuple!(dg_t)[0]).dg = dg;
    } else {
        auto o = new to_conversion_wrapper!(dg_t)(dg);
        to_converter_registry!(typeof(o).T).dg = &o.opCall;
    }
}
void python_to_d(dg_t) (dg_t dg) {
    static if (is(dg_t == delegate) && is(ParameterTypeTuple!(dg_t)[0] == PyObject*)) {
        from_converter_registry!(ReturnType!(dg_t)).dg = dg;
    } else {
        auto o = new from_conversion_wrapper!(dg_t)(dg);
        from_converter_registry!(typeof(o).T).dg = &o.opCall;
    }
}

/**
 * Returns a new (owned) reference to a Python object based on the passed
 * argument. If the passed argument is a PyObject*, this "steals" the
 * reference. (In other words, it returns the PyObject* without changing its
 * reference count.) If the passed argument is a PydObject, this returns a new
 * reference to whatever the PydObject holds a reference to.
 *
 * If the passed argument can't be converted to a PyObject, a Python
 * RuntimeError will be raised and this function will return null.
 */
PyObject* _py(T) (T t) {
    static if (!is(T == PyObject*) && is(typeof(t is null))) {
        if (t is null) {
            Py_INCREF(Py_None);
            return Py_None;
        }
    }
    static if (is(T : bool)) {
        PyObject* temp = (t) ? Py_True : Py_False;
        Py_INCREF(temp);
        return temp;
    } else static if (is(T : C_long)) {
        return PyInt_FromLong(t);
    } else static if (is(T : C_longlong)) {
        return PyLong_FromLongLong(t);
    } else static if (is(T : double)) {
        return PyFloat_FromDouble(t);
    } else static if (is(T : idouble)) {
        return PyComplex_FromDoubles(0.0, t.im);
    } else static if (is(T : cdouble)) {
        return PyComplex_FromDoubles(t.re, t.im);
    } else static if (is(T : string)) {
        return PyString_FromString((t ~ \0).ptr);
    } else static if (is(T : wchar[])) {
        return PyUnicode_FromWideChar(t, t.length);
    // Converts any array (static or dynamic) to a Python list
    } else static if (isArray!(T) || isStaticArray!(T)) {
        PyObject* lst = PyList_New(t.length);
        PyObject* temp;
        if (lst is null) return null;
        for(int i=0; i<t.length; ++i) {
            temp = _py(t[i]);
            if (temp is null) {
                Py_DECREF(lst);
                return null;
            }
            // Steals the reference to temp
            PyList_SET_ITEM(lst, i, temp);
        }
        return lst;
    // Converts any associative array to a Python dict
    } else static if (isAA!(T)) {
        PyObject* dict = PyDict_New();
        PyObject* ktemp, vtemp;
        int result;
        if (dict is null) return null;
        foreach(k, v; t) {
            ktemp = _py(k);
            vtemp = _py(v);
            if (ktemp is null || vtemp is null) {
                if (ktemp !is null) Py_DECREF(ktemp);
                if (vtemp !is null) Py_DECREF(vtemp);
                Py_DECREF(dict);
                return null;
            }
            result = PyDict_SetItem(dict, ktemp, vtemp);
            Py_DECREF(ktemp);
            Py_DECREF(vtemp);
            if (result == -1) {
                Py_DECREF(dict);
                return null;
            }
        }
        return dict;
    } else static if (is(T == delegate) || is(T == function)) {
        PydWrappedFunc_Ready!(T)();
        return WrapPyObject_FromObject(t);
    } else static if (is(T : PydObject)) {
        PyObject* temp = t.ptr();
        Py_INCREF(temp);
        return temp;
    // The function expects to be passed a borrowed reference and return an
    // owned reference. Thus, if passed a PyObject*, this will increment the
    // reference count.
    } else static if (is(T : PyObject*)) {
        Py_INCREF(t);
        return t;
    // Convert wrapped type to a PyObject*
    } else static if (is(T == class)) {
        // But only if it actually is a wrapped type. :-)
        PyTypeObject** type = t.classinfo in wrapped_classes;
        if (type) {
            return WrapPyObject_FromTypeAndObject(*type, t);
        }
        // If it's not a wrapped type, fall through to the exception.
    // If converting a struct by value, create a copy and wrap that
    } else static if (is(T == struct)) {
        if (is_wrapped!(T*)) {
            T* temp = new T;
            *temp = t;
            return WrapPyObject_FromObject(temp);
        }
    // If converting a struct by reference, wrap the thing directly
    } else static if (is(typeof(*t) == struct)) {
        if (is_wrapped!(T)) {
            if (t is null) {
                Py_INCREF(Py_None);
                return Py_None;
            }
            return WrapPyObject_FromObject(t);
        }
    }
    // No conversion found, check runtime registry
    if (to_converter_registry!(T).dg) {
        return to_converter_registry!(T).dg(t);
    }
    PyErr_SetString(PyExc_RuntimeError, ("D conversion function _py failed with type " ~ objToStr(typeid(T))).ptr);
    return null;
}

/**
 * Helper function for creating a PyTuple from a series of D items.
 */
PyObject* PyTuple_FromItems(T ...)(T t) {
    PyObject* tuple = PyTuple_New(t.length);
    PyObject* temp;
    if (tuple is null) return null;
    foreach(i, arg; t) {
        temp = _py(arg);
        if (temp is null) {
            Py_DECREF(tuple);
            return null;
        }
        PyTuple_SetItem(tuple, i, temp);
    }
    return tuple;
}

/**
 * Constructs an object based on the type of the argument passed in.
 *
 * For example, calling py(10) would return a PydObject holding the value 10.
 *
 * Calling this with a PydObject will return back a reference to the very same
 * PydObject.
 */
PydObject py(T) (T t) {
    static if(is(T : PydObject)) {
        return t;
    } else {
        return new PydObject(_py(t));
    }
}

/**
 * An exception class used by d_type.
 */
class PydConversionException : Exception {
    this(string msg) { super(msg); }
}

/**
 * This converts a PyObject* to a D type. The template argument is the type to
 * convert to. The function argument is the PyObject* to convert. For instance:
 *
 *$(D_CODE PyObject* i = PyInt_FromLong(20);
 *int n = _d_type!(int)(i);
 *assert(n == 20);)
 *
 * This throws a PydConversionException if the PyObject can't be converted to
 * the given D type.
 */
T d_type(T) (PyObject* o) {
    // This ordering is very important. If the check for bool came first,
    // then all integral types would be converted to bools (they would be
    // 0 or 1), because bool can be implicitly converted to any integral
    // type.
    //
    // This also means that:
    //  (1) Conversion to PydObject will construct an object and return that.
    //  (2) Any integral type smaller than a C_long (which is usually just
    //      an int, meaning short and byte) will use the bool conversion.
    //  (3) Conversion to a float shouldn't work.
    static if (is(PyObject* : T)) {
        return o;
    } else static if (is(PydObject : T)) {
        return new PydObject(o, true);
    } else static if (is(T == void)) {
        if (o != Py_None) could_not_convert!(T)(o);
        Py_INCREF(Py_None);
        return Py_None;
    } else static if (is(T == class)) {
        // We can only convert to a class if it has been wrapped, and of course
        // we can only convert the object if it is the wrapped type.
        if (
            is_wrapped!(T) &&
            PyObject_IsInstance(o, cast(PyObject*)&wrapped_class_type!(T)) &&
            cast(T)((cast(wrapped_class_object!(Object)*)o).d_obj) !is null
        ) {
            return WrapPyObject_AsObject!(T)(o);
        }
        // Otherwise, throw up an exception.
        //could_not_convert!(T)(o);
    } else static if (is(T == struct)) { // struct by value
        if (is_wrapped!(T*) && PyObject_TypeCheck(o, &wrapped_class_type!(T*))) { 
            return *WrapPyObject_AsObject!(T*)(o);
        }// else could_not_convert!(T)(o);
    } else static if (is(typeof(*(T.init)) == struct)) { // pointer to struct   
        if (is_wrapped!(T) && PyObject_TypeCheck(o, &wrapped_class_type!(T))) {
            return WrapPyObject_AsObject!(T)(o);
        }// else could_not_convert!(T)(o);
    } else static if (is(T == delegate)) {
        // Get the original wrapped delegate out if this is a wrapped delegate
        if (is_wrapped!(T) && PyObject_TypeCheck(o, &wrapped_class_type!(T))) {
            return WrapPyObject_AsObject!(T)(o);
        // Otherwise, wrap the PyCallable with a delegate
        } else if (PyCallable_Check(o)) {
            return PydCallable_AsDelegate!(T)(o);
        }// else could_not_convert!(T)(o);
    } else static if (is(T == function)) {
        // We can only make it a function pointer if we originally wrapped a
        // function pointer.
        if (is_wrapped!(T) && PyObject_TypeCheck(o, &wrapped_class_type!(T))) {
            return WrapPyObject_AsObject!(T)(o);
        }// else could_not_convert!(T)(o);
    /+
    } else static if (is(wchar[] : T)) {
        wchar[] temp;
        temp.length = PyUnicode_GetSize(o);
        PyUnicode_AsWideChar(cast(PyUnicodeObject*)o, temp, temp.length);
        return temp;
    +/
    } else static if (is(string : T) || is(char[] : T)) {
        c_str result;
        PyObject* repr;
        // If it's a string, convert it
        if (PyString_Check(o) || PyUnicode_Check(o)) {
            result = PyString_AsString(o);
        // If it's something else, convert its repr
        } else {
            repr = PyObject_Repr(o);
            if (repr is null) handle_exception();
            result = PyString_AsString(repr);
            Py_DECREF(repr);
        }
        if (result is null) handle_exception();
        version (D_Version2) {
            static if (is(string : T)) {
                return .toString(result);
            } else {
                return .toString(result).dup;
            }
        } else {
            return .toString(result).dup;
        }
    } else static if (is(T E : E[])) {
        // Dynamic arrays
        PyObject* iter = PyObject_GetIter(o);
        if (iter is null) {
            PyErr_Clear();
            could_not_convert!(T)(o);
        }
        scope(exit) Py_DECREF(iter);
        int len = PyObject_Length(o);
        if (len == -1) {
            PyErr_Clear();
            could_not_convert!(T)(o);
        }
        T array;
        array.length = len;
        int i = 0;
        PyObject* item = PyIter_Next(iter);
        while (item) {
            try {
                array[i] = d_type!(E)(item);
            } catch(PydConversionException e) {
                Py_DECREF(item);
                // We re-throw the original conversion exception, rather than
                // complaining about being unable to convert to an array. The
                // partially constructed array is left to the GC.
                throw e;
            }
            ++i;
            Py_DECREF(item);
            item = PyIter_Next(iter);
        }
        return array;
    } else static if (is(cdouble : T)) {
        double real_ = PyComplex_RealAsDouble(o);
        handle_exception();
        double imag = PyComplex_ImagAsDouble(o);
        handle_exception();
        return real_ + imag * 1i;
    } else static if (is(double : T)) {
        double res = PyFloat_AsDouble(o);
        handle_exception();
        return res;
    } else static if (is(C_longlong : T)) {
        if (!PyNumber_Check(o)) could_not_convert!(T)(o);
        C_longlong res = PyLong_AsLongLong(o);
        handle_exception();
        return res;
    } else static if (is(C_long : T)) {
        if (!PyNumber_Check(o)) could_not_convert!(T)(o);
        C_long res = PyInt_AsLong(o);
        handle_exception();
        return res;
    } else static if (is(bool : T)) {
        if (!PyNumber_Check(o)) could_not_convert!(T)(o);
        int res = PyObject_IsTrue(o);
        handle_exception();
        return res == 1;
    }/+ else {
        could_not_convert!(T)(o);
    }+/
    if (from_converter_registry!(T).dg) {
        return from_converter_registry!(T).dg(o);
    }
    could_not_convert!(T)(o);
}

alias d_type!(Object) d_type_Object;

private
void could_not_convert(T) (PyObject* o) {
    // Pull out the name of the type of this Python object, and the
    // name of the D type.
    string py_typename, d_typename;
    PyObject* py_type, py_type_str;
    py_type = PyObject_Type(o);
    if (py_type is null) {
        py_typename = "<unknown>";
    } else {
        py_type_str = PyObject_GetAttrString(py_type, "__name__");
        Py_DECREF(py_type);
        if (py_type_str is null) {
            py_typename = "<unknown>";
        } else {
            py_typename = .toString(PyString_AsString(py_type_str));
            Py_DECREF(py_type_str);
        }
    }
    d_typename = objToStr(typeid(T));
    throw new PydConversionException(
        "Couldn't convert Python type '" ~
        py_typename ~
        "' to D type '" ~
        d_typename ~
        "'"
    );
}
