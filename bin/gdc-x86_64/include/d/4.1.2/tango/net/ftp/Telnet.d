/*******************************************************************************

        copyright:      Copyright (c) 2006 UWB. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: June 2006

        author:         UWB

*******************************************************************************/

module tango.net.ftp.Telnet;

private import tango.time.Clock;

private import tango.net.Socket;

private import tango.core.Exception;

private import Integer = tango.text.convert.Integer;


/// Utilities for telnet-based connections.
///
/// Params:
///    TelnetException =     the type for exceptions thrown
///    socket =              the connected socket
///    timeout =             the timeout for socket communication
class Telnet
{
        /// The control connection socket.
        protected Socket socket;

        /// The number of milliseconds to wait for socket communication or connection.
        protected TimeSpan timeout = TimeSpan.millis(5000);

        /// provided by host
        abstract void exception (char[] msg);
        
        /// Send a line over the socket.
        ///
        /// Params:
        ///    buf =             the bytes to send

        void sendLine(void[] buf)
        {
                this.sendData(buf);
                this.sendData("\r\n");
        }

        /// Send data over the socket.
        ///
        /// Params:
        ///    buf =             the bytes to send
        void sendData(void[] buf)
        in
        {
                assert (buf.length > 0);
        }
        body
        {
                // At end_time, we bail.
                Time end_time = Clock.now + this.timeout;

                // Set up a SocketSet so we can use select() - it's pretty efficient.
                SocketSet set = new SocketSet();
                scope (exit)
                        delete set;

                size_t pos = 0;
                while (Clock.now < end_time)
                {
                        set.reset();
                        set.add(this.socket);

                        // Can we write yet, can we write yet?
                        int code = Socket.select(null, set, null, this.timeout);
                        if (code == -1 || code == 0)
                                break;

                        // Send it (or as much as possible!)
                        int delta = this.socket.send(buf[pos .. buf.length]);
                        if (delta == -1)
                                break;

                        pos += delta;
                        if (pos >= buf.length)
                                break;
                }

                // If we didn't send everything, we're dead in the water.
                if (pos != buf.length)
                    exception ("CLIENT: Timeout when sending command");
        }

        /// Read a CRLF terminated line from the socket.
        ///
        /// Returns:             the line read
        char[] readLine()
        {
                // Figure, first, how long we're allowed to take.
                Time end_time = Clock.now + this.timeout;

                // An overall buffer and a one-char buffer.
                char[] buffer;
                char[1] buf;
                size_t buffer_pos = 0;

                // Push a byte onto the buffer.
                void push_byte()
                {
                        // Lines aren't usually that long.  Allocate in blocks of 16 bytes.
                        if (buffer.length <= buffer_pos)
                                buffer.length = buffer.length + 16;

                        buffer[buffer_pos++] = buf[0];
                }

                // Get the resultant buffer.
                char[] get_buffer()
                {
                        return buffer[0 .. buffer_pos];
                }

                // Now the socket set for selecting purposes.
                SocketSet set = new SocketSet();
                scope (exit)
                        delete set;

                while (Clock.now < end_time)
                {
                        set.reset();
                        set.add(this.socket);

                        // Try to read from the socket.
                        int code = Socket.select(set, null, null, this.timeout);
                        if (code == -1 || code == 0)
                                break;

                        // Okay, now we're ready.  Read in the measly byte.
                        int delta = this.socket.receive(buf);
                        if (delta != 1)
                                break;

                        if (buf == "\r")
                                continue;
                        else if (buf == "\n")
                                break;

                        push_byte();
                }

                return get_buffer();
        }

        /// Find a server which is listening on the specified port.
        ///
        /// Params:
        ///    hostname =        the hostname to lookup and connect to
        ///    port =            the port to connect on
        Socket findAvailableServer(char[] hostname, int port)
        {
                // First we need to get a list of IP addresses.
                auto host = new NetHost();
                scope (exit)
                        delete host;

                // Try to resolve the actual address for this hostname.
                host.getHostByName(hostname);
                scope (exit)
                        delete host.addrList;

                // None were found... darn.
                if (host.addrList.length == 0)
                        throw new AddressException("Unable to resolve host '" ~ hostname ~ "'");

                // Get all the sockets ready (or just one if there's just one address.)
                Socket[] sockets = new Socket[host.addrList.length];
                scope (exit)
                        delete sockets;

                // And now just connect to all of them.
                for (int i = 0; i < host.addrList.length; i++)
                {
                        sockets[i] = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
                        sockets[i].blocking = false;

                        Address addr = new IPv4Address(host.addrList[i], cast(ushort) port);
                        scope (exit)
                                delete addr;

                        // Start trying to connect as soon as possible.
                        sockets[i].connect(addr);
                }

                // Set up some stuff so we can select through the hosts.
                SocketSet set = new SocketSet();
                this.socket = null;

                scope (exit)
                        delete set;

                // Wait until we find a good socket...
                while (this.socket is null)
                {
                        set.reset();
                        foreach (Socket s; sockets)
                                set.add(s);

                        // Anyone available?
                        int code = Socket.select(null, set, null, this.timeout);
                        if (code == -1 || code == 0)
                                break;

                        // Now we have to check to find a good socket, and break out if we find one.
                        foreach (Socket s; sockets)
                                if (set.isSet(s))
                                {
                                        this.socket = s;
                                        break;
                                }
                }

                // Close the other sockets (or all on error.)
                foreach (Socket s; sockets)
                        if (s !is this.socket)
                        {
                                s.shutdown(SocketShutdown.BOTH);
                                s.detach();

                                delete s;
                        }

                // No socket, no data.  Can't do anything about that.
                if (this.socket is null)
                   {
                   char[10] tmp;
                   exception ("CLIENT: Unable to connect within the specified time limit (" ~ Integer.itoa(tmp, cast(uint) this.timeout.millis) ~ " ms.)");
                   }

                // Make it blocking again, because that's the norm.
                this.socket.blocking = true;

                return this.socket;
        }
}
