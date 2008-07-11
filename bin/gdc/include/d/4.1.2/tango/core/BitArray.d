/**
 * This module contains a packed bit array implementation in the style of D's
 * built-in dynamic arrays.
 *
 * Copyright: Copyright (C) 2005-2006 Digital Mars, www.digitalmars.com.
 *            All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Walter Bright, Sean Kelly
 */
module tango.core.BitArray;


private import tango.core.BitManip;


/**
 * This struct represents an array of boolean values, each of which occupy one
 * bit of memory for storage.  Thus an array of 32 bits would occupy the same
 * space as one integer value.  The typical array operations--such as indexing
 * and sorting--are supported, as well as bitwise operations such as and, or,
 * xor, and complement.
 */
struct BitArray
{
    size_t  len;
    uint*   ptr;


    /**
     * This initializes a BitArray of bits.length bits, where each bit value
     * matches the corresponding boolean value in bits.
     *
     * Params:
     *  bits = The initialization value.
     *
     * Returns:
     *  A BitArray with the same number and sequence of elements as bits.
     */
    static BitArray opCall( bool[] bits )
    {
        BitArray temp;

        temp.length = bits.length;
        foreach( pos, val; bits )
            temp[pos] = val;
        return temp;
    }

    /**
     * Get the number of bits in this array.
     *
     * Returns:
     *  The number of bits in this array.
     */
    size_t length()
    {
        return len;
    }


    /**
     * Resizes this array to newlen bits.  If newlen is larger than the current
     * length, the new bits will be initialized to zero.
     *
     * Params:
     *  newlen = The number of bits this array should contain.
     */
    void length( size_t newlen )
    {
        if( newlen != len )
        {
            auto olddim = dim();
            auto newdim = (newlen + 31) / 32;

            if( newdim != olddim )
            {
                // Create a fake array so we can use D's realloc machinery
                uint[] buf = ptr[0 .. olddim];

                buf.length = newdim; // realloc
                ptr = buf.ptr;
                if( newdim & 31 )
                {
                    // Set any pad bits to 0
                    ptr[newdim - 1] &= ~(~0 << (newdim & 31));
                }
            }
            len = newlen;
        }
    }


    /**
     * Gets the length of a uint array large enough to hold all stored bits.
     *
     * Returns:
     *  The size a uint array would have to be to store this array.
     */
    size_t dim()
    {
        return (len + 31) / 32;
    }


    /**
     * Duplicates this array, much like the dup property for built-in arrays.
     *
     * Returns:
     *  A duplicate of this array.
     */
    BitArray dup()
    {
        BitArray ba;

        uint[] buf = ptr[0 .. dim].dup;
        ba.len = len;
        ba.ptr = buf.ptr;
        return ba;
    }


    debug( UnitTest )
    {
      unittest
      {
        BitArray a;
        BitArray b;

        a.length = 3;
        a[0] = 1; a[1] = 0; a[2] = 1;
        b = a.dup;
        assert( b.length == 3 );
        for( int i = 0; i < 3; ++i )
        {
            assert( b[i] == (((i ^ 1) & 1) ? true : false) );
        }
      }
    }


    /**
     * Resets the length of this array to bits.length and then initializes this
     *
     * Resizes this array to hold bits.length bits and initializes each bit
     * value to match the corresponding boolean value in bits.
     *
     * Params:
     *  bits = The initialization value.
     */
    void opAssign( bool[] bits )
    {
        length = bits.length;
        foreach( i, b; bits )
        {
            (*this)[i] = b;
        }
    }


    /**
     * Map BitArray onto target, with numbits being the number of bits in the
     * array. Does not copy the data.  This is the inverse of opCast.
     *
     * Params:
     *  target  = The array to map.
     *  numbits = The number of bits to map in target.
     */
    void init( void[] target, size_t numbits )
    in
    {
        assert( numbits <= target.length * 8 );
        assert( (target.length & 3) == 0 );
    }
    body
    {
        ptr = cast(uint*)target.ptr;
        len = numbits;
    }


    debug( UnitTest )
    {
      unittest
      {
        BitArray a = [1,0,1,0,1];
        BitArray b;
        void[] buf;

        buf = cast(void[])a;
        b.init( buf, a.length );

        assert( b[0] == 1 );
        assert( b[1] == 0 );
        assert( b[2] == 1 );
        assert( b[3] == 0 );
        assert( b[4] == 1 );

        a[0] = 0;
        assert( b[0] == 0 );

        assert( a == b );
      }
    }


    /**
     * Reverses the contents of this array in place, much like the reverse
     * property for built-in arrays.
     *
     * Returns:
     *  A shallow copy of this array.
     */
    BitArray reverse()
    out( result )
    {
        assert( result == *this );
    }
    body
    {
        if( len >= 2 )
        {
            bool t;
            size_t lo, hi;

            lo = 0;
            hi = len - 1;
            for( ; lo < hi; ++lo, --hi )
            {
                t = (*this)[lo];
                (*this)[lo] = (*this)[hi];
                (*this)[hi] = t;
            }
        }
        return *this;
    }


    debug( UnitTest )
    {
      unittest
      {
        static bool[5] data = [1,0,1,1,0];
        BitArray b = data;
        b.reverse;

        for( size_t i = 0; i < data.length; ++i )
        {
            assert( b[i] == data[4 - i] );
        }
      }
    }


    /**
     * Sorts this array in place, with zero entries sorting before one.  This
     * is equivalent to the sort property for built-in arrays.
     *
     * Returns:
     *  A shallow copy of this array.
     */
    BitArray sort()
    out( result )
    {
        assert( result == *this );
    }
    body
    {
        if( len >= 2 )
        {
            size_t lo, hi;

            lo = 0;
            hi = len - 1;
            while( true )
            {
                while( true )
                {
                    if( lo >= hi )
                        goto Ldone;
                    if( (*this)[lo] == true )
                        break;
                    ++lo;
                }

                while( true )
                {
                    if( lo >= hi )
                        goto Ldone;
                    if( (*this)[hi] == false )
                        break;
                    --hi;
                }

                (*this)[lo] = false;
                (*this)[hi] = true;

                ++lo;
                --hi;
            }
            Ldone:
            ;
        }
        return *this;
    }


    debug( UnitTest )
    {
      unittest
      {
        static uint x = 0b1100011000;
        static BitArray ba = { 10, &x };

        ba.sort;
        for( size_t i = 0; i < 6; ++i )
            assert( ba[i] == false );
        for( size_t i = 6; i < 10; ++i )
            assert( ba[i] == true );
      }
    }


    /**
     * Operates on all bits in this array.
     *
     * Params:
     *  dg = The supplied code as a delegate.
     */
    int opApply( int delegate(inout bool) dg )
    {
        int result;

        for( size_t i = 0; i < len; ++i )
        {
            bool b = opIndex( i );
            result = dg( b );
            opIndexAssign( b, i );
            if( result )
                break;
        }
        return result;
    }


    /** ditto */
    int opApply( int delegate(inout size_t, inout bool) dg )
    {
        int result;

        for( size_t i = 0; i < len; ++i )
        {
            bool b = opIndex( i );
            result = dg( i, b );
            opIndexAssign( b, i );
            if( result )
                break;
        }
        return result;
    }


    debug( UnitTest )
    {
      unittest
      {
        BitArray a = [1,0,1];

        int i;
        foreach( b; a )
        {
            switch( i )
            {
            case 0: assert( b == true );  break;
            case 1: assert( b == false ); break;
            case 2: assert( b == true );  break;
            default: assert( false );
            }
            i++;
        }

        foreach( j, b; a )
        {
            switch( j )
            {
            case 0: assert( b == true );  break;
            case 1: assert( b == false ); break;
            case 2: assert( b == true );  break;
            default: assert( false );
            }
        }
      }
    }


    /**
     * Compares this array to another for equality.  Two bit arrays are equal
     * if they are the same size and contain the same series of bits.
     *
     * Params:
     *  rhs = The array to compare against.
     *
     * Returns:
     *  zero if not equal and non-zero otherwise.
     */
    int opEquals( BitArray rhs )
    {
        if( this.length != rhs.length )
            return 0; // not equal
        byte* p1 = cast(byte*)this.ptr;
        byte* p2 = cast(byte*)rhs.ptr;
        size_t n = this.length / 8;
        size_t i;
        for( i = 0; i < n; ++i )
        {
            if( p1[i] != p2[i] )
            return 0; // not equal
        }
        n = this.length & 7;
        ubyte mask = cast(ubyte)((1 << n) - 1);
        return (mask == 0) || (p1[i] & mask) == (p2[i] & mask);
    }

    debug( UnitTest )
    {
      unittest
      {
        BitArray a = [1,0,1,0,1];
        BitArray b = [1,0,1];
        BitArray c = [1,0,1,0,1,0,1];
        BitArray d = [1,0,1,1,1];
        BitArray e = [1,0,1,0,1];

        assert(a != b);
        assert(a != c);
        assert(a != d);
        assert(a == e);
      }
    }


    /**
     * Performs a lexicographical comparison of this array to the supplied
     * array.
     *
     * Params:
     *  rhs = The array to compare against.
     *
     * Returns:
     *  A value less than zero if this array sorts before the supplied array,
     *  zero if the arrays are equavalent, and a value greater than zero if
     *  this array sorts after the supplied array.
     */
    int opCmp( BitArray rhs )
    {
        auto len = this.length;
        if( rhs.length < len )
            len = rhs.length;
        ubyte* p1 = cast(ubyte*)this.ptr;
        ubyte* p2 = cast(ubyte*)rhs.ptr;
        size_t n = len / 8;
        size_t i;
        for( i = 0; i < n; ++i )
        {
            if( p1[i] != p2[i] )
            break; // not equal
        }
        for( size_t j = i * 8; j < len; ++j )
        {
            ubyte mask = cast(ubyte)(1 << j);
            int c;

            c = cast(int)(p1[i] & mask) - cast(int)(p2[i] & mask);
            if( c )
                return c;
        }
        return cast(int)this.len - cast(int)rhs.length;
    }

    debug( UnitTest )
    {
      unittest
      {
        BitArray a = [1,0,1,0,1];
        BitArray b = [1,0,1];
        BitArray c = [1,0,1,0,1,0,1];
        BitArray d = [1,0,1,1,1];
        BitArray e = [1,0,1,0,1];

        assert( a >  b );
        assert( a >= b );
        assert( a <  c );
        assert( a <= c );
        assert( a <  d );
        assert( a <= d );
        assert( a == e );
        assert( a <= e );
        assert( a >= e );
      }
    }


    /**
     * Convert this array to a void array.
     *
     * Returns:
     *  This array represented as a void array.
     */
    void[] opCast()
    {
        return cast(void[])ptr[0 .. dim];
    }


    debug( UnitTest )
    {
      unittest
      {
        BitArray a = [1,0,1,0,1];
        void[] v = cast(void[])a;

        assert( v.length == a.dim * uint.sizeof );
      }
    }


    /**
     * Support for index operations, much like the behavior of built-in arrays.
     *
     * Params:
     *  pos = The desired index position.
     *
     * In:
     *  pos must be less than the length of this array.
     *
     * Returns:
     *  The value of the bit at pos.
     */
    bool opIndex( size_t pos )
    in
    {
        assert( pos < len );
    }
    body
    {
        return cast(bool)bt( ptr, pos );
    }


    /**
     * Generates a copy of this array with the unary complement operation
     * applied.
     *
     * Returns:
     *  A new array which is the complement of this array.
     */
    BitArray opCom()
    {
        auto dim = this.dim();

        BitArray result;

        result.length = len;
        for( size_t i = 0; i < dim; ++i )
            result.ptr[i] = ~this.ptr[i];
        if( len & 31 )
            result.ptr[dim - 1] &= ~(~0 << (len & 31));
        return result;
    }


    debug( UnitTest )
    {
      unittest
      {
        BitArray a = [1,0,1,0,1];
        BitArray b = ~a;

        assert(b[0] == 0);
        assert(b[1] == 1);
        assert(b[2] == 0);
        assert(b[3] == 1);
        assert(b[4] == 0);
      }
    }


    /**
     * Generates a new array which is the result of a bitwise and operation
     * between this array and the supplied array.
     *
     * Params:
     *  rhs = The array with which to perform the bitwise and operation.
     *
     * In:
     *  rhs.length must equal the length of this array.
     *
     * Returns:
     *  A new array which is the result of a bitwise and with this array and
     *  the supplied array.
     */
    BitArray opAnd( BitArray rhs )
    in
    {
        assert( len == rhs.length );
    }
    body
    {
        auto dim = this.dim();

        BitArray result;

        result.length = len;
        for( size_t i = 0; i < dim; ++i )
            result.ptr[i] = this.ptr[i] & rhs.ptr[i];
        return result;
    }


    debug( UnitTest )
    {
      unittest
      {
        BitArray a = [1,0,1,0,1];
        BitArray b = [1,0,1,1,0];

        BitArray c = a & b;

        assert(c[0] == 1);
        assert(c[1] == 0);
        assert(c[2] == 1);
        assert(c[3] == 0);
        assert(c[4] == 0);
      }
    }


    /**
     * Generates a new array which is the result of a bitwise or operation
     * between this array and the supplied array.
     *
     * Params:
     *  rhs = The array with which to perform the bitwise or operation.
     *
     * In:
     *  rhs.length must equal the length of this array.
     *
     * Returns:
     *  A new array which is the result of a bitwise or with this array and
     *  the supplied array.
     */
    BitArray opOr( BitArray rhs )
    in
    {
        assert( len == rhs.length );
    }
    body
    {
        auto dim = this.dim();

        BitArray result;

        result.length = len;
        for( size_t i = 0; i < dim; ++i )
            result.ptr[i] = this.ptr[i] | rhs.ptr[i];
        return result;
    }


    debug( UnitTest )
    {
      unittest
      {
        BitArray a = [1,0,1,0,1];
        BitArray b = [1,0,1,1,0];

        BitArray c = a | b;

        assert(c[0] == 1);
        assert(c[1] == 0);
        assert(c[2] == 1);
        assert(c[3] == 1);
        assert(c[4] == 1);
      }
    }


    /**
     * Generates a new array which is the result of a bitwise xor operation
     * between this array and the supplied array.
     *
     * Params:
     *  rhs = The array with which to perform the bitwise xor operation.
     *
     * In:
     *  rhs.length must equal the length of this array.
     *
     * Returns:
     *  A new array which is the result of a bitwise xor with this array and
     *  the supplied array.
     */
    BitArray opXor( BitArray rhs )
    in
    {
        assert( len == rhs.length );
    }
    body
    {
        auto dim = this.dim();

        BitArray result;

        result.length = len;
        for( size_t i = 0; i < dim; ++i )
            result.ptr[i] = this.ptr[i] ^ rhs.ptr[i];
        return result;
    }


    debug( UnitTest )
    {
      unittest
      {
        BitArray a = [1,0,1,0,1];
        BitArray b = [1,0,1,1,0];

        BitArray c = a ^ b;

        assert(c[0] == 0);
        assert(c[1] == 0);
        assert(c[2] == 0);
        assert(c[3] == 1);
        assert(c[4] == 1);
      }
    }


    /**
     * Generates a new array which is the result of this array minus the
     * supplied array.  $(I a - b) for BitArrays means the same thing as
     * $(I a &amp; ~b).
     *
     * Params:
     *  rhs = The array with which to perform the subtraction operation.
     *
     * In:
     *  rhs.length must equal the length of this array.
     *
     * Returns:
     *  A new array which is the result of this array minus the supplied array.
     */
    BitArray opSub( BitArray rhs )
    in
    {
        assert( len == rhs.length );
    }
    body
    {
        auto dim = this.dim();

        BitArray result;

        result.length = len;
        for( size_t i = 0; i < dim; ++i )
            result.ptr[i] = this.ptr[i] & ~rhs.ptr[i];
        return result;
    }


    debug( UnitTest )
    {
      unittest
      {
        BitArray a = [1,0,1,0,1];
        BitArray b = [1,0,1,1,0];

        BitArray c = a - b;

        assert( c[0] == 0 );
        assert( c[1] == 0 );
        assert( c[2] == 0 );
        assert( c[3] == 0 );
        assert( c[4] == 1 );
      }
    }


    /**
     * Generates a new array which is the result of this array concatenated
     * with the supplied array.
     *
     * Params:
     *  rhs = The array with which to perform the concatenation operation.
     *
     * Returns:
     *  A new array which is the result of this array concatenated with the
     *  supplied array.
     */
    BitArray opCat( bool rhs )
    {
        BitArray result;

        result = this.dup;
        result.length = len + 1;
        result[len] = rhs;
        return result;
    }


    /** ditto */
    BitArray opCat_r( bool lhs )
    {
        BitArray result;

        result.length = len + 1;
        result[0] = lhs;
        for( size_t i = 0; i < len; ++i )
            result[1 + i] = (*this)[i];
        return result;
    }


    /** ditto */
    BitArray opCat( BitArray rhs )
    {
        BitArray result;

        result = this.dup();
        result ~= rhs;
        return result;
    }


    debug( UnitTest )
    {
      unittest
      {
        BitArray a = [1,0];
        BitArray b = [0,1,0];
        BitArray c;

        c = (a ~ b);
        assert( c.length == 5 );
        assert( c[0] == 1 );
        assert( c[1] == 0 );
        assert( c[2] == 0 );
        assert( c[3] == 1 );
        assert( c[4] == 0 );

        c = (a ~ true);
        assert( c.length == 3 );
        assert( c[0] == 1 );
        assert( c[1] == 0 );
        assert( c[2] == 1 );

        c = (false ~ a);
        assert( c.length == 3 );
        assert( c[0] == 0 );
        assert( c[1] == 1 );
        assert( c[2] == 0 );
      }
    }


    /**
     * Support for index operations, much like the behavior of built-in arrays.
     *
     * Params:
     *  b   = The new bit value to set.
     *  pos = The desired index position.
     *
     * In:
     *  pos must be less than the length of this array.
     *
     * Returns:
     *  The new value of the bit at pos.
     */
    bool opIndexAssign( bool b, size_t pos )
    in
    {
        assert( pos < len );
    }
    body
    {
        if( b )
            bts( ptr, pos );
        else
            btr( ptr, pos );
        return b;
    }


    /**
     * Updates the contents of this array with the result of a bitwise and
     * operation between this array and the supplied array.
     *
     * Params:
     *  rhs = The array with which to perform the bitwise and operation.
     *
     * In:
     *  rhs.length must equal the length of this array.
     *
     * Returns:
     *  A shallow copy of this array.
     */
    BitArray opAndAssign( BitArray rhs )
    in
    {
        assert( len == rhs.length );
    }
    body
    {
        auto dim = this.dim();

        for( size_t i = 0; i < dim; ++i )
            ptr[i] &= rhs.ptr[i];
        return *this;
    }


    debug( UnitTest )
    {
      unittest
      {
        BitArray a = [1,0,1,0,1];
        BitArray b = [1,0,1,1,0];

        a &= b;
        assert( a[0] == 1 );
        assert( a[1] == 0 );
        assert( a[2] == 1 );
        assert( a[3] == 0 );
        assert( a[4] == 0 );
      }
    }


    /**
     * Updates the contents of this array with the result of a bitwise or
     * operation between this array and the supplied array.
     *
     * Params:
     *  rhs = The array with which to perform the bitwise or operation.
     *
     * In:
     *  rhs.length must equal the length of this array.
     *
     * Returns:
     *  A shallow copy of this array.
     */
    BitArray opOrAssign( BitArray rhs )
    in
    {
        assert( len == rhs.length );
    }
    body
    {
        auto dim = this.dim();

        for( size_t i = 0; i < dim; ++i )
            ptr[i] |= rhs.ptr[i];
        return *this;
    }


    debug( UnitTest )
    {
      unittest
      {
        BitArray a = [1,0,1,0,1];
        BitArray b = [1,0,1,1,0];

        a |= b;
        assert( a[0] == 1 );
        assert( a[1] == 0 );
        assert( a[2] == 1 );
        assert( a[3] == 1 );
        assert( a[4] == 1 );
      }
    }


    /**
     * Updates the contents of this array with the result of a bitwise xor
     * operation between this array and the supplied array.
     *
     * Params:
     *  rhs = The array with which to perform the bitwise xor operation.
     *
     * In:
     *  rhs.length must equal the length of this array.
     *
     * Returns:
     *  A shallow copy of this array.
     */
    BitArray opXorAssign( BitArray rhs )
    in
    {
        assert( len == rhs.length );
    }
    body
    {
        auto dim = this.dim();

        for( size_t i = 0; i < dim; ++i )
            ptr[i] ^= rhs.ptr[i];
        return *this;
    }


    debug( UnitTest )
    {
      unittest
      {
        BitArray a = [1,0,1,0,1];
        BitArray b = [1,0,1,1,0];

        a ^= b;
        assert( a[0] == 0 );
        assert( a[1] == 0 );
        assert( a[2] == 0 );
        assert( a[3] == 1 );
        assert( a[4] == 1 );
      }
    }


    /**
     * Updates the contents of this array with the result of this array minus
     * the supplied array.  $(I a - b) for BitArrays means the same thing as
     * $(I a &amp; ~b).
     *
     * Params:
     *  rhs = The array with which to perform the subtraction operation.
     *
     * In:
     *  rhs.length must equal the length of this array.
     *
     * Returns:
     *  A shallow copy of this array.
     */
    BitArray opSubAssign( BitArray rhs )
    in
    {
        assert( len == rhs.length );
    }
    body
    {
        auto dim = this.dim();

        for( size_t i = 0; i < dim; ++i )
            ptr[i] &= ~rhs.ptr[i];
        return *this;
    }


    debug( UnitTest )
    {
      unittest
      {
        BitArray a = [1,0,1,0,1];
        BitArray b = [1,0,1,1,0];

        a -= b;
        assert( a[0] == 0 );
        assert( a[1] == 0 );
        assert( a[2] == 0 );
        assert( a[3] == 0 );
        assert( a[4] == 1 );
      }
    }


    /**
     * Updates the contents of this array with the result of this array
     * concatenated with the supplied array.
     *
     * Params:
     *  rhs = The array with which to perform the concatenation operation.
     *
     * Returns:
     *  A shallow copy of this array.
     */
    BitArray opCatAssign( bool b )
    {
        length = len + 1;
        (*this)[len - 1] = b;
        return *this;
    }


    debug( UnitTest )
    {
      unittest
      {
        BitArray a = [1,0,1,0,1];
        BitArray b;

        b = (a ~= true);
        assert( a[0] == 1 );
        assert( a[1] == 0 );
        assert( a[2] == 1 );
        assert( a[3] == 0 );
        assert( a[4] == 1 );
        assert( a[5] == 1 );

        assert( b == a );
      }
    }


    /** ditto */
    BitArray opCatAssign( BitArray rhs )
    {
        auto istart = len;
        length = len + rhs.length;
        for( auto i = istart; i < len; ++i )
            (*this)[i] = rhs[i - istart];
        return *this;
    }


    debug( UnitTest )
    {
      unittest
      {
        BitArray a = [1,0];
        BitArray b = [0,1,0];
        BitArray c;

        c = (a ~= b);
        assert( a.length == 5 );
        assert( a[0] == 1 );
        assert( a[1] == 0 );
        assert( a[2] == 0 );
        assert( a[3] == 1 );
        assert( a[4] == 0 );

        assert( c == a );
      }
    }
}
