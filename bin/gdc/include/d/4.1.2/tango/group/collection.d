/**
 *
 * copyright:      Copyright (c) 2007 Steven Schveighoffer. All rights reserved
 * license:        BSD style: $(LICENSE)
 * version:        Nov 2007: Initial release
 * author:         schveiguy
 *
 * Convenience module to import all collection related modules
 */

module tango.group.collection;

public import   tango.util.collection.HashMap,
                tango.util.collection.TreeMap,
                tango.util.collection.TreeBag,
                tango.util.collection.LinkMap,
                tango.util.collection.HashSet,
                tango.util.collection.LinkSeq,
                tango.util.collection.ArrayBag,
                tango.util.collection.ArraySeq,
                tango.util.collection.CircularSeq;

public import   tango.util.collection.model.Seq,
                tango.util.collection.model.Map,
                tango.util.collection.model.Set,
                tango.util.collection.model.Bag,
                tango.util.collection.model.View,
                tango.util.collection.model.BagView,
                tango.util.collection.model.SeqView,
                tango.util.collection.model.MapView,
                tango.util.collection.model.SetView,
                tango.util.collection.model.Iterator,
                tango.util.collection.model.Sortable,
                tango.util.collection.model.Dispenser,
                tango.util.collection.model.Comparator,
                tango.util.collection.model.HashParams,
                tango.util.collection.model.SortedKeys,
                tango.util.collection.model.SortedValues,
                tango.util.collection.model.GuardIterator;


public import   tango.util.collection.iterator.ArrayIterator,
                tango.util.collection.iterator.FilteringIterator,
                tango.util.collection.iterator.InterleavingIterator;
