/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        April 2004: Initial release

*******************************************************************************/

module tango.net.cluster.model.ICache;

private import tango.time.Time;

/******************************************************************************

******************************************************************************/

interface ICache (K, V)
{
        /**********************************************************************

                Get the cache entry identified by the given key

        **********************************************************************/

        V get (K key);

        /**********************************************************************

                Place an entry into the cache and associate it with the
                provided key. Note that there can be only one entry for
                any particular key. If two keys entries are added with
                the same key, the second effectively overwrites the first.

                Returns what it was given

        **********************************************************************/

        bool put (K key, V entry, Time time = Time.init);

        /**********************************************************************

                Remove (and return) the cache entry associated with the
                provided key. The entry will not be removed if it's time
                attribute is newer than the (optional) specified 'timelimit'.

                Returns null if there is no such entry.

        **********************************************************************/

        V remove (K key, Time time = Time.max);
}

