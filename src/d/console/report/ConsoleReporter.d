module console.report.ConsoleReporter;

import tango.io.Stdout;

import console.report.ResultReporter;
import util.defines;
import util.Registry;
import util.Utils;

mixin RegisterSingleton!("console_reporter",ConsoleReporter);

class ConsoleReporter : ReportBackend
{
	public void flush(OrderedParams reporter) 
	{
		foreach (value; reporter) {
			Stdout.format("{,5} ",value.toString);
		}
		Stdout.newline;
	}
}