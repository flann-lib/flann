/*
 File: SetView.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from collections.d  working file

*/


module tango.util.collection.model.SetView;

private import tango.util.collection.model.View;

/**
 * Sets provide an include operations for adding
 * an element only if it is not already present.
 * They also add a guarantee:
 * With sets,
 * you can be sure that the number of occurrences of any
 * element is either zero or one.
 *
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
 *
**/

public interface SetView(T) : View!(T)
{
version (VERBOSE)
{
        /**
         * Construct a new Collection that is a clone of self except
         * that it has indicated element. This can be used
         * to create a series of collections, each differing from the
         * other only in that they contain additional elements.
         *
         * @param element the element to include in the new collection
         * Returns: a new collection c, with the matches as this, except that
         * c.has(element)
         * Throws: IllegalElementException if !canInclude(element)
        **/

        public Set including (T element);
        public alias including opCat;
} // version
}

