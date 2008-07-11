/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        July 2004: Initial release      
        
        author:         Kris

*******************************************************************************/

module tango.net.cluster.tina.CmdParser;

private import  tango.util.Arguments;

private import  tango.text.convert.Integer;

private import  tango.util.log.Log,
                tango.util.log.Configurator;

/******************************************************************************
        
        Extends the ArgParser to support/extract common arguments

******************************************************************************/

class CmdParser : Arguments
{
        Logger  log;
        ushort  port;
        uint    size;
        bool    help;

        /**********************************************************************

        **********************************************************************/

        this (char[] name)
        {
                log = Log.getLogger (name);

                // default logging is info, not trace
                log.setLevel (log.Level.Info);
        }

        /**********************************************************************

        **********************************************************************/

        void parse (char[][] args)
        {
                define("h");
                define("log").parameters(1);
                define("port").parameters(1);
                define("size").parameters(1);
                
                super.parse(args);
                
                if (this.contains("h"))
                    help = true;
                if (this.contains("log"))
                    log.setLevel(Log.level(this["log"]));
                if (this.contains("port"))
                    port = cast(ushort)atoi(this["port"]);
                if (this.contains("size"))
                    size = atoi(this["size"]);
        }
}
