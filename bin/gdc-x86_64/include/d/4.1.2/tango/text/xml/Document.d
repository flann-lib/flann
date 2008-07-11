/*******************************************************************************

        Copyright: Copyright (C) 2007 Aaron Craelius and Kris Bell  
                   All rights reserved.

        License:   BSD style: $(LICENSE)

        version:   Initial release: February 2008      

        Authors:   Aaron, Kris

*******************************************************************************/

module tango.text.xml.Document;

package import tango.text.xml.PullParser;

//version=discrete;

/*******************************************************************************

        Implements a DOM atop the XML parser, supporting document 
        parsing, tree traversal and ad-hoc tree manipulation.

        The DOM API is non-conformant, yet simple and functional in 
        style - locate a tree node of interest and operate upon or 
        around it. In all cases you will need a document instance to 
        begin, whereupon it may be populated either by parsing an 
        existing document or via API manipulation.

        This particular DOM employs a simple free-list to allocate
        each of the tree nodes, making it quite efficient at parsing
        XML documents. The tradeoff with such a scheme is that copying
        nodes from one document to another requires a little more care
        than otherwise. We felt this was a reasonable tradeoff, given
        the throughput gains vs the relative infrequency of grafting
        operations. For grafting within or across documents, please
        use the move() and copy() methods.

        Another simplification is related to entity transcoding. This
        is not performed internally, and becomes the responsibility
        of the client. That is, the client should perform appropriate
        entity transcoding as necessary. Paying the (high) transcoding 
        cost for all documents doesn't seem appropriate.

        Note that the parser is templated for char, wchar or dchar.

        Parse example:
        ---
        auto doc = new Document!(char);
        doc.parse (content);

        auto print = new XmlPrinter!(char);
        Stdout(print(doc)).newline;
         ---

        API example:
        ---
        auto doc = new Document!(char);

        // attach an xml header
        doc.header;

        // attach an element with some attributes, plus 
        // a child element with an attached data value
        doc.root.element   (null, "element")
                .attribute (null, "attrib1", "value")
                .attribute (null, "attrib2")
                .element   (null, "child", "value");

        auto print = new XmlPrinter!(char);
        Stdout(print(doc)).newline;
        ---

        XPath examples:
        ---
        auto doc = new Document!(char);

        // attach an element with some attributes, plus 
        // a child element with an attached data value
        doc.root.element   (null, "element")
                .attribute (null, "attrib1", "value")
                .attribute (null, "attrib2")
                .element   (null, "child", "value");

        // select named-elements
        auto set = doc.query["element"]["child"];

        // select all attributes named "attrib1"
        set = doc.query.descendant.attribute("attrib1");

        // select elements with one parent and a matching text value
        set = doc.query[].filter((doc.Node n) {return n.hasData("value);});
        ---

        Note that path queries are temporal - they do not retain content
        across mulitple queries. That is, the lifetime of a query result
        is limited unless you explicitly copy it. For example, this will 
        fail:
        ---
        auto elements = doc.query["element"];
        auto children = elements["child"];
        ---

        The above will lose elements because the associated document reuses 
        node space for subsequent queries. In order to retain results, do this:
        ---
        auto elements = doc.query["element"].dup;
        auto children = elements["child"];
        ---

        The above .dup is generally very small (a set of pointers only). On
        the other hand, recursive queries are fully supported:
        ---
        set = doc.query[].filter((doc.Node n) {return n.query[].count > 1;});
        ---

        Typical usage tends to follow the following pattern, Where each query 
        result is processed before another is initiated:
        ---
        foreach (node; doc.query.child("element"))
                {
                // do something with each node
                }
        ---
            
*******************************************************************************/

class Document(T) : package PullParser!(T)
{
        public alias NodeImpl*  Node;

        public  Node            root;
        private NodeImpl[]      list;
        private NodeImpl[][]    lists;
        private int             index,
                                chunks,
                                freelists;
        private XmlPath!(T)     xpath;

        /***********************************************************************
        
                Construct a DOM instance. The optional parameter indicates
                the initial number of nodes assigned to the freelist

        ***********************************************************************/

        this (uint nodes = 1000)
        {
                assert (nodes > 50);
                super (null);
                xpath = new XmlPath!(T);

                chunks = nodes;
                newlist;
                root = allocate;
                root.type = XmlNodeType.Document;
        }

        /***********************************************************************
        
                Return an xpath handle to query this document. This starts
                at the document root.

                See also Node.query

        ***********************************************************************/
        
        final XmlPath!(T).NodeSet query ()
        {
                return xpath.start (root);
        }

        /***********************************************************************
        
                Reset the freelist. Subsequent allocation of document nodes 
                will overwrite prior instances.

        ***********************************************************************/
        
        private final Document collect ()
        {
                root.lastChild_ = 
                root.firstChild_ = null;
                freelists = 0;
                newlist;
                index = 1;
version(d)
{
                freelists = 0;          // needed to align the codegen!
}
                return this;
        }

        /***********************************************************************
        
               Add an XML header to the document root

        ***********************************************************************/
        
        final Document header (T[] encoding = "UTF-8")
        {
                root.prepend (root.create(XmlNodeType.PI, 
                              `xml version="1.0" encoding="`~encoding~`"`));
                return this;
        }

        /***********************************************************************
        
                Parse the given xml content, which will reuse any existing 
                node within this document. The resultant tree is retrieved
                via the document 'root' attribute

        ***********************************************************************/
        
        final void parse(T[] xml)
        {
                collect;
                reset (xml);
                auto cur = root;
                uint defNamespace;

                while (true) 
                      {
                      auto p = text.point;
                      switch (super.next) 
                             {
                             case XmlTokenType.EndElement:
                             case XmlTokenType.EndEmptyElement:
                                  assert (cur.parent_);
                                  cur.end = text.point;
                                  cur = cur.parent_;                      
                                  break;
        
                             case XmlTokenType.Data:
version (discrete)
{
                                  auto node = allocate;
                                  node.rawValue = super.rawValue;
                                  node.type = XmlNodeType.Data;
                                  node.type = XmlNodeType.Data;
                                  cur.append (node);
}
else
{
                                  if (cur.rawValue.length is 0)
                                      cur.rawValue = super.rawValue;
                                  else
                                     // multiple data sections
                                     cur.data (super.rawValue);
}
                                  break;
        
                             case XmlTokenType.StartElement:
                                  auto node = allocate;
                                  node.parent_ = cur;
                                  node.prefix = super.prefix;
                                  node.type = XmlNodeType.Element;
                                  node.localName = super.localName;
                                  node.start = p;
                                  node.start = p;
                                
                                  // inline append
                                  if (cur.lastChild_) 
                                     {
                                     cur.lastChild_.nextSibling_ = node;
                                     node.prevSibling_ = cur.lastChild_;
                                     cur.lastChild_ = node;
                                     }
                                  else 
                                     {
                                     cur.firstChild_ = node;
                                     cur.lastChild_ = node;
                                     }
                                  cur = node;
                                  break;
        
                             case XmlTokenType.Attribute:
                                  auto attr = allocate;
                                  attr.prefix = super.prefix;
                                  attr.rawValue = super.rawValue;
                                  attr.localName = super.localName;
                                  attr.type = XmlNodeType.Attribute;
                                  cur.attrib (attr);
                                  break;
        
                             case XmlTokenType.PI:
                                  cur.pi (super.rawValue, p[0..text.point-p]);
                                  break;
        
                             case XmlTokenType.Comment:
                                  cur.comment (super.rawValue);
                                  break;
        
                             case XmlTokenType.CData:
                                  cur.cdata (super.rawValue);
                                  break;
        
                             case XmlTokenType.Doctype:
                                  cur.doctype (super.rawValue);
                                  break;
        
                             case XmlTokenType.Done:
                                  return;

                             default:
                                  break;
                             }
                      }
        }
        
        /***********************************************************************
        
                allocate a node from the freelist

        ***********************************************************************/

        private final Node allocate ()
        {
                if (index >= list.length)
                    newlist;

                auto p = &list[index++];
                p.start = p.end = null;
                p.document = this;
                p.parent_ =
                p.prevSibling_ = 
                p.nextSibling_ = 
                p.firstChild_ =
                p.lastChild_ = 
                p.firstAttr_ =
                p.lastAttr_ = null;
                p.rawValue = null;
                return p;
        }

        /***********************************************************************
        
                allocate a node from the freelist

        ***********************************************************************/

        private final void newlist ()
        {
                index = 0;
                if (freelists >= lists.length)
                   {
                   lists.length = lists.length + 1;
                   lists[$-1] = new NodeImpl [chunks];
                   }
                list = lists[freelists++];
        }

        /***********************************************************************
        
                Fruct support for nodes. A fruct is a low-overhead 
                mechanism for capturing context relating to an opApply

        ***********************************************************************/
        
        private struct Visitor
        {
                private Node node;
        
                /***************************************************************
                
                        traverse sibling nodes

                ***************************************************************/
        
                int opApply (int delegate(inout Node) dg)
                {
                        int ret;
                        auto cur = node;
                        while (cur)
                              {
                              if ((ret = dg (cur)) != 0) 
                                   break;
                              cur = cur.nextSibling_;
                              }
                        return ret;
                }
        }
        
        
        /***********************************************************************
        
                The node implementation

        ***********************************************************************/
        
        private struct NodeImpl
        {
                public XmlNodeType      type;
                public uint             index;
                public T[]              prefix;
                public T[]              localName;
                public T[]              rawValue;
                public Document         document;
                
                package Node            parent_,
                                        prevSibling_,
                                        nextSibling_,
                                        firstChild_,
                                        lastChild_,
                                        firstAttr_,
                                        lastAttr_;

                package T*              end,
                                        start;

                /***************************************************************
                
                        Return the parent, which may be null

                ***************************************************************/
        
                Node parent () {return parent_;}
        
                /***************************************************************
                
                        Return the first child, which may be nul

                ***************************************************************/
        
                Node firstChild () {return firstChild_;}
        
                /***************************************************************
                
                        Return the last child, which may be null

                ***************************************************************/
        
                Node lastChild () {return lastChild_;}
        
                /***************************************************************
                
                        Return the prior sibling, which may be null

                ***************************************************************/
        
                Node prevSibling () {return prevSibling_;}
        
                /***************************************************************
                
                        Return the next sibling, which may be null

                ***************************************************************/
        
                Node nextSibling () {return nextSibling_;}
        
                /***************************************************************
                
                        Returns whether there are attributes present or not

                ***************************************************************/
        
                bool hasAttributes () {return firstAttr_ !is null;}
                               
                /***************************************************************
                
                        Returns whether there are children present or nor

                ***************************************************************/
        
                bool hasChildren () {return firstChild_ !is null;}
                
                /***************************************************************
                
                        Return the node name, which is a combination of
                        the prefix:local names

                ***************************************************************/
        
                T[] name (T[] output = null)
                {
                        if (prefix.length)
                           {
version (old)
{
                           auto len = prefix.length + localName.length + 1;
                           if (output.length < len)
                               output.length = len;
                           output[0..prefix.length] = prefix;
                           output[prefix.length] = ':';
                           output[prefix.length+1 .. len] = localName;
                           return output[0..len];
}
else
                           return prefix.ptr [0 .. prefix.length + localName.length + 1];
                           }
                        return localName;
                }
                
                /***************************************************************
                
                        Return the data content, which may be null

                ***************************************************************/
        
                T[] value ()
                {
version(discrete)
{
                        if (type is XmlNodeType.Element)
                            foreach (child; children)
                                     if (child.type is XmlNodeType.Data)
                                         return child.rawValue;
}
                        return rawValue;
                }
                
                /***************************************************************
                
                        Set the raw data content, which may be null

                ***************************************************************/
        
                void value (T[] val)
                {
                        rawValue = val; 
                        mutate;
                }
                
                /***************************************************************
                
                        Return the index of this node, or how many 
                        prior siblings it has

                ***************************************************************/
       
                uint position ()
                {
                        return index;
                }
                
                /***************************************************************
                
                        Locate the root of this node

                ***************************************************************/
        
                Node root ()
                {
                        return document.root;
                }

                /***************************************************************
                
                        Return a foreach iterator for node children

                ***************************************************************/
        
                Visitor children () 
                {
                        Visitor v = {firstChild_};
                        return v;
                }
        
                /***************************************************************
                
                        Return a foreach iterator for node attributes

                ***************************************************************/
        
                Visitor attributes () 
                {
                        Visitor v = {firstAttr_};
                        return v;
                }
        
                /***************************************************************
        
                        Creates a child Element

                        Returns a reference to the child

                ***************************************************************/
        
                Node element (T[] prefix, T[] local, T[] value = null)
                {
                        auto node = create (XmlNodeType.Element, null);
                        append (node.set (prefix, local));
version(discrete)
{
                        if (value.length)
                            node.data (value);
}
else
{
                        node.rawValue = value;
}
                        return node;
                }
        
                /***************************************************************
        
                        Attaches an Attribute, and returns the host

                ***************************************************************/
        
                Node attribute (T[] prefix, T[] local, T[] value = null)
                {
                        auto node = create (XmlNodeType.Attribute, value);
                        attrib (node.set (prefix, local));
                        return this;
                }
        
                /***************************************************************
        
                        Attaches a Data node, and returns the host

                ***************************************************************/
        
                Node data (T[] data)
                {
                        append (create (XmlNodeType.Data, data));
                        return this;
                }
        
                /***************************************************************
        
                        Attaches a CData node, and returns the host

                ***************************************************************/
        
                Node cdata (T[] cdata)
                {
                        append (create (XmlNodeType.CData, cdata));
                        return this;
                }
        
                /***************************************************************
        
                        Attaches a Comment node, and returns the host

                ***************************************************************/
        
                Node comment (T[] comment)
                {
                        append (create (XmlNodeType.Comment, comment));
                        return this;
                }
        
                /***************************************************************
        
                        Attaches a PI node, and returns the host

                ***************************************************************/
        
                Node pi (T[] pi, T[] patch)
                {
                        append (create(XmlNodeType.PI, pi).patch(patch));
                        return this;
                }
        
                /***************************************************************
        
                        Attaches a PI node, and returns the host

                ***************************************************************/
        
                Node pi (T[] text)
                {
                        return pi (text, null);
                }
        
                /***************************************************************
        
                        Attaches a Doctype node, and returns the host

                ***************************************************************/
        
                Node doctype (T[] doctype)
                {
                        append (create (XmlNodeType.Doctype, doctype));
                        return this;
                }
        
                /***************************************************************
                
                        Detach this node from its parent and siblings

                ***************************************************************/
        
                Node detach()
                {
                        return remove;
                }

                /***************************************************************
                
                        Duplicate the given sub-tree into place as a child 
                        of this node. 
                        
                        Returns a reference to the subtree

                ***************************************************************/
        
                Node copy (Node tree)
                {
                        assert (tree);
                        tree = tree.clone;
                        tree.migrate (document);
                        append (tree);
                        return tree;
                }

                /***************************************************************
                
                        Relocate the given sub-tree into place as a child 
                        of this node. 
                        
                        Returns a reference to the subtree

                ***************************************************************/
        
                Node move (Node tree)
                {
                        tree.detach;
                        if (tree.document is document)
                            append (tree);
                        else
                           tree = copy (tree);
                        return tree;
                }

                /***************************************************************
        
                        Return an xpath handle to query this node

                        See also Node.document.query

                ***************************************************************/
        
                final XmlPath!(T).NodeSet query ()
                {
                        return document.xpath.start (this);
                }

                /***************************************************************
                
                        Sweep the attributes looking for a name or value
                        match. Either may be null

                        Returns a matching node, or null.

                ***************************************************************/
        
                Node getAttribute (T[] name, T[] value = null)
                {
                        foreach (attr; attributes)
                                {
                                if (name.ptr && name != attr.localName)
                                    continue;

                                if (value.ptr && value != attr.rawValue)
                                    continue;

                                return attr;
                                }
                        return null;
                }

                /***************************************************************
                
                        Sweep the attributes looking for a name or value
                        match. Either may be null

                        Returns true if found.

                ***************************************************************/
        
                bool hasAttribute (T[] name, T[] value = null)
                {
                        return getAttribute (name, value) !is null;
                }

                /***************************************************************
        
                        Sweep the data nodes looking for match

                        Returns a matching node, or null.

                ***************************************************************/
        
                Node data (bool delegate(Node) test)
                {
                        if (type is XmlNodeType.Element)
                            foreach (child; children)
                                     if (child.type is XmlNodeType.Data)
                                         if (test (child))
                                             return child;
                        return null;
                }

                /***************************************************************
        
                        Sweep the data nodes looking for match

                        Returns true if found.

                ***************************************************************/
        
                bool hasData (bool delegate(Node) test)
                {
                        return data(test) !is null;
                }

                /***************************************************************
                
                        Sweep the data nodes looking for match

                        Returns true if found.

                ***************************************************************/
        
                bool hasData (T[] text)
                {
                        return hasData ((Node n){return n.rawValue == text;});
                }

                /***************************************************************
                
                        Append an attribute to this node, The given attribute
                        cannot have an existing parent.

                ***************************************************************/
        
                private void attrib (Node node, uint uriID = 0)
                {
                        assert (node.parent is null);
                        node.parent_ = this;
                        node.type = XmlNodeType.Attribute;
        
                        if (lastAttr_) 
                           {
                           lastAttr_.nextSibling_ = node;
                           node.prevSibling_ = lastAttr_;
                           node.index = lastAttr_.index + 1;
                           lastAttr_ = node;
                           }
                        else 
                           {
                           firstAttr_ = lastAttr_ = node;
                           node.index = 0;
                           }
                }
        
                /***************************************************************
                
                        Append a node to this one. The given node cannot
                        have an existing parent.

                ***************************************************************/
        
                private void append (Node node)
                {
                        assert (node.parent is null);
                        node.parent_ = this;
                        if (lastChild_) 
                           {
                           lastChild_.nextSibling_ = node;
                           node.prevSibling_ = lastChild_;
                           node.index = lastChild_.index + 1;
                           lastChild_ = node;
                           }
                        else 
                           {
                           firstChild_ = lastChild_ = node;                  
                           node.index = 0;
                           }
                }

                /***************************************************************
                
                        Prepend a node to this one. The given node cannot
                        have an existing parent.

                ***************************************************************/
        
                private void prepend (Node node)
                {
                        assert (node.parent is null);
                        node.parent_ = this;
                        if (firstChild_) 
                           {
                           firstChild_.prevSibling_ = node;
                           node.nextSibling_ = firstChild_;
                           firstChild_ = node;
                           }
                        else 
                           {
                           firstChild_ = node;
                           lastChild_ = node;
                           }
                }
                
                /***************************************************************
        
                        Configure node values
        
                ***************************************************************/
        
                private Node set (T[] prefix, T[] local)
                {
                        this.localName = local;
                        this.prefix = prefix;
                        return this;
                }
        
                /***************************************************************
        
                        Creates and returns a child Element node

                ***************************************************************/
        
                private Node create (XmlNodeType type, T[] value)
                {
                        auto node = document.allocate;
                        node.rawValue = value;
                        node.type = type;
                        return node;
                }
        
                /***************************************************************
                
                        Detach this node from its parent and siblings

                ***************************************************************/
        
                private Node remove()
                {
                        if (! parent_) 
                              return this;
                        
                        mutate;
                        if (prevSibling_ && nextSibling_) 
                           {
                           prevSibling_.nextSibling_ = nextSibling_;
                           nextSibling_.prevSibling_ = prevSibling_;
                           prevSibling_ = null;
                           nextSibling_ = null;
                           parent_ = null;
                           }
                        else 
                           if (nextSibling_)
                              {
                              debug assert(parent_.firstChild_ == this);
                              parent_.firstChild_ = nextSibling_;
                              nextSibling_.prevSibling_ = null;
                              nextSibling_ = null;
                              parent_ = null;
                              }
                           else 
                              if (type != XmlNodeType.Attribute)
                                 {
                                 if (prevSibling_)
                                    {
                                    debug assert(parent_.lastChild_ == this);
                                    parent_.lastChild_ = prevSibling_;
                                    prevSibling_.nextSibling_ = null;
                                    prevSibling_ = null;
                                    parent_ = null;
                                    }
                                 else
                                    {
                                    debug assert(parent_.firstChild_ == this);
                                    debug assert(parent_.lastChild_ == this);
                                    parent_.firstChild_ = null;
                                    parent_.lastChild_ = null;
                                    parent_ = null;
                                    }
                                 }
                              else
                                 {
                                 if (prevSibling_)
                                    {
                                    debug assert(parent_.lastAttr_ == this);
                                    parent_.lastAttr_ = prevSibling_;
                                    prevSibling_.nextSibling_ = null;
                                    prevSibling_ = null;
                                    parent_ = null;
                                    }
                                 else
                                    {
                                    debug assert(parent_.firstAttr_ == this);
                                    debug assert(parent_.lastAttr_ == this);
                                    parent_.firstAttr_ = null;
                                    parent_.lastAttr_ = null;
                                    parent_ = null;
                                    }
                                 }

                        return this;
                }

                /***************************************************************

                        purge serialization cache for this node and its
                        ancestors

                ***************************************************************/
        
                private Node mutate ()
                {
                        auto node = this;
                        do {
                           node.end = null;
                           } while ((node = node.parent_) !is null);

                        return node;
                }

                /***************************************************************
        
                        Patch the serialization text

                ***************************************************************/
        
                private Node patch (T[] text)
                {
                        end = text.ptr + text.length;
                        start = text.ptr;
                        return this;
                }
        
                /***************************************************************
                
                        Duplicate a single node

                ***************************************************************/
        
                private Node dup()
                {
                        return create(type, rawValue.dup).set(prefix.dup, localName.dup);
                }

                /***************************************************************
                
                        Duplicate a subtree

                ***************************************************************/
        
                private Node clone ()
                {
                        auto p = dup;

                        foreach (attr; attributes)
                                 p.attrib (attr.dup);
                        foreach (child; children)
                                 p.append (child.clone);
                        return p;
                }

                /***************************************************************

                        Reset the document host for this subtree

                ***************************************************************/
        
                private void migrate (Document host)
                {
                        this.document = host;
                        foreach (attr; attributes)
                                 attr.migrate (host);
                        foreach (child; children)
                                 child.migrate (host);
                }
        }
}


/*******************************************************************************

        XPath support 

        Provides support for common XPath axis and filtering functions,
        via a native-D interface instead of typical interpreted notation.

        The general idea here is to generate a NodeSet consisting of those
        tree-nodes which satisfy a filtering function. The direction, or
        axis, of tree traversal is governed by one of several predefined
        operations. All methods facilitiate call-chaining, where each step 
        returns a new NodeSet instance to be operated upon.

        The set of nodes themselves are collected in a freelist, avoiding
        heap-activity and making good use of D array-slicing facilities.

        (this needs to be a class in order to avoid forward-ref issues)

        XPath examples:
        ---
        auto doc = new Document!(char);

        // attach an element with some attributes, plus 
        // a child element with an attached data value
        doc.root.element   (null, "element")
                .attribute (null, "attrib1", "value")
                .attribute (null, "attrib2")
                .element   (null, "child", "value");

        // select named-elements
        auto set = doc.query["element"]["child"];

        // select all attributes named "attrib1"
        set = doc.query.descendant.attribute("attrib1");

        // select elements with one parent and a matching text value
        set = doc.query[].filter((doc.Node n) {return n.hasData("value");});
        ---

        Note that path queries are temporal - they do not retain content
        across mulitple queries. That is, the lifetime of a query result
        is limited unless you explicitly copy it. For example, this will 
        fail:
        ---
        auto elements = doc.query["element"];
        auto children = elements["child"];
        ---

        The above will lose elements, because the associated document reuses 
        node space for subsequent queries. In order to retain results, do this:
        ---
        auto elements = doc.query["element"].dup;
        auto children = elements["child"];
        ---

        The above .dup is generally very small (a set of pointers only). On
        the other hand, recursive queries are fully supported:
        ---
        set = doc.query[].filter((doc.Node n) {return n.query[].count > 1;});
        ---
  
        Typical usage tends to follow the following pattern, Where each query 
        result is processed before another is initiated:
        ---
        foreach (node; doc.query.child("element"))
                {
                // do something with each node
                }
        ---

        Supported axis include:
        ---
        .child                  immediate children
        .parent                 immediate parent 
        .next                   following siblings
        .prev                   prior siblings
        .ancestor               all parents
        .descendant             all descendants
        .text                   text children
        .attribute              attribute children
        ---

        Each of the above accept an optional string, which is used in an
        axis-specific way to filter nodes. For instance, a .child("food") 
        will filter <food> child elements. These variants are shortcuts
        to using a filter to post-process a result. Each of the above also
        have variants which accept a delegate instead.

        In general, you traverse an axis and operate upon the results. The
        operation applied may be another axis traversal, or a filtering 
        step. All steps can be, and generally should be chained together. 
        Filters are implemented via a delegate mechanism:
        ---
        .filter (bool delegate(Node))
        ---

        Where the delegate returns true if the node passes the filter. An
        example might be selecting all nodes with a specific attribute:
        ---
        auto set = doc.query.descendant.filter((doc.Node n){return n.hasAttribute("test");});
        ---

        Obviously this is not as clean and tidy as true XPath notation, but 
        that can be wrapped atop this API instead. The benefit here is one 
        of raw throughput - important for some applications. 

        Note that every operation returns a discrete result. Methods first()
        and last() also return a set of one or zero elements. Some language
        specific extensions are provided for too:
        ---
        * .child() can be substituted with [] notation instead

        * [] notation can be used to index a specific element, like .nth()

        * the .nodes attribute exposes an underlying Node[], which may be
          sliced or traversed in the usual D manner
        ---

       Other (query result) utility methods include:
       ---
       .dup
       .first
       .last
       .opIndex
       .nth
       .count
       .opApply
       ---

*******************************************************************************/

private class XmlPath(T)
{       
        public alias Document!(T) Doc;          /// the typed document
        public alias Doc.Node     Node;         /// generic document node
         
        private Node[]          freelist;
        private uint            freeIndex,
                                markIndex;
        private uint            recursion;

        /***********************************************************************
        
                Prime a query

                Returns a NodeSet containing just the given node, which
                can then be used to cascade results into subsequent NodeSet
                instances.

        ***********************************************************************/
        
        final NodeSet start (Node root)
        {
                // we have to support recursion which may occur within
                // a filter callback
                if (recursion is 0)
                   {
                   if (freelist.length is 0)
                       freelist.length = 256;
                   freeIndex = 0;
                   }

                NodeSet set = {this};
                auto mark = freeIndex;
                allocate(root);
                return set.assign (mark);
        }

        /***********************************************************************
        
                This is the meat of XPath support. All of the NodeSet
                operators exist here, in order to enable call-chaining.

                Note that some of the axis do double-duty as a filter 
                also. This is just a convenience factor, and doesn't 
                change the underlying mechanisms.

        ***********************************************************************/
        
        struct NodeSet
        {
                private XmlPath host;
                public  Node[]  nodes;
               
                /***************************************************************
        
                        Return a duplicate NodeSet

                ***************************************************************/
        
                NodeSet dup ()
                {
                        NodeSet copy = {host};
                        copy.nodes = nodes.dup;
                        return copy;
                }

                /***************************************************************
        
                        Return the number of selected nodes in the set

                ***************************************************************/
        
                uint count ()
                {
                        return nodes.length;
                }

                /***************************************************************
        
                        Return a set containing just the first node of
                        the current set

                ***************************************************************/
        
                NodeSet first ()
                {
                        return nth (0);
                }

                /***************************************************************
       
                        Return a set containing just the last node of
                        the current set

                ***************************************************************/
        
                NodeSet last ()
                {       
                        auto i = nodes.length;
                        if (i > 0)
                            --i;
                        return nth (i);
                }

                /***************************************************************
        
                        Return a set containing just the nth node of
                        the current set

                ***************************************************************/
        
                NodeSet opIndex (uint i)
                {
                        return nth (i);
                }

                /***************************************************************
        
                        Return a set containing just the nth node of
                        the current set
        
                ***************************************************************/
        
                NodeSet nth (uint index)
                {
                        NodeSet set = {host};
                        auto mark = host.mark;
                        if (index < nodes.length)
                            host.allocate (nodes [index]);
                        return set.assign (mark);
                }

                /***************************************************************
        
                        Return a set containing all child elements of the 
                        nodes within this set
        
                ***************************************************************/
        
                NodeSet opSlice ()
                {
                        return child();
                }

                /***************************************************************
        
                        Return a set containing all child elements of the 
                        nodes within this set, which match the given name

                ***************************************************************/
        
                NodeSet opIndex (T[] name)
                {
                        return child (name);
                }

                /***************************************************************
        
                        Return a set containing all parent elements of the 
                        nodes within this set, which match the optional name

                ***************************************************************/
        
                NodeSet parent (T[] name = null)
                {
                        if (name.ptr)
                            return parent ((Node node){return node.name == name;});
                        return parent (&always);
                }

                /***************************************************************
        
                        Return a set containing all data nodes of the 
                        nodes within this set, which match the optional
                        value

                ***************************************************************/
        
                NodeSet data (T[] value = null)
                {
                        if (value.ptr)
                            return child ((Node node){return node.value == value;}, 
                                           XmlNodeType.Data);
                        return child (&always, XmlNodeType.Data);
                }

                /***************************************************************
        
                        Return a set containing all attributes of the 
                        nodes within this set, which match the optional
                        name

                ***************************************************************/
        
                NodeSet attribute (T[] name = null)
                {
                        if (name.ptr)
                            return attribute ((Node node){return node.name == name;});
                        return attribute (&always);
                }

                /***************************************************************
        
                        Return a set containing all descendant elements of 
                        the nodes within this set, which match the given name

                ***************************************************************/
        
                NodeSet descendant (T[] name = null)
                {
                        if (name.ptr)
                            return descendant ((Node node){return node.name == name;});
                        return descendant (&always);
                }

                /***************************************************************
        
                        Return a set containing all child elements of the 
                        nodes within this set, which match the optional name

                ***************************************************************/
        
                NodeSet child (T[] name = null)
                {
                        if (name.ptr)
                            return child ((Node node){return node.name == name;});
                        return  child (&always);
                }

                /***************************************************************
        
                        Return a set containing all ancestor elements of 
                        the nodes within this set, which match the optional
                        name

                ***************************************************************/
        
                NodeSet ancestor (T[] name = null)
                {
                        if (name.ptr)
                            return ancestor ((Node node){return node.name == name;});
                        return ancestor (&always);
                }

                /***************************************************************
        
                        Return a set containing all prior sibling elements of 
                        the nodes within this set, which match the optional
                        name

                ***************************************************************/
        
                NodeSet prev (T[] name = null)
                {
                        if (name.ptr)
                            return prev ((Node node){return node.name == name;});
                        return prev (&always);
                }

                /***************************************************************
        
                        Return a set containing all subsequent sibling 
                        elements of the nodes within this set, which 
                        match the optional name

                ***************************************************************/
        
                NodeSet next (T[] name = null)
                {
                        if (name.ptr)
                            return next ((Node node){return node.name == name;});
                        return next (&always);
                }

                /***************************************************************
        
                        Return a set containing all nodes within this set
                        which pass the filtering test

                ***************************************************************/
        
                NodeSet filter (bool delegate(Node) filter)
                {
                        NodeSet set = {host};
                        auto mark = host.mark;

                        foreach (node; nodes)
                                 test (filter, node);
                        return set.assign (mark);
                }

                /***************************************************************
        
                        Return a set containing all child nodes of 
                        the nodes within this set which pass the 
                        filtering test

                ***************************************************************/
        
                NodeSet child (bool delegate(Node) filter, 
                               XmlNodeType type = XmlNodeType.Element)
                {
                        NodeSet set = {host};
                        auto mark = host.mark;

                        foreach (parent; nodes)
                                 foreach (child; parent.children)
                                          if (child.type is type)
                                              test (filter, child);
                        return set.assign (mark);
                }

                /***************************************************************
        
                        Return a set containing all attribute nodes of 
                        the nodes within this set which pass the given
                        filtering test

                ***************************************************************/
        
                NodeSet attribute (bool delegate(Node) filter)
                {
                        NodeSet set = {host};
                        auto mark = host.mark;

                        foreach (node; nodes)
                                 foreach (attr; node.attributes)
                                          test (filter, attr);
                        return set.assign (mark);
                }

                /***************************************************************
        
                        Return a set containing all descendant nodes of 
                        the nodes within this set, which pass the given
                        filtering test

                ***************************************************************/
        
                NodeSet descendant (bool delegate(Node) filter, 
                                    XmlNodeType type = XmlNodeType.Element)
                {
                        void traverse (Node parent)
                        {
                                 foreach (child; parent.children)
                                         {
                                         if (child.type is type)
                                             test (filter, child);
                                         if (child.firstChild_)
                                             traverse (child);
                                         }                                                
                        }

                        NodeSet set = {host};
                        auto mark = host.mark;

                        foreach (node; nodes)
                                 traverse (node);
                        return set.assign (mark);
                }

                /***************************************************************
        
                        Return a set containing all parent nodes of 
                        the nodes within this set which pass the given
                        filtering test

                ***************************************************************/
        
                NodeSet parent (bool delegate(Node) filter)
                {
                        NodeSet set = {host};
                        auto mark = host.mark;

                        foreach (node; nodes)
                                {
                                auto p = node.parent;
                                if (p && p.type != XmlNodeType.Document && !set.has(p))
                                   {
                                   test (filter, p);
                                   // continually update our set of nodes, so
                                   // that set.has() can see a prior entry.
                                   // Ideally we'd avoid invoking test() on
                                   // prior nodes, but I don't feel the added
                                   // complexity is warranted
                                   set.nodes = host.slice (mark);
                                   }
                                }
                        return set.assign (mark);
                }

                /***************************************************************
        
                        Return a set containing all ancestor nodes of 
                        the nodes within this set, which pass the given
                        filtering test

                ***************************************************************/
        
                NodeSet ancestor (bool delegate(Node) filter)
                {
                        NodeSet set = {host};
                        auto mark = host.mark;

                        void traverse (Node child)
                        {
                                auto p = child.parent_;
                                if (p && p.type != XmlNodeType.Document && !set.has(p))
                                   {
                                   test (filter, p);
                                   // continually update our set of nodes, so
                                   // that set.has() can see a prior entry.
                                   // Ideally we'd avoid invoking test() on
                                   // prior nodes, but I don't feel the added
                                   // complexity is warranted
                                   set.nodes = host.slice (mark);
                                   traverse (p);
                                   }
                        }

                        foreach (node; nodes)
                                 traverse (node);
                        return set.assign (mark);
                }

                /***************************************************************
        
                        Return a set containing all following siblings 
                        of the ones within this set, which pass the given
                        filtering test

                ***************************************************************/
        
                NodeSet next (bool delegate(Node) filter, 
                              XmlNodeType type = XmlNodeType.Element)
                {
                        NodeSet set = {host};
                        auto mark = host.mark;

                        foreach (node; nodes)
                                {
                                auto p = node.nextSibling_;
                                while (p)
                                      {
                                      if (p.type is type)
                                          test (filter, p);
                                      p = p.nextSibling_;
                                      }
                                }
                        return set.assign (mark);
                }

                /***************************************************************
        
                        Return a set containing all prior sibling nodes 
                        of the ones within this set, which pass the given
                        filtering test

                ***************************************************************/
        
                NodeSet prev (bool delegate(Node) filter, 
                              XmlNodeType type = XmlNodeType.Element)
                {
                        NodeSet set = {host};
                        auto mark = host.mark;

                        foreach (node; nodes)
                                {
                                auto p = node.prevSibling_;
                                while (p)
                                      {
                                      if (p.type is type)
                                          test (filter, p);
                                      p = p.prevSibling_;
                                      }
                                }
                        return set.assign (mark);
                }

                /***************************************************************
                
                        Traverse the nodes of this set

                ***************************************************************/
        
                int opApply (int delegate(inout Node) dg)
                {
                        int ret;

                        foreach (node; nodes)
                                 if ((ret = dg (node)) != 0) 
                                      break;
                        return ret;
                }

                /***************************************************************
        
                        Common predicate
                                
                ***************************************************************/
        
                private bool always (Node node)
                {
                        return true;
                }

                /***************************************************************
        
                        Assign a slice of the freelist to this NodeSet

                ***************************************************************/
        
                private NodeSet assign (uint mark)
                {
                        nodes = host.slice (mark);
                        return *this;
                }

                /***************************************************************
        
                        Execute a filter on the given node. We have to
                        deal with potential query recusion, so we set
                        all kinda crap to recover from that

                ***************************************************************/
        
                private void test (bool delegate(Node) filter, Node node)
                {
                        auto pop = host.push;
                        auto add = filter (node);
                        host.pop (pop);
                        if (add)
                            host.allocate (node);
                }

                /***************************************************************
        
                        We typically need to filter ancestors in order
                        to avoid duplicates, so this is used for those
                        purposes                        

                ***************************************************************/
        
                private bool has (Node p)
                {
                        foreach (node; nodes)
                                 if (node is p)
                                     return true;
                        return false;
                }
        }

        /***********************************************************************

                Return the current freelist index
                        
        ***********************************************************************/
        
        private uint mark ()
        {       
                return freeIndex;
        }

        /***********************************************************************

                Recurse and save the current state
                        
        ***********************************************************************/
        
        private uint push ()
        {       
                ++recursion;
                return freeIndex;
        }

        /***********************************************************************

                Restore prior state
                        
        ***********************************************************************/
        
        private void pop (uint prior)
        {       
                freeIndex = prior;
                --recursion;
        }

        /***********************************************************************
        
                Return a slice of the freelist

        ***********************************************************************/
        
        private Node[] slice (uint mark)
        {
                assert (mark <= freeIndex);
                return freelist [mark .. freeIndex];
        }

        /***********************************************************************
        
                Allocate an entry in the freelist, expanding as necessary

        ***********************************************************************/
        
        private uint allocate (Node node)
        {
                if (freeIndex >= freelist.length)
                    freelist.length = freelist.length + freelist.length / 2;

                freelist[freeIndex] = node;
                return ++freeIndex;
        }
}



/*******************************************************************************

        Specification for an XML serializer

*******************************************************************************/

interface IXmlPrinter(T)
{
        public alias Document!(T) Doc;          /// the typed document
        public alias Doc.Node Node;             /// generic document node
        public alias print opCall;              /// alias for print method

        /***********************************************************************
        
                Generate a text representation of the document tree

        ***********************************************************************/
        
        T[] print (Doc doc);
        
        /***********************************************************************
        
                Generate a representation of the given node-subtree 

        ***********************************************************************/
        
        void print (Node root, void delegate(T[][]...) emit);
}



