/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: May 2004
        
        author:         Kris

*******************************************************************************/

module tango.util.log.Configurator;

private import  tango.util.log.Log,
                tango.util.log.EventLayout,
                tango.util.log.ConsoleAppender;

/*******************************************************************************

        Basic utility for initializing the basic behaviour of the
        default logging hierarchy.

        Adds a default StdioAppender, with a SimpleTimerLayout, to 
        the root node, and set the activity level to be everything 
        enabled.
                
*******************************************************************************/

static this()
{
        Log.getRootLogger.addAppender(new ConsoleAppender(new SimpleTimerLayout));
}



/*******************************************************************************

*******************************************************************************/

public class Configurator
{
        /***********************************************************************

                No longer required. Just import this module instead

        ***********************************************************************/

        deprecated static void opCall ()
        {
        }
}

