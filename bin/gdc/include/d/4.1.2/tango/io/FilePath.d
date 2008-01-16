/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Oct 2004: Initial version
        version:        Nov 2006: Australian version
        version:        Feb 2007: Mutating version
        version:        Mar 2007: Folded FileProxy in
        version:        Nov 2007: VFS dictates '/' always be used

        author:         Kris

*******************************************************************************/

module tango.io.FilePath;

private import  tango.sys.Common;

private import  tango.io.FileConst;

private import  tango.core.Exception;

private import  tango.time.Time;

/*******************************************************************************

*******************************************************************************/

version (Win32)
        {
        version (Win32SansUnicode)
                {
                alias char T;
                private extern (C) int strlen (char *s);
                private alias WIN32_FIND_DATA FIND_DATA;
                }
             else
                {
                alias wchar T;
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

*******************************************************************************/

private extern (C) void memmove (void* dst, void* src, uint bytes);

/*******************************************************************************

        Models a file path. These are expected to be used as the constructor
        argument to various file classes. The intention is that they easily
        convert to other representations such as absolute, canonical, or Url.

        File paths containing non-ansi characters should be UTF-8 encoded.
        Supporting Unicode in this manner was deemed to be more suitable
        than providing a wchar version of FilePath, and is both consistent
        & compatible with the approach taken with the Uri class.

        FilePath is designed to be transformed, thus each mutating method
        modifies the internal content. There is a read-only base-class
        called PathView, which can be used to provide a view into the
        content as desired.

        Note that patterns of adjacent '.' separators are treated specially
        in that they will be assigned to the name instead of the suffix. In
        addition, a '.' at the start of a name signifies it does not belong
        to the suffix i.e. ".file" is a name rather than a suffix.

        Note also that normalization of path-separators occurs by default. 
        This means that the use of '\' characters with be converted into
        '/' instead while parsing. To mutate the path into an O/S native
        version, use the native() method. To obtain a copy instead, use the 
        path.dup.native sequence

        Compile with -version=Win32SansUnicode to enable Win95 & Win32s file
        support.

*******************************************************************************/

class FilePath : PathView
{
        private char[]  fp;                     // filepath with trailing 0

        private bool    dir_;                   // this represents a dir?

        private int     end_,                   // before the trailing 0
                        name_,                  // file/dir name
                        folder_,                // path before name
                        suffix_;                // after rightmost '.'

        public alias    set     opAssign;       // path = x;
        public alias    append  opCatAssign;    // path ~= x;

        /***********************************************************************

                Filter used for screening paths via toList()

        ***********************************************************************/

        public alias bool delegate (FilePath, bool) Filter;

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

                Call-site shortcut to create a FilePath instance. This
                enables the same syntax as struct usage, so may expose
                a migration path

        ***********************************************************************/

        static FilePath opCall (char[] filepath = null)
        {
                return new FilePath (filepath);
        }

        /***********************************************************************

                Create a FilePath from a copy of the provided string.

                FilePath assumes both path & name are present, and therefore
                may split what is otherwise a logically valid path. That is,
                the 'name' of a file is typically the path segment following
                a rightmost path-separator. The intent is to treat files and
                directories in the same manner; as a name with an optional
                ancestral structure. It is possible to bias the interpretation
                by adding a trailing path-separator to the argument. Doing so
                will result in an empty name attribute.

                With regard to the filepath copy, we found the common case to
                be an explicit .dup, whereas aliasing appeared to be rare by
                comparison. We also noted a large proportion interacting with
                C-oriented OS calls, implying the postfix of a null terminator.
                Thus, FilePath combines both as a single operation.

        ***********************************************************************/

        this (char[] filepath = null)
        {
                set (filepath);
        }
        
        // now converts to '/' always. Use toNative to get Win32 paths
        deprecated this (char[] filepath, bool native)
        {
                set (filepath);
        }

        /***********************************************************************

                Return the complete text of this filepath

        ***********************************************************************/

        final char[] toString ()
        {
                return fp [0 .. end_];
        }

        /***********************************************************************

                Duplicate this path

        ***********************************************************************/

        final FilePath dup ()
        {
                return FilePath (toString);
        }

        /***********************************************************************

                Return the complete text of this filepath as a null
                terminated string for use with a C api. Use toString
                instead for any D api.

                Note that the nul is always embedded within the string
                maintained by FilePath, so there's no heap overhead when
                making a C call

        ***********************************************************************/

        final char[] cString ()
        {
                return fp [0 .. end_+1];
        }

        /***********************************************************************

                Return the root of this path. Roots are constructs such as
                "c:"

        ***********************************************************************/

        final char[] root ()
        {
                return fp [0 .. folder_];
        }

        /***********************************************************************

                Return the file path. Paths may start and end with a "/".
                The root path is "/" and an unspecified path is returned as
                an empty string. Directory paths may be split such that the
                directory name is placed into the 'name' member; directory
                paths are treated no differently than file paths

        ***********************************************************************/

        final char[] folder ()
        {
                return fp [folder_ .. name_];
        }

        /***********************************************************************

                Returns a path representing the parent of this one. This
                will typically return the current path component, though
                with a special case where the name component is empty. In 
                such cases, the path is scanned for a prior segment:
                ---
                normal:  /x/y/z => /x/y
                special: /x/y/  => /x
                ---

                Note that this returns a path suitable for splitting into
                path and name components (there's no trailing separator).

                See pop() also, which is generally more useful when working
                with FilePath instances

        ***********************************************************************/

        final char[] parent ()
        {
                auto p = path;
                if (name.length is 0)
                    for (int i=p.length-1; --i > 0;)
                         if (p[i] is FileConst.PathSeparatorChar)
                            {
                            p = p[0 .. i];
                            break;
                            }
                return stripped (p);
        }

        /***********************************************************************

                Return the name of this file, or directory.

        ***********************************************************************/

        final char[] name ()
        {
                return fp [name_ .. suffix_];
        }

        /***********************************************************************

                Ext is the tail of the filename, rightward of the rightmost
                '.' separator e.g. path "foo.bar" has ext "bar". Note that
                patterns of adjacent separators are treated specially; for
                example, ".." will wind up with no ext at all

        ***********************************************************************/

        final char[] ext ()
        {
                auto x = suffix;
                if (x.length)
                    x = x [1..$];
                return x;
        }

        /***********************************************************************

                Suffix is like ext, but includes the separator e.g. path
                "foo.bar" has suffix ".bar"

        ***********************************************************************/

        final char[] suffix ()
        {
                return fp [suffix_ .. end_];
        }

        /***********************************************************************

                return the root + folder combination

        ***********************************************************************/

        final char[] path ()
        {
                return fp [0 .. name_];
        }

        /***********************************************************************

                return the name + suffix combination

        ***********************************************************************/

        final char[] file ()
        {
                return fp [name_ .. end_];
        }

        /***********************************************************************

                Returns true if all fields are equal.

        ***********************************************************************/

        final override int opEquals (Object o)
        {
                return (this is o) || (o && toString == o.toString);
        }

        /***********************************************************************

                Does this FilePath equate to the given text?

        ***********************************************************************/

        final override int opEquals (char[] s)
        {
                return toString() == s;
        }

        /***********************************************************************

                Returns true if this FilePath is *not* relative to the
                current working directory

        ***********************************************************************/

        final bool isAbsolute ()
        {
                return (folder_ > 0) ||
                       (folder_ < end_ && fp[folder_] is FileConst.PathSeparatorChar);
        }

        /***********************************************************************

                Returns true if this FilePath is empty

        ***********************************************************************/

        final bool isEmpty ()
        {
                return end_ is 0;
        }

        /***********************************************************************

                Returns true if this FilePath has a parent. Note that a
                parent is defined by the presence of a path-separator in
                the path. This means 'foo' within "\foo" is considered a
                child of the root

        ***********************************************************************/

        final bool isChild ()
        {
                return folder.length > 0;
        }

        /***********************************************************************

                Replace all 'from' instances with 'to'

        ***********************************************************************/

        final FilePath replace (char from, char to)
        {
                foreach (inout char c; path)
                         if (c is from)
                             c = to;
                return this;
        }

        /***********************************************************************

                Convert path separators to a standard format, using '/' as
                the path separator. This is compatible with URI and all of 
                the contemporary O/S which Tango supports. Known exceptions
                include the Windows command-line processor, which considers
                '/' characters to be switches instead. Use the native()
                method to support that.

                Note: mutates the current path.

        ***********************************************************************/

        final FilePath standard ()
        {
                return replace ('\\', '/');
        }

        /***********************************************************************

                Convert to native O/S path separators where that is required,
                such as when dealing with the Windows command-line. 
                
                Note: mutates the current path. Use this pattern to obtain a 
                copy instead: path.dup.native

        ***********************************************************************/

        final FilePath native ()
        {
                version (Win32)
                         return replace ('/', '\\');
                     else
                        return this;
        }

        /***********************************************************************

                Concatenate text to this path; no separators are added.
                See join() also

        ***********************************************************************/

        final FilePath cat (char[][] others...)
        {
                foreach (other; others)
                        {
                        auto len = end_ + other.length;
                        expand (len);
                        fp [end_ .. len] = other;
                        fp [len] = 0;
                        end_ = len;
                        }
                return parse;
        }

        /***********************************************************************

                Append a folder to this path. A leading separator is added
                as required

        ***********************************************************************/

        final FilePath append (char[] path)
        {
                if (file.length)
                    path = prefixed (path);
                return cat (path);
        }

        /***********************************************************************

                Prepend a folder to this path. A trailing separator is added
                if needed

        ***********************************************************************/

        final FilePath prepend (char[] path)
        {
                adjust (0, folder_, folder_, padded (path));
                return parse;
        }

        /***********************************************************************

                Reset the content of this path to that of another and
                reparse

        ***********************************************************************/

        FilePath set (FilePath path)
        {
                return set (path.toString);
        }

        /***********************************************************************

                Reset the content of this path, and reparse. 

        ***********************************************************************/

        final FilePath set (char[] path)
        {
                end_ = path.length;

                expand (end_);
                if (end_)
                    fp[0 .. end_] = path;

                fp[end_] = '\0';
                return parse;
        }

        /***********************************************************************

                Sidestep the normal lookup for paths that are known to
                be folders. Where folder is true, file-system lookups
                will be skipped.

        ***********************************************************************/

        final FilePath isFolder (bool folder)
        {
                dir_ = folder;
                return this;
        }

        /***********************************************************************

                Replace the root portion of this path

        ***********************************************************************/

        final FilePath root (char[] other)
        {
                auto x = adjust (0, folder_, folder_, padded (other, ':'));
                folder_ += x;
                suffix_ += x;
                name_ += x;
                return this;
        }

        /***********************************************************************

                Replace the folder portion of this path. The folder will be
                padded with a path-separator as required

        ***********************************************************************/

        final FilePath folder (char[] other)
        {
                auto x = adjust (folder_, name_, name_ - folder_, padded (other));
                suffix_ += x;
                name_ += x;
                return this;
        }

        /***********************************************************************

                Replace the name portion of this path

        ***********************************************************************/

        final FilePath name (char[] other)
        {
                auto x = adjust (name_, suffix_, suffix_ - name_, other);
                suffix_ += x;
                return this;
        }

        /***********************************************************************

                Replace the suffix portion of this path. The suffix will be
                prefixed with a file-separator as required

        ***********************************************************************/

        final FilePath suffix (char[] other)
        {
                adjust (suffix_, end_, end_ - suffix_, prefixed (other, '.'));
                return this;
        }

        /***********************************************************************

                Replace the root and folder portions of this path and
                reparse. The replacement will be padded with a path
                separator as required

        ***********************************************************************/

        final FilePath path (char[] other)
        {
                adjust (0, name_, name_, padded (other));
                return parse;
        }

        /***********************************************************************

                Replace the file and suffix portions of this path and
                reparse. The replacement will be prefixed with a suffix
                separator as required

        ***********************************************************************/

        final FilePath file (char[] other)
        {
                adjust (name_, end_, end_ - name_, other);
                return parse;
        }

        /***********************************************************************

                Pop to the parent of the current filepath (in place)

        ***********************************************************************/

        final FilePath pop ()
        {
                auto path = parent();
                end_ = path.length;
                fp[end_] = '\0';
                return parse;
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

                return result.length ? result [0 .. $-1] : null;
        }

        /***********************************************************************

                Return an adjusted path such that non-empty instances do not
                have a trailing separator

        ***********************************************************************/

        static char[] stripped (char[] path, char c = FileConst.PathSeparatorChar)
        {
                if (path.length && path[$-1] is c)
                    path = path [0 .. $-1];
                return path;
        }

        /***********************************************************************

                Return an adjusted path such that non-empty instances always
                have a trailing separator

        ***********************************************************************/

        static char[] padded (char[] path, char c = FileConst.PathSeparatorChar)
        {
                if (path.length && path[$-1] != c)
                    path = path ~ c;
                return path;
        }

        /***********************************************************************

                Return an adjusted path such that non-empty instances always
                have a prefixed separator

        ***********************************************************************/

        static char[] prefixed (char[] s, char c = FileConst.PathSeparatorChar)
        {
                if (s.length && s[0] != c)
                    s = c ~ s;
                return s;
        }

        /***********************************************************************

                Parse the path spec

        ***********************************************************************/

        private final FilePath parse ()
        {
                folder_ = 0;
                name_ = suffix_ = -1;

                for (int i=end_; --i >= 0;)
                     switch (fp[i])
                            {
                            case FileConst.FileSeparatorChar:
                                 if (name_ < 0)
                                     if (suffix_ < 0 && i && fp[i-1] != '.')
                                         suffix_ = i;
                                 break;

                            version (Win32)
                            {
                            case '\\':
                                 fp[i] = '/';
                            }
                            case FileConst.PathSeparatorChar:
                                 if (name_ < 0)
                                     name_ = i + 1;
                                 break;

                            version (Win32)
                            {
                            case FileConst.RootSeparatorChar:
                                 folder_ = i + 1;
                                 break;
                            }

                            default:
                                 break;
                            }

                if (name_ < 0)
                    name_ = folder_;

                if (suffix_ < 0 || suffix_ is name_)
                    suffix_ = end_;

                return this;
        }

        /***********************************************************************

                Potentially make room for more content

        ***********************************************************************/

        private final void expand (uint size)
        {
                ++size;
                if (fp.length < size)
                    fp.length = (size + 127) & ~127;
        }

        /***********************************************************************

                Insert/delete internal content

        ***********************************************************************/

        private final int adjust (int head, int tail, int len, char[] sub)
        {
                len = sub.length - len;

                // don't destroy self-references!
                if (len && sub.ptr >= fp.ptr+head+len && sub.ptr < fp.ptr+fp.length)
                   {
                   char[512] tmp = void;
                   assert (sub.length < tmp.length);
                   sub = tmp[0..sub.length] = sub;
                   }

                // make some room if necessary
                expand  (len + end_);

                // slide tail around to insert or remove space
                memmove (fp.ptr+tail+len, fp.ptr+tail, end_ +1 - tail);

                // copy replacement
                memmove (fp.ptr + head, sub.ptr, sub.length);

                // adjust length
                end_ += len;
                return len;
        }


        /**********************************************************************/
        /********************** file-system methods ***************************/
        /**********************************************************************/


        /***********************************************************************

                Does this path currently exist?

        ***********************************************************************/

        final bool exists ()
        {
                try {
                    fileSize();
                    return true;
                    } catch (IOException){}
                return false;
        }

        /***********************************************************************

                Returns the time of the last modification. Accurate
                to whatever the OS supports

        ***********************************************************************/

        final Time modified ()
        {
                return timeStamps.modified;
        }

        /***********************************************************************

                Returns the time of the last access. Accurate to
                whatever the OS supports

        ***********************************************************************/

        final Time accessed ()
        {
                return timeStamps.accessed;
        }

        /***********************************************************************

                Returns the time of file creation. Accurate to
                whatever the OS supports

        ***********************************************************************/

        final Time created ()
        {
                return timeStamps.created;
        }

        /***********************************************************************

                Create an entire path consisting of this folder along with
                all parent folders. The path must not contain '.' or '..'
                segments. Related methods include PathUtil.normalize() and
                FileSystem.toAbsolute()

                Note that each segment is created as a folder, including the
                trailing segment.

                Returns: a chaining reference (this)

                Throws: IOException upon systen errors

                Throws: IllegalArgumentException if the path contains invalid
                        path segment names (such as '.' or '..') or a segment
                        exists but as a file instead of a folder

        ***********************************************************************/

        final FilePath create ()
        {
                auto segment = name;
                if (segment.length > 0)
                   {
                   if (segment == FileConst.CurrentDirString ||
                       segment == FileConst.ParentDirString)
                       badArg ("FilePath.create :: invalid path: ");

                   if (this.exists)
                       if (this.isFolder)
                           return this;
                       else
                          badArg ("FilePath.create :: file/folder conflict: ");

                   FilePath(this.parent).create;
                   return createFolder;
                   }
                return this;
        }

        /***********************************************************************

                List the set of filenames within this folder, using
                the provided filter to control the list:
                ---
                bool delegate (FilePath path, bool isFolder) Filter
                ---

                Returning true from the filter includes the given path,
                whilst returning false excludes it. Parameter 'isFolder'
                indicates whether the path is a file or folder.

                Note that paths composed of '.' characters are ignored.

        ***********************************************************************/

        final FilePath[] toList (Filter filter = null)
        {
                FilePath[] paths;

                foreach (info; this)
                        {
                        auto p = from (info);

                        // test this entry for inclusion
                        if (filter is null || filter (p, info.folder))
                            paths ~= p;
                        else
                           delete p;
                        }

                return paths;
        }

        /***********************************************************************

                Construct a FilePath from the given FileInfo

        ***********************************************************************/

        static FilePath from (ref FileInfo info)
        {
                char[512] tmp = void;

                auto len = info.path.length + info.name.length;
                assert (len < tmp.length);

                // construct full pathname
                tmp [0 .. info.path.length] = info.path;
                tmp [info.path.length .. len] = info.name;

                return FilePath(tmp[0 .. len]).isFolder(info.folder);
        }

        /***********************************************************************

                change the name or location of a file/directory, and
                adopt the provided Path

        ***********************************************************************/

        final FilePath rename (FilePath dst)
        {
                return rename (dst.toString);
        }

        /***********************************************************************

                Throw an exception using the last known error

        ***********************************************************************/

        private void exception ()
        {
                throw new IOException (toString ~ ": " ~ SysError.lastMsg);
        }

        /***********************************************************************

                Throw an exception using the last known error

        ***********************************************************************/

        private void badArg (char[] msg)
        {
                throw new IllegalArgumentException (msg ~ toString);
        }

        /***********************************************************************

        ***********************************************************************/

        version (Win32)
        {
                /***************************************************************

                        return a wchar[] instance of the path

                ***************************************************************/

                private wchar[] toString16 (wchar[] tmp, char[] path)
                {
                        auto i = MultiByteToWideChar (CP_UTF8, 0,
                                                      path.ptr, path.length,
                                                      tmp.ptr, tmp.length);
                        return tmp [0..i];
                }

                /***************************************************************

                        return a char[] instance of the path

                ***************************************************************/

                private char[] toString (char[] tmp, wchar[] path)
                {
                        auto i = WideCharToMultiByte (CP_UTF8, 0, path.ptr, path.length,
                                                      tmp.ptr, tmp.length, null, null);
                        return tmp [0..i];
                }

                /***************************************************************

                        return a wchar[] instance of the path

                ***************************************************************/

                private wchar[] name16 (wchar[] tmp, bool withNull=true)
                {
                        int offset = withNull ? 0 : 1;
                        return toString16 (tmp, this.cString[0 .. $-offset]);
                }

                /***************************************************************

                        Get info about this path

                ***************************************************************/

                private DWORD getInfo (inout WIN32_FILE_ATTRIBUTE_DATA info)
                {
                        version (Win32SansUnicode)
                                {
                                if (! GetFileAttributesExA (this.cString.ptr, GetFileInfoLevelStandard, &info))
                                      exception;
                                }
                             else
                                {
                                wchar[MAX_PATH] tmp = void;
                                if (! GetFileAttributesExW (name16(tmp).ptr, GetFileInfoLevelStandard, &info))
                                      exception;
                                }

                        return info.dwFileAttributes;
                }

                /***************************************************************

                        Get flags for this path

                ***************************************************************/

                private DWORD getFlags ()
                {
                        WIN32_FILE_ATTRIBUTE_DATA info = void;

                        return getInfo (info);
                }

                /***************************************************************

                        Return the file length (in bytes)

                ***************************************************************/

                final ulong fileSize ()
                {
                        WIN32_FILE_ATTRIBUTE_DATA info = void;

                        getInfo (info);
                        return (cast(ulong) info.nFileSizeHigh << 32) +
                                            info.nFileSizeLow;
                }

                /***************************************************************

                        Is this file writable?

                ***************************************************************/

                final bool isWritable ()
                {
                        return (getFlags & FILE_ATTRIBUTE_READONLY) == 0;
                }

                /***************************************************************

                        Is this file actually a folder/directory?

                ***************************************************************/

                final bool isFolder ()
                {
                        if (dir_)
                            return true;

                        return (getFlags & FILE_ATTRIBUTE_DIRECTORY) != 0;
                }

                /***************************************************************

                        Return timestamp information

                ***************************************************************/

                final Stamps timeStamps ()
                {
                        static Time convert (FILETIME time)
                        {
                                return Time (TimeSpan.Epoch1601 + *cast(long*) &time);
                        }

                        WIN32_FILE_ATTRIBUTE_DATA info = void;
                        Stamps                    time = void;

                        getInfo (info);
                        time.modified = convert (info.ftLastWriteTime);
                        time.accessed = convert (info.ftLastAccessTime);
                        time.created  = convert (info.ftCreationTime);
                        return time;
                }

                /***********************************************************************

                        Transfer the content of another file to this one. Returns a
                        reference to this class on success, or throws an IOException
                        upon failure.

                ***********************************************************************/

                final FilePath copy (char[] source)
                {
                        auto src = new FilePath (source);

                        version (Win32SansUnicode)
                                {
                                if (! CopyFileA (src.cString.ptr, this.cString.ptr, false))
                                      exception;
                                }
                             else
                                {
                                wchar[MAX_PATH+1] tmp1 = void;
                                wchar[MAX_PATH+1] tmp2 = void;

                                if (! CopyFileW (toString16(tmp1, src.cString).ptr, name16(tmp2).ptr, false))
                                      exception;
                                }

                        return this;
                }

                /***************************************************************

                        Remove the file/directory from the file-system

                ***************************************************************/

                final FilePath remove ()
                {
                        if (isFolder)
                           {
                           version (Win32SansUnicode)
                                   {
                                   if (! RemoveDirectoryA (this.cString.ptr))
                                         exception;
                                   }
                                else
                                   {
                                   wchar[MAX_PATH] tmp = void;
                                   if (! RemoveDirectoryW (name16(tmp).ptr))
                                         exception;
                                   }
                           }
                        else
                           version (Win32SansUnicode)
                                   {
                                   if (! DeleteFileA (this.cString.ptr))
                                         exception;
                                   }
                                else
                                   {
                                   wchar[MAX_PATH] tmp = void;
                                   if (! DeleteFileW (name16(tmp).ptr))
                                         exception;
                                   }

                        return this;
                }

                /***************************************************************

                       change the name or location of a file/directory, and
                       adopt the provided Path

                ***************************************************************/

                final FilePath rename (char[] dst)
                {
                        const int Typical = MOVEFILE_REPLACE_EXISTING +
                                            MOVEFILE_COPY_ALLOWED     +
                                            MOVEFILE_WRITE_THROUGH;

                        int     result;
                        char[]  cstr = dst ~ '\0';

                        version (Win32SansUnicode)
                                 result = MoveFileExA (this.cString.ptr, cstr.ptr, Typical);
                             else
                                {
                                wchar[MAX_PATH] tmp1 = void;
                                wchar[MAX_PATH] tmp2 = void;
                                result = MoveFileExW (name16(tmp1).ptr, toString16(tmp2, cstr).ptr, Typical);
                                }

                        if (! result)
                              exception;

                        this.set (dst);
                        return this;
                }

                /***************************************************************

                        Create a new file

                ***************************************************************/

                final FilePath createFile ()
                {
                        HANDLE h;

                        version (Win32SansUnicode)
                                 h = CreateFileA (this.cString.ptr, GENERIC_WRITE,
                                                  0, null, CREATE_ALWAYS,
                                                  FILE_ATTRIBUTE_NORMAL, cast(HANDLE) 0);
                             else
                                {
                                wchar[MAX_PATH] tmp = void;
                                h = CreateFileW (name16(tmp).ptr, GENERIC_WRITE,
                                                 0, null, CREATE_ALWAYS,
                                                 FILE_ATTRIBUTE_NORMAL, cast(HANDLE) 0);
                                }

                        if (h == INVALID_HANDLE_VALUE)
                            exception;

                        if (! CloseHandle (h))
                              exception;

                        return this;
                }

                /***************************************************************

                        Create a new directory

                ***************************************************************/

                final FilePath createFolder ()
                {
                        version (Win32SansUnicode)
                                {
                                if (! CreateDirectoryA (this.cString.ptr, null))
                                      exception;
                                }
                             else
                                {
                                wchar[MAX_PATH] tmp = void;
                                if (! CreateDirectoryW (name16(tmp).ptr, null))
                                      exception;
                                }
                        return this;
                }

                /***************************************************************

                        List the set of filenames within this folder.

                        Each path and filename is passed to the provided
                        delegate, along with the path prefix and whether
                        the entry is a folder or not.

                        Returns the number of files scanned.

                ***************************************************************/

                final int opApply (int delegate(ref FileInfo) dg)
                {
                        HANDLE                  h;
                        int                     ret;
                        char[]                  prefix;
                        char[MAX_PATH+1]        tmp = void;
                        FIND_DATA               fileinfo = void;

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
                                 h = FindFirstFileA (padded(this.toString, "*\0").ptr, &fileinfo);
                             else
                                {
                                wchar[MAX_PATH] host = void;
                                h = FindFirstFileW (padded(name16(host, false), "*\0").ptr, &fileinfo);
                                }

                        if (h is INVALID_HANDLE_VALUE)
                            exception;

                        scope (exit)
                               FindClose (h);

                        prefix = FilePath.padded (this.toString);
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

        ***********************************************************************/

        version (Posix)
        {
                /***************************************************************

                        Get info about this path

                ***************************************************************/

                private uint getInfo (inout stat_t stats)
                {
                        if (posix.stat (this.cString.ptr, &stats))
                            exception;

                        return stats.st_mode;
                }

                /***************************************************************

                        Return the file length (in bytes)

                ***************************************************************/

                final ulong fileSize ()
                {
                        stat_t stats = void;

                        getInfo (stats);
                        return cast(ulong) stats.st_size;    // 32 bits only
                }

                /***************************************************************

                        Is this file writable?

                ***************************************************************/

                final bool isWritable ()
                {
                        stat_t stats = void;

                        return (getInfo(stats) & O_RDONLY) == 0;
                }

                /***************************************************************

                        Is this file actually a folder/directory?

                ***************************************************************/

                final bool isFolder ()
                {
                        stat_t stats = void;

                        return (getInfo(stats) & S_IFDIR) != 0;
                }

                /***************************************************************

                        Return timestamp information

                ***************************************************************/

                final Stamps timeStamps ()
                {
                        static Time convert (timeval* tv)
                        {
                                return Time.epoch1970 +
                                       TimeSpan.seconds(tv.tv_sec) +
                                       TimeSpan.micros(tv.tv_usec);
                        }

                        stat_t stats = void;
                        Stamps time  = void;

                        getInfo (stats);

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

                final FilePath copy (char[] source)
                {
                        auto from = new FilePath (source);

                        auto src = posix.open (from.cString.ptr, O_RDONLY, 0640);
                        scope (exit)
                               if (src != -1)
                                   posix.close (src);

                        auto dst = posix.open (this.cString.ptr, O_CREAT | O_RDWR, 0660);
                        scope (exit)
                               if (dst != -1)
                                   posix.close (dst);

                        if (src is -1 || dst is -1)
                            exception;

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
                                     exception;
                                 } while (read > 0);
                              read = posix.read (src, buf.ptr, buf.length);
                              }
                        if (read is -1)
                            exception;

                        // copy timestamps
                        stat_t stats;
                        if (posix.stat (from.cString.ptr, &stats))
                            exception;

                        utimbuf utim;
                        utim.actime = stats.st_atime;
                        utim.modtime = stats.st_mtime;
                        if (utime (this.cString.ptr, &utim) is -1)
                            exception;

                        return this;
                }

                /***************************************************************

                        Remove the file/directory from the file-system

                ***************************************************************/

                final FilePath remove ()
                {
                        if (isFolder)
                           {
                           if (posix.rmdir (this.cString.ptr))
                               exception;
                           }
                        else
                           if (tango.stdc.stdio.remove (this.cString.ptr) == -1)
                               exception;

                        return this;
                }

                /***************************************************************

                       change the name or location of a file/directory, and
                       adopt the provided FilePath

                ***************************************************************/

                final FilePath rename (char[] dst)
                {
                        char[] cstr = dst ~ '\0';
                        if (tango.stdc.stdio.rename (this.cString.ptr, cstr.ptr) == -1)
                            exception;

                        this.set (dst);
                        return this;
                }

                /***************************************************************

                        Create a new file

                ***************************************************************/

                final FilePath createFile ()
                {
                        int fd;

                        fd = posix.open (this.cString.ptr, O_CREAT | O_WRONLY | O_TRUNC, 0660);
                        if (fd == -1)
                            exception;

                        if (posix.close(fd) == -1)
                            exception;

                        return this;
                }

                /***************************************************************

                        Create a new directory

                ***************************************************************/

                final FilePath createFolder ()
                {
                        if (posix.mkdir (this.cString.ptr, 0777))
                            exception;

                        return this;
                }

                /***************************************************************

                        List the set of filenames within this folder.

                        Each path and filename is passed to the provided
                        delegate, along with the path prefix and whether
                        the entry is a folder or not.

                        Returns the number of files scanned.

                ***************************************************************/

                final int opApply (int delegate(ref FileInfo) dg)
                {
                        int             ret;
                        DIR*            dir;
                        dirent          entry;
                        dirent*         pentry;
                        stat_t          sbuf;
                        char[]          prefix;
                        char[]          sfnbuf;

                        dir = tango.stdc.posix.dirent.opendir (this.cString.ptr);
                        if (! dir)
                              exception;

                        scope (exit)
                               tango.stdc.posix.dirent.closedir (dir);

                        // ensure a trailing '/' is present
                        prefix = FilePath.padded (this.toString);

                        // prepare our filename buffer
                        sfnbuf = prefix.dup;
                        
                        // pentry is null at end of listing, or on an error 
	  		while (readdir_r (dir, &entry, &pentry), pentry != null)
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
                                     exception;

                                 FileInfo info = void;
                                 info.name   = str;
                                 info.path   = prefix;
                                 info.folder = (sbuf.st_mode & S_IFDIR) != 0;
                                 info.bytes  = (sbuf.st_mode & S_IFREG) != 0 ? sbuf.st_size : 0;

                                 if ((ret = dg(info)) != 0)
                                      break;
                                 }
                              }
                        return ret;
                }
        }
}



/*******************************************************************************

*******************************************************************************/

interface PathView
{
        /***********************************************************************

                TimeStamp information. Accurate to whatever the OS supports

        ***********************************************************************/

        struct Stamps
        {
                Time    created,        /// time created
                        accessed,       /// last time accessed
                        modified;       /// last time modified
        }

        /***********************************************************************

                Return the complete text of this filepath

        ***********************************************************************/

        abstract char[] toString ();

        /***********************************************************************

                Return the complete text of this filepath

        ***********************************************************************/

        abstract char[] cString ();

        /***********************************************************************

                Return the root of this path. Roots are constructs such as
                "c:"

        ***********************************************************************/

        abstract char[] root ();

        /***********************************************************************

                Return the file path. Paths may start and end with a "/".
                The root path is "/" and an unspecified path is returned as
                an empty string. Directory paths may be split such that the
                directory name is placed into the 'name' member; directory
                paths are treated no differently than file paths

        ***********************************************************************/

        abstract char[] folder ();

        /***********************************************************************

                Return the name of this file, or directory, excluding a
                suffix.

        ***********************************************************************/

        abstract char[] name ();

        /***********************************************************************

                Ext is the tail of the filename, rightward of the rightmost
                '.' separator e.g. path "foo.bar" has ext "bar". Note that
                patterns of adjacent separators are treated specially; for
                example, ".." will wind up with no ext at all

        ***********************************************************************/

        abstract char[] ext ();

        /***********************************************************************

                Suffix is like ext, but includes the separator e.g. path
                "foo.bar" has suffix ".bar"

        ***********************************************************************/

        abstract char[] suffix ();

        /***********************************************************************

                return the root + folder combination

        ***********************************************************************/

        abstract char[] path ();

        /***********************************************************************

                return the name + suffix combination

        ***********************************************************************/

        abstract char[] file ();

        /***********************************************************************

                Returns true if this FilePath is *not* relative to the
                current working directory.

        ***********************************************************************/

        abstract bool isAbsolute ();

        /***********************************************************************

                Returns true if this FilePath is empty

        ***********************************************************************/

        abstract bool isEmpty ();

        /***********************************************************************

                Returns true if this FilePath has a parent

        ***********************************************************************/

        abstract bool isChild ();

        /***********************************************************************

                Does this path currently exist?

        ***********************************************************************/

        abstract bool exists ();

        /***********************************************************************

                Returns the time of the last modification. Accurate
                to whatever the OS supports

        ***********************************************************************/

        abstract Time modified ();

        /***********************************************************************

                Returns the time of the last access. Accurate to
                whatever the OS supports

        ***********************************************************************/

        abstract Time accessed ();

        /***********************************************************************

                Returns the time of file creation. Accurate to
                whatever the OS supports

        ***********************************************************************/

        abstract Time created ();

        /***********************************************************************

                Return the file length (in bytes)

        ***********************************************************************/

        abstract ulong fileSize ();

        /***********************************************************************

                Is this file writable?

        ***********************************************************************/

        abstract bool isWritable ();

        /***********************************************************************

                Is this file actually a folder/directory?

        ***********************************************************************/

        abstract bool isFolder ();

        /***********************************************************************

                Return timestamp information

        ***********************************************************************/

        abstract Stamps timeStamps ();
}





/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{
        unittest
        {
                version(Win32)
                {
                auto fp = new FilePath(r"C:/home/foo/bar");
                fp ~= "john";
                assert (fp == r"C:/home/foo/bar/john");
                fp = r"C:/";
                fp ~= "john";
                assert (fp == r"C:/john");
                fp = "foo.bar";
                fp ~= "john";
                assert (fp == r"foo.bar/john");
                fp = "";
                fp ~= "john";
                assert (fp == r"john");

                fp = r"C:/home/foo/bar/john/foo.d";
                assert (fp.pop == r"C:/home/foo/bar/john");
                assert (fp.pop == r"C:/home/foo/bar");
                assert (fp.pop == r"C:/home/foo");
                assert (fp.pop == r"C:/home");
                assert (fp.pop == r"C:");
                assert (fp.pop == r"C:");
        
                // special case for popping empty names
                fp = r"C:/home/foo/bar/john/";
                assert (fp.pop == r"C:/home/foo/bar", fp.toString);

                fp = new FilePath;
                fp = r"C:/home/foo/bar/john/";
                assert (fp.isAbsolute);
                assert (fp.name == "");
                assert (fp.folder == r"/home/foo/bar/john/");
                assert (fp == r"C:/home/foo/bar/john/");
                assert (fp.path == r"C:/home/foo/bar/john/");
                assert (fp.file == r"");
                assert (fp.suffix == r"");
                assert (fp.root == r"C:");
                assert (fp.ext == "");
                assert (fp.isChild);

                fp = new FilePath(r"C:/home/foo/bar/john");
                assert (fp.isAbsolute);
                assert (fp.name == "john");
                assert (fp.folder == r"/home/foo/bar/");
                assert (fp == r"C:/home/foo/bar/john");
                assert (fp.path == r"C:/home/foo/bar/");
                assert (fp.file == r"john");
                assert (fp.suffix == r"");
                assert (fp.ext == "");
                assert (fp.isChild);

                fp.pop;
                assert (fp.isAbsolute);
                assert (fp.name == "bar");
                assert (fp.folder == r"/home/foo/");
                assert (fp == r"C:/home/foo/bar");
                assert (fp.path == r"C:/home/foo/");
                assert (fp.file == r"bar");
                assert (fp.suffix == r"");
                assert (fp.ext == "");
                assert (fp.isChild);

                fp.pop;
                assert (fp.isAbsolute);
                assert (fp.name == "foo");
                assert (fp.folder == r"/home/");
                assert (fp == r"C:/home/foo");
                assert (fp.path == r"C:/home/");
                assert (fp.file == r"foo");
                assert (fp.suffix == r"");
                assert (fp.ext == "");
                assert (fp.isChild);

                fp.pop;
                assert (fp.isAbsolute);
                assert (fp.name == "home");
                assert (fp.folder == r"/");
                assert (fp == r"C:/home");
                assert (fp.path == r"C:/");
                assert (fp.file == r"home");
                assert (fp.suffix == r"");
                assert (fp.ext == "");
                assert (fp.isChild);

                fp = new FilePath(r"foo/bar/john.doe");
                assert (!fp.isAbsolute);
                assert (fp.name == "john");
                assert (fp.folder == r"foo/bar/");
                assert (fp.suffix == r".doe");
                assert (fp.file == r"john.doe");
                assert (fp == r"foo/bar/john.doe");
                assert (fp.ext == "doe");
                assert (fp.isChild);

                fp = new FilePath(r"c:doe");
                assert (fp.isAbsolute);
                assert (fp.suffix == r"");
                assert (fp == r"c:doe");
                assert (fp.folder == r"");
                assert (fp.name == "doe");
                assert (fp.file == r"doe");
                assert (fp.ext == "");
                assert (!fp.isChild);

                fp = new FilePath(r"/doe");
                assert (fp.isAbsolute);
                assert (fp.suffix == r"");
                assert (fp == r"/doe");
                assert (fp.name == "doe");
                assert (fp.folder == r"/");
                assert (fp.file == r"doe");
                assert (fp.ext == "");
                assert (fp.isChild);

                fp = new FilePath(r"john.doe.foo");
                assert (!fp.isAbsolute);
                assert (fp.name == "john.doe");
                assert (fp.folder == r"");
                assert (fp.suffix == r".foo");
                assert (fp == r"john.doe.foo");
                assert (fp.file == r"john.doe.foo");
                assert (fp.ext == "foo");
                assert (!fp.isChild);

                fp = new FilePath(r".doe");
                assert (!fp.isAbsolute);
                assert (fp.suffix == r"");
                assert (fp == r".doe");
                assert (fp.name == ".doe");
                assert (fp.folder == r"");
                assert (fp.file == r".doe");
                assert (fp.ext == "");
                assert (!fp.isChild);

                fp = new FilePath(r"doe");
                assert (!fp.isAbsolute);
                assert (fp.suffix == r"");
                assert (fp == r"doe");
                assert (fp.name == "doe");
                assert (fp.folder == r"");
                assert (fp.file == r"doe");
                assert (fp.ext == "");
                assert (!fp.isChild);

                fp = new FilePath(r".");
                assert (!fp.isAbsolute);
                assert (fp.suffix == r"");
                assert (fp == r".");
                assert (fp.name == ".");
                assert (fp.folder == r"");
                assert (fp.file == r".");
                assert (fp.ext == "");
                assert (!fp.isChild);

                fp = new FilePath(r"..");
                assert (!fp.isAbsolute);
                assert (fp.suffix == r"");
                assert (fp == r"..");
                assert (fp.name == "..");
                assert (fp.folder == r"");
                assert (fp.file == r"..");
                assert (fp.ext == "");
                assert (!fp.isChild);

                fp = new FilePath(r"c:/a/b/c/d/e/foo.bar");
                assert (fp.isAbsolute);
                fp.folder (r"/a/b/c/");
                assert (fp.suffix == r".bar");
                assert (fp == r"c:/a/b/c/foo.bar");
                assert (fp.name == "foo");
                assert (fp.folder == r"/a/b/c/");
                assert (fp.file == r"foo.bar");
                assert (fp.ext == "bar");
                assert (fp.isChild);

                fp = new FilePath(r"c:/a/b/c/d/e/foo.bar");
                assert (fp.isAbsolute);
                fp.folder (r"/a/b/c/d/e/f/g/");
                assert (fp.suffix == r".bar");
                assert (fp == r"c:/a/b/c/d/e/f/g/foo.bar");
                assert (fp.name == "foo");
                assert (fp.folder == r"/a/b/c/d/e/f/g/");
                assert (fp.file == r"foo.bar");
                assert (fp.ext == "bar");
                assert (fp.isChild);

                fp = new FilePath(r"C:\foo\bar\test.bar");
                assert (fp.path == "C:/foo/bar/");
                fp = new FilePath(r"C:/foo/bar/test.bar");
                assert (fp.path == r"C:/foo/bar/");

                fp = new FilePath("");
                assert (fp.isEmpty);
                assert (!fp.isChild);
                assert (!fp.isAbsolute);
                assert (fp.suffix == r"");
                assert (fp == r"");
                assert (fp.name == "");
                assert (fp.folder == r"");
                assert (fp.file == r"");
                assert (fp.ext == "");
/+
                fp = new FilePath(r"C:/foo/bar/test.bar");
                fp = new FilePath(fp.asPath ("foo"));
                assert (fp.name == r"test");
                assert (fp.folder == r"foo/");
                assert (fp.path == r"C:foo/");
                assert (fp.ext == ".bar");

                fp = new FilePath(fp.asPath (""));
                assert (fp.name == r"test");
                assert (fp.folder == r"");
                assert (fp.path == r"C:");
                assert (fp.ext == ".bar");

                fp = new FilePath(r"c:/joe/bar");
                assert(fp.cat(r"foo/bar/") == r"c:/joe/bar/foo/bar/");
                assert(fp.cat(new FilePath(r"foo/bar")).toString == r"c:/joe/bar/foo/bar");

                assert (FilePath.join (r"a/b/c/d", r"e/f/" r"g") == r"a/b/c/d/e/f/g");

                fp = new FilePath(r"C:/foo/bar/test.bar");
                assert (fp.asExt(null) == r"C:/foo/bar/test");
                assert (fp.asExt("foo") == r"C:/foo/bar/test.foo");
+/      
                }
        }
}


debug (FilePath)
{       
        import tango.io.Console;

        void main() 
        {
                Cout (FilePath("c:/temp/").file("foo.bar")).newline;
        }

}
