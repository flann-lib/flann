/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: May 2004
        
        author:         Kris

*******************************************************************************/

module tango.util.log.FileAppender;

private import  tango.util.log.Appender;

private import  tango.io.Buffer,
                tango.io.FileConst,
                tango.io.FileConduit;

private import  tango.io.model.IConduit;

/*******************************************************************************

        Append log messages to a file. This basic version has no rollover 
        support, so it just keeps on adding to the file. There's also a
        RollingFileAppender that may suit your needs.

*******************************************************************************/

public class FileAppender : Appender
{
        private Mask            mask;
        private Buffer          buffer;
        private IConduit        conduit_;

        /***********************************************************************

        ***********************************************************************/

        protected this ()
        {
        }

        /***********************************************************************
                
                Create a basic FileAppender to a file with the specified 
                path.

        ***********************************************************************/

        this (FilePath fp, EventLayout layout = null)
        {
                // Get a unique fingerprint for this instance
                mask = register (fp.toString);
        
                // make it shareable for read
                auto style = FileConduit.WriteAppending;
                style.share = FileConduit.Share.Read;
                setConduit (new FileConduit (fp, style));

                setLayout (layout);
        }

        /***********************************************************************
                
                Create a basic FileAppender to a file with the specified 
                path, and with the given EventLayout

        ***********************************************************************/

        this (char[] fp, EventLayout layout = null)
        {
                this (new FilePath (fp), layout);
        }

        /***********************************************************************
                
                Return the conduit

        ***********************************************************************/

        IConduit conduit ()
        {
                return conduit_;
        }

        /***********************************************************************
                
                Set the conduit

        ***********************************************************************/

        protected Buffer setConduit (IConduit conduit)
        {
                // create a new buffer upon this conduit
                conduit_ = conduit;
                return (buffer = new Buffer(conduit));
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
                
                Append an event to the output.
                 
        ***********************************************************************/

        synchronized void append (Event event)
        {
                auto layout = getLayout;
                buffer.append (layout.header  (event));
                buffer.append (layout.content (event));
                buffer.append (layout.footer  (event))
                      .append (FileConst.NewlineString)
                      .flush  ();
        }

        /***********************************************************************
                
                Close the file associated with this Appender

        ***********************************************************************/

        synchronized void close ()
        {
                if (conduit_)
                   {
                   conduit_.detach;
                   conduit_ = null;
                   }
        }
}


