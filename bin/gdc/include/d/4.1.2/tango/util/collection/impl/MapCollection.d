/*******************************************************************************

        File: MapCollection.d

        Originally written by Doug Lea and released into the public domain. 
        Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
        Inc, Loral, and everyone contributing, testing, and using this code.

        History:
        Date     Who                What
        13Oct95  dl                 Create
        28jan97  dl                 make class public
        14Dec06  kb                 adapted for Tango usage

********************************************************************************/

module tango.util.collection.impl.MapCollection;

private import  tango.core.Exception;

private import  tango.util.collection.impl.Collection;

private import  tango.util.collection.model.Map,
                tango.util.collection.model.View,
                tango.util.collection.model.MapView,
                tango.util.collection.model.Iterator,
                tango.util.collection.model.SortedKeys;


/*******************************************************************************

        MapCollection extends Collection to provide default implementations of
        some Map operations. 
                
        author: Doug Lea
                @version 0.93

        <P> For an introduction to this package see <A HREF="index.html"
        > Overview </A>.

 ********************************************************************************/

public abstract class MapCollection(K, T) : Collection!(T), Map!(K, T)
{
        alias MapView!(K, T)            MapViewT;
        alias Collection!(T).remove     remove;
        alias Collection!(T).removeAll  removeAll;


        /***********************************************************************

                Initialize at version 0, an empty count, and null screener

        ************************************************************************/

        protected this ()
        {
                super();
        }

        /***********************************************************************

                Initialize at version 0, an empty count, and supplied screener

        ************************************************************************/

        protected this (Predicate screener)
        {
                super(screener);
        }

        /***********************************************************************

                Implements tango.util.collection.Map.allowsKey.
                Default key-screen. Just checks for null.
                
                See_Also: tango.util.collection.Map.allowsKey

        ************************************************************************/

        public final bool allowsKey(K key)
        {
                return (key !is K.init);
        }

        protected final bool isValidKey(K key)
        {
                static if (is (K : Object))
                          {
                          if (key is null)
                              return false;
                          }
                return true;
        }

        /***********************************************************************

                Principal method to throw a IllegalElementException for keys

        ************************************************************************/

        protected final void checkKey(K key)
        {
                if (!isValidKey(key))
                   {
                   throw new IllegalElementException("Attempt to include invalid key _in Collection");
                   }
        }

        /***********************************************************************

                Implements tango.util.collection.impl.MapCollection.MapCollection.opIndexAssign
                Just calls add(key, element).

                See_Also: tango.util.collection.impl.MapCollection.MapCollection.add

        ************************************************************************/

        public final void opIndexAssign (T element, K key)
        {
                add (key, element);
        }

        /***********************************************************************

                Implements tango.util.collection.impl.Collection.Collection.matches
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

        public override bool matches(View!(T) other)
        {
                if (other is null)
                   {}
                else
                   if (other is this)
                       return true;
                   else
                      {
                      auto tmp = cast (MapViewT) other;
                      if (tmp)
                          if (cast(SortedKeys!(K, T)) this)
                              return sameOrderedPairs(this, tmp);
                          else
                             return samePairs(this, tmp);
                      }
                return false;
        }


        public final static bool samePairs(MapViewT s, MapViewT t)
        {
                if (s.size !is t.size)
                    return false;

                try { // set up to return false on collection exceptions
                    foreach (key, value; t.keys)
                             if (! s.containsPair (key, value))
                                   return false;
                    } catch (NoSuchElementException ex)
                            {
                            return false;
                            }
                return true;
        }

        public final static bool sameOrderedPairs(MapViewT s, MapViewT t)
        {
                if (s.size !is t.size)
                    return false;

                auto ss = s.keys();
                try { // set up to return false on collection exceptions
                    foreach (key, value; t.keys)
                            {
                            K sk;
                            auto sv = ss.get (sk);
                            if (sk != key || sv != value)
                                return false;
                            }
                    } catch (NoSuchElementException ex)
                            {
                            return false;
                            }
                return true;
        }


        // Object methods

        /***********************************************************************

                Implements tango.util.collection.impl.Collection.Collection.removeAll
                See_Also: tango.util.collection.impl.Collection.Collection.removeAll

                Has to be here rather than in the superclass to satisfy
                D interface idioms

        ************************************************************************/

        public void removeAll (Iterator!(T) e)
        {
                while (e.more)
                       removeAll (e.get);
        }

        /***********************************************************************

                Implements tango.util.collection.impl.Collection.Collection.removeElements
                See_Also: tango.util.collection.impl.Collection.Collection.removeElements

                Has to be here rather than in the superclass to satisfy
                D interface idioms

        ************************************************************************/

        public void remove (Iterator!(T) e)
        {
                while (e.more)
                       remove (e.get);
        }
}

