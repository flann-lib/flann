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
module pyd.pydobject;

//private import std.c.stdio;
import python;
import pyd.exception;
import pyd.make_object;
//import std.string;

/**
 * Wrapper class for a Python/C API PyObject.
 *
 * Nearly all of these member functions may throw a PythonException if the
 * underlying Python API raises a Python exception.
 *
 * Authors: $(LINK2 mailto:kirklin.mcdonald@gmail.com, Kirk McDonald)
 * Date: June 18, 2006
 * See_Also:
 *     $(LINK2 http://docs.python.org/api/api.html, The Python/C API)
 */
class PydObject {
protected:
    PyObject* m_ptr;
public:
    /**
     * Wrap around a passed PyObject*.
     * Params:
     *      o = The PyObject to wrap.
     *      borrowed = Whether o is a _borrowed reference. Instances
     *                 of PydObject always own their references.
     *                 Therefore, Py_INCREF will be called if borrowed is
     *                 $(D_KEYWORD true).
     */
    this(PyObject* o, bool borrowed=false) {
        if (o is null) handle_exception();
        // PydObject always owns its references
        if (borrowed) Py_INCREF(o);
        m_ptr = o;
    }

    /// The default constructor constructs an instance of the Py_None PydObject.
    this() { this(Py_None, true); }

    /// Destructor. Calls Py_DECREF on owned PyObject reference.
    ~this() {
        Py_DECREF(m_ptr);
    }

    /**
     * Returns a borrowed reference to the PyObject.
     */
    PyObject* ptr() { return m_ptr; }
    
    /*
     * Prints PyObject to a C FILE* object.
     * Params:
     *      fp = The file object to _print to. std.c.stdio.stdout by default.
     *      raw = If $(D_KEYWORD true), prints the "str" representation of the
     *            PydObject, and uses the "repr" otherwise. Defaults to
     *            $(D_KEYWORD false).
     * Bugs: This does not seem to work, raising an AccessViolation. Meh.
     *       Use toString.
     */
    /+
    void print(FILE* fp=stdout, bool raw=false) {
        if (PyObject_Print(m_ptr, fp, raw ? Py_PRINT_RAW : 0) == -1)
            handle_exception();
    }
    +/

    /// Same as _hasattr(this, attr_name) in Python.
    bool hasattr(char[] attr_name) {
        return PyObject_HasAttrString(m_ptr, (attr_name ~ \0).ptr) == 1;
    }

    /// Same as _hasattr(this, attr_name) in Python.
    bool hasattr(PydObject attr_name) {
        return PyObject_HasAttr(m_ptr, attr_name.m_ptr) == 1;
    }

    /// Same as _getattr(this, attr_name) in Python.
    PydObject getattr(char[] attr_name) {
        return new PydObject(PyObject_GetAttrString(m_ptr, (attr_name ~ \0).ptr));
    }

    /// Same as _getattr(this, attr_name) in Python.
    PydObject getattr(PydObject attr_name) {
        return new PydObject(PyObject_GetAttr(m_ptr, attr_name.m_ptr));
    }

    /**
     * Same as _setattr(this, attr_name, v) in Python.
     */
    void setattr(char[] attr_name, PydObject v) {
        if (PyObject_SetAttrString(m_ptr, (attr_name ~ \0).ptr, v.m_ptr) == -1)
            handle_exception();
    }

    /**
     * Same as _setattr(this, attr_name, v) in Python.
     */
    void setattr(PydObject attr_name, PydObject v) {
        if (PyObject_SetAttr(m_ptr, attr_name.m_ptr, v.m_ptr) == -1)
            handle_exception();
    }

    /**
     * Same as del this.attr_name in Python.
     */
    void delattr(char[] attr_name) {
        if (PyObject_DelAttrString(m_ptr, (attr_name ~ \0).ptr) == -1)
            handle_exception();
    }

    /**
     * Same as del this.attr_name in Python.
     */
    void delattr(PydObject attr_name) {
        if (PyObject_DelAttr(m_ptr, attr_name.m_ptr) == -1)
            handle_exception();
    }

    /**
     * Exposes Python object comparison to D. Same as cmp(this, rhs) in Python.
     */
    int opCmp(PydObject rhs) {
        // This function happily maps exactly to opCmp
        int res = PyObject_Compare(m_ptr, rhs.m_ptr);
        // Check for possible error
        handle_exception();
        return res;
    }

    /**
     * Exposes Python object equality check to D.
     */
    bool opEquals(PydObject rhs) {
        int res = PyObject_Compare(m_ptr, rhs.m_ptr);
        handle_exception();
        return res == 0;
    }
    
    /// Same as _repr(this) in Python.
    PydObject repr() {
        return new PydObject(PyObject_Repr(m_ptr));
    }

    /// Same as _str(this) in Python.
    PydObject str() {
        return new PydObject(PyObject_Str(m_ptr));
    }
    version (Tango) {
        /// Allows PydObject to be formatted.
        char[] toUtf8() {
            return d_type!(char[])(m_ptr);
        }
    } else {
        /// Allows use of PydObject in writef via %s
        char[] toString() {
            return d_type!(char[])(m_ptr);
        }
    }
    
    /// Same as _unicode(this) in Python.
    PydObject unicode() {
        return new PydObject(PyObject_Unicode(m_ptr));
    }

    /// Same as isinstance(this, cls) in Python.
    bool isInstance(PydObject cls) {
        int res = PyObject_IsInstance(m_ptr, cls.m_ptr);
        if (res == -1) handle_exception();
        return res == 1;
    }

    /// Same as issubclass(this, cls) in Python. Only works if this is a class.
    bool isSubclass(PydObject cls) {
        int res = PyObject_IsSubclass(m_ptr, cls.m_ptr);
        if (res == -1) handle_exception();
        return res == 1;
    }

    /// Same as _callable(this) in Python.
    bool callable() {
        return PyCallable_Check(m_ptr) == 1;
    }
    
    /**
     * Calls the PydObject with the PyTuple args.
     * Params:
     *      args = Should be a PydTuple of the arguments to pass. Omit to
     *             call with no arguments.
     * Returns: Whatever the function PydObject returns.
     */
    PydObject unpackCall(PydObject args=null) {
        return new PydObject(PyObject_CallObject(m_ptr, args is null ? null : args.m_ptr));
    }
    
    /**
     * Calls the PydObject with positional and keyword arguments.
     * Params:
     *      args = Positional arguments. Should be a PydTuple. Pass an empty
     *             PydTuple for no positional arguments.
     *      kw = Keyword arguments. Should be a PydDict.
     * Returns: Whatever the function PydObject returns.
     */
    PydObject unpackCall(PydObject args, PydObject kw) {
        return new PydObject(PyObject_Call(m_ptr, args.m_ptr, kw.m_ptr));
    }

    /**
     * Calls the PydObject with any convertible D items.
     */
    PydObject opCall(T ...) (T t) {
        PyObject* tuple = PyTuple_FromItems(t);
        if (tuple is null) handle_exception();
        PyObject* result = PyObject_CallObject(m_ptr, tuple);
        Py_DECREF(tuple);
        if (result is null) handle_exception();
        return new PydObject(result);
    }

    /**
     *
     */
    PydObject methodUnpack(char[] name, PydObject args=null) {
        // Get the method PydObject
        PyObject* m = PyObject_GetAttrString(m_ptr, (name ~ \0).ptr);
        PyObject* result;
        // If this method doesn't exist (or other error), throw exception
        if (m is null) handle_exception();
        // Call the method, and decrement the refcounts on the temporaries.
        result = PyObject_CallObject(m, args is null ? null : args.m_ptr);
        Py_DECREF(m);
        // Return the result.
        return new PydObject(result);
    }

    PydObject methodUnpack(char[] name, PydObject args, PydObject kw) {
        // Get the method PydObject
        PyObject* m = PyObject_GetAttrString(m_ptr, (name ~ \0).ptr);
        PyObject* result;
        // If this method doesn't exist (or other error), throw exception.
        if (m is null) handle_exception();
        // Call the method, and decrement the refcounts on the temporaries.
        result = PyObject_Call(m, args.m_ptr, kw.m_ptr);
        Py_DECREF(m);
        // Return the result.
        return new PydObject(result);
    }

    /**
     * Calls a method of the object with any convertible D items.
     */
    PydObject method(T ...) (char[] name, T t) {
        PyObject* mthd = PyObject_GetAttrString(m_ptr, (name ~ \0).ptr);
        if (mthd is null) handle_exception();
        PyObject* tuple = PyTuple_FromItems(t);
        if (tuple is null) {
            Py_DECREF(mthd);
            handle_exception();
        }
        PyObject* result = PyObject_CallObject(mthd, tuple);
        Py_DECREF(mthd);
        Py_DECREF(tuple);
        if (result is null) handle_exception();
        return new PydObject(result);
    }

    /// Same as _hash(this) in Python.
    int hash() {
        int res = PyObject_Hash(m_ptr);
        if (res == -1) handle_exception();
        return res;
    }

    T toDItem(T)() {
        return d_type!(T)(m_ptr);
    }

    /// Same as "not not this" in Python.
    bool toBool() {
        return d_type!(bool)(m_ptr);
    }

    /// Same as "_not this" in Python.
    bool not() {
        int res = PyObject_Not(m_ptr);
        if (res == -1) handle_exception();
        return res == 1;
    }

    /**
     * Gets the _type of this PydObject. Same as _type(this) in Python.
     * Returns: The _type PydObject of this PydObject.
     */
    PydObject type() {
        return new PydObject(PyObject_Type(m_ptr));
    }

    /**
     * The _length of this PydObject. Same as _len(this) in Python.
     */
    int length() {
        int res = PyObject_Length(m_ptr);
        if (res == -1) handle_exception();
        return res;
    }
    /// Same as length()
    int size() { return length(); }

    /// Same as _dir(this) in Python.
    PydObject dir() {
        return new PydObject(PyObject_Dir(m_ptr));
    }

    //----------
    // Indexing
    //----------
    /// Equivalent to o[_key] in Python.
    PydObject opIndex(PydObject key) {
        return new PydObject(PyObject_GetItem(m_ptr, key.m_ptr));
    }
    /**
     * Equivalent to o['_key'] in Python; usually only makes sense for
     * mappings.
     */
    PydObject opIndex(char[] key) {
        return new PydObject(PyMapping_GetItemString(m_ptr, (key ~ \0).ptr));
    }
    /// Equivalent to o[_i] in Python; usually only makes sense for sequences.
    PydObject opIndex(int i) {
        return new PydObject(PySequence_GetItem(m_ptr, i));
    }

    /// Equivalent to o[_key] = _value in Python.
    void opIndexAssign(PydObject value, PydObject key) {
        if (PyObject_SetItem(m_ptr, key.m_ptr, value.m_ptr) == -1)
            handle_exception();
    }
    /**
     * Equivalent to o['_key'] = _value in Python. Usually only makes sense for
     * mappings.
     */
    void opIndexAssign(PydObject value, char[] key) {
        if (PyMapping_SetItemString(m_ptr, (key ~ \0).ptr, value.m_ptr) == -1)
            handle_exception();
    }
    /**
     * Equivalent to o[_i] = _value in Python. Usually only makes sense for
     * sequences.
     */
    void opIndexAssign(PydObject value, int i) {
        if (PySequence_SetItem(m_ptr, i, value.m_ptr) == -1)
            handle_exception();
    }

    /// Equivalent to del o[_key] in Python.
    void delItem(PydObject key) {
        if (PyObject_DelItem(m_ptr, key.m_ptr) == -1)
            handle_exception();
    }
    /**
     * Equivalent to del o['_key'] in Python. Usually only makes sense for
     * mappings.
     */
    void delItem(char[] key) {
        if (PyMapping_DelItemString(m_ptr, (key ~ \0).ptr) == -1)
            handle_exception();
    }
    /**
     * Equivalent to del o[_i] in Python. Usually only makes sense for
     * sequences.
     */
    void delItem(int i) {
        if (PySequence_DelItem(m_ptr, i) == -1)
            handle_exception();
    }

    //---------
    // Slicing
    //---------
    /// Equivalent to o[_i1:_i2] in Python.
    PydObject opSlice(int i1, int i2) {
        return new PydObject(PySequence_GetSlice(m_ptr, i1, i2));
    }
    /// Equivalent to o[:] in Python.
    PydObject opSlice() {
        return this.opSlice(0, this.length());
    }
    /// Equivalent to o[_i1:_i2] = _v in Python.
    void opSliceAssign(PydObject v, int i1, int i2) {
        if (PySequence_SetSlice(m_ptr, i1, i1, v.m_ptr) == -1)
            handle_exception();
    }
    /// Equivalent to o[:] = _v in Python.
    void opSliceAssign(PydObject v) {
        this.opSliceAssign(v, 0, this.length());
    }
    /// Equivalent to del o[_i1:_i2] in Python.
    void delSlice(int i1, int i2) {
        if (PySequence_DelSlice(m_ptr, i1, i2) == -1)
            handle_exception();
    }
    /// Equivalent to del o[:] in Python.
    void delSlice() {
        this.delSlice(0, this.length());
    }

    //-----------
    // Iteration
    //-----------

    /**
     * Iterates over the items in a collection, be they the items in a
     * sequence, keys in a dictionary, or some other iteration defined for the
     * PydObject's type.
     */
    int opApply(int delegate(inout PydObject) dg) {
        PyObject* iterator = PyObject_GetIter(m_ptr);
        PyObject* item;
        int result = 0;
        PydObject o;

        if (iterator == null) {
            handle_exception();
        }

        item = PyIter_Next(iterator);
        while (item) {
            o = new PydObject(item);
            result = dg(o);
            Py_DECREF(item);
            if (result) break;
            item = PyIter_Next(iterator);
        }
        Py_DECREF(iterator);

        // Just in case an exception occured
        handle_exception();

        return result;
    }

    /**
     * Iterate over (key, value) pairs in a dictionary. If the PydObject is not
     * a dict, this simply does nothing. (It iterates over no items.) You
     * should not attempt to modify the dictionary while iterating through it,
     * with the exception of modifying values. Adding or removing items while
     * iterating through it is an especially bad idea.
     */
    int opApply(int delegate(inout PydObject, inout PydObject) dg) {
        PyObject* key, value;
        version(Python_2_5_Or_Later) {
            Py_ssize_t pos = 0;
        } else {
            int pos = 0;
        }
        int result = 0;
        PydObject k, v;

        while (PyDict_Next(m_ptr, &pos, &key, &value)) {
            k = new PydObject(key, true);
            v = new PydObject(value, true);
            result = dg(k, v);
            if (result) break;
        }

        return result;
    }

    //------------
    // Arithmetic
    //------------
    ///
    PydObject opAdd(PydObject o) {
        return new PydObject(PyNumber_Add(m_ptr, o.m_ptr));
    }
    ///
    PydObject opSub(PydObject o) {
        return new PydObject(PyNumber_Subtract(m_ptr, o.m_ptr));
    }
    ///
    PydObject opMul(PydObject o) {
        return new PydObject(PyNumber_Multiply(m_ptr, o.m_ptr));
    }
    /// Sequence repetition
    PydObject opMul(int count) {
        return new PydObject(PySequence_Repeat(m_ptr, count));
    }
    ///
    PydObject opDiv(PydObject o) {
        return new PydObject(PyNumber_Divide(m_ptr, o.m_ptr));
    }
    ///
    PydObject floorDiv(PydObject o) {
        return new PydObject(PyNumber_FloorDivide(m_ptr, o.m_ptr));
    }
    ///
    PydObject opMod(PydObject o) {
        return new PydObject(PyNumber_Remainder(m_ptr, o.m_ptr));
    }
    ///
    PydObject divmod(PydObject o) {
        return new PydObject(PyNumber_Divmod(m_ptr, o.m_ptr));
    }
    ///
    PydObject pow(PydObject o1, PydObject o2=null) {
        return new PydObject(PyNumber_Power(m_ptr, o1.m_ptr, (o2 is null) ? Py_None : o2.m_ptr));
    }
    ///
    PydObject opPos() {
        return new PydObject(PyNumber_Positive(m_ptr));
    }
    ///
    PydObject opNeg() {
        return new PydObject(PyNumber_Negative(m_ptr));
    }
    ///
    PydObject abs() {
        return new PydObject(PyNumber_Absolute(m_ptr));
    }
    ///
    PydObject opCom() {
        return new PydObject(PyNumber_Invert(m_ptr));
    }
    ///
    PydObject opShl(PydObject o) {
        return new PydObject(PyNumber_Lshift(m_ptr, o.m_ptr));
    }
    ///
    PydObject opShr(PydObject o) {
        return new PydObject(PyNumber_Rshift(m_ptr, o.m_ptr));
    }
    ///
    PydObject opAnd(PydObject o) {
        return new PydObject(PyNumber_And(m_ptr, o.m_ptr));
    }
    ///
    PydObject opXor(PydObject o) {
        return new PydObject(PyNumber_Xor(m_ptr, o.m_ptr));
    }
    ///
    PydObject opOr(PydObject o) {
        return new PydObject(PyNumber_Or(m_ptr, o.m_ptr));
    }

    //---------------------
    // In-place arithmetic
    //---------------------
    private extern(C)
    alias PyObject* function(PyObject*, PyObject*) op_t;

    // A useful wrapper for most of the in-place operators
    private PydObject
    inplace(op_t op, PydObject rhs) {
        if (PyType_HasFeature(m_ptr.ob_type, Py_TPFLAGS_HAVE_INPLACEOPS)) {
            op(m_ptr, rhs.m_ptr);
            handle_exception();
        } else {
            PyObject* result = op(m_ptr, rhs.m_ptr);
            if (result is null) handle_exception();
            Py_DECREF(m_ptr);
            m_ptr = result;
        }
        return this;
    }
    ///
    PydObject opAddAssign(PydObject o) {
        return inplace(&PyNumber_InPlaceAdd, o);
    }
    ///
    PydObject opSubAssign(PydObject o) {
        return inplace(&PyNumber_InPlaceSubtract, o);
    }
    ///
    PydObject opMulAssign(PydObject o) {
        return inplace(&PyNumber_InPlaceMultiply, o);
    }
    /// In-place sequence repetition
    PydObject opMulAssign(int count) {
        if (PyType_HasFeature(m_ptr.ob_type, Py_TPFLAGS_HAVE_INPLACEOPS)) {
            PySequence_InPlaceRepeat(m_ptr, count);
            handle_exception();
        } else {
            PyObject* result = PySequence_InPlaceRepeat(m_ptr, count);
            if (result is null) handle_exception();
            Py_DECREF(m_ptr);
            m_ptr = result;
        }
        return this;
    }
    ///
    PydObject opDivAssign(PydObject o) {
        return inplace(&PyNumber_InPlaceDivide, o);
    }
    ///
    PydObject floorDivAssign(PydObject o) {
        return inplace(&PyNumber_InPlaceFloorDivide, o);
    }
    ///
    PydObject opModAssign(PydObject o) {
        return inplace(&PyNumber_InPlaceRemainder, o);
    }
    ///
    PydObject powAssign(PydObject o1, PydObject o2=null) {
        if (PyType_HasFeature(m_ptr.ob_type, Py_TPFLAGS_HAVE_INPLACEOPS)) {
            PyNumber_InPlacePower(m_ptr, o1.m_ptr, (o2 is null) ? Py_None : o2.m_ptr);
            handle_exception();
        } else {
            PyObject* result = PyNumber_InPlacePower(m_ptr, o1.m_ptr, (o2 is null) ? Py_None : o2.m_ptr);
            if (result is null) handle_exception();
            Py_DECREF(m_ptr);
            m_ptr = result;
        }
        return this;
    }
    ///
    PydObject opShlAssign(PydObject o) {
        return inplace(&PyNumber_InPlaceLshift, o);
    }
    ///
    PydObject opShrAssign(PydObject o) {
        return inplace(&PyNumber_InPlaceRshift, o);
    }
    ///
    PydObject opAndAssign(PydObject o) {
        return inplace(&PyNumber_InPlaceAnd, o);
    }
    ///
    PydObject opXorAssign(PydObject o) {
        return inplace(&PyNumber_InPlaceXor, o);
    }
    ///
    PydObject opOrAssign(PydObject o) {
        return inplace(&PyNumber_InPlaceOr, o);
    }

    //-----------------
    // Type conversion
    //-----------------
    ///
    PydObject asInt() {
        return new PydObject(PyNumber_Int(m_ptr));
    }
    ///
    PydObject asLong() {
        return new PydObject(PyNumber_Long(m_ptr));
    }
    ///
    PydObject asFloat() {
        return new PydObject(PyNumber_Float(m_ptr));
    }
    ///
    C_long toLong() {
        return d_type!(C_long)(m_ptr);
    }
    ///
    C_longlong toLongLong() {
        return d_type!(C_longlong)(m_ptr);
    }
    ///
    double toDouble() {
        return d_type!(double)(m_ptr);
    }
    ///
    cdouble toComplex() {
        return d_type!(cdouble)(m_ptr);
    }
    
    //------------------
    // Sequence methods
    //------------------

    /// Sequence concatenation
    PydObject opCat(PydObject o) {
        return new PydObject(PySequence_Concat(m_ptr, o.m_ptr));
    }
    /// In-place sequence concatenation
    PydObject opCatAssign(PydObject o) {
        return inplace(&PySequence_InPlaceConcat, o);
    }
    ///
    int count(PydObject v) {
        int result = PySequence_Count(m_ptr, v.m_ptr);
        if (result == -1) handle_exception();
        return result;
    }
    ///
    int index(PydObject v) {
        int result = PySequence_Index(m_ptr, v.m_ptr);
        if (result == -1) handle_exception();
        return result;
    }
    /// Converts any iterable PydObject to a list
    PydObject asList() {
        return new PydObject(PySequence_List(m_ptr));
    }
    /// Converts any iterable PydObject to a tuple
    PydObject asTuple() {
        return new PydObject(PySequence_Tuple(m_ptr));
    }
    /+
    wchar[] toWString() {
        wchar[] temp;
        if (PyUnicode_Check(m_ptr)) {
            temp.length = PyUnicode_GetSize(m_ptr);
            if (PyUnicode_AsWideChar(cast(PyUnicodeObject*)m_ptr, temp, temp.length) == -1)
                handle_exception();
            return temp;
        } else {
            PyErr_SetString(PyExc_RuntimeError, "Cannot convert non-PyUnicode PydObject to wchar[].");
            handle_exception();
        }
    }
    // Added by list:
    void insert(int i, PydObject item) { assert(false); }
    void append(PydObject item) { assert(false); }
    void sort() { assert(false); }
    void reverse() { assert(false); }
    +/

    //-----------------
    // Mapping methods
    //-----------------
    /// Same as "v in this" in Python.
    bool opIn_r(PydObject v) {
        int result = PySequence_Contains(m_ptr, v.m_ptr);
        if (result == -1) handle_exception();
        return result == 1;
    }
    /// Same as opIn_r
    bool hasKey(PydObject key) { return this.opIn_r(key); }
    /// Same as "'v' in this" in Python.
    bool opIn_r(char[] key) {
        return this.hasKey(key);
    }
    /// Same as opIn_r
    bool hasKey(char[] key) {
        int result = PyMapping_HasKeyString(m_ptr, (key ~ \0).ptr);
        if (result == -1) handle_exception();
        return result == 1;
    }
    ///
    PydObject keys() {
        return new PydObject(PyMapping_Keys(m_ptr));
    }
    ///
    PydObject values() {
        return new PydObject(PyMapping_Values(m_ptr));
    }
    ///
    PydObject items() {
        return new PydObject(PyMapping_Items(m_ptr));
    }
    /+
    // Added by dict
    void clear() { assert(false); }
    PydObject copy() { assert(false); }
    void update(PydObject o, bool over_ride=true) { assert(false); }
    +/
}

