/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Sep 2007: Initial release
        version:        Nov 2007: Added stream wrappers

        author:         Kris

*******************************************************************************/

module tango.text.convert.Format;

private import tango.text.convert.Layout;

/******************************************************************************

        Constructs a global utf8 instance of Layout

******************************************************************************/

public Layout!(char) Format;

static this()
{
        Format = new Layout!(char);
}

