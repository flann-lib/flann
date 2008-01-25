module jive.formatcat;

public import layout = jive.layout;

private import tango.core.Traits;
private import jive.iterators : IteratorTypeTuple;

uint convertcat
	(U, T)
	(uint delegate (U[]) sink,
	 T                   obj,
	 U[]                 fmt,
	 U[]                 sep = ""/*,
	 Layout!(U)          layout = DefaultLayout!(U)*/)
{
	size_t written = 0;

	static if (isStaticArrayType!(T) || isDynamicArrayType!(T))
	{
		foreach (x; obj)
		{
			if (sep.length > 0 && written > 0)
				written += sink (sep);
			written += layout.convert (sink, fmt, x);
		}
	}
	else static if (isAssocArrayType!(T))
	{
		alias typeof(T.init.values[0]) V;
		alias typeof(T.init.keys[0]) K;

		foreach (K k, V v; obj)
		{
			if (sep.length > 0 && written > 0)
				written += sink (sep);
			written += layout.convert (sink, fmt, k, v);
		}
	}
	else /* opApply-compatible delegates or objects with opApply method */
	{
		alias IteratorTypeTuple!(T) iT;

		foreach (ref iT x; obj)
		{
			if (sep.length > 0 && written > 0)
				written += sink (sep);
			written += layout.convert (sink, fmt, x);
		}
	}

	return written;
}

char[] sprintcat
	(U, T)
	(U[]        buf,
	 T          obj,
	 U[]        fmt,
	 U[]        sep = ""/*,
	 Layout!(U) layout = DefaultLayout!(U)*/)
{
	U*     ptr = buf.ptr;
	size_t len = buf.length;

	uint sink (U[] data)
	{
		size_t dlen = data.length;
		assert (dlen < (buf.ptr + len) - ptr, "Buffer overflow.");
		ptr [0 .. dlen] = data;
		ptr += dlen;
		return dlen;
	}

	convertcat (&sink, obj, fmt, sep/*, layout*/);
	return buf [0 .. ptr - buf.ptr];
}

char[] formatcat
	(U, T)
	(T          obj,
	 U[]        fmt,
	 U[]        sep = ""/*,
	 Layout!(U) layout = DefaultLayout!(U)*/)
{
	U[] output;

	uint sink (U[] data)
	{
		output ~= data;
		return data.length;
	}

	convertcat (&sink, obj, fmt, sep/*, layout*/);
	return output;
}

debug (UnitTest)
{
	unittest
	{
		assert (formatcat ([1, 2, 3], "{}") == "123");
		assert (formatcat ([1, 2, 3], "#{}", ", ") == "#1, #2, #3");
	}
}

// import tango.io.Console;
// 
// alias double T;
// 
// void main ()
// {
// 	char[1024] buf;
// 	
// 	Cout (sprintcat (buf, [1, 2, 3], "{}")).newline;
// 	Cout (sprintcat (buf, [1, 2, 3], "#{}", ", ")).newline;
// 
// 	int iterator (int delegate (ref char[], ref T) dg)
// 	{
// 		char[] s; T f; int result;
// 		s = "Incoming traffic";
// 		f = 649.3;
// 		if ((result = dg (s, f)) != 0) return result;
// 		s = "Outgoing traffic";
// 		f = 222.6;
// 		if ((result = dg (s, f)) != 0) return result;
// 		s = "Total traffic";
// 		f = 871.8;
// 		if ((result = dg (s, f)) != 0) return result;
// 		return 0;
// 	}
// 
// 	Cout (sprintcat (buf, &iterator, "{}: {}k/s", "\n")).newline;
// }
