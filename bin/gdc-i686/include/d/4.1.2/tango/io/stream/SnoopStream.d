/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2007

        author:         Kris

*******************************************************************************/

module tango.io.stream.SnoopStream;

private import  tango.io.Console,
                tango.io.Conduit;

private import  tango.text.convert.Format;

private alias void delegate(char[]) Snoop;

/*******************************************************************************

        Stream to expose call behaviour. By default, activity trace is
        sent to Cerr

*******************************************************************************/

class SnoopInput : InputStream
{
        private InputStream     host;
        private Snoop           snoop;

        /***********************************************************************

                Attach to the provided stream

        ***********************************************************************/

        this (InputStream host, Snoop snoop = null)
        {
                assert (host);
                this.host = host;
                this.snoop = snoop ? snoop : &snooper;
        }

        /***********************************************************************

                Return the hosting conduit

        ***********************************************************************/

        final IConduit conduit ()
        {
                return host.conduit;
        }

        /***********************************************************************

                Read from conduit into a target array. The provided dst 
                will be populated with content from the conduit. 

                Returns the number of bytes read, which may be less than
                requested in dst

        ***********************************************************************/

        final uint read (void[] dst)
        {
                auto x = host.read (dst);
                trace ("{}: read {} bytes", host.conduit, x is -1 ? 0 : x);
                return x;
        }

        /***********************************************************************

                Clear any buffered content

        ***********************************************************************/

        final InputStream clear ()
        {
                host.clear;
                trace ("{}: cleared", host.conduit);
                return this;
        }

        /***********************************************************************

                Close the input

        ***********************************************************************/

        final void close ()
        {
                host.close;
                trace ("{}: closed", host.conduit);
        }

        /***********************************************************************

                Internal trace handler

        ***********************************************************************/

        private void snooper (char[] x)
        {
                Cerr(x).newline;
        }

        /***********************************************************************

                Internal trace handler

        ***********************************************************************/

        private void trace (char[] format, ...)
        {
                char[256] tmp = void;
                snoop (Format.vprint (tmp, format, _arguments, _argptr));
        }
}


/*******************************************************************************

        Stream to expose call behaviour. By default, activity trace is
        sent to Cerr

*******************************************************************************/

class SnoopOutput : OutputStream
{
        private OutputStream    host;
        private Snoop           snoop;

        /***********************************************************************

                Attach to the provided stream

        ***********************************************************************/

        this (OutputStream host, Snoop snoop = null)
        {
                assert (host);
                this.host = host;
                this.snoop = snoop ? snoop : &snooper;
        }

        /***********************************************************************

                Write to conduit from a source array. The provided src
                content will be written to the conduit.

                Returns the number of bytes written from src, which may
                be less than the quantity provided

        ***********************************************************************/

        final uint write (void[] src)
        {
                auto x = host.write (src);
                trace ("{}: wrote {} bytes", host.conduit, x is -1 ? 0 : x);
                return x;
        }

        /***********************************************************************

                Return the hosting conduit

        ***********************************************************************/

        final IConduit conduit ()
        {
                return host.conduit;
        }

        /***********************************************************************

                Emit/purge buffered content

        ***********************************************************************/

        final OutputStream flush ()
        {
                host.flush;
                trace ("{}: flushed", host.conduit);
                return this;
        }

        /***********************************************************************

                Close the output

        ***********************************************************************/

        final void close ()
        {
                host.close;
                trace ("{}: closed", host.conduit);
        }

        /***********************************************************************

                Transfer the content of another conduit to this one. Returns
                a reference to this class, or throws IOException on failure.

        ***********************************************************************/

        final OutputStream copy (InputStream src)
        {
                host.copy (src);
                trace("{}: copied from {}", host.conduit, src.conduit);
                return this;
        }

        /***********************************************************************

                Internal trace handler

        ***********************************************************************/

        private void snooper (char[] x)
        {
                Cerr(x).newline;
        }

        /***********************************************************************

                Internal trace handler

        ***********************************************************************/

        private void trace (char[] format, ...)
        {
                char[256] tmp = void;
                snoop (Format.vprint (tmp, format, _arguments, _argptr));
        }
}

