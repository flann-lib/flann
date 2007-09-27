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
module pyd.class_wrap;

import python;

import pyd.ctor_wrap;
import pyd.def;
import pyd.dg_convert;
import pyd.exception;
import pyd.func_wrap;
version (Pyd_with_StackThreads) {
    import pyd.iteration;
}
import pyd.make_object;
import pyd.make_wrapper;
import pyd.op_wrap;
import pyd.make_wrapper;
import pyd.lib_abstract :
    symbolnameof,
    prettytypeof,
    toString,
    ParameterTypeTuple,
    ReturnType,
    minArgs,
    objToStr,
    ToString
;

//import meta.Default;

PyTypeObject*[ClassInfo] wrapped_classes;
template shim_class(T) {
    PyTypeObject* shim_class;
}

// This is split out in case I ever want to make a subtype of a wrapped class.
template PydWrapObject_HEAD(T) {
    mixin PyObject_HEAD;
    T d_obj;
}

/// The class object, a subtype of PyObject
template wrapped_class_object(T) {
    extern(C)
    struct wrapped_class_object {
        mixin PydWrapObject_HEAD!(T);
    }
}

///
template wrapped_class_type(T) {
/// The type object, an instance of PyType_Type
    static PyTypeObject wrapped_class_type = {
        1,                            /*ob_refcnt*/
        null,                         /*ob_type*/
        0,                            /*ob_size*/
        null,                         /*tp_name*/
        0,                            /*tp_basicsize*/
        0,                            /*tp_itemsize*/
        &wrapped_methods!(T).wrapped_dealloc, /*tp_dealloc*/
        null,                         /*tp_print*/
        null,                         /*tp_getattr*/
        null,                         /*tp_setattr*/
        null,                         /*tp_compare*/
        null,                         /*tp_repr*/
        null,                         /*tp_as_number*/
        null,                         /*tp_as_sequence*/
        null,                         /*tp_as_mapping*/
        null,                         /*tp_hash */
        null,                         /*tp_call*/
        null,                         /*tp_str*/
        null,                         /*tp_getattro*/
        null,                         /*tp_setattro*/
        null,                         /*tp_as_buffer*/
        0,                            /*tp_flags*/
        null,                         /*tp_doc*/
        null,                         /*tp_traverse*/
        null,                         /*tp_clear*/
        null,                         /*tp_richcompare*/
        0,                            /*tp_weaklistoffset*/
        null,                         /*tp_iter*/
        null,                         /*tp_iternext*/
        null,                         /*tp_methods*/
        null,                         /*tp_members*/
        null,                         /*tp_getset*/
        null,                         /*tp_base*/
        null,                         /*tp_dict*/
        null,                         /*tp_descr_get*/
        null,                         /*tp_descr_set*/
        0,                            /*tp_dictoffset*/
        null,                         /*tp_init*/
        null,                         /*tp_alloc*/
        &wrapped_methods!(T).wrapped_new, /*tp_new*/
        null,                         /*tp_free*/
        null,                         /*tp_is_gc*/
        null,                         /*tp_bases*/
        null,                         /*tp_mro*/
        null,                         /*tp_cache*/
        null,                         /*tp_subclasses*/
        null,                         /*tp_weaklist*/
        null,                         /*tp_del*/
    };
}

// A mappnig of all class references that are being held by Python.
PyObject*[void*] wrapped_gc_objects;
// A mapping of all GC references that are being held by Python.
template wrapped_gc_references(dg_t) {
    PyObject*[dg_t] wrapped_gc_references;
}

/**
 * A useful check for whether a given class has been wrapped. Mainly used by
 * the conversion functions (see make_object.d), but possibly useful elsewhere.
 */
template is_wrapped(T) {
    bool is_wrapped = false;
}

// The list of wrapped methods for this class.
template wrapped_method_list(T) {
    PyMethodDef[] wrapped_method_list = [
        { null, null, 0, null }
    ];
}

// The list of wrapped properties for this class.
template wrapped_prop_list(T) {
    static PyGetSetDef[] wrapped_prop_list = [
        { null, null, null, null, null }
    ];
}

//////////////////////
// STANDARD METHODS //
//////////////////////

//import std.stdio;

/// Various wrapped methods
template wrapped_methods(T) {
    alias wrapped_class_object!(T) wrap_object;
    /// The generic "__new__" method
    extern(C)
    PyObject* wrapped_new(PyTypeObject* type, PyObject* args, PyObject* kwds) {
        return exception_catcher(delegate PyObject*() {
            wrap_object* self;

            self = cast(wrap_object*)type.tp_alloc(type, 0);
            if (self !is null) {
                self.d_obj = null;
            }

            return cast(PyObject*)self;
        });
    }

    /// The generic dealloc method.
    extern(C)
    void wrapped_dealloc(PyObject* self) {
        exception_catcher(delegate void() {
            //writefln("wrapped_dealloc: T is %s", typeid(T));
            WrapPyObject_SetObj!(T)(self, cast(T)null);
            self.ob_type.tp_free(self);
        });
    }
}

template wrapped_repr(T, alias fn) {
    alias wrapped_class_object!(T) wrap_object;
    /// The default repr method calls the class's toString.
    extern(C)
    PyObject* repr(PyObject* self) {
        return exception_catcher(delegate PyObject*() {
            return method_wrap!(T, fn, char[] function()).func(self, null);
        });
    }
}

// This template gets an alias to a property and derives the types of the
// getter form and the setter form. It requires that the getter form return the
// same type that the setter form accepts.
template property_parts(alias p) {
    // This may be either the getter or the setter
    alias typeof(&p) p_t;
    alias ParameterTypeTuple!(p_t) Info;
    // This means it's the getter
    static if (Info.length == 0) {
        alias p_t getter_type;
        // The setter may return void, or it may return the newly set attribute.
        alias typeof(p(ReturnType!(p_t).init)) function(ReturnType!(p_t)) setter_type;
    // This means it's the setter
    } else {
        alias p_t setter_type;
        alias Info[0] function() getter_type;
    }
}

///
template wrapped_get(T, alias Fn) {
    /// A generic wrapper around a "getter" property.
    extern(C)
    PyObject* func(PyObject* self, void* closure) {
        // method_wrap already catches exceptions
        return method_wrap!(T, Fn, property_parts!(Fn).getter_type).func(self, null);
    }
}

///
template wrapped_set(T, alias Fn) {
    /// A generic wrapper around a "setter" property.
    extern(C)
    int func(PyObject* self, PyObject* value, void* closure) {
        PyObject* temp_tuple = PyTuple_New(1);
        if (temp_tuple is null) return -1;
        scope(exit) Py_DECREF(temp_tuple);
        Py_INCREF(value);
        PyTuple_SetItem(temp_tuple, 0, value);
        PyObject* res = method_wrap!(T, Fn, property_parts!(Fn).setter_type).func(self, temp_tuple);
        // If we get something back, we need to DECREF it.
        if (res) Py_DECREF(res);
        // If we don't, propagate the exception
        else return -1;
        // Otherwise, all is well.
        return 0;
    }
}

//////////////////////////////
// CLASS WRAPPING INTERFACE //
//////////////////////////////

/+
/**
 * This struct wraps a D class. Its member functions are the primary way of
 * wrapping the specific parts of the class.
 */
struct wrapped_class(T, char[] classname = symbolnameof!(T)) {
    static if (is(T == class)) pragma(msg, "wrapped_class: " ~ classname);
    static const char[] _name = classname;
    static bool _private = false;
    alias T wrapped_type;
+/

//enum ParamType { Def, StaticDef, Property, Init, Parent, Hide, Iter, AltIter }
struct DoNothing {
    static void call(T) () {}
}
/**
Wraps a member function of the class.

Params:
fn = The member function to wrap.
name = The name of the function as it will appear in Python.
fn_t = The type of the function. It is only useful to specify this
       if more than one function has the same name as this one.
*/
struct Def(alias fn) {
    mixin _Def!(fn, symbolnameof!(fn), typeof(&fn), "");
}
struct Def(alias fn, string docstring) {
    mixin _Def!(fn, /*symbolnameof!(fn),*/ symbolnameof!(fn), typeof(&fn)/+, minArgs!(fn)+/, docstring);
}
struct Def(alias fn, string name, string docstring) {
    mixin _Def!(fn, /*symbolnameof!(fn),*/ name, typeof(&fn)/+, minArgs!(fn)+/, docstring);
}
struct Def(alias fn, string name, fn_t) {
    mixin _Def!(fn, /*symbolnameof!(fn),*/ name, fn_t/+, minArgs!(fn)+/, "");
}
struct Def(alias fn, fn_t) {
    mixin _Def!(fn, /*symbolnameof!(fn),*/ symbolnameof!(fn), fn_t/+, minArgs!(fn)+/, "");
}
struct Def(alias fn, fn_t, string docstring) {
    mixin _Def!(fn, /*symbolnameof!(fn),*/ symbolnameof!(fn), fn_t/+, minArgs!(fn)+/, docstring);
}
struct Def(alias fn, string name, fn_t, string docstring) {
    mixin _Def!(fn, /*symbolnameof!(fn),*/ name, fn_t/+, minArgs!(fn)+/, docstring);
}
/+
template Def(alias fn, string name, fn_t, uint MIN_ARGS=minArgs!(fn)/+, string docstring=""+/) {
    alias Def!(fn, /*symbolnameof!(fn),*/ name, fn_t, MIN_ARGS/+, docstring+/) Def;
}
+/
template _Def(alias fn, /*string _realname,*/ string name, fn_t/+, uint MIN_ARGS=minArgs!(fn)+/, string docstring) {
    //static const type = ParamType.Def;
    alias fn func;
    alias fn_t func_t;
    static const char[] realname = symbolnameof!(fn);//_realname;
    static const char[] funcname = name;
    static const uint min_args = minArgs!(fn);
    static const bool needs_shim = false;

    static void call(T) () {
        pragma(msg, "class.def: " ~ name);
        static PyMethodDef empty = { null, null, 0, null };
        alias wrapped_method_list!(T) list;
        list[length-1].ml_name = (name ~ \0).ptr;
        list[length-1].ml_meth = &method_wrap!(T, fn, fn_t).func;
        list[length-1].ml_flags = METH_VARARGS;
        list[length-1].ml_doc = (docstring~\0).ptr;
        list ~= empty;
        // It's possible that appending the empty item invalidated the
        // pointer in the type struct, so we renew it here.
        wrapped_class_type!(T).tp_methods = list.ptr;
    }
    template shim(uint i) {
        const char[] shim =
            "    alias Params["~ToString!(i)~"] __pyd_p"~ToString!(i)~";\n"
            "    ReturnType!(__pyd_p"~ToString!(i)~".func_t) "~realname~"(ParameterTypeTuple!(__pyd_p"~ToString!(i)~".func_t) t) {\n"
            "        return __pyd_get_overload!(\""~realname~"\", __pyd_p"~ToString!(i)~".func_t).func(\""~name~"\", t);\n"
            "    }\n";
    }
}

/**
Wraps a static member function of the class. Identical to pyd.def.def
*/
struct StaticDef(alias fn) {
    mixin _StaticDef!(fn,/+ symbolnameof!(fn),+/ symbolnameof!(fn), typeof(&fn), minArgs!(fn), "");
}
struct StaticDef(alias fn, string docstring) {
    mixin _StaticDef!(fn,/+ symbolnameof!(fn),+/ symbolnameof!(fn), typeof(&fn), minArgs!(fn), docstring);
}
struct StaticDef(alias _fn, string name, string docstring) {
    mixin _StaticDef!(fn,/+ symbolnameof!(fn),+/ name, typeof(&fn), minArgs!(fn), docstring);
}
struct StaticDef(alias _fn, string name, fn_t, string docstring) {
    mixin _StaticDef!(fn,/+ symbolnameof!(fn),+/ name, fn_t, minArgs!(fn), docstring);
}
struct StaticDef(alias _fn, fn_t) {
    mixin _StaticDef!(fn,/+ symbolnameof!(fn),+/ symbolnameof!(fn), fn_t, minArgs!(fn), "");
}
struct StaticDef(alias _fn, fn_t, string docstring) {
    mixin _StaticDef!(fn,/+ symbolnameof!(fn),+/ symbolnameof!(fn), fn_t, minArgs!(fn), docstring);
}
struct StaticDef(alias _fn, string name, fn_t) {
    mixin _StaticDef!(fn,/+ symbolnameof!(fn),+/ name, fn_t, minArgs!(fn), "");
}
struct StaticDef(alias _fn, string name, fn_t, uint MIN_ARGS) {
    mixin _StaticDef!(fn,/+ symbolnameof!(fn),+/ name, fn_t, MIN_ARGS, "");
}
struct StaticDef(alias _fn, string name, fn_t, uint MIN_ARGS, string docstring) {
    mixin _StaticDef!(fn,/+ symbolnameof!(fn),+/ name, fn_t, MIN_ARGS, docstring);
}
template _StaticDef(alias fn,/+ string _realname,+/ string name, fn_t, uint MIN_ARGS, string docstring) {
    //static const type = ParamType.StaticDef;
    alias fn func;
    alias fn_t func_t;
    static const char[] funcname = name;
    static const uint min_args = MIN_ARGS;
    static const bool needs_shim = false;
    static void call(T) () {
        pragma(msg, "class.static_def: " ~ name);
        static PyMethodDef empty = { null, null, 0, null };
        alias wrapped_method_list!(T) list;
        list[length-1].ml_name = (name ~ \0).ptr;
        list[length-1].ml_meth = &function_wrap!(fn, MIN_ARGS, fn_t).func;
        list[length-1].ml_flags = METH_VARARGS | METH_STATIC;
        list[length-1].ml_doc = (docstring~\0).ptr;
        list ~= empty;
        wrapped_class_type!(T).tp_methods = list;
    }
    template shim(uint i) {
        const char[] shim = "";
    }
}

/**
Wraps a property of the class.

Params:
fn = The property to wrap.
name = The name of the property as it will appear in Python.
RO = Whether this is a read-only property.
*/
//template Property(alias fn, char[] name = symbolnameof!(fn), bool RO=false, char[] docstring = "") {
//    alias Property!(fn, symbolnameof!(fn), name, RO, docstring) Property;
//}
struct Property(alias fn) {
    mixin _Property!(fn, symbolnameof!(fn), symbolnameof!(fn), false, "");
}
struct Property(alias fn, string docstring) {
    mixin _Property!(fn, symbolnameof!(fn), symbolnameof!(fn), false, docstring);
}
struct Property(alias fn, string name, string docstring) {
    mixin _Property!(fn, symbolnameof!(fn), name, false, docstring);
}
struct Property(alias fn, string name, bool RO) {
    mixin _Property!(fn, symbolnameof!(fn), name, RO, "");
}
struct Property(alias fn, string name, bool RO, string docstring) {
    mixin _Property!(fn, symbolnameof!(fn), name, RO, docstring);
}
struct Property(alias fn, bool RO) {
    mixin _Property!(fn, symbolnameof!(fn), symbolnameof!(fn), RO, "");
}
struct Property(alias fn, bool RO, string docstring) {
    mixin _Property!(fn, symbolnameof!(fn), symbolnameof!(fn), RO, docstring);
}
template _Property(alias fn, string _realname, string name, bool RO, string docstring) {
    alias property_parts!(fn).getter_type get_t;
    alias property_parts!(fn).setter_type set_t;
    static const char[] realname = _realname;
    static const char[] funcname = name;
    static const bool readonly = RO;
    static const bool needs_shim = false;
    static void call(T) () {
        pragma(msg, "class.prop: " ~ name);
        static PyGetSetDef empty = { null, null, null, null, null };
        wrapped_prop_list!(T)[length-1].name = (name ~ \0).ptr;
        wrapped_prop_list!(T)[length-1].get =
            &wrapped_get!(T, fn).func;
        static if (!RO) {
            wrapped_prop_list!(T)[length-1].set =
                &wrapped_set!(T, fn).func;
        }
        wrapped_prop_list!(T)[length-1].doc = (docstring~\0).ptr;
        wrapped_prop_list!(T)[length-1].closure = null;
        wrapped_prop_list!(T) ~= empty;
        // It's possible that appending the empty item invalidated the
        // pointer in the type struct, so we renew it here.
        wrapped_class_type!(T).tp_getset =
            wrapped_prop_list!(T).ptr;
    }
    template shim_setter(uint i) {
        static if (RO) {
            const char[] shim_setter = "";
        } else {
            const char[] shim_setter =
            "    ReturnType!(__pyd_p"~ToString!(i)~".set_t) "~_realname~"(ParameterTypeTuple!(__pyd_p"~ToString!(i)~".set_t) t) {\n"
            "        return __pyd_get_overload!(\""~_realname~"\", __pyd_p"~ToString!(i)~".set_t).func(\""~name~"\", t);\n"
            "    }\n";
        }
    }
    template shim(uint i) {
        const char[] shim =
            "    alias Params["~ToString!(i)~"] __pyd_p"~ToString!(i)~";\n"
            "    ReturnType!(__pyd_p"~ToString!(i)~".get_t) "~_realname~"() {\n"
            "        return __pyd_get_overload!(\""~_realname~"\", __pyd_p"~ToString!(i)~".get_t).func(\""~name~"\");\n"
            "    }\n" ~
            shim_setter!(i);
    }
}

/**
Wraps a method as the class's __repr__ in Python.
*/
struct Repr(alias fn) {
    static const bool needs_shim = false;
    static void call(T)() {
        alias wrapped_class_type!(T) type;
        type.tp_repr = &wrapped_repr!(T, fn).repr;
    }
    template shim(uint i) {
        const char[] shim = "";
    }
}

/**
Wraps the constructors of the class.

This template takes a series of specializations of the ctor template
(see ctor_wrap.d), each of which describes a different constructor
that the class supports. The default constructor need not be
specified, and will always be available if the class supports it.

Bugs:
This currently does not support having multiple constructors with
the same number of arguments.
*/
struct Init(C ...) {
    alias C ctors;
    static const bool needs_shim = true;
    template call(T, shim) {
        //mixin wrapped_ctors!(param.ctors) Ctors;
        static void call() {
            wrapped_class_type!(T).tp_init =
                //&Ctors.init_func;
                &wrapped_ctors!(shim, C).init_func;
        }
    }
    template shim_impl(uint i, uint c=0) {
        static if (c < ctors.length) {
            const char[] shim_impl = 
                "    this(ParameterTypeTuple!(__pyd_c"~ToString!(i)~"["~ToString!(c)~"]) t) {\n"
                "        super(t);\n"
                "    }\n" ~ shim_impl!(i, c+1);
        } else {
            const char[] shim_impl =
                "    static if (is(typeof(new T))) {\n"
                "        this() { super(); }\n"
                "    }\n";
        }
    }
    template shim(uint i) {
        const char[] shim =
            "    alias Params["~ToString!(i)~"] __pyd_p"~ToString!(i)~";\n"
            "    alias __pyd_p"~ToString!(i)~".ctors __pyd_c"~ToString!(i)~";\n"~
            shim_impl!(i);
    }
}

// Iteration wrapping support requires StackThreads
version(Pyd_with_StackThreads) {

/**
Allows selection of alternate opApply overloads. iter_t should be
the type of the delegate in the opApply function that the user wants
to be the default.
*/
struct Iter(iter_t) {
    static const bool needs_shim = false;
    alias iter_t iterator_t;
    static void call(T) () {
        PydStackContext_Ready();
        // This strange bit of hackery is needed since we operate on pointer-
        // to-struct types, rather than just struct types.
        static if (is(T S : S*) && is(S == struct)) {
            wrapped_class_type!(T).tp_iter = &wrapped_iter!(T, S.opApply, int function(iter_t)).iter;
        } else {
            wrapped_class_type!(T).tp_iter = &wrapped_iter!(T, T.opApply, int function(iter_t)).iter;
        }
    }
}

/**
Exposes alternate iteration methods, originally intended for use with
D's delegate-as-iterator features, as methods returning a Python
iterator.
*/
struct AltIter(alias fn, string name = symbolnameof!(fn), iter_t = ParameterTypeTuple!(fn)[0]) {
    static const bool needs_shim = false;
    static void call(T) () {
        static PyMethodDef empty = { null, null, 0, null };
        alias wrapped_method_list!(T) list;
        PydStackContext_Ready();
        list[length-1].ml_name = name ~ \0;
        list[length-1].ml_meth = cast(PyCFunction)&wrapped_iter!(T, fn, int function(iter_t)).iter;
        list[length-1].ml_flags = METH_VARARGS;
        list[length-1].ml_doc = "";//(docstring ~ \0).ptr;
        list ~= empty;
        // It's possible that appending the empty item invalidated the
        // pointer in the type struct, so we renew it here.
        wrapped_class_type!(T).tp_methods = list;
    }
}

} /*Pyd_with_StackThreads*/

void wrap_class(T, Params...) (string docstring="", string modulename="") {
    _wrap_class!(T, symbolnameof!(T), Params).wrap_class(docstring, modulename);
}
/+
template _wrap_class(T, Params...) {
    mixin _wrap_class!(T, symbolnameof!(T), Params);
}
+/
//import std.stdio;
template _wrap_class(_T, string name, Params...) {
    static if (is(_T == class)) {
        pragma(msg, "wrap_class: " ~ name);
        alias pyd.make_wrapper.make_wrapper!(_T, Params).wrapper shim_class;
        //alias W.wrapper shim_class;
        alias _T T;
//    } else static if (is(_T == interface)) {
//        pragma(msg, "wrap_interface: " ~ name);
//        alias make_wrapper!(_T, Params).wrapper shim_class;
//        alias _T T;
    } else {
        pragma(msg, "wrap_struct: '" ~ name ~ "'");
        alias void shim_class;
        alias _T* T;
    }
void wrap_class(string docstring="", string modulename="") {
    pragma(msg, "shim.mangleof: " ~ shim_class.mangleof);
    alias wrapped_class_type!(T) type;
    //writefln("entering wrap_class for %s", typeid(T));
    //pragma(msg, "wrap_class, T is " ~ prettytypeof!(T));

    //Params params;
    //writefln("before params: tp_init is %s", type.tp_init);
    foreach (param; Params) {
        static if (param.needs_shim) {
            //mixin param.call!(T) PCall;
            param.call!(T, shim_class)();
        } else {
            param.call!(T)();
        }
    }
    //writefln("after params: tp_init is %s", type.tp_init);

    assert(Pyd_Module_p(modulename) !is null, "Must initialize module before wrapping classes.");
    string module_name = toString(python.PyModule_GetName(Pyd_Module_p(modulename)));

    //////////////////
    // Basic values //
    //////////////////
    type.ob_type      = python.PyType_Type_p();
    type.tp_basicsize = (wrapped_class_object!(T)).sizeof;
    type.tp_doc       = (docstring ~ \0).ptr;
    type.tp_flags     = python.Py_TPFLAGS_DEFAULT | python.Py_TPFLAGS_BASETYPE;
    //type.tp_repr      = &wrapped_repr!(T).repr;
    type.tp_methods   = wrapped_method_list!(T).ptr;
    type.tp_name      = (module_name ~ "." ~ name ~ \0).ptr;

    /////////////////
    // Inheritance //
    /////////////////
    // Inherit classes from their wrapped superclass.
    static if (is(T B == super)) {
        foreach (C; B) {
            static if (is(C == class) && !is(C == Object)) {
                if (is_wrapped!(C)) {
                    type.tp_base = &wrapped_class_type!(C);
                }
            }
        }
    }

    ////////////////////////
    // Operator overloads //
    ////////////////////////
    // Numerical operator overloads
    if (pyd.op_wrap.wrapped_class_as_number!(T) != python.PyNumberMethods.init) {
        type.tp_as_number = &pyd.op_wrap.wrapped_class_as_number!(T);
    }
    // Sequence operator overloads
    if (pyd.op_wrap.wrapped_class_as_sequence!(T) != python.PySequenceMethods.init) {
        type.tp_as_sequence = &pyd.op_wrap.wrapped_class_as_sequence!(T);
    }
    // Mapping operator overloads
    if (pyd.op_wrap.wrapped_class_as_mapping!(T) != python.PyMappingMethods.init) {
        type.tp_as_mapping = &pyd.op_wrap.wrapped_class_as_mapping!(T);
    }

    // Standard operator overloads
    // opApply
    version(Pyd_with_StackThreads) {
        static if (is(typeof(&T.opApply))) {
            if (type.tp_iter is null) {
                PydStackContext_Ready();
                type.tp_iter = &wrapped_iter!(T, T.opApply).iter;
            }
        }
    }
    // opCmp
    static if (is(typeof(&T.opCmp))) {
        type.tp_compare = &pyd.op_wrap.opcmp_wrap!(T).func;
    }
    // opCall
    static if (is(typeof(&T.opCall))) {
        type.tp_call = cast(ternaryfunc)&method_wrap!(T, T.opCall, typeof(&T.opCall)).func;
    }

    //////////////////////////
    // Constructor wrapping //
    //////////////////////////
    // If a ctor wasn't supplied, try the default.
    // If the default ctor isn't available, and no ctors were supplied,
    // then this class cannot be instantiated from Python.
    // (Structs always use the default ctor.)
    static if (is(typeof(new T))) {
        if (type.tp_init is null) {
            static if (is(T == class)) {
                type.tp_init = &wrapped_init!(shim_class).init;
            } else {
                type.tp_init = &wrapped_struct_init!(T).init;
            }
        }
    }
    //writefln("after default check: tp_init is %s", type.tp_init);

    //////////////////
    // Finalization //
    //////////////////
    if (PyType_Ready(&type) < 0) {
        throw new Exception("Couldn't ready wrapped type!");
    }
    //writefln("after Ready: tp_init is %s", type.tp_init);
    python.Py_INCREF(cast(PyObject*)&type);
    python.PyModule_AddObject(Pyd_Module_p(modulename), (name~\0).ptr, cast(PyObject*)&type);

    is_wrapped!(T) = true;
    static if (is(T == class)) {
        is_wrapped!(shim_class) = true;
        wrapped_classes[T.classinfo] = &type;
        wrapped_classes[shim_class.classinfo] = &type;
    }
    //writefln("leaving wrap_class for %s", typeid(T));
}
}
////////////////
// DOCSTRINGS //
////////////////

struct Docstring {
    char[] name, doc;
}

void docstrings(T=void)(Docstring[] docs...) {
    static if (is(T == void)) {
        
    }
}

///////////////////////
// PYD API FUNCTIONS //
///////////////////////

// If the passed D reference has an existing Python object, return a borrowed
// reference to it. Otherwise, return null.
PyObject* get_existing_reference(T) (T t) {
    static if (is(T == class)) {
        PyObject** obj_p = cast(void*)t in wrapped_gc_objects;
        if (obj_p) return *obj_p;
        else return null;
    } else {
        PyObject** obj_p = t in wrapped_gc_references!(T);
        if (obj_p) return *obj_p;
        else return null;
    }
}

// Drop the passed D reference from the pool of held references.
void drop_reference(T) (T t) {
    static if (is(T == class)) {
        wrapped_gc_objects.remove(cast(void*)t);
    } else {
        wrapped_gc_references!(T).remove(t);
    }
}

// Add the passed D reference to the pool of held references.
void add_reference(T) (T t, PyObject* o) {
    static if (is(T == class)) {
        wrapped_gc_objects[cast(void*)t] = o;
    } else {
        wrapped_gc_references!(T)[t] = o;
    }
}

PyObject* WrapPyObject_FromObject(T) (T t) {
    return WrapPyObject_FromTypeAndObject(&wrapped_class_type!(T), t);
}

/**
 * Returns a new Python object of a wrapped type.
 */
PyObject* WrapPyObject_FromTypeAndObject(T) (PyTypeObject* type, T t) {
    //alias wrapped_class_object!(T) wrapped_object;
    //alias wrapped_class_type!(T) type;
    if (is_wrapped!(T)) {
        // If this object is already wrapped, get the existing object.
        PyObject* obj_p = get_existing_reference(t);
        if (obj_p) {
            Py_INCREF(obj_p);
            return obj_p;
        }
        // Otherwise, allocate a new object
        PyObject* obj = type.tp_new(type, null, null);
        // Set the contained instance
        WrapPyObject_SetObj(obj, t);
        return obj;
    } else {
        PyErr_SetString(PyExc_RuntimeError, ("Type " ~ objToStr(typeid(T)) ~ " is not wrapped by Pyd.").ptr);
        return null;
    }
}

/**
 * Returns the object contained in a Python wrapped type.
 */
T WrapPyObject_AsObject(T) (PyObject* _self) {
    alias wrapped_class_object!(T) wrapped_object;
    alias wrapped_class_type!(T) type;
    wrapped_object* self = cast(wrapped_object*)_self;
    if (!is_wrapped!(T)) {
        throw new Exception("Error extracting D object: Type " ~ objToStr(typeid(T)) ~ " is not wrapped.");
    }
    if (self is null) {
        throw new Exception("Error extracting D object: 'self' was null!");
    }
    static if (is(T == class)) {
        if (cast(Object)(self.d_obj) is null) {
            throw new Exception("Error extracting D object: Reference was not castable to Object!");
        }
        if (cast(T)cast(Object)(self.d_obj) is null) {
            throw new Exception("Error extracting D object: Object was not castable to type "~objToStr(typeid(T))~".");
        }
    }
    return self.d_obj;
}

/**
 * Sets the contained object in self to t.
 */
void WrapPyObject_SetObj(T) (PyObject* _self, T t) {
    alias wrapped_class_object!(T) obj;
    obj* self = cast(obj*)_self;
    if (t is self.d_obj) return;
    // Clean up the old object, if there is one
    if (self.d_obj !is null) {
        drop_reference(self.d_obj);
    }
    self.d_obj = t;
    // Handle the new one, if there is one
    if (t !is null) add_reference(self.d_obj, _self);
}

