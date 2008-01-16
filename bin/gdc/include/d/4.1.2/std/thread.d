/*
 *  Copyright (C) 2002-2006 by Digital Mars, www.digitalmars.com
 *  Written by Walter Bright
 *
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, subject to the following restrictions:
 *
 *  o  The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  o  Altered source versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *  o  This notice may not be removed or altered from any source
 *     distribution.
 */

/* NOTE: This file has been patched from the original DMD distribution to
   work with the GDC compiler.

   Modified by David Friedman, September 2007
*/

/**************************
 * The thread module defines the class $(B Thread).
 *
 * $(B Thread) is the basis
 * for writing multithreaded applications. Each thread
 * has a unique instance of class $(B Thread) associated with it.
 * It is important to use the $(B Thread) class to create and manage
 * threads as the garbage collector needs to know about all the threads.
 * Macros:
 *	WIKI=Phobos/StdThread
 */

module std.thread;

//debug=thread;

/* ================================ Win32 ================================= */

version (Win32)
{

private import std.c.windows.windows;

extern (Windows) alias uint (*stdfp)(void *);

extern (C)
    thread_hdl _beginthreadex(void* security, uint stack_size,
	stdfp start_addr, void* arglist, uint initflag,
	thread_id* thrdaddr);

/**
 * The type of the thread handle used by the operating system.
 * For Windows, it is equivalent to a HANDLE from windows.d.
 */
alias HANDLE thread_hdl;

alias uint thread_id;

/**
 * Thrown for errors.
 */
class ThreadError : Error
{
    this(char[] s)
    {
	super("Thread error: " ~ s);
    }
}

/**
 * One of these is created for each thread.
 */
class Thread
{
    /**
     * Constructor used by classes derived from Thread that override main(). 
     * The optional stacksize parameter default value of 0 will cause threads
     * to be created with the default size for the executable - Dave Fladebo
     */
    this(size_t stacksize = 0)
    {
	this.stacksize = stacksize;
    }

    /**
     * Constructor used by classes derived from Thread that override run().
     */
    this(int (*fp)(void *), void *arg, size_t stacksize = 0)
    {
	this.fp = fp;
	this.arg = arg;
	this.stacksize = stacksize;
    }

    /**
     * Constructor used by classes derived from Thread that override run().
     */
    this(int delegate() dg, size_t stacksize = 0)
    {
	this.dg = dg;
	this.stacksize = stacksize;
    }

    /**
     * The handle to this thread assigned by the operating system. This is set
     * to thread_id.init if the thread hasn't been started yet.
     */
    thread_hdl hdl;

    void* stackBottom;

    /**
     * Create a new thread and start it running. The new thread initializes
     * itself and then calls run(). start() can only be called once.
     */
    void start()
    {
	if (state != TS.INITIAL)
	    error("already started");

	synchronized (threadLock)
	{
	    for (int i = 0; 1; i++)
	    {
		if (i == allThreads.length)
		    error("too many threads");
		if (!allThreads[i])
		{   allThreads[i] = this;
		    idx = i;
		    if (i >= allThreadsDim)
			allThreadsDim = i + 1;
		    break;
		}
	    }
	    nthreads++;
	}

	state = TS.RUNNING;
	hdl = _beginthreadex(null, cast(uint)stacksize, &threadstart, cast(void*)this, 0, &id);
	if (hdl == cast(thread_hdl)0)
	{   state = TS.TERMINATED;
	    allThreads[idx] = null;
	    idx = -1;
	    error("failed to start");
	}
    }

    /**
     * Entry point for a thread. If not overridden, it calls the function
     * pointer fp and argument arg passed in the constructor, or the delegate
     * dg.
     * Returns: the thread exit code, which is normally 0.
     */
    int run()
    {
	if (fp)
	    return fp(arg);
	else if (dg)
	    return dg();
	assert(0);
    }

    /*****************************
     * Wait for this thread to terminate.
     * Simply returns if thread has already terminated.
     * Throws: $(B ThreadError) if the thread hasn't begun yet or
     * is called on itself.
     */
    void wait()
    {
	if (this is getThis())
	    error("wait on self");
	if (state == TS.RUNNING)
	{   DWORD dw;

	    dw = WaitForSingleObject(hdl, 0xFFFFFFFF);
	}
    }

    /*****************************
     * Wait for this thread to terminate.
     * Simply returns if thread has already terminated.
     * Throws: $(B ThreadError) if the thread hasn't begun yet or
     * is called on itself.
     */
    void wait(uint milliseconds)
    {
	if (this is getThis())
	    error("wait on self");
	if (state == TS.RUNNING)
	{   DWORD dw;

	    dw = WaitForSingleObject(hdl, milliseconds);
	}
    }

    /**
     * The state of a thread.
     */
    enum TS
    {
	INITIAL,	/// The thread hasn't been started yet.
	RUNNING,	/// The thread is running or paused.
	TERMINATED	/// The thread has ended.
    }

    /**
     * Returns the state of a thread.
     */
    TS getState()
    {
	return state;
    }

    /**
     * The priority of a thread.
     */
    enum PRIORITY
    {
	INCREASE,	/// Increase thread priority
	DECREASE,	/// Decrease thread priority
	IDLE,		/// Assign thread low priority
	CRITICAL	/// Assign thread high priority
    }

    /**
     * Adjust the priority of this thread.
     * Throws: ThreadError if cannot set priority
     */
    void setPriority(PRIORITY p)
    {
	int nPriority;

	switch (p)
	{
	    case PRIORITY.INCREASE:
		nPriority = THREAD_PRIORITY_ABOVE_NORMAL;
		break;
	    case PRIORITY.DECREASE:
		nPriority = THREAD_PRIORITY_BELOW_NORMAL;
		break;
	    case PRIORITY.IDLE:
		nPriority = THREAD_PRIORITY_IDLE;
		break;
	    case PRIORITY.CRITICAL:
		nPriority = THREAD_PRIORITY_TIME_CRITICAL;
		break;
	    default:
		assert(0);
	}

	if (SetThreadPriority(hdl, nPriority) == THREAD_PRIORITY_ERROR_RETURN)
	    error("set priority");
    }

    /**
     * Returns true if this thread is the current thread.
     */
    bool isSelf()
    {
	//printf("id = %d, self = %d\n", id, pthread_self());
	return (id == GetCurrentThreadId());
    }

    /**
     * Returns a reference to the Thread for the thread that called the
     * function.
     */
    static Thread getThis()
    {
	thread_id id;
	Thread result;

	//printf("getThis(), allThreadsDim = %d\n", allThreadsDim);
	synchronized (threadLock)
	{
	    id = GetCurrentThreadId();
	    for (int i = 0; i < allThreadsDim; i++)
	    {
		Thread t = allThreads[i];
		if (t && id == t.id)
		{
		    return t;
		}
	    }
	}
	printf("didn't find it\n");
	assert(result);
	return result;
    }

    /**
     * Returns an array of all the threads currently running.
     */
    static Thread[] getAll()
    {
	return allThreads[0 .. allThreadsDim];
    }

    /**
     * Suspend execution of this thread.
     */
    void pause()
    {
	if (state != TS.RUNNING || SuspendThread(hdl) == 0xFFFFFFFF)
	    error("cannot pause");
    }

    /**
     * Resume execution of this thread.
     */
    void resume()
    {
	if (state != TS.RUNNING || ResumeThread(hdl) == 0xFFFFFFFF)
	    error("cannot resume");
    }

    /**
     * Suspend execution of all threads but this thread.
     */
    static void pauseAll()
    {
	if (nthreads > 1)
	{
	    Thread tthis = getThis();

	    for (int i = 0; i < allThreadsDim; i++)
	    {   Thread t;

		t = allThreads[i];
		if (t && t !is tthis && t.state == TS.RUNNING)
		    t.pause();
	    }
	}
    }

    /**
     * Resume execution of all paused threads.
     */
    static void resumeAll()
    {
	if (nthreads > 1)
	{
	    Thread tthis = getThis();

	    for (int i = 0; i < allThreadsDim; i++)
	    {   Thread t;

		t = allThreads[i];
		if (t && t !is tthis && t.state == TS.RUNNING)
		    t.resume();
	    }
	}
    }

    /**
     * Give up the remainder of this thread's time slice.
     */
    static void yield()
    {
	Sleep(0);
    }

    /**
     *
     */
    static uint nthreads = 1;

  private:

    static uint allThreadsDim;
    static Object threadLock;
    static Thread[0x400] allThreads;	// length matches value in C runtime

    TS state;
    int idx = -1;			// index into allThreads[]
    thread_id id;
    size_t stacksize = 0;

    int (*fp)(void *);
    void *arg;

    int delegate() dg;

    void error(char[] msg)
    {
	throw new ThreadError(msg);
    }


    /* ***********************************************
     * This is just a wrapper to interface between C rtl and Thread.run().
     */

    extern (Windows) static uint threadstart(void *p)
    {
	Thread t = cast(Thread)p;
	int result;

	debug (thread) printf("Starting thread %d\n", t.idx);
	t.stackBottom = os_query_stackBottom();
	try
	{
	    result = t.run();
	}
	catch (Object o)
	{
	    printf("Error: ");
	    o.print();
	    result = 1;
	}

	debug (thread) printf("Ending thread %d\n", t.idx);
	t.state = TS.TERMINATED;
	allThreads[t.idx] = null;
	t.idx = -1;
	nthreads--;
	return result;
    }


    /**************************************
     * Create a Thread for global main().
     */

    public static void thread_init()
    {
	threadLock = new Object();

	Thread t = new Thread();

	t.state = TS.RUNNING;
	t.id = GetCurrentThreadId();
	t.hdl = Thread.getCurrentThreadHandle();
	t.stackBottom = os_query_stackBottom();

	assert(!allThreads[0]);
	allThreads[0] = t;
	allThreadsDim = 1;
	t.idx = 0;
    }

    static ~this()
    {
	if (allThreadsDim)
	{
	    version (GNU) { /* unresolved issue: this CloseHandle call causes crashes later... */ } else
	    CloseHandle(allThreads[0].hdl);
	    allThreads[0].hdl = GetCurrentThread();
	}
    }
          
    /********************************************
     * Returns the handle of the current thread.
     * This is needed because GetCurrentThread() always returns -2 which
     * is a pseudo-handle representing the current thread.
     * The returned thread handle is a windows resource and must be explicitly
     * closed.
     * Many thanks to Justin (jhenzie@mac.com) for figuring this out
     * and providing the fix.
     */
    static thread_hdl getCurrentThreadHandle()
    {
	thread_hdl currentThread = GetCurrentThread();
	thread_hdl actualThreadHandle;

	//thread_hdl currentProcess = cast(thread_hdl)-1;
	thread_hdl currentProcess = GetCurrentProcess(); // http://www.digitalmars.com/drn-bin/wwwnews?D/21217


	uint access = cast(uint)0x00000002;

	DuplicateHandle(currentProcess, currentThread, currentProcess,
			 &actualThreadHandle, cast(uint)0, TRUE, access);

	return actualThreadHandle;
     }
}


/**********************************************
 * Determine "bottom" of stack (actually the top on Win32 systems).
 */

void *os_query_stackBottom()
{
    asm
    {
	naked			;
	mov	EAX,FS:4	;
	ret			;
    }
}

}

/* ================================ GCC ================================= */

else version (Unix)
{

private import std.c.unix.unix;
private import gcc.builtins;

version (skyos)
{
    private import std.c.skyos.skyos;
    private import std.c.skyos.compat;
    alias std.c.skyos.compat.pthread_create pthread_create;
    alias std.c.skyos.compat.pthread_join pthread_join;
    alias std.c.skyos.compat.pthread_self pthread_self;
    alias std.c.skyos.compat.pthread_kill pthread_kill;
    alias std.c.skyos.compat.pthread_equal pthread_equal;
    alias std.c.skyos.compat.sched_yield sched_yield;
}

version (GNU_pthread_suspend)
{
    // nothing
}
else
{
    private import gcc.threadsem;
}

private extern (C) void* _d_gcc_query_stack_origin();


class ThreadError : Error
{
    this(char[] s)
    {
	super("Thread error: " ~ s);
    }
}

class Thread
{
    // The optional stacksize parameter default value of 0 will cause threads
    //  to be created with the default pthread size - Dave Fladebo
    this(size_t stacksize = 0)
    {
	init(stacksize);
    }

    this(int (*fp)(void *), void *arg, size_t stacksize = 0)
    {
	this.fp = fp;
	this.arg = arg;
	init(stacksize);
    }

    this(int delegate() dg, size_t stacksize = 0)
    {
	this.dg = dg;
	init(stacksize);
    }

    ~this()
    {
	pthread_cond_destroy(&waitCond);
	pthread_mutex_destroy(&waitMtx);
    }

    pthread_t id;
    void* stackBottom;
    void* stackTop;

    void start()
    {
	if (state != TS.INITIAL)
	    error("already started");

	synchronized (threadLock)
	{
	    for (int i = 0; 1; i++)
	    {
		if (i == allThreads.length)
		    error("too many threads");
		if (!allThreads[i])
		{   allThreads[i] = this;
		    idx = i;
		    if (i >= allThreadsDim)
			allThreadsDim = i + 1;
		    break;
		}
	    }
	    nthreads++;

	    state = TS.RUNNING;
	    int result;
	    //printf("creating thread x%x\n", this);
	    //result = pthread_create(&id, null, &threadstart, this);
	    // Create with thread attributes to allow non-default stack size - Dave Fladebo
	    result = pthread_create(&id, &threadAttrs, &threadstart, cast(void*)this);
	    if (result)
	    {   state = TS.TERMINATED;
		allThreads[idx] = null;
		idx = -1;
		error("failed to start");	// BUG: should report errno
	    }
	} // %% changed end of sync region
	//printf("t = x%x, id = %d\n", this, id);
    }

    int run()
    {
	if (fp)
	    return fp(arg);
	else if (dg)
	    return dg();
	assert(0);
    }

    void wait()
    {
	if (this is getThis())
	    error("wait on self");

	/* Sean Kelly writes:
	 * Change to:
	 *   if (state != TS.INITIAL)
	 * Because it is not only legal to call pthread_join on a thread that
	 * has run and finished, but calling pthread_join or pthread_detach is
	 * required for the thread resources to be released.  However, it is
	 * illegal to call pthread_join more than once, and I believe it is also
	 * illegal to detach a thread that has already been joined, so 'id'
	 * should probably be cleared after join/detach is called, and this
	 * value tested along with 'state' before performing thread ops.
	 */
	if (state == TS.RUNNING)
	{   int result;
	    void *value;

	    result = pthread_join(id, &value);
	    if (result)
		error("failed to wait");
	}
    }

    void wait(uint milliseconds)
    {
	// Implemented for POSIX systems by Dave Fladebo
	if (this is getThis())
	    error("wait on self");
	if (state == TS.RUNNING)
	{
	    timespec ts; 
	    timeval  tv;

	    alias typeof(tv.tv_sec) __time_t;

	    pthread_mutex_lock(&waitMtx);
	    gettimeofday(&tv, null);
	    ts.tv_sec = cast(__time_t)tv.tv_sec + cast(__time_t)(milliseconds / 1_000);
	    ts.tv_nsec = (tv.tv_usec * 1_000) + ((milliseconds % 1_000) * 1_000_000);
	    if (ts.tv_nsec > 1_000_000_000)
	    {
		ts.tv_sec += 1;
		ts.tv_nsec -= 1_000_000_000;
	    }
	    if (pthread_cond_timedwait(&waitCond, &waitMtx, &ts))
	    {
		int oldstate, oldtype;
		pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, &oldstate);
		pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS, &oldtype);

		if (pthread_cancel(id))     // thread was not completed in the timeout period, cancel it
		{
		    pthread_mutex_unlock(&waitMtx);
		    error("cannot terminate thread via timed wait");
		}

		pthread_setcancelstate(oldstate, null);
		pthread_setcanceltype(oldtype, null);

		state = TS.TERMINATED;
		allThreads[idx] = null;
		idx = -1;
		nthreads--;

		pthread_mutex_unlock(&waitMtx);
	    }
	    else
	    {
		pthread_mutex_unlock(&waitMtx);
		wait();	// condition has been signalled as complete (see threadstart()), terminate normally
	    }
	}
    }

    enum TS
    {
	INITIAL,
	RUNNING,
	TERMINATED
    }

    TS getState()
    {
	return state;
    }

    enum PRIORITY
    {
	INCREASE,
	DECREASE,
	IDLE,
	CRITICAL
    }

    void setPriority(PRIORITY p)
    {
	/+ not implemented
	int nPriority;

	switch (p)
	{
	    case PRIORITY.INCREASE:
		nPriority = THREAD_PRIORITY_ABOVE_NORMAL;
		break;
	    case PRIORITY.DECREASE:
		nPriority = THREAD_PRIORITY_BELOW_NORMAL;
		break;
	    case PRIORITY.IDLE:
		nPriority = THREAD_PRIORITY_IDLE;
		break;
	    case PRIORITY.CRITICAL:
		nPriority = THREAD_PRIORITY_TIME_CRITICAL;
		break;
	}

	if (SetThreadPriority(hdl, nPriority) == THREAD_PRIORITY_ERROR_RETURN)
	    error("set priority");
	+/
    }

    int isSelf()
    {
	//printf("id = %d, self = %d\n", id, pthread_self());
	return pthread_equal(pthread_self(), id);
    }

    static Thread getThis()
    {
	pthread_t id;
	Thread result;

	//printf("getThis(), allThreadsDim = %d\n", allThreadsDim);
	//synchronized (threadLock)
	{
	    id = pthread_self();
	    //printf("id = %d\n", id);
	    for (int i = 0; i < allThreadsDim; i++)
	    {
		Thread t = allThreads[i];
		//printf("allThreads[%d] = x%x, id = %d\n", i, t, (t ? t.id : 0));
		if (t && pthread_equal(id, t.id))
		{
		    return t;
		}
	    }
	}
	printf("didn't find it\n");
	assert(result);
	return result;
    }

    static Thread[] getAll()
    {
	return allThreads[0 .. allThreadsDim];
    }

    void pause()
    {
	if (state == TS.RUNNING)
	{   
	    version (GNU_pthread_suspend)
	    {
		if (pthread_suspend_np(id) != 0)
		    error("cannot pause");
	    }
	    else
	    {   int result;

		result = pthread_kill(id, SIGUSR1);
		if (result)
		    error("cannot pause");
		else
		    flagSuspend.wait();	// wait for acknowledgement
	    }
	}
	else
	    error("cannot pause");
    }

    void resume()
    {
	if (state == TS.RUNNING)
	{
	    version (GNU_pthread_suspend)
	    {
		if (pthread_continue_np(id) != 0)
		    error("cannot pause");
	    }
	    else
	    {   int result;

		result = pthread_kill(id, SIGUSR2);
		if (result)
		    error("cannot resume");
	    }
	}
	else
	    error("cannot resume");
    }

    static void pauseAll()
    {
	version (GNU_pthread_suspend)
	{
	    if (nthreads > 1)
	    {
		Thread tthis = getThis();

		synchronized (threadLock)
		{
		    
		for (int i = 0; i < allThreadsDim; i++)
		{   Thread t;

		    t = allThreads[i];
		    if (t && t !is tthis && t.state == TS.RUNNING)
			t.pause();
		}

		}
	    }
	}
	else
	{
	
	if (nthreads > 1)
	{
	    Thread tthis = getThis();
	    int npause = 0;

	    synchronized (threadLock)
	    {
		
	    for (int i = 0; i < allThreadsDim; i++)
	    {   Thread t;

		t = allThreads[i];
		if (t && t !is tthis && t.state == TS.RUNNING)
		{   int result;

		    result = pthread_kill(t.id, SIGUSR1);
		    if (result)
			getThis().error("cannot pause");
		    else
			npause++;	// count of paused threads
		}
	    }

	    }
	    
	    // Wait for each paused thread to acknowledge
	    while (npause--)
	    {
		flagSuspend.wait();
	    }
	}

	}
    }

    static void resumeAll()
    {
	if (nthreads > 1)
	{
	    Thread tthis = getThis();

	    for (int i = 0; i < allThreadsDim; i++)
	    {   Thread t;

		t = allThreads[i];
		if (t && t !is tthis && t.state == TS.RUNNING)
		    t.resume();
	    }
	}
    }

    static void yield()
    {
	sched_yield();
    }

    static uint nthreads = 1;

  private:

    static uint allThreadsDim;
    static Object threadLock;
 
    // Set max to Windows equivalent for compatibility.
    // pthread_create will fail gracefully if stack limit
    // is reached prior to allThreads max.
    static Thread[0x400] allThreads;
 
    version (GNU_pthread_suspend)
    {
	// nothing
    }
    else
    {
	static Semaphore flagSuspend;
    }

    TS state;
    int idx = -1;			// index into allThreads[]
    int flags = 0;

    pthread_attr_t threadAttrs;
    pthread_mutex_t waitMtx;
    pthread_cond_t waitCond;

    int (*fp)(void *);
    void *arg;

    int delegate() dg;

    void error(char[] msg)
    {
	throw new ThreadError(msg);
    }

    void init(size_t stackSize)
    {
	// set to default values regardless
	// passing this as the 2nd arg. for pthread_create()
	// w/o setting an attribute is equivalent to passing null.
	pthread_attr_init(&threadAttrs);
	if (stackSize > 0)
	{
	    if (pthread_attr_setstacksize(&threadAttrs,stackSize))
		error("cannot set stack size");
	}

	if (pthread_mutex_init(&waitMtx, null))
	    error("cannot initialize wait mutex");

	if (pthread_cond_init(&waitCond, null))
	    error("cannot initialize wait condition");
    }

    /************************************************
     * This is just a wrapper to interface between C rtl and Thread.run().
     */

    extern (C) static void *threadstart(void *p)
    {
	Thread t = cast(Thread)p;
	int result;

	debug (thread) printf("Starting thread x%x (%d)\n", t, t.idx);

	// Need to set t.id here, because thread is off and running
	// before pthread_create() sets it.
	t.id = pthread_self();

	version(skyos)
	    installSignalHandlers();

	t.stackBottom = getESP();
	try
	{
	    if(t.state == TS.RUNNING)
		pthread_cond_signal(&t.waitCond);     // signal the wait condition (see the timed wait function)
	    result = t.run();
	}
	catch (Object o)
	{
	    printf("Error: ");
	    o.print();
	    result = 1;
	}

	debug (thread) printf("Ending thread %d\n", t.idx);
	synchronized (threadLock)
	{
	    t.state = TS.TERMINATED;
	    allThreads[t.idx] = null;
	    t.idx = -1;
	    nthreads--;
	}
	return cast(void*)result;
    }


    /**************************************
     * Create a Thread for global main().
     */

    public static void thread_init()
    {
	threadLock = new Object();

	Thread t = new Thread();

	t.state = TS.RUNNING;
	t.id = pthread_self();
	t.stackBottom = cast(void*) _d_gcc_query_stack_origin();

	assert(!allThreads[0]);
	allThreads[0] = t;
	allThreadsDim = 1;
	t.idx = 0;

	version (GNU_pthread_suspend)
	{
	    // nothing
	}
	else
	{
	    /* Install signal handlers so we can suspend/resume threads
	     */
	    installSignalHandlers();
	}

	return;

    }

    version (GNU_pthread_suspend)
    {
	// nothing
    }
    else
    {
    
	private static void installSignalHandlers()
	{
	    int result;
	    sigaction_t sigact;
	    result = sigfillset(&sigact.sa_mask);
	    if (result)
		goto Lfail;
	    sigact.sa_handler = &pauseHandler;
	    result = sigaction(SIGUSR1, &sigact, null);
	    if (result)
		goto Lfail;
	    sigact.sa_handler = &resumeHandler;
	    result = sigaction(SIGUSR2, &sigact, null);
	    if (result)
		goto Lfail;

	    if (! flagSuspend.create())
		goto Lfail;

	    return;
	    Lfail:
	    getThis().error("cannot initialize threads");
	}

	
	/**********************************
	 * This gets called when a thread gets SIGUSR1.
	 */

	extern (C) static void pauseHandler(int sig)
	{	int result;

	    // Save all registers on the stack so they'll be scanned by the GC
	    __builtin_unwind_init();


	    assert(sig == SIGUSR1);

	    sigset_t sigmask;
	    result = sigfillset(&sigmask);
	    assert(result == 0);
	    result = sigdelset(&sigmask, SIGUSR2);
	    assert(result == 0);

	    Thread t = getThis();
	    t.stackTop = getESP();
	    t.flags &= ~1;
	    flagSuspend.signal();
	    while (1)
	    {
		sigsuspend(&sigmask);	// suspend until SIGUSR2
		if (t.flags & 1)		// ensure it was resumeHandler()
		    break;
	    }
	}

	/**********************************
	 * This gets called when a thread gets SIGUSR2.
	 */

	extern (C) static void resumeHandler(int sig)
	{
	    Thread t = getThis();

	    t.flags |= 1;
	}
    }

    public static void* getESP()
    {
	// TODO add builtin for using stack_pointer_rtx
	int dummy;
	void * p = & dummy + 1; // +1 doesn't help much; also assume stack grows down
	p = cast(void*)( (cast(size_t) p) & ~(size_t.sizeof - 1));
	return p;
    }
}


}

else version (NoSystem)
{
    class Thread {
	private this() { }
	static Thread getThis() { return _instance; }
	static Thread[] getAll() { return null; }
	bool isSelf() { return this is _instance; }
	void pause() { }
	void resume() { }
	static void pauseAll() { }
	static void resumeAll() { }
	static void yield() { }
	static void thread_init() { _instance = new Thread; }
	
	private static Thread _instance;
	static uint nthreads = 1;

	void* stackBottom;
	void* stackTop;
	enum TS
	{
	    INITIAL,
	    RUNNING,
	    TERMINATED
	}
    
	TS getState()
	{
	    return TS.RUNNING;
	}

	public static void* getESP()
	{
	    // TODO add builtin for using stack_pointer_rtx
	    int dummy;
	    void * p = & dummy + 1; // +1 doesn't help much; also assume stack grows down
	    p = cast(void*)( (cast(size_t) p) & ~(size_t.sizeof - 1));
	    return p;
	}
    }
}
else
{
    static assert(0);
}
