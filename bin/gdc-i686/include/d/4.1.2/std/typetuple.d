
// Written in the D programming language.

/**
 * Templates with which to manipulate type tuples (also known as type lists).
 *
 * Some operations on type tuples are built in to the language,
 * such as TL[$(I n)] which gets the $(I n)th type from the
 * type tuple. TL[$(I lwr) .. $(I upr)] returns a new type
 * list that is a slice of the old one.
 *
 * References:
 *	Based on ideas in Table 3.1 from
 *	$(LINK2 http://www.amazon.com/exec/obidos/ASIN/0201704315/ref=ase_classicempire/102-2957199-2585768,
 *		Modern C++ Design),
 *	 Andrei Alexandrescu (Addison-Wesley Professional, 2001)
 * Macros:
 *	WIKI = Phobos/StdTypeTuple
 * Copyright:
 *	Public Domain
 */

/* Author:
 *	Walter Bright, Digital Mars, www.digitalmars.com
 */

module std.typetuple;

/**
 * Creates a typetuple out of a sequence of zero or more types.
 * Example:
 * ---
 * import std.typetuple;
 * alias TypeTuple!(int, double) TL;
 *
 * int foo(TL td)  // same as int foo(int, double);
 * {
 *    return td[0] + cast(int)td[1];
 * }
 * ---
 *
 * Example:
 * ---
 * TypeTuple!(TL, char)
 * // is equivalent to:
 * TypeTuple!(int, double, char)
 * ---
 */
template TypeTuple(TList...)
{
    alias TList TypeTuple;
}

/**
 * Returns the index of the first occurrence of type T in the
 * sequence of zero or more types TList.
 * If not found, -1 is returned.
 * Example:
 * ---
 * import std.typetuple;
 * import std.stdio;
 *
 * void foo()
 * {
 *    writefln("The index of long is ",
 *          IndexOf!(long, TypeTuple!(int, long, double)));
 *    // prints: The index of long is 1
 * }
 * ---
 */
template IndexOf(T, TList...)
{
    static if (TList.length == 0)
	const int IndexOf = -1;
    else static if (is(T == TList[0]))
	const int IndexOf = 0;
    else
	const int IndexOf =
		(IndexOf!(T, TList[1 .. length]) == -1)
			? -1
			: 1 + IndexOf!(T, TList[1 .. length]);
}

/**
 * Returns a typetuple created from TList with the first occurrence,
 * if any, of T removed.
 * Example:
 * ---
 * Erase!(long, int, long, double, char)
 * // is the same as:
 * TypeTuple!(int, double, char)
 * ---
 */
template Erase(T, TList...)
{
    static if (TList.length == 0)
	alias TList Erase;
    else static if (is(T == TList[0]))
	alias TList[1 .. length] Erase;
    else
	alias TypeTuple!(TList[0], Erase!(T, TList[1 .. length])) Erase;
}

/**
 * Returns a typetuple created from TList with the all occurrences,
 * if any, of T removed.
 * Example:
 * ---
 * alias TypeTuple!(int, long, long, int) TL;
 *
 * EraseAll!(long, TL)
 * // is the same as:
 * TypeTuple!(int, int)
 * ---
 */
template EraseAll(T, TList...)
{
    static if (TList.length == 0)
	alias TList EraseAll;
    else static if (is(T == TList[0]))
	alias EraseAll!(T, TList[1 .. length]) EraseAll;
    else
	alias TypeTuple!(TList[0], EraseAll!(T, TList[1 .. length])) EraseAll;
}

/**
 * Returns a typetuple created from TList with the all duplicate
 * types removed.
 * Example:
 * ---
 * alias TypeTuple!(int, long, long, int, float) TL;
 *
 * NoDuplicates!(TL)
 * // is the same as:
 * TypeTuple!(int, long, float)
 * ---
 */
template NoDuplicates(TList...)
{
    static if (TList.length == 0)
	alias TList NoDuplicates;
    else
	alias TypeTuple!(TList[0], NoDuplicates!(EraseAll!(TList[0], TList[1 .. length]))) NoDuplicates;
}

/**
 * Returns a typetuple created from TList with the first occurrence
 * of type T, if found, replaced with type U.
 * Example:
 * ---
 * alias TypeTuple!(int, long, long, int, float) TL;
 *
 * Replace!(long, char, TL)
 * // is the same as:
 * TypeTuple!(int, char, long, int, float)
 * ---
 */
template Replace(T, U, TList...)
{
    static if (TList.length == 0)
	alias TList Replace;
    else static if (is(T == TList[0]))
	alias TypeTuple!(U, TList[1 .. length]) Replace;
    else
	alias TypeTuple!(TList[0], Replace!(T, U, TList[1 .. length])) Replace;
}

/**
 * Returns a typetuple created from TList with all occurrences
 * of type T, if found, replaced with type U.
 * Example:
 * ---
 * alias TypeTuple!(int, long, long, int, float) TL;
 *
 * ReplaceAll!(long, char, TL)
 * // is the same as:
 * TypeTuple!(int, char, char, int, float)
 * ---
 */
template ReplaceAll(T, U, TList...)
{
    static if (TList.length == 0)
	alias TList ReplaceAll;
    else static if (is(T == TList[0]))
	alias TypeTuple!(U, ReplaceAll!(T, U, TList[1 .. length])) ReplaceAll;
    else
	alias TypeTuple!(TList[0], ReplaceAll!(T, U, TList[1 .. length])) ReplaceAll;
}

/**
 * Returns a typetuple created from TList with the order reversed.
 * Example:
 * ---
 * alias TypeTuple!(int, long, long, int, float) TL;
 *
 * Reverse!(TL)
 * // is the same as:
 * TypeTuple!(float, int, long, long, int)
 * ---
 */
template Reverse(TList...)
{
    static if (TList.length == 0)
	alias TList Reverse;
    else
	alias TypeTuple!(Reverse!(TList[1 .. length]), TList[0]) Reverse;
}

/**
 * Returns the type from TList that is the most derived from type T.
 * If none are found, T is returned.
 * Example:
 * ---
 * class A { }
 * class B : A { }
 * class C : B { }
 * alias TypeTuple!(A, C, B) TL;
 *
 * MostDerived!(Object, TL) x;  // x is declared as type C
 * ---
 */
template MostDerived(T, TList...)
{
    static if (TList.length == 0)
	alias T MostDerived;
    else static if (is(TList[0] : T))
	alias MostDerived!(TList[0], TList[1 .. length]) MostDerived;
    else
	alias MostDerived!(T, TList[1 .. length]) MostDerived;
}

/**
 * Returns the typetuple TList with the types sorted so that the most
 * derived types come first.
 * Example:
 * ---
 * class A { }
 * class B : A { }
 * class C : B { }
 * alias TypeTuple!(A, C, B) TL;
 *
 * DerivedToFront!(TL)
 * // is the same as:
 * TypeTuple!(C, B, A)
 * ---
 */
template DerivedToFront(TList...)
{
    static if (TList.length == 0)
	alias TList DerivedToFront;
    else
	alias TypeTuple!(MostDerived!(TList[0], TList[1 .. length]),
	                DerivedToFront!(ReplaceAll!(MostDerived!(TList[0], TList[1 .. length]),
						    TList[0],
						    TList[1 .. length]))) DerivedToFront;
}
