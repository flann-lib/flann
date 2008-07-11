/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.CacheInvalidatee;

private import  tango.net.cluster.model.ICache;

private import  tango.net.cluster.NetworkClient,
                tango.net.cluster.CacheInvalidator;
                
/*******************************************************************************

        Wrapper around an ICache instance that attaches it to the network, 
        and ensures the former complies with cache invalidation requests. 
        Use this in conjunction with CacheInvalidator or NetworkCombo. The 
        ICache provided should typically be synchronized against thread 
        contention since it will potentially have entries removed from a 
        listener thread (you won't need synchronization if you're using
        the concurrent hash-map ICache implementation).

*******************************************************************************/

class CacheInvalidatee : NetworkClient
{
        alias ICache!(char[], IMessage) Cache;

        private Cache                   cache_;
        private IConsumer               consumer;

        /***********************************************************************

                Construct a CacheInvalidatee upon the given cache, using
                the named channel. This channel should be a name that is 
                common to both the receiver and the sender.

        ***********************************************************************/
        
        this (ICluster cluster, char[] name, Cache cache)
        {
                super (cluster, name);

                assert (cache);
                cache_ = cache;
        
                // start listening for invalidation requests
                consumer = channel.createBulletinConsumer (&notify);
        }

        /***********************************************************************

                Detach from the network. The CacheInvalidatee is disabled
                from this point forward.

        ***********************************************************************/
        
        void cancel ()
        {
                consumer.cancel;
        }

        /***********************************************************************

                Return the ICache instance provided during construction

        ***********************************************************************/
        
        Cache cache ()
        {
                return cache_;
        }

        /***********************************************************************

                Notification callback from the listener. We remove the
                indicated entry from our cache

        ***********************************************************************/
        
        private void notify (IEvent event)
        {
                scope p = new InvalidatorPayload;
                event.get (p);

                // remove entry from our cache
                if (cache_.remove (p.key, p.time))
                    event.log.trace ("removed cache entry '"~p.key~
                                     "' on channel '"~event.channel.name~"'");
        }  
}

