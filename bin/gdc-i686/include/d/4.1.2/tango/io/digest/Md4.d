/*******************************************************************************

        copyright:      Copyright (c) 2006 Tango. All rights reserved

        license:        BSD style: see doc/license.txt for details

        version:        Initial release: Feb 2006

        author:         Regan Heath, Oskar Linde

        This module implements the MD4 Message Digest Algorithm as described 
        by RFC 1320 The MD4 Message-Digest Algorithm. R. Rivest. April 1992.

*******************************************************************************/

module tango.io.digest.Md4;

public  import tango.io.digest.Digest;

private import tango.io.digest.MerkleDamgard;

/*******************************************************************************

*******************************************************************************/

class Md4 : MerkleDamgard
{
        protected uint[4]       context;
        private const ubyte     padChar = 0x80;

        /***********************************************************************

                Construct an Md4

        ***********************************************************************/

        this() { }

        /***********************************************************************

                The MD 4 digest size is 16 bytes
 
        ***********************************************************************/

        uint digestSize() { return 16; }
            
        /***********************************************************************

                Initialize the cipher

                Remarks:
                Returns the cipher state to it's initial value

        ***********************************************************************/

        override void reset()
        {
                super.reset();
                context[] = initial[];
        }

        /***********************************************************************

                Obtain the digest

                Returns:
                the digest

                Remarks:
                Returns a digest of the current cipher state, this may be the
                final digest, or a digest of the state between calls to update()

        ***********************************************************************/

        override void createDigest(ubyte[] buf)
        {
                version (BigEndian)
                         ByteSwap.swap32 (context.ptr, context.length * uint.sizeof);

                buf[] = cast(ubyte[]) context;
        }

        /***********************************************************************

                 block size

                Returns:
                the block size

                Remarks:
                Specifies the size (in bytes) of the block of data to pass to
                each call to transform(). For MD4 the blockSize is 64.

        ***********************************************************************/

        protected override uint blockSize() { return 64; }

        /***********************************************************************

                Length padding size

                Returns:
                the length padding size

                Remarks:
                Specifies the size (in bytes) of the padding which uses the
                length of the data which has been ciphered, this padding is
                carried out by the padLength method. For MD4 the addSize is 8.

        ***********************************************************************/

        protected override uint addSize()   { return 8;  }

        /***********************************************************************

                Pads the cipher data

                Params:
                data = a slice of the cipher buffer to fill with padding

                Remarks:
                Fills the passed buffer slice with the appropriate padding for
                the final call to transform(). This padding will fill the cipher
                buffer up to blockSize()-addSize().

        ***********************************************************************/

        protected override void padMessage(ubyte[] data)
        {
                data[0] = padChar;
                data[1..$] = 0;
        }

        /***********************************************************************

                Performs the length padding

                Params:
                data   = the slice of the cipher buffer to fill with padding
                length = the length of the data which has been ciphered

                Remarks:
                Fills the passed buffer slice with addSize() bytes of padding
                based on the length in bytes of the input data which has been
                ciphered.

        ***********************************************************************/

        protected override void padLength(ubyte[] data, ulong length)
        {
                length <<= 3;
                littleEndian64((cast(ubyte*)&length)[0..8],cast(ulong[]) data); 
        }   

        /***********************************************************************

                Performs the cipher on a block of data

                Params:
                data = the block of data to cipher

                Remarks:
                The actual cipher algorithm is carried out by this method on
                the passed block of data. This method is called for every
                blockSize() bytes of input data and once more with the remaining
                data padded to blockSize().

        ***********************************************************************/

        protected override void transform(ubyte[] input)
        {
                uint a,b,c,d;
                uint[16] x;

                littleEndian32(input,x);

                a = context[0];
                b = context[1];
                c = context[2];
                d = context[3];

                /* Round 1 */
                ff(a, b, c, d, x[ 0], S11, 0); /* 1 */
                ff(d, a, b, c, x[ 1], S12, 0); /* 2 */
                ff(c, d, a, b, x[ 2], S13, 0); /* 3 */
                ff(b, c, d, a, x[ 3], S14, 0); /* 4 */
                ff(a, b, c, d, x[ 4], S11, 0); /* 5 */
                ff(d, a, b, c, x[ 5], S12, 0); /* 6 */
                ff(c, d, a, b, x[ 6], S13, 0); /* 7 */
                ff(b, c, d, a, x[ 7], S14, 0); /* 8 */
                ff(a, b, c, d, x[ 8], S11, 0); /* 9 */
                ff(d, a, b, c, x[ 9], S12, 0); /* 10 */
                ff(c, d, a, b, x[10], S13, 0); /* 11 */
                ff(b, c, d, a, x[11], S14, 0); /* 12 */
                ff(a, b, c, d, x[12], S11, 0); /* 13 */
                ff(d, a, b, c, x[13], S12, 0); /* 14 */
                ff(c, d, a, b, x[14], S13, 0); /* 15 */
                ff(b, c, d, a, x[15], S14, 0); /* 16 */

                /* Round 2 */
                gg(a, b, c, d, x[ 0], S21, 0x5a827999); /* 17 */
                gg(d, a, b, c, x[ 4], S22, 0x5a827999); /* 18 */
                gg(c, d, a, b, x[ 8], S23, 0x5a827999); /* 19 */
                gg(b, c, d, a, x[12], S24, 0x5a827999); /* 20 */
                gg(a, b, c, d, x[ 1], S21, 0x5a827999); /* 21 */
                gg(d, a, b, c, x[ 5], S22, 0x5a827999); /* 22 */
                gg(c, d, a, b, x[ 9], S23, 0x5a827999); /* 23 */
                gg(b, c, d, a, x[13], S24, 0x5a827999); /* 24 */
                gg(a, b, c, d, x[ 2], S21, 0x5a827999); /* 25 */
                gg(d, a, b, c, x[ 6], S22, 0x5a827999); /* 26 */
                gg(c, d, a, b, x[10], S23, 0x5a827999); /* 27 */
                gg(b, c, d, a, x[14], S24, 0x5a827999); /* 28 */
                gg(a, b, c, d, x[ 3], S21, 0x5a827999); /* 29 */
                gg(d, a, b, c, x[ 7], S22, 0x5a827999); /* 30 */
                gg(c, d, a, b, x[11], S23, 0x5a827999); /* 31 */
                gg(b, c, d, a, x[15], S24, 0x5a827999); /* 32 */

                /* Round 3 */
                hh(a, b, c, d, x[ 0], S31, 0x6ed9eba1); /* 33 */
                hh(d, a, b, c, x[ 8], S32, 0x6ed9eba1); /* 34 */
                hh(c, d, a, b, x[ 4], S33, 0x6ed9eba1); /* 35 */
                hh(b, c, d, a, x[12], S34, 0x6ed9eba1); /* 36 */
                hh(a, b, c, d, x[ 2], S31, 0x6ed9eba1); /* 37 */
                hh(d, a, b, c, x[10], S32, 0x6ed9eba1); /* 38 */
                hh(c, d, a, b, x[ 6], S33, 0x6ed9eba1); /* 39 */
                hh(b, c, d, a, x[14], S34, 0x6ed9eba1); /* 40 */
                hh(a, b, c, d, x[ 1], S31, 0x6ed9eba1); /* 41 */
                hh(d, a, b, c, x[ 9], S32, 0x6ed9eba1); /* 42 */
                hh(c, d, a, b, x[ 5], S33, 0x6ed9eba1); /* 43 */
                hh(b, c, d, a, x[13], S34, 0x6ed9eba1); /* 44 */
                hh(a, b, c, d, x[ 3], S31, 0x6ed9eba1); /* 45 */
                hh(d, a, b, c, x[11], S32, 0x6ed9eba1); /* 46 */
                hh(c, d, a, b, x[ 7], S33, 0x6ed9eba1); /* 47 */
                hh(b, c, d, a, x[15], S34, 0x6ed9eba1); /* 48 */

                context[0] += a;
                context[1] += b;
                context[2] += c;
                context[3] += d;

                x[] = 0;
        }

        /***********************************************************************

        ***********************************************************************/

        protected static uint f(uint x, uint y, uint z)
        {
                return (x&y)|(~x&z);
        }

        /***********************************************************************

        ***********************************************************************/

        protected static uint h(uint x, uint y, uint z)
        {
                return x^y^z;
        }

        /***********************************************************************

        ***********************************************************************/

        private static uint g(uint x, uint y, uint z)
        {
                return (x&y)|(x&z)|(y&z);
        }

        /***********************************************************************

        ***********************************************************************/

        private static void ff(inout uint a, uint b, uint c, uint d, uint x, uint s, uint ac)
        {
                a += f(b, c, d) + x + ac;
                a = rotateLeft(a, s);
        }

        /***********************************************************************

        ***********************************************************************/

        private static void gg(inout uint a, uint b, uint c, uint d, uint x, uint s, uint ac)
        {
                a += g(b, c, d) + x + ac;
                a = rotateLeft(a, s);
        }

        /***********************************************************************

        ***********************************************************************/

        private static void hh(inout uint a, uint b, uint c, uint d, uint x, uint s, uint ac)
        {
                a += h(b, c, d) + x + ac;
                a = rotateLeft(a, s);
        }

        /***********************************************************************

        ***********************************************************************/

        private static const uint[4] initial =
        [
                0x67452301,
                0xefcdab89,
                0x98badcfe,
                0x10325476
        ];

        /***********************************************************************

        ***********************************************************************/

        private static enum
        {
                S11 =  3,
                S12 =  7,
                S13 = 11,
                S14 = 19,
                S21 =  3,
                S22 =  5,
                S23 =  9,
                S24 = 13,
                S31 =  3,
                S32 =  9,
                S33 = 11,
                S34 = 15,
        }
}


/*******************************************************************************

*******************************************************************************/

version (UnitTest)
{
        unittest 
        {
        static char[][] strings = 
        [
                "",
                "a",
                "abc",
                "message digest",
                "abcdefghijklmnopqrstuvwxyz",
                "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
                "12345678901234567890123456789012345678901234567890123456789012345678901234567890"
        ];

        static char[][] results = 
        [
                "31d6cfe0d16ae931b73c59d7e0c089c0",
                "bde52cb31de33e46245e05fbdbd6fb24",
                "a448017aaf21d8525fc10ae87aa6729d",
                "d9130a8164549fe818874806e1c7014b",
                "d79e1c308aa5bbcdeea8ed63df412da9",
                "043f8582f241db351ce627e153e7f0e4",
                "e33b4ddc9c38f2199c3e7b164fcc0536"
        ];

        Md4 h = new Md4();

        foreach (int i, char[] s; strings) 
                {
                h.update(s);
                char[] d = h.hexDigest;
                assert(d == results[i],":("~s~")("~d~")!=("~results[i]~")");
                }
        }
}

