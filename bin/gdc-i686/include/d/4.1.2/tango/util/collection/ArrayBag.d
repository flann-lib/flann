/*
 File: ArrayBag.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from store.d  working file
 13Oct95  dl                 Changed protection statuses

*/


module tango.util.collection.ArrayBag;

private import  tango.core.Exception;

private import  tango.util.collection.model.GuardIterator;

private import  tango.util.collection.impl.CLCell,
                tango.util.collection.impl.BagCollection,
                tango.util.collection.impl.AbstractIterator;



/**
 *
 * Linked Buffer implementation of Bags. The Bag consists of
 * any number of buffers holding elements, arranged in a list.
 * Each buffer holds an array of elements. The size of each
 * buffer is the value of chunkSize that was current during the
 * operation that caused the Bag to grow. The chunkSize() may
 * be adjusted at any time. (It is not considered a version change.)
 * 
 * <P>
 * All but the final buffer is always kept full.
 * When a buffer has no elements, it is released (so is
 * available for garbage collection).
 * <P>
 * ArrayBags are good choices for collections in which
 * you merely put a lot of things in, and then look at
 * them via enumerations, but don't often look for
 * particular elements.
 * 
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public class ArrayBag(T) : BagCollection!(T)
{
        alias CLCell!(T[]) CLCellT;

        alias BagCollection!(T).remove     remove;
        alias BagCollection!(T).removeAll  removeAll;

        /**
         * The default chunk size to use for buffers
        **/

        public static int defaultChunkSize = 32;

        // instance variables

        /**
         * The last node of the circular list of chunks. Null if empty.
        **/

        package CLCellT tail;

        /**
         * The number of elements of the tail node actually used. (all others
         * are kept full).
        **/
        protected int lastCount;

        /**
         * The chunk size to use for making next buffer
        **/

        protected int chunkSize_;

        // constructors

        /**
         * Make an empty buffer.
        **/
        public this ()
        {
                this (null, 0, null, 0, defaultChunkSize);
        }

        /**
         * Make an empty buffer, using the supplied element screener.
        **/

        public this (Predicate s)
        {
                this (s, 0, null, 0, defaultChunkSize);
        }

        /**
         * Special version of constructor needed by clone()
        **/
        protected this (Predicate s, int n, CLCellT t, int lc, int cs)
        {
                super (s);
                count = n;
                tail = t;
                lastCount = lc;
                chunkSize_ = cs;
        }

        /**
         * Make an independent copy. Does not clone elements.
        **/ 

        public final ArrayBag duplicate ()
        {
                if (count is 0)
                    return new ArrayBag (screener);
                else
                   {
                   CLCellT h = tail.copyList();
                   CLCellT p = h;

                   do {
                      T[] obuff = p.element();
                      T[] nbuff = new T[obuff.length];

                      for (int i = 0; i < obuff.length; ++i)
                           nbuff[i] = obuff[i];

                      p.element(nbuff);
                      p = p.next();
                      } while (p !is h);

                   return new ArrayBag (screener, count, h, lastCount, chunkSize_);
                   }
        }


        /**
         * Report the chunk size used when adding new buffers to the list
        **/

        public final int chunkSize()
        {
                return chunkSize_;
        }

        /**
         * Set the chunk size to be used when adding new buffers to the 
         * list during future add() operations.
         * Any value greater than 0 is OK. (A value of 1 makes this a
         * into very slow simulation of a linked list!)
        **/

        public final void chunkSize (int newChunkSize)
        {
                if (newChunkSize > 0)
                    chunkSize_ = newChunkSize;
                else
                   throw new IllegalArgumentException("Attempt to set negative chunk size value");
        }

        // Collection methods

        /*
          This code is pretty repetitive, but I don't know a nice way to
          separate traversal logic from actions
        */

        /**
         * Implements tango.util.collection.impl.Collection.Collection.contains
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.Collection.Collection.contains
        **/
        public final bool contains(T element)
        {
                if (!isValidArg(element) || count is 0)
                     return false;

                CLCellT p = tail.next();

                for (;;)
                    {
                    T[] buff = p.element();
                    bool isLast = p is tail;

                    int n;
                    if (isLast)
                        n = lastCount;
                    else
                       n = buff.length;

                    for (int i = 0; i < n; ++i)
                        {
                        if (buff[i] == (element))
                        return true;
                        }

                    if (isLast)
                        break;
                    else
                       p = p.next();
                    }
                return false;
        }

        /**
         * Implements tango.util.collection.impl.Collection.Collection.instances
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.Collection.instances
        **/
        public final uint instances(T element)
        {
                if (!isValidArg(element) || count is 0)
                    return 0;

                uint c = 0;
                CLCellT p = tail.next();

                for (;;)
                    {
                    T[] buff = p.element();
                    bool isLast = p is tail;

                    int n;
                    if (isLast)
                        n = lastCount;
                    else
                       n = buff.length;

                    for (int i = 0; i < n; ++i)
                       {
                       if (buff[i] == (element))
                           ++c;
                       }

                    if (isLast)
                        break;
                    else
                       p = p.next();
                    }
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

        // MutableCollection methods

        /**
         * Implements tango.util.collection.impl.Collection.Collection.clear.
         * Time complexity: O(1).
         * See_Also: tango.util.collection.impl.Collection.Collection.clear
        **/
        public final void clear()
        {
                setCount(0);
                tail = null;
                lastCount = 0;
        }

        /**
         * Implements tango.util.collection.impl.Collection.Collection.removeAll.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.Collection.Collection.removeAll
        **/
        public final void removeAll (T element)
        {
                remove_(element, true);
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
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.Collection.Collection.replaceAllOf
        **/
        public final void replaceAll(T oldElement, T newElement)
        {
                replace_(oldElement, newElement, true);
        }

        /**
         * Implements tango.util.collection.impl.Collection.Collection.take.
         * Time complexity: O(1).
         * Takes the least element.
         * See_Also: tango.util.collection.impl.Collection.Collection.take
        **/
        public final T take()
        {
                if (count !is 0)
                   {
                   T[] buff = tail.element();
                   T v = buff[lastCount -1];
                   buff[lastCount -1] = T.init;
                   shrink_();
                   return v;
                   }
                checkIndex(0);
                return T.init; // not reached
        }



        // MutableBag methods

        /**
         * Implements tango.util.collection.MutableBag.addIfAbsent.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.MutableBag.addIfAbsent
        **/
        public final void addIf(T element)
        {
                if (!contains(element))
                     add (element);
        }


        /**
         * Implements tango.util.collection.MutableBag.add.
         * Time complexity: O(1).
         * See_Also: tango.util.collection.MutableBag.add
        **/
        public final void add (T element)
        {
                checkElement(element);

                incCount();
                if (tail is null)
                   {
                   tail = new CLCellT(new T[chunkSize_]);
                   lastCount = 0;
                   }

                T[] buff = tail.element();
                if (lastCount is buff.length)
                   {
                   buff = new T[chunkSize_];
                   tail.addNext(buff);
                   tail = tail.next();
                   lastCount = 0;
                   }

                buff[lastCount++] = element;
        }

        /**
         * helper for remove/exclude
        **/

        private final void remove_(T element, bool allOccurrences)
        {
                if (!isValidArg(element) || count is 0)
                     return ;

                CLCellT p = tail;

                for (;;)
                    {
                    T[] buff = p.element();
                    int i = (p is tail) ? lastCount - 1 : buff.length - 1;
                    
                    while (i >= 0)
                          {
                          if (buff[i] == (element))
                             {
                             T[] lastBuff = tail.element();
                             buff[i] = lastBuff[lastCount -1];
                             lastBuff[lastCount -1] = T.init;
                             shrink_();
        
                             if (!allOccurrences || count is 0)
                                  return ;
        
                             if (p is tail && i >= lastCount)
                                 i = lastCount -1;
                             }
                          else
                             --i;
                          }

                    if (p is tail.next())
                        break;
                    else
                       p = p.prev();
                }
        }

        private final void replace_(T oldElement, T newElement, bool allOccurrences)
        {
                if (!isValidArg(oldElement) || count is 0 || oldElement == (newElement))
                     return ;

                CLCellT p = tail.next();

                for (;;)
                    {
                    T[] buff = p.element();
                    bool isLast = p is tail;

                    int n;
                    if (isLast)
                        n = lastCount;
                    else
                       n = buff.length;

                    for (int i = 0; i < n; ++i)
                        {
                        if (buff[i] == (oldElement))
                           {
                           checkElement(newElement);
                           incVersion();
                           buff[i] = newElement;
                           if (!allOccurrences)
                           return ;
                           }
                        }

                    if (isLast)
                        break;
                    else
                       p = p.next();
                    }
        }

        private final void shrink_()
        {
                decCount();
                lastCount--;
                if (lastCount is 0)
                   {
                   if (count is 0)
                       clear();
                   else
                      {
                      CLCellT tmp = tail;
                      tail = tail.prev();
                      tmp.unlink();
                      T[] buff = tail.element();
                      lastCount = buff.length;
                      }
                   }
        }

        // ImplementationCheckable methods

        /**
         * Implements tango.util.collection.model.View.View.checkImplementation.
         * See_Also: tango.util.collection.model.View.View.checkImplementation
        **/
        public override void checkImplementation()
        {

                super.checkImplementation();
                assert(chunkSize_ >= 0);
                assert(lastCount >= 0);
                assert(((count is 0) is (tail is null)));

                if (tail is null)
                    return ;

                int c = 0;
                CLCellT p = tail.next();

                for (;;)
                    {
                    T[] buff = p.element();
                    bool isLast = p is tail;

                    int n;
                    if (isLast)
                        n = lastCount;
                    else
                       n = buff.length;
   
                    c += n;
                    for (int i = 0; i < n; ++i)
                        {
                        auto v = buff[i];
                        assert(allows(v) && contains(v));
                        }
   
                    if (isLast)
                        break;
                    else
                       p = p.next();
                    }

                assert(c is count);

        }



        /***********************************************************************

                opApply() has migrated here to mitigate the virtual call
                on method get()
                
        ************************************************************************/

        static class ArrayIterator(T) : AbstractIterator!(T)
        {
                private CLCellT cell;
                private T[]     buff;
                private int     index;

                public this (ArrayBag bag)
                {
                        super(bag);
                        cell = bag.tail;
                        
                        if (cell)
                            buff = cell.element();  
                }

                public final T get()
                {
                        decRemaining();
                        if (index >= buff.length)
                           {
                           cell = cell.next();
                           buff = cell.element();
                           index = 0;
                           }
                        return buff[index++];
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
                auto bag = new ArrayBag!(char[]);
                bag.add ("foo");
                bag.add ("bar");
                bag.add ("wumpus");

                foreach (value; bag.elements) {}

                auto elements = bag.elements();
                while (elements.more)
                       auto v = elements.get();

                foreach (value; bag)
                         Cout (value).newline;

                bag.checkImplementation();

                Cout (bag).newline;
        }
}
