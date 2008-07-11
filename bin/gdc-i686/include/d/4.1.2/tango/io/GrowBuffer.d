/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: March 2004
        
        author:         Kris

*******************************************************************************/

module tango.io.GrowBuffer;

private import  tango.io.Buffer;

public  import  tango.io.model.IBuffer;

/*******************************************************************************

        Subclass to provide support for content growth. This is handy when
        you want to keep a buffer around as a scratchpad.

*******************************************************************************/

class GrowBuffer : Buffer
{
        private uint increment;

        alias Buffer.slice  slice;
        alias Buffer.append append; 

        /***********************************************************************
        
                Create a GrowBuffer with the specified initial size.

        ***********************************************************************/

        this (uint size = 1024, uint increment = 1024)
        {
                super (size);

                assert (increment >= 32);
                this.increment = increment;
        }

        /***********************************************************************
        
                Create a GrowBuffer with the specified initial size.

        ***********************************************************************/

        this (IConduit conduit, uint size = 1024)
        {
                this (size, size);
                setConduit (conduit);
        }

        /***********************************************************************
        
                Read a chunk of data from the buffer, loading from the
                conduit as necessary. The specified number of bytes is
                loaded into the buffer, and marked as having been read 
                when the 'eat' parameter is set true. When 'eat' is set
                false, the read position is not adjusted.

                Returns the corresponding buffer slice when successful.

        ***********************************************************************/

        override void[] slice (uint size, bool eat = true)
        {   
                if (size > readable)
                   {
                   if (source is null)
                       error (underflow);

                   if (size + index > dimension)
                       makeRoom (size);

                   // populate tail of buffer with new content
                   do {
                      if (fill(source) is IConduit.Eof)
                          error (eofRead);
                      } while (size > readable);
                   }

                uint i = index;
                if (eat)
                    index += size;
                return data [i .. i + size];               
        }

        /***********************************************************************
        
                Append an array of data to this buffer. This is often used 
                in lieu of a Writer.

        ***********************************************************************/

        override IBuffer append (void *src, uint length)        
        {               
                if (length > writable)
                    makeRoom (length);

                copy (src, length);
                return this;
        }

        /***********************************************************************

                Try to fill the available buffer with content from the 
                specified conduit. 

                Returns the number of bytes read, or IConduit.Eof
        
        ***********************************************************************/

        override uint fill (InputStream src)
        {
                if (writable <= increment/8)
                    makeRoom (increment);

                return write (&src.read);
        } 

        /***********************************************************************
        
                Expand and consume the conduit content, up to the maximum 
                size indicated by the argument or until conduit.Eof

                Returns the number of bytes in the buffer

        ***********************************************************************/

        uint fill (uint size = uint.max)
        {   
                while (readable < size)
                       if (fill(source) is IConduit.Eof)
                           break;
                return readable;
        }

        /***********************************************************************

                make some room in the buffer
                        
        ***********************************************************************/

        private uint makeRoom (uint size)
        {
                if (size < increment)
                    size = increment;

                dimension += size;
                data.length = dimension;               
                return writable();
        }
}
