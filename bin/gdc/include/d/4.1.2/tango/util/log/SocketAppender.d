/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: May 2004
        
        author:         Kris

*******************************************************************************/

module tango.util.log.SocketAppender;

private import  tango.util.log.Appender;

private import  tango.io.Buffer,
                tango.io.Console;

private import  tango.net.SocketConduit,
                tango.net.InternetAddress;

/*******************************************************************************

        Appender for sending formatted output to a Socket.

*******************************************************************************/

public class SocketAppender : Appender
{
        private Mask            mask;
        private IBuffer         buffer;
        private SocketConduit   conduit;
        private InternetAddress address;
        private bool            connected;

        /***********************************************************************
                
                Create with the given Layout and address

        ***********************************************************************/

        this (InternetAddress address, EventLayout layout = null)
        {
                setLayout (layout);

                this.address = address;
                this.conduit = new SocketConduit;
                this.buffer  = new Buffer (conduit);

                // Get a unique fingerprint for this class
                this.mask = register (address.toString);
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
                
        /***********************************************************************
                
                Append an event to the output. If the operations fails
                we have to revert to an alternative logging strategy, 
                which will probably require a backup Appender specified
                during construction. For now we simply echo to Cerr if
                the socket has become unavailable.               
                 
        ***********************************************************************/

        void append (Event event)
        {
                auto layout = getLayout();

                if (buffer)
                   {
                   try {
                       if (! connected)
                          {
                          conduit.connect (address);
                          connected = true;
                          }

                       buffer (layout.header  (event));
                       buffer (layout.content (event));
                       buffer (layout.footer  (event)) ();
                       return;
                       } catch (Exception e)
                               {
                               connected = false;
                               Cerr ("SocketAppender.append :: "~e.toString).newline;
                               }
                   }

                Cerr (layout.content(event)).newline;
        }

        /***********************************************************************
            
                Close the socket associated with this Appender
                    
        ***********************************************************************/

        void close ()
        {
                if (conduit)
                    conduit.detach;
                conduit = null;
        }
}
