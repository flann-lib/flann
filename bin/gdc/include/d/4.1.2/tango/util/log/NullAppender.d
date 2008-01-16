/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: May 2004
        
        author:         Kris

*******************************************************************************/

module tango.util.log.NullAppender;

private import tango.util.log.Appender;

/*******************************************************************************

        An appender that does nothing. This is useful for cutting and
        pasting, and for benchmarking the tango.log environment.

*******************************************************************************/

public class NullAppender : Appender
{
        private Mask mask;

        /***********************************************************************
               
                Construct a NullAppender

        ***********************************************************************/

        this ()
        {
                // Get a unique fingerprint for this class
                mask = register (getName);
        }

        /***********************************************************************
                
                Create with the given Layout

        ***********************************************************************/

        this (EventLayout layout)
        {
                setLayout (layout);
        }

        /***********************************************************************
                
                Return the fingerprint for this class

        ***********************************************************************/

        Mask getMask ()
        {
                return mask;
        }

        /***********************************************************************
                
                Return the name of this class

        ***********************************************************************/

        char[] getName ()
        {
                return this.classinfo.name;
        }
                
        /***********************************************************************
                
                Append an event to the output.
                 
        ***********************************************************************/

        void append (Event event)
        {
                auto layout = getLayout;
                layout.header  (event);
                layout.content (event);
                layout.footer  (event);
        }
}
