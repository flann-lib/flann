/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: May 2004
        
        author:         Kris

*******************************************************************************/

module tango.util.log.MailAppender;

private import  tango.util.log.Appender;

private import  tango.io.Buffer,
                tango.net.SocketConduit,
                tango.net.InternetAddress;

/*******************************************************************************

        Appender for sending formatted output to a Mail server. Thanks
        to BCS for posting how to do this.

*******************************************************************************/

public class MailAppender : Appender
{
        private char[]          to,
                                from,
                                subj;
        private Mask            mask;
        private InternetAddress server;

        /***********************************************************************
                
                Create with the given layout and server address

        ***********************************************************************/

        this (InternetAddress server, char[] from, char[] to, char[] subj, EventLayout layout = null)
        {
                setLayout (layout);

                this.to = to;
                this.from = from;
                this.subj = subj;
                this.server = server;

                // Get a unique fingerprint for this appender
                mask = register (to ~ subj);
        }

        /***********************************************************************
                
                Send an event to the mail server
                 
        ***********************************************************************/

        synchronized void append (Event event)
        {
                auto conduit = new SocketConduit;
                scope (exit)
                       conduit.close;

                conduit.connect (server);
                auto emit = new Buffer (conduit);

                emit ("HELO none@anon.org\r\nMAIL FROM:<") 
                     (from) 
                     (">\r\nRCPT TO:<") 
                     (to) 
                     (">\r\nDATA\r\nSubject: ") 
                     (subj) 
                     ("\r\nContent-Type: text/plain; charset=us-ascii\r\n\r\n");
                
                auto layout = getLayout();
                emit (layout.header (event));
                emit (layout.content (event));
                emit (layout.footer (event));
                emit ("\r\n.\r\nQUIT\r\n");
                emit ();
        }

        /***********************************************************************
                
                Return the fingerprint for this class

        ***********************************************************************/

        Mask getMask ()
        {
                return mask;
        }

        /***********************************************************************
                
                Return the name of this class

        ***********************************************************************/

        char[] getName ()
        {
                return this.classinfo.name;
        }
}
