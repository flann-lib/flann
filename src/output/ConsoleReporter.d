module output.ConsoleReporter;

import tango.io.Stdout;

import output.ResultReporter;
import util.utils;
import util.defines;

static this()
{
	register("console_reporter",function Object(TypeInfo[] arguments, va_list argptr)
	{
		return new ConsoleReporter();
	});
}

class ConsoleReporter : ReportBackend
{
	public void flush(OrderedParams reporter) 
	{
		foreach (value; reporter) {
			Stdout.format("{,5} ",value.toUtf8);
		}
		Stdout.newline;
	}
}