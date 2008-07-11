/*******************************************************************************

        copyright:      Copyright (c) 2006 Tango. All rights reserved

        license:        BSD style: see doc/license.txt for details

        version:        Initial release: Feb 2006

        author:         Regan Heath, Oskar Linde

        This module implements the SHA-0 Algorithm described by Secure 
        Hash Standard, FIPS PUB 180

*******************************************************************************/

module tango.io.digest.Sha0;

private import tango.io.digest.Sha01;

public  import tango.io.digest.Digest;

/*******************************************************************************

*******************************************************************************/

final class Sha0 : Sha01
{
        /***********************************************************************

                Construct an Sha0

        ***********************************************************************/

        this() { }

        /***********************************************************************

        ***********************************************************************/

        final protected override void transform(ubyte[] input)
        {
                uint A,B,C,D,E,TEMP;
                uint[16] W;
                uint s;

                bigEndian32(input,W);

                A = context[0];
                B = context[1];
                C = context[2];
                D = context[3];
                E = context[4];

                for(uint t = 0; t < 80; t++) {
                        s = t & mask;
                        if (t >= 16) expand(W,s);
                        TEMP = rotateLeft(A,5) + f(t,B,C,D) + E + W[s] + K[t/20];
                        E = D; D = C; C = rotateLeft(B,30); B = A; A = TEMP;
                }

                context[0] += A;
                context[1] += B;
                context[2] += C;
                context[3] += D;
                context[4] += E;
        }

        /***********************************************************************

        ***********************************************************************/

        final static protected void expand(uint W[], uint s)
        {
                W[s] = W[(s+13)&mask] ^ W[(s+8)&mask] ^ W[(s+2)&mask] ^ W[s];
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
                "abc",
                "message digest",
                "abcdefghijklmnopqrstuvwxyz",
                "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
                "12345678901234567890123456789012345678901234567890123456789012345678901234567890"
        ];

        static char[][] results = 
        [
                "f96cea198ad1dd5617ac084a3d92c6107708c0ef",
                "0164b8a914cd2a5e74c4f7ff082c4d97f1edf880",
                "c1b0f222d150ebb9aa36a40cafdc8bcbed830b14",
                "b40ce07a430cfd3c033039b9fe9afec95dc1bdcd",
                "79e966f7a3a990df33e40e3d7f8f18d2caebadfa",
                "4aa29d14d171522ece47bee8957e35a41f3e9cff",
        ];

        Sha0 h = new Sha0();

        foreach (int i, char[] s; strings) 
                {
                h.update(s);
                char[] d = h.hexDigest();
                assert(d == results[i],":("~s~")("~d~")!=("~results[i]~")");
                }
        }
}
