/*
 File: TreeMap.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from tango.util.collection.d  working file
 13Oct95  dl                 Changed protection statuses

*/


module tango.util.collection.TreeMap;

private import  tango.core.Exception;

private import  tango.util.collection.model.Comparator,
                tango.util.collection.model.SortedKeys,
                tango.util.collection.model.GuardIterator;

private import  tango.util.collection.impl.RBPair,
                tango.util.collection.impl.RBCell,
                tango.util.collection.impl.MapCollection,
                tango.util.collection.impl.AbstractIterator,
                tango.util.collection.impl.DefaultComparator;


/**
 *
 *
 * RedBlack Trees of (key, element) pairs
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/


public class TreeMap(K, T) : MapCollection!(K, T), SortedKeys!(K, T)
{
        alias RBCell!(T)                RBCellT;
        alias RBPair!(K, T)             RBPairT;
        alias Comparator!(K)            ComparatorT;
        alias GuardIterator!(T)         GuardIteratorT;

        alias MapCollection!(K, T).remove     remove;
        alias MapCollection!(K, T).removeAll  removeAll;


        // instance variables

        /**
         * The root of the tree. Null if empty.
        **/

        package RBPairT tree;

        /**
         * The Comparator to use for ordering
        **/

        protected ComparatorT           cmp;
        protected Comparator!(T)        cmpElem;

        /**
         * Make an empty tree, using DefaultComparator for ordering
        **/

        public this ()
        {
                this (null, null, null, 0);
        }


        /**
         * Make an empty tree, using given screener for screening elements (not keys)
        **/
        public this (Predicate screener)
        {
                this(screener, null, null, 0);
        }

        /**
         * Make an empty tree, using given Comparator for ordering
        **/
        public this (ComparatorT c)
        {
                this(null, c, null, 0);
        }

        /**
         * Make an empty tree, using given screener and Comparator.
        **/
        public this (Predicate s, ComparatorT c)
        {
                this(s, c, null, 0);
        }

        /**
         * Special version of constructor needed by clone()
        **/

        protected this (Predicate s, ComparatorT c, RBPairT t, int n)
        {
                super(s);
                count = n;
                tree = t;
                cmp = (c is null) ? new DefaultComparator!(K) : c;
                cmpElem = new DefaultComparator!(T);
        }

        /**
         * Create an independent copy. Does not clone elements.
        **/

        public TreeMap duplicate()
        {
                if (count is 0)
                    return new TreeMap!(K, T)(screener, cmp);
                else
                   return new TreeMap!(K, T)(screener, cmp, cast(RBPairT)(tree.copyTree()), count);
        }


        // Collection methods

        /**
         * Implements tango.util.collection.impl.Collection.Collection.contains
         * Time complexity: O(log n).
         * See_Also: tango.util.collection.impl.Collection.Collection.contains
        **/
        public final bool contains(T element)
        {
                if (!isValidArg(element) || count is 0)
                     return false;
                return tree.find(element, cmpElem) !is null;
        }

        /**
         * Implements tango.util.collection.impl.Collection.Collection.instances
         * Time complexity: O(log n).
         * See_Also: tango.util.collection.impl.Collection.Collection.instances
        **/
        public final uint instances(T element)
        {
                if (!isValidArg(element) || count is 0)
                     return 0;
                return tree.count(element, cmpElem);
        }

        /**
         * Implements tango.util.collection.impl.Collection.Collection.elements
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

        // KeySortedCollection methods

        /**
         * Implements tango.util.collection.KeySortedCollection.comparator
         * Time complexity: O(1).
         * See_Also: tango.util.collection.KeySortedCollection.comparator
        **/
        public final ComparatorT comparator()
        {
                return cmp;
        }

        /**
         * Use a new Comparator. Causes a reorganization
        **/

        public final void comparator (ComparatorT c)
        {
                if (cmp !is c)
                   {
                   cmp = (c is null) ? new DefaultComparator!(K) : c;

                   if (count !is 0)
                      {       
                      // must rebuild tree!
                      incVersion();
                      auto t = cast(RBPairT) (tree.leftmost());
                      tree = null;
                      count = 0;
                      
                      while (t !is null)
                            {
                            add_(t.key(), t.element(), false);
                            t = cast(RBPairT)(t.successor());
                            }
                      }
                   }
        }

        // Map methods

        /**
         * Implements tango.util.collection.Map.containsKey.
         * Time complexity: O(log n).
         * See_Also: tango.util.collection.Map.containsKey
        **/
        public final bool containsKey(K key)
        {
                if (!isValidKey(key) || count is 0)
                    return false;
                return tree.findKey(key, cmp) !is null;
        }

        /**
         * Implements tango.util.collection.Map.containsPair.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.Map.containsPair
        **/
        public final bool containsPair(K key, T element)
        {
                if (count is 0 || !isValidKey(key) || !isValidArg(element))
                    return false;
                return tree.find(key, element, cmp) !is null;
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
         * Time complexity: O(log n).
         * See_Also: tango.util.collection.Map.get
        **/
        public final T get(K key)
        {
                if (count !is 0)
                   {
                   RBPairT p = tree.findKey(key, cmp);
                   if (p !is null)
                       return p.element();
                   }
                throw new NoSuchElementException("no matching Key ");
        }

        /**
         * Return the element associated with Key key. 
         * @param key a key
         * Returns: whether the key is contained or not
        **/

        public final bool get(K key, inout T value)
        {
                if (count !is 0)
                   {
                   RBPairT p = tree.findKey(key, cmp);
                   if (p !is null)
                      {
                      value = p.element();
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

                auto p = (cast(RBPairT)( tree.find(value, cmpElem)));
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
                setCount(0);
                tree = null;
        }


        /**
         * Implements tango.util.collection.impl.Collection.Collection.removeAll.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.Collection.Collection.removeAll
        **/
        public final void removeAll(T element)
        {
                if (!isValidArg(element) || count is 0)
                      return ;

                RBPairT p = cast(RBPairT)(tree.find(element, cmpElem));
                while (p !is null)
                      {
                      tree = cast(RBPairT)(p.remove(tree));
                      decCount();
                      if (count is 0)
                          return ;
                      p = cast(RBPairT)(tree.find(element, cmpElem));
                      }
        }

        /**
         * Implements tango.util.collection.impl.Collection.Collection.removeOneOf.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.Collection.Collection.removeOneOf
        **/
        public final void remove (T element)
        {
                if (!isValidArg(element) || count is 0)
                      return ;

                RBPairT p = cast(RBPairT)(tree.find(element, cmpElem));
                if (p !is null)
                   {
                   tree = cast(RBPairT)(p.remove(tree));
                   decCount();
                   }
        }


        /**
         * Implements tango.util.collection.impl.Collection.Collection.replaceOneOf.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.Collection.Collection.replaceOneOf
        **/
        public final void replace(T oldElement, T newElement)
        {
                if (count is 0 || !isValidArg(oldElement) || !isValidArg(oldElement))
                    return ;

                RBPairT p = cast(RBPairT)(tree.find(oldElement, cmpElem));
                if (p !is null)
                   {
                   checkElement(newElement);
                   incVersion();
                   p.element(newElement);
                   }
        }

        /**
         * Implements tango.util.collection.impl.Collection.Collection.replaceAllOf.
         * Time complexity: O(n).
         * See_Also: tango.util.collection.impl.Collection.Collection.replaceAllOf
        **/
        public final void replaceAll(T oldElement, T newElement)
        {
                RBPairT p = cast(RBPairT)(tree.find(oldElement, cmpElem));
                while (p !is null)
                      {
                      checkElement(newElement);
                      incVersion();
                      p.element(newElement);
                      p = cast(RBPairT)(tree.find(oldElement, cmpElem));
                      }
        }

        /**
         * Implements tango.util.collection.impl.Collection.Collection.take.
         * Time complexity: O(log n).
         * Takes the element associated with the least key.
         * See_Also: tango.util.collection.impl.Collection.Collection.take
        **/
        public final T take()
        {
                if (count !is 0)
                   {
                   RBPairT p = cast(RBPairT)(tree.leftmost());
                   T v = p.element();
                   tree = cast(RBPairT)(p.remove(tree));
                   decCount();
                   return v;
                   }

                checkIndex(0);
                return T.init; // not reached
        }


        // MutableMap methods

        /**
         * Implements tango.util.collection.impl.MapCollection.MapCollection.add.
         * Time complexity: O(log n).
         * See_Also: tango.util.collection.impl.MapCollection.MapCollection.add
        **/
        public final void add(K key, T element)
        {
                add_(key, element, true);
        }


        /**
         * Implements tango.util.collection.impl.MapCollection.MapCollection.remove.
         * Time complexity: O(log n).
         * See_Also: tango.util.collection.impl.MapCollection.MapCollection.remove
        **/
        public final void removeKey (K key)
        {
                if (!isValidKey(key) || count is 0)
                      return ;

                RBCellT p = tree.findKey(key, cmp);
                if (p !is null)
                   {
                   tree = cast(RBPairT)(p.remove(tree));
                   decCount();
                   }
        }


        /**
         * Implements tango.util.collection.impl.MapCollection.MapCollection.replaceElement.
         * Time complexity: O(log n).
         * See_Also: tango.util.collection.impl.MapCollection.MapCollection.replaceElement
        **/
        public final void replacePair (K key, T oldElement,
                                              T newElement)
        {
                if (!isValidKey(key) || !isValidArg(oldElement) || count is 0)
                    return ;

                RBPairT p = tree.find(key, oldElement, cmp);
                if (p !is null)
                   {
                   checkElement(newElement);
                   p.element(newElement);
                   incVersion();
                   }
        }


        // helper methods


        private final void add_(K key, T element, bool checkOccurrence)
        {
                checkKey(key);
                checkElement(element);

                if (tree is null)
                   {
                   tree = new RBPairT(key, element);
                   incCount();
                   }
                else
                   {
                   RBPairT t = tree;
                   for (;;)
                       {
                       int diff = cmp.compare(key, t.key());
                       if (diff is 0 && checkOccurrence)
                          {
                          if (t.element() != element)
                             {
                             t.element(element);
                             incVersion();
                             }
                          return ;
                          }
                       else
                          if (diff <= 0)
                             {
                             if (t.left() !is null)
                                 t = cast(RBPairT)(t.left());
                             else
                                {
                                tree = cast(RBPairT)(t.insertLeft(new RBPairT(key, element), tree));
                                incCount();
                                return ;
                                }
                             }
                          else
                             {
                             if (t.right() !is null)
                                 t = cast(RBPairT)(t.right());
                             else
                                {
                                tree = cast(RBPairT)(t.insertRight(new RBPairT(key, element), tree));
                                incCount();
                                return ;
                                }
                             }
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
                assert(cmp !is null);
                assert(((count is 0) is (tree is null)));
                assert((tree is null || tree.size() is count));

                if (tree !is null)
                   {
                   tree.checkImplementation();
                   K last = K.init;
                   RBPairT t = cast(RBPairT)(tree.leftmost());

                   while (t !is null)
                         {
                         K v = t.key();
                         assert((last is K.init || cmp.compare(last, v) <= 0));
                         last = v;
                         t = cast(RBPairT)(t.successor());
                         }
                   }
        }


        /***********************************************************************

                opApply() has migrated here to mitigate the virtual call
                on method get()
                
        ************************************************************************/

        private static class MapIterator(K, V) : AbstractMapIterator!(K, V)
        {
                private RBPairT pair;

                public this (TreeMap map)
                {
                        super (map);

                        if (map.tree)
                            pair = cast(RBPairT) map.tree.leftmost;
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
                        pair = cast(RBPairT) pair.successor();
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



debug (Test)
{
        import tango.io.Console;
        
        void main()
        {
                auto map = new TreeMap!(char[], double);
                map.add ("foo", 1);
                map.add ("baz", 1);
                map.add ("bar", 2);
                map.add ("wumpus", 3);

                foreach (key, value; map.keys) {typeof(key) x; x = key;}

                foreach (value; map.keys) {}

                foreach (value; map.elements) {}

                auto keys = map.keys();
                while (keys.more)
                       auto v = keys.get();

                foreach (value; map) {}

                foreach (key, value; map)
                         Cout (key).newline;
                
                map.checkImplementation();
        }
}
