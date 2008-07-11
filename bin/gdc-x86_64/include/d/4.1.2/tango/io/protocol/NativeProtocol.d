/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Jan 2007 : initial release
        
        author:         Kris 

*******************************************************************************/

module tango.io.protocol.NativeProtocol;

private import  tango.io.Buffer;

private import  tango.io.protocol.model.IProtocol;

/*******************************************************************************

*******************************************************************************/

class NativeProtocol : IProtocol
{
        protected bool          prefix_;
        protected IBuffer       buffer_;

        /***********************************************************************

        ***********************************************************************/

        this (IConduit conduit, bool prefix=true)
        {
                this.prefix_ = prefix;

                auto b = cast(Buffered) conduit;
                buffer_ = b ? b.buffer : new Buffer(conduit);
        }

        /***********************************************************************

        ***********************************************************************/

        IBuffer buffer ()
        {
                return buffer_;
        }

        /***********************************************************************

        ***********************************************************************/

        void[] read (void* dst, uint bytes, Type type)
        {
                return buffer_.readExact (dst, bytes);
        }
        
        /***********************************************************************

        ***********************************************************************/

        void write (void* src, uint bytes, Type type)
        {
                buffer_.append (src, bytes);
        }
        
        /***********************************************************************

        ***********************************************************************/

        void[] readArray (void* dst, uint bytes, Type type, Allocator alloc)
        {
                if (prefix_)
                   {
                   read (&bytes, bytes.sizeof, Type.UInt);
                   return alloc (&read, bytes, type); 
                   }

                return read (dst, bytes, type);
        }
        
        /***********************************************************************

        ***********************************************************************/

        void writeArray (void* src, uint bytes, Type type)
        {
                if (prefix_)
                    write (&bytes, bytes.sizeof, Type.UInt);

                write (src, bytes, type);
        }
}



/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{
        import tango.io.Buffer;
        import tango.io.protocol.Writer;
        import tango.io.protocol.Reader;
        import tango.io.protocol.NativeProtocol;
        
        unittest
        {
                auto protocol = new NativeProtocol (new Buffer(32));
                auto input  = new Reader (protocol);
                auto output = new Writer (protocol);

                char[] foo;
                output ("testing testing 123"c);
                input (foo);
                assert (foo == "testing testing 123");
        }
}

   