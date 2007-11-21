/*
Project: nn
*/


module util.logger;

// import std.stdio;
// import std.format;
import tango.text.convert.Layout;

import util.defines;

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
		
		
	}
	
	
}
}