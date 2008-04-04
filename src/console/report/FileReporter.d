module console.report.FileReporter;

import console.report.ResultReporter;

import util.Utils;
import util.Registry;

static this()
{
	Registry.register("file_reporter",function Object(TypeInfo[] arguments, va_list argptr)
	{
		if (arguments.length!=1 && typeid(char[])!=arguments[0]) {
			throw new FLANNException("Expected 1 argument of type char[]");
		}
		
		return new FileReporter(va_arg!(char[])(argptr));
	});
}

class FileReporter : ReportBackend
{
	private char[] file;
	
	public this(char[] file)
	{
		this.file = file;
	}
	
	public void flush(OrderedParams reporter) 
	{
		withOpenFile(file, (FormatOutput writer) {
			foreach (value; reporter) {
				writer.format("{} ",value.toString);
			}
			writer.newline;
		});
	}
}