/**
 * The atomic module is intended to provide some basic support for lock-free
 * concurrent programming.  Some common operations are defined, each of which
 * may be performed using the specified memory barrier or a less granular
 * barrier if the hardware does not support the version requested.  This
 * model is based on a design by Alexander Terekhov as outlined in
 * <a href=http://groups.google.com/groups?threadm=3E4820EE.6F408B25%40web.de>
 * this thread</a>.  Another useful reference for memory ordering on modern
 * architectures is <a href=http://www.linuxjournal.com/article/8211>this
 * article by Paul McKenney</a>.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly
 */
module tango.core.Atomic;


////////////////////////////////////////////////////////////////////////////////
// Synchronization Options
////////////////////////////////////////////////////////////////////////////////


/**
 * Memory synchronization flag.  If the supplied option is not available on the
 * current platform then a stronger method will be used instead.
 */
enum msync
{
    raw,    /// not sequenced
    hlb,    /// hoist-load barrier
    hsb,    /// hoist-store barrier
    slb,    /// sink-load barrier
    ssb,    /// sink-store barrier
    acq,    /// hoist-load + hoist-store barrier
    rel,    /// sink-load + sink-store barrier
    seq,    /// fully sequenced (acq + rel)
}


////////////////////////////////////////////////////////////////////////////////
// Internal Type Checking
////////////////////////////////////////////////////////////////////////////////


private
{
    version( DDoc ) {} else
    {
        import tango.core.Traits;


        template isValidAtomicType( T )
        {
            const bool isValidAtomicType = T.sizeof == byte.sizeof  ||
                                           T.sizeof == short.sizeof ||
                                           T.sizeof == int.sizeof   ||
                                           T.sizeof == long.sizeof;
        }


        template isValidNumericType( T )
        {
            const bool isValidNumericType = isIntegerType!( T ) ||
                                            isPointerType!( T );
        }


        template isHoistOp( msync ms )
        {
            const bool isHoistOp = ms == msync.hlb ||
                                   ms == msync.hsb ||
                                   ms == msync.acq ||
                                   ms == msync.seq;
        }


        template isSinkOp( msync ms )
        {
            const bool isSinkOp = ms == msync.slb ||
                                  ms == msync.ssb ||
                                  ms == msync.rel ||
                                  ms == msync.seq;
        }
    }
}


////////////////////////////////////////////////////////////////////////////////
// DDoc Documentation for Atomic Functions
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    ////////////////////////////////////////////////////////////////////////////
    // Atomic Load
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Supported msync values:
     *  msync.raw
     *  msync.hlb
     *  msync.acq
     *  msync.seq
     */
    template atomicLoad( msync ms, T )
    {
        /**
         * Refreshes the contents of 'val' from main memory.  This operation is
         * both lock-free and atomic.
         *
         * Params:
         *  val = The value to load.  This value must be properly aligned.
         *
         * Returns:
         *  The loaded value.
         */
        T atomicLoad( inout T val )
        {
            return val;
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // Atomic Store
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Supported msync values:
     *  msync.raw
     *  msync.ssb
     *  msync.acq
     *  msync.rel
     *  msync.seq
     */
    template atomicStore( msync ms, T )
    {
        /**
         * Stores 'newval' to the memory referenced by 'val'.  This operation
         * is both lock-free and atomic.
         *
         * Params:
         *  val     = The destination variable.
         *  newval  = The value to store.
         */
        void atomicStore( inout T val, T newval )
        {

        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // Atomic StoreIf
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Supported msync values:
     *  msync.raw
     *  msync.ssb
     *  msync.acq
     *  msync.rel
     *  msync.seq
     */
    template atomicStoreIf( msync ms, T )
    {
        /**
         * Stores 'newval' to the memory referenced by 'val' if val is equal to
         * 'equalTo'.  This operation is both lock-free and atomic.
         *
         * Params:
         *  val     = The destination variable.
         *  newval  = The value to store.
         *  equalTo = The comparison value.
         *
         * Returns:
         *  true if the store occurred, false if not.
         */
        bool atomicStoreIf( inout T val, T newval, T equalTo )
        {
            return false;
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // Atomic Increment
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Supported msync values:
     *  msync.raw
     *  msync.ssb
     *  msync.acq
     *  msync.rel
     *  msync.seq
     */
    template atomicIncrement( msync ms, T )
    {
        /**
         * This operation is only legal for built-in value and pointer types,
         * and is equivalent to an atomic "val = val + 1" operation.  This
         * function exists to facilitate use of the optimized increment
         * instructions provided by some architecures.  If no such instruction
         * exists on the target platform then the behavior will perform the
         * operation using more traditional means.  This operation is both
         * lock-free and atomic.
         *
         * Params:
         *  val = The value to increment.
         *
         * Returns:
         *  The result of an atomicLoad of val immediately following the
         *  increment operation.  This value is not required to be equal to the
         *  newly stored value.  Thus, competing writes are allowed to occur
         *  between the increment and successive load operation.
         */
        T atomicIncrement( inout T val )
        {
            return val;
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // Atomic Decrement
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Supported msync values:
     *  msync.raw
     *  msync.ssb
     *  msync.acq
     *  msync.rel
     *  msync.seq
     */
    template atomicDecrement( msync ms, T )
    {
        /**
         * This operation is only legal for built-in value and pointer types,
         * and is equivalent to an atomic "val = val - 1" operation.  This
         * function exists to facilitate use of the optimized decrement
         * instructions provided by some architecures.  If no such instruction
         * exists on the target platform then the behavior will perform the
         * operation using more traditional means.  This operation is both
         * lock-free and atomic.
         *
         * Params:
         *  val = The value to decrement.
         *
         * Returns:
         *  The result of an atomicLoad of val immediately following the
         *  increment operation.  This value is not required to be equal to the
         *  newly stored value.  Thus, competing writes are allowed to occur
         *  between the increment and successive load operation.
         */
        T atomicDecrement( inout T val )
        {
            return val;
        }
    }
}


////////////////////////////////////////////////////////////////////////////////
// x86 Atomic Function Implementation
////////////////////////////////////////////////////////////////////////////////


else version( D_InlineAsm_X86 )
{
    version( X86 )
    {
        version( BuildInfo )
        {
            pragma( msg, "tango.core.Atomic: using IA-32 inline asm" );
        }

        version = Has32BitOps;
        version = Has64BitCAS;
    }
    version( X86_64 )
    {
        version( BuildInfo )
        {
            pragma( msg, "tango.core.Atomic: using AMD64 inline asm" );
        }

        version = Has64BitOps;
    }

    private
    {
        ////////////////////////////////////////////////////////////////////////
        // x86 Value Requirements
        ////////////////////////////////////////////////////////////////////////


        // NOTE: Strictly speaking, the x86 supports atomic operations on
        //       unaligned values.  However, this is far slower than the
        //       common case, so such behavior should be prohibited.
        template atomicValueIsProperlyAligned( T )
        {
            bool atomicValueIsProperlyAligned( size_t addr )
            {
                return addr % T.sizeof == 0;
            }
        }


        ////////////////////////////////////////////////////////////////////////
        // x86 Synchronization Requirements
        ////////////////////////////////////////////////////////////////////////


        // NOTE: While x86 loads have acquire semantics for stores, it appears
        //       that independent loads may be reordered by some processors
        //       (notably the AMD64).  This implies that the hoist-load barrier
        //       op requires an ordering instruction, which also extends this
        //       requirement to acquire ops (though hoist-store should not need
        //       one if support is added for this later).  However, since no
        //       modern architectures will reorder dependent loads to occur
        //       before the load they depend on (except the Alpha), raw loads
        //       are actually a possible means of ordering specific sequences
        //       of loads in some instances.  The original atomic<>
        //       implementation provides a 'ddhlb' ordering specifier for
        //       data-dependent loads to handle this situation, but as there
        //       are no plans to support the Alpha there is no reason to add
        //       that option here.
        //
        //       For reference, the old behavior (acquire semantics for loads)
        //       required a memory barrier if: ms == msync.seq || isSinkOp!(ms)
        template needsLoadBarrier( msync ms )
        {
            const bool needsLoadBarrier = ms != msync.raw;
        }


        // NOTE: x86 stores implicitly have release semantics so a membar is only
        //       necessary on acquires.
        template needsStoreBarrier( msync ms )
        {
            const bool needsStoreBarrier = ms == msync.seq || isHoistOp!(ms);
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // Atomic Load
    ////////////////////////////////////////////////////////////////////////////


    template atomicLoad( msync ms = msync.seq, T )
    {
        T atomicLoad( inout T val )
        in
        {
            assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
        }
        body
        {
            static if( T.sizeof == byte.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 1 Byte Load
                ////////////////////////////////////////////////////////////////


                static if( needsLoadBarrier!(ms) )
                {
                    volatile asm
                    {
                        mov BL, 42;
                        mov AL, 42;
                        mov ECX, val;
                        lock;
                        cmpxchg [ECX], BL;
                    }
                }
                else
                {
                    volatile
                    {
                        return val;
                    }
                }
            }
            else static if( T.sizeof == short.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 2 Byte Load
                ////////////////////////////////////////////////////////////////

                static if( needsLoadBarrier!(ms) )
                {
                    volatile asm
                    {
                        mov BX, 42;
                        mov AX, 42;
                        mov ECX, val;
                        lock;
                        cmpxchg [ECX], BX;
                    }
                }
                else
                {
                    volatile
                    {
                        return val;
                    }
                }
            }
            else static if( T.sizeof == int.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 4 Byte Load
                ////////////////////////////////////////////////////////////////


                static if( needsLoadBarrier!(ms) )
                {
                    volatile asm
                    {
                        mov EBX, 42;
                        mov EAX, 42;
                        mov ECX, val;
                        lock;
                        cmpxchg [ECX], EBX;
                    }
                }
                else
                {
                    volatile
                    {
                        return val;
                    }
                }
            }
            else static if( T.sizeof == long.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 8 Byte Load
                ////////////////////////////////////////////////////////////////


                version( Has64BitOps )
                {
                    ////////////////////////////////////////////////////////////
                    // 8 Byte Load on 64-Bit Processor
                    ////////////////////////////////////////////////////////////


                    static if( needsLoadBarrier!(ms) )
                    {
                        volatile asm
                        {
                            mov RAX, val;
                            lock;
                            mov RAX, [RAX];
                        }
                    }
                    else
                    {
                        volatile
                        {
                            return val;
                        }
                    }
                }
                else
                {
                    ////////////////////////////////////////////////////////////
                    // 8 Byte Load on 32-Bit Processor
                    ////////////////////////////////////////////////////////////


                    pragma( msg, "This operation is only available on 64-bit platforms." );
                    static assert( false );
                }
            }
            else
            {
                ////////////////////////////////////////////////////////////////
                // Not a 1, 2, 4, or 8 Byte Type
                ////////////////////////////////////////////////////////////////


                pragma( msg, "Invalid template type specified." );
                static assert( false );
            }
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // Atomic Store
    ////////////////////////////////////////////////////////////////////////////


    template atomicStore( msync ms = msync.seq, T )
    {
        void atomicStore( inout T val, T newval )
        in
        {
            assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
        }
        body
        {
            static if( T.sizeof == byte.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 1 Byte Store
                ////////////////////////////////////////////////////////////////


                static if( needsStoreBarrier!(ms) )
                {
                    volatile asm
                    {
                        mov EAX, val;
                        mov BL, newval;
                        lock;
                        xchg [EAX], BL;
                    }
                }
                else
                {
                    volatile asm
                    {
                        mov EAX, val;
                        mov BL, newval;
                        mov [EAX], BL;
                    }
                }
            }
            else static if( T.sizeof == short.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 2 Byte Store
                ////////////////////////////////////////////////////////////////


                static if( needsStoreBarrier!(ms) )
                {
                    volatile asm
                    {
                        mov EAX, val;
                        mov BX, newval;
                        lock;
                        xchg [EAX], BX;
                    }
                }
                else
                {
                    volatile asm
                    {
                        mov EAX, val;
                        mov BX, newval;
                        mov [EAX], BX;
                    }
                }
            }
            else static if( T.sizeof == int.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 4 Byte Store
                ////////////////////////////////////////////////////////////////


                static if( needsStoreBarrier!(ms) )
                {
                    volatile asm
                    {
                        mov EAX, val;
                        mov EBX, newval;
                        lock;
                        xchg [EAX], EBX;
                    }
                }
                else
                {
                    volatile asm
                    {
                        mov EAX, val;
                        mov EBX, newval;
                        mov [EAX], EBX;
                    }
                }
            }
            else static if( T.sizeof == long.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 8 Byte Store
                ////////////////////////////////////////////////////////////////


                version( Has64BitOps )
                {
                    ////////////////////////////////////////////////////////////
                    // 8 Byte Store on 64-Bit Processor
                    ////////////////////////////////////////////////////////////


                    static if( needsStoreBarrier!(ms) )
                    {
                        volatile asm
                        {
                            mov RAX, val;
                            mov RBX, newval;
                            lock;
                            xchg [RAX], RBX;
                        }
                    }
                    else
                    {
                        volatile asm
                        {
                            mov RAX, val;
                            mov RBX, newval;
                            mov [RAX], RBX;
                        }
                    }
                }
                else
                {
                    ////////////////////////////////////////////////////////////
                    // 8 Byte Store on 32-Bit Processor
                    ////////////////////////////////////////////////////////////


                    pragma( msg, "This operation is only available on 64-bit platforms." );
                    static assert( false );
                }
            }
            else
            {
                ////////////////////////////////////////////////////////////////
                // Not a 1, 2, 4, or 8 Byte Type
                ////////////////////////////////////////////////////////////////


                pragma( msg, "Invalid template type specified." );
                static assert( false );
            }
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // Atomic Store If
    ////////////////////////////////////////////////////////////////////////////


    template atomicStoreIf( msync ms = msync.seq, T )
    {
        bool atomicStoreIf( inout T val, T newval, T equalTo )
        in
        {
            // NOTE: 32 bit x86 systems support 8 byte CAS, which only requires
            //       4 byte alignment, so use size_t as the align type here.
            static if( T.sizeof > size_t.sizeof )
                assert( atomicValueIsProperlyAligned!(size_t)( cast(size_t) &val ) );
            else
                assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
        }
        body
        {
            static if( T.sizeof == byte.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 1 Byte StoreIf
                ////////////////////////////////////////////////////////////////


                volatile asm
                {
                    mov BL, newval;
                    mov AL, equalTo;
                    mov ECX, val;
                    lock; // lock always needed to make this op atomic
                    cmpxchg [ECX], BL;
                    setz AL;
                }
            }
            else static if( T.sizeof == short.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 2 Byte StoreIf
                ////////////////////////////////////////////////////////////////


                volatile asm
                {
                    mov BX, newval;
                    mov AX, equalTo;
                    mov ECX, val;
                    lock; // lock always needed to make this op atomic
                    cmpxchg [ECX], BX;
                    setz AL;
                }
            }
            else static if( T.sizeof == int.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 4 Byte StoreIf
                ////////////////////////////////////////////////////////////////


                volatile asm
                {
                    mov EBX, newval;
                    mov EAX, equalTo;
                    mov ECX, val;
                    lock; // lock always needed to make this op atomic
                    cmpxchg [ECX], EBX;
                    setz AL;
                }
            }
            else static if( T.sizeof == long.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 8 Byte StoreIf
                ////////////////////////////////////////////////////////////////


                version( Has64BitOps )
                {
                    ////////////////////////////////////////////////////////////
                    // 8 Byte StoreIf on 64-Bit Processor
                    ////////////////////////////////////////////////////////////


                    volatile asm
                    {
                        mov RBX, newval;
                        mov RAX, equalTo;
                        mov RCX, val;
                        lock; // lock always needed to make this op atomic
                        cmpxchg [RCX], RBX;
                        setz AL;
                    }
                }
                else version( Has64BitCAS )
                {
                    ////////////////////////////////////////////////////////////
                    // 8 Byte StoreIf on 32-Bit Processor
                    ////////////////////////////////////////////////////////////


                    volatile asm
                    {
                        lea EDI, newval;
                        mov EBX, [EDI];
                        mov ECX, 4[EDI];
                        lea EDI, equalTo;
                        mov EAX, [EDI];
                        mov EDX, 4[EDI];
                        mov EDI, val;
                        lock; // lock always needed to make this op atomic
                        cmpxch8b [EDI];
                        setz AL;
                    }
                }
            }
            else
            {
                ////////////////////////////////////////////////////////////////
                // Not a 1, 2, 4, or 8 Byte Type
                ////////////////////////////////////////////////////////////////


                pragma( msg, "Invalid template type specified." );
                static assert( false );
            }
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // Atomic Increment
    ////////////////////////////////////////////////////////////////////////////


    template atomicIncrement( msync ms = msync.seq, T )
    {
        //
        // NOTE: This operation is only valid for integer or pointer types
        //
        static assert( isValidNumericType!(T) );


        T atomicIncrement( inout T val )
        in
        {
            assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
        }
        body
        {
            static if( T.sizeof == byte.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 1 Byte Increment
                ////////////////////////////////////////////////////////////////


                volatile asm
                {
                    mov EAX, val;
                    lock; // lock always needed to make this op atomic
                    inc [EAX];
                    mov AL, [EAX];
                }
            }
            else static if( T.sizeof == short.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 2 Byte Increment
                ////////////////////////////////////////////////////////////////


                volatile asm
                {
                    mov EAX, val;
                    lock; // lock always needed to make this op atomic
                    inc [EAX];
                    mov AX, [EAX];
                }
            }
            else static if( T.sizeof == int.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 4 Byte Increment
                ////////////////////////////////////////////////////////////////


                volatile asm
                {
                    mov EAX, val;
                    lock; // lock always needed to make this op atomic
                    inc [EAX];
                    mov EAX, [EAX];
                }
            }
            else static if( T.sizeof == long.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 8 Byte Increment
                ////////////////////////////////////////////////////////////////


                version( Has64BitOps )
                {
                    ////////////////////////////////////////////////////////////
                    // 8 Byte Increment on 64-Bit Processor
                    ////////////////////////////////////////////////////////////


                    volatile asm
                    {
                        mov RAX, val;
                        lock; // lock always needed to make this op atomic
                        inc [RAX];
                        mov RAX, [RAX];
                    }
                }
                else
                {
                    ////////////////////////////////////////////////////////////
                    // 8 Byte Increment on 32-Bit Processor
                    ////////////////////////////////////////////////////////////


                    pragma( msg, "This operation is only available on 64-bit platforms." );
                    static assert( false );
                }
            }
            else
            {
                ////////////////////////////////////////////////////////////////
                // Not a 1, 2, 4, or 8 Byte Type
                ////////////////////////////////////////////////////////////////


                pragma( msg, "Invalid template type specified." );
                static assert( false );
            }
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // Atomic Decrement
    ////////////////////////////////////////////////////////////////////////////


    template atomicDecrement( msync ms = msync.seq, T )
    {
        //
        // NOTE: This operation is only valid for integer or pointer types
        //
        static assert( isValidNumericType!(T) );


        T atomicDecrement( inout T val )
        in
        {
            assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
        }
        body
        {
            static if( T.sizeof == byte.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 1 Byte Decrement
                ////////////////////////////////////////////////////////////////


                volatile asm
                {
                    mov EAX, val;
                    lock; // lock always needed to make this op atomic
                    dec [EAX];
                    mov AL, [EAX];
                }
            }
            else static if( T.sizeof == short.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 2 Byte Decrement
                ////////////////////////////////////////////////////////////////


                volatile asm
                {
                    mov EAX, val;
                    lock; // lock always needed to make this op atomic
                    dec [EAX];
                    mov AX, [EAX];
                }
            }
            else static if( T.sizeof == int.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 4 Byte Decrement
                ////////////////////////////////////////////////////////////////


                volatile asm
                {
                    mov EAX, val;
                    lock; // lock always needed to make this op atomic
                    dec [EAX];
                    mov EAX, [EAX];
                }
            }
            else static if( T.sizeof == long.sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // 8 Byte Decrement
                ////////////////////////////////////////////////////////////////


                version( Has64BitOps )
                {
                    ////////////////////////////////////////////////////////////
                    // 8 Byte Decrement on 64-Bit Processor
                    ////////////////////////////////////////////////////////////


                    volatile asm
                    {
                        mov RAX, val;
                        lock; // lock always needed to make this op atomic
                        dec [RAX];
                        mov RAX, [RAX];
                    }
                }
                else
                {
                    ////////////////////////////////////////////////////////////
                    // 8 Byte Decrement on 32-Bit Processor
                    ////////////////////////////////////////////////////////////


                    pragma( msg, "This operation is only available on 64-bit platforms." );
                    static assert( false );
                }
            }
            else
            {
                ////////////////////////////////////////////////////////////////
                // Not a 1, 2, 4, or 8 Byte Type
                ////////////////////////////////////////////////////////////////


                pragma( msg, "Invalid template type specified." );
                static assert( false );
            }
        }
    }
}
else
{
    version( BuildInfo )
    {
        pragma( msg, "tango.core.Atomic: using synchronized ops" );
    }

    private
    {
        ////////////////////////////////////////////////////////////////////////
        // Default Value Requirements
        ////////////////////////////////////////////////////////////////////////


        template atomicValueIsProperlyAligned( T )
        {
            bool atomicValueIsProperlyAligned( size_t addr )
            {
                return addr % T.sizeof == 0;
            }
        }


        ////////////////////////////////////////////////////////////////////////
        // Default Synchronization Requirements
        ////////////////////////////////////////////////////////////////////////


        template needsLoadBarrier( msync ms )
        {
            const bool needsLoadBarrier = ms != msync.raw;
        }


        template needsStoreBarrier( msync ms )
        {
            const bool needsStoreBarrier = ms != msync.raw;
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // Atomic Load
    ////////////////////////////////////////////////////////////////////////////


    template atomicLoad( msync ms = msync.seq, T )
    {
        T atomicLoad( inout T val )
        in
        {
            assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
        }
        body
        {
            static if( T.sizeof <= (void*).sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // <= (void*).sizeof Byte Load
                ////////////////////////////////////////////////////////////////


                static if( needsLoadBarrier!(ms) )
                {
                    synchronized
                    {
                        return val;
                    }
                }
                else
                {
                    volatile
                    {
                        return val;
                    }
                }
            }
            else
            {
                ////////////////////////////////////////////////////////////////
                // > (void*).sizeof Byte Type
                ////////////////////////////////////////////////////////////////


                pragma( msg, "Invalid template type specified." );
                static assert( false );
            }
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // Atomic Store
    ////////////////////////////////////////////////////////////////////////////


    template atomicStore( msync ms = msync.seq, T )
    {
        void atomicStore( inout T val, T newval )
        in
        {
            assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
        }
        body
        {
            static if( T.sizeof <= (void*).sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // <= (void*).sizeof Byte Store
                ////////////////////////////////////////////////////////////////


                static if( needsStoreBarrier!(ms) )
                {
                    synchronized
                    {
                        val = newval;
                    }
                }
                else
                {
                    volatile
                    {
                        val = newval;
                    }
                }
            }
            else
            {
                ////////////////////////////////////////////////////////////////
                // > (void*).sizeof Byte Type
                ////////////////////////////////////////////////////////////////


                pragma( msg, "Invalid template type specified." );
                static assert( false );
            }
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // Atomic Store If
    ////////////////////////////////////////////////////////////////////////////


    template atomicStoreIf( msync ms = msync.seq, T )
    {
        bool atomicStoreIf( inout T val, T newval, T equalTo )
        in
        {
            assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
        }
        body
        {
            static if( T.sizeof <= (void*).sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // <= (void*).sizeof Byte StoreIf
                ////////////////////////////////////////////////////////////////


                synchronized
                {
                    if( val == equalTo )
                    {
                        val = newval;
                        return true;
                    }
                    return false;
                }
            }
            else
            {
                ////////////////////////////////////////////////////////////////
                // > (void*).sizeof Byte Type
                ////////////////////////////////////////////////////////////////


                pragma( msg, "Invalid template type specified." );
                static assert( false );
            }
        }
    }


    /////////////////////////////////////////////////////////////////////////////
    // Atomic Increment
    ////////////////////////////////////////////////////////////////////////////


    template atomicIncrement( msync ms = msync.seq, T )
    {
        //
        // NOTE: This operation is only valid for integer or pointer types
        //
        static assert( isValidNumericType!(T) );


        T atomicIncrement( inout T val )
        in
        {
            assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
        }
        body
        {
            static if( T.sizeof <= (void*).sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // <= (void*).sizeof Byte Increment
                ////////////////////////////////////////////////////////////////


                synchronized
                {
                    return ++val;
                }
            }
            else
            {
                ////////////////////////////////////////////////////////////////
                // > (void*).sizeof Byte Type
                ////////////////////////////////////////////////////////////////


                pragma( msg, "Invalid template type specified." );
                static assert( false );
            }
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // Atomic Decrement
    ////////////////////////////////////////////////////////////////////////////


    template atomicDecrement( msync ms = msync.seq, T )
    {
        //
        // NOTE: This operation is only valid for integer or pointer types
        //
        static assert( isValidNumericType!(T) );


        T atomicDecrement( inout T val )
        in
        {
            assert( atomicValueIsProperlyAligned!(T)( cast(size_t) &val ) );
        }
        body
        {
            static if( T.sizeof <= (void*).sizeof )
            {
                ////////////////////////////////////////////////////////////////
                // <= (void*).sizeof Byte Decrement
                ////////////////////////////////////////////////////////////////


                synchronized
                {
                    return --val;
                }
            }
            else
            {
                ////////////////////////////////////////////////////////////////
                // > (void*).sizeof Byte Type
                ////////////////////////////////////////////////////////////////


                pragma( msg, "Invalid template type specified." );
                static assert( false );
            }
        }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Atomic
////////////////////////////////////////////////////////////////////////////////


/**
 * This struct represents a value which will be subject to competing access.
 * All accesses to this value will be synchronized with main memory, and
 * various memory barriers may be employed for instruction ordering.  Any
 * primitive type of size equal to or smaller than the memory bus size is
 * allowed, so 32-bit machines may use values with size <= int.sizeof and
 * 64-bit machines may use values with size <= long.sizeof.  The one exception
 * to this rule is that architectures that support DCAS will allow double-wide
 * storeIf operations.  The 32-bit x86 architecture, for example, supports
 * 64-bit storeIf operations.
 */
struct Atomic( T )
{
    ////////////////////////////////////////////////////////////////////////////
    // Atomic Load
    ////////////////////////////////////////////////////////////////////////////


    template load( msync ms = msync.seq )
    {
        static assert( ms == msync.raw || ms == msync.hlb ||
                       ms == msync.acq || ms == msync.seq,
                       "ms must be one of: msync.raw, msync.hlb, msync.acq, msync.seq" );

        /**
         * Refreshes the contents of this value from main memory.  This
         * operation is both lock-free and atomic.
         *
         * Returns:
         *  The loaded value.
         */
        T load()
        {
            return atomicLoad!(ms,T)( m_val );
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // Atomic Store
    ////////////////////////////////////////////////////////////////////////////


    template store( msync ms = msync.seq )
    {
        static assert( ms == msync.raw || ms == msync.ssb ||
                       ms == msync.acq || ms == msync.rel ||
                       ms == msync.seq,
                       "ms must be one of: msync.raw, msync.ssb, msync.acq, msync.rel, msync.seq" );

        /**
         * Stores 'newval' to the memory referenced by this value.  This
         * operation is both lock-free and atomic.
         *
         * Params:
         *  newval  = The value to store.
         */
        void store( T newval )
        {
            atomicStore!(ms,T)( m_val, newval );
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // Atomic StoreIf
    ////////////////////////////////////////////////////////////////////////////


    template storeIf( msync ms = msync.seq )
    {
        static assert( ms == msync.raw || ms == msync.ssb ||
                       ms == msync.acq || ms == msync.rel ||
                       ms == msync.seq,
                       "ms must be one of: msync.raw, msync.ssb, msync.acq, msync.rel, msync.seq" );

        /**
         * Stores 'newval' to the memory referenced by this value if val is
         * equal to 'equalTo'.  This operation is both lock-free and atomic.
         *
         * Params:
         *  newval  = The value to store.
         *  equalTo = The comparison value.
         *
         * Returns:
         *  true if the store occurred, false if not.
         */
        bool storeIf( T newval, T equalTo )
        {
            return atomicStoreIf!(ms,T)( m_val, newval, equalTo );
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // Numeric Functions
    ////////////////////////////////////////////////////////////////////////////


    /**
     * The following additional functions are available for integer types.
     */
    static if( isValidNumericType!(T) )
    {
        ////////////////////////////////////////////////////////////////////////
        // Atomic Increment
        ////////////////////////////////////////////////////////////////////////


        template increment( msync ms = msync.seq )
        {
            static assert( ms == msync.raw || ms == msync.ssb ||
                           ms == msync.acq || ms == msync.rel ||
                           ms == msync.seq,
                           "ms must be one of: msync.raw, msync.ssb, msync.acq, msync.rel, msync.seq" );

            /**
             * This operation is only legal for built-in value and pointer
             * types, and is equivalent to an atomic "val = val + 1" operation.
             * This function exists to facilitate use of the optimized
             * increment instructions provided by some architecures.  If no
             * such instruction exists on the target platform then the
             * behavior will perform the operation using more traditional
             * means.  This operation is both lock-free and atomic.
             *
             * Returns:
             *  The result of an atomicLoad of val immediately following the
             *  increment operation.  This value is not required to be equal to
             *  the newly stored value.  Thus, competing writes are allowed to
             *  occur between the increment and successive load operation.
             */
            T increment()
            {
                return atomicIncrement!(ms,T)( m_val );
            }
        }


        ////////////////////////////////////////////////////////////////////////
        // Atomic Decrement
        ////////////////////////////////////////////////////////////////////////


        template decrement( msync ms = msync.seq )
        {
            static assert( ms == msync.raw || ms == msync.ssb ||
                           ms == msync.acq || ms == msync.rel ||
                           ms == msync.seq,
                           "ms must be one of: msync.raw, msync.ssb, msync.acq, msync.rel, msync.seq" );

            /**
             * This operation is only legal for built-in value and pointer
             * types, and is equivalent to an atomic "val = val - 1" operation.
             * This function exists to facilitate use of the optimized
             * decrement instructions provided by some architecures.  If no
             * such instruction exists on the target platform then the behavior
             * will perform the operation using more traditional means.  This
             * operation is both lock-free and atomic.
             *
             * Returns:
             *  The result of an atomicLoad of val immediately following the
             *  increment operation.  This value is not required to be equal to
             *  the newly stored value.  Thus, competing writes are allowed to
             *  occur between the increment and successive load operation.
             */
            T decrement()
            {
                return atomicDecrement!(ms,T)( m_val );
            }
        }
    }

private:
    T   m_val;
}


////////////////////////////////////////////////////////////////////////////////
// Support Code for Unit Tests
////////////////////////////////////////////////////////////////////////////////


private
{
    version( DDoc ) {} else
    {
        template testLoad( msync ms, T )
        {
            void testLoad( T val = T.init + 1 )
            {
                T          base;
                Atomic!(T) atom;

                assert( atom.load!(ms)() == base );
                base        = val;
                atom.m_val  = val;
                assert( atom.load!(ms)() == base );
            }
        }


        template testStore( msync ms, T )
        {
            void testStore( T val = T.init + 1 )
            {
                T          base;
                Atomic!(T) atom;

                assert( atom.m_val == base );
                base = val;
                atom.store!(ms)( base );
                assert( atom.m_val == base );
            }
        }


        template testStoreIf( msync ms, T )
        {
            void testStoreIf( T val = T.init + 1 )
            {
                T          base;
                Atomic!(T) atom;

                assert( atom.m_val == base );
                base = val;
                atom.storeIf!(ms)( base, val );
                assert( atom.m_val != base );
                atom.storeIf!(ms)( base, T.init );
                assert( atom.m_val == base );
            }
        }


        template testIncrement( msync ms, T )
        {
            void testIncrement( T val = T.init + 1 )
            {
                T          base = val;
                T          incr = val;
                Atomic!(T) atom;

                atom.m_val = val;
                assert( atom.m_val == base && incr == base );
                base = cast(T)( base + 1 );
                incr = atom.increment!(ms)();
                assert( atom.m_val == base && incr == base );
            }
        }


        template testDecrement( msync ms, T )
        {
            void testDecrement( T val = T.init + 1 )
            {
                T          base = val;
                T          decr = val;
                Atomic!(T) atom;

                atom.m_val = val;
                assert( atom.m_val == base && decr == base );
                base = cast(T)( base - 1 );
                decr = atom.decrement!(ms)();
                assert( atom.m_val == base && decr == base );
            }
        }


        template testType( T )
        {
            void testType( T val = T.init  +1 )
            {
                testLoad!(msync.raw, T)( val );
                testLoad!(msync.hlb, T)( val );
                testLoad!(msync.acq, T)( val );
                testLoad!(msync.seq, T)( val );

                testStore!(msync.raw, T)( val );
                testStore!(msync.ssb, T)( val );
                testStore!(msync.acq, T)( val );
                testStore!(msync.rel, T)( val );
                testStore!(msync.seq, T)( val );

                testStoreIf!(msync.raw, T)( val );
                testStoreIf!(msync.ssb, T)( val );
                testStoreIf!(msync.acq, T)( val );
                testStoreIf!(msync.rel, T)( val );
                testStoreIf!(msync.seq, T)( val );

                static if( isValidNumericType!(T) )
                {
                    testIncrement!(msync.raw, T)( val );
                    testIncrement!(msync.ssb, T)( val );
                    testIncrement!(msync.acq, T)( val );
                    testIncrement!(msync.rel, T)( val );
                    testIncrement!(msync.seq, T)( val );

                    testDecrement!(msync.raw, T)( val );
                    testDecrement!(msync.ssb, T)( val );
                    testDecrement!(msync.acq, T)( val );
                    testDecrement!(msync.rel, T)( val );
                    testDecrement!(msync.seq, T)( val );
                }
            }
        }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Unit Tests
////////////////////////////////////////////////////////////////////////////////


debug( UnitTest )
{
    unittest
    {
        testType!(bool)();

        testType!(byte)();
        testType!(ubyte)();

        testType!(short)();
        testType!(ushort)();

        testType!(int)();
        testType!(uint)();

        int x;
        testType!(void*)( &x );

        version( Has64BitOps )
        {
            testType!(long)();
            testType!(ulong)();
        }
        else version( Has64BitCAS )
        {
            testStoreIf!(msync.raw, long)();
            testStoreIf!(msync.ssb, long)();
            testStoreIf!(msync.acq, long)();
            testStoreIf!(msync.rel, long)();
            testStoreIf!(msync.seq, long)();

            testStoreIf!(msync.raw, ulong)();
            testStoreIf!(msync.ssb, ulong)();
            testStoreIf!(msync.acq, ulong)();
            testStoreIf!(msync.rel, ulong)();
            testStoreIf!(msync.seq, ulong)();
        }
    }
}
