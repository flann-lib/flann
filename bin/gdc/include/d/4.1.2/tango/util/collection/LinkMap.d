/*
 File: LinkMap.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from tango.util.collection.d  working file
 13Oct95  dl                 Changed protection statuses
 21Oct95  dl                 Fixed error in remove

*/


module tango.util.collection.LinkMap;

private import tango.core.Exception;

private import  tango.io.protocol.model.IReader,
                tango.io.protocol.model.IWriter;

private import  tango.util.collection.model.View,
                tango.util.collection.model.GuardIterator;

private import  tango.util.collection.impl.LLCell,
                tango.util.collection.impl.LLPair,
                tango.util.collection.impl.MapCollection,
                tango.util.collection.impl.AbstractIterator;

/**
 * Linked lists of (key, element) pairs
 * author: Doug Lea
**/
public class LinkMap(K, T) : MapCollection!(K, T) // , IReadable, IWritable
{
        alias LLCell!(T)               LLCellT;
        alias LLPair!(K, T)            LLPairT;

        alias MapCollection!(K, T).remove     remove;
        alias MapCollection!(K, T) .removeAll  removeAll;

        // instance variables

        /**
         * The head of the list. Null if empty
        **/

        package LLPairT list;

        // constructors

        /**
         * Make an empty list
        **/

        public this ()
        {
                this(null, null, 0);
        }

        /**
         * Make an empty list with the supplied element screener
        **/

        public this (Predicate screener)
        {
                this(screener, null, 0);
        }

        /**
         * Special version of constructor needed by clone()
        **/
        protected this (Predicate s, LLPairT l, int c)
        {
                super(s);
                list = l;
                count = c;
        }

        /**
         * Make an independent copy of the list. Does not clone elements
        **/

        public LinkMap duplicate()
        {
                if (list is null)
                    return new LinkMap (screener, null, 0);
                else
                   return new LinkMap (screener, cast(LLPairT)(list.copyList()), count);
        }


        // Collection methods

        /**
         * Implements tango.util.collection.impl.Collection.Collection.contains.
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
         * Implements tango.util.collection.impl.Collection.Collection.instances.
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
         * Implements tango.util.collection.impl.Collection.Collection.elements.
         * Time complexity: O(1).
         * See_Also: tango.util.collection.impl.Collection.Collection.elements
        **/
        public final GuardIterator!(T) elements()
        {
                return keys();
        }

        /***********************************************************************

                Implements tango.util.collection.model.View.View.opApply
                Time complexity: O(n)
                
                See_Also: tango.util.collection.model.View.View.opApply
        
        ************************************************************************/
        
        int opApply (int delegate (inout T value) dg)
        {
                auto scope iterator = new MapIterator!(K, T)(this);
                return iterator.opApply (dg);
        }


        /***********************************************************************

                Implements tango.util.collection.MapView.opApply
                Time complexity: O(n)
                
                See_Also: tango.util.collection.MapView.opApply
        
        ************************************************************************/
        
        int opApply (int delegate (inout K key, inout T value) dg)
        {
                auto scope iterator = new MapIterator!(K, T)(this);
                return iterator.opApply (dg);
        }


        // Map methods


        /**
         * Implements tango.util.collection.Map.containsKey.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.Map.containsKey
        **/
        public final bool containsKey(K key)
        {
                if (!isValidKey(key) || list is null)
                     return false;

                return list.findKey(key) !is null;
        }

        /**
         * Implements tango.util.collection.Map.containsPair
         * Time complexity: O(n).
         * See_Also: tango.util.collection.Map.containsPair
        **/
        public final bool containsPair(K key, T element)
        {
                if (!isValidKey(key) || !isValidArg(element) || list is null)
                    return false;
                return list.find(key, element) !is null;
        }

        /**
         * Implements tango.util.collection.Map.keys.
         * Time complexity: O(1).
         * See_Also: tango.util.collection.Map.keys
        **/
        public final PairIterator!(K, T) keys()
        {
                return new MapIterator!(K, T)(this);
        }

        /**
         * Implements tango.util.collection.Map.get.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.Map.get
        **/
        public final T get(K key)
        {
                checkKey(key);
                if (list !is null)
                   {
                   auto p = list.findKey(key);
                   if (p !is null)
                       return p.element();
                   }
                throw new NoSuchElementException("no matching Key");
        }

        /**
         * Return the element associated with Key key. 
         * Params:
         *   key = a key
         * Returns: whether the key is contained or not
        **/

        public final bool get(K key, inout T element)
        {
                checkKey(key);
                if (list !is null)
                   {
                   auto p = list.findKey(key);
                   if (p !is null)
                      {
                      element = p.element();
                      return true;
                      }
                   }
                return false;
        }



        /**
         * Implements tango.util.collection.Map.keyOf.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.Map.keyOf
        **/
        public final bool keyOf(inout K key, T value)
        {
                if (!isValidArg(value) || count is 0)
                     return false;

                auto p = (cast(LLPairT)(list.find(value)));
                if (p is null)
                    return false;

                key = p.key();
                return true;
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
        public final void replaceAll(T oldElement, T newElement)
        {
                replace_(oldElement, newElement, true);
        }

        /**
         * Implements tango.util.collection.impl.Collection.Collection.removeAll.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.Collection.Collection.removeAll
        **/
        public final void removeAll(T element)
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
         * Implements tango.util.collection.impl.Collection.Collection.take.
         * Time complexity: O(1).
         * takes the first element on the list
         * See_Also: tango.util.collection.impl.Collection.Collection.take
        **/
        public final T take()
        {
                if (list !is null)
                   {
                   auto v = list.element();
                   list = cast(LLPairT)(list.next());
                   decCount();
                   return v;
                   }
                checkIndex(0);
                return T.init; // not reached
        }


        // MutableMap methods

        /**
         * Implements tango.util.collection.impl.MapCollection.MapCollection.add.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.MapCollection.MapCollection.add
        **/
        public final void add (K key, T element)
        {
                checkKey(key);
                checkElement(element);

                if (list !is null)
                   {
                   auto p = list.findKey(key);
                   if (p !is null)
                      {
                      if (p.element() != (element))
                         {
                         p.element(element);
                         incVersion();
                         }
                      return ;
                      }
                   }
                list = new LLPairT(key, element, list);
                incCount();
        }


        /**
         * Implements tango.util.collection.impl.MapCollection.MapCollection.remove.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.MapCollection.MapCollection.remove
        **/
        public final void removeKey (K key)
        {
                if (!isValidKey(key) || list is null)
                    return ;

                auto p = list;
                auto trail = p;

                while (p !is null)
                      {
                      auto n = cast(LLPairT)(p.next());
                      if (p.key() == (key))
                         {
                         decCount();
                         if (p is list)
                             list = n;
                         else
                            trail.unlinkNext();
                         return ;
                         }
                      else
                         {
                         trail = p;
                         p = n;
                         }
                      }
        }

        /**
         * Implements tango.util.collection.impl.MapCollection.MapCollection.replaceElement.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.MapCollection.MapCollection.replaceElement
        **/
        public final void replacePair (K key, T oldElement, T newElement)
        {
                if (!isValidKey(key) || !isValidArg(oldElement) || list is null)
                     return ;

                auto p = list.find(key, oldElement);
                if (p !is null)
                   {
                   checkElement(newElement);
                   p.element(newElement);
                   incVersion();
                   }
        }

        private final void remove_(T element, bool allOccurrences)
        {
                if (!isValidArg(element) || count is 0)
                     return ;

                auto p = list;
                auto trail = p;

                while (p !is null)
                      {
                      auto n = cast(LLPairT)(p.next());
                      if (p.element() == (element))
                         {
                         decCount();
                         if (p is list)
                            {
                            list = n;
                            trail = n;
                            }
                         else
                            trail.next(n);

                         if (!allOccurrences || count is 0)
                              return ;
                         else
                            p = n;
                         }
                      else
                         {
                         trail = p;
                         p = n;
                         }
                      }
        }

        /**
         * Helper for replace
        **/

        private final void replace_(T oldElement, T newElement, bool allOccurrences)
        {
                if (list is null || !isValidArg(oldElement) || oldElement == (newElement))
                    return ;

                auto p = list.find(oldElement);
                while (p !is null)
                      {
                      checkElement(newElement);
                      p.element(newElement);
                      incVersion();
                      if (!allOccurrences)
                           return ;
                      p = p.find(oldElement);
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

                assert(((count is 0) is (list is null)));
                assert((list is null || list._length() is count));

                for (auto p = list; p !is null; p = cast(LLPairT)(p.next()))
                    {
                    assert(allows(p.element()));
                    assert(allowsKey(p.key()));
                    assert(containsKey(p.key()));
                    assert(contains(p.element()));
                    assert(instances(p.element()) >= 1);
                    assert(containsPair(p.key(), p.element()));
                    }
        }


        /***********************************************************************

                opApply() has migrated here to mitigate the virtual call
                on method get()
                
        ************************************************************************/

        private static class MapIterator(K, V) : AbstractMapIterator!(K, V)
        {
                private LLPairT pair;
                
                public this (LinkMap map)
                {
                        super (map);
                        pair = map.list;
                } 

                public final V get(inout K key)
                {
                        if (pair)
                            key = pair.key;
                        return get();
                }

                public final V get()
                {
                        decRemaining();
                        auto v = pair.element();
                        pair = cast(LLPairT) pair.next();
                        return v;
                }

                int opApply (int delegate (inout V value) dg)
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

                int opApply (int delegate (inout K key, inout V value) dg)
                {
                        K   key;
                        int result;

                        for (auto i=remaining(); i--;)
                            {
                            auto value = get(key);
                            if ((result = dg(key, value)) != 0)
                                 break;
                            }
                        return result;
                }
        }
}


         
debug(Test)
{
        void main()
        {
                auto map = new LinkMap!(Object, double);

                foreach (key, value; map.keys) {typeof(key) x; x = key;}

                foreach (value; map.keys) {}

                foreach (value; map.elements) {}

                auto keys = map.keys();
                while (keys.more)
                       auto v = keys.get();

                foreach (value; map) {}
                foreach (key, value; map) {}

                map.checkImplementation();
        }
}
