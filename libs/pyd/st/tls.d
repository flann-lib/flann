/**
 * Thread Local Storage for DigitalMars D.
 * This module adds a simple wrapper for system specific thread local storage
 * facilities.
 *
 * Authors: Mikola Lysenko, (mclysenk@mtu.edu)
 * License: Public Domain (100% free)
 * Date: 9-11-2006
 * Version: 0.3
 *
 * History:
 *  v0.3 - Fixed some clean up bugs and added fallback code for other platforms.
 *
 *  v0.2 - Merged with stackthreads.
 *
 *  v0.1 - Initial release.
 *
 * Bugs:
 *  On non-windows & non-posix systems, the implementation uses a synchronized
 *  block which may negatively impact performance.
 *
 *  Windows thread local storage is not correctly garbage collected.  Works 
 *  fine on Posix and other environments.
 *
 * Example:
 * <code><pre>
 * //Create a counter initially set to 5
 * auto tls_counter = new ThreadLocal!(int)(5);
 * 
 * //Create a thread
 * Thread t = new Thread(
 * {
 *   //Just decrement the counter until it reaches 0.
 *   while(tls_counter.val > 0)
 *   {
 *       writefln("Countdown ... %d", tls_counter.val);
 *       tls_counter.val = tls_counter.val - 1;
 *   }
 *   writefln("Blast off!");
 *   return 0;
 * });
 *
 * //
 * // Mess with the counter
 * //
 * assert(tls_counter.val == 5);
 * tls_counter.val = 20;
 * //
 * // Invoke the thread
 * //
 * t.start();
 * t.wait();
 * //
 * // This will print out:
 * //
 * //  Countdown ... 5
 * //  Countdown ... 4
 * //  Countdown ... 3
 * //  Countdown ... 2
 * //  Countdown ... 1
 * //  Blast off!
 * //
 * // After the thread completes, the counter is untouched
 * //
 * assert(tls_counter.val == 20);
 * </pre></code>
 */
module st.tls;

private import
    std.stdio,
    std.string,
    std.thread;

/**
 * A ThreadLocalException is generated if the runtime fails to properly
 * handle a ThreadLocal action.
 */
class ThreadLocalException : Exception
{
    this(char[] msg) { super(msg); }
}

version(linux)
    version = TLS_UsePthreads;
version(darwin)
    version = TLS_UsePthreads;
version(Win32)
    version = TLS_UseWinAPI;


version(TLS_UsePthreads)
{
private import std.gc;

private extern(C)
{
    typedef uint pthread_key_t;
    
    int pthread_key_delete(pthread_key_t);
    int pthread_key_create(pthread_key_t*, void function(void*));
    int pthread_setspecific(pthread_key_t, void*);
    void *pthread_getspecific(pthread_key_t);
    
    const int EAGAIN = 11;
    const int ENOMEM = 12;
    const int EINVAL = 22;
}

/**
 * Thread Local Storage is a mechanism for associating variables with specific
 * threads.  This can be used to ensure the principle of confinement, and is
 * useful for many sorts of algorithms.
 */
public class ThreadLocal(T)
{
    /**
     * Allocates the thread local storage.
     *
     * Params:
     *  def = An optional default value for the thread local storage.
     *
     * Throws:
     *  A ThreadLocalException if the system could not allocate the storage.
     */
    public this(T def = T.init)
    {
        this.def = def;
        
        switch(pthread_key_create(&tls_key, &clean_up))
        {
            case 0: break; //Success
            
            case EAGAIN: throw new ThreadLocalException
                ("Out of keys for thread local storage");
            
            case ENOMEM: throw new ThreadLocalException
                ("Out of memory for thread local storage");
            
            default: throw new ThreadLocalException
                ("Undefined error while creating thread local storage");
        }
        
        debug (ThreadLocal) writefln("TLS: Created %s", toString);
    }
    
    /**
     * Deallocates the thread local storage.
     */
    public ~this()
    {
        debug (ThreadLocal) writefln("TLS: Deleting %s", toString);
        pthread_key_delete(tls_key);
    }
    
    /**
     * Returns: The current value of the thread local storage.
     */
    public T val()
    {
        debug (ThreadLocal) writefln("TLS: Accessing %s", toString);
        
        TWrapper * w = cast(TWrapper*)pthread_getspecific(tls_key);
        
        if(w is null)
        {
            debug(ThreadLocal) writefln("TLS: Not found");
            return def;
        }
        
        debug(ThreadLocal) writefln("TLS: Found %s", w);
        
        return w.val;
    }
    
    /**
     * Sets the thread local storage.  Can be used with property syntax.
     *
     * Params:
     *  nv = The new value of the thread local storage.
     *
     * Returns:
     *  nv upon success
     *
     * Throws:
     *  ThreadLocalException if the system could not set the ThreadLocalStorage.
     */
    public T val(T nv)
    {
        debug (ThreadLocal) writefln("TLS: Setting %s", toString);
        
        void * w_old = pthread_getspecific(tls_key);
        
        if(w_old !is null)
        {
            (cast(TWrapper*)w_old).val = nv;
        }
        else
        {
            switch(pthread_setspecific(tls_key, TWrapper(nv)))
            {
                case 0: break;
                    
                case ENOMEM: throw new ThreadLocalException
                    ("Insufficient memory to set new thread local storage");
                
                case EINVAL: throw new ThreadLocalException
                    ("Invalid thread local storage");
                
                default: throw new ThreadLocalException
                    ("Undefined error when setting thread local storage");
            }
        }
        
        debug(ThreadLocal) writefln("TLS: Set %s", toString);
        return nv;
    }
    
    /**
     * Converts the thread local storage into a stringified representation.
     * Can be useful for debugging.
     * 
     * Returns:
     *  A string representing the thread local storage.
     */
    public char[] toString()
    {
        return format("ThreadLocal[%8x]", tls_key);
    }

    
    // Clean up thread local resources
    private extern(C) static void clean_up(void * obj)
    {
        if(obj is null)
            return;
        
        std.gc.removeRoot(obj);
        delete obj;
    }
    
    // The wrapper manages the thread local attributes`
    private struct TWrapper
    {
        T val;
        
        static void * opCall(T nv)
        {
            TWrapper * res = new TWrapper;
            std.gc.addRoot(cast(void*)res);
            res.val = nv;
            return cast(void*)res;
        }
    }
    
    private pthread_key_t tls_key;
    private T def;
}

} else version(TLS_UseWinAPI) {

private import std.gc;
    
private extern(Windows)
{
    uint TlsAlloc();
    bool TlsFree(uint);
    bool TlsSetValue(uint, void*);
    void* TlsGetValue(uint);
}

public class ThreadLocal(T)
{
    public this(T def = T.init)
    {
        this.def = def;
        this.tls_key = TlsAlloc();
    }
    
    public ~this()
    {
        TlsFree(tls_key);
    }
    
    public T val()
    {
        void * v = TlsGetValue(tls_key);
        
        if(v is null)
            return def;
        
        return (cast(TWrapper*)v).val;
    }
    
    public T val(T nv)
    {
        TWrapper * w_old = cast(TWrapper*)TlsGetValue(tls_key);
        
        if(w_old is null)
        {
            TlsSetValue(tls_key, TWrapper(nv));
        }
        else
        {
            w_old.val = nv;
        }
        
        return nv;
    }
    
    private uint tls_key;
    private T def;
        
    private struct TWrapper
    {
        T val;
        
        static void * opCall(T nv)
        {
            TWrapper * res = new TWrapper;
            std.gc.addRoot(cast(void*)res);
            res.val = nv;
            return cast(void*)res;
        }
    }
}

} else {

//Use a terrible hack instead...
//Performance will be bad, but at least we can fake the result.
public class ThreadLocal(T)
{
    public this(T def = T.init)
    {
        this.def = def;
    }
    
    public T val()
    {
        synchronized(this)
        {
            Thread t = Thread.getThis;
            
            if(t in tls_map)
                return tls_map[t];
            return def;
        }
    }
    
    public T val(T nv)
    {
        synchronized(this)
        {
            return tls_map[Thread.getThis] = nv;
        }
    }
    
    private T def;
    private T[Thread] tls_map;
}
    
}

unittest
{
    //Attempt to test out the tls
    auto tls = new ThreadLocal!(int);
    
    //Make sure default values work
    assert(tls.val == 0);
    
    //Init tls to something
    tls.val = 333;
    
    //Create some threads to mess with the tls
    Thread a = new Thread(
    {
        tls.val = 10;
        Thread.yield;
        assert(tls.val == 10);
        
        tls.val = 1010;
        Thread.yield;
        assert(tls.val == 1010);
        
        return 0;
    });
    
    Thread b = new Thread(
    {
        tls.val = 20;
        Thread.yield;
        assert(tls.val == 20);
        
        tls.val = 2020;
        Thread.yield;
        assert(tls.val == 2020);
        
        return 0;
    });
    
    a.start;
    b.start;
    
    //Wait until they have have finished
    a.wait;
    b.wait;
    
    //Make sure the value was preserved
    assert(tls.val == 333);
    
    //Try out structs
    struct TestStruct
    {
        int x = 10;
        real r = 20.0;
        byte b = 3;
    }
    
    auto tls2 = new ThreadLocal!(TestStruct);
    
    assert(tls2.val.x == 10);
    assert(tls2.val.r == 20.0);
    assert(tls2.val.b == 3);
    
    Thread x = new Thread(
    {
        assert(tls2.val.x == 10);
        
        TestStruct nv;
        nv.x = 20;
        tls2.val = nv;
        
        assert(tls2.val.x == 20);
        
        return 0;
    });
    
    x.start();
    x.wait();
    
    assert(tls2.val.x == 10);
    
    //Try out objects
    static class TestClass
    {
        int x = 10;
    }
    
    auto tls3 = new ThreadLocal!(TestClass)(new TestClass);
    
    assert(tls3.val.x == 10);
    
    Thread y = new Thread(
    {
        tls3.val.x ++;
        
        tls3.val = new TestClass;
        tls3.val.x = 2020;
        
        assert(tls3.val.x == 2020);
        
        return 0;
    });
    
    y.start;
    y.wait;
    
    assert(tls3.val.x == 11);
}
