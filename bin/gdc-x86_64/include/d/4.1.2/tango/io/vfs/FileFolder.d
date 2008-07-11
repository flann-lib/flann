/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Oct 2007: Initial version

        author:         Kris

*******************************************************************************/

module tango.io.vfs.FileFolder;

private import tango.io.FilePath,
               tango.io.FileConduit;

private import tango.util.PathUtil;

private import tango.core.Exception;

private import tango.io.vfs.model.Vfs;

private import tango.io.model.IConduit;

/*******************************************************************************

        Represents a physical folder in a file system. Use one of these
        to address specific paths (sub-trees) within the file system.

*******************************************************************************/

class FileFolder : VfsFolder
{
        private FilePath        path;
        private VfsStats        stats;

        /***********************************************************************

                Create a file folder with the given name and path. The
                name itself should not include '.' or '/' characters, 
                though the path can point at whatever it pleases. 

                Option 'create' will create the folder when set true, 
                and open an existing folder otherwise

        ***********************************************************************/

        this (char[] path, bool create=false)
        {
                this.path = open (FilePath(path), create);
        }

        /***********************************************************************

                create a FileFolder as a Group member

        ***********************************************************************/

        private this (FilePath path)
        {
                this.path = path;
        }

        /***********************************************************************

                explicitly create() or open() a named folder

        ***********************************************************************/

        private this (FileFolder parent, char[] name, bool create=false)
        {
                assert (parent);
                this.path = open (parent.path.dup.append(name), create);
        }

        /***********************************************************************

                Return a short name

        ***********************************************************************/

        final char[] name ()
        {
                return path.name;
        }

        /***********************************************************************

                Return a long name

        ***********************************************************************/

        final char[] toString ()
        {
                return path.toString;
        }

        /***********************************************************************

                A folder is being added or removed from the hierarchy. Use 
                this to test for validity (or whatever) and throw exceptions 
                as necessary

                Here we test for folder overlap, and bail-out when found.

        ***********************************************************************/

        final void verify (VfsFolder folder, bool mounting)
        {       
                if (mounting && cast(FileFolder) folder)
                   {
                   auto src = FilePath.padded(this.toString);
                   auto dst = FilePath.padded(folder.toString);

                   auto len = src.length;
                   if (len > dst.length)
                       len = dst.length;

                   if (src[0..len] == dst[0..len])
                       error ("folders '"~dst~"' and '"~src~"' overlap");
                   }
        }

        /***********************************************************************

                Return a contained file representation 

        ***********************************************************************/

        final VfsFile file (char[] name)
        {
                return (new FileHost).set (path.toString, name);
        }

        /***********************************************************************

                Return a contained folder representation 

        ***********************************************************************/

        final VfsFolderEntry folder (char[] path)
        {
                return new FolderHost (this, path);
        }

        /***********************************************************************

                Remove the folder subtree

        ***********************************************************************/

        final VfsFolder clear ()
        {
                path.remove;
                return this;
        }

        /***********************************************************************

                Is folder writable?

        ***********************************************************************/

        final bool writable ()
        {
                return path.isWritable;
        }

        /***********************************************************************

                Returns content information about this folder

        ***********************************************************************/

        final VfsFolders self ()
        {
                return new FolderGroup (this, false);
        }

        /***********************************************************************

                Returns a subtree of folders matching the given name

        ***********************************************************************/

        final VfsFolders tree ()
        {
                return new FolderGroup (this, true);
        }

        /***********************************************************************

                Iterate over the set of immediate child folders. This is 
                useful for reflecting the hierarchy

        ***********************************************************************/

        final int opApply (int delegate(inout VfsFolder) dg)
        {
                int result;

                foreach (folder; folders(true))  
                        {
                        VfsFolder x = folder;  
                        if ((result = dg(x)) != 0)
                             break;
                        }
                return result;
        }

        /***********************************************************************

                Close and/or synchronize changes made to this folder. Each
                driver should take advantage of this as appropriate, perhaps
                combining multiple files together, or possibly copying to a 
                remote location

        ***********************************************************************/

        VfsFolder close (bool commit = true)
        {
                return this;
        }

        /***********************************************************************
        
                Sweep owned folders 

        ***********************************************************************/

        private final FileFolder[] folders (bool collect)
        {
                FileFolder[] folders;

                stats = stats.init;
                foreach (info; path)
                         if (info.folder)
                            {
                            if (collect)
                                folders ~= new FileFolder (FilePath.from (info));
                            ++stats.folders;
                            }
                         else
                            {
                            stats.bytes += info.bytes; 
                            ++stats.files;
                            }

                return folders;         
        }


        /***********************************************************************

                Sweep owned files

        ***********************************************************************/

        private final FilePath[] files (ref VfsStats stats, VfsFilter filter = null)
        {
                FilePath[] files;

                foreach (info; path)
                         if (info.folder is false)
                             if (filter is null || filter(cast(VfsInfo) &info))
                                {
                                files ~= FilePath.from (info);
                                stats.bytes += info.bytes; 
                                ++stats.files;
                                }

                return files;         
        }

        /***********************************************************************

                Throw an exception

        ***********************************************************************/

        private final char[] error (char[] msg)
        {
                throw new VfsException (msg);
        }

        /***********************************************************************

                Create or open the given path, and detect path errors

        ***********************************************************************/

        private final FilePath open (FilePath path, bool create)
        {
                if (path.exists)
                   {
                   if (path.isFolder is false)
                       error ("FileFolder.open :: path exists but not as a folder: "~path.toString);
                   }
                else
                   if (create)
                       path.create;
                   else
                      error ("FileFolder.open :: path does not exist: "~path.toString);
                return path;
        }
}


/*******************************************************************************

        Represents a group of files (need this declared here to avoid
        a bunch of bizarre compiler warnings)

*******************************************************************************/

class FileGroup : VfsFiles
{
        private FilePath[]      group;
        private VfsStats        stats;

        /***********************************************************************

        ***********************************************************************/

        this (FolderGroup host, VfsFilter filter)
        {
                foreach (folder; host.members)
                         group ~= folder.files (stats, filter);
        }

        /***********************************************************************

                Iterate over the set of contained VfsFile instances

        ***********************************************************************/

        final int opApply (int delegate(inout VfsFile) dg)
        {
                int  result;
                auto host = new FileHost;

                foreach (file; group)    
                        {    
                        host.path = file;
                        VfsFile x = host;
                        if ((result = dg(x)) != 0)
                             break;
                        } 
                return result;
        }

        /***********************************************************************

                Return the total number of entries 

        ***********************************************************************/

        final uint files ()
        {
                return group.length;
        }

        /***********************************************************************

                Return the total size of all files 

        ***********************************************************************/

        final ulong bytes ()
        {
                return stats.bytes;
        }
}


/*******************************************************************************

        A set of folders representing a selection. This is where file 
        selection is made, and pattern-matched folder subsets can be
        extracted. You need one of these to expose statistics (such as
        file or folder count) of a selected folder group 

*******************************************************************************/

private class FolderGroup : VfsFolders
{
        private FileFolder[] members;           // folders in group

        /***********************************************************************

                Create a subset group

        ***********************************************************************/

        private this () {}

        /***********************************************************************

                Create a folder group including the provided folder and
                (optionally) all child folders

        ***********************************************************************/

        private this (FileFolder root, bool recurse)
        {
                members = root ~ scan (root, recurse);   
        }

        /***********************************************************************

                Iterate over the set of contained VfsFolder instances

        ***********************************************************************/

        final int opApply (int delegate(inout VfsFolder) dg)
        {
                int  result;

                foreach (folder; members)  
                        {
                        VfsFolder x = folder;  
                        if ((result = dg(x)) != 0)
                             break;
                        }
                return result;
        }

        /***********************************************************************

                Return the number of files in this group

        ***********************************************************************/

        final uint files ()
        {
                uint files;
                foreach (folder; members)
                         files += folder.stats.files;
                return files;
        }

        /***********************************************************************

                Return the total size of all files in this group

        ***********************************************************************/

        final ulong bytes ()
        {
                ulong bytes;

                foreach (folder; members)
                         bytes += folder.stats.bytes;
                return bytes;
        }

        /***********************************************************************

                Return the number of folders in this group

        ***********************************************************************/

        final uint folders ()
        {
                return members.length;
        }

        /***********************************************************************

                Return the total number of entries in this group

        ***********************************************************************/

        final uint entries ()
        {
                return files + folders;
        }

        /***********************************************************************

                Return a subset of folders matching the given pattern

        ***********************************************************************/

        final VfsFolders subset (char[] pattern)
        {  
                auto set = new FolderGroup;

                foreach (folder; members)    
                         if (patternMatch (folder.path.name, pattern))
                             set.members ~= folder; 
                return set;
        }

        /***********************************************************************

                Return a set of files matching the given pattern

        ***********************************************************************/

        final FileGroup catalog (char[] pattern)
        {
                bool foo (VfsInfo info)
                {
                        return patternMatch (info.name, pattern);
                }

                return catalog (&foo);
        }

        /***********************************************************************

                Returns a set of files conforming to the given filter

        ***********************************************************************/

        final FileGroup catalog (VfsFilter filter = null)
        {       
                return new FileGroup (this, filter);
        }

        /***********************************************************************

                Internal routine to traverse the folder tree

        ***********************************************************************/

        private final FileFolder[] scan (FileFolder root, bool recurse) 
        {
                auto folders = root.folders (recurse);
                if (recurse)
                    foreach (child; folders)
                             folders ~= scan (child, recurse);
                return folders;
        }
}


/*******************************************************************************

        A host for folders, currently used to harbor create() and open() 
        methods only

*******************************************************************************/

private class FolderHost : VfsFolderEntry
{       
        private char[]          path;
        private FileFolder      parent;

        /***********************************************************************

        ***********************************************************************/

        private this (FileFolder parent, char[] path)
        {
                this.path = path;
                this.parent = parent;
        }

        /***********************************************************************

        ***********************************************************************/

        final VfsFolder create ()
        {
                return new FileFolder (parent, path, true);
        }

        /***********************************************************************

        ***********************************************************************/

        final VfsFolder open ()
        {
                return new FileFolder (parent, path, false);
        }

        /***********************************************************************

                Test to see if a folder exists

        ***********************************************************************/

        bool exists ()
        {
                try {
                    open();
                    return true;
                    } catch (IOException x) {}
                return false;
        }
}


/*******************************************************************************

        Represents things you can do with a file 

*******************************************************************************/

private class FileHost : VfsFile
{
        private FilePath path;

        /***********************************************************************

        ***********************************************************************/

        private this (char[] path = null)
        {
                this.path = FilePath (path);
        }

        /***********************************************************************

                Return a short name

        ***********************************************************************/

        final char[] name()
        {
                return path.file;
        }

        /***********************************************************************

                Return a long name

        ***********************************************************************/

        final char[] toString ()
        {
                return path.toString;
        }

        /***********************************************************************

                Does this file exist?

        ***********************************************************************/

        final bool exists()
        {
                return path.exists;
        }

        /***********************************************************************

                Return the file size

        ***********************************************************************/

        final ulong size()
        {
                return path.fileSize;
        }

        /***********************************************************************

                Create a new file instance

        ***********************************************************************/

        final VfsFile create ()
        {
                path.createFile ();
                return this;
        }

        /***********************************************************************

                Create a new file instance and populate with stream

        ***********************************************************************/

        final VfsFile create (InputStream input)
        {
                create.output.copy(input).close;
                return this;
        }

        /***********************************************************************

                Create and copy the given source

        ***********************************************************************/

        VfsFile copy (VfsFile source)
        {
                auto input = source.input;
                scope (exit) input.close;
                return create (input);
        }

        /***********************************************************************

                Create and copy the given source, and remove the source

        ***********************************************************************/

        final VfsFile move (VfsFile source)
        {
                copy (source);
                source.remove;
                return this;
        }

        /***********************************************************************

                Return the input stream. Don't forget to close it

        ***********************************************************************/

        final InputStream input ()
        {
                return new FileConduit (path.dup);
        }

        /***********************************************************************

                Return the output stream. Don't forget to close it

        ***********************************************************************/

        final OutputStream output ()
        {
                return new FileConduit (path.dup, FileConduit.WriteExisting);
        }

        /***********************************************************************

                Remove this file

        ***********************************************************************/

        final VfsFile remove ()
        {
                path.remove;
                return this;
        }

        /***********************************************************************

                Duplicate this entry

        ***********************************************************************/

        final VfsFile dup()
        {
                return new FileHost (path.toString);
        }

        /***********************************************************************

        ***********************************************************************/

        private VfsFile set (char[] folder, char[] name)
        {
                path.set(folder).append(name);
                return this;
        }
}


debug (FileFolder)
{

/*******************************************************************************

*******************************************************************************/

import tango.io.Stdout;
import tango.io.Buffer;

void main()
{
        auto root = new FileFolder ("d:/d/import/temp", true);
        root.folder("test").create;
        root.file("test.txt").create(new Buffer("hello"));
        Stdout.formatln ("test.txt.length = {}", root.file("test.txt").size);
        
        root = new FileFolder ("c:/");

        auto set = root.self;

        Stdout.formatln ("self.files = {}", set.files);
        Stdout.formatln ("self.bytes = {}", set.bytes);
        Stdout.formatln ("self.folders = {}", set.folders);
        Stdout.formatln ("self.entries = {}", set.entries);

        set = root.tree;
        Stdout.formatln ("tree.files = {}", set.files);
        Stdout.formatln ("tree.bytes = {}", set.bytes);
        Stdout.formatln ("tree.folders = {}", set.folders);
        Stdout.formatln ("tree.entries = {}", set.entries);

        //foreach (folder; set)
        //         Stdout.formatln ("tree.folder '{}' has {} files", folder.name, folder.self.files);

        auto cat = set.catalog ("s*");
        Stdout.formatln ("cat.files = {}", cat.files);
        Stdout.formatln ("cat.bytes = {}", cat.bytes);
        //foreach (file; cat)
        //         Stdout.formatln ("cat.name '{}' '{}'", file.name, file.toString);
}
}
