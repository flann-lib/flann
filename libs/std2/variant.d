// Written in the D programming language.

/**
 * This module implements a
 * $(LINK2 http://erdani.org/publications/cuj-04-2002.html,discriminated union)
 * type (a.k.a.
 * $(LINK2 http://en.wikipedia.org/wiki/Tagged_union,tagged union),
 * $(LINK2 http://en.wikipedia.org/wiki/Algebraic_data_type,algebraic type)).
 * Such types are useful
 * for type-uniform binary interfaces, interfacing with scripting
 * languages, and comfortable exploratory programming. 
 *
 * Macros:
 *	WIKI = Phobos/StdVariant
 *
 * Synopsis:
 *
 * ----
 * Variant a; // Must assign before use, otherwise exception ensues
 * // Initialize with an integer; make the type int
 * Variant b = 42; 
 * assert(b.type == typeid(int));
 * // Peek at the value
 * assert(b.peek!(int) !is null && *b.peek!(int) == 42);
 * // Automatically convert per language rules
 * auto x = b.get!(real);
 * // Assign any other type, including other variants
 * a = b; 
 * a = 3.14; 
 * assert(a.type == typeid(double));
 * // Implicit conversions work just as with built-in types
 * assert(a > b);
 * // Check for convertibility
 * assert(!a.convertsTo!(int)); // double not convertible to int
 * // Strings and all other arrays are supported
 * a = "now I'm a string";
 * assert(a == "now I'm a string");
 * a = new int[42]; // can also assign arrays
 * assert(a.length == 42);
 * a[5] = 7;
 * assert(a[5] == 7);
 * // Can also assign class values
 * class Foo {}
 * auto foo = new Foo;
 * a = foo; 
 * assert(*a.peek!(Foo) == foo); // and full type information is preserved
 * ----
 * 
 * Author:
 * Andrei Alexandrescu
 * 
 * Credits:
 * 
 * Reviewed by Brad Roberts. Daniel Keep provided a detailed code
 * review prompting the following improvements: (1) better support for
 * arrays; (2) support for associative arrays; (3) friendlier behavior
 * towards the garbage collector.
 */

/*
 *  Copyright (C) 2004-2006 by Digital Mars, www.digitalmars.com
 *  Written by Andrei Alexandrescu, www.erdani.org
 *
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, subject to the following restrictions:
 *
 *  o  The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  o  Altered source versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *  o  This notice may not be removed or altered from any source
 *     distribution.
 */

module util.variant;

import std2.traits, std2.conv, std.c.string, std.typetuple, std.gc;
import std.stdio; // for testing only

//------------------- D1.0 compatibility------------------------
alias IndexOf indexOf;

/**
 * Detect whether type T is an array.
 */
template isArray(T)
{
    static const isArray = isStaticArray!(T) || isDynamicArray!(T);
}

/**
 * Detect whether type T is a dynamic array.
 */
template isDynamicArray(T, U = void)
{
    static const isDynamicArray = false;
}

template isDynamicArray(T : U[], U)
{
  static const isDynamicArray = !isStaticArray!(T);
}



/**
 * Detect whether T is an associative array type
 */

template isAssociativeArray(T)
{
    static const bool isAssociativeArray
    = is(typeof(T.keys)) && is(typeof(T.values));
    //      = is(typeof(T.init.values[0])[typeof(T.init.keys[0])] == T);
}

/**
 * Detect whether T is a built-in floating point type
 */

template isFloatingPoint(T) {
  static const isFloatingPoint = is(T == float)
    || is(T == double) || is(T == real);
}

/**
 * Detect whether T is a built-in numeric type
 */

template isNumeric(T) {
  static const isNumeric = isIntegral!(T) || isFloatingPoint!(T);
}

/**
 * Detect whether T is a built-in integral type
 */

template isIntegral(T)
{
  static const isIntegral = is(T == byte) || is(T == ubyte) || is(T == short)
    || is(T == ushort) || is(T == int) || is(T == uint)
    || is(T == long) || is(T == ulong);
}

/**
 * Returns a tuple with all possible target types of an implicit
 * conversion of a value of type $(D_PARAM T).
 *
 * Important note:
 *
 * The possible targets are computed more conservatively than the D
 * 2.005 compiler does, eliminating all dangerous conversions. For
 * example, $(D_PARAM ImplicitConversionTargets!(double)) does not
 * include $(D_PARAM float).
 */

template ImplicitConversionTargets(T)
{
    static if (is(T == bool))
        alias TypeTuple!(byte, ubyte, short, ushort, int, uint, long, ulong,
            float, double, real, char, wchar, dchar)
            ImplicitConversionTargets;
    else static if (is(T == byte))
        alias TypeTuple!(short, ushort, int, uint, long, ulong,
            float, double, real, char, wchar, dchar)
            ImplicitConversionTargets;
    else static if (is(T == ubyte))
        alias TypeTuple!(short, ushort, int, uint, long, ulong,
            float, double, real, char, wchar, dchar)
            ImplicitConversionTargets;
    else static if (is(T == short))
        alias TypeTuple!(ushort, int, uint, long, ulong,
            float, double, real)
            ImplicitConversionTargets;
    else static if (is(T == ushort))
        alias TypeTuple!(int, uint, long, ulong, float, double, real)
            ImplicitConversionTargets;
    else static if (is(T == int))
        alias TypeTuple!(long, ulong, float, double, real)
            ImplicitConversionTargets;
    else static if (is(T == uint))
        alias TypeTuple!(long, ulong, float, double, real)
            ImplicitConversionTargets;
    else static if (is(T == long))
        alias TypeTuple!(float, double, real)
            ImplicitConversionTargets;
    else static if (is(T == ulong))
        alias TypeTuple!(float, double, real)
            ImplicitConversionTargets;
    else static if (is(T == float))
        alias TypeTuple!(double, real)
            ImplicitConversionTargets;
    else static if (is(T == double))
        alias TypeTuple!(real)
            ImplicitConversionTargets;
//     else static if (is(T == real))
//         alias TypeTuple!()
//             ImplicitConversionTargets;
    else static if (is(T == char))
        alias TypeTuple!(wchar, dchar, byte, ubyte, short, ushort,
            int, uint, long, ulong, float, double, real)
            ImplicitConversionTargets;
    else static if (is(T == wchar))
        alias TypeTuple!(wchar, dchar, short, ushort, int, uint, long, ulong,
            float, double, real)
            ImplicitConversionTargets;
    else static if (is(T == dchar))
        alias TypeTuple!(wchar, dchar, int, uint, long, ulong,
            float, double, real)
            ImplicitConversionTargets;
    else static if(is(T : Object))
        alias TransitiveBaseTypeTuple!(T) ImplicitConversionTargets;
    else static if (is(T : void*))
        alias TypeTuple!(void*) ImplicitConversionTargets;
    else
        alias TypeTuple!() ImplicitConversionTargets;
}


//----------------------------------------------

private template maxSize(T...)
{
    static if (T.length == 1)
    {
        static const size_t maxSize = T[0].sizeof;
    }
    else
    {
        static const size_t maxSize = T[0].sizeof >= maxSize!(T[1 .. $])
            ? T[0].sizeof : maxSize!(T[1 .. $]);
    }
}

/**
 * $(D_PARAM VariantN) is a back-end type seldom used directly by user
 * code. Two commonly-used types using $(D_PARAM VariantN) as
 * back-end are:
 *
 * $(OL $(LI $(B Algebraic): A closed discriminated union with a
 * limited type universe (e.g., $(D_PARAM Algebraic!(int, double,
 * string)) only accepts these three types and rejects anything
 * else).) $(LI $(B Variant): An open discriminated union allowing an
 * unbounded set of types. The restriction is that the size of the
 * stored type cannot be larger than the largest built-in type. This
 * means that $(D_PARAM Variant) can accommodate all primitive types
 * and all user-defined types except for large $(D_PARAM struct)s.) )
 *
 * Both $(D_PARAM Algebraic) and $(D_PARAM Variant) share $(D_PARAM
 * VariantN)'s interface. (See their respective documentations below.)
 * 
 * $(D_PARAM VariantN) is a discriminated union type parameterized
 * with the largest size of the types stored ($(D_PARAM maxDataSize))
 * and with the list of allowed types ($(D_PARAM AllowedTypes)). If
 * the list is empty, then any type up of size up to $(D_PARAM
 * maxDataSize) (rounded up for alignment) can be stored in a
 * $(D_PARAM VariantN) object.
 *
 */

struct VariantN(size_t maxDataSize, AllowedTypes...)
{
private:
    // Compute the largest practical size from maxDataSize
    struct SizeChecker
    {
        int function() fptr;
        ubyte[maxDataSize] data;
    }
    const size_t size = SizeChecker.sizeof - (int function()).sizeof;

    /** Tells whether a type $(D_PARAM T) is statically allowed for
     * storage inside a $(D_PARAM VariantN) object by looking
     * $(D_PARAM T) up in $(D_PARAM AllowedTypes). If $(D_PARAM
     * AllowedTypes) is empty, all types of size up to $(D_PARAM
     * maxSize) are allowed.
     */
    public template allowed(T)
    {
        static const bool allowed =
            (T.sizeof <= size || is(T == VariantN))
            && (!AllowedTypes.length || indexOf!(T, AllowedTypes) >= 0);
    }

    // Each internal operation is encoded with an identifier. See
    // the "handler" function below.
    enum OpID { getTypeInfo, get, compare, testConversion, toString,
                index, indexAssign, catAssign, copyOut, length }

    // state
    int function(OpID selector, ubyte[size]* store, void* data) fptr
        = &handler!(void);
    union
    {
        ubyte[size] store = void;
        // conservatively mark the region as pointers
        static if (size >= (void*).sizeof)
            void* p[size / (void*).sizeof]; 
    }

	public void* data() { return cast(void*) store; };

    // internals
    // Handler for an initialized value
    static int handler(A : void)(OpID selector, ubyte[size]*, void* parm)
    {
        switch (selector)
        {
        case OpID.getTypeInfo:
            *cast(TypeInfo *) parm = typeid(A);
            break;
        case OpID.copyOut:
            auto target = cast(VariantN *) parm;
            target.fptr = &handler!(A);
            // no need to copy the data (it's garbage)
            break;
        case OpID.compare:
            auto rhs = cast(VariantN *) parm;
            return rhs.peek!(A)
                ? 0 // all uninitialized are equal
                : int.min; // uninitialized variant is not comparable otherwise
        case OpID.toString:
            string * target = cast(string*) parm;
            *target = "<Uninitialized VariantN>";
            break;
        case OpID.get:
        case OpID.testConversion:
        case OpID.index:
        case OpID.indexAssign:
        case OpID.catAssign:
        case OpID.length:
            throw new VariantException(
                "Attempt to use an uninitialized VariantN");
        default: assert(false);
        }
        return 0;
    }
    
    // Handler for all of a type's operations
    static int handler(A)(OpID selector, ubyte[size]* pStore, void* parm)
    {
        // Input: TypeInfo object
        // Output: target points to a copy of *me, if me was not null
        // Returns: true iff the A can be converted to the type represented
        // by the incoming TypeInfo 
        static bool tryPutting(A* me, TypeInfo targetType, void* target)
        {
            alias TypeTuple!(A, ImplicitConversionTargets!(A)) AllTypes;
            foreach (T ; AllTypes)
            {
                if (targetType != typeid(T)) continue;
                // found!!!
                static if (is(typeof(*cast(T*) target = *me)))
                {
                    if (me) *cast(T*) target = *me;
                }
                else
                {
                    // type is not assignable
                    if (me) assert(false, typeof(A).stringof);
                }
                return true;
            }
            return false;
        }
        
        switch (selector)
        {
        case OpID.getTypeInfo:
            *cast(TypeInfo *) parm = typeid(A);
            break;
        case OpID.copyOut:
            auto target = cast(VariantN *) parm;
            memcpy(&target.store, pStore, A.sizeof);
            target.fptr = &handler!(A);
            break;
        case OpID.get:
            return !tryPutting(cast(A*) pStore, *cast(TypeInfo*) parm, parm);
            break; // for conformity
        case OpID.testConversion:
            return !tryPutting(null, *cast(TypeInfo*) parm, null);
            break;
        case OpID.compare:
            auto me = cast(A*) pStore;
            auto rhsP = cast(VariantN *) parm;
            auto rhsType = rhsP.type;
            // Are we the same?
            if (rhsType == typeid(A))
            {
                // cool! Same type!
                auto rhsPA = cast(A*) &rhsP.store;
                if (*rhsPA == *me)
                {
                    return 0;
                }
                static if (is(typeof(A.init < A.init)))
                {
                    return *me < *rhsPA ? -1 : 1;
                }
                else
                {
                    // type doesn't support ordering comparisons
                    return int.min;
                }
            }
            VariantN temp;
            // Do I convert to rhs?
            if (tryPutting(me, rhsType, &temp.store))
            {
                // cool, I do; temp's store contains my data in rhs's type!
                // also fix up its fptr
                temp.fptr = rhsP.fptr;
                // now lhsWithRhsType is a full-blown VariantN of rhs's type
                return temp.opCmp(*rhsP);
            }
            // Does rhs convert to me?
            *cast(TypeInfo*) &temp.store = typeid(A);
            if (rhsP.fptr(OpID.get, &rhsP.store, &temp.store) == 0)
            {
                // cool! Now temp has rhs in my type!
                auto rhsPA = cast(A*) temp.store;
                if (*rhsPA == *me)
                {
                    return 0;
                }
                static if (is(typeof(A.init < A.init)))
                {
                    return *me < *rhsPA ? -1 : 1;
                }
                else
                {
                    // type doesn't support ordering comparisons
                    return int.min;
                }
            }
            return int.min; // dunno
            break;
        case OpID.toString:
            auto target = cast(string*) parm;
            auto me = cast(A*) pStore;
            static if (is(typeof(to!(string)(*me))))
            {
                *target = to!(string)(*me);
            }
            else
            {
                throw new VariantException(typeid(A), typeid(string));
            }
            break;
        case OpID.index:
            auto me = cast(A*) pStore;
            static if (isArray!(A))
            {
                // array type; input and output are the same VariantN 
                auto result = cast(VariantN*) parm;
                size_t index = result.convertsTo!(int)
                    ? result.get!(int) : result.get!(size_t);
                *result = (*me)[index];
            }
            else static if (isAssociativeArray!(A))
            {
                auto result = cast(VariantN*) parm;
                *result = (*me)[result.get!(typeof(A.keys[0]))];
            }
            else
            {
                throw new VariantException(typeid(A), typeid(void[]));
            }
            break;
        case OpID.indexAssign:
            auto me = cast(A*) pStore;
            static if (isArray!(A) && is(typeof((*me)[0] = (*me)[0])))
            {
                // array type; result comes first, index comes second
                auto args = cast(VariantN*) parm;
                size_t index = args[1].convertsTo!(int)
                    ? args[1].get!(int) : args[1].get!(size_t);
                (*me)[index] = args[0].get!(typeof((*me)[0]));
            }
            else static if (isAssociativeArray!(A))
            {
                auto args = cast(VariantN*) parm;
                (*me)[args[1].get!(typeof(A.keys[0]))]
                    = args[0].get!(typeof(A.values[0]));
            }
            else
            {
                throw new VariantException(typeid(A), typeid(void[]));
            }
            break;
        case OpID.catAssign:
            auto me = cast(A*) pStore;
            static if (is(typeof((*me)[0])) && !is(typeof(me.keys)))
            {
                // array type; parm is the element to append
                auto arg = cast(VariantN*) parm;
                alias typeof((*me)[0]) E;
                if (arg[0].convertsTo!(E))
                {
                    // append one element to the array
                    (*me) ~= [ arg[0].get!(E) ];
                }
                else
                {
                    // append a whole array to the array
                    (*me) ~= arg[0].get!(A);
                }
            }
            else
            {
                throw new VariantException(typeid(A), typeid(void[]));
            }
            break;
        case OpID.length:
            auto me = cast(A*) pStore;
            static if (is(typeof(me.length)))
            {
                return me.length;
            }
            else
            {
                throw new VariantException(typeid(A), typeid(void[]));
            }
            break;
        default: assert(false);
        }
        return 0;
    }

public:
    /** Constructs a $(D_PARAM VariantN) value given an argument of a
     * generic type. Statically rejects disallowed types.
     */

    static VariantN opCall(T)(T value)
    {
        static assert(allowed!(T), "Cannot store a " ~ T.stringof
            ~ " in a " ~ VariantN.stringof);
        VariantN result = void;
        result.opAssign(value);
        return result;
    }

    /** Assigns a $(D_PARAM VariantN) from a generic
     * argument. Statically rejects disallowed types. */

    VariantN opAssign(T)(T rhs)
    {
        static assert(allowed!(T), "Cannot store a " ~ T.stringof
            ~ " in a " ~ VariantN.stringof);
        static if (isStaticArray!(T))
        {
            DecayStaticToDynamicArray!(T) temp = rhs;
            return opAssign(temp);
        }
        else
        {
            static if (is(T : VariantN))
            {
                rhs.fptr(OpID.copyOut, &rhs.store, this);
            }
            else
            {
                static assert(T.sizeof <= size, "Cannot store type "
                    ~ T.stringof ~ " in a " ~ VariantN.stringof
                    ~ "; it's too large. Try storing a pointer, or using"
                    " VariantN with a larger size.");
                //*cast(U*) &store = rhs;
                memcpy(&store, &rhs, rhs.sizeof);
                fptr = &handler!(T);
            }
            return *this;
        }
    }

    /** Returns true if and only if the $(D_PARAM VariantN) object
     * holds a valid value (has been initialized with, or assigned
     * from, a valid value).
     * Example:
     * ----
     * Variant a;
     * assert(!a.hasValue);
     * Variant b;
     * a = b;
     * assert(!a.hasValue); // still no value
     * a = 5;
     * assert(a.hasValue);
     * ----
     */
    
    bool hasValue()
    {
        return fptr != &handler!(void);
    }

    /**
     * If the $(D_PARAM VariantN) object holds a value of the
     * $(I exact) type $(D_PARAM T), returns a pointer to that
     * value. Otherwise, returns $(D_PARAM null). In cases
     * where $(D_PARAM T) is statically disallowed, $(D_PARAM
     * peek) will not compile.
     * 
     * Example:
     * ----
     * Variant a = 5;
     * auto b = a.peek!(int);
     * assert(b !is null);
     * *b = 6;
     * assert(a == 6);
     * ----
     */
    T * peek(T)()
    {
        static assert(allowed!(T), "Cannot store a " ~ T.stringof
            ~ " in a " ~ VariantN.stringof);
        return type == typeid(T) ? cast(T*) &store : null;
    }

    /**
     * Returns the $(D_PARAM typeid) of the currently held value.
     */
    
    TypeInfo type()
    {
        TypeInfo result;
        fptr(OpID.getTypeInfo, null, &result);
        return result;
    }

    /**
     * Returns $(D_PARAM true) if and only if the $(D_PARAM VariantN)
     * object holds an object implicitly convertible to type $(D_PARAM
     * U). Implicit convertibility is defined as per
     * $(LINK2 std_traits.html#ImplicitConversionTargets,ImplicitConversionTargets).
     */

    bool convertsTo(T)()
    {
        TypeInfo info = typeid(T);
        return fptr(OpID.testConversion, null, &info) == 0;
    }

    private T[] testing123(T)(T*);

    /**
     * A workaround for the fact that functions cannot return
     * statically-sized arrays by value. Essentially $(D_PARAM
     * DecayStaticToDynamicArray!(T[N])) is an alias for $(D_PARAM
     * T[]) and $(D_PARAM DecayStaticToDynamicArray!(T)) is an alias
     * for $(D_PARAM T).
     */

    template DecayStaticToDynamicArray(T)
    {
        static if (isStaticArray!(T))
        {
            alias typeof(testing123(&T[0])) DecayStaticToDynamicArray;
        }
        else
        {
            alias T DecayStaticToDynamicArray;
        }
    }

    static assert(is(DecayStaticToDynamicArray!(char[21]) ==
                     char[]),
                  DecayStaticToDynamicArray!(char[21]).stringof);

    /**
     * Returns the value stored in the $(D_PARAM VariantN) object,
     * implicitly converted to the requested type $(D_PARAM T), in
     * fact $(D_PARAM DecayStaticToDynamicArray!(T)). If an implicit
     * conversion is not possible, throws a $(D_PARAM
     * VariantException).
     */
    
    DecayStaticToDynamicArray!(T) get(T)()
    {
        union Buf
        {
            TypeInfo info;
            DecayStaticToDynamicArray!(T) result;
        };
        Buf buf = { typeid(DecayStaticToDynamicArray!(T)) };
        if (fptr(OpID.get, &store, &buf))
        {
            throw new VariantException(type, typeid(T));
        }
        return buf.result;
    }

    /**
     * Returns the value stored in the $(D_PARAM VariantN) object,
     * explicitly converted (coerced) to the requested type $(D_PARAM
     * T). If $(D_PARAM T) is a string type, the value is formatted as
     * a string. If the $(D_PARAM VariantN) object is a string, a
     * parse of the string to type $(D_PARAM T) is attempted. If a
     * conversion is not possible, throws a $(D_PARAM
     * VariantException).
     */

    T coerce(T)()
    {
        static if (isNumeric!(T))
        {
            // maybe optimize this fella; handle ints separately
            return to!(T)(get!(real));
        }
        else static if (is(T : Object))
        {
            return to!(T)(get!(Object));
        }
        else static if (isSomeString!(T))
        {
            return to!(T)(toString);
        }
    }

    /**
     * Formats the stored value as a string.
     */
    
    string toString()
    {
        string result;
        fptr(OpID.toString, &store, &result) == 0 || assert(false);
        return result;
    }

    /**
     * Comparison for equality used by the "==" and "!="  operators.
     */

    // returns 1 if the two are equal
    int opEquals(T)(T rhs)
    {
        static if (is(T == VariantN))
            alias rhs temp;
        else
            auto temp = Variant(rhs);
        return fptr(OpID.compare, &store, &temp) == 0;
    }

    /**
     * Ordering comparison used by the "<", "<=", ">", and ">="
     * operators. In case comparison is not sensible between the held
     * value and $(D_PARAM rhs), an exception is thrown.
     */

    int opCmp(T)(T rhs)
    {
        static if (is(T == VariantN))
            alias rhs temp;
        else
            auto temp = Variant(rhs);
        auto result = fptr(OpID.compare, &store, &temp);
        if (result == int.min)
        {
            throw new VariantException(type, rhs.type);
        }
        return result;
    }

    /**
     * Computes the hash of the held value.
     */

    uint toHash()
    {
        return type.getHash(&store);
    }

    private VariantN opArithmetic(T, string op)(T other)
    {
        VariantN result;
        static if (is(T == VariantN))
        {
            if (convertsTo!(uint) && other.convertsTo!(uint))
                result = mixin("get!(uint) " ~ op ~ " other.get!(uint)");
            else if (convertsTo!(int) && other.convertsTo!(int))
                result = mixin("get!(int) " ~ op ~ " other.get!(int)");
            if (convertsTo!(ulong) && other.convertsTo!(ulong))
                result = mixin("get!(ulong) " ~ op ~ " other.get!(ulong)");
            else if (convertsTo!(long) && other.convertsTo!(long))
                result = mixin("get!(long) " ~ op ~ " other.get!(long)");
            else if (convertsTo!(double) && other.convertsTo!(double))
                result = mixin("get!(double) " ~ op ~ " other.get!(double)");
            else
                result = mixin("get!(real) " ~ op ~ " other.get!(real)");
        }
        else
        {
            if (is(typeof(T.max) : uint) && T.min == 0 && convertsTo!(uint))
                result = mixin("get!(uint) " ~ op ~ " other");
            else if (is(typeof(T.max) : int) && T.min < 0 && convertsTo!(int))
                result = mixin("get!(int) " ~ op ~ " other");
            if (is(typeof(T.max) : ulong) && T.min == 0 && convertsTo!(ulong))
                result = mixin("get!(ulong) " ~ op ~ " other");
            else if (is(typeof(T.max) : long) && T.min < 0 && convertsTo!(long))
                result = mixin("get!(long) " ~ op ~ " other");
            else if (is(T : double) && convertsTo!(double))
                result = mixin("get!(double) " ~ op ~ " other");
            else
                result = mixin("get!(real) " ~ op ~ " other");
        }
        return result;
    }

    private VariantN opLogic(T, string op)(T other)
    {
        VariantN result;
        static if (is(T == VariantN))
        {
            if (convertsTo!(uint) && other.convertsTo!(uint))
                result = mixin("get!(uint) " ~ op ~ " other.get!(uint)");
            else if (convertsTo!(int) && other.convertsTo!(int))
                result = mixin("get!(int) " ~ op ~ " other.get!(int)");
            if (convertsTo!(ulong) && other.convertsTo!(ulong))
                result = mixin("get!(ulong) " ~ op ~ " other.get!(ulong)");
            else
                result = mixin("get!(long) " ~ op ~ " other.get!(long)");
        }
        else
        {
            if (is(typeof(T.max) : uint) && T.min == 0 && convertsTo!(uint))
                result = mixin("get!(uint) " ~ op ~ " other");
            else if (is(typeof(T.max) : int) && T.min < 0 && convertsTo!(int))
                result = mixin("get!(int) " ~ op ~ " other");
            if (is(typeof(T.max) : ulong) && T.min == 0 && convertsTo!(ulong))
                result = mixin("get!(ulong) " ~ op ~ " other");
            else
                result = mixin("get!(long) " ~ op ~ " other");
        }
        return result;
    }

    /**
     * Arithmetic between $(D_PARAM VariantN) objects and numeric
     * values. All arithmetic operations return a $(D_PARAM VariantN)
     * object typed depending on the types of both values
     * involved. The conversion rules mimic D's built-in rules for
     * arithmetic conversions.
     */

    // Adapted from http://www.prowiki.org/wiki4d/wiki.cgi?DanielKeep/Variant
    // arithmetic
    VariantN opAdd(T)(T rhs) { return opArithmetic!(T, "+")(rhs); }
    ///ditto
    VariantN opSub(T)(T rhs) { return opArithmetic!(T, "-")(rhs); }
    ///ditto
    VariantN opSub_r(T)(T lhs)
    {
        return VariantN(lhs).opArithmetic!(VariantN, "-")(*this);
    }
    ///ditto
    VariantN opMul(T)(T rhs) { return opArithmetic!(T, "*")(rhs); }
    ///ditto
    VariantN opDiv(T)(T rhs) { return opArithmetic!(T, "/")(rhs); }
    ///ditto
    VariantN opDiv_r(T)(T lhs)
    {
        return VariantN(lhs).opArithmetic!(VariantN, "/")(*this);
    }
    ///ditto
    VariantN opMod(T)(T rhs) { return opArithmetic!(T, "%")(rhs); }
    ///ditto
    VariantN opMod_r(T)(T lhs)
    {
        return VariantN(lhs).opArithmetic!(VariantN, "%")(*this);
    }
    ///ditto
    VariantN opAnd(T)(T rhs) { return opLogic!(T, "&")(rhs); }
    ///ditto
    VariantN opOr(T)(T rhs) { return opLogic!(T, "|")(rhs); }
    ///ditto
    VariantN opXor(T)(T rhs) { return opLogic!(T, "^")(rhs); }
    ///ditto
    VariantN opShl(T)(T rhs) { return opLogic!(T, "<<")(rhs); }
    ///ditto
    VariantN opShl_r(T)(T lhs)
    {
        return VariantN(lhs).opLogic!(VariantN, "<<")(*this);
    }
    ///ditto
    VariantN opShr(T)(T rhs) { return opLogic!(T, ">>")(rhs); }
    ///ditto
    VariantN opShr_r(T)(T lhs)
    {
        return VariantN(lhs).opLogic!(VariantN, ">>")(*this);
    }
    ///ditto
    VariantN opUShr(T)(T rhs) { return opLogic!(T, ">>>")(rhs); }
    ///ditto
    VariantN opUShr_r(T)(T lhs)
    {
        return VariantN(lhs).opLogic!(VariantN, ">>>")(*this);
    }
    ///ditto
    VariantN opCat(T)(T rhs)
    {
        auto temp = *this;
        temp ~= rhs;
        return temp;
    }
    ///ditto
    VariantN opCat_r(T)(T rhs)
    {
        VariantN temp = rhs;
        temp ~= *this;
        return temp;
    }
 	
    ///ditto
    VariantN opAddAssign(T)(T rhs)  { return *this = *this + rhs; }
    ///ditto
    VariantN opSubAssign(T)(T rhs)  { return *this = *this - rhs; }
    ///ditto
    VariantN opMulAssign(T)(T rhs)  { return *this = *this * rhs; }
    ///ditto
    VariantN opDivAssign(T)(T rhs)  { return *this = *this / rhs; }
    ///ditto
    VariantN opModAssign(T)(T rhs)  { return *this = *this % rhs; }
    ///ditto
    VariantN opAndAssign(T)(T rhs)  { return *this = *this & rhs; }
    ///ditto
    VariantN opOrAssign(T)(T rhs)   { return *this = *this | rhs; }
    ///ditto
    VariantN opXorAssign(T)(T rhs)  { return *this = *this ^ rhs; }
    ///ditto
    VariantN opShlAssign(T)(T rhs)  { return *this = *this << rhs; }
    ///ditto
    VariantN opShrAssign(T)(T rhs)  { return *this = *this >> rhs; }
    ///ditto
    VariantN opUShrAssign(T)(T rhs) { return *this = *this >>> rhs; }
    ///ditto
    VariantN opCatAssign(T)(T rhs)
    {
        auto toAppend = VariantN(rhs);
        fptr(OpID.catAssign, &store, &toAppend) == 0 || assert(false);
        return *this;
    }

    /**
     * Array and associative array operations. If a $(D_PARAM
     * VariantN) contains an (associative) array, it can be indexed
     * into. Otherwise, an exception is thrown.
     *
     * Example:
     * ----
     * auto a = Variant(new int[10]);
     * a[5] = 42;
     * assert(a[5] == 42);
     * int[int] hash = [ 42:24 ];
     * a = hash;
     * assert(a[42] == 24);
     * ----
     *
     * Caveat:
     *
     * Due to limitations in current language, read-modify-write
     * operations $(D_PARAM op=) will not work properly:
     *
     * ----
     * Variant a = new int[10];
     * a[5] = 42;
     * a[5] += 8;
     * assert(a[5] == 50); // fails, a[5] is still 42
     * ----
     */
    VariantN opIndex(K)(K i)
    {
        auto result = VariantN(i);
        fptr(OpID.index, &store, &result) == 0 || assert(false);
        return result;
    }

    unittest
    {
        int[int] hash = [ 42:24 ];
        Variant v = hash;
        assert(v[42] == 24);
        v[42] = 5;
        assert(v[42] == 5);
    }

    /// ditto
    VariantN opIndexAssign(T, N)(T value, N i)
    {
        VariantN args[2] = [ VariantN(value), VariantN(i) ];
        fptr(OpID.indexAssign, &store, &args) == 0 || assert(false);
        return args[0];
    }

    /** If the $(D_PARAM VariantN) contains an (associative) array,
     * returns the length of that array. Otherwise, throws an
     * exception.
     */
    size_t length()
    {
        return cast(size_t) fptr(OpID.length, &store, null);
    }
}

/**
 * Algebraic data type restricted to a closed set of possible
 * types. It's an alias for a $(D_PARAM VariantN) with an
 * appropriately-constructed maximum size. $(D_PARAM Algebraic) is
 * useful when it is desirable to restrict what a discriminated type
 * could hold to the end of defining simpler and more efficient
 * manipulation.
 *
 * Future additions to $(D_PARAM Algebraic) will allow compile-time
 * checking that all possible types are handled by user code,
 * eliminating a large class of errors.
 *
 * Bugs:
 *
 * Currently, $(D_PARAM Algebraic) does not allow recursive data
 * types. They will be allowed in a future iteration of the
 * implementation.
 * 
 * Example:
 * ----
 * auto v = Algebraic!(int, double, string)(5);
 * assert(v.peek!(int));
 * v = 3.14;
 * assert(v.peek!(double));
 * // auto x = v.peek!(long); // won't compile, type long not allowed
 * // v = '1'; // won't compile, type char not allowed
 * ----
 */

template Algebraic(T...)
{
    alias VariantN!(maxSize!(T), T) Algebraic;
}

/**
 * $(D_PARAM Variant) is an alias for $(D_PARAM VariantN) instantiated
 * with the largest of $(D_PARAM creal), $(D_PARAM char[]), and
 * $(D_PARAM void delegate()). This ensures that $(D_PARAM Variant) is
 * large enough to hold all of D's predefined types, including all
 * numeric types, pointers, delegates, and class references.  You may
 * want to use $(D_PARAM VariantN) directly with a different maximum
 * size either for storing larger types, or for saving memory.
 */

alias VariantN!(maxSize!(creal, char[], void delegate())) Variant;

/**
 * Returns an array of variants constructed from $(D_PARAM args).
 * Example:
 * ----
 * auto a = variantArray(1, 3.14, "Hi!");
 * assert(a[1] == 3.14);
 * auto b = Variant(a); // variant array as variant
 * assert(b[1] == 3.14);
 * ----
 */

Variant[] variantArray(T...)(T args)
{
    Variant[] result;
    foreach (arg; args)
    {
        result ~= Variant(arg);
    }
    return result;
}

/**
 * Thrown in three cases:
 *
 * $(OL $(LI An uninitialized Variant is used in any way except
 * assignment and $(D_PARAM hasValue);) $(LI A $(D_PARAM get) or
 * $(D_PARAM coerce) is attempted with an incompatible target type;)
 * $(LI A comparison between $(D_PARAM Variant) objects of
 * incompatible types is attempted.))
 * 
 */

// @@@ BUG IN COMPILER. THE 'STATIC' BELOW SHOULD NOT COMPILE
static class VariantException : Exception
{
    /// The source type in the conversion or comparison
    TypeInfo source;
    /// The target type in the conversion or comparison
    TypeInfo target;
    this(string s)
    {
        super(s);
    }
    this(TypeInfo source, TypeInfo target)
    {
        super("Variant: attempting to use incompatible types "
                            ~ source.toString
                            ~ " and " ~ target.toString);
        this.source = source;
        this.target = target;
    }
}

unittest
{
    // try it with an oddly small size
    VariantN!(1) test;
    assert(test.size > 1);

    // variantArray tests
    auto heterogeneous = variantArray(1, 4.5, "hi");
    assert(heterogeneous.length == 3);
    auto variantArrayAsVariant = Variant(heterogeneous);
    assert(variantArrayAsVariant[0] == 1);
    assert(variantArrayAsVariant.length == 3);
    
    // array tests
    auto arr = Variant([1.2].dup);
    auto e = arr[0];
    assert(e == 1.2);
    arr[0] = 2.0;
    assert(arr[0] == 2);
    arr ~= 4.5;
    assert(arr[1] == 4.5);

    // general tests
    Variant a;
    auto b = Variant(5);
    assert(!b.peek!(real) && b.peek!(int));
    // assign
    a = *b.peek!(int);
    // comparison
    assert(a == b, a.type.toString ~ " " ~ b.type.toString);
    auto c = Variant("this is a string");
    assert(a != c);
    // comparison via implicit conversions
    a = 42; b = 42.0; assert(a == b);
        
    // try failing conversions
    bool failed = false;
    try
    {
        auto d = c.get!(int);
    }
    catch (Exception e)
    {
        //writeln(stderr, e.toString);
        failed = true;
    }
    assert(failed); // :o)

    // toString tests
    a = Variant(42); assert(a.toString == "42");
    a = Variant(42.22); assert(a.toString == "42.22");

    // coerce tests
    a = Variant(42.22); assert(a.coerce!(int) == 42);
    a = cast(short) 5; assert(a.coerce!(double) == 5);

    // Object tests
    class B1 {}
    class B2 : B1 {}
    a = new B2;
    assert(a.coerce!(B1) !is null);
    a = new B1;
    assert(a.coerce!(B2) is null);
    a = cast(Object) new B2; // lose static type info; should still work
    assert(a.coerce!(B2) !is null);

//     struct Big { int a[45]; }
//     a = Big.init;

    // hash
    assert(a.toHash != 0);
}

// tests adapted from
// http://www.dsource.org/projects/tango/browser/trunk/tango/core/Variant.d?rev=2601
unittest
{
    Variant v;
 	
    assert(!v.hasValue);
    v = 42;
    assert( v.peek!(int) );
    assert( v.convertsTo!(long) );
    assert( v.get!(int) == 42 );
    assert( v.get!(long) == 42L );
    assert( v.get!(ulong) == 42uL );
 	
    // should be string... @@@BUG IN COMPILER
    v = "Hello, World!"c;
    assert( v.peek!(string) );

    assert( v.get!(string) == "Hello, World!" );
    assert(!is(char[] : wchar[]));
    assert( !v.convertsTo!(wchar[]) );
    assert( v.get!(string) == "Hello, World!" ); 	

    v = [1,2,3,4,5];
    assert( v.peek!(int[]) );
    assert( v.get!(int[]) == [1,2,3,4,5] );
 	
    v = 3.1413;
    assert( v.peek!(double) );
    assert( v.convertsTo!(real) );
    //@@@ BUG IN COMPILER: DOUBLE SHOULD NOT IMPLICITLY CONVERT TO FLOAT
    assert( !v.convertsTo!(float) );
    assert( *v.peek!(double) == 3.1413 );

    auto u = Variant(v);
    assert( u.peek!(double) );
    assert( *u.peek!(double) == 3.1413 ); 	

    // operators
    v = 38;
    assert( v + 4 == 42 );
    assert( 4 + v == 42 );
    assert( v - 4 == 34 );
    assert( 4 - v == -34 );
    assert( v * 2 == 76 );
    assert( 2 * v == 76 );
    assert( v / 2 == 19 );
    assert( 2 / v == 0 );
    assert( v % 2 == 0 );
    assert( 2 % v == 2 );
    assert( (v & 6) == 6 );
    assert( (6 & v) == 6 );
    assert( (v | 9) == 47 );
    assert( (9 | v) == 47 );
    assert( (v ^ 5) == 35 );
    assert( (5 ^ v) == 35 );
    assert( v << 1 == 76 );
    assert( 1 << Variant(2) == 4 );
    assert( v >> 1 == 19 );
    assert( 4 >> Variant(2) == 1 );
    assert( Variant("abc") ~ "def" == "abcdef" );
    assert( "abc" ~ Variant("def") == "abcdef" );
 	
    v = 38;
    v += 4;
    assert( v == 42 );
    v = 38; v -= 4; assert( v == 34 );
    v = 38; v *= 2; assert( v == 76 );
    v = 38; v /= 2; assert( v == 19 );
    v = 38; v %= 2; assert( v == 0 );
    v = 38; v &= 6; assert( v == 6 );
    v = 38; v |= 9; assert( v == 47 );
    v = 38; v ^= 5; assert( v == 35 );
    v = 38; v <<= 1; assert( v == 76 );
    v = 38; v >>= 1; assert( v == 19 );
 	
    v = "abc";
    v ~= "def";
    assert( v == "abcdef", *v.peek!(char[]) );
    assert( Variant(0) < Variant(42) );
    assert( Variant(42) > Variant(0) );
    assert( Variant(42) > Variant(0.1) );
    assert( Variant(42.1) > Variant(1) );
    assert( Variant(21) == Variant(21) );
    assert( Variant(0) != Variant(42) );
    assert( Variant("bar") == Variant("bar") );
    assert( Variant("foo") != Variant("bar") );

    {
        auto v1 = Variant(42);
        auto v2 = Variant("foo");
        auto v3 = Variant(1+2.0i);
 	
        int[Variant] hash;
        hash[v1] = 0;
        hash[v2] = 1;
        hash[v3] = 2;
 	
        assert( hash[v1] == 0 );
        assert( hash[v2] == 1 );
        assert( hash[v3] == 2 );
    }
    {
        int[char[]] hash;
        hash["a"] = 1;
        hash["b"] = 2;
        hash["c"] = 3;
        Variant vhash = hash;
 	
        assert( vhash.get!(int[char[]])["a"] == 1 );
        assert( vhash.get!(int[char[]])["b"] == 2 );
        assert( vhash.get!(int[char[]])["c"] == 3 );
    }
}
