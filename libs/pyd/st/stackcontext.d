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
 * This module implements the code necessary for context
 * switching.  StackContexts can be used independently
 * of StackThreads, and may be used for implementing
 * coroutines, custom scheduling or complex iterators.
 *
 * Thanks to Lars Ivar Igesunde (larsivar@igesundes.no)
 * for the ucontext bindings on Linux used in earlier
 * implementations.
 *
 * Version: 0.12
 * Date: October 17, 2006
 * Authors: Mikola Lysenko, mclysenk@mtu.edu
 * License: Use/copy/modify freely, just give credit.
 * Copyright: Public domain.
 *
 * Bugs:
 *  Debug builds will eat more stack space than release
 *  builds.  To prevent this, you can allocate some
 *  extra stack in debug mode.  This is not that tragic,
 *	since overflows are now trapped.
 *
 *  DMD has a bug on linux with multiple delegates in a
 *  scope.  Be aware that the linux version may have
 *  issues due to a lack of proper testing.
 *
 *  Due to the way DMD handles windows exceptions, it is
 *  impossible to trap for stack overflows.  Once this
 *  gets fixed, it will be possible to allocate dynamic
 *  stacks.
 *
 *  To prevent memory leaks, compile with -version=LEAK_FIX
 *  This will slow down the application, but it will
 *  improve memory usage.  In an ideal world, it would be
 *  the default behavior, but due to issues with Phobos'
 *  removeRange I have set it as optional.
 *
 *  GDC version does not support assembler optimizations, since
 *  it uses a different calling convention. 
 *
 * History:
 *  v0.12 - Workaround for DMD bug.
 *
 *  v0.11 - Implementation is now thread safe.
 *
 *  v0.10 - Added the LEAK_FIX flag to work around the
 *          slowness of std.gc.removeRange
 *
 *	v0.9 - Switched linux to an asm implementation.
 *
 *  v0.8 - Added throwYield.
 *
 *  v0.7 - Switched to system specific allocators
 *      (VirtualAlloc, mmap) in order to catch stack
 *      overflows.
 *
 *  v0.6 - Fixed a bug with the window version.  Now saves
 *      EBX, ESI, EDI across switches.
 *
 *  v0.5 - Linux now fully supported.  Discovered the cause
 *      of the exception problems: Bug in DMD.
 *
 *  v0.4 - Fixed the GC, added some linux support
 *
 *  v0.3 - Major refactoring
 *
 *  v0.2 - Fixed exception handling
 *
 *  v0.1 - Initial release
 *
 ******************************************************/
module st.stackcontext;

private import
    std.thread,
    std.stdio,
    std.string,
    std.gc,
    st.tls;

//Handle versions
version(D_InlineAsm_X86)
{
    version(DigitalMars)
    {
        version(Win32) version = SC_WIN_ASM;
        version(linux) version = SC_LIN_ASM;
    }
    
    //GDC uses a different calling conventions, need to reverse engineer them later
}


/// The default size of a StackContext's stack
const size_t DEFAULT_STACK_SIZE = 0x40000;

/// The minimum size of a StackContext's stack
const size_t MINIMUM_STACK_SIZE = 0x1000;

/// The state of a context object
enum CONTEXT_STATE
{
    READY,      /// When a StackContext is in ready state, it may be run
    RUNNING,    /// When a StackContext is running, it is currently in use, and cannot be run
    DEAD,       /// When a StackContext is dead, it may no longer be run
}

/******************************************************
 * A ContextException is generated whenever there is a
 * problem in the StackContext system.  ContextExceptions
 * can be triggered by running out of memory, or errors
 * relating to doubly starting threads.
 ******************************************************/
public class ContextException : Exception
{
    this(char[] msg) { super( msg ); }
    
    this(StackContext context, char[] msg)
    {
        if(context is null)
        {
            debug (StackContext) writefln("Generated an exception: %s", msg);
            super(msg);
        }
        else
        {
            debug (StackContext) writefln("%s generated an exception: %s", context.toString, msg);
            super(format("Context %s: %s", context.toString, msg));
        }
    }
}



/******************************************************
 * A ContextError is generated whenever something
 * horrible and unrecoverable happens.  Like writing out
 * of the stack.
 ******************************************************/
public class ContextError : Error
{
    this(char[] msg)
    {
        super(msg);
    }
}




/******************************************************
 * The StackContext is building block of the
 * StackThread system. It allows the user to swap the
 * stack of the running program.
 *
 * For most applications, there should be no need to use
 * the StackContext, since the StackThreads are simpler.
 * However, the StackContext can provide useful features
 * for custom schedulers and coroutines.
 * 
 * Any non running context may be restarted.  A restarted
 * context starts execution from the beginning of its
 * delegate.
 *
 * Contexts may be nested arbitrarily, ie Context A invokes
 * Context B, such that when B yields A is resumed.
 *
 * Calling run on already running or dead context will
 * result in an exception.
 *
 * If an exception is generated in a context and it is
 * not caught, then it will be rethrown from the run
 * method.  A program calling 'run' must be prepared 
 * to deal with any exceptions that might be thrown.  Once
 * a context has thrown an exception like this, it dies
 * and must be restarted before it may be run again.
 *
 * Example:
 * <code><pre>
 * // Here is a trivial example using contexts. 
 * // More sophisticated uses of contexts can produce
 * // iterators, concurrent state machines and coroutines
 * //
 * void func1()
 * {
 *     writefln("Context 1 : Part 1");
 *     StackContext.yield();
 *     writefln("Context 1 : Part 2");
 * }
 * void func2()
 * {
 *     writefln("Context 2 : Part 1");
 *     StackContext.yield();
 *     writefln("Context 2 : Part 2");
 * }
 * //Create the contexts
 * StackContext ctx1 = new StackContext(&func1);
 * StackContext ctx2 = new StackContext(&func2);
 *
 * //Run the contexts
 * ctx1.run();     // Prints "Context 1 : Part 1"
 * ctx2.run();     // Prints "Context 2 : Part 1"
 * ctx1.run();     // Prints "Context 1 : Part 2"
 * ctx2.run();     // Prints "Context 2 : Part 2"
 *
 * //Here is a more sophisticated example using
 * //exceptions
 * //
 * void func3()
 * {
 *      writefln("Going to throw");
 *      StackContext.yield();
 *      throw new Exception("Test Exception");
 * }
 * //Create the context
 * StackContext ctx3 = new StackContext(&func3);
 *
 * //Now run the context
 * try
 * {
 *      ctx3.run();     // Prints "Going to throw"
 *      ctx3.run();     // Throws an exception
 *      writefln("Bla");// Never gets here
 * }
 * catch(Exception e)
 * {
 *      e.print();      // Prints "Test Exception"
 *      //We can't run ctx3 anymore unless we restart it
 *      ctx3.restart();
 *      ctx3.run();     // Prints "Going to throw"
 * }
 *
 * //A final example illustrating context nesting
 * //
 * StackContext A, B;
 *
 * void funcA()
 * {
 *     writefln("A : Part 1");
 *     B.run();
 *     writefln("A : Part 2");
 *     StackContext.yield();
 *     writefln("A : Part 3");
 * }
 * void funcB()
 * {
 *      writefln("B : Part 1");
 *      StackContext.yield();
 *      writefln("B : Part 2");
 * }
 * A = new StackContext(&funcA);
 * B = new StackContext(&funcB);
 *
 * //We first run A
 * A.run();     //Prints "A : Part 1"
 *              //       "B : Part 1"
 *              //       "A : Part 2"
 *              //
 * //Now we run B
 * B.run();     //Prints "B : Part 2"
 *              //
 * //Now we finish A
 * A.run();     //Prints "A : Part 3"
 *
 * </pre></code>
 * 
 ******************************************************/
public final class StackContext
{
    /**
     * Create a StackContext with the given stack size,
     * using a delegate.
     *
     * Params:
     *  fn = The delegate we will be running.
     *  stack_size = The size of the stack for this thread
     *  in bytes.  Note, Must be greater than the minimum
     *  stack size.
     *
     * Throws:
     *  A ContextException if there is insufficient memory
     *  for the stack.
     */
    public this(void delegate() fn, size_t stack_size = DEFAULT_STACK_SIZE)
    in
    {
        assert(fn !is null);
        assert(stack_size >= MINIMUM_STACK_SIZE);
    }
    body
    {
        //Initalize the delegate
        proc = fn;
        
        //Set up the stack
        setupStack(stack_size);
        
        debug (StackContext) writefln("Created %s", this.toString);
    }
    
    /**
     * Create a StackContext with the given stack size,
     * using a function pointer.
     *
     * Params:
     *  fn = The function pointer we are using
     *  stack_size = The size of the stack for this thread
     *  in bytes.  Note, Must be greater than the minimum
     *  stack size.
     *
     * Throws:
     *  A ContextException if there is insufficient memory
     *  for the stack.
     */
    public this(void function() fn, size_t stack_size = DEFAULT_STACK_SIZE)
    in
    {
        assert(fn !is null);
        assert(stack_size >= MINIMUM_STACK_SIZE);
    }
    body
    {
        //Caste fn to delegate
        f_proc = fn;
        proc = &to_dg;
        
        setupStack(stack_size);
        
        debug (StackContext) writefln("Created %s", this.toString);
    }
    
    
    /**
     * Release the stack context.  Note that since stack
     * contexts are NOT GARBAGE COLLECTED, they must be
     * explicitly freed.  This usually taken care of when
     * the user creates the StackContext implicitly via
     * StackThreads, but in the case of a Context, it must
     * be handled on a per case basis.
     *
     * Throws:
     *  A ContextError if the stack is corrupted.
     */
    ~this()
    in
    {
        assert(state != CONTEXT_STATE.RUNNING);
        assert(current_context.val !is this);
    }
    body
    {
        debug (StackContext) writefln("Deleting %s", this.toString);
        
        //Delete the stack if we are not dead
        deleteStack();
    }
    
    /**
     * Run the context once.  This causes the function to
     * run until it invokes the yield method in this
     * context, at which point control returns to the place
     * where code invoked the program.
     *
     * Throws:
     *  A ContextException if the context is not READY.
     *
     *  Any exceptions generated in the context are 
     *  bubbled up through this method.
     */
    public final void run()
    {
        debug (StackContext) writefln("Running %s", this.toString);
        
        //We must be ready to run
        assert(state == CONTEXT_STATE.READY, 
            "Context is not in a runnable state");
        
        //Save the old context
        StackContext tmp = current_context.val;
        
        version(LEAK_FIX)
        {
            //Mark GC info
            debug (LogGC) writefln("Adding range: %8x-%8x", &tmp, getStackBottom());
            addRange(cast(void*)&tmp, getStackBottom());
        }
        
        //Set new context
        current_context.val = this;
		ctx.switchIn();
        current_context.val = tmp;
        
        assert(state != CONTEXT_STATE.RUNNING);
        
        version(LEAK_FIX)
        {
            //Clear GC info
            debug (LogGC) writefln("Removing range: %8x", &tmp);
            removeRange(cast(void*)&tmp);
            
            
            //If we are dead, we need to release the GC
            if(state == CONTEXT_STATE.DEAD && 
                gc_start !is null)
            {
                debug (LogGC) writefln("Removing range: %8x", gc_start);
                removeRange(gc_start);
                gc_start = null;
            }
        }
        
        // Pass any exceptions generated up the stack
        if(last_exception !is null)
        {
            debug (StackContext) writefln("%s generated an exception: %s", this.toString, last_exception.toString);
            
            //Clear the exception
            Object tmpo = last_exception;
            last_exception = null;
            
            //Pass it up
            throw tmpo;
        }
        
        debug (StackContext) writefln("Done running context: %s", this.toString);
    }
    
    
    /**
     * Returns control of the application to the routine
     * which invoked the StackContext.  At which point,
     * the application runs.
     *
     * Throws:
     *  A ContextException when there is no currently
     *  running context.
     */
    public final static void yield()
    {
        StackContext cur_ctx = current_context.val;
        
        //Make sure we are actually running
        assert(cur_ctx !is null,
            "Tried to yield without any running contexts.");
        
        debug (StackContext) writefln("Yielding %s", cur_ctx.toString);
        
        assert(cur_ctx.running);
        
        //Leave the current context
        cur_ctx.state = CONTEXT_STATE.READY;
        StackContext tmp = cur_ctx;
        
        version(LEAK_FIX)
        {
            //Save the GC range
            cur_ctx.gc_start = cast(void*)&tmp;
            debug (LogGC) writefln("Adding range: %8x-%8x",
                cur_ctx.gc_start, cur_ctx.ctx.stack_top);
            addRange(cur_ctx.gc_start, cur_ctx.ctx.stack_top);
        }
        
        //Swap
        cur_ctx.ctx.switchOut();
        
        version(LEAK_FIX)
        {
            StackContext t_ctx = current_context.val;
            
            //Remove the GC range
            debug (LogGC) writefln("Removing range: %8x",
                t_ctx.gc_start);
            assert(t_ctx.gc_start !is null);
            removeRange(t_ctx.gc_start);
            t_ctx.gc_start = null;
        }
        
        //Return
        current_context.val = tmp;
        tmp.state = CONTEXT_STATE.RUNNING;
        
        debug (StackContext) writefln("Resuming context: %s", tmp.toString);
    }
    
    /**
     * Throws an exception and yields.  The exception
     * will propagate out of the run method, while the
     * context will remain alive and functioning.
     * The context may be resumed after the exception has
     * been thrown.
     *
     * Params:
     *  t = The exception object we will propagate.
     */
    public final static void throwYield(Object t)
    {
        current_context.val.last_exception = t;
        yield();
    }
    
    /**
     * Resets the context to its original state.
     *
     * Throws:
     *  A ContextException if the context is running.
     */
    public final void restart()
    {
        debug (StackContext) writefln("Restarting %s", this.toString);
        
        assert(state != CONTEXT_STATE.RUNNING,
            "Cannot restart a context while it is running");
        
        //Reset the context
        restartStack();
    }
    
    /**
     * Recycles the context by restarting it with a new delegate. This
     * can save resources by allowing a program to reuse previously
     * allocated contexts.
     *
     * Params:
     *  dg = The delegate which we will be running.
     */
    public final void recycle(void delegate() dg)
    {
        debug (StackContext) writefln("Recycling %s", this.toString);
        
        assert(state != CONTEXT_STATE.RUNNING,
            "Cannot recycle a context while it is running");
        
        //Set the delegate and restart
        proc = dg;
        restartStack();
    }
    
    /**
     * Immediately sets the context state to dead. This
     * can be used as an alternative to deleting the 
     * context since it releases any GC references, and
     * may be easily reallocated.
     *
     * Throws:
     *  A ContextException if the context is not READY.
     */
    public final void kill()
    {
        assert(state != CONTEXT_STATE.RUNNING,
            "Cannot kill a context while it is running.");
        
        
        version(LEAK_FIX)
        {
            if(state == CONTEXT_STATE.DEAD)
            {
                return;
            }
            
            //Clear the GC ranges if necessary
            if(gc_start !is null)
            {
                debug (LogGC) writefln("Removing range: %8x", gc_start);
                removeRange(gc_start);
                gc_start = null;
            }
        }
        
        state = CONTEXT_STATE.DEAD;
    }
    
    /**
     * Convert the context into a human readable string,
     * for debugging purposes.
     *
     * Returns: A string describing the context.
     */
    public final char[] toString()
    {
        static char[][] state_names = 
        [
            "RDY",
            "RUN",
            "XXX",
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
        if(f_proc !is null)
            h.d.fptr = cast(void*)f_proc;
        else
            h.dg = proc;
        
        return format(
            "Context[sp:%8x,st:%s,fn:%8x]",
            ctx.stack_pointer,
            state_names[cast(int)state],
            h.d.fptr);
    }
    
    /**
     * Returns: The state of this stack context.
     */
    public CONTEXT_STATE getState()
    {
        return state;
    }
    
    /**
     * Returns: True if the context can be run.
     */
    public bool ready()
    {
        return state == CONTEXT_STATE.READY;
    }
    
    /**
     * Returns: True if the context is currently running
     */
    public bool running()
    {
        return state == CONTEXT_STATE.RUNNING;
    }
    
    /**
     * Returns: True if the context is currenctly dead
     */
    public bool dead()
    {
        return state == CONTEXT_STATE.DEAD;
    }
    
    /**
     * Returns: The currently running stack context.
     *  null if no context is currently running.
     */
    public static StackContext getRunning()
    {
        return current_context.val;
    }
    
    invariant
    {
        
        switch(state)
        {
            case CONTEXT_STATE.RUNNING:
                //Make sure context is running
                //assert(ctx.old_stack_pointer !is null);
                assert(current_context.val !is null);
            
            case CONTEXT_STATE.READY:
                //Make sure state is ready
                assert(ctx.stack_bottom !is null);
                assert(ctx.stack_top !is null);
                assert(ctx.stack_top >= ctx.stack_bottom);
                assert(ctx.stack_top - ctx.stack_bottom >= MINIMUM_STACK_SIZE);
                assert(ctx.stack_pointer !is null);
                assert(ctx.stack_pointer >= ctx.stack_bottom);
                assert(ctx.stack_pointer <= ctx.stack_top);
                assert(proc !is null);
            break;
            
            case CONTEXT_STATE.DEAD:
                //Make sure context is dead
				//assert(gc_start is null);
            break;
            
            default: assert(false);
        }
    }
        
    version(LEAK_FIX)
    {
        // Start of GC range
        private void * gc_start = null;
    }
    
    // The system context
    private SysContext ctx;

    // Context state
    private CONTEXT_STATE state;
    
    // The last exception generated
    private static Object last_exception = null;
    
/*BEGIN TLS {*/
        
    // The currently running stack context
    private static ThreadLocal!(StackContext) current_context = null;
    
/*} END TLS*/
    
    // The procedure this context is running
    private void delegate() proc = null;

    // Used to convert a function pointer to a delegate
    private void function() f_proc = null;
    private void to_dg() { f_proc(); }
    

    /**
     * Initialize the stack for the context.
     */
    private void setupStack(size_t stack_size)
    {
        //Initialize the stack
        ctx.initStack(stack_size);
        
        //Initialize context state
        state = CONTEXT_STATE.READY;
        
        version(LEAK_FIX)
        {
            assert(gc_start is null);
            gc_start = null;
        }
        else
        {
            addRange(ctx.getStackStart, ctx.getStackEnd);
        }
    }
    
    /**
     * Restart the context.
     */
    private void restartStack()
    {
        version(LEAK_FIX)
        {
            //Clear the GC ranges if necessary
            if(gc_start !is null)
            {
                debug (LogGC) writefln("Removing range: %8x", gc_start);
                removeRange(gc_start);
                gc_start = null;
            }
        }
        
        ctx.resetStack();
        state = CONTEXT_STATE.READY;
    }
    
    /**
     * Delete the stack
     */
    private void deleteStack()
    {
        version(LEAK_FIX)
        {
            //Clear the GC ranges if necessary
            if(gc_start !is null)
            {
                debug (LogGC) writefln("Removing range: %8x", gc_start);
                removeRange(gc_start);
                gc_start = null;
            }
        }
        else
        {
            removeRange(ctx.getStackStart);
        }
        
        // Clear state
        state = CONTEXT_STATE.DEAD;
        proc = null;
        f_proc = null;
        
        // Kill the stack
        ctx.killStack();
    }
    
    /**
     * Run the context
     */
    private static extern(C) void startContext()
    in
    {
        assert(current_context.val !is null);
		version(LEAK_FIX)
            assert(current_context.val.gc_start is null);
    }
    body
    {
        StackContext cur_ctx = current_context.val;
        
        try
        {
            //Set state to running, enter the context
            cur_ctx.state = CONTEXT_STATE.RUNNING;
            debug (StackContext) writefln("Starting %s", cur_ctx.toString);
            cur_ctx.proc();
            debug (StackContext) writefln("Finished %s", cur_ctx.toString);
        }
        catch(Object o)
        {
            //Save exceptions so we can throw them later
            debug (StackContext) writefln("Got an exception: %s, in %s", o.toString, cur_ctx.toString);
            cur_ctx.last_exception = o;
        }
        finally
        {
            //Leave the object.  Don't need to worry about
            //GC, since it should already be released.
            cur_ctx.state = CONTEXT_STATE.DEAD;
            debug (StackContext) writefln("Leaving %s", cur_ctx.toString);
            cur_ctx.ctx.switchOut();
        }
        
        //This should never be reached
        assert(false);
    }
    
    /**
     * Grab the stack bottom!
     */
    private void * getStackBottom()
    {
        version(Win32)
        {
            StackContext cur = current_context.val;
            
            if(cur is null)
                return os_query_stackBottom();
            
            return cur.ctx.stack_top;
        }
        else
        {
            Thread t = Thread.getThis;
            return t.stackBottom;
        }
    }
}

static this()
{
    StackContext.current_context = new ThreadLocal!(StackContext);

    version(SC_WIN_ASM)
    {
        //Get the system's page size
        SYSTEM_INFO sys_info;
        GetSystemInfo(&sys_info);
        page_size = sys_info.dwPageSize;
    }
}


/********************************************************
 * SYSTEM SPECIFIC FUNCTIONS
 *  All information below this can be regarded as a
 *  black box.  The details of the implementation are
 *  irrelevant to the workings of the rest of the
 *  context data.
 ********************************************************/

private version (SC_WIN_ASM)
{

import std.windows.syserror;
    
struct SYSTEM_INFO
{
    union
    {
        int dwOemId;
        
        struct
        {
            short wProcessorArchitecture;
            short wReserved;
        }
    }
    
    int dwPageSize;
    void* lpMinimumApplicationAddress;
    void* lpMaximumApplicationAddress;
    int* dwActiveProcessorMask;
    int dwNumberOfProcessors;
    int dwProcessorType;
    int dwAllocationGranularity;
    short wProcessorLevel;
    short wProcessorRevision;
}

extern (Windows) void GetSystemInfo(
    SYSTEM_INFO * sys_info);

extern (Windows) void* VirtualAlloc(
    void * addr,
    size_t size,
    uint type,
    uint protect);

extern (Windows) int VirtualFree(
    void * addr,
    size_t size,
    uint type);

extern (Windows) int GetLastError();

private debug(LogStack)
{
    import std.file; 
}

const uint MEM_COMMIT           = 0x1000;
const uint MEM_RESERVE          = 0x2000;
const uint MEM_RESET            = 0x8000;
const uint MEM_LARGE_PAGES      = 0x20000000;
const uint MEM_PHYSICAL         = 0x400000;
const uint MEM_TOP_DOWN         = 0x100000;
const uint MEM_WRITE_WATCH      = 0x200000;

const uint MEM_DECOMMIT         = 0x4000;
const uint MEM_RELEASE          = 0x8000;

const uint PAGE_EXECUTE             = 0x10;
const uint PAGE_EXECUTE_READ        = 0x20;
const uint PAGE_EXECUTE_READWRITE   = 0x40;
const uint PAGE_EXECUTE_WRITECOPY   = 0x80;
const uint PAGE_NOACCESS            = 0x01;
const uint PAGE_READONLY            = 0x02;
const uint PAGE_READWRITE           = 0x04;
const uint PAGE_WRITECOPY           = 0x08;
const uint PAGE_GUARD               = 0x100;
const uint PAGE_NOCACHE             = 0x200;
const uint PAGE_WRITECOMBINE        = 0x400;

// Size of a page on the system
size_t page_size;


private struct SysContext
{
    // Stack information
    void * stack_bottom = null;
    void * stack_top = null;
    void * stack_pointer = null;

    // The old stack pointer
    void * old_stack_pointer = null;
    
    
    /**
     * Returns: The size of the sys context
     */
    size_t getSize()
    {
        return cast(size_t)(stack_top - stack_bottom - page_size);
    }
    
    
    /**
     * Returns: The start of the stack.
     */
    void * getStackStart()
    {
        return stack_bottom + page_size;
    }
    
    /**
     * Returns: The end of the stack.
     */
    void * getStackEnd()
    {
        return stack_top;
    }
    
    
    /**
     * Handle and report any system errors
     */
    void handleWinError(char[] msg)
    {
        throw new ContextException(format(
            "Failed to %s, %s",
            msg, sysErrorString(GetLastError())));
    }
    
    /**
     * Initialize the stack
     */
    void initStack(size_t stack_size)
    {
        //Allocate the stack + guard page
        
        //Count number of pages
        int num_pages = (stack_size + page_size - 1) / page_size;
        
        //Reserve the address space for the stack
        stack_bottom = VirtualAlloc(
            null,
            (num_pages + 1) * page_size,
            MEM_RESERVE,
            PAGE_NOACCESS);
        if(stack_bottom is null)
            handleWinError("reserve stack address");
        
        //Now allocate the base pages
        void * res = VirtualAlloc(
            stack_bottom + page_size,
            num_pages * page_size,
            MEM_COMMIT,
            PAGE_READWRITE);
        if(res is null)
            handleWinError("allocate stack space");
        
        stack_top = res + num_pages * page_size;
        
        //Create a guard page
        res = VirtualAlloc(
            stack_bottom,
            page_size,
            MEM_COMMIT,
            PAGE_READWRITE | PAGE_GUARD);
        if(res is null)
            handleWinError("create guard page");
        
        //Initialize the stack
        resetStack();
    }
    
    /**
     * Reset the stack.
     */
    void resetStack()
    {
        stack_pointer = stack_top;
        assert(cast(uint)stack_pointer % 4 == 0);
        
        //Initialize stack state
        void push(uint val)
        {
            stack_pointer -= 4;
            *cast(uint*)stack_pointer = val;
        }
        
        push(cast(uint)&StackContext.startContext); //EIP
        push(0xFFFFFFFF);                   //EBP
        push(0xFFFFFFFF);                   //FS:[0]
        push(cast(uint)stack_top);          //FS:[4]
        push(cast(uint)stack_bottom + 4);   //FS:[8]
        push(0);    //EBX
        push(0);    //ESI
        push(0);    //EDI
        
        assert(stack_pointer > stack_bottom);
        assert(stack_pointer < stack_top);
    }
    
    /**
     * Free the stack
     */
    void killStack()
    {
        //Work around for bug in DMD 0.170
        if(stack_bottom is null)
        {
            debug(StackContext)
                writefln("WARNING!!!! Accidentally deleted a context twice");
            return;
        }
        
        debug (LogStack)
        {
            static int log_num = 0;
            write(format("lg%d.bin", log_num++),
                stack_bottom[0..(stack_top - stack_bottom)]);
        }
        
        assert(stack_pointer > stack_bottom);
        assert(stack_pointer < stack_top);
        
        // Release the stack
        assert(stack_bottom !is null);
        
        if(VirtualFree(stack_bottom, 0, MEM_RELEASE) == 0)
        {
            handleWinError("release stack");
        }
        
        //Clear all the old stack pointers
        stack_bottom =
        stack_top =
        stack_pointer =
        old_stack_pointer = null;
    }
    
    /**
     * Switch into a context.
     */
    void switchIn()
    {
        asm
        {
            naked;
            
            //Save old state into stack
            push EBP;
            push dword ptr FS:[0];
            push dword ptr FS:[4];
            push dword ptr FS:[8];
            push EBX;
            push ESI;
            push EDI;
            
            //Save old sp
            mov dword ptr old_stack_pointer[EAX], ESP;
            
            //Set the new stack pointer
            mov ESP, stack_pointer[EAX];
            
            //Restore saved state
            pop EDI;
            pop ESI;
            pop EBX;
            pop dword ptr FS:[8];
            pop dword ptr FS:[4];
            pop dword ptr FS:[0];
            pop EBP;
            
            //Return
            ret;
        }
    }
    
    /**
     * Switch out of a context
     */
    void switchOut()
    {
        asm
        {
            naked;
            
            //Save current state
            push EBP;
            push dword ptr FS:[0];
            push dword ptr FS:[4];
            push dword ptr FS:[8];
            push EBX;
            push ESI;
            push EDI;
            
            // Set the stack pointer
            mov dword ptr stack_pointer[EAX], ESP;
            
            // Restore the stack pointer
            mov ESP, dword ptr old_stack_pointer[EAX];
            
            //Zap the old stack pointer
            xor EDX, EDX;
            mov dword ptr old_stack_pointer[EAX], EDX;
            
            //Restore saved state
            pop EDI;
            pop ESI;
            pop EBX;
            pop dword ptr FS:[8];
            pop dword ptr FS:[4];
            pop dword ptr FS:[0];
            pop EBP;
            
            //Return
            ret;
        }
    }
}
}
else private version(SC_LIN_ASM)
{

private extern(C)
{
	void * mmap(void * start, size_t length, int prot, int flags, int fd, int offset);
	int munmap(void * start, size_t length);
}

private const int PROT_EXEC = 4;
private const int PROT_WRITE = 2;
private const int PROT_READ = 1;
private const int PROT_NONE = 0;

private const int MAP_SHARED 			= 0x0001;
private const int MAP_PRIVATE 			= 0x0002;
private const int MAP_FIXED				= 0x0010;
private const int MAP_ANONYMOUS			= 0x0020;
private const int MAP_GROWSDOWN			= 0x0100;
private const int MAP_DENYWRITE			= 0x0800;
private const int MAP_EXECUTABLE		= 0x1000;
private const int MAP_LOCKED			= 0x2000;
private const int MAP_NORESERVE			= 0x4000;
private const int MAP_POPULATE			= 0x8000;
private const int MAP_NONBLOCK			= 0x10000;

private const void * MAP_FAILED = cast(void*)-1;

private struct SysContext
{
    void * stack_top = null;
    void * stack_bottom = null;
	void * stack_pointer = null;
	void * old_stack_pointer = null;
	

	size_t getSize()
	{
        return cast(size_t)(stack_top - stack_bottom);
	}
    
    void * getStackStart()
    {
        return stack_bottom;
    }
    
    void * getStackEnd()
    {
        return stack_top;
    }

    /**
     * Initialize the stack
     */
	void initStack(size_t stack_size)
	{
        //Allocate stack
        stack_bottom = mmap(
			null, 
			stack_size, 
			PROT_READ | PROT_WRITE | PROT_EXEC,
			MAP_PRIVATE | MAP_ANONYMOUS,
			0,
			0);
		
		if(stack_bottom is MAP_FAILED)
		{
			stack_bottom = null;
            throw new ContextException(null, "Could not allocate stack");
		}
        
        stack_top = stack_bottom + stack_size;
        
        //Initialize the context
        resetStack();
	}

	/**
	 * Reset the stack.
	 */
	void resetStack()
	{
		//Initialize stack pointer
		stack_pointer = stack_top;
        
        //Initialize stack state
        *cast(uint*)(stack_pointer-4) = cast(uint)&StackContext.startContext;
        stack_pointer -= 20;
	}
    
	/**
	 * Release the stack
	 */
	void killStack()
	{
        //Make sure the GC didn't accidentally double collect us...
        if(stack_bottom is null)
        {
            debug(StackContext) writefln("WARNING!!! Accidentally killed stack twice");
            return;
        }
        
        //Deallocate the stack
        if(munmap(stack_bottom, (stack_top - stack_bottom)))
			throw new ContextException(null, "Could not deallocate stack");
        
        //Remove pointer references
        stack_top =
        stack_bottom =
		stack_pointer =
		old_stack_pointer = null;
	}

	/**
	 * Enter the stack context
	 */
	void switchIn()
	{
		//HACK: The GC needs to scan the thread's stack, however we are moving
		//it.  To accomplish this feat, we just write over the internal members
		//in Thread, and hope it works, though it may not in the future.
		Thread t = Thread.getThis();
		void *sb = t.stackBottom;
		void *st = t.stackTop;

		//Note bottom & top are switched thanks to DMD's strange notation.
		//
		//Also, this is not necessarily thread safe, since a collection could
		//occur between when we set the stack ranges and when we perform a
		//context switch; however since we are gauranteed to still have our range
		//marked before we leave, this is acceptable, since the result is
		//merely under-collection.
		t.stackBottom = stack_top;
		t.stackTop = stack_bottom;
		
		pswiThunk();

		t.stackBottom = sb;
		t.stackTop = st;
	}

	//Private switch in thunk
	void pswiThunk()
	{
		asm
		{
			naked;

			//Save current state
			push EBP;
			push EBX;
			push ESI;
			push EDI;

			//Switch around the stack pointers
			mov dword ptr old_stack_pointer[EAX], ESP;
			mov ESP, dword ptr stack_pointer[EAX];

			//Restore previous state
			pop EDI;
			pop ESI;
			pop EBX;
			pop EBP;

			ret;
		}
	}

	/**
	 * Leave current context
	 */
	void switchOut()
	{
		asm
		{
			naked;

			//Save the context's state
			push EBP;
			push EBX;
			push ESI;
			push EDI;

			//Return to previous context's sp.
			mov dword ptr stack_pointer[EAX], ESP;
			mov ESP, dword ptr old_stack_pointer[EAX];

			//Restore previous context's state
			pop EDI;
			pop ESI;
			pop EBX;
			pop EBP;

			ret;
		}
	}
}
}
else
{
    static assert(false, "System currently unsupported");
}


unittest
{
    writefln("Testing context creation/deletion");
    int s0 = 0;
    static int s1 = 0;
    
    StackContext a = new StackContext(
    delegate void()
    {
        s0++;
    });
    
    static void fb() { s1++; }
    
    StackContext b = new StackContext(&fb);
    
    StackContext c = new StackContext(
        delegate void() { assert(false); });
    
    assert(a);
    assert(b);
    assert(c);
    
    assert(s0 == 0);
    assert(s1 == 0);
    assert(a.getState == CONTEXT_STATE.READY);
    assert(b.getState == CONTEXT_STATE.READY);
    assert(c.getState == CONTEXT_STATE.READY);
    
    delete c;
    
    assert(s0 == 0);
    assert(s1 == 0);
    assert(a.getState == CONTEXT_STATE.READY);
    assert(b.getState == CONTEXT_STATE.READY);
    
    writefln("running a");
    a.run();
    writefln("done a");
    
    assert(a);
    
    assert(s0 == 1);
    assert(s1 == 0);
    assert(a.getState == CONTEXT_STATE.DEAD);
    assert(b.getState == CONTEXT_STATE.READY);    
    
    assert(b.getState == CONTEXT_STATE.READY);
    
    writefln("Running b");
    b.run();
    writefln("Done b");
    
    assert(s0 == 1);
    assert(s1 == 1);
    assert(b.getState == CONTEXT_STATE.DEAD);
    
    delete a;
    delete b;
    
    writefln("Context creation passed");
}
    
unittest
{
    writefln("Testing context switching");
    int s0 = 0;
    int s1 = 0;
    int s2 = 0;
    
    StackContext a = new StackContext(
    delegate void()
    {
        while(true)
        {
            debug writefln(" ---A---");
            s0++;
            StackContext.yield();
        }
    });
    
    
    StackContext b = new StackContext(
    delegate void()
    {
        while(true)
        {
            debug writefln(" ---B---");
            s1++;
            StackContext.yield();
        }
    });
    
    
    StackContext c = new StackContext(
    delegate void()
    {
        while(true)
        {
            debug writefln(" ---C---");
            s2++;
            StackContext.yield();
        }
    });
    
    assert(a);
    assert(b);
    assert(c);
    assert(s0 == 0);
    assert(s1 == 0);
    assert(s2 == 0);
    
    a.run();
    b.run();
    
    assert(a);
    assert(b);
    assert(c);
    assert(s0 == 1);
    assert(s1 == 1);
    assert(s2 == 0);
    
    for(int i=0; i<20; i++)
    {
        c.run();
        a.run();
    }
    
    assert(a);
    assert(b);
    assert(c);
    assert(s0 == 21);
    assert(s1 == 1);
    assert(s2 == 20);
    
    delete a;
    delete b;
    delete c;
    
    writefln("Context switching passed");
}
    
unittest
{
    writefln("Testing nested contexts");
    StackContext a, b, c;
    
    int t0 = 0;
    int t1 = 0;
    int t2 = 0;
    
    a = new StackContext(
    delegate void()
    {
        
        t0++;
        b.run();
        
    });
    
    b = new StackContext(
    delegate void()
    {
        assert(t0 == 1);
        assert(t1 == 0);
        assert(t2 == 0);
        
        t1++;
        c.run();
        
    });
    
    c = new StackContext(
    delegate void()
    {
        assert(t0 == 1);
        assert(t1 == 1);
        assert(t2 == 0);
        
        t2++;
    });
    
    assert(a);
    assert(b);
    assert(c);
    assert(t0 == 0);
    assert(t1 == 0);
    assert(t2 == 0);
    
    a.run();
    
    assert(t0 == 1);
    assert(t1 == 1);
    assert(t2 == 1);
    
    assert(a);
    assert(b);
    assert(c);
    
    delete a;
    delete b;
    delete c;
    
    writefln("Nesting contexts passed");
}

unittest
{
	writefln("Testing basic exceptions");


	int t0 = 0;
	int t1 = 0;
	int t2 = 0;

	assert(t0 == 0);
	assert(t1 == 0);
	assert(t2 == 0);

	try
	{

		try
		{
			throw new Exception("Testing");
			t2++;
		}
		catch(Exception fx)
		{
			t1++;
			throw fx;
		}
	
		t2++;
	}
	catch(Exception ex)
	{
		t0++;
		ex.print;
	}

	assert(t0 == 1);
	assert(t1 == 1);
	assert(t2 == 0);

	writefln("Basic exceptions are supported");
}


//Anonymous delegates are slightly broken on linux. Don't run this test yet,
//since dmd will break it.
version(Win32)
unittest
{
    writefln("Testing exceptions");
    StackContext a, b, c;
    
    int t0 = 0;
    int t1 = 0;
    int t2 = 0;
    
    writefln("t0 = %s\nt1 = %s\nt2 = %s", t0, t1, t2);
    
    a = new StackContext(
    delegate void()
    {
        t0++;
        throw new Exception("A exception");
        t0++;
    });
    
    b = new StackContext(
    delegate void()
    {
        t1++;
        c.run();
        t1++;
    });
    
    c = new StackContext(
    delegate void()
    {
        t2++;
        throw new Exception("C exception");
        t2++;
    });
    
    assert(a);
    assert(b);
    assert(c);
    assert(t0 == 0);
    assert(t1 == 0);
    assert(t2 == 0);
    
    try
    {
        a.run();
        assert(false);
    }
    catch(Exception e)
    {
        e.print;
    }
    
    assert(a);
    assert(a.getState == CONTEXT_STATE.DEAD);
    assert(b);
    assert(c);
    assert(t0 == 1);
    assert(t1 == 0);
    assert(t2 == 0);
    
    try
    {
        b.run();
        assert(false);
    }
    catch(Exception e)
    {
        e.print;
    }
    
    writefln("blah2");
    
    assert(a);
    assert(b);
    assert(b.getState == CONTEXT_STATE.DEAD);
    assert(c);
    assert(c.getState == CONTEXT_STATE.DEAD);
    assert(t0 == 1);
    assert(t1 == 1);
    assert(t2 == 1);

	delete a;
	delete b;
	delete c;
    

	StackContext t;
	int q0 = 0;
	int q1 = 0;

	t = new StackContext(
	delegate void()
	{
		try
		{
			q0++;
			throw new Exception("T exception");
			q0++;
		}
		catch(Exception ex)
		{
			q1++;
			writefln("!!!!!!!!GOT EXCEPTION!!!!!!!!");
			ex.print;
		}
	});


	assert(t);
	assert(q0 == 0);
	assert(q1 == 0);
	t.run();
	assert(t);
	assert(t.dead);
	assert(q0 == 1);
	assert(q1 == 1);

	delete t;
   
    StackContext d, e;
    int s0 = 0;
    int s1 = 0;
    
    d = new StackContext(
    delegate void()
    {
        try
        {
            s0++;
            e.run();
            StackContext.yield();
            s0++;
            e.run();
            s0++;
        }
        catch(Exception ex)
        {
            ex.print;
        }
    });
    
    e = new StackContext(
    delegate void()
    {
        s1++;
        StackContext.yield();
        throw new Exception("E exception");
        s1++;
    });
    
    assert(d);
    assert(e);
    assert(s0 == 0);
    assert(s1 == 0);
    
    d.run();
    
    assert(d);
    assert(e);
    assert(s0 == 1);
    assert(s1 == 1);
    
    d.run();
    
    assert(d);
    assert(e);
    assert(s0 == 2);
    assert(s1 == 1);
    
    assert(d.dead);
    assert(e.dead);
    
    delete d;
    delete e;
    
    writefln("Exceptions passed");
}

unittest
{
    writefln("Testing reset");
    int t0 = 0;
    int t1 = 0;
    int t2 = 0;
    
    StackContext a = new StackContext(
    delegate void()
    {
        t0++;
        StackContext.yield();
        t1++;
        StackContext.yield();
        t2++;
    });
    
    assert(a);
    assert(t0 == 0);
    assert(t1 == 0);
    assert(t2 == 0);
    
    a.run();
    assert(a);
    assert(t0 == 1);
    assert(t1 == 0);
    assert(t2 == 0);
    
    a.run();
    assert(a);
    assert(t0 == 1);
    assert(t1 == 1);
    assert(t2 == 0);
    
    a.run();
    assert(a);
    assert(t0 == 1);
    assert(t1 == 1);
    assert(t2 == 1);
    
    a.restart();
    assert(a);
    assert(t0 == 1);
    assert(t1 == 1);
    assert(t2 == 1);
    
    a.run();
    assert(a);
    assert(t0 == 2);
    assert(t1 == 1);
    assert(t2 == 1);
    
    a.restart();
    a.run();
    assert(a);
    assert(t0 == 3);
    assert(t1 == 1);
    assert(t2 == 1);
    
    a.run();
    assert(a);
    assert(t0 == 3);
    assert(t1 == 2);
    assert(t2 == 1);
    
    a.restart();
    a.run();
    assert(a);
    assert(t0 == 4);
    assert(t1 == 2);
    assert(t2 == 1);
    
    delete a;
    
    writefln("Reset passed");
}

//Same problem as above.  
version (Win32)
unittest
{
    writefln("Testing standard exceptions");
    int t = 0;
    
    StackContext a = new StackContext(
    delegate void()
    {
        uint * tmp = null;
        
        *tmp = 0xbadc0de;
        
        t++;
    });
    
    assert(a);
    assert(t == 0);
    
    try
    {
        a.run();
        assert(false);
    }
    catch(Exception e)
    {
        e.print();
    }
    
    assert(a);
    assert(a.dead);
    assert(t == 0);
    
    delete a;
    
    
    writefln("Standard exceptions passed");
}

unittest
{
    writefln("Memory stress test");
    
    const uint STRESS_SIZE = 5000;
    
    StackContext ctx[];
    ctx.length = STRESS_SIZE;
    
    int cnt0 = 0;
    int cnt1 = 0;
    
    void threadFunc()
    {
        cnt0++;
        StackContext.yield;
        cnt1++;
    }
    
    foreach(inout StackContext c; ctx)
    {
        c = new StackContext(&threadFunc, MINIMUM_STACK_SIZE);
    }
    
    assert(cnt0 == 0);
    assert(cnt1 == 0);
    
    foreach(inout StackContext c; ctx)
    {
        c.run;
    }
    
    assert(cnt0 == STRESS_SIZE);
    assert(cnt1 == 0);
    
    foreach(inout StackContext c; ctx)
    {
        c.run;
    }
    
    assert(cnt0 == STRESS_SIZE);
    assert(cnt1 == STRESS_SIZE);
    
    foreach(inout StackContext c; ctx)
    {
        delete c;
    }
    
    assert(cnt0 == STRESS_SIZE);
    assert(cnt1 == STRESS_SIZE);
    
    writefln("Memory stress test passed");
}

unittest
{
    writefln("Testing floating point");
    
    float f0 = 1.0;
    float f1 = 0.0;
    
    double d0 = 2.0;
    double d1 = 0.0;
    
    real r0 = 3.0;
    real r1 = 0.0;
    
    assert(f0 == 1.0);
    assert(f1 == 0.0);
    assert(d0 == 2.0);
    assert(d1 == 0.0);
    assert(r0 == 3.0);
    assert(r1 == 0.0);
    
    StackContext a, b, c;
    
    a = new StackContext(
    delegate void()
    {
        while(true)
        {
            f0 ++;
            d0 ++;
            r0 ++;
            
            StackContext.yield();
        }
    });
    
    b = new StackContext(
    delegate void()
    {
        while(true)
        {
            f1 = d0 + r0;
            d1 = f0 + r0;
            r1 = f0 + d0;
            
            StackContext.yield();
        }
    });
    
    c = new StackContext(
    delegate void()
    {
        while(true)
        {
            f0 *= d1;
            d0 *= r1;
            r0 *= f1;
            
            StackContext.yield();
        }
    });
    
    a.run();
    assert(f0 == 2.0);
    assert(f1 == 0.0);
    assert(d0 == 3.0);
    assert(d1 == 0.0);
    assert(r0 == 4.0);
    assert(r1 == 0.0);
    
    b.run();
    assert(f0 == 2.0);
    assert(f1 == 7.0);
    assert(d0 == 3.0);
    assert(d1 == 6.0);
    assert(r0 == 4.0);
    assert(r1 == 5.0);
    
    c.run();
    assert(f0 == 12.0);
    assert(f1 == 7.0);
    assert(d0 == 15.0);
    assert(d1 == 6.0);
    assert(r0 == 28.0);
    assert(r1 == 5.0);
    
    a.run();
    assert(f0 == 13.0);
    assert(f1 == 7.0);
    assert(d0 == 16.0);
    assert(d1 == 6.0);
    assert(r0 == 29.0);
    assert(r1 == 5.0);
    
    writefln("Floating point passed");
}


version(x86) unittest
{
    writefln("Testing registers");
    
    struct registers
    {
        int eax, ebx, ecx, edx;
        int esi, edi;
        int ebp, esp;
        
        //TODO: Add fpu stuff
    }
    
    static registers old;
    static registers next;
    static registers g_old;
    static registers g_next;
    
    //I believe that D calling convention requires that
    //EBX, ESI and EDI be saved.  In order to validate
    //this, we write to those registers and call the
    //stack thread.
    static StackThread reg_test = new StackThread(
    delegate void() 
    {
        asm
        {
            naked;
            
            pushad;
            
            mov EBX, 1;
            mov ESI, 2;
            mov EDI, 3;
            
            mov [old.ebx], EBX;
            mov [old.esi], ESI;
            mov [old.edi], EDI;
            mov [old.ebp], EBP;
            mov [old.esp], ESP;
            
            call StackThread.yield;
            
            mov [next.ebx], EBX;
            mov [next.esi], ESI;
            mov [next.edi], EDI;
            mov [next.ebp], EBP;
            mov [next.esp], ESP;
            
            popad;
        }
    });
    
    //Run the stack context
    asm
    {
        naked;
        
        pushad;
        
        mov EBX, 10;
        mov ESI, 11;
        mov EDI, 12;
        
        mov [g_old.ebx], EBX;
        mov [g_old.esi], ESI;
        mov [g_old.edi], EDI;
        mov [g_old.ebp], EBP;
        mov [g_old.esp], ESP;
        
        mov EAX, [reg_test];
        call StackThread.run;
        
        mov [g_next.ebx], EBX;
        mov [g_next.esi], ESI;
        mov [g_next.edi], EDI;
        mov [g_next.ebp], EBP;
        mov [g_next.esp], ESP;
        
        popad;
    }
    
    
    //Make sure the registers are byte for byte equal.
    assert(old.ebx = 1);
    assert(old.esi = 2);
    assert(old.edi = 3);
    assert(old == next);
    
    assert(g_old.ebx = 10);
    assert(g_old.esi = 11);
    assert(g_old.edi = 12);
    assert(g_old == g_next);
    
    writefln("Registers passed!");
}


unittest
{
    writefln("Testing throwYield");
    
    int q0 = 0;
    
    StackContext st0 = new StackContext(
    delegate void()
    {
        q0++;
        StackContext.throwYield(new Exception("testing throw yield"));
        q0++;
    });
    
    try
    {
        st0.run();
        assert(false);
    }
    catch(Exception e)
    {
        e.print();
    }
    
    assert(q0 == 1);
    assert(st0.ready);
    
    st0.run();
    assert(q0 == 2);
    assert(st0.dead);
    
    writefln("throwYield passed!");
}

unittest
{
    writefln("Testing thread safety");
    
    int x = 0, y = 0;
    
    StackContext sc0 = new StackContext(
    {
        while(true)
        {
            x++;
            StackContext.yield;
        }
    });
    
    StackContext sc1 = new StackContext(
    {
        while(true)
        {
            y++;
            StackContext.yield;
        }
    });
    
    Thread t0 = new Thread(
    {
        for(int i=0; i<10000; i++)
            sc0.run();
        
        return 0;
    });
    
    Thread t1 = new Thread(
    {
        for(int i=0; i<10000; i++)
            sc1.run();
        
        return 0;
    });
    
    assert(sc0);
    assert(sc1);
    assert(t0);
    assert(t1);
    
    t0.start;
    t1.start;
    t0.wait;
    t1.wait;
    
    assert(x == 10000);
    assert(y == 10000);
    
    writefln("Thread safety passed!");
}

