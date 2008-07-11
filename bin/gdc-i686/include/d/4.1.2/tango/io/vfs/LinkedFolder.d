/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Oct 2007: Initial version

        author:         Kris

*******************************************************************************/

module tango.io.vfs.LinkedFolder;

private import tango.io.vfs.model.Vfs;

private import tango.core.Exception;

private import tango.io.vfs.VirtualFolder;

/*******************************************************************************
        
        LinkedFolder is derived from VirtualFolder, and behaves exactly the 
        same in all but one aspect: it treats mounted folders as an ordered 
        list of alternatives to look for a file. This supports the notion of 
        file 'overrides', whereby "customized" files can be inserted into a 
        chain of alternatives.

        (overridden folders are not currently supported)

*******************************************************************************/


class LinkedFolder : VirtualFolder
{
        private Link* head;

        /***********************************************************************

                Linked-list of folders

        ***********************************************************************/

        private struct Link
        {
                Link*     next;
                VfsFolder folder;

                static Link* opCall(VfsFolder folder)
                {
                        auto p = new Link;
                        p.folder = folder;
                        return p;
                }
        }

        /***********************************************************************

                All folder must have a name. No '.' or '/' chars are 
                permitted

        ***********************************************************************/

        this (char[] name)
        {
                super (name);
        }

        /***********************************************************************

                Add a child folder. The child cannot 'overlap' with others
                in the tree of the same type. Circular references across a
                tree of virtual folders are detected and trapped.

                We add the new child at the end of an ordered list, which
                we subsequently traverse when looking up a file

                The second argument represents an optional name that the
                mount should be known as, instead of the name exposed by 
                the provided folder (it is not an alias).

        ***********************************************************************/

        final VfsHost mount (VfsFolder folder, char[] name=null)
        {
                // traverse to the end of the list
                auto link = &head;
                while (*link)
                        link = &(*link).next;

                // hook up the new folder
                *link = Link (folder);

                // and let superclass deal with it 
                return super.mount (folder, name);
        }

        /***********************************************************************

                TODO: unhook a child folder.

        ***********************************************************************/

        final VfsHost dismount (VfsFolder folder)
        {
                assert (0, "LinkedFolder.dismount not implemented");
        }

        /***********************************************************************

                Return a file representation of the given path. If the
                path-head does not refer to an immediate child folder, 
                and does not match a symbolic link, it is considered to
                be unknown.

                We scan the set of mounted folders, in the order mounted,
                looking for a match. Where one is found, we test to see
                that it really exists before returning the reference

        ***********************************************************************/

        final override VfsFile file (char[] path)
        {
                auto link = head;
                while (link)
                      {
                      //Stdout.formatln ("looking in {}", link.folder.toString);
                      try {
                          auto file = link.folder.file (path);
                          if (file.exists)
                              return file;
                          } catch (VfsException x) {}
                      link = link.next;
                      }
                super.error ("file '"~path~"' not found");
                return null;
        }
}


debug (LinkedFolder)
{
/*******************************************************************************

*******************************************************************************/

import tango.io.Stdout;
import tango.io.Buffer;
import tango.io.vfs.FileFolder;

void main()
{
        auto root = new LinkedFolder ("root");
        auto sub  = new VirtualFolder ("sub");
        sub.mount (new FileFolder (r"d:/d/import/temp"));
        sub.map (sub.file(r"temp/subtree/test.txt"), "wumpus");
        
        root.mount (new FileFolder (r"d:/d/import/tango"))
            .mount (new FileFolder (r"c:/"), "windows");
        root.mount (sub);

        auto file = root.file (r"wumpus");
        Stdout.formatln ("file = {}", file);
}
}
