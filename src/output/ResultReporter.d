
module output.ResultReporter;

import util.variant;


abstract class ResultReporter
{
	Variant[string] values;
	
	void opIndexAssign(T)(T value, string name) 
	{
		setValue(name,value);
	}

	void setValue(T)(string name, T value) 
	{
		values[name] = Variant(value);
	}

	
	public void flush();
}