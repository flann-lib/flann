/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: October 2004      
                        Outback release: December 2006
        
        author:         Kris

        Allocators to use in conjunction with the Reader class. These are
        intended to manage array allocation for a variety of Reader.get()
        methods

*******************************************************************************/

module tango.io.protocol.Allocator;

private import  tango.io.protocol.model.IProtocol;


/*******************************************************************************

        Simple allocator, copying into the heap for each array requested:
        this is the default behaviour for Reader instances
        
*******************************************************************************/

class HeapCopy : IAllocator
{
        private IProtocol protocol_;

        /***********************************************************************
        
        ***********************************************************************/

        this (IProtocol protocol)
        {
                protocol_ = protocol;
        }

        /***********************************************************************
        
        ***********************************************************************/

        final IProtocol protocol ()
        {
                return protocol_;
        }

        /***********************************************************************
        
        ***********************************************************************/

        final void reset ()
        {
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        final void[] allocate (IProtocol.Reader reader, uint bytes, IProtocol.Type type)
        {
                return reader ((new void[bytes]).ptr, bytes, type);
        }
}


/*******************************************************************************

        Allocate from within a private heap space. This supports reading
        data as 'records', reusing the same chunk of memory for each record
        loaded. The ctor takes an argument defining the initial allocation
        made, and this will be increased as necessary to accomodate larger
        records. Use the reset() method to indicate end of record (reuse
        memory for subsequent requests), or set the autoreset flag to reuse
        upon each array request.
        
*******************************************************************************/

class HeapSlice : IAllocator
{
        private uint            used;
        private void[]          buffer;
        private IProtocol       protocol_;
        private bool            autoreset;

        /***********************************************************************
        
        ***********************************************************************/

        this (IProtocol protocol, uint width=4096, bool autoreset=false)
        {
                protocol_ = protocol;
                buffer = new void[width];
                this.autoreset = autoreset;
        }

        /***********************************************************************
        
        ***********************************************************************/

        final IProtocol protocol ()
        {
                return protocol_;
        }

        /***********************************************************************
        
                Reset content length to zero

        ***********************************************************************/

        final void reset ()
        {
                used = 0;
        }

        /***********************************************************************
        
                No allocation: copy into a reserved arena.

                With HeapSlice, it is normal to allocate space large
                enough to contain, say, a record of data. The reserved
                space will grow to accomodate larger records. A reset()
                call should be made between each record read, to ensure
                the space is being reused.
                
        ***********************************************************************/

        final void[] allocate (IProtocol.Reader reader, uint bytes, IProtocol.Type type)
        {
                if (autoreset)
                    used = 0;
                
                if ((used + bytes) > buffer.length)
                     buffer.length = (used + bytes) * 2;
                
                auto ptr = &buffer[used];
                used += bytes;
                
                return reader (ptr, bytes, type);
        }
}


/*******************************************************************************

        Alias directly from the buffer instead of allocating from the heap.
        This avoids both heap activity and copying, but requires some care
        in terms of usage. See methods allocate() for details
        
*******************************************************************************/

class BufferSlice : IAllocator
{
        private IProtocol protocol_;

        /***********************************************************************
        
        ***********************************************************************/

        this (IProtocol protocol)
        {
                protocol_ = protocol;
        }

        /***********************************************************************
        
        ***********************************************************************/

        final IProtocol protocol ()
        {
                return protocol_;
        }

        /***********************************************************************

                Move all unconsumed data to the front of the buffer, freeing
                up space for more
                
        ***********************************************************************/

        final void reset ()
        {
                protocol.buffer.compress;
        }
        
        /***********************************************************************
        
                No alloc or copy: alias directly from buffer. While this is
                very efficient (no heap activity) it should be used only in
                scenarios where content is known to fit within a buffer, and
                there is no conversion of said content e.g. take care when
                using with EndianProtocol since it will convert within the
                buffer, potentially confusing additional buffer clients.

                With BufferSlice, it is considered normal to create a Buffer
                large enough to contain, say, a file and subsequently slice
                all strings/arrays directly from this buffer. Smaller Buffers
                can be used in a record-oriented manner similar to HeapSlice:
                invoke reset() before each record is processed to ensure here
                is sufficient space available in the buffer to house a complete
                record. GrowBuffer could be used in the latter case, to ensure
                the largest record width is always accomodated.

                A good use of this is in handling of network traffic, where
                incoming data is often transient and of a known extent. For
                another potential use, consider the quantity of distinct text
                arrays generated by an XML parser -- would be convenient to
                slice all of them from a single allocation instead
               
        ***********************************************************************/

        final void[] allocate (IProtocol.Reader reader, uint bytes, IProtocol.Type type)
        {
                return protocol_.buffer.slice (bytes);
        }
}
