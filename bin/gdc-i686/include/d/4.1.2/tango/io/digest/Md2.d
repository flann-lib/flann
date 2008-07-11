/*******************************************************************************

        copyright:      Copyright (c) 2006 Tango. All rights reserved

        license:        BSD style: see doc/license.txt for details

        version:        Initial release: Feb 2006

        author:         Regan Heath, Oskar Linde

        This module implements the MD2 Message Digest Algorithm as described 
        by RFC 1319 The MD2 Message-Digest Algorithm. B. Kaliski. April 1992.

*******************************************************************************/

module tango.io.digest.Md2;

public  import tango.io.digest.Digest;

private import tango.io.digest.MerkleDamgard;

/*******************************************************************************

*******************************************************************************/

class Md2 : MerkleDamgard
{
        private ubyte[16] C,
                          state;

        /***********************************************************************

                Construct an Md2

        ***********************************************************************/

        this() { }

        /***********************************************************************

                Initialize the cipher

                Remarks:
                Returns the cipher state to it's initial value

        ***********************************************************************/

        protected override void reset()
        {
                super.reset();
                state[] = 0;
                C[] = 0;
        }

        /***********************************************************************

                Obtain the digest

                Returns:
                the digest

                Remarks:
                Returns a digest of the current cipher state, this may 
                be the final digest, or a digest of the state between 
                calls to update()

        ***********************************************************************/

        protected override void createDigest(ubyte[] buf)
        {
                buf[] = state;                  
        }

        /***********************************************************************

                The MD 2 digest size is 16 bytes
 
        ***********************************************************************/

        uint digestSize() { return 16; }

        /***********************************************************************

                 block size

                Returns:
                the block size

                Remarks:
                Specifies the size (in bytes) of the block of data to pass to
                each call to transform(). For MD2 the blockSize is 16.

        ***********************************************************************/

        protected override uint blockSize()
        {
                return 16;
        }

        /***********************************************************************

                Length padding size

                Returns:
                the length padding size

                Remarks:
                Specifies the size (in bytes) of the padding which uses the
                length of the data which has been ciphered, this padding is
                carried out by the padLength method. For MD2 the addSize is 
                0

        ***********************************************************************/

        protected override uint addSize()
        {
                return 0;
        }

        /***********************************************************************

                Pads the cipher data

                Params:
                data = a slice of the cipher buffer to fill with padding

                Remarks:
                Fills the passed buffer slice with the appropriate padding 
                for the final call to transform(). This padding will fill 
                the cipher buffer up to blockSize()-addSize().

        ***********************************************************************/

        protected override void padMessage (ubyte[] data)
        {
                /* Padding is performed as follows: "i" bytes of value "i" 
                 * are appended to the message so that the length in bytes 
                 * of the padded message becomes congruent to 0, modulo 16. 
                 * At least one byte and at most 16 bytes are appended.
                 */
                data[0..$] = cast(ubyte) data.length;
        }

        /***********************************************************************

                Performs the cipher on a block of data

                Params:
                data = the block of data to cipher

                Remarks:
                The actual cipher algorithm is carried out by this method on
                the passed block of data. This method is called for every
                blockSize() bytes of input data and once more with the 
                remaining data padded to blockSize().

        ***********************************************************************/

        protected override void transform (ubyte[] input)
        {
                ubyte[48] X;
                uint t,i,j;

                X[0..16] = state[];
                X[16..32] = input[];

                for (i = 0; i < 16; i++)
                     X[i+32] = cast(ubyte) (state[i] ^ input[i]);

                t = 0;
                for (i = 0; i < 18; i++) 
                    {
                    for (j = 0; j < 48; j++)
                         t = X[j] ^= PI[t];
                    t = (t + i) & 0xff;
                    }

                state[] = X[0..16];

                t = C[15];

                for (i = 0; i < 16; i++)
                     t = C[i] ^= PI[input[i] ^ t];
        }

        /***********************************************************************

                Final processing of cipher.

                Remarks:
                This method is called after the final transform just prior to
                the creation of the final digest. The MD2 algorithm requires
                an additional step at this stage. Future ciphers may or may not
                require this method.

        ***********************************************************************/

        protected override void extend()
        {
                transform(C);
        }
}


/*******************************************************************************

*******************************************************************************/

private const ubyte[256] PI =
[
         41,  46,  67, 201, 162, 216, 124,   1,  61,  54,  84, 161, 236, 240,   6,
         19,  98, 167,   5, 243, 192, 199, 115, 140, 152, 147,  43, 217, 188,
         76, 130, 202,  30, 155,  87,  60, 253, 212, 224,  22, 103,  66, 111,  24,
        138,  23, 229,  18, 190,  78, 196, 214, 218, 158, 222,  73, 160, 251,
        245, 142, 187,  47, 238, 122, 169, 104, 121, 145,  21, 178,   7,  63,
        148, 194,  16, 137,  11,  34,  95,  33, 128, 127,  93, 154,  90, 144,  50,
         39,  53,  62, 204, 231, 191, 247, 151,  3,  255,  25,  48, 179,  72, 165,
        181, 209, 215,  94, 146,  42, 172,  86, 170, 198,  79, 184,  56, 210,
        150, 164, 125, 182, 118, 252, 107, 226, 156, 116,   4, 241,  69, 157,
        112,  89, 100, 113, 135,  32, 134,  91, 207, 101, 230,  45, 168,   2,  27,
         96,  37, 173, 174, 176, 185, 246,  28,  70,  97, 105,  52,  64, 126,  15,
         85,  71, 163,  35, 221,  81, 175,  58, 195,  92, 249, 206, 186, 197,
        234,  38,  44,  83,  13, 110, 133,  40, 132,   9, 211, 223, 205, 244,  65,
        129,  77,  82, 106, 220,  55, 200, 108, 193, 171, 250,  36, 225, 123,
          8,  12, 189, 177,  74, 120, 136, 149, 139, 227,  99, 232, 109, 233,
        203, 213, 254,  59,   0,  29,  57, 242, 239, 183,  14, 102,  88, 208, 228,
        166, 119, 114, 248, 235, 117,  75,  10,  49,  68,  80, 180, 143, 237,
         31,  26, 219, 153, 141,  51, 159,  17, 131,  20
];


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
                "8350e5a3e24c153df2275c9f80692773",
                "32ec01ec4a6dac72c0ab96fb34c0b5d1",
                "da853b0d3f88d99b30283a69e6ded6bb",
                "ab4f496bfb2a530b219ff33031fe06b0",
                "4e8ddff3650292ab5a4108c3aa47940b",
                "da33def2a42df13975352846c30338cd",
                "d5976f79d83d3a0dc9806c3c66f3efd8"
        ];

        Md2 h = new Md2();

        foreach (int i, char[] s; strings) 
                {
                h.update(s);
                char[] d = h.hexDigest();
                assert(d == results[i],":("~s~")("~d~")!=("~results[i]~")");
                }
        }
}

