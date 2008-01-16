/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.NetworkClient;

private import  tango.time.Clock;

private import  tango.core.Exception;        

public  import  tango.net.cluster.model.ICluster;        

public  import  tango.net.cluster.NetworkMessage,        
                tango.net.cluster.NetworkRegistry;        

/*******************************************************************************

        The base class for all cluster clients (such as CacheInvalidator)
        which acts simply as a container for the operating IChannel and
        the configured ICluster. The former specifies something akin to
        a 'topic' in the pub/sub world, while the latter provides access
        to the underlying functional substrate (the QOS implementation).

*******************************************************************************/

class NetworkClient
{
        private IChannel channel_;
        private ICluster cluster_;

        public static NetworkMessage EmptyMessage;

        static this ()
        {
                NetworkRegistry.shared.enroll (EmptyMessage = new NetworkMessage);
        }

        /***********************************************************************

                Construct this client with the specified channel and cluster. 
                The former specifies something akin to a 'topic', whilst the 
                latter provides access to the underlying functional substrate 
                (the QOS implementation). A good way to think about channels
                is to map them directly to a class name. That is, since you
                send and recieve classes on a channel, you might utilize the 
                class name as the channel name (this.classinfo.name).
 
        ***********************************************************************/
        
        this (ICluster cluster, char[] channel)
        {
                assert (cluster);
                assert (channel.length);
                
                cluster_ = cluster;
                channel_ = cluster.createChannel (channel);
        }

        /***********************************************************************

                Return the channel we're tuned to

        ***********************************************************************/
        
        IChannel channel ()
        {
                return channel_;
        }

        /***********************************************************************

                Return the cluster specified during construction

        ***********************************************************************/
        
        ICluster cluster ()
        {
                return cluster_;
        }

        /***********************************************************************

                Return the current time

        ***********************************************************************/
        
        Time time ()
        {
                return Clock.now;
        }

        /***********************************************************************

                Return the Log instance

        ***********************************************************************/
        
        Logger log ()
        {
                return cluster_.log;
        }

        /***********************************************************************
        
                Create a channel with the specified name. A channel 
                represents something akin to a publush/subscribe topic, 
                or a radio station. These are used to segregate cluster 
                operations into a set of groups, where each group is 
                represented by a channel. Channel names are whatever you 
                want then to be; use of dot notation has proved useful 
                in the past. In fact, a good way to think about channels
                is to map them directly to a class name. That is, since you
                typically send and recieve classes on a channel, you might 
                utilize the class name as the channel (this.classinfo.name).

        ***********************************************************************/
        
        IChannel createChannel (char[] name)
        {
                return cluster_.createChannel (name);
        }
}

/*******************************************************************************

        This exception is thrown by the cluster subsystem when an attempt
        is made to place additional content into a full queue

*******************************************************************************/

class ClusterFullException : ClusterException
{
        this (char[] msg)
        {
                super (msg);
        }
}

/*******************************************************************************

        This exception is thrown by the cluster subsystem when an attempt
        is made to converse with a non-existant cluster, or one where all
        cluster-servers have died.

*******************************************************************************/

class ClusterEmptyException : ClusterException
{
        this (char[] msg)
        {
                super (msg);
        }
}

