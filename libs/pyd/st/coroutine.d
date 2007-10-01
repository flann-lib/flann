/* *** Automatically generated: do not modify *** */
/**
 * This module contains a simple implementation of coroutines, based on the
 * StackContext module.  It supports both eagerly and non-eagerly evaluating
 * coroutines, and coroutines with anywhere from zero to five initial
 * arguments.
 *
 * If you define your coroutine as being both eager, and with an input type of
 * void, then the coroutine will be usable as an iterator in foreach
 * statements.
 *
 * Version:     0.1
 * Date:        2006-06-05
 * Copyright:   Copyright © 2006 Daniel Keep.
 * Authors:     Daniel Keep, daniel.keep+spam@gmail.com
 * License:     zlib
 *
 * Bugs:
 *   None (yet).  Well, ok; none that I *know* about.
 *
 * History:
 *   0.1 -  Initial version.
 */
module st.coroutine;

/*
 * This software is provided 'as-is', without any express or implied
 * warranty. In no event will the authors be held liable for any damages
 * arising from the use of this software.
 * 
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 * 
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software in
 *    a product, an acknowledgement in the product documentation would be
 *    appreciated but is not required.
 * 
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 
 * 3. This notice may not be removed or altered from any source distribution.
 */

private
{
    import st.stackcontext;
}

/**
 * This enumeration defines what kind of coroutine you want.
 */
enum
CoroType
{
    /**
     * This is the default.  Coroutines evaluate successive values on-demand.
     */
    NonEager,

    /**
     * Eager coroutines will evaluate the next value in the sequence before
     * being asked.  This is required for iterator support.
     */
    Eager
}

private
template
CoroutinePublicT(Tin, Tout, CoroType TCoroType)
{
    /// Records what kind of coroutine this is.
    const CoroType coroType = TCoroType;

    static if( is( Tin == void ) )
    {
        /**
         * Resumes the coroutine.
         *
         * Params:
         *  value = This value will be passed into the coroutine.
         *
         * Returns:
         *  The next value from the coroutine.
         */
        final
        Tout
        opCall()
        in
        {
            static if( coroType == CoroType.Eager )
                assert( this.running );
            else
                assert( context.ready );
        }
        body
        {
            static if( coroType == CoroType.Eager )
            {
                static if( !is( Tout == void ) )
                    Tout temp = this.cout;

                context.run();
                if( context.dead )
                    this.running = false;

                static if( !is( Tout == void ) )
                    return temp;
            }
            else
            {
                context.run();
                static if( !is( Tout == void ) )
                    return this.cout;
            }
        }
    }
    else
    {
        /**
         * Resumes the coroutine.
         *
         * Params:
         *  value = This value will be passed into the coroutine.
         *
         * Returns:
         *  The next value from the coroutine.
         */
        final
        Tout
        opCall(Tin value)
        in
        {
            static if( coroType == CoroType.Eager )
                assert( this.running );
            else
                assert( context.ready );
        }
        body
        {
            this.cin = value;

            static if( coroType == CoroType.Eager )
            {
                static if( !is( Tout == void ) )
                    Tout temp = this.cout;

                context.run();
                if( context.dead )
                    this.running = false;

                static if( !is( Tout == void ) )
                    return temp;
            }
            else
            {
                context.run();
                static if( !is( Tout == void ) )
                    return this.cout;
            }
        }
    }

    static if( is( Tin == void ) )
    {
        /**
         * Returns a delegate that can be used to resume the coroutine.
         *
         * Returns:
         *  A delegate that is equivalent to calling the coroutine directly.
         */
        Tout delegate()
        asDelegate()
        {
            return &opCall;
        }
    }
    else
    {
        /// ditto
        Tout delegate(Tin)
        asDelegate()
        {
            return &opCall;
        }
    }

    // TODO: Work out how to get iteration working with non-eager coroutines.
    static if( coroType == CoroType.Eager )
    {
        static if( is( Tin == void ) && !is( Tout == void ) )
        {
            final
            int
            opApply(int delegate(inout Tout) dg)
            {
                int result = 0;

                while( this.running )
                {
                    Tout argTemp = opCall();
                    result = dg(argTemp);
                    if( result )
                        break;
                }

                return result;
            }

            final
            int
            opApply(int delegate(inout Tout, inout uint) dg)
            {
                int result = 0;
                uint counter = 0;

                while( this.running )
                {
                    Tout argTemp = opCall();
                    uint counterTemp = counter;
                    result = dg(argTemp, counterTemp);
                    if( result )
                        break;
                }

                return result;
            }
        }
    }
}

private
template
CoroutineProtectedT(Tin, Tout, CoroType TCoroType)
{
    size_t STACK_SIZE = DEFAULT_STACK_SIZE;

    static if( is( Tout == void ) )
    {
        final
        Tin
        yield()
        in
        {
            assert( StackContext.getRunning is context );
        }
        body
        {
            StackContext.yield();
            static if( is( Tin == void ) ) {}
            else
                return this.cin;
        }
    }
    else
    {
        final
        Tin
        yield(Tout value)
        in
        {
            assert( StackContext.getRunning is context );
        }
        body
        {
            this.cout = value;
            StackContext.yield();
            static if( is( Tin == void ) ) {}
            else
                return this.cin;
        }
    }
}

/**
 * TODO
 */
class
Coroutine(Tin, Tout, CoroType TCoroType = CoroType.NonEager)
{
    mixin CoroutinePublicT!(Tin, Tout, TCoroType);

protected:
    mixin CoroutineProtectedT!(Tin, Tout, TCoroType);

    this()
    {
        
        context = new StackContext(&startProc, STACK_SIZE);
        static if( coroType == CoroType.Eager )
            context.run();
    }

    abstract
    void
    run();

private:
    StackContext context;
    
    static if( coroType == CoroType.Eager )
        bool running = true;

    static if( !is( Tout == void ) )
        Tout cout;

    static if( !is( Tin == void ) )
        Tin cin;

    

    void
    startProc()
    {
        // Initial call to coroutine proper
        run();
    }
}

/**
 * TODO
 */
class
Coroutine(Tin, Tout, Ta1, CoroType TCoroType = CoroType.NonEager)
{
    mixin CoroutinePublicT!(Tin, Tout, TCoroType);

protected:
    mixin CoroutineProtectedT!(Tin, Tout, TCoroType);

    this(Ta1 arg1)
    {
        this.arg1 = arg1;
        context = new StackContext(&startProc, STACK_SIZE);
        static if( coroType == CoroType.Eager )
            context.run();
    }

    abstract
    void
    run(Ta1);

private:
    StackContext context;
    
    static if( coroType == CoroType.Eager )
        bool running = true;

    static if( !is( Tout == void ) )
        Tout cout;

    static if( !is( Tin == void ) )
        Tin cin;

    Ta1 arg1;

    void
    startProc()
    {
        // Initial call to coroutine proper
        run(arg1);
    }
}

/**
 * TODO
 */
class
Coroutine(Tin, Tout, Ta1, Ta2, CoroType TCoroType = CoroType.NonEager)
{
    mixin CoroutinePublicT!(Tin, Tout, TCoroType);

protected:
    mixin CoroutineProtectedT!(Tin, Tout, TCoroType);

    this(Ta1 arg1, Ta2 arg2)
    {
        this.arg1 = arg1;
        this.arg2 = arg2;
        context = new StackContext(&startProc, STACK_SIZE);
        static if( coroType == CoroType.Eager )
            context.run();
    }

    abstract
    void
    run(Ta1, Ta2);

private:
    StackContext context;
    
    static if( coroType == CoroType.Eager )
        bool running = true;

    static if( !is( Tout == void ) )
        Tout cout;

    static if( !is( Tin == void ) )
        Tin cin;

    Ta1 arg1;
    Ta2 arg2;

    void
    startProc()
    {
        // Initial call to coroutine proper
        run(arg1, arg2);
    }
}

/**
 * TODO
 */
class
Coroutine(Tin, Tout, Ta1, Ta2, Ta3, CoroType TCoroType = CoroType.NonEager)
{
    mixin CoroutinePublicT!(Tin, Tout, TCoroType);

protected:
    mixin CoroutineProtectedT!(Tin, Tout, TCoroType);

    this(Ta1 arg1, Ta2 arg2, Ta3 arg3)
    {
        this.arg1 = arg1;
        this.arg2 = arg2;
        this.arg3 = arg3;
        context = new StackContext(&startProc, STACK_SIZE);
        static if( coroType == CoroType.Eager )
            context.run();
    }

    abstract
    void
    run(Ta1, Ta2, Ta3);

private:
    StackContext context;
    
    static if( coroType == CoroType.Eager )
        bool running = true;

    static if( !is( Tout == void ) )
        Tout cout;

    static if( !is( Tin == void ) )
        Tin cin;

    Ta1 arg1;
    Ta2 arg2;
    Ta3 arg3;

    void
    startProc()
    {
        // Initial call to coroutine proper
        run(arg1, arg2, arg3);
    }
}

/**
 * TODO
 */
class
Coroutine(Tin, Tout, Ta1, Ta2, Ta3, Ta4, CoroType TCoroType = CoroType.NonEager)
{
    mixin CoroutinePublicT!(Tin, Tout, TCoroType);

protected:
    mixin CoroutineProtectedT!(Tin, Tout, TCoroType);

    this(Ta1 arg1, Ta2 arg2, Ta3 arg3, Ta4 arg4)
    {
        this.arg1 = arg1;
        this.arg2 = arg2;
        this.arg3 = arg3;
        this.arg4 = arg4;
        context = new StackContext(&startProc, STACK_SIZE);
        static if( coroType == CoroType.Eager )
            context.run();
    }

    abstract
    void
    run(Ta1, Ta2, Ta3, Ta4);

private:
    StackContext context;
    
    static if( coroType == CoroType.Eager )
        bool running = true;

    static if( !is( Tout == void ) )
        Tout cout;

    static if( !is( Tin == void ) )
        Tin cin;

    Ta1 arg1;
    Ta2 arg2;
    Ta3 arg3;
    Ta4 arg4;

    void
    startProc()
    {
        // Initial call to coroutine proper
        run(arg1, arg2, arg3, arg4);
    }
}

/**
 * TODO
 */
class
Coroutine(Tin, Tout, Ta1, Ta2, Ta3, Ta4, Ta5, CoroType TCoroType = CoroType.NonEager)
{
    mixin CoroutinePublicT!(Tin, Tout, TCoroType);

protected:
    mixin CoroutineProtectedT!(Tin, Tout, TCoroType);

    this(Ta1 arg1, Ta2 arg2, Ta3 arg3, Ta4 arg4, Ta5 arg5)
    {
        this.arg1 = arg1;
        this.arg2 = arg2;
        this.arg3 = arg3;
        this.arg4 = arg4;
        this.arg5 = arg5;
        context = new StackContext(&startProc, STACK_SIZE);
        static if( coroType == CoroType.Eager )
            context.run();
    }

    abstract
    void
    run(Ta1, Ta2, Ta3, Ta4, Ta5);

private:
    StackContext context;
    
    static if( coroType == CoroType.Eager )
        bool running = true;

    static if( !is( Tout == void ) )
        Tout cout;

    static if( !is( Tin == void ) )
        Tin cin;

    Ta1 arg1;
    Ta2 arg2;
    Ta3 arg3;
    Ta4 arg4;
    Ta5 arg5;

    void
    startProc()
    {
        // Initial call to coroutine proper
        run(arg1, arg2, arg3, arg4, arg5);
    }
}


/**
 * This mixin implements the constructor, and static opCall method for your
 * coroutine.  It is a good idea to mix this into your coroutine subclasses,
 * so that you need only override the run method.
 */
template
CoroutineMixin(Tin, Tout)
{
    this()
    {
        super();
    }
}

/**
 * This mixin implements the constructor, and static opCall method for your
 * coroutine.  It is a good idea to mix this into your coroutine subclasses,
 * so that you need only override the run method.
 */
template
CoroutineMixin(Tin, Tout, Ta1)
{
    this(Ta1 arg1)
    {
        super(arg1);
    }
}

/**
 * This mixin implements the constructor, and static opCall method for your
 * coroutine.  It is a good idea to mix this into your coroutine subclasses,
 * so that you need only override the run method.
 */
template
CoroutineMixin(Tin, Tout, Ta1, Ta2)
{
    this(Ta1 arg1, Ta2 arg2)
    {
        super(arg1, arg2);
    }
}

/**
 * This mixin implements the constructor, and static opCall method for your
 * coroutine.  It is a good idea to mix this into your coroutine subclasses,
 * so that you need only override the run method.
 */
template
CoroutineMixin(Tin, Tout, Ta1, Ta2, Ta3)
{
    this(Ta1 arg1, Ta2 arg2, Ta3 arg3)
    {
        super(arg1, arg2, arg3);
    }
}

/**
 * This mixin implements the constructor, and static opCall method for your
 * coroutine.  It is a good idea to mix this into your coroutine subclasses,
 * so that you need only override the run method.
 */
template
CoroutineMixin(Tin, Tout, Ta1, Ta2, Ta3, Ta4)
{
    this(Ta1 arg1, Ta2 arg2, Ta3 arg3, Ta4 arg4)
    {
        super(arg1, arg2, arg3, arg4);
    }
}

/**
 * This mixin implements the constructor, and static opCall method for your
 * coroutine.  It is a good idea to mix this into your coroutine subclasses,
 * so that you need only override the run method.
 */
template
CoroutineMixin(Tin, Tout, Ta1, Ta2, Ta3, Ta4, Ta5)
{
    this(Ta1 arg1, Ta2 arg2, Ta3 arg3, Ta4 arg4, Ta5 arg5)
    {
        super(arg1, arg2, arg3, arg4, arg5);
    }
}


