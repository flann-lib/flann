/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Nov 2005: split from Configurator.d
        verison:        Feb 2007: removed default console configuration
         
        author:         Kris

*******************************************************************************/

module tango.util.log.PropertyConfigurator;

private import  tango.io.FilePath;

private import  tango.util.log.Log;

private import  tango.text.Properties;

/*******************************************************************************

        A utility class for initializing the basic behaviour of the
        default logging hierarchy.

        PropertyConfigurator parses a much simplified version of the 
        property file. tango.log only supports the settings of Logger 
        levels at this time; setup of Appenders and Layouts are currently 
        done "in the code"

*******************************************************************************/

struct PropertyConfigurator
{
        /***********************************************************************
        
                Add a default StdioAppender, with a SimpleTimerLayout, to 
                the root node. The activity levels of all nodes are set
                via a property file with name=value pairs specified in the
                following format:

                    name: the actual logger name, in dot notation
                          format. The name "root" is reserved to
                          match the root logger node.

                   value: one of TRACE, INFO, WARN, ERROR, FATAL
                          or NONE (or the lowercase equivalents).

                For example, the declaration

                ---
                tango.unittest = INFO
                myApp.SocketActivity = TRACE
                ---
                
                sets the level of the loggers called tango.unittest and
                myApp.SocketActivity

        ***********************************************************************/

        static void opCall (FilePath path)
        {
                void loader (char[] name, char[] value)
                {
                        auto l = (name == "root") ? Log.getRootLogger
                                                  : Log.getLogger (name);

                        if (l)
                            l.setLevel (Log.level(value));
                }

                // read and parse properties from file
                Properties!(char).load (path, &loader);
        }
}

