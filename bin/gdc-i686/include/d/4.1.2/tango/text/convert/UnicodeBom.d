/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: December 2005      
        
        author:         Kris

*******************************************************************************/

module tango.text.convert.UnicodeBom;

private import  tango.core.ByteSwap;

private import  Utf = tango.text.convert.Utf;


private extern (C) void onUnicodeError (char[] msg, size_t idx = 0);

/*******************************************************************************

        see http://icu.sourceforge.net/docs/papers/forms_of_unicode/#t2

*******************************************************************************/

enum Encoding {
              Unknown,
              UTF_8,
              UTF_8N,
              UTF_16,
              UTF_16BE,
              UTF_16LE,
              UTF_32,
              UTF_32BE,
              UTF_32LE,
              };

/*******************************************************************************

        Convert unicode content

        Unicode is an encoding of textual material. The purpose of this module 
        is to interface external-encoding with a programmer-defined internal-
        encoding. This internal encoding is declared via the template argument 
        T, whilst the external encoding is either specified or derived.

        Three internal encodings are supported: char, wchar, and dchar. The
        methods herein operate upon arrays of this type. That is, decode()
        returns an array of the type, while encode() expect an array of said 
        type.

        Supported external encodings are as follow:

                Encoding.Unknown 
                Encoding.UTF_8
                Encoding.UTF_8N
                Encoding.UTF_16
                Encoding.UTF_16BE
                Encoding.UTF_16LE 
                Encoding.UTF_32 
                Encoding.UTF_32BE
                Encoding.UTF_32LE 

        These can be divided into non-explicit and explicit encodings:

                Encoding.Unknown 
                Encoding.UTF_8
                Encoding.UTF_16
                Encoding.UTF_32 


                Encoding.UTF_8N
                Encoding.UTF_16BE
                Encoding.UTF_16LE 
                Encoding.UTF_32BE
                Encoding.UTF_32LE 
        
        The former group of non-explicit encodings may be used to 'discover'
        an unknown encoding, by examining the first few bytes of the content
        for a signature. This signature is optional, but is often written such 
        that the content is self-describing. When an encoding is unknown, using 
        one of the non-explicit encodings will cause the decode() method to look 
        for a signature and adjust itself accordingly. It is possible that a 
        ZWNBSP character might be confused with the signature; today's unicode 
        content is supposed to use the WORD-JOINER character instead.
       
        The group of explicit encodings are for use when the content encoding 
        is known. These *must* be used when converting back to external encoding, 
        since written content must be in a known format. It should be noted that, 
        during a decode() operation, the existence of a signature is in conflict 
        with these explicit varieties.


        See 
        $(LINK http://www.utf-8.com/)
        $(LINK http://www.hackcraft.net/xmlUnicode/)
        $(LINK http://www.unicode.org/faq/utf_bom.html/)
        $(LINK http://www.azillionmonkeys.com/qed/unicode.html/)
        $(LINK http://icu.sourceforge.net/docs/papers/forms_of_unicode/)

*******************************************************************************/

class UnicodeBom(T) : BomSniffer
{
        static if (!is (T == char) && !is (T == wchar) && !is (T == dchar)) 
                    pragma (msg, "Template type must be char, wchar, or dchar");

        /***********************************************************************
        
                Construct a instance using the given external encoding ~ one 
                of the Encoding.xx types 

        ***********************************************************************/
                                  
        this (Encoding encoding)
        {
                setup (encoding);
        }
        
        /***********************************************************************

                Convert the provided content. The content is inspected 
                for a BOM signature, which is stripped. An exception is
                thrown if a signature is present when, according to the
                encoding type, it should not be. Conversely, An exception
                is thrown if there is no known signature where the current
                encoding expects one to be present

        ***********************************************************************/

        final T[] decode (void[] content, T[] dst=null, uint* ate=null)
        {
                // look for a BOM
                auto info = test (content);

                // are we expecting a BOM?
                if (lookup[encoding].test)
                    if (info)
                       {
                       // yep ~ and we got one
                       setup (info.encoding);

                       // strip BOM from content
                       content = content [info.bom.length .. length];
                       }
                    else
                       // can this encoding be defaulted?
                       if (settings.fallback)
                           setup (settings.fallback);
                       else
                          onUnicodeError ("UnicodeBom.decode :: unknown or missing BOM");
                else
                   if (info)
                       // found a BOM when using an explicit encoding
                       onUnicodeError ("UnicodeBom.decode :: explicit encoding does not permit BOM");   
                
                // convert it to internal representation
                return into (swapBytes(content), settings.type, dst, ate);
        }

        /***********************************************************************

                Perform encoding of content. Note that the encoding must be 
                of the explicit variety by the time we get here

        ***********************************************************************/

        final void[] encode (T[] content, void[] dst=null, uint* ate=null)
        {
                if (settings.test)
                    onUnicodeError ("UnicodeBom.encode :: cannot write to a non-specific encoding");

                // convert it to external representation, and write
		return swapBytes (from (content, settings.type, dst, ate));
        }

        /***********************************************************************

                Swap bytes around, as required by the encoding

        ***********************************************************************/

        private final void[] swapBytes (void[] content)
        {
                bool endian = settings.endian;
                bool swap   = settings.bigEndian;

                version (BigEndian)
                         swap = !swap;

                if (endian && swap)
                   {
                   if (settings.type == Utf16)
                       ByteSwap.swap16 (content.ptr, content.length);
                   else
                       ByteSwap.swap32 (content.ptr, content.length);
                   }
                return content;
        }

        /***********************************************************************
      

        ***********************************************************************/

        static T[] into (void[] x, uint type, T[] dst=null, uint* ate=null)
        {
                T[] ret;

                static if (is (T == char))
                          {
                          if (type == Utf8)
                              return cast(T[]) x;

                          if (type == Utf16)
			      ret = Utf.toString (cast(wchar[]) x, dst, ate);
                          else
                          if (type == Utf32)
                              ret = Utf.toString (cast(dchar[]) x, dst, ate);
                          }

                static if (is (T == wchar))
                          {
                          if (type == Utf16)
                              return cast(T[]) x;

                          if (type == Utf8)
                              ret = Utf.toString16 (cast(char[]) x, dst, ate);
                          else
                          if (type == Utf32)
                              ret = Utf.toString16 (cast(dchar[]) x, dst, ate);
                          }

                static if (is (T == dchar))
                          {
                          if (type == Utf32)
                              return cast(T[]) x;

                          if (type == Utf8)
                              ret = Utf.toString32 (cast(char[]) x, dst, ate);
                          else
                          if (type == Utf16)
                              ret = Utf.toString32 (cast(wchar[]) x, dst, ate);
                          }

                return ret;
        }


        /***********************************************************************

        ***********************************************************************/

        static void[] from (T[] x, uint type, void[] dst=null, uint* ate=null)
        {
                void[] ret;

                static if (is (T == char))
                          {
                          if (type == Utf8)
                              return x;

                          if (type == Utf16)
                              ret = Utf.toString16 (x, cast(wchar[]) dst, ate);
                          else
                          if (type == Utf32)
                              ret = Utf.toString32 (x, cast(dchar[]) dst, ate);
                          }

                static if (is (T == wchar))
                          {
                          if (type == Utf16)
                              return x;

                          if (type == Utf8)
                              ret = Utf.toString (x, cast(char[]) dst, ate);
                          else
                          if (type == Utf32)
                              ret = Utf.toString32 (x, cast(dchar[]) dst, ate);
                          }

                static if (is (T == dchar))
                          {
                          if (type == Utf32)
                              return x;

                          if (type == Utf8)
                              ret = Utf.toString (x, cast(char[]) dst, ate);
                          else
                          if (type == Utf16)
                              ret = Utf.toString16 (x, cast(wchar[]) dst, ate);
                          }

                return ret;
        }
}



/*******************************************************************************

*******************************************************************************/

class BomSniffer 
{
        private Encoding encoder;      // the current encoding
        private Info*    settings;      // pointer to encoding configuration

        private struct  Info
                {
                int      type;          // type of element (char/wchar/dchar)
                Encoding encoding;      // Encoding.xx encoding
                char[]   bom;           // pattern to match for signature
                bool     test,          // should we test for this encoding?
                         endian,        // this encoding have endian concerns?
                         bigEndian;     // is this a big-endian encoding?
                Encoding fallback;      // can this encoding be defaulted?
                };

        private enum {Utf8, Utf16, Utf32};
        
        private const Info[] lookup =
        [
        {Utf8,  Encoding.Unknown,  null,        true,  false, false, Encoding.UTF_8N},
        {Utf8,  Encoding.UTF_8,    null,        true,  false, false, Encoding.UTF_8N},
        {Utf8,  Encoding.UTF_8N,   x"efbbbf",   false},
        {Utf16, Encoding.UTF_16,   null,        true,  false, false, Encoding.UTF_16BE},
        {Utf16, Encoding.UTF_16BE, x"feff",     false, true, true},
        {Utf16, Encoding.UTF_16LE, x"fffe",     false, true},
        {Utf32, Encoding.UTF_32,   null,        true,  false, false, Encoding.UTF_32BE},
        {Utf32, Encoding.UTF_32BE, x"0000feff", false, true, true},
        {Utf32, Encoding.UTF_32LE, x"fffe0000", false, true},
        ];

        /***********************************************************************

                Return the current encoding. This is either the originally
                specified encoding, or a derived one obtained by inspecting
                the content for a BOM. The latter is performed as part of 
                the decode() method

        ***********************************************************************/

        final Encoding encoding ()
        {
                return encoder;
        }
        
        /***********************************************************************

                Return the signature (BOM) of the current encoding

        ***********************************************************************/

        final void[] signature ()
        {
                return settings.bom;
        }

        /***********************************************************************

                Configure this instance with unicode converters

        ***********************************************************************/

        final void setup (Encoding encoding)
        {
                this.settings = &lookup[encoding];
                this.encoder = encoding;
        }
        
        /***********************************************************************

                Scan the BOM signatures looking for a match. We scan in 
                reverse order to get the longest match first

        ***********************************************************************/

        static final Info* test (void[] content)
        {
                for (Info* info=lookup.ptr+lookup.length; --info >= lookup.ptr;)
                     if (info.bom)
                        {
                        int len = info.bom.length;
                        if (len <= content.length)
                            if (content[0..len] == info.bom[0..len])
                                return info;
                        }
                return null;
        }
}

