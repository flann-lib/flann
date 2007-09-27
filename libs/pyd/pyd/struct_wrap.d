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
module pyd.struct_wrap;

import python;

import pyd.class_wrap;
import pyd.exception;
version(Pyd_with_StackThreads) {
    import pyd.iteration;
}
import pyd.make_object;
import pyd.lib_abstract :
    symbolnameof
;

// It is intended that all of these templates accept a pointer-to-struct type
// as a template parameter, rather than the struct type itself.

template wrapped_member(T, string name, _M=void) {
    alias wrapped_class_type!(T) type;
    alias wrapped_class_object!(T) obj;
    static if (is(_M == void)) {
        mixin("alias typeof(T."~name~") M;");
    } else {
        alias _M M;
    }
    extern(C)
    PyObject* get(PyObject* self, void* closure) {
        return exception_catcher(delegate PyObject*() {
            T t = (cast(obj*)self).d_obj;
            mixin("return _py(t."~name~");");
        });
    }

    extern(C)
    int set(PyObject* self, PyObject* value, void* closure) {
        return exception_catcher(delegate int() {
            T t = (cast(obj*)self).d_obj;
            mixin("t."~name~" = d_type!(M)(value);");
            return 0;
        });
    }
}

struct Member(string realname) {
    mixin _Member!(realname, realname, "");
}
struct Member(string realname, string docstring) {
    mixin _Member!(realname, realname, docstring);
}
struct Member(string realname, string name, string docstring) {
    mixin _Member!(realname, name, docstring);
}
template _Member(string realname, string name, string docstring) {
    static const bool needs_shim = false;
    static void call(T) () {
        pragma(msg, "struct.member: " ~ name);
        static PyGetSetDef empty = {null, null, null, null, null};
        alias wrapped_prop_list!(T) list;
        list[length-1].name = (name ~ \0).ptr;
        list[length-1].get = &wrapped_member!(T, realname).get;
        list[length-1].set = &wrapped_member!(T, realname).set;
        list[length-1].doc = (docstring~\0).ptr;
        list[length-1].closure = null;
        list ~= empty;
        wrapped_class_type!(T).tp_getset = list.ptr;
    }
}

alias wrap_class wrap_struct;

