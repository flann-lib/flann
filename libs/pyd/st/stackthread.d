/******************************************************
 * StackThreads are userland, cooperative, lightweight
 * threads. StackThreads are very efficient, requiring
 * much less time per context switch than real threads.
 * They also require far fewer resources than real
 * threads, which allows many more StackThreads to exist
 * simultaneously. In addition, StackThreads do not
 * require explicit synchronization since they are
 * non-preemptive.  There is no requirement that code
 * be reentrant.
 *
 * This module implements the stack thread system on top
 * of the context layer.
 *
 * Version: 0.3
 * Date: July 4, 2006
 * Authors:
 *  Mikola Lysenko, mclysenk@mtu.edu
 * License: Use/copy/modify freely, just give credit.
 * Copyright: Public domain.
 *
 * Bugs:
 *  Not thread safe.  May be changed in future versions,
 *  however this will require a radical refactoring.
 *
 * History:
 *  v0.7 - Switched timing resolution to milliseconds.
 *
 *	v0.6 - Removed timing functions from st_yield/st_throwYield
 *
 *  v0.5 - Addded st_throwYield and MAX/MIN_THREAD_PRIORITY
 *
 *  v0.4 - Unittests finished-ready for an initial release.
 *
 *  v0.3 - Changed name back to StackThread and added
 *      linux support.  Context switching is now handled
 *      in the stackcontext module, and much simpler to
 *      port.
 *
 *  v0.2 - Changed name to QThread, fixed many issues.
 *  
 *  v0.1 - Initial stack thread system. Very buggy.
 *
 ******************************************************/
module st.stackthread;

//Module imports
private import
    st.stackcontext,
    std.stdio,
    std.string;

/// The priority of a stack thread determines its order in
/// the scheduler.  Higher priority threads go first.
alias int priority_t;

/// The default priority for a stack thread is 0.
const priority_t DEFAULT_STACKTHREAD_PRIORITY = 0;

/// Maximum thread priority
const priority_t MAX_STACKTHREAD_PRIORITY = 0x7fffffff;

/// Minimum thread priority
const priority_t MIN_STACKTHREAD_PRIORITY = 0x80000000;

/// The state of a stack thread
enum THREAD_STATE
{
    READY,      /// Thread is ready to run
    RUNNING,    /// Thread is currently running
    DEAD,       /// Thread has terminated
    SUSPENDED,  /// Thread is suspended
}

/// The state of the scheduler
enum SCHEDULER_STATE
{
    READY,      /// Scheduler is ready to run a thread
    RUNNING,    /// Scheduler is running a timeslice
}

//Timeslices
private STPriorityQueue active_slice;
private STPriorityQueue next_slice;

//Scheduler state
private SCHEDULER_STATE sched_state;
    
//Start time of the time slice
private ulong sched_t0;

//Currently active stack thread
private StackThread sched_st;

version(Win32)
{
    private extern(Windows) int QueryPerformanceFrequency(ulong *);
    private ulong sched_perf_freq;
}


//Initialize the scheduler
static this()
{
    active_slice = new STPriorityQueue();
    next_slice = new STPriorityQueue();
    sched_state = SCHEDULER_STATE.READY;
    sched_t0 = -1;
    sched_st = null;
    
    version(Win32)
        QueryPerformanceFrequency(&sched_perf_freq);
}


/******************************************************
 * StackThreadExceptions are generated whenever the
 * stack threads are incorrectly invoked.  Trying to
 * run a time slice while a time slice is in progress
 * will result in a StackThreadException.
 ******************************************************/
class StackThreadException : Exception
{
    this(char[] msg)
    {
        super(msg);
    }
    
    this(StackThread st, char[] msg)
    {
        super(format("%s: %s", st.toString, msg));
    }
}



/******************************************************
 * StackThreads are much like regular threads except
 * they are cooperatively scheduled.  A user may switch
 * between StackThreads using st_yield.
 ******************************************************/
class StackThread
{
    /**
     * Creates a new stack thread and adds it to the
     * scheduler.
     *
     * Params:
     *  dg = The delegate we are invoking
     *  stack_size = The size of the stack for the stack
     *  thread.
     *  priority = The priority of the stack thread.
     */
    public this
    (
        void delegate() dg, 
        priority_t priority = DEFAULT_STACKTHREAD_PRIORITY,
        size_t stack_size = DEFAULT_STACK_SIZE
    )
    {
        this.m_delegate = dg;
        this.context = new StackContext(&m_proc, DEFAULT_STACK_SIZE);
        this.m_priority = priority;
        
        //Schedule the thread
        st_schedule(this);
        
        debug (StackThread) writefln("Created thread, %s", toString);
    }
    
    /**
     * Creates a new stack thread and adds it to the
     * scheduler, using a function pointer.
     *
     * Params:
     *  fn = The function pointer that the stack thread
     *  invokes.
     *  stack_size = The size of the stack for the stack
     *  thread.
     *  priority = The priority of the stack thread.
     */
    public this
    (
        void function() fn, 
        priority_t priority = DEFAULT_STACKTHREAD_PRIORITY,
        size_t stack_size = DEFAULT_STACK_SIZE
    )
    {
        this.m_delegate = &delegator;
        this.m_function = fn;
        this.context = new StackContext(&m_proc, DEFAULT_STACK_SIZE);
        this.m_priority = priority;
        
        //Schedule the thread
        st_schedule(this);
        
        debug (StackThread) writefln("Created thread, %s", toString);
    }
    
    /**
     * Converts the thread to a string.
     *
     * Returns: A string representing the stack thread.
     */
    public char[] toString()
    {
        debug(PQueue)
        {
            return format("ST[t:%8x,p:%8x,l:%8x,r:%8x]",
                cast(void*)this,
                cast(void*)parent,
                cast(void*)left,
                cast(void*)right);
        }
        else
        {
        static char[][] state_names =
        [
            "RDY",
            "RUN",
            "XXX",
            "PAU",
        ];
        
        //horrid hack for getting the address of a delegate
        union hack
        {
            struct dele
            {
                void * frame;
                void * fptr;
            }
            
            dele d;
            void delegate () dg;
        }
        hack h;
        if(m_function !is null)
            h.d.fptr = cast(void*) m_function;
        else if(m_delegate !is null)
            h.dg = m_delegate;
        else
            h.dg = &run;
        
        return format(
            "Thread[pr=%d,st=%s,fn=%8x]", 
            priority,
            state_names[cast(uint)state],
            h.d.fptr);
        }
    }
    
    invariant
    {
        assert(context);
        
        switch(state)
        {
            case THREAD_STATE.READY:
                assert(context.ready);
            break;
            
            case THREAD_STATE.RUNNING:
                assert(context.running);
            break;
            
            case THREAD_STATE.DEAD:
                assert(!context.running);
            break;
            
            case THREAD_STATE.SUSPENDED:
                assert(context.ready);
            break;

			default: assert(false);
        }
        
        if(left !is null)
        {
            assert(left.parent is this);
        }
        
        if(right !is null)
        {
            assert(right.parent is this);
        }
    }
    
    /**
     * Removes this stack thread from the scheduler. The
     * thread will not be run until it is added back to
     * the scheduler.
     */
    public final void pause()
    {
        debug (StackThread) writefln("Pausing %s", toString);
        
        switch(state)
        {
            case THREAD_STATE.READY:
                st_deschedule(this);
                state = THREAD_STATE.SUSPENDED;
            break;
            
            case THREAD_STATE.RUNNING:
                transition(THREAD_STATE.SUSPENDED);
            break;
            
            case THREAD_STATE.DEAD:
                throw new StackThreadException(this, "Cannot pause a dead thread");
            
            case THREAD_STATE.SUSPENDED:
                throw new StackThreadException(this, "Cannot pause a paused thread");

			default: assert(false);
        }
    }
    
    /**
     * Adds the stack thread back to the scheduler. It
     * will resume running with its priority & state
     * intact.
     */
    public final void resume()
    {
        debug (StackThread) writefln("Resuming %s", toString);
        
        //Can only resume paused threads
        if(state != THREAD_STATE.SUSPENDED)
        {
            throw new StackThreadException(this, "Thread is not suspended");
        }
        
        //Set state to ready and schedule
        state = THREAD_STATE.READY;
        st_schedule(this);
    }
    
    /**
     * Kills this stack thread in a violent manner.  The
     * thread does not get a chance to end itself or clean
     * anything up, it is descheduled and all GC references
     * are released.
     */
    public final void kill()
    {
        debug (StackThread) writefln("Killing %s", toString);
        
        switch(state)
        {
            case THREAD_STATE.READY:
                //Kill thread and remove from scheduler
                st_deschedule(this);
                state = THREAD_STATE.DEAD;
                context.kill();
            break;
            
            case THREAD_STATE.RUNNING:
                //Transition to dead
                transition(THREAD_STATE.DEAD);
            break;
            
            case THREAD_STATE.DEAD:
                throw new StackThreadException(this, "Cannot kill already dead threads");
            
            case THREAD_STATE.SUSPENDED:
                //We need to kill the stack, no need to touch scheduler
                state = THREAD_STATE.DEAD;
                context.kill();
            break;

			default: assert(false);
        }
    }
    
    /**
     * Waits to join with this thread.  If the given amount
     * of milliseconds expires before the thread is dead,
     * then we return automatically.
     *
     * Params:
     *  ms = The maximum amount of time the thread is 
     *  allowed to wait. The special value -1 implies that
     *  the join will wait indefinitely.
     *
     * Returns:
     *  The amount of millieconds the thread was actually
     *  waiting.
     */
    public final ulong join(ulong ms = -1)
    {
        debug (StackThread) writefln("Joining %s", toString);
        
        //Make sure we are in a timeslice
        if(sched_state != SCHEDULER_STATE.RUNNING)
        {
            throw new StackThreadException(this, "Cannot join unless a timeslice is currently in progress");
        }
        
        //And make sure we are joining with a valid thread
        switch(state)
        {
            case THREAD_STATE.READY:
                break;
            
            case THREAD_STATE.RUNNING:
                throw new StackThreadException(this, "A thread cannot join with itself!");
            
            case THREAD_STATE.DEAD:
                throw new StackThreadException(this, "Cannot join with a dead thread");
            
            case THREAD_STATE.SUSPENDED:
                throw new StackThreadException(this, "Cannot join with a paused thread");

			default: assert(false);
        }
        
        //Do busy waiting until the thread dies or the
        //timer runs out.
        ulong start_time = getSysMillis();
        ulong timeout = (ms == -1) ? ms : start_time + ms;
        
        while(
            state != THREAD_STATE.DEAD &&
            timeout > getSysMillis())
        {
            StackContext.yield();
        }
        
        return getSysMillis() - start_time;
    }
    
    /**
     * Restarts the thread's execution from the very
     * beginning.  Suspended and dead threads are not
     * resumed, but upon resuming, they will restart.
     */
    public final void restart()
    {
        debug (StackThread) writefln("Restarting %s", toString);
        
        //Each state needs to be handled carefully
        switch(state)
        {
            case THREAD_STATE.READY:
                //If we are ready,
                context.restart();
            break;
            
            case THREAD_STATE.RUNNING:
                //Reset the thread.
                transition(THREAD_STATE.READY);
            break;
            
            case THREAD_STATE.DEAD:
                //Dead threads become suspended
                context.restart();
                state = THREAD_STATE.SUSPENDED;
            break;
            
            case THREAD_STATE.SUSPENDED:
                //Suspended threads stay suspended
                context.restart();
            break;

			default: assert(false);
        }
    }
    
    /**
     * Grabs the thread's priority.  Intended for use
     * as a property.
     *
     * Returns: The stack thread's priority.
     */
    public final priority_t priority()
    {
        return m_priority;
    }
    
    /**
     * Sets the stack thread's priority.  Used to either
     * reschedule or reset the thread.  Changes do not
     * take effect until the next round of scheduling.
     *
     * Params:
     *  p = The new priority for the thread
     *
     * Returns:
     *  The new priority for the thread.
     */
    public final priority_t priority(priority_t p)
    {
        //Update priority
        if(sched_state == SCHEDULER_STATE.READY && 
            state == THREAD_STATE.READY)
        {
            next_slice.remove(this);
            m_priority = p;
            next_slice.add(this);
        }
        
        return m_priority = p;
    }
    
    /**
     * Returns: The state of this thread.
     */
    public final THREAD_STATE getState()
    {
        return state;
    }
    
    /**
     * Returns: True if the thread is ready to run.
     */
    public final bool ready()
    {
        return state == THREAD_STATE.READY;
    }
    
    /**
     * Returns: True if the thread is currently running.
     */
    public final bool running()
    {
        return state == THREAD_STATE.RUNNING;
    }
    
    /**
     * Returns: True if the thread is dead.
     */
    public final bool dead()
    {
        return state == THREAD_STATE.DEAD;
    }
    
    /**
     * Returns: True if the thread is not dead.
     */
    public final bool alive()
    {
        return state != THREAD_STATE.DEAD;
    }
    
    /**
     * Returns: True if the thread is paused.
     */
    public final bool paused()
    {
        return state == THREAD_STATE.SUSPENDED;
    }

    /**
     * Creates a stack thread without a function pointer
     * or delegate.  Used when a user overrides the stack
     * thread class.
     */
    protected this
    (
        priority_t priority = DEFAULT_STACKTHREAD_PRIORITY,
        size_t stack_size = DEFAULT_STACK_SIZE
    )
    {
        this.context = new StackContext(&m_proc, stack_size);
        this.m_priority = priority;
        
        //Schedule the thread
        st_schedule(this);
        
        debug (StackThread) writefln("Created thread, %s", toString);
    }
    
    /**
     * Run the stack thread.  This method may be overloaded
     * by classes which inherit from stack thread, as an
     * alternative to passing delegates.
     *
     * Throws: Anything.
     */
    protected void run()
    {
        m_delegate();
    }
    
    // Heap information
    private StackThread parent = null;
    private StackThread left = null;
    private StackThread right = null;

    // The thread's priority
    private priority_t m_priority;

    // The state of the thread
    private THREAD_STATE state;

    // The thread's context
    private StackContext context;

    //Delegate handler
    private void function() m_function;
    private void delegate() m_delegate;
    private void delegator() { m_function(); }
    
    //My procedure
    private final void m_proc()
    {
        try
        {
            debug (StackThread) writefln("Starting %s", toString);
            run;
        }
        catch(Object o)
        {
            debug (StackThread) writefln("Got a %s exception from %s", o.toString, toString);
            throw o;
        }
        finally
        {
            debug (StackThread) writefln("Finished %s", toString);
            state = THREAD_STATE.DEAD;
        }
    }

    /**
     * Used to change the state of a running thread
     * gracefully
     */
    private final void transition(THREAD_STATE next_state)
    {
        state = next_state;
        StackContext.yield();
    }
}



/******************************************************
 * The STPriorityQueue is used by the scheduler to
 * order the objects in the stack threads.  For the
 * moment, the implementation is binary heap, but future
 * versions might use a binomial heap for performance
 * improvements.
 ******************************************************/
private class STPriorityQueue
{
public:
    
    /**
     * Add a stack thread to the queue.
     *
     * Params:
     *  st = The thread we are adding.
     */
    void add(StackThread st)
    in
    {
        assert(st !is null);
        assert(st);
        assert(st.parent is null);
        assert(st.left is null);
        assert(st.right is null);
    }
    body
    {
        size++;
        
        //Handle trivial case
        if(head is null)
        {
            head = st;
            return;
        }
        
        //First, insert st
        StackThread tmp = head;
        int pos;
        for(pos = size; pos>3; pos>>>=1)
        {
            assert(tmp);
            tmp = (pos & 1) ? tmp.right : tmp.left;
        }
        
        assert(tmp !is null);
        assert(tmp);
        
        if(pos&1)
        {
            assert(tmp.left !is null);
            assert(tmp.right is null);
            tmp.right = st;
        }
        else
        {
            assert(tmp.left is null);
            assert(tmp.right is null);
            tmp.left = st;
        }
        st.parent = tmp;
        
        assert(tmp);
        assert(st);
        
        //Fixup the stack and we're good.
        bubble_up(st);
    }
    
    /**
     * Remove a stack thread.
     *
     * Params:
     *  st = The stack thread we are removing.
     */
    void remove(StackThread st)
    in
    {
        assert(st);
        assert(hasThread(st));
    }
    out
    {
        assert(st);
        assert(st.left is null);
        assert(st.right is null);
        assert(st.parent is null);
    }
    body
    {
        //Handle trivial case
        if(size == 1)
        {
            assert(st is head);
            
            --size;
            
            st.parent =
            st.left =
            st.right = 
            head = null;
            
            return;
        }
        
        //Cycle to the bottom of the heap
        StackThread tmp = head;
        int pos;
        for(pos = size; pos>3; pos>>>=1)
        {
            assert(tmp);
            tmp = (pos & 1) ? tmp.right : tmp.left;
        }
        tmp = (pos & 1) ? tmp.right : tmp.left;
        
        
        assert(tmp !is null);
        assert(tmp.left is null);
        assert(tmp.right is null);
        
        //Remove tmp
        if(tmp.parent.left is tmp)
        {
            tmp.parent.left = null;
        }
        else
        {
            assert(tmp.parent.right is tmp);
            tmp.parent.right = null;
        }
        tmp.parent = null;
        size--;
        
        assert(tmp);
        
        //Handle second trivial case
        if(tmp is st)
        {
            return;
        }
        
        //Replace st with tmp
        if(st is head)
        {
            head = tmp;
        }
        
        //Fix tmp's parent
        tmp.parent = st.parent;
        if(tmp.parent !is null)
        {
            if(tmp.parent.left is st)
            {
                tmp.parent.left = tmp;
            }
            else
            {
                assert(tmp.parent.right is st);
                tmp.parent.right = tmp;
            }
        }
        
        //Fix tmp's left
        tmp.left = st.left;
        if(tmp.left !is null)
        {
            tmp.left.parent = tmp;
        }
        
        //Fix tmp's right
        tmp.right = st.right;
        if(tmp.right !is null)
        {
            tmp.right.parent = tmp;
        }
        
        //Unlink st
        st.parent =
        st.left =
        st.right = null;
        
        
        //Bubble up
        bubble_up(tmp);
        //Bubble back down
        bubble_down(tmp);
        
    }
    
    /**
     * Extract the top priority thread. It is removed from
     * the queue.
     *
     * Returns: The top priority thread.
     */
    StackThread top()
    in
    {
        assert(head !is null);
    }
    out(r)
    {
        assert(r !is null);
        assert(r);
        assert(r.parent is null);
        assert(r.right is null);
        assert(r.left is null);
    }
    body
    {
        StackThread result = head;
        
        //Handle trivial case
        if(size == 1)
        {
            //Drop size and return
            --size;
            result.parent =
            result.left =
            result.right = null;
            head = null;
            return result;
        }
        
        //Cycle to the bottom of the heap
        StackThread tmp = head;
        int pos;
        for(pos = size; pos>3; pos>>>=1)
        {
            assert(tmp);
            tmp = (pos & 1) ? tmp.right : tmp.left;
        }
        tmp = (pos & 1) ? tmp.right : tmp.left;
        
        assert(tmp !is null);
        assert(tmp.left is null);
        assert(tmp.right is null);
        
        //Remove tmp
        if(tmp.parent.left is tmp)
        {
            tmp.parent.left = null;
        }
        else
        {
            assert(tmp.parent.right is tmp);
            tmp.parent.right = null;
        }
        tmp.parent = null;
        
        //Add tmp to top
        tmp.left = head.left;
        tmp.right = head.right;
        if(tmp.left !is null) tmp.left.parent = tmp;
        if(tmp.right !is null) tmp.right.parent = tmp;
        
        //Unlink head
        head.right = 
        head.left = null;
        
        //Verify results
        assert(head);
        assert(tmp);
        
        //Set the new head
        head = tmp;
        
        //Bubble down
        bubble_down(tmp);
        
        //Drop size and return
        --size;
        return result;
    }
    
    /**
     * Merges two priority queues. The result is stored
     * in this queue, while other is emptied.
     *
     * Params:
     *  other = The queue we are merging with.
     */
    void merge(STPriorityQueue other)
    {
        StackThread[] stack;
        stack ~= other.head;
        
        while(stack.length > 0)
        {
            StackThread tmp = stack[$-1];
            stack.length = stack.length - 1;
            
            if(tmp !is null)
            {
                stack ~= tmp.right;
                stack ~= tmp.left;
                
                tmp.parent = 
                tmp.right =
                tmp.left = null;
                
                add(tmp);
            }
        }
        
        //Clear the list
        other.head = null;
        other.size = 0;
    }
    
    /**
     * Returns: true if the heap actually contains the thread st.
     */
    bool hasThread(StackThread st)
    {
        StackThread tmp = st;
        while(tmp !is null)
        {
            if(tmp is head)
                return true;
            tmp = tmp.parent;
        }
        
        return false;
    }
    
    invariant
    {
        if(head !is null)
        {
            assert(head);
            assert(size > 0);
        }
    }

    //Top of the heap
    StackThread head = null;
    
    //Size of the stack
    int size;

    debug (PQueue) void print()
    {
        StackThread[] stack;
        stack ~= head;
        
        while(stack.length > 0)
        {
            StackThread tmp = stack[$-1];
            stack.length = stack.length - 1;
            
            if(tmp !is null)
            {
                writef("%s, ", tmp.m_priority);
                
                if(tmp.left !is null)
                {
                    assert(tmp.left.m_priority <= tmp.m_priority);
                    stack ~= tmp.left;
                }
                
                if(tmp.right !is null)
                {
                    assert(tmp.right.m_priority <= tmp.m_priority);
                    stack ~= tmp.right;
                }
                
            }
        }
        
        writefln("");
    }
    
    void bubble_up(StackThread st)
    {
        //Ok, now we are at the bottom, so time to bubble up
        while(st.parent !is null)
        {
            //Test for end condition
            if(st.parent.m_priority >= st.m_priority)
                return;
            
            //Otherwise, just swap
            StackThread a = st.parent, tp;
            
            assert(st);
            assert(st.parent);
            
            //writefln("%s <-> %s", a.toString, st.toString);
            
            //Switch parents
            st.parent = a.parent;
            a.parent = st;
            
            //Fixup
            if(st.parent !is null)
            {
                if(st.parent.left is a)
                {
                    st.parent.left = st;
                }
                else
                {
                    assert(st.parent.right is a);
                    st.parent.right = st;
                }
                
                assert(st.parent);
            }
            
            //Switch children
            if(a.left is st)
            {
                a.left = st.left;
                st.left = a;
                
                tp = st.right;
                st.right = a.right;
                a.right = tp;
                
                if(st.right !is null) st.right.parent = st;
            }
            else
            {
                a.right = st.right;
                st.right = a;
                
                tp = st.left;
                st.left = a.left;
                a.left = tp;
                
                if(st.left !is null) st.left.parent = st;
            }
            
            if(a.right !is null) a.right.parent = a;
            if(a.left !is null) a.left.parent = a;
            
            //writefln("%s <-> %s", a.toString, st.toString);
            
            assert(st);
            assert(a);
        }
        
        head = st;
    }
    
    //Bubbles a thread downward
    void bubble_down(StackThread st)
    {
        while(st.left !is null)
        {
            StackThread a, tp;
            
            assert(st);
            
            if(st.right is null || 
                st.left.m_priority >= st.right.m_priority)
            {
                if(st.left.m_priority > st.m_priority)
                {
                    a = st.left;
                    assert(a);
                    //writefln("Left: %s - %s", st, a);
                    
                    st.left = a.left;
                    a.left = st;
                    
                    tp = st.right;
                    st.right = a.right;
                    a.right = tp;
                    
                    if(a.right !is null) a.right.parent = a;
                } else break;
            }
            else if(st.right.m_priority > st.m_priority)
            {
                a = st.right;
                assert(a);
                //writefln("Right: %s - %s", st, a);
                
                st.right = a.right;
                a.right = st;
                
                tp = st.left;
                st.left = a.left;
                a.left = tp;
                
                if(a.left !is null) a.left.parent = a;
            }
            else break;
            
            //Fix the parent
            a.parent = st.parent;
            st.parent = a;
            if(a.parent !is null)
            {
                if(a.parent.left is st)
                {
                    a.parent.left = a;
                }
                else
                {
                    assert(a.parent.right is st);
                    a.parent.right = a;
                }
            }
            else
            {
                head = a;
            }
            
            if(st.left !is null) st.left.parent = st;
            if(st.right !is null) st.right.parent = st;
            
            assert(a);
            assert(st);
            //writefln("Done: %s - %s", st, a);            
        }
    }
}

debug (PQueue)
 unittest
{
    writefln("Testing priority queue");
    
    
    //Create some queue
    STPriorityQueue q1 = new STPriorityQueue();
    STPriorityQueue q2 = new STPriorityQueue();
    STPriorityQueue q3 = new STPriorityQueue();
    
    assert(q1);
    assert(q2);
    assert(q3);
    
    //Add some elements
    writefln("Adding elements");
    q1.add(new StackThread(1));
    q1.print();
    assert(q1);
    q1.add(new StackThread(2));
    q1.print();
    assert(q1);
    q1.add(new StackThread(3));
    q1.print();
    assert(q1);
    q1.add(new StackThread(4));
    q1.print();
    assert(q1);
    
    writefln("Removing elements");
    StackThread t;
    
    t = q1.top();
    writefln("t:%s",t.priority);
    q1.print();
    assert(t.priority == 4);
    assert(q1);
    
    t = q1.top();
    writefln("t:%s",t.priority);
    q1.print();
    assert(t.priority == 3);
    assert(q1);
    
    t = q1.top();
    writefln("t:%s",t.priority);
    q1.print();
    assert(t.priority == 2);
    assert(q1);
    
    t = q1.top();
    writefln("t:%s",t.priority);
    q1.print();
    assert(t.priority == 1);
    assert(q1);
    
    writefln("Second round of adds");
    q2.add(new StackThread(5));
    q2.add(new StackThread(4));
    q2.add(new StackThread(1));
    q2.add(new StackThread(3));
    q2.add(new StackThread(6));
    q2.add(new StackThread(2));
    q2.add(new StackThread(7));
    q2.add(new StackThread(0));
    assert(q2);
    q2.print();
    
    writefln("Testing top extraction again");
    assert(q2.top.priority == 7);
    q2.print();
    assert(q2.top.priority == 6);
    assert(q2.top.priority == 5);
    assert(q2.top.priority == 4);
    assert(q2.top.priority == 3);
    assert(q2.top.priority == 2);
    assert(q2.top.priority == 1);
    assert(q2.top.priority == 0);
    assert(q2);
    
    writefln("Third round");
    q2.add(new StackThread(10));
    q2.add(new StackThread(7));
    q2.add(new StackThread(5));
    q2.add(new StackThread(7));
    q2.print();
    assert(q2);
    
    writefln("Testing extraction");
    assert(q2.top.priority == 10);
    assert(q2.top.priority == 7);
    assert(q2.top.priority == 7);
    assert(q2.top.priority == 5);
    
    writefln("Testing merges");
    q3.add(new StackThread(10));
    q3.add(new StackThread(-10));
    q3.add(new StackThread(10));
    q3.add(new StackThread(-10));
    
    q2.add(new StackThread(-9));
    q2.add(new StackThread(9));
    q2.add(new StackThread(-9));
    q2.add(new StackThread(9));
    
    q2.print();
    q3.print();
    q3.merge(q2);
    
    writefln("q2:%d", q2.size);
    q2.print();
    writefln("q3:%d", q3.size);
    q3.print();
    assert(q2);
    assert(q3);
    assert(q2.size == 0);
    assert(q3.size == 8);
    
    writefln("Extracting merges");
    assert(q3.top.priority == 10);
    assert(q3.top.priority == 10);
    assert(q3.top.priority == 9);
    assert(q3.top.priority == 9);
    assert(q3.top.priority == -9);
    assert(q3.top.priority == -9);
    assert(q3.top.priority == -10);
    assert(q3.top.priority == -10);
    
    writefln("Testing removal");
    StackThread ta = new StackThread(5);
    StackThread tb = new StackThread(6);
    StackThread tc = new StackThread(10);
    
    q2.add(new StackThread(7));
    q2.add(new StackThread(1));
    q2.add(ta);
    q2.add(tb);
    q2.add(tc);
    
    assert(q2);
    assert(q2.size == 5);
    
    writefln("Removing");
    q2.remove(ta);
    q2.remove(tc);
    q2.remove(tb);
    assert(q2.size == 2);
    
    writefln("Dumping heap");
    assert(q2.top.priority == 7);
    assert(q2.top.priority == 1);
    
    
    writefln("Testing big add/subtract");
    StackThread[100] st;
    STPriorityQueue stq = new STPriorityQueue();
    
    for(int i=0; i<100; i++)
    {
        st[i] = new StackThread(i);
        stq.add(st[i]);
    }
    
    stq.remove(st[50]);
    stq.remove(st[10]);
    stq.remove(st[31]);
    stq.remove(st[88]);
    
    for(int i=99; i>=0; i--)
    {
        if(i != 50 && i!=10 &&i!=31 &&i!=88)
        {
            assert(stq.top.priority == i);
        }
    }
    writefln("Big add/remove worked");
    
    writefln("Priority queue passed");
}


// -------------------------------------------------
//          SCHEDULER FUNCTIONS
// -------------------------------------------------

/**
 * Grabs the number of milliseconds on the system clock.
 *
 * (Adapted from std.perf)
 *
 * Returns: The amount of milliseconds the system has been
 * up.
 */
version(Win32)
{
    private extern(Windows) int 
        QueryPerformanceCounter(ulong * cnt);
    
    private ulong getSysMillis()
    {
        ulong result;
        QueryPerformanceCounter(&result);
        
        if(result < 0x20C49BA5E353F7L)
	    {
            result = (result * 1000) / sched_perf_freq;
	    }
	    else
	    {
            result = (result / sched_perf_freq) * 1000;
	    }

        return result;
    }
}
else version(linux)
{
    extern (C)
    {
        private struct timeval
        {
            int tv_sec;
            int tv_usec;
        };
        private struct timezone
        {
            int tz_minuteswest;
            int tz_dsttime;
        };
        private void gettimeofday(timeval *tv, timezone *tz);
    }

    private ulong getSysMillis()
    {
        timeval     tv;
        timezone    tz;
        
        gettimeofday(&tv, &tz);
        
        return 
            cast(ulong)tv.tv_sec * 1000 + 
            cast(ulong)tv.tv_usec / 1000;
    }
}
else
{
    static assert(false);
}


/**
 * Schedules a thread such that it will be run in the next
 * timeslice.
 *
 * Params:
 *  st = Thread we are scheduling
 */
private void st_schedule(StackThread st)
in
{
    assert(st.state == THREAD_STATE.READY);
}
body 
{
    debug(PQueue) { return; }
    
    debug (StackThread) writefln("Scheduling %s", st.toString);
    next_slice.add(st);
}

/**
 * Removes a thread from the scheduler.
 *
 * Params:
 *  st = Thread we are removing.
 */
private void st_deschedule(StackThread st)
in
{
    assert(st.state == THREAD_STATE.READY);
}
body
{
    debug (StackThread) writefln("Descheduling %s", st.toString);
    if(active_slice.hasThread(st))
    {
        active_slice.remove(st);
    }
    else
    {
        next_slice.remove(st);
    }
}

/**
 * Runs a single timeslice.  During a timeslice each
 * currently running thread is executed once, with the
 * highest priority first.  Any number of things may
 * cause a timeslice to be aborted, inclduing;
 *
 *  o An exception is unhandled in a thread which is run
 *  o The st_abortSlice function is called
 *  o The timelimit is exceeded in st_runSlice
 *
 * If a timeslice is not finished, it will be resumed on
 * the next call to st_runSlice.  If this is undesirable,
 * calling st_resetSlice will cause the timeslice to
 * execute from the beginning again.
 *
 * Newly created threads are not run until the next
 * timeslice.
 * 
 * This works just like the regular st_runSlice, except it
 * is timed.  If the lasts longer than the specified amount
 * of nano seconds, it is immediately aborted.
 *
 * If no time quanta is specified, the timeslice runs
 * indefinitely.
 *
 * Params:
 *  ms = The number of milliseconds the timeslice is allowed
 *  to run.
 *
 * Throws: The first exception generated in the timeslice.
 *
 * Returns: The total number of milliseconds used by the
 *  timeslice.
 */
ulong st_runSlice(ulong ms = -1)
{
    
    if(sched_state != SCHEDULER_STATE.READY)
    {
        throw new StackThreadException("Cannot run a timeslice while another is already in progress!");
    }
    
    sched_t0 = getSysMillis();
    ulong stop_time = (ms == -1) ? ms : sched_t0 + ms;
    
    //Swap slices
    if(active_slice.size == 0)
    {
        STPriorityQueue tmp = next_slice;
        next_slice = active_slice;
        active_slice = tmp;
    }
    
    debug (StackThread) writefln("Running slice with %d threads", active_slice.size);
    
    sched_state = SCHEDULER_STATE.RUNNING;
    
    while(active_slice.size > 0 && 
        (getSysMillis() - sched_t0) < stop_time &&
        sched_state == SCHEDULER_STATE.RUNNING)
    {
        
        sched_st = active_slice.top();
        debug(StackThread) writefln("Starting thread: %s", sched_st);
        sched_st.state = THREAD_STATE.RUNNING;
        
        
        try
        {
            sched_st.context.run();            
        }
        catch(Object o)
        {
            //Handle exit condition on thread
            
            sched_state = SCHEDULER_STATE.READY;
            throw o;
        }
        finally
        {
            //Process any state transition
            switch(sched_st.state)
            {
                case THREAD_STATE.READY:
                    //Thread wants to be restarted
                    sched_st.context.restart();
                    next_slice.add(sched_st);
                break;
                
                case THREAD_STATE.RUNNING:
                    //Nothing unusual, pass it to next state
                    sched_st.state = THREAD_STATE.READY;
                    next_slice.add(sched_st);
                break;
                
                case THREAD_STATE.SUSPENDED:
                    //Don't reschedule
                break;
                
                case THREAD_STATE.DEAD:
                    //Kill thread's context
                    sched_st.context.kill();
                break;

				default: assert(false);
            }
            
            sched_st = null;
        }
    }
    
    sched_state = SCHEDULER_STATE.READY;
    
    return getSysMillis() - sched_t0;
}

/**
 * Aborts a currently running slice.  The thread which
 * invoked st_abortSlice will continue to run until it
 * yields normally.
 */
void st_abortSlice()
{
    debug (StackThread) writefln("Aborting slice");
    
    if(sched_state != SCHEDULER_STATE.RUNNING)
    {
        throw new StackThreadException("Cannot abort the timeslice while the scheduler is not running!");
    }
    
    sched_state = SCHEDULER_STATE.READY;
}

/**
 * Restarts the entire timeslice from the beginning.
 * This has no effect if the last timeslice was started
 * from the beginning.  If a slice is currently running,
 * then the current thread will continue to execute until
 * it yields normally.
 */
void st_resetSlice()
{
    debug (StackThread) writefln("Resetting timeslice");
    next_slice.merge(active_slice);
}

/**
 * Yields the currently executing stack thread.  This is
 * functionally equivalent to StackContext.yield, except
 * it returns the amount of time the thread was yielded.
 */
void st_yield()
{
    debug (StackThread) writefln("Yielding %s", sched_st.toString);
    
    StackContext.yield();
}

/**
 * Throws an object and yields the thread.  The exception
 * is propagated out of the st_runSlice method.
 */
void st_throwYield(Object t)
{
    debug (StackThread) writefln("Throwing %s, Yielding %s", t.toString, sched_st.toString);
    
    StackContext.throwYield(t);
}

/**
 * Causes the currently executing thread to wait for the
 * specified amount of milliseconds.  After the time
 * has passed, the thread resumes execution.
 *
 * Params:
 *  ms = The amount of milliseconds the thread will sleep.
 *
 * Returns: The number of milliseconds the thread was
 * asleep.
 */
ulong st_sleep(ulong ms)
{
    debug(StackThread) writefln("Sleeping for %d in %s", ms, sched_st.toString);
    
    ulong t0 = getSysMillis();
    
    while((getSysMillis - t0) >= ms)
        StackContext.yield();
    
    return getSysMillis() - t0;
}

/**
 * This function retrieves the number of milliseconds since
 * the start of the timeslice.
 *
 * Returns: The number of milliseconds since the start of
 * the timeslice.
 */
ulong st_time()
{
    return getSysMillis() - sched_t0;
}

/**
 * Returns: The currently running stack thread.  null if
 * a timeslice is not in progress.
 */
StackThread st_getRunning()
{
    return sched_st;
}

/**
 * Returns: The current state of the scheduler.
 */
SCHEDULER_STATE st_getState()
{
    return sched_state;
}

/**
 * Returns: True if the scheduler is running a timeslice.
 */
bool st_isRunning()
{
    return sched_state == SCHEDULER_STATE.RUNNING;
}

/**
 * Returns: The number of threads stored in the scheduler.
 */
int st_numThreads()
{
    return active_slice.size + next_slice.size;
}

/**
 * Returns: The number of threads remaining in the timeslice.
 */
int st_numSliceThreads()
{
    if(active_slice.size > 0)
        return active_slice.size;
    
    return next_slice.size;
}

debug (PQueue) {}
else
{
unittest
{
    writefln("Testing stack thread creation & basic scheduling");
    
    static int q0 = 0;
    static int q1 = 0;
    static int q2 = 0;
    
    //Run one empty slice
    st_runSlice();
    
    StackThread st0 = new StackThread(
    delegate void()
    {
        while(true)
        {
            q0++;
            st_yield();
        }
    });
    
    StackThread st1 = new StackThread(
    function void()
    {
        while(true)
        {
            q1++;
            st_yield();
        }
    });
    
    class TestThread : StackThread
    {
        this() { super(); }
        
        override void run()
        {
            while(true)
            {
                q2++;
                st_yield();
            }
        }
    }
    
    StackThread st2 = new TestThread();
    
    assert(st0);
    assert(st1);
    assert(st2);
    
    st_runSlice();
    
    assert(q0 == 1);
    assert(q1 == 1);
    assert(q2 == 1);
    
    st1.pause();
    st_runSlice();
    
    assert(st0);
    assert(st1);
    assert(st2);
    
    assert(st1.paused);
    assert(q0 == 2);
    assert(q1 == 1);
    assert(q2 == 2);
    
    st2.kill();
    st_runSlice();
    
    assert(st2.dead);
    assert(q0 == 3);
    assert(q1 == 1);
    assert(q2 == 2);
    
    st0.kill();
    st_runSlice();
    
    assert(st0.dead);
    assert(q0 == 3);
    assert(q1 == 1);
    assert(q2 == 2);
    
    st1.resume();
    st_runSlice();
    
    assert(st1.ready);
    assert(q0 == 3);
    assert(q1 == 2);
    assert(q2 == 2);
    
    st1.kill();
    st_runSlice();
    
    assert(st1.dead);
    assert(q0 == 3);
    assert(q1 == 2);
    assert(q2 == 2);
    
    
    assert(st_numThreads == 0);
    writefln("Thread creation passed!");
}

unittest
{
    writefln("Testing priorities");
    
    //Test priority based scheduling
    int a = 0;
    int b = 0;
    int c = 0;
    
    
    StackThread st0 = new StackThread(
    delegate void()
    {
        a++;
        assert(a == 1);
        assert(b == 0);
        assert(c == 0);
        
        st_yield;
        
        a++;
        assert(a == 2);
        assert(b == 2);
        assert(c == 2);
        
        st_yield;
        
        a++;
        
        writefln("a=%d, b=%d, c=%d", a, b, c);
        assert(a == 3);
        writefln("b=%d : ", b, (b==2));
        assert(b == 2);
        assert(c == 2);
        
        
    }, 10);
    
    StackThread st1 = new StackThread(
    delegate void()
    {
        b++;
        assert(a == 1);
        assert(b == 1);
        assert(c == 0);
        
        st_yield;
        
        b++;
        assert(a == 1);
        assert(b == 2);
        assert(c == 2);
        
    }, 5);
    
    StackThread st2 = new StackThread(
    delegate void()
    {
        c++;
        assert(a == 1);
        assert(b == 1);
        assert(c == 1);
        
        st_yield;
        
        c++;
        assert(a == 1);
        assert(b == 1);
        assert(c == 2);
        
        st0.priority = 100;
        
        st_yield;
        
        c++;
        assert(a == 3);
        assert(b == 2);
        assert(c == 3);
        
    }, 1);
    
    st_runSlice();
    
    assert(st0);
    assert(st1);
    assert(st2);
    
    assert(a == 1);
    assert(b == 1);
    assert(c == 1);
    
    st0.priority = -10;
    st1.priority = -5;
    
    st_runSlice();
    
    assert(a == 2);
    assert(b == 2);
    assert(c == 2);
    
    st_runSlice();
    
    assert(st0.dead);
    assert(st1.dead);
    assert(st2.dead);
    
    assert(a == 3);
    assert(b == 2);
    assert(c == 3);
    
    assert(st_numThreads == 0);
    writefln("Priorities pass");
}

version(Win32)
unittest
{
    writefln("Testing exception handling");
    
    int q0 = 0;
    int q1 = 0;
    int q2 = 0;
    int q3 = 0;
    
    StackThread st0, st1;
    
    st0 = new StackThread(
    delegate void()
    {
        q0++;
        throw new Exception("Test exception");
        q0++;
    });
    
    try
    {
        q3++;
        st_runSlice();
        q3++;
    }
    catch(Exception e)
    {
        e.print;
    }
    
    assert(st0.dead);
    assert(q0 == 1);
    assert(q1 == 0);
    assert(q2 == 0);
    assert(q3 == 1);
    
    st1 = new StackThread(
    delegate void()
    {
        try
        {
            q1++;
            throw new Exception("Testing");
            q1++;
        }
        catch(Exception e)
        {
            e.print();
        }
        
        while(true)
        {
            q2++;
            st_yield();
        }
    });
    
    st_runSlice();
    assert(st1.ready);
    assert(q0 == 1);
    assert(q1 == 1);
    assert(q2 == 1);
    assert(q3 == 1);
    
    st1.kill;
    assert(st1.dead);
    
    assert(st_numThreads == 0);
    writefln("Exception handling passed!");
}

unittest
{
    writefln("Testing thread pausing");
    
    //Test pause
    int q = 0;
    int r = 0;
    int s = 0;
    
    StackThread st0;
    
    st0 = new StackThread(
    delegate void()
    {
        s++;
        st0.pause();
        q++;
    });
    
    try
    {
        st0.resume();
    }
    catch(Exception e)
    {
        e.print;
        r ++;
    }
    
    assert(st0);
    assert(q == 0);
    assert(r == 1);
    assert(s == 0);
    
    st0.pause();
    assert(st0.paused);
    
    try
    {
        st0.pause();
    }
    catch(Exception e)
    {
        e.print;
        r ++;
    }
    
    st_runSlice();
    
    assert(q == 0);
    assert(r == 2);
    assert(s == 0);
    
    st0.resume();
    assert(st0.ready);
    
    st_runSlice();
    
    assert(st0.paused);
    assert(q == 0);
    assert(r == 2);
    assert(s == 1);
    
    st0.resume();
    st_runSlice();
    
    assert(st0.dead);
    assert(q == 1);
    assert(r == 2);
    assert(s == 1);
    
    try
    {
        st0.pause();
    }
    catch(Exception e)
    {
        e.print;
        r ++;
    }
    
    st_runSlice();
    
    assert(st0.dead);
    assert(q == 1);
    assert(r == 3);
    assert(s == 1);
    
    assert(st_numThreads == 0);
    writefln("Pause passed!");
}


unittest
{
    writefln("Testing kill");
    
    int q0 = 0;
    int q1 = 0;
    int q2 = 0;
    
    StackThread st0, st1, st2;
    
    st0 = new StackThread(
    delegate void()
    {
        while(true)
        {
            q0++;
            st_yield();
        }
    });
    
    st1 = new StackThread(
    delegate void()
    {
        q1++;
        st1.kill();
        q1++;
    });
    
    st2 = new StackThread(
    delegate void()
    {
        while(true)
        {
            q2++;
            st_yield();
        }
    });
    
    assert(st1.ready);
    
    st_runSlice();
    
    assert(st1.dead);
    assert(q0 == 1);
    assert(q1 == 1);
    assert(q2 == 1);
    
    st_runSlice();
    assert(q0 == 2);
    assert(q1 == 1);
    assert(q2 == 2);
    
    st0.kill();
    st_runSlice();
    assert(st0.dead);
    assert(q0 == 2);
    assert(q1 == 1);
    assert(q2 == 3);
    
    st2.pause();
    assert(st2.paused);
    st2.kill();
    assert(st2.dead);
    
    int r = 0;
    
    try
    {
        r++;
        st2.kill();
        r++;
    }
    catch(StackThreadException e)
    {
        e.print;
    }
    
    assert(st2.dead);
    assert(r == 1);
    
    assert(st_numThreads == 0);
    writefln("Kill passed");
}

unittest
{
    writefln("Testing join");
    
    int q0 = 0;
    int q1 = 0;
    
    StackThread st0, st1;
    
    st0 = new StackThread(
    delegate void()
    {
        q0++;
        st1.join();
        q0++;
    }, 10);
    
    st1 = new StackThread(
    delegate void()
    {
        q1++;
        st_yield();
        q1++;
        st1.join();
        q1++;
    }, 0);
    
    try
    {
        st0.join();
        assert(false);
    }
    catch(StackThreadException e)
    {
        e.print();
    }
    
    st_runSlice();
    
    assert(st0.alive);
    assert(st1.alive);
    assert(q0 == 1);
    assert(q1 == 1);
    
    try
    {
        st_runSlice();
        assert(false);
    }
    catch(Exception e)
    {
        e.print;
    }
    
    assert(st0.alive);
    assert(st1.dead);
    assert(q0 == 1);
    assert(q1 == 2);
    
    st_runSlice();
    assert(st0.dead);
    assert(q0 == 2);
    assert(q1 == 2);
    
    assert(st_numThreads == 0);
    writefln("Join passed");
}

unittest
{
    writefln("Testing restart");
    assert(st_numThreads == 0);
    
    int q0 = 0;
    int q1 = 0;
    
    StackThread st0, st1;
    
    st0 = new StackThread(
    delegate void()
    {
        q0++;
        st_yield();
        st0.restart();
    });
    
    st_runSlice();
    assert(st0.ready);
    assert(q0 == 1);
    
    st_runSlice();
    assert(st0.ready);
    assert(q0 == 1);
    
    st_runSlice();
    assert(st0.ready);
    assert(q0 == 2);
    
    st0.kill();
    assert(st0.dead);
    
    assert(st_numThreads == 0);
    writefln("Testing the other restart");
    
    st1 = new StackThread(
    delegate void()
    {
        q1++;
        while(true)
        {
            st_yield();
        }
    });
    
    assert(st1.ready);
    
    st_runSlice();
    assert(q1 == 1);
    
    st_runSlice();
    assert(q1 == 1);
    
    st1.restart();
    st_runSlice();
    assert(st1.ready);
    assert(q1 == 2);
    
    st1.pause();
    st_runSlice();
    assert(st1.paused);
    assert(q1 == 2);
    
    st1.restart();
    st1.resume();
    st_runSlice();
    assert(st1.ready);
    assert(q1 == 3);
    
    st1.kill();
    st1.restart();
    assert(st1.paused);
    st1.resume();
    
    st_runSlice();
    assert(st1.ready);
    assert(q1 == 4);
    
    st1.kill();
    
    assert(st_numThreads == 0);
    writefln("Restart passed");
}

unittest
{
    writefln("Testing abort / reset");
    assert(st_numThreads == 0);
    
    try
    {
        st_abortSlice();
        assert(false);
    }
    catch(StackThreadException e)
    {
        e.print;
    }
    
    
    int q0 = 0;
    int q1 = 0;
    int q2 = 0;
    
    StackThread st0 = new StackThread(
    delegate void()
    {
        while(true)
        {
            writefln("st0");
            q0++;
            st_abortSlice();
            st_yield();
        }
    }, 10);
    
    StackThread st1 = new StackThread(
    delegate void()
    {
        while(true)
        {
            writefln("st1");
            q1++;
            st_abortSlice();
            st_yield();
        }
    }, 5);
    
    StackThread st2 = new StackThread(
    delegate void()
    {
        while(true)
        {
            writefln("st2");
            q2++;
            st_abortSlice();
            st_yield();
        }
    }, 0);
    
    st_runSlice();
    assert(q0 == 1);
    assert(q1 == 0);
    assert(q2 == 0);
    
    st_runSlice();
    assert(q0 == 1);
    assert(q1 == 1);
    assert(q2 == 0);
    
    st_runSlice();
    assert(q0 == 1);
    assert(q1 == 1);
    assert(q2 == 1);
    
    st_runSlice();
    assert(q0 == 2);
    assert(q1 == 1);
    assert(q2 == 1);
    
    st_resetSlice();
    st_runSlice();
    assert(q0 == 3);
    assert(q1 == 1);
    assert(q2 == 1);
    
    st0.kill();
    st1.kill();
    st2.kill();
    
    st_runSlice();
    assert(q0 == 3);
    assert(q1 == 1);
    assert(q2 == 1);
    
    assert(st_numThreads == 0);
    writefln("Abort slice passed");
}

unittest
{
    writefln("Testing throwYield");
    
    int q0 = 0;
    
    StackThread st0 = new StackThread(
    delegate void()
    {
        q0++;
        st_throwYield(new Exception("testing st_throwYield"));
        q0++;
    });
    
    try
    {
        st_runSlice();
        assert(false);
    }
    catch(Exception e)
    {
        e.print();
    }
    
    assert(q0 == 1);
    assert(st0.ready);
    
    st_runSlice();
    assert(q0 == 2);
    assert(st0.dead);
    
    assert(st_numThreads == 0);
    writefln("throwYield passed");
}
}
