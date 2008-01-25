module jive.formatters;

public import jive.layout;

private import tango.stdc.stdlib : alloca;
private import jive.meta : Unstatic;

/* GenericFormatter for all character types */

template GenericFormatter (alias Fn)
{
	alias GenericFormatter_impl!(Fn).constructor GenericFormatter;
}

template GenericFormatter_impl (alias Fn)
{
	struct GenericFormatter (alias fn, T) // fn parameter duplicated for clarity
	{
		T value;

		uint opFormat (U) (U[] format, uint delegate (U[]) sink)
		{
			return fn!(T, U) (value, format, sink);
		}
	}

	GenericFormatter!(Fn, Unstatic!(T)) constructor (T) (T arg)
	{
		return GenericFormatter!(Fn, Unstatic!(T)) (arg);
	}
}

/* GenericFormatter for one specific character type */

template GenericFormatter (alias Fn, CharT)
{
	alias GenericFormatter_impl!(Fn, CharT).constructor GenericFormatter;
}

template GenericFormatter_impl (alias Fn, CharT)
{
	struct GenericFormatter (alias fn, T) // fn parameter duplicated for clarity
	{
		T value;

		uint opFormat (CharT[] format, uint delegate (CharT[]) sink)
		{
			return fn!(T) (value, format, sink);
		}
	}

	GenericFormatter!(Fn, Unstatic!(T)) constructor (T) (T arg)
	{
		return GenericFormatter!(Fn, Unstatic!(T)) (arg);
	}
}

//---------------

/* Generic nested formatter that simply calls convert
   recursively;
   Usage exaple:
   	formatln ("{,20:'{}'}", nestedF("foo"));
   	// encloses the string foo in quotes and then
   	// aligns the result to 20 characters
*/

alias GenericFormatter!(nestedF_impl) nestedF;

private uint nestedF_impl (T, U) (T value, U[] format, Sink!(U) sink)
{
	return convert (sink, format, value);
}

