/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Oct 2007: Initial release

        author:         Kris

        Synchronized, formatted console output. This can be used in lieu 
        of true logging where appropriate.

        Trace exposes this style of usage:
        ---
        Trace.format ("abc {}", 1);             => abc 1
        Trace.format ("abc {}:{}", 1, 2);       => abc 1:2
        Trace.format ("abc {1}:{0}", 1, 2);     => abc 2:1
        ---

        Special character sequences, such as "\n", are written directly to
        the output without any translation (though an output-filter could
        be inserted to perform translation as required). Platform-specific 
        newlines are generated instead via the formatln() method, which also 
        flushes the output when configured to do so:
        ---
        Trace.formatln ("hello {}", "world");
        ---

        Explicitly flushing the output is achieved via a flush() method
        ---
        Trace.format ("hello {}", "world").flush;
        ---
        
*******************************************************************************/

module tango.util.log.Trace;

private import tango.io.Console;

private import tango.io.model.IConduit;

private import tango.text.convert.Layout;

/*******************************************************************************

        Construct Trace when this module is loaded

*******************************************************************************/

/// global trace instance
public static SyncPrint Trace;

static this()
{
        Trace = new SyncPrint (Cerr.stream, Cerr, !Cerr.redirected);
}

/*******************************************************************************
        
        Intended for internal use only
        
*******************************************************************************/

private class SyncPrint
{
        private Object          mutex;
        private OutputStream    output;
        private Layout!(char)   convert;
        private bool            flushLines;

        version (Win32)
                 private const char[] Eol = "\r\n";
             else
                private const char[] Eol = "\n";

        /**********************************************************************

                Construct a Print instance, tying the provided stream
                to a layout formatter

        **********************************************************************/

        this (OutputStream output, Object mutex, bool flush=false)
        {
                this.mutex = mutex;
                this.output = output;
                this.flushLines = flush;
                this.convert = new Layout!(char);
        }

        /**********************************************************************

                Layout using the provided formatting specification

        **********************************************************************/

        final SyncPrint format (char[] fmt, ...)
        {
                synchronized (mutex)
                              convert (&sink, _arguments, _argptr, fmt);
                return this;
        }

        /**********************************************************************

                Layout using the provided formatting specification

        **********************************************************************/

        final SyncPrint formatln (char[] fmt, ...)
        {
                synchronized (mutex)
                             {
                             convert (&sink, _arguments, _argptr, fmt);
                             output.write (Eol);
                             if (flushLines)
                                 output.flush;
                             }
                return this;
        }

        /**********************************************************************

               Flush the output stream

        **********************************************************************/

        final void flush ()
        {
                synchronized (mutex)
                              output.flush;
        }

        /**********************************************************************

                Sink for passing to the formatter

        **********************************************************************/

        private final uint sink (char[] s)
        {
                return output.write (s);
        }
}
