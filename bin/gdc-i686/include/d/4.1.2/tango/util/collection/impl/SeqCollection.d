/*
 File: SeqCollection.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 13Oct95  dl                 Create
 28jab97  dl                 make class public
*/


module tango.util.collection.impl.SeqCollection;

private import  tango.util.collection.model.Seq,
                tango.util.collection.model.Iterator;

private import  tango.util.collection.impl.Collection;



/**
 *
 * SeqCollection extends MutableImpl to provide
 * default implementations of some Seq operations. 
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
 *
**/

public abstract class SeqCollection(T) : Collection!(T), Seq!(T)
{
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


        // Default implementations of Seq methods

version (VERBOSE)
{
        /**
         * Implements tango.util.collection.model.Seq.Seq.insertingAt.
         * See_Also: tango.util.collection.model.Seq.Seq.insertingAt
        **/
        public final Seq insertingAt(int index, T element)
        {
                MutableSeq c = null;
                //      c = (cast(MutableSeq)clone());
                c = (cast(MutableSeq)duplicate());
                c.insert(index, element);
                return c;
        }

        /**
         * Implements tango.util.collection.model.Seq.Seq.removingAt.
         * See_Also: tango.util.collection.model.Seq.Seq.removingAt
        **/
        public final Seq removingAt(int index)
        {
                MutableSeq c = null;
                //      c = (cast(MutableSeq)clone());
                c = (cast(MutableSeq)duplicate());
                c.remove(index);
                return c;
        }


        /**
         * Implements tango.util.collection.model.Seq.Seq.replacingAt
         * See_Also: tango.util.collection.model.Seq.Seq.replacingAt
        **/
        public final Seq replacingAt(int index, T element)
        {
                MutableSeq c = null;
                //      c = (cast(MutableSeq)clone());
                c = (cast(MutableSeq)duplicate());
                c.replace(index, element);
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

        /***********************************************************************

                Implements tango.util.collection.model.Seq.opIndexAssign
                See_Also: tango.util.collection.model.Seq.replaceAt

                Calls replaceAt(index, element);

        ************************************************************************/
        public final void opIndexAssign (T element, int index)
        {
                replaceAt(index, element);
        }

        /***********************************************************************

                Implements tango.util.collection.model.SeqView.opSlice
                See_Also: tango.util.collection.model.SeqView.subset

                Calls subset(begin, (end - begin));

        ************************************************************************/
        public SeqCollection opSlice(int begin, int end)
        {
                return subset(begin, (end - begin));
        }

}

