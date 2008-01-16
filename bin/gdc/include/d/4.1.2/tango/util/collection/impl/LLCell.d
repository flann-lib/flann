/*
 File: LLCell.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from tango.util.collection.d  working file

*/


module tango.util.collection.impl.LLCell;

private import tango.util.collection.impl.Cell;

private import tango.util.collection.model.Comparator;

/**
 *
 *
 * LLCells extend Cells with standard linkedlist next-fields,
 * and provide a standard operations on them.
 * <P>
 * LLCells are pure implementation tools. They perform
 * no argument checking, no result screening, and no synchronization.
 * They rely on user-level classes (see for example LinkedList) to do such things.
 * Still, the class is made `public' so that you can use them to
 * build other kinds of collections or whatever, not just the ones
 * currently supported.
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public class LLCell(T) : Cell!(T)
{
        alias Comparator!(T) ComparatorT;


        protected LLCell next_;

        /**
         * Return the next cell (or null if none)
        **/

        public LLCell next()
        {
                return next_;
        }

        /**
         * set to point to n as next cell
         * @param n, the new next cell
        **/

        public void next(LLCell n)
        {
                next_ = n;
        }

        public this (T v, LLCell n)
        {
                super(v);
                next_ = n;
        }

        public this (T v)
        {
                this(v, null);
        }

        public this ()
        {
                this(T.init, null);
        }


        /**
         * Splice in p between current cell and whatever it was previously 
         * pointing to
         * @param p, the cell to splice
        **/

        public final void linkNext(LLCell p)
        {
                if (p !is null)
                    p.next_ = next_;
                next_ = p;
        }

        /**
         * Cause current cell to skip over the current next() one, 
         * effectively removing the next element from the list
        **/

        public final void unlinkNext()
        {
                if (next_ !is null)
                    next_ = next_.next_;
        }

        /**
         * Linear search down the list looking for element (using T.equals)
         * @param element to look for
         * Returns: the cell containing element, or null if no such
        **/

        public final LLCell find(T element)
        {
                for (LLCell p = this; p !is null; p = p.next_)
                     if (p.element() == element)
                         return p;
                return null;
        }

        /**
         * return the number of cells traversed to find first occurrence
         * of a cell with element() element, or -1 if not present
        **/

        public final int index(T element)
        {
                int i = 0;
                for (LLCell p = this; p !is null; p = p.next_)
                    {
                    if (p.element() == element)
                        return i;
                    else
                       ++i;
                    }
                return -1;
        }

        /**
         * Count the number of occurrences of element in list
        **/

        public final int count(T element)
        {
                int c = 0;
                for (LLCell p = this; p !is null; p = p.next_)
                     if (p.element() == element)
                         ++c;
                return c;
        }

        /**
         * return the number of cells in the list
        **/

        public final int _length()
        {
                int c = 0;
                for (LLCell p = this; p !is null; p = p.next_)
                     ++c;
                return c;
        }

        /**
         * return the cell representing the last element of the list
         * (i.e., the one whose next() is null
        **/

        public final LLCell tail()
        {
                LLCell p = this;
                for ( ; p.next_ !is null; p = p.next_)
                    {}
                return p;
        }

        /**
         * return the nth cell of the list, or null if no such
        **/

        public final LLCell nth(int n)
        {
                LLCell p = this;
                for (int i = 0; i < n; ++i)
                     p = p.next_;
                return p;
        }


        /**
         * make a copy of the list; i.e., a new list containing new cells
         * but including the same elements in the same order
        **/

        public final LLCell copyList()
        {
                LLCell newlist = null;
                newlist = duplicate();
                LLCell current = newlist;

                for (LLCell p = next_; p !is null; p = p.next_)
                    {
                    current.next_ = p.duplicate();
                    current = current.next_;
                    }
                current.next_ = null;
                return newlist;
        }

        /**
         * Clone is SHALLOW; i.e., just makes a copy of the current cell
        **/

        private final LLCell duplicate()
        {
                return new LLCell(element(), next_);
        }

        /**
         * Basic linkedlist merge algorithm.
         * Merges the lists head by fst and snd with respect to cmp
         * @param fst head of the first list
         * @param snd head of the second list
         * @param cmp a Comparator used to compare elements
         * Returns: the merged ordered list
        **/

        public final static LLCell merge(LLCell fst, LLCell snd, ComparatorT cmp)
        {
                LLCell a = fst;
                LLCell b = snd;
                LLCell hd = null;
                LLCell current = null;
                for (;;)
                    {
                    if (a is null)
                       {
                       if (hd is null)
                           hd = b;
                       else
                          current.next(b);
                       return hd;
                       }
                    else
                       if (b is null)
                          {
                          if (hd is null)
                              hd = a;
                          else
                             current.next(a);
                          return hd;
                          }

                    int diff = cmp.compare(a.element(), b.element());
                    if (diff <= 0)
                       {
                       if (hd is null)
                           hd = a;
                       else
                          current.next(a);
                       current = a;
                       a = a.next();
                       }
                    else
                       {
                       if (hd is null)
                           hd = b;
                       else
                          current.next(b);
                       current = b;
                       b = b.next();
                       }
                    }
                return null;
        }

        /**
         * Standard list splitter, used by sort.
         * Splits the list in half. Returns the head of the second half
         * @param s the head of the list
         * Returns: the head of the second half
        **/

        public final static LLCell split(LLCell s)
        {
                LLCell fast = s;
                LLCell slow = s;

                if (fast is null || fast.next() is null)
                    return null;

                while (fast !is null)
                      {
                      fast = fast.next();
                      if (fast !is null && fast.next() !is null)
                         {
                         fast = fast.next();
                         slow = slow.next();
                         }
                      }

                LLCell r = slow.next();
                slow.next(null);
                return r;

        }

        /**
         * Standard merge sort algorithm
         * @param s the list to sort
         * @param cmp, the comparator to use for ordering
         * Returns: the head of the sorted list
        **/

        public final static LLCell mergeSort(LLCell s, ComparatorT cmp)
        {
                if (s is null || s.next() is null)
                    return s;
                else
                   {
                   LLCell right = split(s);
                   LLCell left = s;
                   left = mergeSort(left, cmp);
                   right = mergeSort(right, cmp);
                   return merge(left, right, cmp);
                   }
        }

}

