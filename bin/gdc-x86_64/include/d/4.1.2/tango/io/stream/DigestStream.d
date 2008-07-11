/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2007

        author:         Kris

*******************************************************************************/

module tango.io.stream.DigestStream;

private import tango.io.Conduit;

private import tango.io.digest.Digest;

/*******************************************************************************

        Inject a digest filter into an input stream, updating the digest
        as information flows through it

*******************************************************************************/

class DigestInput : InputFilter
{
        private Digest filter;

        /***********************************************************************

                Accepts any input stream, and any digest derivation

        ***********************************************************************/

        this (InputStream stream, Digest digest)
        {
                super (stream);
                filter = digest;
        }

        /***********************************************************************

                Read from conduit into a target array. The provided dst 
                will be populated with content from the conduit. 

                Returns the number of bytes read, which may be less than
                requested in dst (or IOStream.Eof for end-of-flow)

        ***********************************************************************/

        final override uint read (void[] dst)
        {
                auto len = host.read (dst);
                if (len != Eof)
                    filter.update (dst [0 .. len]);
                return len;
        }

        /********************************************************************
             
                Return the Digest instance we were created with. Use this
                to access the resultant binary or hex digest value

        *********************************************************************/
    
        final Digest digest()
        {
                return filter;
        }
}


/*******************************************************************************
        
        Inject a digest filter into an output stream, updating the digest
        as information flows through it. Here's an example where we calculate
        an MD5 digest as a side-effect of copying a file:
        ---
        auto output = new DigestOutput(new FileOutput("output"), new Md5);
        output.copy (new FileInput("input"));

        Stdout.formatln ("hex digest: {}", output.digest.hexDigest);
        ---

*******************************************************************************/

class DigestOutput : OutputFilter
{
        private Digest filter;

        /***********************************************************************

                Accepts any output stream, and any digest derivation

        ***********************************************************************/

        this (OutputStream stream, Digest digest)
        {
                super (stream);
                filter = digest;
        }

        /***********************************************************************
        
                Write to conduit from a source array. The provided src
                content will be written to the conduit.

                Returns the number of bytes written from src, which may
                be less than the quantity provided

        ***********************************************************************/

        final override uint write (void[] src)
        {
                auto len = host.write (src);
                if (len != Eof)
                    filter.update (src[0 .. len]);
                return len;
        }

        /********************************************************************
             
                Return the Digest instance we were created with. Use this
                to access the resultant binary or hex digest value

        *********************************************************************/
    
        final Digest digest()
        {
                return filter;
        }
}


/*******************************************************************************
        
*******************************************************************************/
        
debug (DigestStream)
{
        import tango.io.Stdout;
        import tango.io.GrowBuffer;
        import tango.io.digest.Md5;
        import tango.io.stream.FileStream;

        void main()
        {
                auto output = new DigestOutput(new GrowBuffer, new Md5);
                output.copy (new FileInput("digeststream.d"));

                Stdout.formatln ("hex digest:{}", output.digest.hexDigest);
        }
}
