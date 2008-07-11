/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.CacheInvalidator;

package import  tango.net.cluster.NetworkClient;

private import  tango.net.cluster.NetworkMessage;

/*******************************************************************************

        Utility class to invalidate specific cache entries across a 
        network. Any active CacheInvalidatee objects listening upon
        the channel specified for this class will "wake up" whenever
        the invalidate() method is invoked.

*******************************************************************************/

class CacheInvalidator : NetworkClient
{
        private InvalidatorPayload filter;

        /***********************************************************************

                Construct an invalidator on the specified channel. Only
                those CacheInvalidatee instances configured for the same
                channel will be listening to this invalidator.

        ***********************************************************************/
        
        this (ICluster cluster, char[] channel)
        {
                assert (channel.length);
                super (cluster, channel);

                // this is what we'll send as an invalidation notification ...
                this.filter = new InvalidatorPayload;
        }

        /***********************************************************************

                Invalidate all network cache instances on this channel
                using the specified key. When 'timeLimit' is specified, 
                only those cache entries with a time lesser or equal to
                that specified will be removed. This is often useful if 
                you wish to avoid invalidating a cache (local or remote)
                that has just been updated; simply pass the time value
                of the 'old' IMessage as the argument.

                Note that this is asynchronous! An invalidation is just
                a request to remove the item within a short time period.
                If you need the entry removed synchronously, you should
                use the NetworkCache extract() method instead.

        ***********************************************************************/
        
        void invalidate (char[] key, Time timeLimit = Time.max)
        {
                assert (key.length);
                filter.key  (key);
                filter.time (timeLimit);

                // broadcast a message across the cluster
                channel.broadcast (filter);
        }
}


/*******************************************************************************

*******************************************************************************/

private class InvalidatorPayload : NetworkMessage
{
        private char[] key_;

        /***********************************************************************

        ***********************************************************************/

        char[] key ()
        {
                return key_;
        }

        /***********************************************************************

        ***********************************************************************/

        void key (char[] key)
        {
                assert (key.length);
                key_ = key;
        }

        /***********************************************************************

                Read our attributes, after telling our superclass to do
                likewise. The order of this is important with respect to
                inheritance, such that a subclass and superclass may be 
                populated in isolation where appropriate.

                Note that we slice our text attribute, rather than copying
                it. Since this class is temporal we can forego allocation
                of memory, and just map it directly from the input buffer. 

        ***********************************************************************/

        override void read (IReader input)
        {
                super.read (input);
                input (key_); 
        }

        /***********************************************************************

        ***********************************************************************/

        override void write (IWriter output)
        {
                super.write (output);
                output (key_);
        }
}

