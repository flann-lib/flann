/*******************************************************************************
        copyright:      Copyright (c) 2006 Tango. All rights reserved

        license:        BSD style: see doc/license.txt for details

        version:        Initial release: Feb 2006

        author:         Regan Heath, Oskar Linde

        This module implements a generic Merkle-Damgard hash function

*******************************************************************************/

module tango.io.digest.MerkleDamgard;

public  import tango.core.ByteSwap;

public  import tango.io.digest.Digest;

/*******************************************************************************

        Extending MerkleDamgard to create a custom hash function requires 
        the implementation of a number of abstract methods. These include:
        ---
        public uint digestSize();
        protected void reset();
        protected void createDigest(ubyte[] buf);
        protected uint blockSize();
        protected uint addSize();
        protected void padMessage(ubyte[] data);
        protected void transform(ubyte[] data);
        ---

        In addition there exist two further abstract methods; these methods
        have empty default implementations since in some cases they are not 
        required:
        ---
        protected abstract void padLength(ubyte[] data, ulong length);
        protected abstract void extend();
        ---

        The method padLength() is required to implement the SHA series of
        Hash functions and also the Tiger algorithm. Method extend() is 
        required only to implement the MD2 digest.

        The basic sequence of internal events is as follows:
        $(UL
        $(LI transform(), 0 or more times)
        $(LI padMessage())
        $(LI padLength())
        $(LI transform())
        $(LI extend())
        $(LI createDigest())
        $(LI reset())
        )
 
*******************************************************************************/

package class MerkleDamgard : Digest
{
        private uint    bytes;
        private ubyte[] buffer;

        /***********************************************************************

                Constructs the digest

                Params:
                buf = a buffer with enough space to hold the digest

                Remarks:
                Constructs the digest.

        ***********************************************************************/

        protected abstract void createDigest(ubyte[] buf);

        /***********************************************************************

                Digest block size

                Returns:
                the block size

                Remarks:
                Specifies the size (in bytes) of the block of data to pass to
                each call to transform().

        ***********************************************************************/

        protected abstract uint blockSize();

        /***********************************************************************

                Length padding size

                Returns:
                the length padding size

                Remarks:
                Specifies the size (in bytes) of the padding which
                uses the length of the data which has been fed to the
                algorithm, this padding is carried out by the
                padLength method.

        ***********************************************************************/

        protected abstract uint addSize();

        /***********************************************************************

                Pads the digest data

                Params:
                data = a slice of the digest buffer to fill with padding

                Remarks:
                Fills the passed buffer slice with the appropriate
                padding for the final call to transform(). This
                padding will fill the message data buffer up to
                blockSize()-addSize().

        ***********************************************************************/

        protected abstract void padMessage(ubyte[] data);

        /***********************************************************************

                Performs the length padding

                Params:
                data   = the slice of the digest buffer to fill with padding
                length = the length of the data which has been processed

                Remarks:
                Fills the passed buffer slice with addSize() bytes of padding
                based on the length in bytes of the input data which has been
                processed.

        ***********************************************************************/

        protected void padLength(ubyte[] data, ulong length) {}

        /***********************************************************************

                Performs the digest on a block of data

                Params:
                data = the block of data to digest

                Remarks:
                The actual digest algorithm is carried out by this method on
                the passed block of data. This method is called for every
                blockSize() bytes of input data and once more with the remaining
                data padded to blockSize().

        ***********************************************************************/

        protected abstract void transform(ubyte[] data);

        /***********************************************************************

                Final processing of digest.

                Remarks:
                This method is called after the final transform just prior to
                the creation of the final digest. The MD2 algorithm requires
                an additional step at this stage. Future digests may or may not
                require this method.

        ***********************************************************************/

        protected void extend() {} 

        /***********************************************************************

                Construct a digest

                Remarks:
                Constructs the internal buffer for use by the digest, the buffer
                size (in bytes) is defined by the abstract method blockSize().

        ***********************************************************************/

        this()
        {
                buffer = new ubyte[blockSize()];
                reset();
        }

        /***********************************************************************

                Initialize the digest

                Remarks:
                Returns the digest state to its initial value

        ***********************************************************************/

        protected void reset()
        {
                bytes = 0;
        }

        /***********************************************************************

                Digest additional data

                Params:
                input = the data to digest

                Remarks:
                Continues the digest operation on the additional data.

        ***********************************************************************/

        void update (void[] input)
        {
                auto block = blockSize();
                uint i = bytes & (block-1);
                ubyte[] data = cast(ubyte[]) input;

                bytes += data.length;

                if (data.length+i < block) 
                    buffer[i..i+data.length] = data[];
                else
                   {
                   buffer[i..block] = data[0..block-i];
                   transform (buffer);

                   for (i=block-i; i+block-1 < data.length; i += block)
                        transform(data[i..i+block]);

                   buffer[0..data.length-i] = data[i..data.length];
                   }
        }

        /***********************************************************************

                Complete the digest

                Returns:
                the completed digest

                Remarks:
                Concludes the algorithm producing the final digest.

        ***********************************************************************/

        ubyte[] binaryDigest (ubyte[] buf = null)
        {
                auto block = blockSize();
                uint i = bytes & (block-1);

                if (i < block-addSize)
                    padMessage (buffer[i..block-addSize]);
                else 
                   {
                   padMessage (buffer[i..block]);
                   transform (buffer);
                   buffer[] = 0;
                   }

                padLength (buffer[block-addSize..block], bytes);
                transform (buffer);

                extend ();

                if (buf.length < digestSize())
                    buf.length = digestSize();

                createDigest (buf);
                
                reset ();
                return buf;
        }

        /***********************************************************************

                Converts 8 bit to 32 bit Little Endian

                Params:
                input  = the source array
                output = the destination array

                Remarks:
                Converts an array of ubyte[] into uint[] in Little Endian byte order.

        ***********************************************************************/

        static protected final void littleEndian32(ubyte[] input, uint[] output)
        {
                assert(output.length == input.length/4);
                output[] = cast(uint[]) input;

                version (BigEndian)
                         ByteSwap.swap32 (output.ptr, output.length * uint.sizeof);
        }

        /***********************************************************************

                Converts 8 bit to 32 bit Big Endian

                Params:
                input  = the source array
                output = the destination array

                Remarks:
                Converts an array of ubyte[] into uint[] in Big Endian byte order.

        ***********************************************************************/

        static protected final void bigEndian32(ubyte[] input, uint[] output)
        {
                assert(output.length == input.length/4);
                output[] = cast(uint[]) input;

                version(LittleEndian)
                        ByteSwap.swap32 (output.ptr, output.length *  uint.sizeof);
        }

        /***********************************************************************

                Converts 8 bit to 64 bit Little Endian

                Params:
                input  = the source array
                output = the destination array

                Remarks:
                Converts an array of ubyte[] into ulong[] in Little Endian byte order.

        ***********************************************************************/

        static protected final void littleEndian64(ubyte[] input, ulong[] output)
        {
                assert(output.length == input.length/8);
                output[] = cast(ulong[]) input;

                version (BigEndian)
                         ByteSwap.swap64 (output.ptr, output.length * ulong.sizeof);
        }

        /***********************************************************************

                Converts 8 bit to 64 bit Big Endian

                Params: input  = the source array
                output = the destination array

                Remarks:
                Converts an array of ubyte[] into ulong[] in Big Endian byte order.

        ***********************************************************************/

        static protected final void bigEndian64(ubyte[] input, ulong[] output)
        {
                assert(output.length == input.length/8);
                output[] = cast(ulong[]) input;

                version (LittleEndian)
                         ByteSwap.swap64 (output.ptr, output.length * ulong.sizeof);
        }

        /***********************************************************************

                Rotate left by n

                Params:
                x = the value to rotate
                n = the amount to rotate by

                Remarks:
                Rotates a 32 bit value by the specified amount.

        ***********************************************************************/

        static protected final uint rotateLeft(uint x, uint n)
        {
               /+version (D_InlineAsm_X86)
                        version (DigitalMars)
                        {
                        asm {
                            naked;
                            mov ECX,EAX;
                            mov EAX,4[ESP];
                            rol EAX,CL;
                            ret 4;
                            }
                        }
                     else
                        return (x << n) | (x >> (32-n));
            else +/
                   return (x << n) | (x >> (32-n));
        }
}


