module output.SqliteReporter;

// import std.stdio;
import tango.io.Stdout;
import tango.util.Convert : to;
import tango.core.Thread;
import dbi.sqlite.SqliteDatabase;
import dbi.Row;
import dbi.DBIException;
import dbi.ErrorCode;

import output.ResultReporter;
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
	SqliteDatabase db;
	int run;
	
	public this(char[] database) 
	{
		db = new SqliteDatabase();
		db.connect(database);
		
		Row row = db.queryFetchOne("SELECT MAX(run) as max_run FROM results");
		run = to!(int)(row["max_run"]);
		run++;
	}
	
	public ~this() 
	{
		db.close();
	}
	
	public void flush(OrderedParams values) 
	{
		string fields = "";
		string vals = "";
		foreach (name,value; values) {
			fields ~= (name~",");
			if (value.isA!(string)) {
				vals ~= ("'"~value.toString()~"',");
			}// 		this.database = database;

			else {
				vals ~= (value.toString()~",");
			}
		}
		
		
		string query = "INSERT INTO results(run,"~fields[0..$-1]~") VALUES ("~to!(char[])(run)~","~vals[0..$-1]~")";
  		Stdout(query).newline;
  		
  		int retries = 0;
  		bool success = false;
  		while (retries<3 && !success) {
			try {
				db.execute(query);
				success = true;
			} catch(DBIException e) {
				logger.error("Error inserting into database");
				logger.error("SQL: "~e.getSql);
				logger.error("Error code: "~dbi.ErrorCode.toString(e.getErrorCode));
				logger.error(sprint("Specific code: {}",e.getSpecificCode));
			}
			retries++;
			Thread.sleep(1);
		}	
	}
}