module jive.iterators;

public import tango.core.Traits;

private import jive.meta;
private import tango.util.collection.model.Iterator : TangoIterator = Iterator;

void grow (T) (inout T array, size_t amount)
{
	size_t tmp = array.length;
	array.length = tmp + amount;
	array.length = tmp;
}

package template IteratorTypeTuple (T)
{
 	static if (is(T Params == delegate))
 		alias ParameterTupleOf!(ParameterTupleOf!(typeof(T))[0]) IteratorTypeTuple;
	else
		alias ParameterTupleOf!(ParameterTupleOf!(typeof(T.opApply))[0]) IteratorTypeTuple;
}

struct Enumerate (T)
{
	private T source;

	static if (isStaticArrayType!(T) || isDynamicArrayType!(T))
	{
		private alias typeof(T[0]) iT;

		int opApply(int delegate(ref size_t, ref iT) dg)
		{
			int result = 0;
			for (size_t i = 0; i < source.length; i++)
			{
				if ((result = dg (i, source[i])) != 0) break;
			}

			return result;
		}
	}
	else static if (isAssocArrayType!(T))
	{
		private alias typeof(T.init.values[0]) V;
		private alias typeof(T.init.keys[0]) K;

		int opApply(int delegate(ref size_t, ref K, ref V) dg)
		{
			int result = 0;
			size_t i = 0;

			foreach (K k, V v; source)
			{
				if ((result = dg (i, k, v)) != 0) break;
				i++;
			}

			return result;
		}
	}
	else
	{
		private alias IteratorTypeTuple!(T) TypeTuple;

		int opApply(int delegate(ref size_t, TypeTuple) dg)
		{
			int result = 0;
			size_t i = 0;

			foreach (ref TypeTuple x; source)
			{
				if ((result = dg (i, x)) != 0) break;
				++i;
			}

			return result;
		}
	}
}

Enumerate!(T) enumerate(T) (T source)
{
	return Enumerate!(T) (source);
}

struct ZipIterator (T, U)
{
/+	pragma (msg, T.stringof ~ "|" ~ isStaticArrayType!(T).stringof ~ "|" ~ isDynamicArrayType!(T).stringof);
	pragma (msg, U.stringof ~ "|" ~ isStaticArrayType!(U).stringof ~ "|" ~ isDynamicArrayType!(U).stringof);+/
	private
	{
		T source1;
		U source2;
	}

	static if (isAssocArrayType!(T) || isAssocArrayType!(U))
		static assert (false, "SideBySide not supported on associative arrays.");
	else static if (isStaticArrayType!(T) || isDynamicArrayType!(T))
	{
		private
		{
			private alias typeof(T[0]) TypeTuple1;
			static if (isStaticArrayType!(U) || isDynamicArrayType!(T))
				private alias typeof(U[0]) TypeTuple2;
			else
				private alias IteratorTypeTuple!(U) TypeTuple2;
		}

		int opApply (int delegate (ref TypeTuple1, ref TypeTuple2) dg)
		{
			int result = 0;
			int i = 0;

			foreach (ref TypeTuple2 x; source2)
			{
				if (i >= source1.length) break;
				if ((result = dg (source1[i], x)) != 0) break;
				i++;
			}

			return result;
		}
	}
	else static if (isStaticArrayType!(U) || isDynamicArrayType!(U))
	{
		private alias typeof(U[0]) TypeTuple2;
		private alias IteratorTypeTuple!(T) TypeTuple1;

		int opApply (int delegate (ref TypeTuple1, ref TypeTuple2) dg)
		{
			int result = 0;
			int i = 0;

			foreach (ref TypeTuple1 x; source1)
			{
				if (i >= source2.length) break;
				if ((result = dg (x, source2[i])) != 0) break;
				i++;
			}

			return result;
		}
	}
	else static if (is(T V : TangoIterator!(V)))
	{
		private
		{
			private alias V TypeTuple1;
			static if (isStaticArrayType!(U) || isDynamicArrayType!(T))
				private alias typeof(U[0]) TypeTuple2;
			else
				private alias IteratorTypeTuple!(U) TypeTuple2;
		}

		int opApply (int delegate (ref TypeTuple1, ref TypeTuple2) dg)
		{
			int result = 0;

			foreach (ref TypeTuple2 x; source2)
			{
				if (! source1.more()) break;
				if ((result = dg (source1.get(), x)) != 0) break;
			}

			return result;
		}
	}
	else
	{
		debug { pragma (msg, "Warning: iterating sidebyside using two objects uses buffering."); }
		private alias IteratorTypeTuple!(T) TypeTuple1;
		private alias IteratorTypeTuple!(U) TypeTuple2;

		int opApply (int delegate (TypeTuple1, TypeTuple2) dg)
		{
			int result = 0;
			int i = 0;
			
			Stuple!(TypeTuple1)[] X = generate (source1);
// 			grow!(typeof(X))(X, 1024);
// 			//grow (X, 1024)
// 			foreach (ref TypeTuple1 x; source1)
// 			{
// 				X ~= stuple(x);
// 			}

			foreach (ref TypeTuple2 y; source2)
			{
				if (i >= X.length) break;
				if ((result = dg (X[i].tupleof, y)) != 0) break;
				i++;
			}
			
			return result;
		}
	}
}

ZipIterator!(T, U) zip (T, U) (T x, U y)
{
	return ZipIterator!(T, U) (x, y);
}

private template TypeOfGenerate (T)
{
	static if (is(T : T[]) || isStaticArrayType!(T))
		alias typeof(T[0]) TypeOfGenerate;
	else static if (IteratorTypeTuple!(T).length == 1)
		alias IteratorTypeTuple!(T)[0] TypeOfGenerate;
	else
		alias Stuple!(IteratorTypeTuple!(T)) TypeOfGenerate;
}

TypeOfGenerate!(T)[] generate (T) (T obj)
{
	static if (isStaticArrayType!(T) || isDynamicArrayType!(T))
	{
		return obj.dup;
	}
	else static if (IteratorTypeTuple!(T).length == 1)
	{
		TypeOfGenerate!(T)[] X;
		X.length = 32; X.length = 0;
		foreach (ref TypeOfGenerate!(T) x; obj)
			X ~= x;
		return X;
	}
	else
	{
		TypeOfGenerate!(T)[] X;
		X.length = 32; X.length = 0;
		foreach (ref typeof(TypeOfGenerate!(T).tupleof) x; obj)
			X ~= stuple (x);
		return X;
	}
}

char[] IteratorMixinV1 (char[] method)
{
	return `
	int delegate (ParameterTupleOf!(` ~ method ~ `)) ` ~ method ~ ` ()
	{
		return &this.` ~ method ~ `;
	};`;
}

// struct Iterator (T, alias M)
// {
// 	private T source;
// 
// 	int opApply (ParameterTupleOf!(M) p)
// 	{
// 		//return mixin("source." ~ M.stringof ~ "(p)");
// 		source.M();
// 	}
// }

char[] IteratorMixinV2 (char[] method)
{
	return `
	alias typeof(this) Supertype_` ~ method ~ `;
	struct Iterator_` ~ method ~ ` {
		private Supertype_` ~ method ~` source;
		int opApply (ParameterTupleOf!(` ~ method ~ `) args)
		{
			return source.` ~ method ~ ` (args);
		}
	}
	final Iterator_` ~ method ~ ` ` ~ method ~ ` ()
	{
		return Iterator_` ~ method ~ ` (this);
	};`;
}
