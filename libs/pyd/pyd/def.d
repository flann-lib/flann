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
module pyd.def;

import python;

import pyd.func_wrap;
import pyd.lib_abstract :
    symbolnameof,
    minArgs
;
//import meta.Default;
//import meta.Nameof;

private PyMethodDef module_global_methods[] = [
    { null, null, 0, null }
];

private PyMethodDef[][string] module_methods;
private PyObject*[string] pyd_modules;

private void ready_module_methods(string modulename) {
    PyMethodDef empty;
    if (!(modulename in module_methods)) {
        module_methods[modulename] = (PyMethodDef[]).init;
        module_methods[modulename] ~= empty;
    }
}

PyObject* Pyd_Module_p(string modulename="") {
    PyObject** m = modulename in pyd_modules;
    if (m is null) return null;
    else return *m;
}

/**
 * Wraps a D function, making it callable from Python.
 *
 * Params:
 *      name = The name of the function as it will appear in Python.
 *      fn   = The function to wrap.
 *      MIN_ARGS = The minimum number of arguments this function can accept.
 *                 For use with functions with default arguments. Defaults to
 *                 the maximum number of arguments this function supports.
 *      fn_t = The function type of the function to wrap. This must be
 *             specified if more than one function shares the same name,
 *             otherwise the first one defined lexically will be used.
 *
 * Examples:
 *$(D_CODE import pyd.pyd;
 *char[] foo(int i) {
 *    if (i > 10) {
 *        return "It's greater than 10!";
 *    } else {
 *        return "It's less than 10!";
 *    }
 *}
 *extern (C)
 *export void inittestdll() {
 *    _def!("foo", foo);
 *    module_init("testdll");
 *})
 * And in Python:
 *$(D_CODE >>> import testdll
 *>>> print testdll.foo(20)
 *It's greater than 10!)
 */
void def(alias fn, string name = symbolnameof!(fn), fn_t=typeof(&fn), uint MIN_ARGS = minArgs!(fn, fn_t)) (string docstring="") {
    def!("", fn, name, fn_t, MIN_ARGS)(docstring);
}

void def(string modulename, alias fn, string name = symbolnameof!(fn), fn_t=typeof(&fn), uint MIN_ARGS = minArgs!(fn, fn_t)) (string docstring) {
    pragma(msg, "def: " ~ name);
    PyMethodDef empty;
    ready_module_methods(modulename);
    PyMethodDef[]* list = &module_methods[modulename];

    (*list)[length-1].ml_name = (name ~ \0).ptr;
    (*list)[length-1].ml_meth = &function_wrap!(fn, MIN_ARGS, fn_t).func;
    (*list)[length-1].ml_flags = METH_VARARGS;
    (*list)[length-1].ml_doc = (docstring ~ \0).ptr;
    (*list) ~= empty;
}

string pyd_module_name;

/**
 * Module initialization function. Should be called after the last call to def.
 */
PyObject* module_init(string docstring="") {
    //_loadPythonSupport();
    string name = pyd_module_name;
    ready_module_methods("");
    pyd_modules[""] = Py_InitModule3((name ~ \0).ptr, module_methods[""].ptr, (docstring ~ \0).ptr);
    return pyd_modules[""];
}

/**
 * Module initialization function. Should be called after the last call to def.
 */
PyObject* add_module(string name, string docstring="") {
    ready_module_methods(name);
    pyd_modules[name] = Py_InitModule3((name ~ \0).ptr, module_methods[name].ptr, (docstring ~ \0).ptr);
    return pyd_modules[name];
}

