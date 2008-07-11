/*******************************************************************************

        copyright:      Copyright (c) 2008 Jeff Davey. All rights reserved

        license:        BSD style: $(LICENSE)

        author:         Jeff Davey <j@submersion.com>

*******************************************************************************/

module tango.net.SSLServerSocket;

import tango.net.SSLSocketConduit;
import tango.net.SocketConduit;
import tango.net.InternetAddress;
import tango.net.ServerSocket;
import tango.net.PKI;

/*******************************************************************************

    SSLServerSocket is a sub-class of ServerSocket. It's purpose is to provide
    SSL encryption at the socket level as well as easily tie into existing 
    Tango applications that may already be using ServerSocket.

    SSLServerSocket requires the OpenSSL library, and uses a dynamic binding
    to the library. You can find the library at http://www.openssl.org and a
    Win32 specific port at http://www.slproweb.com/products/Win32OpenSSL.html.

    Example
    ---
    auto cert = new Certificate(cast(char[])File("public.pem").read);
    auto pkey = new PrivateKey(cast(char[])File("private.pem").read);
    auto ctx = new SSLCtx();
    ctx.certificate(cert).privateKey(pkey);
    auto server = new SSLServerSocket(new InternetAddress(443), ctx);
    for(;;)
    {
        auto sslSock = server.accept();
        sc.write("HTTP/1.1 200\r\n\r\n<b>Hello World</b>");
        sc.shutdown();
        sc.close();
    }
    ---

*******************************************************************************/

class SSLServerSocket : ServerSocket
{
    private SSLCtx sslCtx;

    /*******************************************************************************

        Constructs a new SSLServerSocket. This constructor is similar to 
        ServerSocket, except it takes a SSLCtx as provided by PKI.

        Params:
            addr = the address to bind and listen on.
            ctx = the provided SSLCtx
            backlog = the number of connections to backlog before refusing connection
            reuse = if enabled, allow rebinding of existing ip/port

    *******************************************************************************/

    this(InternetAddress addr, SSLCtx ctx, int backlog=32, bool reuse=false)
    {
        super(addr, backlog, reuse);
        sslCtx = ctx;
    }

    /*******************************************************************************

      This is used during the super.accept() in order to provide the proper
      SSLSocketConduit. It allocates using the free-list provided with
      SSLSocketConduit.

    *******************************************************************************/

    override SSLSocketConduit create()
    {
        return SSLSocketConduit.allocate();
    }

    /*******************************************************************************

      Accepts a new conection and copies the provided server SSLCtx to a new
      SSLSocketConduit.

    *******************************************************************************/

    SSLSocketConduit accept()
    {
        SSLSocketConduit rtn = cast(SSLSocketConduit)super.accept();
        rtn.setCtx(sslCtx, false);
        return rtn;
    }
}
