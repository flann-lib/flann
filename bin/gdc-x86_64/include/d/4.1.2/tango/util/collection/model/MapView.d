/*
 File: MapView.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from collections.d  working file

*/


module tango.util.collection.model.MapView;

private import  tango.util.collection.model.View,
                tango.util.collection.model.GuardIterator;


/**
 *
 * Maps maintain keyed elements. Any kind of Object 
 * may serve as a key for an element.
 *
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/


public interface MapView(K, V) : View!(V)
{
        /**
         * Report whether the MapT COULD include k as a key
         * Always returns false if k is null
        **/

        public bool allowsKey(K key);

        /**
         * Report whether there exists any element with Key key.
         * Returns: true if there is such an element
        **/

        public bool containsKey(K key);

        /**
         * Report whether there exists a (key, value) pair
         * Returns: true if there is such an element
        **/

        public bool containsPair(K key, V value);


        /**
         * Return an enumeration that may be used to traverse through
         * the keys (not elements) of the collection. The corresponding
         * elements can be looked at by using at(k) for each key k. For example:
         * <PRE>
         * Iterator keys = amap.keys();
         * while (keys.more()) {
         *   K key = keys.get();
         *   T value = amap.get(key)
         * // ...
         * }
         * </PRE>
         * Returns: the enumeration
        **/

        public PairIterator!(K, V) keys();

        /**
         traverse the collection content. This is cheaper than using an
         iterator since there is no creation cost involved.
        **/

        int opApply (int delegate (inout K key, inout V value) dg);
        
        /**
         * Return the element associated with Key key. 
         * @param key a key
         * Returns: element such that contains(key, element)
         * Throws: NoSuchElementException if !containsKey(key)
        **/

        public V get(K key);
        public alias get opIndex;

        /**
         * Return the element associated with Key key. 
         * @param key a key
         * Returns: whether the key is contained or not
        **/

        public bool get(K key, inout V element); 


        /**
         * Return a key associated with element. There may be any
         * number of keys associated with any element, but this returns only
         * one of them (any arbitrary one), or false if no such key exists.
         * @param key, a place to return a located key
         * @param element, a value to try to find a key for.
         * Returns: true where value is found; false otherwise
        **/

        public bool keyOf(inout K key, V value);
}

