/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.NetworkAlert;

private import tango.net.cluster.NetworkClient;

/*******************************************************************************

*******************************************************************************/

class NetworkAlert : NetworkClient
{
        /***********************************************************************

                Construct a NetworkAlert gateway on the provided QOS cluster
                for the specified channel. Each subsequent alert will take 
                place over the given channel.

        ***********************************************************************/
        
        this (ICluster cluster, char[] channel)
        {
                super (cluster, channel);
        }

        /***********************************************************************

        ***********************************************************************/
        
        IConsumer createConsumer (ChannelListener listener)
        {
                return channel.createBulletinConsumer (listener);
        }

        /***********************************************************************

        ***********************************************************************/
        
        void broadcast (IMessage payload = null)
        {
                channel.broadcast (payload);
        }
}

