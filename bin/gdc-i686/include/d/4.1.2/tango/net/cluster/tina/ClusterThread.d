/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.tina.ClusterThread;

private import  tango.core.Thread,
                tango.core.Runtime,
                tango.core.Exception;

private import  tango.io.Buffer,
                tango.io.GrowBuffer,
                tango.net.ServerSocket;

package import  tango.io.model.IBuffer,
                tango.io.model.IConduit;

private import  tango.text.convert.Sprint;

package import  tango.net.cluster.tina.Cluster,
                tango.net.cluster.tina.ProtocolReader,
                tango.net.cluster.tina.ProtocolWriter;

package import  tango.net.cluster.tina.util.AbstractServer;

/******************************************************************************

        Thread for handling client requests. Note that this remains alive
        until the client kills the socket

******************************************************************************/

class ClusterThread
{
        protected IBuffer         buffer;
        protected ProtocolReader  reader;
        protected ProtocolWriter  writer;
        protected Logger          logger;
        protected char[]          client;
        protected Thread          thread;
        protected Sprint!(char)   sprint;
        protected Cluster         cluster;
        protected IConduit        conduit;

        /**********************************************************************

                request handler

        **********************************************************************/

        abstract void dispatch ();

        /**********************************************************************

                Note that the conduit stays open until the client kills it.
                Also note that we use a GrowableBuffer here, which expands
                as necessary to contain larger payloads.

        **********************************************************************/

        this (AbstractServer server, IConduit conduit, Cluster cluster)
        {
                buffer = new GrowBuffer (1024 * 8);
                buffer.setConduit (conduit);

                // get client infomation
                client = server.remoteAddress(conduit).toString;

                // setup cluster protocol-transcoders
                writer = new ProtocolWriter (buffer);
                reader = new ProtocolReader (buffer);

                // grab a thread to execute within
                thread = new Thread (&run);

                // make a formatter for this thread
                sprint = new Sprint!(char);
                
                // save state
                logger = server.getLogger;
                this.conduit = conduit;
                this.cluster = cluster;
        }

        /**********************************************************************

                IRunnable method

        **********************************************************************/

        void execute ()
        {
                thread.start;
        }
        
        /**********************************************************************

                process client requests
                
        **********************************************************************/

        private void run ()
        {
                logger.info (sprint ("{} starting service handler", client));
                
                try {
                    while (true)
                          {
                          // start with a clear conscience
                          buffer.clear;

                          // wait for something to arrive before we try/catch
                          buffer.slice (1, false);

                          try {
                              dispatch;
                              } catch (Object x)
                                      {
                                      logger.error (sprint ("{} cluster request error '{}'", client, x));
                                      writer.exception (sprint ("cluster request error '{}'", x.toString));
                                      }

                          // send response back to client
                          buffer.flush;
                          }

                    } catch (IOException x)
                             if (! Runtime.isHalting)
                                   logger.trace (sprint ("{} cluster socket exception '{}'", client, x));

                      catch (Object x)
                             logger.fatal (sprint ("{} cluster runtime exception '{}'", client, x));

                // log our halt status
                logger.info (sprint ("{} halting service handler", client));

                // make sure we close the conduit
                conduit.detach;
        }
}

