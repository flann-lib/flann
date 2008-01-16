/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.tina.TaskThread;

private import  tango.core.Exception;

private import  tango.net.cluster.NetworkRegistry;

private import  tango.net.cluster.tina.ClusterThread;

/******************************************************************************

        Thread for handling remote-call requests.

******************************************************************************/

class TaskThread : ClusterThread
{
        private NetworkRegistry registry;

        /**********************************************************************

                Note that the conduit stays open until the client kills it

        **********************************************************************/

        this (AbstractServer server, IConduit conduit, Cluster cluster)
        {
                super (server, conduit, cluster);

                // clone the registry so that we have our own set of 
                // message templates to act as hosts. This eliminates
                // allocating hosts on the fly
                registry = NetworkRegistry.shared.dup;
        }

        /**********************************************************************

                process client requests
                
        **********************************************************************/

        void dispatch ()
        {
                ProtocolWriter.Command  cmd;
                char[]                  channel;
                char[]                  element;

                // wait for request to arrive
                if (reader.getHeader (cmd, channel, element))
                   {
                   // convert to a task. Note that we use a private set of 
                   // msg templates, so we don't collide with other threads
                   auto task = reader.thaw (registry);

                   if (task is null)
                       throw new IllegalArgumentException ("Remote-call instance is not executable");
                    
                   switch (cmd)
                          {
                          case ProtocolWriter.Command.Call:
                               logger.trace (sprint ("{} executing remote call '{}'", client, task.toString)); 
                               task.execute;

                               writer.put (ProtocolWriter.Command.OK, channel, element, task); 
                               break;
      
                          default:
                               throw new IllegalArgumentException ("invalid command");
                          }
                   }
        }
}

