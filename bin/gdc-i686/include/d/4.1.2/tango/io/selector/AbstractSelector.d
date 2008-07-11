/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

module tango.io.selector.AbstractSelector;

public import tango.io.model.IConduit;
public import tango.io.selector.SelectorException;

private import tango.io.selector.model.ISelector;
private import tango.sys.Common;
private import tango.stdc.errno;

version (Windows)
{
    public struct timeval
    {
        int tv_sec;     // seconds
        int tv_usec;    // microseconds
    }
}

/**
 * Base class for all selectors.
 *
 * A selector is a multiplexor for I/O events associated to a Conduit.
 * All selectors must implement this interface.
 *
 * A selector needs to be initialized by calling the open() method to pass
 * it the initial amount of conduits that it will handle and the maximum
 * amount of events that will be returned per call to select(). In both cases,
 * these values are only hints and may not even be used by the specific
 * ISelector implementation you choose to use, so you cannot make any
 * assumptions regarding what results from the call to select() (i.e. you
 * may receive more or less events per call to select() than what was passed
 * in the 'maxEvents' argument. The amount of conduits that the selector can
 * manage will be incremented dynamically if necessary.
 *
 * To add, modify or remove conduit registrations to the selector you use
 * the register(), reregister() and unregister() methods respectively.
 *
 * To wait for events from the conduits you need to call any of the select()
 * methods. The selector cannot be modified from another thread while
 * blocking on a call to these methods.
 *
 * Once the selector is no longer used you must call the close() method so
 * that the selector can free any resources it may have allocated in the call
 * to open().
 *
 * See_Also: ISelector
 *
 * Examples:
 * ---
 * import tango.io.selector.model.ISelector;
 * import tango.io.Stdout;
 * import tango.net.SocketConduit;
 *
 * AbstractSelector selector;
 * SocketConduit conduit1;
 * SocketConduit conduit2;
 * MyClass object1;
 * MyClass object2;
 * uint eventCount;
 *
 * // Initialize the selector assuming that it will deal with 2 conduits and
 * // will receive 2 events per invocation to the select() method.
 * selector.open(2, 2);
 *
 * selector.register(conduit, Event.Read, object1);
 * selector.register(conduit, Event.Write, object2);
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
 *                 Stdout("Sent 'MESSAGE' to peer\n");
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
abstract class AbstractSelector: ISelector
{
    /**
     * Restart interrupted system calls when blocking inside a call to select.
     */
    protected bool _restartInterruptedSystemCall = true;

    /**
     * Indicates whether interrupted system calls will be restarted when
     * blocking inside a call to select.
     */
    public bool restartInterruptedSystemCall()
    {
        return _restartInterruptedSystemCall;
    }

    /**
     * Sets whether interrupted system calls will be restarted when
     * blocking inside a call to select.
     */
    public void restartInterruptedSystemCall(bool value)
    {
        _restartInterruptedSystemCall = value;
    }

    /**
     * Initialize the selector.
     *
     * Params:
     * size         = value that provides a hint for the maximum amount of
     *                conduits that will be registered
     * maxEvents    = value that provides a hint for the maximum amount of
     *                conduit events that will be returned in the selection
     *                set per call to select.
     */
    public abstract void open(uint size, uint maxEvents);

    /**
     * Free any operating system resources that may have been allocated in the
     * call to open().
     *
     * Remarks:
     * Not all of the selectors need to free resources other than allocated
     * memory, but those that do will normally also add a call to close() in
     * their destructors.
     */
    public abstract void close();

    /**
     * Associate a conduit to the selector and track specific I/O events.
     *
     * Params:
     * conduit      = conduit that will be associated to the selector
     * events       = bit mask of Event values that represent the events that
     *                will be tracked for the conduit.
     * attachment   = optional object with application-specific data that will
     *                be available when an event is triggered for the conduit
     *
     * Examples:
     * ---
     * AbstractSelector selector;
     * SocketConduit conduit;
     * MyClass object;
     *
     * selector.register(conduit, Event.Read | Event.Write, object);
     * ---
     */
    public abstract void register(ISelectable conduit, Event events,
                                  Object attachment);

    /**
     * Modify the events that are being tracked or the 'attachment' field
     * for an already registered conduit.
     *
     * Params:
     * conduit      = conduit that will be associated to the selector
     * events       = bit mask of Event values that represent the events that
     *                will be tracked for the conduit.
     * attachment   = optional object with application-specific data that will
     *                be available when an event is triggered for the conduit
     *
     * Remarks:
     * The 'attachment' member of the SelectionKey will always be overwritten,
     * even if it's null.
     *
     * Examples:
     * ---
     * AbstractSelector selector;
     * SocketConduit conduit;
     * MyClass object;
     *
     * selector.reregister(conduit, Event.Write, object);
     * ---
     */
    public abstract void reregister(ISelectable conduit, Event events,
                                    Object attachment);

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
     */
    public abstract void unregister(ISelectable conduit);

    /**
     * Wait for I/O events from the registered conduits for a specified
     * amount of time.
     *
     * Returns:
     * The amount of conduits that have received events; 0 if no conduits
     * have received events within the specified timeout; and -1 if the
     * wakeup() method has been called from another thread.
     *
     * Remarks:
     * This method is the same as calling select(TimeSpan.max).
     */
    public int select()
    {
        return select(TimeSpan.max);
    }

    /**
     * Wait for I/O events from the registered conduits for a specified
     * amount of time.
     *
     * Note: This representation of timeout is not always accurate, so it is
     * possible that the function will return with a timeout before the
     * specified period.  For more accuracy, use the TimeSpan version.
     *
     * Params:
     * timeout  = the maximum amount of time in seconds that the
     *            selector will wait for events from the conduits; the
     *            amount of time is relative to the current system time
     *            (i.e. just the number of milliseconds that the selector
     *            has to wait for the events).
     *
     * Returns:
     * The amount of conduits that have received events; 0 if no conduits
     * have received events within the specified timeout.
     */
    public int select(double timeout)
    {
            return select(TimeSpan.interval(timeout));
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
     */
    public abstract int select(TimeSpan timeout);

    /**
     * Causes the first call to select() that has not yet returned to return
     * immediately.
     *
     * If another thread is currently blocked in an call to any of the
     * select() methods then that call will return immediately. If no
     * selection operation is currently in progress then the next invocation
     * of one of these methods will return immediately. In any case the value
     * returned by that invocation may be non-zero. Subsequent invocations of
     * the select() methods will block as usual unless this method is invoked
     * again in the meantime.
     */
    // public abstract void wakeup();

    /**
     * Return the selection set resulting from the call to any of the select()
     * methods.
     *
     * Remarks:
     * If the call to select() was unsuccessful or it did not return any
     * events, the returned value will be null.
     */
    public abstract ISelectionSet selectedSet();

    /**
     * Return the selection key resulting from the registration of a conduit
     * to the selector.
     *
     * Remarks:
     * If the conduit is not registered to the selector the returned
     * value will be null. No exception will be thrown by this method.
     */
    public abstract SelectionKey key(ISelectable conduit);

    /**
     * Cast the time duration to a C timeval struct.
    */
    public timeval* toTimeval(timeval* tv, TimeSpan interval)
    in
    {
        assert(tv !is null);
    }
    body
    {
        tv.tv_sec = cast(typeof(tv.tv_sec)) interval.seconds;
        tv.tv_usec = cast(typeof(tv.tv_usec)) (interval.micros % 1_000_000);
        return tv;
    }

    /**
     * Check the 'errno' global variable from the C standard library and
     * throw an exception with the description of the error.
     *
     * Params:
     * file     = name of the source file where the check is being made; you
     *            would normally use __FILE__ for this parameter.
     * line     = line number of the source file where this method was called;
     *            you would normally use __LINE__ for this parameter.
     *
     * Throws:
     * RegisteredConduitException when the conduit should not be registered
     * but it is (EEXIST); UnregisteredConduitException when the conduit
     * should be registered but it isn't (ENOENT);
     * InterruptedSystemCallException when a system call has been interrupted
     * (EINTR); OutOfMemoryException if a memory allocation fails (ENOMEM);
     * SelectorException for any of the other cases in which errno is not 0.
     */
    protected void checkErrno(char[] file, size_t line)
    {
        int errorCode = errno;
        switch (errorCode)
        {
            case EBADF:
                throw new SelectorException("Bad file descriptor", file, line);
                // break;
            case EEXIST:
                throw new RegisteredConduitException(file, line);
                // break;
            case EINTR:
                throw new InterruptedSystemCallException(file, line);
                // break;
            case EINVAL:
                throw new SelectorException("An invalid parameter was sent to a system call", file, line);
                // break;
            case ENFILE:
                throw new SelectorException("Maximum number of open files reached", file, line);
                // break;
            case ENOENT:
                throw new UnregisteredConduitException(file, line);
                // break;
            case ENOMEM:
                throw new OutOfMemoryException(file, line);
                // break;
            case EPERM:
                throw new SelectorException("The conduit cannot be used with this Selector", file, line);
                // break;
            default:
                throw new SelectorException("Unknown Selector error: " ~ SysError.lookup(errorCode), file, line);
                // break;
        }
    }
}
