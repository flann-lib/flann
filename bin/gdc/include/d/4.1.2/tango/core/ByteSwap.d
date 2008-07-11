/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: October 2004

        version:        Feb 20th 2005 - Asm version removed by Aleksey Bobnev

        author:         Kris, Aleksey Bobnev

*******************************************************************************/

module tango.core.ByteSwap;

import tango.core.BitManip;

/*******************************************************************************

        Reverse byte order for specific datum sizes. Note that the
        byte-swap approach avoids alignment issues, so is probably
        faster overall than a traditional 'shift' implementation.
        ---
        ubyte[] x = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08];

        swap16 (x) => 02 01 04 03 06 05 08 07     
        swap32 (x) => 04 03 02 01 08 07 06 05
        swap64 (x) => 08 07 06 05 04 03 02 01
        ---

*******************************************************************************/

struct ByteSwap
{
        /***********************************************************************

                Reverses two-byte sequences. Parameter dst imples the 
                number of bytes, which should be a multiple of 2

        ***********************************************************************/

        final static void swap16 (void[] dst)
        {
                swap16 (dst.ptr, dst.length);
        }

        /***********************************************************************

                Reverses four-byte sequences. Parameter dst implies the  
                number of bytes, which should be a multiple of 4

        ***********************************************************************/

        final static void swap32 (void[] dst)
        {
                swap32 (dst.ptr, dst.length);
        }

        /***********************************************************************

                Reverse eight-byte sequences. Parameter dst implies the 
                number of bytes, which should be a multiple of 8

        ***********************************************************************/

        final static void swap64 (void[] dst)
        {
                swap64 (dst.ptr, dst.length);
        }

        /***********************************************************************

                Reverse ten-byte sequences. Parameter dst implies the 
                number of bytes, which should be a multiple of 10

        ***********************************************************************/

        final static void swap80 (void[] dst)
        {
                swap80 (dst.ptr, dst.length);
        }

        /***********************************************************************

                Reverses two-byte sequences. Parameter bytes specifies the 
                number of bytes, which should be a multiple of 2

        ***********************************************************************/

        final static void swap16 (void *dst, uint bytes)
        {
                assert ((bytes & 0x01) is 0);

                auto p = cast(ubyte*) dst;
                while (bytes)
                      {
                      ubyte b = p[0];
                      p[0] = p[1];
                      p[1] = b;

                      p += short.sizeof;
                      bytes -= short.sizeof;
                      }
        }

        /***********************************************************************

                Reverses four-byte sequences. Parameter bytes specifies the  
                number of bytes, which should be a multiple of 4

        ***********************************************************************/

        final static void swap32 (void *dst, uint bytes)
        {
                assert ((bytes & 0x03) is 0);

                auto p = cast(uint*) dst;
                while (bytes)
                      {
                      *p = bswap(*p);
                      ++p;
                      bytes -= int.sizeof;
                      }
        }

        /***********************************************************************

                Reverse eight-byte sequences. Parameter bytes specifies the 
                number of bytes, which should be a multiple of 8

        ***********************************************************************/

        final static void swap64 (void *dst, uint bytes)
        {
                assert ((bytes & 0x07) is 0);

                auto p = cast(uint*) dst;
                while (bytes)
                      {
                      uint i = p[0];
                      p[0] = bswap(p[1]);
                      p[1] = bswap(i);

                      p += (long.sizeof / int.sizeof);
                      bytes -= long.sizeof;
                      }
        }

        /***********************************************************************

                Reverse ten-byte sequences. Parameter bytes specifies the 
                number of bytes, which should be a multiple of 10

        ***********************************************************************/

        final static void swap80 (void *dst, uint bytes)
        {
                assert ((bytes % 10) is 0);
               
                auto p = cast(ubyte*) dst;
                while (bytes)
                      {
                      ubyte b = p[0];
                      p[0] = p[9];
                      p[9] = b;

                      b = p[1];
                      p[1] = p[8];
                      p[8] = b;

                      b = p[2];
                      p[2] = p[7];
                      p[7] = b;

                      b = p[3];
                      p[3] = p[6];
                      p[6] = b;

                      b = p[4];
                      p[4] = p[5];
                      p[5] = b;

                      p += 10;
                      bytes -= 10;
                      }
        }
}




