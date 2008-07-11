/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.tina.ClusterCache;

private import  tango.core.Exception;

private import  tango.net.cluster.QueuedCache;
                
private import  tango.net.cluster.tina.Cluster,
                tango.net.cluster.tina.ClusterTypes;

/******************************************************************************
       
        The cache containers. These are initiated by ClusterServer and 
        maintained via ClusterThread.
         
******************************************************************************/

class ClusterCache
{
        alias QueuedCache!(char[], ClusterContent)      Cache;

        private Cache[char[]]                           set;
        private uint                                    size;
        private Cluster                                 cluster;
        
        /**********************************************************************

                Construct a host for multi-channel cache instances. 

                TODO: all cache instances are currently the same size, 
                and it would be more practical to support some scheme
                of specifying distinct sizes. Also, this could likely
                benefit from a dedicated slab allocator instead of a
                QueuedCache.

        **********************************************************************/

        this (Cluster cluster, uint size)
        {
                this.size = size;
                if (size < 1 || size > 32 * 1024)
                    throw new IllegalArgumentException ("cache size should be between 1 and 32K entries");
        }

        /**********************************************************************

                Stuff an entry into cache for the channel:element pair. If
                the time value is provided, it will be used to guard against
                updating an existing "newer" cache entry.

                Note that the args are aliased, so we copy them as necessary

        **********************************************************************/

        bool put (char[] channel, char[] element, ClusterContent content, Time time)
        {       
                return lookup(channel).put (element, {return element.dup;}, 
                                                     {return cast(ClusterContent) content.dup;}, time);
        }       

        /**********************************************************************

                Remove an entry from the cache

        **********************************************************************/

        ClusterContent extract (char[] channel, char[] element)
        {
                return lookup(channel).remove (element);
        }

        /**********************************************************************

                Return an entry from the cache

        **********************************************************************/

        ClusterContent get (char[] channel, char[] element)
        {
                return lookup(channel).get (element);
        }

        /**********************************************************************

                Add a cache lock where the entry is invalid or unlocked.
                Returns true if locked by this call, false otherwise. Note
                that this will return false if the entry is already locked.

                TODO: implement

        **********************************************************************/

        bool lock (char[] channel, char[] element, Time time)
        {
                return true;
        }

        /**********************************************************************

                TODO: implement

        **********************************************************************/

        void unlock (char[] channel, char[] element)
        {
        }

        /**********************************************************************

                Return a channel-specific cache. Could benefit from a
                lock-free hashmap, instread of synching on AA access

        **********************************************************************/

        private synchronized Cache lookup (char[] channel)
        {       
                if (auto p = channel in set)
                    return *p;

                return set[channel.dup] = new Cache (size);               
        }       
}

