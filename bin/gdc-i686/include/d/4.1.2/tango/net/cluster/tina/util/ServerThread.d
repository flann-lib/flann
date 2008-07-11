/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: April 2004

        author:         Kris

*******************************************************************************/

module tango.net.cluster.tina.util.ServerThread;

private import  tango.core.Thread,
                tango.core.Runtime,
                tango.core.Exception;

private import  tango.net.ServerSocket;

private import  tango.net.cluster.tina.util.AbstractServer;

/******************************************************************************

        Subclasses Thread to provide the basic server-thread loop. This
        functionality could also be implemented as a delegate, however,
        we also wish to subclass in order to add thread-local data (see
        HttpThread).

******************************************************************************/

class ServerThread
{
        private AbstractServer  server;
        private ServerSocket    socket;

        /**********************************************************************

                Construct a ServerThread for the given Server, upon the
                specified socket

        **********************************************************************/

        this (AbstractServer server, ServerSocket socket)
        {
                this.server = server;
                this.socket = socket;
                (new Thread (&run)).start;
        }

        /**********************************************************************

                Execute this thread until the Server says to halt. Each
                thread waits in the socket.accept() state, waiting for
                a connection request to arrive. Upon selection, a thread
                dispatches the request via the request service-handler
                and, upon completion, enters the socket.accept() state
                once more.

        **********************************************************************/

        private void run ()
        {
                while (Runtime.isHalting is false)
                       try {
                           // wait for a socket connection
                           auto sc = socket.accept;

                           // did we get a valid response?
                           if (sc)
                               // yep - process this request
                               server.service (sc);
                           else
                              // server may be halting ...
                              if (socket.isAlive)
                                  server.getLogger.error ("Socket.accept failed");

                           } catch (IOException x)
                                    server.getLogger.error ("IOException: "~x.toString);

                             catch (Object x)
                                    server.getLogger.fatal ("Exception: "~x.toString);
        }
}
