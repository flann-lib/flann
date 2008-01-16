/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mar 2004: Initial release
                        Dec 2006: Outback release

        authors:        Kris
        
*******************************************************************************/

module tango.io.Buffer;

private import  tango.core.Exception;

public  import  tango.io.model.IBuffer,
                tango.io.model.IConduit;

/******************************************************************************

******************************************************************************/

extern (C)
{
        protected void * memcpy (void *dst, void *src, uint);
}       

/*******************************************************************************

        Buffer is central concept in Tango I/O. Each buffer acts
        as a queue (line) where items are removed from the front
        and new items are added to the back. Buffers are modeled 
        by tango.io.model.IBuffer, and a concrete implementation 
        is provided by this class.
        
        Buffer can be read from and written to directly, though 
        various data-converters and filters are often leveraged 
        to apply structure to what might otherwise be simple raw 
        data. 

        Buffers may also be tokenized by applying an Iterator. 
        This can be handy when one is dealing with text input, 
        and/or the content suits a more fluid format than most 
        typical converters support. Iterator tokens are mapped 
        directly onto buffer content (sliced), making them quite 
        efficient in practice. Like other types of buffer client, 
        multiple iterators can be mapped onto one common buffer
        and access will be serialized.

        Buffers are sometimes memory-only, in which case there
        is nothing left to do when a client has consumed all the 
        content. Other buffers are themselves bound to an external
        device called a conduit. When this is the case, a consumer 
        will eventually cause a buffer to reload via its associated 
        conduit and previous buffer content will be lost. 
        
        A similar approach is applied to clients which populate a
        buffer, whereby the content of a full buffer will be flushed
        to a bound conduit before continuing. Another variation is 
        that of a memory-mapped buffer, whereby the buffer content 
        is mapped directly to virtual memory exposed via the OS. This 
        can be used to address large files as an array of content.

        Direct buffer manipulation typically involves appending, 
        as in the following example:
        ---
        // create a small buffer
        auto buf = new Buffer (256);

        auto foo = "to write some D";

        // append some text directly to it
        buf.append ("now is the time for all good men ").append(foo);
        ---

        Alternatively, one might use a formatter to append the buffer:
        ---
        auto output = new FormatOutput (new Buffer(256));
        output.format ("now is the time for {} good men {}", 3, foo);
        ---

        A slice() method will return all valid content within a buffer.
        GrowBuffer can be used instead, where one wishes to append beyond 
        a specified limit. 
        
        A common usage of a buffer is in conjunction with a conduit, 
        such as FileConduit. Each conduit exposes a preferred-size for 
        its associated buffers, utilized during buffer construction:
        ---
        auto file = new FileConduit ("file.name");
        auto buf = new Buffer (file);
        ---

        However, this is typically hidden by higher level constructors 
        such as those exposed via the stream wrappers. For example:
        ---
        auto input = new DataInput (new FileInput("file.name"));
        ---

        There is indeed a buffer between the resultant stream and the 
        file source, but explicit buffer construction is unecessary in 
        common cases. 

        An Iterator is constructed in a similar manner, where you provide 
        it an input stream to operate upon. There's a variety of iterators 
        available in the tango.text.stream package, and they are templated 
        for each of utf8, utf16, and utf32. This example uses a line iterator 
        to sweep a text file:
        ---
        auto lines = new LineInput (new FileInput("file.name"));
        foreach (line; lines)
                 Cout(line).newline;
        ---                 

        Buffers are useful for many purposes within Tango, but there
        are times when it may be more appropriate to sidestep them. For 
        such cases, all conduit derivatives (such as FileConduit) support 
        direct array-based IO via a pair of read() and write() methods. 

*******************************************************************************/

class Buffer : IBuffer
{
        protected OutputStream  sink;           // optional data sink
        protected InputStream   source;         // optional data source
        protected void[]        data;           // the raw data buffer
        protected uint          index;          // current read position
        protected uint          extent;         // limit of valid content
        protected uint          dimension;      // maximum extent of content

        
        protected static char[] overflow  = "output buffer is full";
        protected static char[] underflow = "input buffer is empty";
        protected static char[] eofRead   = "end-of-flow whilst reading";
        protected static char[] eofWrite  = "end-of-flow whilst writing";

        /***********************************************************************
        
                Ensure the buffer remains valid between method calls
                 
        ***********************************************************************/

        invariant 
        {
                assert (index <= extent);
                assert (extent <= dimension);
        }

        /***********************************************************************
        
                Construct a buffer

                Params: 
                conduit = the conduit to buffer

                Remarks:
                Construct a Buffer upon the provided conduit. A relevant 
                buffer size is supplied via the provided conduit.

        ***********************************************************************/

        this (IConduit conduit)
        {
                assert (conduit);

                this (conduit.bufferSize);
                setConduit (conduit);
        }

        /***********************************************************************
        
                Construct a buffer

                Params: 
                stream = an input stream
                capacity = desired buffer capacity

                Remarks:
                Construct a Buffer upon the provided input stream.

        ***********************************************************************/

        this (InputStream stream, uint capacity)
        {
                this (capacity);
                input = stream;
        }

        /***********************************************************************
        
                Construct a buffer

                Params: 
                stream = an output stream
                capacity = desired buffer capacity

                Remarks:
                Construct a Buffer upon the provided output stream.

        ***********************************************************************/

        this (OutputStream stream, uint capacity)
        {
                this (capacity);
                output = stream;
        }

        /***********************************************************************
        
                Construct a buffer

                Params: 
                capacity = the number of bytes to make available

                Remarks:
                Construct a Buffer with the specified number of bytes. 

        ***********************************************************************/

        this (uint capacity = 0)
        {
                setContent (new ubyte[capacity], 0);              
        }

        /***********************************************************************
        
                Construct a buffer

                Params: 
                data = the backing array to buffer within

                Remarks:
                Prime a buffer with an application-supplied array. All content
                is considered valid for reading, and thus there is no writable 
                space initially available.

        ***********************************************************************/

        this (void[] data)
        {
                setContent (data, data.length);
        }

        /***********************************************************************
        
                Construct a buffer

                Params: 
                data =          the backing array to buffer within
                readable =      the number of bytes initially made
                                readable

                Remarks:
                Prime buffer with an application-supplied array, and 
                indicate how much readable data is already there. A
                write operation will begin writing immediately after
                the existing readable content.

                This is commonly used to attach a Buffer instance to 
                a local array.

        ***********************************************************************/

        this (void[] data, uint readable)
        {
                setContent (data, readable);
        }

        /***********************************************************************
        
                Attempt to share an upstream Buffer, and create an instance
                where there not one available.

                Params: 
                stream = an input stream
                size = a hint of the desired buffer size. Defaults to the
                conduit-defined size

                Remarks:
                If an upstream Buffer instances is visible, it will be shared.
                Otherwise, a new instance is created based upon the bufferSize
                exposed by the stream endpoint (conduit).

        ***********************************************************************/

        static IBuffer share (InputStream stream, uint size=uint.max)
        {
                auto b = cast(Buffered) stream;
                if (b)
                    return b.buffer;

                if (size is uint.max)
                    size = stream.conduit.bufferSize;

                return new Buffer (stream, size);
        }

        /***********************************************************************
        
                Attempt to share an upstream Buffer, and create an instance
                where there not one available.

                Params: 
                stream = an output stream
                size = a hint of the desired buffer size. Defaults to the
                conduit-defined size

                Remarks:
                If an upstream Buffer instances is visible, it will be shared.
                Otherwise, a new instance is created based upon the bufferSize
                exposed by the stream endpoint (conduit).

        ***********************************************************************/

        static IBuffer share (OutputStream stream, uint size=uint.max)
        {
                auto b = cast(Buffered) stream;
                if (b)
                    return b.buffer;

                if (size is uint.max)
                    size = stream.conduit.bufferSize;

                return new Buffer (stream, size);
        }

        /***********************************************************************

                Reset the buffer content

                Params: 
                data =  the backing array to buffer within. All content
                        is considered valid

                Returns:
                the buffer instance

                Remarks:
                Set the backing array with all content readable. Writing
                to this will either flush it to an associated conduit, or
                raise an Eof condition. Use clear() to reset the content
                (make it all writable).

        ***********************************************************************/

        IBuffer setContent (void[] data)
        {
                return setContent (data, data.length);
        }

        /***********************************************************************
        
                Reset the buffer content

                Params: 
                data =          the backing array to buffer within
                readable =      the number of bytes within data considered
                                valid

                Returns:
                the buffer instance

                Remarks:
                Set the backing array with some content readable. Writing
                to this will either flush it to an associated conduit, or
                raise an Eof condition. Use clear() to reset the content
                (make it all writable).

        ***********************************************************************/

        IBuffer setContent (void[] data, uint readable)
        {
                this.data = data;
                this.extent = readable;
                this.dimension = data.length;

                // reset to start of input
                this.index = 0;

                return this;            
        }

        /***********************************************************************
        
                Access buffer content

                Params: 
                size =  number of bytes to access
                eat =   whether to consume the content or not

                Returns:
                the corresponding buffer slice when successful, or
                null if there's not enough data available (Eof; Eob).

                Remarks:
                Read a slice of data from the buffer, loading from the
                conduit as necessary. The specified number of bytes is
                sliced from the buffer, and marked as having been read 
                when the 'eat' parameter is set true. When 'eat' is set
                false, the read position is not adjusted.

                Note that the slice cannot be larger than the size of 
                the buffer ~ use method fill(void[]) instead where you
                simply want the content copied, or use conduit.read()
                to extract directly from an attached conduit. Also note 
                that if you need to retain the slice, then it should be 
                .dup'd before the buffer is compressed or repopulated.

                Examples:
                ---
                // create a buffer with some content 
                auto buffer = new Buffer ("hello world");

                // consume everything unread 
                auto slice = buffer.slice (buffer.readable);
                ---

        ***********************************************************************/

        void[] slice (uint size, bool eat = true)
        {   
                if (size > readable)
                   {
                   if (source is null)
                       error (underflow);

                   // make some space? This will try to leave as much content
                   // in the buffer as possible, such that entire records may
                   // be aliased directly from within. 
                   if (size > writable)
                      {
                      if (size > dimension)
                          error (underflow);
                      compress ();
                      }

                   // populate tail of buffer with new content
                   do {
                      if (fill(source) is IConduit.Eof)
                          error (eofRead);
                      } while (size > readable);
                   }

                auto i = index;
                if (eat)
                    index += size;
                return data [i .. i + size];               
        }

        /**********************************************************************

                Fill the provided buffer. Returns the number of bytes
                actually read, which will be less that dst.length when
                Eof has been reached and IConduit.Eof thereafter

        **********************************************************************/

        uint fill (void[] dst)
        {
                uint len = 0;

                while (len < dst.length)
                      {
                      uint i = read (dst [len .. $]);
                      if (i is IConduit.Eof)
                          return (len > 0) ? len : IConduit.Eof;
                      len += i;
                      }
                return len;
        }

        /***********************************************************************

                Copy buffer content into the provided dst

                Params: 
                dst = destination of the content
                bytes = size of dst

                Returns:
                A reference to the populated content

                Remarks:
                Fill the provided array with content. We try to satisfy 
                the request from the buffer content, and read directly
                from an attached conduit where more is required.

        ***********************************************************************/

        void[] readExact (void* dst, uint bytes)
        {
                auto tmp = dst [0 .. bytes];
                if (fill (tmp) != bytes)
                    error (eofRead);

                return tmp;
        }
        
        /***********************************************************************
        
                Append content

                Params:
                src = the content to _append

                Returns a chaining reference if all content was written. 
                Throws an IOException indicating eof or eob if not.

                Remarks:
                Append an array to this buffer, and flush to the
                conduit as necessary. This is often used in lieu of 
                a Writer.

        ***********************************************************************/

        IBuffer append (void[] src)
        {
                return append (src.ptr, src.length);
        }
        
        /***********************************************************************
        
                Append content

                Params:
                src = the content to _append
                length = the number of bytes in src

                Returns a chaining reference if all content was written. 
                Throws an IOException indicating eof or eob if not.

                Remarks:
                Append an array to this buffer, and flush to the
                conduit as necessary. This is often used in lieu of 
                a Writer.

        ***********************************************************************/

        IBuffer append (void* src, uint length)
        {               
                if (length > writable)
                    // can we write externally?
                    if (sink)
                       {
                       flush ();

                       // check for pathological case
                       if (length > dimension)
                          {
                          do {
                             auto written = sink.write (src [0 .. length]);
                             if (written is IConduit.Eof)
                                 error (eofWrite);
                             src += written, length -= written;
                             } while (length > dimension);
                          }
                       }
                    else
                       error (overflow);

                copy (src, length);
                return this;
        }

        /***********************************************************************
        
                Append content

                Params:
                other = a buffer with content available

                Returns:
                Returns a chaining reference if all content was written. 
                Throws an IOException indicating eof or eob if not.

                Remarks:
                Append another buffer to this one, and flush to the
                conduit as necessary. This is often used in lieu of 
                a Writer.

        ***********************************************************************/

        IBuffer append (IBuffer other)        
        {               
                return append (other.slice);
        }

        /***********************************************************************
        
                Consume content from a producer

                Params:
                The content to consume. This is consumed verbatim, and in
                raw binary format ~ no implicit conversions are performed.

                Remarks:
                This is often used in lieu of a Writer, and enables simple
                classes, such as FilePath and Uri, to emit content directly
                into a buffer (thus avoiding potential heap activity)

                Examples:
                ---
                auto path = new FilePath (somepath);

                path.produce (&buffer.consume);
                ---

        ***********************************************************************/

        void consume (void[] x)        
        {   
                append (x);
        }
                    
        /***********************************************************************
        
                Retrieve the valid content

                Returns:
                a void[] slice of the buffer

                Remarks:
                Return a void[] slice of the buffer, from the current position 
                up to the limit of valid content. The content remains in the
                buffer for future extraction.

        ***********************************************************************/

        void[] slice ()
        {       
                return  data [index .. extent];
        }

        /***********************************************************************
        
                Move the current read location

                Params:
                size = the number of bytes to move

                Returns:
                Returns true if successful, false otherwise.

                Remarks:
                Skip ahead by the specified number of bytes, streaming from 
                the associated conduit as necessary.
        
                Can also reverse the read position by 'size' bytes, when size
                is negative. This may be used to support lookahead operations. 
                Note that a negative size will fail where there is not sufficient
                content available in the buffer (can't _skip beyond the beginning).

        ***********************************************************************/

        bool skip (int size)
        {
                if (size < 0)
                   {
                   size = -size;
                   if (index >= size)
                      {
                      index -= size;
                      return true;
                      }
                   return false;
                   }
                return slice(size) !is null;
        }

        /***********************************************************************
        
                Iterator support

                Params:
                scan = the delagate to invoke with the current content

                Returns:
                Returns true if a token was isolated, false otherwise.

                Remarks:
                Upon success, the delegate should return the byte-based 
                index of the consumed pattern (tail end of it). Failure
                to match a pattern should be indicated by returning an
                IConduit.Eof

                Each pattern is expected to be stripped of the delimiter.
                An end-of-file condition causes trailing content to be 
                placed into the token. Requests made beyond Eof result
                in empty matches (length is zero).

                Note that additional iterator and/or reader instances
                will operate in lockstep when bound to a common buffer.

        ***********************************************************************/

        bool next (uint delegate (void[]) scan)
        {
                while (read(scan) is IConduit.Eof)
                       // not found - are we streaming?
                       if (source)
                          {
                          // did we start at the beginning?
                          if (position)
                              // nope - move partial token to start of buffer
                              compress ();
                          else
                             // no more space in the buffer?
                             if (writable is 0)
                                 error ("Token is too large to fit within buffer");

                          // read another chunk of data
                          if (fill(source) is IConduit.Eof)
                              return false;
                          }
                       else
                          return false;

                return true;
        }

        /***********************************************************************
        
                Available content

                Remarks:
                Return count of _readable bytes remaining in buffer. This is 
                calculated simply as limit() - position()

        ***********************************************************************/

        uint readable ()
        {
                return extent - index;
        }               

        /***********************************************************************
        
                Available space

                Remarks:
                Return count of _writable bytes available in buffer. This is 
                calculated simply as capacity() - limit()

        ***********************************************************************/

        uint writable ()
        {
                return dimension - extent;
        }               

        /***********************************************************************

                Write into this buffer

                Params:
                dg = the callback to provide buffer access to

                Returns:
                Returns whatever the delegate returns.

                Remarks:
                Exposes the raw data buffer at the current _write position, 
                The delegate is provided with a void[] representing space
                available within the buffer at the current _write position.

                The delegate should return the appropriate number of bytes 
                if it writes valid content, or IConduit.Eof on error.

        ***********************************************************************/

        uint write (uint delegate (void[]) dg)
        {
                int count = dg (data [extent..dimension]);

                if (count != IConduit.Eof) 
                   {
                   extent += count;
                   assert (extent <= dimension);
                   }
                return count;
        }               

        /***********************************************************************

                Read directly from this buffer

                Params:
                dg = callback to provide buffer access to

                Returns:
                Returns whatever the delegate returns.

                Remarks:
                Exposes the raw data buffer at the current _read position. The
                delegate is provided with a void[] representing the available
                data, and should return zero to leave the current _read position
                intact. 
                
                If the delegate consumes data, it should return the number of 
                bytes consumed; or IConduit.Eof to indicate an error.

        ***********************************************************************/

        uint read (uint delegate (void[]) dg)
        {
                int count = dg (data [index..extent]);
                
                if (count != IConduit.Eof)
                   {
                   index += count;
                   assert (index <= extent);
                   }
                return count;
        }               

        /***********************************************************************

                Compress buffer space

                Returns:
                the buffer instance

                Remarks:
                If we have some data left after an export, move it to 
                front-of-buffer and set position to be just after the 
                remains. This is for supporting certain conduits which 
                choose to write just the initial portion of a request.
                
                Limit is set to the amount of data remaining. Position 
                is always reset to zero.

        ***********************************************************************/

        IBuffer compress ()
        {
                uint r = readable ();

                if (index > 0 && r > 0)
                    // content may overlap ...
                    memcpy (&data[0], &data[index], r);

                index = 0;
                extent = r;
                return this;
        }               

        /***********************************************************************

                Fill buffer from the specific conduit
               
                Returns:
                Returns the number of bytes read, or Conduit.Eof
        
                Remarks:
                Try to _fill the available buffer with content from the 
                specified conduit. We try to read as much as possible 
                by clearing the buffer when all current content has been 
                eaten. If there is no space available, nothing will be 
                read.

        ***********************************************************************/

        uint fill (InputStream src)
        {
                if (src is null)
                    return IConduit.Eof;

                if (readable is 0)
                    index = extent = 0;  // same as clear(), but without chain
                else 
                   if (writable is 0)
                       return 0;

                return write (&src.read);
        } 

        /***********************************************************************

                Drain buffer content to the specific conduit

                Returns:
                Returns the number of bytes written

                Remarks:
                Write as much of the buffer that the associated conduit
                can consume. The conduit is not obliged to consume all 
                content, so some may remain within the buffer.

                Throws an IOException on premature Eof.
        
        ***********************************************************************/

        final uint drain (OutputStream dst)
        {
                if (dst is null)
                    return IConduit.Eof;

                uint ret = read (&dst.write);
                if (ret is IConduit.Eof)
                    error (eofWrite);

                compress ();
                return ret;
        }

        /***********************************************************************
        
                Truncate buffer content

                Remarks:
                Truncate the buffer within its extent. Returns true if
                the new length is valid, false otherwise.

        ***********************************************************************/

        bool truncate (uint length)
        {
                if (length <= data.length)
                   {
                   extent = length;
                   return true;
                   }
                return false;
        }               

        /***********************************************************************
        
                Access buffer limit

                Returns:
                Returns the limit of readable content within this buffer.

                Remarks:
                Each buffer has a capacity, a limit, and a position. The
                capacity is the maximum content a buffer can contain, limit
                represents the extent of valid content, and position marks 
                the current read location.

        ***********************************************************************/

        uint limit ()
        {
                return extent;
        }

        /***********************************************************************
        
                Access buffer capacity

                Returns:
                Returns the maximum capacity of this buffer

                Remarks:
                Each buffer has a capacity, a limit, and a position. The
                capacity is the maximum content a buffer can contain, limit
                represents the extent of valid content, and position marks 
                the current read location.

        ***********************************************************************/

        uint capacity ()
        {
                return dimension;
        }

        /***********************************************************************
        
                Access buffer read position

                Returns:
                Returns the current read-position within this buffer

                Remarks:
                Each buffer has a capacity, a limit, and a position. The
                capacity is the maximum content a buffer can contain, limit
                represents the extent of valid content, and position marks 
                the current read location.

        ***********************************************************************/

        uint position ()
        {
                return index;
        }

        /***********************************************************************
        
                Set external conduit

                Params:
                conduit = the conduit to attach to

                Remarks:
                Sets the external conduit associated with this buffer.

                Buffers do not require an external conduit to operate, but 
                it can be convenient to associate one. For example, methods
                fill() & drain() use it to import/export content as necessary.

        ***********************************************************************/

        IBuffer setConduit (IConduit conduit)
        {
                sink = conduit.output;
                source = conduit.input;
                return this;
        }

        /***********************************************************************
        
                Set output stream

                Params:
                sink = the stream to attach to

                Remarks:
                Sets the external output stream associated with this buffer.

                Buffers do not require an external stream to operate, but 
                it can be convenient to associate one. For example, methods
                fill & drain use them to import/export content as necessary.

        ***********************************************************************/

        final IBuffer output (OutputStream sink)
        {
                this.sink = sink;
                return this;
        }

        /***********************************************************************
        
                Set input stream

                Params:
                source = the stream to attach to

                Remarks:
                Sets the external input stream associated with this buffer.

                Buffers do not require an external stream to operate, but 
                it can be convenient to associate one. For example, methods
                fill & drain use them to import/export content as necessary.

        ***********************************************************************/

        final IBuffer input (InputStream source)
        {
                this.source = source;
                return this;
        }

        /***********************************************************************
                
                Access buffer content

                Remarks:
                Return the entire backing array. Exposed for subclass usage 
                only

        ***********************************************************************/

        protected void[] getContent ()
        {
                return data;
        }

        /***********************************************************************
        
                Copy content into buffer

                Params:
                src = the soure of the content
                size = the length of content at src

                Remarks:
                Bulk _copy of data from 'src'. The new content is made 
                available for reading. This is exposed for subclass use
                only 

        ***********************************************************************/

        protected void copy (void *src, uint size)
        {
                // avoid "out of bounds" test on zero size
                if (size)
                   {
                   // content may overlap ...
                   memcpy (&data[extent], src, size);
                   extent += size;
                   }
        }

        /***********************************************************************

                Cast to a target type without invoking the wrath of the 
                runtime checks for misalignment. Instead, we truncate the 
                array length

        ***********************************************************************/

        static T[] convert(T)(void[] x)
        {
                return (cast(T*) x.ptr) [0 .. (x.length / T.sizeof)];
        }



        /**********************************************************************/
        /*********************** Buffered Interface ***************************/
        /**********************************************************************/

        IBuffer buffer ()
        {
                return this;
        }


        /**********************************************************************/
        /******************** Stream & Conduit Interfaces *********************/
        /**********************************************************************/


        /***********************************************************************
        
                Return the name of this conduit

        ***********************************************************************/

        override char[] toString ()
        {
                return "<buffer>";
        }
                     
        /***********************************************************************
        
                Generic IOException thrower
                
                Params: 
                msg = a text message describing the exception reason

                Remarks:
                Throw an IOException with the provided message

        ***********************************************************************/

        final void error (char[] msg)
        {
                throw new IOException (msg);
        }

        /***********************************************************************
        
                Flush all buffer content to the specific conduit

                Remarks:
                Flush the contents of this buffer. This will block until 
                all content is actually flushed via the associated conduit, 
                whereas drain() will not.

                Do nothing where a conduit is not attached, enabling memory
                buffers to treat flush as a noop.

                Throws an IOException on premature Eof.

        ***********************************************************************/

        override OutputStream flush ()
        {
                if (sink)
                   {
                   while (readable() > 0)
                          drain (sink);

                   // flush the filter chain also
                   sink.flush;
                   }
                return this;
        } 

        /***********************************************************************
        
                Clear buffer content

                Remarks:
                Reset 'position' and 'limit' to zero. This effectively 
                clears all content from the buffer.

        ***********************************************************************/

        override InputStream clear ()
        {
                index = extent = 0;

                // clear the filter chain also
                if (source)
                    source.clear;
                return this;
        }               

        /***********************************************************************
        
                Copy content via this buffer from the provided src
                conduit.

                Remarks:
                The src conduit has its content transferred through 
                this buffer via a series of fill & drain operations, 
                until there is no more content available. The buffer
                content should be explicitly flushed by the caller.

                Throws an IOException on premature eof

        ***********************************************************************/

        override OutputStream copy (InputStream src)
        {
                while (fill(src) != IConduit.Eof)
                       // don't drain until we actually need to
                       if (writable is 0)
                           if (sink)
                               drain (sink);
                           else
                              error (overflow);
                return this;
        } 

        /***********************************************************************

                Transfer content into the provided dst

                Params: 
                dst = destination of the content

                Returns:
                return the number of bytes read, which may be less than
                dst.length. Eof is returned when no further content is
                available.

                Remarks:
                Populates the provided array with content. We try to 
                satisfy the request from the buffer content, and read 
                directly from an attached conduit when the buffer is 
                empty.

        ***********************************************************************/

        override uint read (void[] dst)
        {   
                uint content = readable();
                if (content)
                   {
                   if (content >= dst.length)
                       content = dst.length;

                   // transfer buffer content
                   dst [0 .. content] = data [index .. index + content];
                   index += content;
                   }
                else
                   if (source) 
                      {
                      // pathological cases read directly from conduit
                      if (dst.length > dimension) 
                          content = source.read (dst);
                      else
                         // keep buffer partially populated
                         if ((content = fill(source)) != IConduit.Eof && content > 0)
                              content = read (dst);
                      }
                   else
                      content = IConduit.Eof;
                return content;
        }

        /***********************************************************************

                Emulate OutputStream.write()

                Params: 
                src = the content to write

                Returns:
                return the number of bytes written, which may be less than
                provided (conceptually).

                Remarks:
                Appends src content to the buffer, flushing to an attached
                conduit as necessary. An IOException is thrown upon write 
                failure.

        ***********************************************************************/

        override uint write (void[] src)
        {   
                append (src.ptr, src.length);
                return src.length;
        }

        /***********************************************************************
        
                Access configured conduit

                Returns:
                Returns the conduit associated with this buffer. Returns 
                null if the buffer is purely memory based; that is, it's
                not backed by some external medium.

                Remarks:
                Buffers do not require an external conduit to operate, but 
                it can be convenient to associate one. For example, methods
                fill() & drain() use it to import/export content as necessary.

        ***********************************************************************/

        final override IConduit conduit ()
        {
                if (sink)
                    return sink.conduit;
                else
                   if (source)
                       return source.conduit;
                return this;
        }

        /***********************************************************************
        
                Return a preferred size for buffering conduit I/O

        ***********************************************************************/

        final override uint bufferSize ()
        {
                return 32 * 1024;
        }
                     
        /***********************************************************************

                Is the conduit alive?

        ***********************************************************************/

        final override bool isAlive ()
        {       
                return true;
        }

        /***********************************************************************
        
                Exposes configured output stream

                Returns:
                Returns the OutputStream associated with this buffer. Returns 
                null if the buffer is not attached to an output; that is, it's
                not backed by some external medium.

                Remarks:
                Buffers do not require an external stream to operate, but 
                it can be convenient to associate them. For example, methods
                fill & drain use them to import/export content as necessary.

        ***********************************************************************/

        final OutputStream output ()
        {
                return sink;
        }

        /***********************************************************************
        
                Exposes configured input stream

                Returns:
                Returns the InputStream associated with this buffer. Returns 
                null if the buffer is not attached to an input; that is, it's
                not backed by some external medium.

                Remarks:
                Buffers do not require an external stream to operate, but 
                it can be convenient to associate them. For example, methods
                fill & drain use them to import/export content as necessary.

        ***********************************************************************/

        final InputStream input ()
        {
                return source;
        }

        /***********************************************************************
                
                Release external resources

        ***********************************************************************/

        final override void detach ()
        {
        }

        /***********************************************************************
        
                Close the stream

                Remarks:
                Propagate request to an attached OutputStream (this is a
                requirement for the OutputStream interface)

        ***********************************************************************/

        override void close () 
        {
                if (sink)
                    sink.close;
                else
                   if (source)
                       source.close;
        }
}
