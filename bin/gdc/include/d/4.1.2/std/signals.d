// This is part of the Phobos runtime libary for the D programming language.

/********************************
 * Signals and Slots are an implementation of the Observer Pattern.
 * Essentially, when a Signal is emitted, a list of connected Observers
 * (called slots) are called.
 *
 * There have been several D implementations of Signals and Slots.
 * This version makes use of several new features in D, which make
 * using it simpler and less error prone. In particular, it is no
 * longer necessary to instrument the slots.
 *
 * References:
 *	$(LINK2 http://scottcollins.net/articles/a-deeper-look-at-_signals-and-slots.html, A Deeper Look at Signals and Slots)$(BR)
 *	$(LINK2 http://en.wikipedia.org/wiki/Observer_pattern, Observer pattern)$(BR)
 *	$(LINK2 http://en.wikipedia.org/wiki/Signals_and_slots, Wikipedia)$(BR)
 *	$(LINK2 http://boost.org/doc/html/$(SIGNALS).html, Boost Signals)$(BR)
 *	$(LINK2 http://doc.trolltech.com/4.1/signalsandslots.html, Qt)$(BR)
 *
 *	There has been a great deal of discussion in the D newsgroups
 *	over this, and several implementations:
 *
 *	$(LINK2 http://www.digitalmars.com/d/archives/digitalmars/D/announce/signal_slots_library_4825.html, signal slots library)$(BR)
 *	$(LINK2 http://www.digitalmars.com/d/archives/digitalmars/D/Signals_and_Slots_in_D_42387.html, Signals and Slots in D)$(BR)
 *	$(LINK2 http://www.digitalmars.com/d/archives/digitalmars/D/Dynamic_binding_--_Qt_s_Signals_and_Slots_vs_Objective-C_42260.html, Dynamic binding -- Qt's Signals and Slots vs Objective-C)$(BR)
 *	$(LINK2 http://www.digitalmars.com/d/archives/digitalmars/D/Dissecting_the_SS_42377.html, Dissecting the SS)$(BR)
 *	$(LINK2 http://www.digitalmars.com/d/archives/digitalmars/D/dwt/about_harmonia_454.html, about harmonia)$(BR)
 *	$(LINK2 http://www.digitalmars.com/d/archives/digitalmars/D/announce/1502.html, Another event handling module)$(BR)
 *	$(LINK2 http://www.digitalmars.com/d/archives/digitalmars/D/41825.html, Suggestion: signal/slot mechanism)$(BR)
 *	$(LINK2 http://www.digitalmars.com/d/archives/digitalmars/D/13251.html, Signals and slots?)$(BR)
 *	$(LINK2 http://www.digitalmars.com/d/archives/digitalmars/D/10714.html, Signals and slots ready for evaluation)$(BR)
 *	$(LINK2 http://www.digitalmars.com/d/archives/digitalmars/D/1393.html, Signals &amp; Slots for Walter)$(BR)
 *	$(LINK2 http://www.digitalmars.com/d/archives/28456.html, Signal/Slot mechanism?)$(BR)
 *	$(LINK2 http://www.digitalmars.com/d/archives/19470.html, Modern Features?)$(BR)
 *	$(LINK2 http://www.digitalmars.com/d/archives/16592.html, Delegates vs interfaces)$(BR)
 *	$(LINK2 http://www.digitalmars.com/d/archives/16583.html, The importance of component programming (properties, signals and slots, etc))$(BR)
 *	$(LINK2 http://www.digitalmars.com/d/archives/16368.html, signals and slots)$(BR)
 *
 * Bugs:
 *	Slots can only be delegates formed from class objects or
 *	interfaces to class objects. If a delegate to something else
 *	is passed to connect(), such as a struct member function,
 *	a nested function or a COM interface, undefined behavior
 *	will result.
 *
 *	Not safe for multiple threads operating on the same signals
 *	or slots.
 * Macros:
 *	WIKI = Phobos/StdSignals
 *	SIGNALS=signals
 * Copyright:
 *	Public Domain
 * Author: Walter Bright, Digital Mars, www.digitalmars.com
 */

module std.signals;

import std.stdio;
import std.c.stdlib : calloc, realloc, free;
import std.outofmemory : _d_OutOfMemory;

// Special function for internal use only.
// Use of this is where the slot had better be a delegate
// to an object or an interface that is part of an object.
extern (C) Object _d_toObject(void* p);

//debug=signal;

/************************
 * Mixin to create a signal within a class object.
 *
 * Different signals can be added to a class by naming the mixins.
 *
 * Example:
---
import std.signals;
import std.stdio;

class Observer
{   // our slot
    void watch(char[] msg, int i)
    {
	writefln("Observed msg '%s' and value %s", msg, i);
    }
}

class Foo
{
    int value() { return _value; }

    int value(int v)
    {
	if (v != _value)
	{   _value = v;
	    // call all the connected slots with the two parameters
	    emit("setting new value", v);
	}
	return v;
    }

    // Mix in all the code we need to make Foo into a signal
    mixin Signal!(char[], int);

  private :
    int _value;
}

void main()
{
    Foo a = new Foo;
    Observer o = new Observer;

    a.value = 3;		// should not call o.watch()
    a.connect(&o.watch);	// o.watch is the slot
    a.value = 4;		// should call o.watch()
    a.disconnect(&o.watch);	// o.watch is no longer a slot
    a.value = 5;		// so should not call o.watch()
    a.connect(&o.watch);	// connect again
    a.value = 6;		// should call o.watch()
    delete o;			// destroying o should automatically disconnect it
    a.value = 7;		// should not call o.watch()
}
---
 * which should print:
 * <pre>
 * Observed msg 'setting new value' and value 4
 * Observed msg 'setting new value' and value 6
 * </pre>
 *
 */

template Signal(T1...)
{
    /***
     * A slot is implemented as a delegate.
     * The slot_t is the type of the delegate.
     * The delegate must be to an instance of a class or an interface
     * to a class instance.
     * Delegates to struct instances or nested functions must not be
     * used as slots.
     */
    alias void delegate(T1) slot_t;

    /***
     * Call each of the connected slots, passing the argument(s) i to them.
     */
    void emit( T1 i )
    {
        foreach (slot; slots[0 .. slots_idx])
	{   if (slot)
		slot(i);
	}
    }

    /***
     * Add a slot to the list of slots to be called when emit() is called.
     */
    void connect(slot_t slot)
    {
	/* Do this:
	 *    slots ~= slot;
	 * but use malloc() and friends instead
	 */
	auto len = slots.length;
	if (slots_idx == len)
	{
	    if (slots.length == 0)
	    {
		len = 4;
		auto p = std.signals.calloc(slot_t.sizeof, len);
		if (!p)
		    std.signals._d_OutOfMemory();
		slots = (cast(slot_t*)p)[0 .. len];
	    }
	    else
	    {
		len = len * 2 + 4;
		auto p = std.signals.realloc(slots.ptr, slot_t.sizeof * len);
		if (!p)
		    std.signals._d_OutOfMemory();
		slots = (cast(slot_t*)p)[0 .. len];
		slots[slots_idx + 1 .. length] = null;
	    }
	}
	slots[slots_idx++] = slot;

     L1:
	Object o = _d_toObject(slot.ptr);
	o.notifyRegister(&unhook);
    }

    /***
     * Remove a slot from the list of slots to be called when emit() is called.
     */
    void disconnect( slot_t slot)
    {
	debug (signal) writefln("Signal.disconnect(slot)");
	for (size_t i = 0; i < slots_idx; )
	{
	    if (slots[i] == slot)
	    {	slots_idx--;
		slots[i] = slots[slots_idx];
		slots[slots_idx] = null;	// not strictly necessary

		Object o = _d_toObject(slot.ptr);
		o.notifyUnRegister(&unhook);
	    }
	    else
		i++;
	}
    }

    /* **
     * Special function called when o is destroyed.
     * It causes any slots dependent on o to be removed from the list
     * of slots to be called by emit().
     */
    void unhook(Object o)
    {
	debug (signal) writefln("Signal.unhook(o = %s)", cast(void*)o);
	for (size_t i = 0; i < slots_idx; )
	{
	    if (_d_toObject(slots[i].ptr) is o)
	    {	slots_idx--;
		slots[i] = slots[slots_idx];
		slots[slots_idx] = null;	// not strictly necessary
	    }
	    else
		i++;
	}
    }

    /* **
     * There can be multiple destructors inserted by mixins.
     */
    ~this()
    {
	/* **
	 * When this object is destroyed, need to let every slot
	 * know that this object is destroyed so they are not left
	 * with dangling references to it.
	 */
	if (slots)
	{
	    foreach (slot; slots[0 .. slots_idx])
	    {
		if (slot)
		{   Object o = _d_toObject(slot.ptr);
		    o.notifyUnRegister(&unhook);
		}
	    }
	    std.signals.free(slots.ptr);
	    slots = null;
	}
    }

  private:
    slot_t[] slots;		// the slots to call from emit()
    size_t slots_idx;		// used length of slots[]
}

// A function whose sole purpose is to get this module linked in
// so the unittest will run.
void linkin() { }

unittest
{
    class Observer
    {
	void watch(char[] msg, int i)
	{
	    writefln("Observed msg '%s' and value %s", msg, i);
	}
    }

    class Foo
    {
	int value() { return _value; }

	int value(int v)
	{
	    if (v != _value)
	    {   _value = v;
		emit("setting new value", v);
	    }
	    return v;
	}

	mixin Signal!(char[], int);

      private:
	int _value;
    }

    Foo a = new Foo;
    Observer o = new Observer;

    a.value = 3;
    a.connect(&o.watch);
    a.value = 4;
    a.disconnect(&o.watch);
    a.value = 5;
    a.connect(&o.watch);
    a.value = 6;
    delete o;
    a.value = 7;
}
