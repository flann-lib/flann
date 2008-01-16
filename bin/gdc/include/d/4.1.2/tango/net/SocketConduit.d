/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mar 2004 : Initial release
        version:        Jan 2005 : RedShodan patch for timeout query
        version:        Dec 2006 : Outback release
        
        author:         Kris

*******************************************************************************/

module tango.net.SocketConduit;

private import  tango.time.Time;

public  import  tango.io.Conduit;

private import  tango.net.Socket;

/*******************************************************************************

        A wrapper around the bare Socket to implement the IConduit abstraction
        and add socket-specific functionality.

        SocketConduit data-transfer is typically performed in conjunction with
        an IBuffer, but can happily be handled directly using void array where
        preferred
        
*******************************************************************************/

class SocketConduit : Conduit
{
        private timeval                 tv;
        private SocketSet               ss;
        package Socket                  socket_;
        private bool                    timeout;

        // freelist support
        private SocketConduit           next;   
        private bool                    fromList;
        private static SocketConduit    freelist;

        /***********************************************************************
        
                Create a streaming Internet Socket

        ***********************************************************************/

        this ()
        {
                this (SocketType.STREAM, ProtocolType.TCP);
        }

        /***********************************************************************
        
                Create an Internet Socket. Used by subclasses and by
                ServerSocket; the latter via method allocate() below

        ***********************************************************************/

        protected this (SocketType type, ProtocolType protocol, bool create=true)
        {
                socket_ = new Socket (AddressFamily.INET, type, protocol, create);
        }

        /***********************************************************************

                Return the name of this device

        ***********************************************************************/

        override char[] toString()
        {
                return socket.toString;
        }

        /***********************************************************************

                Return the socket wrapper
                
        ***********************************************************************/

        Socket socket ()
        {
                return socket_;
        }

        /***********************************************************************

                Return a preferred size for buffering conduit I/O

        ***********************************************************************/

        override uint bufferSize ()
        {
                return 1024 * 8;
        }

        /***********************************************************************

                Models a handle-oriented device.

                TODO: figure out how to avoid exposing this in the general
                case

        ***********************************************************************/

        override Handle fileHandle ()
        {
                return cast(Handle) socket_.fileHandle;
        }

        /***********************************************************************

                Set the read timeout to the specified interval. Set a
                value of zero to disable timeout support.

        ***********************************************************************/

        SocketConduit setTimeout (TimeSpan interval)
        {
                tv = Socket.toTimeval (interval);
                return this;
        }

        /***********************************************************************

                Did the last operation result in a timeout? 

        ***********************************************************************/

        bool hadTimeout ()
        {
                return timeout;
        }

        /***********************************************************************

                Is this socket still alive?

        ***********************************************************************/

        override bool isAlive ()
        {
                return socket_.isAlive;
        }

        /***********************************************************************

                Connect to the provided endpoint
        
        ***********************************************************************/

        SocketConduit connect (Address addr)
        {
                socket_.connect (addr);
                return this;
        }

        /***********************************************************************

                Bind the socket. This is typically used to configure a
                listening socket (such as a server or multicast socket).
                The address given should describe a local adapter, or
                specify the port alone (ADDR_ANY) to have the OS assign
                a local adapter address.
        
        ***********************************************************************/

        SocketConduit bind (Address address)
        {
                socket_.bind (address);
                return this;
        }

        /***********************************************************************

                Inform other end of a connected socket that we're no longer
                available. In general, this should be invoked before close()
                is invoked
        
                The shutdown function shuts down the connection of the socket: 

                    -   stops receiving data for this socket. If further data 
                        arrives, it is rejected.

                    -   stops trying to transmit data from this socket. Also
                        discards any data waiting to be sent. Stop looking for 
                        acknowledgement of data already sent; don't retransmit 
                        if any data is lost.

        ***********************************************************************/

        SocketConduit shutdown ()
        {
                socket_.shutdown (SocketShutdown.BOTH);
                return this;
        }

        /***********************************************************************

                Read content from socket. This is implemented as a callback
                from the reader() method so we can expose the timout support
                to subclasses
                
        ***********************************************************************/

        protected uint socketReader (void[] dst)
        {
                return socket_.receive (dst);
        }
        
        /***********************************************************************

                Release this SocketConduit

                Note that one should always disconnect a SocketConduit 
                under normal conditions, and generally invoke shutdown 
                on all connected sockets beforehand

        ***********************************************************************/

        override void detach ()
        {
                socket_.detach;

                // deallocate if this came from the free-list,
                // otherwise just wait for the GC to handle it
                if (fromList)
                    deallocate (this);
        }

       /***********************************************************************

                Callback routine to read content from the socket. Note
                that the operation may timeout if method setTimeout()
                has been invoked with a non-zero value.

                Returns the number of bytes read from the socket, or
                IConduit.Eof where there's no more content available

                Note that a timeout is equivalent to Eof. Isolating
                a timeout condition can be achieved via hadTimeout()

                Note also that a zero return value is not legitimate;
                such a value indicates Eof

        ***********************************************************************/

        override uint read (void[] dst)
        {
                // ensure just one read at a time
                synchronized (this)
                {
                // reset timeout; we assume there's no thread contention
                timeout = false;

                // did user disable timeout checks?
                if (tv.tv_usec | tv.tv_sec)
                   {
                   // nope: ensure we have a SocketSet
                   if (ss is null)
                       ss = new SocketSet (1);

                   ss.reset ();
                   ss.add (socket_);

                   // wait until data is available, or a timeout occurs
                   auto copy = tv;
                   int i = socket_.select (ss, null, null, &copy);
                       
                   if (i <= 0)
                      {
                      if (i is 0)
                          timeout = true;
                      return Eof;
                      }
                   }       

                // invoke the actual read op
                int count = socketReader (dst);
                if (count <= 0)
                    count = Eof;
                return count;
                }
        }
        
        /***********************************************************************

                Callback routine to write the provided content to the
                socket. This will stall until the socket responds in
                some manner. Returns the number of bytes sent to the
                output, or IConduit.Eof if the socket cannot write.

        ***********************************************************************/

        override uint write (void[] src)
        {
                int count = socket_.send (src);
                if (count <= 0)
                    count = Eof;
                return count;
        }

        /***********************************************************************

                Allocate a SocketConduit from a list rather than creating
                a new one. Note that the socket itself is not opened; only
                the wrappers. This is because the socket is often assigned
                directly via accept()

        ***********************************************************************/

        package static synchronized SocketConduit allocate ()
        {       
                SocketConduit s;

                if (freelist)
                   {
                   s = freelist;
                   freelist = s.next;
                   }
                else
                   {
                   s = new SocketConduit (SocketType.STREAM, ProtocolType.TCP, false);
                   s.fromList = true;
                   }
                return s;
        }

        /***********************************************************************

                Return this SocketConduit to the free-list

        ***********************************************************************/

        private static synchronized void deallocate (SocketConduit s)
        {
                s.next = freelist;
                freelist = s;
        }
}

