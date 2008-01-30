/*
Project: nn
*/


module util.Logger;

import tango.util.log.Log;
import tango.util.log.ConsoleAppender;
	
public Logger logger;

static this()
{
	logger = Log.getLogger("log");
}

void initLogger()
{
	logger.addAppender(new ConsoleAppender());
}

