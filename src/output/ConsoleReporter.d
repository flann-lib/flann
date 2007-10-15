
module output.ConsoleReporter;

import util.logger;
public import output.ResultReporter;

import std.stdio;

class ConsoleReporter : ResultReporter
{
	
	public void flush() 
	{
		foreach (value; values) {
			Logger.log(Logger.REPORT,value," ");
		}
		Logger.log(Logger.REPORT,"\n");
	}
}