/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Nov 2007

        author:         Kris

*******************************************************************************/

module tango.io.stream.TextFileStream;

public  import tango.io.FileConduit;

private import tango.io.Buffer;

private import tango.io.stream.FileStream,
               tango.io.stream.LineStream,
               tango.io.stream.FormatStream;

/*******************************************************************************

        Composes a file with line-oriented input. The input is buffered

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
       
        Composes a file with formatted text output. The output is buffered

*******************************************************************************/

class TextFileOutput : FormatOutput
{
        /***********************************************************************

                compose a FileStream              

        ***********************************************************************/

        this (char[] path, FileConduit.Style style = FileConduit.WriteCreate)
        {
                super (new Buffer (new FileOutput (path, style)));
        }
 }


/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{
}
