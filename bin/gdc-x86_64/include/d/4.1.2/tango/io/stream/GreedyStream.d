/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: June 2007

        author:         Kris

*******************************************************************************/

module tango.io.stream.GreedyStream;

private import tango.io.Conduit;


/*******************************************************************************

        A conduit filter that ensures its input is read in full. There's
        also an optional readExact() for more explicit requests         

*******************************************************************************/

class GreedyInput : InputFilter
{
        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (InputStream stream)
        {
                super (stream);
        }

        /***********************************************************************

                Fill the provided array. Returns the number of bytes
                actually read, which will be less that dst.length when
                Eof has been reached, and then Eof thereafter

        ***********************************************************************/

        final override uint read (void[] dst)
        {
                uint len = 0;

                while (len < dst.length)
                      {
                      auto i = host.read (dst [len .. $]);
                      if (i is Eof)
                          return (len ? len : i);
                      len += i;
                      } 
                return len;
        }

        /***********************************************************************
        
                Read from a stream into a target array. The provided dst
                will be fully populated with content from the input. 

                This differs from read in that it will throw an exception
                where an Eof condition is reached before input has completed

        ***********************************************************************/

        final GreedyInput readExact (void[] dst)
        {
                while (dst.length)
                      {
                      auto i = read (dst);
                      if (i is Eof)
                          conduit.error ("unexpected Eof while reading: "~conduit.toString);
                      dst = dst [i .. $];
                      }
                return this;
        }          
}



/*******************************************************************************

        A conduit filter that ensures its output is written in full. There's
        also an optional writeExact() for more explicit requests   

*******************************************************************************/

class GreedyOutput : OutputFilter
{
        /***********************************************************************

                Propagate ctor to superclass

        ***********************************************************************/

        this (OutputStream stream)
        {
                super (stream);
        }

        /***********************************************************************

                Consume everything we were given. Returns the number of
                bytes written which will be less than src.length only
                when an Eof condition is reached, and Eof from that point 
                forward

        ***********************************************************************/

        final override uint write (void[] src)
        {
                uint len = 0;

                while (len < src.length)
                      {
                      auto i = host.write (src [len .. $]);
                      if (i is Eof)
                          return (len ? len : i);
                      len += i;
                      } 
                return len;
        }
                             
        /***********************************************************************
        
                Write to stream from a source array. The provided src content 
                will be written in full to the output.

                This differs from write in that it will throw an exception
                where an Eof condition is reached before output has completed

        ***********************************************************************/

        final GreedyOutput writeExact (void[] src)
        {
                while (src.length)
                      {
                      auto i = write (src);
                      if (i is Eof)
                          conduit.error ("unexpected Eof while writing: "~conduit.toString);
                      src = src [i .. $];
                      }
                return this;
        }       
}


/*******************************************************************************

*******************************************************************************/

debug (GreedyStream)
{
        void main()
        {       
                auto s = new GreedyInput (null);
        }
}