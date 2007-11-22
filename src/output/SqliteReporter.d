module output.SqliteRepoter;

// import std.stdio;
import tango.io.Stdout;

import output.ResultReporter;
import util.utils;
import dbi.sqlite.SqliteDatabase;


static this()
{
	register_reporter!(SqliteRepoter);
}

class SqliteRepoter : ResultReporter
{
	static string NAME = "sqlite";
	
	public void flush(OrderedParams values) 
	{
		auto db = new SqliteDatabase();
		db.connect(output);

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
		db.execute(query);
		
		db.close();
	}
}