module output.ConsoleReporter;

import std.stdio;

import output.ResultReporter;
import util.utils;

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
			writef(value," ");
		}
		writefln();
	}
}