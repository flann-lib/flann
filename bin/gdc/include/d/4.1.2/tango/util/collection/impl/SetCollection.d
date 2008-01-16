/*
 File: SetCollection.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 13Oct95  dl                 Create
 22Oct95  dl                 add includeElements
 28jan97  dl                 make class public
*/


module tango.util.collection.impl.SetCollection;

private import  tango.util.collection.model.Set,
                tango.util.collection.model.Iterator;

private import  tango.util.collection.impl.Collection;

/**
 *
 * SetCollection extends MutableImpl to provide
 * default implementations of some Set operations. 
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
 *
**/

public abstract class SetCollection(T) : Collection!(T), Set!(T)
{
        alias Set!(T).add               add;
        alias Collection!(T).remove     remove;
        alias Collection!(T).removeAll  removeAll;


        /**
         * Initialize at version 0, an empty count, and null screener
        **/

        protected this ()
        {
                super();
        }

        /**
         * Initialize at version 0, an empty count, and supplied screener
        **/
        protected this (Predicate screener)
        {
                super(screener);
        }

        /**
         * Implements tango.util.collection.impl.SetCollection.SetCollection.includeElements
         * See_Also: tango.util.collection.impl.SetCollection.SetCollection.includeElements
        **/

        public void add (Iterator!(T) e)
        {
                foreach (value; e)
                         add (value);
        }


        version (VERBOSE)
        {
        // Default implementations of Set methods

        /**
         * Implements tango.util.collection.Set.including
         * See_Also: tango.util.collection.Set.including
        **/
        public final Set including (T element)
        {
                auto c = cast(MutableSet) duplicate();
                c.include(element);
                return c;
        }
        } // version

        /***********************************************************************

                Implements tango.util.collection.impl.Collection.Collection.removeAll
                See_Also: tango.util.collection.impl.Collection.Collection.removeAll

                Has to be here rather than in the superclass to satisfy
                D interface idioms

        ************************************************************************/

        public void removeAll (Iterator!(T) e)
        {
                while (e.more)
                       removeAll (e.get);
        }

        /***********************************************************************

                Implements tango.util.collection.impl.Collection.Collection.removeElements
                See_Also: tango.util.collection.impl.Collection.Collection.removeElements

                Has to be here rather than in the superclass to satisfy
                D interface idioms

        ************************************************************************/

        public void remove (Iterator!(T) e)
        {
                while (e.more)
                       remove (e.get);
        }
}


