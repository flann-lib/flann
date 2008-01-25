/**

   Based on tango.text.convert.Layout by Kris

   Original copyright notice at the end of the file

   Copyright: Copyright (C) 2007-2008 Zygfryd (aka Hxal). All rights reserved.
   License:   zlib
   Authors:   Kris, Zygfryd (aka Hxal)

 */

module jive.layout;

import tango.core.Traits;

private import jive.meta : Unstatic, itoa, expandForeach;

private import Integer = tango.text.convert.Integer;
private import Float = tango.text.convert.Float;
private import Utf = tango.text.convert.Utf;

private import tango.stdc.stdlib : alloca;

private import tango.time.Time : Time, TimeSpan;
private import tango.text.locale.Convert : formatDateTime;
private import tango.text.locale.Core : DateTimeFormat, IFormatService;

public template Sink (CharT) { alias uint delegate (CharT[]) Sink; }

/* root of custom typeinfos, allows us to reference select
   methods of the actual type (here : opFormat) without knowing
   the exact type at runtime */

public class LayoutTypeInfo /*: TypeInfo // not needed */
{
	size_t tsize;
	//abstract size_t tsize ();
	abstract uint opFormat (void* object, char[] format, Sink!(char) sink);
	abstract uint opFormat (void* object, wchar[] format, Sink!(wchar) sink);
	abstract uint opFormat (void* object, dchar[] format, Sink!(dchar) sink);
}

/* subclass LayoutTypeInfo and create a singleton, similar to typeid(T) */

private class typeidLayoutClass (T) : LayoutTypeInfo
{
	pragma (msg, "creating typeidLayout for " ~ T.stringof);
	static typeof(this) singleton;

	this ()
	{
		tsize = T.sizeof;
	}

	static this ()
	{
		singleton = new typeof(this);
	}

	template opFormatMixin (CharT)
	{
		override uint opFormat (void* object, CharT[] format, Sink!(CharT) sink)
		{
			static if (is (T == Time))
			{
				static if (is (CharT == char))
					return formatDate!(CharT) (*cast(Time*) object, format, sink);
				else
					return sink ("{Time supported for char only}");
			}
			else static if (is (T == struct) || is (T == class) || is (T == interface) || is (T == union))
			{
				static if (is(typeof((cast(T*) object).opFormat(format, sink)))) // struct provides opFormat of the right type
				{
					//pragma (msg, "direct impl for " ~ CharT.stringof);
					return (cast(T*) object).opFormat (format, sink);
				}
				else
				{
					/* wrap sink with an encoding converter */

					const char[] achar;
					const wchar[] awchar;
					const dchar[] adchar;
					const Sink!(char) fchar;
					const Sink!(wchar) fwchar;
					const Sink!(dchar) fdchar;
					//pragma (msg, typeof((&T.opFormat)(awchar, fwchar)).stringof);
					static if (is(typeof((cast(T*) object).opFormat(achar, fchar))))
						alias char V;
					else static if (is(typeof((cast(T*) object).opFormat(awchar, fwchar))))
						alias wchar V;
					else static if (is(typeof((cast(T*) object).opFormat(adchar, fdchar))))
						alias dchar V;
					else
						static assert (false, "Type " ~ T.stringof ~ " doesn't implement opFormat for either char, wchar or dchar.");

					//static assert (!is(CharT == V), T.stringof ~ " " ~ CharT.stringof);
					static if (is(CharT == V))
					{ // I don't know why the outer static if started failing O_o
						return (cast(T*) object).opFormat (format, sink);
					}
					else
					{
						V[8192] fmtbuf;
						V[] newfmt;

						static if (is(V == char))
							newfmt = Utf.toString (format, fmtbuf);
						else static if (is(V == wchar))
							newfmt = Utf.toString16 (format, fmtbuf);
						else static if (is(V == dchar))
							newfmt = Utf.toString32 (format, fmtbuf);

						uint sinkwrap (V[] s)
						{
							CharT[16384] buf;

							static if (is(CharT == char))
								sink (Utf.toString (s, buf));
							else static if (is(CharT == wchar))
								sink (Utf.toString16 (s, buf));
							else static if (is(CharT == dchar))
								sink (Utf.toString32 (s, buf));
							else
								static assert (false);

							return s.length;
						}

						return (cast(T*) object).opFormat (newfmt, &sinkwrap);
					}
				}
			}
			else static if (isIntegerType!(T))
				return formatInteger!(CharT, T) (object, format, sink);
				
			else static if (isRealType!(T))
				return formatFloat!(CharT, T) (object, format, sink);
				
			else static if (isStaticArrayType!(T) || isDynamicArrayType!(T))
				return formatArray!(CharT, typeof(T[0])) (object, format, sink);
				
			else static if (is(T == void*) || isPointerType!(T))
				return formatPointer!(CharT, T) (object, format, sink);
				
			else static if (isCharType!(T))
				return formatCharacter!(CharT, T) (object, format, sink);
				
			else
				static assert (0, "Type " ~ typeof(T).stringof ~ " is unsupported by the formatter");
			//return doFormat!(T) (object, format, sink);
		}
	}

	mixin opFormatMixin!(char);
	mixin opFormatMixin!(wchar);
	mixin opFormatMixin!(dchar);

	//override size_t tsize () { return T.sizeof; }

	/*
	override hash_t getHash (void* p) { return typeid(T).getHash(p); }
	override int equals (void* p1, void* p2) { return typeid(T).equals(p1, p2); }
	override int compare (void* p1, void* p2) { return typeid(T).compare(p1, p2); }
	override void swap (void* p1, void* p2) { typeid(T).swap(p1, p2); }
	*/
	//...
}

/* replacement for typeid(T) that returns our TypeInfos for select types */

public template typeidLayout (T)
{
	alias typeidLayoutClass!(Unstatic!(T)).singleton typeidLayout;
}

private template typeidLayoutArray_impl (T...)
{
	LayoutTypeInfo[T.length] array;

	static this ()
	{
		int i = 0;
		foreach (t; T)
		{
			array[i] = typeidLayout!(t);
			//Stdout.formatln ("typeidLayout!({}) = 0x{:x8}", t.stringof, cast(void*) array[i]);
			i++;
		}
	}
}

private template typeidLayoutArray_impl2 (T...)
{
	/* this is crucial so that typeidLayoutClass static constructors
   executed before typeidLayoutArray_impl static constructors */
	alias expandForeach!(typeidLayout, T) expandTheseNow;
	alias typeidLayoutArray_impl!(T).array array;
}

public template typeidLayoutArray (T...)
{
	alias typeidLayoutArray_impl2!(T).array typeidLayoutArray;
}

/* formula taken from tango.core.Vararg */

private template argptr_size (T)
{
	const argptr_size = ( T.sizeof + int.sizeof - 1 ) & ~( int.sizeof - 1 ); // fancy way of saying T.sizeof aligned to int.sizeof
}

/* generate mixin code for building an _argptr array from discrete arguments */
/* this ctfe function is sadly generated in the binary, (for every T...)
   could be turned into a template instead */

public char[] build_argptr (T...) () //TODO: change to template, might be faster
{
	int i = 0;
	char[] output = "void*[" ~ itoa(T.length) ~ "] _argptr;\n";
	foreach (t; T)
	{
		char[] I = itoa(i);
		if (is (t == Unstatic!(t)))
		{
			//output ~= "// " ~ t.stringof ~ "\n";
			output ~= "_argptr[" ~ I ~ "] = &args[" ~ I ~ "];\n";
		}
		else
		{
			//output ~= "// " ~ t.stringof ~ " --> " ~ Unstatic!(t).stringof ~ "\n";
			output ~= "Unstatic!(typeof(args[" ~ I ~"])) _arg" ~ I ~ " = args[" ~ I ~ "];\n";
			output ~= "_argptr[" ~ I ~ "] = &_arg" ~ I ~ ";\n";
		}
		i++;
	}

	return output;
}

/** */
public uint convert (CharT, T...) (uint delegate (CharT[]) sink, CharT[] format, T args) //"Sink!(U) sink" doesn't work
{
	version (GNU) { struct S { pragma (GNU_set_attribute, convert!(CharT, T), always_inline); } }
	
	static if (T.length > 0)
	{
		//pragma (msg, build_argptr!(T)());
		mixin (build_argptr!(T)());
		return vconvert!(CharT) (sink, typeidLayoutArray!(T), _argptr, format);
	}
	else
	{
		return vconvert!(CharT) (sink, null, null, format);
	}
}

private uint vconvert (CharT) (Sink!(CharT) sink, LayoutTypeInfo[] _arguments, void*[] _argptr, CharT[] fmt)
{
	//Stdout.formatln ("{}", formatcat ((cast(ubyte*)_argptr)[0..28], "{:x2}", "."));
	//Stdout.format ("convert({}):", fmt);
	
	if (fmt.length == 0)
	{
		uint ret = 0;
		for (int index = 0; index < _arguments.length; index++)
		{
			ret += _arguments[index].opFormat (_argptr[index], fmt, sink);
		}
		return ret;
	}

	CharT* s = fmt.ptr;
	CharT* fs = s;
	CharT* end = s + fmt.length;
	CharT* bs = cast(CharT*) alloca (fmt.length * CharT.sizeof);
	CharT* b = bs;
	int lastindex = -1;
	uint ret = 0;

	while (s < end)
	{
		//while (s < end && *s != '{') s++;
		while (s < end)
		{
			if (*s is '\\')
			{
				//Stdout.formatln ("<{}>-", *s);
				if (s + 1 < end)
				{
					*(b++) = *(++s);
					s++;
				}
				else
					s++;
			}
			else if (*s is '{')
				break;
			else
				*(b++) = *(s++);
		}
		
		//ret += sink (fs [0 .. s-fs]);
		ret += sink (bs [0 .. b-bs]);
		b = bs;
		//Stdout.formatln ("writing '{}' {}", fs [0 .. s-fs], ret);
		fs = s;
		
		if (s >= end) break;
		
		int index;
		int width;
		CharT[] sf;
		fs = s = parseFormat (s [1 .. end-s], index, width, sf).ptr;
		
// 		if (*s !is '}')
// 			throw new Exception ("missing }");

		//fs = ++s;

		if (index == NoIndex)
			index = ++lastindex;
		else
			lastindex = index;
		
		if (index < 0)
			index = _arguments.length - index;

		//Stdout.format("<{}>", index);

		uint actual;

		if (width > 0)
		{
			uint capacity = width > 128 ? width : 128;
			CharT[] buf = (cast(CharT*) alloca (capacity * CharT.sizeof)) [0 .. capacity];
			uint written = 0;

			uint bufsink (CharT[] z)
			{
				CharT[] Z = cast(CharT[]) z;
				if (written + Z.length >= capacity)
				{
					sink (buf[0 .. written]);
					written = 0;
					sink (z);
					return Z.length;
				}
				buf[written .. written + Z.length] = Z;
				written += Z.length;
				return Z.length;
			}

			actual = _arguments[index].opFormat (_argptr[index], sf, &bufsink);
			if (actual < width)
				actual += spaces!(CharT) (sink, width - actual);
			if (written)
				actual += sink (buf[0 .. written]);
		}
		else
		{
			width = -width;
			actual = _arguments[index].opFormat (_argptr[index], sf, sink);
			//if (width != 0)
			//	actual += convert (sink, "<{}>" , actual);
			if (actual < width)
				actual += spaces!(CharT) (sink, width - actual);
		}
		
		ret += actual;
	}
	
	return ret;
}

/** */
public CharT[] sprint (CharT, T...) (CharT[] output, CharT[] format, T args)
{
	version (GNU) { struct S { pragma (GNU_set_attribute, sprint!(CharT, T), always_inline); } }

	CharT* p = output.ptr;
	CharT* end = output.ptr + output.length;

	uint sink (CharT[] s)
	{
		int len = s.length;
		if (len < end - p)
		{
			p [0..len] = s;
			p += len;
		}
		else
			throw new Exception ("jive.layout.sprint :: output buffer is full");
		return len;
	}

	convert (&sink, format, args);
	return output[0 .. p - output.ptr];
}

/** */
public CharT[] sformat (CharT, T...) (CharT[] format, T args)
{
	version (GNU) { struct S { pragma (GNU_set_attribute, sformat!(CharT, T), always_inline); } }

	CharT[] output;

	uint sink (CharT[] s)
	{
		output ~= s;
		return s.length;
	}

	convert (&sink, format, args);
	return output;
}

/** */
public CharT[] sformatbuf (CharT, T...) (size_t bufsize, CharT[] format, T args)
{
	version (GNU) { struct S { pragma (GNU_set_attribute, sformatbuf!(CharT, T), always_inline); } }

	CharT[] output;
	CharT[] buf = (cast(CharT*) alloca (CharT.sizeof * bufsize)) [0 .. bufsize];
	size_t written = 0;

	uint sink (CharT[] s)
	{
		if (s.length + written > buf.length)
		{
			if (written > 0)
			{
				output ~= buf[0 .. written];
				written = 0;
			}
			
			output ~= s;
			return s.length;
		}

		buf[written .. written + s.length] = s;
		written += s.length;

		return s.length;
	}

	convert (&sink, format, args);

	if (written > 0)
		output ~= buf[0 .. written];

	return output;
}

/** */
public uint convertOne (CharT, T) (uint delegate (CharT[]) sink, CharT[] fmt, T arg)
{
	Unstatic!(T) val = arg;
	LayoutTypeInfo type = typeidLayout!(T);
	return type.opFormat (&val, fmt, sink);
}

/**
   Provides the possibility of explicit CharT definition.

   Example: LayoutFor!(char).sformat ("{} {}", arg1, arg2)
 */
public template LayoutFor (CharT)
{
	/** */
	uint convert (T...) (uint delegate (CharT[]) sink, CharT[] format, T args) //"Sink!(U) sink" doesn't work
	{
		return .convert!(CharT, T) (sink, format, args);
	}

	/** */
	CharT[] sprint (T...) (CharT[] output, CharT[] format, T args)
	{
		return .sprint!(CharT, T) (output, format, args);
	}
	
	/** */
	CharT[] sformat (T...) (CharT[] format, T args)
	{
		return .sformat!(CharT, T) (format, args);
	}

	/** */
	CharT[] sformatbuf (T...) (size_t bufsize, CharT[] format, T args)
	{
		return .sformatbuf!(CharT, T) (bufsize, format, args);
	}
}

private bool parseGeneric (T) (T[] format, ref uint width, ref T style)
{
	if (format.length)
	{
		uint number;
		auto p = format.ptr;
		auto e = p + format.length;
		style = *p;

		while (++p < e)
			if (*p >= '0' && *p <= '9')
				number = number * 10 + *p - '0';
			else
				break;

		if (p - format.ptr > 1)
		{
			width = number;
			return true;
		}
	}
	return false;
}

private const int NoIndex = int.max;

private:

CharT[] parseFormat (CharT) (CharT[] fmt, out int index, out int width, out CharT[] subformat)
{
	CharT* s   = fmt.ptr;
	CharT* end = s + fmt.length;
	index = NoIndex;
	bool negindex = false;

	if (*s == '-')
	{
		negindex = true;
		s++;
	}

	if (*s >= '0' && *s <= '9')
	{
		index = 0;
		do
			index = index * 10 + (*s++ - '0');
		while (*s >= '0' && *s <= '9');

		if (negindex)
			index *= -1;
	}

	// skip spaces
	while (s < end && *s is ' ') s++;

	width = 0;
	bool left = false;

	// padding
	if (*s is ',')
	{
		while (++s < end && *s is ' ') {};

		if (*s is '-')
		{
			left = true;
			s++;
		}

		while (*s >= '0' && *s <= '9')
			width = width * 10 + (*s++ - '0');

		if (left)
			width *= -1;

		while (s < end && *s is ' ') s++;
	}

	// subformat
	if (*s is ':')
	{
		CharT* fs = ++s;
		int depth = 1;
		
		while (s < end)
		{
/+			if (*s == '\\')
			{
				s += 2;
			}
			else+/ if (*s == '{')
				depth += 1;
			else if (*s == '}')
			{
				depth -= 1;
				if (depth == 0) break;
			}

			s++;
		}

		subformat = fs [0 .. s - fs];
	}

	//Stdout.format ("<parseFormat({} -> {} {} {})>", fmt, index, width, subformat);
	
 	if (*s !is '}')
		throw new Exception ("missing }");

	return s [1 .. end-s];
}

uint formatInteger (CharT, T) (void* object, CharT[] format, Sink!(CharT) sink)
{
	static if (isSignedIntegerType!(T))
		CharT style = 'd';
//	else static if (isPointerType!(T))
//		CharT style = 'x';
	else
		CharT style = 'u';

	CharT[1024] _buf = void;
	CharT[] buf = _buf;
	Integer.Flags flags;
	uint width = 256;
	
	if (parseGeneric (format, width, style))
		if (width <= 256)
		{
			buf    = buf[0 .. width];
			flags |= flags.Zero;
		}
		
	CharT[] ret = Integer.format!(CharT, T) (buf, *cast(T*) object, cast(Integer.Style) style, flags);
	return sink (ret);
}

uint formatFloat (CharT, T) (void* object, CharT[] format, Sink!(CharT) sink)
{
	CharT       style = 'f';
	CharT[1024] _buf = void;
	CharT[]     buf = _buf;
	uint places = 2;
	
	parseGeneric (format, places, style);
	CharT[] ret = Float.format!(CharT, T) (buf, *cast(T*) object, places, (style is 'e' || style is 'E') ? 0 : 10);
	return sink (ret);
}

uint formatPointer (CharT, T) (void* object, CharT[] format, Sink!(CharT) sink)
{
	CharT style = 'p';
	CharT[1024] _buf = void;
	CharT[] buf = _buf;
	Integer.Flags flags;
	uint width = 256;
	
	if (parseGeneric (format, width, style))
		if (width <= 256)
		{
			buf    = buf[0 .. width];
			flags |= flags.Zero;
		}

	if (style is '*')
	{
		static if (is(T == void*))
			return sink ("{cannot dereference void*}");
		else
			return convert (sink, format[1..$], **cast(T*) object);
	}
	else if (style is 'z')
	{
		static if (!is(T == void*) && isCharType!(typeof(*T)))
		{
			size_t len = 0;
			T ptr = *cast(T*) object;
			while (*ptr != '\0' && len <= width)
			{
				ptr++;
				len++;
			}
			typeof(*T)[] array = (*cast(T*) object)[0 .. len];
			return formatArray!(CharT, typeof(*T)) (&array, "", sink);
		}
		else
			return convert!(CharT, char[]) (sink, "\\{cannot interpret {} as zero-terminated array}", T.stringof);
	}
	else
	{
		uint ret = 0;

		if (style is 'p')
		{
			ret = sink ("0x");
			style = 'x';
			if (width < 4) width = 8;
		}

		CharT[] res = Integer.format!(CharT, uint) (buf, cast(uint) *cast(T*) object, cast(Integer.Style) style, flags);
		return ret + sink (res);
	}
}

IFormatService GlobalDTF;
static this ()
{
	GlobalDTF = cast(IFormatService)DateTimeFormat.current;
}

uint formatDate (CharT) (Time object, CharT[] format, Sink!(CharT) sink)
{
	CharT[1024] buf = void;
	CharT[] ret = formatDateTime (buf, object, format.length > 0 ? format : "s", GlobalDTF);
	return sink (ret);
}

uint formatCharacter (CharT, T) (void* object, CharT[] format, Sink!(CharT) sink)
{
	static if (is(CharT == T))
	{
		CharT[1] buf;
		buf[0] = *cast(CharT*) object;
		return sink (buf);
	}
	else
	{
		//pragma (msg, "converting " ~ T.stringof ~ " to " ~ CharT.stringof);
		//Stdout ("<converting " ~ T.stringof ~ " to " ~ CharT.stringof ~ ">");
		T[1] str;
		str[0] = *cast(T*) object;
		CharT[6] buf;// = (cast(CharT*) alloca (len * CharT.sizeof)) [0 .. len];
		CharT[] ret;
		static if (is(CharT == char))
			ret = Utf.toString (str, buf);
		else static if (is(CharT == wchar))
			ret = Utf.toString16 (str, buf);
		else static if (is(CharT == dchar))
			ret = Utf.toString32 (str, buf);
		else
			static assert (false);
		return sink (ret);
	}
}

uint formatArray (CharT, T) (void* object, CharT[] format, Sink!(CharT) sink)
{
	static if (isCharType!(T))
	{
		//return sink ("string(") + sink (*cast(T[]*) object) + sink (")");
		//return sink (to!(CharT[]) (*cast(T[]*) object));

		static if (is(CharT == T))
		{
			return sink (*cast(CharT[]*) object);
		}
		else
		{
			//pragma (msg, "converting " ~ T.stringof ~ " to " ~ CharT.stringof);
			//Stdout ("<converting " ~ T.stringof ~ " to " ~ CharT.stringof ~ ">");
			T[] str = *cast(T[]*) object;
			size_t len = str.length * 6;
			CharT[] buf = (cast(CharT*) alloca (len * CharT.sizeof)) [0 .. len];
			static if (is(CharT == char))
				buf = Utf.toString (str, buf);
			else static if (is(CharT == wchar))
				buf = Utf.toString16 (str, buf);
			else static if (is(CharT == dchar))
				buf = Utf.toString32 (str, buf);
			else
				static assert (false);
			return sink (buf);
		}
	}
	else static if (is(T == void))
	{
		static assert (false, "void[] is not formattable, cast it to a proper type");
	}
	else
	{
		CharT[] efmt = "{}";
		CharT[] sep = ", ";

		if (format.length > 0)
		{
			int    i = 0;

			while (i < format.length && format[i] != '{' && format[i] != '}') i++;
			sep = format[0 .. i];
			if (i < format.length)
			{
				int j = i;
				int depth = 0;

				while (j < format.length)
				{
					if (format[j] == '{')
						depth += 1;
					else if (format[j] == '}')
					{
						depth -= 1;
						if (depth == 0) break;
					}

					j++;
				}
				
				if (depth > 0)
					return sink ("{unterminated format specifier}");

				efmt = format[i .. j+1];
			}
		}
		//Stdout.formatln ("inp=({}), sep=({}), fmt=({})", format, sep, efmt);

		T[]  array = *cast(T[]*) object;
		uint ret = 0;//sink ("array(");
		foreach (element; array)
		{
			if (ret > 0)
				ret += sink (sep);
			//Stdout.format ("<convert({}, {}>", efmt, element);
			ret += //typeidLayout!(T).opFormat (&element, efmt, sink);
				convert (sink, efmt, element);
		}
		return ret;// + sink (")");
	}
}

private uint spaces (CharT) (Sink!(CharT) sink, int count)
{
	uint ret;

	static const CharT[32] Spaces = ' ';
	while (count > Spaces.length)
	{
		ret += sink (Spaces);
		count -= Spaces.length;
	}

	return ret + sink (Spaces[0..count]);
}

/*******************************************************************************
			copyright:      Copyright (c) 2005 Kris. All rights reserved
			license:        BSD style: $(LICENSE)
			version:        Initial release: 2005
			author:         Kris
******************************************************************************/
