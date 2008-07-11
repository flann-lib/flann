/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

module tango.io.selector.Selector;

/**
 * A multiplexor of conduit I/O events.
 *
 * A Selector can wait for I/O events (Read, Write, etc.) for multiple
 * conduits efficiently (i.e. without consuming CPU cycles).
 *
 * The Selector is an alias for your system's most efficient I/O multiplexor,
 * which will be determined during compilation.
 *
 * To create a Selector you need to use the open() method and when you decide
 * you no longer need it you should call its close() method to free any system
 * resources it may be consuming. All selectors that need to free resources
 * when close() is called also implement a destructor that automatically calls
 * this method. This means that if you declare your selector instance with the
 * 'auto' keyword you won't have to worry about doing it manually.
 *
 * Once you have open()'ed your selector you need to associate the conduits to
 * it by using the register() method. This method receives the conduit and the
 * events you want to track for it. For example, if you wanted to read from
 * the conduit you would do:
 *
 * ---
 * selector.register(conduit, Event.Read, myObject);
 * ---
 *
 * This method also accepts an optional third parameter to associate a
 * user-defined object to the conduit. These three parameters together define
 * a SelectionKey, which is what you'll receive when the conduit is "selected"
 * (i.e. receives an event).
 *
 * If you need to modify your conduit's registration you need to use the
 * reregister() method, which works like register(), but expects to be passed
 * a conduit that has already been associated to the selector:
 *
 * ---
 * selector.reregister(conduit, Event.Write, myObject);
 * ---
 *
 * If you need to remove a conduit from the selector you do it by calling
 * unregister():
 *
 * ---
 * selector.unregister(conduit);
 * ---
 *
 * Once you are done setting up the conduits you will want to wait for I/O
 * events for them. To do that you need to use the select() method. This
 * method blocks until either one of the conduits is selected or the
 * specified timeout is reached. Even though it has two different versions:
 * a) select(); b) select(Interval); the first one is just the same as doing
 * select(Interval.max). In that case we don't have a timeout and
 * select() blocks until a conduit receives an event.
 *
 * When select() returns you will receive an integer; if this integer is
 * bigger than 0, it indicates the number of conduits that have been selected.
 * If this number is 0, the it means that the selector reached a timeout, and
 * if it's -1, then it means that there was an error. A normal block that deals 
 * with the selection process would look like this:
 *
 * ---
 * try
 * {
 *     int eventCount = selector.select(10.0);
 *     if (eventCount > 0)
 *     {
 *         // Process the I/O events in the selected set
 *     }
 *     else if (eventCount == 0)
 *     {
 *         // Timeout
 *     }
 *     else if (eventCount == -1)
 *     {
 *         // Error
 *     }
 *     else
 *     {
 *         // Error: should never happen.
 *     }
 * }
 * catch (SelectorException e)
 * {
 *     Stdout.format("Exception caught: {0}", e.toString()).newline();
 * }
 * ---
 *
 * Finally, to gather the events you need to iterate over the selector's
 * selection set, which can be accessed via the selectedSet() method.
 *
 * ---
 * foreach (SelectionKey key; selector.selectedSet())
 * {
 *     if (key.isReadable())
 *     {
 *         // Read from conduit
 *         // [...]
 *         // Then register it for writing
 *         selector.reregister(key.conduit, Event.Write, key.attachment);
 *     }
 *
 *     if (key.isWriteable())
 *     {
 *         // Write to conduit
 *         // [...]
 *         // Then register it for reading
 *         selector.reregister(key.conduit, Event.Read, key.attachment);
 *     }
 *
 *     if (key.isError())
 *     {
 *         // Problem with conduit; remove it from selector
 *         selector.remove(conduit);
 *     }
 * }
 * ---
 */
version (linux)
{
    public import tango.io.selector.EpollSelector;

    /**
     * Default Selector for Linux.
     */
    alias EpollSelector Selector;
}
else version(Posix)
{
    public import tango.io.selector.PollSelector;

    /**
     * Default Selector for POSIX-compatible platforms.
     */
    alias PollSelector Selector;
}
else
{
    public import tango.io.selector.SelectSelector;

    /**
     * Default Selector for Windows.
     */
    alias SelectSelector Selector;
}
