/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: January 2006      
        
        author:         Kris

*******************************************************************************/

module tango.text.stream.RegexIterator;

private import  tango.text.Regex;
    
private import  tango.text.stream.StreamIterator;

/*******************************************************************************

        Iterate across a set of text patterns.

        Each pattern is exposed to the client as a slice of the original
        content, where the slice is transient. If you need to retain the
        exposed content, then you should .dup it appropriately. 

        These iterators are based upon the IBuffer construct, and can
        thus be used in conjunction with other Iterators and/or Reader
        instances upon a common buffer ~ each will stay in lockstep via
        state maintained within the IBuffer.

        The content exposed via an iterator is supposed to be entirely
        read-only. All current iterators abide by this rule, but it is
        possible a user could mutate the content through a get() slice.
        To enforce the desired read-only aspect, the code would have to 
        introduce redundant copying or the compiler would have to support 
        read-only arrays.

        See LineIterator, SimpleIterator, RegexIterator, QuotedIterator.


*******************************************************************************/

class RegexIterator : StreamIterator!(char)
{
        private Regex regex;
        private alias char T;
        
        /***********************************************************************
        
                Construct an uninitialized iterator. For example:
                ---
                auto lines = new LineIterator!(char);

                void somefunc (IBuffer buffer)
                {
                        foreach (line; lines.set(buffer))
                                 Cout (line).newline;
                }
                ---

                Construct a streaming iterator upon a buffer:
                ---
                void somefunc (IBuffer buffer)
                {
                        foreach (line; new LineIterator!(char) (buffer))
                                 Cout (line).newline;
                }
                ---
                
                Construct a streaming iterator upon a conduit:
                ---
                foreach (line; new LineIterator!(char) (new FileConduit ("myfile")))
                         Cout (line).newline;
                ---

        ***********************************************************************/

        this (T[] pattern, InputStream stream = null)
        {
                regex = new Regex (pattern, "");
                super (stream);
        }

        /***********************************************************************
                
        ***********************************************************************/

        protected uint scan (void[] data)
        {
                auto content = (cast(T*) data.ptr) [0 .. data.length / T.sizeof];

                if (regex.test (content))
                   {
                   int start = regex.pmatch[0].rm_so;
                   int finish = regex.pmatch[0].rm_eo;
                   set (content.ptr, 0, start);
                   return found (finish-1);        
                   }

                return notFound;
        }
}
