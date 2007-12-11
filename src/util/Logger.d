/*
Project: nn
*/


module util.logger;

import tango.text.convert.Sprint;
import tango.util.log.Log;
import tango.util.log.ConsoleAppender;
	
import util.defines;

public Logger logger;
public Sprint!(char) sprint;


static this()
{
	sprint = new Sprint!(char);
	Log.getRootLogger().addAppender(new ConsoleAppender());
	logger = Log.getLogger("log");
}

