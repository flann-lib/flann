/************************************************************************
 * Logging functionality.
 *
 * This module contains the logging functionality. We use Tango's
 * execellent logging subsystem. 
 * 
 * Authors: Marius Muja, mariusm@cs.ubc.ca
 * 
 * Version: 0.9
 * 
 * History:
 * 
 * License:
 * 
 *************************************************************************/
module util.Logger;

import tango.util.log.Log;
import tango.util.log.ConsoleAppender;

/**
 * The default logger used through the application
 */
public Logger logger;

/**
 * Static initializer. This is run at application startup 
 * before main function.
 */
static this()
{
	logger = Log.getLogger("log");
}

/**
 * Logging initialization.
 * 
 * By default all logging goes to the console.
 */
void initLogger()
{
	logger.addAppender(new ConsoleAppender());
}

