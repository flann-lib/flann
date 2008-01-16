/*******************************************************************************

        copyright:      Copyright (c) 2007 Tango. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Jul 2007: Initial version

        author:         Lars Ivar, Kris

*******************************************************************************/

module tango.io.vfs.model.Vfs;

private import tango.io.FilePath;

private import tango.io.model.IConduit;

/*******************************************************************************

                Passed around during filtering

*******************************************************************************/

struct VfsFilterInfo
{
        char[]  path,                   // full path (sans virtual-path)
                name;                   // name + ext
        ulong   bytes;                  // file size, as applicable
        bool    folder;                 // is this a folder?
}

alias VfsFilterInfo* VfsInfo;

// return false to exclude something
public alias bool delegate(VfsInfo) VfsFilter;


/*******************************************************************************

*******************************************************************************/

private struct VfsStats
{
        ulong   bytes;                  // byte count of files
        uint    files,                  // number of files
                folders;                // number of folders
}

/*******************************************************************************

******************************************************************************/

interface VfsHost : VfsFolder
{
        /**********************************************************************

                Add a child folder. The child cannot 'overlap' with others
                in the tree of the same type. Circular references across a
                tree of virtual folders are detected and trapped.

                The second argument represents an optional name that the
                mount should be known as, instead of the name exposed by 
                the provided folder (it is not an alias).

        **********************************************************************/

        VfsHost mount (VfsFolder folder, char[] name=null);

        /***********************************************************************

                Add a set of child folders. The children cannot 'overlap' 
                with others in the tree of the same type. Circular references 
                are detected and trapped.

        ***********************************************************************/

        VfsHost mount (VfsFolders group);

        /**********************************************************************

                Unhook a child folder 

        **********************************************************************/

        VfsHost dismount (VfsFolder folder);

        /**********************************************************************

                Add a symbolic link to another file. These are referenced
                by file() alone, and do not show up in tree traversals

        **********************************************************************/

        VfsHost map (VfsFile target, char[] name);

        /***********************************************************************

                Add a symbolic link to another folder. These are referenced
                by folder() alone, and do not show up in tree traversals

        ***********************************************************************/

        VfsHost map (VfsFolderEntry target, char[] name);
}


/*******************************************************************************

        Supports a model a bit like CSS selectors, where a selection
        of operands is made before applying some operation. For example:
        ---
        // count of files in this folder
        auto count = folder.self.files;

        // accumulated file byte-count
        auto bytes = folder.self.bytes;

        // a group of one folder (itself)
        auto folders = folder.self;
        ---

        The same approach is used to select the subtree descending from
        a folder:
        ---
        // count of files in this tree
        auto count = folder.tree.files;

        // accumulated file byte-count
        auto bytes = folder.tree.bytes;

        // the group of child folders
        auto folders = folder.tree;
        ---

        Filtering can be applied to the tree resulting in a sub-group. 
        Group operations remain applicable. Note that various wildcard 
        characters may be used in the filtering:
        ---
        // select a subset of the resultant tree
        auto folders = folder.tree.subset("install");

        // get total file bytes for a tree subset, using wildcards
        auto bytes = folder.tree.subset("foo*").bytes;
        ---

        Files are selected from a set of folders in a similar manner:
        ---
        // files called "readme.txt" in this folder
        auto count = folder.self.catalog("readme.txt").files;

        // files called "read*.*" in this tree
        auto count = folder.tree.catalog("read*.*").files;

        // all txt files belonging to folders starting with "ins"
        auto count = folder.tree.subset("ins*").catalog("*.txt").files;

        // custom-filtered files within a subtree
        auto count = folder.tree.catalog(&filter).files;
        ---

        Sets of folders and files support iteration via foreach:
        ---
        foreach (folder; root.tree)
                 Stdout.formatln ("folder name:{}", folder.name);

        foreach (folder; root.tree.subset("ins*"))
                 Stdout.formatln ("folder name:{}", folder.name);

        foreach (file; root.tree.catalog("*.d"))
                 Stdout.formatln ("file name:{}", file.name);
        ---

        Creating and opening a sub-folder is supported in a similar
        manner, where the single instance is 'selected' before the
        operation is applied. Open differs from create in that the
        folder must exist for the former:
        ---
        root.folder("myNewFolder").create;

        root.folder("myExistingFolder").open;
        ---
      
        File manipulation is handled in much the same way:
        ---
        root.file("myNewFile").create;

        auto source = root.file("myExistingFile");
        root.file("myCopiedFile").copy(source);
        ---

        The principal benefits of these approaches are twofold: 1) it 
        turns out to be notably more efficient in terms of traversal, and 
        2) there's no casting required, since there is a clean separation 
        between files and folders.
        
        See VfsFile for more information on file handling

*******************************************************************************/

interface VfsFolder
{
        /***********************************************************************

                Return a short name

        ***********************************************************************/

        char[] name();

        /***********************************************************************

                Return a long name

        ***********************************************************************/

        char[] toString();

        /***********************************************************************

                Return a contained file representation 

        ***********************************************************************/

        VfsFile file (char[] path);

        /***********************************************************************

                Return a contained folder representation 

        ***********************************************************************/

        VfsFolderEntry folder (char[] path);

        /***********************************************************************

                Returns a folder set containing only this one. Statistics 
                are inclusive of entries within this folder only

        ***********************************************************************/

        VfsFolders self ();

        /***********************************************************************

                Returns a subtree of folders. Statistics are inclusive of 
                files within this folder and all others within the tree

        ***********************************************************************/

        VfsFolders tree ();

        /***********************************************************************

                Iterate over the set of immediate child folders. This is 
                useful for reflecting the hierarchy

        ***********************************************************************/

        int opApply (int delegate(inout VfsFolder) dg);

        /***********************************************************************

                Clear all content from this folder and subordinates

        ***********************************************************************/

        VfsFolder clear();

        /***********************************************************************

                Is folder writable?

        ***********************************************************************/

        bool writable();

        /***********************************************************************

                Close and/or synchronize changes made to this folder. Each
                driver should take advantage of this as appropriate, perhaps
                combining multiple files together, or possibly copying to a 
                remote location

        ***********************************************************************/

        VfsFolder close (bool commit = true);

        /***********************************************************************

                A folder is being added or removed from the hierarchy. Use 
                this to test for validity (or whatever) and throw exceptions 
                as necessary

        ***********************************************************************/

        void verify (VfsFolder folder, bool mounting);

        //VfsFolder copy(VfsFolder from, char[] to);
        //VfsFolder move(Entry from, VfsFolder toFolder, char[] toName);
        //char[] absolutePath(char[] path);
}


/*******************************************************************************

        Operations upon a set of folders 

*******************************************************************************/

interface VfsFolders
{
        /***********************************************************************

                Iterate over the set of contained VfsFolder instances

        ***********************************************************************/

        int opApply (int delegate(inout VfsFolder) dg);

        /***********************************************************************

                Return the number of files 

        ***********************************************************************/

        uint files();

        /***********************************************************************

                Return the number of folders 

        ***********************************************************************/

        uint folders();

        /***********************************************************************

                Return the total number of entries (files + folders)

        ***********************************************************************/

        uint entries();

        /***********************************************************************

                Return the total size of contained files 

        ***********************************************************************/

        ulong bytes();

        /***********************************************************************

                Return a subset of folders matching the given pattern

        ***********************************************************************/

        VfsFolders subset (char[] pattern);

       /***********************************************************************

                Return a set of files matching the given pattern

        ***********************************************************************/

        VfsFiles catalog (char[] pattern);

        /***********************************************************************

                Return a set of files matching the given filter

        ***********************************************************************/

        VfsFiles catalog (VfsFilter filter = null);
}


/*******************************************************************************

        Operations upon a set of files

*******************************************************************************/

interface VfsFiles
{
        /***********************************************************************

                Iterate over the set of contained VfsFile instances

        ***********************************************************************/

        int opApply (int delegate(inout VfsFile) dg);

        /***********************************************************************

                Return the total number of entries 

        ***********************************************************************/

        uint files();

        /***********************************************************************

                Return the total size of all files 

        ***********************************************************************/

        ulong bytes();
}


/*******************************************************************************

        A specific file representation 

*******************************************************************************/

interface VfsFile 
{
        /***********************************************************************

                Return a short name

        ***********************************************************************/

        char[] name();

        /***********************************************************************

                Return a long name

        ***********************************************************************/

        char[] toString();

        /***********************************************************************

                Does this file exist?

        ***********************************************************************/

        bool exists();

        /***********************************************************************

                Return the file size

        ***********************************************************************/

        ulong size ();

        /***********************************************************************

                Create and copy the given source

        ***********************************************************************/

        VfsFile copy (VfsFile source);

        /***********************************************************************

                Create and copy the given source, and remove the source

        ***********************************************************************/

        VfsFile move (VfsFile source);

        /***********************************************************************

                Create a new file instance

        ***********************************************************************/

        VfsFile create ();

        /***********************************************************************

                Create a new file instance and populate with stream

        ***********************************************************************/

        VfsFile create (InputStream stream);

        /***********************************************************************

                Remove this file

        ***********************************************************************/

        VfsFile remove ();

        /***********************************************************************

                Return the input stream. Don't forget to close it

        ***********************************************************************/

        InputStream input ();

        /***********************************************************************

                Return the output stream. Don't forget to close it

        ***********************************************************************/

        OutputStream output ();

        /***********************************************************************

                Duplicate this entry

        ***********************************************************************/

        VfsFile dup ();
}


/*******************************************************************************

        Handler for folder operations. Needs some work ...

*******************************************************************************/

interface VfsFolderEntry 
{
        /***********************************************************************

                Open a folder

        ***********************************************************************/

        VfsFolder open ();

        /***********************************************************************

                Create a new folder

        ***********************************************************************/

        VfsFolder create ();

        /***********************************************************************

                Test to see if a folder exists

        ***********************************************************************/

        bool exists ();
}


/*******************************************************************************

    Would be used for things like zip files, where the
    implementation mantains the contents in memory or on disk, and where
    the actual zip file isn't/shouldn't be written until one is finished
    filling it up (for zip due to inefficient file format).

*******************************************************************************/

interface VfsSync
{
        /***********************************************************************

        ***********************************************************************/

        VfsFolder sync();
}

