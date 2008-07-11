/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Jan 2007: initial release
        
        author:         Kris 

*******************************************************************************/

module tango.io.protocol.model.IProtocol;

private import tango.io.model.IBuffer;

/*******************************************************************************
        
*******************************************************************************/

abstract class IProtocol
{
        enum Type
        {
                Void = 0,
                Utf8, 
                Bool,
                Byte,
                UByte,
                Utf16,
                Short,
                UShort,
                Utf32,
                Int,
                UInt,
                Float,
                Long,
                ULong,
                Double,
                Real,
                Obj,
                Pointer,
        }
        
        /***********************************************************************

        ***********************************************************************/

        alias void   delegate (void* src, uint bytes, Type type) Writer;
        alias void   delegate (void* src, uint bytes, Type type) ArrayWriter;

        alias void[] delegate (void* dst, uint bytes, Type type) Reader;
        alias void[] delegate (Reader reader, uint bytes, Type type) Allocator;

        alias void[] delegate (void* dst, uint bytes, Type type, Allocator) ArrayReader;
        
        /***********************************************************************

        ***********************************************************************/

        abstract IBuffer buffer ();

        /***********************************************************************

        ***********************************************************************/

        abstract void[] read (void* dst, uint bytes, Type type);

        /***********************************************************************

        ***********************************************************************/

        abstract void write (void* src, uint bytes, Type type);

        /***********************************************************************

        ***********************************************************************/

        abstract void[] readArray (void* dst, uint bytes, Type type, Allocator alloc);
        
        /***********************************************************************

        ***********************************************************************/

        abstract void writeArray (void* src, uint bytes, Type type);
}


/*******************************************************************************

*******************************************************************************/

abstract class IAllocator
{
        /***********************************************************************
        
        ***********************************************************************/

        abstract void reset ();
        
        /***********************************************************************

        ***********************************************************************/

        abstract IProtocol protocol ();

        /***********************************************************************

        ***********************************************************************/

        abstract void[] allocate (IProtocol.Reader, uint bytes, IProtocol.Type);
}
