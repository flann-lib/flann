/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

module tango.io.selector.SelectSelector;

public import tango.io.model.IConduit;

private import tango.io.selector.model.ISelector;
private import tango.io.selector.AbstractSelector;
private import tango.io.selector.SelectorException;
private import tango.sys.Common;

private import tango.stdc.errno;

debug (selector)
{
    private import tango.io.Stdout;
    private import tango.text.convert.Integer;
}


version (Windows)
{
    import tango.core.Thread;

    private
    {
        // Opaque struct
        struct fd_set
        {
        }

        extern (Windows) int select(int nfds, fd_set* readfds, fd_set* writefds,
                                    fd_set* errorfds, timeval* timeout);
    }
}


/**
 * Selector that uses the select() system call to receive I/O events for
 * the registered conduits. To use this class you would normally do
 * something like this:
 *
 * Examples:
 * ---
 * import tango.io.selector.SelectSelector;
 *
 * Socket socket;
 * ISelector selector = new SelectSelector();
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
public class SelectSelector: AbstractSelector
{
    /**
     * Alias for the select() method as we're not reimplementing it in
     * this class.
     */
    alias AbstractSelector.select select;

    uint _size;
    private SelectionKey[ISelectable.Handle] _keys;
    private HandleSet _readSet;
    private HandleSet _writeSet;
    private HandleSet _exceptionSet;
    private HandleSet _selectedReadSet;
    private HandleSet _selectedWriteSet;
    private HandleSet _selectedExceptionSet;
    int _eventCount;
    version (Posix)
    {
        private ISelectable.Handle _maxfd = cast(ISelectable.Handle) -1;

        /**
         * Default number of SelectionKey's that will be handled by the
         * SelectSelector.
         */
        public const uint DefaultSize = 1024;
    }
    else
    {
        /**
         * Default number of SelectionKey's that will be handled by the
         * SelectSelector.
         */
        public const uint DefaultSize = 63;
    }

    /**
     * Open the select()-based selector.
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
        _size = size;
    }

    /**
     * Close the selector.
     *
     * Remarks:
     * It can be called multiple times without harmful side-effects.
     */
    public void close()
    {
        _size = 0;
        _keys = null;
        _readSet = null;
        _writeSet = null;
        _exceptionSet = null;
        _selectedReadSet = null;
        _selectedWriteSet = null;
        _selectedExceptionSet = null;
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
        ISelectable.Handle handle = conduit.fileHandle();

        debug (selector)
            Stdout.format("--- SelectSelector.register(handle={0}, events=0x{1:x})\n",
                   cast(int) handle, cast(uint) events);

        // We make sure that the conduit is not already registered to
        // the Selector
        SelectionKey* key = (conduit.fileHandle() in _keys);

        if (key is null)
        {
            // Keep record of the Conduits for whom we're tracking events.
            _keys[handle] = new SelectionKey(conduit, events, attachment);

            if ((events & Event.Read) || (events & Event.Hangup))
            {
                if (_readSet is null)
                {
                    _readSet = new HandleSet(_size);
                    _selectedReadSet = new HandleSet(_size);
                }
                _readSet.set(handle);
            }

            if (events & Event.Write)
            {
                if (_writeSet is null)
                {
                    _writeSet = new HandleSet(_size);
                    _selectedWriteSet = new HandleSet(_size);
                }
                _writeSet.set(handle);
            }

            if (events & Event.Error)
            {
                if (_exceptionSet is null)
                {
                    _exceptionSet = new HandleSet(_size);
                    _selectedExceptionSet = new HandleSet(_size);
                }
                _exceptionSet.set(handle);
            }

            version (Posix)
            {
                if (handle > _maxfd)
                    _maxfd = handle;
            }
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
        ISelectable.Handle handle = conduit.fileHandle();

        debug (selector)
            Stdout.format("--- SelectSelector.reregister(handle={0}, events=0x{1:x})\n",
                          cast(int) handle, cast(uint) events);

        SelectionKey *key = (handle in _keys);
        if (key !is null)
        {
            if ((events & Event.Read) || (events & Event.Hangup))
            {
                if (_readSet is null)
                {
                    _readSet = new HandleSet(_size);
                    _selectedReadSet = new HandleSet(_size);
                }
                _readSet.set(handle);
            }
            else if (_readSet !is null)
            {
                _readSet.clear(handle);
            }

            if ((events & Event.Write))
            {
                if (_writeSet is null)
                {
                    _writeSet = new HandleSet(_size);
                    _selectedWriteSet = new HandleSet(_size);
                }
                _writeSet.set(handle);
            }
            else if (_writeSet !is null)
            {
                _writeSet.clear(handle);
            }

            if (events & Event.Error)
            {
                if (_exceptionSet is null)
                {
                    _exceptionSet = new HandleSet(_size);
                    _selectedExceptionSet = new HandleSet(_size);
                }
                _exceptionSet.set(handle);
            }
            else if (_exceptionSet !is null)
            {
                _exceptionSet.clear(handle);
            }

            version (Posix)
            {
                if (handle > _maxfd)
                    _maxfd = handle;
            }

            (*key).events = events;
            (*key).attachment = attachment;
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
            ISelectable.Handle handle = conduit.fileHandle();

            debug (selector)
                Stdout.format("--- SelectSelector.unregister(handle={0})\n",
                              cast(int) handle);

            SelectionKey* removed = (handle in _keys);

            if (removed !is null)
            {
                if (_exceptionSet !is null)
                {
                    _exceptionSet.clear(handle);
                }
                if (_writeSet !is null)
                {
                    _writeSet.clear(handle);
                }
                if (_readSet !is null)
                {
                    _readSet.clear(handle);
                }
                _keys.remove(handle);

                version (Posix)
                {
                    // If we're removing the biggest handle we've entered so far
                    // we need to recalculate this value for the set.
                    if (handle == _maxfd)
                    {
                        while (--_maxfd >= 0)
                        {
                            if ((_readSet !is null && _readSet.isSet(_maxfd)) ||
                                (_writeSet !is null && _writeSet.isSet(_maxfd)) ||
                                (_exceptionSet !is null && _exceptionSet.isSet(_maxfd)))
                            {
                                break;
                            }
                        }
                    }
                }
            }
            else
            {
                debug (selector)
                    Stdout.format("--- SelectSelector.unregister(handle={0}): conduit was not found\n",
                                  cast(int) conduit.fileHandle());
                throw new UnregisteredConduitException(__FILE__, __LINE__);
            }
        }
    }

    /**
     * Wait for I/O events from the registered conduits for a specified
     * amount of time.
     *
     * Params:
     * timeout  = TimeSpan with the maximum amount of time that the
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
        fd_set *readfds;
        fd_set *writefds;
        fd_set *exceptfds;
        timeval tv;
        version (Windows)
            bool handlesAvailable = false;

        debug (selector)
            Stdout.format("--- SelectSelector.select(timeout={0} msec)\n", timeout.millis);

        if (_readSet !is null)
        {
            debug (selector)
                _readSet.dump("_readSet");

            version (Windows)
                handlesAvailable = handlesAvailable || (_readSet.length > 0);

            readfds = cast(fd_set*) _selectedReadSet.copy(_readSet);
        }
        if (_writeSet !is null)
        {
            debug (selector)
                _writeSet.dump("_writeSet");

            version (Windows)
                handlesAvailable = handlesAvailable || (_writeSet.length > 0);

            writefds = cast(fd_set*) _selectedWriteSet.copy(_writeSet);
        }
        if (_exceptionSet !is null)
        {
            debug (selector)
                _exceptionSet.dump("_exceptionSet");

            version (Windows)
                handlesAvailable = handlesAvailable || (_exceptionSet.length > 0);

            exceptfds = cast(fd_set*) _selectedExceptionSet.copy(_exceptionSet);
        }

        version (Posix)
        {
            while (true)
            {
                toTimeval(&tv, timeout);

                // FIXME: add support for the wakeup() call.
                _eventCount = .select(_maxfd + 1, readfds, writefds, exceptfds, timeout is TimeSpan.max ? null : &tv);

                debug (selector)
                    Stdout.format("---   .select() returned {0} (maxfd={1})\n",
                                  _eventCount, cast(int) _maxfd);
                if (_eventCount >= 0)
                {
                    break;
                }
                else
                {
                    if (errno != EINTR || !_restartInterruptedSystemCall)
                    {
                        // checkErrno() always throws an exception
                        checkErrno(__FILE__, __LINE__);
                    }
                    debug (selector)
                        Stdout.print("--- Restarting select() after being interrupted\n");
                }
            }
        }
        else
        {
            // Windows returns an error when select() is called with all three
            // handle sets empty, so we emulate the POSIX behavior by calling
            // Thread.sleep().
            if (handlesAvailable)
            {
                toTimeval(&tv, timeout);

                // FIXME: Can a system call be interrupted on Windows?
                _eventCount = .select(ISelectable.Handle.max, readfds, writefds, exceptfds, timeout is TimeSpan.max ? null : &tv);

                debug (selector)
                    Stdout.format("---   .select() returned {0}\n", _eventCount);
            }
            else
            {
                Thread.sleep(timeout.interval());
                _eventCount = 0;
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
        return (_eventCount > 0 ? new SelectSelectionSet(_keys, cast(uint) _eventCount, _selectedReadSet,
                                                         _selectedWriteSet, _selectedExceptionSet) : null);
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
}

/**
 * SelectionSet for the select()-based Selector.
 */
private class SelectSelectionSet: ISelectionSet
{
    private SelectionKey[ISelectable.Handle] _keys;
    private uint _eventCount;
    private HandleSet _readSet;
    private HandleSet _writeSet;
    private HandleSet _exceptionSet;

    protected this(SelectionKey[ISelectable.Handle] keys, uint eventCount,
                   HandleSet readSet, HandleSet writeSet, HandleSet exceptionSet)
    {
        _keys = keys;
        _eventCount = eventCount;
        _readSet = readSet;
        _writeSet = writeSet;
        _exceptionSet = exceptionSet;
    }

    public uint length()
    {
        return _eventCount;
    }

    public int opApply(int delegate(inout SelectionKey) dg)
    {
        int rc = 0;
        ISelectable.Handle handle;
        Event events;

        debug (selector)
            Stdout.format("--- SelectSelectionSet.opApply() ({0} elements)\n", _eventCount);

        foreach (SelectionKey current; _keys)
        {
            handle = current.conduit.fileHandle();

            if (_readSet !is null && _readSet.isSet(handle))
                events = Event.Read;
            else
                events = Event.None;

            if (_writeSet !is null && _writeSet.isSet(handle))
                events |= Event.Write;

            if (_exceptionSet !is null && _exceptionSet.isSet(handle))
                events |= Event.Error;

            // Only invoke the delegate if there is an event for the conduit.
            if (events != Event.None)
            {
                current.events = events;

                debug (selector)
                    Stdout.format("---   Calling foreach delegate with selection key ({0}, 0x{1:x})\n",
                                  cast(int) handle, cast(uint) events);

                if (dg(current) != 0)
                {
                    rc = -1;
                    break;
                }
            }
            else
            {
                debug (selector)
                    Stdout.format("---   Handle {0} doesn't have pending events\n",
                                  cast(int) handle);
            }
        }
        return rc;
    }
}


version (Windows)
{
    /**
     * Helper class used by the select()-based Selector to store handles.
     * On Windows the handles are kept in an array of uints and the first
     * element of the array stores the array "length" (i.e. number of handles
     * in the array). Everything is stored so that the native select() API
     * can use the HandleSet without additional conversions by just casting it
     * to a fd_set*.
     */
    private class HandleSet
    {
        /** Default number of handles that will be held in the HandleSet. */
        public const uint DefaultSize = 63;

        private uint[] _buffer;

        /**
         * Constructor. Sets the initial number of handles that will be held
         * in the HandleSet.
         */
        public this(uint size = DefaultSize)
        {
            _buffer = new uint[1 + size];
            _buffer[0] = 0;
        }

        /**
         * Return the number of handles present in the HandleSet.
         */
        public uint length()
        {
            return _buffer[0];
        }

        /**
         * Remove all the handles from the set.
         */
        private void reset()
        {
            _buffer[0] = 0;
        }

        /**
         * Add the handle to the set.
         */
        public void set(ISelectable.Handle handle)
        in
        {
            assert(handle >= 0);
        }
        body
        {
            if (!isSet(handle))
            {
                // If we added too many sockets we increment the size of the buffer
                if (++_buffer[0] >= _buffer.length)
                {
                    _buffer.length = _buffer[0] + 1;
                }
                _buffer[_buffer[0]] = cast(uint) handle;
            }
        }

        /**
         * Remove the handle from the set.
         */
        public void clear(ISelectable.Handle handle)
        {
            for (uint i = 1; i <= _buffer[0]; ++i)
            {
                if (_buffer[i] == cast(uint) handle)
                {
                    // We don't need to keep the handles in the order in which
                    // they were inserted, so we optimize the removal by
                    // copying the last element to the position of the removed
                    // element.
                    if (i != _buffer[0])
                    {
                        _buffer[i] = _buffer[_buffer[0]];
                    }
                    _buffer[0]--;
                    return;
                }
            }
        }

        /**
         * Copy the contents of the HandleSet into this instance.
         */
        private HandleSet copy(HandleSet handleSet)
        {
            if (handleSet !is null)
            {
                _buffer[] = handleSet._buffer[];
            }
            else
            {
                _buffer = null;
            }
            return this;
        }

        /**
         * Check whether the handle has been set.
         */
        public bool isSet(ISelectable.Handle handle)
        {
            uint* start;
            uint* stop;

            for (start = _buffer.ptr + 1, stop = start + _buffer[0]; start != stop; start++)
            {
                if (*start == cast(uint) handle)
                    return true;
            }
            return false;
        }

        /**
         * Cast the current object to a pointer to an fd_set, to be used with the
         * select() system call.
         */
        public fd_set* opCast()
        {
            return cast(fd_set*) _buffer.ptr;
        }


        debug (selector)
        {
            /**
             * Dump the contents of a HandleSet into stdout.
             */
            void dump(char[] name = null)
            {
                if (_buffer !is null && _buffer.length > 0 && _buffer[0] > 0)
                {
                    char[] handleStr = new char[16];
                    char[] handleListStr;
                    bool isFirst = true;

                    if (name is null)
                    {
                        name = "HandleSet";
                    }

                    for (uint i = 1; i < _buffer[0]; ++i)
                    {
                        if (!isFirst)
                        {
                            handleListStr ~= ", ";
                        }
                        else
                        {
                            isFirst = false;
                        }

                        handleListStr ~= itoa(handleStr, _buffer[i]);
                    }

                    Stdout.formatln("--- {0}[{1}]: {2}", name, _buffer[0], handleListStr);
                }
            }
        }
    }
}
else version (Posix)
{
    private import tango.core.BitManip;

    /**
     * Helper class used by the select()-based Selector to store handles.
     * On POSIX-compatible platforms the handles are kept in an array of bits.
     * Everything is stored so that the native select() API can use the
     * HandleSet without additional conversions by casting it to a fd_set*.
     */
    private class HandleSet
    {
        /** Default number of handles that will be held in the HandleSet. */
        const uint DefaultSize     = 1024;
        /** Number of bits per element held in the _buffer */
        const uint BitsPerElement = uint.sizeof * 8;

        private uint[] _buffer;

        /**
         * Constructor. Sets the initial number of handles that will be held
         * in the HandleSet.
         */
        protected this(uint size = DefaultSize)
        {
            uint count;

            if (size < 1024)
                size = 1024;

            count = size / BitsPerElement;
            if (size % BitsPerElement != 0)
                count++;
            _buffer = new uint[count];
        }

        /**
         * Return the number of handles present in the HandleSet.
         */
        public uint length()
        {
            return _buffer.length;
        }

        /**
         * Remove all the handles from the set.
         */
        public void reset()
        {
            _buffer[] = 0;
        }

        /**
         * Add a handle to the set.
         */
        public void set(ISelectable.Handle handle)
        {
            // If we added too many sockets we increment the size of the buffer
            if (cast(uint) handle >= BitsPerElement * _buffer.length)
            {
                _buffer.length = cast(uint) handle + 1;
            }
            bts(&_buffer[elementOffset(handle)], bitOffset(handle));
        }

        /**
         * Remove a handle from the set.
         */
        public void clear(ISelectable.Handle handle)
        {
            btr(&_buffer[elementOffset(handle)], bitOffset(handle));
        }

        /**
         * Copy the contents of the HandleSet into this instance.
         */
        private HandleSet copy(HandleSet handleSet)
        {
            if (handleSet !is null)
            {
                _buffer[] = handleSet._buffer[];
            }
            else
            {
                _buffer = null;
            }
            return this;
        }

        /**
         * Check whether the handle has been set.
         */
        public bool isSet(ISelectable.Handle handle)
        {
            return (bt(&_buffer[elementOffset(handle)], bitOffset(handle)) != 0);
        }

        /**
         * Cast the current object to a pointer to an fd_set, to be used with the
         * select() system call.
         */
        public fd_set* opCast()
        {
            return cast(fd_set*) _buffer;
        }

        /**
         * Calculate the offset (in uints) of a handle in the set.
         */
        private static uint elementOffset(ISelectable.Handle handle)
        {
            return cast(uint) handle / BitsPerElement;
        }

        /**
         * Calculate the offset of the bit corresponding to a handle in the set.
         */
        private static uint bitOffset(ISelectable.Handle handle)
        {
            return cast(uint) handle % BitsPerElement;
        }

        debug (selector)
        {
            /**
             * Dump the contents of a HandleSet into stdout.
             */
            void dump(char[] name = null)
            {
                if (_buffer !is null && _buffer.length > 0)
                {
                    char[] handleStr = new char[16];
                    char[] handleListStr;
                    bool isFirst = true;

                    if (name is null)
                    {
                        name = "HandleSet";
                    }

                    for (uint i = 0; i < _buffer.length * _buffer[0].sizeof; ++i)
                    {
                        if (isSet(cast(ISelectable.Handle) i))
                        {
                            if (!isFirst)
                            {
                                handleListStr ~= ", ";
                            }
                            else
                            {
                                isFirst = false;
                            }
                            handleListStr ~= itoa(handleStr, i);
                        }
                    }
                    Stdout.formatln("--- {0}: {1}", name, handleListStr);
                }
            }
        }
    }
}
