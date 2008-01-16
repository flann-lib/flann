/**
 * The array module provides array manipulation routines in a manner that
 * balances performance and flexibility.  Operations are provided for sorting,
 * and for processing both sorted and unsorted arrays.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly
 */
module tango.core.Array;


private import tango.core.Traits;
private import tango.stdc.stdlib : alloca;


version( DDoc )
{
    typedef int Num;
    typedef int Elem;

    typedef bool function( Elem )       Pred1E;
    typedef bool function( Elem, Elem ) Pred2E;
}


private
{
    struct IsEqual( T )
    {
        static bool opCall( T p1, T p2 )
        {
            // TODO: Fix this if/when opEquals is changed to return a bool.
            static if( is( T == class ) || is( T == struct ) )
                return (p1 == p2) != 0;
            else
                return p1 == p2;
        }
    }


    struct IsLess( T )
    {
        static bool opCall( T p1, T p2 )
        {
            return p1 < p2;
        }
    }


    template ElemTypeOf( T )
    {
        alias typeof(T[0]) ElemTypeOf;
    }
}


////////////////////////////////////////////////////////////////////////////////
// Find
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear scan of buf from $(LB)0 .. buf.length$(RP), returning
     * the index of the first element matching pat, or buf.length if no match
     * was found.  Comparisons will be performed using the supplied predicate
     * or '==' if none is supplied.
     *
     * Params:
     *  buf  = The array to search.
     *  pat  = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or buf.length if no match was found.
     */
    size_t find( Elem[] buf, Elem pat, Pred2E pred = Pred2E.init );


    /**
     * Performs a linear scan of buf from $(LB)0 .. buf.length$(RP), returning
     * the index of the first element matching pat, or buf.length if no match
     * was found.  Comparisons will be performed using the supplied predicate
     * or '==' if none is supplied.
     *
     * Params:
     *  buf  = The array to search.
     *  pat  = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or buf.length if no match was found.
     */
    size_t find( Elem[] buf, Elem[] pat, Pred2E pred = Pred2E.init );

}
else
{
    template find_( Elem, Pred = IsEqual!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat, Pred pred = Pred.init )
        {
            foreach( size_t pos, Elem cur; buf )
            {
                if( pred( cur, pat ) )
                    return pos;
            }
            return buf.length;
        }


        size_t fn( Elem[] buf, Elem[] pat, Pred pred = Pred.init )
        {
            if( buf.length == 0 ||
                pat.length == 0 ||
                buf.length < pat.length )
            {
                return buf.length;
            }

            size_t end = buf.length - pat.length + 1;

            for( size_t pos = 0; pos < end; ++pos )
            {
                if( pred( buf[pos], pat[0] ) )
                {
                    size_t mat = 0;

                    do
                    {
                        if( ++mat >= pat.length )
                            return pos - pat.length + 1;
                        if( ++pos >= buf.length )
                            return buf.length;
                    } while( pred( buf[pos], pat[mat] ) );
                    pos -= mat;
                }
            }
            return buf.length;
        }
    }


    template find( Buf, Pat )
    {
        size_t find( Buf buf, Pat pat )
        {
            return find_!(ElemTypeOf!(Buf)).fn( buf, pat );
        }
    }


    template find( Buf, Pat, Pred )
    {
        size_t find( Buf buf, Pat pat, Pred pred )
        {
            return find_!(ElemTypeOf!(Buf), Pred).fn( buf, pat, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        // find element
        assert( find( "", 'a' ) == 0 );
        assert( find( "abc", 'a' ) == 0 );
        assert( find( "abc", 'b' ) == 1 );
        assert( find( "abc", 'c' ) == 2 );
        assert( find( "abc", 'd' ) == 3 );

        // null parameters
        assert( find( "", "" ) == 0 );
        assert( find( "a", "" ) == 1 );
        assert( find( "", "a" ) == 0 );

        // exact match
        assert( find( "abc", "abc" ) == 0 );

        // simple substring match
        assert( find( "abc", "a" ) == 0 );
        assert( find( "abca", "a" ) == 0 );
        assert( find( "abc", "b" ) == 1 );
        assert( find( "abc", "c" ) == 2 );
        assert( find( "abc", "d" ) == 3 );

        // multi-char substring match
        assert( find( "abc", "ab" ) == 0 );
        assert( find( "abcab", "ab" ) == 0 );
        assert( find( "abc", "bc" ) == 1 );
        assert( find( "abc", "ac" ) == 3 );
        assert( find( "abrabracadabra", "abracadabra" ) == 3 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Reverse Find
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear scan of buf from $(LP)buf.length .. 0$(RB), returning
     * the index of the first element matching pat, or buf.length if no match
     * was found.  Comparisons will be performed using the supplied predicate
     * or '==' if none is supplied.
     *
     * Params:
     *  buf  = The array to search.
     *  pat  = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or buf.length if no match was found.
     */
    size_t rfind( Elem[] buf, Elem pat, Pred2E pred = Pred2E.init );


    /**
     * Performs a linear scan of buf from $(LP)buf.length .. 0$(RB), returning
     * the index of the first element matching pat, or buf.length if no match
     * was found.  Comparisons will be performed using the supplied predicate
     * or '==' if none is supplied.
     *
     * Params:
     *  buf  = The array to search.
     *  pat  = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or buf.length if no match was found.
     */
    size_t rfind( Elem[] buf, Elem[] pat, Pred2E pred = Pred2E.init );
}
else
{
    template rfind_( Elem, Pred = IsEqual!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat, Pred pred = Pred.init )
        {
            if( buf.length == 0 )
                return buf.length;

            size_t pos = buf.length;

            do
            {
                if( pred( buf[--pos], pat ) )
                    return pos;
            } while( pos > 0 );
            return buf.length;
        }


        size_t fn( Elem[] buf, Elem[] pat, Pred pred = Pred.init )
        {
            if( buf.length == 0 ||
                pat.length == 0 ||
                buf.length < pat.length )
            {
                return buf.length;
            }

            size_t pos = buf.length - pat.length + 1;

            do
            {
                if( pred( buf[--pos], pat[0] ) )
                {
                    size_t mat = 0;

                    do
                    {
                        if( ++mat >= pat.length )
                            return pos - pat.length + 1;
                        if( ++pos >= buf.length )
                            return buf.length;
                    } while( pred( buf[pos], pat[mat] ) );
                    pos -= mat;
                }
            } while( pos > 0 );
            return buf.length;
        }
    }


    template rfind( Buf, Pat )
    {
        size_t rfind( Buf buf, Pat pat )
        {
            return rfind_!(ElemTypeOf!(Buf)).fn( buf, pat );
        }
    }


    template rfind( Buf, Pat, Pred )
    {
        size_t rfind( Buf buf, Pat pat, Pred pred )
        {
            return rfind_!(ElemTypeOf!(Buf), Pred).fn( buf, pat, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        // rfind element
        assert( rfind( "", 'a' ) == 0 );
        assert( rfind( "abc", 'a' ) == 0 );
        assert( rfind( "abc", 'b' ) == 1 );
        assert( rfind( "abc", 'c' ) == 2 );
        assert( rfind( "abc", 'd' ) == 3 );

        // null parameters
        assert( rfind( "", "" ) == 0 );
        assert( rfind( "a", "" ) == 1 );
        assert( rfind( "", "a" ) == 0 );

        // exact match
        assert( rfind( "abc", "abc" ) == 0 );

        // simple substring match
        assert( rfind( "abc", "a" ) == 0 );
        assert( rfind( "abca", "a" ) == 3 );
        assert( rfind( "abc", "b" ) == 1 );
        assert( rfind( "abc", "c" ) == 2 );
        assert( rfind( "abc", "d" ) == 3 );

        // multi-char substring match
        assert( rfind( "abc", "ab" ) == 0 );
        assert( rfind( "abcab", "ab" ) == 3 );
        assert( rfind( "abc", "bc" ) == 1 );
        assert( rfind( "abc", "ac" ) == 3 );
        assert( rfind( "abracadabrabra", "abracadabra" ) == 0 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// KMP Find
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear scan of buf from $(LB)0 .. buf.length$(RP), returning
     * the index of the first element matching pat, or buf.length if no match
     * was found.  Comparisons will be performed using the supplied predicate
     * or '==' if none is supplied.
     *
     * This function uses the KMP algorithm and offers O(M+N) performance but
     * must allocate a temporary buffer of size pat.sizeof to do so.  If it is
     * available on the target system, alloca will be used for the allocation,
     * otherwise a standard dynamic memory allocation will occur.
     *
     * Params:
     *  buf  = The array to search.
     *  pat  = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or buf.length if no match was found.
     */
    size_t kfind( Elem[] buf, Elem pat, Pred2E pred = Pred2E.init );


    /**
     * Performs a linear scan of buf from $(LB)0 .. buf.length$(RP), returning
     * the index of the first element matching pat, or buf.length if no match
     * was found.  Comparisons will be performed using the supplied predicate
     * or '==' if none is supplied.
     *
     * This function uses the KMP algorithm and offers O(M+N) performance but
     * must allocate a temporary buffer of size pat.sizeof to do so.  If it is
     * available on the target system, alloca will be used for the allocation,
     * otherwise a standard dynamic memory allocation will occur.
     *
     * Params:
     *  buf  = The array to search.
     *  pat  = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or buf.length if no match was found.
     */
    size_t kfind( Elem[] buf, Elem[] pat, Pred2E pred = Pred2E.init );
}
else
{
    template kfind_( Elem, Pred = IsEqual!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat, Pred pred = Pred.init )
        {
            foreach( size_t pos, Elem cur; buf )
            {
                if( pred( cur, pat ) )
                    return pos;
            }
            return buf.length;
        }


        size_t fn( Elem[] buf, Elem[] pat, Pred pred = Pred.init )
        {
            if( buf.length == 0 ||
                pat.length == 0 ||
                buf.length < pat.length )
            {
                return buf.length;
            }

            static if( is( alloca ) )
            {
                size_t[] func = (cast(size_t*) alloca( (pat.length + 1) * size_t.sizeof ))[0 .. pat.length + 1];
            }
            else
            {
                size_t[] func = new size_t[pat.length + 1];
                scope( exit ) delete func; // force cleanup
            }

            func[0] = 0;

            //
            // building prefix-function
            //
            for( size_t m = 0, i = 1 ; i < pat.length ; ++i )
            {
                while( ( m > 0 ) && !pred( pat[m], pat[i] ) )
                    m = func[m - 1];
                if( pred( pat[m], pat[i] ) )
                    ++m;
                func[i] = m;
            }

            //
            // searching
            //
            for( size_t m = 0, i = 0; i < buf.length; ++i )
            {
                while( ( m > 0 ) && !pred( pat[m], buf[i] ) )
                    m = func[m - 1];
                if( pred( pat[m], buf[i] ) )
                {
                    ++m;
                    if( m == pat.length )
                    {
                        return i - pat.length + 1;
                    }
                }
            }

            return buf.length;
        }
    }


    template kfind( Buf, Pat )
    {
        size_t kfind( Buf buf, Pat pat )
        {
            return kfind_!(ElemTypeOf!(Buf)).fn( buf, pat );
        }
    }


    template kfind( Buf, Pat, Pred )
    {
        size_t kfind( Buf buf, Pat pat, Pred pred )
        {
            return kfind_!(ElemTypeOf!(Buf), Pred).fn( buf, pat, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        // find element
        assert( kfind( "", 'a' ) == 0 );
        assert( kfind( "abc", 'a' ) == 0 );
        assert( kfind( "abc", 'b' ) == 1 );
        assert( kfind( "abc", 'c' ) == 2 );
        assert( kfind( "abc", 'd' ) == 3 );

        // null parameters
        assert( kfind( "", "" ) == 0 );
        assert( kfind( "a", "" ) == 1 );
        assert( kfind( "", "a" ) == 0 );

        // exact match
        assert( kfind( "abc", "abc" ) == 0 );

        // simple substring match
        assert( kfind( "abc", "a" ) == 0 );
        assert( kfind( "abca", "a" ) == 0 );
        assert( kfind( "abc", "b" ) == 1 );
        assert( kfind( "abc", "c" ) == 2 );
        assert( kfind( "abc", "d" ) == 3 );

        // multi-char substring match
        assert( kfind( "abc", "ab" ) == 0 );
        assert( kfind( "abcab", "ab" ) == 0 );
        assert( kfind( "abc", "bc" ) == 1 );
        assert( kfind( "abc", "ac" ) == 3 );
        assert( kfind( "abrabracadabra", "abracadabra" ) == 3 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// KMP Reverse Find
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear scan of buf from $(LP)buf.length .. 0$(RB), returning
     * the index of the first element matching pat, or buf.length if no match
     * was found.  Comparisons will be performed using the supplied predicate
     * or '==' if none is supplied.
     *
     * This function uses the KMP algorithm and offers O(M+N) performance but
     * must allocate a temporary buffer of size pat.sizeof to do so.  If it is
     * available on the target system, alloca will be used for the allocation,
     * otherwise a standard dynamic memory allocation will occur.
     *
     * Params:
     *  buf  = The array to search.
     *  pat  = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or buf.length if no match was found.
     */
    size_t krfind( Elem[] buf, Elem pat, Pred2E pred = Pred2E.init );


    /**
     * Performs a linear scan of buf from $(LP)buf.length .. 0$(RB), returning
     * the index of the first element matching pat, or buf.length if no match
     * was found.  Comparisons will be performed using the supplied predicate
     * or '==' if none is supplied.
     *
     * This function uses the KMP algorithm and offers O(M+N) performance but
     * must allocate a temporary buffer of size pat.sizeof to do so.  If it is
     * available on the target system, alloca will be used for the allocation,
     * otherwise a standard dynamic memory allocation will occur.
     *
     * Params:
     *  buf  = The array to search.
     *  pat  = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or buf.length if no match was found.
     */
    size_t krfind( Elem[] buf, Elem[] pat, Pred2E pred = Pred2E.init );
}
else
{
    template krfind_( Elem, Pred = IsEqual!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat, Pred pred = Pred.init )
        {
            if( buf.length == 0 )
                return buf.length;

            size_t pos = buf.length;

            do
            {
                if( pred( buf[--pos], pat ) )
                    return pos;
            } while( pos > 0 );
            return buf.length;
        }


        size_t fn( Elem[] buf, Elem[] pat, Pred pred = Pred.init )
        {
            if( buf.length == 0 ||
                pat.length == 0 ||
                buf.length < pat.length )
            {
                return buf.length;
            }

            static if( is( alloca ) )
            {
                size_t[] func = (cast(size_t*) alloca( (pat.length + 1) * size_t.sizeof ))[0 .. pat.length + 1];
            }
            else
            {
                size_t[] func = new size_t[pat.length + 1];
                scope( exit ) delete func; // force cleanup
            }

            func[$ - 1] = 0;

            //
            // building prefix-function
            //
            for( size_t m = 0, i = pat.length - 1; i > 0; --i )
            {
                while( ( m > 0 ) && !pred( pat[length - m - 1], pat[i - 1] ) )
                    m = func[length - m];
                if( pred( pat[length - m - 1], pat[i - 1] ) )
                    ++m;
                func[i - 1] = m;
            }

            //
            // searching
            //
            size_t  m = 0;
            size_t  i = buf.length;
            do
            {
                --i;
                while( ( m > 0 ) && !pred( pat[length - m - 1], buf[i] ) )
                    m = func[length - m - 1];
                if( pred( pat[length - m - 1], buf[i] ) )
                {
                    ++m;
                    if ( m == pat.length )
                    {
                        return i;
                    }
                }
            } while( i > 0 );

            return buf.length;
        }
    }


    template krfind( Buf, Pat )
    {
        size_t krfind( Buf buf, Pat pat )
        {
            return krfind_!(ElemTypeOf!(Buf)).fn( buf, pat );
        }
    }


    template krfind( Buf, Pat, Pred )
    {
        size_t krfind( Buf buf, Pat pat, Pred pred )
        {
            return krfind_!(ElemTypeOf!(Buf), Pred).fn( buf, pat, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        // rfind element
        assert( krfind( "", 'a' ) == 0 );
        assert( krfind( "abc", 'a' ) == 0 );
        assert( krfind( "abc", 'b' ) == 1 );
        assert( krfind( "abc", 'c' ) == 2 );
        assert( krfind( "abc", 'd' ) == 3 );

        // null parameters
        assert( krfind( "", "" ) == 0 );
        assert( krfind( "a", "" ) == 1 );
        assert( krfind( "", "a" ) == 0 );

        // exact match
        assert( krfind( "abc", "abc" ) == 0 );

        // simple substring match
        assert( krfind( "abc", "a" ) == 0 );
        assert( krfind( "abca", "a" ) == 3 );
        assert( krfind( "abc", "b" ) == 1 );
        assert( krfind( "abc", "c" ) == 2 );
        assert( krfind( "abc", "d" ) == 3 );

        // multi-char substring match
        assert( krfind( "abc", "ab" ) == 0 );
        assert( krfind( "abcab", "ab" ) == 3 );
        assert( krfind( "abc", "bc" ) == 1 );
        assert( krfind( "abc", "ac" ) == 3 );
        assert( krfind( "abracadabrabra", "abracadabra" ) == 0 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Find-If
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear scan of buf from $(LB)0 .. buf.length$(RP), returning
     * the index of the first element where pred returns true.
     *
     * Params:
     *  buf  = The array to search.
     *  pred = The evaluation predicate, which should return true if the
     *         element is a valid match and false if not.  This predicate
     *         may be any callable type.
     *
     * Returns:
     *  The index of the first match or buf.length if no match was found.
     */
    size_t findIf( Elem[] buf, Pred1E pred );
}
else
{
    template findIf_( Elem, Pred )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Pred pred )
        {
            foreach( size_t pos, Elem cur; buf )
            {
                if( pred( cur ) )
                    return pos;
            }
            return buf.length;
        }
    }


    template findIf( Buf, Pred )
    {
        size_t findIf( Buf buf, Pred pred )
        {
            return findIf_!(ElemTypeOf!(Buf), Pred).fn( buf, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        assert( findIf( "bcecg", ( char c ) { return c == 'a'; } ) == 5 );
        assert( findIf( "bcecg", ( char c ) { return c == 'b'; } ) == 0 );
        assert( findIf( "bcecg", ( char c ) { return c == 'c'; } ) == 1 );
        assert( findIf( "bcecg", ( char c ) { return c == 'd'; } ) == 5 );
        assert( findIf( "bcecg", ( char c ) { return c == 'g'; } ) == 4 );
        assert( findIf( "bcecg", ( char c ) { return c == 'h'; } ) == 5 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Reverse Find-If
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear scan of buf from $(LP)buf.length .. 0$(RB), returning
     * the index of the first element where pred returns true.
     *
     * Params:
     *  buf  = The array to search.
     *  pred = The evaluation predicate, which should return true if the
     *         element is a valid match and false if not.  This predicate
     *         may be any callable type.
     *
     * Returns:
     *  The index of the first match or buf.length if no match was found.
     */
    size_t rfindIf( Elem[] buf, Pred1E pred );
}
else
{
    template rfindIf_( Elem, Pred )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Pred pred )
        {
            if( buf.length == 0 )
                return buf.length;

            size_t pos = buf.length;

            do
            {
                if( pred( buf[--pos] ) )
                    return pos;
            } while( pos > 0 );
            return buf.length;
        }
    }


    template rfindIf( Buf, Pred )
    {
        size_t rfindIf( Buf buf, Pred pred )
        {
            return rfindIf_!(ElemTypeOf!(Buf), Pred).fn( buf, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        assert( rfindIf( "bcecg", ( char c ) { return c == 'a'; } ) == 5 );
        assert( rfindIf( "bcecg", ( char c ) { return c == 'b'; } ) == 0 );
        assert( rfindIf( "bcecg", ( char c ) { return c == 'c'; } ) == 3 );
        assert( rfindIf( "bcecg", ( char c ) { return c == 'd'; } ) == 5 );
        assert( rfindIf( "bcecg", ( char c ) { return c == 'g'; } ) == 4 );
        assert( rfindIf( "bcecg", ( char c ) { return c == 'h'; } ) == 5 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Find Adjacent
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear scan of buf from $(LB)0 .. buf.length$(RP), returning
     * the index of the first element that compares equal to the next element
     * in the sequence.  Comparisons will be performed using the supplied
     * predicate or '==' if none is supplied.
     *
     * Params:
     *  buf  = The array to scan.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or buf.length if no match was found.
     */
    size_t findAdj( Elem[] buf, Elem pat, Pred2E pred = Pred2E.init );

}
else
{
    template findAdj_( Elem, Pred = IsEqual!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Pred pred = Pred.init )
        {
            if( buf.length < 2 )
                return buf.length;

            Elem sav = buf[0];

            foreach( size_t pos, Elem cur; buf[1 .. $] )
            {
                if( pred( cur, sav ) )
                    return pos;
                sav = cur;
            }
            return buf.length;
        }
    }


    template findAdj( Buf )
    {
        size_t findAdj( Buf buf )
        {
            return findAdj_!(ElemTypeOf!(Buf)).fn( buf );
        }
    }


    template findAdj( Buf, Pred )
    {
        size_t findAdj( Buf buf, Pred pred )
        {
            return findAdj_!(ElemTypeOf!(Buf), Pred).fn( buf, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        assert( findAdj( "aabcdef" ) == 0 );
        assert( findAdj( "abcddef" ) == 3 );
        assert( findAdj( "abcdeff" ) == 5 );
        assert( findAdj( "abcdefg" ) == 7 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Contains
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear scan of buf from $(LB)0 .. buf.length$(RP), returning
     * true if an element matching pat is found.  Comparisons will be performed
     * using the supplied predicate or '<' if none is supplied.
     *
     * Params:
     *  buf  = The array to search.
     *  pat  = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  True if an element equivalent to pat is found, false if not.
     */
    size_t contains( Elem[] buf, Elem pat, Pred2E pred = Pred2E.init );


    /**
     * Performs a linear scan of buf from $(LB)0 .. buf.length$(RP), returning
     * true if a sequence matching pat is found.  Comparisons will be performed
     * using the supplied predicate or '<' if none is supplied.
     *
     * Params:
     *  buf  = The array to search.
     *  pat  = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  True if an element equivalent to pat is found, false if not.
     */
    size_t contains( Elem[] buf, Elem[] pat, Pred2E pred = Pred2E.init );
}
else
{
    template contains( Buf, Pat )
    {
        size_t contains( Buf buf, Pat pat )
        {
            return find( buf, pat ) != buf.length;
        }
    }


    template contains( Buf, Pat, Pred )
    {
        size_t contains( Buf buf, Pat pat, Pred pred )
        {
            return find( buf, pat, pred ) != buf.length;
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        // find element
        assert( !contains( "", 'a' ) );
        assert(  contains( "abc", 'a' ) );
        assert(  contains( "abc", 'b' ) );
        assert(  contains( "abc", 'c' ) );
        assert( !contains( "abc", 'd' ) );

        // null parameters
        assert( !contains( "", "" ) );
        assert( !contains( "a", "" ) );
        assert( !contains( "", "a" ) );

        // exact match
        assert(  contains( "abc", "abc" ) );

        // simple substring match
        assert(  contains( "abc", "a" ) );
        assert(  contains( "abca", "a" ) );
        assert(  contains( "abc", "b" ) );
        assert(  contains( "abc", "c" ) );
        assert( !contains( "abc", "d" ) );

        // multi-char substring match
        assert(  contains( "abc", "ab" ) );
        assert(  contains( "abcab", "ab" ) );
        assert(  contains( "abc", "bc" ) );
        assert( !contains( "abc", "ac" ) );
        assert(  contains( "abrabracadabra", "abracadabra" ) );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Mismatch
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a parallel linear scan of bufA and bufB from $(LB)0 .. N$(RP)
     * where N = min$(LP)bufA.length, bufB.length$(RP), returning the index of
     * the first element in bufA which does not match the corresponding element
     * in bufB or N if no mismatch occurs.  Comparisons will be performed using
     * the supplied predicate or '==' if none is supplied.
     *
     * Params:
     *  bufA = The array to evaluate.
     *  bufB = The array to match against.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first mismatch or N if the first N elements of bufA
     * and bufB match, where N = min$(LP)bufA.length, bufB.length$(RP).
     */
    size_t mismatch( Elem[] bufA, Elem[] bufB, Pred2E pred = Pred2E.init );

}
else
{
    template mismatch_( Elem, Pred = IsEqual!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] bufA, Elem[] bufB, Pred pred = Pred.init )
        {
            size_t  posA = 0,
                    posB = 0;

            while( posA < bufA.length && posB < bufB.length )
            {
                if( !pred( bufB[posB], bufA[posA] ) )
                    break;
                ++posA, ++posB;
            }
            return posA;
        }
    }


    template mismatch( BufA, BufB )
    {
        size_t mismatch( BufA bufA, BufB bufB )
        {
            return mismatch_!(ElemTypeOf!(BufA)).fn( bufA, bufB );
        }
    }


    template mismatch( BufA, BufB, Pred )
    {
        size_t mismatch( BufA bufA, BufB bufB, Pred pred )
        {
            return mismatch_!(ElemTypeOf!(BufA), Pred).fn( bufA, bufB, pred );
        }
    }

    debug( UnitTest )
    {
      unittest
      {
        assert( mismatch( "a", "abcdefg" ) == 1 );
        assert( mismatch( "abcdefg", "a" ) == 1 );

        assert( mismatch( "x", "abcdefg" ) == 0 );
        assert( mismatch( "abcdefg", "x" ) == 0 );

        assert( mismatch( "xbcdefg", "abcdefg" ) == 0 );
        assert( mismatch( "abcdefg", "xbcdefg" ) == 0 );

        assert( mismatch( "abcxefg", "abcdefg" ) == 3 );
        assert( mismatch( "abcdefg", "abcxefg" ) == 3 );

        assert( mismatch( "abcdefx", "abcdefg" ) == 6 );
        assert( mismatch( "abcdefg", "abcdefx" ) == 6 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Count
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear scan of buf from $(LB)0 .. buf.length$(RP), returning
     * a count of the number of elements matching pat.  Comparisons will be
     * performed using the supplied predicate or '==' if none is supplied.
     *
     * Params:
     *  buf  = The array to scan.
     *  pat  = The pattern to match.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The number of elements matching pat.
     */
    size_t count( Elem[] buf, Elem pat, Pred2E pred = Pred2E.init );

}
else
{
    template count_( Elem, Pred = IsEqual!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat, Pred pred = Pred.init )
        {
            size_t cnt = 0;

            foreach( size_t pos, Elem cur; buf )
            {
                if( pred( cur, pat ) )
                    ++cnt;
            }
            return cnt;
        }
    }


    template count( Buf, Pat )
    {
        size_t count( Buf buf, Pat pat )
        {
            return count_!(ElemTypeOf!(Buf)).fn( buf, pat );
        }
    }


    template count( Buf, Pat, Pred )
    {
        size_t count( Buf buf, Pat pat, Pred pred )
        {
            return count_!(ElemTypeOf!(Buf), Pred).fn( buf, pat, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        assert( count( "gbbbi", 'a' ) == 0 );
        assert( count( "gbbbi", 'g' ) == 1 );
        assert( count( "gbbbi", 'b' ) == 3 );
        assert( count( "gbbbi", 'i' ) == 1 );
        assert( count( "gbbbi", 'd' ) == 0 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Count-If
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear scan of buf from $(LB)0 .. buf.length$(RP), returning
     * a count of the number of elements where pred returns true.
     *
     * Params:
     *  buf  = The array to scan.
     *  pred = The evaluation predicate, which should return true if the
     *         element is a valid match and false if not.  This predicate
     *         may be any callable type.
     *
     * Returns:
     *  The number of elements where pred returns true.
     */
    size_t countIf( Elem[] buf, Pred1E pred = Pred1E.init );

}
else
{
    template countIf_( Elem, Pred )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Pred pred )
        {
            size_t cnt = 0;

            foreach( size_t pos, Elem cur; buf )
            {
                if( pred( cur ) )
                    ++cnt;
            }
            return cnt;
        }
    }


    template countIf( Buf, Pred )
    {
        size_t countIf( Buf buf, Pred pred )
        {
            return countIf_!(ElemTypeOf!(Buf), Pred).fn( buf, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        assert( countIf( "gbbbi", ( char c ) { return c == 'a'; } ) == 0 );
        assert( countIf( "gbbbi", ( char c ) { return c == 'g'; } ) == 1 );
        assert( countIf( "gbbbi", ( char c ) { return c == 'b'; } ) == 3 );
        assert( countIf( "gbbbi", ( char c ) { return c == 'i'; } ) == 1 );
        assert( countIf( "gbbbi", ( char c ) { return c == 'd'; } ) == 0 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Replace
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear scan of buf from $(LB)0 .. buf.length$(RP), replacing
     * occurrences of pat with val.  Comparisons will be performed using the
     * supplied predicate or '==' if none is supplied.
     *
     * Params:
     *  buf  = The array to scan.
     *  pat  = The pattern to match.
     *  val  = The value to substitute.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The number of elements replaced.
     */
    size_t replace( Elem[] buf, Elem pat, Elem val, Pred2E pred = Pred2E.init );

}
else
{
    template replace_( Elem, Pred = IsEqual!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat, Elem val, Pred pred = Pred.init )
        {
            size_t cnt = 0;

            foreach( size_t pos, inout Elem cur; buf )
            {
                if( pred( cur, pat ) )
                {
                    cur = val;
                    ++cnt;
                }
            }
            return cnt;
        }
    }


    template replace( Buf, Elem )
    {
        size_t replace( Buf buf, Elem pat, Elem val )
        {
            return replace_!(ElemTypeOf!(Buf)).fn( buf, pat, val );
        }
    }


    template replace( Buf, Elem, Pred )
    {
        size_t replace( Buf buf, Elem pat, Elem val, Pred pred )
        {
            return replace_!(ElemTypeOf!(Buf), Pred).fn( buf, pat, val, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        assert( replace( "gbbbi".dup, 'a', 'b' ) == 0 );
        assert( replace( "gbbbi".dup, 'g', 'h' ) == 1 );
        assert( replace( "gbbbi".dup, 'b', 'c' ) == 3 );
        assert( replace( "gbbbi".dup, 'i', 'j' ) == 1 );
        assert( replace( "gbbbi".dup, 'd', 'e' ) == 0 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Replace-If
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear scan of buf from $(LB)0 .. buf.length$(RP), replacing
     * elements where pred returns true with val.
     *
     * Params:
     *  buf  = The array to scan.
     *  val  = The value to substitute.
     *  pred = The evaluation predicate, which should return true if the
     *         element is a valid match and false if not.  This predicate
     *         may be any callable type.
     *
     * Returns:
     *  The number of elements replaced.
     */
    size_t replaceIf( Elem[] buf, Elem val, Pred2E pred = Pred2E.init );

}
else
{
    template replaceIf_( Elem, Pred )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem val, Pred pred )
        {
            size_t cnt = 0;

            foreach( size_t pos, inout Elem cur; buf )
            {
                if( pred( cur ) )
                {
                    cur = val;
                    ++cnt;
                }
            }
            return cnt;
        }
    }


    template replaceIf( Buf, Elem, Pred )
    {
        size_t replaceIf( Buf buf, Elem val, Pred pred )
        {
            return replaceIf_!(ElemTypeOf!(Buf), Pred).fn( buf, val, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        assert( replaceIf( "gbbbi".dup, 'b', ( char c ) { return c == 'a'; } ) == 0 );
        assert( replaceIf( "gbbbi".dup, 'h', ( char c ) { return c == 'g'; } ) == 1 );
        assert( replaceIf( "gbbbi".dup, 'c', ( char c ) { return c == 'b'; } ) == 3 );
        assert( replaceIf( "gbbbi".dup, 'j', ( char c ) { return c == 'i'; } ) == 1 );
        assert( replaceIf( "gbbbi".dup, 'e', ( char c ) { return c == 'd'; } ) == 0 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Remove
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear scan of buf from $(LB)0 .. buf.length$(RP), moving all
     * elements matching pat to the end of the sequence.  The relative order of
     * elements not matching pat will be preserved.  Comparisons will be
     * performed using the supplied predicate or '==' if none is supplied.
     *
     * Params:
     *  buf  = The array to scan.  This parameter is not marked 'inout'
     *         to allow temporary slices to be modified.  As buf is not resized
     *         in any way, omitting the 'inout' qualifier has no effect on the
     *         result of this operation, even though it may be viewed as a
     *         side-effect.
     *  pat  = The pattern to match against.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The number of elements that do not match pat.
     */
    size_t remove( Elem[] buf, Elem pat, Pred2E pred = Pred2E.init );
}
else
{
    template remove_( Elem, Pred = IsEqual!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat, Pred pred = Pred.init )
        {
            // NOTE: Indexes are passed instead of references because DMD does
            //       not inline the reference-based version.
            void exch( size_t p1, size_t p2 )
            {
                Elem t  = buf[p1];
                buf[p1] = buf[p2];
                buf[p2] = t;
            }

            size_t cnt = 0;

            for( size_t pos = 0, len = buf.length; pos < len; ++pos )
            {
                if( pred( buf[pos], pat ) )
                    ++cnt;
                else
                    exch( pos, pos - cnt );
            }
            return buf.length - cnt;
        }
    }


    template remove( Buf, Pat )
    {
        size_t remove( Buf buf, Pat pat )
        {
            return remove_!(ElemTypeOf!(Buf)).fn( buf, pat );
        }
    }


    template remove( Buf, Pat, Pred )
    {
        size_t remove( Buf buf, Pat pat, Pred pred )
        {
            return remove_!(ElemTypeOf!(Buf), Pred).fn( buf, pat, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        void test( char[] buf, char pat, size_t num )
        {
            assert( remove( buf, pat ) == num );
            foreach( pos, cur; buf )
            {
                assert( pos < num ? cur != pat : cur == pat );
            }
        }

        test( "abcdefghij".dup, 'x', 10 );
        test( "xabcdefghi".dup, 'x',  9 );
        test( "abcdefghix".dup, 'x',  9 );
        test( "abxxcdefgh".dup, 'x',  8 );
        test( "xaxbcdxxex".dup, 'x',  5 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Remove-If
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear scan of buf from $(LB)0 .. buf.length$(RP), moving all
     * elements that satisfy pred to the end of the sequence.  The relative
     * order of elements that do not satisfy pred will be preserved.
     *
     * Params:
     *  buf  = The array to scan.  This parameter is not marked 'inout'
     *         to allow temporary slices to be modified.  As buf is not resized
     *         in any way, omitting the 'inout' qualifier has no effect on the
     *         result of this operation, even though it may be viewed as a
     *         side-effect.
     *  pred = The evaluation predicate, which should return true if the
     *         element satisfies the condition and false if not.  This
     *         predicate may be any callable type.
     *
     * Returns:
     *  The number of elements that do not satisfy pred.
     */
    size_t removeIf( Elem[] buf, Pred1E pred );
}
else
{
    template removeIf_( Elem, Pred )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Pred pred )
        {
            // NOTE: Indexes are passed instead of references because DMD does
            //       not inline the reference-based version.
            void exch( size_t p1, size_t p2 )
            {
                Elem t  = buf[p1];
                buf[p1] = buf[p2];
                buf[p2] = t;
            }

            size_t cnt = 0;

            for( size_t pos = 0, len = buf.length; pos < len; ++pos )
            {
                if( pred( buf[pos] ) )
                    ++cnt;
                else
                    exch( pos, pos - cnt );
            }
            return buf.length - cnt;
        }
    }


    template removeIf( Buf, Pred )
    {
        size_t removeIf( Buf buf, Pred pred )
        {
            return removeIf_!(ElemTypeOf!(Buf), Pred).fn( buf, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        void test( char[] buf, bool delegate( char ) dg, size_t num )
        {
            assert( removeIf( buf, dg ) == num );
            foreach( pos, cur; buf )
            {
                assert( pos < num ? !dg( cur ) : dg( cur ) );
            }
        }

        test( "abcdefghij".dup, ( char c ) { return c == 'x'; }, 10 );
        test( "xabcdefghi".dup, ( char c ) { return c == 'x'; },  9 );
        test( "abcdefghix".dup, ( char c ) { return c == 'x'; },  9 );
        test( "abxxcdefgh".dup, ( char c ) { return c == 'x'; },  8 );
        test( "xaxbcdxxex".dup, ( char c ) { return c == 'x'; },  5 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Unique
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear scan of buf from $(LB)0 .. buf.length$(RP), moving all
     * but the first element of each consecutive group of duplicate elements to
     * the end of the sequence.  The relative order of all remaining elements
     * will be preserved.  Comparisons will be performed using the supplied
     * predicate or '==' if none is supplied.
     *
     * Params:
     *  buf  = The array to scan.  This parameter is not marked 'inout'
     *         to allow temporary slices to be modified.  As buf is not resized
     *         in any way, omitting the 'inout' qualifier has no effect on the
     *         result of this operation, even though it may be viewed as a
     *         side-effect.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The number of unique elements in buf.
     */
    size_t unique( Elem[] buf, Pred2E pred = Pred2E.init );
}
else
{
    template unique_( Elem, Pred = IsEqual!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Pred pred = Pred.init )
        {
            // NOTE: Indexes are passed instead of references because DMD does
            //       not inline the reference-based version.
            void exch( size_t p1, size_t p2 )
            {
                Elem t  = buf[p1];
                buf[p1] = buf[p2];
                buf[p2] = t;
            }

            if( buf.length < 2 )
                return buf.length;

            size_t cnt = 0;
            Elem   pat = buf[0];

            for( size_t pos = 1, len = buf.length; pos < len; ++pos )
            {
                if( pred( buf[pos], pat ) )
                    ++cnt;
                else
                {
                    pat = buf[pos];
                    exch( pos, pos - cnt );
                }
            }
            return buf.length - cnt;
        }
    }


    template unique( Buf )
    {
        size_t unique( Buf buf )
        {
            return unique_!(ElemTypeOf!(Buf)).fn( buf );
        }
    }


    template unique( Buf, Pred )
    {
        size_t unique( Buf buf, Pred pred )
        {
            return unique_!(ElemTypeOf!(Buf), Pred).fn( buf, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        void test( char[] buf, char[] pat )
        {
            assert( unique( buf ) == pat.length );
            foreach( pos, cur; pat )
            {
                assert( buf[pos] == cur );
            }
        }

        test( "abcdefghij".dup, "abcdefghij" );
        test( "aabcdefghi".dup, "abcdefghi" );
        test( "bcdefghijj".dup, "bcdefghij" );
        test( "abccdefghi".dup, "abcdefghi" );
        test( "abccdddefg".dup, "abcdefg" );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Partition
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Partitions buf such that all elements that satisfy pred will be placed
     * before the elements that do not satisfy pred.  The algorithm is not
     * required to be stable.
     *
     * Params:
     *  buf  = The array to partition.  This parameter is not marked 'inout'
     *         to allow temporary slices to be sorted.  As buf is not resized
     *         in any way, omitting the 'inout' qualifier has no effect on
     *         the result of this operation, even though it may be viewed
     *         as a side-effect.
     *  pred = The evaluation predicate, which should return true if the
     *         element satisfies the condition and false if not.  This
     *         predicate may be any callable type.
     *
     * Returns:
     *  The number of elements that satisfy pred.
     */
    size_t partition( Elem[] buf, Pred1E pred );
}
else
{
    template partition_( Elem, Pred = IsLess!(Elem) )
    {
        static assert( isCallableType!(Pred ) );


        size_t fn( Elem[] buf, Pred pred )
        {
            // NOTE: Indexes are passed instead of references because DMD does
            //       not inline the reference-based version.
            void exch( size_t p1, size_t p2 )
            {
                Elem t  = buf[p1];
                buf[p1] = buf[p2];
                buf[p2] = t;
            }

            if( buf.length < 2 )
                return 0;

            size_t  l = 0,
                    r = buf.length,
                    i = l,
                    j = r - 1;

            while( true )
            {
                while( i < r && pred( buf[i] ) )
                    ++i;
                while( j > l && !pred( buf[j] ) )
                    --j;
                if( i >= j )
                    break;
                exch( i++, j-- );
            }
            return i;
        }
    }


    template partition( Buf, Pred )
    {
        size_t partition( Buf buf, Pred pred )
        {
            return partition_!(ElemTypeOf!(Buf), Pred).fn( buf, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        void test( char[] buf, bool delegate( char ) dg, size_t num )
        {
            assert( partition( buf, dg ) == num );
            for( size_t pos = 0; pos < buf.length; ++pos )
            {
                assert( pos < num ? dg( buf[pos] ) : !dg( buf[pos] ) );
            }
        }

        test( "abcdefg".dup, ( char c ) { return c < 'a'; }, 0 );
        test( "gfedcba".dup, ( char c ) { return c < 'a'; }, 0 );
        test( "abcdefg".dup, ( char c ) { return c < 'h'; }, 7 );
        test( "gfedcba".dup, ( char c ) { return c < 'h'; }, 7 );
        test( "abcdefg".dup, ( char c ) { return c < 'd'; }, 3 );
        test( "gfedcba".dup, ( char c ) { return c < 'd'; }, 3 );
        test( "bbdaabc".dup, ( char c ) { return c < 'c'; }, 5 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Select
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Partitions buf with num - 1 as a pivot such that the first num elements
     * will be less than or equal to the remaining elements in the array.
     * Comparisons will be performed using the supplied predicate or '<' if
     * none is supplied.  The algorithm is not required to be stable.
     *
     * Params:
     *  buf  = The array to partition.  This parameter is not marked 'inout'
     *         to allow temporary slices to be sorted.  As buf is not resized
     *         in any way, omitting the 'inout' qualifier has no effect on
     *         the result of this operation, even though it may be viewed
     *         as a side-effect.
     *  num  = The number of elements which are considered significant in
     *         this array, where num - 1 is the pivot around which partial
     *         sorting will occur.  For example, if num is buf.length / 2
     *         then select will effectively partition the array around its
     *         median value, with the elements in the first half of the array
     *         evaluating as less than or equal to the elements in the second
     *         half.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         less than e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the pivot point, which will be the lesser of num - 1 and
     *  buf.length.
     */
    size_t select( Elem[] buf, Num num, Pred2E pred = Pred2E.init );
}
else
{
    template select_( Elem, Pred = IsLess!(Elem) )
    {
        static assert( isCallableType!(Pred ) );


        size_t fn( Elem[] buf, size_t num, Pred pred = Pred.init )
        {
            // NOTE: Indexes are passed instead of references because DMD does
            //       not inline the reference-based version.
            void exch( size_t p1, size_t p2 )
            {
                Elem t  = buf[p1];
                buf[p1] = buf[p2];
                buf[p2] = t;
            }

            if( buf.length < 2 )
                return buf.length;

            size_t  l = 0,
                    r = buf.length - 1,
                    k = num;

            while( r > l )
            {
                size_t  i = l,
                        j = r - 1;
                Elem    v = buf[r];

                while( true )
                {
                    while( i < r && pred( buf[i], v ) )
                        ++i;
                    while( j > l && pred( v, buf[j] ) )
                        --j;
                    if( i >= j )
                        break;
                    exch( i++, j-- );
                }
                exch( i, r );
                if( i >= k )
                    r = i - 1;
                if( i <= k )
                    l = i + 1;
            }
            return num - 1;
        }
    }


    template select( Buf, Num )
    {
        size_t select( Buf buf, Num num )
        {
            return select_!(ElemTypeOf!(Buf)).fn( buf, num );
        }
    }


    template select( Buf, Num, Pred )
    {
        size_t select( Buf buf, Num num, Pred pred )
        {
            return select_!(ElemTypeOf!(Buf), Pred).fn( buf, num, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        char[] buf = "efedcaabca".dup;
        size_t num = buf.length / 2;
        size_t pos = select( buf, num );

        assert( pos == num - 1 );
        foreach( cur; buf[0 .. pos] )
            assert( cur <= buf[pos] );
        foreach( cur; buf[pos .. $] )
            assert( cur >= buf[pos] );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Sort
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Sorts buf using the supplied predicate or '<' if none is supplied.  The
     * algorithm is not required to be stable.  The current implementation is
     * based on quicksort, but uses a three-way partitioning scheme to improve
     * performance for ranges containing duplicate values (Bentley and McIlroy,
     * 1993).
     *
     * Params:
     *  buf  = The array to sort.  This parameter is not marked 'inout' to
     *         allow temporary slices to be sorted.  As buf is not resized
     *         in any way, omitting the 'inout' qualifier has no effect on
     *         the result of this operation, even though it may be viewed
     *         as a side-effect.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         less than e2 and false if not.  This predicate may be any
     *         callable type.
     */
    void sort( Elem[] buf, Pred2E pred = Pred2E.init );
}
else
{
    template sort_( Elem, Pred = IsLess!(Elem) )
    {
        static assert( isCallableType!(Pred ) );


        void fn( Elem[] buf, Pred pred = Pred.init )
        {
            bool equiv( Elem p1, Elem p2 )
            {
                return !pred( p1, p2 ) && !pred( p2, p1 );
            }

            // NOTE: Indexes are passed instead of references because DMD does
            //       not inline the reference-based version.
            void exch( size_t p1, size_t p2 )
            {
                Elem t  = buf[p1];
                buf[p1] = buf[p2];
                buf[p2] = t;
            }

            void quicksort( size_t l, size_t r )
            {
                if( r <= l )
                    return;

                // This implementation of quicksort improves upon the classic
                // algorithm by partitioning the array into three parts, one
                // each for keys smaller than, equal to, and larger than the
                // partitioning element, v:
                //
                // |--less than v--|--equal to v--|--greater than v--[v]
                // l               j              i                   r
                //
                // This approach sorts ranges containing duplicate elements
                // more quickly.  During processing, the following situation
                // is maintained:
                //
                // |--equal--|--less--|--[###]--|--greater--|--equal--[v]
                // l         p        i         j           q          r
                //
                // Please note that this implementation varies from the typical
                // algorithm by replacing the use of signed index values with
                // unsigned values.

                Elem    v = buf[r];
                size_t  i = l,
                        j = r,
                        p = l,
                        q = r;

                while( true )
                {
                    while( pred( buf[i], v ) )
                        ++i;
                    while( pred( v, buf[--j] ) )
                        if( j == l ) break;
                    if( i >= j )
                        break;
                    exch( i, j );
                    if( equiv( buf[i], v ) )
                        exch( p++, i );
                    if( equiv( v, buf[j] ) )
                        exch( --q, j );
                    ++i;
                }
                exch( i, r );
                if( p < i )
                {
                    j = i - 1;
                    for( size_t k = l; k < p; k++, j-- )
                        exch( k, j );
                    quicksort( l, j );
                }
                if( ++i < q )
                {
                    for( size_t k = r - 1; k >= q; k--, i++ )
                        exch( k, i );
                    quicksort( i, r );
                }
            }

            if( buf.length > 1 )
            {
                quicksort( 0, buf.length - 1 );
            }
        }
    }


    template sort( Buf )
    {
        void sort( Buf buf )
        {
            return sort_!(ElemTypeOf!(Buf)).fn( buf );
        }
    }


    template sort( Buf, Pred )
    {
        void sort( Buf buf, Pred pred )
        {
            return sort_!(ElemTypeOf!(Buf), Pred).fn( buf, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        void test( char[] buf )
        {
            sort( buf );
            char sav = buf[0];
            foreach( cur; buf )
            {
                assert( cur >= sav );
                sav = cur;
            }
        }

        test( "mkcvalsidivjoaisjdvmzlksvdjioawmdsvmsdfefewv".dup );
        test( "asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf".dup );
        test( "the quick brown fox jumped over the lazy dog".dup );
        test( "abcdefghijklmnopqrstuvwxyz".dup );
        test( "zyxwvutsrqponmlkjihgfedcba".dup );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Lower Bound
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a binary search of buf, returning the index of the first
     * location where pat may be inserted without disrupting sort order.  If
     * the sort order of pat precedes all elements in buf then 0 will be
     * returned.  If the sort order of pat succeeds the largest element in buf
     * then buf.length will be returned.  Comparisons will be performed using
     * the supplied predicate or '<' if none is supplied.
     *
     * Params:
     *  buf = The sorted array to search.
     *  pat = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         less than e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or buf.length if no match was found.
     */
    size_t lbound( Elem[] buf, Elem pat, Pred2E pred = Pred2E.init );
}
else
{
    template lbound_( Elem, Pred = IsLess!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat, Pred pred = Pred.init )
        {
            size_t  beg   = 0,
                    end   = buf.length,
                    mid   = end / 2;

            while( beg < end )
            {
                if( pred( buf[mid], pat ) )
                    beg = mid + 1;
                else
                    end = mid;
                mid = beg + ( end - beg ) / 2;
            }
            return mid;
        }
    }


    template lbound( Buf, Pat )
    {
        size_t lbound( Buf buf, Pat pat )
        {
            return lbound_!(ElemTypeOf!(Buf)).fn( buf, pat );
        }
    }


    template lbound( Buf, Pat, Pred )
    {
        size_t lbound( Buf buf, Pat pat, Pred pred )
        {
            return lbound_!(ElemTypeOf!(Buf), Pred).fn( buf, pat, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        assert( lbound( "bcefg", 'a' ) == 0 );
        assert( lbound( "bcefg", 'h' ) == 5 );
        assert( lbound( "bcefg", 'd' ) == 2 );
        assert( lbound( "bcefg", 'e' ) == 2 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Upper Bound
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a binary search of buf, returning the index of the first
     * location beyond where pat may be inserted without disrupting sort order.
     * If the sort order of pat precedes all elements in buf then 0 will be
     * returned.  If the sort order of pat succeeds the largest element in buf
     * then buf.length will be returned.  Comparisons will be performed using
     * the supplied predicate or '<' if none is supplied.
     *
     * Params:
     *  buf = The sorted array to search.
     *  pat = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         less than e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or buf.length if no match was found.
     */
    size_t ubound( Elem[] buf, Elem pat, Pred2E pred = Pred2E.init );
}
else
{
    template ubound_( Elem, Pred = IsLess!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat, Pred pred = Pred.init )
        {
            size_t  beg   = 0,
                    end   = buf.length,
                    mid   = end / 2;

            while( beg < end )
            {
                if( !pred( pat, buf[mid] ) )
                    beg = mid + 1;
                else
                    end = mid;
                mid = beg + ( end - beg ) / 2;
            }
            return mid;
        }
    }


    template ubound( Buf, Pat )
    {
        size_t ubound( Buf buf, Pat pat )
        {
            return ubound_!(ElemTypeOf!(Buf)).fn( buf, pat );
        }
    }


    template ubound( Buf, Pat, Pred )
    {
        size_t ubound( Buf buf, Pat pat, Pred pred )
        {
            return ubound_!(ElemTypeOf!(Buf), Pred).fn( buf, pat, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        assert( ubound( "bcefg", 'a' ) == 0 );
        assert( ubound( "bcefg", 'h' ) == 5 );
        assert( ubound( "bcefg", 'd' ) == 2 );
        assert( ubound( "bcefg", 'e' ) == 3 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Binary Search
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a binary search of buf, returning true if an element equivalent
     * to pat is found.  Comparisons will be performed using the supplied
     * predicate or '<' if none is supplied.
     *
     * Params:
     *  buf = The sorted array to search.
     *  pat = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         less than e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  True if an element equivalent to pat is found, false if not.
     */
    bool bsearch( Elem[] buf, Elem pat, Pred2E pred = Pred2E.init );
}
else
{
    template bsearch_( Elem, Pred = IsLess!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        bool fn( Elem[] buf, Elem pat, Pred pred = Pred.init )
        {
            size_t pos = lbound( buf, pat, pred );
            return pos < buf.length && !( pat < buf[pos] );
        }
    }


    template bsearch( Buf, Pat )
    {
        bool bsearch( Buf buf, Pat pat )
        {
            return bsearch_!(ElemTypeOf!(Buf)).fn( buf, pat );
        }
    }


    template bsearch( Buf, Pat, Pred )
    {
        bool bsearch( Buf buf, Pat pat, Pred pred )
        {
            return bsearch_!(ElemTypeOf!(Buf), Pred).fn( buf, pat, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        assert( !bsearch( "bcefg", 'a' ) );
        assert(  bsearch( "bcefg", 'b' ) );
        assert(  bsearch( "bcefg", 'c' ) );
        assert( !bsearch( "bcefg", 'd' ) );
        assert(  bsearch( "bcefg", 'e' ) );
        assert(  bsearch( "bcefg", 'f' ) );
        assert(  bsearch( "bcefg", 'g' ) );
        assert( !bsearch( "bcefg", 'h' ) );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Includes
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a parallel linear scan of setA and setB from $(LB)0 .. N$(RP)
     * where N = min$(LP)setA.length, setB.length$(RP), returning true if setA
     * includes all elements in setB and false if not.  Both setA and setB are
     * required to be sorted, and duplicates in setB require an equal number of
     * duplicates in setA.  Comparisons will be performed using the supplied
     * predicate or '<' if none is supplied.
     *
     * Params:
     *  setA = The sorted array to evaluate.
     *  setB = The sorted array to match against.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         less than e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  true if setA includes all elements in setB, false if not.
     */
    bool includes( Elem[] setA, Elem[] setB, Pred2E pred = Pred2E.init );
}
else
{
    template includes_( Elem, Pred = IsLess!(Elem) )
    {
        static assert( isCallableType!(Pred ) );


        bool fn( Elem[] setA, Elem[] setB, Pred pred = Pred.init )
        {
            size_t  posA = 0,
                    posB = 0;

            while( posA < setA.length && posB < setB.length )
            {
                if( pred( setB[posB], setA[posA] ) )
                    return false;
                else if( pred( setA[posA], setB[posB] ) )
                    ++posA;
                else
                    ++posA, ++posB;
            }
            return posB == setB.length;
        }
    }


    template includes( BufA, BufB )
    {
        bool includes( BufA setA, BufB setB )
        {
            return includes_!(ElemTypeOf!(BufA)).fn( setA, setB );
        }
    }


    template includes( BufA, BufB, Pred )
    {
        bool includes( BufA setA, BufB setB, Pred pred )
        {
            return includes_!(ElemTypeOf!(BufA), Pred).fn( setA, setB, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        assert( includes( "abcdefg", "a" ) );
        assert( includes( "abcdefg", "g" ) );
        assert( includes( "abcdefg", "d" ) );
        assert( includes( "abcdefg", "abcdefg" ) );
        assert( includes( "aaaabbbcdddefgg", "abbbcdefg" ) );

        assert( !includes( "abcdefg", "aaabcdefg" ) );
        assert( !includes( "abcdefg", "abcdefggg" ) );
        assert( !includes( "abbbcdefg", "abbbbcdefg" ) );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Union Of
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Computes the union of setA and setB as a set operation and returns the
     * retult in a new sorted array.  Both setA and setB are required to be
     * sorted.  If either setA or setB contain duplicates, the result will
     * contain the larger number of duplicates from setA and setB.  When an
     * overlap occurs, entries will be copied from setA.  Comparisons will be
     * performed using the supplied predicate or '<' if none is supplied.
     *
     * Params:
     *  setA = The first sorted array to evaluate.
     *  setB = The second sorted array to evaluate.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         less than e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  A new array containing the union of setA and setB.
     */
    Elem[] unionOf( Elem[] setA, Elem[] setB, Pred2E pred = Pred2E.init );
}
else
{
    template unionOf_( Elem, Pred = IsLess!(Elem) )
    {
        static assert( isCallableType!(Pred ) );


        Elem[] fn( Elem[] setA, Elem[] setB, Pred pred = Pred.init )
        {
            size_t  posA = 0,
                    posB = 0;
            Elem[]  setU;

            while( posA < setA.length && posB < setB.length )
            {
                if( pred( setA[posA], setB[posB] ) )
                    setU ~= setA[posA++];
                else if( pred( setB[posB], setA[posA] ) )
                    setU ~= setB[posB++];
                else
                    setU ~= setA[posA++], posB++;
            }
            setU ~= setA[posA .. $];
            setU ~= setB[posB .. $];
            return setU;
        }
    }


    template unionOf( BufA, BufB )
    {
        ElemTypeOf!(BufA)[] unionOf( BufA setA, BufB setB )
        {
            return unionOf_!(ElemTypeOf!(BufA)).fn( setA, setB );
        }
    }


    template unionOf( BufA, BufB, Pred )
    {
        ElemTypeOf!(BufA)[] unionOf( BufA setA, BufB setB, Pred pred )
        {
            return unionOf_!(ElemTypeOf!(BufA), Pred).fn( setA, setB, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        assert( unionOf( "", "" ) == "" );
        assert( unionOf( "abc", "def" ) == "abcdef" );
        assert( unionOf( "abbbcd", "aadeefg" ) == "aabbbcdeefg" );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Intersection Of
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Computes the intersection of setA and setB as a set operation and
     * returns the retult in a new sorted array.  Both setA and setB are
     * required to be sorted.  If either setA or setB contain duplicates, the
     * result will contain the smaller number of duplicates from setA and setB.
     * All entries will be copied from setA.  Comparisons will be performed
     * using the supplied predicate or '<' if none is supplied.
     *
     * Params:
     *  setA = The first sorted array to evaluate.
     *  setB = The second sorted array to evaluate.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         less than e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  A new array containing the intersection of setA and setB.
     */
    Elem[] intersectionOf( Elem[] setA, Elem[] setB, Pred2E pred = Pred2E.init );
}
else
{
    template intersectionOf_( Elem, Pred = IsLess!(Elem) )
    {
        static assert( isCallableType!(Pred ) );


        Elem[] fn( Elem[] setA, Elem[] setB, Pred pred = Pred.init )
        {
            size_t  posA = 0,
                    posB = 0;
            Elem[]  setI;

            while( posA < setA.length && posB < setB.length )
            {
                if( pred( setA[posA], setB[posB] ) )
                    ++posA;
                else if( pred( setB[posB], setA[posA] ) )
                    ++posB;
                else
                    setI ~= setA[posA++], posB++;
            }
            return setI;
        }
    }


    template intersectionOf( BufA, BufB )
    {
        ElemTypeOf!(BufA)[] intersectionOf( BufA setA, BufB setB )
        {
            return intersectionOf_!(ElemTypeOf!(BufA)).fn( setA, setB );
        }
    }


    template intersectionOf( BufA, BufB, Pred )
    {
        ElemTypeOf!(BufA)[] intersectionOf( BufA setA, BufB setB, Pred pred )
        {
            return intersectionOf_!(ElemTypeOf!(BufA), Pred).fn( setA, setB, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        assert( intersectionOf( "", "" ) == "" );
        assert( intersectionOf( "abc", "def" ) == "" );
        assert( intersectionOf( "abbbcd", "aabdddeefg" ) == "abd" );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Missing From
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Returns a new array containing all elements in setA which are not
     * present in setB.  Both setA and setB are required to be sorted.
     * Comparisons will be performed using the supplied predicate or '<'
     * if none is supplied.
     *
     * Params:
     *  setA = The first sorted array to evaluate.
     *  setB = The second sorted array to evaluate.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         less than e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  A new array containing the elements in setA that are not in setB.
     */
    Elem[] missingFrom( Elem[] setA, Elem[] setB, Pred2E pred = Pred2E.init );
}
else
{
    template missingFrom_( Elem, Pred = IsLess!(Elem) )
    {
        static assert( isCallableType!(Pred ) );


        Elem[] fn( Elem[] setA, Elem[] setB, Pred pred = Pred.init )
        {
            size_t  posA = 0,
                    posB = 0;
            Elem[]  setM;

            while( posA < setA.length && posB < setB.length )
            {
                if( pred( setA[posA], setB[posB] ) )
                    setM ~= setA[posA++];
                else if( pred( setB[posB], setA[posA] ) )
                    ++posB;
                else
                    ++posA, ++posB;
            }
            setM ~= setA[posA .. $];
            return setM;
        }
    }


    template missingFrom( BufA, BufB )
    {
        ElemTypeOf!(BufA)[] missingFrom( BufA setA, BufB setB )
        {
            return missingFrom_!(ElemTypeOf!(BufA)).fn( setA, setB );
        }
    }


    template missingFrom( BufA, BufB, Pred )
    {
        ElemTypeOf!(BufA)[] missingFrom( BufA setA, BufB setB, Pred pred )
        {
            return missingFrom_!(ElemTypeOf!(BufA), Pred).fn( setA, setB, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        assert( missingFrom( "", "" ) == "" );
        assert( missingFrom( "", "abc" ) == "" );
        assert( missingFrom( "abc", "" ) == "abc" );
        assert( missingFrom( "abc", "abc" ) == "" );
        assert( missingFrom( "abc", "def" ) == "abc" );
        assert( missingFrom( "abbbcd", "abd" ) == "bbc" );
        assert( missingFrom( "abcdef", "bc" ) == "adef" );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Difference Of
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
   /**
     * Returns a new array containing all elements in setA which are not
     * present in setB and the elements in setB which are not present in
     * setA.  Both setA and setB are required to be sorted.  Comparisons
     * will be performed using the supplied predicate or '<' if none is
     * supplied.
     *
     * Params:
     *  setA = The first sorted array to evaluate.
     *  setB = The second sorted array to evaluate.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         less than e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  A new array containing the elements in setA that are not in setB
     *  and the elements in setB that are not in setA.
     */
    Elem[] differenceOf( Elem[] setA, Elem[] setB, Pred2E pred = Pred2E.init );
}
else
{
    template differenceOf_( Elem, Pred = IsLess!(Elem) )
    {
        static assert( isCallableType!(Pred ) );


        Elem[] fn( Elem[] setA, Elem[] setB, Pred pred = Pred.init )
        {
            size_t  posA = 0,
                    posB = 0;
            Elem[]  setD;

            while( posA < setA.length && posB < setB.length )
            {
                if( pred( setA[posA], setB[posB] ) )
                    setD ~= setA[posA++];
                else if( pred( setB[posB], setA[posA] ) )
                    setD ~= setB[posB++];
                else
                    ++posA, ++posB;
            }
            setD ~= setA[posA .. $];
            setD ~= setB[posB .. $];
            return setD;
        }
    }


    template differenceOf( BufA, BufB )
    {
        ElemTypeOf!(BufA)[] differenceOf( BufA setA, BufB setB )
        {
            return differenceOf_!(ElemTypeOf!(BufA)).fn( setA, setB );
        }
    }


    template differenceOf( BufA, BufB, Pred )
    {
        ElemTypeOf!(BufA)[] differenceOf( BufA setA, BufB setB, Pred pred )
        {
            return differenceOf_!(ElemTypeOf!(BufA), Pred).fn( setA, setB, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        assert( differenceOf( "", "" ) == "" );
        assert( differenceOf( "", "abc" ) == "abc" );
        assert( differenceOf( "abc", "" ) == "abc" );
        assert( differenceOf( "abc", "abc" ) == "" );
        assert( differenceOf( "abc", "def" ) == "abcdef" );
        assert( differenceOf( "abbbcd", "abd" ) == "bbc" );
        assert( differenceOf( "abd", "abbbcd" ) == "bbc" );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Make Heap
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Converts buf to a heap using the supplied predicate or '<' if none is
     * supplied.
     *
     * Params:
     *  buf  = The array to convert.  This parameter is not marked 'inout' to
     *         allow temporary slices to be sorted.  As buf is not resized in
     *         any way, omitting the 'inout' qualifier has no effect on the
     *         result of this operation, even though it may be viewed as a
     *         side-effect.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         less than e2 and false if not.  This predicate may be any
     *         callable type.
     */
    void makeHeap( Elem[] buf, Pred2E pred = Pred2E.init );
}
else
{
    template makeHeap_( Elem, Pred = IsLess!(Elem) )
    {
        static assert( isCallableType!(Pred ) );


        void fn( Elem[] buf, Pred pred = Pred.init )
        {
            // NOTE: Indexes are passed instead of references because DMD does
            //       not inline the reference-based version.
            void exch( size_t p1, size_t p2 )
            {
                Elem t  = buf[p1];
                buf[p1] = buf[p2];
                buf[p2] = t;
            }

            void fixDown( size_t pos, size_t end )
            {
                if( end <= pos )
                    return;
                while( pos <= ( end - 1 ) / 2 )
                {
                    size_t nxt = 2 * pos + 1;

                    if( nxt < end && pred( buf[nxt], buf[nxt + 1] ) )
                        ++nxt;
                    if( !pred( buf[pos], buf[nxt] ) )
                        break;
                    exch( pos, nxt );
                    pos = nxt;
                }
            }

            if( buf.length < 2 )
                return;

            size_t  end = buf.length - 1,
                    pos = end / 2 + 2;

            do
            {
                fixDown( --pos, end );
            } while( pos > 0 );
        }
    }


    template makeHeap( Buf )
    {
        void makeHeap( Buf buf )
        {
            return makeHeap_!(ElemTypeOf!(Buf)).fn( buf );
        }
    }


    template makeHeap( Buf, Pred )
    {
        void makeHeap( Buf buf, Pred pred )
        {
            return makeHeap_!(ElemTypeOf!(Buf), Pred).fn( buf, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        void basic( char[] buf )
        {
            if( buf.length < 2 )
                return;

            size_t  pos = 0,
                    end = buf.length - 1;

            while( pos <= ( end - 1 ) / 2 )
            {
                assert( buf[pos] >= buf[2 * pos + 1] );
                if( 2 * pos + 1 < end )
                {
                    assert( buf[pos] >= buf[2 * pos + 2] );
                }
                ++pos;
            }
        }

        void test( char[] buf )
        {
            makeHeap( buf );
            basic( buf );
        }

        test( "mkcvalsidivjoaisjdvmzlksvdjioawmdsvmsdfefewv".dup );
        test( "asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf".dup );
        test( "the quick brown fox jumped over the lazy dog".dup );
        test( "abcdefghijklmnopqrstuvwxyz".dup );
        test( "zyxwvutsrqponmlkjihgfedcba".dup );
        test( "ba".dup );
        test( "a".dup );
        test( "".dup );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Push Heap
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Adds val to buf by appending it and adjusting it up the heap.
     *
     * Params:
     *  buf  = The heap to modify.  This parameter is marked 'inout' because
     *         buf.length will be altered.
     *  val  = The element to push onto buf.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         less than e2 and false if not.  This predicate may be any
     *         callable type.
     */
    void pushHeap( inout Elem[] buf, Elem val, Pred2E pred = Pred2E.init );
}
else
{
    template pushHeap_( Elem, Pred = IsLess!(Elem) )
    {
        static assert( isCallableType!(Pred ) );


        void fn( inout Elem[] buf, Elem val, Pred pred = Pred.init )
        {
            // NOTE: Indexes are passed instead of references because DMD does
            //       not inline the reference-based version.
            void exch( size_t p1, size_t p2 )
            {
                Elem t  = buf[p1];
                buf[p1] = buf[p2];
                buf[p2] = t;
            }

            void fixUp( size_t pos )
            {
                if( pos < 1 )
                    return;
                size_t par = ( pos - 1 ) / 2;
                while( pos > 0 && pred( buf[par], buf[pos] ) )
                {
                    exch( par, pos );
                    pos = par;
                    par = ( pos - 1 ) / 2;
                }
            }

            buf ~= val;
            if( buf.length > 1 )
            {
                fixUp( buf.length - 1 );
            }
        }
    }


    template pushHeap( Buf, Val )
    {
        void pushHeap( inout Buf buf, Val val )
        {
            return pushHeap_!(ElemTypeOf!(Buf)).fn( buf, val );
        }
    }


    template pushHeap( Buf, Val, Pred )
    {
        void pushHeap( inout Buf buf, Val val, Pred pred )
        {
            return pushHeap_!(ElemTypeOf!(Buf), Pred).fn( buf, val, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        void basic( char[] buf )
        {
            if( buf.length < 2 )
                return;

            size_t  pos = 0,
                    end = buf.length - 1;

            while( pos <= ( end - 1 ) / 2 )
            {
                assert( buf[pos] >= buf[2 * pos + 1] );
                if( 2 * pos + 1 < end )
                {
                    assert( buf[pos] >= buf[2 * pos + 2] );
                }
                ++pos;
            }
        }

        char[] buf;

        foreach( cur; "abcdefghijklmnopqrstuvwxyz" )
        {
            pushHeap( buf, cur );
            basic( buf );
        }

        buf.length = 0;

        foreach( cur; "zyxwvutsrqponmlkjihgfedcba" )
        {
            pushHeap( buf, cur );
            basic( buf );
        }
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Pop Heap
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Removes the top element from buf by swapping it with the bottom element,
     * adjusting it down the heap, and reducing the length of buf by one.
     *
     * Params:
     *  buf  = The heap to modify.  This parameter is marked 'inout' because
     *         buf.length will be altered.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         less than e2 and false if not.  This predicate may be any
     *         callable type.
     */
    void popHeap( inout Elem[] buf, Pred2E pred = Pred2E.init );
}
else
{
    template popHeap_( Elem, Pred = IsLess!(Elem) )
    {
        static assert( isCallableType!(Pred ) );


        void fn( inout Elem[] buf, Pred pred = Pred.init )
        {
            // NOTE: Indexes are passed instead of references because DMD does
            //       not inline the reference-based version.
            void exch( size_t p1, size_t p2 )
            {
                Elem t  = buf[p1];
                buf[p1] = buf[p2];
                buf[p2] = t;
            }

            void fixDown( size_t pos, size_t end )
            {
                if( end <= pos )
                    return;
                while( pos <= ( end - 1 ) / 2 )
                {
                    size_t nxt = 2 * pos + 1;

                    if( nxt < end && pred( buf[nxt], buf[nxt + 1] ) )
                        ++nxt;
                    if( !pred( buf[pos], buf[nxt] ) )
                        break;
                    exch( pos, nxt );
                    pos = nxt;
                }
            }

            if( buf.length > 1 )
            {
                exch( 0, buf.length - 1 );
                fixDown( 0, buf.length - 2 );
            }
            if( buf.length > 0 )
            {
                buf.length = buf.length - 1;
            }
        }
    }


    template popHeap( Buf )
    {
        void popHeap( inout Buf buf )
        {
            return popHeap_!(ElemTypeOf!(Buf)).fn( buf );
        }
    }


    template popHeap( Buf, Pred )
    {
        void popHeap( inout Buf buf, Pred pred )
        {
            return popHeap_!(ElemTypeOf!(Buf), Pred).fn( buf, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        void test( char[] buf )
        {
            if( buf.length < 2 )
                return;

            size_t  pos = 0,
                    end = buf.length - 1;

            while( pos <= ( end - 1 ) / 2 )
            {
                assert( buf[pos] >= buf[2 * pos + 1] );
                if( 2 * pos + 1 < end )
                {
                    assert( buf[pos] >= buf[2 * pos + 2] );
                }
                ++pos;
            }
        }

        char[] buf = "zyxwvutsrqponmlkjihgfedcba".dup;

        while( buf.length > 0 )
        {
            popHeap( buf );
            test( buf );
        }
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Sort Heap
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Sorts buf as a heap using the supplied predicate or '<' if none is
     * supplied.  Calling makeHeap and sortHeap on an array in succession
     * has the effect of sorting the array using the heapsort algorithm.
     *
     * Params:
     *  buf  = The heap to sort.  This parameter is not marked 'inout' to
     *         allow temporary slices to be sorted.  As buf is not resized
     *         in any way, omitting the 'inout' qualifier has no effect on
     *         the result of this operation, even though it may be viewed
     *         as a side-effect.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         less than e2 and false if not.  This predicate may be any
     *         callable type.
     */
    void sortHeap( Elem[] buf, Pred2E pred = Pred2E.init );
}
else
{
    template sortHeap_( Elem, Pred = IsLess!(Elem) )
    {
        static assert( isCallableType!(Pred ) );


        void fn( Elem[] buf, Pred pred = Pred.init )
        {
            // NOTE: Indexes are passed instead of references because DMD does
            //       not inline the reference-based version.
            void exch( size_t p1, size_t p2 )
            {
                Elem t  = buf[p1];
                buf[p1] = buf[p2];
                buf[p2] = t;
            }

            void fixDown( size_t pos, size_t end )
            {
                if( end <= pos )
                    return;
                while( pos <= ( end - 1 ) / 2 )
                {
                    size_t nxt = 2 * pos + 1;

                    if( nxt < end && pred( buf[nxt], buf[nxt + 1] ) )
                        ++nxt;
                    if( !pred( buf[pos], buf[nxt] ) )
                        break;
                    exch( pos, nxt );
                    pos = nxt;
                }
            }

            if( buf.length < 2 )
                return;

            size_t  pos = buf.length - 1;

            while( pos > 0 )
            {
                exch( 0, pos );
                fixDown( 0, --pos );
            }
        }
    }


    template sortHeap( Buf )
    {
        void sortHeap( Buf buf )
        {
            return sortHeap_!(ElemTypeOf!(Buf)).fn( buf );
        }
    }


    template sortHeap( Buf, Pred )
    {
        void sortHeap( Buf buf, Pred pred )
        {
            return sortHeap_!(ElemTypeOf!(Buf), Pred).fn( buf, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        char[] buf = "zyxwvutsrqponmlkjihgfedcba".dup;

        sortHeap( buf );
        char sav = buf[0];
        foreach( cur; buf )
        {
            assert( cur >= sav );
            sav = cur;
        }
      }
    }
}
