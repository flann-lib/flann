/*
File: Cell.d

Originally written by Doug Lea and released into the public domain. 
Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
Inc, Loral, and everyone contributing, testing, and using this code.

History:
Date     Who                What
24Sep95  dl@cs.oswego.edu   Create from tango.util.collection.d  working file
9Apr97   dl                 made Serializable

*/


module tango.util.collection.impl.Cell;

/**
 *
 *
 * Cell is the base of a bunch of implementation classes
 * for lists and the like.
 * The base version just holds an Object as its element value
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public class Cell (T)
{
        // instance variables
        private T element_;

        /**
         * Make a cell with element value v
        **/

        public this (T v)
        {
                element_ = v;
        }

        /**
         * Make A cell with null element value
        **/

        public this ()
        {
//                element_ = null;
        }

        /**
         * return the element value
        **/

        public final T element()
        {
                return element_;
        }

        /**
         * set the element value
        **/

        public final void element (T v)
        {
                element_ = v;
        }

        public final int elementHash ()
        {
                return typeid(T).getHash(&element_);
        }

        protected Cell duplicate()
        {
                return new Cell (element_);
        }
}
