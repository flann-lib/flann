/*******************************************************************************

        Copyright: Copyright (C) 2007-2008 Scott Sanders, Kris Bell.  
                   All rights reserved.

        License:   BSD style: $(LICENSE)

        version:   Initial release: February 2008      

        Authors:   stonecobra, Kris

        Acknowledgements: 
                   Many thanks to the entire group that came up with
                   SAX as an API, and then had the foresight to place
                   it into the public domain so that it can become a
                   de-facto standard.  It may not be the best XML API, 
                   but it sure is handy. For more information, see 
                   <a href='http://www.saxproject.org'>http://www.saxproject.org</a>.

*******************************************************************************/

module tango.text.xml.SaxParser;

private import tango.io.model.IConduit;
private import tango.text.xml.PullParser;

/*******************************************************************************

        Single attributes are represented by this struct.

 *******************************************************************************/
struct Attribute(Ch = char) {

        Ch[] localName;
        Ch[] value;

}

/*******************************************************************************
 * Receive notification of the logical content of a document.
 *
 * <p>This is the main interface that most SAX applications
 * implement: if the application needs to be informed of basic parsing 
 * events, it implements this interface and registers an instance with 
 * the SAX parser using the {@link org.xml.sax.XMLReader#setContentHandler 
 * setContentHandler} method.  The parser uses the instance to report 
 * basic document-related events like the start and end of elements 
 * and character data.</p>
 *
 * <p>The order of events in this interface is very important, and
 * mirrors the order of information in the document itself.  For
 * example, all of an element's content (character data, processing
 * instructions, and/or subelements) will appear, in order, between
 * the startElement event and the corresponding endElement event.</p>
 *
 * <p>This interface is similar to the now-deprecated SAX 1.0
 * DocumentHandler interface, but it adds support for Namespaces
 * and for reporting skipped entities (in non-validating XML
 * processors).</p>
 *
 * <p>Implementors should note that there is also a 
 * <code>ContentHandler</code> class in the <code>java.net</code>
 * package; that means that it's probably a bad idea to do</p>
 *
 * <pre>import java.net.*;
 * import org.xml.sax.*;
 * </pre>
 *
 * <p>In fact, "import ...*" is usually a sign of sloppy programming
 * anyway, so the user should consider this a feature rather than a
 * bug.</p>
 *
 * @since SAX 2.0
 * @author David Megginson
 * @version 2.0.1+ (sax2r3pre1)
 * @see org.xml.sax.XMLReader
 * @see org.xml.sax.ErrorHandler
 *******************************************************************************/
public class SaxHandler(Ch = char) {
        
        Locator!(Ch) locator;

        /*******************************************************************************
         * Receive an object for locating the origin of SAX document events.
         *
         * <p>SAX parsers are strongly encouraged (though not absolutely
         * required) to supply a locator: if it does so, it must supply
         * the locator to the application by invoking this method before
         * invoking any of the other methods in the ContentHandler
         * interface.</p>
         *
         * <p>The locator allows the application to determine the end
         * position of any document-related event, even if the parser is
         * not reporting an error.  Typically, the application will
         * use this information for reporting its own errors (such as
         * character content that does not match an application's
         * business rules).  The information returned by the locator
         * is probably not sufficient for use with a search engine.</p>
         *
         * <p>Note that the locator will return correct information only
         * during the invocation SAX event callbacks after
         * {@link #startDocument startDocument} returns and before
         * {@link #endDocument endDocument} is called.  The
         * application should not attempt to use it at any other time.</p>
         *
         * @param locator an object that can return the location of
         *                any SAX document event
         * @see org.xml.sax.Locator
         *******************************************************************************/
        public void setDocumentLocator(Locator!(Ch) locator)
        {
                this.locator = locator;
        }

        /*******************************************************************************
         * Receive notification of the beginning of a document.
         *
         * <p>The SAX parser will invoke this method only once, before any
         * other event callbacks (except for {@link #setDocumentLocator 
         * setDocumentLocator}).</p>
         *
         * @throws org.xml.sax.SAXException any SAX exception, possibly
         *            wrapping another exception
         * @see #endDocument
         *******************************************************************************/
        public void startDocument()
        {
                
        }

        /*******************************************************************************
         * Receive notification of the end of a document.
         *
         * <p><strong>There is an apparent contradiction between the
         * documentation for this method and the documentation for {@link
         * org.xml.sax.ErrorHandler#fatalError}.  Until this ambiguity is
         * resolved in a future major release, clients should make no
         * assumptions about whether endDocument() will or will not be
         * invoked when the parser has reported a fatalError() or thrown
         * an exception.</strong></p>
         *
         * <p>The SAX parser will invoke this method only once, and it will
         * be the last method invoked during the parse.  The parser shall
         * not invoke this method until it has either abandoned parsing
         * (because of an unrecoverable error) or reached the end of
         * input.</p>
         *
         * @throws org.xml.sax.SAXException any SAX exception, possibly
         *            wrapping another exception
         * @see #startDocument
         *******************************************************************************/
        public void endDocument()
        {
                
        }

        /*******************************************************************************
         * Begin the scope of a prefix-URI Namespace mapping.
         *
         * <p>The information from this event is not necessary for
         * normal Namespace processing: the SAX XML reader will 
         * automatically replace prefixes for element and attribute
         * names when the <code>http://xml.org/sax/features/namespaces</code>
         * feature is <var>true</var> (the default).</p>
         *
         * <p>There are cases, however, when applications need to
         * use prefixes in character data or in attribute values,
         * where they cannot safely be expanded automatically; the
         * start/endPrefixMapping event supplies the information
         * to the application to expand prefixes in those contexts
         * itself, if necessary.</p>
         *
         * <p>Note that start/endPrefixMapping events are not
         * guaranteed to be properly nested relative to each other:
         * all startPrefixMapping events will occur immediately before the
         * corresponding {@link #startElement startElement} event, 
         * and all {@link #endPrefixMapping endPrefixMapping}
         * events will occur immediately after the corresponding
         * {@link #endElement endElement} event,
         * but their order is not otherwise 
         * guaranteed.</p>
         *
         * <p>There should never be start/endPrefixMapping events for the
         * "xml" prefix, since it is predeclared and immutable.</p>
         *
         * @param prefix the Namespace prefix being declared.
         * An empty string is used for the default element namespace,
         * which has no prefix.
         * @param uri the Namespace URI the prefix is mapped to
         * @throws org.xml.sax.SAXException the client may throw
         *            an exception during processing
         * @see #endPrefixMapping
         * @see #startElement
         *******************************************************************************/
        public void startPrefixMapping(Ch[] prefix, Ch[] uri)
        {
                
        }

        /*******************************************************************************
         * End the scope of a prefix-URI mapping.
         *
         * <p>See {@link #startPrefixMapping startPrefixMapping} for 
         * details.  These events will always occur immediately after the
         * corresponding {@link #endElement endElement} event, but the order of 
         * {@link #endPrefixMapping endPrefixMapping} events is not otherwise
         * guaranteed.</p>
         *
         * @param prefix the prefix that was being mapped.
         * This is the empty string when a default mapping scope ends.
         * @throws org.xml.sax.SAXException the client may throw
         *            an exception during processing
         * @see #startPrefixMapping
         * @see #endElement
         *******************************************************************************/
        public void endPrefixMapping(Ch[] prefix)
        {
                
        }

        /*******************************************************************************
         * Receive notification of the beginning of an element.
         *
         * <p>The Parser will invoke this method at the beginning of every
         * element in the XML document; there will be a corresponding
         * {@link #endElement endElement} event for every startElement event
         * (even when the element is empty). All of the element's content will be
         * reported, in order, before the corresponding endElement
         * event.</p>
         *
         * <p>This event allows up to three name components for each
         * element:</p>
         *
         * <ol>
         * <li>the Namespace URI;</li>
         * <li>the local name; and</li>
         * <li>the qualified (prefixed) name.</li>
         * </ol>
         *
         * <p>Any or all of these may be provided, depending on the
         * values of the <var>http://xml.org/sax/features/namespaces</var>
         * and the <var>http://xml.org/sax/features/namespace-prefixes</var>
         * properties:</p>
         *
         * <ul>
         * <li>the Namespace URI and local name are required when 
         * the namespaces property is <var>true</var> (the default), and are
         * optional when the namespaces property is <var>false</var> (if one is
         * specified, both must be);</li>
         * <li>the qualified name is required when the namespace-prefixes property
         * is <var>true</var>, and is optional when the namespace-prefixes property
         * is <var>false</var> (the default).</li>
         * </ul>
         *
         * <p>Note that the attribute list provided will contain only
         * attributes with explicit values (specified or defaulted):
         * #IMPLIED attributes will be omitted.  The attribute list
         * will contain attributes used for Namespace declarations
         * (xmlns* attributes) only if the
         * <code>http://xml.org/sax/features/namespace-prefixes</code>
         * property is true (it is false by default, and support for a 
         * true value is optional).</p>
         *
         * <p>Like {@link #characters characters()}, attribute values may have
         * characters that need more than one <code>char</code> value.  </p>
         *
         * @param uri the Namespace URI, or the empty string if the
         *        element has no Namespace URI or if Namespace
         *        processing is not being performed
         * @param localName the local name (without prefix), or the
         *        empty string if Namespace processing is not being
         *        performed
         * @param qName the qualified name (with prefix), or the
         *        empty string if qualified names are not available
         * @param atts the attributes attached to the element.  If
         *        there are no attributes, it shall be an empty
         *        Attributes object.  The value of this object after
         *        startElement returns is undefined
         * @throws org.xml.sax.SAXException any SAX exception, possibly
         *            wrapping another exception
         * @see #endElement
         * @see org.xml.sax.Attributes
         * @see org.xml.sax.helpers.AttributesImpl
         *******************************************************************************/
        public void startElement(Ch[] uri, Ch[] localName, Ch[] qName, Attribute!(Ch)[] atts)
        {
                
        }

        /*******************************************************************************
         * Receive notification of the end of an element.
         *
         * <p>The SAX parser will invoke this method at the end of every
         * element in the XML document; there will be a corresponding
         * {@link #startElement startElement} event for every endElement 
         * event (even when the element is empty).</p>
         *
         * <p>For information on the names, see startElement.</p>
         *
         * @param uri the Namespace URI, or the empty string if the
         *        element has no Namespace URI or if Namespace
         *        processing is not being performed
         * @param localName the local name (without prefix), or the
         *        empty string if Namespace processing is not being
         *        performed
         * @param qName the qualified XML name (with prefix), or the
         *        empty string if qualified names are not available
         * @throws org.xml.sax.SAXException any SAX exception, possibly
         *            wrapping another exception
         *******************************************************************************/
        public void endElement(Ch[] uri, Ch[] localName, Ch[] qName)
        {
                
        }

        /*******************************************************************************
         * Receive notification of character data.
         *
         * <p>The Parser will call this method to report each chunk of
         * character data.  SAX parsers may return all contiguous character
         * data in a single chunk, or they may split it into several
         * chunks; however, all of the characters in any single event
         * must come from the same external entity so that the Locator
         * provides useful information.</p>
         *
         * <p>The application must not attempt to read from the array
         * outside of the specified range.</p>
         *
         * <p>Individual characters may consist of more than one Java
         * <code>char</code> value.  There are two important cases where this
         * happens, because characters can't be represented in just sixteen bits.
         * In one case, characters are represented in a <em>Surrogate Pair</em>,
         * using two special Unicode values. Such characters are in the so-called
         * "Astral Planes", with a code point above U+FFFF.  A second case involves
         * composite characters, such as a base character combining with one or
         * more accent characters. </p>
         *
         * <p> Your code should not assume that algorithms using
         * <code>char</code>-at-a-time idioms will be working in character
         * units; in some cases they will split characters.  This is relevant
         * wherever XML permits arbitrary characters, such as attribute values,
         * processing instruction data, and comments as well as in data reported
         * from this method.  It's also generally relevant whenever Java code
         * manipulates internationalized text; the issue isn't unique to XML.</p>
         *
         * <p>Note that some parsers will report whitespace in element
         * content using the {@link #ignorableWhitespace ignorableWhitespace}
         * method rather than this one (validating parsers <em>must</em> 
         * do so).</p>
         *
         * @param ch the characters from the XML document
         * @param start the start position in the array
         * @param length the number of characters to read from the array
         * @throws org.xml.sax.SAXException any SAX exception, possibly
         *            wrapping another exception
         * @see #ignorableWhitespace 
         * @see org.xml.sax.Locator
         *******************************************************************************/
        public void characters(Ch ch[])
        {
                
        }

        /*******************************************************************************
         * Receive notification of ignorable whitespace in element content.
         *
         * <p>Validating Parsers must use this method to report each chunk
         * of whitespace in element content (see the W3C XML 1.0
         * recommendation, section 2.10): non-validating parsers may also
         * use this method if they are capable of parsing and using
         * content models.</p>
         *
         * <p>SAX parsers may return all contiguous whitespace in a single
         * chunk, or they may split it into several chunks; however, all of
         * the characters in any single event must come from the same
         * external entity, so that the Locator provides useful
         * information.</p>
         *
         * <p>The application must not attempt to read from the array
         * outside of the specified range.</p>
         *
         * @param ch the characters from the XML document
         * @param start the start position in the array
         * @param length the number of characters to read from the array
         * @throws org.xml.sax.SAXException any SAX exception, possibly
         *            wrapping another exception
         * @see #characters
         *******************************************************************************/
        public void ignorableWhitespace(Ch ch[])
        {
                
        }

        /*******************************************************************************
         * Receive notification of a processing instruction.
         *
         * <p>The Parser will invoke this method once for each processing
         * instruction found: note that processing instructions may occur
         * before or after the main document element.</p>
         *
         * <p>A SAX parser must never report an XML declaration (XML 1.0,
         * section 2.8) or a text declaration (XML 1.0, section 4.3.1)
         * using this method.</p>
         *
         * <p>Like {@link #characters characters()}, processing instruction
         * data may have characters that need more than one <code>char</code>
         * value. </p>
         *
         * @param target the processing instruction target
         * @param data the processing instruction data, or null if
         *        none was supplied.  The data does not include any
         *        whitespace separating it from the target
         * @throws org.xml.sax.SAXException any SAX exception, possibly
         *            wrapping another exception
         *******************************************************************************/
        public void processingInstruction(Ch[] target, Ch[] data)
        {
                
        }

        /*******************************************************************************
         * Receive notification of a skipped entity.
         * This is not called for entity references within markup constructs
         * such as element start tags or markup declarations.  (The XML
         * recommendation requires reporting skipped external entities.
         * SAX also reports internal entity expansion/non-expansion, except
         * within markup constructs.)
         *
         * <p>The Parser will invoke this method each time the entity is
         * skipped.  Non-validating processors may skip entities if they
         * have not seen the declarations (because, for example, the
         * entity was declared in an external DTD subset).  All processors
         * may skip external entities, depending on the values of the
         * <code>http://xml.org/sax/features/external-general-entities</code>
         * and the
         * <code>http://xml.org/sax/features/external-parameter-entities</code>
         * properties.</p>
         *
         * @param name the name of the skipped entity.  If it is a 
         *        parameter entity, the name will begin with '%', and if
         *        it is the external DTD subset, it will be the string
         *        "[dtd]"
         * @throws org.xml.sax.SAXException any SAX exception, possibly
         *            wrapping another exception
         *******************************************************************************/
        public void skippedEntity(Ch[] name)
        {
                
        }

}

/*******************************************************************************
 * Basic interface for resolving entities.
 *
 * <p>If a SAX application needs to implement customized handling
 * for external entities, it must implement this interface and
 * register an instance with the SAX driver using the
 * {@link org.xml.sax.XMLReader#setEntityResolver setEntityResolver}
 * method.</p>
 *
 * <p>The XML reader will then allow the application to intercept any
 * external entities (including the external DTD subset and external
 * parameter entities, if any) before including them.</p>
 *
 * <p>Many SAX applications will not need to implement this interface,
 * but it will be especially useful for applications that build
 * XML documents from databases or other specialised input sources,
 * or for applications that use URI types other than URLs.</p>
 *
 * <p>The following resolver would provide the application
 * with a special character stream for the entity with the system
 * identifier "http://www.myhost.com/today":</p>
 *
 * <pre>
 * import org.xml.sax.EntityResolver;
 * import org.xml.sax.InputSource;
 *
 * public class MyResolver implements EntityResolver {
 *   public InputSource resolveEntity (String publicId, String systemId)
 *   {
 *     if (systemId.equals("http://www.myhost.com/today")) {
 *              // return a special input source
 *       MyReader reader = new MyReader();
 *       return new InputSource(reader);
 *     } else {
 *              // use the default behaviour
 *       return null;
 *     }
 *   }
 * }
 * </pre>
 *
 * <p>The application can also use this interface to redirect system
 * identifiers to local URIs or to look up replacements in a catalog
 * (possibly by using the public identifier).</p>
 *
 * @since SAX 1.0
 * @author David Megginson
 * @version 2.0.1 (sax2r2)
 * @see org.xml.sax.XMLReader#setEntityResolver
 * @see org.xml.sax.InputSource
 *******************************************************************************/
public interface EntityResolver(Ch = char) {

        /*******************************************************************************
         * Allow the application to resolve external entities.
         *
         * <p>The parser will call this method before opening any external
         * entity except the top-level document entity.  Such entities include
         * the external DTD subset and external parameter entities referenced
         * within the DTD (in either case, only if the parser reads external
         * parameter entities), and external general entities referenced
         * within the document element (if the parser reads external general
         * entities).  The application may request that the parser locate
         * the entity itself, that it use an alternative URI, or that it
         * use data provided by the application (as a character or byte
         * input stream).</p>
         *
         * <p>Application writers can use this method to redirect external
         * system identifiers to secure and/or local URIs, to look up
         * public identifiers in a catalogue, or to read an entity from a
         * database or other input source (including, for example, a dialog
         * box).  Neither XML nor SAX specifies a preferred policy for using
         * public or system IDs to resolve resources.  However, SAX specifies
         * how to interpret any InputSource returned by this method, and that
         * if none is returned, then the system ID will be dereferenced as
         * a URL.  </p>
         *
         * <p>If the system identifier is a URL, the SAX parser must
         * resolve it fully before reporting it to the application.</p>
         *
         * @param publicId The public identifier of the external entity
         *        being referenced, or null if none was supplied.
         * @param systemId The system identifier of the external entity
         *        being referenced.
         * @return An InputSource object describing the new input source,
         *         or null to request that the parser open a regular
         *         URI connection to the system identifier.
         * @exception org.xml.sax.SAXException Any SAX exception, possibly
         *            wrapping another exception.
         * @exception java.io.IOException A Java-specific IO exception,
         *            possibly the result of creating a new InputStream
         *            or Reader for the InputSource.
         * @see org.xml.sax.InputSource
         *******************************************************************************/

        public InputStream resolveEntity(Ch[] publicId, Ch[] systemId);

}

/*******************************************************************************
 * Basic interface for SAX error handlers.
 *
 * <p>If a SAX application needs to implement customized error
 * handling, it must implement this interface and then register an
 * instance with the XML reader using the
 * {@link org.xml.sax.XMLReader#setErrorHandler setErrorHandler}
 * method.  The parser will then report all errors and warnings
 * through this interface.</p>
 *
 * <p><strong>WARNING:</strong> If an application does <em>not</em>
 * register an ErrorHandler, XML parsing errors will go unreported,
 * except that <em>SAXParseException</em>s will be thrown for fatal errors.
 * In order to detect validity errors, an ErrorHandler that does something
 * with {@link #error error()} calls must be registered.</p>
 *
 * <p>For XML processing errors, a SAX driver must use this interface 
 * in preference to throwing an exception: it is up to the application 
 * to decide whether to throw an exception for different types of 
 * errors and warnings.  Note, however, that there is no requirement that 
 * the parser continue to report additional errors after a call to 
 * {@link #fatalError fatalError}.  In other words, a SAX driver class 
 * may throw an exception after reporting any fatalError.
 * Also parsers may throw appropriate exceptions for non-XML errors.
 * For example, {@link XMLReader#parse XMLReader.parse()} would throw
 * an IOException for errors accessing entities or the document.</p>
 *
 * @since SAX 1.0
 * @author David Megginson
 * @version 2.0.1+ (sax2r3pre1)
 * @see org.xml.sax.XMLReader#setErrorHandler
 * @see org.xml.sax.SAXParseException 
 *******************************************************************************/
public interface ErrorHandler(Ch = char) {

        /*******************************************************************************
         * Receive notification of a warning.
         *
         * <p>SAX parsers will use this method to report conditions that
         * are not errors or fatal errors as defined by the XML
         * recommendation.  The default behaviour is to take no
         * action.</p>
         *
         * <p>The SAX parser must continue to provide normal parsing events
         * after invoking this method: it should still be possible for the
         * application to process the document through to the end.</p>
         *
         * <p>Filters may use this method to report other, non-XML warnings
         * as well.</p>
         *
         * @param exception The warning information encapsulated in a
         *                  SAX parse exception.
         * @exception org.xml.sax.SAXException Any SAX exception, possibly
         *            wrapping another exception.
         * @see org.xml.sax.SAXParseException 
         *******************************************************************************/
        public void warning(SAXException exception);

        /*******************************************************************************
         * Receive notification of a recoverable error.
         *
         * <p>This corresponds to the definition of "error" in section 1.2
         * of the W3C XML 1.0 Recommendation.  For example, a validating
         * parser would use this callback to report the violation of a
         * validity constraint.  The default behaviour is to take no
         * action.</p>
         *
         * <p>The SAX parser must continue to provide normal parsing
         * events after invoking this method: it should still be possible
         * for the application to process the document through to the end.
         * If the application cannot do so, then the parser should report
         * a fatal error even if the XML recommendation does not require
         * it to do so.</p>
         *
         * <p>Filters may use this method to report other, non-XML errors
         * as well.</p>
         *
         * @param exception The error information encapsulated in a
         *                  SAX parse exception.
         * @exception org.xml.sax.SAXException Any SAX exception, possibly
         *            wrapping another exception.
         * @see org.xml.sax.SAXParseException 
         *******************************************************************************/
        public void error(SAXException exception);

        /*******************************************************************************
         * Receive notification of a non-recoverable error.
         *
         * <p><strong>There is an apparent contradiction between the
         * documentation for this method and the documentation for {@link
         * org.xml.sax.ContentHandler#endDocument}.  Until this ambiguity
         * is resolved in a future major release, clients should make no
         * assumptions about whether endDocument() will or will not be
         * invoked when the parser has reported a fatalError() or thrown
         * an exception.</strong></p>
         *
         * <p>This corresponds to the definition of "fatal error" in
         * section 1.2 of the W3C XML 1.0 Recommendation.  For example, a
         * parser would use this callback to report the violation of a
         * well-formedness constraint.</p>
         *
         * <p>The application must assume that the document is unusable
         * after the parser has invoked this method, and should continue
         * (if at all) only for the sake of collecting additional error
         * messages: in fact, SAX parsers are free to stop reporting any
         * other events once this method has been invoked.</p>
         *
         * @param exception The error information encapsulated in a
         *                  SAX parse exception.  
         * @exception org.xml.sax.SAXException Any SAX exception, possibly
         *            wrapping another exception.
         * @see org.xml.sax.SAXParseException
         *******************************************************************************/
        public void fatalError(SAXException exception);

}

/*******************************************************************************
 * Interface for associating a SAX event with a document location.
 *
 * <p>If a SAX parser provides location information to the SAX
 * application, it does so by implementing this interface and then
 * passing an instance to the application using the content
 * handler's {@link org.xml.sax.ContentHandler#setDocumentLocator
 * setDocumentLocator} method.  The application can use the
 * object to obtain the location of any other SAX event
 * in the XML source document.</p>
 *
 * <p>Note that the results returned by the object will be valid only
 * during the scope of each callback method: the application
 * will receive unpredictable results if it attempts to use the
 * locator at any other time, or after parsing completes.</p>
 *
 * <p>SAX parsers are not required to supply a locator, but they are
 * very strongly encouraged to do so.  If the parser supplies a
 * locator, it must do so before reporting any other document events.
 * If no locator has been set by the time the application receives
 * the {@link org.xml.sax.ContentHandler#startDocument startDocument}
 * event, the application should assume that a locator is not 
 * available.</p>
 *
 * @since SAX 1.0
 * @author David Megginson
 * @version 2.0.1 (sax2r2)
 * @see org.xml.sax.ContentHandler#setDocumentLocator 
 *******************************************************************************/
public interface Locator(Ch = char) {

        /*******************************************************************************
         * Return the public identifier for the current document event.
         *
         * <p>The return value is the public identifier of the document
         * entity or of the external parsed entity in which the markup
         * triggering the event appears.</p>
         *
         * @return A string containing the public identifier, or
         *         null if none is available.
         * @see #getSystemId
         *******************************************************************************/
        public Ch[] getPublicId();

        /*******************************************************************************
         * Return the system identifier for the current document event.
         *
         * <p>The return value is the system identifier of the document
         * entity or of the external parsed entity in which the markup
         * triggering the event appears.</p>
         *
         * <p>If the system identifier is a URL, the parser must resolve it
         * fully before passing it to the application.  For example, a file
         * name must always be provided as a <em>file:...</em> URL, and other
         * kinds of relative URI are also resolved against their bases.</p>
         *
         * @return A string containing the system identifier, or null
         *         if none is available.
         * @see #getPublicId
         *******************************************************************************/
        public Ch[] getSystemId();

        /*******************************************************************************
         * Return the line number where the current document event ends.
         * Lines are delimited by line ends, which are defined in
         * the XML specification.
         *
         * <p><strong>Warning:</strong> The return value from the method
         * is intended only as an approximation for the sake of diagnostics;
         * it is not intended to provide sufficient information
         * to edit the character content of the original XML document.
         * In some cases, these "line" numbers match what would be displayed
         * as columns, and in others they may not match the source text
         * due to internal entity expansion.  </p>
         *
         * <p>The return value is an approximation of the line number
         * in the document entity or external parsed entity where the
         * markup triggering the event appears.</p>
         *
         * <p>If possible, the SAX driver should provide the line position 
         * of the first character after the text associated with the document 
         * event.  The first line is line 1.</p>
         *
         * @return The line number, or -1 if none is available.
         * @see #getColumnNumber
         *******************************************************************************/
        public int getLineNumber();

        /*******************************************************************************
         * Return the column number where the current document event ends.
         * This is one-based number of Java <code>char</code> values since
         * the last line end.
         *
         * <p><strong>Warning:</strong> The return value from the method
         * is intended only as an approximation for the sake of diagnostics;
         * it is not intended to provide sufficient information
         * to edit the character content of the original XML document.
         * For example, when lines contain combining character sequences, wide
         * characters, surrogate pairs, or bi-directional text, the value may
         * not correspond to the column in a text editor's display. </p>
         *
         * <p>The return value is an approximation of the column number
         * in the document entity or external parsed entity where the
         * markup triggering the event appears.</p>
         *
         * <p>If possible, the SAX driver should provide the line position 
         * of the first character after the text associated with the document 
         * event.  The first column in each line is column 1.</p>
         *
         * @return The column number, or -1 if none is available.
         * @see #getLineNumber
         *******************************************************************************/
        public int getColumnNumber();

}


/*******************************************************************************
 * Encapsulate a general SAX error or warning.
 *
 * <p>This class can contain basic error or warning information from
 * either the XML parser or the application: a parser writer or
 * application writer can subclass it to provide additional
 * functionality.  SAX handlers may throw this exception or
 * any exception subclassed from it.</p>
 *
 * <p>If the application needs to pass through other types of
 * exceptions, it must wrap those exceptions in a SAXException
 * or an exception derived from a SAXException.</p>
 *
 * <p>If the parser or application needs to include information about a
 * specific location in an XML document, it should use the
 * {@link org.xml.sax.SAXParseException SAXParseException} subclass.</p>
 *
 * @since SAX 1.0
 * @author David Megginson
 * @version 2.0.1 (sax2r2)
 * @see org.xml.sax.SAXParseException
 *******************************************************************************/
public class SAXException : Exception {

        /*******************************************************************************
         * Create a new SAXException.
         *******************************************************************************/
        public this () {
                super ("", null);
        }

        /*******************************************************************************
         * Create a new SAXException.
         *
         * @param message The error or warning message.
         *******************************************************************************/
        public this (char[] message) {
                super (message, null);
        }

        /*******************************************************************************
         * Create a new SAXException wrapping an existing exception.
         *
         * <p>The existing exception will be embedded in the new
         * one, and its message will become the default message for
         * the SAXException.</p>
         *
         * @param e The exception to be wrapped in a SAXException.
         *******************************************************************************/
        public this (Exception e) {
                super ("", e);
        }

        /*******************************************************************************
         * Create a new SAXException from an existing exception.
         *
         * <p>The existing exception will be embedded in the new
         * one, but the new exception will have its own message.</p>
         *
         * @param message The detail message.
         * @param e The exception to be wrapped in a SAXException.
         *******************************************************************************/
        public this (char[] message, Exception e) {
                super (message, e);
        }

        /*******************************************************************************
         * Return a detail message for this exception.
         *
         * <p>If there is an embedded exception, and if the SAXException
         * has no detail message of its own, this method will return
         * the detail message from the embedded exception.</p>
         *
         * @return The error or warning message.
         *******************************************************************************/
        public char[] message() {
                if (msg is null && next !is null) {
                        return next.msg;
                }
                else {
                        return msg;
                }

        }

}
/*******************************************************************************
 *******************************************************************************/
class SaxParser(Ch = char) : XMLReader!(Ch), Locator!(Ch) {

        private SaxHandler!(Ch) saxHandler;
        private ErrorHandler!(Ch) errorHandler;
        private EntityResolver!(Ch) entityResolver;
        private Ch[] content;
        private Attribute!(Ch)[] attributes;
        private int attrTop = 0;
        private bool hasStartElement = false;
        private Ch[] startElemName;
        private PullParser!(Ch) parser;

        /*******************************************************************************
         *******************************************************************************/
        public this() {
                attributes = new Attribute!(Ch)[255];
        }

        ////////////////////////////////////////////////////////////////////
        // Configuration.
        ////////////////////////////////////////////////////////////////////
        /*******************************************************************************
         * Look up the value of a feature flag.
         *
         * <p>The feature name is any fully-qualified URI.  It is
         * possible for an XMLReader to recognize a feature name but
         * temporarily be unable to return its value.
         * Some feature values may be available only in specific
         * contexts, such as before, during, or after a parse.
         * Also, some feature values may not be programmatically accessible.
         * (In the case of an adapter for SAX1 {@link Parser}, there is no
         * implementation-independent way to expose whether the underlying
         * parser is performing validation, expanding external entities,
         * and so forth.) </p>
         *
         * <p>All XMLReaders are required to recognize the
         * http://xml.org/sax/features/namespaces and the
         * http://xml.org/sax/features/namespace-prefixes feature names.</p>
         *
         * <p>Typical usage is something like this:</p>
         *
         * <pre>
         * XMLReader r = new MySAXDriver();
         *
         *                         // try to activate validation
         * try {
         *   r.setFeature("http://xml.org/sax/features/validation", true);
         * } catch (SAXException e) {
         *   System.err.println("Cannot activate validation."); 
         * }
         *
         *                         // register event handlers
         * r.setContentHandler(new MyContentHandler());
         * r.setErrorHandler(new MyErrorHandler());
         *
         *                         // parse the first document
         * try {
         *   r.parse("http://www.foo.com/mydoc.xml");
         * } catch (IOException e) {
         *   System.err.println("I/O exception reading XML document");
         * } catch (SAXException e) {
         *   System.err.println("XML exception reading document.");
         * }
         * </pre>
         *
         * <p>Implementors are free (and encouraged) to invent their own features,
         * using names built on their own URIs.</p>
         *
         * @param name The feature name, which is a fully-qualified URI.
         * @return The current value of the feature (true or false).
         * @exception org.xml.sax.SAXNotRecognizedException If the feature
         *            value can't be assigned or retrieved.
         * @exception org.xml.sax.SAXNotSupportedException When the
         *            XMLReader recognizes the feature name but 
         *            cannot determine its value at this time.
         * @see #setFeature
         *******************************************************************************/
        public bool getFeature(Ch[] name) {
                return false;
        }

        /*******************************************************************************
         * Set the value of a feature flag.
         *
         * <p>The feature name is any fully-qualified URI.  It is
         * possible for an XMLReader to expose a feature value but
         * to be unable to change the current value.
         * Some feature values may be immutable or mutable only 
         * in specific contexts, such as before, during, or after 
         * a parse.</p>
         *
         * <p>All XMLReaders are required to support setting
         * http://xml.org/sax/features/namespaces to true and
         * http://xml.org/sax/features/namespace-prefixes to false.</p>
         *
         * @param name The feature name, which is a fully-qualified URI.
         * @param value The requested value of the feature (true or false).
         * @exception org.xml.sax.SAXNotRecognizedException If the feature
         *            value can't be assigned or retrieved.
         * @exception org.xml.sax.SAXNotSupportedException When the
         *            XMLReader recognizes the feature name but 
         *            cannot set the requested value.
         * @see #getFeature
         *******************************************************************************/
        public void setFeature(Ch[] name, bool value) {

        }

        /*******************************************************************************
         * Look up the value of a property.
         *
         * <p>The property name is any fully-qualified URI.  It is
         * possible for an XMLReader to recognize a property name but
         * temporarily be unable to return its value.
         * Some property values may be available only in specific
         * contexts, such as before, during, or after a parse.</p>
         *
         * <p>XMLReaders are not required to recognize any specific
         * property names, though an initial core set is documented for
         * SAX2.</p>
         *
         * <p>Implementors are free (and encouraged) to invent their own properties,
         * using names built on their own URIs.</p>
         *
         * @param name The property name, which is a fully-qualified URI.
         * @return The current value of the property.
         * @exception org.xml.sax.SAXNotRecognizedException If the property
         *            value can't be assigned or retrieved.
         * @exception org.xml.sax.SAXNotSupportedException When the
         *            XMLReader recognizes the property name but 
         *            cannot determine its value at this time.
         * @see #setProperty
         *******************************************************************************/
        public Object getProperty(Ch[] name) {
                return null;
        }

        /*******************************************************************************
         * Set the value of a property.
         *
         * <p>The property name is any fully-qualified URI.  It is
         * possible for an XMLReader to recognize a property name but
         * to be unable to change the current value.
         * Some property values may be immutable or mutable only 
         * in specific contexts, such as before, during, or after 
         * a parse.</p>
         *
         * <p>XMLReaders are not required to recognize setting
         * any specific property names, though a core set is defined by 
         * SAX2.</p>
         *
         * <p>This method is also the standard mechanism for setting
         * extended handlers.</p>
         *
         * @param name The property name, which is a fully-qualified URI.
         * @param value The requested value for the property.
         * @exception org.xml.sax.SAXNotRecognizedException If the property
         *            value can't be assigned or retrieved.
         * @exception org.xml.sax.SAXNotSupportedException When the
         *            XMLReader recognizes the property name but 
         *            cannot set the requested value.
         *******************************************************************************/
        public void setProperty(Ch[] name, Object value) {

        }

        ////////////////////////////////////////////////////////////////////
        // Event handlers.
        ////////////////////////////////////////////////////////////////////
        /*******************************************************************************
         * Allow an application to register an entity resolver.
         *
         * <p>If the application does not register an entity resolver,
         * the XMLReader will perform its own default resolution.</p>
         *
         * <p>Applications may register a new or different resolver in the
         * middle of a parse, and the SAX parser must begin using the new
         * resolver immediately.</p>
         *
         * @param resolver The entity resolver.
         * @see #getEntityResolver
         *******************************************************************************/
        public void setEntityResolver(EntityResolver!(Ch) resolver) {
                entityResolver = resolver;
        }

        /*******************************************************************************
         * Return the current entity resolver.
         *
         * @return The current entity resolver, or null if none
         *         has been registered.
         * @see #setEntityResolver
         *******************************************************************************/
        public EntityResolver!(Ch) getEntityResolver() {
                return entityResolver;
        }

        /*******************************************************************************
         * Allow an application to register a content event handler.
         *
         * <p>If the application does not register a content handler, all
         * content events reported by the SAX parser will be silently
         * ignored.</p>
         *
         * <p>Applications may register a new or different handler in the
         * middle of a parse, and the SAX parser must begin using the new
         * handler immediately.</p>
         *
         * @param handler The content handler.
         * @see #getContentHandler
         *******************************************************************************/
        public void setSaxHandler(SaxHandler!(Ch) handler) {
                saxHandler = handler;
        }

        /*******************************************************************************
         * Return the current content handler.
         *
         * @return The current content handler, or null if none
         *         has been registered.
         * @see #setContentHandler
         *******************************************************************************/
        public SaxHandler!(Ch) getSaxHandler() {
                return saxHandler;
        }

        /*******************************************************************************
         * Allow an application to register an error event handler.
         *
         * <p>If the application does not register an error handler, all
         * error events reported by the SAX parser will be silently
         * ignored; however, normal processing may not continue.  It is
         * highly recommended that all SAX applications implement an
         * error handler to avoid unexpected bugs.</p>
         *
         * <p>Applications may register a new or different handler in the
         * middle of a parse, and the SAX parser must begin using the new
         * handler immediately.</p>
         *
         * @param handler The error handler.
         * @see #getErrorHandler
         *******************************************************************************/
        public void setErrorHandler(ErrorHandler!(Ch) handler) {
                errorHandler = handler;
        }

        /*******************************************************************************
         * Return the current error handler.
         *
         * @return The current error handler, or null if none
         *         has been registered.
         * @see #setErrorHandler
         *******************************************************************************/
        public ErrorHandler!(Ch) getErrorHandler() {
                return errorHandler;
        }

        ////////////////////////////////////////////////////////////////////
        // Parsing.
        ////////////////////////////////////////////////////////////////////
        /*******************************************************************************
         * Parse an XML document.
         *
         * <p>The application can use this method to instruct the XML
         * reader to begin parsing an XML document from any valid input
         * source (a character stream, a byte stream, or a URI).</p>
         *
         * <p>Applications may not invoke this method while a parse is in
         * progress (they should create a new XMLReader instead for each
         * nested XML document).  Once a parse is complete, an
         * application may reuse the same XMLReader object, possibly with a
         * different input source.
         * Configuration of the XMLReader object (such as handler bindings and
         * values established for feature flags and properties) is unchanged
         * by completion of a parse, unless the definition of that aspect of
         * the configuration explicitly specifies other behavior.
         * (For example, feature flags or properties exposing
         * characteristics of the document being parsed.)
         * </p>
         *
         * <p>During the parse, the XMLReader will provide information
         * about the XML document through the registered event
         * handlers.</p>
         *
         * <p>This method is synchronous: it will not return until parsing
         * has ended.  If a client application wants to terminate 
         * parsing early, it should throw an exception.</p>
         *
         * @param input The input source for the top-level of the
         *        XML document.
         * @exception org.xml.sax.SAXException Any SAX exception, possibly
         *            wrapping another exception.
         * @exception java.io.IOException An IO exception from the parser,
         *            possibly from a byte stream or character stream
         *            supplied by the application.
         * @see org.xml.sax.InputSource
         * @see #parse(java.lang.String)
         * @see #setEntityResolver
         * @see #setContentHandler
         * @see #setErrorHandler 
         *******************************************************************************/
        public void parse(InputStream input) {
                //TODO turn into a Ch[] buffer
                doParse();
        }

        /*******************************************************************************
         * Parse an XML document from a system identifier (URI).
         *
         * <p>This method is a shortcut for the common case of reading a
         * document from a system identifier.  It is the exact
         * equivalent of the following:</p>
         *
         * <pre>
         * parse(new InputSource(systemId));
         * </pre>
         *
         * <p>If the system identifier is a URL, it must be fully resolved
         * by the application before it is passed to the parser.</p>
         *
         * @param systemId The system identifier (URI).
         * @exception org.xml.sax.SAXException Any SAX exception, possibly
         *            wrapping another exception.
         * @exception java.io.IOException An IO exception from the parser,
         *            possibly from a byte stream or character stream
         *            supplied by the application.
         * @see #parse(org.xml.sax.InputSource)
         *******************************************************************************/
        public void parseUrl(Ch[] systemId) {
                //TODO turn url into a Ch[] buffer            
                doParse();
        }

        /*******************************************************************************
         * Parse an XML document from a character array.
         *
         * @param content The actual document content.
         * @exception org.xml.sax.SAXException Any SAX exception, possibly
         *            wrapping another exception.
         * @exception java.io.IOException An IO exception from the parser,
         *            possibly from a byte stream or character stream
         *            supplied by the application.
         * @see #parse(org.xml.sax.InputSource)
         *******************************************************************************/
        public void parse(Ch[] content) {
                this.content = content;
                doParse();
        }

        /*******************************************************************************
         *******************************************************************************/
        public void parse() {
                doParse();
        }

        /*******************************************************************************
         *******************************************************************************/
        public void setContent(Ch[] content) {
                parser = new PullParser!(Ch)(content);
        }

        /*******************************************************************************
         *******************************************************************************/
        public void reset() {
                parser.reset();
        }

        /*******************************************************************************
         *         The meat of the class.  Turn the pull parser's nodes into SAX
         *         events and send out to the SaxHandler.
         *******************************************************************************/
        private void doParse() {
                saxHandler.setDocumentLocator(this);
                saxHandler.startDocument();
                while (true) {
                        switch (parser.next) {
                        case XmlTokenType.StartElement :
                                if (hasStartElement) {
                                        saxHandler.startElement(null, startElemName, null, attributes[0..attrTop]);
                                        hasStartElement = false;
                                        attrTop = 0;
                                }               
                                startElemName = parser.localName;
                                hasStartElement = true;
                                break;
                        case XmlTokenType.Attribute :
                                attributes[attrTop].localName = parser.localName;
                                attributes[attrTop].value = parser.rawValue;
                                attrTop++;
                                break;
                        case XmlTokenType.EndElement :
                        case XmlTokenType.EndEmptyElement :
                                if (hasStartElement) {
                                        saxHandler.startElement(null, startElemName, null, attributes[0..attrTop]);
                                        hasStartElement = false;
                                        attrTop = 0;
                                }               
                                saxHandler.endElement(null, parser.localName, null);
                                break;
                        case XmlTokenType.Data :
                                if (hasStartElement) {
                                        saxHandler.startElement(null, startElemName, null, attributes[0..attrTop]);
                                        hasStartElement = false;
                                        attrTop = 0;
                                }               
                                saxHandler.characters(parser.rawValue);
                                break;
                        case XmlTokenType.Comment :
                        case XmlTokenType.CData :
                        case XmlTokenType.Doctype :
                        case XmlTokenType.PI :
                        case XmlTokenType.None :
                                if (hasStartElement) {
                                        saxHandler.startElement(null, startElemName, null, attributes[0..attrTop]);
                                        hasStartElement = false;
                                        attrTop = 0;
                                }               
                                break;

                        case XmlTokenType.Done:
                             goto foo;

                        default:
                                throw new SAXException("unknown parser token type");
                        }
                } 
foo:                              
                saxHandler.endDocument();
        }

        /*******************************************************************************
         * Return the public identifier for the current document event.
         *
         * <p>The return value is the public identifier of the document
         * entity or of the external parsed entity in which the markup
         * triggering the event appears.</p>
         *
         * @return A string containing the public identifier, or
         *         null if none is available.
         * @see #getSystemId
         *******************************************************************************/
        public Ch[] getPublicId() {
                return null;
        }

        /*******************************************************************************
         * Return the system identifier for the current document event.
         *
         * <p>The return value is the system identifier of the document
         * entity or of the external parsed entity in which the markup
         * triggering the event appears.</p>
         *
         * <p>If the system identifier is a URL, the parser must resolve it
         * fully before passing it to the application.  For example, a file
         * name must always be provided as a <em>file:...</em> URL, and other
         * kinds of relative URI are also resolved against their bases.</p>
         *
         * @return A string containing the system identifier, or null
         *         if none is available.
         * @see #getPublicId
         *******************************************************************************/
        public Ch[] getSystemId() {
                return null;  
        }

        /*******************************************************************************
         * Return the line number where the current document event ends.
         * Lines are delimited by line ends, which are defined in
         * the XML specification.
         *
         * <p><strong>Warning:</strong> The return value from the method
         * is intended only as an approximation for the sake of diagnostics;
         * it is not intended to provide sufficient information
         * to edit the character content of the original XML document.
         * In some cases, these "line" numbers match what would be displayed
         * as columns, and in others they may not match the source text
         * due to internal entity expansion.  </p>
         *
         * <p>The return value is an approximation of the line number
         * in the document entity or external parsed entity where the
         * markup triggering the event appears.</p>
         *
         * <p>If possible, the SAX driver should provide the line position 
         * of the first character after the text associated with the document 
         * event.  The first line is line 1.</p>
         *
         * @return The line number, or -1 if none is available.
         * @see #getColumnNumber
         *******************************************************************************/
        public int getLineNumber() {
                return 0;
        }

        /*******************************************************************************
         * Return the column number where the current document event ends.
         * This is one-based number of Java <code>char</code> values since
         * the last line end.
         *
         * <p><strong>Warning:</strong> The return value from the method
         * is intended only as an approximation for the sake of diagnostics;
         * it is not intended to provide sufficient information
         * to edit the character content of the original XML document.
         * For example, when lines contain combining character sequences, wide
         * characters, surrogate pairs, or bi-directional text, the value may
         * not correspond to the column in a text editor's display. </p>
         *
         * <p>The return value is an approximation of the column number
         * in the document entity or external parsed entity where the
         * markup triggering the event appears.</p>
         *
         * <p>If possible, the SAX driver should provide the line position 
         * of the first character after the text associated with the document 
         * event.  The first column in each line is column 1.</p>
         *
         * @return The column number, or -1 if none is available.
         * @see #getLineNumber
         *******************************************************************************/
        public int getColumnNumber() {
                return 0;
        }


}


/*******************************************************************************
 * Interface for an XML filter.
 *
 * <p>An XML filter is like an XML reader, except that it obtains its
 * events from another XML reader rather than a primary source like
 * an XML document or database.  Filters can modify a stream of
 * events as they pass on to the final application.</p>
 *
 * <p>The XMLFilterImpl helper class provides a convenient base
 * for creating SAX2 filters, by passing on all {@link org.xml.sax.EntityResolver
 * EntityResolver}, {@link org.xml.sax.DTDHandler DTDHandler},
 * {@link org.xml.sax.ContentHandler ContentHandler} and {@link org.xml.sax.ErrorHandler
 * ErrorHandler} events automatically.</p>
 *
 * @since SAX 2.0
 * @author David Megginson
 * @version 2.0.1 (sax2r2)
 * @see org.xml.sax.helpers.XMLFilterImpl
 *******************************************************************************/
public abstract class XMLFilter(Ch = char) : XMLReader {

        /*******************************************************************************
         * Set the parent reader.
         *
         * <p>This method allows the application to link the filter to
         * a parent reader (which may be another filter).  The argument
         * may not be null.</p>
         *
         * @param parent The parent reader.
         *******************************************************************************/
        public void setParent(XMLReader parent){
                //do nothing
        }

        /*******************************************************************************
         * Get the parent reader.
         *
         * <p>This method allows the application to query the parent
         * reader (which may be another filter).  It is generally a
         * bad idea to perform any operations on the parent reader
         * directly: they should all pass through this filter.</p>
         *
         * @return The parent filter, or null if none has been set.
         *******************************************************************************/
        public XMLReader getParent() {
                return null;
        }

}

/*******************************************************************************
 * Base class for deriving an XML filter.
 *
 * <p>This class is designed to sit between an {@link org.xml.sax.XMLReader
 * XMLReader} and the client application's event handlers.  By default, it
 * does nothing but pass requests up to the reader and events
 * on to the handlers unmodified, but subclasses can override
 * specific methods to modify the event stream or the configuration
 * requests as they pass through.</p>
 *
 * @since SAX 2.0
 * @author David Megginson
 * @version 2.0.1 (sax2r2)
 * @see org.xml.sax.XMLFilter
 * @see org.xml.sax.XMLReader
 * @see org.xml.sax.EntityResolver
 * @see org.xml.sax.ContentHandler
 * @see org.xml.sax.ErrorHandler
 *******************************************************************************/
public class XMLFilterImpl(Ch = char) : SaxHandler, XMLFilter, EntityResolver, ErrorHandler {

        ////////////////////////////////////////////////////////////////////
        // Constructors.
        ////////////////////////////////////////////////////////////////////
        /*******************************************************************************
         * Construct an empty XML filter, with no parent.
         *
         * <p>This filter will have no parent: you must assign a parent
         * before you start a parse or do any configuration with
         * setFeature or setProperty, unless you use this as a pure event
         * consumer rather than as an {@link XMLReader}.</p>
         *
         * @see org.xml.sax.XMLReader#setFeature
         * @see org.xml.sax.XMLReader#setProperty
         * @see #setParent
         *******************************************************************************/
        public this () {

        }

        /*******************************************************************************
         * Construct an XML filter with the specified parent.
         *
         * @see #setParent
         * @see #getParent
         *******************************************************************************/
        public this (XMLReader parent) {
                setParent(parent);
        }

        ////////////////////////////////////////////////////////////////////
        // Implementation of org.xml.sax.XMLFilter.
        ////////////////////////////////////////////////////////////////////
        /*******************************************************************************
         * Set the parent reader.
         *
         * <p>This is the {@link org.xml.sax.XMLReader XMLReader} from which 
         * this filter will obtain its events and to which it will pass its 
         * configuration requests.  The parent may itself be another filter.</p>
         *
         * <p>If there is no parent reader set, any attempt to parse
         * or to set or get a feature or property will fail.</p>
         *
         * @param parent The parent XML reader.
         * @see #getParent
         *******************************************************************************/
        public void setParent(XMLReader parent) {
                this.parent = parent;
        }

        /*******************************************************************************
         * Get the parent reader.
         *
         * @return The parent XML reader, or null if none is set.
         * @see #setParent
         *******************************************************************************/
        public XMLReader getParent() {
                return parent;
        }

        ////////////////////////////////////////////////////////////////////
        // Implementation of org.xml.sax.XMLReader.
        ////////////////////////////////////////////////////////////////////
        /*******************************************************************************
         * Set the value of a feature.
         *
         * <p>This will always fail if the parent is null.</p>
         *
         * @param name The feature name.
         * @param value The requested feature value.
         * @exception org.xml.sax.SAXNotRecognizedException If the feature
         *            value can't be assigned or retrieved from the parent.
         * @exception org.xml.sax.SAXNotSupportedException When the
         *            parent recognizes the feature name but 
         *            cannot set the requested value.
         *******************************************************************************/
        public void setFeature(Ch[] name, bool value) {
                if (parent !is null) {
                        parent.setFeature(name, value);
                }
                else {
                        throw new SAXException("Feature not recognized: " ~ name);
                }

        }

        /*******************************************************************************
         * Look up the value of a feature.
         *
         * <p>This will always fail if the parent is null.</p>
         *
         * @param name The feature name.
         * @return The current value of the feature.
         * @exception org.xml.sax.SAXNotRecognizedException If the feature
         *            value can't be assigned or retrieved from the parent.
         * @exception org.xml.sax.SAXNotSupportedException When the
         *            parent recognizes the feature name but 
         *            cannot determine its value at this time.
         *******************************************************************************/
        public bool getFeature(Ch[] name) {
                if (parent !is null) {
                        return parent.getFeature(name);
                }
                else {
                        throw new SAXException("Feature not recognized: " ~ name);
                }

        }

        /*******************************************************************************
         * Set the value of a property.
         *
         * <p>This will always fail if the parent is null.</p>
         *
         * @param name The property name.
         * @param value The requested property value.
         * @exception org.xml.sax.SAXNotRecognizedException If the property
         *            value can't be assigned or retrieved from the parent.
         * @exception org.xml.sax.SAXNotSupportedException When the
         *            parent recognizes the property name but 
         *            cannot set the requested value.
         *******************************************************************************/
        public void setProperty(Ch[] name, Object value) {
                if (parent !is null) {
                        parent.setProperty(name, value);
                }
                else {
                        throw new SAXException("Property not recognized: " ~ name);
                }

        }

        /*******************************************************************************
         * Look up the value of a property.
         *
         * @param name The property name.
         * @return The current value of the property.
         * @exception org.xml.sax.SAXNotRecognizedException If the property
         *            value can't be assigned or retrieved from the parent.
         * @exception org.xml.sax.SAXNotSupportedException When the
         *            parent recognizes the property name but 
         *            cannot determine its value at this time.
         *******************************************************************************/
        public Object getProperty(Ch[] name) {
                if (parent !is null) {
                        return parent.getProperty(name);
                }
                else {
                        throw new SAXException("Property not recognized: " ~ name);
                }

        }

        /*******************************************************************************
         * Set the entity resolver.
         *
         * @param resolver The new entity resolver.
         *******************************************************************************/
        public void setEntityResolver(EntityResolver resolver) {
                entityResolver = resolver;
        }

        /**
         * Get the current entity resolver.
         *
         * @return The current entity resolver, or null if none was set.
         *******************************************************************************/
        public EntityResolver getEntityResolver() {
                return entityResolver;
        }

        /*******************************************************************************
         * Set the content event handler.
         *
         * @param handler the new content handler
         *******************************************************************************/
        public void setSaxHandler(SaxHandler handler) {
                saxHandler = handler;
        }

        /*******************************************************************************
         * Get the content event handler.
         *
         * @return The current content handler, or null if none was set.
         *******************************************************************************/
        public SaxHandler getSaxHandler() {
                return saxHandler;
        }

        /*******************************************************************************
         * Set the error event handler.
         *
         * @param handler the new error handler
         *******************************************************************************/
        public void setErrorHandler(ErrorHandler handler) {
                errorHandler = handler;
        }

        /*******************************************************************************
         * Get the current error event handler.
         *
         * @return The current error handler, or null if none was set.
         *******************************************************************************/
        public ErrorHandler getErrorHandler() {
                return errorHandler;
        }

        /*******************************************************************************
         * Parse a document.
         *
         * @param input The input source for the document entity.
         * @exception org.xml.sax.SAXException Any SAX exception, possibly
         *            wrapping another exception.
         * @exception java.io.IOException An IO exception from the parser,
         *            possibly from a byte stream or character stream
         *            supplied by the application.
         *******************************************************************************/
        public void parse(InputStream input) {
                setupParse();
                parent.parse(input);
        }

        /*******************************************************************************
         * Parse the given content.
         *
         * @param input The input source for the document entity.
         * @exception org.xml.sax.SAXException Any SAX exception, possibly
         *            wrapping another exception.
         * @exception java.io.IOException An IO exception from the parser,
         *            possibly from a byte stream or character stream
         *            supplied by the application.
         *******************************************************************************/
        public void parse(Ch[] content) {
                //TODO FIXME - create a buffer of this content as the input stream, and then parse.
                //setupParse();
                //parent.parse(input);
        }

        public void parse() {}
        public void setContent(Ch[] content) {}


        /*******************************************************************************
         * Parse a document.
         *
         * @param systemId The system identifier as a fully-qualified URI.
         * @exception org.xml.sax.SAXException Any SAX exception, possibly
         *            wrapping another exception.
         * @exception java.io.IOException An IO exception from the parser,
         *            possibly from a byte stream or character stream
         *            supplied by the application.
         *******************************************************************************/
        public void parseUrl(Ch[] systemId) {
                //TODO FIXME
                //parse(new InputSource(systemId));
        }

        ////////////////////////////////////////////////////////////////////
        // Implementation of org.xml.sax.EntityResolver.
        ////////////////////////////////////////////////////////////////////
        /*******************************************************************************
         * Filter an external entity resolution.
         *
         * @param publicId The entity's public identifier, or null.
         * @param systemId The entity's system identifier.
         * @return A new InputSource or null for the default.
         * @exception org.xml.sax.SAXException The client may throw
         *            an exception during processing.
         * @exception java.io.IOException The client may throw an
         *            I/O-related exception while obtaining the
         *            new InputSource.
         *******************************************************************************/
        public InputStream resolveEntity(Ch[] publicId, Ch[] systemId) {
                if (entityResolver !is null) {
                        return entityResolver.resolveEntity(publicId, systemId);
                }
                else {
                        return null;
                }

        }

        ////////////////////////////////////////////////////////////////////
        // Implementation of org.xml.sax.ContentHandler.
        ////////////////////////////////////////////////////////////////////
        /*******************************************************************************
         * Filter a new document locator event.
         *
         * @param locator The document locator.
         *******************************************************************************/
        public void setDocumentLocator(Locator locator) {
                this.locator = locator;
                if (saxHandler !is null) {
                        saxHandler.setDocumentLocator(locator);
                }

        }

        /*******************************************************************************
         * Filter a start document event.
         *
         * @exception org.xml.sax.SAXException The client may throw
         *            an exception during processing.
         *******************************************************************************/
        public void startDocument() {
                if (saxHandler !is null) {
                        saxHandler.startDocument();
                }

        }

        /*******************************************************************************
         * Filter an end document event.
         *
         * @exception org.xml.sax.SAXException The client may throw
         *            an exception during processing.
         *******************************************************************************/
        public void endDocument() {
                if (saxHandler !is null) {
                        saxHandler.endDocument();
                }

        }

        /*******************************************************************************
         * Filter a start Namespace prefix mapping event.
         *
         * @param prefix The Namespace prefix.
         * @param uri The Namespace URI.
         * @exception org.xml.sax.SAXException The client may throw
         *            an exception during processing.
         *******************************************************************************/
        public void startPrefixMapping(Ch[] prefix, Ch[] uri) {
                if (saxHandler !is null) {
                        saxHandler.startPrefixMapping(prefix, uri);
                }

        }

        /*******************************************************************************
         * Filter an end Namespace prefix mapping event.
         *
         * @param prefix The Namespace prefix.
         * @exception org.xml.sax.SAXException The client may throw
         *            an exception during processing.
         *******************************************************************************/
        public void endPrefixMapping(Ch[] prefix) {
                if (saxHandler !is null) {
                        saxHandler.endPrefixMapping(prefix);
                }

        }

        /*******************************************************************************
         * Filter a start element event.
         *
         * @param uri The element's Namespace URI, or the empty string.
         * @param localName The element's local name, or the empty string.
         * @param qName The element's qualified (prefixed) name, or the empty
         *        string.
         * @param atts The element's attributes.
         * @exception org.xml.sax.SAXException The client may throw
         *            an exception during processing.
         *******************************************************************************/
        public void startElement(Ch[] uri, Ch[] localName, Ch[] qName, Attribute[] atts) {
                if (saxHandler !is null) {
                        saxHandler.startElement(uri, localName, qName, atts);
                }    

        }

        /*******************************************************************************
         * Filter an end element event.
         *
         * @param uri The element's Namespace URI, or the empty string.
         * @param localName The element's local name, or the empty string.
         * @param qName The element's qualified (prefixed) name, or the empty
         *        string.
         * @exception org.xml.sax.SAXException The client may throw
         *            an exception during processing.
         *******************************************************************************/
        public void endElement(Ch[] uri, Ch[] localName, Ch[] qName) {
                if (saxHandler !is null) {
                        saxHandler.endElement(uri, localName, qName);
                }

        }

        /*******************************************************************************
         * Filter a character data event.
         *
         * @param ch An array of characters.
         * @exception org.xml.sax.SAXException The client may throw
         *            an exception during processing.
         *******************************************************************************/
        public void characters(Ch ch[]) {
                if (saxHandler !is null) {
                        saxHandler.characters(ch);
                }

        }

        /*******************************************************************************
         * Filter an ignorable whitespace event.
         *
         * @param ch An array of characters.
         * @param start The starting position in the array.
         * @param length The number of characters to use from the array.
         * @exception org.xml.sax.SAXException The client may throw
         *            an exception during processing.
         *******************************************************************************/
        public void ignorableWhitespace(Ch ch[]) {
                if (saxHandler !is null) {
                        saxHandler.ignorableWhitespace(ch);
                }

        }

        /*******************************************************************************
         * Filter a processing instruction event.
         *
         * @param target The processing instruction target.
         * @param data The text following the target.
         * @exception org.xml.sax.SAXException The client may throw
         *            an exception during processing.
         *******************************************************************************/
        public void processingInstruction(Ch[] target, Ch[] data) {
                if (saxHandler !is null) {
                        saxHandler.processingInstruction(target, data);
                }

        }

        /*******************************************************************************
         * Filter a skipped entity event.
         *
         * @param name The name of the skipped entity.
         * @exception org.xml.sax.SAXException The client may throw
         *            an exception during processing.
         *******************************************************************************/
        public void skippedEntity(Ch[] name) {
                if (saxHandler !is null) {
                        saxHandler.skippedEntity(name);
                }

        }

        ////////////////////////////////////////////////////////////////////
        // Implementation of org.xml.sax.ErrorHandler.
        ////////////////////////////////////////////////////////////////////
        /*******************************************************************************
         * Filter a warning event.
         *
         * @param e The warning as an exception.
         * @exception org.xml.sax.SAXException The client may throw
         *            an exception during processing.
         *******************************************************************************/
        public void warning(SAXException e) {
                if (errorHandler !is null) {
                        errorHandler.warning(e);
                }

        }

        /*******************************************************************************
         * Filter an error event.
         *
         * @param e The error as an exception.
         * @exception org.xml.sax.SAXException The client may throw
         *            an exception during processing.
         *******************************************************************************/
        public void error(SAXException e) {
                if (errorHandler !is null) {
                        errorHandler.error(e);
                }

        }

        /*******************************************************************************
         * Filter a fatal error event.
         *
         * @param e The error as an exception.
         * @exception org.xml.sax.SAXException The client may throw
         *            an exception during processing.
         *******************************************************************************/
        public void fatalError(SAXException e) {
                if (errorHandler !is null) {
                        errorHandler.fatalError(e);
                }

        }

        ////////////////////////////////////////////////////////////////////
        // Internal methods.
        ////////////////////////////////////////////////////////////////////
        /*******************************************************************************
         * Set up before a parse.
         *
         * <p>Before every parse, check whether the parent is
         * non-null, and re-register the filter for all of the 
         * events.</p>
         *******************************************************************************/
        private void setupParse() {
                if (parent is null) {
                        throw new Exception("No parent for filter");
                }
                parent.setEntityResolver(this);
                parent.setSaxHandler(this);
                parent.setErrorHandler(this);
        }

        ////////////////////////////////////////////////////////////////////
        // Internal state.
        ////////////////////////////////////////////////////////////////////
        private XMLReader parent = null;

        private Locator locator = null;

        private EntityResolver entityResolver = null;

        private SaxHandler saxHandler = null;

        private ErrorHandler errorHandler = null;

}



/*******************************************************************************
 * Interface for reading an XML document using callbacks.
 *
 * <p>XMLReader is the interface that an XML parser's SAX2 driver must
 * implement.  This interface allows an application to set and
 * query features and properties in the parser, to register
 * event handlers for document processing, and to initiate
 * a document parse.</p>
 *
 * <p>All SAX interfaces are assumed to be synchronous: the
 * {@link #parse parse} methods must not return until parsing
 * is complete, and readers must wait for an event-handler callback
 * to return before reporting the next event.</p>
 *
 * <p>This interface replaces the (now deprecated) SAX 1.0 {@link
 * org.xml.sax.Parser Parser} interface.  The XMLReader interface
 * contains two important enhancements over the old Parser
 * interface (as well as some minor ones):</p>
 *
 * <ol>
 * <li>it adds a standard way to query and set features and 
 *  properties; and</li>
 * <li>it adds Namespace support, which is required for many
 *  higher-level XML standards.</li>
 * </ol>
 *
 * <p>There are adapters available to convert a SAX1 Parser to
 * a SAX2 XMLReader and vice-versa.</p>
 *
 * @since SAX 2.0
 * @author David Megginson
 * @version 2.0.1+ (sax2r3pre1)
 * @see org.xml.sax.XMLFilter
 * @see org.xml.sax.helpers.ParserAdapter
 * @see org.xml.sax.helpers.XMLReaderAdapter 
 *******************************************************************************/
public interface XMLReader(Ch = char) {

        ////////////////////////////////////////////////////////////////////
        // Configuration.
        ////////////////////////////////////////////////////////////////////
        /*******************************************************************************
         * Look up the value of a feature flag.
         *
         * <p>The feature name is any fully-qualified URI.  It is
         * possible for an XMLReader to recognize a feature name but
         * temporarily be unable to return its value.
         * Some feature values may be available only in specific
         * contexts, such as before, during, or after a parse.
         * Also, some feature values may not be programmatically accessible.
         * (In the case of an adapter for SAX1 {@link Parser}, there is no
         * implementation-independent way to expose whether the underlying
         * parser is performing validation, expanding external entities,
         * and so forth.) </p>
         *
         * <p>All XMLReaders are required to recognize the
         * http://xml.org/sax/features/namespaces and the
         * http://xml.org/sax/features/namespace-prefixes feature names.</p>
         *
         * <p>Typical usage is something like this:</p>
         *
         * <pre>
         * XMLReader r = new MySAXDriver();
         *
         *                         // try to activate validation
         * try {
         *   r.setFeature("http://xml.org/sax/features/validation", true);
         * } catch (SAXException e) {
         *   System.err.println("Cannot activate validation."); 
         * }
         *
         *                         // register event handlers
         * r.setContentHandler(new MyContentHandler());
         * r.setErrorHandler(new MyErrorHandler());
         *
         *                         // parse the first document
         * try {
         *   r.parse("http://www.foo.com/mydoc.xml");
         * } catch (IOException e) {
         *   System.err.println("I/O exception reading XML document");
         * } catch (SAXException e) {
         *   System.err.println("XML exception reading document.");
         * }
         * </pre>
         *
         * <p>Implementors are free (and encouraged) to invent their own features,
         * using names built on their own URIs.</p>
         *
         * @param name The feature name, which is a fully-qualified URI.
         * @return The current value of the feature (true or false).
         * @exception org.xml.sax.SAXNotRecognizedException If the feature
         *            value can't be assigned or retrieved.
         * @exception org.xml.sax.SAXNotSupportedException When the
         *            XMLReader recognizes the feature name but 
         *            cannot determine its value at this time.
         * @see #setFeature
         *******************************************************************************/
        public bool getFeature(Ch[] name);

        /*******************************************************************************
         * Set the value of a feature flag.
         *
         * <p>The feature name is any fully-qualified URI.  It is
         * possible for an XMLReader to expose a feature value but
         * to be unable to change the current value.
         * Some feature values may be immutable or mutable only 
         * in specific contexts, such as before, during, or after 
         * a parse.</p>
         *
         * <p>All XMLReaders are required to support setting
         * http://xml.org/sax/features/namespaces to true and
         * http://xml.org/sax/features/namespace-prefixes to false.</p>
         *
         * @param name The feature name, which is a fully-qualified URI.
         * @param value The requested value of the feature (true or false).
         * @exception org.xml.sax.SAXNotRecognizedException If the feature
         *            value can't be assigned or retrieved.
         * @exception org.xml.sax.SAXNotSupportedException When the
         *            XMLReader recognizes the feature name but 
         *            cannot set the requested value.
         * @see #getFeature
         *******************************************************************************/
        public void setFeature(Ch[] name, bool value);

        /*******************************************************************************
         * Look up the value of a property.
         *
         * <p>The property name is any fully-qualified URI.  It is
         * possible for an XMLReader to recognize a property name but
         * temporarily be unable to return its value.
         * Some property values may be available only in specific
         * contexts, such as before, during, or after a parse.</p>
         *
         * <p>XMLReaders are not required to recognize any specific
         * property names, though an initial core set is documented for
         * SAX2.</p>
         *
         * <p>Implementors are free (and encouraged) to invent their own properties,
         * using names built on their own URIs.</p>
         *
         * @param name The property name, which is a fully-qualified URI.
         * @return The current value of the property.
         * @exception org.xml.sax.SAXNotRecognizedException If the property
         *            value can't be assigned or retrieved.
         * @exception org.xml.sax.SAXNotSupportedException When the
         *            XMLReader recognizes the property name but 
         *            cannot determine its value at this time.
         * @see #setProperty
         *******************************************************************************/
        public Object getProperty(Ch[] name);

        /*******************************************************************************
         * Set the value of a property.
         *
         * <p>The property name is any fully-qualified URI.  It is
         * possible for an XMLReader to recognize a property name but
         * to be unable to change the current value.
         * Some property values may be immutable or mutable only 
         * in specific contexts, such as before, during, or after 
         * a parse.</p>
         *
         * <p>XMLReaders are not required to recognize setting
         * any specific property names, though a core set is defined by 
         * SAX2.</p>
         *
         * <p>This method is also the standard mechanism for setting
         * extended handlers.</p>
         *
         * @param name The property name, which is a fully-qualified URI.
         * @param value The requested value for the property.
         * @exception org.xml.sax.SAXNotRecognizedException If the property
         *            value can't be assigned or retrieved.
         * @exception org.xml.sax.SAXNotSupportedException When the
         *            XMLReader recognizes the property name but 
         *            cannot set the requested value.
         *******************************************************************************/
        public void setProperty(Ch[] name, Object value);

        ////////////////////////////////////////////////////////////////////
        // Event handlers.
        ////////////////////////////////////////////////////////////////////
        /*******************************************************************************
         * Allow an application to register an entity resolver.
         *
         * <p>If the application does not register an entity resolver,
         * the XMLReader will perform its own default resolution.</p>
         *
         * <p>Applications may register a new or different resolver in the
         * middle of a parse, and the SAX parser must begin using the new
         * resolver immediately.</p>
         *
         * @param resolver The entity resolver.
         * @see #getEntityResolver
         *******************************************************************************/
        public void setEntityResolver(EntityResolver!(Ch) resolver);

        /*******************************************************************************
         * Return the current entity resolver.
         *
         * @return The current entity resolver, or null if none
         *         has been registered.
         * @see #setEntityResolver
         *******************************************************************************/
        public EntityResolver!(Ch) getEntityResolver();

        /*******************************************************************************
         * Allow an application to register a content event handler.
         *
         * <p>If the application does not register a content handler, all
         * content events reported by the SAX parser will be silently
         * ignored.</p>
         *
         * <p>Applications may register a new or different handler in the
         * middle of a parse, and the SAX parser must begin using the new
         * handler immediately.</p>
         *
         * @param handler The content handler.
         * @see #getContentHandler
         *******************************************************************************/
        public void setSaxHandler(SaxHandler!(Ch) handler);

        /*******************************************************************************
         * Return the current content handler.
         *
         * @return The current content handler, or null if none
         *         has been registered.
         * @see #setContentHandler
         *******************************************************************************/
        public SaxHandler!(Ch) getSaxHandler();

        /*******************************************************************************
         * Allow an application to register an error event handler.
         *
         * <p>If the application does not register an error handler, all
         * error events reported by the SAX parser will be silently
         * ignored; however, normal processing may not continue.  It is
         * highly recommended that all SAX applications implement an
         * error handler to avoid unexpected bugs.</p>
         *
         * <p>Applications may register a new or different handler in the
         * middle of a parse, and the SAX parser must begin using the new
         * handler immediately.</p>
         *
         * @param handler The error handler.
         * @see #getErrorHandler
         *******************************************************************************/
        public void setErrorHandler(ErrorHandler!(Ch) handler);

        /*******************************************************************************
         * Return the current error handler.
         *
         * @return The current error handler, or null if none
         *         has been registered.
         * @see #setErrorHandler
         *******************************************************************************/
        public ErrorHandler!(Ch) getErrorHandler();

        ////////////////////////////////////////////////////////////////////
        // Parsing.
        ////////////////////////////////////////////////////////////////////
        /*******************************************************************************
         * Parse an XML document.
         *
         * <p>The application can use this method to instruct the XML
         * reader to begin parsing an XML document from any valid input
         * source (a character stream, a byte stream, or a URI).</p>
         *
         * <p>Applications may not invoke this method while a parse is in
         * progress (they should create a new XMLReader instead for each
         * nested XML document).  Once a parse is complete, an
         * application may reuse the same XMLReader object, possibly with a
         * different input source.
         * Configuration of the XMLReader object (such as handler bindings and
         * values established for feature flags and properties) is unchanged
         * by completion of a parse, unless the definition of that aspect of
         * the configuration explicitly specifies other behavior.
         * (For example, feature flags or properties exposing
         * characteristics of the document being parsed.)
         * </p>
         *
         * <p>During the parse, the XMLReader will provide information
         * about the XML document through the registered event
         * handlers.</p>
         *
         * <p>This method is synchronous: it will not return until parsing
         * has ended.  If a client application wants to terminate 
         * parsing early, it should throw an exception.</p>
         *
         * @param input The input source for the top-level of the
         *        XML document.
         * @exception org.xml.sax.SAXException Any SAX exception, possibly
         *            wrapping another exception.
         * @exception java.io.IOException An IO exception from the parser,
         *            possibly from a byte stream or character stream
         *            supplied by the application.
         * @see org.xml.sax.InputSource
         * @see #parse(java.lang.String)
         * @see #setEntityResolver
         * @see #setContentHandler
         * @see #setErrorHandler 
         *******************************************************************************/
        public void parse(InputStream input);

        /*******************************************************************************
         * Parse an XML document from a system identifier (URI).
         *
         * <p>This method is a shortcut for the common case of reading a
         * document from a system identifier.  It is the exact
         * equivalent of the following:</p>
         *
         * <pre>
         * parse(new InputSource(systemId));
         * </pre>
         *
         * <p>If the system identifier is a URL, it must be fully resolved
         * by the application before it is passed to the parser.</p>
         *
         * @param systemId The system identifier (URI).
         * @exception org.xml.sax.SAXException Any SAX exception, possibly
         *            wrapping another exception.
         * @exception java.io.IOException An IO exception from the parser,
         *            possibly from a byte stream or character stream
         *            supplied by the application.
         * @see #parse(org.xml.sax.InputSource)
         *******************************************************************************/
        public void parseUrl(Ch[] systemId);

        /*******************************************************************************
         * Parse an XML document from a character array.
         *
         * @param content The actual document content.
         * @exception org.xml.sax.SAXException Any SAX exception, possibly
         *            wrapping another exception.
         * @exception java.io.IOException An IO exception from the parser,
         *            possibly from a byte stream or character stream
         *            supplied by the application.
         * @see #parse(org.xml.sax.InputSource)
         *******************************************************************************/
        public void parse(Ch[] content);

        /*******************************************************************************
         *******************************************************************************/
        public void parse();

        /*******************************************************************************
         *******************************************************************************/
        public void setContent(Ch[] content);

}
