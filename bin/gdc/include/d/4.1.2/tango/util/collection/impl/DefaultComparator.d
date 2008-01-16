/*
 File: DefaultComparator.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from tango.util.collection.d  working file

*/


module tango.util.collection.impl.DefaultComparator;

private import tango.util.collection.model.Comparator;


/**
 *
 *
 * DefaultComparator provides a general-purpose but slow compare
 * operation. 
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public class DefaultComparator(T) : Comparator!(T)
{

        /**
         * Try various downcasts to find a basis for
         * comparing two elements. If all else fails, just compare
         * hashCodes(). This can be effective when you are
         * using an ordered implementation data structure like trees,
         * but don't really care about ordering.
         *
         * @param fst first argument
         * @param snd second argument
         * Returns: a negative number if fst is less than snd; a
         * positive number if fst is greater than snd; else 0
        **/

        public final int compare(T fst, T snd)
        {
                if (fst is snd)
                    return 0;

                return typeid(T).compare (&fst, &snd);
        }
}
