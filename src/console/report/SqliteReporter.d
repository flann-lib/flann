module console.report.SqliteReporter;

import tango.io.Stdout;
import tango.util.Convert : to;
import tango.sys.Process;

import console.report.ResultReporter;
import util.Utils;
import util.Logger;
import util.Registry;

static this()
{
	Registry.register("sqlite_reporter",function Object(TypeInfo[] arguments, va_list argptr)
	{
		if (arguments.length!=1 && typeid(char[])!=arguments[0]) {
			throw new FANNException("Expected 1 argument of type char[]");
		}
			
		return new SqliteReporter(va_arg!(char[])(argptr));
	});
}

class SqliteReporter : ReportBackend
{
	char[] database;
	Process p;
	
	public this(char[] database) 
	{
		this.database = database;
		p = new Process();
	}
	
	public ~this()
	{
		delete p;
	}
	
	public void flush(OrderedParams values) 
	{
		string fields = "";
		string vals = "";
		foreach (name,value; values) {
			fields ~= (name~",");
			if (value.isA!(string)) {
				vals ~= ("'"~value.toString()~"',");
			}
			else {
				
				vals ~= (value.toString()~",");
			}
		}
		
		
		string query = "INSERT INTO results("~fields[0..$-1]~") VALUES ("~vals[0..$-1]~")";
  		Stdout(query).newline;
  		try {
	  		p.execute("sqlite3 " ~ database ~ " \"" ~ query ~ "\"",null);
	  	}
		catch (ProcessCreateException e)
		{
			logger.error("Process execution failed: " ~ e.toString);
		}
  	
	}
}