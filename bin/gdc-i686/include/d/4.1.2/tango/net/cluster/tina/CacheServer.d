/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.tina.CacheServer;

private import  tango.net.cluster.tina.RollCall,
                tango.net.cluster.tina.CacheThread,
                tango.net.cluster.tina.ClusterCache,
                tango.net.cluster.tina.ClusterServer;

/******************************************************************************
        
        Extends the ClusterServer to glue cluster-cache support together

******************************************************************************/

class CacheServer : ClusterServer
{
        private ClusterCache cache;

        /**********************************************************************

                Construct this server with the requisite attributes. The 
                'bind' address is the local address we'll be listening on 

        **********************************************************************/

        this (InternetAddress bind, Logger logger, uint size)
        {
                super ("cache", bind, logger);

                // create a cache instance
                cache = new ClusterCache (cluster, size);
        }

        /**********************************************************************

                Start the server

        **********************************************************************/

        void start (bool reuse=false)
        {
                super.start (new RollCall(RollCall.Cache), reuse);
        }

        /**********************************************************************

                Factory method for servicing a request. We just create
                a new CacheThread to handle requests from the client.
                The thread does not exit until the socket connection is
                broken by the client, or some other exception occurs. 

        **********************************************************************/

        override void service (IConduit conduit)
        {
                (new CacheThread (this, conduit, cluster, cache)).execute;
        }
}



version (CacheServer)
{
        import tango.io.Console;

        import tango.net.cluster.tina.CmdParser;

        void main (char[][] args)
        {
                auto arg = new CmdParser ("cache.server");

                // default number of cache entries (per channel)
                arg.size = 1024;

                if (args.length > 1)
                    arg.parse (args[1..$]);
                
                if (arg.help)
                    Cout ("usage: cacheserver -port=number -size=cachesize -log[=trace, info, warn, error, fatal, none]").newline;
                else
                   (new CacheServer(new InternetAddress(arg.port), arg.log, arg.size)).start;
        }
}
