/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.tina.QueueFile;

private import  tango.io.FilePath,
                tango.io.FileConduit;

private import  tango.util.log.Logger;

private import  tango.text.convert.Sprint;

private import  tango.net.cluster.model.IChannel;

version (Posix)
         private import tango.stdc.posix.fcntl;

/******************************************************************************
        

******************************************************************************/

class QueueFile
{
        struct Header                           // 16 bytes
        {
                uint    size,                   // size of the current chunk
                        prior;                  // size of the prior chunk
                ushort  check;                  // simpe header checksum
                ubyte   pad;                    // how much padding applied?
                byte[5] unused;                 // future use
        }

        private Logger          log;            // logging target
        private bool            dirty;          // is queue dirty?
        private uint            limit,          // max file size
                                depth,          // stack depth
                                insert;         // file insert position
        private void[]          buffer;         // read buffer
        private Sprint!(char)   sprint;         // formatting buffer
        private Header          current;        // top-of-stack info
        private FileConduit     conduit;        // the file itself
        private IChannel        channel_;       // the channel we're using

        /**********************************************************************

        **********************************************************************/

        this (Logger log, IChannel channel, uint max, uint min=1024*1024)
        {
                this (log, channel.name~".queue", max, min);
                channel_ = channel;
        }

        /**********************************************************************

        **********************************************************************/

        this (Logger log, char[] name, uint max, uint min=1024*1024)
        {
                Header tmp;

                this.log = log;
                limit    = max;
                sprint   = new Sprint!(char);
                buffer   = new void [1024 * 8];
                conduit  = new FileConduit (name, FileConduit.ReadWriteOpen);

                // lock the file on Posix, since it has no O/S file locks
                version (Posix)
                        {
                        flock f;
                        f.l_type = F_WRLCK;
                        f.l_start = f.l_len = f.l_whence = 0;
                        if (fcntl (conduit.fileHandle, F_SETLK, &f) is -1)
                           {
                           log.error (sprint("failed to lock queue file '{}'; it may already be in use", name));
                           conduit.error;
                           }
                        }

                auto length = conduit.path.fileSize;
                if (length is 0)
                   {
                   // make some space in the file
                   min = (min + buffer.length - 1) / buffer.length;
                   log.trace (sprint("initializing queue '{}' to {} KB", name, (min * buffer.length)/1024));

                   while (min-- > 0)
                          write (buffer.ptr, buffer.length);
                   conduit.seek (0);
                   }
                else
                   {
                   // sweep the file and truncate on inconsistencies
                   while (insert < length)
                         {
                         // get a header
                         read (&tmp, tmp.sizeof);

                         // end of queue?
                         if (tmp.size)
                            {
                            // a corrupted header?
                            if (checksum(tmp) != tmp.check)
                               {
                               log.warn (sprint("invalid header located in queue '{}'; truncating", name));
                               break;
                               }

                            // corrupted content?
                            auto content = read (tmp);

                            ++depth;
                            current = tmp;
                            insert = insert + tmp.size + tmp.sizeof;
                            conduit.seek (insert);

                            debug
                              log.trace (sprint("open: depth {}, prior {}, size {}, insert {}", 
                                                       depth, tmp.prior, tmp.size, insert));
                            }  
                         else
                            break;
                         }

                   // leave file position at insert point
                   conduit.seek (insert);
                   }
        }

        /**********************************************************************

        **********************************************************************/

        final void close ()
        {
                if (conduit)
                    conduit.detach;
                conduit = null;
        }

        /**********************************************************************

        **********************************************************************/

        final uint size ()
        {
                return depth;
        }

        /**********************************************************************

        **********************************************************************/

        final IChannel channel ()
        {
                return channel_;
        }

        /**********************************************************************

        **********************************************************************/

        final bool isDirty ()
        {
                return dirty;
        }

        /**********************************************************************

        **********************************************************************/

        final synchronized void flush ()
        {
                //conduit.commit;
                dirty = false;
        }

        /**********************************************************************

        **********************************************************************/

        final synchronized bool push (void[] data)
        {
                //assert (insert is conduit.position);

                if (data.length is 0)
                    conduit.error ("invalid zero length content");

                // check for overflow
                if (insert > limit)
                    return false;

                Header chunk = void;

                // pad the output to 4 byte boundary, so  
                // that each header is aligned
                chunk.prior = current.size;
                chunk.size  = ((data.length + 3) / 4) * 4;
                chunk.pad   = cast(ubyte) (chunk.size - data.length);
                chunk.check = checksum (chunk);

                debug
                  log.trace (sprint("push: data {}, prior {}, size {}, insert {}, filepos {}", 
                             data.length, chunk.prior, chunk.size, insert, conduit.position));

                // write msg header and content
                write (&chunk, chunk.sizeof);
                write (data.ptr, chunk.size);

                // update refs
                insert = insert + chunk.sizeof + chunk.size;
                current = chunk;
                ++depth;

                return dirty = true;
        }

        /**********************************************************************

        **********************************************************************/

        final synchronized void[] pop ()
        {
                //assert (insert is conduit.position);

                Header tmp = void;

                if (depth)
                   {
                   // locate the current header
                   auto point = insert - (current.size + tmp.sizeof);
                   conduit.seek (point);

                   // write a zero header to indicate eof
                   Header zero;
                   write (&zero, zero.sizeof);

                   // read the current record
                   auto content = read (current, current.pad);
        
                   // content before us?
                   if (depth > 1)
                      {
                      auto prior = point - (current.prior + tmp.sizeof);
                      conduit.seek (prior);
                      read (&current, current.sizeof);
                      }
                   else
                      if (current.prior)
                          conduit.error ("queue file is corrupt");
                      else
                         current = zero;

                   // leave file position at insert-point
                   conduit.seek (point);
                   insert = point;
                   if (--depth is 0 && insert > 0)
                       conduit.error ("queue file is corrupt");
                   return content;
                   }
                return null;
        }

        /**********************************************************************

        **********************************************************************/

        private final void[] read (inout Header hdr, uint pad=0)
        {
                auto len = hdr.size - pad;

                // make buffer big enough
                if (buffer.length < len)
                    buffer.length = len;

                read (buffer.ptr, len);
                return buffer [0 .. len];
        }

        /**********************************************************************

        **********************************************************************/

        private final void read (void* data, uint len)
        {
                auto input = conduit.input;

                for (uint i; len > 0; len -= i, data += i)
                     if ((i = input.read (data[0..len])) is conduit.Eof)
                          conduit.error ("QueueFile.read :: Eof while reading");
        }

        /**********************************************************************

        **********************************************************************/

        private final void write (void* data, uint len)
        {
                auto output = conduit.output;

                for (uint i; len > 0; len -= i, data += i)
                     if ((i = output.write (data[0..len])) is conduit.Eof)
                          conduit.error ("QueueFile.write :: Eof while writing");
        }

        /**********************************************************************

        **********************************************************************/

        private static ushort checksum (inout Header hdr)
        {
                uint i = hdr.pad;
                i = i ^ hdr.size  ^ (hdr.size >> 16);
                i = i ^ hdr.prior ^ (hdr.prior >> 16);
                return cast(ushort) i;
        }
}


/******************************************************************************
        

******************************************************************************/

version (QueueFile)
{
        import  tango.time.StopWatch;

        import  tango.util.log.Log,
                tango.util.log.Configurator;

        void main (char[][] args)
        {
                auto log = Log.getLogger("queue.persist").setLevel(Logger.Level.Info);

                auto z = new QueueFile (log, "foo.bar", 30 * 1024 * 1024);
                pushTimer (z);
                z.close;
        }

        void pushTimer (QueueFile z)
        {
                StopWatch w;
                char[200] test;
                
                popAll(z);
                w.start;
                for (int i=10_000; i--;)
                     z.push(test);
                z.log.info (z.sprint("{} push/s", 10_000/w.stop));
                popAll(z);
        }

        void push (QueueFile z)
        {
                z.push ("one");
                z.push ("two");
                z.push ("three");
                z.push ("four");
                z.push ("five");
                z.push ("six");
                z.push ("seven");
                z.push ("eight");
                z.push ("nine");
                z.push ("ten");
                z.push ("eleven");
        }

        void popAll(QueueFile z)
        {        
                uint i;
                StopWatch w;

                w.start;
                while (z.pop !is null) ++i;
                z.log.info (z.sprint("{}, {} pop/s",i, i/w.stop));
        }       
}
