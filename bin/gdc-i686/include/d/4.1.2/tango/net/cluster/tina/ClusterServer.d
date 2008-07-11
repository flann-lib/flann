/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.tina.ClusterServer;

private import  tango.core.Thread;

private import  tango.util.ArgParser;

private import  tango.net.Socket,
                tango.net.InternetAddress;
        
private import  tango.net.cluster.tina.Cluster,
                tango.net.cluster.tina.RollCall;

private import  tango.net.cluster.NetworkRegistry;

private import  tango.net.cluster.tina.util.ServerThread;

package import  tango.net.cluster.tina.util.AbstractServer;

/******************************************************************************
        
        Extends the AbstractServer to glue cluster support together.

******************************************************************************/

abstract class ClusterServer : AbstractServer
{
        package char[]          name;
        package Cluster         cluster;
        package IChannel        channel;
        package RollCall        rollcall;

        /**********************************************************************

                Concrete server must expose a service handler

        **********************************************************************/

        abstract void service (IConduit conduit);

        /**********************************************************************

                Construct this server with the requisite attributes. The 
                'bind' address is the local address we'll be listening on, 
                'threads' represents the number of socket-accept threads, 
                and backlog is the number of "simultaneous" connection 
                requests that a socket layer will buffer on our behalf.

                We also set up a listener for client discovery-requests, 
                and lastly, we tell active clients that we're available 
                for work. Clients should be listening on the appropriate 
                channel for an instance of the RollCall payload.

        **********************************************************************/

        this (char[] name, InternetAddress bind, Logger logger)
        {
                this.name = name;

                super (bind, 1, 50, logger);

                // hook into the cluster as a server
                cluster = new Cluster (logger);
        }

        /**********************************************************************

        **********************************************************************/

        void enroll (IMessage task)
        {
                NetworkRegistry.shared.enroll (task);
        }

        /**********************************************************************

                Start the server

                Note that we hijack the calling thread, and use it to 
                generate a hearbeat. The hearbeat has two functions: it
                tells all clients when this server starts, and it tells
                them we're still alive. The latter is important if, for
                example, a client request to this server had timed-out
                due to the server being too busy. In such a case, the
                client will mark the server as being unavailable, and 
                the heartbeat will presumably revert that.

                It would also be useful to monitor the GC from here.

        **********************************************************************/

        void start (RollCall id, bool reuse=false)
        {
                super.start (reuse);

                // configure an identity for ourselves
                id.addr = Socket.hostName ~ ':' ~ localAddress.toPortString;
                this.rollcall = id;

                // clients are listening on this channel ...
                channel = cluster.createChannel ("cluster.server.advertise");

                // ... and listen for subsequent server.advertise requests
                channel.createBulletinConsumer (&notify);

                while (true)
                      {
                      getLogger.trace ("heartbeat");
                      channel.broadcast (rollcall);
                      Thread.sleep (30.0);
                      }
        }

        /**********************************************************************

                Return a text string identifying this server

        **********************************************************************/

        char[] getProtocol ()
        {
                return name;
        }

        /**********************************************************************

                Return a text string identifying this server

        **********************************************************************/

        override char[] toString ()
        {
                return "cluster::" ~ name;
        }

        /**********************************************************************

                Create a ServerSocket instance. 

        **********************************************************************/

        override ServerSocket createSocket (InternetAddress bind, int backlog, bool reuse=false)
        {
                return new ServerSocket (bind, backlog, reuse);
        }

        /**********************************************************************

                Create a ServerThread instance. This can be overridden to 
                create other thread-types, perhaps with additional thread-
                level data attached.

        **********************************************************************/

        override void createThread (ServerSocket socket)
        {
                new ServerThread (this, socket);
        }

        /**********************************************************************

                Interface method that's invoked when a client is making
                discovery requests. We just send back our identity in a
                reply

        **********************************************************************/

        private void notify (IEvent event)
        {
                scope input = new RollCall;
                event.get (input);

                // if this is a request, reply with our identity
                if (input.type is input.Request)
                    channel.broadcast (rollcall);
        }
}

