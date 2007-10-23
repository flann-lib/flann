module output.SqliteRepoter;

import std.stdio;

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
				vals ~= ("'"~value.toString()~"',");
			}
			else {
				vals ~= (value.toString()~",");
			}
		}
		
		string query = "INSERT INTO results("~fields[0..$-1]~") VALUES ("~vals[0..$-1]~")";
  		writefln(query);
		db.execute(query);
		
		db.close();
	}
}