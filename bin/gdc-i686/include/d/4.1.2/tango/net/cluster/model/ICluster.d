/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.model.ICluster;

public  import  tango.util.log.Logger;

public  import  tango.net.cluster.model.IChannel,
                tango.net.cluster.model.IMessage,
                tango.net.cluster.model.IConsumer;

/*******************************************************************************

        The contract exposed by each QOS implementation. This is the heart
        of the cluster package, designed with multiple implementations in 
        mind. It should be reasonably straightforward to construct specific
        implementations upon a database, pub/sub system, or other substrates.

*******************************************************************************/

interface ICluster
{
        /***********************************************************************
                
                Create a channel instance. Every cluster operation has
                a channel provided as an argument

        ***********************************************************************/
        
        IChannel createChannel (char[] channel);

        /***********************************************************************

                Return the Logger associated with this cluster

        ***********************************************************************/
        
        Logger log ();
}
