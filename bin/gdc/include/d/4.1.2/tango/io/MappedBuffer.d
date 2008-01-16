/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
      
        version:        Initial release: March 2004
        
        author:         Kris

*******************************************************************************/

module tango.io.MappedBuffer;

private import  tango.sys.Common;

private import  tango.io.Buffer;

private import  tango.core.Exception;

public  import  tango.io.FileConduit;

/*******************************************************************************

        Win32 declarations

*******************************************************************************/

version (Win32)
         private extern (Windows) 
                        {
                        BOOL   UnmapViewOfFile    (LPCVOID);
                        BOOL   FlushViewOfFile    (LPCVOID, DWORD);
                        LPVOID MapViewOfFile      (HANDLE, DWORD, DWORD, DWORD, DWORD);
                        HANDLE CreateFileMappingA (HANDLE, LPSECURITY_ATTRIBUTES, DWORD, DWORD, DWORD, LPCTSTR);
                        }

version (Posix)
        {               
        private import tango.stdc.posix.sys.mman;
        }


/*******************************************************************************

        Subclass to treat the buffer as a seekable entity, where all 
        capacity is available for reading and/or writing. To achieve 
        this we must effectively disable the 'limit' watermark, and 
        locate write operations around 'position' instead. 

*******************************************************************************/

class MappedBuffer : Buffer, IConduit.Seek
{
        private FileConduit     host;                   // the hosting file

        version (Win32)
        {
                private void*   base;                   // array pointer
                private HANDLE  mmFile;                 // mapped file

                /***************************************************************

                        Construct a MappedBuffer upon the given FileConduit. 
                        One should set the file size using seek() & truncate() 
                        to setup the available working space.

                ***************************************************************/

                this (FileConduit host)
                {
                        super (0);

                        this.host = host;

                        // can only do 32bit mapping on 32bit platform
                        auto size = host.length;
                        assert (size <= uint.max);

                        auto access = host.style.access;

                        DWORD flags = PAGE_READONLY;
                        if (access & host.Access.Write)
                            flags = PAGE_READWRITE;

                        auto handle = cast(HANDLE) host.fileHandle;
                        mmFile = CreateFileMappingA (handle, null, flags, 0, 0, null);
                        if (mmFile is null)
                            host.error ();

                        flags = FILE_MAP_READ;
                        if (access & host.Access.Write)
                            flags |= FILE_MAP_WRITE;

                        base = MapViewOfFile (mmFile, flags, 0, 0, 0);
                        if (base is null)
                            host.error;
 
                        void[] mem = base [0 .. cast(int) size];
                        setContent (mem);
                }

                /***************************************************************

                        Release this mapped buffer without flushing

                ***************************************************************/

                override void close ()
                {
                        if (base)
                            UnmapViewOfFile (base);

                        if (mmFile)
                            CloseHandle (mmFile);       

                        mmFile = null;
                        base = null;
                }

                /***************************************************************

                        Flush dirty content out to the drive. This
                        fails with error 33 if the file content is
                        virgin. Opening a file for ReadWriteExists
                        followed by a flush() will cause this.

                ***************************************************************/

                override OutputStream flush ()
                {
                        // flush all dirty pages
                        if (! FlushViewOfFile (base, 0))
                              host.error ();
                        return this;
                }
        }

        /***********************************************************************
                
        ***********************************************************************/

        version (Posix)
        {               
                // Linux code: not yet tested on other POSIX systems.
                private void*   base;           // array pointer
                private ulong   size;           // length of file

                this (FileConduit host)
                {
                        super(0);

                        this.host = host;
                        size = host.length;
                        
                        // Make sure the mapping attributes are consistant with
                        // the FileConduit attributes.
                        
                        auto access = host.style.access;
                        
                        int flags = MAP_SHARED;
                        int protection = PROT_READ;
                        
                        if (access & host.Access.Write)
                            protection |= PROT_WRITE;
                                
                        base = mmap (null, size, protection, flags, host.fileHandle(), 0);
                        if (base is null)
                            host.error();
                                
                        void[] mem = base [0 .. cast(int) size];
                        setContent (mem);
                }    

                /***************************************************************

                        Release this mapped buffer without flushing

                ***************************************************************/

                override void close ()
                {
                        // NOTE: When a process ends, all mmaps belonging to that process
                        //       are automatically unmapped by system (Linux).
                        //       On the other hand, this is NOT the case when the related 
                        //       file descriptor is closed.  This function unmaps explicitly.
                        
                        if (base)
                            if (munmap (base, size))
                                host.error();
                        base = null;    
                }

                /***************************************************************

                        Flush dirty content out to the drive. 

                ***************************************************************/

                override OutputStream flush () 
                {
                        // MS_ASYNC: delayed flush; equivalent to "add-to-queue"
                        // MS_SYNC: function flushes file immediately; no return until flush complete
                        // MS_INVALIDATE: invalidate all mappings of the same file (shared)

                        if (msync (base, size, MS_SYNC | MS_INVALIDATE))
                            host.error();
                        return this;
                }
        }

        /***********************************************************************
        
                Seek to the specified position within the buffer, and return
                the byte offset of the new location (relative to zero).

        ***********************************************************************/

        long seek (long offset, Anchor anchor = Anchor.Begin)
        {
                uint pos = dimension;

                if (anchor is Anchor.Begin)
                    pos = cast(uint) offset;
                else
                   if (anchor is Anchor.End)
                       pos -= cast(uint) offset;
                   else
                      pos = index + cast(uint) offset;

                return index = pos;
        }

        /***********************************************************************
        
                Return count of writable bytes available in buffer. This is 
                calculated simply as capacity() - limit()

        ***********************************************************************/

        override uint writable ()
        {
                return dimension - index;
        }               

        /***********************************************************************
        
                Bulk copy of data from 'src'. Position is adjusted by 'size'
                bytes.

        ***********************************************************************/

        override protected void copy (void *src, uint size)
        {
                // avoid "out of bounds" test on zero size
                if (size)
                   {
                   // content may overlap ...
                   memcpy (&data[index], src, size);
                   index += size;
                   }
        }

        /***********************************************************************

                Exposes the raw data buffer at the current write position, 
                The delegate is provided with a void[] representing space
                available within the buffer at the current write position.

                The delegate should return the appropriate number of bytes 
                if it writes valid content, or IConduit.Eof on error.

                Returns whatever the delegate returns.

        ***********************************************************************/

        override uint write (uint delegate (void[]) dg)
        {
                int count = dg (data [index .. dimension]);

                if (count != IConduit.Eof) 
                   {
                   index += count;
                   assert (index <= dimension);
                   }
                return count;
        }               

        /***********************************************************************

                Prohibit compress() from doing anything at all.

        ***********************************************************************/

        override IBuffer compress ()
        {
                return this;
        }               

        /***********************************************************************

                Prohibit clear() from doing anything at all.

        ***********************************************************************/

        override InputStream clear ()
        {       
                return this;
        }               

        /***********************************************************************
        
                Prohibit the setting of another IConduit

        ***********************************************************************/

        override IBuffer setConduit (IConduit conduit)
        {
                error ("cannot setConduit on memory-mapped buffer");
                return null;
        }
}


debug (MappedBuffer)
{
        void main()
        {
                auto x = new MappedBuffer(null);
        }
}
