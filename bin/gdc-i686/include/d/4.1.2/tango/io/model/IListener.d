/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module tango.io.model.IListener;


/******************************************************************************

******************************************************************************/

interface IListener
{
        /***********************************************************************

                Stop listening; this may be delayed until after the next
                valid read operation.

        ***********************************************************************/

        void cancel ();
}
