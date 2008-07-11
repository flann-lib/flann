/*******************************************************************************

        copyright:      Copyright (c) 2006 Tango. All rights reserved

        license:        BSD style: see doc/license.txt for details

        version:        Initial release: Feb 2006

        author:         Regan Heath, Oskar Linde

        This module implements the MD5 Message Digest Algorithm as described
        by RFC 1321 The MD5 Message-Digest Algorithm. R. Rivest. April 1992.

*******************************************************************************/

module tango.io.digest.Md5;

public  import tango.io.digest.Md4;

private import tango.io.digest.MerkleDamgard;

/*******************************************************************************

*******************************************************************************/

final class Md5 : Md4
{
        /***********************************************************************

        ***********************************************************************/

        private enum
        {
                S11 =  7,
                S12 = 12,
                S13 = 17,
                S14 = 22,
                S21 =  5,
                S22 =  9,
                S23 = 14,
                S24 = 20,
                S31 =  4,
                S32 = 11,
                S33 = 16,
                S34 = 23,
                S41 =  6,
                S42 = 10,
                S43 = 15,
                S44 = 21
        };

        /***********************************************************************

                Construct an Md5

        ***********************************************************************/

        this() { }


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
                ff(a, b, c, d, x[ 0], S11, 0xd76aa478); /* 1 */
                ff(d, a, b, c, x[ 1], S12, 0xe8c7b756); /* 2 */
                ff(c, d, a, b, x[ 2], S13, 0x242070db); /* 3 */
                ff(b, c, d, a, x[ 3], S14, 0xc1bdceee); /* 4 */
                ff(a, b, c, d, x[ 4], S11, 0xf57c0faf); /* 5 */
                ff(d, a, b, c, x[ 5], S12, 0x4787c62a); /* 6 */
                ff(c, d, a, b, x[ 6], S13, 0xa8304613); /* 7 */
                ff(b, c, d, a, x[ 7], S14, 0xfd469501); /* 8 */
                ff(a, b, c, d, x[ 8], S11, 0x698098d8); /* 9 */
                ff(d, a, b, c, x[ 9], S12, 0x8b44f7af); /* 10 */
                ff(c, d, a, b, x[10], S13, 0xffff5bb1); /* 11 */
                ff(b, c, d, a, x[11], S14, 0x895cd7be); /* 12 */
                ff(a, b, c, d, x[12], S11, 0x6b901122); /* 13 */
                ff(d, a, b, c, x[13], S12, 0xfd987193); /* 14 */
                ff(c, d, a, b, x[14], S13, 0xa679438e); /* 15 */
                ff(b, c, d, a, x[15], S14, 0x49b40821); /* 16 */

                /* Round 2 */
                gg(a, b, c, d, x[ 1], S21, 0xf61e2562); /* 17 */
                gg(d, a, b, c, x[ 6], S22, 0xc040b340); /* 18 */
                gg(c, d, a, b, x[11], S23, 0x265e5a51); /* 19 */
                gg(b, c, d, a, x[ 0], S24, 0xe9b6c7aa); /* 20 */
                gg(a, b, c, d, x[ 5], S21, 0xd62f105d); /* 21 */
                gg(d, a, b, c, x[10], S22,  0x2441453); /* 22 */
                gg(c, d, a, b, x[15], S23, 0xd8a1e681); /* 23 */
                gg(b, c, d, a, x[ 4], S24, 0xe7d3fbc8); /* 24 */
                gg(a, b, c, d, x[ 9], S21, 0x21e1cde6); /* 25 */
                gg(d, a, b, c, x[14], S22, 0xc33707d6); /* 26 */
                gg(c, d, a, b, x[ 3], S23, 0xf4d50d87); /* 27 */
                gg(b, c, d, a, x[ 8], S24, 0x455a14ed); /* 28 */
                gg(a, b, c, d, x[13], S21, 0xa9e3e905); /* 29 */
                gg(d, a, b, c, x[ 2], S22, 0xfcefa3f8); /* 30 */
                gg(c, d, a, b, x[ 7], S23, 0x676f02d9); /* 31 */
                gg(b, c, d, a, x[12], S24, 0x8d2a4c8a); /* 32 */

                /* Round 3 */
                hh(a, b, c, d, x[ 5], S31, 0xfffa3942); /* 33 */
                hh(d, a, b, c, x[ 8], S32, 0x8771f681); /* 34 */
                hh(c, d, a, b, x[11], S33, 0x6d9d6122); /* 35 */
                hh(b, c, d, a, x[14], S34, 0xfde5380c); /* 36 */
                hh(a, b, c, d, x[ 1], S31, 0xa4beea44); /* 37 */
                hh(d, a, b, c, x[ 4], S32, 0x4bdecfa9); /* 38 */
                hh(c, d, a, b, x[ 7], S33, 0xf6bb4b60); /* 39 */
                hh(b, c, d, a, x[10], S34, 0xbebfbc70); /* 40 */
                hh(a, b, c, d, x[13], S31, 0x289b7ec6); /* 41 */
                hh(d, a, b, c, x[ 0], S32, 0xeaa127fa); /* 42 */
                hh(c, d, a, b, x[ 3], S33, 0xd4ef3085); /* 43 */
                hh(b, c, d, a, x[ 6], S34,  0x4881d05); /* 44 */
                hh(a, b, c, d, x[ 9], S31, 0xd9d4d039); /* 45 */
                hh(d, a, b, c, x[12], S32, 0xe6db99e5); /* 46 */
                hh(c, d, a, b, x[15], S33, 0x1fa27cf8); /* 47 */
                hh(b, c, d, a, x[ 2], S34, 0xc4ac5665); /* 48 */

                /* Round 4 */ /* Md5 not md4 */
                ii(a, b, c, d, x[ 0], S41, 0xf4292244); /* 49 */
                ii(d, a, b, c, x[ 7], S42, 0x432aff97); /* 50 */
                ii(c, d, a, b, x[14], S43, 0xab9423a7); /* 51 */
                ii(b, c, d, a, x[ 5], S44, 0xfc93a039); /* 52 */
                ii(a, b, c, d, x[12], S41, 0x655b59c3); /* 53 */
                ii(d, a, b, c, x[ 3], S42, 0x8f0ccc92); /* 54 */
                ii(c, d, a, b, x[10], S43, 0xffeff47d); /* 55 */
                ii(b, c, d, a, x[ 1], S44, 0x85845dd1); /* 56 */
                ii(a, b, c, d, x[ 8], S41, 0x6fa87e4f); /* 57 */
                ii(d, a, b, c, x[15], S42, 0xfe2ce6e0); /* 58 */
                ii(c, d, a, b, x[ 6], S43, 0xa3014314); /* 59 */
                ii(b, c, d, a, x[13], S44, 0x4e0811a1); /* 60 */
                ii(a, b, c, d, x[ 4], S41, 0xf7537e82); /* 61 */
                ii(d, a, b, c, x[11], S42, 0xbd3af235); /* 62 */
                ii(c, d, a, b, x[ 2], S43, 0x2ad7d2bb); /* 63 */
                ii(b, c, d, a, x[ 9], S44, 0xeb86d391); /* 64 */

                context[0] += a;
                context[1] += b;
                context[2] += c;
                context[3] += d;

                x[] = 0;
        }

        /***********************************************************************

        ***********************************************************************/

        private static uint g(uint x, uint y, uint z)
        {
                return (x&z)|(y&~z);
        }

        /***********************************************************************

        ***********************************************************************/

        private static uint i(uint x, uint y, uint z)
        {
                return y^(x|~z);
        }

        /***********************************************************************

        ***********************************************************************/

        private static void ff(inout uint a, uint b, uint c, uint d, uint x, uint s, uint ac)
        {
                a += f(b, c, d) + x + ac;
                a = rotateLeft(a, s);
                a += b;
        }

        /***********************************************************************

        ***********************************************************************/

        private static void gg(inout uint a, uint b, uint c, uint d, uint x, uint s, uint ac)
        {
                a += g(b, c, d) + x + ac;
                a = rotateLeft(a, s);
                a += b;
        }

        /***********************************************************************

        ***********************************************************************/

        private static void hh(inout uint a, uint b, uint c, uint d, uint x, uint s, uint ac)
        {
                a += h(b, c, d) + x + ac;
                a = rotateLeft(a, s);
                a += b;
        }

        /***********************************************************************

        ***********************************************************************/

        private static void ii(inout uint a, uint b, uint c, uint d, uint x, uint s, uint ac)
        {
                a += i(b, c, d) + x + ac;
                a = rotateLeft(a, s);
                a += b;
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
                "d41d8cd98f00b204e9800998ecf8427e",
                "0cc175b9c0f1b6a831c399e269772661",
                "900150983cd24fb0d6963f7d28e17f72",
                "f96b697d7cb7938d525a2f31aaf161d0",
                "c3fcd3d76192e4007dfb496cca67e13b",
                "d174ab98d277d9f5a5611c2c9f419d9f",
                "57edf4a22be3c955ac49da2e2107b67a"
        ];

        Md5 h = new Md5();

        foreach (int i, char[] s; strings)
                {
                h.update(cast(ubyte[]) s);
                char[] d = h.hexDigest;

                assert(d == results[i],":("~s~")("~d~")!=("~results[i]~")");
                }
        }
}
