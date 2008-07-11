/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.NetworkCache;

private import  tango.core.Thread;

private import  tango.net.cluster.model.IMessage;

private import  tango.net.cluster.QueuedCache,
                tango.net.cluster.CacheInvalidator,
                tango.net.cluster.CacheInvalidatee;

/*******************************************************************************

        A gateway to the network cache. From here you can easily place
        IMessage objects into the network cluster, copy them and remove 
        them. A cluster cache is spread out across many servers within 
        the network. Each cache entry is associated with a 'channel', 
        which is effectively the name of a cache instance within the
        cluster. See ComboCache also. The basic procedure is so:
        ---
        import tango.net.cluster.NetworkCache;
        import tango.net.cluster.tina.Cluster;

        auto cluster = new Cluster (...);
        auto cache = new NetworkCache (cluster, ...);

        cache.put (...);
        cache.get ();
        cache.invalidate (...);
        ---

        Note that any content placed into the cache must implement the
        IMessage interface, and must be enrolled with the Registry, as
        it may be frozen and thawed as it travels around the network.

*******************************************************************************/

class NetworkCache : CacheInvalidator
{
        /***********************************************************************

                Construct a NetworkCache using the QOS (cluster) provided, 
                and hook it onto the specified channel. Each subsequent 
                operation is tied to this channel.

        ***********************************************************************/
        
        this (ICluster cluster, char[] channel)
        {
                super (cluster, channel);
        }

        /***********************************************************************

                Returns a copy of the cluster cache entry corresponding to 
                the provided key. Returns null if there is no such entry.

        ***********************************************************************/
        
        IMessage get (char[] key)
        {
                assert (key.length);
                return channel.getCache (key, false);
        }

        /***********************************************************************

                Remove and return the cache entry corresponding to the 
                provided key.

        ***********************************************************************/
        
        IMessage extract (char[] key)
        {
                assert (key.length);
                return channel.getCache (key, true);
        }

        /***********************************************************************

                Set a cluster cache entry. 

                Place an entry into the network cache, replacing the
                entry with the identical key. Where message.time is
                set, it will be used to test for newer cache entries
                than the one being sent i.e. if someone else placed
                a newer entry into the cache, that one will remain.

                The msg will be placed into one or more cluster hosts 
                (depending upon QOS)

                Returns true if the cache entry was inserted, false if
                the cache server already has an exiting key with a more
                recent timestamp (where message.time is set).

        ***********************************************************************/
        
        bool put (char[] key, IMessage message)
        {
                assert (message);
                assert (key.length);

                return channel.putCache (key, message);
        }
}


/*******************************************************************************

        A combination of a local cache, cluster cache, and CacheInvalidatee.
        The two cache instances are combined such that they represent a
        classic level1/level2 cache. The CacheInvalidatee ensures that the
        level1 cache maintains coherency with the cluster. 

*******************************************************************************/

class NetworkCombo : NetworkCache
{
        private QueuedCache!(char[], IMessage)  cache;
        private CacheInvalidatee                invalidatee;

        /***********************************************************************
        
                Construct a ComboCache for the specified local cache, and
                on the given cluster channel.

        ***********************************************************************/
        
        this (ICluster cluster, char[] channel, uint capacity)
        {
                super (cluster, channel);

                cache = new QueuedCache!(char[], IMessage) (capacity);
                invalidatee = new CacheInvalidatee (cluster, channel, cache);
        }

        /***********************************************************************

                Get an IMessage from the local cache, and revert to the
                cluster cache if it's not found. 
                
                Cluster lookups will *not* place new content into the 
                local cache without confirmation: the supplied delegate 
                must perform the appropriate cloning of cluster entries 
                before they will be placed into the local cache. This 
                delegate would typically invoke the clone() method on 
                the provided network message; behaviour is undefined
                where a delegate simply returns a message without the
                appropriate cloning steps.

                Returns null if the entry does not exist in either the
                local or remote cache, or if the delegate returned null.
                Returns the cache entry otherwise.

        ***********************************************************************/
        
        IMessage get (char[] key, IMessage delegate(IMessage) dg)
        {
                auto cached = cache.get (key);
                if (cached is null)
                   {
                   cached = super.get (key);

                   // if delegate cloned the entry, 
                   // place said clone into the cache
                   if (cached && (cached = dg(cached)) !is null)
                       cache.put (key, cached, cached.time);
                   }
                return cached;
        }

        /***********************************************************************

                Place a new entry into the cache. This will also place
                the entry into the cluster, and optionally invalidate 
                all other local cache instances across the network. If
                a cache entry exists with the same key, it is replaced.

                Where message.time is set, it will be used to test for 
                newer cache entries than the one being sent i.e. if a
                newer entry exists in the cache, that one will remain.
                
                Note that when using the coherency option you should 
                ensure your IMessage has a valid time stamp, since that
                is used to invalidate appropriate cache listeners in the
                cluster. You can use the getTime() method to retrieve a 
                current millisecond count.

                Returns true if the cache entry was inserted, false if
                the cache server already has an exiting key with a more
                recent timestamp (where message.time is set).

        ***********************************************************************/
        
        bool put (char[] key, IMessage message, bool coherent = false)
        {
                // this will throw an exception if there's a problem
                if (super.put (key, message))
                   {
                   // place into local cache also
                   cache.put (key, message, message.time);

                   // invalidate all other cache instances except this new one,
                   // such that no other listening cache has the same key 
                   if (coherent)
                       invalidate (key, message.time);

                   return true;
                   }
                return false;
        }

        /***********************************************************************

                Remove and return the cache entry corresponding to the 
                provided key. 
                
                Synchronously extracts the entry from the cluster, and 
                returns the entry from the local cache if there is one 
                there; null otherwise

        ***********************************************************************/
        
        IMessage extract (char[] key)
        {
                // do this first, since its return value may have to be cloned
                super.extract (key);

                // return the local entry if there is one
                return cache.remove (key);
        }
}



