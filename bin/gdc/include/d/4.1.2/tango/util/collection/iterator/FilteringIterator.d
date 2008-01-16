/*
 File: FilteringIterator.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 22Oct95  dl@cs.oswego.edu   Created.

*/


module tango.util.collection.iterator.FilteringIterator;

private import tango.core.Exception;

private import tango.util.collection.model.Iterator;

/**
 *
 * FilteringIterators allow you to filter out elements from
 * other enumerations before they are seen by their `consumers'
 * (i.e., the callers of `get').
 *
 * FilteringIterators work as wrappers around other Iterators.
 * To build one, you need an existing Iterator (perhaps one
 * from coll.elements(), for some Collection coll), and a Predicate
 * object (i.e., implementing interface Predicate). 
 * For example, if you want to screen out everything but Panel
 * objects from a collection coll that might hold things other than Panels,
 * write something of the form:
 * ---
 * Iterator e = coll.elements();
 * Iterator panels = FilteringIterator(e, IsPanel);
 * while (panels.more())
 *  doSomethingWith(cast(Panel)(panels.get()));
 * ---
 * To use this, you will also need to write a little class of the form:
 * ---
 * class IsPanel : Predicate {
 *  bool predicate(Object v) { return ( 0 !is cast(Panel)v; }
 * }
 * ---
 * See_Also: tango.util.collection.Predicate.predicate
 * author: Doug Lea
 *
**/

public class FilteringIterator(T) : Iterator!(T)
{
        alias bool delegate(T) Predicate;
        
        // instance variables

        /**
         * The enumeration we are wrapping
        **/

        private Iterator!(T) src_;

        /**
         * The screening predicate
        **/

        private Predicate pred_;

        /**
         * The sense of the predicate. False means to invert
        **/

        private bool sign_;

        /**
         * The next element to hand out
        **/

        private T get_;

        /**
         * True if we have a next element 
        **/

        private bool haveNext_;

        /**
         * Make a Filter using src for the elements, and p as the screener,
         * selecting only those elements of src for which p is true
        **/

        public this (Iterator!(T) src, Predicate p)
        {
                this(src, p, true);
        }

        /**
         * Make a Filter using src for the elements, and p as the screener,
         * selecting only those elements of src for which p.predicate(v) == sense.
         * A value of true for sense selects only values for which p.predicate
         * is true. A value of false selects only those for which it is false.
        **/
        public this (Iterator!(T) src, Predicate p, bool sense)
        {
                src_ = src;
                pred_ = p;
                sign_ = sense;
                findNext();
        }

        /**
         * Implements java.util.Iterator.more
        **/

        public final bool more()
        {
                return haveNext_;
        }

        /**
         * Implements java.util.Iterator.get.
        **/
        public final T get()
        {
                if (! haveNext_)
                      throw new NoSuchElementException("exhausted enumeration");
                else
                   {
                   auto result = get_;
                   findNext();
                   return result;
                   }
        }


        int opApply (int delegate (inout T value) dg)
        {
                int result;

                while (haveNext_)
                      {
                      auto value = get();
                      if ((result = dg(value)) != 0)
                           break;
                      }
                return result;
        }


        /**
         * Traverse through src_ elements finding one passing predicate
        **/
        private final void findNext()
        {
                haveNext_ = false;

                for (;;)
                    {
                    if (! src_.more())
                          return ;
                    else
                       {
                       try {
                           auto v = src_.get();
                           if (pred_(v) is sign_)
                              {
                              haveNext_ = true;
                              get_ = v;
                              return;
                              }
                           } catch (NoSuchElementException ex)
                                   {
                                   return;
                                   }
                       }
                    }
        }
}

