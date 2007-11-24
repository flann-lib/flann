module output.SqliteRepoter;

// import std.stdio;
import tango.io.Stdout;
import dbi.sqlite.SqliteDatabase;
import dbi.DBIException;
import dbi.ErrorCode;

import output.ResultReporter;
import util.utils;
import util.logger;


static this()
{
	register("sqlite_reporter",function Object(TypeInfo[] arguments, va_list argptr)
	{
		if (arguments.length!=1 && typeid(char[])!=arguments[0]) {
			throw new Exception("Expected 1 argument of type char[]");
		}
			
		return new SqliteRepoter(va_arg!(char[])(argptr));
	});
}

class SqliteRepoter : ReportBackend
{
	public char[] database;
	
	public this(char[] database) 
	{
		this.database = database;
	}
	
	public void flush(OrderedParams values) 
	{
		auto db = new SqliteDatabase();
		db.connect(database);
		scope(exit) db.close();

		string fields = "";
		string vals = "";			
		foreach (name,value; values) {
			fields ~= (name~",");
			if (value.isA!(string)) {
				vals ~= ("'"~value.toUtf8()~"',");
			}
			else {
				vals ~= (value.toUtf8()~",");
			}
		}
		
		string query = "INSERT INTO results("~fields[0..$-1]~") VALUES ("~vals[0..$-1]~")";
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
				logger.error("Error code: "~toString(e.getErrorCode));
				logger.error(sprint("Specific code: {}",e.getSpecificCode));
			}
		}	
	}
}