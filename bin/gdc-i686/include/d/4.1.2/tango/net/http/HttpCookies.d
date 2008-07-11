/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module tango.net.http.HttpCookies;

private import  tango.io.Buffer;

private import  tango.stdc.ctype;

private import  tango.net.http.HttpHeaders;

private import  tango.io.protocol.model.IWriter;

private import  tango.text.stream.StreamIterator;

private import  Integer = tango.text.convert.Integer;

/*******************************************************************************

        Defines the Cookie class, and the means for reading & writing them.
        Cookie implementation conforms with RFC 2109, but supports parsing 
        of server-side cookies only. Client-side cookies are supported in
        terms of output, but response parsing is not yet implemented ...

        See over <A HREF="http://www.faqs.org/rfcs/rfc2109.html">here</A>
        for the RFC document.        

*******************************************************************************/

class Cookie : IWritable
{
        private char[]  name,
                        path,
                        value,
                        domain,
                        comment;
        private uint    vrsn=1;              // 'version' is a reserved word
        private long    maxAge;
        private bool    secure;

        /***********************************************************************
                
                Construct an empty client-side cookie. You add these
                to an output request using HttpClient.addCookie(), or
                the equivalent.

        ***********************************************************************/

        this () {}

        /***********************************************************************
        
                Construct a cookie with the provided attributes. You add 
                these to an output request using HttpClient.addCookie(), 
                or the equivalent.

        ***********************************************************************/

        this (char[] name, char[] value)
        {
                setName (name);
                setValue (value);
        }

        /***********************************************************************
        
                Set the name of this cookie

        ***********************************************************************/

        void setName (char[] name)
        {
                this.name = name;
        }

        /***********************************************************************
        
                Set the value of this cookie

        ***********************************************************************/

        void setValue (char[] value)
        {
                this.value = value;
        }

        /***********************************************************************
                
                Set the version of this cookie

        ***********************************************************************/

        void setVersion (uint vrsn)
        {
                this.vrsn = vrsn;
        }

        /***********************************************************************
        
                Set the path of this cookie

        ***********************************************************************/

        void setPath (char[] path)
        {
                this.path = path;
        }

        /***********************************************************************
        
                Set the domain of this cookie

        ***********************************************************************/

        void setDomain (char[] domain)
        {
                this.domain = domain;
        }

        /***********************************************************************
        
                Set the comment associated with this cookie

        ***********************************************************************/

        void setComment (char[] comment)
        {
                this.comment = comment;
        }

        /***********************************************************************
        
                Set the maximum duration of this cookie

        ***********************************************************************/

        void setMaxAge (long maxAge)
        {
                this.maxAge = maxAge;
        }

        /***********************************************************************
        
                Indicate wether this cookie should be considered secure or not

        ***********************************************************************/

        void setSecure (bool secure)
        {
                this.secure = secure;
        }

        /***********************************************************************
        
                Output the cookie as a text stream, via the provided IWriter

        ***********************************************************************/

        void write (IWriter writer)
        {
                produce (&writer.buffer.consume);
        }

        /***********************************************************************
        
                Output the cookie as a text stream, via the provided consumer

        ***********************************************************************/

        void produce (void delegate(void[]) consume)
        {
                consume (name);

                if (value.length)
                    consume ("="), consume (value);

                if (path.length)
                    consume (";Path="), consume (path);

                if (domain.length)
                    consume (";Domain="), consume (domain);

                if (vrsn)
                   {
                   char[16] tmp = void;

                   consume (";Version=");
                   consume (Integer.format (tmp, vrsn));

                   if (comment.length)
                       consume (";Comment=\""), consume(comment), consume("\"");

                   if (secure)
                       consume (";Secure");

                   if (maxAge >= 0)
                       consume (";Max-Age="c), consume (Integer.format (tmp, maxAge));
                   }
        }

        /***********************************************************************
        
                Reset this cookie

        ***********************************************************************/

        void clear ()
        {
                vrsn = 1;
                maxAge = 0;
                secure = false;
                name = path = domain = comment = null;
        }
}



/*******************************************************************************

        Implements a stack of cookies. Each cookie is pushed onto the
        stack by a parser, which takes its input from HttpHeaders. The
        stack can be populated for both client and server side cookies.

*******************************************************************************/

class CookieStack
{
        private int             depth;
        private Cookie[]        cookies;

        /**********************************************************************

                Construct a cookie stack with the specified initial extent.
                The stack will grow as necessary over time.

        **********************************************************************/

        this (int size)
        {
                cookies = new Cookie[0];
                resize (cookies, size);
        }

        /**********************************************************************

                Pop the stack all the way to zero

        **********************************************************************/

        final void reset ()
        {
                depth = 0;
        }

        /**********************************************************************

                Return a fresh cookie from the stack

        **********************************************************************/

        final Cookie push ()
        {
                if (depth == cookies.length)
                    resize (cookies, depth * 2);
                return cookies [depth++];
        }
        
        /**********************************************************************

                Resize the stack such that it has more room.

        **********************************************************************/

        private final static void resize (inout Cookie[] cookies, int size)
        {
                int i = cookies.length;
                
                for (cookies.length=size; i < cookies.length; ++i)
                     cookies[i] = new Cookie();
        }

        /**********************************************************************

                Iterate over all cookies in stack

        **********************************************************************/

        int opApply (int delegate(inout Cookie) dg)
        {
                int result = 0;

                for (int i=0; i < depth; ++i)
                     if ((result = dg (cookies[i])) != 0)
                          break;
                return result;
        }
}



/*******************************************************************************

        This is the support point for server-side cookies. It wraps a
        CookieStack together with a set of HttpHeaders, along with the
        appropriate cookie parser. One would do something very similar
        for client side cookie parsing also.

*******************************************************************************/

class HttpCookiesView : IWritable
{
        private bool                    parsed;
        private CookieStack             stack;
        private CookieParser            parser;
        private HttpHeadersView         headers;

        /**********************************************************************

                Construct cookie wrapper with the provided headers.

        **********************************************************************/

        this (HttpHeadersView headers)
        {
                this.headers = headers;

                // create a stack for parsed cookies
                stack = new CookieStack (10);

                // create a parser
                parser = new CookieParser (stack);
        }

        /**********************************************************************

                Output each of the cookies parsed to the provided IWriter.

        **********************************************************************/

        void write (IWriter writer)
        {
                produce (&writer.buffer.consume, HttpConst.Eol);
        }

        /**********************************************************************

                Output the token list to the provided consumer

        **********************************************************************/

        void produce (void delegate (void[]) consume, char[] eol = HttpConst.Eol)
        {
                foreach (cookie; parse)
                         cookie.produce (consume), consume (eol);
        }

        /**********************************************************************

                Reset these cookies for another parse

        **********************************************************************/

        void reset ()
        {
                stack.reset;
                parsed = false;
        }

        /**********************************************************************

                Parse all cookies from our HttpHeaders, pushing each onto
                the CookieStack as we go.

        **********************************************************************/

        CookieStack parse ()
        {
                if (! parsed)
                   {
                   parsed = true;

                   foreach (HeaderElement header; headers)
                            if (header.name.value == HttpHeader.Cookie.value)
                                parser.parse (header.value);
                   }
                return stack;
        }
}



/*******************************************************************************

        Handles a set of output cookies by writing them into the list of
        output headers.

*******************************************************************************/

class HttpCookies
{
        private HttpHeaders headers;

        /**********************************************************************

                Construct an output cookie wrapper upon the provided 
                output headers. Each cookie added is converted to an
                addition to those headers.

        **********************************************************************/

        this (HttpHeaders headers)
        {
                this.headers = headers;
        }

        /**********************************************************************

                Add a cookie to our output headers.

        **********************************************************************/

        void add (Cookie cookie)
        {
                // add the cookie header via our callback
                headers.add (HttpHeader.SetCookie, (IBuffer buf){cookie.produce (&buf.consume);});        
        }
}



/*******************************************************************************

        Server-side cookie parser. See RFC 2109 for details.

*******************************************************************************/

class CookieParser : StreamIterator!(char)
{
        private enum State {Begin, LValue, Equals, RValue, Token, SQuote, DQuote};

        private CookieStack stack;
        private Buffer      buffer;
        
        /***********************************************************************

        ***********************************************************************/

        this (CookieStack stack)
        {
                super();
                this.stack = stack;
                buffer = new Buffer;
        }

        /***********************************************************************

                Callback for iterator.next(). We scan for name-value
                pairs, populating Cookie instances along the way.

        ***********************************************************************/

        protected uint scan (void[] data)
        {      
                char    c;
                int     mark,
                        vrsn;
                char[]  name,
                        token;
                Cookie  cookie;

                State   state = State.Begin;
                char[]  content = cast(char[]) data;

                /***************************************************************

                        Found a value; set that also

                ***************************************************************/

                void setValue (int i)
                {   
                        token = content [mark..i];
                        //Print ("::name '%.*s'\n", name);
                        //Print ("::value '%.*s'\n", token);

                        if (name[0] != '$')
                           {
                           cookie = stack.push();
                           cookie.setName (name);
                           cookie.setValue (token);
                           cookie.setVersion (vrsn);
                           }
                        else
                           switch (toLower (name))
                                  {
                                  case "$path":
                                        if (cookie)
                                            cookie.setPath (token); 
                                        break;

                                  case "$domain":
                                        if (cookie)
                                            cookie.setDomain (token); 
                                        break;

                                  case "$version":
                                        vrsn = cast(int) Integer.parse (token); 
                                        break;

                                  default:
                                       break;
                                  }
                        state = State.Begin;
                }

                /***************************************************************

                        Scan content looking for cookie fields

                ***************************************************************/

                for (int i; i < content.length; ++i)
                    {
                    c = content [i];
                    switch (state)
                           {
                           // look for an lValue
                           case State.Begin:
                                mark = i;
                                if (isalpha (c) || c is '$')
                                    state = State.LValue;
                                continue;

                           // scan until we have all lValue chars
                           case State.LValue:
                                if (! isalnum (c))
                                   {
                                   state = State.Equals;
                                   name = content [mark..i];
                                   --i;
                                   }
                                continue;

                           // should now have either a '=', ';', or ','
                           case State.Equals:
                                if (c is '=')
                                    state = State.RValue;
                                else
                                   if (c is ',' || c is ';')
                                       // get next NVPair
                                       state = State.Begin;
                                continue;

                           // look for a quoted token, or a plain one
                           case State.RValue:
                                mark = i;
                                if (c is '\'')
                                    state = State.SQuote;
                                else
                                   if (c is '"')
                                       state = State.DQuote;
                                   else
                                      if (isalpha (c))
                                          state = State.Token;
                                continue;

                           // scan for all plain token chars
                           case State.Token:
                                if (! isalnum (c))
                                   {
                                   setValue (i);
                                   --i;
                                   }
                                continue;

                           // scan until the next '
                           case State.SQuote:
                                if (c is '\'')
                                    ++mark, setValue (i);
                                continue;

                           // scan until the next "
                           case State.DQuote:
                                if (c is '"')
                                    ++mark, setValue (i);
                                continue;

                           default:
                                continue;
                           }
                    }

                // we ran out of content; patch partial cookie values 
                if (state is State.Token)
                    setValue (content.length);

                // go home
                return IConduit.Eof;
        }
                                
        /***********************************************************************
        
                Locate the next token from the provided buffer, and map a
                buffer reference into token. Returns true if a token was 
                located, false otherwise. 

                Note that the buffer content is not duplicated. Instead, a
                slice of the buffer is referenced by the token. You can use
                Token.clone() or Token.toString().dup() to copy content per
                your application needs.

                Note also that there may still be one token left in a buffer 
                that was not terminated correctly (as in eof conditions). In 
                such cases, tokens are mapped onto remaining content and the 
                buffer will have no more readable content.

        ***********************************************************************/

        bool parse (char[] header)
        {
                super.set (buffer.setContent (header));
                return next.ptr > null;
        }

        /**********************************************************************

                in-place conversion to lowercase 

        **********************************************************************/

        final static char[] toLower (inout char[] src)
        {
                foreach (int i, char c; src)
                         if (c >= 'A' && c <= 'Z')
                             src[i] = c + ('a' - 'A');
                return src;
        }
}
   
     
