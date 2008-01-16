/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.tina.ClusterTask;

/*******************************************************************************


*******************************************************************************/

private import tango.core.Thread;

private import tango.net.cluster.tina.Cluster;

/*******************************************************************************

        Quick bootstrap for cluster connectivity 

*******************************************************************************/

static this ()
{
        auto cluster = (new Cluster).join;
        Thread.setLocal (0, cast(void*) cluster.createChannel("task"));
}

