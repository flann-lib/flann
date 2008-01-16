/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Nov 2007

        author:         Kris

*******************************************************************************/

module tango.io.stream.TextFileStream;

public  import tango.io.FileConduit;

private import tango.io.stream.FileStream,
               tango.io.stream.LineStream,
               tango.io.stream.FormatStream;

/*******************************************************************************

        Composes a file with line-oriented input

*******************************************************************************/

class TextFileInput : LineInput
{
        /***********************************************************************

                compose a FileStream              

        ***********************************************************************/

        this (char[] path, FileConduit.Style style = FileConduit.ReadExisting)
        {
                super (new FileInput (path, style));
        }
}


/*******************************************************************************
       
        Composes a file with formatted text output

*******************************************************************************/

class TextFileOutput : FormatOutput
{
        /***********************************************************************

                compose a FileStream              

        ***********************************************************************/

        this (char[] path, FileConduit.Style style = FileConduit.WriteCreate)
        {
                super (new FileOutput (path, style));
        }
 }


/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{
}
