/*
 File: ArrayIterator.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from tango.util.collection.d  working file
 13Oct95  dl                 Changed protection statuses

*/


module tango.util.collection.iterator.ArrayIterator;

private import tango.core.Exception;

private import tango.util.collection.model.GuardIterator;


/**
 *
 * ArrayIterator allows you to use arrays as Iterators
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public class ArrayIterator(T) : GuardIterator!(T)
{
        private T [] arr_;
        private int cur_;
        private int size_;

        /**
         * Build an enumeration that returns successive elements of the array
        **/
        public this (T arr[])
        {
                // arr_ = arr; cur_ = 0; size_ = arr._length;
                arr_ = arr;
                cur_ = -1;
                size_ = arr.length;
        }

        /**
         * Implements tango.util.collection.impl.Collection.CollectionIterator.remaining
         * See_Also: tango.util.collection.impl.Collection.CollectionIterator.remaining
        **/
        public uint remaining()
        {
                return size_;
        }

        /**
         * Implements java.util.Iterator.more.
         * See_Also: java.util.Iterator.more
        **/
        public bool more()
        {
                return size_ > 0;
        }

        /**
         * Implements tango.util.collection.impl.Collection.CollectionIterator.corrupted.
         * Always false. Inconsistency cannot be reliably detected for arrays
         * Returns: false
         * See_Also: tango.util.collection.impl.Collection.CollectionIterator.corrupted
        **/

        public bool corrupted()
        {
                return false;
        }

        /**
         * Implements java.util.Iterator.get().
         * See_Also: java.util.Iterator.get()
        **/
        public T get()
        {
                if (size_ > 0)
                   {
                   --size_;
                   ++cur_;
                   return arr_[cur_];
                   }
                throw new NoSuchElementException ("Exhausted Iterator");
        }


        int opApply (int delegate (inout T value) dg)
        {
                int result;

                for (auto i=size_; i--;)
                    {
                    auto value = get();
                    if ((result = dg(value)) != 0)
                         break;
                    }
                return result;
        }
}
