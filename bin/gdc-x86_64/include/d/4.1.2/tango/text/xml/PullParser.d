/*******************************************************************************
 
        Copyright: Copyright (C) 2007 Aaron Craelius and Kris Bell  
                   All rights reserved.

        License:   BSD style: $(LICENSE)

        version:   Initial release: February 2008      

        Authors:   Aaron, Kris

*******************************************************************************/

module tango.text.xml.PullParser;

private import tango.text.Util : indexOf;

private import tango.core.Exception : XmlException;

private import Integer = tango.text.convert.Integer;

version = a;
version = b;

/*******************************************************************************

*******************************************************************************/

public enum XmlNodeType {Element, Data, Attribute, CData, 
                         Comment, PI, Doctype, Document};

/*******************************************************************************

*******************************************************************************/

public enum XmlTokenType {Done, StartElement, Attribute, EndElement, 
                          EndEmptyElement, Data, Comment, CData, 
                          Doctype, PI, None};


/*******************************************************************************

        Token based XML Parser.  Templated to operate with char[], wchar[], 
        and dchar[] based Xml strings. 

        The parser is constructed with some tradeoffs relating to document
        integrity. It is generally optimized for well-formed documents, and
        currently may read past a document-end for those that are not well
        formed. There are various compilation options to enable checks and
        balances, depending on how things should be handled. We'll settle
        on a common configuration over the next few weeks, but for now all
        settings are somewhat experimental. Partly because making some tiny 
        unrelated change to the code can cause notable throughput changes, 
        and we need to track that down.

        We're not yet clear why these swings are so pronounced (for changes
        outside the code path) but they seem to be related to the alignment
        of codegen. It could be a cache-line issue, or something else. We'll
        figure it out, yet it's interesting that some hardware buttons are 
        clearly being pushed

*******************************************************************************/

class PullParser(Ch = char)
{
        public int                      depth;
        public Ch[]                     prefix;    
        public Ch[]                     rawValue;
        public Ch[]                     localName;     
        public XmlTokenType             type = XmlTokenType.None;

        package XmlIterator!(Ch)        text;
        private bool                    err;
        private char[]                  errMsg;

        /***********************************************************************
        
        ***********************************************************************/

        this(Ch[] content = null)
        {
                reset (content);
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        final XmlTokenType next()
        {      
                auto p = text.point;
                if (*p <= 32) 
                   {
                   while (*++p <= 32)
                   if (p >= text.end)                                      
                       return doEndOfStream;
                   text.point = p;
                   }
                
                if (type >= XmlTokenType.EndElement) 
                    return doMain;

                // in element
                switch (*p)
                       {
                       case '/':
                            return doEndEmptyElement;

                       case '>':
                            ++depth;
                            ++text.point;
                            return doMain;

                       default:
                            return doAttributeName;
                       }
        }
 
        /***********************************************************************
        
        ***********************************************************************/

        private XmlTokenType doMain()
        {
                auto p = text.point;
                if (*p != '<') 
                   {
version (a)
{
                   auto q = p;
                   if (p < text.end)
                       while (*++p != '<') {}

                   if (p < text.end)
                      {
                      rawValue = q [0 .. p - q];
                      text.point = p;
                      return type = XmlTokenType.Data;
                      }
                   return XmlTokenType.Done;
}
else
{
                   auto q = p;
                   while (*++p != '<') 
                         {}
                   if (p < text.end)
                      {
                      rawValue = q [0 .. p - q];
                      text.point = p;
                      return type = XmlTokenType.Data;
                      }
                   return XmlTokenType.Done;
}
                   }

                switch (p[1])
                       {
                       default:
                            auto q = ++p;
version (b)
{
                            while (*q > 63 || text.name[*q]) 
                                   ++q;
}
else
{
                            while (q < text.end)
                                  {
                                  auto c = *q;
                                  if (c > 63 || text.name[c])
                                      ++q;
                                  else
                                     break;
                                  }                        
}
                            text.point = q;

                            if (*q != ':') 
                               {
                               prefix = null;
                               localName = p [0 .. q - p];
                               }
                            else
                               {
version (c)
{
                               prefix = p[0 .. q - p];
                               p = ++q;
                               while (*q > 63 || text.attributeName[*q])
                                      ++q;
                               localName = p[0 .. q - p];
                               text.point = q;
}
else
{
                               prefix = p [0 .. q - p];
                               p = ++text.point;
                               q = text.eatAttrName;
                               localName = p [0 .. q - p];
}
                               }

                            return type = XmlTokenType.StartElement;

                       case '!':
                            if (text[2..4] == "--") 
                               {
                               text.point += 4;
                               return doComment();
                               }       
                            else 
                               if (text[2..9] == "[CDATA[") 
                                  {
                                  text.point += 9;
                                  return doCData();
                                  }
                               else 
                                  if (text[2..9] == "DOCTYPE") 
                                     {
                                     text.point += 9;
                                     return doDoctype();
                                     }
                            return doUnexpected("!");

                       case '\?':
                            text.point += 2;
                            return doPI();

                       case '/':
                            p += 2;
                            auto q = p;
                            while (*q > 63 || text.name[*q]) 
                                   ++q;

                            if (*q is ':') 
                               {
                               prefix = p[0 .. q - p];
                               p = ++q;
                               while (*q > 63 || text.attributeName[*q])
                                      ++q;
                               localName = p[0 .. q - p];
                               }
                            else 
                               {
                               prefix = null;
                               localName = p[0 .. q - p];
                               }

                            while (*q <= 32) 
                                   ++q;

                            if (q >= text.end)
                                return doUnexpectedEOF;

                            if (*q is '>')
                               {
                               text.point = q + 1;
                               --depth;
                               return type = XmlTokenType.EndElement;
                               }
                            return doUnexpected(">");
                       }

               return XmlTokenType.Done;
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        private XmlTokenType doAttributeName()
        {
                auto p = text.point;
                auto q = p;
                auto e = text.end;

                while (*q > 63 || text.attributeName[*q])
                       ++q;
                if (q >= e)
                    return doUnexpectedEOF;

                if (*q is ':')
                   {
                   prefix = p[0 .. q - p];
                   p = ++q;

                   while (*q > 63 || text.attributeName[*q])
                          ++q;
                   if (q >= e)
                       return doUnexpectedEOF;

                   localName = p[0 .. q - p];
                   }
                else 
                   {
                   prefix = null;
                   localName = p[0 .. q - p];
                   }
                
                if (*q <= 32) 
                   {
                   while (*++q <= 32) {}
                   if (q >= e)
                       return doUnexpectedEOF;
                   }

                if (*q is '=')
                   {
                   while (*++q <= 32) {}
                   if (q >= e)
                       return doUnexpectedEOF;

                   auto quote = *q;
                   switch (quote)
                          {
                          case '"':
                          case '\'':
                               p = q + 1;
                               while (*++q != quote) {}
                               //q = text.forwardLocate(p, quote);
                               if (q < e)
                                  {
                                  rawValue = p[0 .. q - p];
                                  text.point = q + 1;   //Skip end quote
                                  return type = XmlTokenType.Attribute;
                                  }
                               return doUnexpectedEOF; 

                          default: 
                               return doUnexpected("\' or \"");
                          }
                   }
                
                return doUnexpected (q[0..1]);
        }

        /***********************************************************************
        
        ***********************************************************************/

        private XmlTokenType doEndEmptyElement()
        {
                if (text.point[0] is '/' && text.point[1] is '>')
                   {
                   localName = prefix = null;
                   text.point += 2;
                   return type = XmlTokenType.EndEmptyElement;
                   }
                return doUnexpected("/>");               
       }
        
        /***********************************************************************
        
        ***********************************************************************/

        private XmlTokenType doComment()
        {
                auto p = text.point;

                while (text.good)
                      {
                      if (! text.forwardLocate('-')) 
                            return doUnexpectedEOF;

                      if (text[0..3] == "-->") 
                         {
                         rawValue = p [0 .. text.point - p];
                         //prefix = null;
                         text.point += 3;
                         return type = XmlTokenType.Comment;
                         }
                      ++text.point;
                      }

                return doUnexpectedEOF;
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        private XmlTokenType doCData()
        {
                auto p = text.point;
                
                while (text.good)
                      {
                      if (! text.forwardLocate(']')) 
                            return doUnexpectedEOF;
                
                      if (text[0..3] == "]]>") 
                         {
                         rawValue = p [0 .. text.point - p];
                         //prefix = null;
                         text.point += 3;                      
                         return type = XmlTokenType.CData;
                         }
                      ++text.point;
                      }

                return doUnexpectedEOF;
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        private XmlTokenType doPI()
        {
                auto p = text.point;
                text.eatElemName;
                ++text.point;

                while (text.good)
                      {
                      if (! text.forwardLocate('\?')) 
                            return doUnexpectedEOF;

                      if (text.point[1] == '>') 
                         {
                         rawValue = p [0 .. text.point - p];
                         text.point += 2;
                         return type = XmlTokenType.PI;
                         }
                      ++text.point;
                      }
                return doUnexpectedEOF;
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        private XmlTokenType doDoctype()
        {
                text.eatSpace;
                auto p = text.point;
                                
                while (text.good) 
                      {
                      if (*text.point == '>') 
                         {
                         rawValue = p [0 .. text.point - p];
                         prefix = null;
                         ++text.point;
                         return type = XmlTokenType.Doctype;
                         }
                      else 
                         if (*text.point == '[') 
                            {
                            ++text.point;
                            text.forwardLocate(']');
                            ++text.point;
                            }
                         else 
                            ++text.point;
                      }

                if (! text.good)
                      return doUnexpectedEOF;
                return XmlTokenType.Doctype;
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        private XmlTokenType doUnexpectedEOF()
        {
                return error ("Unexpected EOF");
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        private XmlTokenType doUnexpected(char[] msg = null)
        {
                return error ("Unexpected event " ~ msg ~ " " ~ Integer.toString(type));
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        private XmlTokenType doEndOfStream()
        {
                return XmlTokenType.Done;
        }
              
        /***********************************************************************
        
        ***********************************************************************/

        private XmlTokenType error (char[] msg)
        {
                errMsg = msg;
                err = true;
                throw new XmlException (msg);
                return XmlTokenType.Done;
        }

        /***********************************************************************
        
        ***********************************************************************/

        final Ch[] value()
        {
                return rawValue;
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        final Ch[] name()
        {
                if (prefix.length)
                    return prefix ~ ":" ~ localName;
                return localName;
        }
                
        /***********************************************************************
        
        ***********************************************************************/

        final bool error()
        {
                return err;
        }

        /***********************************************************************
        
        ***********************************************************************/

        final bool reset()
        {
                text.seek (0);
                reset_;
                return true;
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        final void reset(Ch[] newText)
        {
                text.reset (newText);
                reset_;                
        }
        
        /***********************************************************************
        
        ***********************************************************************/

        private void reset_()
        {
                err = false;
                depth = 0;
                type = XmlTokenType.None;

                if (text.point)
                   {
                   static if (Ch.sizeof == 1)
                   {
                       //Read UTF8 BOM
                       if (*text.point == 0xef)
                          {
                          if (text.point[1] == 0xbb)
                             {
                             if(text.point[2] == 0xbf)
                                text.point += 3;
                             }
                          }
                  }
                
                   //TODO enable optional declaration parsing
                   text.eatSpace;
                   if (*text.point == '<')
                      {
                      if (text.point[1] == '\?')
                         {
                         if (text[2..5] == "xml")
                            {
                            text.point += 5;
                            text.forwardLocate('\?');
                            text.point += 2;
                            }
                         }
                      }
                   }
        }
}


/*******************************************************************************

*******************************************************************************/

private struct XmlIterator(Ch)
{
        package Ch*     end;
        package size_t  len;
        package Ch[]    text;
        package Ch*     point;

        final bool good()
        {
                return point < end;
        }
        
        final Ch[] opSlice(size_t x, size_t y)
        in {
                if ((point+y) >= end || y < x)
                     assert(false);                  
           }
        body
        {               
                return point[x .. y];
        }
        
        final void seek(size_t position)
        in {
                if (position >= len) 
                    assert(false);
           }
        body
        {
                point = text.ptr + position;
        }

        final void reset(Ch[] newText)
        {
                this.text = newText;
                this.len = newText.length;
                this.point = text.ptr;
                this.end = point + len;
        }

        final bool forwardLocate (Ch ch)
        {
                auto tmp = end - point;
                auto l = indexOf!(Ch)(point, ch, tmp);
                if (l < tmp) 
                   {
                   point += l;
                   return true;
                   }
                return false;
        }
        
        final Ch* eatElemName()
        {      
                auto p = point;
                auto e = end;
                while (p < e)
                      {
                      auto c = *p;
                      if (c > 63 || name[c])
                          ++p;
                      else
                         break;
                      }
                return point = p;
        }
        
        final Ch* eatAttrName()
        {      
                auto p = point;
                auto e = end;
                while (p < e)
                      {
                      auto c = *p;
                      if (c > 63 || attributeName[c])
                          ++p;
                      else
                         break;
                      }
                return point = p;
        }
        
        final Ch* eatAttrName(Ch* p)
        {      
                auto e = end;
                while (p < e)
                      {
                      auto c = *p;
                      if (c > 63 || attributeName[c])
                          ++p;
                      else
                         break;
                      }
                return p;
        }
        
        final bool eatSpace()
        {
                auto p = point;
                auto e = end;
                while (p < e)
                      {                
                      if (*p <= 32)                                          
                          ++p;
                      else
                         {
                         point = p;
                         return true;
                         }                                  
                      }
               point = p;
               return false;
        }

        final Ch* eatSpace(Ch* p)
        {
                auto e = end;
                while (p < e)
                      {                
                      if (*p <= 32)                                          
                          ++p;
                      else
                         break;
                      }
               return p;
        }

        static const ubyte name[64] =
        [
             // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
                0,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  0,  1,  1,  // 0
                1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
                0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  // 2
                1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  1,  1,  1,  0,  0   // 3
        ];

        static const ubyte attributeName[64] =
        [
             // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
                0,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  0,  1,  1,  // 0
                1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
                0,  0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  // 2
                1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  1,  0,  0,  0,  0   // 3
        ];
}

/*******************************************************************************

*******************************************************************************/

debug (UnitTest)
{

	/***********************************************************************
	
	***********************************************************************/
	
	void testParser(Ch)(PullParser!(Ch) itr)
	{
	  /*      assert(itr.next);
	        assert(itr.value == "");
	        assert(itr.type == XmlTokenType.Declaration, Integer.toString(itr.type));
	        assert(itr.next);
	        assert(itr.value == "version");
	        assert(itr.next);
	        assert(itr.value == "1.0");*/
	        assert(itr.next);
	        assert(itr.value == "element [ <!ELEMENT element (#PCDATA)>]");
	        assert(itr.type == XmlTokenType.Doctype);
	        assert(itr.next);
	        assert(itr.localName == "element");
	        assert(itr.type == XmlTokenType.StartElement);
	        assert(itr.depth == 0);
	        assert(itr.next);
	        assert(itr.localName == "attr");
	        assert(itr.value == "1");
	        assert(itr.next);
	        assert(itr.type == XmlTokenType.Attribute, Integer.toString(itr.type));
	        assert(itr.localName == "attr2");
	        assert(itr.value == "two");
	        assert(itr.next);
	        assert(itr.value == "comment");
	        assert(itr.next);
	        assert(itr.rawValue == "test&amp;&#x5a;");
	        assert(itr.next);
	        assert(itr.prefix == "qual");
	        assert(itr.localName == "elem");
	        assert(itr.next);
	        assert(itr.type == XmlTokenType.EndEmptyElement);
	        assert(itr.next);
	        assert(itr.localName == "el2");
	        assert(itr.depth == 1);
	        assert(itr.next);
	        assert(itr.localName == "attr3");
	        assert(itr.value == "3three", itr.value);
	        assert(itr.next);
	        assert(itr.rawValue == "sdlgjsh");
	        assert(itr.next);
	        assert(itr.localName == "el3");
	        assert(itr.depth == 2);
	        assert(itr.next);
	        assert(itr.type == XmlTokenType.EndEmptyElement);
	        assert(itr.next);
	        assert(itr.value == "data");
	        assert(itr.next);
	      //  assert(itr.qvalue == "pi", itr.qvalue);
	      //  assert(itr.value == "test");
	        assert(itr.rawValue == "pi test");
	        assert(itr.next);
	        assert(itr.localName == "el2");
	        assert(itr.next);
	        assert(itr.localName == "element");
	        assert(!itr.next);
	}
	
	
	/***********************************************************************
	
	***********************************************************************/
	
	static const char[] testXML = "<?xml version=\"1.0\" ?><!DOCTYPE element [ <!ELEMENT element (#PCDATA)>]><element "
	    "attr=\"1\" attr2=\"two\"><!--comment-->test&amp;&#x5a;<qual:elem /><el2 attr3 = "
	    "'3three'><![CDATA[sdlgjsh]]><el3 />data<?pi test?></el2></element>";
	
	unittest
	{       
	        auto itr = new PullParser!(char)(testXML);     
	        testParser (itr);
	}
}
