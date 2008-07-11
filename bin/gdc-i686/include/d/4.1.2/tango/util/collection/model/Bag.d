/*
 File: Bag.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from collections.d  working file

*/


module tango.util.collection.model.Bag;

private import  tango.util.collection.model.BagView,
                tango.util.collection.model.Iterator,
                tango.util.collection.model.Dispenser;

/**
 * Bags are collections supporting multiple occurrences of elements.
 * author: Doug Lea
**/

public interface Bag(V) : BagView!(V), Dispenser!(V)
{
        public alias add opCatAssign;

        void add (V);

        void addIf (V);

        void add (Iterator!(V));
}


