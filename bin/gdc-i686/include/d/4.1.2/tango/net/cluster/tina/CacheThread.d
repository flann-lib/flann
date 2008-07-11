/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.tina.CacheThread;

private import  tango.core.Exception;

private import  tango.net.cluster.NetworkRegistry;

private import  tango.net.cluster.tina.ClusterCache,
                tango.net.cluster.tina.ClusterTypes,
                tango.net.cluster.tina.ClusterThread;

/******************************************************************************

        Thread for handling cache requests

******************************************************************************/

class CacheThread : ClusterThread
{
        private ClusterCache            cache;
        private NetworkRegistry         registry;

        /**********************************************************************

                Note that the conduit stays open until the client kills it

        **********************************************************************/

        this (AbstractServer server, IConduit conduit, Cluster cluster, ClusterCache cache)
        {
                super (server, conduit, cluster);

                // clone the registry so that we have our own set of 
                // message templates to act as hosts. This eliminates
                // allocating hosts on the fly for load() requests
                registry = NetworkRegistry.shared.dup;
        
                // retain the cache instance
                this.cache = cache;
        }

        /**********************************************************************

                process client requests
                
        **********************************************************************/

        void dispatch ()
        {
                ProtocolWriter.Command  cmd;
                long                    time;
                char[]                  channel;
                char[]                  element;

                // wait for request to arrive
                auto content = reader.getPacket (cmd, channel, element, time);

                switch (cmd)
                       {
                       case ProtocolWriter.Command.Add:
                            logger.trace (sprint ("{} add cache entry '{}' on channel '{}'", client, element, channel)); 
                                
                            // return the content if we can't put it in the cache
                            if (cache.put (channel, element, content, Time(time)))
                                writer.success ("success"); 
                            else
                               writer.reply (content); 
                            break;
 
                       case ProtocolWriter.Command.Copy:
                            logger.trace (sprint ("{} copy cache entry '{}' on channel '{}'", client, element, channel)); 

                            writer.reply (cache.get (channel, element)); 
                            break;
  
                       case ProtocolWriter.Command.Remove:
                            logger.trace (sprint ("{} remove cache entry '{}' on channel '{}'", client, element, channel)); 

                            writer.reply (cache.extract (channel, element));
                            break;
  
                       case ProtocolWriter.Command.Load:
                            logger.trace (sprint ("{} loading cache entry '{}' on channel '{}'", client, element, channel)); 

                            load (cmd, channel, element);
                            break;
     
                       default:
                            throw new IllegalArgumentException ("invalid command");
                       }
        }


        /**********************************************************************

                Manages the loading of cache entries remotely, upon 
                the host that actually contains the cache entry. 
                
                The benefit of this approach lies in the ability to 
                'gate' access to specific resources across the entire 
                network. That is; where particular cache entries are 
                prohibitively costly to construct, it is worthwhile 
                ensuring that cost is reduced to a bare minimum. These 
                remote loaders allow the cache host to block multiple 
                network clients until there's a new entry available. 
                Without this mechanism, it would become possible for 
                multiple  network clients to request the same entry 
                simultaneously, therefore increasing the overall cost. 
                The end result is similar to that of a distributed 
                transaction.
         
        **********************************************************************/

        void load (ProtocolWriter.Command cmd, char[] channel, char[] element)
        {
                // convert to a message instance. Note that we use a private 
                // set of msg templates, so we don't collide with other threads
                auto msg = reader.thaw (registry);

                // check to see if it has already been updated or is
                // currently locked; go home if so, otherwise lock it
                if (cache.lock (channel, element, msg.time))
                    try {                                                
                        // ensure this is the right object
                        auto loader = cast(IMessageLoader) msg;
                        if (loader)
                           {
                           // acknowledge the request. Do NOT wait for completion!
                           writer.success.flush;
 
                           // get the new cache entry. The 'time' attribute should 
                           // be set appropriately before return
                           if (auto e = loader.load)
                              {
                              long time;
                              // serialize new entry and stuff it into cache
                              writer.put (writer.Command.OK, channel, element, e);
                              cache.put  (channel, element, reader.getPacket (cmd, channel, element, time), e.time);
                              }
                           }
                        else
                           writer.exception (sprint ("invalid remote cache-loader '{}'", msg.toString)).flush;
 
                        } finally 
                                // ensure we unlock this one!
                                cache.unlock (channel, element);
                else
                   writer.success.flush;
        }
}

