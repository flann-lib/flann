/**
 * Variant
 * Written by Daniel Keep.
 *
 * I hereby release this code to the Public Domain; share and enjoy.
 */
module variant;

version( Tango )
{
    pragma(msg, `
    ** WARNING **

The Variant module does not fully support Tango.  Tango lacks string
formatters for some basic types, and thus does not pass the unit tests.
`);

    import tango.core.Exception : TracedException;
    import tango.core.Vararg : va_list;
    import tango.text.convert.Float;
    import tango.text.convert.Integer;
    import tango.text.convert.Layout : Layout;
    import tango.text.convert.Utf;

    private
    {
        alias tango.text.convert.Float.toUtf8 toUtf8;
        alias tango.text.convert.Integer.toUtf8 toUtf8;
        alias tango.text.convert.Utf.toUtf8 toUtf8;
    
        char[] toUtf8(bool v)
        {
            return v ? "true" : "false";
        }
    
        alias toUtf8 toString;
    
        Layout!(char) layout;
    }

    static this()
    {
        layout = new Layout!(char);
    }
}
else
{
    import std.format : doFormat;
    import std.stdarg : va_list;
    import std.string : toString;
    import std.utf : encode, toUTF8;
}

private template maxT(uint a, uint b)
{
    const maxT = (a > b) ? a : b;
}

private struct AtomicTypes
{
    union
    {
        bool _bool;
        char _char;
        wchar _wchar;
        dchar _dchar;
        byte _byte;
        short _short;
        int _int;
        long _long;
        ubyte _ubyte;
        ushort _ushort;
        uint _uint;
        ulong _ulong;
        float _float;
        double _double;
        real _real;
        ifloat _ifloat;
        idouble _idouble;
        ireal _ireal;
        void* ptr;
        void[] arr;
        Object obj;
        ubyte[maxT!(_real.sizeof,arr.sizeof)] data;
    }
}

private template isAtomicType(T)
{
    static if( is( T == bool )
            || is( T == char )
            || is( T == wchar )
            || is( T == dchar )
            || is( T == byte )
            || is( T == short )
            || is( T == int )
            || is( T == long )
            || is( T == ubyte )
            || is( T == ushort )
            || is( T == uint )
            || is( T == ulong )
            || is( T == float )
            || is( T == double )
            || is( T == real )
            || is( T == ifloat )
            || is( T == idouble )
            || is( T == ireal ) )
        const isAtomicType = true;
    else
        const isAtomicType = false;
}

private template isArray(T)
{
    static if( is( T U : U[] ) )
        const isArray = true;
    else
        const isArray = false;
}

private template isPointer(T)
{
    static if( is( T U : U* ) )
        const isPointer = true;
    else
        const isPointer = false;
}

private template isObject(T)
{
    static if( is( T : Object ) )
        const isObject = true;
    else
        const isObject = false;
}

private template isStaticArray(T)
{
    static if( is( typeof(T.init)[(T).sizeof / typeof(T.init).sizeof] == T ) )
        const isStaticArray = true;
    else
        const isStaticArray = false;
}

private bool isAny(T,argsT...)(T v, argsT args)
{
    foreach( arg ; args )
        if( v is arg ) return true;
    return false;
}

private
{
    const tibool = typeid(bool);
    const tichar = typeid(char);
    const tiwchar = typeid(wchar);
    const tidchar = typeid(dchar);
    const tibyte = typeid(byte);
    const tishort = typeid(short);
    const tiint = typeid(int);
    const tilong = typeid(long);
    const tiubyte = typeid(ubyte);
    const tiushort = typeid(ushort);
    const tiuint = typeid(uint);
    const tiulong = typeid(ulong);
    const tifloat = typeid(float);
    const tidouble = typeid(double);
    const tireal = typeid(real);
    const tiifloat = typeid(ifloat);
    const tiidouble = typeid(idouble);
    const tiireal = typeid(ireal);
}

private bool canImplicitCastTo(dsttypeT)(TypeInfo srctype)
{
    static if( is( dsttypeT == char ) )
        return isAny(srctype, tibool, tiubyte);

    else static if( is( dsttypeT == wchar ) )
        return isAny(srctype, tibool, tiubyte, tiushort, tichar);

    else static if( is( dsttypeT == dchar ) )
        return isAny(srctype, tibool, tiubyte, tiushort, tiuint, tichar,
                tiwchar);

    else static if( is( dsttypeT == byte ) )
        return isAny(srctype, tibool);

    else static if( is( dsttypeT == ubyte ) )
        return isAny(srctype, tibool, tichar);

    else static if( is( dsttypeT == short ) )
        return isAny(srctype, tibool, tibyte, tiubyte, tichar);

    else static if( is( dsttypeT == ushort ) )
        return isAny(srctype, tibool, tibyte, tiubyte, tichar, tiwchar);

    else static if( is( dsttypeT == int ) )
        return isAny(srctype, tibool, tibyte, tiubyte, tishort, tiushort,
                tichar, tiwchar);

    else static if( is( dsttypeT == uint ) )
        return isAny(srctype, tibool, tibyte, tiubyte, tishort, tiushort,
                tichar, tiwchar, tidchar);

    else static if( is( dsttypeT == long ) || is( dsttypeT == ulong ) )
        return isAny(srctype, tibool, tibyte, tiubyte, tishort, tiushort,
                    tiint, tiuint, tichar, tiwchar, tidchar);

    else static if( is( dsttypeT == float ) )
        return isAny(srctype, tibool, tibyte, tiubyte);

    else static if( is( dsttypeT == double ) )
        return isAny(srctype, tibool, tibyte, tiubyte, tifloat);

    else static if( is( dsttypeT == real ) )
        return isAny(srctype, tibool, tibyte, tiubyte, tifloat, tidouble);

    else static if( is( dsttypeT == idouble ) )
        return isAny(srctype, tiifloat);

    else static if( is( dsttypeT == ireal ) )
        return isAny(srctype, tiifloat, tiidouble);

    else
        return false;
}

version( Tango )
    alias TracedException BaseException;
else
    alias Exception BaseException;

class VariantTypeMismatchException : BaseException
{
    this(TypeInfo expected, TypeInfo got)
    {
        version( Tango )
            super("cannot convert "~expected.toUtf8
                    ~" value to a "~got.toUtf8);
        else
            super("cannot convert "~expected.toString
                    ~" value to a "~got.toString);
    }
}

private template storageT(T)
{
    static if( isStaticArray!(T) )
        alias typeof(T.dup) storageT;
    else
        alias T storageT;
}

struct Variant
{
    TypeInfo type = typeid(void);
    AtomicTypes value;

    static Variant opCall(T)(T value)
    {
        Variant _this;

        static if( isStaticArray!(T) )
            _this = value.dup;

        else
            _this = value;

        return _this;
    }

    Variant opAssign(T)(T value)
    {
        static if( isStaticArray!(T) )
        {
            return (*this = value.dup);
        }
        else
        {
            type = typeid(T);

            static if( isAtomicType!(T) )
            {
                mixin("this.value._"~T.stringof~"=value;");
            }
            else static if( isArray!(T) )
            {
                this.value.arr = (cast(void*)value.ptr)
                    [0 .. value.length];
            }
            else static if( isPointer!(T) )
            {
                this.value.ptr = cast(void*)T;
            }
            else static if( isObject!(T) )
            {
                this.value.obj = T;
            }
            else
            {
                if( T.sizeof <= this.value.data.length )
                {
                    this.value.data[0..T.sizeof] =
                        (cast(ubyte*)&value)[0..T.sizeof];
                }
                else
                {
                    auto buffer = (cast(ubyte*)&value)[0..T.sizeof].dup;
                    this.value.arr = cast(void[])buffer;
                }
            }
            return *this;
        }
    }

    bool isA(T)()
    {
        return cast(bool)(typeid(T) is type);
    }

    bool isImplicitly(T)()
    {
        return ( cast(bool)(typeid(T) is type)
                || canImplicitCastTo!(T)(type) );
    }

    storageT!(S) get(S)()
    {
        alias storageT!(S) T;

        if( type !is typeid(T)
                // Let D do runtime check itself
                && !isObject!(T)
                // Allow implicit upcasts
                && !canImplicitCastTo!(T)(type)
          )
            throw new VariantTypeMismatchException(type,typeid(T));

        static if( isAtomicType!(T) )
        {
            if( type is typeid(T) )
            {
                return mixin("this.value._"~T.stringof);
            }
            else
            {
                if( type is tibool ) return cast(T)this.value._bool;
                else if( type is tichar ) return cast(T)this.value._char;
                else if( type is tiwchar ) return cast(T)this.value._wchar;
                else if( type is tidchar ) return cast(T)this.value._dchar;
                else if( type is tibyte ) return cast(T)this.value._byte;
                else if( type is tishort ) return cast(T)this.value._short;
                else if( type is tiint ) return cast(T)this.value._int;
                else if( type is tilong ) return cast(T)this.value._long;
                else if( type is tiubyte ) return cast(T)this.value._ubyte;
                else if( type is tiushort ) return cast(T)this.value._ushort;
                else if( type is tiuint ) return cast(T)this.value._uint;
                else if( type is tiulong ) return cast(T)this.value._ulong;
                else if( type is tifloat ) return cast(T)this.value._float;
                else if( type is tidouble ) return cast(T)this.value._double;
                else if( type is tireal ) return cast(T)this.value._real;
                else if( type is tiifloat ) return cast(T)this.value._ifloat;
                else if( type is tiidouble ) return cast(T)this.value._idouble;
                else if( type is tiireal ) return cast(T)this.value._ireal;
                else
                    throw new VariantTypeMismatchException(type,typeid(T));
            }
        }
        else static if( isArray!(T) )
        {
            return (cast(typeof(T[0])*)this.value.arr.ptr)
                [0 .. this.value.arr.length];
        }
        else static if( isPointer!(T) )
        {
            return cast(T)this.value.ptr;
        }
        else static if( isObject!(T) )
        {
            return cast(T)this.value.obj;
        }
        else
        {
            if( T.sizeof <= this.value.data.length )
            {
                T result;
                (cast(ubyte*)&result)[0..T.sizeof] =
                    this.value.data[0..T.sizeof];
                return result;
            }
            else
            {
                T result;
                (cast(ubyte*)&result)[0..T.sizeof] =
                    (cast(ubyte[])this.value.arr)[0..T.sizeof];
                return result;
            }
        }
        assert(false);
    }

    typeof(T+T) opAdd(T)(T rhs)     { return get!(T) + rhs; }
    typeof(T+T) opAdd_r(T)(T lhs)   { return lhs + get!(T); }
    typeof(T-T) opSub(T)(T rhs)     { return get!(T) - rhs; }
    typeof(T-T) opSub_r(T)(T lhs)   { return lhs - get!(T); }
    typeof(T*T) opMul(T)(T rhs)     { return get!(T) * rhs; }
    typeof(T*T) opMul_r(T)(T lhs)   { return lhs * get!(T); }
    typeof(T/T) opDiv(T)(T rhs)     { return get!(T) / rhs; }
    typeof(T/T) opDiv_r(T)(T lhs)   { return lhs / get!(T); }
    typeof(T%T) opMod(T)(T rhs)     { return get!(T) % rhs; }
    typeof(T%T) opMod_r(T)(T lhs)   { return lhs % get!(T); }
    typeof(T&T) opAnd(T)(T rhs)     { return get!(T) & rhs; }
    typeof(T&T) opAnd_r(T)(T lhs)   { return lhs & get!(T); }
    typeof(T|T) opOr(T)(T rhs)      { return get!(T) | rhs; }
    typeof(T|T) opOr_r(T)(T lhs)    { return lhs | get!(T); }
    typeof(T^T) opXor(T)(T rhs)     { return get!(T) ^ rhs; }
    typeof(T^T) opXor_r(T)(T lhs)   { return lhs ^ get!(T); }
    typeof(T<<T) opShl(T)(T rhs)    { return get!(T) << rhs; }
    typeof(T<<T) opShl_r(T)(T lhs)  { return lhs << get!(T); }
    typeof(T>>T) opShr(T)(T rhs)    { return get!(T) >> rhs; }
    typeof(T>>T) opShr_r(T)(T lhs)  { return lhs >> get!(T); }
    typeof(T>>>T) opUShr(T)(T rhs)  { return get!(T) >>> rhs; }
    typeof(T>>>T) opUShr_r(T)(T lhs){ return lhs >>> get!(T); }
    typeof(T~T) opCat(T)(T rhs)     { return get!(T) ~ rhs; }
    typeof(T~T) opCat_r(T)(T lhs)   { return lhs ~ get!(T); }

    Variant opAddAssign(T)(T value) { return (*this = get!(T) + value); }
    Variant opSubAssign(T)(T value) { return (*this = get!(T) - value); }
    Variant opMulAssign(T)(T value) { return (*this = get!(T) * value); }
    Variant opDivAssign(T)(T value) { return (*this = get!(T) / value); }
    Variant opModAssign(T)(T value) { return (*this = get!(T) % value); }
    Variant opAndAssign(T)(T value) { return (*this = get!(T) & value); }
    Variant opOrAssign(T)(T value)  { return (*this = get!(T) | value); }
    Variant opXorAssign(T)(T value) { return (*this = get!(T) ^ value); }
    Variant opShlAssign(T)(T value) { return (*this = get!(T) << value); }
    Variant opShrAssign(T)(T value) { return (*this = get!(T) >> value); }
    Variant opUShrAssign(T)(T value){ return (*this = get!(T) >>> value); }
    Variant opCatAssign(T)(T value) { return (*this = get!(T) ~ value); }

    int opEquals(T)(T rhs)
    {
        static if( is( T == Variant ) )
            return opEqualsVariant(rhs);
        else
            return get!(T) == rhs;
    }
    int opCmp(T)(T rhs)
    {
        static if( is( T == Variant ) )
            return opCmpVariant(rhs);
        else
        {
            auto lhs = get!(T);
            return (lhs < rhs) ? -1 : (lhs == rhs) ? 0 : 1;
        }
    }
    hash_t toHash()
    {
        return type.getHash(data.ptr);
    }

    private int opEqualsVariant(Variant rhs)
    {
        if( type != rhs.type ) return false;
        return cast(bool) type.equals(data.ptr, rhs.data.ptr);
    }

    private int opCmpVariant(Variant rhs)
    {
        if( type != rhs.type )
            throw new VariantTypeMismatchException(type, rhs.type);
        return type.compare(data.ptr, rhs.data.ptr);
    }

    public	 void[] data()
    {
        if( type.tsize <= value.data.length )
            return cast(void[])(value.data);
        else
            return value.arr;
    }

    version( Tango )
    {
        alias toStringImpl toUtf8;
        version( PhobosCompatibility )
            alias toStringImpl toString;
    }
    else
        alias toStringImpl toString;

    public char[] toStringImpl()
    {
        // Special case: void type
        if( type is typeid(void) )
        {
            return "Variant.init";
        }
        // Special case: strings (for h3r3tic)
        else if( type is typeid(char[]) )
        {
            return get!(char[]);
        }
        else if( type is typeid(wchar[]) )
        {
            return .toUTF8(get!(wchar[]));
        }
        else if( type is typeid(dchar[]) )
        {
            return .toUTF8(get!(dchar[]));
        }	
        else if (type is typeid(float))
        {
        	return .toString(value._float);
        }
        // Everything else
        else
        {
            version( Tango )
            {
                TypeInfo[1] tis = [type];
                void* args = this.data.ptr;
    
                return layout.convert(tis, args, "{}");
            }
            else
            {
                char[] result;
                TypeInfo[1] tis = [type];
                doFormat((dchar c){encode(result,c);}, tis, cast(va_list)this.data.ptr);
                return result;
            }
        }
    }
}

version( Tango )
{
    version( PhobosCompatibility ) {}
    else
        version = Tango_NoUnittests;
}

version( Tango_NoUnittests )
{
    unittest
    {
        pragma(msg,
`    ** WARNING **

The Variant unittests cannot currently be run under Tango without the
PhobosCompatibility version flag.  Why?  Because I can't be bothered to write
all the unit tests out twice just because Tango uses toUtf8 instead of
toString.
`);
    }
}
else
{
    unittest
    {
        Variant v;
        assert( v.isA!(void), v.type.toString );

        v = 42;
        assert( v.isA!(int), v.type.toString );
        assert( v.isImplicitly!(long), v.type.toString );
        assert( v.isImplicitly!(ulong), v.type.toString );
        assert( !v.isImplicitly!(uint), v.type.toString );
        assert( v.get!(int) == 42 );
        assert( v.get!(long) == 42L );
        assert( v.get!(ulong) == 42uL );

        v = "Hello, World!"c;
        assert( v.isA!(char[]), v.type.toString );
        assert( !v.isImplicitly!(wchar[]), v.type.toString );
        assert( v.get!(char[]) == "Hello, World!" );

        v = [1,2,3,4,5];
        assert( v.isA!(int[]), v.type.toString );
        assert( v.get!(int[]) == [1,2,3,4,5] );

        v = 3.1413;
        assert( v.isA!(double), v.type.toString );
        assert( v.isImplicitly!(real), v.type.toString );
        assert( !v.isImplicitly!(float), v.type.toString );
        assert( v.get!(double) == 3.1413 );
        
        auto u = Variant(v);
        assert( u.isA!(double), u.type.toString );
        assert( u.get!(double) == 3.1413 );

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

        v = 38; v += 4; assert( v == 42 );
        v = 38; v -= 4; assert( v == 34 );
        v = 38; v *= 2; assert( v == 76 );
        v = 38; v /= 2; assert( v == 19 );
        v = 38; v %= 2; assert( v == 0 );
        v = 38; v &= 6; assert( v == 6 );
        v = 38; v |= 9; assert( v == 47 );
        v = 38; v ^= 5; assert( v == 35 );
        v = 38; v <<= 1; assert( v == 76 );
        v = 38; v >>= 1; assert( v == 19 );

        v = "abc"; v ~= "def"; assert( v == "abcdef" );

        v = Variant.init;   assert( v.toString == "Variant.init", v.toString );
        v = 42;             assert( v.toString == "42", v.toString );
        v = "abc";          assert( v.toString == "abc", v.toString );
        v = [1,2,3];        assert( v.toString == "[1,2,3]", v.toString );
        v = 1+2.0i;         assert( v.toString == "1+2i", v.toString );

        assert( Variant(0) < Variant(42) );
        assert( Variant(42) > Variant(0) );
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
}