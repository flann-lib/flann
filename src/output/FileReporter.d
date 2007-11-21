module output.FileReporter;

// import std.stdio;

import output.ResultReporter;
// import std.stdio;
import util.utils;

static this()
{
	register_reporter!(FileReporter);
}

class FileReporter : ResultReporter
{
	static string NAME = "file";
	
	public void flush(OrderedParams reporter) 
	{
		withOpenFile(output, (FormatOutput writer) {
			foreach (value; reporter) {
				writer("{} ",value);
			}
			writer("\n");
		});
	}
}