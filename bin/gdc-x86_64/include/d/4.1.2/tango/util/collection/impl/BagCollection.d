/*
 File: BagCollection.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 13Oct95  dl                 Create
 22Oct95  dl                 add addElements
 28jan97  dl                 make class public
*/


module tango.util.collection.impl.BagCollection;

private import  tango.util.collection.model.Bag,
                tango.util.collection.model.Iterator;

private import  tango.util.collection.impl.Collection;

/**
 *
 * MutableBagImpl extends MutableImpl to provide
 * default implementations of some Bag operations. 
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
 *
**/

public abstract class BagCollection(V) : Collection!(V), Bag!(V)
{
        alias Bag!(V).add               add;
        alias Collection!(V).remove     remove;
        alias Collection!(V).removeAll  removeAll;

        
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
         * Implements tango.util.collection.MutableBag.addElements
         * See_Also: tango.util.collection.MutableBag.addElements
        **/

        public final void add(Iterator!(V) e)
        {
                foreach (value; e)
                         add (value);
        }


        // Default implementations of Bag methods

version (VERBOSE)
{
        /**
         * Implements tango.util.collection.Bag.addingIfAbsent
         * See_Also: tango.util.collection.Bag.addingIfAbsent
        **/
        public final Bag addingIf(V element)
        {
                Bag c = duplicate();
                c.addIf(element);
                return c;
        }


        /**
         * Implements tango.util.collection.Bag.adding
         * See_Also: tango.util.collection.Bag.adding
        **/

        public final Bag adding(V element)
        {
                Bag c = duplicate();
                c.add(element);
                return c;
        }
} // version


        /***********************************************************************

                Implements tango.util.collection.impl.Collection.Collection.removeAll
                See_Also: tango.util.collection.impl.Collection.Collection.removeAll

                Has to be here rather than in the superclass to satisfy
                D interface idioms

        ************************************************************************/

        public void removeAll (Iterator!(V) e)
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

        public void remove (Iterator!(V) e)
        {
                while (e.more)
                       remove (e.get);
        }
}

