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

private Layout!(char) layout;

static this()
{
	sprint = new Sprint!(char);
	layout = new Layout!(char);
	Log.getRootLogger().addAppender(new ConsoleAppender());
	logger = Log.getLogger("log");
}

void write(...)
{
	char[] format = va_arg!(char[])(_argptr);
 	layout((char[] s){return Cout.stream.write(s);},_arguments[1..$],_argptr,format);
	Cout.flush();
}
