/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004      
                        Outback release: December 2006
        
        author:         Kris

*******************************************************************************/

module tango.io.model.IConduit;

public import tango.io.model.IBuffer;

/*******************************************************************************

        Conduits provide virtualized access to external content, and 
        represent things like files or Internet connections. Conduits 
        expose a pair of streams, are modelled by tango.io.model.IConduit, 
        and are implemented via classes such as FileConduit & SocketConduit. 
        
        Additional kinds of conduit are easy to construct: one either 
        subclasses tango.io.Conduit, or implements tango.io.model.IConduit. 
        A conduit typically reads and writes from/to an IBuffer in large 
        chunks, typically the entire buffer. Alternatively, one can invoke 
        input.read(dst[]) and/or output.write(src[]) directly.

*******************************************************************************/

interface IConduit : InputStream, OutputStream
{
        /***********************************************************************

                Return the input stream

        ***********************************************************************/
        
        abstract InputStream input ();

        /***********************************************************************

                Return the output stream

        ***********************************************************************/
        
        abstract OutputStream output ();

        /***********************************************************************
        
                Return a preferred size for buffering conduit I/O

        ***********************************************************************/

        abstract uint bufferSize (); 
                     
        /***********************************************************************
        
                Return the name of this conduit

        ***********************************************************************/

        abstract char[] toString (); 
                     
        /***********************************************************************

                Is the conduit alive?

        ***********************************************************************/

        abstract bool isAlive ();

        /***********************************************************************
                
                Release external resources

        ***********************************************************************/

        abstract void detach ();

        /***********************************************************************

                Throw a generic IO exception with the provided msg

        ***********************************************************************/

        abstract void error (char[] msg);

        /***********************************************************************

                Models the ability to seek within a conduit

        ***********************************************************************/

        interface Seek
        {
                /***************************************************************
        
                        The anchor positions supported by seek()

                ***************************************************************/

                enum Anchor     {
                                Begin   = 0,
                                Current = 1,
                                End     = 2,
                                };

                /***************************************************************
                
                        Move the file position to the given offset from the 
                        provided anchor point, and return adjusted position.

                ***************************************************************/

                long seek (long offset, Anchor anchor = Anchor.Begin);
        }
}


/*******************************************************************************

        Describes how to make an IO entity usable with selectors
        
*******************************************************************************/

interface ISelectable
{      
        typedef int Handle = -1;        /// opaque OS file-handle        

        /***********************************************************************

                Models a handle-oriented device. 

                TODO: figure out how to avoid exposing this in the general
                case

        ***********************************************************************/

        Handle fileHandle ();
}


/*******************************************************************************
        
        The common attributes of streams

*******************************************************************************/

interface IOStream 
{
        enum : uint 
        {
                Eof = uint.max /// the End-of-Flow identifer
        }

        /***********************************************************************
        
                Return the host conduit

        ***********************************************************************/

        IConduit conduit ();

                          
        /***********************************************************************
        
                Close the input

        ***********************************************************************/

        void close ();               
}


/*******************************************************************************
        
        The Tango input stream

*******************************************************************************/

interface InputStream : IOStream
{
        /***********************************************************************
        
                Read from conduit into a target array. The provided dst 
                will be populated with content from the conduit. 

                Returns the number of bytes read, which may be less than
                requested in dst. Eof is returned whenever an end-of-flow 
                condition arises.

        ***********************************************************************/

        uint read (void[] dst);               
                        
        /***********************************************************************
        
                Clear any buffered content

        ***********************************************************************/

        InputStream clear ();               
}


/*******************************************************************************
        
        The Tango output stream

*******************************************************************************/

interface OutputStream : IOStream
{
        /***********************************************************************
        
                Write to conduit from a source array. The provided src
                content will be written to the conduit.

                Returns the number of bytes written from src, which may
                be less than the quantity provided. Eof is returned when 
                an end-of-flow condition arises.

        ***********************************************************************/

        uint write (void[] src);     
        
        /***********************************************************************

                Transfer the content of another conduit to this one. Returns
                a reference to this class, and throws IOException on failure.

        ***********************************************************************/

        OutputStream copy (InputStream src);
                          
        /***********************************************************************
        
                Purge buffered content

        ***********************************************************************/

        OutputStream flush ();               
}


