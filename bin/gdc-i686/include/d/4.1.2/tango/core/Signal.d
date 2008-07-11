/**
 * The signal module provides a basic implementation of the listener pattern
 * using the "Signals and Slots" model from Qt.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly
 */
module tango.core.Signal;


private import tango.core.Array;


/**
 * A signal is an event which contains a collection of listeners (called
 * slots).  When a signal is called, that call will be propagated to each
 * attached slot in a synchronous manner.  It is legal for a slot to call a
 * signal's attach and detach methods when it is signaled.  When this occurs,
 * attach events will be queued and processed after the signal has propagated
 * to all slots, but detach events are processed immediately.  This ensures
 * that it is safe for slots to be deleted at any time, even within a slot
 * routine.
 *
 * Example:
 * -----------------------------------------------------------------------------
 *
 * class Button
 * {
 *     Signal!(Button) press;
 * }
 *
 * void wasPressed( Button b )
 * {
 *     printf( "Button was pressed.\n" );
 * }
 *
 * Button b = new Button;
 *
 * b.press.attach( &wasPressed );
 * b.press( b );
 *
 * -----------------------------------------------------------------------------
 *
 * Please note that this implementation does not use weak pointers to store
 * references to slots.  This design was chosen because weak pointers are
 * inherently unsafe when combined with non-deterministic destruction, with
 * many of the same limitations as destructors in the same situation.  It is
 * still possible to obtain weak-pointer behavior, but this must be done
 * through a proxy object instead.
 */
struct Signal( Args... )
{
    alias void delegate(Args) SlotDg; ///
    alias void function(Args) SlotFn; ///

    alias opCall call; /// Alias to simplify chained calling.


    /**
     * The signal procedure.  When called, each of the attached slots will be
     * called synchronously.
     *
     * args = The signal arguments.
     */
    void opCall( Args args )
    {
        synchronized
        {
            m_blk = true;

            for( size_t i = 0; i < m_dgs.length; ++i )
            {
                if( m_dgs[i] !is null )
                    m_dgs[i]( args );
            }
            m_dgs.length = m_dgs.remove( cast(SlotDg) null );

            for( size_t i = 0; i < m_fns.length; ++i )
            {
                if( m_fns[i] !is null )
                    m_fns[i]( args );
            }
            m_fns.length = m_fns.remove( cast(SlotFn) null );

            m_blk = false;

            procAdds();
        }
    }


    /**
     * Attaches a delegate to this signal.  A delegate may be either attached
     * or detached, so successive calls to attach for the same delegate will
     * have no effect.
     *
     * dg = The delegate to attach.
     */
    void attach( SlotDg dg )
    {
        synchronized
        {
            if( m_blk )
            {
                m_add ~= Add( dg );
            }
            else
            {
                auto pos = m_dgs.find( dg );
                if( pos == m_dgs.length )
                    m_dgs ~= dg;
            }
        }
    }


    /**
     * Attaches a function to this signal.  A function may be either attached
     * or detached, so successive calls to attach for the same function will
     * have no effect.
     *
     * fn = The function to attach.
     */
    void attach( SlotFn fn )
    {
        synchronized
        {
            if( m_blk )
            {
                m_add ~= Add( fn );
            }
            else
            {
                auto pos = m_fns.find( fn );
                if( pos == m_fns.length )
                    m_fns ~= fn;
            }
        }
    }


    /**
     * Detaches a delegate from this signal.
     *
     * dg = The delegate to detach.
     */
    void detach( SlotDg dg )
    {
        synchronized
        {
            auto pos = m_dgs.find( dg );
            if( pos < m_dgs.length )
                m_dgs[pos] = null;
        }
    }


    /**
     * Detaches a function from this signal.
     *
     * fn = The function to detach.
     */
    void detach( SlotFn fn )
    {
        synchronized
        {
            auto pos = m_fns.find( fn );
            if( pos < m_fns.length )
                m_fns[pos] = null;
        }
    }


private:
    struct Add
    {
        enum Type
        {
            DG,
            FN
        }

        static Add opCall( SlotDg d )
        {
            Add e;
            e.ty = Type.DG;
            e.dg = d;
            return e;
        }

        static Add opCall( SlotFn f )
        {
            Add e;
            e.ty = Type.FN;
            e.fn = f;
            return e;
        }

        union
        {
            SlotDg  dg;
            SlotFn  fn;
        }
        Type        ty;
    }


    void procAdds()
    {
        foreach( a; m_add )
        {
            if( a.ty == Add.Type.DG )
                m_dgs ~= a.dg;
            else
                m_fns ~= a.fn;
        }
        m_add.length = 0;
    }


    SlotDg[]    m_dgs;
    SlotFn[]    m_fns;
    Add[]       m_add;
    bool        m_blk;
}


debug( UnitTest )
{
  unittest
  {
    class Button
    {
        Signal!(Button) press;
    }

    int count = 0;

    void wasPressedA( Button b )
    {
        ++count;
    }

    void wasPressedB( Button b )
    {
        ++count;
    }

    Button b = new Button;

    b.press.attach( &wasPressedA );
    b.press( b );
    assert( count == 1 );

    count = 0;
    b.press.attach( &wasPressedB );
    b.press( b );
    assert( count == 2 );

    count = 0;
    b.press.attach( &wasPressedA );
    b.press( b );
    assert( count == 2 );

    count = 0;
    b.press.detach( &wasPressedB );
    b.press( b );
    assert( count == 1 );

    count = 0;
    b.press.detach( &wasPressedA );
    b.press( b );
    assert( count == 0 );
  }
}
