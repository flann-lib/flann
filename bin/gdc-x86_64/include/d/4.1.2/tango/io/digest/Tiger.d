/*******************************************************************************

        copyright:      Copyright (c) 2006 Tango. All rights reserved

        license:        BSD style: see doc/license.txt for details

        version:        Initial release: Feb 2006

        author:         Regan Heath, Oskar Linde

        This module implements the Tiger algorithm by Ross Anderson and Eli
        Biham.

*******************************************************************************/

module tango.io.digest.Tiger;

private import tango.core.ByteSwap;

private import tango.io.digest.MerkleDamgard;

public  import tango.io.digest.Digest;

/*******************************************************************************

*******************************************************************************/

final class Tiger : MerkleDamgard
{
        private ulong[3]        context;
        private uint            npass = 3;
        private const uint      padChar = 0x01;

        /***********************************************************************

        ***********************************************************************/

        private static const ulong[3] initial =
        [
                0x0123456789ABCDEF,
                0xFEDCBA9876543210,
                0xF096A5B4C3B2E187
        ];

        /***********************************************************************

                Construct an Tiger

        ***********************************************************************/

        this() { }

        /***********************************************************************

                The size of a tiger digest is 24 bytes
                
        ***********************************************************************/

        override uint digestSize() {return 24;}
        

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
                version (LittleEndian)
                        ByteSwap.swap64 (context.ptr, context.length * ulong.sizeof);
                buf[] = cast(ubyte[]) context;
        }

        /***********************************************************************

                Get the number of passes being performed

                Returns:
                the number of passes

                Remarks:
                The Tiger algorithm may perform an arbitrary number of passes
                the minimum recommended number is 3 and this number should be
                quite secure however the "ultra-cautious" may wish to increase
                this number.

        ***********************************************************************/

        uint passes()
        {
                return npass;
        }

        /***********************************************************************

                Set the number of passes to be performed

                Params:
                n = the number of passes to perform

                Remarks:
                The Tiger algorithm may perform an arbitrary number of passes
                the minimum recommended number is 3 and this number should be
                quite secure however the "ultra-cautious" may wish to increase
                this number.

        ***********************************************************************/

        void passes(uint n)
        {
                if (n < 3) return ;
                npass = n;
        }

        /***********************************************************************

                 block size

                Returns:
                the block size

                Remarks:
                Specifies the size (in bytes) of the block of data to pass to
                each call to transform(). For Tiger the blockSize is 64.

        ***********************************************************************/

        protected override uint blockSize() { return 64; }

        /***********************************************************************

                Length padding size

                Returns:
                the length padding size

                Remarks:
                Specifies the size (in bytes) of the padding which uses the
                length of the data which has been ciphered, this padding is
                carried out by the padLength method. For Tiger the addSize is 8.

        ***********************************************************************/

        protected uint addSize()   { return 8;  }

        /***********************************************************************

                Pads the cipher data

                Params:
                data = a slice of the cipher buffer to fill with padding

                Remarks:
                Fills the passed buffer slice with the appropriate padding for
                the final call to transform(). This padding will fill the cipher
                buffer up to blockSize()-addSize().

        ***********************************************************************/

        protected override void padMessage(ubyte[] at)
        {
                at[0] = padChar;
                at[1..at.length] = 0;
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

        protected override void padLength(ubyte[] at, ulong length)
        {
                length <<= 3;
                littleEndian64((cast(ubyte*)&length)[0..8],cast(ulong[]) at); 
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
                ulong tmpa,a,b,c;
                ulong[8] x;
                uint i;

                littleEndian64(input,x);

                a = context[0];
                b = context[1];
                c = context[2];

                for(i = 0; i < npass; i++) {
                        if (i > 0) keySchedule(x);
                        pass(a,b,c,x,(i==0)?5:(i==1)?7:9);
                        tmpa = a; a = c; c = b; b = tmpa;
                }

                context[0] = a ^ context[0];
                context[1] = b - context[1];
                context[2] = c + context[2];

                x[] = 0;
        }

        /***********************************************************************

        ***********************************************************************/

        private static ubyte getByte(ulong c, uint b1, uint b2 = 0)
        {
                return cast(ubyte) (c >> (b1*8) >> (b2*8));
        }

        /***********************************************************************

        ***********************************************************************/

        private static void round(inout ulong a, inout ulong b, inout ulong c, ulong x, ulong mul)
        {
                c ^= x;
                a -= t1[getByte(c,0)] ^ t2[getByte(c,2)] ^ t3[getByte(c,4)] ^ t4[getByte(c,4,2)];
                b += t4[getByte(c,1)] ^ t3[getByte(c,3)] ^ t2[getByte(c,4,1)] ^ t1[getByte(c,4,3)];
                b *= mul;
        }

        /***********************************************************************

        ***********************************************************************/

        private static void pass(inout ulong a, inout ulong b, inout ulong c, ulong[8] x, ulong mul)
        {
                round(a,b,c,x[0],mul);
                round(b,c,a,x[1],mul);
                round(c,a,b,x[2],mul);
                round(a,b,c,x[3],mul);
                round(b,c,a,x[4],mul);
                round(c,a,b,x[5],mul);
                round(a,b,c,x[6],mul);
                round(b,c,a,x[7],mul);
        }

        /***********************************************************************

        ***********************************************************************/

        private static void keySchedule(ulong[8] x)
        {
                x[0] -= x[7] ^ 0xA5A5A5A5A5A5A5A5;
                x[1] ^= x[0];
                x[2] += x[1];
                x[3] -= x[2] ^ ((~x[1])<<19);
                x[4] ^= x[3];
                x[5] += x[4];
                x[6] -= x[5] ^ ((~x[4])>>23);
                x[7] ^= x[6];
                x[0] += x[7];
                x[1] -= x[0] ^ ((~x[7])<<19);
                x[2] ^= x[1];
                x[3] += x[2];
                x[4] -= x[3] ^ ((~x[2])>>23);
                x[5] ^= x[4];
                x[6] += x[5];
                x[7] -= x[6] ^ 0x0123456789ABCDEF;
        }

        /***********************************************************************

        ***********************************************************************/

        private static ulong[] t1() { return table[0..256]; }
        private static ulong[] t2() { return table[256..512]; }
        private static ulong[] t3() { return table[512..768]; }
        private static ulong[] t4() { return table[768..1024]; }
}


/*******************************************************************************

*******************************************************************************/

private static ulong[1024] table = 
[
    0x02aab17cf7e90c5e   /*    0 */,    0xac424b03e243a8ec   /*    1 */,
    0x72cd5be30dd5fcd3   /*    2 */,    0x6d019b93f6f97f3a   /*    3 */,
    0xcd9978ffd21f9193   /*    4 */,    0x7573a1c9708029e2   /*    5 */,
    0xb164326b922a83c3   /*    6 */,    0x46883eee04915870   /*    7 */,
    0xeaace3057103ece6   /*    8 */,    0xc54169b808a3535c   /*    9 */,
    0x4ce754918ddec47c   /*   10 */,    0x0aa2f4dfdc0df40c   /*   11 */,
    0x10b76f18a74dbefa   /*   12 */,    0xc6ccb6235ad1ab6a   /*   13 */,
    0x13726121572fe2ff   /*   14 */,    0x1a488c6f199d921e   /*   15 */,
    0x4bc9f9f4da0007ca   /*   16 */,    0x26f5e6f6e85241c7   /*   17 */,
    0x859079dbea5947b6   /*   18 */,    0x4f1885c5c99e8c92   /*   19 */,
    0xd78e761ea96f864b   /*   20 */,    0x8e36428c52b5c17d   /*   21 */,
    0x69cf6827373063c1   /*   22 */,    0xb607c93d9bb4c56e   /*   23 */,
    0x7d820e760e76b5ea   /*   24 */,    0x645c9cc6f07fdc42   /*   25 */,
    0xbf38a078243342e0   /*   26 */,    0x5f6b343c9d2e7d04   /*   27 */,
    0xf2c28aeb600b0ec6   /*   28 */,    0x6c0ed85f7254bcac   /*   29 */,
    0x71592281a4db4fe5   /*   30 */,    0x1967fa69ce0fed9f   /*   31 */,
    0xfd5293f8b96545db   /*   32 */,    0xc879e9d7f2a7600b   /*   33 */,
    0x860248920193194e   /*   34 */,    0xa4f9533b2d9cc0b3   /*   35 */,
    0x9053836c15957613   /*   36 */,    0xdb6dcf8afc357bf1   /*   37 */,
    0x18beea7a7a370f57   /*   38 */,    0x037117ca50b99066   /*   39 */,
    0x6ab30a9774424a35   /*   40 */,    0xf4e92f02e325249b   /*   41 */,
    0x7739db07061ccae1   /*   42 */,    0xd8f3b49ceca42a05   /*   43 */,
    0xbd56be3f51382f73   /*   44 */,    0x45faed5843b0bb28   /*   45 */,
    0x1c813d5c11bf1f83   /*   46 */,    0x8af0e4b6d75fa169   /*   47 */,
    0x33ee18a487ad9999   /*   48 */,    0x3c26e8eab1c94410   /*   49 */,
    0xb510102bc0a822f9   /*   50 */,    0x141eef310ce6123b   /*   51 */,
    0xfc65b90059ddb154   /*   52 */,    0xe0158640c5e0e607   /*   53 */,
    0x884e079826c3a3cf   /*   54 */,    0x930d0d9523c535fd   /*   55 */,
    0x35638d754e9a2b00   /*   56 */,    0x4085fccf40469dd5   /*   57 */,
    0xc4b17ad28be23a4c   /*   58 */,    0xcab2f0fc6a3e6a2e   /*   59 */,
    0x2860971a6b943fcd   /*   60 */,    0x3dde6ee212e30446   /*   61 */,
    0x6222f32ae01765ae   /*   62 */,    0x5d550bb5478308fe   /*   63 */,
    0xa9efa98da0eda22a   /*   64 */,    0xc351a71686c40da7   /*   65 */,
    0x1105586d9c867c84   /*   66 */,    0xdcffee85fda22853   /*   67 */,
    0xccfbd0262c5eef76   /*   68 */,    0xbaf294cb8990d201   /*   69 */,
    0xe69464f52afad975   /*   70 */,    0x94b013afdf133e14   /*   71 */,
    0x06a7d1a32823c958   /*   72 */,    0x6f95fe5130f61119   /*   73 */,
    0xd92ab34e462c06c0   /*   74 */,    0xed7bde33887c71d2   /*   75 */,
    0x79746d6e6518393e   /*   76 */,    0x5ba419385d713329   /*   77 */,
    0x7c1ba6b948a97564   /*   78 */,    0x31987c197bfdac67   /*   79 */,
    0xde6c23c44b053d02   /*   80 */,    0x581c49fed002d64d   /*   81 */,
    0xdd474d6338261571   /*   82 */,    0xaa4546c3e473d062   /*   83 */,
    0x928fce349455f860   /*   84 */,    0x48161bbacaab94d9   /*   85 */,
    0x63912430770e6f68   /*   86 */,    0x6ec8a5e602c6641c   /*   87 */,
    0x87282515337ddd2b   /*   88 */,    0x2cda6b42034b701b   /*   89 */,
    0xb03d37c181cb096d   /*   90 */,    0xe108438266c71c6f   /*   91 */,
    0x2b3180c7eb51b255   /*   92 */,    0xdf92b82f96c08bbc   /*   93 */,
    0x5c68c8c0a632f3ba   /*   94 */,    0x5504cc861c3d0556   /*   95 */,
    0xabbfa4e55fb26b8f   /*   96 */,    0x41848b0ab3baceb4   /*   97 */,
    0xb334a273aa445d32   /*   98 */,    0xbca696f0a85ad881   /*   99 */,
    0x24f6ec65b528d56c   /*  100 */,    0x0ce1512e90f4524a   /*  101 */,
    0x4e9dd79d5506d35a   /*  102 */,    0x258905fac6ce9779   /*  103 */,
    0x2019295b3e109b33   /*  104 */,    0xf8a9478b73a054cc   /*  105 */,
    0x2924f2f934417eb0   /*  106 */,    0x3993357d536d1bc4   /*  107 */,
    0x38a81ac21db6ff8b   /*  108 */,    0x47c4fbf17d6016bf   /*  109 */,
    0x1e0faadd7667e3f5   /*  110 */,    0x7abcff62938beb96   /*  111 */,
    0xa78dad948fc179c9   /*  112 */,    0x8f1f98b72911e50d   /*  113 */,
    0x61e48eae27121a91   /*  114 */,    0x4d62f7ad31859808   /*  115 */,
    0xeceba345ef5ceaeb   /*  116 */,    0xf5ceb25ebc9684ce   /*  117 */,
    0xf633e20cb7f76221   /*  118 */,    0xa32cdf06ab8293e4   /*  119 */,
    0x985a202ca5ee2ca4   /*  120 */,    0xcf0b8447cc8a8fb1   /*  121 */,
    0x9f765244979859a3   /*  122 */,    0xa8d516b1a1240017   /*  123 */,
    0x0bd7ba3ebb5dc726   /*  124 */,    0xe54bca55b86adb39   /*  125 */,
    0x1d7a3afd6c478063   /*  126 */,    0x519ec608e7669edd   /*  127 */,
    0x0e5715a2d149aa23   /*  128 */,    0x177d4571848ff194   /*  129 */,
    0xeeb55f3241014c22   /*  130 */,    0x0f5e5ca13a6e2ec2   /*  131 */,
    0x8029927b75f5c361   /*  132 */,    0xad139fabc3d6e436   /*  133 */,
    0x0d5df1a94ccf402f   /*  134 */,    0x3e8bd948bea5dfc8   /*  135 */,
    0xa5a0d357bd3ff77e   /*  136 */,    0xa2d12e251f74f645   /*  137 */,
    0x66fd9e525e81a082   /*  138 */,    0x2e0c90ce7f687a49   /*  139 */,
    0xc2e8bcbeba973bc5   /*  140 */,    0x000001bce509745f   /*  141 */,
    0x423777bbe6dab3d6   /*  142 */,    0xd1661c7eaef06eb5   /*  143 */,
    0xa1781f354daacfd8   /*  144 */,    0x2d11284a2b16affc   /*  145 */,
    0xf1fc4f67fa891d1f   /*  146 */,    0x73ecc25dcb920ada   /*  147 */,
    0xae610c22c2a12651   /*  148 */,    0x96e0a810d356b78a   /*  149 */,
    0x5a9a381f2fe7870f   /*  150 */,    0xd5ad62ede94e5530   /*  151 */,
    0xd225e5e8368d1427   /*  152 */,    0x65977b70c7af4631   /*  153 */,
    0x99f889b2de39d74f   /*  154 */,    0x233f30bf54e1d143   /*  155 */,
    0x9a9675d3d9a63c97   /*  156 */,    0x5470554ff334f9a8   /*  157 */,
    0x166acb744a4f5688   /*  158 */,    0x70c74caab2e4aead   /*  159 */,
    0xf0d091646f294d12   /*  160 */,    0x57b82a89684031d1   /*  161 */,
    0xefd95a5a61be0b6b   /*  162 */,    0x2fbd12e969f2f29a   /*  163 */,
    0x9bd37013feff9fe8   /*  164 */,    0x3f9b0404d6085a06   /*  165 */,
    0x4940c1f3166cfe15   /*  166 */,    0x09542c4dcdf3defb   /*  167 */,
    0xb4c5218385cd5ce3   /*  168 */,    0xc935b7dc4462a641   /*  169 */,
    0x3417f8a68ed3b63f   /*  170 */,    0xb80959295b215b40   /*  171 */,
    0xf99cdaef3b8c8572   /*  172 */,    0x018c0614f8fcb95d   /*  173 */,
    0x1b14accd1a3acdf3   /*  174 */,    0x84d471f200bb732d   /*  175 */,
    0xc1a3110e95e8da16   /*  176 */,    0x430a7220bf1a82b8   /*  177 */,
    0xb77e090d39df210e   /*  178 */,    0x5ef4bd9f3cd05e9d   /*  179 */,
    0x9d4ff6da7e57a444   /*  180 */,    0xda1d60e183d4a5f8   /*  181 */,
    0xb287c38417998e47   /*  182 */,    0xfe3edc121bb31886   /*  183 */,
    0xc7fe3ccc980ccbef   /*  184 */,    0xe46fb590189bfd03   /*  185 */,
    0x3732fd469a4c57dc   /*  186 */,    0x7ef700a07cf1ad65   /*  187 */,
    0x59c64468a31d8859   /*  188 */,    0x762fb0b4d45b61f6   /*  189 */,
    0x155baed099047718   /*  190 */,    0x68755e4c3d50baa6   /*  191 */,
    0xe9214e7f22d8b4df   /*  192 */,    0x2addbf532eac95f4   /*  193 */,
    0x32ae3909b4bd0109   /*  194 */,    0x834df537b08e3450   /*  195 */,
    0xfa209da84220728d   /*  196 */,    0x9e691d9b9efe23f7   /*  197 */,
    0x0446d288c4ae8d7f   /*  198 */,    0x7b4cc524e169785b   /*  199 */,
    0x21d87f0135ca1385   /*  200 */,    0xcebb400f137b8aa5   /*  201 */,
    0x272e2b66580796be   /*  202 */,    0x3612264125c2b0de   /*  203 */,
    0x057702bdad1efbb2   /*  204 */,    0xd4babb8eacf84be9   /*  205 */,
    0x91583139641bc67b   /*  206 */,    0x8bdc2de08036e024   /*  207 */,
    0x603c8156f49f68ed   /*  208 */,    0xf7d236f7dbef5111   /*  209 */,
    0x9727c4598ad21e80   /*  210 */,    0xa08a0896670a5fd7   /*  211 */,
    0xcb4a8f4309eba9cb   /*  212 */,    0x81af564b0f7036a1   /*  213 */,
    0xc0b99aa778199abd   /*  214 */,    0x959f1ec83fc8e952   /*  215 */,
    0x8c505077794a81b9   /*  216 */,    0x3acaaf8f056338f0   /*  217 */,
    0x07b43f50627a6778   /*  218 */,    0x4a44ab49f5eccc77   /*  219 */,
    0x3bc3d6e4b679ee98   /*  220 */,    0x9cc0d4d1cf14108c   /*  221 */,
    0x4406c00b206bc8a0   /*  222 */,    0x82a18854c8d72d89   /*  223 */,
    0x67e366b35c3c432c   /*  224 */,    0xb923dd61102b37f2   /*  225 */,
    0x56ab2779d884271d   /*  226 */,    0xbe83e1b0ff1525af   /*  227 */,
    0xfb7c65d4217e49a9   /*  228 */,    0x6bdbe0e76d48e7d4   /*  229 */,
    0x08df828745d9179e   /*  230 */,    0x22ea6a9add53bd34   /*  231 */,
    0xe36e141c5622200a   /*  232 */,    0x7f805d1b8cb750ee   /*  233 */,
    0xafe5c7a59f58e837   /*  234 */,    0xe27f996a4fb1c23c   /*  235 */,
    0xd3867dfb0775f0d0   /*  236 */,    0xd0e673de6e88891a   /*  237 */,
    0x123aeb9eafb86c25   /*  238 */,    0x30f1d5d5c145b895   /*  239 */,
    0xbb434a2dee7269e7   /*  240 */,    0x78cb67ecf931fa38   /*  241 */,
    0xf33b0372323bbf9c   /*  242 */,    0x52d66336fb279c74   /*  243 */,
    0x505f33ac0afb4eaa   /*  244 */,    0xe8a5cd99a2cce187   /*  245 */,
    0x534974801e2d30bb   /*  246 */,    0x8d2d5711d5876d90   /*  247 */,
    0x1f1a412891bc038e   /*  248 */,    0xd6e2e71d82e56648   /*  249 */,
    0x74036c3a497732b7   /*  250 */,    0x89b67ed96361f5ab   /*  251 */,
    0xffed95d8f1ea02a2   /*  252 */,    0xe72b3bd61464d43d   /*  253 */,
    0xa6300f170bdc4820   /*  254 */,    0xebc18760ed78a77a   /*  255 */,
    0xe6a6be5a05a12138   /*  256 */,    0xb5a122a5b4f87c98   /*  257 */,
    0x563c6089140b6990   /*  258 */,    0x4c46cb2e391f5dd5   /*  259 */,
    0xd932addbc9b79434   /*  260 */,    0x08ea70e42015aff5   /*  261 */,
    0xd765a6673e478cf1   /*  262 */,    0xc4fb757eab278d99   /*  263 */,
    0xdf11c6862d6e0692   /*  264 */,    0xddeb84f10d7f3b16   /*  265 */,
    0x6f2ef604a665ea04   /*  266 */,    0x4a8e0f0ff0e0dfb3   /*  267 */,
    0xa5edeef83dbcba51   /*  268 */,    0xfc4f0a2a0ea4371e   /*  269 */,
    0xe83e1da85cb38429   /*  270 */,    0xdc8ff882ba1b1ce2   /*  271 */,
    0xcd45505e8353e80d   /*  272 */,    0x18d19a00d4db0717   /*  273 */,
    0x34a0cfeda5f38101   /*  274 */,    0x0be77e518887caf2   /*  275 */,
    0x1e341438b3c45136   /*  276 */,    0xe05797f49089ccf9   /*  277 */,
    0xffd23f9df2591d14   /*  278 */,    0x543dda228595c5cd   /*  279 */,
    0x661f81fd99052a33   /*  280 */,    0x8736e641db0f7b76   /*  281 */,
    0x15227725418e5307   /*  282 */,    0xe25f7f46162eb2fa   /*  283 */,
    0x48a8b2126c13d9fe   /*  284 */,    0xafdc541792e76eea   /*  285 */,
    0x03d912bfc6d1898f   /*  286 */,    0x31b1aafa1b83f51b   /*  287 */,
    0xf1ac2796e42ab7d9   /*  288 */,    0x40a3a7d7fcd2ebac   /*  289 */,
    0x1056136d0afbbcc5   /*  290 */,    0x7889e1dd9a6d0c85   /*  291 */,
    0xd33525782a7974aa   /*  292 */,    0xa7e25d09078ac09b   /*  293 */,
    0xbd4138b3eac6edd0   /*  294 */,    0x920abfbe71eb9e70   /*  295 */,
    0xa2a5d0f54fc2625c   /*  296 */,    0xc054e36b0b1290a3   /*  297 */,
    0xf6dd59ff62fe932b   /*  298 */,    0x3537354511a8ac7d   /*  299 */,
    0xca845e9172fadcd4   /*  300 */,    0x84f82b60329d20dc   /*  301 */,
    0x79c62ce1cd672f18   /*  302 */,    0x8b09a2add124642c   /*  303 */,
    0xd0c1e96a19d9e726   /*  304 */,    0x5a786a9b4ba9500c   /*  305 */,
    0x0e020336634c43f3   /*  306 */,    0xc17b474aeb66d822   /*  307 */,
    0x6a731ae3ec9baac2   /*  308 */,    0x8226667ae0840258   /*  309 */,
    0x67d4567691caeca5   /*  310 */,    0x1d94155c4875adb5   /*  311 */,
    0x6d00fd985b813fdf   /*  312 */,    0x51286efcb774cd06   /*  313 */,
    0x5e8834471fa744af   /*  314 */,    0xf72ca0aee761ae2e   /*  315 */,
    0xbe40e4cdaee8e09a   /*  316 */,    0xe9970bbb5118f665   /*  317 */,
    0x726e4beb33df1964   /*  318 */,    0x703b000729199762   /*  319 */,
    0x4631d816f5ef30a7   /*  320 */,    0xb880b5b51504a6be   /*  321 */,
    0x641793c37ed84b6c   /*  322 */,    0x7b21ed77f6e97d96   /*  323 */,
    0x776306312ef96b73   /*  324 */,    0xae528948e86ff3f4   /*  325 */,
    0x53dbd7f286a3f8f8   /*  326 */,    0x16cadce74cfc1063   /*  327 */,
    0x005c19bdfa52c6dd   /*  328 */,    0x68868f5d64d46ad3   /*  329 */,
    0x3a9d512ccf1e186a   /*  330 */,    0x367e62c2385660ae   /*  331 */,
    0xe359e7ea77dcb1d7   /*  332 */,    0x526c0773749abe6e   /*  333 */,
    0x735ae5f9d09f734b   /*  334 */,    0x493fc7cc8a558ba8   /*  335 */,
    0xb0b9c1533041ab45   /*  336 */,    0x321958ba470a59bd   /*  337 */,
    0x852db00b5f46c393   /*  338 */,    0x91209b2bd336b0e5   /*  339 */,
    0x6e604f7d659ef19f   /*  340 */,    0xb99a8ae2782ccb24   /*  341 */,
    0xccf52ab6c814c4c7   /*  342 */,    0x4727d9afbe11727b   /*  343 */,
    0x7e950d0c0121b34d   /*  344 */,    0x756f435670ad471f   /*  345 */,
    0xf5add442615a6849   /*  346 */,    0x4e87e09980b9957a   /*  347 */,
    0x2acfa1df50aee355   /*  348 */,    0xd898263afd2fd556   /*  349 */,
    0xc8f4924dd80c8fd6   /*  350 */,    0xcf99ca3d754a173a   /*  351 */,
    0xfe477bacaf91bf3c   /*  352 */,    0xed5371f6d690c12d   /*  353 */,
    0x831a5c285e687094   /*  354 */,    0xc5d3c90a3708a0a4   /*  355 */,
    0x0f7f903717d06580   /*  356 */,    0x19f9bb13b8fdf27f   /*  357 */,
    0xb1bd6f1b4d502843   /*  358 */,    0x1c761ba38fff4012   /*  359 */,
    0x0d1530c4e2e21f3b   /*  360 */,    0x8943ce69a7372c8a   /*  361 */,
    0xe5184e11feb5ce66   /*  362 */,    0x618bdb80bd736621   /*  363 */,
    0x7d29bad68b574d0b   /*  364 */,    0x81bb613e25e6fe5b   /*  365 */,
    0x071c9c10bc07913f   /*  366 */,    0xc7beeb7909ac2d97   /*  367 */,
    0xc3e58d353bc5d757   /*  368 */,    0xeb017892f38f61e8   /*  369 */,
    0xd4effb9c9b1cc21a   /*  370 */,    0x99727d26f494f7ab   /*  371 */,
    0xa3e063a2956b3e03   /*  372 */,    0x9d4a8b9a4aa09c30   /*  373 */,
    0x3f6ab7d500090fb4   /*  374 */,    0x9cc0f2a057268ac0   /*  375 */,
    0x3dee9d2dedbf42d1   /*  376 */,    0x330f49c87960a972   /*  377 */,
    0xc6b2720287421b41   /*  378 */,    0x0ac59ec07c00369c   /*  379 */,
    0xef4eac49cb353425   /*  380 */,    0xf450244eef0129d8   /*  381 */,
    0x8acc46e5caf4deb6   /*  382 */,    0x2ffeab63989263f7   /*  383 */,
    0x8f7cb9fe5d7a4578   /*  384 */,    0x5bd8f7644e634635   /*  385 */,
    0x427a7315bf2dc900   /*  386 */,    0x17d0c4aa2125261c   /*  387 */,
    0x3992486c93518e50   /*  388 */,    0xb4cbfee0a2d7d4c3   /*  389 */,
    0x7c75d6202c5ddd8d   /*  390 */,    0xdbc295d8e35b6c61   /*  391 */,
    0x60b369d302032b19   /*  392 */,    0xce42685fdce44132   /*  393 */,
    0x06f3ddb9ddf65610   /*  394 */,    0x8ea4d21db5e148f0   /*  395 */,
    0x20b0fce62fcd496f   /*  396 */,    0x2c1b912358b0ee31   /*  397 */,
    0xb28317b818f5a308   /*  398 */,    0xa89c1e189ca6d2cf   /*  399 */,
    0x0c6b18576aaadbc8   /*  400 */,    0xb65deaa91299fae3   /*  401 */,
    0xfb2b794b7f1027e7   /*  402 */,    0x04e4317f443b5beb   /*  403 */,
    0x4b852d325939d0a6   /*  404 */,    0xd5ae6beefb207ffc   /*  405 */,
    0x309682b281c7d374   /*  406 */,    0xbae309a194c3b475   /*  407 */,
    0x8cc3f97b13b49f05   /*  408 */,    0x98a9422ff8293967   /*  409 */,
    0x244b16b01076ff7c   /*  410 */,    0xf8bf571c663d67ee   /*  411 */,
    0x1f0d6758eee30da1   /*  412 */,    0xc9b611d97adeb9b7   /*  413 */,
    0xb7afd5887b6c57a2   /*  414 */,    0x6290ae846b984fe1   /*  415 */,
    0x94df4cdeacc1a5fd   /*  416 */,    0x058a5bd1c5483aff   /*  417 */,
    0x63166cc142ba3c37   /*  418 */,    0x8db8526eb2f76f40   /*  419 */,
    0xe10880036f0d6d4e   /*  420 */,    0x9e0523c9971d311d   /*  421 */,
    0x45ec2824cc7cd691   /*  422 */,    0x575b8359e62382c9   /*  423 */,
    0xfa9e400dc4889995   /*  424 */,    0xd1823ecb45721568   /*  425 */,
    0xdafd983b8206082f   /*  426 */,    0xaa7d29082386a8cb   /*  427 */,
    0x269fcd4403b87588   /*  428 */,    0x1b91f5f728bdd1e0   /*  429 */,
    0xe4669f39040201f6   /*  430 */,    0x7a1d7c218cf04ade   /*  431 */,
    0x65623c29d79ce5ce   /*  432 */,    0x2368449096c00bb1   /*  433 */,
    0xab9bf1879da503ba   /*  434 */,    0xbc23ecb1a458058e   /*  435 */,
    0x9a58df01bb401ecc   /*  436 */,    0xa070e868a85f143d   /*  437 */,
    0x4ff188307df2239e   /*  438 */,    0x14d565b41a641183   /*  439 */,
    0xee13337452701602   /*  440 */,    0x950e3dcf3f285e09   /*  441 */,
    0x59930254b9c80953   /*  442 */,    0x3bf299408930da6d   /*  443 */,
    0xa955943f53691387   /*  444 */,    0xa15edecaa9cb8784   /*  445 */,
    0x29142127352be9a0   /*  446 */,    0x76f0371fff4e7afb   /*  447 */,
    0x0239f450274f2228   /*  448 */,    0xbb073af01d5e868b   /*  449 */,
    0xbfc80571c10e96c1   /*  450 */,    0xd267088568222e23   /*  451 */,
    0x9671a3d48e80b5b0   /*  452 */,    0x55b5d38ae193bb81   /*  453 */,
    0x693ae2d0a18b04b8   /*  454 */,    0x5c48b4ecadd5335f   /*  455 */,
    0xfd743b194916a1ca   /*  456 */,    0x2577018134be98c4   /*  457 */,
    0xe77987e83c54a4ad   /*  458 */,    0x28e11014da33e1b9   /*  459 */,
    0x270cc59e226aa213   /*  460 */,    0x71495f756d1a5f60   /*  461 */,
    0x9be853fb60afef77   /*  462 */,    0xadc786a7f7443dbf   /*  463 */,
    0x0904456173b29a82   /*  464 */,    0x58bc7a66c232bd5e   /*  465 */,
    0xf306558c673ac8b2   /*  466 */,    0x41f639c6b6c9772a   /*  467 */,
    0x216defe99fda35da   /*  468 */,    0x11640cc71c7be615   /*  469 */,
    0x93c43694565c5527   /*  470 */,    0xea038e6246777839   /*  471 */,
    0xf9abf3ce5a3e2469   /*  472 */,    0x741e768d0fd312d2   /*  473 */,
    0x0144b883ced652c6   /*  474 */,    0xc20b5a5ba33f8552   /*  475 */,
    0x1ae69633c3435a9d   /*  476 */,    0x97a28ca4088cfdec   /*  477 */,
    0x8824a43c1e96f420   /*  478 */,    0x37612fa66eeea746   /*  479 */,
    0x6b4cb165f9cf0e5a   /*  480 */,    0x43aa1c06a0abfb4a   /*  481 */,
    0x7f4dc26ff162796b   /*  482 */,    0x6cbacc8e54ed9b0f   /*  483 */,
    0xa6b7ffefd2bb253e   /*  484 */,    0x2e25bc95b0a29d4f   /*  485 */,
    0x86d6a58bdef1388c   /*  486 */,    0xded74ac576b6f054   /*  487 */,
    0x8030bdbc2b45805d   /*  488 */,    0x3c81af70e94d9289   /*  489 */,
    0x3eff6dda9e3100db   /*  490 */,    0xb38dc39fdfcc8847   /*  491 */,
    0x123885528d17b87e   /*  492 */,    0xf2da0ed240b1b642   /*  493 */,
    0x44cefadcd54bf9a9   /*  494 */,    0x1312200e433c7ee6   /*  495 */,
    0x9ffcc84f3a78c748   /*  496 */,    0xf0cd1f72248576bb   /*  497 */,
    0xec6974053638cfe4   /*  498 */,    0x2ba7b67c0cec4e4c   /*  499 */,
    0xac2f4df3e5ce32ed   /*  500 */,    0xcb33d14326ea4c11   /*  501 */,
    0xa4e9044cc77e58bc   /*  502 */,    0x5f513293d934fcef   /*  503 */,
    0x5dc9645506e55444   /*  504 */,    0x50de418f317de40a   /*  505 */,
    0x388cb31a69dde259   /*  506 */,    0x2db4a83455820a86   /*  507 */,
    0x9010a91e84711ae9   /*  508 */,    0x4df7f0b7b1498371   /*  509 */,
    0xd62a2eabc0977179   /*  510 */,    0x22fac097aa8d5c0e   /*  511 */,
    0xf49fcc2ff1daf39b   /*  512 */,    0x487fd5c66ff29281   /*  513 */,
    0xe8a30667fcdca83f   /*  514 */,    0x2c9b4be3d2fcce63   /*  515 */,
    0xda3ff74b93fbbbc2   /*  516 */,    0x2fa165d2fe70ba66   /*  517 */,
    0xa103e279970e93d4   /*  518 */,    0xbecdec77b0e45e71   /*  519 */,
    0xcfb41e723985e497   /*  520 */,    0xb70aaa025ef75017   /*  521 */,
    0xd42309f03840b8e0   /*  522 */,    0x8efc1ad035898579   /*  523 */,
    0x96c6920be2b2abc5   /*  524 */,    0x66af4163375a9172   /*  525 */,
    0x2174abdcca7127fb   /*  526 */,    0xb33ccea64a72ff41   /*  527 */,
    0xf04a4933083066a5   /*  528 */,    0x8d970acdd7289af5   /*  529 */,
    0x8f96e8e031c8c25e   /*  530 */,    0xf3fec02276875d47   /*  531 */,
    0xec7bf310056190dd   /*  532 */,    0xf5adb0aebb0f1491   /*  533 */,
    0x9b50f8850fd58892   /*  534 */,    0x4975488358b74de8   /*  535 */,
    0xa3354ff691531c61   /*  536 */,    0x0702bbe481d2c6ee   /*  537 */,
    0x89fb24057deded98   /*  538 */,    0xac3075138596e902   /*  539 */,
    0x1d2d3580172772ed   /*  540 */,    0xeb738fc28e6bc30d   /*  541 */,
    0x5854ef8f63044326   /*  542 */,    0x9e5c52325add3bbe   /*  543 */,
    0x90aa53cf325c4623   /*  544 */,    0xc1d24d51349dd067   /*  545 */,
    0x2051cfeea69ea624   /*  546 */,    0x13220f0a862e7e4f   /*  547 */,
    0xce39399404e04864   /*  548 */,    0xd9c42ca47086fcb7   /*  549 */,
    0x685ad2238a03e7cc   /*  550 */,    0x066484b2ab2ff1db   /*  551 */,
    0xfe9d5d70efbf79ec   /*  552 */,    0x5b13b9dd9c481854   /*  553 */,
    0x15f0d475ed1509ad   /*  554 */,    0x0bebcd060ec79851   /*  555 */,
    0xd58c6791183ab7f8   /*  556 */,    0xd1187c5052f3eee4   /*  557 */,
    0xc95d1192e54e82ff   /*  558 */,    0x86eea14cb9ac6ca2   /*  559 */,
    0x3485beb153677d5d   /*  560 */,    0xdd191d781f8c492a   /*  561 */,
    0xf60866baa784ebf9   /*  562 */,    0x518f643ba2d08c74   /*  563 */,
    0x8852e956e1087c22   /*  564 */,    0xa768cb8dc410ae8d   /*  565 */,
    0x38047726bfec8e1a   /*  566 */,    0xa67738b4cd3b45aa   /*  567 */,
    0xad16691cec0dde19   /*  568 */,    0xc6d4319380462e07   /*  569 */,
    0xc5a5876d0ba61938   /*  570 */,    0x16b9fa1fa58fd840   /*  571 */,
    0x188ab1173ca74f18   /*  572 */,    0xabda2f98c99c021f   /*  573 */,
    0x3e0580ab134ae816   /*  574 */,    0x5f3b05b773645abb   /*  575 */,
    0x2501a2be5575f2f6   /*  576 */,    0x1b2f74004e7e8ba9   /*  577 */,
    0x1cd7580371e8d953   /*  578 */,    0x7f6ed89562764e30   /*  579 */,
    0xb15926ff596f003d   /*  580 */,    0x9f65293da8c5d6b9   /*  581 */,
    0x6ecef04dd690f84c   /*  582 */,    0x4782275fff33af88   /*  583 */,
    0xe41433083f820801   /*  584 */,    0xfd0dfe409a1af9b5   /*  585 */,
    0x4325a3342cdb396b   /*  586 */,    0x8ae77e62b301b252   /*  587 */,
    0xc36f9e9f6655615a   /*  588 */,    0x85455a2d92d32c09   /*  589 */,
    0xf2c7dea949477485   /*  590 */,    0x63cfb4c133a39eba   /*  591 */,
    0x83b040cc6ebc5462   /*  592 */,    0x3b9454c8fdb326b0   /*  593 */,
    0x56f56a9e87ffd78c   /*  594 */,    0x2dc2940d99f42bc6   /*  595 */,
    0x98f7df096b096e2d   /*  596 */,    0x19a6e01e3ad852bf   /*  597 */,
    0x42a99ccbdbd4b40b   /*  598 */,    0xa59998af45e9c559   /*  599 */,
    0x366295e807d93186   /*  600 */,    0x6b48181bfaa1f773   /*  601 */,
    0x1fec57e2157a0a1d   /*  602 */,    0x4667446af6201ad5   /*  603 */,
    0xe615ebcacfb0f075   /*  604 */,    0xb8f31f4f68290778   /*  605 */,
    0x22713ed6ce22d11e   /*  606 */,    0x3057c1a72ec3c93b   /*  607 */,
    0xcb46acc37c3f1f2f   /*  608 */,    0xdbb893fd02aaf50e   /*  609 */,
    0x331fd92e600b9fcf   /*  610 */,    0xa498f96148ea3ad6   /*  611 */,
    0xa8d8426e8b6a83ea   /*  612 */,    0xa089b274b7735cdc   /*  613 */,
    0x87f6b3731e524a11   /*  614 */,    0x118808e5cbc96749   /*  615 */,
    0x9906e4c7b19bd394   /*  616 */,    0xafed7f7e9b24a20c   /*  617 */,
    0x6509eadeeb3644a7   /*  618 */,    0x6c1ef1d3e8ef0ede   /*  619 */,
    0xb9c97d43e9798fb4   /*  620 */,    0xa2f2d784740c28a3   /*  621 */,
    0x7b8496476197566f   /*  622 */,    0x7a5be3e6b65f069d   /*  623 */,
    0xf96330ed78be6f10   /*  624 */,    0xeee60de77a076a15   /*  625 */,
    0x2b4bee4aa08b9bd0   /*  626 */,    0x6a56a63ec7b8894e   /*  627 */,
    0x02121359ba34fef4   /*  628 */,    0x4cbf99f8283703fc   /*  629 */,
    0x398071350caf30c8   /*  630 */,    0xd0a77a89f017687a   /*  631 */,
    0xf1c1a9eb9e423569   /*  632 */,    0x8c7976282dee8199   /*  633 */,
    0x5d1737a5dd1f7abd   /*  634 */,    0x4f53433c09a9fa80   /*  635 */,
    0xfa8b0c53df7ca1d9   /*  636 */,    0x3fd9dcbc886ccb77   /*  637 */,
    0xc040917ca91b4720   /*  638 */,    0x7dd00142f9d1dcdf   /*  639 */,
    0x8476fc1d4f387b58   /*  640 */,    0x23f8e7c5f3316503   /*  641 */,
    0x032a2244e7e37339   /*  642 */,    0x5c87a5d750f5a74b   /*  643 */,
    0x082b4cc43698992e   /*  644 */,    0xdf917becb858f63c   /*  645 */,
    0x3270b8fc5bf86dda   /*  646 */,    0x10ae72bb29b5dd76   /*  647 */,
    0x576ac94e7700362b   /*  648 */,    0x1ad112dac61efb8f   /*  649 */,
    0x691bc30ec5faa427   /*  650 */,    0xff246311cc327143   /*  651 */,
    0x3142368e30e53206   /*  652 */,    0x71380e31e02ca396   /*  653 */,
    0x958d5c960aad76f1   /*  654 */,    0xf8d6f430c16da536   /*  655 */,
    0xc8ffd13f1be7e1d2   /*  656 */,    0x7578ae66004ddbe1   /*  657 */,
    0x05833f01067be646   /*  658 */,    0xbb34b5ad3bfe586d   /*  659 */,
    0x095f34c9a12b97f0   /*  660 */,    0x247ab64525d60ca8   /*  661 */,
    0xdcdbc6f3017477d1   /*  662 */,    0x4a2e14d4decad24d   /*  663 */,
    0xbdb5e6d9be0a1eeb   /*  664 */,    0x2a7e70f7794301ab   /*  665 */,
    0xdef42d8a270540fd   /*  666 */,    0x01078ec0a34c22c1   /*  667 */,
    0xe5de511af4c16387   /*  668 */,    0x7ebb3a52bd9a330a   /*  669 */,
    0x77697857aa7d6435   /*  670 */,    0x004e831603ae4c32   /*  671 */,
    0xe7a21020ad78e312   /*  672 */,    0x9d41a70c6ab420f2   /*  673 */,
    0x28e06c18ea1141e6   /*  674 */,    0xd2b28cbd984f6b28   /*  675 */,
    0x26b75f6c446e9d83   /*  676 */,    0xba47568c4d418d7f   /*  677 */,
    0xd80badbfe6183d8e   /*  678 */,    0x0e206d7f5f166044   /*  679 */,
    0xe258a43911cbca3e   /*  680 */,    0x723a1746b21dc0bc   /*  681 */,
    0xc7caa854f5d7cdd3   /*  682 */,    0x7cac32883d261d9c   /*  683 */,
    0x7690c26423ba942c   /*  684 */,    0x17e55524478042b8   /*  685 */,
    0xe0be477656a2389f   /*  686 */,    0x4d289b5e67ab2da0   /*  687 */,
    0x44862b9c8fbbfd31   /*  688 */,    0xb47cc8049d141365   /*  689 */,
    0x822c1b362b91c793   /*  690 */,    0x4eb14655fb13dfd8   /*  691 */,
    0x1ecbba0714e2a97b   /*  692 */,    0x6143459d5cde5f14   /*  693 */,
    0x53a8fbf1d5f0ac89   /*  694 */,    0x97ea04d81c5e5b00   /*  695 */,
    0x622181a8d4fdb3f3   /*  696 */,    0xe9bcd341572a1208   /*  697 */,
    0x1411258643cce58a   /*  698 */,    0x9144c5fea4c6e0a4   /*  699 */,
    0x0d33d06565cf620f   /*  700 */,    0x54a48d489f219ca1   /*  701 */,
    0xc43e5eac6d63c821   /*  702 */,    0xa9728b3a72770daf   /*  703 */,
    0xd7934e7b20df87ef   /*  704 */,    0xe35503b61a3e86e5   /*  705 */,
    0xcae321fbc819d504   /*  706 */,    0x129a50b3ac60bfa6   /*  707 */,
    0xcd5e68ea7e9fb6c3   /*  708 */,    0xb01c90199483b1c7   /*  709 */,
    0x3de93cd5c295376c   /*  710 */,    0xaed52edf2ab9ad13   /*  711 */,
    0x2e60f512c0a07884   /*  712 */,    0xbc3d86a3e36210c9   /*  713 */,
    0x35269d9b163951ce   /*  714 */,    0x0c7d6e2ad0cdb5fa   /*  715 */,
    0x59e86297d87f5733   /*  716 */,    0x298ef221898db0e7   /*  717 */,
    0x55000029d1a5aa7e   /*  718 */,    0x8bc08ae1b5061b45   /*  719 */,
    0xc2c31c2b6c92703a   /*  720 */,    0x94cc596baf25ef42   /*  721 */,
    0x0a1d73db22540456   /*  722 */,    0x04b6a0f9d9c4179a   /*  723 */,
    0xeffdafa2ae3d3c60   /*  724 */,    0xf7c8075bb49496c4   /*  725 */,
    0x9cc5c7141d1cd4e3   /*  726 */,    0x78bd1638218e5534   /*  727 */,
    0xb2f11568f850246a   /*  728 */,    0xedfabcfa9502bc29   /*  729 */,
    0x796ce5f2da23051b   /*  730 */,    0xaae128b0dc93537c   /*  731 */,
    0x3a493da0ee4b29ae   /*  732 */,    0xb5df6b2c416895d7   /*  733 */,
    0xfcabbd25122d7f37   /*  734 */,    0x70810b58105dc4b1   /*  735 */,
    0xe10fdd37f7882a90   /*  736 */,    0x524dcab5518a3f5c   /*  737 */,
    0x3c9e85878451255b   /*  738 */,    0x4029828119bd34e2   /*  739 */,
    0x74a05b6f5d3ceccb   /*  740 */,    0xb610021542e13eca   /*  741 */,
    0x0ff979d12f59e2ac   /*  742 */,    0x6037da27e4f9cc50   /*  743 */,
    0x5e92975a0df1847d   /*  744 */,    0xd66de190d3e623fe   /*  745 */,
    0x5032d6b87b568048   /*  746 */,    0x9a36b7ce8235216e   /*  747 */,
    0x80272a7a24f64b4a   /*  748 */,    0x93efed8b8c6916f7   /*  749 */,
    0x37ddbff44cce1555   /*  750 */,    0x4b95db5d4b99bd25   /*  751 */,
    0x92d3fda169812fc0   /*  752 */,    0xfb1a4a9a90660bb6   /*  753 */,
    0x730c196946a4b9b2   /*  754 */,    0x81e289aa7f49da68   /*  755 */,
    0x64669a0f83b1a05f   /*  756 */,    0x27b3ff7d9644f48b   /*  757 */,
    0xcc6b615c8db675b3   /*  758 */,    0x674f20b9bcebbe95   /*  759 */,
    0x6f31238275655982   /*  760 */,    0x5ae488713e45cf05   /*  761 */,
    0xbf619f9954c21157   /*  762 */,    0xeabac46040a8eae9   /*  763 */,
    0x454c6fe9f2c0c1cd   /*  764 */,    0x419cf6496412691c   /*  765 */,
    0xd3dc3bef265b0f70   /*  766 */,    0x6d0e60f5c3578a9e   /*  767 */,
    0x5b0e608526323c55   /*  768 */,    0x1a46c1a9fa1b59f5   /*  769 */,
    0xa9e245a17c4c8ffa   /*  770 */,    0x65ca5159db2955d7   /*  771 */,
    0x05db0a76ce35afc2   /*  772 */,    0x81eac77ea9113d45   /*  773 */,
    0x528ef88ab6ac0a0d   /*  774 */,    0xa09ea253597be3ff   /*  775 */,
    0x430ddfb3ac48cd56   /*  776 */,    0xc4b3a67af45ce46f   /*  777 */,
    0x4ececfd8fbe2d05e   /*  778 */,    0x3ef56f10b39935f0   /*  779 */,
    0x0b22d6829cd619c6   /*  780 */,    0x17fd460a74df2069   /*  781 */,
    0x6cf8cc8e8510ed40   /*  782 */,    0xd6c824bf3a6ecaa7   /*  783 */,
    0x61243d581a817049   /*  784 */,    0x048bacb6bbc163a2   /*  785 */,
    0xd9a38ac27d44cc32   /*  786 */,    0x7fddff5baaf410ab   /*  787 */,
    0xad6d495aa804824b   /*  788 */,    0xe1a6a74f2d8c9f94   /*  789 */,
    0xd4f7851235dee8e3   /*  790 */,    0xfd4b7f886540d893   /*  791 */,
    0x247c20042aa4bfda   /*  792 */,    0x096ea1c517d1327c   /*  793 */,
    0xd56966b4361a6685   /*  794 */,    0x277da5c31221057d   /*  795 */,
    0x94d59893a43acff7   /*  796 */,    0x64f0c51ccdc02281   /*  797 */,
    0x3d33bcc4ff6189db   /*  798 */,    0xe005cb184ce66af1   /*  799 */,
    0xff5ccd1d1db99bea   /*  800 */,    0xb0b854a7fe42980f   /*  801 */,
    0x7bd46a6a718d4b9f   /*  802 */,    0xd10fa8cc22a5fd8c   /*  803 */,
    0xd31484952be4bd31   /*  804 */,    0xc7fa975fcb243847   /*  805 */,
    0x4886ed1e5846c407   /*  806 */,    0x28cddb791eb70b04   /*  807 */,
    0xc2b00be2f573417f   /*  808 */,    0x5c9590452180f877   /*  809 */,
    0x7a6bddfff370eb00   /*  810 */,    0xce509e38d6d9d6a4   /*  811 */,
    0xebeb0f00647fa702   /*  812 */,    0x1dcc06cf76606f06   /*  813 */,
    0xe4d9f28ba286ff0a   /*  814 */,    0xd85a305dc918c262   /*  815 */,
    0x475b1d8732225f54   /*  816 */,    0x2d4fb51668ccb5fe   /*  817 */,
    0xa679b9d9d72bba20   /*  818 */,    0x53841c0d912d43a5   /*  819 */,
    0x3b7eaa48bf12a4e8   /*  820 */,    0x781e0e47f22f1ddf   /*  821 */,
    0xeff20ce60ab50973   /*  822 */,    0x20d261d19dffb742   /*  823 */,
    0x16a12b03062a2e39   /*  824 */,    0x1960eb2239650495   /*  825 */,
    0x251c16fed50eb8b8   /*  826 */,    0x9ac0c330f826016e   /*  827 */,
    0xed152665953e7671   /*  828 */,    0x02d63194a6369570   /*  829 */,
    0x5074f08394b1c987   /*  830 */,    0x70ba598c90b25ce1   /*  831 */,
    0x794a15810b9742f6   /*  832 */,    0x0d5925e9fcaf8c6c   /*  833 */,
    0x3067716cd868744e   /*  834 */,    0x910ab077e8d7731b   /*  835 */,
    0x6a61bbdb5ac42f61   /*  836 */,    0x93513efbf0851567   /*  837 */,
    0xf494724b9e83e9d5   /*  838 */,    0xe887e1985c09648d   /*  839 */,
    0x34b1d3c675370cfd   /*  840 */,    0xdc35e433bc0d255d   /*  841 */,
    0xd0aab84234131be0   /*  842 */,    0x08042a50b48b7eaf   /*  843 */,
    0x9997c4ee44a3ab35   /*  844 */,    0x829a7b49201799d0   /*  845 */,
    0x263b8307b7c54441   /*  846 */,    0x752f95f4fd6a6ca6   /*  847 */,
    0x927217402c08c6e5   /*  848 */,    0x2a8ab754a795d9ee   /*  849 */,
    0xa442f7552f72943d   /*  850 */,    0x2c31334e19781208   /*  851 */,
    0x4fa98d7ceaee6291   /*  852 */,    0x55c3862f665db309   /*  853 */,
    0xbd0610175d53b1f3   /*  854 */,    0x46fe6cb840413f27   /*  855 */,
    0x3fe03792df0cfa59   /*  856 */,    0xcfe700372eb85e8f   /*  857 */,
    0xa7be29e7adbce118   /*  858 */,    0xe544ee5cde8431dd   /*  859 */,
    0x8a781b1b41f1873e   /*  860 */,    0xa5c94c78a0d2f0e7   /*  861 */,
    0x39412e2877b60728   /*  862 */,    0xa1265ef3afc9a62c   /*  863 */,
    0xbcc2770c6a2506c5   /*  864 */,    0x3ab66dd5dce1ce12   /*  865 */,
    0xe65499d04a675b37   /*  866 */,    0x7d8f523481bfd216   /*  867 */,
    0x0f6f64fcec15f389   /*  868 */,    0x74efbe618b5b13c8   /*  869 */,
    0xacdc82b714273e1d   /*  870 */,    0xdd40bfe003199d17   /*  871 */,
    0x37e99257e7e061f8   /*  872 */,    0xfa52626904775aaa   /*  873 */,
    0x8bbbf63a463d56f9   /*  874 */,    0xf0013f1543a26e64   /*  875 */,
    0xa8307e9f879ec898   /*  876 */,    0xcc4c27a4150177cc   /*  877 */,
    0x1b432f2cca1d3348   /*  878 */,    0xde1d1f8f9f6fa013   /*  879 */,
    0x606602a047a7ddd6   /*  880 */,    0xd237ab64cc1cb2c7   /*  881 */,
    0x9b938e7225fcd1d3   /*  882 */,    0xec4e03708e0ff476   /*  883 */,
    0xfeb2fbda3d03c12d   /*  884 */,    0xae0bced2ee43889a   /*  885 */,
    0x22cb8923ebfb4f43   /*  886 */,    0x69360d013cf7396d   /*  887 */,
    0x855e3602d2d4e022   /*  888 */,    0x073805bad01f784c   /*  889 */,
    0x33e17a133852f546   /*  890 */,    0xdf4874058ac7b638   /*  891 */,
    0xba92b29c678aa14a   /*  892 */,    0x0ce89fc76cfaadcd   /*  893 */,
    0x5f9d4e0908339e34   /*  894 */,    0xf1afe9291f5923b9   /*  895 */,
    0x6e3480f60f4a265f   /*  896 */,    0xeebf3a2ab29b841c   /*  897 */,
    0xe21938a88f91b4ad   /*  898 */,    0x57dfeff845c6d3c3   /*  899 */,
    0x2f006b0bf62caaf2   /*  900 */,    0x62f479ef6f75ee78   /*  901 */,
    0x11a55ad41c8916a9   /*  902 */,    0xf229d29084fed453   /*  903 */,
    0x42f1c27b16b000e6   /*  904 */,    0x2b1f76749823c074   /*  905 */,
    0x4b76eca3c2745360   /*  906 */,    0x8c98f463b91691bd   /*  907 */,
    0x14bcc93cf1ade66a   /*  908 */,    0x8885213e6d458397   /*  909 */,
    0x8e177df0274d4711   /*  910 */,    0xb49b73b5503f2951   /*  911 */,
    0x10168168c3f96b6b   /*  912 */,    0x0e3d963b63cab0ae   /*  913 */,
    0x8dfc4b5655a1db14   /*  914 */,    0xf789f1356e14de5c   /*  915 */,
    0x683e68af4e51dac1   /*  916 */,    0xc9a84f9d8d4b0fd9   /*  917 */,
    0x3691e03f52a0f9d1   /*  918 */,    0x5ed86e46e1878e80   /*  919 */,
    0x3c711a0e99d07150   /*  920 */,    0x5a0865b20c4e9310   /*  921 */,
    0x56fbfc1fe4f0682e   /*  922 */,    0xea8d5de3105edf9b   /*  923 */,
    0x71abfdb12379187a   /*  924 */,    0x2eb99de1bee77b9c   /*  925 */,
    0x21ecc0ea33cf4523   /*  926 */,    0x59a4d7521805c7a1   /*  927 */,
    0x3896f5eb56ae7c72   /*  928 */,    0xaa638f3db18f75dc   /*  929 */,
    0x9f39358dabe9808e   /*  930 */,    0xb7defa91c00b72ac   /*  931 */,
    0x6b5541fd62492d92   /*  932 */,    0x6dc6dee8f92e4d5b   /*  933 */,
    0x353f57abc4beea7e   /*  934 */,    0x735769d6da5690ce   /*  935 */,
    0x0a234aa642391484   /*  936 */,    0xf6f9508028f80d9d   /*  937 */,
    0xb8e319a27ab3f215   /*  938 */,    0x31ad9c1151341a4d   /*  939 */,
    0x773c22a57bef5805   /*  940 */,    0x45c7561a07968633   /*  941 */,
    0xf913da9e249dbe36   /*  942 */,    0xda652d9b78a64c68   /*  943 */,
    0x4c27a97f3bc334ef   /*  944 */,    0x76621220e66b17f4   /*  945 */,
    0x967743899acd7d0b   /*  946 */,    0xf3ee5bcae0ed6782   /*  947 */,
    0x409f753600c879fc   /*  948 */,    0x06d09a39b5926db6   /*  949 */,
    0x6f83aeb0317ac588   /*  950 */,    0x01e6ca4a86381f21   /*  951 */,
    0x66ff3462d19f3025   /*  952 */,    0x72207c24ddfd3bfb   /*  953 */,
    0x4af6b6d3e2ece2eb   /*  954 */,    0x9c994dbec7ea08de   /*  955 */,
    0x49ace597b09a8bc4   /*  956 */,    0xb38c4766cf0797ba   /*  957 */,
    0x131b9373c57c2a75   /*  958 */,    0xb1822cce61931e58   /*  959 */,
    0x9d7555b909ba1c0c   /*  960 */,    0x127fafdd937d11d2   /*  961 */,
    0x29da3badc66d92e4   /*  962 */,    0xa2c1d57154c2ecbc   /*  963 */,
    0x58c5134d82f6fe24   /*  964 */,    0x1c3ae3515b62274f   /*  965 */,
    0xe907c82e01cb8126   /*  966 */,    0xf8ed091913e37fcb   /*  967 */,
    0x3249d8f9c80046c9   /*  968 */,    0x80cf9bede388fb63   /*  969 */,
    0x1881539a116cf19e   /*  970 */,    0x5103f3f76bd52457   /*  971 */,
    0x15b7e6f5ae47f7a8   /*  972 */,    0xdbd7c6ded47e9ccf   /*  973 */,
    0x44e55c410228bb1a   /*  974 */,    0xb647d4255edb4e99   /*  975 */,
    0x5d11882bb8aafc30   /*  976 */,    0xf5098bbb29d3212a   /*  977 */,
    0x8fb5ea14e90296b3   /*  978 */,    0x677b942157dd025a   /*  979 */,
    0xfb58e7c0a390acb5   /*  980 */,    0x89d3674c83bd4a01   /*  981 */,
    0x9e2da4df4bf3b93b   /*  982 */,    0xfcc41e328cab4829   /*  983 */,
    0x03f38c96ba582c52   /*  984 */,    0xcad1bdbd7fd85db2   /*  985 */,
    0xbbb442c16082ae83   /*  986 */,    0xb95fe86ba5da9ab0   /*  987 */,
    0xb22e04673771a93f   /*  988 */,    0x845358c9493152d8   /*  989 */,
    0xbe2a488697b4541e   /*  990 */,    0x95a2dc2dd38e6966   /*  991 */,
    0xc02c11ac923c852b   /*  992 */,    0x2388b1990df2a87b   /*  993 */,
    0x7c8008fa1b4f37be   /*  994 */,    0x1f70d0c84d54e503   /*  995 */,
    0x5490adec7ece57d4   /*  996 */,    0x002b3c27d9063a3a   /*  997 */,
    0x7eaea3848030a2bf   /*  998 */,    0xc602326ded2003c0   /*  999 */,
    0x83a7287d69a94086   /* 1000 */,    0xc57a5fcb30f57a8a   /* 1001 */,
    0xb56844e479ebe779   /* 1002 */,    0xa373b40f05dcbce9   /* 1003 */,
    0xd71a786e88570ee2   /* 1004 */,    0x879cbacdbde8f6a0   /* 1005 */,
    0x976ad1bcc164a32f   /* 1006 */,    0xab21e25e9666d78b   /* 1007 */,
    0x901063aae5e5c33c   /* 1008 */,    0x9818b34448698d90   /* 1009 */,
    0xe36487ae3e1e8abb   /* 1010 */,    0xafbdf931893bdcb4   /* 1011 */,
    0x6345a0dc5fbbd519   /* 1012 */,    0x8628fe269b9465ca   /* 1013 */,
    0x1e5d01603f9c51ec   /* 1014 */,    0x4de44006a15049b7   /* 1015 */,
    0xbf6c70e5f776cbb1   /* 1016 */,    0x411218f2ef552bed   /* 1017 */,
    0xcb0c0708705a36a3   /* 1018 */,    0xe74d14754f986044   /* 1019 */,
    0xcd56d9430ea8280e   /* 1020 */,    0xc12591d7535f5065   /* 1021 */,
    0xc83223f1720aef96   /* 1022 */,    0xc3a0396f7363a51f   /* 1023 */
];


/*******************************************************************************

*******************************************************************************/

version (UnitTest)
{
        unittest 
        {
        static char[][] strings = [
                "",
                "abc",
                "Tiger",
                "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-",
                "ABCDEFGHIJKLMNOPQRSTUVWXYZ=abcdefghijklmnopqrstuvwxyz+0123456789",
                "Tiger - A Fast New Hash Function, by Ross Anderson and Eli Biham",
                "Tiger - A Fast New Hash Function, by Ross Anderson and Eli Biham, proceedings of Fast Software Encryption 3, Cambridge.",
                "Tiger - A Fast New Hash Function, by Ross Anderson and Eli Biham, proceedings of Fast Software Encryption 3, Cambridge, 1996.",
                "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-"
        ];
        static char[][] results = [
                "24f0130c63ac933216166e76b1bb925ff373de2d49584e7a",
                "f258c1e88414ab2a527ab541ffc5b8bf935f7b951c132951",
                "9f00f599072300dd276abb38c8eb6dec37790c116f9d2bdf",
                "87fb2a9083851cf7470d2cf810e6df9eb586445034a5a386",
                "467db80863ebce488df1cd1261655de957896565975f9197",
                "0c410a042968868a1671da5a3fd29a725ec1e457d3cdb303",
                "ebf591d5afa655ce7f22894ff87f54ac89c811b6b0da3193",
                "3d9aeb03d1bd1a6357b2774dfd6d5b24dd68151d503974fc",
                "00b83eb4e53440c576ac6aaee0a7485825fd15e70a59ffe4"
        ];

        Tiger h = new Tiger();

        foreach(int i, char[] s; strings) {
                h.update(cast(ubyte[]) s);

                char[] d = h.hexDigest();

                assert(d == results[i],":("~s~")("~d~")!=("~results[i]~")");

        }

        ubyte[65536] buffer;

        for (uint i = 0; i < 65536; i++)
                buffer[i] = cast(ubyte) i;

                h.update(buffer);
                char[] e = h.hexDigest();

        assert(e == "8ef43951b3f5f4fd1d41afe51b420e710462f233c3aaa8e1",
                ":(65k)("~e~")!=(8ef43951b3f5f4fd1d41afe51b420e710462f233c3aaa8e1)");
        }
}
