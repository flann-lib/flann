/*
Project: nn
*/


module util.Logger;

import tango.util.log.Log;
import tango.util.log.ConsoleAppender;
	
public Logger logger;

static this()
{
	Log.getRootLogger().addAppender(new ConsoleAppender());
	logger = Log.getLogger("log");
}

