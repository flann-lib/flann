/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: May 2004
        
        author:         Kris

*******************************************************************************/

module tango.util.log.DateLayout;

private import  tango.text.Util;

private import  tango.time.Clock,
                tango.time.WallClock;

private import  tango.text.convert.Integer;

private import  tango.util.log.Event,
                tango.util.log.EventLayout;

/*******************************************************************************

        A layout with ISO-8601 date information prefixed to each message
       
*******************************************************************************/

public class DateLayout : EventLayout
{
        private bool localTime;

        private static char[6] spaces = ' ';

        /***********************************************************************
        
                Ctor with indicator for local vs UTC time. Default is 
                local time.
                        
        ***********************************************************************/

        this (bool localTime = true)
        {
                this.localTime = localTime;
        }

        /***********************************************************************
                
                Format message attributes into an output buffer and return
                the populated portion.

        ***********************************************************************/

        char[] header (Event event)
        {
                char[] level = event.getLevelName;
                
                // convert time to field values
                auto tm = event.getTime;
                auto dt = (localTime) ? WallClock.toDate(tm) : Clock.toDate(tm);
                                
                // format date according to ISO-8601 (lightweight formatter)
                char[20] tmp = void;
                return layout (event.scratch.content, "%0-%1-%2 %3:%4:%5,%6 %7%8 %9 - ", 
                               convert (tmp[0..4],   dt.date.year),
                               convert (tmp[4..6],   dt.date.month),
                               convert (tmp[6..8],   dt.date.day),
                               convert (tmp[8..10],  dt.time.hours),
                               convert (tmp[10..12], dt.time.minutes),
                               convert (tmp[12..14], dt.time.seconds),
                               convert (tmp[14..17], dt.time.millis),
                               spaces [0 .. $-level.length],
                               level,
                               event.getName
                              );
        }
        
        /**********************************************************************

                Convert an integer to a zero prefixed text representation

        **********************************************************************/

        private char[] convert (char[] tmp, int i)
        {
                return format (tmp, cast(long) i, Style.Unsigned, Flags.Zero);
        }
}
