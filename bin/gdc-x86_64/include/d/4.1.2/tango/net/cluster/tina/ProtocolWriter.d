/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.tina.ProtocolWriter;

private import  tango.io.protocol.Writer,
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

        Everything is written in Network order (big endian)

*******************************************************************************/

class ProtocolWriter
{
        private Writer  emit;
        package IBuffer buffer;
        
        const ubyte Version = 0x01;

        /***********************************************************************
        
                protocol commands

        ***********************************************************************/

        enum Command : ubyte 
             {
             OK, 
             Exception, 
             Full, 
             Locked, 
             Add, 
             Copy, 
             Remove, 
             Load, 
             AddQueue, 
             RemoveQueue, 
             Call
             }

        /***********************************************************************
        
                Construct a ProtocolWriter upon the given buffer. As
                Objects are serialized, their content is written to this
                buffer. The buffer content is then typically flushed to 
                some external conduit, such as a file or socket.

                Note that serialized data is always in Network order.

        ***********************************************************************/
        
        this (IBuffer buffer)
        {
                assert (buffer);
                emit = new Writer (new PickleProtocol(this.buffer = buffer));
        }

        /***********************************************************************
        
                Stuff the request into our output buffer. Note that this
                protocol is prefixed by a 'size' value, requiring that
                all messages can be contained within the buffer. This is
                not considered a serious limitation, as the messages are
                not intended to be "large" given that they're traversing 
                the network.

        ***********************************************************************/

        ProtocolWriter put (Command cmd, char[] channel, char[] element = null, IMessage msg = null)
        {
                auto time = (msg ? msg.time : Time.init);
        
                // reset the buffer first!
                buffer.clear;

                auto content = cast(ubyte[]) buffer.getContent;
                emit (cast(ushort) 0)
                     (cast(ubyte) cmd)
                     (cast(ubyte) Version)
                     (cast(ulong) time.ticks)
                     (channel)
                     (element);

                // is there a payload?
                if (msg)
                    NetworkRegistry.shared.freeze (emit, msg);

                // go back and write the total number of bytes
                auto size = buffer.limit;
                content[0] = cast(ubyte) (size >> 8);
                content[1] = cast(ubyte) (size & 0xff);
                return this;
        }

        /***********************************************************************
        
                Emit a ClusterContent constructed by ProtocolReader.getPacket

        ***********************************************************************/

        ProtocolWriter reply (ClusterContent content)
        {
                uint empty = 0;

                // reset the buffer first
                buffer.clear;

                // write the length, the ack, version, and timestamp
                emit (cast(ushort) (content.length + ushort.sizeof + ubyte.sizeof + ubyte.sizeof + ulong.sizeof))
                     (cast(ubyte) ProtocolWriter.Command.OK)
                     (cast(ubyte) Version)
                     (cast(ulong) ulong.init);

                // and the payload (which includes both channel & element)
                if (content.length)
                    buffer.append (content);
                else
                   // or filler for an empty channel & element ...
                   emit (empty) (empty);

                return this;
        }

        /***********************************************************************
        
                Write an exception message

        ***********************************************************************/

        ProtocolWriter exception (char[] message)
        {
                return put (ProtocolWriter.Command.Exception, message);
        }

        /***********************************************************************
                
                Write an "OK" confirmation

        ***********************************************************************/

        ProtocolWriter success (char[] message = null)
        {
                return put (ProtocolWriter.Command.OK, message);
        }

        /***********************************************************************
                
                Indicate something has filled up

        ***********************************************************************/

        ProtocolWriter full (char[] message)
        {
                return put (ProtocolWriter.Command.Full, message);
        }

        /***********************************************************************
                
                Flush the output
        
        ***********************************************************************/

        void flush () 
        {
                emit.flush;
        }
}

