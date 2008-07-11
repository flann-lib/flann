/*
 File: CLCell.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from tango.util.collection.d  working file
 13Oct95  dl                 Changed protection statuses

*/


module tango.util.collection.impl.CLCell;

private import tango.util.collection.impl.Cell;


/**
 *
 *
 * CLCells are cells that are always arranged in circular lists
 * They are pure implementation tools
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public class CLCell(T) : Cell!(T)
{
        // instance variables

        private CLCell next_;
        private CLCell prev_;

        // constructors

        /**
         * Make a cell with contents v, previous cell p, next cell n
        **/

        public this (T v, CLCell p, CLCell n)
        {
                super(v);
                prev_ = p;
                next_ = n;
        }

        /**
         * Make a singular cell
        **/

        public this (T v)
        {
                super(v);
                prev_ = this;
                next_ = this;
        }

        /**
         * Make a singular cell with null contents
        **/

        public this ()
        {
                super(T.init);
                prev_ = this;
                next_ = this;
        }

        /**
         * return next cell
        **/

        public final CLCell next()
        {
                return next_;
        }

        /**
         * Set next cell. You probably don't want to call this
        **/

        public final void next(CLCell n)
        {
                next_ = n;
        }


        /**
         * return previous cell
        **/
        public final CLCell prev()
        {
                return prev_;
        }

        /**
         * Set previous cell. You probably don't want to call this
        **/
        public final void prev(CLCell n)
        {
                prev_ = n;
        }


        /**
         * Return true if current cell is the only one on the list
        **/

        public final bool isSingleton()
        {
                return next_ is this;
        }

        public final void linkNext(CLCell p)
        {
                if (p !is null)
                   {
                   next_.prev_ = p;
                   p.next_ = next_;
                   p.prev_ = this;
                   next_ = p;
                   }
        }

        /**
         * Make a cell holding v and link it immediately after current cell
        **/

        public final void addNext(T v)
        {
                CLCell p = new CLCell(v, this, next_);
                next_.prev_ = p;
                next_ = p;
        }

        /**
         * make a node holding v, link it before the current cell, and return it
        **/

        public final CLCell addPrev(T v)
        {
                CLCell p = prev_;
                CLCell c = new CLCell(v, p, this);
                p.next_ = c;
                prev_ = c;
                return c;
        }

        /**
         * link p before current cell
        **/

        public final void linkPrev(CLCell p)
        {
                if (p !is null)
                   {
                   prev_.next_ = p;
                   p.prev_ = prev_;
                   p.next_ = this;
                   prev_ = p;
                   }
        }

        /**
         * return the number of cells in the list
        **/

        public final int _length()
        {
                int c = 0;
                CLCell p = this;
                do {
                   ++c;
                   p = p.next();
                   } while (p !is this);
                return c;
        }

        /**
         * return the first cell holding element found in a circular traversal starting
         * at current cell, or null if no such
        **/

        public final CLCell find(T element)
        {
                CLCell p = this;
                do {
                   if (p.element() == (element))
                       return p;
                   p = p.next();
                   } while (p !is this);
                return null;
        }

        /**
         * return the number of cells holding element found in a circular
         * traversal
        **/

        public final int count(T element)
        {
                int c = 0;
                CLCell p = this;
                do {
                   if (p.element() == (element))
                       ++c;
                   p = p.next();
                   } while (p !is this);
                return c;
        }

        /**
         * return the nth cell traversed from here. It may wrap around.
        **/

        public final CLCell nth(int n)
        {
                CLCell p = this;
                for (int i = 0; i < n; ++i)
                     p = p.next_;
                return p;
        }


        /**
         * Unlink the next cell.
         * This has no effect on the list if isSingleton()
        **/

        public final void unlinkNext()
        {
                CLCell nn = next_.next_;
                nn.prev_ = this;
                next_ = nn;
        }

        /**
         * Unlink the previous cell.
         * This has no effect on the list if isSingleton()
        **/

        public final void unlinkPrev()
        {
                CLCell pp = prev_.prev_;
                pp.next_ = this;
                prev_ = pp;
        }


        /**
         * Unlink self from list it is in.
         * Causes it to be a singleton
        **/

        public final void unlink()
        {
                CLCell p = prev_;
                CLCell n = next_;
                p.next_ = n;
                n.prev_ = p;
                prev_ = this;
                next_ = this;
        }

        /**
         * Make a copy of the list and return new head. 
        **/

        public final CLCell copyList()
        {
                CLCell hd = this;

                CLCell newlist = new CLCell(hd.element(), null, null);
                CLCell current = newlist;

                for (CLCell p = next_; p !is hd; p = p.next_)
                     {
                     current.next_ = new CLCell(p.element(), current, null);
                     current = current.next_;
                     }
                newlist.prev_ = current;
                current.next_ = newlist;
                return newlist;
        }
}

