/**
 * The semaphore module provides a general use semaphore for synchronization.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly
 */
module tango.core.sync.Semaphore;


public import tango.core.Exception : SyncException;

version( Win32 )
{
    private import tango.sys.win32.UserGdi;
}
else version( Posix )
{
    private import tango.core.sync.Config;
    private import tango.stdc.errno;
    private import tango.stdc.posix.pthread;
    private import tango.stdc.posix.semaphore;
}


////////////////////////////////////////////////////////////////////////////////
// Semaphore
//
// void wait();
// void notify();
// bool tryWait();
////////////////////////////////////////////////////////////////////////////////


/**
 * This class represents a general counting semaphore as concieved by Edsger
 * Dijkstra.  As per Mesa type monitors however, "signal" has been replaced
 * with "notify" to indicate that control is not transferred to the waiter when
 * a notification is sent.
 */
class Semaphore
{
    ////////////////////////////////////////////////////////////////////////////
    // Initialization
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Initializes a semaphore object with the specified initial count.
     *
     * Params:
     *  count = The initial count for the semaphore.
     *
     * Throws:
     *  SyncException on error.
     */
    this( uint count = 0 )
    {
        version( Win32 )
        {
            m_hndl = CreateSemaphoreA( null, count, int.max, null );
            if( m_hndl == m_hndl.init )
                throw new SyncException( "Unable to create semaphore" );
        }
        else version( Posix )
        {
            int rc = sem_init( &m_hndl, 0, count );
            if( rc )
                throw new SyncException( "Unable to create semaphore" );
        }
    }


    ~this()
    {
        version( Win32 )
        {
            BOOL rc = CloseHandle( m_hndl );
            assert( rc, "Unable to destroy semaphore" );
        }
        else version( Posix )
        {
            int rc = sem_destroy( &m_hndl );
            assert( !rc, "Unable to destroy semaphore" );
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // General Actions
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Wait until the current count is above zero, then atomically decrement
     * the count by one and return.
     *
     * Throws:
     *  SyncException on error.
     */
    void wait()
    {
        version( Win32 )
        {
            DWORD rc = WaitForSingleObject( m_hndl, INFINITE );
            if( rc != WAIT_OBJECT_0 )
                throw new SyncException( "Unable to wait for semaphore" );
        }
        else version( Posix )
        {
            while( true )
            {
                if( !sem_wait( &m_hndl ) )
                    return;
                if( errno != EINTR )
                    throw new SyncException( "Unable to wait for semaphore" );
            }
        }
    }


    /**
     * Suspends the calling thread until the current count moves above zero or
     * until the supplied time period has elapsed.  If the count moves above
     * zero in this interval, then atomically decrement the count by one and
     * return true.  Otherwise, return false.  The supplied period may be up to
     * a maximum of (uint.max - 1) milliseconds.
     *
     * Params:
     *  period = The number of seconds to wait.
     *
     * In:
     *  period must be less than (uint.max - 1) milliseconds.
     *
     * Returns:
     *  true if notified before the timeout and false if not.
     *
     * Throws:
     *  SyncException on error.
     */
    bool wait( double period )
    in
    {
        assert( period * 1000 + 0.1 < uint.max - 1);
    }
    body
    {
        version( Win32 )
        {
            DWORD t = cast(DWORD)(period * 1000 + 0.1);
            switch( WaitForSingleObject( m_hndl, t ) )
            {
            case WAIT_OBJECT_0:
                return true;
            case WAIT_TIMEOUT:
                return false;
            default:
                throw new SyncException( "Unable to wait for semaphore" );
            }
        }
        else version( Posix )
        {
            timespec t;

            getTimespec( t );
            adjTimespec( t, period );

            while( true )
            {
                if( !sem_timedwait( &m_hndl, &t ) )
                    return true;
                if( errno == ETIMEDOUT )
                    return false;
                if( errno != EINTR )
                    throw new SyncException( "Unable to wait for semaphore" );
            }
        }

        // -w trip
        return false;
    }


    /**
     * Atomically increment the current count by one.  This will notify one
     * waiter, if there are any in the queue.
     *
     * Throws:
     *  SyncException on error.
     */
    void notify()
    {
        version( Win32 )
        {
            if( !ReleaseSemaphore( m_hndl, 1, null ) )
                throw new SyncException( "Unable to notify semaphore" );
        }
        else version( Posix )
        {
            int rc = sem_post( &m_hndl );
            if( rc )
                throw new SyncException( "Unable to notify semaphore" );
        }
    }


    /**
     * If the current count is equal to zero, return.  Otherwise, atomically
     * decrement the count by one and return true.
     *
     * Returns:
     *  true if the count was above zero and false if not.
     *
     * Throws:
     *  SyncException on error.
     */
    bool tryWait()
    {
        version( Win32 )
        {
            switch( WaitForSingleObject( m_hndl, 0 ) )
            {
            case WAIT_OBJECT_0:
                return true;
            case WAIT_TIMEOUT:
                return false;
            default:
                throw new SyncException( "Unable to wait for semaphore" );
            }
        }
        else version( Posix )
        {
            while( true )
            {
                if( !sem_trywait( &m_hndl ) )
                    return true;
                if( errno == EAGAIN )
                    return false;
                if( errno != EINTR )
                    throw new SyncException( "Unable to wait for semaphore" );
            }
        }

        // -w trip
        return false;
    }


private:
    version( Win32 )
    {
        HANDLE  m_hndl;
    }
    else version( Posix )
    {
        sem_t   m_hndl;
    }
}


////////////////////////////////////////////////////////////////////////////////
// Unit Tests
////////////////////////////////////////////////////////////////////////////////


debug( UnitTest )
{
    private import tango.core.Thread;


    void testWait()
    {
        auto semaphore    = new Semaphore;
        int  numToProduce = 10;
        bool allProduced  = false;
        auto synProduced  = new Object;
        int  numConsumed  = 0;
        auto synConsumed  = new Object;
        int  numConsumers = 10;
        int  numComplete  = 0;
        auto synComplete  = new Object;

        void consumer()
        {
            while( true )
            {
                semaphore.wait();

                synchronized( synProduced )
                {
                    if( allProduced )
                        break;
                }

                synchronized( synConsumed )
                {
                    ++numConsumed;
                }
            }

            synchronized( synComplete )
            {
                ++numComplete;
            }
        }

        void producer()
        {
            assert( !semaphore.tryWait() );

            for( int i = 0; i < numToProduce; ++i )
            {
                semaphore.notify();
                Thread.yield();
            }

            synchronized( synProduced )
            {
                allProduced = true;
            }

            for( int i = 0; i < numConsumers; ++i )
            {
                semaphore.notify();
                Thread.yield();
            }

            for( int i = numConsumers * 10; i > 0; --i )
            {
                synchronized( synComplete )
                {
                    if( numComplete == numConsumers )
                        break;
                }
            }

            synchronized( synComplete )
            {
                assert( numComplete == numConsumers );
            }
            assert( numConsumed == numToProduce );

            assert( !semaphore.tryWait() );
            semaphore.notify();
            assert( semaphore.tryWait() );
            assert( !semaphore.tryWait() );
        }

        auto group = new ThreadGroup;

        for( int i = 0; i < numConsumers; ++i )
            group.create( &consumer );
        group.create( &producer );
        group.joinAll();
    }


    void testWaitTimeout()
    {
        auto synReady   = new Object;
        auto semReady   = new Semaphore;
        bool waiting    = false;
        bool alertedOne = true;
        bool alertedTwo = true;

        void waiter()
        {
            synchronized( synReady )
            {
                waiting    = true;
            }
            alertedOne = semReady.wait( 0.1 );
            alertedTwo = semReady.wait( 0.1 );
        }

        auto thread = new Thread( &waiter );
        thread.start();

        while( true )
        {
            synchronized( synReady )
            {
                if( waiting )
                {
                    semReady.notify();
                    break;
                }
            }
            Thread.yield();
        }
        thread.join();
        assert( waiting && alertedOne && !alertedTwo );
    }


    unittest
    {
        testWait();
        testWaitTimeout();
    }
}
