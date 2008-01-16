/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.tina.QueueServer;

private import  tango.net.cluster.tina.RollCall,
                tango.net.cluster.tina.QueueThread,
                tango.net.cluster.tina.ClusterQueue,  
                tango.net.cluster.tina.ClusterServer;

/******************************************************************************
        
        Extends the ClusterServer to glue cluster-cache support together.

******************************************************************************/

class QueueServer : ClusterServer
{
        private ClusterQueue queue;

        /**********************************************************************

                Construct this server with the requisite attributes. The 
                'bind' address is the local address we'll be listening on

        **********************************************************************/

        this (InternetAddress bind, Logger logger)
        {
                super ("queue", bind, logger);

                // create a queue instance
                // queue = new MemoryQueue  (cluster, 64 * 1024 * 1024, 1.0);
                queue = new PersistQueue (cluster, 64 * 1024 * 1024, 3.0);

        }

        /**********************************************************************

                Start the server

        **********************************************************************/

        void start (bool reuse=false)
        {
                super.start (new RollCall(RollCall.Queue), reuse);
        }

        /**********************************************************************

                Factory method for servicing a request. We just create
                a new QueueThread to handle requests from the client.
                The thread does not exit until the socket connection is
                broken by the client, or some other exception occurs. 

        **********************************************************************/

        override void service (IConduit conduit)
        {
                (new QueueThread (this, conduit, cluster, queue)).execute;
        }
}



version (QueueServer)
{
        import tango.io.Console;

        import tango.net.cluster.tina.CmdParser;

        void main (char[][] args)
        {
                auto arg = new CmdParser ("queue.server");

                if (args.length > 1)
                    arg.parse (args[1..$]);
                
                if (arg.help)
                    Cout ("usage: queueserver -port=number -log[=trace, info, warn, error, fatal, none]").newline;
                else
                   (new QueueServer(new InternetAddress(arg.port), arg.log)).start;
        }
}
