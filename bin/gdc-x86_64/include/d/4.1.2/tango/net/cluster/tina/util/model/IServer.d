/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.tina.util.model.IServer;

private import tango.io.model.IConduit;

/******************************************************************************

        Contract to be fulfilled by all Mango servers.

******************************************************************************/

interface IServer
{
        /**********************************************************************

                Provide support for figuring out the remote address

        **********************************************************************/

        char[] getRemoteAddress (IConduit conduit);

        /**********************************************************************

                Provide support for figuring out the remote host. 

        **********************************************************************/

        char[] getRemoteHost (IConduit conduit);

        /**********************************************************************

                Return the protocol in use.

        **********************************************************************/

        char[] getProtocol();

        /**********************************************************************

                Return the local port we're attached to

        **********************************************************************/

        int getPort();

        /**********************************************************************

                Return the local address we're attached to

        **********************************************************************/

        char[] getHost();
}
