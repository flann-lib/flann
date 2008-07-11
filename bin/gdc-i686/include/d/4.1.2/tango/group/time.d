/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Dec 2007: Initial release

        author:         Kris

        Convenience module to import tango.time modules 

*******************************************************************************/

module tango.group.time;

pragma (msg, "Please post your usage of tango.group to this ticket: http://dsource.org/projects/tango/ticket/1013");

public import tango.time.Time;
public import tango.time.Clock;
public import tango.time.ISO8601;
public import tango.time.WallClock;
public import tango.time.StopWatch;
