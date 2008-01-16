/*******************************************************************************

        copyright:      Copyright (c) 2006 UWB. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: June 2006

        author:         UWB

*******************************************************************************/

module tango.net.ftp.FtpClient;

private import  tango.net.Socket;

private import  tango.net.ftp.Telnet;

private import  tango.time.Clock;

private import  tango.io.Conduit,
                tango.io.GrowBuffer,
                tango.io.FileConduit;

private import  tango.time.chrono.Gregorian;

private import  Text = tango.text.Util;

private import  Ascii = tango.text.Ascii;

private import  Regex = tango.text.Regex;

private import  Integer = tango.text.convert.Integer;

private import  Timestamp = tango.text.convert.TimeStamp;


/// An FTP progress delegate.
///
/// You may need to add the restart position to this, and use SIZE to determine
/// percentage completion.  This only represents the number of bytes
/// transferred.
///
/// Params:
///    pos =                 the current offset into the stream
alias void delegate(in size_t pos) FtpProgress;

/// The format of data transfer.
enum FtpFormat
{
    /// Indicates ASCII NON PRINT format (line ending conversion to CRLF.)
    ascii,
    /// Indicates IMAGE format (8 bit binary octets.)
    image,
}

/// A server response, consisting of a code and a potentially multi-line message.
struct FtpResponse
{
    /// The response code.
    ///
    /// The digits in the response code can be used to determine status
    /// programatically.
    ///
    /// First Digit (status):
    ///    1xx =             a positive, but preliminary, reply
    ///    2xx =             a positive reply indicating completion
    ///    3xx =             a positive reply indicating incomplete status
    ///    4xx =             a temporary negative reply
    ///    5xx =             a permanent negative reply
    ///
    /// Second Digit (subject):
    ///    x0x =             condition based on syntax
    ///    x1x =             informational
    ///    x2x =             connection
    ///    x3x =             authentication/process
    ///    x5x =             file system
    char[3] code = "000";

    /// The message from the server.
    ///
    /// With some responses, the message may contain parseable information.
    /// For example, this is true of the 257 response.
    char[] message = null;
}

/// Active or passive connection mode.
enum FtpConnectionType
{
    /// Active - server connects to client on open port.
    active,
    /// Passive - server listens for a connection from the client.
    passive,
}

/// Detail about the data connection.
///
/// This is used to properly send PORT and PASV commands.
struct FtpConnectionDetail
{
    /// The type to be used.
    FtpConnectionType type = FtpConnectionType.passive;

    /// The address to give the server.
    Address address = null;

    /// The address to actually listen on.
    Address listen = null;
}

/// A supported feature of an FTP server.
struct FtpFeature
{
    /// The command which is supported, e.g. SIZE.
    char[] command = null;
    /// Parameters for this command; e.g. facts for MLST.
    char[] params = null;
}

/// The type of a file in an FTP listing.
enum FtpFileType
{
    /// An unknown file or type (no type fact.)
    unknown,
    /// A regular file, or similar.
    file,
    /// The current directory (e.g. ., but not necessarily.)
    cdir,
    /// A parent directory (usually "..".)
    pdir,
    /// Any other type of directory.
    dir,
    /// Another type of file.  Consult the "type" fact.
    other,
}

/// Information about a file in an FTP listing.
struct FtpFileInfo
{
    /// The filename.
    char[] name = null;
    /// Its type.
    FtpFileType type = FtpFileType.unknown;
    /// Size in bytes (8 bit octets), or -1 if not available.
    long size = -1;
    /// Modification time, if available.
    Time modify = Time.max;
    /// Creation time, if available (not often.)
    Time create = Time.max;
    /// The file's mime type, if known.
    char[] mime = null;
    /// An associative array of all facts returned by the server, lowercased.
    char[][char[]] facts;
}

/// A connection to an FTP server.
///
/// Example:
/// ----------
/// auto ftp = new FTPConnection("hostname", "user", "pass",21);
///
/// ftp.mkdir("test");
/// ftp.close();
/// ----------
///
/// Standards:               RFC 959, RFC 2228, RFC 2389, RFC 2428
///
/// Bugs:
///    Does not support several uncommon FTP commands and responses.


class FTPConnection : Telnet
{
    /// Supported features (if known.)
    ///
    /// This will be empty if not known, or else contain at least FEAT.
    public FtpFeature[] supported_features = null;

    /// Data connection information.
    protected FtpConnectionDetail data_info;

    /// The last-set restart position.
    ///
    /// This is only used when a local file is used for a RETR or STOR.
    protected size_t restart_pos = 0;

    /// error handler
    protected void exception (char[] msg)
    {
        throw new FTPException ("Exception: " ~ msg);
    }
      
    /// ditto
    protected void exception (FtpResponse r)
    {
        throw new FTPException (r);
    }

    /// Construct an FTPConnection without connecting immediately.
    public this()
    {
    }

    /// Connect to an FTP server with a username and password.
    ///
    /// Params:
    ///    hostname =        the hostname or IP address to connect to
    ///    port =            the port number to connect to
    ///    username =        username to be sent
    ///    password =        password to be sent, if requested
    public this(char[] hostname, char[] username, char[] password, int port = 21)
    {
        this.connect(hostname, username, password,port);
    }

    /// Connect to an FTP server with a username and password.
    ///
    /// Params:
    ///    hostname =        the hostname or IP address to connect to
    ///    port =            the port number to connect to
    ///    username =        username to be sent
    ///    password =        password to be sent, if requested
    public void connect(char[] hostname, char[] username, char[] password, int port = 21)
        in
    {
        // We definitely need a hostname and port.
        assert (hostname.length > 0);
        assert (port > 0);
    }
    body
    {
        // Close any active connection.

        if (this.socket !is null)
            this.close();


        // Connect to whichever FTP server responds first.
        this.findAvailableServer(hostname, port);

        this.socket.blocking = false;

        scope (failure)
            {
                this.close();
            }

        // The welcome message should always be a 220.  120 and 421 are considered errors.
        this.readResponse("220");

        if (username.length == 0)
            return;

        // Send the username.  Anything but 230, 331, or 332 is basically an error.
        this.sendCommand("USER", username);
        auto response = this.readResponse();

        // 331 means username okay, please proceed with password.
        if (response.code == "331")
            {
                this.sendCommand("PASS", password);
                response = this.readResponse();
            }

        // We don't support ACCT (332) so we should get a 230 here.
        if (response.code != "230" && response.code != "202")
            {

                exception (response);
            }

    }

    /// Close the connection to the server.
    public void close()
    {
        assert (this.socket !is null);

        // Don't even try to close it if it's not open.
        if (this.socket !is null)
            {
                try
                    {
                        this.sendCommand("QUIT");
                        this.readResponse("221");
                    }
                // Ignore if the above could not be completed.
                catch (FTPException)
                    {
                    }

                // Shutdown the socket...
                this.socket.shutdown(SocketShutdown.BOTH);
                this.socket.detach();

                // Clear out everything.
                delete this.supported_features;
                delete this.socket;
            }
    }

    /// Set the connection to use passive mode for data tranfers.
    ///
    /// This is the default.
    public void setPassive()
    {
        this.data_info.type = FtpConnectionType.passive;

        delete this.data_info.address;
        delete this.data_info.listen;
    }

    /// Set the connection to use active mode for data transfers.
    ///
    /// This may not work behind firewalls.
    ///
    /// Params:
    ///    ip =              the ip address to use
    ///    port =            the port to use
    ///    listen_ip =       the ip to listen on, or null for any
    ///    listen_port =     the port to listen on, or 0 for the same port
    public void setActive(char[] ip, ushort port, char[] listen_ip = null, ushort listen_port = 0)
        in
    {
        assert (ip.length > 0);
        assert (port > 0);
    }
    body
    {
        this.data_info.type = FtpConnectionType.active;
        this.data_info.address = new IPv4Address(ip, port);

        // A local-side port?
        if (listen_port == 0)
            listen_port = port;

        // Any specific IP to listen on?
        if (listen_ip == null)
            this.data_info.listen = new IPv4Address(IPv4Address.ADDR_ANY, listen_port);
        else
            this.data_info.listen = new IPv4Address(listen_ip, listen_port);
    }


    /// Change to the specified directory.
    public void cd(char[] dir)
        in
    {
        assert (dir.length > 0);
    }
    body
    {
        this.sendCommand("CWD", dir);
        this.readResponse("250");
    }

    /// Change to the parent of this directory.
    public void cdup()
    {
        this.sendCommand("CDUP");
        this.readResponse("200");
    }

    /// Determine the current directory.
    ///
    /// Returns:             the current working directory
    public char[] cwd()
    {
        this.sendCommand("PWD");
        auto response = this.readResponse("257");

        return this.parse257(response);
    }

    /// Change the permissions of a file.
    ///
    /// This is a popular feature of most FTP servers, but not explicitly outlined
    /// in the spec.  It does not work on, for example, Windows servers.
    ///
    /// Params:
    ///    path =            the path to the file to chmod
    ///    mode =            the desired mode; expected in octal (0777, 0644, etc.)
    public void chmod(char[] path, int mode)
        in
    {
        assert (path.length > 0);
        assert (mode >= 0 && (mode >> 16) == 0);
    }
    body
    {
        char[] tmp = "000";
        // Convert our octal parameter to a string.
        Integer.format(tmp, cast(long) mode, Integer.Style.Octal);
        this.sendCommand("SITE CHMOD", tmp, path);
        this.readResponse("200");
    }

    /// Remove a file or directory.
    ///
    /// Params:
    ///    path =            the path to the file or directory to delete
    public void del(char[] path)
        in
    {
        assert (path.length > 0);
    }
    body
    {
        this.sendCommand("DELE", path);
        auto response = this.readResponse();

        // Try it as a directory, then...?
        if (response.code != "250")
            this.rm(path);
    }

    /// Remove a directory.
    ///
    /// Params:
    ///    path =            the directory to delete
    public void rm(char[] path)
        in
    {
        assert (path.length > 0);
    }
    body
    {
        this.sendCommand("RMD", path);
        this.readResponse("250");
    }

    /// Rename/move a file or directory.
    ///
    /// Params:
    ///    old_path =        the current path to the file
    ///    new_path =        the new desired path
    public void rename(char[] old_path, char[] new_path)
        in
    {
        assert (old_path.length > 0);
        assert (new_path.length > 0);
    }
    body
    {
        // Rename from... rename to.  Pretty simple.
        this.sendCommand("RNFR", old_path);
        this.readResponse("350");

        this.sendCommand("RNTO", new_path);
        this.readResponse("250");
    }

    /// Determine the size in bytes of a file.
    ///
    /// This size is dependent on the current type (ASCII or IMAGE.)
    ///
    /// Params:
    ///    path =            the file to retrieve the size of
    ///    format =          what format the size is desired in
    public size_t size(char[] path, FtpFormat format = FtpFormat.image)
        in
    {
        assert (path.length > 0);
    }
    body
    {
        this.type(format);

        this.sendCommand("SIZE", path);
        auto response = this.readResponse("213");

        // Only try to parse the numeric bytes of the response.
        size_t end_pos = 0;
        while (end_pos < response.message.length)
            {
                if (response.message[end_pos] < '0' || response.message[end_pos] > '9')
                    break;
                end_pos++;
            }

        return toInt(response.message[0 .. end_pos]);
    }

    /// Send a command and process the data socket.
    ///
    /// This opens the data connection and checks for the appropriate response.
    ///
    /// Params:
    ///    command =         the command to send (e.g. STOR)
    ///    parameters =      any arguments to send
    ///
    /// Returns:             the data socket
    public Socket processDataCommand(char[] command, char[][] parameters ...)
    {
        // Create a connection.
        Socket data = this.getDataSocket();
        scope (failure)
            {
                // Close the socket, whether we were listening or not.
                data.shutdown(SocketShutdown.BOTH);
                data.detach();
            }

        // Tell the server about it.
        this.sendCommand(command, parameters);

        // We should always get a 150/125 response.
        auto response = this.readResponse();
        if (response.code != "150" && response.code != "125")
            exception (response);

        // We might need to do this for active connections.
        this.prepareDataSocket(data);

        return data;
    }

    /// Clean up after the data socket and process the response.
    ///
    /// This closes the socket and reads the 226 response.
    ///
    /// Params:
    ///    data =            the data socket
    public void finishDataCommand(Socket data)
    {
        // Close the socket.  This tells the server we're done (EOF.)
        data.shutdown(SocketShutdown.BOTH);
        data.detach();

        // We shouldn't get a 250 in STREAM mode.
        this.readResponse("226");
    }

    /// Get a data socket from the server.
    ///
    /// This sends PASV/PORT as necessary.
    ///
    /// Returns:             the data socket or a listener
    protected Socket getDataSocket()
    {
        // What type are we using?
        switch (this.data_info.type)
            {
            default:
                exception ("unknown connection type");

                // Passive is complicated.  Handle it in another member.
            case FtpConnectionType.passive:
                return this.connectPassive();

                // Active is simpler, but not as fool-proof.
            case FtpConnectionType.active:
                IPv4Address data_addr = cast(IPv4Address) this.data_info.address;

                // Start listening.
                Socket listener = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
                listener.bind(this.data_info.listen);
                listener.listen(32);

                // Use EPRT if we know it's supported.
                if (this.is_supported("EPRT"))
                    {
                        char[64] tmp = void;

                        this.sendCommand("EPRT", Text.layout(tmp, "|1|%0|%1|", data_addr.toAddrString, data_addr.toPortString));
                        // this.sendCommand("EPRT", format("|1|%s|%s|", data_addr.toAddrString(), data_addr.toPortString()));
                        this.readResponse("200");
                    }
                else
                    {
                        int h1, h2, h3, h4, p1, p2;
                        h1 = (data_addr.addr() >> 24) % 256;
                        h2 = (data_addr.addr() >> 16) % 256;
                        h3 = (data_addr.addr() >> 8_) % 256;
                        h4 = (data_addr.addr() >> 0_) % 256;
                        p1 = (data_addr.port() >> 8_) % 256;
                        p2 = (data_addr.port() >> 0_) % 256;
        
                        // low overhead method to format a numerical string
                        char[64] tmp = void;
                        char[20] foo = void;
                        auto str = Text.layout (tmp, "%0,%1,%2,%3,%4,%5",
                                                Integer.format(foo[0..3], h1),
                                                Integer.format(foo[3..6], h2),
                                                Integer.format(foo[6..9], h3),
                                                Integer.format(foo[9..12], h4),
                                                Integer.format(foo[12..15], p1),
                                                Integer.format(foo[15..18], p2));

                        // This formatting is weird.
                        // this.sendCommand("PORT", format("%d,%d,%d,%d,%d,%d", h1, h2, h3, h4, p1, p2));

                        this.sendCommand("PORT", str);
                        this.readResponse("200");
                    }

                return listener;
            }
        assert (false);
    }

    /// Prepare a data socket for use.
    ///
    /// This modifies the socket in some cases.
    ///
    /// Params:
    ///    data =            the data listener socket
    protected void prepareDataSocket(inout Socket data)
    {
        switch (this.data_info.type)
            {
            default:
                exception ("unknown connection type");

            case FtpConnectionType.active:
                Socket new_data = null;

                SocketSet set = new SocketSet();
                scope (exit)
                    delete set;

                // At end_time, we bail.
                Time end_time = Clock.now + this.timeout;

                while (Clock.now < end_time)
                    {
                        set.reset();
                        set.add(data);

                        // Can we accept yet?
                        int code = Socket.select(set, null, null, this.timeout);
                        if (code == -1 || code == 0)
                            break;

                        new_data = data.accept();
                        break;
                    }

                if (new_data is null)
                    throw new FTPException("CLIENT: No connection from server", "420");

                // We don't need the listener anymore.
                data.shutdown(SocketShutdown.BOTH);
                data.detach();

                // This is the actual socket.
                data = new_data;
                break;

            case FtpConnectionType.passive:
                break;
            }
    }

    /// Send a PASV and initiate a connection.
    ///
    /// Returns:             a connected socket
    public Socket connectPassive()
    {
        Address connect_to = null;

        // SPSV, which is just a port number.
        if (this.is_supported("SPSV"))
            {
                this.sendCommand("SPSV");
                auto response = this.readResponse("227");

                // Connecting to the same host.
                IPv4Address remote = cast(IPv4Address) this.socket.remoteAddress();
                assert (remote !is null);

                uint address = remote.addr();
                uint port = toInt(response.message);

                connect_to = new IPv4Address(address, cast(ushort) port);
            }
        // Extended passive mode (IP v6, etc.)
        else if (this.is_supported("EPSV"))
            {
                this.sendCommand("EPSV");
                auto response = this.readResponse("229");

                // Try to pull out the (possibly not parenthesized) address.
                auto r = Regex.search(response.message, `\([^0-9][^0-9][^0-9](\d+)[^0-9]\)`);
                if (r is null)
                    throw new FTPException("CLIENT: Unable to parse address", "501");

                IPv4Address remote = cast(IPv4Address) this.socket.remoteAddress();
                assert (remote !is null);

                uint address = remote.addr();
                uint port = toInt(r.match(1));

                connect_to = new IPv4Address(address, cast(ushort) port);
            }
        else
            {
                this.sendCommand("PASV");
                auto response = this.readResponse("227");

                // Try to pull out the (possibly not parenthesized) address.
                auto r = Regex.search(response.message, `(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+)(,\s*(\d+))?`);
                if (r is null)
                    throw new FTPException("CLIENT: Unable to parse address", "501");

                // Now put it into something std.socket will understand.
                char[] address = r.match(1)~"."~r.match(2)~"."~r.match(3)~"."~r.match(4);
                uint port = (toInt(r.match(5)) << 8) + (r.match(7).length > 0 ? toInt(r.match(7)) : 0);

                // Okay, we've got it!
                connect_to = new IPv4Address(address, port);
            }

        scope (exit)
            delete connect_to;

        // This will throw an exception if it cannot connect.
        auto sock = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
        sock.connect (connect_to);
        return sock;
    }

    /// Change the type of data transfer.
    ///
    /// ASCII mode implies that line ending conversion should be made.
    /// Only NON PRINT is supported.
    ///
    /// Params:
    ///    type =            FtpFormat.ascii or FtpFormat.image
    public void type(FtpFormat format)
    {
        if (format == FtpFormat.ascii)
            this.sendCommand("TYPE", "A");
        else
            this.sendCommand("TYPE", "I");

        this.readResponse("200");
    }

    /// Store a local file on the server.
    ///
    /// Calling this function will change the current data transfer format.
    ///
    /// Params:
    ///    path =            the path to the remote file
    ///    local_file =      the path to the local file
    ///    progress =        a delegate to call with progress information
    ///    format =          what format to send the data in

    public void put(char[] path, char[] local_file, FtpProgress progress = null, FtpFormat format = FtpFormat.image)
        in
    {
        assert (path.length > 0);
        assert (local_file.length > 0);
    }
    body
    {
        // Open the file for reading...
        auto file = new FileConduit(local_file);
        scope (exit)
            {
                file.detach();
                delete file;
            }

        // Seek to the correct place, if specified.
        if (this.restart_pos > 0)
            {
                file.seek(this.restart_pos);
                this.restart_pos = 0;
            }
        else
            {
                // Allocate space for the file, if we need to.
                this.allocate(file.length);
            }

        // Now that it's open, we do what we always do.
        this.put(path, file, progress, format);
    }

    /// Store data from a stream on the server.
    ///
    /// Calling this function will change the current data transfer format.
    ///
    /// Params:
    ///    path =            the path to the remote file
    ///    stream =          data to store, or null for a blank file
    ///    progress =        a delegate to call with progress information
    ///    format =          what format to send the data in
    public void put(char[] path, InputStream stream = null, FtpProgress progress = null, FtpFormat format = FtpFormat.image)
        in
    {
        assert (path.length > 0);
    }
    body
    {
        // Change to the specified format.
        this.type(format);

        // Okay server, we want to store something...
        Socket data = this.processDataCommand("STOR", path);

        // Send the stream over the socket!
        if (stream !is null)
            this.sendStream(data, stream, progress);

        this.finishDataCommand(data);
    }

    /// Append data to a file on the server.
    ///
    /// Calling this function will change the current data transfer format.
    ///
    /// Params:
    ///    path =            the path to the remote file
    ///    stream =          data to append to the file
    ///    progress =        a delegate to call with progress information
    ///    format =          what format to send the data in
    public void append(char[] path, InputStream stream, FtpProgress progress = null, FtpFormat format = FtpFormat.image)
        in
    {
        assert (path.length > 0);
        assert (stream !is null);
    }
    body
    {
        // Change to the specified format.
        this.type(format);

        // Okay server, we want to store something...
        Socket data = this.processDataCommand("APPE", path);

        // Send the stream over the socket!
        this.sendStream(data, stream, progress);

        this.finishDataCommand(data);
    }

    /// Seek to a byte offset for the next transfer.
    ///
    /// Params:
    ///    offset =          the number of bytes to seek forward
    public void restartSeek(size_t offset)
    {
        char[16] tmp;
        this.sendCommand("REST", Integer.format (tmp, cast(long) offset));
        this.readResponse("350");

        // Set this for later use.
        this.restart_pos = offset;
    }

    /// Allocate space for a file.
    ///
    /// After calling this, append() or put() should be the next command.
    ///
    /// Params:
    ///    bytes =           the number of bytes to allocate
    public void allocate(long bytes)
        in
    {
        assert (bytes > 0);
    }
    body
    {
        char[16] tmp;
        this.sendCommand("ALLO", Integer.format(tmp, bytes));
        auto response = this.readResponse();

        // For our purposes 200 and 202 are both fine.
        if (response.code != "200" && response.code != "202")
            exception (response);
    }

    /// Retrieve a remote file's contents into a local file.
    ///
    /// Calling this function will change the current data transfer format.
    ///
    /// Params:
    ///    path =            the path to the remote file
    ///    local_file =      the path to the local file
    ///    progress =        a delegate to call with progress information
    ///    format =          what format to read the data in
    public void get(char[] path, char[] local_file, FtpProgress progress = null, FtpFormat format = FtpFormat.image)
        in
    {
        assert (path.length > 0);
        assert (local_file.length > 0);
    }
    body
    {
        FileConduit file = null;

        // We may either create a new file...
        if (this.restart_pos == 0)
            file = new FileConduit (local_file, FileConduit.ReadWriteCreate);
        // Or open an existing file, and seek to the specified position (read: not end, necessarily.)
        else
            {
                file = new FileConduit (local_file, FileConduit.ReadWriteExisting);
                file.seek(this.restart_pos);

                this.restart_pos = 0;
            }

        scope (exit)
            {
                file.detach();
                delete file;
            }

        // Now that it's open, we do what we always do.
        this.get(path, file, progress, format);
    }

    /// Retrieve a remote file's contents into a local file.
    ///
    /// Calling this function will change the current data transfer format.
    ///
    /// Params:
    ///    path =            the path to the remote file
    ///    stream =          stream to write the data to
    ///    progress =        a delegate to call with progress information
    ///    format =          what format to read the data in
    public void get(char[] path, OutputStream stream, FtpProgress progress = null, FtpFormat format = FtpFormat.image)
        in
    {
        assert (path.length > 0);
        assert (stream !is null);
    }
    body
    {
        // Change to the specified format.
        this.type(format);

        // Okay server, we want to get this file...
        Socket data = this.processDataCommand("RETR", path);

        // Read the stream in from the socket!
        this.readStream(data, stream, progress);

        this.finishDataCommand(data);
    }

    /// Get information about a single file.
    ///
    /// Return an FtpFileInfo struct about the specified path.
    /// This may not work consistently on directories (but should.)
    ///
    /// Params:
    ///    path =            the file or directory to get information about
    ///
    /// Returns:             the file information
    public FtpFileInfo getFileInfo(char[] path)
        in
    {
        assert (path.length > 0);
    }
    body
    {
        // Start assuming the MLST didn't work.
        bool mlst_success = false;
        FtpResponse response;

        // Check if MLST might be supported...
        if (this.isSupported("MLST"))
            {
                this.sendCommand("MLST", path);
                response = this.readResponse();

                // If we know it was supported for sure, this is an error.
                if (this.is_supported("MLST"))
                    exception (response);
                // Otherwise, it probably means we need to try a LIST.
                else
                    mlst_success = response.code == "250";
            }

        // Okay, we got the MLST response... parse it.
        if (mlst_success)
            {
                char[][] lines = Text.splitLines (response.message);

                // We need at least 3 lines - first and last and header/footer lines.
                // Note that more than 3 could be returned; e.g. multiple lines about the one file.
                if (lines.length <= 2)
                    throw new FTPException("CLIENT: Bad MLST response from server", "501");

                // Return the first line's information.
                return parseMlstLine(lines[1]);
            }
        else
            {
                // Send a list command.  This may list the contents of a directory, even.
                FtpFileInfo[] temp = this.sendListCommand(path);

                // If there wasn't at least one line, the file didn't exist?
                // We should have already handled that.
                if (temp.length < 1)
                    throw new FTPException("CLIENT: Bad LIST response from server", "501");

                // If there are multiple lines, try to return the correct one.
                if (temp.length != 1)
                    foreach (FtpFileInfo info; temp)
                    {
                        if (info.type == FtpFileType.cdir)
                            return info;
                    }

                // Okay then, the first line.  Best we can do?
                return temp[0];
            }
    }

    /// Get a listing of a directory's contents.
    ///
    /// Don't end path in a /.  Blank means the current directory.
    ///
    /// Params:
    ///    path =            the directory to list
    ///
    /// Returns:             an array of the contents
    public FtpFileInfo[] ls(char[] path = "") // default to current dir
        in
    {
        assert (path.length == 0 || path[path.length - 1] != '/');
    }
    body
    {
        FtpFileInfo[] dir;

        // We'll try MLSD (which is so much better) first... but it may fail.
        bool mlsd_success = false;
        Socket data = null;

        // Try it if it could/might/maybe is supported.
        if (this.isSupported("MLST"))
            {
                mlsd_success = true;

                // Since this is a data command, processDataCommand handles
                // checking the response... just catch its Exception.
                try
                    {
                        if (path.length > 0)
                            data = this.processDataCommand("MLSD", path);
                        else
                            data = this.processDataCommand("MLSD");
                    }
                catch (FTPException)
                    mlsd_success = false;
            }

        // If it passed, parse away!
        if (mlsd_success)
            {
                auto listing = new GrowBuffer;
                this.readStream(data, listing);
                this.finishDataCommand(data);

                // Each line is something in that directory.
                char[][] lines = Text.splitLines (cast(char[]) listing.slice());
                scope (exit)
                    delete lines;

                foreach (char[] line; lines)
                    {
                        // Parse each line exactly like MLST does.
                        FtpFileInfo info = this.parseMlstLine(line);
                        if (info.name.length > 0)
                            dir ~= info;
                    }

                return dir;
            }
        // Fall back to LIST.
        else
            return this.sendListCommand(path);
    }

    /// Send a LIST command to determine a directory's content.
    ///
    /// The format of a LIST response is not guaranteed.  If available,
    /// MLSD should be used instead.
    ///
    /// Params:
    ///    path =            the file or directory to list
    ///
    /// Returns:             an array of the contents
    protected FtpFileInfo[] sendListCommand(char[] path)
    {
        FtpFileInfo[] dir;
        Socket data = null;

        if (path.length > 0)
            data = this.processDataCommand("LIST", path);
        else
            data = this.processDataCommand("LIST");

        // Read in the stupid non-standardized response.
        auto listing = new GrowBuffer;
        this.readStream(data, listing);
        this.finishDataCommand(data);

        // Split out the lines.  Most of the time, it's one-to-one.
        char[][] lines = Text.splitLines (cast(char[]) listing.slice());
        scope (exit)
            delete lines;

        foreach (char[] line; lines)
            {
                // If there are no spaces, or if there's only one... skip the line.
                // This is probably like a "total 8" line.
                if (Text.locate(line, ' ') == Text.locatePrior(line, ' '))
                    continue;

                // Now parse the line, or try to.
                FtpFileInfo info = this.parseListLine(line);
                if (info.name.length > 0)
                    dir ~= info;
            }

        return dir;
    }

    /// Parse a LIST response line.
    ///
    /// The format here isn't even specified, so we have to try to detect
    /// commmon ones.
    ///
    /// Params:
    ///    line =            the line to parse
    ///
    /// Returns:             information about the file
    protected FtpFileInfo parseListLine(char[] line)
    {
        FtpFileInfo info;
        size_t pos = 0;

        // Convenience function to parse a word from the line.
        char[] parse_word()
            {
                size_t start = 0, end = 0;

                // Skip whitespace before.
                while (pos < line.length && line[pos] == ' ')
                    pos++;

                start = pos;
                while (pos < line.length && line[pos] != ' ')
                    pos++;
                end = pos;

                // Skip whitespace after.
                while (pos < line.length && line[pos] == ' ')
                    pos++;

                return line[start .. end];
            }

        // We have to sniff this... :/.
        switch (! Text.contains ("0123456789", line[0]))
            {
                // Not a number; this is UNIX format.
            case true:
                // The line must be at least 20 characters long.
                if (line.length < 20)
                    return info;

                // The first character tells us what it is.
                if (line[0] == 'd')
                    info.type = FtpFileType.dir;
                else if (line[0] == '-')
                    info.type = FtpFileType.file;
                else
                    info.type = FtpFileType.unknown;

                // Parse out the mode... rwxrwxrwx = 777.
                char[] unix_mode = "0000".dup;
                void read_mode(int digit)
                    {
                        for (pos = 1 + digit * 3; pos <= 3 + digit * 3; pos++)
                            {
                                if (line[pos] == 'r')
                                    unix_mode[digit + 1] |= 4;
                                else if (line[pos] == 'w')
                                    unix_mode[digit + 1] |= 2;
                                else if (line[pos] == 'x')
                                    unix_mode[digit + 1] |= 1;
                            }
                    }

                // This makes it easier, huh?
                read_mode(0);
                read_mode(1);
                read_mode(2);

                info.facts["UNIX.mode"] = unix_mode;

                // Links, owner, group.  These are hard to translate to MLST facts.
                parse_word();
                parse_word();
                parse_word();

                // Size in bytes, this one is good.
                info.size = toLong(parse_word());

                // Make sure we still have enough space.
                if (pos + 13 >= line.length)
                    return info;

                // Not parsing date for now.  It's too weird (last 12 months, etc.)
                pos += 13;

                info.name = line[pos .. line.length];
                break;

                // A number; this is DOS format.
            case false:
                // We need some data here, to parse.
                if (line.length < 18)
                    return info;

                // The order is 1 MM, 2 DD, 3 YY, 4 HH, 5 MM, 6 P
                auto r = Regex.search(line, `(\d\d)-(\d\d)-(\d\d)\s+(\d\d):(\d\d)(A|P)M`);
                if (r is null)
                    return info;

                if (Timestamp.dostime (r.match(0), info.modify) is 0)
                    info.modify = Time.max;

                pos = r.match(0).length;
                delete r;

                // This will either be <DIR>, or a number.
                char[] dir_or_size = parse_word();

                if (dir_or_size.length < 0)
                    return info;
                else if (dir_or_size[0] == '<')
                    info.type = FtpFileType.dir;
                else
                    info.size = toLong(dir_or_size);

                info.name = line[pos .. line.length];
                break;

                // Something else, not supported.
            default:
                throw new FTPException("CLIENT: Unsupported LIST format", "501");
            }

        // Try to fix the type?
        if (info.name == ".")
            info.type = FtpFileType.cdir;
        else if (info.name == "..")
            info.type = FtpFileType.pdir;

        return info;
    }

    /// Parse an MLST/MLSD response line.
    ///
    /// The format here is very rigid, and has facts followed by a filename.
    ///
    /// Params:
    ///    line =            the line to parse
    ///
    /// Returns:             information about the file
    protected FtpFileInfo parseMlstLine(char[] line)
    {
        FtpFileInfo info;

        // After this loop, filename_pos will be location of space + 1.
        size_t filename_pos = 0;
        while (filename_pos < line.length && line[filename_pos++] != ' ')
            continue;

        if (filename_pos == line.length)
            throw new FTPException("CLIENT: Bad syntax in MLSx response", "501");

        info.name = line[filename_pos .. line.length];

        // Everything else is frosting on top.
        if (filename_pos > 1)
            {
                char[][] temp_facts = Text.delimit(line[0 .. filename_pos - 1], ";");

                // Go through each fact and parse them into the array.
                foreach (char[] fact; temp_facts)
                    {
                        int pos = Text.locate(fact, '=');
                        if (pos == fact.length)
                            continue;

                        info.facts[Ascii.toLower(fact[0 .. pos])] = fact[pos + 1 .. fact.length];
                    }

                // Do we have a type?
                if ("type" in info.facts)
                    {
                        // Some reflection might be nice here.
                        switch (Ascii.toLower(info.facts["type"]))
                            {
                            case "file":
                                info.type = FtpFileType.file;
                                break;

                            case "cdir":
                                info.type = FtpFileType.cdir;
                                break;

                            case "pdir":
                                info.type = FtpFileType.pdir;
                                break;

                            case "dir":
                                info.type = FtpFileType.dir;
                                break;

                            default:
                                info.type = FtpFileType.other;
                            }
                    }

                // Size, mime, etc...
                if ("size" in info.facts)
                    info.size = toLong(info.facts["size"]);
                if ("media-type" in info.facts)
                    info.mime = info.facts["media-type"];

                // And the two dates.
                if ("modify" in info.facts)
                    info.modify = this.parseTimeval(info.facts["modify"]);
                if ("create" in info.facts)
                    info.create = this.parseTimeval(info.facts["create"]);
            }

        return info;
    }

    /// Parse a timeval from an FTP response.
    ///
    /// This is basically an ISO 8601 date, but even more rigid.
    ///
    /// Params:
    ///    timeval =         the YYYYMMDDHHMMSS date
    ///
    /// Returns:             a d_time representing the same date

    protected Time parseTimeval(char[] timeval)
    {
        if (timeval.length < 14)
            throw new FTPException("CLIENT: Unable to parse timeval", "501");

        return Gregorian.generic.toTime (Integer.atoi (timeval[0..4]), 
                                                 Integer.atoi (timeval[4..6]),
                                                 Integer.atoi (timeval[6..8]),
                                                 Integer.atoi (timeval[8..10]),
                                                 Integer.atoi (timeval[10..12]),
                                                 Integer.atoi (timeval[12..14]));
    }

    /// Get the modification time of a file.
    ///
    /// Not supported by a lot of servers.
    ///
    /// Params:
    ///    path =            the file or directory in question
    ///
    /// Returns:             a d_time representing the mtime
    public Time filemtime(char[] path)
        in
    {
        assert (path.length > 0);
    }
    body
    {
        this.sendCommand("MDTM", path);
        auto response = this.readResponse("213");

        // The whole response should be a timeval.
        return this.parseTimeval(response.message);
    }

    /// Create a directory.
    ///
    /// Depending on server model, a cwd with the same path may not work.
    /// Use the return value instead to escape this problem.
    ///
    /// Params:
    ///    path =            the directory to create
    ///
    /// Returns:             the path to the directory created
    public char[] mkdir(char[] path)
        in
    {
        assert (path.length > 0);
    }
    body
    {
        this.sendCommand("MKD", path);
        auto response = this.readResponse("257");

        return this.parse257(response);
    }

    /// Get supported features from the server.
    ///
    /// This may not be supported, in which case the list will remain empty.
    /// Otherwise, it will contain at least FEAT.
    public void getFeatures()
    {
        this.sendCommand("FEAT");
        auto response = this.readResponse();

        // 221 means FEAT is supported, and a list follows.  Otherwise we don't know...
        if (response.code != "211")
            delete this.supported_features;
        else
            {
                char[][] lines = Text.splitLines (response.message);

                // There are two more lines than features, but we also have FEAT.
                this.supported_features = new FtpFeature[lines.length - 1];
                this.supported_features[0].command = "FEAT";

                for (size_t i = 1; i < lines.length - 1; i++)
                    {
                        size_t pos = Text.locate(lines[i], ' ');

                        this.supported_features[i].command = lines[i][0 .. pos];
                        if (pos < lines[i].length - 1)
                            this.supported_features[i].params = lines[i][pos + 1 .. lines[i].length];
                    }

                delete lines;
            }
    }

    /// Check if a specific feature might be supported.
    ///
    /// Example:
    /// ----------
    /// if (ftp.isSupported("SIZE"))
    ///     size = ftp.size("example.txt");
    /// ----------
    ///
    /// Params:
    ///    command =         the command in question
    public bool isSupported(char[] command)
        in
    {
        assert (command.length > 0);
    }
    body
    {
        if (this.supported_features.length == 0)
            return true;

        // Search through the list for the feature.
        foreach (FtpFeature feat; this.supported_features)
            {
                if (Ascii.icompare(feat.command, command) == 0)
                    return true;
            }

        return false;
    }

    /// Check if a specific feature is known to be supported.
    ///
    /// Example:
    /// ----------
    /// if (ftp.is_supported("SIZE"))
    ///     size = ftp.size("example.txt");
    /// ----------
    ///
    /// Params:
    ///    command =         the command in question
    public bool is_supported(char[] command)
    {
        if (this.supported_features.length == 0)
            return false;

        return this.isSupported(command);
    }

    /// Send a site-specific command.
    ///
    /// The command might be WHO, for example, returning a list of users online.
    /// These are typically heavily server-specific.
    ///
    /// Params:
    ///    command =         the command to send (after SITE)
    ///    parameters =      any additional parameters to send
    ///                      (each will be prefixed by a space)
    public FtpResponse siteCommand(char[] command, char[][] parameters ...)
        in
    {
        assert (command.length > 0);
    }
    body
    {
        // Because of the way sendCommand() works, we have to tweak this a bit.
        char[][] temp_params = new char[][parameters.length + 1];
        temp_params[0] = command;
        temp_params[1 .. temp_params.length][] = parameters;

        this.sendCommand("SITE", temp_params);
        auto response = this.readResponse();

        // Check to make sure it didn't fail.
        if (response.code[0] != '2')
            exception (response);

        return response;
    }

    /// Send a NOOP, typically used to keep the connection alive.
    public void noop()
    {
        this.sendCommand("NOOP");
        this.readResponse("200");
    }

    /// Send the stream to the server.
    ///
    /// Params:
    ///    data =            the socket to write to
    ///    stream =          the stream to read from
    ///    progress =        a delegate to call with progress information

    protected void sendStream(Socket data, InputStream stream, FtpProgress progress = null)
        in
    {
        assert (data !is null);
        assert (stream !is null);
    }
    body
    {
        // Set up a SocketSet so we can use select() - it's pretty efficient.
        SocketSet set = new SocketSet();
        scope (exit)
            delete set;

        // At end_time, we bail.
        Time end_time = Clock.now + this.timeout;

        // This is the buffer the stream data is stored in.
        ubyte[8 * 1024] buf;
        size_t buf_size = 0, buf_pos = 0;
        int delta = 0;

        size_t pos = 0;
        bool completed = false;
        while (!completed && Clock.now < end_time)
            {
                set.reset();
                set.add(data);

                // Can we write yet, can we write yet?
                int code = Socket.select(null, set, null, this.timeout);
                if (code == -1 || code == 0)
                    break;

                if (buf_size - buf_pos <= 0)
                    {
                        if ((buf_size = stream.read(buf)) is stream.Eof)
                            buf_size = 0, completed = true;
                        buf_pos = 0;
                    }

                // Send the chunk (or as much of it as possible!)
                delta = data.send(buf[buf_pos .. buf_size]);
                if (delta == data.ERROR)
                    break;

                buf_pos += delta;

                pos += delta;
                if (progress !is null)
                    progress(pos);

                // Give it more time as long as data is going through.
                if (delta != 0)
                    end_time = Clock.now + this.timeout;
            }

        // Did all the data get sent?
        if (!completed)
            throw new FTPException("CLIENT: Timeout when sending data", "420");
    }

    /// Reads from the server to a stream until EOF.
    ///
    /// Params:
    ///    data =            the socket to read from
    ///    stream =          the stream to write to
    ///    progress =        a delegate to call with progress information
    protected void readStream(Socket data, OutputStream stream, FtpProgress progress = null)
        in
    {
        assert (data !is null);
        assert (stream !is null);
    }
    body
    {
        // Set up a SocketSet so we can use select() - it's pretty efficient.
        SocketSet set = new SocketSet();
        scope (exit)
            delete set;

        // At end_time, we bail.
        Time end_time = Clock.now + this.timeout;

        // This is the buffer the stream data is stored in.
        ubyte[8 * 1024] buf;
        int buf_size = 0;

        bool completed = false;
        size_t pos;
        while (Clock.now < end_time)
            {
                set.reset();
                set.add(data);

                // Can we read yet, can we read yet?
                int code = Socket.select(set, null, null, this.timeout);
                if (code == -1 || code == 0)
                    break;

                buf_size = data.receive(buf);
                if (buf_size == data.ERROR)
                    break;

                if (buf_size == 0)
                    {
                        completed = true;
                        break;
                    }

                stream.write(buf[0 .. buf_size]);

                pos += buf_size;
                if (progress !is null)
                    progress(pos);

                // Give it more time as long as data is going through.
                end_time = Clock.now + this.timeout;
            }

        // Did all the data get received?
        if (!completed)
            throw new FTPException("CLIENT: Timeout when reading data", "420");
    }

    /// Parse a 257 response (which begins with a quoted path.)
    ///
    /// Params:
    ///    response =        the response to parse
    ///
    /// Returns:             the path in the response

    protected char[] parse257(FtpResponse response)
    {
        char[] path = new char[response.message.length];
        size_t pos = 1, len = 0;

        // Since it should be quoted, it has to be at least 3 characters in length.
        if (response.message.length <= 2)
            exception (response);

        assert (response.message[0] == '"');

        // Trapse through the response...
        while (pos < response.message.length)
            {
                if (response.message[pos] == '"')
                    {
                        // An escaped quote, keep going.  False alarm.
                        if (response.message[++pos] == '"')
                            path[len++] = response.message[pos];
                        else
                            break;
                    }
                else
                    path[len++] = response.message[pos];

                pos++;
            }

        // Okay, done!  That wasn't too hard.
        path.length = len;
        return path;
    }

    /// Send a command to the FTP server.
    ///
    /// Does not get/wait for the response.
    ///
    /// Params:
    ///    command =         the command to send
    ///    ... =             additional parameters to send (a space will be prepended to each)
    public void sendCommand(char[] command, char[][] parameters ...)
    {
        assert (this.socket !is null);


        char [] socketCommand = command ;

        // Send the command, parameters, and then a CRLF.

        foreach (char[] param; parameters)
            {
                socketCommand ~= " " ~ param;

            }

        socketCommand ~= "\r\n";

        debug(FtpDebug)
            {
                Stdout.formatln("[sendCommand] Sending command '{0}'",socketCommand );
            }
        this.sendData(socketCommand);
    }

    /// Read in response lines from the server, expecting a certain code.
    ///
    /// Params:
    ///    expected_code =   the code expected from the server
    ///
    /// Returns:             the response from the server
    ///
    /// Throws:              FTPException if code does not match
    public FtpResponse readResponse(char[] expected_code)
    {
        debug (FtpDebug ) { Stdout.formatln("[readResponse] Expected Response {0}",expected_code )(); }
        auto response = this.readResponse();
        debug (FtpDebug ) { Stdout.formatln("[readResponse] Actual Response {0}",response.code)(); }

        if (response.code != expected_code)
            exception (response);



        return response;
    }

    /// Read in the response line(s) from the server.
    ///
    /// Returns:             the response from the server
    public FtpResponse readResponse()
    {
        assert (this.socket !is null);

        // Pick a time at which we stop reading.  It can't take too long, but it could take a bit for the whole response.
        Time end_time = Clock.now + this.timeout * 10;

        FtpResponse response;
        char[] single_line = null;

        // Danger, Will Robinson, don't fall into an endless loop from a malicious server.
        while (Clock.now < end_time)
            {
                single_line = this.readLine();


                // This is the first line.
                if (response.message.length == 0)
                    {
                        // The first line must have a code and then a space or hyphen.
                        if (single_line.length <= 4)
                            {
                                response.code[] = "500";
                                break;
                            }

                        // The code is the first three characters.
                        response.code[] = single_line[0 .. 3];
                        response.message = single_line[4 .. single_line.length];
                    }
                // This is either an extra line, or the last line.
                else
                    {
                        response.message ~= "\n";

                        // If the line starts like "123-", that is not part of the response message.
                        if (single_line.length > 4 && single_line[0 .. 3] == response.code)
                            response.message ~= single_line[4 .. single_line.length];
                        // If it starts with a space, that isn't either.
                        else if (single_line.length > 2 && single_line[0] == ' ')
                            response.message ~= single_line[1 .. single_line.length];
                        else
                            response.message ~= single_line;
                    }

                // We're done if the line starts like "123 ".  Otherwise we're not.
                if (single_line.length > 4 && single_line[0 .. 3] == response.code && single_line[3] == ' ')
                    break;
            }

        return response;
    }

    /// convert text to integer
    private int toInt (char[] s)
    {
        return cast(int) toLong (s);
    }

    /// convert text to integer
    private long toLong (char[] s)
    {
        return Integer.parse (s);
    }
}



/// An exception caused by an unexpected FTP response.
///
/// Even after such an exception, the connection may be in a usable state.
/// Use the response code to determine more information about the error.
///
/// Standards:               RFC 959, RFC 2228, RFC 2389, RFC 2428
class FTPException: Exception
{
    /// The three byte response code.
    char[3] response_code = "000";

    /// Construct an FTPException based on a message and code.
    ///
    /// Params:
    ///    message =         the exception message
    ///    code =            the code (5xx for fatal errors)
    this (char[] message, char[3] code = "420")
    {
        this.response_code[] = code;
        super(message);
    }

    /// Construct an FTPException based on a response.
    ///
    /// Params:
    ///    r =               the server response
    this (FtpResponse r)
    {
        this.response_code[] = r.code;
        super(r.message);
    }

    /// A string representation of the error.
    char[] toString()
    {
        char[] buffer = new char[this.msg.length + 4];

        buffer[0 .. 3] = this.response_code;
        buffer[3] = ' ';
        buffer[4 .. buffer.length] = this.msg;

        return buffer;
    }
}


debug (UnitTest )
{
   import tango.io.Stdout;

    unittest
        {

            try
                {
                    /+
                     + TODO: Fix this
                     +
                    auto ftp = new FTPConnection("ftp.gnu.org","anonymous","anonymous");
                    auto dirList = ftp.ls(); // get list for current dir

                    foreach ( entry;dirList )
                        {

                            Stdout("File :")(entry.name)("\tSize :")(entry.size).newline;

                        }

                    ftp.cd("gnu/windows/emacs");


                    dirList = ftp.ls();

                    foreach ( entry;dirList )
                        {

                            Stdout("File :")(entry.name)("\tSize :")(entry.size).newline;

                        }


                    size_t size = ftp.size("emacs-21.3-barebin-i386.tar.gz");

                    void progress( size_t pos )
                        {

                            Stdout.formatln("Byte {0} of {1}",pos,size);

                        }


                    ftp.get("emacs-21.3-barebin-i386.tar.gz","emacs.tgz", &progress);
                     +/
                }
            catch( Object o )
                {
                    assert( false );
                }
        }
}
