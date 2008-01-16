/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: May 2004
        
        author:         Kris

*******************************************************************************/

module tango.util.log.Log4Layout;

private import  tango.core.Thread;

private import  tango.util.log.Event,
                tango.util.log.EventLayout;

/*******************************************************************************

        A layout with XML output conforming to Log4J specs.
       
*******************************************************************************/

public class Log4Layout : EventLayout
{
        /***********************************************************************
                
                Format message attributes into an output buffer and return
                the populated portion.

        ***********************************************************************/

        char[] header (Event event)
        {
                char[20] tmp;
                char[]   threadName;
                
                threadName = Thread.getThis.name;
                if (threadName.length is 0)
                    threadName = "{unknown}";

                event.append ("<log4j:event logger=\"")
                     .append (event.getName)
                     .append ("\" timestamp=\"")
                     .append (toMilli (tmp, event.getTime.span))
                     .append ("\" level=\"")
                     .append (event.getLevelName [0..length-1])
                     .append ("\" thread=\"").append(threadName).append("\">\r\n<log4j:message><![CDATA[");

                return event.getContent;
        }


        /***********************************************************************
                
                Format message attributes into an output buffer and return
                the populated portion.

        ***********************************************************************/

        char[] footer (Event event)
        {       
                event.scratch.length = 0;
                event.append ("]]></log4j:message>\r\n<log4j:properties><log4j:data name=\"application\" value=\"")
                     .append (event.getHierarchy.getName)
                     .append ("\"/><log4j:data name=\"hostname\" value=\"")
                     .append (event.getHierarchy.getAddress)
                     .append ("\"/></log4j:properties></log4j:event>\r\n");

                return event.getContent;
        }
}


