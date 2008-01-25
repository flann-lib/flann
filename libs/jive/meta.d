/******************************************************************************

    Parts based on code from scrapple.tools

******************************************************************************/

module jive.meta;

public import tango.core.Traits;

char[] itoa (int input)
{
	assert (input >= 0);

	if (input > 0)
	{
		char[] result;
		while (input)
		{
			result = "0123456789"[input % 10] ~ result;
			input /= 10;
		}
		return result;
	}
	else
		return "0";
}

template eval (A...)
{
	const typeof(A[0]) eval = A[0];
}

template Tuple (T...)
{
	alias T Tuple;
}

template Init (T)
{
	T Init;
}

template Unstatic (T)
{
	alias T Unstatic;
}

template Unstatic (T : T[])
{
	alias T[] Unstatic;
}

template expandForeach (alias T, U...)
{
	static if (U.length > 0)
	{
		alias T!(U[0]) X;
		static if (U.length > 0)
			alias expandForeach!(T, U[1 .. $]) Y;
	}
}

template applyForeach (alias T, U...)
{
	static if (U.length == 0)
		alias Tuple!() applyForeach;
	else static if (U.length == 1)
		alias Tuple!(T!(U[0])) applyForeach;
	else
		alias Tuple!(T!(U[0]), applyForeach!(T, U[1..$])) applyForeach;
}

template UnstaticTuple (T...)
{
	static if (T.length == 0)
		alias Tuple!() UnstaticTuple;
	else
		alias Tuple!(Unstatic!(T[0]), UnstaticTuple!(T[1..$])) UnstaticTuple;
}

private char[] stuple_expand (int args)
{
	char[] output = "";
	for (int i = 0; i < args; i++)
	{
		char[] a = itoa (i);
		output ~= "Unstatic!(T[" ~ a ~ "]) _" ~ a ~ ";\n";
	}
	return output;
}

struct Stuple (T...)
{
	mixin (stuple_expand (T.length));
}

Stuple!(T) stuple (T...) (T t)
{
	return Stuple!(T) (t);
}
