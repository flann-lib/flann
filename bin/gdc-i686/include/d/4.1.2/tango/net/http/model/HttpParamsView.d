/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module tango.net.http.model.HttpParamsView;

private import  tango.time.Time;

private import  tango.io.model.IBuffer;

private import  tango.io.protocol.model.IWriter;

/******************************************************************************

        Maintains a set of query parameters, parsed from an HTTP request.
        Use HttpParams instead for output parameters.

        Note that these input params may have been encoded by the user-
        agent. Unfortunately there has been little consensus on what that
        encoding should be (especially regarding GET query-params). With
        luck, that will change to a consistent usage of UTF-8 within the 
        near future.

******************************************************************************/

interface HttpParamsView : IWritable
{
        /**********************************************************************
                
                Return the value of the provided header, or null if the
                header does not exist

        **********************************************************************/

        char[] get (char[] name, char[] ret = null);

        /**********************************************************************
                
                Return the integer value of the provided header, or the 
                provided default-value if the header does not exist

        **********************************************************************/

        int getInt (char[] name, int ret = -1);

        /**********************************************************************
                
                Return the date value of the provided header, or the 
                provided default-value if the header does not exist

        **********************************************************************/

        Time getDate (char[] name, Time ret = Time.epoch);

        /**********************************************************************

                Output the param list to the provided consumer

        **********************************************************************/

        void produce (void delegate (void[]) consume, char[] eol);
}
