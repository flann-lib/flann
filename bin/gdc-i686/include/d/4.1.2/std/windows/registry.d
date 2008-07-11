/* /////////////////////////////////////////////////////////////////////////////
 * File:        registry.d (from synsoft.win32.registry)
 *
 * Purpose:     Win32 Registry manipulation
 *
 * Created      15th March 2003
 * Updated:     25th April 2004
 *
 * Author:      Matthew Wilson
 *
 * License:
 *
 * Copyright 2003-2004 by Matthew Wilson and Synesis Software
 * Written by Matthew Wilson
 *
 * This software is provided 'as-is', without any express or implied
 * warranty. In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, in both source and binary form, subject to the following
 * restrictions:
 *
 * -  The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * -  Altered source versions must be plainly marked as such, and must not
 *    be misrepresented as being the original software.
 * -  This notice may not be removed or altered from any source
 *    distribution.
 *
 * ////////////////////////////////////////////////////////////////////////// */



/** \file std/windows/registry.d This file contains
 * the \c std.windows.registry.* classes
 */

/* ////////////////////////////////////////////////////////////////////////// */

module std.windows.registry;

/* /////////////////////////////////////////////////////////////////////////////
 * Imports
 */

//import std.windows.error_codes;
//import std.windows.types;
private import std.string;
private import std.c.windows.windows;
//private import std.windows.exceptions;

//import synsoft.types;
/+ + These are borrowed from synsoft.types, until such time as something similar is in Phobos ++
 +/
/// A strongly-typed Boolean
public alias int        boolean;

version(LittleEndian)
{
    private const int Endian_Ambient =   1;
}
version(BigEndian)
{
    private const int Endian_Ambient =   2;
}

class Win32Exception : Exception
{
    int error;

    this(string message)
    {
	super(msg);
    }

    this(string msg, int errnum)
    {
	super(msg);
	error = errnum;
    }
}

/// An enumeration representing byte-ordering (Endian) strategies
public enum Endian
{
        Unknown =   0                   //!< Unknown endian-ness. Indicates an error
    ,   Little  =   1                   //!< Little endian architecture
    ,   Big     =   2                   //!< Big endian architecture
    ,   Middle  =   3                   //!< Middle endian architecture
    ,   ByteSex =   4
    ,   Ambient =   Endian_Ambient      //!< The ambient architecture, e.g. equivalent to Big on big-endian architectures.
/+ ++++ The compiler does not support this, due to deficiencies in the version() mechanism ++++
  version(LittleEndian)
  {
    ,   Ambient =   Little
  }
  version(BigEndian)
  {
    ,   Ambient =   Big
  }
+/
}
/+
 +/


//import synsoft.win32.types;
/+ + These are borrowed from synsoft.win32.types for the moment, but will not be
 + needed once I've convinced Walter to use strong typedefs for things like HKEY +
 +/
private typedef uint Reserved;

//import synsoft.text.token;
/+ ++++++ This is borrowed from synsoft.text.token, until such time as something
 + similar is in Phobos ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 +/
string[] tokenise(string source, char delimiter, boolean bElideBlanks, boolean bZeroTerminate)
{
    int         i;
    int         cDelimiters =   128;
    string[]   tokens      =   new string[cDelimiters];
    int         start;
    int         begin;
    int         cTokens;

    /// Ensures that the tokens array is big enough
    void ensure_length()
    {
        if(!(cTokens < tokens.length))
        {
            tokens.length = tokens.length * 2;
        }
    }

    if(bElideBlanks)
    {
        for(start = 0, begin = 0, cTokens = 0; begin < source.length; ++begin)
        {
            if(source[begin] == delimiter)
            {
                if(start < begin)
                {
                    ensure_length();

                    tokens[cTokens++]   =   source[start .. begin];
                }

                start = begin + 1;
            }
        }

        if(start < begin)
        {
            ensure_length();

            tokens[cTokens++]   =   source[start .. begin];
        }
    }
    else
    {
        for(start = 0, begin = 0, cTokens = 0; begin < source.length; ++begin)
        {
            if(source[begin] == delimiter)
            {
                ensure_length();

                tokens[cTokens++]   =   source[start .. begin];

                start = begin + 1;
            }
        }

        ensure_length();

        tokens[cTokens++]   =   source[start .. begin];
    }

    tokens.length = cTokens;

    if(bZeroTerminate)
    {
        for(i = 0; i < tokens.length; ++i)
        {
            tokens[i] ~= cast(char)0;
        }
    }

    return tokens;
}
/+
 +/


/* ////////////////////////////////////////////////////////////////////////// */

/// \defgroup group_std_windows_reg std.windows.registry
/// \ingroup group_std_windows
/// \brief This library provides Win32 Registry facilities

/* /////////////////////////////////////////////////////////////////////////////
 * Private constants
 */

private const DWORD DELETE                      =   0x00010000L;
private const DWORD READ_CONTROL                =   0x00020000L;
private const DWORD WRITE_DAC                   =   0x00040000L;
private const DWORD WRITE_OWNER                 =   0x00080000L;
private const DWORD SYNCHRONIZE                 =   0x00100000L;

private const DWORD STANDARD_RIGHTS_REQUIRED    =   0x000F0000L;

private const DWORD STANDARD_RIGHTS_READ        =   0x00020000L/* READ_CONTROL */;
private const DWORD STANDARD_RIGHTS_WRITE       =   0x00020000L/* READ_CONTROL */;
private const DWORD STANDARD_RIGHTS_EXECUTE     =   0x00020000L/* READ_CONTROL */;

private const DWORD STANDARD_RIGHTS_ALL         =   0x001F0000L;

private const DWORD SPECIFIC_RIGHTS_ALL         =   0x0000FFFFL;

private const Reserved  RESERVED                =   cast(Reserved)0;

private const DWORD REG_CREATED_NEW_KEY     =   0x00000001;
private const DWORD REG_OPENED_EXISTING_KEY =   0x00000002;

/* /////////////////////////////////////////////////////////////////////////////
 * Public enumerations
 */

/// Enumeration of the recognised registry access modes
///
/// \ingroup group_D_win32_reg
public enum REGSAM
{
        KEY_QUERY_VALUE         =   0x0001 //!< Permission to query subkey data
    ,   KEY_SET_VALUE           =   0x0002 //!< Permission to set subkey data
    ,   KEY_CREATE_SUB_KEY      =   0x0004 //!< Permission to create subkeys
    ,   KEY_ENUMERATE_SUB_KEYS  =   0x0008 //!< Permission to enumerate subkeys
    ,   KEY_NOTIFY              =   0x0010 //!< Permission for change notification
    ,   KEY_CREATE_LINK         =   0x0020 //!< Permission to create a symbolic link
    ,   KEY_WOW64_32KEY         =   0x0200 //!< Enables a 64- or 32-bit application to open a 32-bit key
    ,   KEY_WOW64_64KEY         =   0x0100 //!< Enables a 64- or 32-bit application to open a 64-bit key
    ,   KEY_WOW64_RES           =   0x0300 //!< 
    ,   KEY_READ                =   (   STANDARD_RIGHTS_READ
                                    |   KEY_QUERY_VALUE
                                    |   KEY_ENUMERATE_SUB_KEYS
                                    |   KEY_NOTIFY)
                                &   ~(SYNCHRONIZE) //!< Combines the STANDARD_RIGHTS_READ, KEY_QUERY_VALUE, KEY_ENUMERATE_SUB_KEYS, and KEY_NOTIFY access rights
    ,   KEY_WRITE               =   (   STANDARD_RIGHTS_WRITE
                                    |   KEY_SET_VALUE
                                    |   KEY_CREATE_SUB_KEY)
                                &   ~(SYNCHRONIZE) //!< Combines the STANDARD_RIGHTS_WRITE, KEY_SET_VALUE, and KEY_CREATE_SUB_KEY access rights
    ,   KEY_EXECUTE             =   KEY_READ
                                &   ~(SYNCHRONIZE) //!< Permission for read access
    ,   KEY_ALL_ACCESS          =   (   STANDARD_RIGHTS_ALL
                                    |   KEY_QUERY_VALUE
                                    |   KEY_SET_VALUE
                                    |   KEY_CREATE_SUB_KEY
                                    |   KEY_ENUMERATE_SUB_KEYS
                                    |   KEY_NOTIFY
                                    |   KEY_CREATE_LINK)
                                &   ~(SYNCHRONIZE) //!< Combines the KEY_QUERY_VALUE, KEY_ENUMERATE_SUB_KEYS, KEY_NOTIFY, KEY_CREATE_SUB_KEY, KEY_CREATE_LINK, and KEY_SET_VALUE access rights, plus all the standard access rights except SYNCHRONIZE
}

/// Enumeration of the recognised registry value types
///
/// \ingroup group_D_win32_reg
public enum REG_VALUE_TYPE
{
        REG_UNKNOWN                     =   -1 //!< 
    ,   REG_NONE                        =   0  //!< The null value type. (In practise this is treated as a zero-length binary array by the Win32 registry)
    ,   REG_SZ                          =   1  //!< A zero-terminated string
    ,   REG_EXPAND_SZ                   =   2  //!< A zero-terminated string containing expandable environment variable references
    ,   REG_BINARY                      =   3  //!< A binary blob
    ,   REG_DWORD                       =   4  //!< A 32-bit unsigned integer
    ,   REG_DWORD_LITTLE_ENDIAN         =   4  //!< A 32-bit unsigned integer, stored in little-endian byte order
    ,   REG_DWORD_BIG_ENDIAN            =   5  //!< A 32-bit unsigned integer, stored in big-endian byte order
    ,   REG_LINK                        =   6  //!< A registry link
    ,   REG_MULTI_SZ                    =   7  //!< A set of zero-terminated strings
    ,   REG_RESOURCE_LIST               =   8  //!< A hardware resource list
    ,   REG_FULL_RESOURCE_DESCRIPTOR    =   9  //!< A hardware resource descriptor
    ,   REG_RESOURCE_REQUIREMENTS_LIST  =   10 //!< A hardware resource requirements list
    ,   REG_QWORD                       =   11 //!< A 64-bit unsigned integer
    ,   REG_QWORD_LITTLE_ENDIAN         =   11 //!< A 64-bit unsigned integer, stored in little-endian byte order
}

/* /////////////////////////////////////////////////////////////////////////////
 * External function declarations
 */

extern (C)
{
    int wsprintfA(char *dest, char *fmt, ...);
}

extern (Windows)
{
    LONG    RegCreateKeyExA(in HKEY hkey, in LPCSTR lpSubKey, in Reserved 
                        ,   in Reserved , in DWORD dwOptions
                        ,   in REGSAM samDesired
                        ,   in LPSECURITY_ATTRIBUTES lpsa
                        ,   out HKEY hkeyResult, out DWORD disposition);
    LONG    RegDeleteKeyA(in HKEY hkey, in LPCSTR lpSubKey);
    LONG    RegDeleteValueA(in HKEY hkey, in LPCSTR lpValueName);
    LONG    RegOpenKeyA(in HKEY hkey, in LPCSTR lpSubKey, out HKEY hkeyResult);
    LONG    RegOpenKeyExA(  in HKEY hkey, in LPCSTR lpSubKey, in Reserved 
                        ,   in REGSAM samDesired, out HKEY hkeyResult);
    LONG    RegCloseKey(in HKEY hkey);
    LONG    RegFlushKey(in HKEY hkey);
    LONG    RegQueryValueExA(   in HKEY hkey, in LPCSTR lpValueName, in Reserved 
                            ,   out REG_VALUE_TYPE type, in void *lpData
                            ,   inout DWORD cbData);
    LONG    RegEnumKeyExA(  in HKEY hkey, in DWORD dwIndex, in LPSTR lpName
                        ,   inout DWORD cchName, in Reserved , in LPSTR lpClass
                        ,   in LPDWORD cchClass, in FILETIME *ftLastWriteTime);
    LONG    RegEnumValueA(  in HKEY hkey, in DWORD dwIndex, in LPSTR lpValueName
                        ,   inout DWORD cchValueName, in Reserved 
                        ,   in LPDWORD lpType, in void *lpData
                        ,   in LPDWORD lpcbData);
    LONG    RegQueryInfoKeyA(   in HKEY hkey, in LPSTR lpClass
                            ,   in LPDWORD lpcClass, in Reserved
                            ,   in LPDWORD lpcSubKeys
                            ,   in LPDWORD lpcMaxSubKeyLen
                            ,   in LPDWORD lpcMaxClassLen, in LPDWORD lpcValues
                            ,   in LPDWORD lpcMaxValueNameLen
                            ,   in LPDWORD lpcMaxValueLen
                            ,   in LPDWORD lpcbSecurityDescriptor
                            ,   in FILETIME *lpftLastWriteTime);
    LONG    RegSetValueExA( in HKEY hkey, in LPCSTR lpSubKey, in Reserved 
                        ,   in REG_VALUE_TYPE type, in LPCVOID lpData
                        ,   in DWORD cbData);

    DWORD   ExpandEnvironmentStringsA(in LPCSTR src, in LPSTR dest, in DWORD cchDest);
    int     GetLastError();
}

/* /////////////////////////////////////////////////////////////////////////////
 * Private utility functions
 */

private REG_VALUE_TYPE _RVT_from_Endian(Endian endian)
{
    switch(endian)
    {
        case    Endian.Big:
            return REG_VALUE_TYPE.REG_DWORD_BIG_ENDIAN;

        case    Endian.Little:
            return REG_VALUE_TYPE.REG_DWORD_LITTLE_ENDIAN;

        default:
            throw new RegistryException("Invalid Endian specified");
    }
    assert(0);
}

private uint swap(in uint i)
{
    version(X86)
    {
        asm
        {    naked;
             bswap EAX ;
             ret ;
        }
    }
    else
    {
        uint    v_swap  =   (i & 0xff) << 24
                        |   (i & 0xff00) << 8
                        |   (i >> 8) & 0xff00
                        |   (i >> 24) & 0xff;

        return v_swap;
    }
}

/+
private string expand_environment_strings(in string value)
in
{
    assert(!(null is value));
}
body
{
    LPCSTR  lpSrc       =   toStringz(value);
    DWORD   cchRequired =   ExpandEnvironmentStringsA(lpSrc, null, 0);
    char[]  newValue    =   new char[cchRequired];

    if(!ExpandEnvironmentStringsA(lpSrc, newValue, newValue.length))
    {
        throw new Win32Exception("Failed to expand environment variables");
    }

    return newValue;
}
+/

/* /////////////////////////////////////////////////////////////////////////////
 * Translation of the raw APIs:
 *
 * - translating char[] to char*
 * - removing the reserved arguments.
 */

private LONG Reg_CloseKey_(in HKEY hkey)
in
{
    assert(!(null is hkey));
}
body
{
    /* No need to attempt to close any of the standard hive keys.
     * Although it's documented that calling RegCloseKey() on any of
     * these hive keys is ignored, we'd rather not trust the Win32
     * API.
     */
    if(cast(uint)hkey & 0x80000000)
    {
        switch(cast(uint)hkey)
        {
            case    HKEY_CLASSES_ROOT:
            case    HKEY_CURRENT_USER:
            case    HKEY_LOCAL_MACHINE:
            case    HKEY_USERS:
            case    HKEY_PERFORMANCE_DATA:
            case    HKEY_PERFORMANCE_TEXT:
            case    HKEY_PERFORMANCE_NLSTEXT:
            case    HKEY_CURRENT_CONFIG:
            case    HKEY_DYN_DATA:
                return ERROR_SUCCESS;
            default:
                /* Do nothing */
                break;
        }
    }

    return RegCloseKey(hkey);
}

private LONG Reg_FlushKey_(in HKEY hkey)
in
{
    assert(!(null is hkey));
}
body
{
    return RegFlushKey(hkey);
}

private LONG Reg_CreateKeyExA_(     in HKEY hkey, in string subKey
                                ,   in DWORD dwOptions, in REGSAM samDesired
                                ,   in LPSECURITY_ATTRIBUTES lpsa
                                ,   out HKEY hkeyResult, out DWORD disposition)
in
{
    assert(!(null is hkey));
    assert(!(null is subKey));
}
body
{
    return RegCreateKeyExA( hkey, toStringz(subKey), RESERVED, RESERVED
                        ,   dwOptions, samDesired, lpsa, hkeyResult
                        ,   disposition);
}

private LONG Reg_DeleteKeyA_(in HKEY hkey, in string subKey)
in
{
    assert(!(null is hkey));
    assert(!(null is subKey));
}
body
{
    return RegDeleteKeyA(hkey, toStringz(subKey));
}

private LONG Reg_DeleteValueA_(in HKEY hkey, in string valueName)
in
{
    assert(!(null is hkey));
    assert(!(null is valueName));
}
body
{
    return RegDeleteValueA(hkey, toStringz(valueName));
}

private HKEY Reg_Dup_(HKEY hkey)
in
{
    assert(!(null is hkey));
}
body
{
    /* Can't duplicate standard keys, but don't need to, so can just return */
    if(cast(uint)hkey & 0x80000000)
    {
        switch(cast(uint)hkey)
        {
            case    HKEY_CLASSES_ROOT:
            case    HKEY_CURRENT_USER:
            case    HKEY_LOCAL_MACHINE:
            case    HKEY_USERS:
            case    HKEY_PERFORMANCE_DATA:
            case    HKEY_PERFORMANCE_TEXT:
            case    HKEY_PERFORMANCE_NLSTEXT:
            case    HKEY_CURRENT_CONFIG:
            case    HKEY_DYN_DATA:
                return hkey;
            default:
                /* Do nothing */
                break;
        }
    }

    HKEY    hkeyDup;
    LONG    lRes = RegOpenKeyA(hkey, null, hkeyDup);

    debug
    {
        if(ERROR_SUCCESS != lRes)
        {
            printf("Reg_Dup_() failed: 0x%08x 0x%08x %d\n", hkey, hkeyDup, lRes);
        }

        assert(ERROR_SUCCESS == lRes);
    }

    return (ERROR_SUCCESS == lRes) ? hkeyDup : null;
}

private LONG Reg_EnumKeyName_(  in HKEY hkey, in DWORD index, inout char [] name
                            ,   out DWORD cchName)
in
{
    assert(!(null is hkey));
    assert(!(null is name));
    assert(0 < name.length);
}
body
{
    LONG    res;

    // The Registry API lies about the lengths of a very few sub-key lengths
    // so we have to test to see if it whinges about more data, and provide 
    // more if it does.
    for(;;)
    {
        cchName = name.length;

        res = RegEnumKeyExA(hkey, index, name.ptr, cchName, RESERVED, null, null, null);

        if(ERROR_MORE_DATA != res)
        {
            break;
        }
        else
        {
            // Now need to increase the size of the buffer and try again
            name.length = 2 * name.length;
        }
    }

    return res;
}


private LONG Reg_EnumValueName_(in HKEY hkey, in DWORD dwIndex, in LPSTR lpName
                            ,   inout DWORD cchName)
in
{
    assert(!(null is hkey));
}
body
{
    return RegEnumValueA(hkey, dwIndex, lpName, cchName, RESERVED, null, null, null);
}

private LONG Reg_GetNumSubKeys_(in HKEY hkey, out DWORD cSubKeys
                            ,   out DWORD cchSubKeyMaxLen)
in
{
    assert(!(null is hkey));
}
body
{
    return RegQueryInfoKeyA(hkey, null, null, RESERVED, &cSubKeys
                        ,   &cchSubKeyMaxLen, null, null, null, null, null, null);
}

private LONG Reg_GetNumValues_( in HKEY hkey, out DWORD cValues
                            ,   out DWORD cchValueMaxLen)
in
{
    assert(!(null is hkey));
}
body
{
    return RegQueryInfoKeyA(hkey, null, null, RESERVED, null, null, null
                        ,   &cValues, &cchValueMaxLen, null, null, null);
}

private LONG Reg_GetValueType_( in HKEY hkey, in string name
                            ,   out REG_VALUE_TYPE type)
in
{
    assert(!(null is hkey));
}
body
{
    DWORD   cbData  =   0;
    LONG    res     =   RegQueryValueExA(   hkey, toStringz(name), RESERVED, type
                                        ,   cast(byte*)0, cbData);

    if(ERROR_MORE_DATA == res)
    {
        res = ERROR_SUCCESS;
    }

    return res;
}

private LONG Reg_OpenKeyExA_(   in HKEY hkey, in string subKey
                            ,   in REGSAM samDesired, out HKEY hkeyResult)
in
{
    assert(!(null is hkey));
    assert(!(null is subKey));
}
body
{
    return RegOpenKeyExA(hkey, toStringz(subKey), RESERVED, samDesired, hkeyResult);
}

private void Reg_QueryValue_(   in HKEY hkey, string name, out string value
                            ,   out REG_VALUE_TYPE type)
in
{
    assert(!(null is hkey));
}
body
{
    // See bugzilla 961 on this
    union U
    {
        uint    dw;
        ulong   qw;
    };
    U       u;
    void    *data   =   &u.qw;
    DWORD   cbData  =   U.qw.sizeof;
    LONG    res     =   RegQueryValueExA(   hkey, toStringz(name), RESERVED
                                        ,   type, data, cbData);

    if(ERROR_MORE_DATA == res)
    {
        data = (new byte[cbData]).ptr;

        res = RegQueryValueExA( hkey, toStringz(name), RESERVED, type, data
                            ,   cbData);
    }

    if(ERROR_SUCCESS != res)
    {
        throw new RegistryException("Cannot read the requested value", res);
    }
    else
    {
        switch(type)
        {
            default:
            case    REG_VALUE_TYPE.REG_BINARY:
            case    REG_VALUE_TYPE.REG_MULTI_SZ:
                throw new RegistryException("Cannot read the given value as a string");

            case    REG_VALUE_TYPE.REG_SZ:
            case    REG_VALUE_TYPE.REG_EXPAND_SZ:
                value = std.string.toString(cast(char*)data);
		if (value.ptr == cast(char*)&u.qw)
		    value = value.dup;		// don't point into the stack
                break;
version(LittleEndian)
{
            case    REG_VALUE_TYPE.REG_DWORD_LITTLE_ENDIAN:
                value = std.string.toString(u.dw);
                break;
            case    REG_VALUE_TYPE.REG_DWORD_BIG_ENDIAN:
                value = std.string.toString(swap(u.dw));
                break;
}
version(BigEndian)
{
            case    REG_VALUE_TYPE.REG_DWORD_LITTLE_ENDIAN:
                value = std.string.toString(swap(u.dw));
                break;
            case    REG_VALUE_TYPE.REG_DWORD_BIG_ENDIAN:
                value = std.string.toString(u.dw);
                break;
}
            case    REG_VALUE_TYPE.REG_QWORD_LITTLE_ENDIAN:
                value = std.string.toString(u.qw);
                break;
        }
    }
}

private void Reg_QueryValue_(   in HKEY hkey, in string name, out string[] value
                            ,   out REG_VALUE_TYPE type)
in
{
    assert(!(null is hkey));
}
body
{
    char[]  data    =   new char[256];
    DWORD   cbData  =   data.sizeof;
    LONG    res     =   RegQueryValueExA( hkey, toStringz(name), RESERVED, type
                                        , data.ptr, cbData);

    if(ERROR_MORE_DATA == res)
    {
        data.length = cbData;

        res = RegQueryValueExA(hkey, toStringz(name), RESERVED, type, data.ptr, cbData);
    }
    else if(ERROR_SUCCESS == res)
    {
        data.length = cbData;
    }

    if(ERROR_SUCCESS != res)
    {
        throw new RegistryException("Cannot read the requested value", res);
    }
    else
    {
        switch(type)
        {
            default:
                throw new RegistryException("Cannot read the given value as a string");

            case    REG_VALUE_TYPE.REG_MULTI_SZ:
                break;
        }
    }

    // Now need to tokenise it
    value = tokenise(data, cast(char)0, 1, 0);
}

private void Reg_QueryValue_(   in HKEY hkey, in string name, out uint value
                            ,   out REG_VALUE_TYPE type)
in
{
    assert(!(null is hkey));
}
body
{
    DWORD   cbData  =   value.sizeof;
    LONG    res     =   RegQueryValueExA(   hkey, toStringz(name), RESERVED, type
                                        ,   &value, cbData);

    if(ERROR_SUCCESS != res)
    {
        throw new RegistryException("Cannot read the requested value", res);
    }
    else
    {
        switch(type)
        {
            default:
                throw new RegistryException("Cannot read the given value as a 32-bit integer");

version(LittleEndian)
{
            case    REG_VALUE_TYPE.REG_DWORD_LITTLE_ENDIAN:
                assert(REG_VALUE_TYPE.REG_DWORD == REG_VALUE_TYPE.REG_DWORD_LITTLE_ENDIAN);
                break;
            case    REG_VALUE_TYPE.REG_DWORD_BIG_ENDIAN:
} // version(LittleEndian)
version(BigEndian)
{
            case    REG_VALUE_TYPE.REG_DWORD_BIG_ENDIAN:
                assert(REG_VALUE_TYPE.REG_DWORD == REG_VALUE_TYPE.REG_DWORD_BIG_ENDIAN);
                break;
            case    REG_VALUE_TYPE.REG_DWORD_LITTLE_ENDIAN:
} // version(BigEndian)
                value = swap(value);
                break;
        }
    }
}

private void Reg_QueryValue_(   in HKEY hkey, in string name, out ulong value
                            ,   out REG_VALUE_TYPE type)
in
{
    assert(!(null is hkey));
}
body
{
    DWORD   cbData  =   value.sizeof;
    LONG    res     =   RegQueryValueExA(   hkey, toStringz(name), RESERVED, type
                                        ,   &value, cbData);

    if(ERROR_SUCCESS != res)
    {
        throw new RegistryException("Cannot read the requested value", res);
    }
    else
    {
        switch(type)
        {
            default:
                throw new RegistryException("Cannot read the given value as a 64-bit integer");

            case    REG_VALUE_TYPE.REG_QWORD_LITTLE_ENDIAN:
                break;
        }
    }
}

private void Reg_QueryValue_(   in HKEY hkey, in string name, out byte[] value
                            ,   out REG_VALUE_TYPE type)
in
{
    assert(!(null is hkey));
}
body
{
    byte[]  data    =   new byte[100];
    DWORD   cbData  =   data.sizeof;
    LONG    res     =   RegQueryValueExA(   hkey, toStringz(name), RESERVED, type
                                        ,   data.ptr, cbData);

    if(ERROR_MORE_DATA == res)
    {
        data.length = cbData;

        res = RegQueryValueExA(hkey, toStringz(name), RESERVED, type, data.ptr, cbData);
    }

    if(ERROR_SUCCESS != res)
    {
        throw new RegistryException("Cannot read the requested value", res);
    }
    else
    {
        switch(type)
        {
            default:
                throw new RegistryException("Cannot read the given value as a string");

            case    REG_VALUE_TYPE.REG_BINARY:
                data.length = cbData;
                value = data;
                break;
        }
    }
}

private void Reg_SetValueExA_(  in HKEY hkey, in string subKey
                            ,   in REG_VALUE_TYPE type, in LPCVOID lpData
                            ,   in DWORD cbData)
in
{
    assert(!(null is hkey));
}
body
{
    LONG    res =   RegSetValueExA( hkey, toStringz(subKey), RESERVED, type
                                ,   lpData, cbData);

    if(ERROR_SUCCESS != res)
    {
        throw new RegistryException("Value cannot be set: \"" ~ subKey ~ "\"", res);
    }
}

/* /////////////////////////////////////////////////////////////////////////////
 * Classes
 */

////////////////////////////////////////////////////////////////////////////////
// RegistryException

/// Exception class thrown by the std.windows.registry classes
///
/// \ingroup group_D_win32_reg

public class RegistryException
    : Win32Exception
{
/// \name Construction
//@{
public:
    /// \brief Creates an instance of the exception
    ///
    /// \param message The message associated with the exception
    this(string message)
    {
        super(message);
    }
    /// \brief Creates an instance of the exception, with the given 
    ///
    /// \param message The message associated with the exception
    /// \param error The Win32 error number associated with the exception
    this(string message, int error)
    {
        super(message, error);
    }
//@}
}

unittest
{
    // (i) Test that we can throw and catch one by its own type
    try
    {
        string  message =   "Test 1";
        int     code    =   3;
        string  string  =   "Test 1 (3)";

        try
        {
            throw new RegistryException(message, code);
        }
        catch(RegistryException x)
        {
            assert(x.error == code);
            if(string != x.toString())
            {
                printf( "UnitTest failure for RegistryException:\n"
                        "  x.message [%d;\"%.*s\"] does not equal [%d;\"%.*s\"]\n"
                    ,   x.msg.length, x.msg
                    ,   string.length, string);
            }
            assert(message == x.msg);
        }
    }
    catch(Exception /* x */)
    {
        int code_flow_should_never_reach_here = 0;
        assert(code_flow_should_never_reach_here);
    }
}

////////////////////////////////////////////////////////////////////////////////
// Key

/// This class represents a registry key
///
/// \ingroup group_D_win32_reg

public class Key
{
    invariant()
    {
        assert(!(null is m_hkey));
    }

/// \name Construction
//@{
private:
    this(HKEY hkey, string name, boolean created)
    in
    {
        assert(!(null is hkey));
    }
    body
    {
        m_hkey      =   hkey;
        m_name      =   name;
        m_created   =   created;
    }

    ~this()
    {
        Reg_CloseKey_(m_hkey);

        // Even though this is horried waste-of-cycles programming
        // we're doing it here so that the 
        m_hkey = null;
    }
//@}

/// \name Attributes
//@{
public:
    /// The name of the key
    string name()
    {
        return m_name;
    }

/*  /// Indicates whether this key was created, rather than opened, by the client
    boolean Created()
    {
        return m_created;
    }
*/

    /// The number of sub keys
    uint keyCount()
    {
        uint    cSubKeys;
        uint    cchSubKeyMaxLen;
        LONG    res =   Reg_GetNumSubKeys_(m_hkey, cSubKeys, cchSubKeyMaxLen);

        if(ERROR_SUCCESS != res)
        {
            throw new RegistryException("Number of sub-keys cannot be determined", res);
        }

        return cSubKeys;
    }

    /// An enumerable sequence of all the sub-keys of this key
    KeySequence keys()
    {
        return new KeySequence(this);
    }

    /// An enumerable sequence of the names of all the sub-keys of this key
    KeyNameSequence keyNames()
    {
        return new KeyNameSequence(this);
    }

    /// The number of values
    uint valueCount()
    {
        uint    cValues;
        uint    cchValueMaxLen;
        LONG    res =   Reg_GetNumValues_(m_hkey, cValues, cchValueMaxLen);

        if(ERROR_SUCCESS != res)
        {
            throw new RegistryException("Number of values cannot be determined", res);
        }

        return cValues;
    }

    /// An enumerable sequence of all the values of this key
    ValueSequence values()
    {
        return new ValueSequence(this);
    }

    /// An enumerable sequence of the names of all the values of this key
    ValueNameSequence valueNames()
    {
        return new ValueNameSequence(this);
    }
//@}

/// \name Methods
//@{
public:
    /// Returns the named sub-key of this key
    ///
    /// \param name The name of the subkey to create. May not be null
    /// \return The created key
    /// \note If the key cannot be created, a RegistryException is thrown.
    Key createKey(string name, REGSAM access)
    {
        if( null is name ||
            0 == name.length)
        {
            throw new RegistryException("Key name is invalid");
        }
        else
        {
            HKEY    hkey;
            DWORD   disposition;
            LONG    lRes    =   Reg_CreateKeyExA_(  m_hkey, name, 0
                                                ,   REGSAM.KEY_ALL_ACCESS
                                                ,   null, hkey, disposition);

            if(ERROR_SUCCESS != lRes)
            {
                throw new RegistryException("Failed to create requested key: \"" ~ name ~ "\"", lRes);
            }

            assert(!(null is hkey));

            // Potential resource leak here!!
            //
            // If the allocation of the memory for Key fails, the HKEY could be
            // lost. Hence, we catch such a failure by the finally, and release
            // the HKEY there. If the creation of 
            try
            {
                Key key =   new Key(hkey, name, disposition == REG_CREATED_NEW_KEY);

                hkey = null;

                return key;
            }
            finally
            {
                if(hkey != null)
                {
                    Reg_CloseKey_(hkey);
                }
            }
        }
    }
    
    /// Returns the named sub-key of this key
    ///
    /// \param name The name of the subkey to create. May not be null
    /// \return The created key
    /// \note If the key cannot be created, a RegistryException is thrown.
    /// \note This function is equivalent to calling CreateKey(name, REGSAM.KEY_ALL_ACCESS), and returns a key with all access
    Key createKey(string name)
    {
        return createKey(name, cast(REGSAM)REGSAM.KEY_ALL_ACCESS);
    }

    /// Returns the named sub-key of this key
    ///
    /// \param name The name of the subkey to aquire. If name is null (or the empty-string), then the called key is duplicated
    /// \param access The desired access; one of the REGSAM enumeration
    /// \return The aquired key. 
    /// \note This function never returns null. If a key corresponding to the requested name is not found, a RegistryException is thrown
    Key getKey(string name, REGSAM access)
    {
        if( null is name ||
            0 == name.length)
        {
            return new Key(Reg_Dup_(m_hkey), m_name, false);
        }
        else
        {
            HKEY    hkey;
            LONG    lRes    =   Reg_OpenKeyExA_(m_hkey, name, REGSAM.KEY_ALL_ACCESS, hkey);

            if(ERROR_SUCCESS != lRes)
            {
                throw new RegistryException("Failed to open requested key: \"" ~ name ~ "\"", lRes);
            }

            assert(!(null is hkey));

            // Potential resource leak here!!
            //
            // If the allocation of the memory for Key fails, the HKEY could be
            // lost. Hence, we catch such a failure by the finally, and release
            // the HKEY there. If the creation of 
            try
            {
                Key key =   new Key(hkey, name, false);

                hkey = null;

                return key;
            }
            finally
            {
                if(hkey != null)
                {
                    Reg_CloseKey_(hkey);
                }
            }
        }
    }

    /// Returns the named sub-key of this key
    ///
    /// \param name The name of the subkey to aquire. If name is null (or the empty-string), then the called key is duplicated
    /// \return The aquired key. 
    /// \note This function never returns null. If a key corresponding to the requested name is not found, a RegistryException is thrown
    /// \note This function is equivalent to calling GetKey(name, REGSAM.KEY_READ), and returns a key with read/enum access
    Key getKey(string name)
    {
        return getKey(name, cast(REGSAM)(REGSAM.KEY_READ));
    }

    /// Deletes the named key
    ///
    /// \param name The name of the key to delete. May not be null
    void deleteKey(string name)
    {
        if( null is name ||
            0 == name.length)
        {
            throw new RegistryException("Key name is invalid");
        }
        else
        {
            LONG    res =   Reg_DeleteKeyA_(m_hkey, name);

            if(ERROR_SUCCESS != res)
            {
                throw new RegistryException("Value cannot be deleted: \"" ~ name ~ "\"", res);
            }
        }
    }

    /// Returns the named value
    ///
    /// \note if name is null (or the empty-string), then the default value is returned
    /// \return This function never returns null. If a value corresponding to the requested name is not found, a RegistryException is thrown
    Value getValue(string name)
    {
        REG_VALUE_TYPE  type;
        LONG            res =   Reg_GetValueType_(m_hkey, name, type);

        if(ERROR_SUCCESS == res)
        {
            return new Value(this, name, type);
        }
        else
        {
            throw new RegistryException("Value cannot be opened: \"" ~ name ~ "\"", res);
        }
    }

    /// Sets the named value with the given 32-bit unsigned integer value
    ///
    /// \param name The name of the value to set. If null, or the empty string, sets the default value
    /// \param value The 32-bit unsigned value to set
    /// \note If a value corresponding to the requested name is not found, a RegistryException is thrown
    void setValue(string name, uint value)
    {
        setValue(name, value, Endian.Ambient);
    }

    /// Sets the named value with the given 32-bit unsigned integer value, according to the desired byte-ordering
    ///
    /// \param name The name of the value to set. If null, or the empty string, sets the default value
    /// \param value The 32-bit unsigned value to set
    /// \param endian Can be Endian.Big or Endian.Little
    /// \note If a value corresponding to the requested name is not found, a RegistryException is thrown
    void setValue(string name, uint value, Endian endian)
    {
        REG_VALUE_TYPE  type    =   _RVT_from_Endian(endian);

        assert( type == REG_VALUE_TYPE.REG_DWORD_BIG_ENDIAN || 
                type == REG_VALUE_TYPE.REG_DWORD_LITTLE_ENDIAN);

        Reg_SetValueExA_(m_hkey, name, type, &value, value.sizeof);
    }

    /// Sets the named value with the given 64-bit unsigned integer value
    ///
    /// \param name The name of the value to set. If null, or the empty string, sets the default value
    /// \param value The 64-bit unsigned value to set
    /// \note If a value corresponding to the requested name is not found, a RegistryException is thrown
    void setValue(string name, ulong value)
    {
        Reg_SetValueExA_(m_hkey, name, REG_VALUE_TYPE.REG_QWORD, &value, value.sizeof);
    }

    /// Sets the named value with the given string value
    ///
    /// \param name The name of the value to set. If null, or the empty string, sets the default value
    /// \param value The string value to set
    /// \note If a value corresponding to the requested name is not found, a RegistryException is thrown
    void setValue(string name, string value)
    {
        setValue(name, value, false);
    }

    /// Sets the named value with the given string value
    ///
    /// \param name The name of the value to set. If null, or the empty string, sets the default value
    /// \param value The string value to set
    /// \param asEXPAND_SZ If true, the value will be stored as an expandable environment string, otherwise as a normal string
    /// \note If a value corresponding to the requested name is not found, a RegistryException is thrown
    void setValue(string name, string value, boolean asEXPAND_SZ)
    {
        Reg_SetValueExA_(m_hkey, name, asEXPAND_SZ 
                                            ? REG_VALUE_TYPE.REG_EXPAND_SZ
                                            : REG_VALUE_TYPE.REG_SZ, value.ptr
                        , value.length);
    }

    /// Sets the named value with the given multiple-strings value
    ///
    /// \param name The name of the value to set. If null, or the empty string, sets the default value
    /// \param value The multiple-strings value to set
    /// \note If a value corresponding to the requested name is not found, a RegistryException is thrown
    void setValue(string name, string[] value)
    {
        int total = 2;

        // Work out the length

        foreach(string s; value)
        {
            total += 1 + s.length;
        }

        // Allocate

	char[]  cs      =   new char[total];
        int     base    =   0;

        // Slice the individual strings into the new array

        foreach(string s; value)
        {
            int top = base + s.length;

            cs[base .. top] = s;
            cs[top] = 0;

            base = 1 + top;
        }

        Reg_SetValueExA_(m_hkey, name, REG_VALUE_TYPE.REG_MULTI_SZ, cs.ptr, cs.length);
    }

    /// Sets the named value with the given binary value
    ///
    /// \param name The name of the value to set. If null, or the empty string, sets the default value
    /// \param value The binary value to set
    /// \note If a value corresponding to the requested name is not found, a RegistryException is thrown
    void setValue(string name, byte[] value)
    {
        Reg_SetValueExA_(m_hkey, name, REG_VALUE_TYPE.REG_BINARY, value.ptr, value.length);
    }

    /// Deletes the named value
    ///
    /// \param name The name of the value to delete. May not be null
    /// \note If a value of the requested name is not found, a RegistryException is thrown
    void deleteValue(string name)
    {
        LONG    res =   Reg_DeleteValueA_(m_hkey, name);

        if(ERROR_SUCCESS != res)
        {
            throw new RegistryException("Value cannot be deleted: \"" ~ name ~ "\"", res);
        }
    }

    /// Flushes any changes to the key to disk
    ///
    void flush()
    {
        LONG    res =   Reg_FlushKey_(m_hkey);

        if(ERROR_SUCCESS != res)
        {
            throw new RegistryException("Key cannot be flushed", res);
        }
    }
//@}

/// \name Members
//@{
private:
    HKEY    m_hkey;
    string m_name;
    boolean m_created;
//@}
}

////////////////////////////////////////////////////////////////////////////////
// Value

/// This class represents a value of a registry key
///
/// \ingroup group_D_win32_reg

public class Value
{
    invariant()
    {
        assert(!(null is m_key));
    }

private:
    this(Key key, string name, REG_VALUE_TYPE type)
    in
    {
        assert(!(key is null));
    }
    body
    {
        m_key   =   key;
        m_type  =   type;
        m_name  =   name;
    }

/// \name Attributes
//@{
public:
    /// The name of the value.
    ///
    /// \note If the value represents a default value of a key, which has no name, the returned string will be of zero length
    string name()
    {
        return m_name;
    }

    /// The type of value
    REG_VALUE_TYPE type()
    {
        return m_type;
    }

    /// Obtains the current value of the value as a string.
    ///
    /// \return The contents of the value
    /// \note If the value's type is REG_EXPAND_SZ the returned value is <b>not</b> expanded; Value_EXPAND_SZ() should be called
    /// \note Throws a RegistryException if the type of the value is not REG_SZ, REG_EXPAND_SZ, REG_DWORD(_*) or REG_QWORD(_*):
    string value_SZ()
    {
        REG_VALUE_TYPE  type;
        string          value;

        Reg_QueryValue_(m_key.m_hkey, m_name, value, type);

        if(type != m_type)
        {
            throw new RegistryException("Value type has been changed since the value was acquired");
        }

        return value;
    }

    /// Obtains the current value as a string, within which any environment
    /// variables have undergone expansion
    ///
    /// \return The contents of the value
    /// \note This function works with the same value-types as Value_SZ().
    string value_EXPAND_SZ()
    {
        string  value   =   value_SZ;

/+
        value = expand_environment_strings(value);

        return value;
 +/
	// ExpandEnvironemntStrings():
	//	http://msdn2.microsoft.com/en-us/library/ms724265.aspx
        LPCSTR  lpSrc       =   toStringz(value);
        DWORD   cchRequired =   ExpandEnvironmentStringsA(lpSrc, null, 0);
        char[]  newValue    =   new char[cchRequired];

        if(!ExpandEnvironmentStringsA(lpSrc, newValue.ptr, newValue.length))
        {
            throw new Win32Exception("Failed to expand environment variables");
        }

        return std.string.toString(newValue.ptr);	// remove trailing 0
    }

    /// Obtains the current value as an array of strings
    ///
    /// \return The contents of the value
    /// \note Throws a RegistryException if the type of the value is not REG_MULTI_SZ
    string[] value_MULTI_SZ()
    {
        REG_VALUE_TYPE  type;
        string[]        value;

        Reg_QueryValue_(m_key.m_hkey, m_name, value, type);

        if(type != m_type)
        {
            throw new RegistryException("Value type has been changed since the value was acquired");
        }

        return value;
    }

    /// Obtains the current value as a 32-bit unsigned integer, ordered correctly according to the current architecture
    ///
    /// \return The contents of the value
    /// \note An exception is thrown for all types other than REG_DWORD, REG_DWORD_LITTLE_ENDIAN and REG_DWORD_BIG_ENDIAN.
    uint value_DWORD()
    {
        REG_VALUE_TYPE  type;
        uint            value;

        Reg_QueryValue_(m_key.m_hkey, m_name, value, type);

        if(type != m_type)
        {
            throw new RegistryException("Value type has been changed since the value was acquired");
        }

        return value;
    }

    deprecated uint value_DWORD_LITTLEENDIAN()
    {
        return value_DWORD();
    }

    deprecated uint value_DWORD_BIGENDIAN()
    {
        return value_DWORD();
    }

    /// Obtains the value as a 64-bit unsigned integer, ordered correctly according to the current architecture
    ///
    /// \return The contents of the value
    /// \note Throws a RegistryException if the type of the value is not REG_QWORD
    ulong value_QWORD()
    {
        REG_VALUE_TYPE  type;
        ulong           value;

        Reg_QueryValue_(m_key.m_hkey, m_name, value, type);

        if(type != m_type)
        {
            throw new RegistryException("Value type has been changed since the value was acquired");
        }

        return value;
    }

    deprecated ulong value_QWORD_LITTLEENDIAN()
    {
        return value_QWORD();
    }

    /// Obtains the value as a binary blob
    ///
    /// \return The contents of the value
    /// \note Throws a RegistryException if the type of the value is not REG_BINARY
    byte[]  value_BINARY()
    {
        REG_VALUE_TYPE  type;
        byte[]          value;

        Reg_QueryValue_(m_key.m_hkey, m_name, value, type);

        if(type != m_type)
        {
            throw new RegistryException("Value type has been changed since the value was acquired");
        }

        return value;
    }
//@}

/// \name Members
//@{
private:
    Key             m_key;
    REG_VALUE_TYPE  m_type;
    string         m_name;
//@}
}

////////////////////////////////////////////////////////////////////////////////
// Registry

/// Represents the local system registry.
///
/// \ingroup group_D_win32_reg

public class Registry
{
private:
    static this()
    {
        sm_keyClassesRoot       = new Key(  Reg_Dup_(HKEY_CLASSES_ROOT)
                                        ,   "HKEY_CLASSES_ROOT", false);
        sm_keyCurrentUser       = new Key(  Reg_Dup_(HKEY_CURRENT_USER)
                                        ,   "HKEY_CURRENT_USER", false);
        sm_keyLocalMachine      = new Key(  Reg_Dup_(HKEY_LOCAL_MACHINE)
                                        ,   "HKEY_LOCAL_MACHINE", false);
        sm_keyUsers             = new Key(  Reg_Dup_(HKEY_USERS)
                                        ,   "HKEY_USERS", false);
        sm_keyPerformanceData   = new Key(  Reg_Dup_(HKEY_PERFORMANCE_DATA)
                                        ,   "HKEY_PERFORMANCE_DATA", false);
        sm_keyCurrentConfig     = new Key(  Reg_Dup_(HKEY_CURRENT_CONFIG)
                                        ,   "HKEY_CURRENT_CONFIG", false);
        sm_keyDynData           = new Key(  Reg_Dup_(HKEY_DYN_DATA)
                                        ,   "HKEY_DYN_DATA", false);
    }

private:
    this() {  }

/// \name Hives
//@{
public:
    /// Returns the root key for the HKEY_CLASSES_ROOT hive
    static Key  classesRoot()       {   return sm_keyClassesRoot;       }
    /// Returns the root key for the HKEY_CURRENT_USER hive
    static Key  currentUser()       {   return sm_keyCurrentUser;       }
    /// Returns the root key for the HKEY_LOCAL_MACHINE hive
    static Key  localMachine()      {   return sm_keyLocalMachine;      }
    /// Returns the root key for the HKEY_USERS hive
    static Key  users()             {   return sm_keyUsers;             }
    /// Returns the root key for the HKEY_PERFORMANCE_DATA hive
    static Key  performanceData()   {   return sm_keyPerformanceData;   }
    /// Returns the root key for the HKEY_CURRENT_CONFIG hive
    static Key  currentConfig()     {   return sm_keyCurrentConfig;     }
    /// Returns the root key for the HKEY_DYN_DATA hive
    static Key  dynData()           {   return sm_keyDynData;           }
//@}

private:
    static Key  sm_keyClassesRoot;
    static Key  sm_keyCurrentUser;
    static Key  sm_keyLocalMachine;
    static Key  sm_keyUsers;
    static Key  sm_keyPerformanceData;
    static Key  sm_keyCurrentConfig;
    static Key  sm_keyDynData;
}

////////////////////////////////////////////////////////////////////////////////
// KeyNameSequence

/// An enumerable sequence representing the names of the sub-keys of a registry Key
///
/// It would be used as follows:
///
/// <code>&nbsp;&nbsp;Key&nbsp;key&nbsp;=&nbsp;. . .</code>
/// <br>
/// <code></code>
/// <br>
/// <code>&nbsp;&nbsp;foreach(char[] kName; key.SubKeys)</code>
/// <br>
/// <code>&nbsp;&nbsp;{</code>
/// <br>
/// <code>&nbsp;&nbsp;&nbsp;&nbsp;process_Key(kName);</code>
/// <br>
/// <code>&nbsp;&nbsp;}</code>
/// <br>
/// <br>
///
/// \ingroup group_D_win32_reg

public class KeyNameSequence
{
    invariant()
    {
        assert(!(null is m_key));
    }

/// Construction
private:
    this(Key key)
    {
        m_key = key;
    }

/// \name Attributes
///@{
public:
    /// The number of keys
    uint count()
    {
        return m_key.keyCount();
    }

    /// The name of the key at the given index
    ///
    /// \param index The 0-based index of the key to retrieve
    /// \return The name of the key corresponding to the given index
    /// \note Throws a RegistryException if no corresponding key is retrieved
    string getKeyName(uint index)
    {
        DWORD   cSubKeys;
        DWORD   cchSubKeyMaxLen;
        HKEY    hkey    =   m_key.m_hkey;
        LONG    res     =   Reg_GetNumSubKeys_(hkey, cSubKeys, cchSubKeyMaxLen);
        char[]  sName   =   new char[1 + cchSubKeyMaxLen];
        DWORD   cchName;

        assert(ERROR_SUCCESS == res);

        res = Reg_EnumKeyName_(hkey, index, sName, cchName);

        assert(ERROR_MORE_DATA != res);

        if(ERROR_SUCCESS != res)
        {
            throw new RegistryException("Invalid key", res);
        }

        return sName[0 .. cchName];
    }

    /// The name of the key at the given index
    ///
    /// \param index The 0-based index of the key to retrieve
    /// \return The name of the key corresponding to the given index
    /// \note Throws a RegistryException if no corresponding key is retrieved
    string opIndex(uint index)
    {
        return getKeyName(index);
    }
///@}

public:
    int opApply(int delegate(inout string name) dg)
    {
        int     result  =   0;
        HKEY    hkey    =   m_key.m_hkey;
        DWORD   cSubKeys;
        DWORD   cchSubKeyMaxLen;
        LONG    res     =   Reg_GetNumSubKeys_(hkey, cSubKeys, cchSubKeyMaxLen);
        char[]  sName   =   new char[1 + cchSubKeyMaxLen];

        assert(ERROR_SUCCESS == res);

        for(DWORD index = 0; 0 == result; ++index)
        {
            DWORD   cchName;

            res =   Reg_EnumKeyName_(hkey, index, sName, cchName);
            assert(ERROR_MORE_DATA != res);

            if(ERROR_NO_MORE_ITEMS == res)
            {
                // Enumeration complete

                break;
            }
            else if(ERROR_SUCCESS == res)
            {
                string name = sName[0 .. cchName];

                result = dg(name);
            }
            else
            {
                throw new RegistryException("Key name enumeration incomplete", res);

                break;
            }
        }

        return result;
    }

/// Members
private:
    Key m_key;
}


////////////////////////////////////////////////////////////////////////////////
// KeySequence

/// An enumerable sequence representing the sub-keys of a registry Key
///
/// It would be used as follows:
///
/// <code>&nbsp;&nbsp;Key&nbsp;key&nbsp;=&nbsp;. . .</code>
/// <br>
/// <code></code>
/// <br>
/// <code>&nbsp;&nbsp;foreach(Key k; key.SubKeys)</code>
/// <br>
/// <code>&nbsp;&nbsp;{</code>
/// <br>
/// <code>&nbsp;&nbsp;&nbsp;&nbsp;process_Key(k);</code>
/// <br>
/// <code>&nbsp;&nbsp;}</code>
/// <br>
/// <br>
///
/// \ingroup group_D_win32_reg

public class KeySequence
{
    invariant()
    {
        assert(!(null is m_key));
    }

/// Construction
private:
    this(Key key)
    {
        m_key = key;
    }

/// \name Attributes
///@{
public:
    /// The number of keys
    uint count()
    {
        return m_key.keyCount();
    }

    /// The key at the given index
    ///
    /// \param index The 0-based index of the key to retrieve
    /// \return The key corresponding to the given index
    /// \note Throws a RegistryException if no corresponding key is retrieved
    Key getKey(uint index)
    {
        DWORD   cSubKeys;
        DWORD   cchSubKeyMaxLen;
        HKEY    hkey    =   m_key.m_hkey;
        LONG    res     =   Reg_GetNumSubKeys_(hkey, cSubKeys, cchSubKeyMaxLen);
        char[]  sName   =   new char[1 + cchSubKeyMaxLen];
        DWORD   cchName;

        assert(ERROR_SUCCESS == res);

        res =   Reg_EnumKeyName_(hkey, index, sName, cchName);

        assert(ERROR_MORE_DATA != res);

        if(ERROR_SUCCESS != res)
        {
            throw new RegistryException("Invalid key", res);
        }

        return m_key.getKey(sName[0 .. cchName]);
    }

    /// The key at the given index
    ///
    /// \param index The 0-based index of the key to retrieve
    /// \return The key corresponding to the given index
    /// \note Throws a RegistryException if no corresponding key is retrieved
    Key opIndex(uint index)
    {
        return getKey(index);
    }
///@}

public:
    int opApply(int delegate(inout Key key) dg)
    {
        int         result  =   0;
        HKEY        hkey    =   m_key.m_hkey;
        DWORD       cSubKeys;
        DWORD       cchSubKeyMaxLen;
        LONG        res     =   Reg_GetNumSubKeys_(hkey, cSubKeys, cchSubKeyMaxLen);
        char[]      sName   =   new char[1 + cchSubKeyMaxLen];

        assert(ERROR_SUCCESS == res);

        for(DWORD index = 0; 0 == result; ++index)
        {
            DWORD   cchName;

	    res     =   Reg_EnumKeyName_(hkey, index, sName, cchName);
            assert(ERROR_MORE_DATA != res);

            if(ERROR_NO_MORE_ITEMS == res)
            {
                // Enumeration complete

                break;
            }
            else if(ERROR_SUCCESS == res)
            {
                try
                {
                    Key key =   m_key.getKey(sName[0 .. cchName]);

                    result = dg(key);
                }
                catch(RegistryException x)
                {
                    // Skip inaccessible keys; they are
                    // accessible via the KeyNameSequence
                    if(x.error == ERROR_ACCESS_DENIED)
                    {
                        continue;
                    }

                    throw x;
                }
            }
            else
            {
                throw new RegistryException("Key enumeration incomplete", res);

                break;
            }
        }

        return result;
    }

/// Members
private:
    Key m_key;
}

////////////////////////////////////////////////////////////////////////////////
// ValueNameSequence

/// An enumerable sequence representing the names of the values of a registry Key
///
/// It would be used as follows:
///
/// <code>&nbsp;&nbsp;Key&nbsp;key&nbsp;=&nbsp;. . .</code>
/// <br>
/// <code></code>
/// <br>
/// <code>&nbsp;&nbsp;foreach(char[] vName; key.Values)</code>
/// <br>
/// <code>&nbsp;&nbsp;{</code>
/// <br>
/// <code>&nbsp;&nbsp;&nbsp;&nbsp;process_Value(vName);</code>
/// <br>
/// <code>&nbsp;&nbsp;}</code>
/// <br>
/// <br>
///
/// \ingroup group_D_win32_reg

public class ValueNameSequence
{
    invariant()
    {
        assert(!(null is m_key));
    }

/// Construction
private:
    this(Key key)
    {
        m_key = key;
    }

/// \name Attributes
///@{
public:
    /// The number of values
    uint count()
    {
        return m_key.valueCount();
    }

    /// The name of the value at the given index
    ///
    /// \param index The 0-based index of the value to retrieve
    /// \return The name of the value corresponding to the given index
    /// \note Throws a RegistryException if no corresponding value is retrieved
    string getValueName(uint index)
    {
        DWORD   cValues;
        DWORD   cchValueMaxLen;
        HKEY    hkey    =   m_key.m_hkey;
        LONG    res     =   Reg_GetNumValues_(hkey, cValues, cchValueMaxLen);
        char[]  sName   =   new char[1 + cchValueMaxLen];
        DWORD   cchName =   1 + cchValueMaxLen;

        assert(ERROR_SUCCESS == res);

        res = Reg_EnumValueName_(hkey, index, sName.ptr, cchName);

        if(ERROR_SUCCESS != res)
        {
            throw new RegistryException("Invalid value", res);
        }

        return sName[0 .. cchName];
    }

    /// The name of the value at the given index
    ///
    /// \param index The 0-based index of the value to retrieve
    /// \return The name of the value corresponding to the given index
    /// \note Throws a RegistryException if no corresponding value is retrieved
    string opIndex(uint index)
    {
        return getValueName(index);
    }
///@}

public:
    int opApply(int delegate(inout string name) dg)
    {
        int     result  =   0;
        HKEY    hkey    =   m_key.m_hkey;
        DWORD   cValues;
        DWORD   cchValueMaxLen;
        LONG    res     =   Reg_GetNumValues_(hkey, cValues, cchValueMaxLen);
        char[]  sName   =   new char[1 + cchValueMaxLen];

        assert(ERROR_SUCCESS == res);

        for(DWORD index = 0; 0 == result; ++index)
        {
            DWORD   cchName =   1 + cchValueMaxLen;

	    res = Reg_EnumValueName_(hkey, index, sName.ptr, cchName);
            if(ERROR_NO_MORE_ITEMS == res)
            {
                // Enumeration complete
                break;
            }
            else if(ERROR_SUCCESS == res)
            {
                string  name = sName[0 .. cchName];

                result = dg(name);
            }
            else
            {
                throw new RegistryException("Value name enumeration incomplete", res);

                break;
            }
        }

        return result;
    }

/// Members
private:
    Key m_key;
}

////////////////////////////////////////////////////////////////////////////////
// ValueSequence

/// An enumerable sequence representing the values of a registry Key
///
/// It would be used as follows:
///
/// <code>&nbsp;&nbsp;Key&nbsp;key&nbsp;=&nbsp;. . .</code>
/// <br>
/// <code></code>
/// <br>
/// <code>&nbsp;&nbsp;foreach(Value v; key.Values)</code>
/// <br>
/// <code>&nbsp;&nbsp;{</code>
/// <br>
/// <code>&nbsp;&nbsp;&nbsp;&nbsp;process_Value(v);</code>
/// <br>
/// <code>&nbsp;&nbsp;}</code>
/// <br>
/// <br>
///
/// \ingroup group_D_win32_reg

public class ValueSequence
{
    invariant()
    {
        assert(!(null is m_key));
    }

/// Construction
private:
    this(Key key)
    {
        m_key = key;
    }

/// \name Attributes
///@{
public:
    /// The number of values
    uint count()
    {
        return m_key.valueCount();
    }

    /// The value at the given index
    ///
    /// \param index The 0-based index of the value to retrieve
    /// \return The value corresponding to the given index
    /// \note Throws a RegistryException if no corresponding value is retrieved
    Value getValue(uint index)
    {
        DWORD   cValues;
        DWORD   cchValueMaxLen;
        HKEY    hkey    =   m_key.m_hkey;
        LONG    res     =   Reg_GetNumValues_(hkey, cValues, cchValueMaxLen);
        char[]  sName   =   new char[1 + cchValueMaxLen];
        DWORD   cchName =   1 + cchValueMaxLen;

        assert(ERROR_SUCCESS == res);

        res     =   Reg_EnumValueName_(hkey, index, sName.ptr, cchName);

        if(ERROR_SUCCESS != res)
        {
            throw new RegistryException("Invalid value", res);
        }

        return m_key.getValue(sName[0 .. cchName]);
    }

    /// The value at the given index
    ///
    /// \param index The 0-based index of the value to retrieve
    /// \return The value corresponding to the given index
    /// \note Throws a RegistryException if no corresponding value is retrieved
    Value opIndex(uint index)
    {
        return getValue(index);
    }
///@}

public:
    int opApply(int delegate(inout Value value) dg)
    {
        int     result  =   0;
        HKEY    hkey    =   m_key.m_hkey;
        DWORD   cValues;
        DWORD   cchValueMaxLen;
        LONG    res     =   Reg_GetNumValues_(hkey, cValues, cchValueMaxLen);
        char[]  sName   =   new char[1 + cchValueMaxLen];

        assert(ERROR_SUCCESS == res);

        for(DWORD index = 0; 0 == result; ++index)
        {
            DWORD   cchName =   1 + cchValueMaxLen;

	    res = Reg_EnumValueName_(hkey, index, sName.ptr, cchName);
            if(ERROR_NO_MORE_ITEMS == res)
            {
                // Enumeration complete
                break;
            }
            else if(ERROR_SUCCESS == res)
            {
                Value   value   =   m_key.getValue(sName[0 .. cchName]);

                result = dg(value);
            }
            else
            {
                throw new RegistryException("Value enumeration incomplete", res);

                break;
            }
        }

        return result;
    }

/// Members
private:
    Key m_key;
}

/* ////////////////////////////////////////////////////////////////////////// */

unittest
{
    Key HKCR    =   Registry.classesRoot;
    Key CLSID   =   HKCR.getKey("CLSID");

//  foreach(Key key; CLSID.keys) // Still cannot use a property as a freachable quantity without calling the prop function
    foreach(Key key; CLSID.keys())
    {
//      foreach(Value val; key.Values) // Still cannot use a property as a freachable quantity without calling the prop function
        foreach(Value val; key.values())
        {
        }
    }
}

/* ////////////////////////////////////////////////////////////////////////// */
