/*
Project: nn
*/


module util.logger;

import std.stdio;
import std.format;

class Logger 
{
static {

	const LogLevel INFO = cast(LogLevel)"info";
	const LogLevel DEBUG = cast(LogLevel)"debug";
	const LogLevel ERROR = cast(LogLevel)"error";
	
	const LogLevel SIMPLE = cast(LogLevel)"simple";

	
	private typedef string LogLevel;
	
	int[LogLevel] levels;
	
 	FILE* streams[];
	
	void addStream(FILE* stream) {
 		streams[streams.length] = stream;
	}
	
	
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
		FILE* activeStream = stdout;

		void putChar(dchar c)
    	{
			fputc(c, activeStream);
    	}

		if (logLevel in levels) {
			doFormat(&putChar, _arguments, _argptr);
			fflush(activeStream);		
		}
		
	}
	
	
}
}