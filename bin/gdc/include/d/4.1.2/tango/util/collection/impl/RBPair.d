/*
 File: RBPair.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from tango.util.collection.d  working file
 13Oct95  dl                 Changed protection statuses

*/


module tango.util.collection.impl.RBPair;

private import tango.util.collection.impl.RBCell;

private import tango.util.collection.model.Comparator;


/**
 *
 * RBPairs are RBCells with keys.
 *
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public class RBPair(K, T) : RBCell!(T) 
{
        alias RBCell!(T).element element;

        // instance variable

        private K key_;

        /**
         * Make a cell with given key and element values, and null links
        **/

        public this (K k, T v)
        {
                super(v);
                key_ = k;
        }

        /**
         * Make a new node with same key and element values, but null links
        **/

        protected final RBPair duplicate()
        {
                auto t = new RBPair(key_, element());
                t.color_ = color_;
                return t;
        }

        /**
         * return the key
        **/

        public final K key()
        {
                return key_;
        }


        /**
         * set the key
        **/

        public final void key(K k)
        {
                key_ = k;
        }

        /**
         * Implements RBCell.find.
         * Override RBCell version since we are ordered on keys, not elements, so
         * element find has to search whole tree.
         * comparator argument not actually used.
         * See_Also: RBCell.find
        **/

        public final override RBCell!(T) find(T element, Comparator!(T) cmp)
        {
                RBCell!(T) t = this;

                while (t !is null)
                      {
                      if (t.element() == (element))
                          return t;
                      else
                        if (t.right_ is null)
                            t = t.left_;
                        else
                           if (t.left_ is null)
                               t = t.right_;
                           else
                              {
                              auto p = t.left_.find(element, cmp);

                              if (p !is null)
                                  return p;
                              else
                                 t = t.right_;
                              }
                      }
                return null; // not reached
        }

        /**
         * Implements RBCell.count.
         * See_Also: RBCell.count
        **/
        public final override int count(T element, Comparator!(T) cmp)
        {
                int c = 0;
                RBCell!(T) t = this;

                while (t !is null)
                      {
                      if (t.element() == (element))
                          ++c;

                      if (t.right_ is null)
                          t = t.left_;
                      else
                         if (t.left_ is null)
                             t = t.right_;
                         else
                            {
                            c += t.left_.count(element, cmp);
                            t = t.right_;
                            }
                      }
                return c;
        }

        /**
         * find and return a cell holding key, or null if no such
        **/

        public final RBPair findKey(K key, Comparator!(K) cmp)
        {
                auto t = this;

                for (;;)
                    {
                    int diff = cmp.compare(key, t.key_);
                    if (diff is 0)
                        return t;
                    else
                       if (diff < 0)
                           t = cast(RBPair)(t.left_);
                       else
                          t = cast(RBPair)(t.right_);

                    if (t is null)
                        break;
                    }
                return null;
        }

        /**
         * find and return a cell holding (key, element), or null if no such
        **/
        public final RBPair find(K key, T element, Comparator!(K) cmp)
        {
                auto t = this;

                for (;;)
                    {
                    int diff = cmp.compare(key, t.key_);
                    if (diff is 0 && t.element() == (element))
                        return t;
                    else
                       if (diff <= 0)
                           t = cast(RBPair)(t.left_);
                       else
                          t = cast(RBPair)(t.right_);

                    if (t is null)
                        break;
                    }
                return null;
        }

        /**
         * return number of nodes of subtree holding key
        **/
        public final int countKey(K key, Comparator!(K) cmp)
        {
                int c = 0;
                auto t = this;

                while (t !is null)
                      {
                      int diff = cmp.compare(key, t.key_);
                      // rely on insert to always go left on <=
                      if (diff is 0)
                          ++c;

                      if (diff <= 0)
                          t = cast(RBPair)(t.left_);
                      else
                         t = cast(RBPair)(t.right_);
                      }
                return c;
        }

        /**
         * return number of nodes of subtree holding (key, element)
        **/
        public final int count(K key, T element, Comparator!(K) cmp)
        {
                int c = 0;
                auto t = this;
                
                while (t !is null)
                      {
                      int diff = cmp.compare(key, t.key_);
                      if (diff is 0)
                         {
                         if (t.element() == (element))
                             ++c;

                         if (t.left_ is null)
                             t = cast(RBPair)(t.right_);
                         else
                            if (t.right_ is null)
                                t = cast(RBPair)(t.left_);
                            else
                               {
                               c += (cast(RBPair)(t.right_)).count(key, element, cmp);
                               t = cast(RBPair)(t.left_);
                               }
                         }
                      else
                         if (diff < 0)
                             t = cast(RBPair)(t.left());
                         else
                            t = cast(RBPair)(t.right());
                      }
                return c;
        }
}

