/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module tango.net.Uri;

public  import  tango.net.model.UriView;

private import  tango.core.Exception;

private import  Integer = tango.text.convert.Integer;

/*******************************************************************************

        external links
        
*******************************************************************************/

extern (C) char* memchr (char *, char, uint);


/*******************************************************************************

        Implements an RFC 2396 compliant URI specification. See 
        <A HREF="http://ftp.ics.uci.edu/pub/ietf/uri/rfc2396.txt">this page</A>
        for more information. 

        The implementation fails the spec on two counts: it doesn't insist
        on a scheme being present in the Uri, and it doesn't implement the
        "Relative References" support noted in section 5.2. The latter can
        be found in tango.util.PathUtil instead.
        
        Note that IRI support can be implied by assuming each of userinfo,
        path, query, and fragment are UTF-8 encoded 
        (see <A HREF="http://www.w3.org/2001/Talks/0912-IUC-IRI/paper.html">
        this page</A> for further details).

        Use the UriView subset where you need a readonly perspective. 

*******************************************************************************/

class Uri : UriView
{
        // simplistic string appender
        private alias void delegate (void[]) Consumer;  

        private int             port;
        private char[]          host,
                                path,
                                query,
                                scheme,
                                userinfo,
                                fragment;
        private HeapSlice       decoded;

        private static ubyte    map[256];

        private static short[char[]] genericSchemes;

        private static const char[] hexDigits = "0123456789abcdef";

        private static const SchemePort[] schemePorts =
                [
                {"coffee",      80},
                {"file",        InvalidPort},
                {"ftp",         21},
                {"gopher",      70},
                {"hnews",       80},
                {"http",        80},
                {"http-ng",     80},
                {"https",       443},
                {"imap",        143},
                {"irc",         194}, 
                {"ldap",        389},
                {"news",        119},
                {"nfs",         2049}, 
                {"nntp",        119},
                {"pop",         110}, 
                {"prospero",    1525},
                {"rwhois",      4321},
                {"sip",         InvalidPort},
                {"sips",        InvalidPort},
                {"sipt",        InvalidPort},
                {"sipu",        InvalidPort},
                {"shttp",       80},
                {"smtp",        25},
                {"snews",       563},
                {"telnet",      23},
                {"vemmi",       575},
                {"videotex",    516},
                {"wais",        210},
                {"whois",       43},
                {"whois++",     43},
                ];

        public enum    
        {       
                ExcScheme       = 0x01,         
                ExcAuthority    = 0x02, 
                ExcPath         = 0x04, 
                IncUser         = 0x80,         // encode spec for User
                IncPath         = 0x10,         // encode spec for Path
                IncQuery        = 0x20,         // encode spec for Query
                IncQueryAll     = 0x40,
                IncScheme       = 0x80,         // encode spec for Scheme
                IncGeneric      = IncScheme | 
                                  IncUser   | 
                                  IncPath   | 
                                  IncQuery  | 
                                  IncQueryAll
        }

        // scheme and port pairs
        private struct SchemePort
        {
                char[]  name;
                short   port;
        }

        /***********************************************************************
        
                Initialize the Uri character maps and so on

        ***********************************************************************/

        static this ()
        {
                // Map known generic schemes to their default port. Specify
                // InvalidPort for those schemes that don't use ports. Note
                // that a port value of zero is not supported ...
                foreach (SchemePort sp; schemePorts)
                         genericSchemes[sp.name] = sp.port;
                genericSchemes.rehash;

                // load the character map with valid symbols
                for (int i='a'; i <= 'z'; ++i)  
                     map[i] = IncGeneric;

                for (int i='A'; i <= 'Z'; ++i)  
                     map[i] = IncGeneric;

                for (int i='0'; i<='9'; ++i)  
                     map[i] = IncGeneric;

                // exclude these from parsing elements
                map[':'] |= ExcScheme;
                map['/'] |= ExcScheme | ExcAuthority;
                map['?'] |= ExcScheme | ExcAuthority | ExcPath;
                map['#'] |= ExcScheme | ExcAuthority | ExcPath;

                // include these as common symbols
                map['-'] |= IncUser | IncQuery | IncQueryAll;
                map['_'] |= IncUser | IncQuery | IncQueryAll;
                map['.'] |= IncUser | IncQuery | IncQueryAll;
                map['!'] |= IncUser | IncQuery | IncQueryAll;
                map['~'] |= IncUser | IncQuery | IncQueryAll;
                map['*'] |= IncUser | IncQuery | IncQueryAll;
                map['\''] |= IncUser | IncQuery | IncQueryAll;
                map['('] |= IncUser | IncQuery | IncQueryAll;
                map[')'] |= IncUser | IncQuery | IncQueryAll;

                // include these as scheme symbols
                map['+'] |= IncScheme;
                map['-'] |= IncScheme;
                map['.'] |= IncScheme;

                // include these as userinfo symbols
                map[';'] |= IncUser;
                map[':'] |= IncUser;
                map['&'] |= IncUser;
                map['='] |= IncUser;
                map['+'] |= IncUser;
                map['$'] |= IncUser;
                map[','] |= IncUser;

                // include these as path symbols
                map['/'] |= IncPath;
                map[';'] |= IncPath;
                map[':'] |= IncPath;
                map['@'] |= IncPath;
                map['&'] |= IncPath;
                map['='] |= IncPath;
                map['+'] |= IncPath;
                map['$'] |= IncPath;
                map[','] |= IncPath;

                // include these as query symbols
                map[';'] |= IncQuery | IncQueryAll;
                map['/'] |= IncQuery | IncQueryAll;
                map['?'] |= IncQueryAll;
                map[':'] |= IncQuery | IncQueryAll;
                map['@'] |= IncQuery | IncQueryAll;
                map['&'] |= IncQueryAll;
                map['='] |= IncQuery | IncQueryAll;
                map['+'] |= IncQuery | IncQueryAll;
                map['$'] |= IncQuery | IncQueryAll;
                map[','] |= IncQuery | IncQueryAll;

                // '%' are permitted inside queries when constructing output
                map['%'] |= IncQueryAll;
        }
        
        /***********************************************************************
        
                Create an empty Uri

        ***********************************************************************/

        this ()
        {
                port = InvalidPort;
                decoded = new HeapSlice (256);
        }

        /***********************************************************************
        
                Construct a Uri from the provided character string

        ***********************************************************************/

        this (char[] uri)
        {
                this ();
                parse (uri);
        }

        /***********************************************************************
        
                Construct a Uri from the given components. The query is
                optional.
                
        ***********************************************************************/

        this (char[] scheme, char[] host, char[] path, char[] query = null)
        {
                this ();

                this.scheme = scheme;
                this.query = query;
                this.host = host;
                this.path = path;
        }

        /***********************************************************************
        
                Clone another Uri. This can be used to make a mutable Uri
                from an immutable UriView.

        ***********************************************************************/

        this (UriView other)
        {
                with (other)
                     {
                     this (getScheme, getHost, getPath, getQuery);
                     this.userinfo = getUserInfo;
                     this.fragment = getFragment;
                     this.port = getPort;
                     }
        }

        /***********************************************************************
        
                Return the default port for the given scheme. InvalidPort
                is returned if the scheme is unknown, or does not accept
                a port.

        ***********************************************************************/

        final int getDefaultPort (char[] scheme)
        {
                short* port = scheme in genericSchemes; 
                if (port is null)
                    return InvalidPort;
                return *port;
        }

        /***********************************************************************
        
                Return the parsed scheme, or null if the scheme was not
                specified

        ***********************************************************************/

        final char[] getScheme()
        {
                return scheme;
        }

        /***********************************************************************
        
                Return the parsed host, or null if the host was not
                specified

        ***********************************************************************/

        final char[] getHost()
        {
                return host;
        }

        /***********************************************************************
        
                Return the parsed port number, or InvalidPort if the port
                was not provided.

        ***********************************************************************/

        final int getPort()
        {
                return port;
        }

        /***********************************************************************
        
                Return a valid port number by performing a lookup on the 
                known schemes if the port was not explicitly specified.

        ***********************************************************************/

        final int getValidPort()
        {
                if (port is InvalidPort)
                    return getDefaultPort (scheme);
                return port;
        }

        /***********************************************************************
        
                Return the parsed userinfo, or null if userinfo was not 
                provided.

        ***********************************************************************/

        final char[] getUserInfo()
        {
                return userinfo;
        }

        /***********************************************************************
        
                Return the parsed path, or null if the path was not 
                provided.

        ***********************************************************************/

        final char[] getPath()
        {
                return path;
        }

        /***********************************************************************
        
                Return the parsed query, or null if a query was not 
                provided.

        ***********************************************************************/

        final char[] getQuery()
        {
                return query;
        }

        /***********************************************************************
        
                Return the parsed fragment, or null if a fragment was not 
                provided.

        ***********************************************************************/

        final char[] getFragment()
        {
                return fragment;
        }

        /***********************************************************************
        
                Return whether or not the Uri scheme is considered generic.

        ***********************************************************************/

        final bool isGeneric ()
        {
                return (scheme in genericSchemes) !is null;
        }

        /***********************************************************************
        
                Emit the content of this Uri via the provided Consumer. The
                output is constructed per RFC 2396.

        ***********************************************************************/

        final Consumer produce (Consumer consume)
        {
                if (scheme.length)
                    consume (scheme), consume (":");


                if (userinfo.length || host.length || port != InvalidPort)
                   {
                   consume ("//");

                   if (userinfo.length)
                       encode (consume, userinfo, IncUser) ("@");

                   if (host.length)
                       consume (host);

                   if (port != InvalidPort && port != getDefaultPort(scheme))
                      {
                      char[8] tmp;
                      consume (":"), consume (Integer.itoa (tmp, cast(uint) port));
                      }
                   }

                if (path.length)
                    encode (consume, path, IncPath);

                if (query.length)
                   {
                   consume ("?");
                   encode (consume, query, IncQueryAll);
                   }

                if (fragment.length)
                   {
                   consume ("#");
                   encode (consume, fragment, IncQuery);
                   }

                return consume;
        }

        /***********************************************************************
        
                Emit the content of this Uri via the provided Consumer. The
                output is constructed per RFC 2396.

        ***********************************************************************/

        final char[] toString ()
        {
                void[] s;

                s.length = 256, s.length = 0;
                produce ((void[] v) {s ~= v;});
                return cast(char[]) s;
        }

        /***********************************************************************
        
                Encode uri characters into a Consumer, such that
                reserved chars are converted into their %hex version.

        ***********************************************************************/

        static Consumer encode (Consumer consume, char[] s, int flags)
        {
                char[3] hex;
                int     mark;

                hex[0] = '%';
                foreach (int i, char c; s)
                        {
                        if (! (map[c] & flags))
                           {
                           consume (s[mark..i]);
                           mark = i+1;
                                
                           hex[1] = hexDigits [(c >> 4) & 0x0f];
                           hex[2] = hexDigits [c & 0x0f];
                           consume (hex);
                           }
                        }

                // add trailing section
                if (mark < s.length)
                    consume (s[mark..s.length]);

                return consume;
        }

        /***********************************************************************
        
                Encode uri characters into a string, such that reserved 
                chars are converted into their %hex version.

                Returns a dup'd string

        ***********************************************************************/

        final char[] encode (char[] text, int flags)
        {
                void[] s;
                encode ((void[] v) {s ~= v;}, text, flags);
                return cast(char[]) s;
        }

        /***********************************************************************
        
                Decode a character string with potential %hex values in it.
                The decoded strings are placed into a thread-safe expanding
                buffer, and a slice of it is returned to the caller.

        ***********************************************************************/

        private char[] decoder (char[] s, char ignore=0)
        {
                static int toInt (char c)
                {
                        if (c >= '0' && c <= '9')
                            c -= '0';
                        else
                        if (c >= 'a' && c <= 'f')
                            c -= ('a' - 10);
                        else
                        if (c >= 'A' && c <= 'F')
                            c -= ('A' - 10);
                        return c;
                }
                
                int length = s.length;

                // take a peek first, to see if there's work to do
                if (length && memchr (s.ptr, '%', length))
                   {
                   char* p;
                   int   j;
                        
                   // ensure we have enough decoding space available
                   p = cast(char*) decoded.expand (length);

                   // scan string, stripping % encodings as we go
                   for (int i; i < length; ++i, ++j, ++p)
                       {
                       int c = s[i];

                       if (c is '%' && (i+2) < length)
                          {
                          c = toInt(s[i+1]) * 16 + toInt(s[i+2]);

                          // leave ignored escapes in the stream, 
                          // permitting escaped '&' to remain in
                          // the query string
                          if (c && (c is ignore))
                              c = '%';
                          else
                             i += 2;
                          }

                       *p = c;
                       }

                   // return a slice from the decoded input
                   return cast(char[]) decoded.slice (j);
                   }

                // return original content
                return s;
        }   

        /***********************************************************************
        
                Decode a duplicated string with potential %hex values in it

        ***********************************************************************/

        final char[] decode (char[] s)
        {
                return decoder(s).dup;
        }

        /***********************************************************************
        
                Parsing is performed according to RFC 2396
                
                ---
                  ^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?
                   12            3  4          5       6  7        8 9
                    
                2 isolates scheme
                4 isolates authority
                5 isolates path
                7 isolates query
                9 isolates fragment
                ---

                This was originally a state-machine; it turned out to be a 
                lot faster (~40%) when unwound like this instead.
                
        ***********************************************************************/

        final Uri parse (char[] uri, bool relative = false)
        {
                char    c;
                int     i, 
                        mark, 
                        len = uri.length;

                reset;

                // isolate scheme (note that it's OK to not specify a scheme)
                for (i=0; i < len && !(map[c = uri[i]] & ExcScheme); ++i) {}
                if (c is ':')
                   {
                   scheme = uri [mark .. i];
                   toLower (scheme);
                   mark = i + 1;
                   }

                // isolate authority
                if (mark < len-1 && uri[mark] is '/' && uri[mark+1] is '/')
                   {
                   for (mark+=2, i=mark; i < len && !(map[uri[i]] & ExcAuthority); ++i) {}
                   parseAuthority (uri[mark .. i]); 
                   mark = i;
                   }
                else
                   if (relative && uri[0] != '/')
                      {
                      uri = toLastSlash(path) ~ uri;
                      query = fragment = null;
                      len = uri.length;
                      }

                // isolate path
                for (i=mark; i < len && !(map[uri[i]] & ExcPath); ++i) {}
                path = decoder (uri[mark .. i]);
                mark = i;

                // isolate query
                if (mark < len && uri[mark] is '?')
                   {
                   for (++mark, i=mark; i < len && uri[i] != '#'; ++i) {}
                   query = decoder (uri[mark .. i], '&');
                   mark = i;
                   }

                // isolate fragment
                if (mark < len && uri[mark] is '#')
                    fragment = decoder (uri[mark+1 .. len]);

                return this;
        }

        /***********************************************************************
        
                Clear everything to null.

        ***********************************************************************/

        final void reset()
        {
                decoded.reset;
                port = InvalidPort;
                host = path = query = scheme = userinfo = fragment = null;
        }

        /***********************************************************************
        
                Parse the given uri, with support for relative URLs

        ***********************************************************************/

        final Uri relParse (char[] uri)
        {
                return parse (uri, true);
        }
        
        /***********************************************************************
                
                Set the Uri scheme

        ***********************************************************************/

        final Uri setScheme (char[] scheme)
        {
                this.scheme = scheme;
                return this;
        }

        /***********************************************************************
        
                Set the Uri host

        ***********************************************************************/

        final Uri setHost (char[] host)
        {
                this.host = host;
                return this;
        }

        /***********************************************************************
        
                Set the Uri port

        ***********************************************************************/

        final Uri setPort (int port)
        {
                this.port = port;
                return this;
        }

        /***********************************************************************
        
                Set the Uri userinfo

        ***********************************************************************/

        final Uri setUserInfo (char[] userinfo)
        {
                this.userinfo = userinfo;
                return this;
        }

        /***********************************************************************
        
                Set the Uri query

        ***********************************************************************/

        final Uri setQuery (char[] query)
        {
                this.query = query;
                return this;
        }

        /***********************************************************************
        
                Extend the Uri query

        ***********************************************************************/

        final char[] extendQuery (char[] tail)
        {
                if (tail.length)
                    if (query.length)
                        query = query ~ "&" ~ tail;
                    else
                       query = tail;
                return query;
        }

        /***********************************************************************
        
                Set the Uri path

        ***********************************************************************/

        final Uri setPath (char[] path)
        {
                this.path = path;
                return this;
        }

        /***********************************************************************
        
                Set the Uri fragment

        ***********************************************************************/

        final Uri setFragment (char[] fragment)
        {
                this.fragment = fragment;
                return this;
        }
        
        /***********************************************************************
        
                Authority is the section after the scheme, but before the 
                path, query or fragment; it typically represents a host.
               
                ---
                    ^(([^@]*)@?)([^:]*)?(:(.*))?
                     12         3       4 5
                  
                2 isolates userinfo
                3 isolates host
                5 isolates port
                ---

        ***********************************************************************/

        private void parseAuthority (char[] auth)
        {
                int     mark,
                        len = auth.length;

                // get userinfo: (([^@]*)@?)
                foreach (int i, char c; auth)
                         if (c is '@')
                            {
                            userinfo = decoder (auth[0 .. i]);
                            mark = i + 1;
                            break;
                            }

                // get port: (:(.*))?
                for (int i=mark; i < len; ++i)
                     if (auth [i] is ':')
                        {
                        port = Integer.atoi (auth [i+1 .. len]);
                        len = i;
                        break;
                        }

                // get host: ([^:]*)?
                host = auth [mark..len];
        }

        /**********************************************************************

        **********************************************************************/

        private final char[] toLastSlash (char[] path)
        {
                for (char*p = path.ptr+path.length; --p >= path.ptr;)
                     if (*p is '/')
                         return path [0 .. (p-path.ptr)+1];
                return path;
        }

        /**********************************************************************

                in-place conversion to lowercase 

        **********************************************************************/

        private final static char[] toLower (inout char[] src)
        {
                foreach (inout char c; src)
                         if (c >= 'A' && c <= 'Z')
                             c = c + ('a' - 'A');
                return src;
        }
}


/*******************************************************************************
        
*******************************************************************************/

private class HeapSlice
{
        private uint    used;
        private void[]  buffer;

        /***********************************************************************
        
                Create with the specified starting size

        ***********************************************************************/

        this (uint size)
        {
                buffer = new void[size];
        }

        /***********************************************************************
        
                Reset content length to zero

        ***********************************************************************/

        final void reset ()
        {
                used = 0;
        }

        /***********************************************************************
        
                Potentially expand the content space, and return a pointer
                to the start of the empty section.

        ***********************************************************************/

        final void* expand (uint size)
        {
                if ((used + size) > buffer.length)
                     buffer.length = (used + size) * 2;
                return &buffer [used];
        }

        /***********************************************************************
        
                Return a slice of the content from the current position 
                with the specified size. Adjusts the current position to 
                point at an empty zone.

        ***********************************************************************/

        final void[] slice (int size)
        {
                uint i = used;
                used += size;
                return buffer [i..used];
        }
}



/*******************************************************************************
        
*******************************************************************************/

debug (Uri)
{
        import tango.io.Console;

        void main()
        {
                auto uri = new Uri ("http://foo.bar?a=1&b=2&c=3&d=%26%26&e=5");

                Cout (uri.getQuery).newline;
                Cout (uri).newline;

                Cout (uri.encode ("&#$%", uri.IncQuery)).newline;
        }
}