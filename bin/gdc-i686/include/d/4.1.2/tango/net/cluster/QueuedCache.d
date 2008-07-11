/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        April 2004: Initial release

        author:         Kris

*******************************************************************************/

module tango.net.cluster.QueuedCache;

private import tango.time.Time;

private import tango.net.cluster.model.ICache;

/******************************************************************************

        QueuedCache extends the basic cache type by adding a limit to
        the number of items contained at any given time. In addition,
        QueuedCache sorts the cache entries such that those entries
        frequently accessed are at the head of the queue, and those
        least frequently accessed are at the tail. When the queue
        becomes full, old entries are dropped from the tail and are
        reused to house new cache entries.

        This is great for keeping commonly accessed items around, while
        limiting the amount of memory used. Typically, the queue size
        would be set in the hundreds (perhaps thousands).

        Note that key.init cannot be used as a valid key

******************************************************************************/

class QueuedCache (K, V) : ICache!(K, V)
{
        private QueuedEntry*[K]         map;

        // head and tail of queue
        private QueuedEntry*            head,
                                        tail;

        /**********************************************************************

                Construct a cache with the specified maximum number of
                entries. Additions to the cache beyond this number will
                reuse the slot of the least-recently-referenced cache
                entry. The concurrency level indicates approximately how
                many threads will content for write access at one time.

        **********************************************************************/

        this (uint capacity)
        {
                auto set = new QueuedEntry [capacity];

                foreach (inout entry; set)
                        {
                        if (tail)
                            tail.next = &entry;
                        entry.prev = tail;
                        tail = &entry;
                        }
                head = set.ptr;
        }

        /**********************************************************************

                Get the cache entry identified by the given key

        **********************************************************************/

        synchronized bool get (K key, inout V value)
        {
                // if we find 'key' then move it to the list head
                auto e = lookup (key);
                if (e)
                   {
                   value = reReference(e).value;
                   return true;
                   }
                return false;
        }

        /**********************************************************************

                Get the cache entry identified by the given key

        **********************************************************************/

        synchronized V get (K key)
        {
                // if we find 'key' then move it to the list head
                auto e = lookup (key);
                if (e)
                    return reReference(e).value;
                return V.init;
        }

        /**********************************************************************

                Place an entry into the cache and associate it with the
                provided key. Note that there can be only one entry for
                any particular key. If two entries are added with the
                same key, the second effectively overwrites the first.

                An optional time value allows for testing whether an
                existing entry is newer than our provided one. Where
                the provided time value is lesser, the put() operation
                will be abandoned and false is returned.

                Returns true if the cache was updated.

        **********************************************************************/

        synchronized bool put (K key, V value, Time time = Time.init)
        {
                assert (key !is key.init);

                auto e = lookup (key);
                if (e is null)
                    map[key] = e = addEntry();
                else
                   if (time < e.time)
                       return false;

                reReference(e).set (key, value, time);
                return true;
        }

        /**********************************************************************

                Same as above, but being careful to avoid heap activity
                where the provided key and value are potentially aliased

        **********************************************************************/

        synchronized bool put (K peek, K delegate() key, V delegate() value, Time time = Time.init)
        {
                assert (peek !is peek.init);

                auto e = lookup (peek);
                if (e is null)
                    map[peek = key()] = e = addEntry();
                else
                   if (time < e.time)
                       return false;
                   else
                      peek = e.key;

                reReference(e).set (peek, value(), time);
                return true;
        }

        /**********************************************************************

                Remove (and return) the cache entry associated with the
                provided key. Returns null if there is no such entry.

        **********************************************************************/

        synchronized V remove (K key, Time time = Time.max)
        {
                auto e = lookup (key);
                if (e && (e.time < time))
                   {
                   auto value = e.value;

                   // don't actually kill the list entry -- just place
                   // it at the list 'tail' ready for subsequent reuse
                   deReference(e).set (K.init, V.init, Time.min);

                   map.remove (key);
                   return value;
                   }

                return V.init;
        }

        /**********************************************************************

                Iterate over elements

                Note that this needs to be synchronized, and can therefore
                be very costly in terms of blocking other threads. Use with
                caution

        **********************************************************************/

        synchronized int opApply (int delegate(inout K key, inout V value) dg)
        {
                int ret;
                foreach (k, v; map)
                         if ((ret = dg(k, v.value)) != 0)
                              break;
                return ret;
        }

        /**********************************************************************


        **********************************************************************/

        private final QueuedEntry* lookup (K key)
        {
                auto p = key in map;
                return (p ? *p : null);
        }

        /**********************************************************************

                Place a cache entry at the tail of the queue. This makes
                it the least-recently referenced.

        **********************************************************************/

        private final QueuedEntry* deReference (QueuedEntry* entry)
        {
                if (entry !is tail)
                   {
                   // adjust head
                   if (entry is head)
                       head = entry.next;

                   // move to tail
                   entry.extract;
                   tail = entry.append (tail);
                   }
                return entry;
        }

        /**********************************************************************

                Move a cache entry to the head of the queue. This makes
                it the most-recently referenced.

        **********************************************************************/

        private final QueuedEntry* reReference (QueuedEntry* entry)
        {
                if (entry !is head)
                   {
                   // adjust tail
                   if (entry is tail)
                       tail = entry.prev;

                   // move to head
                   entry.extract;
                   head = entry.prepend (head);
                   }
                return entry;
        }

        /**********************************************************************

                Add an entry into the queue. If the queue is full, the
                least-recently-referenced entry is reused for the new
                addition.

        **********************************************************************/

        private final QueuedEntry* addEntry ()
        {
                // steal from tail ...
                auto entry = tail;

                // we're re-using an old QueuedEntry, so remove
                // the old name from the hash-table first
                if (entry.key !is entry.key.init)
                    map.remove (entry.key);

                // place at head of list
                return reReference (entry);
        }

        /**********************************************************************

                A doubly-linked list entry, used as a wrapper for queued
                cache entries.

        **********************************************************************/

        private static struct QueuedEntry
        {
                K               key;
                QueuedEntry*    prev,
                                next;
                Time            time;
                V               value;

                /**************************************************************

                        Set this entry with the given arguments.

                **************************************************************/

                QueuedEntry* set (K key, V value, Time time)
                {
                        this.value = value;
                        this.time = time;
                        this.key = key;
                        return this;
                }

                /**************************************************************

                        Insert this entry into the linked-list just in front
                        of the given entry.

                **************************************************************/

                QueuedEntry* prepend (QueuedEntry* before)
                {
                        assert (before);

                        prev = before.prev;

                        // patch 'prev' to point at me
                        if (prev)
                            prev.next = this;

                        //patch 'before' to point at me
                        next = before;
                        return before.prev = this;
                }

                /**************************************************************

                        Add this entry into the linked-list just after the
                        given entry.

                **************************************************************/

                QueuedEntry* append (QueuedEntry* after)
                {
                        assert (after);

                        next = after.next;

                        // patch 'next' to point at me
                        if (next)
                            next.prev = this;

                        //patch 'after' to point at me
                        prev = after;
                        return after.next = this;
                }

                /**************************************************************

                        Remove this entry from the linked-list. The previous
                        and next entries are patched together appropriately.

                **************************************************************/

                QueuedEntry* extract ()
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
        }
}



version (QueuedCache)
{
        import tango.io.Stdout;

        void main()
        {
                new QueuedCache!(int, char[])(100);
                auto map = new QueuedCache!(char[], int)(2);

                map.put ("one", 1);
                map.put ("two", 2);
                int v;
                map.get ("one", v);
                map.put ("three", 3);

                foreach (k, v; map)
                         Stdout.formatln ("{}:{}", k, v);

                foreach (k, v; map.map)
                         Stdout.formatln ("{}:{}", k, v.value);
        }
}
