/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.model.IChannel;

private import  tango.util.log.Logger;

private import  tango.net.cluster.model.IMessage,
                tango.net.cluster.model.IConsumer;    

/*******************************************************************************
        
        A channel represents something akin to a publish/subscribe topic, 
        or a radio station. These are used to segregate cluster operations
        into a set of groups, where each group is represented by a channel.
        Channel names are whatever you want then to be: use of dot notation 
        has proved useful in the past. See Client.createChannel

*******************************************************************************/

interface IChannel
{
        /***********************************************************************

                Return the Logger associated with this cluster

        ***********************************************************************/
        
        Logger log ();

        /***********************************************************************
        
                Return the name of this channel. This is the name provided
                when the channel was constructed.

        ***********************************************************************/

        char[] name ();

        /***********************************************************************

                Create a message listener on the given
                channel. The ChannelListener should be called whenever
                a corresponding cluster event happens. Note that the
                notification is expected to be on a seperate thread.

        ***********************************************************************/
        
        IConsumer createConsumer (ChannelListener notify);

        /***********************************************************************

                Create a bulletin listener on the given
                channel. The ChannelListener should be called whenever
                a corresponding cluster event happens. Note that the
                notification is expected to be on a seperate thread.

        ***********************************************************************/
        
        IConsumer createBulletinConsumer (ChannelListener notify);

        /***********************************************************************

                Place a cache entry into the cluster. If there is already
                a matching entry, it is replaced.

        ***********************************************************************/
        
        bool putCache (char[] key, IMessage message);

        /***********************************************************************

                Return a cluster cache entry, and optionally remove it
                from the cluster.

        ***********************************************************************/
        
        IMessage getCache (char[] key, bool remove, IMessage host=null);

        /***********************************************************************

                Ask the cache host to load an entry, via the provided
                message. Note that the message itself should contain all 
                pertinent information to load the entry (such as whatever
                key values are required). 
                
                The host executes the message in a manner akin to RPC, thus
                the message also needs to be registered with the host server

        ***********************************************************************/
        
        bool loadCache (char[] key, IMessage message);

        /***********************************************************************

                Place a new entry into the cluster queue. This may throw
                a ClusterFullException when there is no space left within
                the cluster queues.

        ***********************************************************************/
        
        IMessage putQueue (IMessage message);

        /***********************************************************************
                
                Query the cluster for queued entries on our corresponding 
                channel. Removes, and returns, the first matching entry 
                from the cluster.

        ***********************************************************************/
        
        IMessage getQueue (IMessage host = null);

        /***********************************************************************

                Scatter a message to all registered listeners. This is
                akin to multicast.

        ***********************************************************************/
        
        void broadcast (IMessage message = null);

        /***********************************************************************
                
                Execute the provided message on the cluster, and return the
                results internally

        ***********************************************************************/
        
        bool execute (IMessage message);
}


/*******************************************************************************

        An IEvent is passed as the argument to each ChannelListener callback

*******************************************************************************/

interface IEvent
{
        /***********************************************************************

                Return the channel used to initiate the listener

        ***********************************************************************/
        
        IChannel channel ();

        /***********************************************************************

                Return one or more messages associated with this event, or
                null if there is nothing available

        ***********************************************************************/
        
        IMessage get (IMessage host = null);

        /***********************************************************************

                Send a message back to the producer. This should support all
                the various event styles.                 

        ***********************************************************************/
        
        void reply (IChannel channel, IMessage message);

        /***********************************************************************

                Return an appropriate reply channel for the given message, 
                or return null if no reply is expected

        ***********************************************************************/
        
        IChannel replyChannel (IMessage message);

        /***********************************************************************

                Return the Logger associated with this cluster

        ***********************************************************************/
        
        Logger log ();
}

/*******************************************************************************

        Declares the contract for listeners within the cluster package.
        When creating a listener, you provide a callback delegate matching
        this signature. The delegate is invoked, on a seperate thread, each
        time a relevant event occurs.

*******************************************************************************/

alias void delegate (IEvent event) ChannelListener;


