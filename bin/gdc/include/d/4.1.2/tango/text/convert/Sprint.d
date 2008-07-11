/*******************************************************************************

        copyright:      Copyright (c) 2005 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Nov 2005: Initial release

        author:         Kris

*******************************************************************************/

module tango.text.convert.Sprint;

private import tango.text.convert.Layout;

/******************************************************************************

        Constructs sprintf-style output. This is a replacement for the 
        vsprintf() family of functions, and writes its output into a 
        lookaside buffer:
        ---
        // create a Sprint instance
        auto sprint = new Sprint!(char);

        // write formatted text to a logger
        log.info (sprint ("{} green bottles, sitting on a wall\n", 10));
        ---

        Sprint can be handy when you wish to format text for a Logger
        or similar, since it avoids heap activity during conversion by
        hosting a fixed size conversion buffer. This is important when
        debugging since heap activity can be responsible for behavioral 
        changes. One would create a Sprint instance ahead of time, and
        utilize it in conjunction with the logging package.
               
        Please note that the class itself is stateful, and therefore a 
        single instance is not shareable across multiple threads. The
        returned content is not .dup'd either, so do that yourself if
        you require a persistent copy.
        
        Note also that Sprint is templated, and can be instantiated for
        wide chars through a Sprint!(dchar) or Sprint!(wchar). The wide
        versions differ in that both the output and the format-string
        are of the target type. Variadic text arguments are transcoded 
        appropriately.

        See also: tango.text.convert.Layout

******************************************************************************/

class Sprint(T)
{
        protected T[]           buffer;
        static Layout!(T)       global;
        Layout!(T)              layout;

        alias format            opCall;
       
        /**********************************************************************

                Create new Sprint instances with a buffer of the specified
                size
                
        **********************************************************************/

        this (int size = 256)
        {
                // Workaround for bug with static ctors in GDC
                if (global is null)
                    global = new Layout!(T);
                this (size, global);
        }
        
        /**********************************************************************

                Create new Sprint instances with a buffer of the specified
                size, and the provided formatter. The second argument can be
                used to apply cultural specifics (I18N) to Sprint
                
        **********************************************************************/

        this (int size, Layout!(T) formatter)
        {
                buffer = new T[size];
                this.layout = formatter;
        }

        /**********************************************************************

                Layout a set of arguments
                
        **********************************************************************/

        T[] format (T[] fmt, ...)
        {
                return layout.vprint (buffer, fmt, _arguments, _argptr);
        }

        /**********************************************************************

                Layout a set of arguments
                
        **********************************************************************/

        T[] format (T[] fmt, TypeInfo[] arguments, ArgList argptr)
        {
                return layout.vprint (buffer, fmt, arguments, argptr);
        }
}

