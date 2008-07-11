/*
 File: CircularSeq.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from store.d  working file
 13Oct95  dl                 Changed protection statuses
*/

module tango.util.collection.CircularSeq;

private import  tango.util.collection.model.Iterator,
                tango.util.collection.model.GuardIterator;

private import  tango.util.collection.impl.CLCell,
                tango.util.collection.impl.SeqCollection,
                tango.util.collection.impl.AbstractIterator;


/**
 * Circular linked lists. Publically Implement only those
 * methods defined in interfaces.
 * author: Doug Lea
**/
public class CircularSeq(T) : SeqCollection!(T)
{
        alias CLCell!(T) CLCellT;

        alias SeqCollection!(T).remove     remove;
        alias SeqCollection!(T).removeAll  removeAll;

        // instance variables

        /**
         * The head of the list. Null if empty
        **/
        package CLCellT list;

        // constructors

        /**
         * Make an empty list with no element screener
        **/
        public this ()
        {
                this(null, null, 0);
        }

        /**
         * Make an empty list with supplied element screener
        **/
        public this (Predicate screener)
        {
                this(screener, null, 0);
        }

        /**
         * Special version of constructor needed by clone()
        **/
        protected this (Predicate s, CLCellT h, int c)
        {
                super(s);
                list = h;
                count = c;
        }

        /**
         * Make an independent copy of the list. Elements themselves are not cloned
        **/
        public final CircularSeq duplicate()
        {
                if (list is null)
                    return new CircularSeq (screener, null, 0);
                else
                   return new CircularSeq (screener, list.copyList(), count);
        }


        // Collection methods

        /**
         * Implements tango.util.collection.impl.Collection.Collection.contains
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.Collection.Collection.contains
        **/
        public final bool contains(T element)
        {
                if (!isValidArg(element) || list is null)
                    return false;
                return list.find(element) !is null;
        }

        /**
         * Implements tango.util.collection.impl.Collection.Collection.instances
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.Collection.Collection.instances
        **/
        public final uint instances(T element)
        {
                if (!isValidArg(element) || list is null)
                    return 0;
                return list.count(element);
        }

        /**
         * Implements tango.util.collection.impl.Collection.Collection.elements
         * Time complexity: O(1).
         * See_Also: tango.util.collection.impl.Collection.Collection.elements
        **/
        public final GuardIterator!(T) elements()
        {
                return new CellIterator!(T)(this);
        }

        /**
         * Implements tango.util.collection.model.View.View.opApply
         * Time complexity: O(n).
         * See_Also: tango.util.collection.model.View.View.opApply
        **/
        int opApply (int delegate (inout T value) dg)
        {
                auto scope iterator = new CellIterator!(T)(this);
                return iterator.opApply (dg);
        }


        // Seq methods

        /**
         * Implements tango.util.collection.model.Seq.Seq.head.
         * Time complexity: O(1).
         * See_Also: tango.util.collection.model.Seq.Seq.head
        **/
        public final T head()
        {
                return firstCell().element();
        }

        /**
         * Implements tango.util.collection.model.Seq.Seq.tail.
         * Time complexity: O(1).
         * See_Also: tango.util.collection.model.Seq.Seq.tail
        **/
        public final T tail()
        {
                return lastCell().element();
        }

        /**
         * Implements tango.util.collection.model.Seq.Seq.get.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.model.Seq.Seq.get
        **/
        public final T get(int index)
        {
                return cellAt(index).element();
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

                CLCellT p = list;
                if (p is null || !isValidArg(element))
                    return -1;

                for (int i = 0; true; ++i)
                    {
                    if (i >= startingIndex && p.element() == (element))
                        return i;

                    p = p.next();
                    if (p is list)
                        break;
                    }
                return -1;
        }


        /**
         * Implements tango.util.collection.model.Seq.Seq.last.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.model.Seq.Seq.last
        **/
        public final int last(T element, int startingIndex = 0)
        {
                if (!isValidArg(element) || count is 0)
                    return -1;

                if (startingIndex >= size())
                    startingIndex = size() - 1;

                if (startingIndex < 0)
                    startingIndex = 0;

                CLCellT p = cellAt(startingIndex);
                int i = startingIndex;
                for (;;)
                    {
                    if (p.element() == (element))
                        return i;
                    else
                       if (p is list)
                           break;
                       else
                          {
                          p = p.prev();
                          --i;
                          }
                    }
                return -1;
        }

        /**
         * Implements tango.util.collection.model.Seq.Seq.subseq.
         * Time complexity: O(length).
         * See_Also: tango.util.collection.model.Seq.Seq.subseq
        **/
        public final CircularSeq subset (int from, int _length)
        {
                if (_length > 0)
                   {
                   checkIndex(from);
                   CLCellT p = cellAt(from);
                   CLCellT newlist = new CLCellT(p.element());
                   CLCellT current = newlist;

                   for (int i = 1; i < _length; ++i)
                       {
                       p = p.next();
                       if (p is null)
                           checkIndex(from + i); // force exception

                       current.addNext(p.element());
                       current = current.next();
                       }
                   return new CircularSeq (screener, newlist, _length);
                   }
                else
                   return new CircularSeq ();
        }

        // MutableCollection methods

        /**
         * Implements tango.util.collection.impl.Collection.Collection.clear.
         * Time complexity: O(1).
         * See_Also: tango.util.collection.impl.Collection.Collection.clear
        **/
        public final void clear()
        {
                list = null;
                setCount(0);
        }

        /**
         * Implements tango.util.collection.impl.Collection.Collection.exclude.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.Collection.Collection.exclude
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
        public final void remove (T element)
        {
                remove_(element, false);
        }

        /**
         * Implements tango.util.collection.impl.Collection.Collection.replaceOneOf
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.Collection.Collection.replaceOneOf
        **/
        public final void replace (T oldElement, T newElement)
        {
                replace_(oldElement, newElement, false);
        }

        /**
         * Implements tango.util.collection.impl.Collection.Collection.replaceAllOf.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.Collection.Collection.replaceAllOf
        **/
        public final void replaceAll (T oldElement, T newElement)
        {
                replace_(oldElement, newElement, true);
        }


        /**
         * Implements tango.util.collection.impl.Collection.Collection.take.
         * Time complexity: O(1).
         * takes the last element on the list.
         * See_Also: tango.util.collection.impl.Collection.Collection.take
        **/
        public final T take()
        {
                auto v = tail();
                removeTail();
                return v;
        }



        // MutableSeq methods

        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.prepend.
         * Time complexity: O(1).
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.prepend
        **/
        public final void prepend(T element)
        {
                checkElement(element);
                if (list is null)
                    list = new CLCellT(element);
                else
                   list = list.addPrev(element);
                incCount();
        }

        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.replaceHead.
         * Time complexity: O(1).
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.replaceHead
        **/
        public final void replaceHead(T element)
        {
                checkElement(element);
                firstCell().element(element);
                incVersion();
        }

        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.removeHead.
         * Time complexity: O(1).
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.removeHead
        **/
        public final void removeHead()
        {
                if (firstCell().isSingleton())
                   list = null;
                else
                   {
                   auto n = list.next();
                   list.unlink();
                   list = n;
                   }
                decCount();
        }

        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.append.
         * Time complexity: O(1).
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.append
        **/
        public final void append(T element)
        {
                if (list is null)
                    prepend(element);
                else
                   {
                   checkElement(element);
                   list.prev().addNext(element);
                   incCount();
                   }
        }

        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.replaceTail.
         * Time complexity: O(1).
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.replaceTail
        **/
        public final void replaceTail(T element)
        {
                checkElement(element);
                lastCell().element(element);
                incVersion();
        }


        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.removeTail.
         * Time complexity: O(1).
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.removeTail
        **/
        public final void removeTail()
        {
                auto l = lastCell();
                if (l is list)
                    list = null;
                else
                   l.unlink();
                decCount();
        }

        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.addAt.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.addAt
        **/
        public final void addAt(int index, T element)
        {
                if (index is 0)
                    prepend(element);
                else
                   {
                   checkElement(element);
                   cellAt(index - 1).addNext(element);
                   incCount();
                   }
        }

        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.replaceAt.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.replaceAt
        **/
        public final void replaceAt(int index, T element)
        {
                checkElement(element);
                cellAt(index).element(element);
                incVersion();
        }

        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.removeAt.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.removeAt
        **/
        public final void removeAt(int index)
        {
                if (index is 0)
                    removeHead();
                else
                   {
                   cellAt(index - 1).unlinkNext();
                   decCount();
                   }
        }

        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.prepend.
         * Time complexity: O(number of elements in e).
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.prepend
        **/
        public final void prepend(Iterator!(T) e)
        {
                CLCellT hd = null;
                CLCellT current = null;
      
                while (e.more())
                      {
                      auto element = e.get();
                      checkElement(element);
                      incCount();

                      if (hd is null)
                         {
                         hd = new CLCellT(element);
                         current = hd;
                         }
                      else
                         {
                         current.addNext(element);
                         current = current.next();
                         }
                      }

                if (list is null)
                    list = hd;
                else
                   if (hd !is null)
                      {
                      auto tl = list.prev();
                      current.next(list);
                      list.prev(current);
                      tl.next(hd);
                      hd.prev(tl);
                      list = hd;
                      }
        }

        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.append.
         * Time complexity: O(number of elements in e).
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.append
        **/
        public final void append(Iterator!(T) e)
        {
                if (list is null)
                    prepend(e);
                else
                   {
                   CLCellT current = list.prev();
                   while (e.more())
                         {
                         T element = e.get();
                         checkElement(element);
                         incCount();
                         current.addNext(element);
                         current = current.next();
                         }
                   }
        }

        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.addAt.
         * Time complexity: O(size() + number of elements in e).
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.addAt
        **/
        public final void addAt(int index, Iterator!(T) e)
        {
                if (list is null || index is 0)
                    prepend(e);
                else
                   {
                   CLCellT current = cellAt(index - 1);
                   while (e.more())
                         {
                         T element = e.get();
                         checkElement(element);
                         incCount();
                         current.addNext(element);
                         current = current.next();
                         }
                   }
        }


        /**
         * Implements tango.util.collection.impl.SeqCollection.SeqCollection.removeFromTo.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.SeqCollection.SeqCollection.removeFromTo
        **/
        public final void removeRange (int fromIndex, int toIndex)
        {
                checkIndex(toIndex);
                CLCellT p = cellAt(fromIndex);
                CLCellT last = list.prev();
                for (int i = fromIndex; i <= toIndex; ++i)
                    {
                    decCount();
                    CLCellT n = p.next();
                    p.unlink();
                    if (p is list)
                       {
                       if (p is last)
                          {
                          list = null;
                          return ;
                          }
                       else
                          list = n;
                       }
                    p = n;
                    }
        }


        // helper methods

        /**
         * return the first cell, or throw exception if empty
        **/
        private final CLCellT firstCell()
        {
                if (list !is null)
                    return list;

                checkIndex(0);
                return null; // not reached!
        }

        /**
         * return the last cell, or throw exception if empty
        **/
        private final CLCellT lastCell()
        {
                if (list !is null)
                    return list.prev();

                checkIndex(0);
                return null; // not reached!
        }

        /**
         * return the index'th cell, or throw exception if bad index
        **/
        private final CLCellT cellAt(int index)
        {
                checkIndex(index);
                return list.nth(index);
        }

        /**
         * helper for remove/exclude
        **/
        private final void remove_(T element, bool allOccurrences)
        {
                if (!isValidArg(element) || list is null)
                    return;

                CLCellT p = list;
                for (;;)
                    {
                    CLCellT n = p.next();
                    if (p.element() == (element))
                       {
                       decCount();
                       p.unlink();
                       if (p is list)
                          {
                          if (p is n)
                             {
                             list = null;
                             break;
                             }
                          else
                             list = n;
                          }

                       if (! allOccurrences)
                             break;
                       else
                          p = n;
                       }
                    else
                       if (n is list)
                           break;
                       else
                          p = n;
                    }
        }


        /**
         * helper for replace *
        **/
        private final void replace_(T oldElement, T newElement, bool allOccurrences)
        {
                if (!isValidArg(oldElement) || list is null)
                    return;

                CLCellT p = list;
                do {
                   if (p.element() == (oldElement))
                      {
                      checkElement(newElement);
                      incVersion();
                      p.element(newElement);
                      if (! allOccurrences)
                            return;
                      }
                   p = p.next();
                } while (p !is list);
        }

        // ImplementationCheckable methods

        /**
         * Implements tango.util.collection.model.View.View.checkImplementation.
         * See_Also: tango.util.collection.model.View.View.checkImplementation
        **/

        public override void checkImplementation()
        {
                super.checkImplementation();

                assert(((count is 0) is (list is null)));
                assert((list is null || list._length() is count));

                if (list is null)
                    return;

                int c = 0;
                CLCellT p = list;
                do {
                   assert(p.prev().next() is p);
                   assert(p.next().prev() is p);
                   assert(allows(p.element()));
                   assert(instances(p.element()) > 0);
                   assert(contains(p.element()));
                   p = p.next();
                   ++c;
                   } while (p !is list);

                assert(c is count);
        }


        /***********************************************************************

                opApply() has migrated here to mitigate the virtual call
                on method get()
                
        ************************************************************************/

        static class CellIterator(T) : AbstractIterator!(T)
        {
                private CLCellT cell;

                public this (CircularSeq seq)
                {
                        super (seq);
                        cell = seq.list;
                }

                public final T get()
                {
                        decRemaining();
                        auto v = cell.element();
                        cell = cell.next();
                        return v;
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
                auto array = new CircularSeq!(char[]);
                array.append ("foo");
                array.append ("bar");
                array.append ("wumpus");

                foreach (value; array.elements) {}

                auto elements = array.elements();
                while (elements.more)
                       auto v = elements.get();

                foreach (value; array)
                         Cout (value).newline;

                array.checkImplementation();
        }
}
