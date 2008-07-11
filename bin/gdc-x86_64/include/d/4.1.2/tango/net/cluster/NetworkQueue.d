/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.NetworkQueue;

private import tango.net.cluster.NetworkClient;

/*******************************************************************************

        Exposes a gateway to the cluster queues, which collect ICached
        objects until they are removed. Because there is a finite limit
        to the quantity of entries stored, the put() method may throw a
        ClusterFullException if it cannot add a new entry.

*******************************************************************************/

class NetworkQueue : NetworkClient, IConsumer
{
        private IChannel        reply;
        private IConsumer       consumer;

        /***********************************************************************

                Construct a NetworkMessage gateway on the provided QOS cluster
                for the specified channel. Each subsequent queue operation
                will take place over the given channel.

                You can listen for cluster replies by providing an optional 
                ChannelListener. Outgoing messages will be tagged appropriately
                such that a consumer can respond using IEvent.reply

        ***********************************************************************/
        
        this (ICluster cluster, char[] channel, ChannelListener listener = null)
        {
                super (cluster, channel);

                if (listener)
                   {
                   reply = cluster.createChannel (channel ~ ".reply");
                   consumer = reply.createConsumer (listener);
                   }
        }

        /***********************************************************************
        
                Add an IMessage entry to the corresponding queue. This
                will throw a ClusterFullException if there is no space
                left in the clustered queue.

        ***********************************************************************/
        
        void put (IMessage message)
        {
                assert (message);

                if (reply)
                    message.reply = reply.name;

                channel.putQueue (message);
        }

        /***********************************************************************
                
                Query the cluster for queued entries on our corresponding 
                channel. Returns, and removes, a matching entry from the 
                cluster. This is the synchronous (polling) approach; you
                should use createConsumer() instead for asynchronous style
                notification instead.

        ***********************************************************************/
        
        IMessage get ()
        {
                return channel.getQueue;
        }

        /***********************************************************************

                Cancel the listener. No more events will be dispatched to
                the reply ChannelListener.

        ***********************************************************************/
        
        void cancel()
        {
                if (consumer)
                    consumer.cancel;
                consumer = null;
        }

        /***********************************************************************

                Create a listener for this channel. Listeners are invoked
                when new content is placed into a corresponding queue.

        ***********************************************************************/
        
        IConsumer createConsumer (ChannelListener listener)
        {
                return channel.createConsumer (listener);
        }
}
