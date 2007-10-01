/**
 * functools -- Functional programming tools.
 * Written by Daniel Keep.
 * Released under the BSDv2 license.
 */
/*
  Copyright © 2007, Daniel Keep
  All rights reserved.
  
  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
  
  * Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.
  * The names of the contributors may be used to endorse or promote
  products derived from this software without specific prior written
  permission.
  
  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.
*/
module functools;

template tIsArray(tType)
{
    static if( is( tType T : T[] ) )
        const bool tIsArray = true;
    else
        const bool tIsArray = false;
}

template tIsHash(tType)
{
    static if( tType.mangleof[0..1] == "H" )
        const bool tIsHash = true;
    else
        const bool tIsHash = false;
}

template tHashTypes(tType)
{
    static assert( tIsHash!(tType) );
    private tType h;

    static if( is( typeof(h.keys) tK : tK[] ) )
        alias tK tKey;
    else
        static assert(false, "Could not derive hash key type!");

    static if( is( typeof(h.values) tV : tV[] ) )
        alias tV tValue;
    else
        static assert(false, "Could not derive hash value type!");
}

template tHasOpApply(tType)
{
    alias tiHasOpApply!(tType).result tHasOpApply;
}

template tiHasOpApply(tType)
{
    tType inst;
    static if( is( typeof(&inst.opApply) tF ) )
        const result = true;
    else
        const result = false;
}

template tHasOpApplyReverse(tType)
{
    alias tiHasOpApplyReverse!(tType).result tHasOpApplyReverse;
}

template tiHasOpApplyReverse(tType)
{
    tType inst;
    static if( is( typeof(&inst.opApplyReverse) tF ) )
        const result = true;
    else
        const result = false;
}

template tIteratorType(tFn)
{
    static if( is( tFn tDg == delegate ) )
        alias tIteratorType!(tDg) tIteratorType;
    else static if( is( tFn tArgs == function ) )
        static if( is( tArgs[0] tDg == delegate ) )
            static if( is( tDg tDgArgs == function ) )
                alias tDgArgs[0] tIteratorType;
}

template tMapResult(tType, tOp)
{
    static if( tIsArray!(tType) )
    {
        static if( is( tOp tRet == return ) )
            alias tRet[] tMapResult;
    }
    else static if( tIsHash!(tType) )
    {
        static if( is( tOp tRet == return ) )
            alias tRet[tHashTypes!(tType).tKey] tMapResult;
    }
    else static if( tHasOpApply!(tType) )
    {
        static if( is( tOp tRet == return ) )
            alias tRet[] tMapResult;
    }
    /+else static if( tHasOpApplyReverse!(tType) )
    {
        static if( is( tOp tRet == return ) )
            alias tRet[] tMapResult;
    }+/
    else static if( tIsIteratorFunction!(tType) )
    {
        static if( is( tOp tRet == return ) )
            alias tRet[] tMapResult;
    }
    else
    {
        static assert(false, "Unsupported type: "~tType.stringof);
    }
}

template tFilterResult(tType)
{
    static if( tIsArray!(tType) )
    {
        alias tType tFilterResult;
    }
    else static if( tIsHash!(tType) )
    {
        alias tType tFilterResult;
    }
    else static if( tHasOpApply!(tType) )
    {
        alias tIteratorType!(tIteratorClass!(tType))[] tFilterResult;
    }
    /+else static if( tHasOpApplyReverse!(tType) )
    {
        alias tIteratorType!(tType)[] tFilterResult;
    }+/
    else static if( tIsIteratorFunction!(tType) )
    {
        alias tIteratorType!(tType)[] tFilterResult;
    }
    else
    {
        static assert(false, "Unsupported type: "~tType.stringof);
    }
}

template tIteratorClass(tType)
{
    alias tiIteratorClass!(tType).result tIteratorClass;
}

template tiIteratorClass(tType)
{
    private tType inst;
    alias typeof(&inst.opApply) result;
}

template tReduceResult(tOp)
{
    static if( is( tOp tFn == delegate ) )
        alias tReduceResult!(tFn) tReduceResult;
    else static if( is( tOp tResult == return ) )
        alias tResult tReduceResult;
}

typedef int ReduceDefault;

tMapResult!(tType, tOp) map(tType, tOp)(tType coll, tOp op)
{
    static if( tIsArray!(tType) )
    {
        tMapResult!(tType, tOp) result;
        result.length = coll.length;

        foreach( i, v ; coll )
            result[i] = op(v);

        return result;
    }
    else static if( tIsHash!(tType) )
    {
        tMapResult!(tType, tOp) result;

        foreach( k, v ; coll )
        {
            static if( is( typeof(op(k,v)) ) )
            {
                result[k] = op(k, v);
            }
            else
            {
                result[k] = op(v);
            }
        }

        return result;
    }
    else static if( tHasOpApply!(tType) )
    {
        tMapResult!(tType, tOp) result;

        foreach( v ; coll )
        {
            result.length = result.length + 1;
            result[$-1] = op(v);
        }

        return result;
    }
    /+else static if( tIsIteratorFunction!(tType) )
    {
        tMapResult!(tType, tOp) result;

        int ifr = 0;
        tMapResult!(tType) temp;
        temp.length = 1;
        scope(exit) temp.length = 0;

        do
        {
            ifr = coll((typeof(temp[0]) v){temp[0] = v});
            if( result )
                break;
            else
            {
                result.length = result.length + 1;
                result[$-1] = op(temp[0]);
            }
        }
        while( true );

        return result;
    }+/
    else
    {
        static assert(false, "Unsupported type: "~tType.mangleof);
    }
}

tFilterResult!(tType) filter(tType, tOp)(tType coll, tOp op)
{
    static if( tIsArray!(tType) )
    {
        tFilterResult!(tType) result;
        result.length = coll.length;
        uint l = 0;

        foreach( v ; coll )
        {
            if( op(v) )
                result[l++] = v;
        }

        return result[0..l];
    }
    else static if( tIsHash!(tType) )
    {
        tFilterResult!(tType) result;

        foreach( k,v ; coll )
        {
            bool use;
            static if( is( typeof(op(k,v)) ) )
                use = op(k, v);
            else
                use = op(v);
            if( use )
            result[k] = v;
        }

        return result;
    }
    else static if( tHasOpApply!(tType) )
    {
        tFilterResult!(tType) result;

        foreach( v ; coll )
        {
            if( op(v) )
            {
                result.length = result.length + 1;
                result[$-1] = v;
            }
        }

        return result;
    }
    else
    {
        static assert(false, "Unsupported type: "~tType.mangleof);
    }
}

tReduceResult!(tOp) reduce(tType, tOp, tInit = ReduceDefault)(
        tType seq, tOp op,
        tInit init = ReduceDefault.init)
{
    static if( tIsArray!(tType) || tHasOpApply!(tType) )
    {
        tReduceResult!(tOp) result;
        static if( !is( tInit == ReduceDefault ) )
            result = init;

        foreach( v ; seq )
            result = op(result, v);

        return result;
    }
    else
    {
        static assert(false, "Unsupported type: "~tType.mangleof);
    }
}

version( functools_test ):

import std.stdio;

class Naturals(int tpMax)
{
    int opApply(int delegate(inout int) dg)
    {
        int result = 0;

        for( int i=1; i<=tpMax; i++ )
        {
            result = dg(i);
            if( result )
                break;
        }

        return result;
    }
}

void main()
{
    //
    // map
    //

    writefln("Testing map(seq, op)...");

    // Arrays
    {
        int[] naturals = [1,2,3,4,5,6,7,8,9];
        auto squares = map(naturals, (int v) { return v*v; });

        writefln("squares: %s", squares);
    }

    {
        int[] naturals = [1,2,3,4,5,6,7,8,9];
        auto halves = map(naturals, (int v) { return cast(real)v/2.; });

        writefln("halves: %s", halves);
    }

    // Hashes
    {
        char[int] table;
        table[1] = char.init;
        table[2] = char.init;
        table[3] = char.init;
    
        auto new_table = map(table,
            (int k, char v) { return '0'+k; });
    
        writef("new_table: [");
        bool first = true;
        foreach( k,v ; new_table )
        {
            if( !first )
                writef(", ");
            writef("%d -> '%s'", k, v);
            first = false;
        }
        writefln("]");
    }

    {
        bool[char] table;
        table['a'] = false;
        table['b'] = false;
        table['c'] = false;

        auto new_table = map(table,
            (char k, bool v) { return cast(ubyte)k; });

        writef("new_table: [");
        bool first = true;
        foreach( k,v ; new_table )
        {
            if( !first )
                writef(", ");
            writef("'%s' -> %d", k, v);
            first = false;
        }
        writefln("]");
    }

    // Objects
    {
        scope naturals = new Naturals!(9);
        auto cubes = map(naturals, (int v) { return v*v*v; });

        writefln("cubes: %s", cubes);
    }

    //
    // filter
    //

    writefln("\nTesting filter(seq, op)...");

    // Arrays
    {
        int[] naturals = [1,2,3,4,5,6,7,8,9];
        auto evens = filter(naturals, (int v) { return v%2==0; });

        writefln("evens: %s", evens);
    }

    // Hashes
    {
        dchar[int] table;
        table[1] = 'a';
        table[2] = 'b';
        table[3] = 'c';

        auto new_table = filter(table,
            (int k, char v) { return k%2!=0; });

        writef("new_table: [");
        bool first = true;
        foreach( k,v ; new_table )
        {
            if( !first )
                writef(", ");
            writef("%d -> '%s'", k, v);
            first = false;
        }
        writefln("]");
    }

    // Objects
    {
        scope naturals = new Naturals!(9);
        auto odds = filter(naturals, (int v) { return v%2!=0; });

        writefln("odds: %s", odds);
    }

    //
    // reduce
    //

    writefln("\nTesting reduce(seq, op)...");

    // Arrays
    {
        int[] naturals = [1,2,3,4,5,6,7,8,9];
        int sum = reduce(naturals, (int a, int b) { return a+b; });

        writefln("sum: %s", sum);
    }

    // Objects
    {
        scope naturals = new Naturals!(9);
        int product = reduce(naturals,
            (int a, int b) { return a*b; }, 1);

        writefln("product: %s", product);
    }
}