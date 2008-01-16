/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.model.IConsumer;

/*******************************************************************************

        Contract exposed by each cluster listener. This is what you are
        handed back upon successful construction of a listener.

*******************************************************************************/

interface IConsumer
{
        /***********************************************************************

                Cancel the listener. No more events will be dispatched to
                the associated ChannelListener.

        ***********************************************************************/
        
        void cancel();
}


