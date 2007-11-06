// Written in the D programming language.

/**
 * This module defines tools for effecting contracts and enforcing
 * predicates (a la $(D_PARAM assert)).
 *
 * Macros:
 *	WIKI = Phobos/StdContracts
 *
 * Synopsis:
 *
 * ----
 * string synopsis()
 * {
 *     FILE* f = enforce(fopen("some/file"));
 *     // f is not null from here on
 *     FILE* g = enforceEx!(WriteException)(fopen("some/other/file", "w"));
 *     // g is not null from here on
 *     Exception e = collectException(write(g, readln(f)));
 *     if (e)
 *     {
 *         ... an exception occurred...
 *     }
 *     char[] line;
 *     enforce(readln(f, line));
 *     return assumeUnique(line);
 * }
 * ----
 * 
 * Author:
 * Andrei Alexandrescu
 * 
 * Credits:
 * 
 * Brad Roberts came up with the name $(D_PARAM contracts).
 */

module std2.contracts;

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

/**
 * If $(D_PARAM value) is nonzero, returns it. Otherwise, throws
 * $(D_PARAM new Exception(msg)).
 * Example:
 * ----
 * auto f = enforce(fopen("data.txt"));
 * auto line = readln(f);
 * enforce(line.length); // expect a non-empty line
 * ----
 */

T enforce(T)(T value, lazy string msg = "")
{
    if (value) return value;
    throw new Exception(msg);
}

/**
 * If $(D_PARAM value) is nonzero, returns it. Otherwise, throws
 * $(D_PARAM new E(msg)).
 * Example:
 * ----
 * auto f = enforceEx!(FileMissingException)(fopen("data.txt"));
 * auto line = readln(f);
 * enforceEx!(DataCorruptionException)(line.length);
 * ----
 */

template enforceEx(E)
{
    T enforceEx(T)(T value, lazy string msg = "")
    {
        if (value) return value;
        throw new E(msg);
    }
}

unittest
{
    enforce(true);
    enforce(true, "blah");
    typedef Exception MyException;
    try
    {
        enforceEx!(MyException)(false);
        assert(false);
    }
    catch (MyException e)
    {
    }
}

/**
 * Evaluates $(D_PARAM expression). If evaluation throws an exception,
 * return that exception. Otherwise, deposit the resulting value in
 * $(D_PARAM target) and return $(D_PARAM null).
 * Example:
 * ----
 * int[] a = new int[3];
 * int b;
 * assert(collectException(a[4], b));
 * ----
 */

Exception collectException(T)(lazy T expression, ref T target)
{
    try
    {
        target = expression();
    }
    catch (Exception e)
    {
        return e;
    }
    return null;
}

unittest
{
    int[] a = new int[3];
    int b;
    int foo() { throw new Exception("blah"); }
    assert(collectException(foo(), b));
}

/** Evaluates $(D_PARAM expression). If evaluation throws an
 * exception, return that exception. Otherwise, return $(D_PARAM
 * null). $(D_PARAM T) can be $(D_PARAM void).
 */

Exception collectException(T)(lazy T expression)
{
    try
    {
        expression();
    }
    catch (Exception e)
    {
        return e;
    }
    return null;
}

unittest
{
    int foo() { throw new Exception("blah"); }
    assert(collectException(foo()));
}

/**
 * Casts a mutable array to an invariant array in an idiomatic
 * manner. Technically, $(D_PARAM assumeUnique) just inserts a cast,
 * but its name documents assumptions on the part of the
 * caller. $(D_PARAM assumeUnique(arr)) should only be called when
 * there are no more active mutable aliases to elements of $(D_PARAM
 * arr). To strenghten this assumption, $(D_PARAM assumeUnique(arr))
 * also clears $(D_PARAM arr) before returning. Essentially $(D_PARAM
 * assumeUnique(arr)) indicates commitment from the caller that there
 * is no more mutable access to any of $(D_PARAM arr)'s elements
 * (transitively), and that all future accesses will be done through
 * the invariant array returned by $(D_PARAM assumeUnique).
 *
 * Typically, $(D_PARAM assumeUnique) is used to return arrays from
 * functions that have allocated and built them.
 *
 * Example:
 *
 * ----
 * string letters()
 * {
 *   char[] result = new char['z' - 'a' + 1];
 *   foreach (i, ref e; result)
 *   {
 *     e = 'a' + i;
 *   }
 *   return assumeUnique(result);
 * }
 * ----
 *
 * The use in the example above is correct because $(D_PARAM result)
 * was private to $(D_PARAM letters) and is unaccessible in writing
 * after the function returns. The following example shows an
 * incorrect use of $(D_PARAM assumeUnique).
 *
 * Bad:
 *
 * ----
 * private char[] buffer;
 * string letters(char first, char last)
 * {
 *   if (first >= last) return null; // fine
 *   auto sneaky = buffer;
 *   sneaky.length = last - first + 1;
 *   foreach (i, ref e; sneaky)
 *   {
 *     e = 'a' + i;
 *   }
 *   return assumeUnique(sneaky); // BAD
 * }
 * ----
 *
 * The example above wreaks havoc on client code because it is
 * modifying arrays that callers considered immutable. To obtain an
 * invariant array from the writable array $(D_PARAM buffer), replace
 * the last line with:
 * ----
 * return to!(string)(sneaky); // not that sneaky anymore
 * ----
 *
 * The call will duplicate the array appropriately.
 * 
 * Checking for uniqueness during compilation is possible in certain
 * cases (see the $(D_PARAM unique) and $(D_PARAM lent) keywords in the
 * $(LINK2 http://archjava.fluid.cs.cmu.edu/papers/oopsla02.pdf,ArchJava)
 * language), but complicates the language considerably. The downside
 * of $(D_PARAM assumeUnique)'s
 * convention-based usage is that at this time there is no formal
 * checking of the correctness of the assumption; on the upside, the
 * idiomatic use of $(D_PARAM assumeUnique) is simple and rare enough
 * to make it tolerable.
 *
 */

T[] assumeUnique(T)(ref T[] array)
{
    auto result = cast(T[]) array;
    array = null;
    return result;
}

unittest
{
    int[] arr = new int[1];
    auto arr1 = assumeUnique(arr);
    assert(is(typeof(arr1) == int[]) && arr == null);
}
