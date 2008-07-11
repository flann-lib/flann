/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.tina.RollCall;

private import tango.net.cluster.NetworkMessage;

/******************************************************************************

        An IMessage used by the cluster client and server during discovery 
        lookup and liveness broadcasts. The client broadcasts one of these
        at startup to see which servers are alive. The server responds with
        a reply RollCall stating its name and port. The server will also
        broadcast one of these when it first starts, such that any running
        clients can tell the server has 'recovered'.

        Requests and responses are distinguished by the content of the msg:
        a type value of Request indicates a request from a client and other 
        values are considered to be responses from servers.
         
******************************************************************************/

class RollCall : NetworkMessage
{
        enum {Request, Cache, Queue, Task}

        char[]  addr;           // server name & port pair
        uint    type;           // request, cache, queue, or task server?

        /**********************************************************************

                A request from a client

        **********************************************************************/

        this ()
        {
        }

        /**********************************************************************

                Response from a server

        **********************************************************************/

        this (int type)
        {
                this.type = type;
        }

        /**********************************************************************

                Freeze the content

        **********************************************************************/

        void read (IReader input)
        {
                super.read (input);
                input (addr) (type);
        }

        /**********************************************************************

                Defrost the content

        **********************************************************************/

        void write (IWriter output)
        {
                super.write (output);
                output (addr) (type);
        }
}


