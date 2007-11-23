module output.FileReporter;

import output.ResultReporter;

import util.utils;

static this()
{
	register("file_reporter",function Object(TypeInfo[] arguments, va_list argptr)
	{
		if (arguments.length!=1 && typeid(char[])!=arguments[0]) {
			throw new Exception("Expected 1 argument of type char[]");
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
		tango.io.Stdout.Stdout(file);
		withOpenFile(file, (FormatOutput writer) {
			foreach (value; reporter) {
				writer.format("{} ",value.toUtf8);
			}
			writer.newline;
		});
	}
}