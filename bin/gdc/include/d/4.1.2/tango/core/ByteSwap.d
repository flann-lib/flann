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

*******************************************************************************/

struct ByteSwap
{
        /***********************************************************************

        ***********************************************************************/

        final static void swap16 (void *dst, uint bytes)
        {
                ubyte* p = cast(ubyte*) dst;
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

        ***********************************************************************/

        final static void swap32 (void *dst, uint bytes)
        {
                uint* p = cast(uint*) dst;
                while (bytes)
                      {
                      *p = bswap(*p);
                      p ++;
                      bytes -= int.sizeof;
                      }
        }

        /***********************************************************************

        ***********************************************************************/

        final static void swap64 (void *dst, uint bytes)
        {
                uint* p = cast(uint*) dst;
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

        ***********************************************************************/

        final static void swap80 (void *dst, uint bytes)
        {
                ubyte* p = cast(ubyte*) dst;
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

                      p += real.sizeof;
                      bytes -= real.sizeof;
                      }
        }
}




