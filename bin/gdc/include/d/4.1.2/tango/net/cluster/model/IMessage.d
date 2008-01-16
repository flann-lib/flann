/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.model.IMessage;

public import tango.time.Time;

public import tango.io.protocol.model.IReader,
              tango.io.protocol.model.IWriter;

/*******************************************************************************

*******************************************************************************/

interface IMessage : IReadable, IWritable
{
        /***********************************************************************

        ***********************************************************************/
        
        char[] toString ();

        /***********************************************************************

        ***********************************************************************/
        
        IMessage clone ();

        /***********************************************************************

        ***********************************************************************/
        
        void reply (char[] channel);

        /***********************************************************************

        ***********************************************************************/
        
        char[] reply ();

        /***********************************************************************

        ***********************************************************************/
        
        void time (Time value);

        /***********************************************************************

        ***********************************************************************/
        
        Time time ();

        /***********************************************************************

        ***********************************************************************/
        
        void id (uint value);

        /***********************************************************************

        ***********************************************************************/
        
        uint id ();

        /***********************************************************************

        ***********************************************************************/
        
        void execute ();
}


/******************************************************************************

        Manages the lifespan of an ICache entry. These loaders effectively
        isolate the cache from whence the content is derived. It's a good
        idea to employ this abstraction where appropriate, since it allows
        the cache source to change with minimal (if any) impact on client
        code.

******************************************************************************/

interface IMessageLoader
{
        /**********************************************************************

                Load a cache entry from wherever the content is persisted.
                The 'time' argument represents that belonging to a stale
                entry, which can be used to optimize the loader operation
                (no need to perform a full load where there's already a 
                newer version in an L2 cache). This 'time' value will be
                long.min where was no such stale entry.

        **********************************************************************/

        IMessage load ();
}



