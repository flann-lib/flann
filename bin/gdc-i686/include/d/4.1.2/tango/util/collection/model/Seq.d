/*
 File: Seq.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from collections.d  working file

*/


module tango.util.collection.model.Seq;

private import  tango.util.collection.model.SeqView,
                tango.util.collection.model.Iterator,
                tango.util.collection.model.Dispenser;

/**
 *
 * Seqs are Seqs possessing standard modification methods
 *
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/


public interface Seq(T) : SeqView!(T), Dispenser!(T)
{
        /**
         * Insert all elements of enumeration e at a given index, preserving 
         * their order. The index can range from
         * 0..size() (i.e., one past the current last index). If the index is
         * equal to size(), the elements are appended.
         * 
         * @param index the index to start adding at
         * @param e the elements to add
         * Returns: condition:
         * <PRE>
         * foreach (int i in 0 .. index-1) at(i).equals(PREV(this)at(i)); &&
         * All existing elements at indices at or greater than index have their
         *  indices incremented by the number of elements 
         *  traversable via e.get() &&
         * The new elements are at indices index + their order in
         *   the enumeration's get traversal.
         * !(e.more()) &&
         * (version() != PREV(this).version()) == PREV(e).more() 
         * </PRE>
         * Throws: IllegalElementException if !canInclude some element of e;
         * this may or may not nullify the effect of insertions of other elements.
         * Throws: NoSuchElementException if index is not in range 0..size()
         * Throws: CorruptedIteratorException is propagated if raised; this
         * may or may not nullify the effects of insertions of other elements.
        **/
        
        public void addAt (int index, Iterator!(T) e);


        /**
         * Insert element at indicated index. The index can range from
         * 0..size() (i.e., one past the current last index). If the index is
         * equal to size(), the element is appended as the new last element.
         * @param index the index to add at
         * @param element the element to add
         * Returns: condition:
         * <PRE>
         * size() == PREV(this).size()+1 &&
         * at(index).equals(element) &&
         * foreach (int i in 0 .. index-1)      get(i).equals(PREV(this).get(i))
         * foreach (int i in index+1..size()-1) get(i).equals(PREV(this).get(i-1))
         * Version change: always
         * </PRE>
         * Throws: NoSuchElementException if index is not in range 0..size()
         * Throws: IllegalElementException if !canInclude(element)
        **/

        public void addAt (int index, T element);

        /**
         * replace element at indicated index with new value
         * @param index the index at which to replace value
         * @param element the new value
         * Returns: condition:
         * <PRE>
         * size() == PREV(this).size() &&
         * at(index).equals(element) &&
         * no spurious effects
         * Version change <-- !element.equals(PREV(this).get(index)
         *                    (but MAY change even if equal).
         * </PRE>
         * Throws: NoSuchElementException if index is not in range 0..size()-1
         * Throws: IllegalElementException if !canInclude(element)
        **/

        public void replaceAt (int index, T element);

        /**
         * replace element at indicated index with new value
         * @param element the new value
         * @param index the index at which to replace value
         * Returns: condition:
         * <PRE>
         * size() == PREV(this).size() &&
         * at(index).equals(element) &&
         * no spurious effects
         * Version change <-- !element.equals(PREV(this).get(index)
         *                    (but MAY change even if equal).
         * </PRE>
         * Throws: NoSuchElementException if index is not in range 0..size()-1
         * Throws: IllegalElementException if !canInclude(element)
        **/
        public void opIndexAssign (T element, int index);


        /**
         * Remove element at indicated index. All elements to the right
         * have their indices decremented by one.
         * @param index the index of the element to remove
         * Returns: condition:
         * <PRE>
         * size() = PREV(this).size()-1 &&
         * foreach (int i in 0..index-1)      get(i).equals(PREV(this).get(i)); &&
         * foreach (int i in index..size()-1) get(i).equals(PREV(this).get(i+1));
         * Version change: always
         * </PRE>
         * Throws: NoSuchElementException if index is not in range 0..size()-1
        **/
        public void removeAt (int index);


        /**
         * Insert element at front of the sequence.
         * Behaviorally equivalent to insert(0, element)
         * @param element the element to add
         * Throws: IllegalElementException if !canInclude(element)
        **/

        public void prepend(T element);


        /**
         * replace element at front of the sequence with new value.
         * Behaviorally equivalent to replace(0, element);
        **/
        public void replaceHead(T element);

        /**
         * Remove the leftmost element. 
         * Behaviorally equivalent to remove(0);
        **/

        public void removeHead();


        /**
         * insert element at end of the sequence
         * Behaviorally equivalent to insert(size(), element)
         * @param element the element to add
         * Throws: IllegalElementException if !canInclude(element)
        **/

        public void append(T element);
        public alias append opCatAssign;

        /**
         * replace element at end of the sequence with new value
         * Behaviorally equivalent to replace(size()-1, element);
        **/

        public void replaceTail(T element);



        /**
         * Remove the rightmost element. 
         * Behaviorally equivalent to remove(size()-1);
         * Throws: NoSuchElementException if isEmpty
        **/
        public void removeTail();


        /**
         * Remove the elements from fromIndex to toIndex, inclusive.
         * No effect if fromIndex > toIndex.
         * Behaviorally equivalent to
         * <PRE>
         * for (int i = fromIndex; i &lt;= toIndex; ++i) remove(fromIndex);
         * </PRE>
         * @param index the index of the first element to remove
         * @param index the index of the last element to remove
         * Returns: condition:
         * <PRE>
         * let n = max(0, toIndex - fromIndex + 1 in
         *  size() == PREV(this).size() - 1 &&
         *  for (int i in 0 .. fromIndex - 1)     get(i).equals(PREV(this).get(i)) && 
         *  for (int i in fromIndex .. size()- 1) get(i).equals(PREV(this).get(i+n) 
         *  Version change iff n > 0 
         * </PRE>
         * Throws: NoSuchElementException if fromIndex or toIndex is not in 
         * range 0..size()-1
        **/

        public void removeRange(int fromIndex, int toIndex);


        /**
         * Prepend all elements of enumeration e, preserving their order.
         * Behaviorally equivalent to addElementsAt(0, e)
         * @param e the elements to add
        **/

        public void prepend(Iterator!(T) e);


        /**
         * Append all elements of enumeration e, preserving their order.
         * Behaviorally equivalent to addElementsAt(size(), e)
         * @param e the elements to add
        **/
        public void append(Iterator!(T) e);
}


