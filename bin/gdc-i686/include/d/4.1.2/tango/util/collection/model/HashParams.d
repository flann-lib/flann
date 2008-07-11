/*
 File: HashParams.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from collections.d  working file

*/


module tango.util.collection.model.HashParams;


/**
 *
 * Base interface for hash table based collections.
 * Provides common ways of dealing with buckets and threshholds.
 * (It would be nice to share some of the code too, but this
 * would require multiple inheritance here.)
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
 *
**/


public interface HashParams
{

        /**
         * The default initial number of buckets of a non-empty HT
        **/

        public static int defaultInitialBuckets = 31;

        /**
         * The default load factor for a non-empty HT. When the proportion
         * of elements per buckets exceeds this, the table is resized.
        **/

        public static float defaultLoadFactor = 0.75f;

        /**
         * return the current number of hash table buckets
        **/

        public int buckets();

        /**
         * Set the desired number of buckets in the hash table.
         * Any value greater than or equal to one is OK.
         * if different than current buckets, causes a version change
         * Throws: IllegalArgumentException if newCap less than 1
        **/

        public void buckets(int newCap);


        /**
         * Return the current load factor threshold
         * The Hash table occasionally checka against the load factor
         * resizes itself if it has gone past it.
        **/

        public float thresholdLoadFactor();

        /**
         * Set the current desired load factor. Any value greater than 0 is OK.
         * The current load is checked against it, possibly causing resize.
         * Throws: IllegalArgumentException if desired is 0 or less
        **/

        public void thresholdLoadFactor(float desired);
}
