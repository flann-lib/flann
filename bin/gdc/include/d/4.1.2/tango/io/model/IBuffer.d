/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mar 2004: Initial release
                        Dec 2006: Outback release
        
        author:         Kris

*******************************************************************************/

module tango.io.model.IBuffer;

private import tango.io.model.IConduit;

/*******************************************************************************

        Buffer is central concept in Tango I/O. Each buffer acts
        as a queue (line) where items are removed from the front
        and new items are added to the back. Buffers are modeled 
        by this interface and implemented in various ways.
        
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

        See tango.io.Buffer for more info.

*******************************************************************************/

abstract class IBuffer : IConduit, Buffered
{
        alias append opCall;
        alias flush  opCall;
      
        /***********************************************************************
                
                implements Buffered interface

        ***********************************************************************/

        abstract IBuffer buffer ();

        /***********************************************************************
                
                Return the backing array

        ***********************************************************************/

        abstract void[] getContent ();

        /***********************************************************************
        
                Return a void[] slice of the buffer up to the limit of
                valid content.

        ***********************************************************************/

        abstract void[] slice ();

        /***********************************************************************
        
                Set the backing array with all content readable. Writing
                to this will either flush it to an associated conduit, or
                raise an Eof condition. Use IBuffer.clear() to reset the
                content (make it all writable).

        ***********************************************************************/

        abstract IBuffer setContent (void[] data);

        /***********************************************************************
        
                Set the backing array with some content readable. Writing
                to this will either flush it to an associated conduit, or
                raise an Eof condition. Use IBuffer.clear() to reset the
                content (make it all writable).

        ***********************************************************************/

        abstract IBuffer setContent (void[] data, uint readable);

        /***********************************************************************

                Append an array of data into this buffer, and flush to the
                conduit as necessary. Returns a chaining reference if all 
                data was written; throws an IOException indicating eof or 
                eob if not.

                This is often used in lieu of a Writer.

        ***********************************************************************/

        abstract IBuffer append (void* content, uint length);

        /***********************************************************************

                Append an array of data into this buffer, and flush to the
                conduit as necessary. Returns a chaining reference if all 
                data was written; throws an IOException indicating eof or 
                eob if not.

                This is often used in lieu of a Writer.

        ***********************************************************************/

        abstract IBuffer append (void[] content);

        /***********************************************************************
        
                Append another buffer to this one, and flush to the
                conduit as necessary. Returns a chaining reference if all 
                data was written; throws an IOException indicating eof or 
                eob if not.

                This is often used in lieu of a Writer.

        ***********************************************************************/

        abstract IBuffer append (IBuffer other);

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

        abstract void consume (void[] src);

        /***********************************************************************

                Read a chunk of data from the buffer, loading from the
                conduit as necessary. The requested number of bytes are
                loaded into the buffer, and marked as having been read 
                when the 'eat' parameter is set true. When 'eat' is set
                false, the read position is not adjusted.

                Returns the corresponding buffer slice when successful, 
                or null if there's not enough data available (Eof; Eob).

        ***********************************************************************/

        abstract void[] slice (uint size, bool eat = true);

        /***********************************************************************

                Access buffer content

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

        abstract void[] readExact (void* dst, uint bytes);
        
        /**********************************************************************

                Fill the provided buffer. Returns the number of bytes
                actually read, which will be less than dst.length when
                Eof has been reached and IConduit.Eof thereafter.

        **********************************************************************/

        abstract uint fill (void[] dst);

        /***********************************************************************

                Exposes the raw data buffer at the current write position, 
                The delegate is provided with a void[] representing space
                available within the buffer at the current write position.

                The delegate should return the approriate number of bytes 
                if it writes valid content, or IConduit.Eof on error.

                Returns whatever the delegate returns.

        ***********************************************************************/

        abstract uint write (uint delegate (void[]) writer);

        /***********************************************************************

                Exposes the raw data buffer at the current read position. The
                delegate is provided with a void[] representing the available
                data, and should return zero to leave the current read position
                intact. 
                
                If the delegate consumes data, it should return the number of 
                bytes consumed; or IConduit.Eof to indicate an error.

                Returns whatever the delegate returns.

        ***********************************************************************/

        abstract uint read (uint delegate (void[]) reader);

        /***********************************************************************

                If we have some data left after an export, move it to 
                front-of-buffer and set position to be just after the 
                remains. This is for supporting certain conduits which 
                choose to write just the initial portion of a request.
                            
                Limit is set to the amount of data remaining. Position 
                is always reset to zero.

        ***********************************************************************/

        abstract IBuffer compress ();

        /***********************************************************************
        
                Skip ahead by the specified number of bytes, streaming from 
                the associated conduit as necessary.
        
                Can also reverse the read position by 'size' bytes. This may
                be used to support lookahead-type operations.

                Returns true if successful, false otherwise.

        ***********************************************************************/

        abstract bool skip (int size);

        /***********************************************************************

                Support for tokenizing iterators. 
                
                Upon success, the delegate should return the byte-based 
                index of the consumed pattern (tail end of it). Failure
                to match a pattern should be indicated by returning an
                IConduit.Eof.

                Each pattern is expected to be stripped of the delimiter.
                An end-of-file condition causes trailing content to be 
                placed into the token. Requests made beyond Eof result
                in empty matches (length == zero).

                Note that additional iterator and/or reader instances
                will stay in lockstep when bound to a common buffer.

                Returns true if a token was isolated, false otherwise.

        ***********************************************************************/

        abstract bool next (uint delegate (void[]));

        /***********************************************************************

                Try to _fill the available buffer with content from the 
                specified conduit. We try to read as much as possible 
                by clearing the buffer when all current content has been 
                eaten. If there is no space available, nothing will be 
                read.

                Returns the number of bytes read, or Conduit.Eof.
        
        ***********************************************************************/

        abstract uint fill (InputStream src);

        /***********************************************************************

                Write as much of the buffer that the associated conduit
                can consume.

                Returns the number of bytes written, or Conduit.Eof.
        
        ***********************************************************************/

        abstract uint drain (OutputStream dst);

        /***********************************************************************
        
                Truncate the buffer within its extent. Returns true if
                the new 'extent' is valid, false otherwise.

        ***********************************************************************/

        abstract bool truncate (uint extent);

        /***********************************************************************
        
                Return count of readable bytes remaining in buffer. This is 
                calculated simply as limit() - position().

        ***********************************************************************/

        abstract uint readable ();               

        /***********************************************************************
        
                Return count of writable bytes available in buffer. This is 
                calculated simply as capacity() - limit().

        ***********************************************************************/

        abstract uint writable ();

        /***********************************************************************
        
                Returns the limit of readable content within this buffer.

        ***********************************************************************/

        abstract uint limit ();               

        /***********************************************************************
        
                Returns the total capacity of this buffer.

        ***********************************************************************/

        abstract uint capacity ();               

        /***********************************************************************
        
                Returns the current position within this buffer.

        ***********************************************************************/

        abstract uint position ();               

        /***********************************************************************
        
                Sets the external conduit associated with this buffer.

                Buffers do not require an external conduit to operate, but 
                it can be convenient to associate one. For example, methods
                read and write use it to import/export content as necessary.

        ***********************************************************************/

        abstract IBuffer setConduit (IConduit conduit);

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

        abstract IBuffer output (OutputStream sink);

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

        abstract IBuffer input (InputStream source);

        /***********************************************************************

                Transfer content into the provided dst.

                Params: 
                dst = destination of the content

                Returns:
                Return the number of bytes read, which may be less than
                dst.length. Eof is returned when no further content is
                available.

                Remarks:
                Populates the provided array with content. We try to 
                satisfy the request from the buffer content, and read 
                directly from an attached conduit when the buffer is 
                empty.

        ***********************************************************************/

        abstract uint read (void[] dst);

        /***********************************************************************

                Emulate OutputStream.write()

                Params: 
                src = the content to write

                Returns:
                Return the number of bytes written, which will be Eof when
                the content cannot be written.

                Remarks:
                Appends all of dst to the buffer, flushing to an attached
                conduit as necessary.

        ***********************************************************************/

        abstract uint write (void[] src);

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

        abstract OutputStream output ();

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

        abstract InputStream input ();

        /***********************************************************************
        
                Throw an exception with the provided message

        ***********************************************************************/

        abstract void error (char[] msg);

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

        abstract IConduit conduit ();

        /***********************************************************************
        
                Return a preferred size for buffering conduit I/O.

        ***********************************************************************/

        abstract uint bufferSize (); 
                     
        /***********************************************************************
        
                Return the name of this conduit.

        ***********************************************************************/

        abstract char[] toString (); 
                     
        /***********************************************************************

                Is the conduit alive?

        ***********************************************************************/

        abstract bool isAlive ();

        /***********************************************************************
        
                Flush the contents of this buffer to the related conduit.
                Throws an IOException on premature eof.

        ***********************************************************************/

        abstract OutputStream flush ();

        /***********************************************************************
        
                Reset position and limit to zero.

        ***********************************************************************/

        abstract InputStream clear ();               

        /***********************************************************************
        
                Copy content via this buffer from the provided src
                conduit.

                Remarks:
                The src conduit has its content transferred through 
                this buffer via a series of fill & drain operations, 
                until there is no more content available. The buffer
                content should be explicitly flushed by the caller.

                Throws an IOException on premature Eof.

        ***********************************************************************/

        abstract OutputStream copy (InputStream src);

        /***********************************************************************
                
                Release external resources

        ***********************************************************************/

        abstract void detach ();

        /***********************************************************************
        
                Close the stream

                Remarks:
                Propagate request to an attached OutputStream (this is a
                requirement for the OutputStream interface)

        ***********************************************************************/

        abstract void close ();
}


/*******************************************************************************

        Supported by streams which are prepared to share an internal buffer 
        instance. This is intended to avoid a situation whereby content is
        shunted unnecessarily from one buffer to another when "decorator"
        streams are connected together in arbitrary ways.
        
        Do not implement this if the internal buffer should not be accessed 
        directly by another stream e.g. if wrapper methods manipulate content
        on the way in or out of the buffer.

*******************************************************************************/

interface Buffered
{
        IBuffer buffer();
}
