/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: January 2006
        
        author:         Kris

*******************************************************************************/

module tango.net.http.HttpGet;

public  import  tango.net.Uri;

private import  tango.io.GrowBuffer;

private import  tango.net.http.HttpClient,
                tango.net.http.HttpHeaders;

/*******************************************************************************

        Supports the basic needs of a client making requests of an HTTP
        server. The following is a usage example:
        ---
        // open a web-page for reading (see HttpPost for writing)
        auto page = new HttpGet ("http://www.digitalmars.com/d/intro.html");

        // retrieve and flush display content
        Cout (cast(char[]) page.read) ();
        ---

*******************************************************************************/

class HttpGet : HttpClient
{      
        private GrowBuffer buffer;

        /***********************************************************************
        
                Create a client for the given URL. The argument should be
                fully qualified with an "http:" or "https:" scheme, or an
                explicit port should be provided.

        ***********************************************************************/

        this (char[] url, uint pageChunk = 16 * 1024)
        {
                this (new Uri(url), pageChunk);
        }

        /***********************************************************************
        
                Create a client with the provided Uri instance. The Uri should 
                be fully qualified with an "http:" or "https:" scheme, or an
                explicit port should be provided. 

        ***********************************************************************/

        this (Uri uri, uint pageChunk = 16 * 1024)
        {
                super (HttpClient.Get, uri);
                buffer = new GrowBuffer (pageChunk, pageChunk);
        }

        /***********************************************************************
        
        ***********************************************************************/

        void[] read ()
        {
                try {
                    buffer.clear;
                    open (buffer);
                    if (isResponseOK)
                        buffer.fill (getResponseHeaders.getInt(HttpHeader.ContentLength, uint.max));
                    } finally {close;}
                return buffer.slice;
        }
}

