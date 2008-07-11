/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

module tango.io.selector.PollSelector;

version (Posix)
{
    public import tango.io.model.IConduit;

    private import tango.io.selector.model.ISelector;
    private import tango.io.selector.AbstractSelector;
    private import tango.io.selector.SelectorException;
    private import tango.sys.Common;
    private import tango.stdc.errno;

    version (linux)
        private import tango.sys.linux.linux;

    debug (selector)
        private import tango.io.Stdout;


    /**
     * Selector that uses the poll() system call to receive I/O events for
     * the registered conduits. To use this class you would normally do
     * something like this:
     *
     * Examples:
     * ---
     * import tango.io.selector.PollSelector;
     *
     * Socket socket;
     * ISelector selector = new PollSelector();
     *
     * selector.open(100, 10);
     *
     * // Register to read from socket
     * selector.register(socket, Event.Read);
     *
     * int eventCount = selector.select(0.1); // 0.1 seconds
     * if (eventCount > 0)
     * {
     *     // We can now read from the socket
     *     socket.read();
     * }
     * else if (eventCount == 0)
     * {
     *     // Timeout
     * }
     * else if (eventCount == -1)
     * {
     *     // Another thread called the wakeup() method.
     * }
     * else
     * {
     *     // Error: should never happen.
     * }
     *
     * selector.close();
     * ---
     */
    public class PollSelector: AbstractSelector
    {
        /**
         * Alias for the select() method as we're not reimplementing it in
         * this class.
         */
        alias AbstractSelector.select select;

        /**
         * Default number of SelectionKey's that will be handled by the
         * PollSelector.
         */
        public const uint DefaultSize = 64;

        /** Map to associate the conduit handles with their selection keys */
        private PollSelectionKey[ISelectable.Handle] _keys;
        private SelectionKey[] _selectedKeys;
        private pollfd[] _pfds;
        private uint _count = 0;
        private int _eventCount = 0;

        /**
         * Open the poll()-based selector.
         *
         * Params:
         * size         = maximum amount of conduits that will be registered;
         *                it will grow dynamically if needed.
         * maxEvents    = maximum amount of conduit events that will be
         *                returned in the selection set per call to select();
         *                this value is currently not used by this selector.
         */
        public void open(uint size = DefaultSize, uint maxEvents = DefaultSize)
        in
        {
            assert(size > 0);
        }
        body
        {
            _pfds = new pollfd[size];
        }

        /**
         * Close the selector.
         *
         * Remarks:
         * It can be called multiple times without harmful side-effects.
         */
        public void close()
        {
            _keys = null;
            _selectedKeys = null;
            _pfds = null;
            _count = 0;
            _eventCount = 0;
        }

        /**
         * Associate a conduit to the selector and track specific I/O events.
         *
         * Params:
         * conduit      = conduit that will be associated to the selector;
         *                must be a valid conduit (i.e. not null and open).
         * events       = bit mask of Event values that represent the events
         *                that will be tracked for the conduit.
         * attachment   = optional object with application-specific data that
         *                will be available when an event is triggered for the
         *                conduit
         *
         * Throws:
         * RegisteredConduitException if the conduit had already been
         * registered to the selector.
         *
         * Examples:
         * ---
         * selector.register(conduit, Event.Read | Event.Write, object);
         * ---
         */
        public void register(ISelectable conduit, Event events, Object attachment = null)
        in
        {
            assert(conduit !is null && conduit.fileHandle() >= 0);
        }
        body
        {
            debug (selector)
                Stdout.format("--- PollSelector.register(handle={0}, events=0x{1:x})\n",
                              cast(int) conduit.fileHandle(), cast(uint) events);

            // We make sure that the conduit is not already registered to
            // the Selector
            if ((conduit.fileHandle() in _keys) is null)
            {
                if (_count == _pfds.length)
                    _pfds.length = _pfds.length + 1;

                _pfds[_count].fd = conduit.fileHandle();
                _pfds[_count].events = cast(short) events;
                _pfds[_count].revents = 0;

                _keys[conduit.fileHandle()] = new PollSelectionKey(conduit, events, _count, attachment);
                _count++;
            }
            else
            {
                throw new RegisteredConduitException(__FILE__, __LINE__);
            }
        }

        /**
         * Modify the events that are being tracked or the 'attachment' field
         * for an already registered conduit.
         *
         * Params:
         * conduit      = conduit that will be associated to the selector;
         *                must be a valid conduit (i.e. not null and open).
         * events       = bit mask of Event values that represent the events
         *                that will be tracked for the conduit.
         * attachment   = optional object with application-specific data that
         *                will be available when an event is triggered for the
         *                conduit
         *
         * Remarks:
         * The 'attachment' member of the SelectionKey will always be
         * overwritten, even if it's null.
         *
         * Throws:
         * UnregisteredConduitException if the conduit had not been previously
         * registered to the selector.
         *
         * Examples:
         * ---
         * selector.reregister(conduit, Event.Write, object);
         * ---
         */
        public void reregister(ISelectable conduit, Event events, Object attachment = null)
        in
        {
            assert(conduit !is null && conduit.fileHandle() >= 0);
        }
        body
        {
            debug (selector)
                Stdout.format("--- PollSelector.reregister(handle={0}, events=0x{1:x})",
                              cast(int) conduit.fileHandle(), cast(uint) events);

            PollSelectionKey* current = (conduit.fileHandle() in _keys);

            if (current !is null)
            {
                debug (selector)
                    Stdout.format("--- Adding pollfd in index {0} (of {1})\n",
                                  current.index, _count);

                (*current).events = events;
                (*current).attachment = attachment;

                _pfds[current.index].events = cast(short) events;
            }
            else
            {
                throw new UnregisteredConduitException(__FILE__, __LINE__);
            }
        }

        /**
         * Remove a conduit from the selector.
         *
         * Params:
         * conduit      = conduit that had been previously associated to the
         *                selector; it can be null.
         *
         * Remarks:
         * Unregistering a null conduit is allowed and no exception is thrown
         * if this happens.
         *
         * Throws:
         * UnregisteredConduitException if the conduit had not been previously
         * registered to the selector.
         */
        public void unregister(ISelectable conduit)
        {
            if (conduit !is null)
            {
                try
                {
                    debug (selector)
                        Stdout.format("--- PollSelector.unregister(handle={0})\n",
                                      cast(int) conduit.fileHandle());

                    PollSelectionKey* removed = (conduit.fileHandle() in _keys);

                    if (removed !is null)
                    {
                        debug (selector)
                            Stdout.format("--- Removing pollfd in index {0} (of {1})\n",
                                          removed.index, _count);

                        for (uint i = removed.index + 1; i > 0 && i < _count; i++)
                        {
                            _pfds[i - 1] = _pfds[i];
                        }
                        _count--;

                        _keys.remove(conduit.fileHandle());
                    }
                    else
                    {
                        debug (selector)
                            Stdout.format("--- PollSelector.unregister(handle={0}): conduit was not found\n",
                                          cast(int) conduit.fileHandle());
                        throw new UnregisteredConduitException(__FILE__, __LINE__);
                    }
                }
                catch (Exception e)
                {
                    debug (selector)
                        Stdout.format("--- Exception inside PollSelector.unregister(handle={0}): {1}",
                                      cast(int) conduit.fileHandle(), e.toString());

                    throw new UnregisteredConduitException(__FILE__, __LINE__);
                }
            }
        }

        /**
         * Wait for I/O events from the registered conduits for a specified
         * amount of time.
         *
         * Params:
         * timeout  = Timespan with the maximum amount of time that the
         *            selector will wait for events from the conduits; the
         *            amount of time is relative to the current system time
         *            (i.e. just the number of milliseconds that the selector
         *            has to wait for the events).
         *
         * Returns:
         * The amount of conduits that have received events; 0 if no conduits
         * have received events within the specified timeout; and -1 if the
         * wakeup() method has been called from another thread.
         *
         * Throws:
         * InterruptedSystemCallException if the underlying system call was
         * interrupted by a signal and the 'restartInterruptedSystemCall'
         * property was set to false; SelectorException if there were no
         * resources available to wait for events from the conduits.
         */
        public int select(TimeSpan timeout)
        {
            int to = (timeout != TimeSpan.max ? cast(int) timeout.millis : -1);

            debug (selector)
                Stdout.format("--- PollSelector.select({0} ms): waiting on {1} handles\n",
                              to, _count);

            // We run the call to poll() inside a loop in case the system call
            // was interrupted by a signal and we need to restart it.
            while (true)
            {
                _eventCount = poll(_pfds.ptr, _count, to);
                if (_eventCount > 0)
                {
                    int i = 0;
                    PollSelectionKey* key;

                    if (_selectedKeys is null)
                    {
                        _selectedKeys = new SelectionKey[16];
                    }

                    // FIXME: add support for the wakeup() call.
                    foreach (pollfd pfd; _pfds[0 .. _count])
                    {
                        if (i < _eventCount)
                        {
                            if (pfd.revents != 0)
                            {
                                debug (selector)
                                    Stdout.format("--- Found events 0x{0:x} for handle {1} (index {2})\n",
                                                  cast(uint) pfd.revents, cast(int) pfd.fd, i);

                                // Find the key whose handle received an event
                                key = ((cast(ISelectable.Handle) pfd.fd) in _keys);
                                if (key !is null)
                                {
                                    // Enlarge the array of necessary
                                    if (i >= _selectedKeys.length)
                                    {
                                        // The underlying array worries about
                                        // incrementing the allocated block
                                        // efficiently.
                                        _selectedKeys.length = i + 1;
                                    }

                                    (*key).events = cast(Event) pfd.revents;

                                    _selectedKeys[i] = *key;
                                    i++;
                                }
                                else
                                {
                                    debug (selector)
                                        Stdout.format("--- Handle {0} was not found in the Selector\n",
                                                      cast(int) pfd.fd);
                                }
                            }
                        }
                        else
                        {
                            break;
                        }
                    }
                    _selectedKeys.length = i;
                    break;
                }
                else if (_eventCount == 0)
                {
                    // Timeout
                    break;
                }
                else // if (eventCount < 0)
                {
                    if (errno != EINTR || !_restartInterruptedSystemCall)
                    {
                        // The call to checkErrno() ends up throwing an exception
                        checkErrno(__FILE__, __LINE__);
                    }
                    debug (selector)
                        Stdout.print("--- Restarting poll() after being interrupted\n");
                }
            }
            return _eventCount;
        }

        /**
         * Return the selection set resulting from the call to any of the
         * select() methods.
         *
         * Remarks:
         * If the call to select() was unsuccessful or it did not return any
         * events, the returned value will be null.
         */
        public ISelectionSet selectedSet()
        {
            return (_eventCount > 0 ? new PollSelectionSet(_selectedKeys) : null);
        }

        /**
         * Return the selection key resulting from the registration of a
         * conduit to the selector.
         *
         * Remarks:
         * If the conduit is not registered to the selector the returned
         * value will be null. No exception will be thrown by this method.
         */
        public SelectionKey key(ISelectable conduit)
        {
            return (conduit !is null ? _keys[conduit.fileHandle()] : null);
        }

        unittest
        {
        }
    }

    /**
     * Class used to hold the list of Conduits that have received events.
     */
    private class PollSelectionSet: ISelectionSet
    {
        private SelectionKey[] _keys;

        protected this(SelectionKey[] keys)
        {
            _keys = keys;
        }

        public uint length()
        {
            return _keys.length;
        }

        /**
         * Iterate over all the Conduits that have received events.
         */
        public int opApply(int delegate(inout SelectionKey) dg)
        {
            int rc = 0;

            foreach (SelectionKey current; _keys)
            {
                if (dg(current) != 0)
                {
                    rc = -1;
                    break;
                }
            }
            return rc;
        }
    }

    /**
     * Class that holds the information that the PollSelector needs to deal
     * with each registered Conduit.
     */
    private class PollSelectionKey: SelectionKey
    {
        private uint _index;

        public this()
        {
        }

        public this(ISelectable conduit, Event events, uint index, Object attachment)
        {
            super(conduit, events, attachment);

            _index = index;
        }

        public uint index()
        {
            return _index;
        }

        public void index(uint index)
        {
            _index = index;
        }
    }
}

