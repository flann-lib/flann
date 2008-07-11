/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: May 2004
        
        author:         Kris
                        Anders F Bjorklund (Darwin patches)

*******************************************************************************/

module tango.util.log.Event;

version = UseEventFreeList;

private import  tango.time.Clock;

private import  tango.sys.Common;

private import  tango.core.Exception;

private import  tango.util.log.model.ILevel,
                tango.util.log.model.IHierarchy;


version (Win32)
{
        extern(Windows) int QueryPerformanceCounter(ulong *count);
        extern(Windows) int QueryPerformanceFrequency(ulong *frequency);
}


/*******************************************************************************

        Contains all information about a logging event, and is passed around
        between methods once it has been determined that the invoking logger
        is enabled for output.

        Note that Event instances are maintained in a freelist rather than
        being allocated each time, and they include a scratchpad area for
        EventLayout formatters to use.

*******************************************************************************/

public class Event : ILevel
{
        // primary event attributes
        private char[]          msg,
                                name;
        private Time            time;
        private Level           level;
        private IHierarchy      hierarchy;

        // timestamps
        private static Time beginTime;

        // scratch buffer for constructing output strings
        struct  Scratch
                {
                uint            length;
                char[256]       content;
                }
        package Scratch         scratch;


        // logging-level names
        package static char[][] LevelNames = 
        [
                "Trace ", "Info  ", "Warn  ", "Error ", "Fatal ", "None  "
        ];

        version (Win32)
        {
                private static double multiplier;
                private static ulong  timerStart;
        }

        /***********************************************************************
                
                Support for free-list

        ***********************************************************************/

        version (UseEventFreeList)
        {
                /***************************************************************

                        Instance variables for free-list support

                ***************************************************************/

                private Event           next;   
                private static Event    freelist;

                /***************************************************************

                        Allocate an Event from a list rather than 
                        creating a new one

                ***************************************************************/

                static final synchronized Event allocate ()
                {       
                        Event e;

                        if (freelist)
                           {
                           e = freelist;
                           freelist = e.next;
                           }
                        else
                           e = new Event ();                                
                        return e;
                }

                /***************************************************************

                        Return this Event to the free-list

                ***************************************************************/

                static final synchronized void deallocate (Event e)
                { 
                        e.next = freelist;
                        freelist = e;

                        version (EventReset)
                                 e.reset;
                }
        }

        /***********************************************************************
                
                Setup timing information for later use

        ***********************************************************************/

        package static void initialize ()
        {
                version (Posix)       
                {
                        beginTime = Clock.now;
                }

                version (Win32)
                {
                        ulong freq;

                        if (! QueryPerformanceFrequency (&freq))
                              throw new PlatformException ("high-resolution timer is not available");
                        
                        QueryPerformanceCounter (&timerStart);
                        multiplier = cast(double) TimeSpan.TicksPerSecond / freq;       
                        beginTime = Clock.now;

                }
        }

        /***********************************************************************
                
                Return time when the executable started

        ***********************************************************************/

        final static Time startedAt ()
        {
                return beginTime;
        }

        /***********************************************************************
                
                Return the current time

        ***********************************************************************/

        final static Time timer ()
        {
                version (Posix)       
                {
                        return Clock.now;
                }

                version (Win32)
                {
                        ulong now;

                        QueryPerformanceCounter (&now);
                        return beginTime + TimeSpan(cast(long)((now - timerStart) * multiplier));
                }
        }

        /***********************************************************************
                
                Set the various attributes of this event.

        ***********************************************************************/

        final void set (IHierarchy hierarchy, Level level, char[] msg, char[] name)
        {
                this.hierarchy = hierarchy;
                this.time = timer();
                this.level = level;
                this.name = name;
                this.msg = msg;
        }

        version (EventReset)
        {
                /***************************************************************

                        Reset this event

                ***************************************************************/

                final void reset ()
                {
                        time = 0;
                        msg = null;
                        name = null;
                        level = Level.None;
                }
        }

        /***********************************************************************
                
                Return the message attached to this event.

        ***********************************************************************/

        final override char[] toString ()
        {
                return msg;
        }

        /***********************************************************************
                
                Return the name of the logger which produced this event

        ***********************************************************************/

        final char[] getName ()
        {
                return name;
        }

        /***********************************************************************
                
                Return the scratch buffer for formatting. This is a thread
                safe place to format data within, without allocating any
                memory.

        ***********************************************************************/

        final char[] getContent ()
        {
                return scratch.content [0..scratch.length];
        }

        /***********************************************************************
                
                Return the logger level of this event.

        ***********************************************************************/

        final Level getLevel ()
        {
                return level;
        }

        /***********************************************************************
                
                Return the logger level name of this event.

        ***********************************************************************/

        final char[] getLevelName ()
        {
                return LevelNames[level];
        }

        /***********************************************************************
                
                Return the hierarchy where the event was produced from

        ***********************************************************************/

        final IHierarchy getHierarchy ()
        {
                return hierarchy;
        }

        /***********************************************************************
                
                Return the time this event was produced, relative to the 
                start of this executable

        ***********************************************************************/

        final TimeSpan getSpan ()
        {
                return time - beginTime;
        }

        /***********************************************************************
               
                Return the time this event was produced relative to Epoch

        ***********************************************************************/

        final Time getTime ()
        {
                return time;
        }

        /***********************************************************************

                Append some content to the scratch buffer. This is limited
                to the size of said buffer, and will not expand further.

        ***********************************************************************/

        final Event append (char[] x)
        {
                uint addition = x.length;
                uint newLength = scratch.length + x.length;

                if (newLength < scratch.content.length)
                   {
                   scratch.content [scratch.length..newLength] = x[0..addition];
                   scratch.length = newLength;
                   }
                return this;
        }
}
