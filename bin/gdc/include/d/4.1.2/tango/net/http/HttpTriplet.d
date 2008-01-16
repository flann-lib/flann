/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: December 2005      
        
        author:         Kris

*******************************************************************************/

module tango.net.http.HttpTriplet;

private import  tango.core.Exception;

private import  tango.io.protocol.model.IWriter;

/******************************************************************************

        Class to represent an HTTP response- or request-line 

******************************************************************************/

class HttpTriplet : IWritable
{
        protected char[]        line;
        protected char[][3]     tokens;

        /**********************************************************************

                test the validity of these tokens

        **********************************************************************/

        abstract void test ();

        /**********************************************************************

                Parse the the given line into its constituent components.

        **********************************************************************/

        void parse (char[] line)
        {
                int i;
                int mark;

                this.line = line;
                foreach (int index, char c; line)
                         if (c is ' ')
                             if (i < 2)
                                {
                                tokens[i] = line[mark .. index];
                                mark = index+1;
                                ++i;
                                }
                             else
                                break;

                tokens[2] = line [mark .. line.length];

                test ();
        }

        /**********************************************************************

                return a reference to the original string

        **********************************************************************/

        override char[] toString ()
        {
                return line;
        }

        /**********************************************************************

                Output the string via the given writer

        **********************************************************************/

        void write (IWriter writer)
        {
               writer(toString).newline();
        }

        /**********************************************************************

                throw an exception

        **********************************************************************/

        final void error (char[] msg)
        {
                throw new IOException (msg);
        }
}


