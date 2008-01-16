/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

module tango.io.selector.EpollSelector;


version (linux)
{
    public import tango.io.model.IConduit;

    private import tango.io.selector.model.ISelector;
    private import tango.io.selector.AbstractSelector;
    private import tango.sys.Common;
    private import tango.sys.linux.linux;
    private import tango.stdc.errno;

    debug (selector)
        private import tango.io.Stdout;


    /**
     * Selector that uses the Linux epoll* family of system calls.
     *
     * This selector is the best option when dealing with large amounts of
     * conduits under Linux. It will scale much better than any of the other
     * options (PollSelector, SelectSelector). For small amounts of conduits
     * (n < 20) the PollSelector will probably be more performant.
     *
     * See_Also: ISelector, AbstractSelector
     *
     * Examples:
     * ---
     * import tango.io.selector.EpollSelector;
     * import tango.io.Stdout;
     * import tango.net.SocketConduit;
     *
     * SocketConduit conduit1;
     * SocketConduit conduit2;
     * EpollSelector selector = new EpollSelector();
     * MyClass object1 = new MyClass();
     * MyClass object2 = new MyClass();
     * uint eventCount;
     *
     * // Initialize the selector assuming that it will deal with 10 conduits and
     * // will receive 3 events per invocation to the select() method.
     * selector.open(10, 3);
     *
     * selector.register(conduit1, Event.Read, object1);
     * selector.register(conduit2, Event.Write, object2);
     *
     * eventCount = selector.select();
     *
     * if (eventCount > 0)
     * {
     *     char[16] buffer;
     *     int count;
     *
     *     foreach (SelectionKey key, selector.selectedSet())
     *     {
     *         if (key.isReadable())
     *         {
     *             count = (cast(SocketConduit) key.conduit).read(buffer);
     *             if (count != IConduit.Eof)
     *             {
     *                 Stdout.format("Received '{0}' from peer\n", buffer[0..count]);
     *                 selector.reregister(key.conduit, Event.Write, key.attachment);
     *             }
     *             else
     *             {
     *                 selector.unregister(key.conduit);
     *                 key.conduit.close();
     *             }
     *         }
     *
     *         if (key.isWritable())
     *         {
     *             count = (cast(SocketConduit) key.conduit).write("MESSAGE");
     *             if (count != IConduit.Eof)
     *             {
     *                 Stdout("Sent 'MESSAGE' to peer");
     *                 selector.reregister(key.conduit, Event.Read, key.attachment);
     *             }
     *             else
     *             {
     *                 selector.unregister(key.conduit);
     *                 key.conduit.close();
     *             }
     *         }
     *
     *         if (key.isError() || key.isHangup() || key.isInvalidHandle())
     *         {
     *             selector.unregister(key.conduit);
     *             key.conduit.close();
     *         }
     *     }
     * }
     *
     * selector.close();
     * ---
     */
    public class EpollSelector: AbstractSelector
    {
        /**
         * Alias for the select() method as we're not reimplementing it in 
         * this class.
         */
        alias AbstractSelector.select select;

        /**
         * Default number of SelectionKey's that will be handled by the
         * EpollSelector.
         */
        public const uint DefaultSize = 64;
        /**
         * Default maximum number of events that will be received per
         * invocation to select().
         */
        public const uint DefaultMaxEvents = 16;


        /** Map to associate the conduit handles with their selection keys */
        private SelectionKey[ISelectable.Handle] _keys;
        /** File descriptor returned by the epoll_create() system call. */
        private int _epfd = -1;
        /**
         * Array of events that is filled by epoll_wait() inside the call
         * to select().
         */
        private epoll_event[] _events;
        /** Number of events resulting from the call to select() */
        private int _eventCount = 0;


        /**
         * Destructor
         */
        ~this()
        {
            // Make sure that we release the epoll file descriptor once this
            // object is garbage collected.
            close();
        }

        /**
         * Open the epoll selector, makes a call to epoll_create()
         *
         * Params:
         * size         = maximum amount of conduits that will be registered;
         *                it will grow dynamically if needed.
         * maxEvents    = maximum amount of conduit events that will be
         *                returned in the selection set per call to select();
         *                this limit is enforced by this selector.
         *
         * Throws:
         * SelectorException if there are not enough resources to open the
         * selector (e.g. not enough file handles or memory available).
         */
        public void open(uint size = DefaultSize, uint maxEvents = DefaultMaxEvents)
        in
        {
            assert(size > 0);
            assert(maxEvents > 0);
        }
        body
        {
            _events = new epoll_event[maxEvents];

            _epfd = epoll_create(cast(int) size);
            if (_epfd < 0)
            {
                checkErrno(__FILE__, __LINE__);
            }
        }

        /**
         * Close the selector, releasing the file descriptor that had been
         * created in the previous call to open().
         *
         * Remarks:
         * It can be called multiple times without harmful side-effects.
         */
        public void close()
        {
            if (_epfd >= 0)
            {
                .close(_epfd);
                _epfd = -1;
            }
            _events = null;
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
         * registered to the selector; SelectorException if there are not
         * enough resources to add the conduit to the selector.
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
            epoll_event     event;
            SelectionKey    key = new SelectionKey(conduit, events, attachment);

            event.events = events;
            // We associate the selection key to the epoll_event to be able to
            // retrieve it efficiently when we get events for this handle.
            event.data.ptr = cast(void*) key;

            if (epoll_ctl(_epfd, EPOLL_CTL_ADD, conduit.fileHandle(), &event) == 0)
            {
                // We keep the keys in a map to make sure that the key is not
                // garbage collected while there is still a reference to it in
                // an epoll_event. This also allows to to efficiently find the
                // key corresponding to a handle in methods where this
                // association is not provided automatically.
                _keys[conduit.fileHandle()] = key;
            }
            else
            {
                checkErrno(__FILE__, __LINE__);
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
         * registered to the selector; SelectorException if there are not
         * enough resources to modify the conduit registration.
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
            SelectionKey* key = (conduit.fileHandle() in _keys);

            if (key !is null)
            {
                epoll_event event;

                (*key).events = events;
                (*key).attachment = attachment;

                event.events = events;
                event.data.ptr = cast(void*) *key;

                if (epoll_ctl(_epfd, EPOLL_CTL_MOD, conduit.fileHandle(), &event) != 0)
                {
                    checkErrno(__FILE__, __LINE__);
                }
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
         * registered to the selector; SelectorException if there are not
         * enough resources to remove the conduit registration.
         */
        public void unregister(ISelectable conduit)
        {
            if (conduit !is null)
            {
                if (epoll_ctl(_epfd, EPOLL_CTL_DEL, conduit.fileHandle(), null) == 0)
                {
                    _keys.remove(conduit.fileHandle());
                }
                else
                {
                    checkErrno(__FILE__, __LINE__);
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
            int to = (timeout != TimeSpan.max ? cast(int) timeout.millis : -1);

            while (true)
            {
                // FIXME: add support for the wakeup() call.
                _eventCount = epoll_wait(_epfd, _events.ptr, _events.length, to);
                if (_eventCount >= 0)
                {
                    break;
                }
                else
                {
                    if (errno != EINTR || !_restartInterruptedSystemCall)
                    {
                        checkErrno(__FILE__, __LINE__);
                    }
                    debug (selector)
                        Stdout("--- Restarting epoll_wait() after being interrupted by a signal\n");
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
            return (_eventCount > 0 ? new EpollSelectionSet(_events[0.._eventCount]) : null);
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
    private class EpollSelectionSet: ISelectionSet
    {
        private epoll_event[] _events;

        protected this(epoll_event[] events)
        {
            _events = events;
        }

        public uint length()
        {
            return _events.length;
        }

        /**
         * Iterate over all the Conduits that have received events.
         */
        public int opApply(int delegate(inout SelectionKey) dg)
        {
            int rc = 0;
            SelectionKey key;

            debug (selector)
                Stdout.format("--- EpollSelectionSet.opApply() ({0} events)\n", _events.length);

            foreach (epoll_event event; _events)
            {
                // Only invoke the delegate if there is an event for the conduit.
                if (event.events != 0)
                {
                    key = cast(SelectionKey) event.data.ptr;
                    key.events = cast(Event) event.events;

                    debug (selector)
                        Stdout.format("---   Event 0x{0:x} for handle {1}\n",
                                      cast(uint) event.events, cast(int) key.conduit.fileHandle());

                    rc = dg(key);
                    if (rc != 0)
                    {
                        break;
                    }
                }
            }
            return rc;
        }
    }
}

