/*
Project: nn
*/


module util.logger;

// import std.stdio;
// import std.format;
import tango.core.Vararg;
import tango.text.convert.Layout;
import tango.text.convert.Sprint;
import tango.io.Console;
import tango.io.Stdout;

import util.defines;
import util.allocator;

private static Sprint!(char) sprint;

static this() {
	sprint = new Sprint!(char);
}

class Logger 
{
static {

	const LogLevel INFO = cast(LogLevel)"info";
	const LogLevel DEBUG = cast(LogLevel)"debug";
	const LogLevel ERROR = cast(LogLevel)"error";
	
	const LogLevel SIMPLE = cast(LogLevel)"simple";
	const LogLevel REPORT = cast(LogLevel)"report";

	
	private typedef string LogLevel;
	
	int[LogLevel] levels;
	
	
	public void enableLevel(LogLevel level) 
	{
		levels[level] = levels.length;
	}
	
	public void enableLevel(string level) 
	{
		enableLevel(cast(LogLevel)level);
	}

	public void disableLevel(LogLevel level) 
	{
		levels.remove(level);
	}

	public void log(LogLevel logLevel, ...)
	{
/+		const int BUFFER_SIZE = 1000;
		mixin(allocate_static("char[BUFFER_SIZE] buffer;"));+/
		
		if (logLevel in levels) {
			int size = _arguments.length;
			
			char[] format = va_arg!(char[])(_argptr);
			Cout(sprint(format,_arguments[1..$],_argptr));
			Cout.flush;
		}
		
	}
	
	
}
}