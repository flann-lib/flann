/*
Project: nn
*/


module util.logger;

import tango.core.Vararg;
import tango.text.convert.Layout;
import tango.text.convert.Sprint;
import tango.io.Console;
import tango.util.log.Log;
import tango.util.log.ConsoleAppender;
	
import util.defines;

public Logger logger;
public Sprint!(char) sprint;

public ConsoleWriter write;

static this()
{
	sprint = new Sprint!(char);
	write = new ConsoleWriter();
	Log.getRootLogger().addAppender(new ConsoleAppender());
	logger = Log.getLogger("log");
}

class ConsoleWriter {

	private Layout!(char) layout;
	
	alias write opCall;
	
	public this() 
	{
		layout = new Layout!(char);	
	}

	ConsoleWriter write(...)
	{
		char[] format = va_arg!(char[])(_argptr);
		layout((char[] s){return Cout.stream.write(s);},_arguments[1..$],_argptr,format);
		Cout.flush();
		
		return this;
	}
}
