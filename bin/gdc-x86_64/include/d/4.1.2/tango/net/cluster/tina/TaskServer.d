/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.tina.TaskServer;

private import  tango.net.cluster.tina.RollCall,
                tango.net.cluster.tina.TaskThread,
                tango.net.cluster.tina.ClusterServer;

/******************************************************************************
        
        Extends the ClusterServer to glue cluster-rpc support together

******************************************************************************/

class TaskServer : ClusterServer
{
        /**********************************************************************

                Construct this server with the requisite attributes. The 
                'bind' address is the local address we'll be listening on

        **********************************************************************/

        this (InternetAddress bind, Logger logger)
        {
                super ("task", bind, logger);
        }

        /**********************************************************************

                Start the server

        **********************************************************************/

        override void start (bool reuse=false)
        {
                super.start (new RollCall(RollCall.Task), reuse);
        }

        /**********************************************************************

                Factory method for servicing a request. We just create
                a new TaskThread to handle requests from the client.
                The thread does not exit until the socket connection is
                broken by the client, or some other exception occurs. 

        **********************************************************************/

        override void service (IConduit conduit)
        {
                (new TaskThread (this, conduit, cluster)).execute;
        }
}



version (TaskServer)
{
        import tango.io.Console;

        import tango.net.cluster.tina.CmdParser;

        void main (char[][] args)
        {
                auto arg = new CmdParser ("task.server");

                if (args.length > 1)
                    arg.parse (args[1..$]);

                if (arg.help)
                    Cout ("usage: taskserver -port=number -log[=trace, info, warn, error, fatal, none]").newline;
                else
                   (new TaskServer(new InternetAddress(arg.port), arg.log)).start;
        }
}
