/*
Copyright (c) 2006 Kirk McDonald

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

// This module abstracts out all of the uses of Phobos, Tango, and meta, easing
// the ability to switch between Phobos and Tango arbitrarily.
module pyd.lib_abstract;

version (Tango) {
    import tango.stdc.string : strlen;
    import tango.text.convert.Integer : qadut;
    char[] toString(char* s) {
        return s[0 .. strlen(s)];
    }
    char[] toString(uint i) {
        char[64] tmp;
        return qadut(tmp, i);
    }

    public import tango.util.meta.Nameof : symbolnameof, prettytypeof, prettynameof;
    public import meta.Default : minArgs, ParameterTypeTuple, ReturnType;
    char[] objToStr(Object o) {
        return o.toUtf8();
    }
} else {
    string objToStr(Object o) {
        return o.toString();
    }
    version (D_Version2) {
        // D1 issues?
        template symbolnameof(alias symbol) {
            static if (is(typeof(symbol) == function)) {
                const char[] symbolnameof = (&symbol).stringof[2 .. $];
            } else {
                const char[] symbolnameof = symbol.stringof;
            }
        }
    } else {
        public import meta.Nameof : symbolnameof;
    }
    public import meta.Nameof : /*symbolnameof,*/ prettytypeof, prettynameof;

    public import std.string : toString;
    public import std.traits : ParameterTypeTuple, ReturnType;
    public import meta.Default : minArgs;
    public import std.metastrings : ToString;
}
