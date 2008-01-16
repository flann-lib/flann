/*******************************************************************************

        copyright:      Copyright (c) 2007 Tango. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Feb 2007: Initial release

        author:         Deewiant, Maxter, Gregor, Kris

*******************************************************************************/

module tango.sys.Environment;

private import  tango.sys.Common;

private import  tango.io.FilePath,
                tango.io.FileConst,
                tango.io.FileSystem;

private import  tango.core.Exception;

private import  Text = tango.text.Util;

/*******************************************************************************

*******************************************************************************/

version (Windows)
{
        private import tango.text.convert.Utf;

        pragma (lib, "kernel32.lib");

        extern (Windows)
        {
                private void* GetEnvironmentStringsW();
                private bool FreeEnvironmentStringsW(wchar**);
        }
        extern (Windows)
        {
                private int SetEnvironmentVariableW(wchar*, wchar*);
                private uint GetEnvironmentVariableW(wchar*, wchar*, uint);
                private const int ERROR_ENVVAR_NOT_FOUND = 203;
        }
}
else
{
    private extern (C) extern char** environ;

    import tango.stdc.posix.stdlib;
    import tango.stdc.string;
}


/*******************************************************************************

        Exposes the system Environment settings, along with some handy
        utilities

*******************************************************************************/

struct Environment
{
        /***********************************************************************

                Returns the full path location of the provided executable
                file, rifling through the PATH as necessary.

                Returns null if the provided filename was not found

        ***********************************************************************/

        static FilePath exePath (char[] file)
        {
                auto bin = new FilePath (file);

                // on Windows, this is a .exe
                version (Windows)
                         if (bin.ext.length is 0)
                             bin.append (".exe");

                // is this a directory? Potentially make it absolute
                if (bin.isChild)
                    return FileSystem.toAbsolute (bin);

                // is it in cwd?
                version (Windows)
                         if (bin.path(FileSystem.getDirectory).exists)
                             return bin;

                // rifle through the path
                foreach (pe; Text.patterns (get("PATH"), FileConst.SystemPathString))
                         if (bin.path(pe).exists)
                             version (Windows)
                                      return bin;
                                  else
                                     {
                                     stat_t stats;
                                     stat(bin.cString.ptr, &stats);
                                     if (stats.st_mode & 0100)
                                         return bin;
                                     }
                return null;
        }


        version (Win32)
        {
                /**************************************************************

                        Returns the provided 'def' value if the variable 
                        does not exist

                **************************************************************/

                static char[] get (char[] variable, char[] def = null)
                {
                        wchar[] var = toString16(variable) ~ "\0";

                        uint size = GetEnvironmentVariableW(var.ptr, cast(wchar*)null, 0);
                        if (size is 0)
                           {
                           if (SysError.lastCode is ERROR_ENVVAR_NOT_FOUND)
                               return def;
                           else
                              throw new PlatformException (SysError.lastMsg);
                           }

                        auto buffer = new wchar[size];
                        size = GetEnvironmentVariableW(var.ptr, buffer.ptr, size);
                        if (size is 0)
                            throw new PlatformException (SysError.lastMsg);

                        return toString (buffer[0 .. size]);
                }

                /**************************************************************

                        clears the variable if value is null or empty

                **************************************************************/

                static void set (char[] variable, char[] value = null)
                {
                        wchar * var, val;

                        var = (toString16 (variable) ~ "\0").ptr;

                        if (value.length > 0)
                            val = (toString16 (value) ~ "\0").ptr;

                        if (! SetEnvironmentVariableW(var, val))
                              throw new PlatformException (SysError.lastMsg);
                }

                /**************************************************************

                **************************************************************/

                static char[][char[]] get ()
                {
                        char[][char[]] arr;

                        wchar[] key = new wchar[20],
                                value = new wchar[40];

                        wchar** env = cast(wchar**) GetEnvironmentStringsW();
                        scope (exit)
                               FreeEnvironmentStringsW (env);

                        for (wchar* str = cast(wchar*) env; *str; ++str)
                            {
                            size_t k = 0, v = 0;

                            while (*str != '=')
                                  {
                                  key[k++] = *str++;

                                  if (k is key.length)
                                      key.length = 2 * key.length;
                                  }

                            ++str;

                            while (*str)
                                  {
                                  value [v++] = *str++;

                                  if (v is value.length)
                                      value.length = 2 * value.length;
                                  }

                            arr [toString(key[0 .. k])] = toString(value[0 .. v]);
                            }

                        return arr;
                }
        }
        else // POSIX
        {
                /**************************************************************

                        Returns the provided 'def' value if the variable 
                        does not exist

                **************************************************************/

                static char[] get (char[] variable, char[] def = null)
                {
                        char* ptr = getenv (variable.ptr);

                        if (ptr is null)
                            return def;

                        return ptr[0 .. strlen(ptr)].dup;
                }

                /**************************************************************

                        clears the variable, if value is null or empty
        
                **************************************************************/

                static void set (char[] variable, char[] value = null)
                {
                        int result;

                        if (value.length is 0)
                            unsetenv ((variable ~ '\0').ptr);
                        else
                           result = setenv ((variable ~ '\0').ptr, (value ~ '\0').ptr, 1);

                        if (result != 0)
                            throw new PlatformException (SysError.lastMsg);
                }

                /**************************************************************

                **************************************************************/

                static char[][char[]] get ()
                {
                        char[][char[]] arr;

                        for (char** p = environ; *p; ++p)
                            {
                            size_t k = 0;
                            char* str = *p;

                            while (*str++ != '=')
                                   ++k;
                            char[] key = (*p)[0..k];

                            k = 0;
                            char* val = str;
                            while (*str++)
                                   ++k;
                            arr[key] = val[0 .. k];
                            }

                        return arr;
                }
        }
}

debug (Environment)
{
        import tango.io.Console;


        void main(char[][] args)
        {
        const char[] VAR = "TESTENVVAR";
        const char[] VAL1 = "VAL1";
        const char[] VAL2 = "VAL2";

        assert(Environment.get(VAR) is null);

        Environment.set(VAR, VAL1);
        assert(Environment.get(VAR) == VAL1);

        Environment.set(VAR, VAL2);
        assert(Environment.get(VAR) == VAL2);

        Environment.set(VAR, null);
        assert(Environment.get(VAR) is null);

        Environment.set(VAR, VAL1);
        Environment.set(VAR, "");

        assert(Environment.get(VAR) is null);

        foreach (key, value; Environment.get)
                 Cout (key) ("=") (value).newline;

        if (args.length > 0)
           {
           auto p = Environment.exePath (args[0]);
           Cout (p).newline;
           }

        if (args.length > 1)
           {
           if (auto p = Environment.exePath (args[1]))
               Cout (p).newline;
           }
        }
}

