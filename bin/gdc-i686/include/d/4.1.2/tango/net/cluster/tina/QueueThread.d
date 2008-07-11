/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.tina.QueueThread;

private import  tango.core.Exception;

private import  tango.net.cluster.tina.ClusterQueue,
                tango.net.cluster.tina.ClusterTypes,
                tango.net.cluster.tina.ClusterThread;

/******************************************************************************

        Thread for handling queue requests.

******************************************************************************/

class QueueThread : ClusterThread
{
        private ClusterQueue queue;
        
        /**********************************************************************

                Note that the conduit stays open until the client kills it

        **********************************************************************/

        this (AbstractServer server, IConduit conduit, Cluster cluster, ClusterQueue queue)
        {
                super (server, conduit, cluster);
                this.queue = queue;
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
                       case ProtocolWriter.Command.AddQueue:
                            logger.trace (sprint ("{} add queue entry on channel '{}'", client, channel)); 
        
                            if (queue.put (channel, content))
                                writer.success;
                            else
                               writer.full ("cluster queue is full");
                            break;
        
                       case ProtocolWriter.Command.RemoveQueue:
                            logger.trace (sprint ("{} remove queue entry on channel '{}'", client, channel)); 
        
                            writer.reply (queue.get (channel));
                            break;
             
                       default:
                            throw new IllegalArgumentException ("invalid command");
                       }
        }
}
