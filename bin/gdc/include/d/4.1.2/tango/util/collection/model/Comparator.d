/*
 File: Comparator.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from collections.d  working file

*/


module tango.util.collection.model.Comparator;


/**
 *
 * Comparator is an interface for any class possessing an element
 * comparison method.
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
 *
**/

public interface Comparator(T)
{
        /**
         * @param fst first argument
         * @param snd second argument
         * Returns: a negative number if fst is less than snd; a
         * positive number if fst is greater than snd; else 0
        **/
        public int compare(T fst, T snd);
}

