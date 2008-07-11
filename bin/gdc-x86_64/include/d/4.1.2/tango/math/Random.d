/*******************************************************************************

        copyright:      Copyright (c) 2004. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: April 2004

        author:         Various

*******************************************************************************/

module tango.math.Random;


version (Win32)
         private extern(Windows) int QueryPerformanceCounter (ulong *);

version (Posix)
        {
        private import tango.stdc.posix.sys.time;
        }


/******************************************************************************

        KISS (via George Marsaglia & Paul Hsieh)

        the idea is to use simple, fast, individually promising
        generators to get a composite that will be fast, easy to code
        have a very long period and pass all the tests put to it.
        The three components of KISS are

                x(n)=a*x(n-1)+1 mod 2^32
                y(n)=y(n-1)(I+L^13)(I+R^17)(I+L^5),
                z(n)=2*z(n-1)+z(n-2) +carry mod 2^32

        The y's are a shift register sequence on 32bit binary vectors
        period 2^32-1; The z's are a simple multiply-with-carry sequence
        with period 2^63+2^32-1.

        The period of KISS is thus 2^32*(2^32-1)*(2^63+2^32-1) > 2^127

******************************************************************************/

class Random
{
        /**********************************************************************

                Shared instance:
                ---
                auto random = Random.shared.next;
                ---

        **********************************************************************/
        public static Random shared;

        private uint kiss_k;
        private uint kiss_m;
        private uint kiss_x = 1;
        private uint kiss_y = 2;
        private uint kiss_z = 4;
        private uint kiss_w = 8;
        private uint kiss_carry = 0;
        
        /**********************************************************************

                Create a static and shared instance:
                ---
                auto random = Random.shared.next;
                ---

        **********************************************************************/

        static this ()
        {
                shared = new Random;
        }

        /**********************************************************************

                Creates and seeds a new generator with the current time

        **********************************************************************/

        this ()
        {
                this.seed;
        }

        /**********************************************************************

                Seed the generator with current time

        **********************************************************************/

        final Random seed ()
        {
                ulong s;

                version (Posix)
                        {
                        timeval tv;

                        gettimeofday (&tv, null);
                        s = tv.tv_usec;
                        }
                version (Win32)
                         QueryPerformanceCounter (&s);

                return seed (cast(uint) s);
        }

        /**********************************************************************

                Seed the generator with a provided value

        **********************************************************************/

        final Random seed (uint seed)
        {
                kiss_x = seed | 1;
                kiss_y = seed | 2;
                kiss_z = seed | 4;
                kiss_w = seed | 8;
                kiss_carry = 0;
                return this;
        }

        /**********************************************************************

                Returns X such that 0 <= X <= uint.max

        **********************************************************************/

        final uint next ()
        {
                kiss_x = kiss_x * 69069 + 1;
                kiss_y ^= kiss_y << 13;
                kiss_y ^= kiss_y >> 17;
                kiss_y ^= kiss_y << 5;
                kiss_k = (kiss_z >> 2) + (kiss_w >> 3) + (kiss_carry >> 2);
                kiss_m = kiss_w + kiss_w + kiss_z + kiss_carry;
                kiss_z = kiss_w;
                kiss_w = kiss_m;
                kiss_carry = kiss_k >> 30;
                return kiss_x + kiss_y + kiss_w;
        }

        /**********************************************************************

                Returns X such that 0 <= X < max

                Note that max is exclusive, making it compatible with
                array indexing

        **********************************************************************/

        final uint next (uint max)
        {
                return next() % max;
        }

        /**********************************************************************

                Returns X such that min <= X < max

                Note that max is exclusive, making it compatible with
                array indexing

        **********************************************************************/

        final uint next (uint min, uint max)
        {
                return next(max-min) + min;
        }
}

