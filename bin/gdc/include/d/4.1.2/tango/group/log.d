/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Dec 2007: Initial release

        author:         Kris

        Convenience module to import tango.util.log modules 

*******************************************************************************/

module tango.group.log;

public import tango.util.log.Log;
public import tango.util.log.Logger;
public import tango.util.log.Hierarchy;
public import tango.util.log.DateLayout;
public import tango.util.log.Log4Layout;
public import tango.util.log.EventLayout;
public import tango.util.log.FileAppender;
public import tango.util.log.MailAppender;
public import tango.util.log.SocketAppender;
public import tango.util.log.ConsoleAppender;
public import tango.util.log.RollingFileAppender;
                

