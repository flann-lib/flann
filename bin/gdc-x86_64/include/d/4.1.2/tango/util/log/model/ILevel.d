/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: May 2004
        
        author:         Kris

*******************************************************************************/

module tango.util.log.model.ILevel;

/*******************************************************************************

*******************************************************************************/

interface ILevel
{
        /***********************************************************************
                
                These represent the standard LOG4J event levels. Note that
                Debug is called Trace here, because debug is a reserved word
                in D (this needs to be fixed!).

        ***********************************************************************/

        enum Level {Trace=0, Info, Warn, Error, Fatal, None};
}
