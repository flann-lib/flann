/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Nov 2007: Initial release

        author:         Kris

        Convenience module to import renamed text conversions 

*******************************************************************************/

module tango.group.convert;

pragma (msg, "Please post your usage of tango.group to this ticket: http://dsource.org/projects/tango/ticket/1013");

public import Utf = tango.text.convert.Utf;
public import Float = tango.text.convert.Float;
public import Integer = tango.text.convert.Integer;
public import TimeStamp = tango.text.convert.TimeStamp;

