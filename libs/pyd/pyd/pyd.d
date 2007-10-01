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
 * This module simply publicly imports all of the other components of the Pyd
 * package, making them all available from a single point.
 */
module pyd.pyd;

public {
    import pyd.class_wrap;
    import pyd.def;
    import pyd.exception;
    import pyd.func_wrap;
    import pyd.make_object;
    import pyd.pydobject;
    import pyd.struct_wrap;

    // Importing these is only needed as a workaround to bug #311
    import pyd.ctor_wrap;
    import pyd.dg_convert;
    import pyd.exception;
    import pyd.func_wrap;
    version(Pyd_with_StackThreads) {
        import pyd.iteration;
    }
    import pyd.make_wrapper;
}

