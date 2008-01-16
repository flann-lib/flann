/*
 File: ArraySeq.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 2Oct95  dl@cs.oswego.edu   refactored from DASeq.d
 13Oct95  dl                 Changed protection statuses

*/

        
module tango.util.collection.ArraySeq;

private import  tango.util.collection.model.Iterator,
                tango.util.collection.model.Sortable,
                tango.util.collection.model.Comparator,
                tango.util.collection.model.GuardIterator;

private import  tango.util.collection.impl.SeqCollection,
                tango.util.collection.impl.AbstractIterator;


/**
 *
 * Dynamically allocated and resized Arrays.
 * 
 * Beyond implementing its interfaces, adds methods
 * to adjust capacities. The default heuristics for resizing
 * usually work fine, but you can adjust them manually when
 * you need to.
 *
 * ArraySeqs are generally like java.util.Vectors. But unlike them,
 * ArraySeqs do not actually allocate arrays when they are constructed.
 * Among other consequences, you can adjust the capacity `for free'
 * after construction but before adding elements. You can adjust
 * it at other times as well, but this may lead to more expensive
 * resizing. Also, unlike Vectors, they release their internal arrays
 * whenever they are empty.
 *
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
 *
**/

public class ArraySeq(T) : SeqCollection!(T), Sortable!(T)
{
        alias SeqCollection!(T).remove     remove;
        alias SeqCollection!(T).removeAll  removeAll;

        /**
         * The minimum capacity of any non-empty buffer
        **/

        public static int minCapacity = 16;


        // instance variables

        /**
         * The elements, or null if no buffer yet allocated.
        **/

        package T array[];


        // constructors

        /**
         * Make a new empty ArraySeq. 
        **/

        public this ()
        {
                this (null, null, 0);
        }

        /**
         * Make an empty ArraySeq with given element screener
        **/

        public this (Predicate screener)
        {
                this (screener, null, 0);
        }

        /**
         * Special version of constructor needed by clone()
        **/
        package this (Predicate s, T[] b, int c)
        {
                super(s);
                array = b;
                count = c;
        }

        /**
         * Make an independent copy. The elements themselves are not cloned
        **/

        public final ArraySeq duplicate()
        {
                int cap = count;
                if (cap is 0)
                    return new ArraySeq (screener, null, 0);
                else
                   {
                   if (cap < minCapacity)
                       cap = minCapacity;

                   T newArray[] = new T[cap];
                   //System.copy (array[0].sizeof, array, 0, newArray, 0, count);

                   newArray[0..count] = array[0..count];
                   return new ArraySeq!(T)(screener, newArray, count);
                   }
        }

        // methods introduced _in ArraySeq

        /**
         * return the current internal buffer capacity (zero if no buffer allocated).
         * Returns: capacity (always greater than or equal to size())
        **/

        public final int capacity()
        {
                return (array is null) ? 0 : array.length;
        }

        /**
         * Set the internal buffer capacity to max(size(), newCap).
         * That is, if given an argument less than the current
         * number of elements, the capacity is just set to the
         * current number of elements. Thus, elements are never lost
         * by setting the capacity. 
         * 
         * @param newCap the desired capacity.
         * Returns: condition: 
         * <PRE>
         * capacity() >= size() &&
         * version() != PREV(this).version() == (capacity() != PREV(this).capacity())
         * </PRE>
        **/

        public final void capacity(int newCap)
        {
                if (newCap < count)
                    newCap = count;

                if (newCap is 0)
                   {
                   clear();
                   }
                else
                   if (array is null)
                      {
                      array = new T[newCap];
                      incVersion();
                      }
                   else
                      if (newCap !is array.length)
                         {
                         //T newArray[] = new T[newCap];
                         //newArray[0..count] = array[0..count];
                         //array = newArray;
                         array ~= new T[newCap - array.length];
                         incVersion();
                         }
        }


        // Collection methods

        /**
         * Implements tango.util.collection.impl.Collection.Collection.contains
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.Collection.Collection.contains
        **/
        public final bool contains(T element)
        {
                if (! isValidArg (element))
                      return false;

                for (int i = 0; i < count; ++i)
                     if (array[i] == (element))
                         return true;
                return false;
        }

        /**
         * Implements tango.util.collection.impl.Collection.Collection.instances
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.Collection.Collection.instances
        **/
        public final uint instances(T element)
        {
                if (! isValidArg(element))
                      return 0;

                uint c = 0;
                for (uint i = 0; i < count; ++i)
                     if (array[i] == (element))
                         ++c;
                return c;
        }

        /**
         * Implements tango.util.collection.impl.Collection.Collection.elements
         * Time complexity: O(1).
         * See_Also: tango.util.collection.impl.Collection.Collection.elements
        **/
        public final GuardIterator!(T) elements()
        {
                return new ArrayIterator!(T)(this);
        }

        /**
         * Implements tango.util.collection.model.View.View.opApply
         * Time complexity: O(n).
         * See_Also: tango.util.collection.model.View.View.opApply
        **/
        int opApply (int delegate (inout T value) dg)
        {
                auto scope iterator = new ArrayIterator!(T)(this);
                return iterator.opApply (dg);
        }


        // Seq methods:

        /**
         * Implements tango.util.collection.model.Seq.Seq.head.
         * Time complexity: O(1).
         * See_Also: tango.util.collection.model.Seq.Seq.head
        **/
        public final T head()
        {
                checkIndex(0);
                return array[0];
        }

        /**
         * Implements tango.util.collection.model.Seq.Seq.tail.
         * Time complexity: O(1).
         * See_Also: tango.util.collection.model.Seq.Seq.tail
        **/
        public final T tail()
        {
                checkIndex(count -1);
                return array[count -1];
        }

        /**
         * Implements tango.util.collection.model.Seq.Seq.get.
         * Time complexity: O(1).
         * See_Also: tango.util.collection.model.Seq.Seq.get
        **/
        public final T get(int index)
        in {
           checkIndex(index);
           }
        body
        {
                return array[index];
        }

        /**
         * Implements tango.util.collection.model.Seq.Seq.first.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.model.Seq.Seq.first
        **/
        public final int first(T element, int startingIndex = 0)
        {
                if (startingIndex < 0)
                    startingIndex = 0;

                for (int i = startingIndex; i < count; ++i)
                     if (array[i] == (element))
                         return i;
                return -1;
        }

        /**
         * Implements tango.util.collection.model.Seq.Seq.last.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.model.Seq.Seq.last
        **/
        public final int last(T element, int startingIndex = 0)
        {
                if (startingIndex >= count)
                    startingIndex = count -1;
 
                for (int i = startingIndex; i >= 0; --i)
                     if (array[i] == (element))
                         return i;
                return -1;
        }


        /**
         * Implements tango.util.collection.model.Seq.Seq.subseq.
         * Time complexity: O(length).
         * See_Also: tango.util.collection.model.Seq.Seq.subseq
        **/
        public final ArraySeq subset (int from, int _length)
        {
                if (_length > 0)
                   {
                   checkIndex(from);
                   checkIndex(from + _length - 1);

                   T newArray[] = new T[_length];
                   //System.copy (array[0].sizeof, array, from, newArray, 0, _length);

                   newArray[0.._length] = array[from..from+_length];
                   return new ArraySeq!(T)(screener, newArray, _length);
                   }
                else
                   return new ArraySeq!(T)(screener);
        }


        // MutableCollection methods

        /**
         * Implements tango.util.collection.impl.Collection.Collection.clear.
         * Time complexity: O(1).
         * See_Also: tango.util.collection.impl.Collection.Collection.clear
        **/
        public final void clear()
        {
                array = null;
                setCount(0);
        }

        /**
         * Implements tango.util.collection.impl.Collection.Collection.removeOneOf.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.Collection.Collection.removeOneOf
        **/
        public final void remove(T element)
        {
                remove_(element, false);
        }


        /**
         * Implements tango.util.collection.impl.Collection.Collection.replaceOneOf
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.Collection.Collection.replaceOneOf
        **/
        public final void replace(T oldElement, T newElement)
        {
                replace_(oldElement, newElement, false);
        }

        /**
         * Implements tango.util.collection.impl.Collection.Collection.replaceAllOf.
         * Time complexity: O(n * number of replacements).
         * See_Also: tango.util.collection.impl.Collection.Collection.replaceAllOf
        **/
        public final void replaceAll(T oldElement, T newElement)
        {
                replace_(oldElement, newElement, true);
        }

        /**
         * Implements tango.util.collection.impl.Collection.Collection.exclude.
         * Time complexity: O(n * instances(element)).
         * See_Also: tango.util.collection.impl.Collection.Collection.exclude
        **/
        public final void removeAll(T element)
        {
                remove_(element, true);
        }

        /**
         * Implements tango.util.collection.impl.Collection.Collection.take.
         * Time complexity: O(1).
         * Takes the rightmost element of the array.
         * See_Also: tango.util.collection.impl.Collection.Collection.take
        **/
        public final T take()
        {
                T v = tail();
                removeTail();
                return v;
        }


        // SortableCollection methods:


        /**
         * Implements tango.util.collection.SortableCollection.sort.
         * Time complexity: O(n log n).
         * Uses a quicksort-based algorithm.
         * See_Also: tango.util.collection.SortableCollection.sort
        **/
        public void sort(Comparator!(T) cmp)
        {
                if (count > 0)
                   {
                   quickSort(array, 0, count - 1, cmp);
                   incVersion();
                   }
        }


        // MutableSeq methods

        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.prepend.
         * Time complexity: O(n)
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.prepend
        **/
        public final void prepend(T element)
        {
                checkElement(element);
                growBy_(1);
                for (int i = count -1; i > 0; --i)
                     array[i] = array[i - 1];
                array[0] = element;
        }

        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.replaceHead.
         * Time complexity: O(1).
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.replaceHead
        **/
        public final void replaceHead(T element)
        {
                checkElement(element);
                array[0] = element;
                incVersion();
        }

        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.removeHead.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.removeHead
        **/
        public final void removeHead()
        {
                removeAt(0);
        }

        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.append.
         * Time complexity: normally O(1), but O(n) if size() == capacity().
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.append
        **/
        public final void append(T element)
        in {
           checkElement (element);
           }
        body
        {
                int last = count;
                growBy_(1);
                array[last] = element;
        }

        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.replaceTail.
         * Time complexity: O(1).
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.replaceTail
        **/
        public final void replaceTail(T element)
        {
                checkElement(element);
                array[count -1] = element;
                incVersion();
        }

        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.removeTail.
         * Time complexity: O(1).
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.removeTail
        **/
        public final void removeTail()
        {
                checkIndex(0);
                array[count -1] = T.init;
                growBy_( -1);
        }

        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.addAt.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.addAt
        **/
        public final void addAt(int index, T element)
        {
                if (index !is count)
                    checkIndex(index);

                checkElement(element);
                growBy_(1);
                for (int i = count -1; i > index; --i)
                     array[i] = array[i - 1];
                array[index] = element;
        }

        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.remove.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.removeAt
        **/
        public final void removeAt(int index)
        {
                checkIndex(index);
                for (int i = index + 1; i < count; ++i)
                     array[i - 1] = array[i];
                array[count -1] = T.init;
                growBy_( -1);
        }


        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.replaceAt.
         * Time complexity: O(1).
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.replaceAt
        **/
        public final void replaceAt(int index, T element)
        {
                checkIndex(index);
                checkElement(element);
                array[index] = element;
                incVersion();
        }

        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.prepend.
         * Time complexity: O(n + number of elements in e) if (e 
         * instanceof CollectionIterator) else O(n * number of elements in e)
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.prepend
        **/
        public final void prepend(Iterator!(T) e)
        {
                insert_(0, e);
        }

        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.append.
         * Time complexity: O(number of elements in e) 
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.append
        **/
        public final void append(Iterator!(T) e)
        {
                insert_(count, e);
        }

        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.addAt.
         * Time complexity: O(n + number of elements in e) if (e 
         * instanceof CollectionIterator) else O(n * number of elements in e)
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.addAt
        **/
        public final void addAt(int index, Iterator!(T) e)
        {
                if (index !is count)
                    checkIndex(index);
                insert_(index, e);
        }


        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.removeFromTo.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.removeFromTo
        **/
        public final void removeRange (int fromIndex, int toIndex)
        {
                checkIndex(fromIndex);
                checkIndex(toIndex);
                if (fromIndex <= toIndex)
                   {
                   int gap = toIndex - fromIndex + 1;
                   int j = fromIndex;
                   for (int i = toIndex + 1; i < count; ++i)
                        array[j++] = array[i];
 
                   for (int i = 1; i <= gap; ++i)
                        array[count -i] = T.init;
                   addToCount( -gap);
                   }
        }

        /**
         * An implementation of Quicksort using medians of 3 for partitions.
         * Used internally by sort.
         * It is public and static so it can be used  to sort plain
         * arrays as well.
         * @param s, the array to sort
         * @param lo, the least index to sort from
         * @param hi, the greatest index
         * @param cmp, the comparator to use for comparing elements
        **/

        public final static void quickSort(T s[], int lo, int hi, Comparator!(T) cmp)
        {
                if (lo >= hi)
                    return;

                /*
                   Use median-of-three(lo, mid, hi) to pick a partition. 
                   Also swap them into relative order while we are at it.
                */

                int mid = (lo + hi) / 2;

                if (cmp.compare(s[lo], s[mid]) > 0)
                   {
                   T tmp = s[lo];
                   s[lo] = s[mid];
                   s[mid] = tmp; // swap
                   }

                if (cmp.compare(s[mid], s[hi]) > 0)
                   {
                   T tmp = s[mid];
                   s[mid] = s[hi];
                   s[hi] = tmp; // swap

                   if (cmp.compare(s[lo], s[mid]) > 0)
                      {
                      T tmp2 = s[lo];
                      s[lo] = s[mid];
                      s[mid] = tmp2; // swap
                      }
                   }

                int left = lo + 1;           // start one past lo since already handled lo
                int right = hi - 1;          // similarly
                if (left >= right)
                    return;                  // if three or fewer we are done

                T partition = s[mid];

                for (;;)
                    {
                    while (cmp.compare(s[right], partition) > 0)
                           --right;

                    while (left < right && cmp.compare(s[left], partition) <= 0)
                           ++left;

                    if (left < right)
                       {
                       T tmp = s[left];
                       s[left] = s[right];
                       s[right] = tmp; // swap
                       --right;
                       }
                    else
                       break;
                    }

                quickSort(s, lo, left, cmp);
                quickSort(s, left + 1, hi, cmp);
        }

        /***********************************************************************

                expose collection content as an array

        ************************************************************************/

        override public T[] toArray ()
        {
                return array[0..count].dup;
        }
        
        // helper methods

        /**
         * Main method to control buffer sizing.
         * The heuristic used for growth is:
         * <PRE>
         * if out of space:
         *   if need less than minCapacity, grow to minCapacity
         *   else grow by average of requested size and minCapacity.
         * </PRE>
         * <P>
         * For small buffers, this causes them to be about 1/2 full.
         * while for large buffers, it causes them to be about 2/3 full.
         * <P>
         * For shrinkage, the only thing we do is unlink the buffer if it is empty.
         * @param inc, the amount of space to grow by. Negative values mean shrink.
         * Returns: condition: adjust record of count, and if any of
         * the above conditions apply, allocate and copy into a new
         * buffer of the appropriate size.
        **/

        private final void growBy_(int inc)
        {
                int needed = count + inc;
                if (inc > 0)
                   {
                   /* heuristic: */
                   int current = capacity();
                   if (needed > current)
                      {
                      incVersion();
                      int newCap = needed + (needed + minCapacity) / 2;

                      if (newCap < minCapacity)
                          newCap = minCapacity;

                      if (array is null)
                         {
                         array = new T[newCap];
                         }
                      else
                         {
                         //T newArray[] = new T[newCap];
                         //newArray[0..count] = array[0..count];
                         //array = newArray;
                         array ~= new T[newCap - array.length];
                         }
                      }
                   }
                else
                   if (needed is 0)
                       array = null;

                setCount(needed);
        }


        /**
         * Utility to splice in enumerations
        **/

        private final void insert_(int index, Iterator!(T) e)
        {
                if (cast(GuardIterator!(T)) e)
                   { 
                   // we know size!
                   int inc = (cast(GuardIterator!(T)) (e)).remaining();
                   int oldcount = count;
                   int oldversion = vershion;
                   growBy_(inc);

                   for (int i = oldcount - 1; i >= index; --i)
                        array[i + inc] = array[i];

                   int j = index;
                   while (e.more())
                         {
                         T element = e.get();
                         if (!allows (element))
                            { // Ugh. Can only do full rollback
                            for (int i = index; i < oldcount; ++i)
                                 array[i] = array[i + inc];

                            vershion = oldversion;
                            count = oldcount;
                            checkElement(element); // force throw
                            }
                         array[j++] = element;
                         }
                   }
                else
                   if (index is count)
                      { // next best; we can append
                      while (e.more())
                            {
                            T element = e.get();
                            checkElement(element);
                            growBy_(1);
                            array[count -1] = element;
                            }
                      }
                   else
                      { // do it the slow way
                      int j = index;
                      while (e.more())
                            {
                            T element = e.get();
                            checkElement(element);
                            growBy_(1);

                            for (int i = count -1; i > j; --i)
                                 array[i] = array[i - 1];
                            array[j++] = element;
                            }
                      }
        }

        private final void remove_(T element, bool allOccurrences)
        {
                if (! isValidArg(element))
                      return;

                for (int i = 0; i < count; ++i)
                    {
                    while (i < count && array[i] == (element))
                          {
                          for (int j = i + 1; j < count; ++j)
                               array[j - 1] = array[j];

                          array[count -1] = T.init;
                          growBy_( -1);

                          if (!allOccurrences || count is 0)
                               return ;
                          }
                    }
        }

        private final void replace_(T oldElement, T newElement, bool allOccurrences)
        {
                if (isValidArg(oldElement) is false || count is 0)
                    return;

                for (int i = 0; i < count; ++i)
                    {
                    if (array[i] == (oldElement))
                       {
                       checkElement(newElement);
                       array[i] = newElement;
                       incVersion();

                       if (! allOccurrences)
                             return;
                       }
                    }
        }

        /**
         * Implements tango.util.collection.model.View.View.checkImplementation.
         * See_Also: tango.util.collection.model.View.View.checkImplementation
        **/
        public override void checkImplementation()
        {
                super.checkImplementation();
                assert(!(array is null && count !is 0));
                assert((array is null || count <= array.length));

                for (int i = 0; i < count; ++i)
                    {
                    assert(allows(array[i]));
                    assert(instances(array[i]) > 0);
                    assert(contains(array[i]));
                    }
        }

        /***********************************************************************

                opApply() has migrated here to mitigate the virtual call
                on method get()
                
        ************************************************************************/

        static class ArrayIterator(T) : AbstractIterator!(T)
        {
                private int row;
                private T[] array;

                public this (ArraySeq seq)
                {
                        super (seq);
                        array = seq.array;
                }

                public final T get()
                {
                        decRemaining();
                        return array[row++];
                }

                int opApply (int delegate (inout T value) dg)
                {
                        int result;

                        for (auto i=remaining(); i--;)
                            {
                            auto value = get();
                            if ((result = dg(value)) != 0)
                                 break;
                            }
                        return result;
                }
        }
}



debug (Test)
{
        import tango.io.Console;
        
        void main()
        {
                auto array = new ArraySeq!(char[]);
                array.append ("foo");
                array.append ("bar");
                array.append ("wumpus");

                foreach (value; array.elements) {}

                auto elements = array.elements();
                while (elements.more)
                       auto v = elements.get();

                foreach (value; array)
                         Cout (value).newline;

                auto a = array.toArray;
                foreach (value; a)
                         Cout (value).newline;

                 array.checkImplementation();
        }
}
