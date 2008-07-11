
// Written in the D programming language.

/* /////////////////////////////////////////////////////////////////////////////
 * File:        loader.d (originally from synsoft.win32.loader)
 *
 * Purpose:     Win32 exception classes
 *
 * Created      18th October 2003
 * Updated:     24th April 2004
 *
 * Author:      Matthew Wilson
 *
 * Copyright 2004-2005 by Matthew Wilson and Synesis Software
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

/*
    Copyright for Darwin specific code

    Copyright (c) 2002 Peter O'Gorman <ogorman@users.sourceforge.net>

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
    LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
    OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
    WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/* NOTE: This file has been patched from the original DMD distribution to
   work with the GDC compiler.

   Modified by David Friedman, June 2006 (applied patches from Anders F Björklund.)
*/


/** \file D/std/loader.d This file contains the \c D standard library 
 * executable module loader library, and the ExeModule class.
 */

/* ////////////////////////////////////////////////////////////////////////// */

module std.loader;

/* /////////////////////////////////////////////////////////////////////////////
 * Imports
 */

private import std.string;
private import std.c.string;
private import std.c.stdlib;
private import std.c.stdio;

//import synsoft.types;
/+ + These are borrowed from synsoft.types, until such time as something similar is in Phobos ++
 +/
public alias int                    boolean;

/* /////////////////////////////////////////////////////////////////////////////
 * External function declarations
 */

version(linux)
    version = dlopen;
else version (freebsd)
    version = dlopen;

version(Windows)
{
    private import std.c.windows.windows;
    private import std.windows.syserror;

    extern(Windows)
    {
        alias HMODULE HModule_;
    }
}
else version(dlopen)
{
    private import std.c.linux.linux;

    extern(C)
    {
	alias void* HModule_;
    }
}
else version(darwin)
{
    extern(C)
    {
        // #include <mach-o/loader.h>

        struct mach_header
        {
            uint    magic;      /* mach magic number identifier */
            uint    cputype;    /* cpu specifier */
            uint    cpusubtype; /* machine specifier */
            uint    filetype;   /* type of file */
            uint    ncmds;      /* number of load commands */
            uint    sizeofcmds; /* the size of all the load commands */
            uint    flags;      /* flags */
        }
        
        /* Constant for the magic field of the mach_header */
        const uint MH_MAGIC = 0xfeedface;   // the mach magic number
        const uint MH_CIGAM = 0xcefaedfe;   // x86 variant
	const uint MH_MAGIC_64 = 0xfeedfacf;  // the 64-bit mach magic number
	const uint MH_CIGAM_64 = 0xcffaedfe;  // NXSwapInt(MH_MAGIC_64)

        // #include <mach-o/dyld.h>
        
        typedef void *NSObjectFileImage;
        
        typedef void *NSModule;
        
        typedef void *NSSymbol;

        enum // DYLD_BOOL: uint
        {
            FALSE,
            TRUE
        }
        alias uint DYLD_BOOL;

        enum // NSObjectFileImageReturnCode: uint
        {
            NSObjectFileImageFailure, /* for this a message is printed on stderr */
            NSObjectFileImageSuccess,
            NSObjectFileImageInappropriateFile,
            NSObjectFileImageArch,
            NSObjectFileImageFormat, /* for this a message is printed on stderr */
            NSObjectFileImageAccess
        }
        alias uint NSObjectFileImageReturnCode;
        
        enum // NSLinkEditErrors: uint
        {
            NSLinkEditFileAccessError,
            NSLinkEditFileFormatError,
            NSLinkEditMachResourceError,
            NSLinkEditUnixResourceError,
            NSLinkEditOtherError,
            NSLinkEditWarningError,
            NSLinkEditMultiplyDefinedError,
            NSLinkEditUndefinedError
        }
        alias uint NSLinkEditErrors;


        alias NSModule HModule_;
    
        NSObjectFileImageReturnCode NSCreateObjectFileImageFromFile(char *pathName, NSObjectFileImage* objectFileImage);
        DYLD_BOOL NSDestroyObjectFileImage(NSObjectFileImage objectFileImage);
   
        mach_header * NSAddImage(char *image_name, uint options);
        const uint NSADDIMAGE_OPTION_NONE = 0x0;
        const uint NSADDIMAGE_OPTION_RETURN_ON_ERROR = 0x1;
        const uint NSADDIMAGE_OPTION_WITH_SEARCHING = 0x2;
        const uint NSADDIMAGE_OPTION_RETURN_ONLY_IF_LOADED = 0x4;
        const uint NSADDIMAGE_OPTION_MATCH_FILENAME_BY_INSTALLNAME = 0x8;

        NSModule NSLinkModule(NSObjectFileImage objectFileImage, char* moduleName, uint options);
        const uint NSLINKMODULE_OPTION_NONE = 0x0;
        const uint NSLINKMODULE_OPTION_BINDNOW = 0x01;
        const uint NSLINKMODULE_OPTION_PRIVATE = 0x02;
        const uint NSLINKMODULE_OPTION_RETURN_ON_ERROR = 0x04;
        const uint NSLINKMODULE_OPTION_DONT_CALL_MOD_INIT_ROUTINES = 0x08;
        const uint NSLINKMODULE_OPTION_TRAILING_PHYS_NAME = 0x10;
        DYLD_BOOL NSUnLinkModule(NSModule module_, uint options);
    
        void NSLinkEditError(NSLinkEditErrors *c, int *errorNumber, char **fileName, char **errorString);
   
        DYLD_BOOL NSIsSymbolNameDefined(char *symbolName);
        DYLD_BOOL NSIsSymbolNameDefinedInImage(mach_header *image, char *symbolName);
        NSSymbol NSLookupAndBindSymbol(char *symbolName);
        NSSymbol NSLookupSymbolInModule(NSModule module_, char* symbolName);
        NSSymbol NSLookupSymbolInImage(mach_header *image, char *symbolName, uint options);
        const uint NSLOOKUPSYMBOLINIMAGE_OPTION_BIND = 0x0;
        const uint NSLOOKUPSYMBOLINIMAGE_OPTION_BIND_NOW = 0x1;
        const uint NSLOOKUPSYMBOLINIMAGE_OPTION_BIND_FULLY = 0x2;
        const uint NSLOOKUPSYMBOLINIMAGE_OPTION_RETURN_ON_ERROR = 0x4;

        void* NSAddressOfSymbol(NSSymbol symbol);
        char* NSNameOfSymbol(NSSymbol symbol);
    }
}
else
{
	const int platform_not_discriminated = 0;

	static assert(platform_not_discriminated);
}

/** The platform-independent module handle. Note that this has to be
 * separate from the platform-dependent handle because different module names
 * can result in the same module being loaded, which cannot be detected in
 * some operating systems
 */
typedef void    *HXModule;

/* /////////////////////////////////////////////////////////////////////////////
 * ExeModule functions
 */

/* These are "forward declared" here because I don't like the way D forces me
 * to provide my declaration and implementation together, and mixed in with all
 * the other implementation gunk.
 */

/** ExeModule library Initialisation
 *
 * \retval <0 Initialisation failed. Processing must gracefully terminate, 
 * without making any use of the ExeModule library
 * \retval 0 Initialisation succeeded for the first time. Any necessary resources
 * were successfully allocated
 * \retval >0 Initialisation has already succeefully completed via a prior call.
 */
public int ExeModule_Init()
{
    return ExeModule_Init_();
}

public void ExeModule_Uninit()
{
    ExeModule_Uninit_();
}

/** 
 *
 * \note The value of the handle returned may not be a valid handle for your operating
 * system, and you <b>must not</b> attempt to use it with any other operating system
 * or other APIs. It is only valid for use with the ExeModule library.
 */
public HXModule ExeModule_Load(in string moduleName)
{
    return ExeModule_Load_(moduleName);
}

public HXModule ExeModule_AddRef(HXModule hModule)
{
    return ExeModule_AddRef_(hModule);
}

/**
 *
 * \param hModule The module handler. It must not be null.
 */
public void ExeModule_Release(inout HXModule hModule)
{
    ExeModule_Release_(hModule);
}

public void *ExeModule_GetSymbol(inout HXModule hModule, in string symbolName)
{
    return ExeModule_GetSymbol_(hModule, symbolName);
}

public string ExeModule_Error()
{
    return ExeModule_Error_();
}


version(Windows)
{
    private int         s_init;
    private int         s_lastError;    // This is NOT thread-specific

    private void record_error_()
    {
        s_lastError = GetLastError();
    }


    private int ExeModule_Init_()
    {
        return ++s_init > 1;
    }

    private void ExeModule_Uninit_()
    {
        --s_init;
    }

    private HXModule ExeModule_Load_(in string moduleName)
    in
    {
        assert(null !is moduleName);
    }
    body
    {
        HXModule hmod = cast(HXModule)LoadLibraryA(toStringz(moduleName));

        if(null is hmod)
        {
            record_error_();
        }

        return hmod;
    }

    private HXModule ExeModule_AddRef_(HXModule hModule)
    in
    {
        assert(null !is hModule);
    }
    body
    {
        return ExeModule_Load_(ExeModule_GetPath_(hModule));
    }

    private void ExeModule_Release_(inout HXModule hModule)
    in
    {
        assert(null !is hModule);
    }
    body
    {
        if(!FreeLibrary(cast(HModule_)hModule))
        {
            record_error_();
        }
        hModule = null;
    }

    private void *ExeModule_GetSymbol_(inout HXModule hModule, in string symbolName)
    in
    {
        assert(null !is hModule);
    }
    body
    {
        void    *symbol = GetProcAddress(cast(HModule_)hModule, toStringz(symbolName));

        if(null is symbol)
        {
            record_error_();
        }

        return symbol;
    }

    private string ExeModule_Error_()
    {
	return sysErrorString(s_lastError);
    }

    private string ExeModule_GetPath_(HXModule hModule)
    {
        char    szFileName[260]; // Need to use a constant here

	// http://msdn.microsoft.com/library/default.asp?url=/library/en-us/dllproc/base/getmodulefilename.asp
        uint cch = GetModuleFileNameA(cast(HModule_)hModule, szFileName.ptr, szFileName.length);

	if (cch == 0)
	{
            record_error_();
	}
        return szFileName[0 .. cch].dup;
    }
}
else version(dlopen)
{
    private class ExeModuleInfo
    {
    public:
        int         m_cRefs;
        HModule_    m_hmod;
        string      m_name;

        this(HModule_ hmod, string name)
        {
            m_cRefs =   1;
            m_hmod  =   hmod;
            m_name  =   name;
        }
    };

    private int                     s_init;
    private ExeModuleInfo [string]  s_modules;
    private string                  s_lastError;    // This is NOT thread-specific

    private void record_error_()
    {
        char *err = dlerror();
        s_lastError = (null is err) ? "" : err[0 .. std.string.strlen(err)];
    }

    private int ExeModule_Init_()
    {
        if(1 == ++s_init)
        {

            return 0;
        }

        return 1;
    }

    private void ExeModule_Uninit_()
    {
        if(0 == --s_init)
	    {
        }
    }

    private HXModule ExeModule_Load_(in char[] moduleName)
    in
    {
        assert(null !is moduleName);
    }
    body
    {
	ExeModuleInfo*   mi_p = moduleName in s_modules;
	ExeModuleInfo   mi = mi_p is null ? null : *mi_p;

        if(null !is mi)
        {
            return (++mi.m_cRefs, cast(HXModule)mi);
        }
        else
        {
            HModule_    hmod = dlopen(toStringz(moduleName), RTLD_NOW);

            if(null is hmod)
            {
                record_error_();

                return null;
            }
            else
            {
                ExeModuleInfo   mi2  =   new ExeModuleInfo(hmod, moduleName);

                s_modules[moduleName]   =   mi2;

                return cast(HXModule)mi2;
            }
        }
    }

    private HXModule ExeModule_AddRef_(HXModule hModule)
    in
    {
        assert(null !is hModule);

        ExeModuleInfo   mi = cast(ExeModuleInfo)hModule;

        assert(0 < mi.m_cRefs);
        assert(null !is mi.m_hmod);
        assert(null !is mi.m_name);
        assert(null !is s_modules[mi.m_name]);
        assert(mi is s_modules[mi.m_name]);
    }
    body
    {
        ExeModuleInfo   mi = cast(ExeModuleInfo)hModule;

        if(null !is mi)
        {
            return (++mi.m_cRefs, hModule);
        }
        else
        {
            return null;
        }
    }

    private void ExeModule_Release_(inout HXModule hModule)
    in
    {
        assert(null !is hModule);

        ExeModuleInfo   mi = cast(ExeModuleInfo)hModule;

        assert(0 < mi.m_cRefs);
        assert(null !is mi.m_hmod);
        assert(null !is mi.m_name);
        assert(null !is s_modules[mi.m_name]);
        assert(mi is s_modules[mi.m_name]);
    }
    body
    {
        ExeModuleInfo   mi      =   cast(ExeModuleInfo)hModule;

        if(0 == --mi.m_cRefs)
        {
            string      name    =   mi.m_name;

            if (dlclose(mi.m_hmod))
            {
                record_error_();
            }
            s_modules.remove(name);
            delete mi;
        }

        hModule = null;
    }

    private void *ExeModule_GetSymbol_(inout HXModule hModule, in string symbolName)
    in
    {
        assert(null !is hModule);

        ExeModuleInfo   mi = cast(ExeModuleInfo)hModule;

        assert(0 < mi.m_cRefs);
        assert(null !is mi.m_hmod);
        assert(null !is mi.m_name);
        assert(null !is s_modules[mi.m_name]);
        assert(mi is s_modules[mi.m_name]);
    }
    body
    {
        ExeModuleInfo   mi      =   cast(ExeModuleInfo)hModule;
        void *symbol = dlsym(mi.m_hmod, toStringz(symbolName));

        if(null == symbol)
        {
            record_error_();
        }

        return symbol;
    }

    private string ExeModule_Error_()
    {
        return s_lastError;
    }

    private string ExeModule_GetPath_(HXModule hModule)
    in
    {
        assert(null !is hModule);

        ExeModuleInfo   mi = cast(ExeModuleInfo)hModule;

        assert(0 < mi.m_cRefs);
        assert(null !is mi.m_hmod);
        assert(null !is mi.m_name);
        assert(null !is s_modules[mi.m_name]);
        assert(mi is s_modules[mi.m_name]);
    }
    body
    {
        ExeModuleInfo   mi = cast(ExeModuleInfo)hModule;

        return mi.m_name;
    }
}
else version(darwin)
{
    private class ExeModuleInfo
    {
    public:
        int         m_cRefs;
        HModule_    m_hmod;
        char[]      m_name;

        this(HModule_ hmod, char[] name)
        {
            m_cRefs =   1;
            m_hmod  =   hmod;
            m_name  =   name;
        }
    };

    private void record_error_()
    {
        NSLinkEditErrors error;
        int errno;
        char *fileName;
        char *err = null;

        NSLinkEditError(&error, &errno, &fileName, &err);
        printf("NSLinkEditError: %d %d - %s %s\n", cast(uint) error, errno, fileName, err);
        
        s_lastError = (err == null) ? "" : err[0 .. std.string.strlen(err)];
    }

    private int                     s_init;
    private ExeModuleInfo [char[]]  s_modules;
    private string                  s_lastError;    // This is NOT thread-specific

    private int ExeModule_Init_()
    {
        if(1 == ++s_init)
        {
            return 0;
        }

        return 1;
    }

    private void ExeModule_Uninit_()
    {
        if(0 == --s_init)
        {
        }
    }

    private HXModule ExeModule_Load_(in char[] moduleName)
    in
    {
        assert(null !is moduleName);
    }
    body
    {
        ExeModuleInfo   *p_mi = moduleName in s_modules;

        if(p_mi != null)
        {
            return (++(*p_mi).m_cRefs, cast(HXModule)*p_mi);
        }
        else
        {
            NSModule handle = null;
            NSObjectFileImage fileImage = null;
            char * filename = toStringz(moduleName);
            // printf("DEBUG Trying to load: %s\n", filename);

            NSObjectFileImageReturnCode returnCode =
                NSCreateObjectFileImageFromFile(filename, &fileImage);
            if(returnCode == NSObjectFileImageSuccess)
            {
                handle = NSLinkModule(fileImage,filename, 
                    NSLINKMODULE_OPTION_RETURN_ON_ERROR |
                    NSLINKMODULE_OPTION_PRIVATE |
                    NSLINKMODULE_OPTION_BINDNOW);
                NSDestroyObjectFileImage(fileImage);
            }
            else if(returnCode == NSObjectFileImageInappropriateFile)
            {
                NSDestroyObjectFileImage(fileImage);
                /* Could be dynamic library rather than a bundle */
                handle = cast(NSModule) NSAddImage(filename,
                    NSADDIMAGE_OPTION_RETURN_ON_ERROR);
            }
            else
            {
                // printf("Failed: %d\n", returnCode);
                s_lastError = "NSCreateObjectFileImageFromFile failed";
                return null;
            }
            
            if (handle == null)
            {
                record_error_();
        
                return null;
            }
            else
            {
                ExeModuleInfo   mi  =   new ExeModuleInfo(handle, moduleName);

                s_modules[moduleName]   =   mi;

                return cast(HXModule)mi;
            }        
        }
    }

    private HXModule ExeModule_AddRef_(in HXModule hModule)
    in
    {
        assert(null !is hModule);

        ExeModuleInfo   mi = cast(ExeModuleInfo)hModule;

        assert(0 < mi.m_cRefs);
        assert(null !is mi.m_hmod);
        assert(null !is mi.m_name);
        assert(null !is s_modules[mi.m_name]);
        assert(mi is s_modules[mi.m_name]);
    }
    body
    {
        ExeModuleInfo   mi = cast(ExeModuleInfo)hModule;

        if(null !is mi)
        {
            return (++mi.m_cRefs, hModule);
        }
        else
        {
            return null;
        }
    }

    private void ExeModule_Release_(inout HXModule hModule)
    in
    {
        assert(null !is hModule);

        ExeModuleInfo   mi = cast(ExeModuleInfo)hModule;

        assert(0 < mi.m_cRefs);
        assert(null !is mi.m_hmod);
        assert(null !is mi.m_name);
        assert(null !is s_modules[mi.m_name]);
        assert(mi is s_modules[mi.m_name]);
    }
    body
    {
        ExeModuleInfo   mi      =   cast(ExeModuleInfo)hModule;

        if(0 == --mi.m_cRefs)
        {
            char[]      name    =   mi.m_name;
            uint        magic;
            
            magic = (* cast(mach_header *) mi.m_hmod).magic;
            if ( magic == MH_MAGIC || magic == MH_CIGAM ||
		 magic == MH_MAGIC_64 || magic == MH_CIGAM_64)
            {
                // Can not unlink dynamic libraries on Darwin
            }
            else if (NSUnLinkModule(mi.m_hmod, 0) == FALSE)
            {
                // printf("DEBUG: Could not unlink module %.*s\n", name);
            }
            s_modules.remove(name);
            delete mi;
        }

        hModule = null;
    }

    private void *ExeModule_GetSymbol_(inout HXModule hModule, in char[] symbolName)
    in
    {
        assert(null !is hModule);

        ExeModuleInfo   mi = cast(ExeModuleInfo)hModule;

        assert(0 < mi.m_cRefs);
        assert(null !is mi.m_hmod);
        assert(null !is mi.m_name);
        assert(null !is s_modules[mi.m_name]);
        assert(mi is s_modules[mi.m_name]);
    }
    body
    {
        ExeModuleInfo   mi      =   cast(ExeModuleInfo)hModule;
        
        NSModule handle = mi.m_hmod;
        uint magic = (* cast(mach_header *) handle).magic;
        char *name = ("_" ~ symbolName ~ "\0").ptr;
        NSSymbol symbol = null;
 
        if ( (handle == cast(NSModule) -1) &&
            NSIsSymbolNameDefined(name))
            /* Global context, use NSLookupAndBindSymbol */
            symbol = NSLookupAndBindSymbol(name);
        else if ( ( magic == MH_MAGIC || magic == MH_CIGAM ||
		    magic == MH_MAGIC_64 || magic == MH_CIGAM_64
		    ) &&
            NSIsSymbolNameDefinedInImage(cast(mach_header *) handle, name))
            symbol = NSLookupSymbolInImage(cast(mach_header *) handle, name,
                NSLOOKUPSYMBOLINIMAGE_OPTION_BIND |
                NSLOOKUPSYMBOLINIMAGE_OPTION_RETURN_ON_ERROR);
        else
            symbol = NSLookupSymbolInModule(handle, name);
        
        if (symbol == null)
        {
            // printf("DEBUG: Symbol not found: %s\n", name);
            return null;
        }
        
        void *address = NSAddressOfSymbol(symbol);

        if(address == null)
        {
            record_error_();
        }

        return address;
    }

    private char[] ExeModule_Error_()
    {
        return s_lastError;
    }

    private char[] ExeModule_GetPath_(HXModule hModule)
    in
    {
        assert(null !is hModule);

        ExeModuleInfo   mi = cast(ExeModuleInfo)hModule;

        assert(0 < mi.m_cRefs);
        assert(null !is mi.m_hmod);
        assert(null !is mi.m_name);
        assert(null !is s_modules[mi.m_name]);
        assert(mi is s_modules[mi.m_name]);
    }
    body
    {
        ExeModuleInfo   mi = cast(ExeModuleInfo)hModule;

        return mi.m_name;
    }
}
else
{
	const int platform_not_discriminated = 0;

	static assert(platform_not_discriminated);
}

/* /////////////////////////////////////////////////////////////////////////////
 * Classes
 */

public class ExeModuleException
    : Exception
{
public:
    this(string message)
    {
        super(message);
    }

    this(uint errcode)
    {
      version (Unix)
      {
	char[80] buf = void;
	super(std.string.toString(_d_gnu_cbridge_strerror(errcode, buf.ptr, buf.length)).dup);
      }
      else
      {
	super(std.string.toString(strerror(errcode)).dup);
      }
    }
}

/// This class represents an executable image
public auto class ExeModule
{
/// \name Construction
/// @{
public:
    /// Constructs from an existing image handle
    this(HXModule hModule, boolean bTakeOwnership)
    in
    {
        assert(null !is hModule);
    }
    body
    {
        if(bTakeOwnership)
        {
            m_hModule = hModule;
        }
        else
        {
	    version (Windows)
	    {
		string path = Path();
		m_hModule = cast(HXModule)LoadLibraryA(toStringz(path));
		if (m_hModule == null)
		    throw new ExeModuleException(GetLastError());
	    }
	    else version (dlopen)
	    {
		m_hModule = ExeModule_AddRef(hModule);
	    }
        else version (darwin)
        {
        m_hModule = ExeModule_AddRef(hModule);
        }
	    else
		static assert(0);
        }
    }

    this(string moduleName)
    in
    {
        assert(null !is moduleName);
    }
    body
    {
	version (Windows)
	{
	    m_hModule = cast(HXModule)LoadLibraryA(toStringz(moduleName));
	    if (null is m_hModule)
		throw new ExeModuleException(GetLastError());
	}
	else version (dlopen)
	{
	    m_hModule = ExeModule_Load(moduleName);
	    if (null is m_hModule)
		throw new ExeModuleException(ExeModule_Error());
	}
    else version (darwin)
    {
        m_hModule = ExeModule_Load(moduleName);
        if (null is m_hModule)
        throw new ExeModuleException(ExeModule_Error());
    }
	else
	{
	    static assert(0);		// unsupported system
	}
    }
    ~this()
    {
        close();
    }
/// @}

/// \name Operations
/// @{
public:
    /// Closes the library
    ///
    /// \note This is available to close the module at any time. Repeated
    /// calls do not result in an error, and are simply ignored.
    void close()
    {
        if(null !is m_hModule)
        {
	    version (Windows)
	    {
		if(!FreeLibrary(cast(HModule_)m_hModule))
		    throw new ExeModuleException(GetLastError());
	    }
	    else version (dlopen)
	    {
		ExeModule_Release(m_hModule);
	    }
        else version (darwin)
        {
        ExeModule_Release(m_hModule);
        }
	    else
		static assert(0);
        }
    }
/// @}

/// \name Accessors
/// @{
public:
    /** Retrieves the named symbol.
     *
     * \return A pointer to the symbol. There is no null return - failure to retrieve the symbol
     * results in an ExeModuleException exception being thrown.
     */
    void *getSymbol(in string symbolName)
    {
	version (Windows)
	{
	    void *symbol = GetProcAddress(cast(HModule_)m_hModule, toStringz(symbolName));
	    if(null is symbol)
	    {
		throw new ExeModuleException(GetLastError());
	    }
	}
	else version (dlopen)
	{
	    void *symbol = ExeModule_GetSymbol(m_hModule, symbolName);

	    if(null is symbol)
	    {
		throw new ExeModuleException(ExeModule_Error());
	    }
	}
    else version (darwin)
    {
        void *symbol = ExeModule_GetSymbol(m_hModule, symbolName);

        if(null is symbol)
        {
        throw new ExeModuleException(ExeModule_Error());
        }
    }
	else
	{
	    static assert(0);
	}

        return symbol;
    }

    /** Retrieves the named symbol.
     *
     * \return A pointer to the symbol, or null if it does not exist
     */
    void *findSymbol(in string symbolName)
    {
        return ExeModule_GetSymbol(m_hModule, symbolName);
    }

/// @}

/// \name Properties
/// @{
public:
    /// The handle of the module
    ///
    /// \note Will be \c null if the module load in the constructor failed
    HXModule Handle()
    {
        return m_hModule;
    }
    /// The handle of the module
    ///
    /// \note Will be \c null if the module load in the constructor failed
    string Path()
    {
        assert(null != m_hModule);

	version (Windows)
	{
	    char szFileName[260]; // Need to use a constant here

	    // http://msdn.microsoft.com/library/default.asp?url=/library/en-us/dllproc/base/getmodulefilename.asp
	    uint cch = GetModuleFileNameA(cast(HModule_)m_hModule, szFileName.ptr, szFileName.length);
	    if (cch == 0)
		throw new ExeModuleException(GetLastError());

	    return szFileName[0 .. cch].dup;
	}
	else version (dlopen)
	{
	    return ExeModule_GetPath_(m_hModule);
	}
    else version (darwin)
    {
        return ExeModule_GetPath_(m_hModule);
    }
	else
	    static assert(0);
    }
/// @}

private:
    HXModule m_hModule;
};

/* ////////////////////////////////////////////////////////////////////////// */

version(TestMain)
{
    int main(string[] args)
    {
        if(args.length < 3)
        {
            printf("USAGE: <moduleName> <symbolName>\n");
        }
        else
        {
            string  moduleName  =   args[1];
            string  symbolName  =   args[2];

            try
            {
                auto ExeModule xmod =   new ExeModule(moduleName);

                printf("\"%.*s\" is loaded\n", cast(int) moduleName.length,
		    moduleName.ptr);

                void    *symbol =   xmod.getSymbol(symbolName);

                if(null == symbol)
                {
                    throw new ExeModuleException(ExeModule_Error());
                }
                else
                {
                    printf("\"%.*s\" is acquired\n", symbolName);
                }
            }
            catch(ExeModuleException x)
            {
                x.print();
            }
        }

        return 0;
    }
}

/* ////////////////////////////////////////////////////////////////////////// */
