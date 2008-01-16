/*
 File: View.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from collections.d  working file
 14dec95  dl                 Declare as a subinterface of Cloneable
 9Apr97   dl                 made Serializable

*/


module tango.util.collection.model.View;

private import tango.util.collection.model.Dispenser;
private import tango.util.collection.model.GuardIterator;


/**
 * this is the base interface for most classes in this package.
 *
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
 *
**/
public interface View(T) 
{
        /**
         * All Views implement duplicate
        **/

        public Dispenser!(T) duplicate ();
        public alias duplicate dup;

        /**
         * Report whether the View contains element.
         * Behaviorally equivalent to <CODE>instances(element) &gt;= 0</CODE>.
         * @param element the element to look for
         * Returns: true iff contains at least one member that is equal to element.
        **/
        public bool contains (T element);
        public alias contains opIn;

        /**
         * Report the number of elements in the View.
         * No other spurious effects.
         * Returns: number of elements
        **/
        public uint size ();
        public alias size length;

        /**
         * Report whether this View has no elements.
         * Behaviorally equivalent to <CODE>size() == 0</CODE>.
         * Returns: true if size() == 0
        **/

        public bool drained ();


        /**
         * All collections maintain a `version number'. The numbering
         * scheme is arbitrary, but is guaranteed to change upon every
         * modification that could possibly affect an elements() enumeration traversal.
         * (This is true at least within the precision of the `int' representation;
         * performing more than 2^32 operations will lead to reuse of version numbers).
         * Versioning
         * <EM>may</EM> be conservative with respect to `replacement' operations.
         * For the sake of versioning replacements may be considered as
         * removals followed by additions. Thus version numbers may change 
         * even if the old and new  elements are identical.
         * <P>
         * All element() enumerations for Mutable Collections track version
         * numbers, and raise inconsistency exceptions if the enumeration is
         * used (via get()) on a version other than the one generated
         * by the elements() method.
         * <P>
         * You can use versions to check if update operations actually have any effect
         * on observable state.
         * For example, clear() will cause cause a version change only
         * if the collection was previously non-empty.
         * Returns: the version number
        **/

        public uint mutation ();
        
        /**
         * Report whether the View COULD contain element,
         * i.e., that it is valid with respect to the View's
         * element screener if it has one.
         * Always returns false if element == null.
         * A constant function: if allows(v) is ever true it is always true.
         * (This property is not in any way enforced however.)
         * No other spurious effects.
         * Returns: true if non-null and passes element screener check
        **/
        public bool allows (T element);


        /**
         * Report the number of occurrences of element in View.
         * Always returns 0 if element == null.
         * Otherwise T.equals is used to test for equality.
         * @param element the element to look for
         * Returns: the number of occurrences (always nonnegative)
        **/
        public uint instances (T element);

        /**
         * Return an enumeration that may be used to traverse through
         * the elements in the View. Standard usage, for some
         * ViewT c, and some operation `use(T obj)':
         * <PRE>
         * for (Iterator e = c.elements(); e.more(); )
         *   use(e.value());
         * </PRE>
         * (The values of get very often need to
         * be coerced to types that you know they are.)
         * <P>
         * All Views return instances
         * of ViewIterator, that can report the number of remaining
         * elements, and also perform consistency checks so that
         * for MutableViews, element enumerations may become 
         * invalidated if the View is modified during such a traversal
         * (which could in turn cause random effects on the ViewT.
         * TO prevent this,  ViewIterators 
         * raise CorruptedIteratorException on attempts to access
         * gets of altered Views.)
         * Note: Since all View implementations are synchronizable,
         * you may be able to guarantee that element traversals will not be
         * corrupted by using the java <CODE>synchronized</CODE> construct
         * around code blocks that do traversals. (Use with care though,
         * since such constructs can cause deadlock.)
         * <P>
         * Guarantees about the nature of the elements returned by  get of the
         * returned Iterator may vary accross sub-interfaces.
         * In all cases, the enumerations provided by elements() are guaranteed to
         * step through (via get) ALL elements in the View.
         * Unless guaranteed otherwise (for example in Seq), elements() enumerations
         * need not have any particular get() ordering so long as they
         * allow traversal of all of the elements. So, for example, two successive
         * calls to element() may produce enumerations with the same
         * elements but different get() orderings.
         * Again, sub-interfaces may provide stronger guarantees. In
         * particular, Seqs produce enumerations with gets in
         * index order, ElementSortedViews enumerations are in ascending 
         * sorted order, and KeySortedViews are in ascending order of keys.
         * Returns: an enumeration e such that
         * <PRE>
         *   e.remaining() == size() &&
         *   foreach (v in e) has(e) 
         * </PRE>
        **/

        public GuardIterator!(T) elements ();

        /**
         traverse the collection content. This is cheaper than using an
         iterator since there is no creation cost involved.
        **/

        public int opApply (int delegate (inout T value) dg);

        /**
         expose collection content as an array
        **/

        public T[] toArray ();

        /**
         * Report whether other has the same element structure as this.
         * That is, whether other is of the same size, and has the same 
         * elements() properties.
         * This is a useful version of equality testing. But is not named
         * `equals' in part because it may not be the version you need.
         * <P>
         * The easiest way to decribe this operation is just to
         * explain how it is interpreted in standard sub-interfaces:
         * <UL>
         *  <LI> Seq and ElementSortedView: other.elements() has the 
         *        same order as this.elements().
         *  <LI> Bag: other.elements has the same instances each element as this.
         *  <LI> Set: other.elements has all elements of this
         *  <LI> Map: other has all (key, element) pairs of this.
         *  <LI> KeySortedView: other has all (key, element)
         *       pairs as this, and with keys enumerated in the same order as
         *       this.keys().
         *</UL>
         * @param other, a View
         * Returns: true if considered to have the same size and elements.
        **/

        public bool matches (View other);
        public alias matches opEquals;


        /**
         * Check the consistency of internal state, and raise exception if
         * not OK.
         * These should be `best-effort' checks. You cannot always locally
         * determine full consistency, but can usually approximate it,
         * and validate the most important representation invariants.
         * The most common kinds of checks are cache checks. For example,
         * A linked list that also maintains a separate record of the
         * number of items on the list should verify that the recorded
         * count matches the number of elements in the list.
         * <P>
         * This method should either return normally or throw:
         * Throws: ImplementationError if check fails
        **/

        public void checkImplementation();
}

