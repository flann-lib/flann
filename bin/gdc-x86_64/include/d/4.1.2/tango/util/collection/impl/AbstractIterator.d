/*
 File: AbstractIterator.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from tango.util.collection.d  working file
 13Oct95  dl                 Changed protection statuses
  9Apr97  dl                 made class public
*/


module tango.util.collection.impl.AbstractIterator;

private import  tango.core.Exception;

private import  tango.util.collection.model.View,
                tango.util.collection.model.GuardIterator;
                


/**
 *
 * A convenient base class for implementations of GuardIterator
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public abstract class AbstractIterator(T) : GuardIterator!(T)
{
        /**
         * The collection being enumerated
        **/

        private View!(T) view;

        /**
         * The version number of the collection we got upon construction
        **/

        private uint mutation;

        /**
         * The number of elements we think we have left.
         * Initialized to view.size() upon construction
        **/

        private uint togo;
        

        protected this (View!(T) v)
        {
                view = v;
                togo = v.size();
                mutation = v.mutation();
        }

        /**
         * Implements tango.util.collection.impl.Collection.CollectionIterator.corrupted.
         * Claim corruption if version numbers differ
         * See_Also: tango.util.collection.impl.Collection.CollectionIterator.corrupted
        **/

        public final bool corrupted()
        {
                return mutation != view.mutation;
        }

        /**
         * Implements tango.util.collection.impl.Collection.CollectionIterator.numberOfRemaingingElements.
         * See_Also: tango.util.collection.impl.Collection.CollectionIterator.remaining
        **/
        public final uint remaining()
        {
                return togo;
        }

        /**
         * Implements tango.util.collection.model.Iterator.more.
         * Return true if remaining > 0 and not corrupted
         * See_Also: tango.util.collection.model.Iterator.more
        **/
        public final bool more()
        {
                return togo > 0 && mutation is view.mutation;
        }

        /**
         * Subclass utility. 
         * Tries to decrement togo, raising exceptions
         * if it is already zero or if corrupted()
         * Always call as the first line of get.
        **/
        protected final void decRemaining()
        {
                if (mutation != view.mutation)
                    throw new CorruptedIteratorException ("Collection modified during iteration");

                if (togo is 0)
                    throw new NoSuchElementException ("exhausted enumeration");

                --togo;
        }
}


public abstract class AbstractMapIterator(K, V) : AbstractIterator!(V), PairIterator!(K, V) 
{
        abstract V get (inout K key);

        protected this (View!(V) c)
        {
                super (c);
        }
}
