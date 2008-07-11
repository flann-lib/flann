/*******************************************************************************

        Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.

        License:   BSD style: $(LICENSE)

        version:   Initial release: February 2008      

        Authors:   Aaron

*******************************************************************************/

module tango.text.xml.XmlPrinter;

private import tango.text.xml.Document;

/*******************************************************************************

*******************************************************************************/

class XmlPrinter(T) : IXmlPrinter!(T)
{
        /***********************************************************************
        
                Generate a text representation of the document tree

        ***********************************************************************/
        
        final T[] print (Doc doc)
        {       
                T[] content;

                print (doc.root, (T[][] s...){foreach(t; s) content ~= t;});
                return content;
        }
        
        /***********************************************************************
        
                Generate a representation of the given node-subtree 

        ***********************************************************************/
        
        final void print (Node root, void delegate(T[][]...) emit)
        {
                T[256] spaces = ' ';

                void printNode (Node node, uint indent)
                {
                        switch (node.type)
                               {
                               case XmlNodeType.Document:
                                    foreach (n; node.children)
                                             printNode (n, indent + 2);
                                    break;
        
                               case XmlNodeType.Element:
                                    emit ("<", node.name);
                                    foreach (attr; node.attributes)
                                             emit (" ", attr.name, "=\"", attr.rawValue, "\"");

                                    if (node.hasChildren || node.rawValue.length)
                                       {
                                       if (node.rawValue.length)
                                           emit (">", node.rawValue);
                                       else
                                       if (node.firstChild_.type is XmlNodeType.Data)
                                           emit (">");
                                       else
                                          emit (">\r\n");
                                       foreach (n; node.children)
                                               {
                                               if (node.firstChild_.type != XmlNodeType.Data)
                                                   emit (spaces[0..indent]);
                                               printNode (n, indent + 2);
                                               }
                                       emit ("</", node.name, ">\r\n");
                                       }
                                    else 
                                       emit ("/>\r\n");      
                                    break;
        
                               case XmlNodeType.Data:
                                    emit (node.rawValue);
                                    break;
        
                               case XmlNodeType.Attribute:                               
                                    emit (node.name, "=\"", node.rawValue, "\"");                                
                                    break;
        
                               case XmlNodeType.Comment:
                                    emit ("<!--", node.rawValue, "-->\r\n");
                                    break;
        
                               case XmlNodeType.PI:
                                    emit ("<?", node.rawValue, "?>\r\n");
                                    break;
        
                               case XmlNodeType.CData:
                                    emit ("<![CDATA[", node.rawValue, "]]>");
                                    break;
        
                               case XmlNodeType.Doctype:
                                    emit ("<!DOCTYPE ", node.rawValue, ">\r\n");
                                    break;
        
                               default:
                                    break;
                               }
                }
        
                printNode (root, 0);
        }
}
