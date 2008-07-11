/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Jan 2007 : initial release
        
        author:         Kris 

*******************************************************************************/

module tango.io.protocol.EndianProtocol;

private import  tango.core.ByteSwap;

private import  tango.io.model.IBuffer,
                tango.io.model.IConduit;

private import  tango.io.protocol.NativeProtocol;

/*******************************************************************************

*******************************************************************************/

class EndianProtocol : NativeProtocol
{
        /***********************************************************************

        ***********************************************************************/

        this (IConduit conduit, bool prefix=true)
        {
                super (conduit, prefix);
        }

        /***********************************************************************

        ***********************************************************************/

        override void[] read (void* dst, uint bytes, Type type)
        {
                auto ret = super.read (dst, bytes, type);

                switch (type)
                       {
                       case Type.Short:
                       case Type.UShort:
                       case Type.Utf16:
                            ByteSwap.swap16 (dst, bytes);    
                            break;

                       case Type.Int:
                       case Type.UInt:
                       case Type.Float:
                       case Type.Utf32:
                            ByteSwap.swap32 (dst, bytes);      
                            break;

                       case Type.Long:
                       case Type.ULong:
                       case Type.Double:
                            ByteSwap.swap64 (dst, bytes);
                            break;

                       case Type.Real:
                            ByteSwap.swap80 (dst, bytes);
                            break;

                       default:
                            break;
                       }

                return ret;
        }
        
        /***********************************************************************

        ***********************************************************************/

        override void write (void* src, uint bytes, Type type)
        {
                alias void function (void* dst, uint bytes) Swapper;
                
                void write (int mask, Swapper mutate)
                {
                        uint writer (void[] dst)
                        {
                                // cap bytes written
                                uint len = dst.length & mask;
                                if (len > bytes)
                                    len = bytes;

                                dst [0..len] = src [0..len];
                                mutate (dst.ptr, len);
                                return len;
                        }

                        while (bytes)
                               if (bytes -= buffer_.write (&writer))
                                   // flush if we used all buffer space
                                   buffer_.drain (buffer.output);
                }


                switch (type)
                       {
                       case Type.Short:
                       case Type.UShort:
                       case Type.Utf16:
                            write (~1, &ByteSwap.swap16);   
                            break;

                       case Type.Int:
                       case Type.UInt:
                       case Type.Float:
                       case Type.Utf32:
                            write (~3, &ByteSwap.swap32);   
                            break;

                       case Type.Long:
                       case Type.ULong:
                       case Type.Double:
                            write (~7, &ByteSwap.swap64);   
                            break;

                       case Type.Real:
                            write (~15, &ByteSwap.swap80);   
                            break;

                       default:
                            super.write (src, bytes, type);
                            break;
                       }
        }
}


/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{
        import tango.io.Buffer;

        unittest
        {
                void[] alloc (EndianProtocol.Reader reader, uint bytes, EndianProtocol.Type type)
                {
                        return reader ((new void[bytes]).ptr, bytes, type);
                }
        
                char[] mule;
                char[] test = "testing testing 123";
                
                auto protocol = new EndianProtocol (new Buffer(32));
                protocol.writeArray (test.ptr, test.length, protocol.Type.Utf8);
                
                mule = cast(char[]) protocol.readArray (mule.ptr, mule.length, protocol.Type.Utf8, &alloc);
                assert (mule == test);

        }
}





