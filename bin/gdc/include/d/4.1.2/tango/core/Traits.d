/**
 * The traits module defines tools useful for obtaining detailed compile-time
 * information about a type.  Please note that the mixed naming scheme used in
 * this module is intentional.  Templates which evaluate to a type follow the
 * naming convention used for types, and templates which evaluate to a value
 * follow the naming convention used for functions.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly
 */
module tango.core.Traits;


/**
 * Evaluates to true if T is char, wchar, or dchar.
 */
template isCharType( T )
{
    const bool isCharType = is( T == char )  ||
                            is( T == wchar ) ||
                            is( T == dchar );
}


/**
 * Evaluates to true if T is a signed integer type.
 */
template isSignedIntegerType( T )
{
    const bool isSignedIntegerType = is( T == byte )  ||
                                     is( T == short ) ||
                                     is( T == int )   ||
                                     is( T == long )/+||
                                     is( T == cent  )+/;
}


/**
 * Evaluates to true if T is an unsigned integer type.
 */
template isUnsignedIntegerType( T )
{
    const bool isUnsignedIntegerType = is( T == ubyte )  ||
                                       is( T == ushort ) ||
                                       is( T == uint )   ||
                                       is( T == ulong )/+||
                                       is( T == ucent  )+/;
}


/**
 * Evaluates to true if T is a signed or unsigned integer type.
 */
template isIntegerType( T )
{
    const bool isIntegerType = isSignedIntegerType!(T) ||
                               isUnsignedIntegerType!(T);
}


/**
 * Evaluates to true if T is a real floating-point type.
 */
template isRealType( T )
{
    const bool isRealType = is( T == float )  ||
                            is( T == double ) ||
                            is( T == real );
}


/**
 * Evaluates to true if T is a complex floating-point type.
 */
template isComplexType( T )
{
    const bool isComplexType = is( T == cfloat )  ||
                               is( T == cdouble ) ||
                               is( T == creal );
}


/**
 * Evaluates to true if T is an imaginary floating-point type.
 */
template isImaginaryType( T )
{
    const bool isImaginaryType = is( T == ifloat )  ||
                                 is( T == idouble ) ||
                                 is( T == ireal );
}


/**
 * Evaluates to true if T is any floating-point type: real, complex, or
 * imaginary.
 */
template isFloatingPointType( T )
{
    const bool isFloatingPointType = isRealType!(T)    ||
                                     isComplexType!(T) ||
                                     isImaginaryType!(T);
}


/**
 * Evaluates to true if T is a pointer type.
 */
template isPointerType( T )
{
    const bool isPointerType = is( typeof(*T) );
}


/**
 * Evaluates to true if T is a a pointer, class, interface, or delegate.
 */
template isReferenceType( T )
{

    const bool isReferenceType = isPointerType!(T)  ||
                               is( T == class )     ||
                               is( T == interface ) ||
                               is( T == delegate );
}


/**
 * Evaulates to true if T is a dynamic array type.
 */
template isDynamicArrayType( T )
{
    const bool isDynamicArrayType = is( typeof(T.init[0])[] == T );
}


private template isStaticArrayTypeInst( T )
{
    const T isStaticArrayTypeInst = void;
}


/**
 * Evaluates to true if T is a static array type.
 */
template isStaticArrayType( T )
{
    static if( is( typeof(T.length) ) && !is( typeof(T) == typeof(T.init) ) )
    {
        const bool isStaticArrayType = is( T == typeof(T[0])[isStaticArrayTypeInst!(T).length] );
    }
    else
    {
        const bool isStaticArrayType = false;
    }
}


/**
 * Evaluates to true if T is an associative array type.
 */
private template isAssocArrayType( T )
{
    const bool isAssocArrayType = is( typeof(T.init.values[0])[typeof(T.init.keys[0])] == T );
}


/**
 * Evaluates to true if T is a function, function pointer, delegate, or
 * callable object.
 */
template isCallableType( T )
{
    const bool isCallableType = is( T == function )             ||
                                is( typeof(*T) == function )    ||
                                is( T == delegate )             ||
                                is( typeof(T.opCall) == function );
}


/**
 * Evaluates to the return type of Fn.  Fn is required to be a callable type.
 */
template ReturnTypeOf( Fn )
{
    static if( is( Fn Ret == return ) )
        alias Ret ReturnTypeOf;
    else
        static assert( false, "Argument has no return type." );
}


/**
 * Evaluates to the return type of fn.  fn is required to be callable.
 */
template ReturnTypeOf( alias fn )
{
    static if( is( typeof(fn) Base == typedef ) )
        alias ReturnTypeOf!(Base) ReturnTypeOf;
    else
        alias ReturnTypeOf!(typeof(fn)) ReturnTypeOf;
}


/**
 * Evaluates to a tuple representing the parameters of Fn.  Fn is required to
 * be a callable type.
 */
template ParameterTupleOf( Fn )
{
    static if( is( Fn Params == function ) )
        alias Params ParameterTupleOf;
    else static if( is( Fn Params == delegate ) )
        alias ParameterTupleOf!(Params) ParameterTupleOf;
    else static if( is( Fn Params == Params* ) )
        alias ParameterTupleOf!(Params) ParameterTupleOf;
    else
        static assert( false, "Argument has no parameters." );
}


/**
 * Evaluates to a tuple representing the parameters of fn.  n is required to
 * be callable.
 */
template ParameterTupleOf( alias fn )
{
    static if( is( typeof(fn) Base == typedef ) )
        alias ParameterTupleOf!(Base) ParameterTupleOf;
    else
        alias ParameterTupleOf!(typeof(fn)) ParameterTupleOf;
}


/**
 * Evaluates to a tuple representing the ancestors of T.  T is required to be
 * a class or interface type.
 */
template BaseTypeTupleOf( T )
{
    static if( is( T Base == super ) )
        alias Base BaseTypeTupleOf;
    else
        static assert( false, "Argument is not a class or interface." );
}
