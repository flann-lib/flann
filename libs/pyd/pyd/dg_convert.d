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
 * This module used to contain some more or less dirty hacks for converting
 * between function and delegate types. As of DMD 0.174, the language has
 * built-in support for hacking apart delegates like this. Hooray!
 */
module pyd.dg_convert;

import pyd.lib_abstract :
    ParameterTypeTuple,
    ReturnType
;
//import std.traits;

template fn_to_dgT(Fn) {
    alias ParameterTypeTuple!(Fn) T;
    alias ReturnType!(Fn) Ret;

    alias Ret delegate(T) type;
}

/**
 * This template converts a function type into an equivalent delegate type.
 */
template fn_to_dg(Fn) {
    alias fn_to_dgT!(Fn).type fn_to_dg;
}

// Breaking out the old hack again for GDC support...
struct dg_struct {
    void* ptr;
    void* funcptr;
}

union dg_hack(T) {
    dg_struct fake_dg;
    T real_dg;
}

/**
 * This template function converts a pointer to a member function into a
 * delegate.
 */
fn_to_dg!(Fn) dg_wrapper(T, Fn) (T t, Fn fn) {
    //fn_to_dg!(Fn) dg;
    //dg.ptr = t;
    //dg.funcptr = fn;

    //return dg;

    dg_hack!(fn_to_dg!(Fn)) dg;
    dg.fake_dg.ptr = cast(void*)t;
    dg.fake_dg.funcptr = fn;
    return dg.real_dg;
}

