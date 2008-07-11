/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: May 2005

        author:         Kris

*******************************************************************************/

module tango.io.DeviceConduit;

private import  tango.sys.Common;

public  import  tango.io.Conduit;

private import  tango.core.Exception;

/*******************************************************************************

        Implements a means of reading and writing a file device. Conduits
        are the primary means of accessing external data, and are usually
        routed through a Buffer.

*******************************************************************************/

class DeviceConduit : Conduit
{
        /// expose in superclass definition also
        public alias Conduit.error error;

        /***********************************************************************

                Throw an IOException noting the last error
        
        ***********************************************************************/

        final void error ()
        {
                super.error (toString() ~ " :: " ~ SysError.lastMsg);
        }

        /***********************************************************************

                Return the name of this device

        ***********************************************************************/

        override char[] toString()
        {
                return "<device>";
        }

        /***********************************************************************

                Return a preferred size for buffering conduit I/O

        ***********************************************************************/

        override uint bufferSize ()
        {
                return 1024 * 16;
        }

        /***********************************************************************

                Windows-specific code

        ***********************************************************************/

        version (Win32)
        {
                protected HANDLE handle;

                /***************************************************************

                        Gain access to the standard IO handles (console etc).

                ***************************************************************/

                protected void reopen (Handle handle)
                {
                        this.handle = cast(HANDLE) handle;
                }

                /***************************************************************

                        Return the underlying OS handle of this Conduit

                ***************************************************************/

                final override Handle fileHandle ()
                {
                        return cast(Handle) handle;
                }

                /***************************************************************

                        Release the underlying file

                ***************************************************************/

                override void detach ()
                {
                        if (handle)
                            if (! CloseHandle (handle))
                                  error ();
                        handle = cast(HANDLE) null;
                }

                /***************************************************************

                        Read a chunk of bytes from the file into the provided
                        array (typically that belonging to an IBuffer). 

                        Returns the number of bytes read, or Eof when there is
                        no further data

                ***************************************************************/

                override uint read (void[] dst)
                {
                        DWORD read;
                        void *p = dst.ptr;

                        if (! ReadFile (handle, p, dst.length, &read, null))
                              // make Win32 behave like linux
                              if (SysError.lastCode is ERROR_BROKEN_PIPE)
                                  return Eof;
                              else
                                 error ();

                        if (read is 0 && dst.length > 0)
                            return Eof;
                        return read;
                }

                /***************************************************************

                        Write a chunk of bytes to the file from the provided
                        array (typically that belonging to an IBuffer)

                ***************************************************************/

                override uint write (void[] src)
                {
                        DWORD written;

                        if (! WriteFile (handle, src.ptr, src.length, &written, null))
                              error ();

                        return written;
                }
        }


        /***********************************************************************

                 Unix-specific code.

        ***********************************************************************/

        version (Posix)
        {
                protected int handle = -1;

                /***************************************************************

                        Gain access to the standard IO handles (console etc).

                ***************************************************************/

                protected void reopen (Handle handle)
                {
                        this.handle = handle;
                }

                /***************************************************************

                        Return the underlying OS handle of this Conduit

                ***************************************************************/

                final override Handle fileHandle ()
                {
                        return cast(Handle) handle;
                }

                /***************************************************************

                        Release the underlying file

                ***************************************************************/

                override void detach ()
                {
                        if (handle >= 0)
                            if (posix.close (handle) is -1)
                                error ();
                        handle = -1;
                }

                /***************************************************************

                        Read a chunk of bytes from the file into the provided
                        array (typically that belonging to an IBuffer)

                ***************************************************************/

                override uint read (void[] dst)
                {
                        int read = posix.read (handle, dst.ptr, dst.length);
                        if (read == -1)
                            error ();
                        else
                           if (read is 0 && dst.length > 0)
                               return Eof;
                        return read;
                }

                /***************************************************************

                        Write a chunk of bytes to the file from the provided
                        array (typically that belonging to an IBuffer)

                ***************************************************************/

                override uint write (void[] src)
                {
                        int written = posix.write (handle, src.ptr, src.length);
                        if (written is -1)
                            error ();
                        return written;
                }
        }
}


