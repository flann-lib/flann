/*
 File: Dispenser.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from collections.d  working file

*/


module tango.util.collection.model.Dispenser;

private import  tango.util.collection.model.View,
                tango.util.collection.model.Iterator;

/**
 *
 * Dispenser is the root interface of all mutable collections; i.e.,
 * collections that may have elements dynamically added, removed,
 * and/or replaced in accord with their collection semantics.
 *
 * author: Doug Lea
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public interface Dispenser(T) : View!(T)
{
        /**
         * Cause the collection to become empty. 
         * Returns: condition:
         * <PRE>
         * isEmpty() &&
         * Version change iff !PREV(this).isEmpty();
         * </PRE>
        **/

        public void clear ();

        /**
         * Replace an occurrence of oldElement with newElement.
         * No effect if does not hold oldElement or if oldElement.equals(newElement).
         * The operation has a consistent, but slightly special interpretation
         * when applied to Sets. For Sets, because elements occur at
         * most once, if newElement is already included, replacing oldElement with
         * with newElement has the same effect as just removing oldElement.
         * Returns: condition:
         * <PRE>
         * let int delta = oldElement.equals(newElement)? 0 : 
         *               max(1, PREV(this).instances(oldElement) in
         *  instances(oldElement) == PREV(this).instances(oldElement) - delta &&
         *  instances(newElement) ==  (this instanceof Set) ? 
         *         max(1, PREV(this).instances(oldElement) + delta):
         *                PREV(this).instances(oldElement) + delta) &&
         *  no other element changes &&
         *  Version change iff delta != 0
         * </PRE>
         * Throws: IllegalElementException if has(oldElement) and !allows(newElement)
        **/

        public void replace (T oldElement, T newElement);

        /**
         * Replace all occurrences of oldElement with newElement.
         * No effect if does not hold oldElement or if oldElement.equals(newElement).
         * The operation has a consistent, but slightly special interpretation
         * when applied to Sets. For Sets, because elements occur at
         * most once, if newElement is already included, replacing oldElement with
         * with newElement has the same effect as just removing oldElement.
         * Returns: condition:
         * <PRE>
         * let int delta = oldElement.equals(newElement)? 0 : 
                           PREV(this).instances(oldElement) in
         *  instances(oldElement) == PREV(this).instances(oldElement) - delta &&
         *  instances(newElement) ==  (this instanceof Set) ? 
         *         max(1, PREV(this).instances(oldElement) + delta):
         *                PREV(this).instances(oldElement) + delta) &&
         *  no other element changes &&
         *  Version change iff delta != 0
         * </PRE>
         * Throws: IllegalElementException if has(oldElement) and !allows(newElement)
        **/

        public void replaceAll(T oldElement, T newElement);

        /**
         * Remove and return an element.  Implementations
         * may strengthen the guarantee about the nature of this element.
         * but in general it is the most convenient or efficient element to remove.
         * <P>
         * Example usage. One way to transfer all elements from 
         * Dispenser a to MutableBag b is:
         * <PRE>
         * while (!a.empty()) b.add(a.take());
         * </PRE>
         * Returns: an element v such that PREV(this).has(v) 
         * and the postconditions of removeOneOf(v) hold.
         * Throws: NoSuchElementException iff isEmpty.
        **/

        public T take ();


        /**
         * Exclude all occurrences of each element of the Iterator.
         * Behaviorally equivalent to
         * <PRE>
         * while (e.more()) removeAll(e.value());
         * @param e the enumeration of elements to exclude.
         * Throws: CorruptedIteratorException is propagated if thrown
        **/

        public void removeAll (Iterator!(T) e);

        /**
         * Remove an occurrence of each element of the Iterator.
         * Behaviorally equivalent to
         * <PRE>
         * while (e.more()) remove (e.value());
         * @param e the enumeration of elements to remove.
         * Throws: CorruptedIteratorException is propagated if thrown
        **/

        public void remove (Iterator!(T) e);

        /**
         * Exclude all occurrences of the indicated element from the collection. 
         * No effect if element not present.
         * @param element the element to exclude.
         * Returns: condition: 
         * <PRE>
         * !has(element) &&
         * size() == PREV(this).size() - PREV(this).instances(element) &&
         * no other element changes &&
         * Version change iff PREV(this).has(element)
         * </PRE>
        **/

        public void removeAll (T element);


        /**
         * Remove an instance of the indicated element from the collection. 
         * No effect if !has(element)
         * @param element the element to remove
         * Returns: condition: 
         * <PRE>
         * let occ = max(1, instances(element)) in
         *  size() == PREV(this).size() - occ &&
         *  instances(element) == PREV(this).instances(element) - occ &&
         *  no other element changes &&
         *  version change iff occ == 1
         * </PRE>
        **/

        public void remove (T element);
}


