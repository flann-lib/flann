/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: January 2006
        
        author:         Kris

*******************************************************************************/

module tango.net.http.HttpPost;

public import   tango.net.Uri;

private import  tango.io.GrowBuffer;

private import  tango.net.http.HttpClient,
                tango.net.http.HttpHeaders;

/*******************************************************************************

        Supports the basic needs of a client sending POST requests to a
        HTTP server. The following is a usage example:

        ---
        // open a web-page for posting (see HttpGet for simple reading)
        auto post = new HttpPost ("http://yourhost/yourpath");

        // send, retrieve and display response
        Cout (cast(char[]) post.write("posted data", "text/plain"));
        ---

*******************************************************************************/

class HttpPost : HttpClient
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
                super (HttpClient.Post, uri);
                buffer = new GrowBuffer (pageChunk, pageChunk);
        }

        /***********************************************************************
        
                Send query params only

        ***********************************************************************/

        void[] write ()
        {
                return write (null);
        }

        /***********************************************************************
        
                Send content and no query params. The contentLength header
                will be set to match the provided content, and contentType
                set to the given type.

        ***********************************************************************/

        void[] write (void[] content, char[] type)
        {
                auto headers = getRequestHeaders();

                headers.add    (HttpHeader.ContentType, type);
                headers.addInt (HttpHeader.ContentLength, content.length);
                
                return write (delegate void (IBuffer b){b.append(content);});
        }

        /***********************************************************************
        
                Send raw data via the provided pump, and no query 
                params. You have full control over headers and so 
                on via this method.

        ***********************************************************************/

        void[] write (Pump pump)
        {
                try {
                    buffer.clear;
                    open (pump, buffer);

                    // check return status for validity
                    auto status = getStatus();
                    if (status is HttpResponseCode.OK || 
                        status is HttpResponseCode.Created || 
                        status is HttpResponseCode.Accepted)
                        buffer.fill (getResponseHeaders.getInt (HttpHeader.ContentLength, uint.max));
                    } finally {close;}

                return buffer.slice;
        }
}

