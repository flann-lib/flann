/*
 File: Sortable.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from collections.d  working file

*/


module tango.util.collection.model.Sortable;

private import  tango.util.collection.model.Dispenser,
                tango.util.collection.model.Comparator;


/**
 *
 *
 * Sortable is a mixin interface for MutableCollections
 * supporting a sort method that accepts
 * a user-supplied Comparator with a compare method that
 * accepts any two Objects and returns -1/0/+1 depending on whether
 * the first is less than, equal to, or greater than the second.
 * <P>
 * After sorting, but in the absence of other mutative operations,
 * Sortable Collections guarantee that enumerations
 * appear in sorted order;  that is if a and b are two elements
 * obtained in succession from nextElement(), that 
 * <PRE>
 * comparator().compare(a, b) <= 0.
 * </PRE>
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public interface Sortable(T) : Dispenser!(T)
{

        /**
         * Sort the current elements with respect to cmp.compare.
        **/

        public void sort(Comparator!(T) cmp);
}


