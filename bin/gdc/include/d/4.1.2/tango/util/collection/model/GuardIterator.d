/*
 File: GuardIterator.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from collections.d  working file

*/


module tango.util.collection.model.GuardIterator;

private import tango.util.collection.model.Iterator;

/**
 *
 * CollectionIterator extends the standard java.util.Iterator
 * interface with two additional methods.
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
 *
**/

public interface GuardIterator(V) : Iterator!(V)
{
        /**
         * Return true if the collection that constructed this enumeration
         * has been detectably modified since construction of this enumeration.
         * Ability and precision of detection of this condition can vary
         * across collection class implementations.
         * more() is false whenever corrupted is true.
         *
         * Returns: true if detectably corrupted.
        **/

        public bool corrupted();

        /**
         * Return the number of elements in the enumeration that have
         * not yet been traversed. When corrupted() is true, this 
         * number may (or may not) be greater than zero even if more() 
         * is false. Exception recovery mechanics may be able to
         * use this as an indication that recovery of some sort is
         * warranted. However, it is not necessarily a foolproof indication.
         * <P>
         * You can also use it to pack enumerations into arrays. For example:
         * <PRE>
         * Object arr[] = new Object[e.numberOfRemainingElement()]
         * int i = 0;
         * while (e.more()) arr[i++] = e.value();
         * </PRE>
         * <P>
         * For the converse case, 
         * See_Also: tango.util.collection.iterator.ArrayIterator.ArrayIterator
         * Returns: the number of untraversed elements
        **/

        public uint remaining();
}


public interface PairIterator(K, V) : GuardIterator!(V)
{
        alias GuardIterator!(V).get     get;
        alias GuardIterator!(V).opApply opApply;
        
        public V get (inout K key);

        int opApply (int delegate (inout K key, inout V value) dg);        
}

