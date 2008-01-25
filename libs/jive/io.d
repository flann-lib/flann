module jive.io;

private import layout = jive.layout;
public import jive.layout : sprint, sformat;

private import tango.io.model.IConduit;
private import tango.io.model.IBuffer;
private import tango.io.Console;

version (Win32)
{
	template LineEnding (T)
	{
		const T[] LineEnding = cast(T[]) "\r\n";
	}
}
else
{
	template LineEnding (T)
	{
		const T[] LineEnding = cast(T[]) "\n";
	}
}

/** */
uint format (CharT, T...) (OutputStream stream, CharT[] fmt, T args)
{
	uint sink (CharT[] s)
	{
		stream.write (s);
		return s.length;
	}

	return layout.convert (&sink, fmt, args);
}

/** */
uint format (CharT, T...) (CharT[] fmt, T args)
{
	return format (Cout.stream, fmt, args);
}

/** */
uint formatln (CharT, T...) (OutputStream stream, CharT[] fmt, T args)
{
	uint result = format (stream, fmt, args);
	stream.write (LineEnding!(CharT));
	stream.flush ();

	return result + LineEnding!(CharT).length;
}

/** */
uint formatln (CharT, T...) (CharT[] fmt, T args)
{
	return formatln (Cout.stream, fmt, args);
}

/** */
uint write (void[] s)
{
	return Cout.stream.write (s);
}

/** */
uint writeln (void[] s)
{
	uint n = Cout.stream.write (s) + Cout.stream.write ("\n");
	Cout.flush();
	return n;
}

uint writeln ()
{
	uint n = Cout.stream.write ("\n");
	Cout.flush();
	return n;
}

/** */
uint writeln (OutputStream stream, void[] s)
{
	uint n = stream.write (s) + stream.write ("\n");
	stream.flush();
	return n;
}

uint writeln (OutputStream stream)
{
	uint n = stream.write ("\n");
	stream.flush();
	return n;
}

/** */
bool readln (CharT) (inout CharT[] output, IBuffer from, bool raw = false)
{
	uint line (void[] input)
	{
		auto text = cast(char[]) input;
		foreach (i, c; text)
		{
			if (c is '\n')
			{
				auto j = i;
				if (raw)
					j++;
				else
					if (j && (text[j-1] is '\r'))
						j--;
				output = text [0 .. j];
				return i + 1;
			}
		}
		return IConduit.Eof;
	}

	return from.next (&line) ||
		(output = cast(char[]) from.slice (from.readable), false);
}

/** */
bool readln (CharT) (inout CharT[] output, bool raw = false)
{
	return readln (output, cast(IBuffer) Cin.stream, raw);
}

/** */
void flush ()
{
	Cout.flush();
}

struct writeTo (U = char)
{
	OutputStream stream;

	private uint sink (U[] s)
	{
		stream.write (s);
		return s.length;
	}

	writeTo opShl (T) (T arg)
	{
		layout.convertOne (&sink, "", arg);
		return *this;
	}
}

writeTo!(char) cout;
writeTo!(char) cerr;

static this ()
{
	cout = writeTo!(char) (Cout.stream);
	cerr = writeTo!(char) (Cerr.stream);
}
