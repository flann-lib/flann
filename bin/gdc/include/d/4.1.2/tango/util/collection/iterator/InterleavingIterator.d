/*
 File: InterleavingIterator.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 22Oct95  dl@cs.oswego.edu   Created.

*/


module tango.util.collection.iterator.InterleavingIterator;

private import  tango.core.Exception;

private import  tango.util.collection.model.Iterator;

/**
 *
 * InterleavingIterators allow you to combine the elements
 * of two different enumerations as if they were one enumeration
 * before they are seen by their `consumers'.
 * This sometimes allows you to avoid having to use a 
 * Collection object to temporarily combine two sets of Collection elements()
 * that need to be collected together for common processing.
 * <P>
 * The elements are revealed (via get()) in a purely
 * interleaved fashion, alternating between the first and second
 * enumerations unless one of them has been exhausted, in which case
 * all remaining elements of the other are revealed until it too is
 * exhausted. 
 * <P>
 * InterleavingIterators work as wrappers around other Iterators.
 * To build one, you need two existing Iterators.
 * For example, if you want to process together the elements of
 * two Collections a and b, you could write something of the form:
 * <PRE>
 * Iterator items = InterleavingIterator(a.elements(), b.elements());
 * while (items.more()) 
 *  doSomethingWith(items.get());
 * </PRE>
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
 *
**/


public class InterleavingIterator(T) : Iterator!(T)
{

        /**
         * The first source; nulled out once it is exhausted
        **/

        private Iterator!(T) fst_;

        /**
         * The second source; nulled out once it is exhausted
        **/

        private Iterator!(T) snd_;

        /**
         * The source currently being used
        **/

        private Iterator!(T) current_;



        /**
         * Make an enumeration interleaving elements from fst and snd
        **/

        public this (Iterator!(T) fst, Iterator!(T) snd)
        {
                fst_ = fst;
                snd_ = snd;
                current_ = snd_; // flip will reset to fst (if it can)
                flip();
        }

        /**
         * Implements java.util.Iterator.more
        **/
        public final bool more()
        {
                return current_ !is null;
        }

        /**
         * Implements java.util.Iterator.get.
        **/
        public final T get()
        {
                if (current_ is null)
                        throw new NoSuchElementException("exhausted iterator");
                else
                {
                        // following line may also throw ex, but there's nothing
                        // reasonable to do except propagate
                        auto result = current_.get();
                        flip();
                        return result;
                }
        }


        int opApply (int delegate (inout T value) dg)
        {
                int result;

                while (current_)
                      {
                      auto value = get();
                      if ((result = dg(value)) != 0)
                           break;
                      }
                return result;
        }

        /**
         * Alternate sources
        **/

        private final void flip()
        {
                if (current_ is fst_)
                {
                        if (snd_ !is null && !snd_.more())
                                snd_ = null;
                        if (snd_ !is null)
                                current_ = snd_;
                        else
                        {
                                if (fst_ !is null && !fst_.more())
                                        fst_ = null;
                                current_ = fst_;
                        }
                }
                else
                {
                        if (fst_ !is null && !fst_.more())
                                fst_ = null;
                        if (fst_ !is null)
                                current_ = fst_;
                        else
                        {
                                if (snd_ !is null && !snd_.more())
                                        snd_ = null;
                                current_ = snd_;
                        }
                }
        }


}

