/*******************************************************************************

        copyright:      Copyright (c) 2006 James Pelcis. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: August 2006

        author:         James Pelcis

*******************************************************************************/

module tango.io.digest.Crc32;

public import tango.io.digest.Digest;


/** This class implements the CRC-32 checksum algorithm.
    The digest returned is a little-endian 4 byte string. */
final class Crc32 : Digest
{
        private uint[256] table;
        private uint result = 0xffffffff;

        /**
         * Create a cloned CRC32
         */
        this (Crc32 crc32)
        {
                this.table[] = crc32.table[];
                this.result = crc32.result;
        }

        /**
         * Prepare Crc32 to checksum the data with a given polynomial.
         *
         * Params:
         *      polynomial = The magic CRC number to base calculations on.  The
         *      default compatible with ZIP, PNG, ethernet and others. Note: This
         *      default value has poor error correcting properties.
         */
        this (uint polynomial = 0xEDB88320U)
        {
                for (int i = 0; i < 256; i++)
                {
                        uint value = i;
                        for (int j = 8; j > 0; j--)
                        {
                                if (value & 1) {
                                        value &= 0xFFFFFFFE;
                                        value /= 2;
                                        value &= 0x7FFFFFFF;
                                        value ^= polynomial;
                                }
                                else
                                {
                                        value &= 0xFFFFFFFE;
                                        value /= 2;
                                        value &= 0x7FFFFFFF;
                                }
                        }
                        table[i] = value;
                }
        }

        /** */
        override void update (void[] input)
        {
                uint r = result; // DMD optimization
                foreach (ubyte value; cast(ubyte[]) input)
                {
                        auto i = cast(ubyte) r;// & 0xff;
                        i ^= value;
                        r &= 0xFFFFFF00;
                        r /= 0x100;
                        r &= 16777215;
                        r ^= table[i];
                }
                result = r;
        }

        /** The Crc32 digestSize is 4 */
        override uint digestSize ()
        {
                return 4;
        }

        /** */
        override ubyte[] binaryDigest(ubyte[] buf = null) {
                if (buf.length < 4)
                        buf.length = 4;
                uint v = ~result;
                buf[3] = cast(ubyte) (v >> 24);
                buf[2] = cast(ubyte) (v >> 16);
                buf[1] = cast(ubyte) (v >> 8);
                buf[0] = cast(ubyte) (v);
                result = 0xffffffff;
                return buf;
        }

        /** Returns the Crc32 digest as a uint */
        uint crc32Digest() {
                uint ret = ~result;
                result = 0xffffffff;
                return ret;
        }
}

version (UnitTest)
{
        unittest 
        {
        scope c = new Crc32();
        static ubyte[] data = [1,2,3,4,5,6,7,8,9,10];
        c.update(data);
        assert(c.binaryDigest() == cast(ubyte[]) x"7b572025");
        c.update(data);
        assert(c.crc32Digest == 0x2520577b);
        c.update(data);
        assert(c.hexDigest() == "7b572025");
        }
}
