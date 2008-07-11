/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: November 2005

        author:         Kris

*******************************************************************************/

module tango.sys.Common;

version (Win32)
        {
        public import tango.sys.win32.UserGdi;
        }

version (linux)
        {
        public import tango.sys.linux.linux;
        alias tango.sys.linux.linux posix;
        }

version (darwin)
        {
        public import tango.sys.darwin.darwin;
        alias tango.sys.darwin.darwin posix;
        }
version (freebsd)
        {
        public import tango.sys.freebsd.freebsd;
        alias tango.sys.freebsd.freebsd posix;
        }

/*******************************************************************************

        Stuff for sysErrorMsg(), kindly provided by Regan Heath.

*******************************************************************************/

version (Win32)
        {
        private const FORMAT_MESSAGE_ALLOCATE_BUFFER = 0x00000100;
        private const FORMAT_MESSAGE_IGNORE_INSERTS  = 0x00000200;
        private const FORMAT_MESSAGE_FROM_STRING     = 0x00000400;
        private const FORMAT_MESSAGE_FROM_HMODULE    = 0x00000800;
        private const FORMAT_MESSAGE_FROM_SYSTEM     = 0x00001000;
        private const FORMAT_MESSAGE_ARGUMENT_ARRAY  = 0x00002000;
        private const FORMAT_MESSAGE_MAX_WIDTH_MASK  = 0x000000FF;

        private DWORD MAKELANGID(WORD p, WORD s)  { return (((cast(WORD)s) << 10) | cast(WORD)p); }

        private alias HGLOBAL HLOCAL;

        private const LANG_NEUTRAL = 0x00;
        private const SUBLANG_DEFAULT = 0x01;

        private extern (Windows)
                       {
                       DWORD FormatMessageW (DWORD dwFlags,
                                             LPCVOID lpSource,
                                             DWORD dwMessageId,
                                             DWORD dwLanguageId,
                                             LPWSTR lpBuffer,
                                             DWORD nSize,
                                             LPCVOID args
                                             );

                       HLOCAL LocalFree(HLOCAL hMem);
                       }
        }
else
version (Posix)
        {
        private import tango.stdc.errno;
        private import tango.stdc.string;
        }
else
   {
   pragma (msg, "Unsupported environment; neither Win32 or Posix is declared");
   static assert(0);
   }

   
/*******************************************************************************

*******************************************************************************/

struct SysError
{   
        /***********************************************************************

        ***********************************************************************/

        static uint lastCode ()
        {
                version (Win32)
                         return GetLastError;
                     else
                         return errno;
        }

        /***********************************************************************

        ***********************************************************************/

        static char[] lastMsg ()
        {
                return lookup (lastCode);
        }

        /***********************************************************************

        ***********************************************************************/

        static char[] lookup (uint errcode)
        {
                char[] text;

                version (Win32)
                        {
                        DWORD  i;
                        LPWSTR lpMsgBuf;

                        i = FormatMessageW (
                                FORMAT_MESSAGE_ALLOCATE_BUFFER |
                                FORMAT_MESSAGE_FROM_SYSTEM |
                                FORMAT_MESSAGE_IGNORE_INSERTS,
                                null,
                                errcode,
                                MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), // Default language
                                cast(LPWSTR)&lpMsgBuf,
                                0,
                                null);

                        /* Remove \r\n from error string */
                        if (i >= 2) i -= 2;
                        text = new char[i * 3];
                        i = WideCharToMultiByte (CP_UTF8, 0, lpMsgBuf, i, 
                                                 text.ptr, i, null, null);
                        text = text [0 .. i];
                        LocalFree (cast(HLOCAL) lpMsgBuf);
                        }
                     else
                        {
                        uint  r;
                        char* pemsg;

                        pemsg = strerror(errcode);
                        r = strlen(pemsg);

                        /* Remove \r\n from error string */
                        if (pemsg[r-1] == '\n') r--;
                        if (pemsg[r-1] == '\r') r--;
                        text = pemsg[0..r].dup;
                        }

                return text;
        }
}
