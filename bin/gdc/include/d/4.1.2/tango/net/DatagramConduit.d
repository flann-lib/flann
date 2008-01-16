/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mar 2004 : Initial release
        version:        Dec 2006 : South Pacific release
        
        author:         Kris

*******************************************************************************/

module tango.net.DatagramConduit;

public  import  tango.io.Conduit;

package import  tango.net.Socket,
                tango.net.SocketConduit;

/*******************************************************************************
        
        Datagrams provide a low-overhead, non-reliable data transmission
        mechanism.

        Datagrams are not 'connected' in the same manner as a TCP socket; you
        don't need to listen() or accept() to receive a datagram, and data
        may arrive from multiple sources. A datagram socket may, however,
        still use the connect() method like a TCP socket. When connected,
        the read() and write() methods will be restricted to a single address
        rather than being open instead. That is, applying connect() will make
        the address argument to both read() and write() irrelevant. Without
        connect(), method write() must be supplied with an address and method
        read() should be supplied with one to identify where data originated.
        
        Note that when used as a listener, you must first bind the socket
        to a local adapter. This can be achieved by binding the socket to
        an InternetAddress constructed with a port only (ADDR_ANY), thus
        requesting the OS to assign the address of a local network adapter

*******************************************************************************/

class DatagramConduit : SocketConduit
{
        private Address to,
                        from;

        /***********************************************************************
        
                Create a read/write datagram socket

        ***********************************************************************/

        this ()
        {
                super (SocketType.DGRAM, ProtocolType.IP);
        }

        /***********************************************************************
        
                Read bytes from an available datagram into the given array.
                When provided, the 'from' address will be populated with the
                origin of the incoming data. Note that we employ the timeout
                mechanics exposed via our SocketConduit superclass. 

                Returns the number of bytes read from the input, or Eof if
                the socket cannot read

        ***********************************************************************/

        uint read (void[] dst, Address from=null)
        {
                this.from = from;
                return input.read (dst);
        }

        /***********************************************************************
        
                Write an array to the specified address. If address 'to' is
                null, it is assumed the socket has been connected instead.

                Returns the number of bytes sent to the output, or Eof if
                the socket cannot write

        ***********************************************************************/

        uint write (void[] src, Address to=null)
        {
                this.to = to;
                return output.write (src);
        }

        /***********************************************************************

                SocketConduit override:
                
                Read available datagram bytes into a provided array. Returns
                the number of bytes read from the input, or Eof if the socket
                cannot read.

                Note that we're taking advantage of timout support within the
                superclass 

        ***********************************************************************/

        protected override uint socketReader (void[] dst)
        {
                int count;

                if (dst.length)
                    count = (from) ? socket.receiveFrom (dst, from) : socket.receiveFrom (dst);

                return count;
        }

        /***********************************************************************

                SocketConduit override:

                Write the provided content to the socket. This will stall
                until the socket responds in some manner. If there is no
                target address held by this class, we assume the datagram
                has been connected instead.

                Returns the number of bytes sent to the output, or Eof if
                the socket cannot write

        ***********************************************************************/

        protected override uint write (void[] src)
        {
                int count;
                
                if (src.length)
                   {
                   count = (to) ? socket.sendTo (src, to) : socket.sendTo (src);
                   if (count <= 0)
                       count = Eof;
                   }
                return count;
        }
}



/******************************************************************************

*******************************************************************************/

debug (Datagram)
{
        import tango.io.Console;

        import tango.net.InternetAddress;

        void main()
        {
                auto addr = new InternetAddress ("127.0.0.1", 8080);

                // listen for datagrams on the local address
                auto gram = new DatagramConduit;
                gram.bind (addr);

                // write to the local address
                gram.write ("hello", addr);

                // we are listening also ...
                char[8] tmp;
                auto x = new InternetAddress;
                auto bytes = gram.read (tmp, x);
                Cout (x) (tmp[0..bytes]).newline;
        }
}
