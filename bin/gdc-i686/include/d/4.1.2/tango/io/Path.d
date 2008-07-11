/*******************************************************************************

        copyright:      Copyright (c) 2008 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mar 2008: Initial version

        author:         Kris

        A more direct route to the file-system than FilePath, but with 
        the potential overhead of heap activity. Use this if you don't
        need path editing or extraction features. For example, if all
        you want is to see if some path exists, using this module might 
        be a more convenient option than FilePath:
        ---
        if (exists ("my file path")) 
            ...
        ---

        These functions are generally less efficient than FilePath because 
        they have to attach a null to the filename for each underlying O/S
        call. Use Path when you need pedestrian access to the file-system, 
        and are not manipulating the path components. Use FilePath for other
        scenarios.

        We encourage the use of "scoped import" with this module, such as
        ---
        import Path = tango.io.Path;

        if (Path.exists ("my file path")) 
            ...
        ---

        Compile with -version=Win32SansUnicode to enable Win95 & Win32s file
        support.

*******************************************************************************/

module tango.io.Path;

private import  tango.sys.Common;

public  import  tango.time.Time : Time, TimeSpan;

public  import  tango.core.Exception : IOException;


/*******************************************************************************

        Various imports

*******************************************************************************/

version (Win32)
        {
        version (Win32SansUnicode)
                {
                private extern (C) int strlen (char *s);
                private alias WIN32_FIND_DATA FIND_DATA;
                }
             else
                {
                private extern (C) int wcslen (wchar *s);
                private alias WIN32_FIND_DATAW FIND_DATA;
                }
        }

version (Posix)
        {
        private import tango.stdc.stdio;
        private import tango.stdc.string;
        private import tango.stdc.posix.utime;
        private import tango.stdc.posix.dirent;
        }


/*******************************************************************************

        Wraps the O/S specific calls with a D API. Note that these accept
        null-terminated strings only, which is why it's not public. We need 
        this declared first to avoid forward-reference issues

*******************************************************************************/

package struct FS
{
        /***********************************************************************

                TimeStamp information. Accurate to whatever the F/S supports

        ***********************************************************************/

        struct Stamps
        {
                Time    created,        /// time created
                        accessed,       /// last time accessed
                        modified;       /// last time modified
        }

        /***********************************************************************

                Passed around during file-scanning

        ***********************************************************************/

        struct FileInfo
        {
                char[]  path,
                        name;
                ulong   bytes;
                bool    folder;
        }

        /***********************************************************************

                Some fruct glue for directory listings

        ***********************************************************************/

        struct Listing
        {
                char[] folder;

                int opApply (int delegate(ref FileInfo) dg)
                {
                        return list (folder, dg);
                }
        }

        /***********************************************************************

                Throw an exception using the last known error

        ***********************************************************************/

        static void exception (char[] filename)
        {
                throw new IOException (filename[0..$-1] ~ ": " ~ SysError.lastMsg);
        }

        /***********************************************************************

                Return an adjusted path such that non-empty instances always
                have a trailing separator

        ***********************************************************************/

        static char[] padded (char[] path, char c = '/')
        {
                if (path.length && path[$-1] != c)
                    path = path ~ c;
                return path;
        }

        /***********************************************************************

                Return an adjusted path such that non-empty instances do not
                have a trailing separator

        ***********************************************************************/

        static char[] stripped (char[] path, char c = '/')
        {
                if (path.length && path[$-1] is c)
                    path = path [0 .. $-1];
                return path;
        }

        /***********************************************************************

                Join a set of path specs together. A path separator is
                potentially inserted between each of the segments.

        ***********************************************************************/

        static char[] join (char[][] paths...)
        {
                char[] result;

                foreach (path; paths)
                         result ~= padded (path);

                return result.length ? result [0 .. $-1] : "";
        }

        /***********************************************************************

                Append a terminating null onto a string, cheaply where 
                feasible

        ***********************************************************************/

        static char[] strz (char[] src, char[] dst)
        {
                auto i = src.length + 1;
                if (dst.length < i)
                    dst.length = i;
                dst [0 .. i-1] = src;
                dst[i-1] = 0;
                return dst [0 .. i];
        }

        /***********************************************************************

                Win32 API code

        ***********************************************************************/

        version (Win32)
        {
                /***************************************************************

                        return a wchar[] instance of the path

                ***************************************************************/

                private static wchar[] toString16 (wchar[] tmp, char[] path)
                {
                        auto i = MultiByteToWideChar (CP_UTF8, 0,
                                                      path.ptr, path.length,
                                                      tmp.ptr, tmp.length);
                        return tmp [0..i];
                }

                /***************************************************************

                        return a char[] instance of the path

                ***************************************************************/

                private static char[] toString (char[] tmp, wchar[] path)
                {
                        auto i = WideCharToMultiByte (CP_UTF8, 0, path.ptr, path.length,
                                                      tmp.ptr, tmp.length, null, null);
                        return tmp [0..i];
                }

                /***************************************************************

                        Get info about this path

                ***************************************************************/

                private static bool fileInfo (char[] name, inout WIN32_FILE_ATTRIBUTE_DATA info)
                {
                        version (Win32SansUnicode)
                                {
                                if (! GetFileAttributesExA (name.ptr, GetFileInfoLevelStandard, &info))
                                      return false;
                                }
                             else
                                {
                                wchar[MAX_PATH] tmp = void;
                                if (! GetFileAttributesExW (toString16(tmp, name).ptr, GetFileInfoLevelStandard, &info))
                                      return false;
                                }

                        return true;
                }

                /***************************************************************

                        Get info about this path

                ***************************************************************/

                private static DWORD getInfo (char[] name, inout WIN32_FILE_ATTRIBUTE_DATA info)
                {
                        if (! fileInfo (name, info))
                              exception (name);
                        return info.dwFileAttributes;
                }

                /***************************************************************

                        Get flags for this path

                ***************************************************************/

                private static DWORD getFlags (char[] name)
                {
                        WIN32_FILE_ATTRIBUTE_DATA info = void;

                        return getInfo (name, info);
                }

                /***************************************************************

                        Return whether the file or path exists

                ***************************************************************/

                static bool exists (char[] name)
                {
                        WIN32_FILE_ATTRIBUTE_DATA info = void;

                        return fileInfo (name, info);
                }

                /***************************************************************

                        Return the file length (in bytes)

                ***************************************************************/

                static ulong fileSize (char[] name)
                {
                        WIN32_FILE_ATTRIBUTE_DATA info = void;

                        getInfo (name, info);
                        return (cast(ulong) info.nFileSizeHigh << 32) +
                                            info.nFileSizeLow;
                }

                /***************************************************************

                        Is this file writable?

                ***************************************************************/

                static bool isWritable (char[] name)
                {
                        return (getFlags(name) & FILE_ATTRIBUTE_READONLY) == 0;
                }

                /***************************************************************

                        Is this file actually a folder/directory?

                ***************************************************************/

                static bool isFolder (char[] name)
                {
                        return (getFlags(name) & FILE_ATTRIBUTE_DIRECTORY) != 0;
                }

                /***************************************************************

                        Return timestamp information

                        Timstamps are returns in a format dictated by the 
                        file-system. For example NTFS keeps UTC time, 
                        while FAT timestamps are based on the local time

                ***************************************************************/

                static Stamps timeStamps (char[] name)
                {
                        static Time convert (FILETIME time)
                        {
                                return Time (TimeSpan.Epoch1601 + *cast(long*) &time);
                        }

                        WIN32_FILE_ATTRIBUTE_DATA info = void;
                        Stamps                    time = void;

                        getInfo (name, info);
                        time.modified = convert (info.ftLastWriteTime);
                        time.accessed = convert (info.ftLastAccessTime);
                        time.created  = convert (info.ftCreationTime);
                        return time;
                }

                /***************************************************************

                        Transfer the content of another file to this one. 
                        Returns a reference to this class on success, or 
                        throws an IOException upon failure.

                ***************************************************************/

                static void copy (char[] src, char[] dst)
                {
                        version (Win32SansUnicode)
                                {
                                if (! CopyFileA (src.ptr, dst.ptr, false))
                                      exception (src);
                                }
                             else
                                {
                                wchar[MAX_PATH+1] tmp1 = void;
                                wchar[MAX_PATH+1] tmp2 = void;

                                if (! CopyFileW (toString16(tmp1, src).ptr, toString16(tmp2, dst).ptr, false))
                                      exception (src);
                                }
                }

                /***************************************************************

                        Remove the file/directory from the file-system

                ***************************************************************/

                static void remove (char[] name)
                {
                        if (isFolder(name))
                           {
                           version (Win32SansUnicode)
                                   {
                                   if (! RemoveDirectoryA (name.ptr))
                                         exception (name);
                                   }
                                else
                                   {
                                   wchar[MAX_PATH] tmp = void;
                                   if (! RemoveDirectoryW (toString16(tmp, name).ptr))
                                         exception (name);
                                   }
                           }
                        else
                           version (Win32SansUnicode)
                                   {
                                   if (! DeleteFileA (name.ptr))
                                         exception (name);
                                   }
                                else
                                   {
                                   wchar[MAX_PATH] tmp = void;
                                   if (! DeleteFileW (toString16(tmp, name).ptr))
                                         exception (name);
                                   }
                }

                /***************************************************************

                       change the name or location of a file/directory, and
                       adopt the provided Path

                ***************************************************************/

                static void rename (char[] src, char[] dst)
                {
                        const int Typical = MOVEFILE_REPLACE_EXISTING +
                                            MOVEFILE_COPY_ALLOWED     +
                                            MOVEFILE_WRITE_THROUGH;

                        int result;
                        version (Win32SansUnicode)
                                 result = MoveFileExA (src.ptr, dst.ptr, Typical);
                             else
                                {
                                wchar[MAX_PATH] tmp1 = void;
                                wchar[MAX_PATH] tmp2 = void;
                                result = MoveFileExW (toString16(tmp1, src).ptr, toString16(tmp2, dst).ptr, Typical);
                                }

                        if (! result)
                              exception (src);
                }

                /***************************************************************

                        Create a new file

                ***************************************************************/

                static void createFile (char[] name)
                {
                        HANDLE h;

                        version (Win32SansUnicode)
                                 h = CreateFileA (name.ptr, GENERIC_WRITE,
                                                  0, null, CREATE_ALWAYS,
                                                  FILE_ATTRIBUTE_NORMAL, cast(HANDLE) 0);
                             else
                                {
                                wchar[MAX_PATH] tmp = void;
                                h = CreateFileW (toString16(tmp, name).ptr, GENERIC_WRITE,
                                                 0, null, CREATE_ALWAYS,
                                                 FILE_ATTRIBUTE_NORMAL, cast(HANDLE) 0);
                                }

                        if (h == INVALID_HANDLE_VALUE)
                            exception (name);

                        if (! CloseHandle (h))
                              exception (name);
                }

                /***************************************************************

                        Create a new directory

                ***************************************************************/

                static void createFolder (char[] name)
                {
                        version (Win32SansUnicode)
                                {
                                if (! CreateDirectoryA (name.ptr, null))
                                      exception (name);
                                }
                             else
                                {
                                wchar[MAX_PATH] tmp = void;
                                if (! CreateDirectoryW (toString16(tmp, name).ptr, null))
                                      exception (name);
                                }
                }

                /***************************************************************

                        List the set of filenames within this folder.

                        Each path and filename is passed to the provided
                        delegate, along with the path prefix and whether
                        the entry is a folder or not.

                        Returns the number of files scanned.

                ***************************************************************/

                static int list (char[] folder, int delegate(ref FileInfo) dg)
                {
                        HANDLE                  h;
                        int                     ret;
                        char[]                  prefix;
                        char[MAX_PATH+1]        tmp = void;
                        FIND_DATA               fileinfo = void;
                        
                        version (Win32SansUnicode)
                                 alias char T;
                              else
                                 alias wchar T;

                        int next()
                        {
                                version (Win32SansUnicode)
                                         return FindNextFileA (h, &fileinfo);
                                   else
                                      return FindNextFileW (h, &fileinfo);
                        }

                        static T[] padded (T[] s, T[] ext)
                        {
                                if (s.length is 0 || s[$-1] != '\\')
                                    return s ~ "\\" ~ ext;
                                return s ~ ext;
                        }

                        version (Win32SansUnicode)
                                 h = FindFirstFileA (padded(folder[0..$-1], "*\0").ptr, &fileinfo);
                             else
                                {
                                wchar[MAX_PATH] host = void;
                                h = FindFirstFileW (padded(toString16(host, folder[0..$-1]), "*\0").ptr, &fileinfo);
                                }

                        if (h is INVALID_HANDLE_VALUE)
                            exception (folder);

                        scope (exit)
                               FindClose (h);

                        prefix = FS.padded (folder[0..$-1]);
                        do {
                           version (Win32SansUnicode)
                                   {
                                   auto len = strlen (fileinfo.cFileName.ptr);
                                   auto str = fileinfo.cFileName.ptr [0 .. len];
                                   }
                                else
                                   {
                                   auto len = wcslen (fileinfo.cFileName.ptr);
                                   auto str = toString (tmp, fileinfo.cFileName [0 .. len]);
                                   }

                           // skip hidden/system files
                           if ((fileinfo.dwFileAttributes & (FILE_ATTRIBUTE_SYSTEM | FILE_ATTRIBUTE_HIDDEN)) is 0)
                              {
                              FileInfo info = void;
                              info.name   = str;
                              info.path   = prefix;
                              info.bytes  = (cast(ulong) fileinfo.nFileSizeHigh << 32) + fileinfo.nFileSizeLow;
                              info.folder = (fileinfo.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0;

                              // skip "..." names
                              if (str.length > 3 || str != "..."[0 .. str.length])
                                  if ((ret = dg(info)) != 0)
                                       break;
                              }
                           } while (next);

                        return ret;
                }
        }

        /***********************************************************************

                Posix-specific code

        ***********************************************************************/

        version (Posix)
        {
                /***************************************************************

                        Get info about this path

                ***************************************************************/

                private static uint getInfo (char[] name, inout stat_t stats)
                {
                        if (posix.stat (name.ptr, &stats))
                            exception (name);

                        return stats.st_mode;
                }

                /***************************************************************

                        Return whether the file or path exists

                ***************************************************************/

                static bool exists (char[] name)
                {
                        stat_t stats = void;
                        return posix.stat (name.ptr, &stats) is 0;
                }

                /***************************************************************

                        Return the file length (in bytes)

                ***************************************************************/

                static ulong fileSize (char[] name)
                {
                        stat_t stats = void;

                        getInfo (name, stats);
                        return cast(ulong) stats.st_size;    // 32 bits only
                }

                /***************************************************************

                        Is this file writable?

                ***************************************************************/

                static bool isWritable (char[] name)
                {
                        stat_t stats = void;

                        return (getInfo(name, stats) & O_RDONLY) == 0;
                }

                /***************************************************************

                        Is this file actually a folder/directory?

                ***************************************************************/

                static bool isFolder (char[] name)
                {
                        stat_t stats = void;

                        return (getInfo(name, stats) & S_IFDIR) != 0;
                }

                /***************************************************************

                        Return timestamp information

                        Timstamps are returns in a format dictated by the 
                        file-system. For example NTFS keeps UTC time, 
                        while FAT timestamps are based on the local time

                ***************************************************************/

                static Stamps timeStamps (char[] name)
                {
                        static Time convert (timeval* tv)
                        {
                                return Time.epoch1970 +
                                       TimeSpan.seconds(tv.tv_sec) +
                                       TimeSpan.micros(tv.tv_usec);
                        }

                        stat_t stats = void;
                        Stamps time  = void;

                        getInfo (name, stats);

                        time.modified = convert (cast(timeval*) &stats.st_mtime);
                        time.accessed = convert (cast(timeval*) &stats.st_atime);
                        time.created  = convert (cast(timeval*) &stats.st_ctime);
                        return time;
                }

                /***********************************************************************

                        Transfer the content of another file to this one. Returns a
                        reference to this class on success, or throws an IOException
                        upon failure.

                ***********************************************************************/

                static void copy (char[] source, char[] dest)
                {
                        auto src = posix.open (source.ptr, O_RDONLY, 0640);
                        scope (exit)
                               if (src != -1)
                                   posix.close (src);

                        auto dst = posix.open (dest.ptr, O_CREAT | O_RDWR, 0660);
                        scope (exit)
                               if (dst != -1)
                                   posix.close (dst);

                        if (src is -1 || dst is -1)
                            exception (source);

                        // copy content
                        ubyte[] buf = new ubyte [16 * 1024];
                        int read = posix.read (src, buf.ptr, buf.length);
                        while (read > 0)
                              {
                              auto p = buf.ptr;
                              do {
                                 int written = posix.write (dst, p, read);
                                 p += written;
                                 read -= written;
                                 if (written is -1)
                                     exception (dest);
                                 } while (read > 0);
                              read = posix.read (src, buf.ptr, buf.length);
                              }
                        if (read is -1)
                            exception (source);

                        // copy timestamps
                        stat_t stats;
                        if (posix.stat (source.ptr, &stats))
                            exception (source);

                        utimbuf utim;
                        utim.actime = stats.st_atime;
                        utim.modtime = stats.st_mtime;
                        if (utime (dest.ptr, &utim) is -1)
                            exception (dest);
                }

                /***************************************************************

                        Remove the file/directory from the file-system

                ***************************************************************/

                static void remove (char[] name)
                {
                        if (isFolder (name))
                           {
                           if (posix.rmdir (name.ptr))
                               exception (name);
                           }
                        else
                           if (tango.stdc.stdio.remove (name.ptr) == -1)
                               exception (name);
                }

                /***************************************************************

                       change the name or location of a file/directory, and
                       adopt the provided FilePath

                ***************************************************************/

                static void rename (char[] src, char[] dst)
                {
                        if (tango.stdc.stdio.rename (src.ptr, dst.ptr) == -1)
                            exception (src);
                }

                /***************************************************************

                        Create a new file

                ***************************************************************/

                static void createFile (char[] name)
                {
                        int fd;

                        fd = posix.open (name.ptr, O_CREAT | O_WRONLY | O_TRUNC, 0660);
                        if (fd == -1)
                            exception (name);

                        if (posix.close(fd) == -1)
                            exception (name);
                }

                /***************************************************************

                        Create a new directory

                ***************************************************************/

                static void createFolder (char[] name)
                {
                        if (posix.mkdir (name.ptr, 0777))
                            exception (name);
                }
                /***************************************************************

                        List the set of filenames within this folder.

                        Each path and filename is passed to the provided
                        delegate, along with the path prefix and whether
                        the entry is a folder or not.

                        Returns the number of files scanned.

                ***************************************************************/

                static int list (char[] folder, int delegate(ref FileInfo) dg)
                {
                        int             ret;
                        DIR*            dir;
                        dirent          entry;
                        dirent*         pentry;
                        stat_t          sbuf;
                        char[]          prefix;
                        char[]          sfnbuf;

                        dir = tango.stdc.posix.dirent.opendir (folder.ptr);
                        if (! dir)
                              exception (folder);

                        scope (exit)
                               tango.stdc.posix.dirent.closedir (dir);

                        // ensure a trailing '/' is present
                        prefix = FS.padded (folder[0..$-1]);

                        // prepare our filename buffer
                        sfnbuf = prefix.dup;
                        
                        // pentry is null at end of listing, or on an error 
                        while (readdir_r (dir, &entry, &pentry), pentry !is null)
                              {
                              auto len = tango.stdc.string.strlen (entry.d_name.ptr);
                              auto str = entry.d_name.ptr [0 .. len];
                              ++len;  // include the null

                              // resize the buffer as necessary ...
                              if (sfnbuf.length < prefix.length + len)
                                  sfnbuf.length = prefix.length + len;

                              sfnbuf [prefix.length .. prefix.length + len]
                                      = entry.d_name.ptr [0 .. len];

                              // skip "..." names
                              if (str.length > 3 || str != "..."[0 .. str.length])
                                 {
                                 if (stat (sfnbuf.ptr, &sbuf))
                                     exception (folder);

                                 FileInfo info = void;
                                 info.name   = str;
                                 info.path   = prefix;
                                 info.folder = (sbuf.st_mode & S_IFDIR) != 0;
                                 info.bytes  = cast(ulong) 
                                               ((sbuf.st_mode & S_IFREG) != 0 ? sbuf.st_size : 0);

                                 if ((ret = dg(info)) != 0)
                                      break;
                                 }
                              }
                        return ret;
                }
        }
}


/*******************************************************************************

        Does this path currently exist?

*******************************************************************************/

bool exists (char[] name)
{
        char[512] tmp = void;
        return FS.exists (FS.strz(name, tmp));
}

/*******************************************************************************

        Returns the time of the last modification. Accurate
        to whatever the F/S supports, and in a format dictated
        by the file-system. For example NTFS keeps UTC time, 
        while FAT timestamps are based on the local time. 

*******************************************************************************/

Time modified (char[] name)
{       
        return timeStamps(name).modified;
}

/*******************************************************************************

        Returns the time of the last access. Accurate to
        whatever the F/S supports, and in a format dictated
        by the file-system. For example NTFS keeps UTC time, 
        while FAT timestamps are based on the local time.

*******************************************************************************/

Time accessed (char[] name)
{
        return timeStamps(name).accessed;
}

/*******************************************************************************

        Returns the time of file creation. Accurate to
        whatever the F/S supports, and in a format dictated
        by the file-system. For example NTFS keeps UTC time,  
        while FAT timestamps are based on the local time.

*******************************************************************************/

Time created (char[] name)
{
        return timeStamps(name).created;
}

/*******************************************************************************

        Return the file length (in bytes)

*******************************************************************************/

ulong fileSize (char[] name)
{
        char[512] tmp = void;
        return FS.fileSize (FS.strz(name, tmp));
}

/*******************************************************************************

        Is this file writable?

*******************************************************************************/

bool isWritable (char[] name)
{
        char[512] tmp = void;
        return FS.isWritable (FS.strz(name, tmp));
}

/*******************************************************************************

        Is this file actually a folder/directory?

*******************************************************************************/

bool isFolder (char[] name)
{
        char[512] tmp = void;
        return FS.isFolder (FS.strz(name, tmp));
}

/*******************************************************************************

        Return timestamp information

        Timstamps are returns in a format dictated by the 
        file-system. For example NTFS keeps UTC time, 
        while FAT timestamps are based on the local time

*******************************************************************************/

FS.Stamps timeStamps (char[] name)
{
        char[512] tmp = void;
        return FS.timeStamps (FS.strz(name, tmp));
}

/*******************************************************************************

        Remove the file/directory from the file-system

*******************************************************************************/

void remove (char[] name)
{      
        char[512] tmp = void;
        FS.remove (FS.strz(name, tmp));
}

/*******************************************************************************

        Create a new file

*******************************************************************************/

void createFile (char[] name)
{
        char[512] tmp = void;
        FS.createFile (FS.strz(name, tmp));
}

/*******************************************************************************

        Create a new directory

*******************************************************************************/

void createFolder (char[] name)
{
        char[512] tmp = void;
        FS.createFolder (FS.strz(name, tmp));
}

/*******************************************************************************

       change the name or location of a file/directory

*******************************************************************************/

void rename (char[] src, char[] dst)
{
        char[512] tmp1 = void;
        char[512] tmp2 = void;
        FS.rename (FS.strz(src, tmp1), FS.strz(dst, tmp2));
}

/*******************************************************************************

        Transfer the content of one file to another. Throws 
        an IOException upon failure.

*******************************************************************************/

void copy (char[] src, char[] dst)
{
        char[512] tmp1 = void;
        char[512] tmp2 = void;
        FS.copy (FS.strz(src, tmp1), FS.strz(dst, tmp2));
}

/*******************************************************************************

        Provides foreach support via a fruct, as in
        ---
        foreach (info; children("myfolder"))
                 ...
        ---

        Each path and filename is passed to the foreach
        delegate, along with the path prefix and whether
        the entry is a folder or not. The info construct
        exposes the following attributes:
        ---
        char[]  path
        char[]  name
        ulong   bytes
        bool    folder
        ---

*******************************************************************************/

FS.Listing children (char[] folder)
{
        return FS.Listing (folder~'\0');
}

/*******************************************************************************

        Join a set of path specs together. A path separator is
        potentially inserted between each of the segments.

*******************************************************************************/

char[] join (char[][] paths...)
{
        return FS.join (paths);
}

/*******************************************************************************

        Convert path separators to a standard format, using '/' as
        the path separator. This is compatible with URI and all of 
        the contemporary O/S which Tango supports. Known exceptions
        include the Windows command-line processor, which considers
        '/' characters to be switches instead. Use the native()
        method to support that.

        Note: mutates the provided path.

*******************************************************************************/

final char[] standard (char[] path)
{
        return replace (path, '\\', '/');
}

/*******************************************************************************

        Convert to native O/S path separators where that is required,
        such as when dealing with the Windows command-line. 
        
        Note: mutates the provided path. Use this pattern to obtain a 
        copy instead: native(path.dup);

*******************************************************************************/

final char[] native (char[] path)
{
        version (Win32)
                 replace (path, '/', '\\');
        return path;
}

/*******************************************************************************

        Break a path into "head" and "tail" components. For example: 
        ---
        "/a/b/c" -> "/a","b/c" 
        "a/b/c" -> "a","b/c" 
        ---

*******************************************************************************/

char[] split (char[] path, out char[] head, out char[] tail)
{
        head = path;
        if (path.length > 1)
            foreach (i, char c; path[1..$])
                     if (c is '/')
                        {
                        head = path [0 .. i+1];
                        tail = path [i+2 .. $];
                        break;
                        }
        return path;
}

/*******************************************************************************

        Replace all path 'from' instances with 'to'

*******************************************************************************/

package char[] replace (char[] path, char from, char to)
{
        foreach (inout char c; path)
                 if (c is from)
                     c = to;
        return path;
}



/*******************************************************************************

*******************************************************************************/

debug(Path)
{
        void main()
        {
                exists ("path.d");
                assert(exists("Path.d"));
                    
        }
}