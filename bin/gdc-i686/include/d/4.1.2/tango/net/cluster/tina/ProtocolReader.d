/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.tina.ProtocolReader;

private import  tango.io.protocol.Reader,
                tango.io.protocol.Allocator,
                tango.io.protocol.PickleProtocol;

private import  tango.net.cluster.model.IMessage;

private import  tango.net.cluster.NetworkRegistry;

private import  tango.net.cluster.tina.ClusterTypes;

/*******************************************************************************
        
        Objects passed around a cluster are prefixed with a header, so the 
        receiver can pick them apart correctly. This header consists of:
        ---
                * the packet size, including the header (16 bits)
                * a command code (8 bits)
                * a version id (8 bits)
                * a timestamp (64 bits)
                * length of the channel name (32 bits)
                * the channel name
                * length of the key (32 bits)
                * the key
                * an optional payload (an IMessage instance)
        ---

        Everything is written in Network order (big endian).

*******************************************************************************/

class ProtocolReader : Reader
{
        /***********************************************************************
        
                Construct a ProtocolReader upon the given buffer. As
                Objects are serialized their content is written to this
                buffer. The buffer content is then typically flushed to 
                some external conduit, such as a file or socket.

                Note that arrays (such as text) are *always* sliced from
                the buffer -- there's no heap activity involved. Thus it
                may be necessary to .dup content where appropriate

        ***********************************************************************/
        
        this (IBuffer buffer)
        {
                super (new BufferSlice (new PickleProtocol (buffer)));
        }

        /***********************************************************************

                deserialize a payload into a provided host, or via
                the registered instance of the incoming payload
                        
        ***********************************************************************/

        IMessage thaw (IMessage host = null)
        {
                return thaw (NetworkRegistry.shared, host);                
        }

        /***********************************************************************

                deserialize a payload into a provided host, or via
                the registered instance of the incoming payload
                        
        ***********************************************************************/

        IMessage thaw (NetworkRegistry registry, IMessage host = null)
        {
                return registry.thaw (this, host);                
        }

        /***********************************************************************
        
                Read the protocol header and return true if there's a 
                payload available

        ***********************************************************************/

        bool getHeader (inout ubyte cmd, inout char[] channel, inout char[] element)
        {
                auto position = buffer.position;

                long   time;
                ushort size;
                ubyte  versn;

                get (size) (cmd) (versn) (time);

                // avoid allocation for these two strings
                get (channel) (element);

                // is there a payload attached?
                if (size > (buffer.position - position))
                    return true;

                return false;
        }

        /***********************************************************************
        
                Return an aliased slice of the buffer representing the 
                recieved payload. This is a bit of a hack, but eliminates
                a reasonable amount of overhead. Note that the channel/key
                text is retained right at the start of the returned content, 
                enabling the host to toss the whole thing back without any 
                further munging. 

        ***********************************************************************/

        ClusterContent getPacket (inout ubyte cmd, inout char[] channel, inout char[] element, inout long time)
        {
                ushort  size;
                ubyte   versn;

                // load up the header
                get (size) (cmd) (versn) (time);

                //printf ("size: %d\n", cast(int) size);

                // subtract header size
                size -= buffer.position;
                
                // may throw an exception if the payload is too large to fit
                // completely inside the buffer!
                buffer.slice (size, false);

                // slice the remaining packet (with channel/key text)
                auto content = cast(ClusterContent) buffer.slice;

                // get a slice upon the channel name
                get (channel);

                // get a slice upon the element name
                get (element);

                // return the aliased payload (including channel/key text)
                return content;
        }
}

