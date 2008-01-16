/*******************************************************************************

        copyright:      Copyright (c) 2006 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Dec 2006: Initial release

        author:         Kris


        Placeholder for a selection of ASCII utilities. These generally will
        not work with utf8, and cannot be easily extended to utf16 or utf32
        
*******************************************************************************/

module tango.text.Ascii;

version (Win32)
        {
        private extern (C) int memicmp (char *, char *, uint);
        private extern (C) int memcmp (char *, char *, uint);
        }

version (Posix)
        {
        private extern (C) int memcmp (char *, char *, uint);
        private extern (C) int strncasecmp (char *, char*, uint);
        private alias strncasecmp memicmp;
        }

/******************************************************************************

        Convert to lowercase. Returns the converted content in dst,
        performing an in-place conversion if dst is null

******************************************************************************/

char[] toLower (char[] src, char[] dst = null)
{
        if (dst.ptr)
           {
           assert (dst.length >= src.length);
           dst[0 .. src.length] = src [0 .. $];
           }
        else
           dst = src;
        
        foreach (inout c; dst)
                 if (c>= 'A' && c <= 'Z')
                     c = c + 32;
        return dst [0  .. src.length];
}

/******************************************************************************

        Convert to uppercase. Returns the converted content in dst,
        performing an in-place conversion if dst is null

******************************************************************************/

char[] toUpper (char[] src, char[] dst = null)
{
        if (dst.ptr)
           {
           assert (dst.length >= src.length);
           dst[0 .. src.length] = src [0 .. $];
           }
        else
           dst = src;
        
        foreach (inout c; dst)
                 if (c>= 'a' && c <= 'z')
                     c = c - 32;
        return dst[0 .. src.length];
}

/******************************************************************************

        Compare two char[] ignoring case. Returns 0 if equal
        
******************************************************************************/

int icompare (char[] s1, char[] s2)
{
        auto len = s1.length;
        if (s2.length < len)
            len = s2.length;

        auto result = memicmp (s1.ptr, s2.ptr, len);

        if (result is 0)
            result = s1.length - s2.length;
        return result;
}


/******************************************************************************

        Compare two char[] with case. Returns 0 if equal
        
******************************************************************************/

int compare (char[] s1, char[] s2)
{
        auto len = s1.length;
        if (s2.length < len)
            len = s2.length;

        auto result = memcmp (s1.ptr, s2.ptr, len);

        if (result is 0)
            result = s1.length - s2.length;
        return result;
}



/******************************************************************************

******************************************************************************/

debug (UnitTest)
{       
//        void main(){}
        
        unittest
        {
        char[20] tmp;
        
        assert (toLower("1bac", tmp) == "1bac");
        assert (toLower("1BAC", tmp) == "1bac");
        assert (toUpper("1bac", tmp) == "1BAC");
        assert (toUpper("1BAC", tmp) == "1BAC");
        assert (icompare ("ABC", "abc") is 0);
        assert (icompare ("abc", "abc") is 0);
        assert (icompare ("abcd", "abc") > 0);
        assert (icompare ("abc", "abcd") < 0);
        assert (icompare ("ACC", "abc") > 0);
        }
}
