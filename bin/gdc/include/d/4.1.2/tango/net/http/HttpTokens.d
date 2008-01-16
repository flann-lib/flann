/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
       
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module tango.net.http.HttpTokens;

private import  tango.time.Time;

private import  tango.io.Buffer;

private import  tango.io.model.IBuffer;

private import  tango.net.http.HttpStack,
                tango.net.http.HttpConst;

private import  Text = tango.text.Util;

private import  tango.io.protocol.model.IWriter;

private import  Integer = tango.text.convert.Integer;

private import  TimeStamp = tango.text.convert.TimeStamp;

/******************************************************************************

        Struct used to expose freachable HttpToken instances.

******************************************************************************/

struct HttpToken
{
        char[]  name,
                value;
}

/******************************************************************************

        Maintains a set of HTTP tokens. These tokens include headers, query-
        parameters, and anything else vaguely related. Both input and output
        are supported, though a subclass may choose to expose as read-only.

        All tokens are mapped directly onto a buffer, so there is no memory
        allocation or copying involved. 

        Note that this class does not support deleting tokens, per se. Instead
        it marks tokens as being 'unused' by setting content to null, avoiding 
        unwarranted reshaping of the token stack. The token stack is reused as
        time goes on, so there's only minor runtime overhead.

******************************************************************************/

class HttpTokens : IWritable
{
        protected HttpStack    stack;

        private IBuffer         input,
                                output;
        private bool            parsed;
        private bool            inclusive;
        private char            separator;
        private char[1]         sepString;

        /**********************************************************************
                
                Construct a set of tokens based upon the given delimiter, 
                and an indication of whether said delimiter should be
                considered part of the left side (effectively the name).
        
                The latter is useful with headers, since the seperating
                ':' character should really be considered part of the 
                name for purposes of subsequent token matching.

        **********************************************************************/

        this (char separator, bool inclusive = false)
        {
                stack = new HttpStack;

                this.inclusive = inclusive;
                this.separator = separator;
                
                // convert separator into a string, for later use
                sepString[0] = separator;

                // pre-construct an empty buffer for wrapping char[] parsing
                input = new Buffer;
        }

        /**********************************************************************
                
                Clone a source set of HttpTokens

        **********************************************************************/

        this (HttpTokens source)
        {
                stack = source.stack.clone;
                input = null;
                output = source.output;
                parsed = true;
                inclusive = source.inclusive;
                separator = source.separator;
                sepString[0] = source.sepString[0];
        }

        /**********************************************************************
                
                Read all tokens. Everything is mapped rather than being 
                allocated & copied

        **********************************************************************/

        abstract void parse (IBuffer input);

        /**********************************************************************
                
                Parse an input string.

        **********************************************************************/

        void parse (char[] content)
        {
                input.setContent (content);
                parse (input);       
        }

        /**********************************************************************
                
                Reset this set of tokens.

        **********************************************************************/

        HttpTokens reset ()
        {
                stack.reset;
                parsed = false;

                // reset output buffer, if it was configured
                if (output)
                    output.clear;

                return this;
        }

        /**********************************************************************
                
                Have tokens been parsed yet?

        **********************************************************************/

        bool isParsed ()
        {
                return parsed;
        }

        /**********************************************************************
                
                Indicate whether tokens have been parsed or not.

        **********************************************************************/

        void setParsed (bool parsed)
        {
                this.parsed = parsed;
        }

        /**********************************************************************
                
                Return the value of the provided header, or null if the
                header does not exist

        **********************************************************************/

        char[] get (char[] name, char[] ret = null)
        {
                Token token = stack.findToken (name);
                if (token)
                   {
                   HttpToken element;

                   if (split (token, element))
                       ret = trim (element.value);
                   }
                return ret;
        }

        /**********************************************************************
                
                Return the integer value of the provided header, or the 
                provided default-vaule if the header does not exist

        **********************************************************************/

        int getInt (char[] name, int ret = -1)
        {       
                char[] value = get (name);

                if (value.length)
                    ret = cast(int) Integer.parse (value);

                return ret;
        }

        /**********************************************************************
                
                Return the date value of the provided header, or the 
                provided default-value if the header does not exist

        **********************************************************************/

        Time getDate (char[] name, Time date = Time.epoch)
        {
                char[] value = get (name);

                if (value.length)
                    date = TimeStamp.parse (value);

                return date;
        }

        /**********************************************************************

                Iterate over the set of tokens

        **********************************************************************/

        int opApply (int delegate(inout HttpToken) dg)
        {
                HttpToken element;
                int       result = 0;

                foreach (Token t; stack)
                         if (split (t, element))
                            {
                            result = dg (element);
                            if (result)
                                break;
                            }
                return result;
        }

        /**********************************************************************

                Output the token list to the provided writer

        **********************************************************************/

        void write (IWriter writer)
        {
                produce (&writer.buffer.consume, HttpConst.Eol);
        }

        /**********************************************************************

                Output the token list to the provided consumer

        **********************************************************************/

        void produce (void delegate (void[]) consume, char[] eol)
        {
                foreach (Token token; stack)
                        {
                        auto content = token.toString();
                        if (content.length)
                            consume (content), consume (eol);
                        }                           
        }

        /**********************************************************************

                overridable method to handle the case where a token does
                not have a separator. Apparently, this can happen in HTTP 
                usage

        **********************************************************************/

        protected bool handleMissingSeparator (char[] s, inout HttpToken element)
        {
                return false;
        }

        /**********************************************************************

                split basic token into an HttpToken

        **********************************************************************/

        final private bool split (Token t, inout HttpToken element)
        {
                auto s = t.toString();

                if (s.length)
                   {
                   auto i = Text.locate (s, separator);

                   // we should always find the separator
                   if (i < s.length)
                      {
                      auto j = (inclusive) ? i+1 : i;
                      element.name = s[0 .. j];
                      element.value = (++i < s.length) ? s[i .. $] : null;
                      return true;
                      }
                   else
                      // allow override to specialize this case
                      return handleMissingSeparator (s, element);
                   }
                return false;                           
        }

        /**********************************************************************

                Create a filter for iterating over the tokens matching
                a particular name. 
        
        **********************************************************************/

        FilteredTokens createFilter (char[] match)
        {
                return new FilteredTokens (this, match);
        }

        /**********************************************************************

                Implements a filter for iterating over tokens matching
                a particular name. We do it like this because there's no 
                means of passing additional information to an opApply() 
                method.
        
        **********************************************************************/

        private static class FilteredTokens 
        {       
                private char[]          match;
                private HttpTokens      tokens;

                /**************************************************************

                        Construct this filter upon the given tokens, and
                        set the pattern to match against.

                **************************************************************/

                this (HttpTokens tokens, char[] match)
                {
                        this.match = match;
                        this.tokens = tokens;
                }

                /**************************************************************

                        Iterate over all tokens matching the given name

                **************************************************************/

                int opApply (int delegate(inout HttpToken) dg)
                {
                        HttpToken       element;
                        int             result = 0;
                        
                        foreach (Token token; tokens.stack)
                                 if (tokens.stack.isMatch (token, match))
                                     if (tokens.split (token, element))
                                        {
                                        result = dg (element);
                                        if (result)
                                            break;
                                        }
                        return result;
                }

        }

        /**********************************************************************

                Is the argument a whitespace character?

        **********************************************************************/

        private bool isSpace (char c)
        {
                return cast(bool) (c is ' ' || c is '\t' || c is '\r' || c is '\n');
        }

        /**********************************************************************

                Trim the provided string by stripping whitespace from 
                both ends. Returns a slice of the original content.

        **********************************************************************/

        private char[] trim (char[] source)
        {
                int  front,
                     back = source.length;

                if (back)
                   {
                   while (front < back && isSpace(source[front]))
                          ++front;

                   while (back > front && isSpace(source[back-1]))
                          --back;
                   } 
                return source [front .. back];
        }


        /**********************************************************************
        ****************** these should be exposed carefully ******************
        **********************************************************************/


        /**********************************************************************
                
                Set the output buffer for adding tokens to. This is used
                by the various mutating classes.

        **********************************************************************/

        protected void setOutputBuffer (IBuffer output)
        {
                this.output = output;
        }

        /**********************************************************************
                
                Return the buffer used for output.

        **********************************************************************/

        protected IBuffer getOutputBuffer ()
        {
                return output;
        }

        /**********************************************************************
                
                Return a char[] representing the output. An empty array
                is returned if output was not configured. This perhaps
                could just return our 'output' buffer content, but that
                would not reflect deletes, or seperators. Better to do 
                it like this instead, for a small cost.

        **********************************************************************/

        char[] formatTokens (IBuffer dst, char[] delim)
        {
                int adjust = 0;

                foreach (Token token; stack)
                        {
                        char[] content = token.toString;
                        if (content.length)
                           {
                           dst.append(content).append(delim);
                           adjust = delim.length;
                           }
                        }    

                dst.truncate (dst.limit - adjust);
                return cast(char[]) dst.slice;
        }

        /**********************************************************************
                
                Add a token with the given name. The content is provided
                via the specified delegate. We stuff this name & content
                into the output buffer, and map a new Token onto the
                appropriate buffer slice.

        **********************************************************************/

        protected void add (char[] name, void delegate (IBuffer) dg)
        {
                // save the buffer write-position
                int prior = output.limit;

                // add the name
                output.append (name);

                // don't append separator if it's already part of the name
                if (! inclusive)
                      output.append (sepString);
                
                // add the value
                dg (output);

                // map new token onto buffer slice
                stack.push (cast(char[]) output.slice [prior .. $]);
        }

        /**********************************************************************
                
                Add a simple name/value pair to the output

        **********************************************************************/

        protected void add (char[] name, char[] value)
        {
                void addValue (IBuffer buffer)
                {
                        buffer.append (value);
                }

                add (name, &addValue);
        }

        /**********************************************************************
                
                Add a name/integer pair to the output

        **********************************************************************/

        protected void addInt (char[] name, int value)
        {
                char[16] tmp = void;

                add (name, Integer.format (tmp, cast(long) value));
        }

        /**********************************************************************
               
               Add a name/date(long) pair to the output
                
        **********************************************************************/

        protected void addDate (char[] name, Time value)
        {
                char[40] tmp = void;

                add (name, TimeStamp.format (tmp, value));
        }

        /**********************************************************************
               
               remove a token from our list. Returns false if the named
               token is not found.
                
        **********************************************************************/

        protected bool remove (char[] name)
        {
                return stack.removeToken (name);
        }
}
