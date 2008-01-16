/*******************************************************************************

    copyright:  Copyright © 2007 Daniel Keep.  All rights reserved.

    license:    BSD style: $(LICENSE)

    version:    Initial release: December 2007

    author:     Daniel Keep

*******************************************************************************/

module tango.io.vfs.ZipArchive;

import tango.io.FileConduit : FileConduit;
import tango.io.FilePath : FilePath;
import tango.io.TempFile : TempFile;
import tango.io.archive.Zip : ZipReader, ZipBlockReader,
       ZipWriter, ZipBlockWriter, ZipEntry, ZipEntryInfo, Method;
import tango.io.model.IConduit : IConduit, InputStream, OutputStream;
import tango.io.vfs.model.Vfs : VfsFolder, VfsFolderEntry, VfsFile,
       VfsFolders, VfsFiles, VfsFilter, VfsStats, VfsFilterInfo,
       VfsInfo, VfsSync;
import tango.util.PathUtil : patternMatch;

debug( ZipArchive )
{
    import tango.io.Stdout : Stderr;
}

// This disables code that is causing heap corruption in Tango 0.99.3
version = Bug_HeapCorruption;

// ************************************************************************ //
// ************************************************************************ //

private
{
    enum EntryType { Dir, File }
   
    /*
     * Entries are what make up the internal tree that describes the
     * filesystem of the archive.  Each Entry is either a directory or a file.
     */
    struct Entry
    {
        EntryType type;

        union
        {
            DirEntry dir;
            FileEntry file;
        }

        char[] fullname;
        char[] name;

        /+
        invariant
        {
            assert( (type == EntryType.Dir)
                 || (type == EntryType.File) );

            assert( fullname.nz() );
            assert( name.nz() );
        }
        +/

        VfsFilterInfo vfsFilterInfo;

        VfsInfo vfsInfo()
        {
            return &vfsFilterInfo;
        }

        /*
         * Updates the VfsInfo structure for this entry.
         */
        void makeVfsInfo()
        {
            with( vfsFilterInfo )
            {
                // Cheat horribly here
                name = this.name;
                path = this.fullname[0..($-name.length+"/".length)];

                folder = isDir;
                bytes = folder ? 0 : fileSize;
            }
        }

        bool isDir()
        {
            return (type == EntryType.Dir);
        }

        bool isFile()
        {
            return (type == EntryType.File);
        }

        ulong fileSize()
        in
        {
            assert( type == EntryType.File );
        }
        body
        {
            if( file.zipEntry !is null )
                return file.zipEntry.size;

            else if( file.tempFile !is null )
                return file.tempFile.length;

            else
                return 0;
        }

        /*
         * Opens a File Entry for reading.
         *
         * BUG: Currently, if a user opens a new or unmodified file for input,
         * and then opens it for output, the two streams will be working with
         * different underlying conduits.  This means that the result of
         * openInput should probably be wrapped in some kind of switching
         * stream that can update when the backing store for the file changes.
         */
        InputStream openInput()
        in
        {
            assert( type == EntryType.File );
        }
        body
        {
            if( file.zipEntry !is null )
            {
                file.zipEntry.verify;
                return file.zipEntry.open;
            }
            else if( file.tempFile !is null )
                return new WrapSeekInputStream(file.tempFile.input, 0);

            else
                return new DummyInputStream;
        }

        /*
         * Opens a file entry for output.
         */
        OutputStream openOutput()
        in
        {
            assert( type == EntryType.File );
        }
        body
        {
            if( file.tempFile !is null )
                return new WrapSeekOutputStream(file.tempFile.output);

            else
            {
                // Ok; we need to make a temporary file to store output in.
                // If we already have a zip entry, we need to dump that into
                // the temp. file and remove the zipEntry.
                if( file.zipEntry !is null )
                {
                    {
                        scope zi = file.zipEntry.open;
                        scope(exit) zi.close;
    
                        file.tempFile = new TempFile;
                        file.tempFile.output.copy(zi).close;

                        debug( ZipArchive )
                            Stderr.formatln("Entry.openOutput: duplicated"
                                    " temp file {} for {}",
                                    file.tempFile, this.fullname);
                    }

                    // TODO: Copy file info if available

                    file.zipEntry = null;
                }
                else
                {
                    // Otherwise, just make a new, blank temp file
                    file.tempFile = new TempFile;

                    debug( ZipArchive )
                        Stderr.formatln("Entry.openOutput: created"
                                " temp file {} for {}",
                                file.tempFile, this.fullname);
                }

                assert( file.tempFile !is null );
                return openOutput;
            }
        }

        void dispose()
        {
            fullname = name = null;
            
            with( vfsFilterInfo )
            {
                name = path = null;
            }

            dispose_children;
        }

        void dispose_children()
        {
            switch( type )
            {
                case EntryType.Dir:
                    auto keys = dir.children.keys;
                    scope(exit) delete keys;
                    foreach( k ; keys )
                    {
                        auto child = dir.children[k];
                        child.dispose();
                        dir.children.remove(k);
                        delete child;
                    }
                    dir.children = dir.children.init;
                    break;

                case EntryType.File:
                    if( file.zipEntry !is null )
                    {
                        // Don't really need to do anything here
                        file.zipEntry = null;
                    }
                    else if( file.tempFile !is null )
                    {
                        // Detatch to destroy the physical file itself
                        file.tempFile.detach();
                        file.tempFile = null;
                    }
                    break;

                debug( ZipArchive )
                {
                default:
                    Stderr.formatln(
                            "Entry.dispose_children: unknown type {}",
                            type);
                    assert(false);
                }
            }
        }
    }

    struct DirEntry
    {
        Entry*[char[]] children;
    }

    struct FileEntry
    {
        ZipEntry zipEntry;
        TempFile tempFile;

        invariant
        {
            auto zn = zipEntry is null;
            auto tn = tempFile is null;
            assert( (zn && tn)
          /* zn xor tn */ || (!(zn&&tn)&&(zn||tn)) );
        }
    }
}

// ************************************************************************ //
// ************************************************************************ //

/**
 * ZipArchive serves as the root object for all Zip archives in the VFS.
 * Presently, it can only open archives on the local filesystem.
 */
class ZipArchive : ZipFolder
{
    /**
     * Opens an archive from the local filesystem.  If the readonly argument
     * is specified as true, then modification of the archive will be
     * explicitly disallowed.
     */
    this(char[] path, bool readonly=false)
    out { assert( valid ); }
    body
    {
        debug( ZipArchive )
            Stderr.formatln(`ZipArchive("{}", {})`, path, readonly);
        this(FilePath(path), readonly);
    }

    /// ditto
    this(FilePath path, bool readonly=false)
    out { assert( valid ); }
    body
    {
        debug( ZipArchive )
            Stderr.formatln(`ZipArchive("{}", {})`, path, readonly);
        this.resetArchive(path, readonly);
        super(this, root);
    }

    /**
     * Closes the archive, and releases all internal resources.  If the commit
     * argument is true (the default), then changes to the archive will be
     * flushed out to disk.  If false, changes will simply be discarded.
     */
    final override VfsFolder close(bool commit = true)
    in { assert( valid ); }
    body
    {
        debug( ZipArchive )
            Stderr.formatln("ZipArchive.close({})",commit);

        // MUTATE
        if( commit ) sync;

        // Close ZipReader
        if( zr !is null )
        {
            zr.close();
            delete zr;
        }

        // Destroy entries
        root.dispose();
        version( Bug_HeapCorruption )
            root = null;
        else
            delete root;

        return this;
    }

    /**
     * Flushes all changes to the archive out to disk.
     */
    final override VfsFolder sync()
    in { assert( valid ); }
    out
    {
        assert( valid );
        assert( !modified );
    }
    body
    {
        debug( ZipArchive )
            Stderr("ZipArchive.sync()").newline;

        if( !modified )
            return this;

version( ZipArchive_NonMutating )
{
        mutate_error("ZipArchive.sync");
        assert(false);
}
else
{
        enforce_mutable;
        
        // First, we need to determine if we have any zip entries.  If we
        // don't, then we can write directly to the path.  If there *are*
        // zip entries, then we'll need to write to a temporary path instead.
        OutputStream os;
        TempFile tempFile;
        scope(exit) if( tempFile !is null ) delete tempFile;

        foreach( file ; this.tree.catalog )
        {
            if( auto zf = cast(ZipFile) file )
                if( zf.entry.file.zipEntry !is null )
                {
                    tempFile = new TempFile(path.path, TempFile.Permanent);
                    os = tempFile.output;
                    debug( ZipArchive )
                        Stderr.formatln(" sync: created temp file {}",
                                tempFile.path);
                    break;
                }
        }

        if( tempFile is null )
        {
            // Kill the current zip reader so we can re-open the file it's
            // using.
            if( zr !is null )
            {
                zr.close;
                delete zr;
            }

            os = new FileConduit(path, FileConduit.WriteCreate);
        }

        // Now, we can create the archive.
        {
            scope zw = new ZipBlockWriter(os);
            foreach( file ; this.tree.catalog )
            {
                auto zei = ZipEntryInfo(file.toString[1..$]);
                // BUG: Passthru doesn't maintain compression for some
                // reason...
                if( auto zf = cast(ZipFile) file )
                {
                    if( zf.entry.file.zipEntry !is null )
                        zw.putEntry(zei, zf.entry.file.zipEntry);
                    else
                        zw.putStream(zei, file.input);
                }
                else
                    zw.putStream(zei, file.input);
            }
            zw.finish;
        }

        // With that done, we can free all our handles, etc.
        debug( ZipArchive )
            Stderr(" sync: close").newline;
        this.close(/*commit*/ false);
        os.close;

        // If we wrote the archive into a temporary file, move that over the
        // top of the old archive.
        if( tempFile !is null )
        {
            debug( ZipArchive )
                Stderr(" sync: destroying temp file").newline;
            auto tempFilePath = tempFile.path.dup;
            delete tempFile;
            debug( ZipArchive )
                Stderr.formatln(" sync: renaming {} to {}",
                        tempFilePath, path);
            tempFilePath.rename(path);
        }

        // Finally, re-open the archive so that we have all the nicely
        // compressed files.
        debug( ZipArchive )
            Stderr(" sync: reset archive").newline;
        this.resetArchive(path, readonly);
        
        debug( ZipArchive )
            Stderr(" sync: reset folder").newline;
        this.reset(this, root);

        debug( ZipArchive )
            Stderr(" sync: done").newline;

        return this;
}
    }

    /**
     * Indicates whether the archive was opened for read-only access.  Note
     * that in addition to the readonly constructor flag, this is also
     * influenced by whether the file itself is read-only or not.
     */
    final bool readonly() { return _readonly; }

    /**
     * Allows you to read and specify the path to the archive.  The effect of
     * setting this is to change where the archive will be written to when
     * flushed to disk.
     */
    final FilePath path() { return _path; }
    final FilePath path(FilePath v) { return _path = v; } /// ditto

private:
    ZipReader zr;
    Entry* root;
    FilePath _path;
    bool _readonly;
    bool modified = false;

    final bool readonly(bool v) { return _readonly = v; }

    final bool closed()
    {
        debug( ZipArchive )
            Stderr("ZipArchive.closed()").newline;
        return (root is null);
    }

    final bool valid()
    {
        debug( ZipArchive )
            Stderr("ZipArchive.valid()").newline;
        return !closed;
    }

    final OutputStream mutateStream(OutputStream source)
    {
        return new EventSeekOutputStream(source,
                EventSeekOutputStream.Callbacks(
                    null,
                    null,
                    &mutate_write,
                    null));
    }

    void mutate_write(uint bytes, void[] src)
    {
        if( !(bytes == 0 || bytes == IConduit.Eof) )
            this.modified = true;
    }

    void resetArchive(FilePath path, bool readonly=false)
    out { assert( valid ); }
    body
    {
        debug( ZipArchive )
            Stderr.formatln(`ZipArchive.resetArchive("{}", {})`, path, readonly);

        debug( ZipArchive )
            Stderr.formatln(" .. size of Entry: {0}, {0:x} bytes", Entry.sizeof);

        this.path = path;
        this.readonly = readonly & !path.isWritable;

        zr = new ZipBlockReader(path.toString);

        // First, create a root entry
        root = new Entry;
        root.type = EntryType.Dir;
        root.fullname = root.name = "/";

        // Parse the contents of the archive
        foreach( zipEntry ; zr )
        {
            // Normalise name
            auto name = FilePath(zipEntry.info.name).standard.toString;

            // If the last character is '/', treat as a directory and skip
            // TODO: is there a better way of detecting this?
            if( name[$-1] == '/' )
                continue;

            // Now, we need to locate the right spot to insert this entry.
            {
                // That's CURrent ENTity, not current OR currant...
                Entry* curent = root;
                char[] h,t;
                headTail(name,h,t);
                while( t.nz() )
                {
                    assert( curent.isDir );
                    if( auto nextent = (h in curent.dir.children) )
                        curent = *nextent;
                    
                    else
                    {
                        // Create new directory entry
                        Entry* dirent = new Entry;
                        dirent.type = EntryType.Dir;
                        if( curent.fullname != "/" )
                            dirent.fullname = curent.fullname ~ "/" ~ h;
                        else
                            dirent.fullname = "/" ~ h;
                        dirent.name = dirent.fullname[$-h.length..$];

                        // Insert into current entry
                        curent.dir.children[dirent.name] = dirent;

                        // Make it the new current entry
                        curent = dirent;
                    }

                    headTail(t,h,t);
                }

                // Getting here means that t is empty, which means the final
                // component of the path--the file name--is in h.  The entry
                // of the containing directory is in curent.

                // Make sure the file isn't already there (you never know!)
                assert( !(h in curent.dir.children) );

                // Create a new file entry for it.
                {
                    // BUG: Bug_HeapCorruption
                    // with ZipTest, on the resetArchive operation, on
                    // the second time through this next line, it erroneously
                    // allocates filent 16 bytes lower than curent.  Entry
                    // is *way* larger than 16 bytes, and this causes it to
                    // zero-out the existing root element, which leads to
                    // segfaults later on at line +12:
                    //
                    //      // Insert
                    //      curent.dir.children[filent.name] = filent;

                    Entry* filent = new Entry;
                    filent.type = EntryType.File;
                    if( curent.fullname != "/" )
                        filent.fullname = curent.fullname ~ "/" ~ h;
                    else
                        filent.fullname = "/" ~ h;
                    filent.name = filent.fullname[$-h.length..$];
                    filent.file.zipEntry = zipEntry.dup;

                    filent.makeVfsInfo;

                    // Insert
                    curent.dir.children[filent.name] = filent;
                }
            }
        }

        // Make sure the modified flag is set appropriately
        modified = false;
    }
}

// ************************************************************************ //
// ************************************************************************ //

/**
 * This class represents a folder in an archive.  In addition to supporting
 * the sync operation, you can also use the archive member to get a reference
 * to the underlying ZipArchive instance.
 */
class ZipFolder : VfsFolder, VfsSync
{
    ///
    final override char[] name()
    in { assert( valid ); }
    body
    {
        return entry.name;
    }

    ///
    final override char[] toString()
    in { assert( valid ); }
    body
    {
        return entry.fullname;
    }

    ///
    final override VfsFile file(char[] path)
    in
    {
        assert( valid );
        assert( !FilePath(path).isAbsolute );
    }
    body
    {
        auto fp = FilePath(path);
        auto dir = fp.path;
        auto name = fp.file;

        // If the file is in another directory, then we need to look up that
        // up first.
        if( dir.nz() )
        {
            scope dir_ent = this.folder(dir);
            scope dir_obj = dir_ent.open;
            return dir_obj.file(name);
        }
        else
        {
            // Otherwise, we need to check and see whether the file is in our
            // entry list.
            if( auto file_entry = (name in this.entry.dir.children) )
            {
                // It is; create a new object for it.
                return new ZipFile(archive, this.entry, *file_entry);
            }
            else
            {
                // Oh dear... return a holding object.
                return new ZipFile(archive, this.entry, name);
            }
        }
    }

    ///
    final override VfsFolderEntry folder(char[] path)
    in
    {
        assert( valid );
        assert( !FilePath(path).isAbsolute );
    }
    body
    {
        // Locate the folder in question.  We do this by "walking" the
        // path components.  If we find a component that doesn't exist,
        // then we create a ZipFolderEntry for the remainder.
        Entry* curent = this.entry;

        // h is the "head" of the path, t is the remainder.  ht is both
        // joined together.
        char[] h,t,ht;
        ht = path;

        do
        {
            // Split ht at the first path separator.
            assert( ht.nz() );
            headTail(ht,h,t);

            // Look for a pre-existing subentry
            auto subent = (h in curent.dir.children);
            if( t.nz() && !!subent )
            {
                // Move to the subentry, and split the tail on the next
                // iteration.
                curent = *subent;
                ht = t;
            }
            else
                // If the next component doesn't exist, return a folder entry.
                // If the tail is empty, return a folder entry as well (let
                // the ZipFolderEntry do the last lookup.)
                return new ZipFolderEntry(archive, curent, ht);
        }
        while( true );
    }

    ///
    final override VfsFolders self()
    in { assert( valid ); }
    body
    {
        return new ZipFolderGroup(archive, this, false);
    }

    ///
    final override VfsFolders tree()
    in { assert( valid ); }
    body
    {
        return new ZipFolderGroup(archive, this, true);
    }

    ///
    final override int opApply(int delegate(ref VfsFolder) dg)
    in { assert( valid ); }
    body
    {
        int result = 0;

        foreach( _,childEntry ; this.entry.dir.children )
        {
            if( childEntry.isDir )
            {
                VfsFolder childFolder = new ZipFolder(archive, childEntry);
                if( (result = dg(childFolder)) != 0 )
                    break;
            }
        }

        return result;
    }

    ///
    final override VfsFolder clear()
    in { assert( valid ); }
    body
    {
version( ZipArchive_NonMutating )
{
        mutate_error("VfsFolder.clear");
        assert(false);
}
else
{
        // MUTATE
        enforce_mutable;

        // Disposing of the underlying entry subtree should do our job for us.
        entry.dispose_children;
        mutate;
        return this;
}
    }

    ///
    final override bool writable()
    in { assert( valid ); }
    body
    {
        return !archive.readonly;
    }

    /**
     * Closes this folder object.  If commit is true, then the folder is
     * sync'ed before being closed.
     */
    override VfsFolder close(bool commit = true)
    in { assert( valid ); }
    body
    {
        // MUTATE
        if( commit ) sync;

        // Just clean up our pointers
        archive = null;
        entry = null;
        return this;
    }

    /**
     * This will flush any changes to the archive to disk.  Note that this
     * applies to the entire archive, not just this folder and its contents.
     */
    override VfsFolder sync()
    in { assert( valid ); }
    body
    {
        // MUTATE
        archive.sync;
        return this;
    }

    ///
    final override void verify(VfsFolder folder, bool mounting)
    in { assert( valid ); }
    body
    {
        auto zipfolder = cast(ZipFolder) folder;

        if( mounting
                && zipfolder !is null
                && zipfolder.archive is archive )
        {
            auto src = this.toString;
            auto dst = zipfolder.toString;

            auto len = src.length > dst.length ? dst.length : src.length;

            if( src[0..len] == dst[0..len] )
                error(`folders "`~dst~`" and "`~src~`" in archive "`
                        ~archive.path.toString~`" overlap`);
        }
    }

    /**
     * Returns a reference to the underlying ZipArchive instance.
     */
    final ZipArchive archive() { return _archive; }

private:
    ZipArchive _archive;
    Entry* entry;
    VfsStats stats;

    final ZipArchive archive(ZipArchive v) { return _archive = v; }

    this(ZipArchive archive, Entry* entry)
    {
        this.reset(archive, entry);
    }

    final void reset(ZipArchive archive, Entry* entry)
    in
    {
        assert( archive !is null );
        assert( entry.isDir );
    }
    out { assert( valid ); }
    body
    {
        this.archive = archive;
        this.entry = entry;
    }

    final bool valid()
    {
        return( (archive !is null) && !archive.closed );
    }

    final void enforce_mutable()
    in { assert( valid ); }
    body
    {
        if( archive.readonly )
            // TODO: exception
            throw new Exception("cannot mutate a read-only Zip archive");
    }

    final void mutate()
    in { assert( valid ); }
    body
    {
        enforce_mutable;
        archive.modified = true;
    }

    final ZipFolder[] folders(bool collect)
    in { assert( valid ); }
    body
    {
        ZipFolder[] folders;
        stats = stats.init;

        foreach( _,childEntry ; entry.dir.children )
        {
            if( childEntry.isDir )
            {
                if( collect ) folders ~= new ZipFolder(archive, childEntry);
                ++ stats.folders;
            }
            else
            {
                assert( childEntry.isFile );
                stats.bytes += childEntry.fileSize;
                ++ stats.files;
            }
        }

        return folders;
    }

    final Entry*[] files(ref VfsStats stats, VfsFilter filter = null)
    in { assert( valid ); }
    body
    {
        Entry*[] files;

        foreach( _,childEntry ; entry.dir.children )
        {
            if( childEntry.isFile )
                if( filter is null || filter(childEntry.vfsInfo) )
                {
                    files ~= childEntry;
                    stats.bytes += childEntry.fileSize;
                    ++stats.files;
                }
        }

        return files;
    }
}

// ************************************************************************ //
// ************************************************************************ //

/**
 * This class represents a file within an archive.
 */
class ZipFile : VfsFile
{
    ///
    final override char[] name()
    in { assert( valid ); }
    body
    {
        if( entry ) return entry.name;
        else        return name_;
    }

    ///
    final override char[] toString()
    in { assert( valid ); }
    body
    {
        if( entry ) return entry.fullname;
        else        return parent.fullname ~ "/" ~ name_;
    }

    ///
    final override bool exists()
    in { assert( valid ); }
    body
    {
        // If we've only got a parent and a name, this means we don't actually
        // exist; EXISTENTIAL CRISIS TEIM!!!
        return !!entry;
    }

    ///
    final override ulong size()
    in { assert( valid ); }
    body
    {
        if( exists )
            return entry.fileSize;
        else
            error("ZipFile.size: cannot reliably determine size of a "
                    "non-existent file");
    }

    ///
    final override VfsFile copy(VfsFile source)
    in { assert( valid ); }
    body
    {
version( ZipArchive_NonMutating )
{
        mutate_error("ZipFile.copy");
        assert(false);
}
else
{
        // MUTATE
        enforce_mutable;

        if( !exists ) this.create;
        this.output.copy(source.input);

        return this;
}
    }

    ///
    final override VfsFile move(VfsFile source)
    in { assert( valid ); }
    body
    {
version( ZipArchive_NonMutating )
{
        mutate_error("ZipFile.move");
        assert(false);
}
else
{
        // MUTATE
        enforce_mutable;

        this.copy(source);
        source.remove;

        return this;
}
    }

    ///
    final override VfsFile create()
    in { assert( valid ); }
    out { assert( valid ); }
    body
    {
version( ZipArchive_NonMutating )
{
        mutate_error("ZipFile.create");
        assert(false);
}
else
{
        if( exists )
            error("ZipFile.create: cannot create already existing file: "
                    "this folder ain't big enough for the both of 'em");

        // MUTATE
        enforce_mutable;

        auto entry = new Entry;
        entry.type = EntryType.File;
        entry.fullname = parent.fullname.dir_app(name);
        entry.name = entry.fullname[$-name.length..$];
        entry.makeVfsInfo;

        assert( !(entry.name in parent.dir.children) );
        parent.dir.children[entry.name] = entry;
        this.reset(archive, parent, entry);
        mutate;

        // Done
        return this;
}
    }

    ///
    final override VfsFile create(InputStream stream)
    in { assert( valid ); }
    body
    {
version( ZipArchive_NonMutating )
{
        mutate_error("ZipFile.create");
        assert(false);
}
else
{
        create;
        output.copy(stream).close;
        return this;
}
    }

    ///
    final override VfsFile remove()
    in{ assert( valid ); }
    out { assert( valid ); }
    body
    {
version( ZipArchive_NonMutating )
{
        mutate_error("ZipFile.remove");
        assert(false);
}
else
{
        if( !exists )
            error("ZipFile.remove: cannot remove non-existent file; "
                    "rather redundant, really");

        // MUTATE
        enforce_mutable;

        // Save the old name
        auto old_name = name;

        // Do the removal
        assert( !!(name in parent.dir.children) );
        parent.dir.children.remove(name);
        entry.dispose;
        entry = null;
        mutate;

        // Swap out our now empty entry for the name, so the file can be
        // directly recreated.
        this.reset(archive, parent, old_name);

        return this;
}
    }

    ///
    final override InputStream input()
    in { assert( valid ); }
    body
    {
        if( exists )
            return entry.openInput;

        else
            error("ZipFile.input: cannot open non-existent file for input; "
                    "results would not be very useful");
    }

    ///
    final override OutputStream output()
    in { assert( valid ); }
    body
    {
version( ZipArchive_NonMutable )
{
        mutate_error("ZipFile.output");
        assert(false);
}
else
{
        // MUTATE
        enforce_mutable;
        
        // Don't call mutate; defer that until the user actually writes to or
        // modifies the underlying stream.
        return archive.mutateStream(entry.openOutput);
}
    }

    ///
    final override VfsFile dup()
    in { assert( valid ); }
    body
    {
        if( entry )
            return new ZipFile(archive, parent, entry);
        else
            return new ZipFile(archive, parent, name);
    }

private:
    ZipArchive archive;
    Entry* entry;

    Entry* parent;
    char[] name_;

    this()
    out { assert( !valid ); }
    body
    {
    }

    this(ZipArchive archive, Entry* parent, Entry* entry)
    in
    {
        assert( archive !is null );
        assert( parent );
        assert( parent.isDir );
        assert( entry );
        assert( entry.isFile );
        assert( parent.dir.children[entry.name] is entry );
    }
    out { assert( valid ); }
    body
    {
        this.reset(archive, parent, entry);
    }

    this(ZipArchive archive, Entry* parent, char[] name)
    in
    {
        assert( archive !is null );
        assert( parent );
        assert( parent.isDir );
        assert( name.nz() );
        assert( !(name in parent.dir.children) );
    }
    out { assert( valid ); }
    body
    {
        this.reset(archive, parent, name);
    }

    final bool valid()
    {
        return( (archive !is null) && !archive.closed );
    }

    final void enforce_mutable()
    in { assert( valid ); }
    body
    {
        if( archive.readonly )
            // TODO: exception
            throw new Exception("cannot mutate a read-only Zip archive");
    }

    final void mutate()
    in { assert( valid ); }
    body
    {
        enforce_mutable;
        archive.modified = true;
    }

    final void reset(ZipArchive archive, Entry* parent, Entry* entry)
    in
    {
        assert( archive !is null );
        assert( parent );
        assert( parent.isDir );
        assert( entry );
        assert( entry.isFile );
        assert( parent.dir.children[entry.name] is entry );
    }
    out { assert( valid ); }
    body
    {
        this.parent = parent;
        this.archive = archive;
        this.entry = entry;
        this.name_ = null;
    }

    final void reset(ZipArchive archive, Entry* parent, char[] name)
    in
    {
        assert( archive !is null );
        assert( parent );
        assert( parent.isDir );
        assert( name.nz() );
        assert( !(name in parent.dir.children) );
    }
    out { assert( valid ); }
    body
    {
        this.archive = archive;
        this.parent = parent;
        this.entry = null;
        this.name_ = name;
    }

    final void close()
    in { assert( valid ); }
    out { assert( !valid ); }
    body
    {
        archive = null;
        parent = null;
        entry = null;
        name_ = null;
    }
}

// ************************************************************************ //
// ************************************************************************ //

class ZipFolderEntry : VfsFolderEntry
{
    final override VfsFolder open()
    in { assert( valid ); }
    body
    {
        auto entry = (name in parent.dir.children);
        if( entry )
            return new ZipFolder(archive, *entry);

        else
        {
            // NOTE: this can be called with a multi-part path.
            error("ZipFolderEntry.open: \""
                    ~ parent.fullname ~ "/" ~ name
                    ~ "\" does not exist");
        }
    }

    final override VfsFolder create()
    in { assert( valid ); }
    body
    {
version( ZipArchive_NonMutating )
{
        // TODO: different exception if folder exists (this operation is
        // currently invalid either way...)
        mutate_error("ZipFolderEntry.create");
        assert(false);
}
else
{
        // MUTATE
        enforce_mutable;

        // If the folder exists, we can't really create it, now can we?
        if( this.exists )
            error("ZipFolderEntry.create: cannot create folder that already "
                    "exists, and believe me, I *tried*");
        
        // Ok, I suppose I can do this for ya...
        auto entry = new Entry;
        entry.type = EntryType.Dir;
        entry.fullname = parent.fullname.dir_app(name);
        entry.name = entry.fullname[$-name.length..$];
        entry.makeVfsInfo;

        assert( !(entry.name in parent.dir.children) );
        parent.dir.children[entry.name] = entry;
        mutate;

        // Done
        return new ZipFolder(archive, entry);
}
    }

    final override bool exists()
    in { assert( valid ); }
    body
    {
        return !!(name in parent.dir.children);
    }

private:
    ZipArchive archive;
    Entry* parent;
    char[] name;

    this(ZipArchive archive, Entry* parent, char[] name)
    in
    {
        assert( archive !is null );
        assert( parent.isDir );
        assert( name.nz() );
        assert( name.single_path_part() );
    }
    out { assert( valid ); }
    body
    {
        this.archive = archive;
        this.parent = parent;
        this.name = name;
    }

    final bool valid()
    {
        return (archive !is null) && !archive.closed;
    }
    
    final void enforce_mutable()
    in { assert( valid ); }
    body
    {
        if( archive.readonly )
            // TODO: exception
            throw new Exception("cannot mutate a read-only Zip archive");
    }

    final void mutate()
    in { assert( valid ); }
    body
    {
        enforce_mutable;
        archive.modified = true;
    }
}

// ************************************************************************ //
// ************************************************************************ //

class ZipFolderGroup : VfsFolders
{
    final override int opApply(int delegate(ref VfsFolder) dg)
    in { assert( valid ); }
    body
    {
        int result = 0;

        foreach( folder ; members )
        {
            VfsFolder x = folder;
            if( (result = dg(x)) != 0 )
                break;
        }

        return result;
    }

    final override uint files()
    in { assert( valid ); }
    body
    {
        uint files = 0;

        foreach( folder ; members )
            files += folder.stats.files;

        return files;
    }

    final override uint folders()
    in { assert( valid ); }
    body
    {
        return members.length;
    }

    final override uint entries()
    in { assert( valid ); }
    body
    {
        return files + folders;
    }

    final override ulong bytes()
    in { assert( valid ); }
    body
    {
        ulong bytes = 0;

        foreach( folder ; members )
            bytes += folder.stats.bytes;

        return bytes;
    }

    final override VfsFolders subset(char[] pattern)
    in { assert( valid ); }
    body
    {
        ZipFolder[] set;

        foreach( folder ; members )
            if( patternMatch(folder.name, pattern) )
                set ~= folder;

        return new ZipFolderGroup(archive, set);
    }

    final override VfsFiles catalog(char[] pattern)
    in { assert( valid ); }
    body
    {
        return catalog(
            (VfsInfo info)
            {
                return patternMatch(info.name, pattern);
            }
        );
    }

    final override VfsFiles catalog(VfsFilter filter = null)
    in { assert( valid ); }
    body
    {
        return new ZipFileGroup(archive, this, filter);
    }

private:
    ZipArchive archive;
    ZipFolder[] members;

    this(ZipArchive archive, ZipFolder root, bool recurse)
    out { assert( valid ); }
    body
    {
        this.archive = archive;
        members = root ~ scan(root, recurse);
    }

    this(ZipArchive archive, ZipFolder[] members)
    out { assert( valid ); }
    body
    {
        this.archive = archive;
        this.members = members;
    }

    final bool valid()
    {
        return (archive !is null) && !archive.closed;
    }

    final ZipFolder[] scan(ZipFolder root, bool recurse)
    in { assert( valid ); }
    body
    {
        auto folders = root.folders(recurse);

        if( recurse )
            foreach( child ; folders )
                folders ~= scan(child, recurse);

        return folders;
    }
}

// ************************************************************************ //
// ************************************************************************ //

class ZipFileGroup : VfsFiles
{
    final override int opApply(int delegate(ref VfsFile) dg)
    in { assert( valid ); }
    body
    {
        int result = 0;
        auto file = new ZipFile;

        foreach( entry ; group )
        {
            file.reset(archive,entry.parent,entry.entry);
            VfsFile x = file;
            if( (result = dg(x)) != 0 )
                break;
        }

        return result;
    }

    final override uint files()
    in { assert( valid ); }
    body
    {
        return group.length;
    }

    final override ulong bytes()
    in { assert( valid ); }
    body
    {
        return stats.bytes;
    }

private:
    ZipArchive archive;
    FileEntry[] group;
    VfsStats stats;

    struct FileEntry
    {
        Entry* parent;
        Entry* entry;
    }

    this(ZipArchive archive, ZipFolderGroup host, VfsFilter filter)
    out { assert( valid ); }
    body
    {
        this.archive = archive;
        foreach( folder ; host.members )
            foreach( file ; folder.files(stats, filter) )
                group ~= FileEntry(folder.entry, file);
    }

    final bool valid()
    {
        return (archive !is null) && !archive.closed;
    }
}

// ************************************************************************ //
// ************************************************************************ //

private:

void error(char[] msg)
{
    throw new Exception(msg);
}

void mutate_error(char[] method)
{
    error(method ~ ": mutating the contents of a ZipArchive "
            "is not supported yet; terribly sorry");
}

bool nz(char[] s)
{
    return s.length > 0;
}

bool zero(char[] s)
{
    return s.length == 0;
}

bool single_path_part(char[] s)
{
    foreach( c ; s )
        if( c == '/' ) return false;
    return true;
}

char[] dir_app(char[] dir, char[] name)
{
    return dir ~ (dir[$-1]!='/' ? "/" : "") ~ name;
}

void headTail(ref FilePath fp, out char[] head, out char[] tail)
{
    return headTail(fp.toString, head, tail);
}

void headTail(char[] path, out char[] head, out char[] tail)
{
    foreach( i,dchar c ; path[1..$] )
        if( c == '/' )
        {
            head = path[0..i+1];
            tail = path[i+2..$];
            return;
        }

    head = path;
    tail = null;
}

unittest
{
    char[] h,t;

    headTail("/a/b/c", h, t);
    assert( h == "/a" );
    assert( t == "b/c" );

    headTail("a/b/c", h, t);
    assert( h == "a" );
    assert( t == "b/c" );

    headTail("a/", h, t);
    assert( h == "a" );
    assert( t == "" );

    headTail("a", h, t);
    assert( h == "a" );
    assert( t == "" );
}

// ************************************************************************** //
// ************************************************************************** //
// ************************************************************************** //

// Dependencies
private:
import tango.io.Conduit : Conduit;

/*******************************************************************************

    copyright:  Copyright © 2007 Daniel Keep.  All rights reserved.

    license:    BSD style: $(LICENSE)

    version:    Prerelease

    author:     Daniel Keep

*******************************************************************************/

//module tangox.io.stream.DummyStream;

//import tango.io.Conduit : Conduit;
//import tango.io.model.IConduit : IConduit, InputStream, OutputStream;

/**
 * The dummy stream classes are used to provide simple, empty stream objects
 * where one is required, but none is available.
 *
 * Note that, currently, these classes return 'null' for the underlying
 * conduit, which will likely break code which expects streams to have an
 * underlying conduit.
 */
class DummyInputStream : InputStream, IConduit.Seek
{
    alias IConduit.Seek.Anchor Anchor;

    ///
    this(){}
    override IConduit conduit() { return null; }
    override void close() {}
    override uint read(void[] dst) { return IConduit.Eof; }
    override InputStream clear() { return this; }
    override long seek(long offset, Anchor anchor = cast(Anchor)0) { return 0; }
}

/// ditto
class DummyOutputStream : OutputStream, IConduit.Seek
{
    alias IConduit.Seek.Anchor Anchor;

    ///
    this(){}
    override IConduit conduit() { return null; }
    override void close() {}
    override uint write(void[] src) { return IConduit.Eof; }
    override OutputStream copy(InputStream src)
    {
        return Conduit.transfer(src, this);
    }
    override OutputStream flush() { return this; }
    override long seek(long offset, Anchor anchor = cast(Anchor)0) { return 0; }
}

/*******************************************************************************

    copyright:  Copyright © 2007 Daniel Keep.  All rights reserved.

    license:    BSD style: $(LICENSE)

    version:    Prerelease

    author:     Daniel Keep

*******************************************************************************/

//module tangox.io.stream.EventStream;

//import tango.io.Conduit : Conduit;
//import tango.io.model.IConduit : IConduit, InputStream, OutputStream;

/**
 * The event stream classes are designed to allow you to receive feedback on
 * how a stream chain is being used.  This is done through the use of
 * delegate callbacks which are invoked just before the associated method is
 * complete.
 */
class EventSeekInputStream : InputStream, IConduit.Seek
{
    ///
    struct Callbacks
    {
        void delegate()                     close; ///
        void delegate()                     clear; ///
        void delegate(uint, void[])         read; ///
        void delegate(long, long, Anchor)   seek; ///
    }

    alias IConduit.Seek.Anchor Anchor;

    ///
    this(InputStream source, Callbacks callbacks)
    in
    {
        assert( source !is null );
        assert( (cast(IConduit.Seek) source) !is null );
    }
    body
    {
        this.source = source;
        this.seeker = cast(IConduit.Seek) source;
        this.callbacks = callbacks;
    }

    override IConduit conduit()
    {
        return source.conduit;
    }

    override void close()
    {
        source.close;
        source = null;
        seeker = null;
        if( callbacks.close ) callbacks.close();
    }

    override uint read(void[] dst)
    {
        auto result = source.read(dst);
        if( callbacks.read ) callbacks.read(result, dst);
        return result;
    }

    override InputStream clear()
    {
        source.clear();
        if( callbacks.clear ) callbacks.clear();
        return this;
    }

    override long seek(long offset, Anchor anchor = cast(Anchor)0)
    {
        auto result = seeker.seek(offset, anchor);
        if( callbacks.seek ) callbacks.seek(result, offset, anchor);
        return result;
    }

private:
    InputStream source;
    IConduit.Seek seeker;
    Callbacks callbacks;

    invariant
    {
        assert( cast(Object) source is cast(Object) seeker );
    }
}

/// ditto
class EventSeekOutputStream : OutputStream, IConduit.Seek
{
    ///
    struct Callbacks
    {
        void delegate()                     close; ///
        void delegate()                     flush; ///
        void delegate(uint, void[])         write; ///
        void delegate(long, long, Anchor)   seek; ///
    }

    alias IConduit.Seek.Anchor Anchor;

    ///
    this(OutputStream source, Callbacks callbacks)
    in
    {
        assert( source !is null );
        assert( (cast(IConduit.Seek) source) !is null );
    }
    body
    {
        this.source = source;
        this.seeker = cast(IConduit.Seek) source;
        this.callbacks = callbacks;
    }

    override IConduit conduit()
    {
        return source.conduit;
    }

    override void close()
    {
        source.close;
        source = null;
        seeker = null;
        if( callbacks.close ) callbacks.close();
    }

    override uint write(void[] dst)
    {
        auto result = source.write(dst);
        if( callbacks.write ) callbacks.write(result, dst);
        return result;
    }

    override OutputStream flush()
    {
        source.flush();
        if( callbacks.flush ) callbacks.flush();
        return this;
    }

    override long seek(long offset, Anchor anchor = cast(Anchor)0)
    {
        auto result = seeker.seek(offset, anchor);
        if( callbacks.seek ) callbacks.seek(result, offset, anchor);
        return result;
    }

    override OutputStream copy(InputStream src)
    {
        return Conduit.transfer(src, this);
    }

private:
    OutputStream source;
    IConduit.Seek seeker;
    Callbacks callbacks;

    invariant
    {
        assert( cast(Object) source is cast(Object) seeker );
    }
}

/*******************************************************************************

    copyright:  Copyright © 2007 Daniel Keep.  All rights reserved.

    license:    BSD style: $(LICENSE)

    version:    Prerelease

    author:     Daniel Keep

*******************************************************************************/

//module tangox.io.stream.WrapStream;

//import tango.io.Conduit : Conduit;
//import tango.io.model.IConduit : IConduit, InputStream, OutputStream;

/**
 * This stream can be used to provide access to another stream.
 * Its distinguishing feature is that users cannot close the underlying
 * stream.
 *
 * This stream fully supports seeking, and as such requires that the
 * underlying stream also support seeking.
 */
class WrapSeekInputStream : InputStream, IConduit.Seek
{
    alias IConduit.Seek.Anchor Anchor;

    /**
     * Create a new wrap stream from the given source.
     */
    this(InputStream source)
    in
    {
        assert( source !is null );
        assert( (cast(IConduit.Seek) source) !is null );
    }
    body
    {
        this.source = source;
        this.seeker = cast(IConduit.Seek) source;
        this._position = seeker.seek(0, Anchor.Current);
    }

    /// ditto
    this(InputStream source, long position)
    in
    {
        assert( position >= 0 );
    }
    body
    {
        this(source);
        this._position = position;
    }

    override IConduit conduit()
    {
        return source.conduit;
    }

    override void close()
    {
        source = null;
        seeker = null;
    }

    override uint read(void[] dst)
    {
        if( seeker.seek(0, Anchor.Current) != _position )
            seeker.seek(_position, Anchor.Begin);

        auto read = source.read(dst);
        if( read != IConduit.Eof )
            _position += read;

        return read;
    }

    override InputStream clear()
    {
        source.clear();
        return this;
    }

    override long seek(long offset, Anchor anchor = cast(Anchor)0)
    {
        seeker.seek(_position, Anchor.Begin);
        return (_position = seeker.seek(offset, anchor));
    }

private:
    InputStream source;
    IConduit.Seek seeker;
    long _position;

    invariant
    {
        assert( cast(Object) source is cast(Object) seeker );
        assert( _position >= 0 );
    }
}

/**
 * This stream can be used to provide access to another stream.
 * Its distinguishing feature is that the users cannot close the underlying
 * stream.
 *
 * This stream fully supports seeking, and as such requires that the
 * underlying stream also support seeking.
 */
class WrapSeekOutputStream : OutputStream, IConduit.Seek
{
    alias IConduit.Seek.Anchor Anchor;

    /**
     * Create a new wrap stream from the given source.
     */
    this(OutputStream source)
    in
    {
        assert( (cast(IConduit.Seek) source) !is null );
    }
    body
    {
        this.source = source;
        this.seeker = cast(IConduit.Seek) source;
        this._position = seeker.seek(0, Anchor.Current);
    }

    /// ditto
    this(OutputStream source, long position)
    in
    {
        assert( position >= 0 );
    }
    body
    {
        this(source);
        this._position = position;
    }

    override IConduit conduit()
    {
        return source.conduit;
    }

    override void close()
    {
        source = null;
        seeker = null;
    }

    uint write(void[] src)
    {
        if( seeker.seek(0, Anchor.Current) != _position )
            seeker.seek(_position, Anchor.Begin);

        auto wrote = source.write(src);
        if( wrote != IConduit.Eof )
            _position += wrote;
        return wrote;
    }

    override OutputStream copy(InputStream src)
    {
        return Conduit.transfer(src, this);
    }

    override OutputStream flush()
    {
        source.flush();
        return this;
    }

    override long seek(long offset, Anchor anchor = cast(Anchor)0)
    {
        seeker.seek(_position, Anchor.Begin);
        return (_position = seeker.seek(offset, anchor));
    }

private:
    OutputStream source;
    IConduit.Seek seeker;
    long _position;

    invariant
    {
        assert( cast(Object) source is cast(Object) seeker );
        assert( _position >= 0 );
    }
}

