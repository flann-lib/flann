/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004      
                        Outback release: December 2006
                        
        author:         $(UL Kris)
                        $(UL John Reimer)
                        $(UL Anders F Bjorklund (Darwin patches))
                        $(UL Chris Sauls (Win95 file support))

*******************************************************************************/

module tango.io.FileConduit;

private import  tango.sys.Common;

public  import  tango.io.FilePath;

private import  tango.io.DeviceConduit;

private import  Utf = tango.text.convert.Utf;

/*******************************************************************************

        Other O/S functions

*******************************************************************************/

version (Win32)
         private extern (Windows) BOOL SetEndOfFile (HANDLE);
     else
        private extern (C) int ftruncate (int, int);


/*******************************************************************************

        Implements a means of reading and writing a generic file. Conduits
        are the primary means of accessing external data and FileConduit
        extends the basic pattern by providing file-specific methods to
        set the file size, seek to a specific file position and so on. 
        
        Serial input and output is straightforward. In this example we
        copy a file directly to the console:
        ---
        // open a file for reading
        auto from = new FileConduit ("test.txt");

        // stream directly to console
        Stdout.copy (from);
        ---

        And here we copy one file to another:
        ---
        // open another for writing
        auto to = new FileConduit ("copy.txt", FileConduit.WriteCreate);

        // copy file
        to.output.copy (new FileConduit("test.txt"));
        ---
        
        To load a file directly into memory one might do this:
        ---
        // open file for reading
        auto fc = new FileConduit ("test.txt");

        // create an array to house the entire file
        auto content = new char[fc.length];

        // read the file content. Return value is the number of bytes read
        auto bytesRead = fc.input.read (content);
        ---

        Conversely, one may write directly to a FileConduit, like so:
        ---
        // open file for writing
        auto to = new FileConduit ("text.txt", FileConduit.WriteCreate);

        // write an array of content to it
        auto bytesWritten = to.output.write (content);
        ---

        FileConduit can just as easily handle random IO. Here we use seek()
        to relocate the file pointer and, for variation, apply a protocol to
        perform simple input and output:
        ---
        // open a file for reading
        auto fc = new FileConduit ("random.bin", FileConduit.ReadWriteCreate);

        // construct (binary) reader & writer upon this conduit
        auto read = new Reader (fc);
        auto write = new Writer (fc);

        int x=10, y=20;

        // write some data, and flush output since protocol IO is buffered
        write (x) (y) ();

        // rewind to file start
        fc.seek (0);

        // read data back again
        read (x) (y);

        fc.close();
        ---

        See File, FilePath, FileConst, FileScan, and FileSystem for 
        additional functionality related to file manipulation. 

        Compile with -version=Win32SansUnicode to enable Win95 & Win32s file 
        support.
        
*******************************************************************************/

class FileConduit : DeviceConduit, DeviceConduit.Seek
{
        /***********************************************************************
        
                Fits into 32 bits ...

        ***********************************************************************/

        struct Style
        {
                align (1):

                Access          access;                 /// access rights
                Open            open;                   /// how to open
                Share           share;                  /// how to share
                Cache           cache;                  /// how to cache
        }

        /***********************************************************************

        ***********************************************************************/

        enum Access : ubyte     {
                                Read      = 0x01,       /// is readable
                                Write     = 0x02,       /// is writable
                                ReadWrite = 0x03,       /// both
                                }

        /***********************************************************************
        
        ***********************************************************************/

        enum Open : ubyte       {
                                Exists=0,               /// must exist
                                Create,                 /// create or truncate
                                Sedate,                 /// create if necessary
                                Append,                 /// create if necessary
                                };

        /***********************************************************************
        
        ***********************************************************************/

        enum Share : ubyte      {
                                None=0,                 /// no sharing
                                Read,                   /// shared reading
                                ReadWrite,              /// open for anything
                                };

        /***********************************************************************
        
        ***********************************************************************/

        enum Cache : ubyte      {
                                None      = 0x00,       /// don't optimize
                                Random    = 0x01,       /// optimize for random
                                Stream    = 0x02,       /// optimize for stream
                                WriteThru = 0x04,       /// backing-cache flag
                                };

        /***********************************************************************

            Read an existing file
        
        ***********************************************************************/

        const Style ReadExisting = {Access.Read, Open.Exists};

        /***********************************************************************
        
                Write on an existing file. Do not create

        ***********************************************************************/

        const Style WriteExisting = {Access.Write, Open.Exists};

        /***********************************************************************
        
                Write on a clean file. Create if necessary

        ***********************************************************************/

        const Style WriteCreate = {Access.Write, Open.Create};

        /***********************************************************************
        
                Write at the end of the file

        ***********************************************************************/

        deprecated const Style WriteAppending = {Access.Write, Open.Append};

        /***********************************************************************
        
                Read and write an existing file

        ***********************************************************************/

        const Style ReadWriteExisting = {Access.ReadWrite, Open.Exists}; 

        /***********************************************************************
        
                Read & write on a clean file. Create if necessary

        ***********************************************************************/

        const Style ReadWriteCreate = {Access.ReadWrite, Open.Create}; 

        /***********************************************************************
        
                Read and Write. Use existing file if present

        ***********************************************************************/

        const Style ReadWriteOpen = {Access.ReadWrite, Open.Sedate}; 




        // the file we're working with 
        private PathView path_;

        // the style we're opened with
        private Style    style_;

        /***********************************************************************
        
                Create a FileConduit with the provided path and style.

        ***********************************************************************/

        this (char[] name, Style style = ReadExisting)
        {
                this (new FilePath(name), style);
        }

        /***********************************************************************
        
                Create a FileConduit with the provided path and style.

        ***********************************************************************/

        this (PathView path, Style style = ReadExisting)
        {
                // remember who we are
                path_ = path;

                // open the file
                open (this.style_ = style);
        }    

        /***********************************************************************
        
                Return the PathView used by this file.

        ***********************************************************************/

        PathView path ()
        {
                return path_;
        }               

        /***********************************************************************
        
                Return the Style used for this file.

        ***********************************************************************/

        Style style ()
        {
                return style_;
        }               

        /***********************************************************************
        
                Return the name of the FilePath used by this file.

        ***********************************************************************/

        override char[] toString ()
        {
                return path_.toString;
        }               

        /***********************************************************************
                
                Return the current file position.
                
        ***********************************************************************/

        long position ()
        {
                return seek (0, Seek.Anchor.Current);
        }               

        /***********************************************************************
        
                Return the total length of this file.

        ***********************************************************************/

        long length ()
        {
                long    pos,    
                        ret;
                        
                pos = position ();
                ret = seek (0, Seek.Anchor.End);
                seek (pos);
                return ret;
        }               


        /***********************************************************************

                Windows-specific code
        
        ***********************************************************************/

        version(Win32)
        {
                private bool appending;

                /***************************************************************

                        Open a file with the provided style.

                ***************************************************************/

                protected void open (Style style)
                {
                        DWORD   attr,
                                share,
                                access,
                                create;

                        alias DWORD[] Flags;

                        static const Flags Access =  
                                        [
                                        0,                      // invalid
                                        GENERIC_READ,
                                        GENERIC_WRITE,
                                        GENERIC_READ | GENERIC_WRITE,
                                        ];
                                                
                        static const Flags Create =  
                                        [
                                        OPEN_EXISTING,          // must exist
                                        CREATE_ALWAYS,          // truncate always
                                        OPEN_ALWAYS,            // create if needed
                                        OPEN_ALWAYS,            // (for appending)
                                        ];
                                                
                        static const Flags Share =   
                                        [
                                        0,
                                        FILE_SHARE_READ,
                                        FILE_SHARE_READ | FILE_SHARE_WRITE,
                                        ];
                                                
                        static const Flags Attr =   
                                        [
                                        0,
                                        FILE_FLAG_RANDOM_ACCESS,
                                        FILE_FLAG_SEQUENTIAL_SCAN,
                                        0,
                                        FILE_FLAG_WRITE_THROUGH,
                                        ];

                        attr   = Attr[style.cache];
                        share  = Share[style.share];
                        create = Create[style.open];
                        access = Access[style.access];

                        version (Win32SansUnicode)
                                 handle = CreateFileA (path.cString.ptr, access, share, 
                                                       null, create, 
                                                       attr | FILE_ATTRIBUTE_NORMAL,
                                                       cast(HANDLE) null);
                             else
                                {
                                wchar[256] tmp = void;
                                auto name = Utf.toString16 (path.cString, tmp);
                                handle = CreateFileW (name.ptr, access, share,
                                                      null, create, 
                                                      attr | FILE_ATTRIBUTE_NORMAL,
                                                      cast(HANDLE) null);
                                }

                        if (handle is INVALID_HANDLE_VALUE)
                            error ();

                        // move to end of file?
                        if (style.open is Open.Append)
                            appending = true;
                }
                
                /***************************************************************

                        Write a chunk of bytes to the file from the provided
                        array (typically that belonging to an IBuffer)

                ***************************************************************/

                override uint write (void[] src)
                {
                        DWORD written;

                        // try to emulate the Unix O_APPEND mode
                        if (appending)
                            SetFilePointer (handle, 0, null, Seek.Anchor.End);
                        
                        return super.write (src);
                }
            
                /***************************************************************

                        Ensures that data is flushed immediately to disk

                ***************************************************************/
/+
                override void commit ()
                {
                        if (style_.access & Access.Write)
                            if (! FlushFileBuffers (handle))
                                  error ();
                }
+/
                /***************************************************************

                        Set the file size to be that of the current seek 
                        position. The file must be writable for this to
                        succeed.

                ***************************************************************/

                void truncate ()
                {
                        // must have Generic_Write access
                        if (! SetEndOfFile (handle))
                              error ();                            
                }               

                /***************************************************************

                        Set the file seek position to the specified offset
                        from the given anchor. 

                ***************************************************************/

                long seek (long offset, Seek.Anchor anchor = Seek.Anchor.Begin)
                {
                        LONG high = cast(LONG) (offset >> 32);
                        long result = SetFilePointer (handle, cast(LONG) offset, 
                                                      &high, anchor);

                        if (result is -1 && 
                            GetLastError() != ERROR_SUCCESS)
                            error ();

                        return result + (cast(long) high << 32);
                }               
        }


        /***********************************************************************

                 Unix-specific code. Note that some methods are 32bit only
        
        ***********************************************************************/

        version (Posix)
        {
                /***************************************************************

                        Open a file with the provided style.

                        Note that files default to no-sharing. That is, 
                        they are locked exclusively to the host process 
                        unless otherwise stipulated. We do this in order
                        to expose the same default behaviour as Win32

                        NO FILE LOCKING FOR BORKED POSIX

                ***************************************************************/

                protected void open (Style style)
                {
                        alias int[] Flags;

                        const O_LARGEFILE = 0x8000;

                        static const Flags Access =  
                                        [
                                        0,                      // invalid
                                        O_RDONLY,
                                        O_WRONLY,
                                        O_RDWR,
                                        ];
                                                
                        static const Flags Create =  
                                        [
                                        0,                      // open existing
                                        O_CREAT | O_TRUNC,      // truncate always
                                        O_CREAT,                // create if needed
                                        O_APPEND | O_CREAT,     // append
                                        ];

                        static const short[] Locks =   
                                        [
                                        F_WRLCK,                // no sharing
                                        F_RDLCK,                // shared read
                                        ];
                                                
                        auto mode = Access[style.access] | Create[style.open];

                        // always open as a large file
                        handle = posix.open (path.cString.ptr, mode | O_LARGEFILE, 0666);
                        if (handle is -1)
                            error ();
                }

                /***************************************************************

                        Ensures that data is flushed immediately to disk

                ***************************************************************/
/+
                override void commit ()
                {
                        // no Posix API for this :(
                }
+/
                /***************************************************************

                        Set the file size to be that of the current seek 
                        position. The file must be writable for this to
                        succeed.

                ***************************************************************/

                void truncate ()
                {
                        // set filesize to be current seek-position
                        if (ftruncate (handle, position) is -1)
                            error ();
                }               

                /***************************************************************

                        Set the file seek position to the specified offset
                        from the given anchor. 

                ***************************************************************/

                long seek (long offset, Seek.Anchor anchor = Seek.Anchor.Begin)
                {
                        long result = posix.lseek (handle, offset, anchor);
                        if (result is -1)
                            error ();
                        return result;
                }               
        }
}
