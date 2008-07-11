/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Oct 2007: Initial version

        author:         Kris

*******************************************************************************/

module tango.io.vfs.VirtualFolder;

private import tango.io.FileConst;

private import tango.util.PathUtil;

private import tango.core.Exception;

private import tango.io.vfs.model.Vfs;

private import tango.text.Util : head, locatePrior;

/*******************************************************************************
        
        Virtual folders play host to other folder types, including both
        concrete folder instances and subordinate virtual folders. You 
        can build a (singly rooted) tree from a set of virtual and non-
        virtual folders, and treat them as though they were a combined
        or single entity. For example, listing the contents of such a
        tree is no different than listing the contents of a non-virtual
        tree - there's just potentially more nodes to traverse.

*******************************************************************************/

class VirtualFolder : VfsHost
{
        private char[]                  name_;
        private VfsFile[char[]]         files;
        private VfsFolder[char[]]       mounts;
        private VfsFolderEntry[char[]]  folders;
        private VirtualFolder           parent;

        /***********************************************************************

                All folder must have a name. No '.' or '/' chars are 
                permitted

        ***********************************************************************/

        this (char[] name)
        {
                validate (this.name_ = name);
        }

        /***********************************************************************

                Return the (short) name of this folder

        ***********************************************************************/

        final char[] name()
        {
                return name_;
        }

        /***********************************************************************

                Return the (long) name of this folder. Virtual folders 
                do not have long names, since they don't relate directly
                to a concrete folder instance

        ***********************************************************************/

        final char[] toString()
        {
                return name;
        }

        /***********************************************************************

                Add a child folder. The child cannot 'overlap' with others
                in the tree of the same type. Circular references across a
                tree of virtual folders are detected and trapped.

                The second argument represents an optional name that the
                mount should be known as, instead of the name exposed by 
                the provided folder (it is not an alias).

        ***********************************************************************/

        VfsHost mount (VfsFolder folder, char[] name = null)
        {
                assert (folder);
                if (name.length is 0)
                    name = folder.name;

                // link virtual children to us
                auto child = cast(VirtualFolder) folder;
                if (child)
                    if (child.parent)
                        error ("folder '"~name~"' belongs to another host"); 
                    else
                       child.parent = this;

                // reach up to the root, and initiate tree sweep
                auto root = this;
                while (root.parent)
                       if (root is this)
                           error ("circular reference detected at '"~this.name~"' while mounting '"~name~"'");
                       else
                          root = root.parent;
                root.verify (folder, true);

                // all clear, so add the new folder
                mounts [name] = folder;
                return this;
        }

        /***********************************************************************

                Add a set of child folders. The children cannot 'overlap' 
                with others in the tree of the same type. Circular references 
                are detected and trapped.

        ***********************************************************************/

        VfsHost mount (VfsFolders group)
        {
                foreach (folder; group)
                         mount (folder);
                return this;
        }

        /***********************************************************************

                Unhook a child folder 

        ***********************************************************************/

        VfsHost dismount (VfsFolder folder)
        {
                char[] name = null;

                // check this is a child, and locate the mapped name
                foreach (key, value; mounts)
                         if (folder is value)
                             name = key; 
                assert (name.ptr);

                // reach up to the root, and initiate tree sweep
                auto root = this;
                while (root.parent)
                       root = root.parent;
                root.verify (folder, false);
        
                // all clear, so remove it
                mounts.remove (name);
                return this;
        }

        /***********************************************************************

                Add a symbolic link to another file. These are referenced
                by file() alone, and do not show up in tree traversals

        ***********************************************************************/

        final VfsHost map (VfsFile file, char[] name)
        {       
                assert (name);
                files[name] = file;
                return this;
        }

        /***********************************************************************

                Add a symbolic link to another folder. These are referenced
                by folder() alone, and do not show up in tree traversals

        ***********************************************************************/

        final VfsHost map (VfsFolderEntry folder, char[] name)
        {       
                assert (name);
                folders[name] = folder;
                return this;
        }

        /***********************************************************************

                Iterate over the set of immediate child folders. This is 
                useful for reflecting the hierarchy

        ***********************************************************************/

        final int opApply (int delegate(inout VfsFolder) dg)
        {
                int result;

                foreach (folder; mounts)  
                        {
                        VfsFolder x = folder;  
                        if ((result = dg(x)) != 0)
                             break;
                        }
                return result;
        }

        /***********************************************************************

                Return a folder representation of the given path. If the
                path-head does not refer to an immediate child, and does
                not match a symbolic link, it is considered unknown.

        ***********************************************************************/

        final VfsFolderEntry folder (char[] path)
        {
                char[] tail;
                auto text = head (path, FileConst.PathSeparatorString, tail);

                auto child = text in mounts;
                if (child)
                    return child.folder (tail);

                auto sym = text in folders;
                if (sym is null)
                    error ("'"~text~"' is not a recognized member of '"~name~"'");
                return *sym;
        }

        /***********************************************************************

                Return a file representation of the given path. If the
                path-head does not refer to an immediate child folder, 
                and does not match a symbolic link, it is considered unknown.

        ***********************************************************************/

        VfsFile file (char[] path)
        {
                auto tail = locatePrior (path, FileConst.PathSeparatorChar);
                if (tail < path.length)
                    return folder(path[0..tail]).open.file(path[tail..$]);

                auto sym = path in files;
                if (sym is null)
                    error ("'"~path~"' is not a recognized member of '"~name~"'");
                return *sym;
        }

        /***********************************************************************

                Clear the entire subtree. Use with caution

        ***********************************************************************/

        final VfsFolder clear ()
        {
                foreach (name, child; mounts)
                         child.clear;
                return this;
        }

        /***********************************************************************

                Returns true if all of the children are writable

        ***********************************************************************/

        final bool writable ()
        {
                foreach (name, child; mounts)
                         if (! child.writable)
                               return false;
                return true;
        }

        /***********************************************************************

                Returns a folder set containing only this one. Statistics 
                are inclusive of entries within this folder only, which 
                should be zero since symbolic links are not included

        ***********************************************************************/

        final VfsFolders self ()
        {
                return new VirtualFolders (this, false);
        }

        /***********************************************************************

                Returns a subtree of folders. Statistics are inclusive of 
                all files and folders throughout the sub-tree

        ***********************************************************************/

        final VfsFolders tree ()
        {
                return new VirtualFolders (this, true);
        }

        /***********************************************************************

                Sweep the subtree of mountpoints, testing a new folder
                against all others. This propogates a folder test down
                throughout the tree, where each folder implementation
                should take appropriate action

        ***********************************************************************/

        final void verify (VfsFolder folder, bool mounting)
        {
                foreach (name, child; mounts)
                         child.verify (folder, mounting);
        }

        /***********************************************************************

                Close and/or synchronize changes made to this folder. Each
                driver should take advantage of this as appropriate, perhaps
                combining multiple files together, or possibly copying to a 
                remote location

        ***********************************************************************/

        VfsFolder close (bool commit = true)
        {
                foreach (name, child; mounts)
                         child.close (commit);
                return this;
        }

        /***********************************************************************

                Throw an exception

        ***********************************************************************/

        package final char[] error (char[] msg)
        {
                throw new VfsException (msg);
        }

        /***********************************************************************

                Validate path names

        ***********************************************************************/

        private final void validate (char[] name)
        {       
                assert (name);
                if (locatePrior(name, '.') != name.length ||
                    locatePrior(name, FileConst.PathSeparatorChar) != name.length)
                    error ("'"~name~"' contains invalid characters");
        }
}


/*******************************************************************************

        A set of virtual folders. For a sub-tree, we compose the results 
        of all our subordinates and delegate subsequent request to that
        group.

*******************************************************************************/

private class VirtualFolders : VfsFolders
{
        private VfsFolders[] members;           // folders in group

        /***********************************************************************

                Create a subset group

        ***********************************************************************/

        private this () {}

        /***********************************************************************

                Create a folder group including the provided folder and
                (optionally) all child folders

        ***********************************************************************/

        private this (VirtualFolder root, bool recurse)
        {
                if (recurse)
                    foreach (name, folder; root.mounts)
                             members ~= folder.tree;
        }

        /***********************************************************************

                Iterate over the set of contained VfsFolder instances

        ***********************************************************************/

        final int opApply (int delegate(inout VfsFolder) dg)
        {
                int ret;

                foreach (group; members)  
                         foreach (folder; group)
                                 { 
                                 auto x = cast(VfsFolder) folder;
                                 if ((ret = dg(x)) != 0)
                                      break;
                                 }
                return ret;
        }

        /***********************************************************************

                Return the number of files in this group

        ***********************************************************************/

        final uint files ()
        {
                uint files;
                foreach (group; members)
                         files += group.files;
                return files;
        }

        /***********************************************************************

                Return the total size of all files in this group

        ***********************************************************************/

        final ulong bytes ()
        {
                ulong bytes;
                foreach (group; members)
                         bytes += group.bytes;
                return bytes;
        }

        /***********************************************************************

                Return the number of folders in this group

        ***********************************************************************/

        final uint folders ()
        {
                uint count;
                foreach (group; members)
                         count += group.folders;
                return count;
        }

        /***********************************************************************

                Return the total number of entries in this group

        ***********************************************************************/

        final uint entries ()
        {
                uint count;
                foreach (group; members)
                         count += group.entries;
                return count;
        }

        /***********************************************************************

                Return a subset of folders matching the given pattern

        ***********************************************************************/

        final VfsFolders subset (char[] pattern)
        {  
                auto set = new VirtualFolders;

                foreach (group; members)    
                         set.members ~= group.subset (pattern); 
                return set;
        }

        /***********************************************************************

                Return a set of files matching the given pattern

        ***********************************************************************/

        final VfsFiles catalog (char[] pattern)
        {
                return catalog ((VfsInfo info){return patternMatch (info.name, pattern);});
        }

        /***********************************************************************

                Returns a set of files conforming to the given filter

        ***********************************************************************/

        final VfsFiles catalog (VfsFilter filter = null)
        {       
                return new VirtualFiles (this, filter);
        }
}


/*******************************************************************************

        A set of virtual files, represented by composing the results of
        the given set of folders. Subsequent calls are delegated to the
        results from those folders

*******************************************************************************/

private class VirtualFiles : VfsFiles
{
        private VfsFiles[] members;

        /***********************************************************************

        ***********************************************************************/

        private this (VirtualFolders host, VfsFilter filter)
        {
                foreach (group; host.members)    
                         members ~= group.catalog (filter); 
        }

        /***********************************************************************

                Iterate over the set of contained VfsFile instances

        ***********************************************************************/

        final int opApply (int delegate(inout VfsFile) dg)
        {
                int ret;

                foreach (group; members)    
                         foreach (file; group)    
                                  if ((ret = dg(file)) != 0)
                                       break;
                return ret;
        }

        /***********************************************************************

                Return the total number of entries 

        ***********************************************************************/

        final uint files ()
        {
                uint count;
                foreach (group; members)    
                         count += group.files;
                return count;
        }

        /***********************************************************************

                Return the total size of all files 

        ***********************************************************************/

        final ulong bytes ()
        {
                ulong count;
                foreach (group; members)    
                         count += group.bytes;
                return count;
        }
}


debug (VirtualFolder)
{
/*******************************************************************************

*******************************************************************************/

import tango.io.Stdout;
import tango.io.Buffer;
import tango.io.vfs.FileFolder;

void main()
{
        auto root = new VirtualFolder ("root");
        auto sub  = new VirtualFolder ("sub");
        sub.mount (new FileFolder (r"d:/d/import/tango"));

        root.mount (sub)
            .mount (new FileFolder (r"c:/"), "windows")
            .mount (new FileFolder (r"d:/d/import/temp"));

        auto folder = root.folder (r"temp/bar");
        Stdout.formatln ("folder = {}", folder);

        root.map (root.folder(r"temp/subtree"), "fsym")
            .map (root.file(r"temp/subtree/test.txt"), "wumpus");
        auto file = root.file (r"wumpus");
        Stdout.formatln ("file = {}", file);
        Stdout.formatln ("fsym = {}", root.folder(r"fsym").open.file("test.txt"));

        foreach (folder; root.folder(r"temp/subtree").open)
                 Stdout.formatln ("folder.child '{}'", folder.name);

        auto set = root.self;
        Stdout.formatln ("self.files = {}", set.files);
        Stdout.formatln ("self.bytes = {}", set.bytes);
        Stdout.formatln ("self.folders = {}", set.folders);

        set = root.folder("temp").open.tree;
        Stdout.formatln ("tree.files = {}", set.files);
        Stdout.formatln ("tree.bytes = {}", set.bytes);
        Stdout.formatln ("tree.folders = {}", set.folders);

        foreach (folder; set)
                 Stdout.formatln ("tree.folder '{}' has {} files", folder.name, folder.self.files);

        auto cat = set.catalog ("*.txt");
        Stdout.formatln ("cat.files = {}", cat.files);
        Stdout.formatln ("cat.bytes = {}", cat.bytes);
        foreach (file; cat)
                 Stdout.formatln ("cat.name '{}' '{}'", file.name, file.toString);
}
}
