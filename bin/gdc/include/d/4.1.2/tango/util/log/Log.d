/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: May 2004
        version:        Hierarchy moved due to circular dependencies; Oct 2004
        
        author:         Kris

*******************************************************************************/

module tango.util.log.Log;

public  import  tango.util.log.Logger;

private import  tango.util.log.Event,
                tango.util.log.Hierarchy;

private import  tango.util.log.model.ILevel;

/*******************************************************************************

        Manager for routing Logger calls to the default hierarchy. Note 
        that you may have multiple hierarchies per application, but must
        access the hierarchy directly for getRootLogger() and getLogger()
        methods within each additional instance.

*******************************************************************************/

class Log : ILevel
{
        static private  Hierarchy base;

        private static  ILevel.Level[char[]] map;
        
        private struct  Pair {char[] name; ILevel.Level value;}

        private static  Pair[] Pairs = 
                        [
                        {"TRACE",  ILevel.Level.Trace},
                        {"Trace",  ILevel.Level.Trace},
                        {"trace",  ILevel.Level.Trace},
                        {"INFO",   ILevel.Level.Info},
                        {"Info",   ILevel.Level.Info},
                        {"info",   ILevel.Level.Info},
                        {"WARN",   ILevel.Level.Warn},
                        {"Warn",   ILevel.Level.Warn},
                        {"warn",   ILevel.Level.Warn},
                        {"ERROR",  ILevel.Level.Error},
                        {"Error",  ILevel.Level.Error},
                        {"error",  ILevel.Level.Error},
                        {"Fatal",  ILevel.Level.Fatal},
                        {"FATAL",  ILevel.Level.Fatal},
                        {"fatal",  ILevel.Level.Fatal},
                        {"NONE",   ILevel.Level.None},
                        {"None",   ILevel.Level.None},
                        {"none",   ILevel.Level.None},
                        ];

        /***********************************************************************
        
                This is a singleton, so hide the constructor.

        ***********************************************************************/

        private this ()
        {
        }

        /***********************************************************************
        
                Initialize the base hierarchy.                
              
        ***********************************************************************/

        static this ()
        {
                base = new Hierarchy ("tango");
                Event.initialize ();

                // populate a map of acceptable level names
                foreach (p; Pairs)
                         map[p.name] = p.value;
        }

        /***********************************************************************

                Return the root Logger instance. This is the ancestor of
                all loggers and, as such, can be used to manipulate the 
                entire hierarchy. For instance, setting the root 'level' 
                attribute will affect all other loggers in the tree.

        ***********************************************************************/

        static Logger getRootLogger ()
        {
                return base.getRootLogger ();
        }

        /***********************************************************************
        
                Return an instance of the named logger. Names should be
                hierarchical in nature, using dot notation (with '.') to 
                separate each name section. For example, a typical name 
                might be something like "tango.io.Buffer".

                If the logger does not currently exist, it is created and
                inserted into the hierarchy. A parent will be attached to
                it, which will be either the root logger or the closest
                ancestor in terms of the hierarchical name space.

        ***********************************************************************/

        static Logger getLogger (char[] name)
        {
                return base.getLogger (name);
        }

        /***********************************************************************
        
                Return the singleton hierarchy.

        ***********************************************************************/

        static Hierarchy getHierarchy ()
        {
                return base;
        }

        /***********************************************************************
        
                Return the level of a given name

        ***********************************************************************/

        static ILevel.Level level (char[] name, ILevel.Level def=ILevel.Level.Trace)
        {
                auto p = name in map;
                if (p)
                    return *p;
                return def;
        }
}
