/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2007

        author:         Kris

*******************************************************************************/

module tango.io.stream.FileStream;

public import tango.io.FileConduit;

/*******************************************************************************

        Trivial wrapper around a FileConduit

*******************************************************************************/

class FileInput : FileConduit
{
        /***********************************************************************

                Open a file for reading. Don't forget to use close()

        ***********************************************************************/

        this (char[] path, FileConduit.Style style = FileConduit.ReadExisting)
        {
                super (path, style);
        }
}


/*******************************************************************************

        Trivial wrapper around a FileConduit

*******************************************************************************/

class FileOutput : FileConduit
{
        /***********************************************************************

                Open a file for writing. Don't forget to use close()

        ***********************************************************************/

        this (char[] path, FileConduit.Style style = FileConduit.WriteCreate)
        {
                super (path, style);
        }
}

