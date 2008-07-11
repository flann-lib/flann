/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: May 2004
        
        author:         Kris

*******************************************************************************/

module tango.util.log.Appender;

public import  tango.core.Exception;

public import  tango.util.log.Event,
               tango.util.log.EventLayout;

/*******************************************************************************

        Base class for all Appenders. These objects are responsible for
        emitting messages sent to a particular logger. There may be more
        than one appender attached to any logger. The actual message is
        constructed by another class known as an EventLayout.
        
*******************************************************************************/

public class Appender
{
        typedef int Mask;

        private Appender        next;
        private EventLayout     layout;

        /***********************************************************************
                
                Return the mask used to identify this Appender. The mask
                is used to figure out whether an appender has already been 
                invoked for a particular logger.

        ***********************************************************************/

        abstract Mask getMask ();

        /***********************************************************************
                
                Return the name of this Appender.

        ***********************************************************************/

        abstract char[] getName ();
                
        /***********************************************************************
                
                Append a message to the output.

        ***********************************************************************/

        abstract void append (Event event);

        /***********************************************************************
              
              Create an Appender and default its layout to SimpleLayout.  

        ***********************************************************************/

        this ()
        {
                layout = new SimpleLayout;
        }

        /***********************************************************************
                
                Static method to return a mask for identifying the Appender.
                Each Appender class should have a unique fingerprint so that
                we can figure out which ones have been invoked for a given
                event. A bitmask is a simple an efficient way to do that.

        ***********************************************************************/

        protected Mask register (char[] tag)
        {
                static Mask mask = 1;
                static Mask[char[]] registry;

                Mask* p = tag in registry;
                if (p)
                    return *p;
                else
                   {
                   auto ret = mask;
                   registry [tag] = mask;

                   if (mask < 0)
                       throw new IllegalArgumentException ("too many unique registrations");

                   mask <<= 1;
                   return ret;
                   }
        }

        /***********************************************************************
                
                Set the current layout to be that of the argument.

        ***********************************************************************/

        void setLayout (EventLayout layout)
        {
                if (layout)
                    this.layout = layout;
        }

        /***********************************************************************
                
                Return the current Layout

        ***********************************************************************/

        EventLayout getLayout ()
        {
                return layout;
        }

        /***********************************************************************
                
                Attach another appender to this one

        ***********************************************************************/

        void setNext (Appender next)
        {
                this.next = next;
        }

        /***********************************************************************
                
                Return the next appender in the list

        ***********************************************************************/

        Appender getNext ()
        {
                return next;
        }

        /***********************************************************************
                
                Close this appender. This would be used for file, sockets, 
                and such like.

        ***********************************************************************/

        void close ()
        {
        }
}

