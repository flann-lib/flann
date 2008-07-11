/**
 * This module is a set of types and functions for converting any object (value
 * or heap) into a generic box type, allowing the user to pass that object
 * around without knowing what's in the box, and then allowing him to recover
 * the value afterwards. 
 *
 * Example:
---
// Convert the integer 45 into a box.
Box b = box(45);

// Recover the integer and cast it to real.
real r = unbox!(real)(b);
---
 *
 * That is the basic interface and will usually be all that you need to
 * understand. If it cannot unbox the object to the given type, it throws
 * UnboxException. As demonstrated, it uses implicit casts to behave in the exact
 * same way that static types behave. So for example, you can unbox from int to
 * real, but you cannot unbox from real to int: that would require an explicit
 * cast. 
 *
 * This therefore means that attempting to unbox an int as a string will throw
 * an error instead of formatting it. In general, you can call the toString method
 * on the box and receive a good result, depending upon whether std.string.format
 * accepts it. 
 *
 * Boxes can be compared to one another and they can be used as keys for
 * associative arrays. 
 *
 * There are also functions for converting to and from arrays of boxes.
 *
 * Example:
---
// Convert arguments into an array of boxes.
Box[] a = boxArray(1, 45.4, "foobar");

// Convert an array of boxes back into arguments.
TypeInfo[] arg_types;
void* arg_data;

boxArrayToArguments(a, arg_types, arg_data);

// Convert the arguments back into boxes using a
// different form of the function.
a = boxArray(arg_types, arg_data);
---
 * One use of this is to support a variadic function more easily and robustly;
 * simply call "boxArray(_arguments, _argptr)", then do whatever you need to do
 * with the array.
 *
 * Authors:
 *	Burton Radons
 * License:
 *	Public Domain
 * Macros:
 *	WIKI=Phobos/StdBoxer
 */

/* NOTE: This file has been patched from the original DMD distribution to
   work with the GDC compiler.

   Modified by David Friedman, May 2005

   This module make not work on all GCC targets due to assumptions
   about the type of va_list.
*/
module std.boxer;

private import std.format;
private import std.string;
private import std.utf;
version (GNU)
    private import std.stdarg;

 /* These functions and types allow packing objects into generic containers
  * and recovering them later.  This comes into play in a wide spectrum of
  * utilities, such as with a scripting language, or as additional user data
  * for an object.
  * 
  * Box an object by calling the box function:
  *
  *     Box x = box(4);
  *
  * Recover the value by using the unbox template:
  *
  *     int y = unbox!(int)(x);
  *
  * If it cannot unbox the object to that type, it throws UnboxException.  It will
  * use implicit casts to behave in the exact same way as D does - for
  * instance:
  *
  *     byte v;
  *     int i = v; // Implicitly cast from byte to int.
  *     int j = unbox!(int)(Box(i)); // Do the exact same thing at runtime.
  *
  * This therefore means that attempting to unbox an int as a string will
  * throw an error and not format it.  In general, you can call the toString
  * method on the box and receive a good result, depending upon whether
  * std.string.format accepts it.
  * 
  * Boxes can be compared to one another and they can be used as keys for
  * associative arrays.  Boxes of different types can be compared to one
  * another, using the same casting rules as the main type system.
  *
  * boxArray has two forms:
  *
  *     Box[] boxArray(...);
  *     Box[] boxArray(TypeInfo[] types, void* data);
  *
  * This converts an array of arguments into an array of boxes.  To convert
  * back into an array of arguments, use boxArrayToArguments:
  *
  *     void boxArrayToArguments(Box[] arguments, out TypeInfo[] types,
  *         out void[] data);
  *
  * Finally, you can discover whether unboxing as a certain type is legal by
  * using the unboxable template or method:
  *
  *     bool unboxable!(T) (Box value);
  *     bool Box.unboxable(TypeInfo T);
  */
  
/** Return the next type in an array typeinfo, or null if there is none. */
private bool isArrayTypeInfo(TypeInfo type)
{
    char[] name = type.classinfo.name;
    return name.length >= 10 && name[9] == 'A' && name != "TypeInfo_AssociativeArray";
}

/** The type class returned from Box.findTypeClass; the order of entries is important. */
private enum TypeClass
{
    Bool, /**< bool */
    Bit = Bool,	// for backwards compatibility
    Integer, /**< byte, ubyte, short, ushort, int, uint, long, ulong */
    Float, /**< float, double, real */
    Complex, /**< cfloat, cdouble, creal */
    Imaginary, /**< ifloat, idouble, ireal */
    Class, /**< Inherits from Object */
    Pointer, /**< Pointer type (T *) */
    Array, /**< Array type (T []) */
    Other, /**< Any other type, such as delegates, function pointers, struct, void... */
}

version (DigitalMars)
    version = DigitalMars_TypeInfo;
else version (GNU)
    version = DigitalMars_TypeInfo;

/**
 * Box is a generic container for objects (both value and heap), allowing the
 * user to box them in a generic form and recover them later.
 * A box object contains a value in a generic fashion, allowing it to be
 * passed from one place to another without having to know its type.  It is
 * created by calling the box function, and you can recover the value by
 * instantiating the unbox template.
 */
struct Box
{
    private TypeInfo p_type; /**< The type of the contained object. */
    
    private union
    {
        void* p_longData; /**< An array of the contained object. */
        void[8] p_shortData; /**< Data used when the object is small. */
    }

    private static TypeClass findTypeClass(TypeInfo type)
    {
        if (cast(TypeInfo_Class) type)
            return TypeClass.Class;
        if (cast(TypeInfo_Pointer) type)
            return TypeClass.Pointer;
        if (isArrayTypeInfo(type))
            return TypeClass.Array;

        version (DigitalMars_TypeInfo)
        {
            /* Depend upon the name of the base type classes. */
            if (type.classinfo.name.length != "TypeInfo_?".length)
                return TypeClass.Other;
            switch (type.classinfo.name[9])
            {
                case 'b', 'x': return TypeClass.Bool;
                case 'g', 'h', 's', 't', 'i', 'k', 'l', 'm': return TypeClass.Integer;
                case 'f', 'd', 'e': return TypeClass.Float;
                case 'q', 'r', 'c': return TypeClass.Complex;
                case 'o', 'p', 'j': return TypeClass.Imaginary;
                default: return TypeClass.Other;
            }
        }
        else
        {
            /* Use the name returned from toString, which might (but hopefully doesn't) include an allocation. */
            switch (type.toString)
            {
                case "bool": return TypeClass.Bool;
                case "byte", "ubyte", "short", "ushort", "int", "uint", "long", "ulong": return TypeClass.Integer;
                case "float", "real", "double": return TypeClass.Float;
                case "cfloat", "cdouble", "creal": return TypeClass.Complex;
                case "ifloat", "idouble", "ireal": return TypeClass.Imaginary;
                default: return TypeClass.Other;
            }
        }
	assert(0);
    }
    
    /** Return whether this value could be unboxed as the given type without throwing. */
    bool unboxable(TypeInfo test)
    {
        if (type is test)
            return true;
        
        TypeInfo_Class ca = cast(TypeInfo_Class) type, cb = cast(TypeInfo_Class) test;
        
        if (ca !is null && cb !is null)
        {
            ClassInfo ia = (*cast(Object *) data).classinfo, ib = cb.info;
            
            for ( ; ia !is null; ia = ia.base)
                if (ia is ib)
                    return true;
            return false;
        }
        
        TypeClass ta = findTypeClass(type), tb = findTypeClass(test);
        
        if (type is typeid(void*) && *cast(void**) data is null)
            return (tb == TypeClass.Class || tb == TypeClass.Pointer || tb == TypeClass.Array);
        
        if (test is typeid(void*))
            return (tb == TypeClass.Class || tb == TypeClass.Pointer || tb == TypeClass.Array);
        
        if (ta == TypeClass.Pointer && tb == TypeClass.Pointer)
            return (cast(TypeInfo_Pointer)type).next is (cast(TypeInfo_Pointer)test).next;
        
        if ((ta == tb && ta != TypeClass.Other)
        || (ta == TypeClass.Bool && tb == TypeClass.Integer)
        || (ta <= TypeClass.Integer && tb == TypeClass.Float)
        || (ta <= TypeClass.Imaginary && tb == TypeClass.Complex))
            return true;
        return false;
    }
    
    /**
     * Property for the type contained by the box.
     * This is initially null and cannot be assigned directly.
     * Returns: the type of the contained object.
     */
    TypeInfo type()
    {
        return p_type;
    }
    
    /**
     * Property for the data pointer to the value of the box.
     * This is initially null and cannot be assigned directly.
     * Returns: the data array.
     */
    void[] data()
    {
        size_t size = type.tsize();
        
        return size <= p_shortData.length ? p_shortData[0..size] : p_longData[0..size];
    }

    /**
     * Attempt to convert the boxed value into a string using std.string.format;
     * this will throw if that function cannot handle it. If the box is
     * uninitialized then this returns "".    
     */
    char[] toString()
    {
        if (type is null)
            return "<empty box>";
        
        TypeInfo[2] arguments;
        char[] string;
        void[] args = new void[(char[]).sizeof + data.length];
        char[] format = "%s";
        
        arguments[0] = typeid(char[]);
        arguments[1] = type;
        
        void putc(dchar ch)
        {
            std.utf.encode(string, ch);
        }
        
        args[0..(char[]).sizeof] = (cast(void*) &format)[0..(char[]).sizeof];
        args[(char[]).sizeof..length] = data;
	version (GNU)
	{
	    va_list dummy = void;
	    std.format.doFormatPtr(&putc, arguments, dummy, args.ptr);
	}
	else
	    std.format.doFormat(&putc, arguments, args.ptr);
        delete args;
        
        return string;
    }
    
    private bool opEqualsInternal(Box other, bool inverted)
    {
        if (type != other.type)
        {
            if (!unboxable(other.type))
            {
                if (inverted)
                    return false;
                return other.opEqualsInternal(*this, true);
            }
            
            TypeClass ta = findTypeClass(type), tb = findTypeClass(other.type);
            
            if (ta <= TypeClass.Integer && tb <= TypeClass.Integer)
            {
                char[] na = type.toString, nb = other.type.toString;
                
                if (na == "ulong" || nb == "ulong")
                    return unbox!(ulong)(*this) == unbox!(ulong)(other);
                return unbox!(long)(*this) == unbox!(long)(other);
            }
            else if (tb == TypeClass.Float)
                return unbox!(real)(*this) == unbox!(real)(other);
            else if (tb == TypeClass.Complex)
                return unbox!(creal)(*this) == unbox!(creal)(other);
            else if (tb == TypeClass.Imaginary)
                return unbox!(ireal)(*this) == unbox!(ireal)(other);
            
            assert (0);
        }
        
        return cast(bool)type.equals(data.ptr, other.data.ptr);
    }

    /**
     * Compare this box's value with another box. This implicitly casts if the
     * types are different, identical to the regular type system.    
     */
    bool opEquals(Box other)
    {
        return opEqualsInternal(other, false);
    }
    
    private float opCmpInternal(Box other, bool inverted)
    {
        if (type != other.type)
        {
            if (!unboxable(other.type))
            {
                if (inverted)
                    return 0;
                return other.opCmpInternal(*this, true);
            }
            
            TypeClass ta = findTypeClass(type), tb = findTypeClass(other.type);
            
            if (ta <= TypeClass.Integer && tb == TypeClass.Integer)
            {
                if (type == typeid(ulong) || other.type == typeid(ulong))
                {
                    ulong va = unbox!(ulong)(*this), vb = unbox!(ulong)(other);
                    return va > vb ? 1 : va < vb ? -1 : 0;
                }
                
                long va = unbox!(long)(*this), vb = unbox!(long)(other);
                return va > vb ? 1 : va < vb ? -1 : 0;
            }
            else if (tb == TypeClass.Float)
            {
                real va = unbox!(real)(*this), vb = unbox!(real)(other);
                return va > vb ? 1 : va < vb ? -1 : va == vb ? 0 : float.nan;
            }
            else if (tb == TypeClass.Complex)
            {
                creal va = unbox!(creal)(*this), vb = unbox!(creal)(other);
                return va == vb ? 0 : float.nan;
            }
            else if (tb == TypeClass.Imaginary)
            {
                ireal va = unbox!(ireal)(*this), vb = unbox!(ireal)(other);
                return va > vb ? 1 : va < vb ? -1 : va == vb ? 0 : float.nan;
            }
            
            assert (0);
        }
        
        return type.compare(data.ptr, other.data.ptr);
    }

    /**
     * Compare this box's value with another box. This implicitly casts if the
     * types are different, identical to the regular type system.
     */
    float opCmp(Box other)
    {
        return opCmpInternal(other, false);
    }

    /**
     * Return the value's hash.
     */
    hash_t toHash()
    {
        return type.getHash(data.ptr);
    }
}

/**
 * Box the single argument passed to the function. If more or fewer than one
 * argument is passed, this will assert. 
 */    
Box box(...)
in
{
    assert (_arguments.length == 1);
}
body
{
    version (GNU)
    {
	// Help for promoted types
	TypeInfo ti_orig = _arguments[0]; 
	TypeInfo ti = ti_orig;
	TypeInfo_Typedef ttd;
	
	while ( (ttd = cast(TypeInfo_Typedef) ti) !is null )
	    ti = ttd.base;

	if (ti is typeid(float))
	{
	    float f = va_arg!(float)(_argptr);
	    return box(ti_orig, cast(void *) & f);
	}
	else if (ti is typeid(char) || ti is typeid(byte) || ti is typeid(ubyte))
	{
	    byte b = va_arg!(byte)(_argptr);
	    return box(ti_orig, cast(void *) & b);
	}
	else if (ti is typeid(wchar) || ti is typeid(short) || ti is typeid(ushort))
	{
	    short s = va_arg!(short)(_argptr);
	    return box(ti_orig, cast(void *) & s);
	}
	else if (ti is typeid(bool))
	{
	    bool b = va_arg!(bool)(_argptr);
	    return box(ti_orig, cast(void *) & b);
	}
    }
    return box(_arguments[0], cast(void*) _argptr);
}

/**
 * Box the explicitly-defined object. type must not be null; data must not be
 * null if the type's size is greater than zero.
 * The data is copied.
 */    
Box box(TypeInfo type, void* data)
in
{
    assert(type !is null);
}
body
{
    Box result;
    size_t size = type.tsize();
    
    result.p_type = type;
    if (size <= result.p_shortData.length)
        result.p_shortData[0..size] = data[0..size];
    else
        result.p_longData = data[0..size].dup.ptr;
        
    return result;
}

/** Return the length of an argument in bytes. */
private size_t argumentLength(size_t baseLength)
{
    return (baseLength + int.sizeof - 1) & ~(int.sizeof - 1);
}

/**
 * Convert a list of arguments into a list of boxes.
 */    
Box[] boxArray(TypeInfo[] types, void* data)
{
    Box[] array = new Box[types.length];
    
    foreach(size_t index, TypeInfo type; types)
    {
        array[index] = box(type, data);
        data += argumentLength(type.tsize());
    }
    
    return array;
}

 /**
  * Box each argument passed to the function, returning an array of boxes.
  */    
Box[] boxArray(...)
{
    version (GNU)
    {
	Box[] array = new Box[_arguments.length];
	
	foreach(size_t index, TypeInfo ti_orig; _arguments)
	{
	    TypeInfo ti = ti_orig;
	    TypeInfo_Typedef ttd;

	    while ( (ttd = cast(TypeInfo_Typedef) ti) !is null )
		ti = ttd.base;

	    if (ti is typeid(float))
	    {
		float f = va_arg!(float)(_argptr);
		array[index] = box(ti_orig, cast(void *) & f);
	    }
	    else if (ti is typeid(char) || ti is typeid(byte) || ti is typeid(ubyte))
	    {
		byte b = va_arg!(byte)(_argptr);
		array[index] = box(ti_orig, cast(void *) & b);
	    }
	    else if (ti is typeid(wchar) || ti is typeid(short) || ti is typeid(ushort))
	    {
		short s = va_arg!(short)(_argptr);
		array[index] = box(ti_orig, cast(void *) & s);
	    }
	    else if (ti is typeid(bool))
	    {
		bool b = va_arg!(bool)(_argptr);
		array[index] = box(ti_orig, cast(void *) & b);
	    }
	    else
		array[index] = box(ti_orig, cast(void*) _argptr);
	}

	return array;
    }
    else
	return boxArray(_arguments, cast(void *) _argptr);
}

 /**
  * Convert an array of boxes into an array of arguments.
  */    
void boxArrayToArguments(Box[] arguments, out TypeInfo[] types, out void* data)
{
    size_t dataLength;
    void* pointer;
    
    /* Determine the number of bytes of data to allocate by summing the arguments. */
    foreach (Box item; arguments)
        dataLength += argumentLength(item.data.length);
        
    types = new TypeInfo[arguments.length];
    pointer = data = (new void[dataLength]).ptr;

    /* Stash both types and data. */
    foreach (size_t index, Box item; arguments)
    {
        types[index] = item.type;
        pointer[0..item.data.length] = item.data;
        pointer += argumentLength(item.data.length);
    }    
}

/**
 * This class is thrown if unbox is unable to cast the value into the desired
 * result.
 */    
class UnboxException : Exception
{
    Box object;	/// This is the box that the user attempted to unbox.

    TypeInfo outputType; /// This is the type that the user attempted to unbox the value as.

    /**
     * Assign parameters and create the message in the form
     * <tt>"Could not unbox from type ... to ... ."</tt>
     */
    this(Box object, TypeInfo outputType)
    {
        this.object = object;
        this.outputType = outputType;
        super(format("Could not unbox from type %s to %s.", object.type, outputType));
    }
}

/** A generic unboxer for the real numeric types. */
private template unboxCastReal(T)
{
    T unboxCastReal(Box value)
    {
        assert (value.type !is null);
        
        if (value.type is typeid(float))
            return cast(T) *cast(float*) value.data;
        if (value.type is typeid(double))
            return cast(T) *cast(double*) value.data;
        if (value.type is typeid(real))
            return cast(T) *cast(real*) value.data;
        return unboxCastInteger!(T)(value);
    }
}

/** A generic unboxer for the integral numeric types. */
private template unboxCastInteger(T)
{
    T unboxCastInteger(Box value)
    {
        assert (value.type !is null);
        
        if (value.type is typeid(int))
            return cast(T) *cast(int*) value.data;
        if (value.type is typeid(uint))
            return cast(T) *cast(uint*) value.data;
        if (value.type is typeid(long))
            return cast(T) *cast(long*) value.data;
        if (value.type is typeid(ulong))
            return cast(T) *cast(ulong*) value.data;
        if (value.type is typeid(bool))
            return cast(T) *cast(bool*) value.data;
        if (value.type is typeid(byte))
            return cast(T) *cast(byte*) value.data;
        if (value.type is typeid(ubyte))
            return cast(T) *cast(ubyte*) value.data;
        if (value.type is typeid(short))
            return cast(T) *cast(short*) value.data;
        if (value.type is typeid(ushort))
            return cast(T) *cast(ushort*) value.data;
        throw new UnboxException(value, typeid(T));
    }
}

/** A generic unboxer for the complex numeric types. */
private template unboxCastComplex(T)
{
    T unboxCastComplex(Box value)
    {
        assert (value.type !is null);
        
        if (value.type is typeid(cfloat))
            return cast(T) *cast(cfloat*) value.data;
        if (value.type is typeid(cdouble))
            return cast(T) *cast(cdouble*) value.data;
        if (value.type is typeid(creal))
            return cast(T) *cast(creal*) value.data;
        if (value.type is typeid(ifloat))
            return cast(T) *cast(ifloat*) value.data;
        if (value.type is typeid(idouble))
            return cast(T) *cast(idouble*) value.data;
        if (value.type is typeid(ireal))
            return cast(T) *cast(ireal*) value.data;
        return unboxCastReal!(T)(value);
    }
}

/** A generic unboxer for the imaginary numeric types. */
private template unboxCastImaginary(T)
{
    T unboxCastImaginary(Box value)
    {
        assert (value.type !is null);
        
        if (value.type is typeid(ifloat))
            return cast(T) *cast(ifloat*) value.data;
        if (value.type is typeid(idouble))
            return cast(T) *cast(idouble*) value.data;
        if (value.type is typeid(ireal))
            return cast(T) *cast(ireal*) value.data;
        throw new UnboxException(value, typeid(T));
    }
}

/**
 * The unbox template takes a type parameter and returns a function that
 * takes a box object and returns the specified type.
 *
 * To use it, instantiate the template with the desired result type, and then
 * call the function with the box to convert. 
 * This will implicitly cast base types as necessary and in a way consistent
 * with static types - for example, it will cast a boxed byte into int, but it
 * won't cast a boxed float into short.
 *
 * Throws: UnboxException if it cannot cast
 *
 * Example:
 * ---
 * Box b = box(4.5);
 * bit u = unboxable!(real)(b); // This is true.
 * real r = unbox!(real)(b);
 *
 * Box y = box(4);
 * int x = unbox!(int) (y);
 * ---
 */    
template unbox(T)
{
    T unbox(Box value)
    {
        assert (value.type !is null);
        
        if (typeid(T) is value.type)
            return *cast(T*) value.data;
        throw new UnboxException(value, typeid(T));
    }
}

template unbox(T : byte) { T unbox(Box value) { return unboxCastInteger!(T) (value); } }
template unbox(T : ubyte) { T unbox(Box value) { return unboxCastInteger!(T) (value); } }
template unbox(T : short) { T unbox(Box value) { return unboxCastInteger!(T) (value); } }
template unbox(T : ushort) { T unbox(Box value) { return unboxCastInteger!(T) (value); } }
template unbox(T : int) { T unbox(Box value) { return unboxCastInteger!(T) (value); } }
template unbox(T : uint) { T unbox(Box value) { return unboxCastInteger!(T) (value); } }
template unbox(T : long) { T unbox(Box value) { return unboxCastInteger!(T) (value); } }
template unbox(T : ulong) { T unbox(Box value) { return unboxCastInteger!(T) (value); } }
template unbox(T : float) { T unbox(Box value) { return unboxCastReal!(T) (value); } }
template unbox(T : double) { T unbox(Box value) { return unboxCastReal!(T) (value); } }
template unbox(T : real) { T unbox(Box value) { return unboxCastReal!(T) (value); } }
template unbox(T : cfloat) { T unbox(Box value) { return unboxCastComplex!(T) (value); } }
template unbox(T : cdouble) { T unbox(Box value) { return unboxCastComplex!(T) (value); } }
template unbox(T : creal) { T unbox(Box value) { return unboxCastComplex!(T) (value); } }
template unbox(T : ifloat) { T unbox(Box value) { return unboxCastImaginary!(T) (value); } }
template unbox(T : idouble) { T unbox(Box value) { return unboxCastImaginary!(T) (value); } }
template unbox(T : ireal) { T unbox(Box value) { return unboxCastImaginary!(T) (value); } }

template unbox(T : Object)
{
    T unbox(Box value)
    {
        assert (value.type !is null);
        
        if (typeid(T) == value.type || cast(TypeInfo_Class) value.type)
        {
            Object object = *cast(Object*)value.data;
            T result = cast(T)object;
            
            if (object is null)
                return null;
            if (result is null)
                throw new UnboxException(value, typeid(T));
            return result;
        }
        
        if (typeid(void*) is value.type && *cast(void**) value.data is null)
            return null;
        throw new UnboxException(value, typeid(T));
    }
}

template unbox(T : T[])
{
    T[] unbox(Box value)
    {
        assert (value.type !is null);
        
        if (typeid(T[]) is value.type)
            return *cast(T[]*) value.data;
        if (typeid(void*) is value.type && *cast(void**) value.data is null)
            return null;
        throw new UnboxException(value, typeid(T[]));
    }
}

template unbox(T : T*)
{
    T* unbox(Box value)
    {
        assert (value.type !is null);
        
        if (typeid(T*) is value.type)
            return *cast(T**) value.data;
        if (typeid(void*) is value.type && *cast(void**) value.data is null)
            return null;
        if (typeid(T[]) is value.type)
            return (*cast(T[]*) value.data).ptr;
        
        throw new UnboxException(value, typeid(T*));
    }
}

template unbox(T : void*)
{
    T unbox(Box value)
    {
        assert (value.type !is null);
        
        if (cast(TypeInfo_Pointer) value.type)
            return *cast(void**) value.data;
        if (isArrayTypeInfo(value.type))
            return (*cast(void[]*) value.data).ptr;
        if (cast(TypeInfo_Class) value.type)
            return *cast(Object*) value.data;
        
        throw new UnboxException(value, typeid(T));
    }
}

/**
 * Return whether the value can be unboxed as the given type; if this returns
 * false, attempting to do so will throw UnboxException.
 */    
template unboxable(T)
{
    bool unboxable(Box value)
    {
        return value.unboxable(typeid(T));
    }
}

/* Tests unboxing - assert that if it says it's unboxable, it is. */
private template unboxTest(T)
{
    T unboxTest(Box value)
    {
        T result;
        bool unboxable = value.unboxable(typeid(T));
        
        try result = unbox!(T) (value);
        catch (UnboxException error)
        {
            if (unboxable)
                throw new Error ("Could not unbox " ~ value.type.toString ~ " as " ~ typeid(T).toString ~ "; however, unboxable says it would work.");
            assert (!unboxable);
            throw error;
        }
        
        if (!unboxable)
            throw new Error ("Unboxed " ~ value.type.toString ~ " as " ~ typeid(T).toString ~ "; however, unboxable says it should fail.");
        return result;
    }
}

unittest
{
    class A { }
    class B : A { }
    struct SA { }
    struct SB { }
    
    Box a, b;
    
    /* Call the function, catch UnboxException, return that it threw correctly. */
    bool fails(void delegate()func)
    {
        try func();
        catch (UnboxException error)
            return true;
        return false;
    }
    
    /* Check that equals and comparison work properly. */
    a = box(0);
    b = box(32);
    assert (a != b);
    assert (a == a);
    assert (a < b);
    
    /* Check that toString works properly. */
    assert (b.toString == "32");
    
    /* Assert that unboxable works. */
    assert (unboxable!(char[])(box("foobar")));
    
    /* Assert that we can cast from int to byte. */
    assert (unboxTest!(byte)(b) == 32);
    
    /* Assert that we can cast from int to real. */
    assert (unboxTest!(real)(b) == 32.0L);
    
    /* Check that real works properly. */
    assert (unboxTest!(real)(box(32.45L)) == 32.45L);
    
    /* Assert that we cannot implicitly cast from real to int. */
    assert(fails(delegate void() { unboxTest!(int)(box(1.3)); }));
    
    /* Check that the unspecialized unbox template works. */
    assert(unboxTest!(char[])(box("foobar")) == "foobar");
    
    /* Assert that complex works correctly. */
    assert(unboxTest!(cdouble)(box(1 + 2i)) == 1 + 2i);
    
    /* Assert that imaginary works correctly. */
    assert(unboxTest!(ireal)(box(45i)) == 45i);
    
    /* Create an array of boxes from arguments. */
    Box[] array = boxArray(16, "foobar", new Object);
    
    assert(array.length == 3);
    assert(unboxTest!(int)(array[0]) == 16);
    assert(unboxTest!(char[])(array[1]) == "foobar");
    assert(unboxTest!(Object)(array[2]) !is null);
    
    /* Convert the box array back into arguments. */
    TypeInfo[] array_types;
    void* array_data;
    
    boxArrayToArguments(array, array_types, array_data);
    assert (array_types.length == 3);
    
    /* Confirm the symmetry. */
    assert (boxArray(array_types, array_data) == array);
    
    /* Assert that we can cast from int to creal. */
    assert (unboxTest!(creal)(box(45)) == 45+0i);
    
    /* Assert that we can cast from idouble to creal. */
    assert (unboxTest!(creal)(box(45i)) == 0+45i);
    
    /* Assert that equality testing casts properly. */
    assert (box(1) == box(cast(byte)1));
    assert (box(cast(real)4) == box(4));
    assert (box(5) == box(5+0i));
    assert (box(0+4i) == box(4i));
    assert (box(8i) == box(0+8i));
    
    /* Assert that comparisons cast properly. */
    assert (box(450) < box(451));
    assert (box(4) > box(3.0));
    assert (box(0+3i) < box(0+4i));
    
    /* Assert that casting from bool to int works. */
    assert (1 == unboxTest!(int)(box(true)));
    assert (box(1) == box(true));
 
    /* Assert that unboxing to an object works properly. */
    assert (unboxTest!(B)(box(cast(A)new B)) !is null);
    
    /* Assert that illegal object casting fails properly. */   
    assert (fails(delegate void() { unboxTest!(B)(box(new A)); }));
    
    /* Assert that we can unbox a null. */
    assert (unboxTest!(A)(box(cast(A)null)) is null);
    assert (unboxTest!(A)(box(null)) is null);
    
    /* Unboxing null in various contexts. */
    assert (unboxTest!(char[])(box(null)) is null);
    assert (unboxTest!(int*)(box(null)) is null);
    
    /* Assert that unboxing between pointer types fails. */
    int [1] p;
    assert (fails(delegate void() { unboxTest!(char*)(box(p.ptr)); }));
    
    /* Assert that unboxing various types as void* does work. */
    assert (unboxTest!(void*)(box(p.ptr))); // int*
    assert (unboxTest!(void*)(box(p))); // int[]
    assert (unboxTest!(void*)(box(new A))); // Object
    
    /* Assert that we can't unbox an integer as bool. */
    assert (!unboxable!(bool) (box(4)));
    
    /* Assert that we can't unbox a struct as another struct. */
    SA sa;
    assert (!unboxable!(SB)(box(sa)));
}
