module output.ConsoleReporter;

import tango.io.Stdout;

import output.ResultReporter;
import util.defines;
import util.Registry;
import util.Utils;

mixin RegisterSingleton!("console_reporter",ConsoleReporter);

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