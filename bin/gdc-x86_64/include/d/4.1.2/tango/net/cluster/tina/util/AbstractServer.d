/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: April 2004

        author:         Kris

*******************************************************************************/

module tango.net.cluster.tina.util.AbstractServer;

private   import  tango.net.Socket;

protected import  tango.util.log.Log;

protected import  tango.net.ServerSocket,
                  tango.net.SocketConduit;

protected import  tango.io.model.IConduit;

protected import  tango.text.convert.Sprint;

protected import  tango.net.cluster.tina.util.model.IServer;

/******************************************************************************

        Exposes the foundation of a multi-threaded Socket server. This is
        subclassed by  mango.net.http.server.HttpServer, which itself would
        likely be subclassed by a SecureHttpServer.

******************************************************************************/

class AbstractServer : IServer
{
        private InternetAddress bind;
        private ServerSocket    server;
        private Logger          logger;
        private Sprint!(char)   sprint;
        private uint            threads;
        private uint            backlog;

        /**********************************************************************

                Setup this server with the requisite attributes. The number
                of threads specified dictate exactly that. You might have
                anything between 1 thread and several hundred, dependent
                upon the underlying O/S and hardware.

                Parameter 'backlog' specifies the max number of"simultaneous"
                connection requests to be handled by an underlying socket
                implementation.

        **********************************************************************/

        this (InternetAddress bind, int threads, int backlog, Logger logger)
        in {
           assert (bind);
           assert (logger);
           assert (backlog >= 0);
           assert (threads > 0 && threads < 256);
           }
        body
        {
                this.bind = bind;
                this.logger = logger;
                this.threads = threads;
                this.backlog = backlog;
                this.sprint = new Sprint!(char);
        }

        /**********************************************************************

                Concrete server must expose a name

        **********************************************************************/

        protected abstract char[] toString();

        /**********************************************************************

                Concrete server must expose a ServerSocket factory

        **********************************************************************/

        protected abstract ServerSocket createSocket (InternetAddress bind, int backlog, bool reuse=false);

        /**********************************************************************

                Concrete server must expose a thread factory

        **********************************************************************/

        protected abstract void createThread (ServerSocket socket);

        /**********************************************************************

                Concrete server must expose a service handler

        **********************************************************************/

        abstract void service (IConduit conduit);

        /**********************************************************************

                Provide support for figuring out the remote address

        **********************************************************************/

        IPv4Address remoteAddress (IConduit conduit)
        {
                auto tmp = cast(SocketConduit) conduit;
                if (tmp)
                    return cast(IPv4Address) tmp.socket.remoteAddress;
                return null;
        }

        /**********************************************************************

                Provide support for figuring out the remote address

        **********************************************************************/

        IPv4Address localAddress ()
        {
                return cast(IPv4Address) server.socket.localAddress;
        }

        /**********************************************************************

                Provide support for figuring out the remote address

        **********************************************************************/

        char[] getRemoteAddress (IConduit conduit)
        {
                auto addr = remoteAddress (conduit);

                if (addr)
                    return addr.toAddrString;
                return "127.0.0.1";
        }

        /**********************************************************************

                Provide support for figuring out the remote host. Not
                currently implemented.

        **********************************************************************/

        char[] getRemoteHost (IConduit conduit)
        {
                return null;
        }

        /**********************************************************************

                Return the local port we're attached to

        **********************************************************************/

        int getPort ()
        {
                return localAddress.port;
        }

        /**********************************************************************

                Return the local address we're attached to

        **********************************************************************/

        char[] getHost ()
        {
                return localAddress.toAddrString;
        }

        /**********************************************************************

                Return the logger associated with this server

        **********************************************************************/

        Logger getLogger ()
        {
                return logger;
        }

        /**********************************************************************

                Start this server

        **********************************************************************/

        void start (bool reuse = false)
        {
                // have the subclass create a ServerSocket for us
                server = createSocket (bind, backlog, reuse);

                // instantiate and start all threads
                for (auto i=threads; i-- > 0;)
                     createThread (server);

                // indicate what's going on
                logger.info (sprint ("Server {} started on {} with {} accept threads and {} backlogs",
                                      this, localAddress, threads, backlog));
        }
}
