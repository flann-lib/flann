/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: May 2004
        
        author:         Kris

*******************************************************************************/

module tango.util.log.RollingFileAppender;

private import  tango.time.Time;

private import  tango.io.FilePath,
                tango.io.FileConst,
                tango.io.FileConduit;

private import  tango.io.model.IBuffer;

private import  tango.util.log.Appender,
                tango.util.log.FileAppender;

/*******************************************************************************

        Append log messages to a file set. 

*******************************************************************************/

public class RollingFileAppender : FileAppender
{
        private Mask            mask;
        private FilePath[]      paths;
        private int             index;
        private IBuffer         buffer;
        private ulong           maxSize,
                                fileSize;

        /***********************************************************************
                
                Create a RollingFileAppender upon a file-set with the 
                specified path and optional layout.

                Where a file set already exists, we resume appending to 
                the one with the most recent activity timestamp.

        ***********************************************************************/

        this (char[] path, int count, ulong maxSize, EventLayout layout = null)
        {
                assert (path);
                assert (count > 1 && count < 10);

                // Get a unique fingerprint for this instance
                mask = register (path);

                char[1] x;
                Time mostRecent;

                for (int i=0; i < count; ++i)
                    {
                    x[0] = '0' + i;

                    auto p = new FilePath (path);
                    p.name = p.name ~ x;
                    paths ~= p;

                    // use the most recent file in the set
                    if (p.exists)
                       {
                       auto modified = p.modified;
                       if (modified > mostRecent)
                          {
                          mostRecent = modified;
                          index = i;
                          }
                       }
                    }

                // remember the maximum size 
                this.maxSize = maxSize;

                // adjust index and open the appropriate log file
                --index; 
                nextFile (false);

                // set provided layout (ignored when null)
                setLayout (layout);
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
                char[] msg;

                // file already full?
                if (fileSize >= maxSize)
                    nextFile (true);

                // bump file size
                fileSize += FileConst.NewlineString.length;

                // write log message and flush it
                auto layout = getLayout ();
                msg = layout.header (event);
                fileSize += msg.length;
                buffer.append (msg);

                msg = layout.content (event);
                fileSize += msg.length;
                buffer.append (msg);

                msg = layout.footer (event);
                fileSize += msg.length;
                buffer.append (msg);

                buffer.append(FileConst.NewlineString).flush;
        }

        /***********************************************************************
                
                Switch to the next file within the set

        ***********************************************************************/

        private void nextFile (bool reset)
        {
                // select next file in the set
                if (++index >= paths.length)
                    index = 0;
                
                // reset file size
                fileSize = 0;

                // close any existing conduit
                close;

                // make it shareable for read
                auto style = FileConduit.WriteAppending;
                style.share = FileConduit.Share.Read;
                auto conduit = new FileConduit (paths[index], style);

                buffer = setConduit (conduit);
                if (reset)
                    conduit.truncate;
        }
}

