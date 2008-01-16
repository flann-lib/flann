/**
 * The traits module defines tools useful for obtaining detailed type
 * information at compile-time.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly
 */
module tango.core.Traits;


/**
 *
 */
template isCharType( T )
{
    const bool isCharType = is( T == char )  ||
                            is( T == wchar ) ||
                            is( T == dchar );
}


/**
 *
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
 *
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
 *
 */
template isIntegerType( T )
{
    const bool isIntegerType = isSignedIntegerType!(T) ||
                               isUnsignedIntegerType!(T);
}


/**
 *
 */
template isRealType( T )
{
    const bool isRealType = is( T == float )  ||
                            is( T == double ) ||
                            is( T == real );
}


/**
 *
 */
template isComplexType( T )
{
    const bool isComplexType = is( T == cfloat )  ||
                               is( T == cdouble ) ||
                               is( T == creal );
}


/**
 *
 */
template isImaginaryType( T )
{
    const bool isImaginaryType = is( T == ifloat )  ||
                                 is( T == idouble ) ||
                                 is( T == ireal );
}


/**
 *
 */
template isFloatingPointType( T )
{
    const bool isFloatingPointType = isRealType!(T)    ||
                                     isComplexType!(T) ||
                                     isImaginaryType!(T);
}


/**
 *
 */
template isPointerType( T )
{
    const bool isPointerType = is( typeof(*T) );
}


/**
 *
 */
template isReferenceType( T )
{

    const bool isReferenceType = isPointerType!(T)  ||
                               is( T == class )     ||
                               is( T == interface ) ||
                               is( T == delegate );
}


/**
 *
 */
template isDynamicArrayType( T )
{
    const bool isDynamicArrayType = is( typeof(T.init[0])[] == T );
}


/**
 *
 */
template isStaticArrayType( T )
{
    const bool isStaticArrayType = is( typeof(T.init)[(T).sizeof / typeof(T.init).sizeof] == T );
}


/**
 *
 */
private template isAssocArrayType( T )
{
    const bool isAssocArrayType = is( typeof(T.init.values[0])[typeof(T.init.keys[0])] == T );
}


/**
 *
 */
template isCallableType( T )
{
    const bool isCallableType = is( T == function )             ||
                                is( typeof(*T) == function )    ||
                                is( T == delegate )             ||
                                is( typeof(T.opCall) == function );
}


/**
 *
 */
template ReturnTypeOf( Fn )
{
    static if( is( Fn Ret == return ) )
        alias Ret ReturnTypeOf;
    else
        static assert( false, "Argument has no return type." );
}


/**
 *
 */
template ReturnTypeOf( alias fn )
{
    alias ReturnTypeOf!(typeof(fn)) ReturnTypeOf;
}


/**
 *
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
 *
 */
template ParameterTupleOf( alias fn )
{
    alias ParameterTupleOf!(typeof(fn)) ParameterTupleOf;
}


/**
 *
 */
template BaseTypeTupleOf( T )
{
    static if( is( T Base == super ) )
        alias Base BaseTypeTupleOf;
    else
        static assert( false, "Argument is not a class or interface." );
}
