/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.NetworkTask;

private import  tango.net.cluster.NetworkClient;
              
/*******************************************************************************

*******************************************************************************/

class NetworkTask : NetworkClient
{
        /***********************************************************************

                Construct a NetworkTask gateway on the provided QOS cluster
                for the specified channel. Each subsequent task operation
                will take place over the given channel.

        ***********************************************************************/
        
        this (ICluster cluster, char[] channel)
        {
                super (cluster, channel);
        }

        /***********************************************************************
        
                Add an ITask entry to the corresponding queue. This
                will throw a ClusterFullException if there is no space
                left in the clustered queue.

        ***********************************************************************/
        
        void execute (IMessage task)
        {
                channel.execute (task);
        }
}

