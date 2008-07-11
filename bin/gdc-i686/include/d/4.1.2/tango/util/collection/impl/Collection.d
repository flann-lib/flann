/*******************************************************************************

        File: Collection.d

        Originally written by Doug Lea and released into the public domain. 
        Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
        Inc, Loral, and everyone contributing, testing, and using this code.

        History:
        Date     Who                What
        24Sep95  dl@cs.oswego.edu   Create from tango.util.collection.d  working file
        13Oct95  dl                 Add assert
        22Oct95  dl                 Add excludeElements, removeElements
        28jan97  dl                 make class public; isolate version changes
        14Dec06  kb                 Adapted for Tango usage
        
********************************************************************************/

module tango.util.collection.impl.Collection;

private import  tango.core.Exception;

private import  tango.util.collection.model.View,
                tango.util.collection.model.Iterator,
                tango.util.collection.model.Dispenser;

/*******************************************************************************

        Collection serves as a convenient base class for most implementations
        of mutable containers. It maintains a version number and element count.
        It also provides default implementations of many collection operations. 

        Authors: Doug Lea

********************************************************************************/

public abstract class Collection(T) : Dispenser!(T)
{
        alias View!(T)          ViewT;

        alias bool delegate(T)  Predicate;


        // instance variables

        /***********************************************************************

                version represents the current version number

        ************************************************************************/

        protected uint vershion;

        /***********************************************************************

                screener hold the supplied element screener

        ************************************************************************/

        protected Predicate screener;

        /***********************************************************************

                count holds the number of elements.

        ************************************************************************/

        protected uint count;

        // constructors

        /***********************************************************************

                Initialize at version 0, an empty count, and supplied screener

        ************************************************************************/

        protected this (Predicate screener = null)
        {
                this.screener = screener;
        }


        /***********************************************************************

        ************************************************************************/

        protected final static bool isValidArg (T element)
        {
                static if (is (T : Object))
                          {
                          if (element is null)
                              return false;
                          }
                return true;
        }

        // Default implementations of Collection methods

        /***********************************************************************

                expose collection content as an array

        ************************************************************************/

        public T[] toArray ()
        {
                auto result = new T[this.size];
        
                int i = 0;
                foreach (e; this)
                         result[i++] = e;

                return result;
        }

        /***********************************************************************

                Time complexity: O(1).
                See_Also: tango.util.collection.impl.Collection.Collection.drained

        ************************************************************************/

        public final bool drained()
        {
                return count is 0;
        }

        /***********************************************************************

                Time complexity: O(1).
                Returns: the count of elements currently in the collection
                See_Also: tango.util.collection.impl.Collection.Collection.size

        ************************************************************************/

        public final uint size()
        {
                return count;
        }

        /***********************************************************************

                Checks if element is an allowed element for this collection.
                This will not throw an exception, but any other attemp to add an
                invalid element will do.

                Time complexity: O(1) + time of screener, if present

                See_Also: tango.util.collection.impl.Collection.Collection.allows

        ************************************************************************/

        public final bool allows (T element)
        {
                return isValidArg(element) &&
                                 (screener is null || screener(element));
        }


        /***********************************************************************

                Time complexity: O(n).
                Default implementation. Fairly sleazy approach.
                (Defensible only when you remember that it is just a default impl.)
                It tries to cast to one of the known collection interface types
                and then applies the corresponding comparison rules.
                This suffices for all currently supported collection types,
                but must be overridden if you define new Collection subinterfaces
                and/or implementations.

                See_Also: tango.util.collection.impl.Collection.Collection.matches

        ************************************************************************/

        public bool matches(ViewT other)
        {
/+
                if (other is null)
                    return false;
                else
                   if (other is this)
                       return true;
                   else
                      if (cast(SortedKeys) this)
                         {
                         if (!(cast(Map) other))
                               return false;
                         else
                            return sameOrderedPairs(cast(Map)this, cast(Map)other);
                         }
                      else
                         if (cast(Map) this)
                            {
                            if (!(cast(Map) other))
                                  return false;
                            else
                               return samePairs(cast(Map)(this), cast(Map)(other));
                            }
                         else
                            if ((cast(Seq) this) || (cast(SortedValues) this))
                                 return sameOrderedElements(this, other);
                            else
                               if (cast(Bag) this)
                                   return sameOccurrences(this, other);
                               else
                                  if (cast(Set) this)
                                      return sameInclusions(this, cast(View)(other));
                                  else
                                     return false;
+/
                   return false;
        }

        // Default implementations of MutableCollection methods

        /***********************************************************************

                Time complexity: O(1).
                See_Also: tango.util.collection.impl.Collection.Collection.version

        ************************************************************************/

        public final uint mutation()
        {
                return vershion;
        }

        // Object methods

        /***********************************************************************

                Default implementation of toString for Collections. Not
                very pretty, but parenthesizing each element means that
                for most kinds of elements, it's conceivable that the
                strings could be parsed and used to build other tango.util.collection.

                Not a very pretty implementation either. Casts are used
                to get at elements/keys

        ************************************************************************/

        public override char[] toString()
        {
                char[16] tmp;
                
                return "<" ~ this.classinfo.name ~ ", size:" ~ itoa(tmp, size()) ~ ">";
        }


        /***********************************************************************

        ************************************************************************/

        protected final char[] itoa(char[] buf, uint i)
        {
                auto j = buf.length;
                
                do {
                   buf[--j] = i % 10 + '0';
                   } while (i /= 10);
                return buf [j..$];
        }
        
        // protected operations on version and count

        /***********************************************************************

                change the version number

        ************************************************************************/

        protected final void incVersion()
        {
                ++vershion;
        }


        /***********************************************************************

                Increment the element count and update version

        ************************************************************************/

        protected final void incCount()
        {
                count++;
                incVersion();
        }

        /***********************************************************************

                Decrement the element count and update version

        ************************************************************************/

        protected final void decCount()
        {
                count--;
                incVersion();
        }


        /***********************************************************************

                add to the element count and update version if changed

        ************************************************************************/

        protected final void addToCount(uint c)
        {
                if (c !is 0)
                   {
                   count += c;
                   incVersion();
                   }
        }
        

        /***********************************************************************

                set the element count and update version if changed

        ************************************************************************/

        protected final void setCount(uint c)
        {
                if (c !is count)
                   {
                   count = c;
                   incVersion();
                   }
        }


        /***********************************************************************

                Helper method left public since it might be useful

        ************************************************************************/

        public final static bool sameInclusions(ViewT s, ViewT t)
        {
                if (s.size !is t.size)
                    return false;

                try { // set up to return false on collection exceptions
                    auto ts = t.elements();
                    while (ts.more)
                          {
                          if (!s.contains(ts.get))
                              return false;
                          }
                    return true;
                    } catch (NoSuchElementException ex)
                            {
                            return false;
                            }
        }

        /***********************************************************************

                Helper method left public since it might be useful

        ************************************************************************/

        public final static bool sameOccurrences(ViewT s, ViewT t)
        {
                if (s.size !is t.size)
                    return false;

                auto ts = t.elements();
                T last = T.init; // minor optimization -- skip two successive if same

                try { // set up to return false on collection exceptions
                    while (ts.more)
                          {
                          T m = ts.get;
                          if (m !is last)
                             {
                             if (s.instances(m) !is t.instances(m))
                                 return false;
                             }
                          last = m;
                          }
                    return true;
                    } catch (NoSuchElementException ex)
                            {
                            return false;
                            }
        }
        

        /***********************************************************************

                Helper method left public since it might be useful

        ************************************************************************/

        public final static bool sameOrderedElements(ViewT s, ViewT t)
        {
                if (s.size !is t.size)
                    return false;

                auto ts = t.elements();
                auto ss = s.elements();

                try { // set up to return false on collection exceptions
                    while (ts.more)
                          {
                          T m = ts.get;
                          T o = ss.get;
                          if (m != o)
                              return false;
                          }
                    return true;
                    } catch (NoSuchElementException ex)
                            {       
                            return false;
                            }
        }

        // misc common helper methods

        /***********************************************************************

                Principal method to throw a NoSuchElementException.
                Besides index checks in Seqs, you can use it to check for
                operations on empty collections via checkIndex(0)

        ************************************************************************/

        protected final void checkIndex(int index)
        {
                if (index < 0 || index >= count)
                   {
                   char[] msg;

                   if (count is 0)
                       msg = "Element access on empty collection";
                   else
                      {
                      char[16] idx, cnt;
                      msg = "Index " ~ itoa (idx, index) ~ " out of range for collection of size " ~ itoa (cnt, count);
                      }
                   throw new NoSuchElementException(msg);
                   }
        }

        
        /***********************************************************************

                Principal method to throw a IllegalElementException

        ************************************************************************/

        protected final void checkElement(T element)
        {
                if (! allows(element))
                   {
                   throw new IllegalElementException("Attempt to include invalid element _in Collection");
                   }
        }

        /***********************************************************************

                See_Also: tango.util.collection.model.View.View.checkImplementation

        ************************************************************************/

        public void checkImplementation()
        {
                assert(count >= 0);
        }
        //public override void checkImplementation() //Doesn't compile with the override attribute

        /***********************************************************************

                Cause the collection to become empty. 

        ************************************************************************/

        abstract void clear();

        /***********************************************************************

                Exclude all occurrences of the indicated element from the collection. 
                No effect if element not present.
                Params:
                    element = the element to exclude.
                ---
                !has(element) &&
                size() == PREV(this).size() - PREV(this).instances(element) &&
                no other element changes &&
                Version change iff PREV(this).has(element)
                ---

        ************************************************************************/

        abstract void removeAll(T element);

        /***********************************************************************

                Remove an instance of the indicated element from the collection. 
                No effect if !has(element)
                Params:
                    element = the element to remove
                ---
                let occ = max(1, instances(element)) in
                 size() == PREV(this).size() - occ &&
                 instances(element) == PREV(this).instances(element) - occ &&
                 no other element changes &&
                 version change iff occ == 1
                ---

        ************************************************************************/

        abstract void remove (T element);
        
        /***********************************************************************

                Replace an occurrence of oldElement with newElement.
                No effect if does not hold oldElement or if oldElement.equals(newElement).
                The operation has a consistent, but slightly special interpretation
                when applied to Sets. For Sets, because elements occur at
                most once, if newElement is already included, replacing oldElement with
                with newElement has the same effect as just removing oldElement.
                ---
                let int delta = oldElement.equals(newElement)? 0 : 
                              max(1, PREV(this).instances(oldElement) in
                 instances(oldElement) == PREV(this).instances(oldElement) - delta &&
                 instances(newElement) ==  (this instanceof Set) ? 
                        max(1, PREV(this).instances(oldElement) + delta):
                               PREV(this).instances(oldElement) + delta) &&
                 no other element changes &&
                 Version change iff delta != 0
                ---
                Throws: IllegalElementException if has(oldElement) and !allows(newElement)

        ************************************************************************/

        abstract void replace (T oldElement, T newElement);

        /***********************************************************************

                Replace all occurrences of oldElement with newElement.
                No effect if does not hold oldElement or if oldElement.equals(newElement).
                The operation has a consistent, but slightly special interpretation
                when applied to Sets. For Sets, because elements occur at
                most once, if newElement is already included, replacing oldElement with
                with newElement has the same effect as just removing oldElement.
                ---
                let int delta = oldElement.equals(newElement)? 0 : 
                           PREV(this).instances(oldElement) in
                 instances(oldElement) == PREV(this).instances(oldElement) - delta &&
                 instances(newElement) ==  (this instanceof Set) ? 
                        max(1, PREV(this).instances(oldElement) + delta):
                               PREV(this).instances(oldElement) + delta) &&
                 no other element changes &&
                 Version change iff delta != 0
                ---
                Throws: IllegalElementException if has(oldElement) and !allows(newElement)

        ************************************************************************/

        abstract void replaceAll(T oldElement, T newElement);

        /***********************************************************************

                Exclude all occurrences of each element of the Iterator.
                Behaviorally equivalent to
                ---
                while (e.more())
                  removeAll(e.get());
                ---
                Param :
                    e = the enumeration of elements to exclude.

                Throws: CorruptedIteratorException is propagated if thrown

                See_Also: tango.util.collection.impl.Collection.Collection.removeAll

        ************************************************************************/

        abstract void removeAll (Iterator!(T) e);

        /***********************************************************************

                 Remove an occurrence of each element of the Iterator.
                 Behaviorally equivalent to

                 ---
                 while (e.more())
                    remove (e.get());
                 ---

                 Param:
                    e = the enumeration of elements to remove.

                 Throws: CorruptedIteratorException is propagated if thrown

        ************************************************************************/

        abstract void remove (Iterator!(T) e);

        /***********************************************************************

                Remove and return an element.  Implementations
                may strengthen the guarantee about the nature of this element.
                but in general it is the most convenient or efficient element to remove.

                Examples:
                One way to transfer all elements from 
                MutableCollection a to MutableBag b is:
                ---
                while (!a.empty())
                    b.add(a.take());
                ---

                Returns:
                    an element v such that PREV(this).has(v) 
                    and the postconditions of removeOneOf(v) hold.

                Throws: NoSuchElementException iff drained.

        ************************************************************************/

        abstract T take();
}


