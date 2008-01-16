/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: May 2004
        
        author:         Kris

*******************************************************************************/

module tango.util.log.model.IHierarchy;

public import tango.util.log.model.ILevel;

/*******************************************************************************

        The Logger hierarchy Interface. We use this to break the
        interdependency between a couple of modules        

*******************************************************************************/

interface IHierarchy
{
        /**********************************************************************

                Return the name of this Hierarchy

        **********************************************************************/

        char[] getName ();

        /**********************************************************************

                Return the address of this Hierarchy. This is typically
                attached when sending events to remote monitors.

        **********************************************************************/

        char[] getAddress ();

        /***********************************************************************
                
                Configure a context

        ***********************************************************************/

        void context (Context context);

        /***********************************************************************
                
                Return the configured context

        ***********************************************************************/

        Context context ();

        /***********************************************************************
                
                Context for a hierarchy, used for customizing behaviour
                of log hierarchies. You can use this to implement dynamic
                log-levels, based upon filtering or some other mechanism

        ***********************************************************************/

        interface Context
        {
                /// return a label for this context
                char[] label ();
                
                /// first arg is the setting of the logger itself, and
                /// the second arg is what kind of message we're being
                /// asked to produce
                bool isEnabled (ILevel.Level setting, ILevel.Level target);
        }
}
