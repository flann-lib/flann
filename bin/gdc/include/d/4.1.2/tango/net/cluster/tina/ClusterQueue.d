/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.tina.ClusterQueue;

private import  tango.core.Thread;

private import tango.stdc.stdlib : alloca;

private import  tango.net.cluster.tina.Cluster,
                tango.net.cluster.tina.QueueFile,
                tango.net.cluster.tina.ClusterTypes;

/******************************************************************************
        
******************************************************************************/

class ClusterQueue
{
        private Logger          log;
        private uint            used, 
                                limit;
        private double          sleep;
        private Thread          thread;
        private Cluster         cluster;

        /**********************************************************************

        **********************************************************************/

        abstract void watchdog ();

        /**********************************************************************

        **********************************************************************/

        abstract ClusterContent get (char[] name);

        /**********************************************************************

        **********************************************************************/

        abstract bool put (char[] name, ClusterContent content);

        /**********************************************************************

        **********************************************************************/

        this (Cluster cluster, uint limit, double sleep)
        {
                thread = new Thread (&run);
                
                log = cluster.log;
                this.limit = limit;
                this.sleep = sleep;
                this.cluster = cluster;
                
                thread.start;
        }
        
        /**********************************************************************

        **********************************************************************/

        final void publish (IChannel channel)
        {
                log.info ("publishing queue channel '" ~ channel.name ~ "'");
                channel.broadcast;
        }

        /**********************************************************************

        **********************************************************************/

        private void run ()
        {       
                while (true)
                      {
                      Thread.sleep (sleep);

                      try {
                          watchdog;
                          } catch (Object x)
                                   log.error ("queue-publisher: "~x.toString);
                      }
        }           
}



/******************************************************************************
        

******************************************************************************/

class PersistQueue  : ClusterQueue
{
        private QueueFile[char[]] queueSet;
        private QueueFile[]       queueList;

        /**********************************************************************

        **********************************************************************/

        this (Cluster cluster, uint limit, double sleep)
        {
                super (cluster, limit, sleep);
        }

        /**********************************************************************

        **********************************************************************/

        final synchronized QueueFile lookup (char[] name)
        {
                auto p = name in queueSet;
                if (p is null)
                   {
                   // name is currently a reference only; copy it
                   name = name.dup;

                   log.trace ("creating new queue for channel '" ~ name ~ "'");
                
                   // place new ChannelQueue into the list
                   auto queue = new QueueFile (log, cluster.createChannel(name), limit);
                   queueSet[name] = queue;
                   queueList ~= queue;
                   return queue;
                   }
                   
                return *p;
        }

        /**********************************************************************

        **********************************************************************/

        final bool put (char[] name, ClusterContent content)
        {       
                // stuff content into the appropriate queue
                auto queue = lookup (name);
                auto ret = queue.push (content);

                // notify immediately if we just transitioned from 0
                if (ret && queue.size is 1)
                    publish (queue.channel);

                return ret;
        }       

        /**********************************************************************

        **********************************************************************/

        final ClusterContent get (char[] name)
        {
                return cast(ClusterContent) lookup(name).pop;
        }   

        /**********************************************************************

                Workaround for a compiler bug in 0.018

        **********************************************************************/

        private final synchronized void copy (QueueFile[] dst, QueueFile[] src)
        {
                dst[] = src;
        }   

        /**********************************************************************

        **********************************************************************/

        final void watchdog ()
        {       
                auto len = queueList.length;
                auto list = (cast(QueueFile*) alloca(len * QueueFile.sizeof))[0..len];

                // clone the list of queues to avoid stalling everything
                copy (list, queueList);

                // synchronized (this)
                //               list[] = queueList;

                foreach (q; list)
                        {
                        if (q.size)
                            publish (q.channel);

                        if (q.isDirty)
                           {
                           q.flush;
                           log.info ("flushed "~q.channel.name~" to disk");
                           }
                        }
        }    
}


/+

/******************************************************************************
        
******************************************************************************/

class MemoryQueue : ClusterQueue
{
        private HashMap queueSet;
        
        /**********************************************************************

        **********************************************************************/

        this (Cluster cluster, uint limit, Interval sleep)
        {
                queueSet = new HashMap (256);
                super (cluster, limit, sleep);
        }

        /**********************************************************************

        **********************************************************************/

        final ChannelQueue lookup (char[] channel)
        {
                return cast(ChannelQueue) queueSet.get (channel);
        }

        /**********************************************************************

        **********************************************************************/

        bool put (char[] name, ClusterContent content)
        {       
                if ((used + content.length) < limit)
                   {
                   // select the appropriate queue
                   auto queue = lookup (name);
                   if (queue is null)
                      {
                      // name is currently a reference only; copy it
                      name = name.dup;

                      log.trace ("creating new queue for channel '" ~ name ~ "'");

                      // place new ChannelQueue into the list
                      queueSet.put (name, queue = new ChannelQueue (cluster.createChannel (name)));
                      }

                   queue.put (cast (ClusterContent) content.dup);
                   used += content.length;
                   return true;
                   }
                return false;
        }       

        /**********************************************************************

        **********************************************************************/

        synchronized ClusterContent get (char[] name)
        {
                ClusterContent ret = null;
                auto queue = lookup (name);

                if (queue)
                   {
                   ret = queue.get;
                   used -= ret.length;
                   }
                return ret;
        }   
        
        /**********************************************************************

        **********************************************************************/

        void watchdog ()
        {       
                foreach (char[] k, Object o; queueSet)
                        {
                        auto q = cast(ChannelQueue) o;
                        if (q.count)
                            publish (q.channel);
                        }
        }           
}


/******************************************************************************
        
******************************************************************************/

private class ChannelQueue
{
        private Link            head,           // head of the Queue
                                tail;           // tail of the Queue
        private int             count;          // number of items present
        IChannel                channel;        // Queue channel

        /**********************************************************************

        **********************************************************************/

        private static class Link
        {
                Link            prev,
                                next;
                ClusterContent  data;

                static Link     freeList;

                /**************************************************************

                **************************************************************/

                Link append (Link after)
                {
                        if (after)
                           {
                           next = after.next;

                           // patch 'next' to point at me
                           if (next)
                               next.prev = this;

                           //patch 'after' to point at me
                           prev = after;
                           after.next = this;
                           }
                        return this;
                }

                /**************************************************************

                **************************************************************/

                Link unlink ()
                {
                        // make 'prev' and 'next' entries see each other
                        if (prev)
                            prev.next = next;

                        if (next)
                            next.prev = prev;

                        // Murphy's law 
                        next = prev = null;
                        return this;
                }

                /**************************************************************

                **************************************************************/

                Link create ()
                {
                        Link l;

                        if (freeList)
                           {
                           l = freeList;
                           freeList = l.next;
                           }
                        else
                           l = new Link;
                        return l;                       
                }

                /**************************************************************

                **************************************************************/

                void destroy ()
                {
                        next = freeList;
                        freeList = this;
                        this.data = null;
                }
        }


        /**********************************************************************

        **********************************************************************/

        this (IChannel channel)
        {
                head = tail = new Link;
                this.channel = channel;
        }

        /**********************************************************************

                Add the specified content to the queue at the current
                tail position, and bump tail to the next Link

        **********************************************************************/

        void put (ClusterContent content)
        {
                tail.data = content;
                tail = tail.create.append (tail);
                ++count;
        }       

        /**********************************************************************

                Extract from the head, which is the oldest item in the 
                queue. The removed Link is then appended to the tail, 
                ready for another put. Head is adjusted to point at the
                next valid queue entry.

        **********************************************************************/

        ClusterContent get ()
        {
                if (head !is tail)
                   {
                   auto l = head;
                   head = head.next;
                   auto ret = l.data;
                   l.unlink;
                   l.destroy;
                   --count;
                   return ret;
                   }
                return null;                   
        }       
}

+/
