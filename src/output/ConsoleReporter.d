module output.ConsoleReporter;

// import std.stdio;
import tango.io.Stdout;

import output.ResultReporter;
import util.utils;
import util.defines;

static this()
{
	register_reporter!(ConsoleReporter);
}

class ConsoleReporter : ResultReporter
{
	static string NAME = "console";
	
	public void flush(OrderedParams reporter) 
	{
		foreach (value; reporter) {
			Stdout.format("{} ",value);
		}
		Stdout("\n");
	}
}