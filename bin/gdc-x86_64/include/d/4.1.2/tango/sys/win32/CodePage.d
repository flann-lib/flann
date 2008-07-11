/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: April 2007

        author:         Kris

*******************************************************************************/

module tango.sys.win32.CodePage;

private import tango.sys.Common;

private import tango.core.Exception;

/*******************************************************************************

        Convert text to and from Windows 'code pages'. This is non-portable,
        and will be unlikely to operate even across all Windows platforms.
        
*******************************************************************************/

struct CodePage
{
        /**********************************************************************

                Test a text array to see if it contains non-ascii elements.
                Returns true if ascii, false otherwise

        **********************************************************************/

        static bool isAscii (char[] src)
        {
                foreach (c; src)
                         if (c & 0x80)
                             return false;
                return true;
        }
        

        /**********************************************************************

                Convert utf8 text to a codepage representation

                page  0     - the ansi code page
                      1     - the oem code page
                      2     - the mac code page
                      3     - ansi code page for the calling thread
                      65000 - UTF-7 translation
                      65001 - UTF-8 translation

                      or a region-specific codepage

                returns: a slice of the provided output buffer 
                         representing converted text

                Note that the input must be utf8 encoded. Note also
                that the dst output should be sufficiently large to
                accomodate the output; a size of 2*src.length would
                be enough to host almost any conversion

        **********************************************************************/

        static char[] into (char[] src, char[] dst, uint page=0)
        {  
                return convert (src, dst, CP_UTF8, page);
        }


        /**********************************************************************

                Convert codepage text to a utf8 representation

                page  0     - the ansi code page
                      1     - the oem code page
                      2     - the mac code page
                      3     - ansi code page for the calling thread
                      65000 - UTF-7 translation
                      65001 - UTF-8 translation

                      or a region-specific codepage

                returns: a slice of the provided output buffer 
                         representing converted text

                Note that the input will be utf8 encoded. Note also
                that the dst output should be sufficiently large to
                accomodate the output; a size of 2*src.length would
                be enough to host almost any conversion

        **********************************************************************/

        static char[] from (char[] src, char[] dst, uint page=0)
        {       
                return convert (src, dst, page, CP_UTF8);
        }


        /**********************************************************************

                Internal conversion routine; we avoid heap activity for
                strings of short and medium length. A zero is appended 
                to the dst array in order to simplify C API conversions

        **********************************************************************/

        private static char[] convert (char[] src, char[] dst, uint from, uint into)
        {       
                uint len = 0;

                // sanity check
                assert (dst.length);

                // got some input?
                if (src.length > 0)
                   {    
                   wchar[2000] tmp = void;
                   wchar[] wide = (src.length <= tmp.length) ? tmp : new wchar[src.length];

                   len = MultiByteToWideChar (from, 0, src.ptr, src.length, 
                                              wide.ptr, wide.length);
                   if (len)
                       len = WideCharToMultiByte (into, 0, wide.ptr, len, 
                                                  dst.ptr, dst.length-1, null, null);
                   if (len is 0)
                       throw new IllegalArgumentException ("CodePage.convert :: "~SysError.lastMsg);
                   }

                // append a null terminator
                dst[len] = 0;
                return dst [0 .. len];
        }
}


debug(Test)
{
        void main ()
        {
                char[] s = "foo";
                char[3] x = void;

                //if (! CodePage.isAscii (s))
                      s = CodePage.into (s, x);
                      s = CodePage.from (s, x);
        }
}
