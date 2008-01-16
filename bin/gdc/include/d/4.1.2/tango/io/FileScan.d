/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Jun 2004: Initial release
        version:        Dec 2006: Pacific release

        author:         Kris

*******************************************************************************/

module tango.io.FileScan;

public  import tango.io.FilePath;

private import tango.core.Exception;

/*******************************************************************************

        Recursively scan files and directories, adding filtered files to
        an output structure as we go. This can be used to produce a list
        of subdirectories and the files contained therein. The following
        example lists all files with suffix ".d" located via the current
        directory, along with the folders containing them:
        ---
        auto scan = new FileScan;

        scan (".", ".d");

        Stdout.formatln ("{} Folders", scan.folders.length);
        foreach (folder; scan.folders)
                 Stdout.formatln ("{}", folder);

        Stdout.formatln ("\n{} Files", scan.files.length);
        foreach (file; scan.files)
                 Stdout.formatln ("{}", file);
        ---

        This is unlikely the most efficient method to scan a vast number of
        files, but operates in a convenient manner
        
*******************************************************************************/

class FileScan
{       
        alias sweep     opCall;

        FilePath[]      fileSet;
        char[][]        errorSet;
        FilePath[]      folderSet;
        
        /***********************************************************************

            Alias for Filter delegate. Accepts a FilePath & a bool as 
            arguments and returns a bool.

            The FilePath argument represents a file found by the scan, 
            and the bool whether the FilePath represents a folder.

            The filter should return true, if matched by the filter. Note
            that returning false where the path is a folder will result 
            in all files contained being ignored. To always recurse folders, 
            do something like this:
            ---
            return (isDir || match (fp.name));
            ---

        ***********************************************************************/

        alias FilePath.Filter Filter;

       /***********************************************************************

                Return all the errors found in the last scan

        ***********************************************************************/

        public char[][] errors ()
        {
                return errorSet;
        }

        /***********************************************************************

                Return all the files found in the last scan

        ***********************************************************************/

        public FilePath[] files ()
        {
                return fileSet;
        }

        /***********************************************************************
        
                Return all directories found in the last scan

        ***********************************************************************/

        public FilePath[] folders ()
        {
                return folderSet;
        }

        /***********************************************************************

                Sweep a set of files and directories from the given parent
                path, with no filtering applied
        
        ***********************************************************************/
        
        FileScan sweep (char[] path, bool recurse=true)
        {
                return sweep (path, cast(Filter) null, recurse);
        }

        /***********************************************************************

                Sweep a set of files and directories from the given parent
                path, where the files are filtered by the given suffix
        
        ***********************************************************************/
        
        FileScan sweep (char[] path, char[] match, bool recurse=true)
        {
                return sweep (path, (FilePath fp, bool isDir)
                             {return isDir || fp.suffix == match;}, recurse);
        }

        /***********************************************************************

                Sweep a set of files and directories from the given parent
                path, where the files are filtered by the provided delegate

        ***********************************************************************/
        
        FileScan sweep (char[] path, Filter filter, bool recurse=true)
        {
                errorSet = null, fileSet = folderSet = null;
                return scan (new FilePath(path), filter, recurse);
        }

        /***********************************************************************

                Internal routine to locate files and sub-directories. We
                skip entries with names composed only of '.' characters. 

        ***********************************************************************/

        private FileScan scan (FilePath folder, Filter filter, bool recurse) 
        {
                try {
                    auto paths = folder.toList (filter);
                
                    auto count = fileSet.length;
                    foreach (path; paths)
                             if (! path.isFolder)
                                   fileSet ~= path;
                             else
                                if (recurse)
                                    scan (path, filter, recurse);
                
                    // add packages only if there's something in them
                    if (fileSet.length > count)
                        folderSet ~= folder;

                    } catch (IOException e)
                             errorSet ~= e.toString;
                return this;
        }
}


/*******************************************************************************

*******************************************************************************/

debug (FileScan)
{
        import tango.io.Stdout;

        void main()
        {
                auto scan = new FileScan;

                scan (".");

                Stdout.formatln ("{} Folders", scan.folders.length);
                foreach (folder; scan.folders)
                         Stdout (folder).newline;

                Stdout.formatln ("\n{} Files", scan.files.length);
                foreach (file; scan.files)
                         Stdout (file).newline;

                Stdout.formatln ("\n{} Errors", scan.errors.length);
                foreach (error; scan.errors)
                         Stdout (error).newline;
        }
}
