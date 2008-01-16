/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.tina.Cluster;

private import  tango.math.Random;

private import  tango.core.Thread,
                tango.core.Runtime,
                tango.core.Exception;

private import  tango.util.log.Log,
                tango.util.log.Logger;

private import  tango.time.Clock;

private import  tango.io.Buffer,
                tango.io.GrowBuffer;

private import  tango.io.model.IConduit;

private import  tango.net.Socket,
                tango.net.SocketConduit,
                tango.net.SocketListener,
                tango.net.InternetAddress,
                tango.net.MulticastConduit;

private import  tango.net.cluster.NetworkClient;

public  import  tango.net.cluster.model.ICluster;

private import  tango.net.cluster.tina.RollCall,
                tango.net.cluster.tina.ProtocolReader,
                tango.net.cluster.tina.ProtocolWriter;

private import  Integer = tango.text.convert.Integer;

/*******************************************************************************
        
        QOS implementation for sockets. All cluster-client activity is 
        gated through here by the higher level classes; NetworkQueue &
        NetworkCache for example. You gain access to the cluster by 
        creating an instance of the QOS (quality of service) you desire
        and either mapping client classes onto it, or usign it directly.
        For example:
        ---
        import tango.net.cluster.tina.Cluster;

        auto cluster = new Cluster;
        cluster.join;

        auto channel = cluster.createChannel (...);
        channel.putQueue (...);
        channel.getQueue ();
        ---

        Please see the cluster clients for additional details. Currently
        these include CacheInvalidator, CacheInvalidatee, NetworkMessage, 
        NetworkTask, NetworkQueue, NetworkCache, NetworkCombo, plus the 
        Client base-class.

*******************************************************************************/

class Cluster : Broadcaster, ICluster
{  
        private FlexNodeSet     task,
                                queue;
        private FixedNodeSet    cache;
        private Logger          logger;

        /***********************************************************************

                Create a cluster instance with a default logger and Nagle
                caching disabled

        ***********************************************************************/
        
        this ()
        {
                this (Log.getLogger ("cluster.generic"), true);
        }

        /***********************************************************************

                Create a cluster instance with the provided logger. Option
                noDelay controls the settting of the Nagle algorithm on an
                active connection to a server, which should be disabled by 
                default (noDelay == true)

        ***********************************************************************/
        
        this (Logger log, bool noDelay = true)
        {
                assert (log);
                logger = log;

                task  = new FlexNodeSet  (log, noDelay);
                queue = new FlexNodeSet  (log, noDelay);
                cache = new FixedNodeSet (log, noDelay);
        }

        /***********************************************************************

                Join the cluster as a client, discovering servers. Client 
                applications should invoke this before making requests so
                that there are some servers to address. 

                If cache facilities will be used, then the join(cacheHosts) 
                variation should be used instead

        ***********************************************************************/
       
        final Cluster join ()
        {
                // listen for cluster servers
                auto channel = createChannel ("cluster.server.advertise");
                channel.createBulletinConsumer (&notify);

                // ask who's currently running
                channel.broadcast (new RollCall);
                logger.trace ("discovering cluster nodes");

                // wait for enabled servers to respond ...
                Thread.sleep (0.250);
                return this;
        }
         
        /***********************************************************************

                Join the cluster as a client, discovering servers. Client 
                applications should invoke this before making requests so
                that there are some servers to address.

                If cache facilities will be used, use this method to set
                the group of valid cache hosts. Each cache host should be
                described as an array of machine-name and port pairs e.g.
                ---
                ["lucy:1234", "daisy:3343", "daisy:3344"]
                ---

                This sets up a fixed set of cache hosts, which should be
                identical for all cache clients. Cache hosts not included
                in this list will be ignored when they come online.

        ***********************************************************************/
        
        final Cluster join (char[][] cacheHosts)
        {
                foreach (addr; cacheHosts)
                         cache.addNode (new Node (log, addr, "cache"));
                return join;
        }

        /***********************************************************************

                Return the logger instance provided during construction.
                
        ***********************************************************************/
        
        final Logger log ()
        {
                return logger;
        }

        /***********************************************************************

                Create a channel instance. Our channel implementation 
                includes a number of cached IO helpers (ProtocolWriter
                and so on) which simplifies and speeds up execution.

        ***********************************************************************/
        
        final IChannel createChannel (char[] channel)
        {
                return new Channel (this, channel);
        }

        /***********************************************************************

                ChannelListener method for listening to RollCall responses. 
                These are sent out by cluster servers both when they get a 
                RollCall request, and when they heartbeat.

        ***********************************************************************/

        private void notify (IEvent event)
        {
                scope rollcall = new RollCall;
                event.get (rollcall);

                switch (rollcall.type)
                       {
                       default:
                            break;

                       case RollCall.Task:
                            task.enable (rollcall.addr, "task");
                            break;

                       case RollCall.Cache:
                            cache.enable (rollcall.addr);
                            break;

                       case RollCall.Queue:
                            queue.enable (rollcall.addr, "queue");
                            break;
                       }
        }
}


/*******************************************************************************

        Basic multicast support across the cluster. Multicast is used 
        for broadcasting messages to all nodes in the cluster. We use
        it for cache-invalidation, heartbeat, rollcall and notification
        of queue activity
                        
*******************************************************************************/

private class Broadcaster
{  
        private static InternetAddress[char[]]  groups;
        private Buffer                          mBuffer;
        private ProtocolWriter                  mWriter;
        private MulticastConduit                mSocket;

        private int                             groupPort = 3333;
        private int                             groupPrefix = 225;

        /***********************************************************************

                Setup a Cluster instance. Currently the buffer & writer
                are shared for all bulletin serialization; this should
                probably change at some point such that we can support 
                multiple threads broadcasting concurrently to different 
                output ports.

        ***********************************************************************/
        
        this ()
        {
                mBuffer = new Buffer (1024 * 4);
                mSocket = new MulticastConduit;
                mWriter = new ProtocolWriter (mBuffer);
        }

        /***********************************************************************

                Setup the multicast options. Port is used as the sole 
                address port for multicast usage, prefix is prepended 
                to each fabricated multicast address (should be a valid 
                class-D prefix), and ttl is the number of hops 

        ***********************************************************************/
        
        final MulticastConduit conduit ()
        {
                return mSocket;
        }

        /***********************************************************************

                Setup the multicast options. Port is used as the sole 
                address port for multicast usage & prefix is prepended 
                to each fabricated multicast address (should be a valid 
                class-D prefix: 225 through 239 inclusive)

        ***********************************************************************/
        
        final void multicast (int port, int prefix=225)
        {
                groupPort = port;
                groupPrefix = prefix;
        }

        /***********************************************************************

                Broadcast a message on the specified channel. This uses
                IP/Multicast to scatter the payload to all registered
                listeners (on the same multicast group). Note that the
                maximum message size is limited to that of an Ethernet 
                data frame, minus the IP/UDP header size (1472 bytes).

                Also note that we are synchronized to avoid contention
                on the otherwise shared output buffer.

        ***********************************************************************/
        
        final synchronized void broadcast (char[] channel, IMessage message=null)
        {
                // clear buffer and serialize content
                mWriter.put (ProtocolWriter.Command.OK, channel, null, message);

                // Ethernet data-frame size minus the 28 byte UDP/IP header:
                if (mBuffer.position > 1472)
                    throw new ClusterException ("message is too large to broadcast");

                // send it to the appropriate multicast group
                mSocket.write (mBuffer.slice, getGroup (channel));
        }

        /***********************************************************************

                Return an internet address representing the multicast
                group for the specified channel. We use three of the
                four address segments to represent the channel itself
                (via a hash on the channel name), and set the primary
                segment to be that of the broadcast prefix (above).

        ***********************************************************************/
        
        final synchronized InternetAddress getGroup (char[] channel)
        {
                auto p = channel in groups;
                if (p)
                    return *p;

                // construct a group address from the prefix & channel-hash,
                // where the hash is folded down to 24 bits
                uint hash = jhash (channel.ptr, channel.length);
                hash = (hash >> 24) ^ (hash & 0x00ffffff);
                  
                auto address = Integer.toString (groupPrefix) ~ "." ~
                               Integer.toString ((hash >> 16) & 0xff) ~ "." ~
                               Integer.toString ((hash >> 8) & 0xff) ~ "." ~
                               Integer.toString (hash & 0xff);

                // insert InternetAddress into hashmap
                auto group = new InternetAddress (address, groupPort);
                groups [channel] = group;
                return group;              
        }
}


/*******************************************************************************
        
        A channel represents something akin to a publish/subscribe topic, 
        or a radio station. These are used to segregate cluster operations
        into a set of groups, where each group is represented by a channel.
        Channel names are whatever you want then to be: use of dot notation 
        has proved useful in the past. 
        
        Channel maintain internal state in order to avoid heap activity. So
        they should not be shared across threads without appropriate synchs 
        in place. One remedy is create another channel instance

*******************************************************************************/

private class Channel : IChannel
{
        private char[]                  name_;
        private Buffer                  buffer;
        private ProtocolReader          reader;
        private ProtocolWriter          writer;
        private Cluster                 cluster_;

        /***********************************************************************
        
                Construct a channel with the specified name. We cache
                a number of session-related constructs here also, in
                order to eliminate runtime overhead

        ***********************************************************************/

        this (Cluster cluster, char[] name)
        in {
           assert (cluster);
           assert (name.length);
           }
        body
        {       
                name_ = name;
                cluster_ = cluster;

                // this buffer will grow as required to house larger messages
                buffer = new GrowBuffer (1024 * 2);
                writer = new ProtocolWriter (buffer);

                // make the reader slice directly from the buffer content
                reader = new ProtocolReader (buffer);
        }

        /***********************************************************************
        
                Return the name of this channel. This is the name provided
                when the channel was constructed.

        ***********************************************************************/

        final char[] name ()
        {
                return name_;
        }

        /***********************************************************************
        
                Return the assigned cluster

        ***********************************************************************/

        final Cluster cluster ()
        {
                return cluster_;
        }

        /***********************************************************************
        
                Return the assigned logger

        ***********************************************************************/

        final Logger log ()
        {
                return cluster_.log;
        }

        /***********************************************************************
       
                Output this channel via the provided IWriter

        ***********************************************************************/

        final void write (IWriter writer)
        {
                writer.put (name_);
        }

        /***********************************************************************
        
                Input this channel via the provided IReader

        ***********************************************************************/

        final void read (IReader reader)
        {
                reader.get (name_);
        }

        /***********************************************************************

                deserialize a message into a provided host, or via
                the registered instance of the incoming message
                        
        ***********************************************************************/

        final IMessage thaw (IMessage host = null)
        {
                return reader.thaw (host);
        }

        /***********************************************************************

                Create a listener of the specified type. Listeners are 
                run within their own thread, since they spend the vast 
                majority of their time blocked on a Socket read. Would
                be good to support multiplexed reading instead, such 
                that a thread pool could be applied instead.
                 
        ***********************************************************************/
        
        final IConsumer createConsumer (ChannelListener notify)
        {
                cluster_.log.trace ("creating message consumer for '" ~ name_ ~ "'");
                return new MessageConsumer (this, notify);
        }

        /***********************************************************************

                Create a listener of the specified type. Listeners are 
                run within their own thread, since they spend the vast 
                majority of their time blocked on a Socket read. Would
                be good to support multiplexed reading instead, such 
                that a thread pool could be applied instead.
                 
        ***********************************************************************/
        
        final IConsumer createBulletinConsumer (ChannelListener notify)
        {
                cluster_.log.trace ("creating bulletin consumer for '" ~ name_ ~ "'");
                return new BulletinConsumer (this, notify);
        }

        /***********************************************************************

                Return a entry from the network cache, and optionally
                remove it. This is a synchronous operation as opposed
                to the asynchronous nature of an invalidate broadcast.

        ***********************************************************************/
        
        final IMessage getCache (char[] key, bool remove, IMessage host = null)
        {
                void send (IConduit conduit)
                {
                        buffer.setConduit (conduit);
                        writer.put (remove ? ProtocolWriter.Command.Remove : 
                                    ProtocolWriter.Command.Copy, name_, key).flush;
                }

                if (cluster_.cache.request (&send, reader, key))
                    return reader.thaw (host);
                return null;
        }

        /***********************************************************************

                Place an entry into the network cache, replacing the
                entry with the identical key. Where message.time is
                set, it will be used to test for newer cache entries
                than the one being sent i.e. if someone else placed
                a newer entry into the cache, that one will remain.
                
                Note that this may cause the oldest entry in the cache 
                to be displaced if the cache is already full.

        ***********************************************************************/
        
        final bool putCache (char[] key, IMessage message)
        {
                void send (IConduit conduit)
                {
                        buffer.setConduit (conduit);
                        writer.put (ProtocolWriter.Command.Add, name_, key, message).flush;
                }

                // return false if the cache server said there's 
                // already something newer 
                if (cluster_.cache.request (&send, reader, key))
                    return false;
                return true;
        }

        /***********************************************************************
                
                Load a network cache entry remotely. This sends the given
                IMessage over a network to the cache host, where it will
                be executed locally. The benefit of doing so it that the
                host may deny access to the cache entry for the duration
                of the load operation. This, in turn, provides a mechanism 
                for gating/synchronizing multiple network clients  over a 
                given cache entry; quite handy for those entries that are 
                relatively expensive to construct or access. 

        ***********************************************************************/
        
        final bool loadCache (char[] key, IMessage message)
        {                       
                void send (IConduit conduit)
                {
                        buffer.setConduit (conduit);
                        writer.put (ProtocolWriter.Command.Load, name_, key, message).flush;
                }

                return cluster_.cache.request (&send, reader, key);
        }

        /***********************************************************************
                
                Query the cluster for queued entries on the corresponding 
                channel. Returns, and removes, the first matching entry 
                from the cluster. Note that this sweeps the cluster for
                matching entries, and is synchronous in nature. The more
                common approach is to setup a queue listener, which will
                grab and dispatch queue entries asynchronously.

        ***********************************************************************/
        
        final IMessage getQueue (IMessage host = null)
        {
                if (scanQueue)
                    return reader.thaw (host);
                return null;
        }

        /***********************************************************************
                
                Query the cluster for queued entries on the corresponding 
                channel. Returns, and removes, the first matching entry 
                from the cluster. Note that this sweeps the cluster for
                matching entries, and is synchronous in nature. The more
                common approach is to setup a queue listener, which will
                grab and dispatch queue entries asynchronously.

        ***********************************************************************/
        
        private bool scanQueue ()
        {
                void send (IConduit conduit)
                {
                        buffer.setConduit (conduit);
                        writer.put (ProtocolWriter.Command.RemoveQueue, name_).flush;
                }

                bool scan (Node node)
                {       
                        bool message;
                        node.request (&send, reader, message);
                        return message;
                }

                // make a pass over each Node, looking for channel entries
                return cluster_.queue.scan (&scan);
        }

        /***********************************************************************

                Add an entry to the specified network queue. May throw a
                QueueFullException if there's no room available.

        ***********************************************************************/
        
        final IMessage putQueue (IMessage message)
        {
                void send (IConduit conduit)
                {
                        buffer.setConduit (conduit);
                        writer.put (ProtocolWriter.Command.AddQueue, name_, null, message).flush;
                }

                cluster_.queue.request (&send, reader);
                return message;
        }

        /***********************************************************************
                
               Send a remote call request to a server, and place the result
               back into the provided message

        ***********************************************************************/
        
        final bool execute (IMessage message)
        {
                void send (IConduit conduit)
                {
                        buffer.setConduit (conduit);
                        writer.put (ProtocolWriter.Command.Call, name_, null, message).flush;
                }

                if (cluster_.task.request (&send, reader))
                   {
                   // place result back into the provided message
                   reader.thaw (message);
                   return true;
                   }
                return false;
        }

        /***********************************************************************

                Broadcast a message on the specified channel. This uses
                IP/Multicast to scatter the message to all registered
                listeners (on the same multicast group). Note that the
                maximum message size is limited to that of an Ethernet 
                data frame, minus the IP/UDP header size (1472 bytes).

        ***********************************************************************/
        
        final void broadcast (IMessage message = null)
        {
                   cluster_.broadcast (name_, message);
        }
}


/*******************************************************************************         

        A listener for multicast channel traffic. These are currently used 
        for cache coherency, queue publishing, and node discovery activity; 
        though could be used for direct messaging also.

        Be careful when using the retained channel, since it is shared with
        the calling thread. Thus a race condition could arise between the
        client and this thread, were both to use the channel for transfers 
        at the same instant. Note that MessageConsumer makes a copy of the
        channel for this purpose

*******************************************************************************/

private class BulletinConsumer : SocketListener, IConsumer, IEvent 
{
        private bool                    hasMore;        // incoming message?
        private Buffer                  buffer;         // input buffer
        private ProtocolReader          reader;         // input decoder
        private Channel                 channel_;       // associated channel
        private Cluster                 cluster;        // associated cluster
        private MulticastConduit        consumer;       // broadcast listener
        private ChannelListener         listener;       // user-level callback

        /***********************************************************************

                Construct a multicast consumer for the specified event. The
                event handler will be invoked whenever a message arrives for
                the associated channel.

        ***********************************************************************/
        
        this (Channel channel, ChannelListener listener)
        {
                this.channel_ = channel;
                this.listener = listener;
                this.cluster  = channel.cluster;

                // buffer doesn't need to be larger than Ethernet data-frame
                buffer = new Buffer (1500);

                // make the reader slice directly from the buffer content
                reader = new ProtocolReader (buffer);

                // configure a listener socket
                consumer = new MulticastConduit (cluster.getGroup (channel_.name), true);
                consumer.join;

                super (consumer, buffer);

                // fire up this listener
                super.execute;
        }

        /***********************************************************************

                Notification callback invoked when we receive a multicast
                packet. Note that we check the packet channel-name against
                the one we're consuming, to check for cases where the group
                address had a hash collision.

        ***********************************************************************/
        
        override void notify (IBuffer buffer)
        {
                ProtocolWriter.Command  cmd;
                char[]                  channel;
                char[]                  element;
                
                // read the incoming header, along with the object guid
                // where available
                hasMore = reader.getHeader (cmd, channel, element);

                // check it's really for us first (might be a hash collision)
                if (channel == this.channel_.name)
                    invoke (this);
        }

        /***********************************************************************

        ***********************************************************************/

        IMessage get (IMessage host = null)
        {
                if (hasMore)
                    return reader.thaw (host);

                throw new ClusterException ("attempting to thaw a non-existant message");
        }

        /***********************************************************************
        
                Return the assigned logger

        ***********************************************************************/

        final Logger log ()
        {
                return cluster.log;
        }

        /***********************************************************************

                Handle error conditions from the listener thread.

        ***********************************************************************/

        override void exception (char [] msg)
        {
                cluster.log.error ("BulletinConsumer: "~msg);
        }

        /***********************************************************************

                Overridable mean of notifying the client code.
                 
        ***********************************************************************/
        
        protected void invoke (IEvent event)
        {
                listener (event);
        }

        /***********************************************************************

                Return the cluster instance we're associated with.

        ***********************************************************************/
        
        final Channel channel ()
        {
                return channel_;
        }

        /***********************************************************************

                Temporarily halt listening. This can be used to ignore
                multicast messages while, for example, the consumer is
                busy doing other things.

        ***********************************************************************/

        final void pauseGroup ()
        {
                consumer.leave;
        }

        /***********************************************************************

                Resume listening, post-pause.

        ***********************************************************************/

        final void resumeGroup ()
        {
                consumer.join;
        }

        /***********************************************************************

                Cancel this consumer. The listener is effectively disabled
                from this point forward. The listener thread does not halt
                at this point, but waits until the socket-read returns. 
                Note that the D Interface implementation requires us to 
                "reimplement and dispatch" trivial things like this ~ it's
                a pain in the neck to maintain.

        ***********************************************************************/
        
        final void cancel ()
        {
                super.cancel;
        }

        /***********************************************************************

                Send a message back to the producer       

        ***********************************************************************/
        
        void reply (IChannel channel, IMessage message)
        {
                assert (channel);
                assert (message);

                channel.broadcast (message);
        }


        /***********************************************************************

                Return an appropriate reply channel for the given message, 
                or return null if no reply is expected

        ***********************************************************************/
        
        IChannel replyChannel (IMessage message)
        {
                if (message.reply.length)
                    return cluster.createChannel (message.reply);
                return null;
        }
}


/*******************************************************************************
        
        A listener for queue events. These events are produced by the 
        queue host on a periodic bases when it has available entries.
        We listen for them (rather than constantly scanning) and then
        begin a sweep to process as many as we can. Note that we will
        be in competition with other nodes to process these entries.

        Also note that we create a copy of the channel in use, so that
        race-conditions with the requesting client are avoided.

*******************************************************************************/

private class MessageConsumer : BulletinConsumer
{
        /***********************************************************************

                Construct a multicast consumer for the specified event

        ***********************************************************************/
        
        this (Channel channel, ChannelListener listener)
        {
                super (channel, listener);

                // create private channel instance to use in our thread
                this.channel_ = new Channel (channel.cluster, channel.name);
        }

        /***********************************************************************

                Handle error conditions from the listener thread.

        ***********************************************************************/

        override void exception (char [] msg)
        {
                cluster.log.error ("MessageConsumer: "~msg);
        }

        /***********************************************************************

                Overrides the default processing to sweep the cluster for 
                queued entries. Each server node is queried until one is
                found that contains a message. Note that it is possible 
                to set things up where we are told exactly which node to
                go to; however given that we won't be listening whilst
                scanning, and that there's likely to be a group of new
                entries in the cluster, it's just as effective to scan.
                This will be far from ideal for all environments, so we 
                should make the strategy pluggable instead.                 

                Note also that the content is retrieved via a duplicate
                channel to avoid potential race-conditions on the original

        ***********************************************************************/

        override IMessage get (IMessage host = null)
        {
                if (channel.scanQueue)
                    return channel.thaw (host);
                return null;
        }

        /***********************************************************************

                Send a message back to the producer       

        ***********************************************************************/
        
        override void reply (IChannel channel, IMessage message)
        {
                assert (channel);
                assert (message);

                channel.putQueue (message);
        }

        /***********************************************************************

                Override the default notification handler in order to
                disable multicast reciepts while the application does
                what it needs to
                
        ***********************************************************************/
       
        override protected void invoke (IEvent event)
        {                
                // temporarily pause listening while processing
                pauseGroup;
                try {
                    listener (event);
                    } finally resumeGroup;
        }
}


/*******************************************************************************
        
        An abstraction of a socket connection. Used internally by the 
        socket-based Cluster. 

*******************************************************************************/

private class Connection
{
        abstract bool reset();

        abstract void done (Time time);

        abstract SocketConduit conduit ();
}


/*******************************************************************************
        
        A pool of socket connections for accessing cluster nodes. Note 
        that the entries will timeout after a period of inactivity, and
        will subsequently cause a connected host to drop the supporting
        session.

*******************************************************************************/

private class ConnectionPool
{ 
        private Logger          log;
        private int             count;
        private bool            noDelay;
        private InternetAddress address;
        private PoolConnection  freelist;
        private TimeSpan        timeout = TimeSpan.seconds(60);

        /***********************************************************************
        
                Utility class to provide the basic connection facilities
                provided by the connection pool.

        ***********************************************************************/

        static class PoolConnection : Connection
        {
                Time            time;
                PoolConnection  next;   
                ConnectionPool  parent;   
                SocketConduit   conduit_;

                /***************************************************************
                
                        Construct a new connection and set its parent

                ***************************************************************/
        
                this (ConnectionPool pool)
                {
                        parent = pool;
                        reset;
                }
                  
                /***************************************************************

                        Create a new socket and connect it to the specified 
                        server. This will cause a dedicated thread to start 
                        on the server. Said thread will quit when an error
                        occurs.

                ***************************************************************/
        
                final bool reset ()
                {
                        try {
                            conduit_ = new SocketConduit;

                            // apply Nagle settings
                            conduit.socket.setNoDelay (parent.noDelay);

                            // set a 500ms timeout for read operations
                            conduit_.setTimeout (TimeSpan.millis(500));

                            // open a connection to this server
                            // parent.log.trace ("connecting to server");
                            conduit_.connect (parent.address);
                            return true;

                            } catch (Object o)
                                    {
                                    if (! Runtime.isHalting)
                                          parent.log.warn ("server is unavailable :: "~o.toString);
                                    }
                        return false;
                }
                  
                /***************************************************************

                        Return the socket belonging to this connection

                ***************************************************************/
        
                final SocketConduit conduit ()
                {
                        return conduit_;
                }
                  
                /***************************************************************

                        Close the socket. This will cause any host session
                        to be terminated.

                ***************************************************************/
        
                final void close ()
                {
                        conduit_.detach;
                }

                /***************************************************************

                        Return this connection to the free-list. Note that
                        we have to synchronize on the parent-pool itself.

                ***************************************************************/

                final void done (Time time)
                {
                        synchronized (parent)
                                     {
                                     next = parent.freelist;
                                     parent.freelist = this;
                                     this.time = time;
                                     }
                }
        }


        /***********************************************************************

                Create a connection-pool for the specified address.

        ***********************************************************************/

        this (InternetAddress address, Logger log, bool noDelay)
        {      
                this.log = log;
                this.address = address;
                this.noDelay = noDelay;
        }

        /***********************************************************************

                Allocate a Connection from a list rather than creating a 
                new one. Reap old entries as we go.

        ***********************************************************************/

        final synchronized Connection borrow (Time time)
        {  
                if (freelist)
                    do {
                       auto c = freelist;

                       freelist = c.next;
                       if (freelist && (time - c.time > timeout))
                           c.close;
                       else
                          return c;
                       } while (true);

                return new PoolConnection (this);
        }

        /***********************************************************************

                Close this pool and drop all existing connections.

        ***********************************************************************/

        final synchronized void close ()
        {       
                auto c = freelist;
                freelist = null;
                while (c)
                      {
                      c.close;
                      c = c.next;
                      }
        }
}


/*******************************************************************************
        
        Class to represent a cluster node. Each node supports both cache
        and queue functionality. Note that the set of available nodes is
        configured at startup, simplifying the discovery process in some
        significant ways, and causing less thrashing of cache-keys.

*******************************************************************************/

private class Node
{ 
        private Logger                  log;
        private char[]                  name,
                                        addr;
        private ConnectionPool          pool;
        private bool                    enabled;

        alias void delegate (IConduit conduit) Requestor;

        /***********************************************************************

                Construct a node with the provided name. This name should
                be the network name of the hosting device.

        ***********************************************************************/
        
        this (Logger log, char[] addr, char[] name)
        {
                this.log = log;
                this.addr = addr;
                this.name = name ~ ':' ~ addr;
        }

        /***********************************************************************

                Add a cache/queue reference for the remote node
                 
        ***********************************************************************/

        final void setPool (InternetAddress address, bool noDelay)
        {      
                this.pool = new ConnectionPool (address, log, noDelay);
        }

        /***********************************************************************

                Return the name of this node

        ***********************************************************************/
        
        override char[] toString ()
        {
                return name;
        }

        /***********************************************************************

                Return the network address of this node

        ***********************************************************************/
        
        final char[] address ()
        {
                return addr;
        }

        /***********************************************************************

                Remove this Node from the cluster. The node is disabled
                until it is seen to recover.

        ***********************************************************************/

        final void fail ()
        {       
                setEnabled (false);
                pool.close;    
        }

        /***********************************************************************

                Get the current state of this node

        ***********************************************************************/

        final bool isEnabled ()
        {      
                volatile  
                       return enabled;    
        }

        /***********************************************************************

                Set the enabled state of this node

        ***********************************************************************/

        final void setEnabled (bool enabled)
        {      
                if (enabled)
                    log.trace ("enabling "~name);
                else
                   log.trace ("disabling "~name);

                volatile  
                       this.enabled = enabled;    
        }

        /***********************************************************************

                request data; fail this Node if we can't connect. Note
                that we make several attempts to connect before writing
                the node off as a failure. We use a delegate to perform 
                the request output since it may be invoked on more than
                one iteration, where the current attempt fails.

                We return true if the cluster node responds, and false
                otherwise. Exceptions are thrown if they occured on the 
                server. Parameter 'message' is set true if a message is
                available from the server response
                
        ***********************************************************************/
        
        final bool request (Requestor dg, ProtocolReader reader, out bool message)
        {       
                ProtocolWriter.Command  cmd;
                Time                    time;
                char[]                  channel;
                char[]                  element;

                // it's possible that the pool may have failed between 
                // the point of selecting it, and the invocation itself
                if (pool is null)
                    return false;

                // get a connection to the server
                auto connect = pool.borrow (time = Clock.now);

                // talk to the server (try a few times if necessary)
                for (int attempts=3; attempts--;)
                     try {
                         // attach connection to writer and send request
                         dg (connect.conduit); 

                         // attach connection to reader
                         reader.buffer.setConduit (connect.conduit);
        
                         // load the returned object. Don't retry on
                         // failed reads, since the server is either
                         // really really busy, or near death. We must
                         // assume it is offline until it tells us 
                         // otherwise (via a heartbeat)
                         attempts = 0;
                         message = reader.getHeader (cmd, channel, element);

                         // return borrowed connection
                         connect.done (time);

                         } catch (RegistryException x)
                                 {
                                 connect.done (time);
                                 throw x;
                                 }
                           catch (IOException x)
                                 {
                                 log.trace ("IOException on server request :: "~x.toString);

                                 // attempt to reconnect?
                                 if (attempts is 0 || !connect.reset)
                                    {
                                    // that server is offline
                                    fail;
  
                                    // state that we failed
                                    return false;
                                    }
                                }
                    
                // is message an exception?
                if (cmd !is ProtocolWriter.Command.OK)                       
                   {
                   // is node full?
                   if (cmd is ProtocolWriter.Command.Full)                       
                       throw new ClusterFullException (channel);

                   // did node barf?
                   if (cmd is ProtocolWriter.Command.Exception)                       
                       throw new ClusterException (channel);
                        
                   // bogus response
                   throw new ClusterException ("invalid response from cluster server");
                   }

                // ok, our server responded
                return true;
        }
}


/*******************************************************************************
        
        Models a generic set of cluster nodes. This is intended to be
        thread-safe, with no locking on a lookup operation

*******************************************************************************/

private class NodeSet
{ 
        private Node[char[]]    map;
        private Logger          log;
        private Set             set;
        private bool            noDelay;

        /***********************************************************************

        ***********************************************************************/
        
        this (Logger log, bool noDelay)
        {
                this.log = log;
                this.set = new Set;
                this.noDelay = noDelay;
        }

        /***********************************************************************

        ***********************************************************************/
        
        final Logger logger ()
        {
                return log;
        }

        /***********************************************************************

                Add a node to the list of servers

        ***********************************************************************/
        
        synchronized final Node addNode (Node node)
        {
                auto addr = node.address;
                if (addr in map)
                    throw new ClusterException ("Attempt to add cluster node '"~addr~"' more than once");

                map[addr] = node;

                // note that this creates a new Set instance. We do this
                // so that selectNode() can avoid synchronization
                set = set.add (node);
                return node;
        }

        /***********************************************************************

                Select a cluster server based on a starting index. If the
                selected server is not currently enabled, we just try the
                next one. This behaviour should be consistent across each
                cluster client.

        ***********************************************************************/
        
        final Node selectNode (uint index)
        {
                auto hosts = set.nodes;
                uint count = hosts.length;

                if (count)
                   {
                   index %= count;

                   while (count--)
                         {
                         auto node = hosts [index];
                         if (node.isEnabled)
                             return node;
        
                         if (++index >= hosts.length)
                             index = 0;
                         }
                   }
                throw new ClusterEmptyException ("No appropriate cluster nodes are available"); 
        }

        /***********************************************************************

                Host class for the set of nodes. We utilize this to enable
                atomic read/write where it would not be otherwise possible
                -- D arrays are organized as ptr+length pairs and are thus
                inherently non-atomic for assignment purposes

        ***********************************************************************/
        
        private static class Set
        {
                Node[]  nodes,
                        random;

                final Set add (Node node)
                {
                        auto s = new Set;
                        s.nodes = nodes ~ node;
                        s.randomize;
                        return s;
                }
        
                private final void randomize ()
                {
                        // copy the node list
                        random = nodes.dup;

                        // muddle up the duplicate list. This randomized list
                        // is used when scanning the cluster for queued entries
                        foreach (i, n; random)
                                {
                                auto j = Random.shared.next (random.length);
                                auto tmp = random[i];
                                random[i] = random[j];
                                random[j] = tmp;
                                }
                }
        }
}

 
/*******************************************************************************
        
        Models a fixed set of cluster nodes. Used for Cache

*******************************************************************************/

private class FixedNodeSet : NodeSet
{ 
        /***********************************************************************

        ***********************************************************************/
        
        this (Logger log, bool noDelay)
        {
                super (log, noDelay);
        }

        /***********************************************************************

        ***********************************************************************/
        
        final synchronized void enable (char[] addr)
        {
                auto p = addr in map;
                if (p)
                   {
                   auto node = *p;
                   if (! node.isEnabled)
                      {
                      node.setPool (new InternetAddress(addr), noDelay);
                      node.setEnabled (true);
                      }
                   }
                else
                   // don't throw when no cache hosts have been configured at all
                   if (set.nodes.length)
                       throw new ClusterException ("Attempt to enable unregistered cache node '"~addr~"'");
        }

        /***********************************************************************

                Select a cluster server based on the specified key. If the
                selected server is not currently enabled, we just try the
                next one. This behaviour should be consistent across each
                cluster client.

        ***********************************************************************/
        
        final bool request (Node.Requestor dg, ProtocolReader reader, char[] key)
        {
                Node node;
                bool message;

                do {
                   node = selectNode (jhash (key.ptr, key.length));
                   } while (! node.request (dg, reader, message));

                return message;
        }
}

 
/*******************************************************************************
        
        Models a flexible set of cluster nodes. Used for queue and task

*******************************************************************************/

private class FlexNodeSet : NodeSet
{ 
        private uint rollover;

        /***********************************************************************

        ***********************************************************************/
        
        this (Logger log, bool noDelay)
        {
                super (log, noDelay);
        }

        /***********************************************************************

        ***********************************************************************/
        
        final synchronized void enable (char[] addr, char[] name)
        {
                auto p = addr in map;
                auto node = p ? *p : addNode (new Node (log, addr, name));

                if (! node.isEnabled)
                   {
                   node.setPool (new InternetAddress(addr), noDelay);
                   node.setEnabled (true);
                   }
        }

        /***********************************************************************

                Select a cluster server based on the specified key. If the
                selected server is not currently enabled, we just try the
                next one. This behaviour should be consistent across each
                cluster client.

        ***********************************************************************/
        
        final bool request (Node.Requestor dg, ProtocolReader reader)
        {
                Node node;
                bool message;

                do {
                   node = selectNode (++rollover);
                   } while (! node.request (dg, reader, message));

                return message;
        }

        /***********************************************************************

                Sweep the cluster servers. Returns true if the delegate
                returns true, false otherwise. The sweep is halted when
                the delegate returns true. Note that this scans nodes in
                a randomized pattern, which should tend to avoid 'bursty'
                activity by a set of clients upon any one cluster server.

        ***********************************************************************/
        
        final bool scan (bool delegate(Node) dg)
        {
                auto hosts = set.random;
                auto index = hosts.length;
                
                while (index)
                      {
                      // lookup the randomized set of server nodes
                      auto node = hosts [--index];

                      // callback on each enabled node
                      if (node.isEnabled)
                          if (dg (node))
                              return true;
                      }
                return false;
        }
}

 
/******************************************************************************

        The Bob Jenkins lookup2 algorithm. This should be relocated 
        to somewhere common

******************************************************************************/

private static uint jhash (void* k, uint len, uint init = 0)
{
        uint a = 0x9e3779b9,
             b = 0x9e3779b9,
             c = init,
             i = len;

        // handle most of the key 
        while (i >= 12) 
              {
              a += *cast(uint*)(k+0);
              b += *cast(uint*)(k+4);
              c += *cast(uint*)(k+8);

              a -= b; a -= c; a ^= (c>>13); 
              b -= c; b -= a; b ^= (a<<8); 
              c -= a; c -= b; c ^= (b>>13); 
              a -= b; a -= c; a ^= (c>>12);  
              b -= c; b -= a; b ^= (a<<16); 
              c -= a; c -= b; c ^= (b>>5); 
              a -= b; a -= c; a ^= (c>>3);  
              b -= c; b -= a; b ^= (a<<10); 
              c -= a; c -= b; c ^= (b>>15); 
              k += 12; i -= 12;
              }

        // handle the last 11 bytes 
        c += len;
        switch (i)
               {
               case 11: c+=(cast(uint)(cast(ubyte*)k)[10]<<24);
               case 10: c+=(cast(uint)(cast(ubyte*)k)[9]<<16);
               case 9 : c+=(cast(uint)(cast(ubyte*)k)[8]<<8);
               case 8 : b+=(cast(uint)(cast(ubyte*)k)[7]<<24);
               case 7 : b+=(cast(uint)(cast(ubyte*)k)[6]<<16);
               case 6 : b+=(cast(uint)(cast(ubyte*)k)[5]<<8);
               case 5 : b+=(cast(uint)(cast(ubyte*)k)[4]);
               case 4 : a+=(cast(uint)(cast(ubyte*)k)[3]<<24);
               case 3 : a+=(cast(uint)(cast(ubyte*)k)[2]<<16);
               case 2 : a+=(cast(uint)(cast(ubyte*)k)[1]<<8);
               case 1 : a+=(cast(uint)(cast(ubyte*)k)[0]);
               default:
               }

        a -= b; a -= c; a ^= (c>>13); 
        b -= c; b -= a; b ^= (a<<8); 
        c -= a; c -= b; c ^= (b>>13); 
        a -= b; a -= c; a ^= (c>>12);  
        b -= c; b -= a; b ^= (a<<16); 
        c -= a; c -= b; c ^= (b>>5); 
        a -= b; a -= c; a ^= (c>>3);  
        b -= c; b -= a; b ^= (a<<10); 
        c -= a; c -= b; c ^= (b>>15); 

        return c;
}

