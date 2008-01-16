/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: December 2005

        author:         Kris

*******************************************************************************/

module tango.text.stream.StreamIterator;

public  import tango.io.Buffer;

private import Text = tango.text.Util;

private import tango.io.model.IConduit;

/*******************************************************************************

        The base class for a set of stream iterators. These operate
        upon a buffered input stream, and are designed to deal with
        partial content. That is, stream iterators go to work the
        moment any data becomes available in the buffer. Contrast
        this behaviour with the tango.text.Util iterators, which
        operate upon the extent of an array.

        There are two types of iterators supported; exclusive and
        inclusive. The former are the more common kind, where a token
        is delimited by elements that are considered foreign. Examples
        include space, comma, and end-of-line delineation. Inclusive
        tokens are just the opposite: they look for patterns in the
        text that should be part of the token itself - everything else
        is considered foreign. Currently tango.text.stream includes the
        exclusive variety only.

        Each pattern is exposed to the client as a slice of the original
        content, where the slice is transient. If you need to retain the
        exposed content, then you should .dup it appropriately. 

        The content provided to these iterators is intended to be fully
        read-only. All current tokenizers abide by this rule, but it is
        possible a user could mutate the content through a token slice.
        To enforce the desired read-only aspect, the code would have to
        introduce redundant copying or the compiler would have to support
        read-only arrays.

        See LineIterator, CharIterator, RegexIterator, QuotedIterator,
        and SimpleIterator

*******************************************************************************/

class StreamIterator(T) : InputStream, Buffered
{
        protected T[]           slice,
                                pushed;
        private IBuffer         input;

        /***********************************************************************

                The pattern scanner, implemented via subclasses

        ***********************************************************************/

        abstract protected uint scan (void[] data);

        /***********************************************************************

                Instantiate with a buffer

        ***********************************************************************/

        this (InputStream stream = null)
        {
                if (stream)
                    set (stream);
        }

        /***********************************************************************

                Set the provided stream as the scanning source

        ***********************************************************************/

        final StreamIterator set (InputStream stream)
        {
                assert (stream);
                input = Buffer.share (stream);
                return this;
        }

        /***********************************************************************

                Return the current token as a slice of the content

        ***********************************************************************/

        final T[] get ()
        {
                return slice;
        }

        /***********************************************************************

                Push one token back into the stream, to be returned by a
                subsequent call to next()

                Push null to cancel a prior assignment

        ***********************************************************************/

        final StreamIterator push (T[] token)
        {
                pushed = token;
                return this;
        }

        /**********************************************************************

                Iterate over the set of tokens. This should really
                provide read-only access to the tokens, but D does
                not support that at this time

        **********************************************************************/

        int opApply (int delegate(inout T[]) dg)
        {
                bool more;
                int  result;

                do {
                   more = consume;
                   result = dg (slice);
                   } while (more && !result);
                return result;
        }

        /**********************************************************************

                Iterate over a set of tokens, exposing a token count 
                starting at zero

        **********************************************************************/

        int opApply (int delegate(inout int, inout T[]) dg)
        {
                bool more;
                int  result,
                     tokens;

                do {
                   more = consume;
                   result = dg (tokens, slice);
                   ++tokens;
                   } while (more && !result);
                return result;
        }

        /***********************************************************************

                Locate the next token. Returns the token if found, null
                otherwise. Null indicates an end of stream condition. To
                sweep a conduit for lines using method next():
                ---
                auto lines = new LineIterator!(char) (new FileConduit("myfile"));
                while (lines.next)
                       Cout (lines.get).newline;
                ---

                Alternatively, we can extract one line from a conduit:
                ---
                auto line = (new LineIterator!(char) (new FileConduit("myfile"))).next;
                ---

                The difference between next() and foreach() is that the
                latter processes all tokens in one go, whereas the former
                processes in a piecemeal fashion. To wit:
                ---
                foreach (line; new LineIterator!(char) (new FileConduit("myfile"))
                         Cout(line).newline;
                ---

                Note that tokens exposed via push() are returned immediately
                when available, taking priority over the input stream itself
                
        ***********************************************************************/

        final T[] next ()
        {
                if (pushed.ptr)
                    return pushed;
                else
                   if (consume() || slice.length)
                       return slice;
                return null;
        }

        /***********************************************************************

                Set the content of the current slice

        ***********************************************************************/

        protected final uint set (T* content, uint start, uint end)
        {
                slice = content [start .. end];
                return end;
        }

        /***********************************************************************

                Called when a scanner fails to find a matching pattern.
                This may cause more content to be loaded, and a rescan
                initiated

        ***********************************************************************/

        protected final uint notFound ()
        {
                return IConduit.Eof;
        }

        /***********************************************************************

                Invoked when a scanner matches a pattern. The provided
                value should be the index of the last element of the
                matching pattern, which is converted back to a void[]
                index.

        ***********************************************************************/

        protected final uint found (uint i)
        {
                return (i + 1) * T.sizeof;
        }

        /***********************************************************************

                See if set of characters holds a particular instance

        ***********************************************************************/

        protected final bool has (T[] set, T match)
        {
                foreach (T c; set)
                         if (match is c)
                             return true;
                return false;
        }

        /***********************************************************************

                Consume the next token and place it in 'slice'. Returns 
                true when there are potentially more tokens

        ***********************************************************************/

        private bool consume ()
        {
                if (input.next (&scan))
                    return true;

                auto tmp = input.slice (buffer.readable);
                slice = (cast(T*) tmp.ptr) [0 .. tmp.length/T.sizeof];
                return false;
        }


        /**********************************************************************/
        /************************ Buffered Interface **************************/
        /**********************************************************************/


        /***********************************************************************

                Return the associated buffer

        ***********************************************************************/

        final IBuffer buffer ()
        {
                return input;
        }

        /**********************************************************************/
        /********************** InputStream Interface *************************/
        /**********************************************************************/


        /***********************************************************************
        
                Return the host conduit

        ***********************************************************************/

        final IConduit conduit ()
        {
                return input.conduit;
        }

        /***********************************************************************
        
                Read from conduit into a target array. The provided dst 
                will be populated with content from the conduit. 

                Returns the number of bytes read, which may be less than
                requested in dst

        ***********************************************************************/

        uint read (void[] dst)
        {
                return input.read (dst);
        }               
                        
        /***********************************************************************
        
                Clear any buffered content

        ***********************************************************************/

        final InputStream clear ()               
        {
                return input.clear;
        }
                                  
        /***********************************************************************
        
                Close the input

        ***********************************************************************/

        final void close ()
        {
                input.close;
        }               
}


