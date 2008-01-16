/**
 * Macros:
 *	WIKI = Phobos/StdRandom
 */

// random.d
// www.digitalmars.com

/* NOTE: This file has been patched from the original DMD distribution to
   work with the GDC compiler.

   Modified by David Friedman, September 2007
*/

module std.random;

// Segments of the code in this file Copyright (c) 1997 by Rick Booth
// From "Inner Loops" by Rick Booth, Addison-Wesley

version (Win32)
{
    extern(Windows) int QueryPerformanceCounter(ulong *count);
}
else version (Unix)
{
    private import std.c.unix.unix;
}

/* ===================== Random ========================= */

// BUG: not multithreaded

private uint seed;		// starting seed
private uint index;		// ith random number

/**
 * The random number generator is seeded at program startup with a random value.
 This ensures that each program generates a different sequence of random
 numbers. To generate a repeatable sequence, use rand_seed() to start the
 sequence. seed and index start it, and each successive value increments index.
 This means that the $(I n)th random number of the sequence can be directly
 generated
 by passing index + $(I n) to rand_seed().

 Note: This is more random, but slower, than C's rand() function.
 To use C's rand() instead, import std.c.stdlib.
 */

void rand_seed(uint seed, uint index)
{
     .seed = seed;
     .index = index;
}

/**
 * Get the next random number in sequence.
 * BUGS: shares a global single state, not multithreaded
 */

uint rand()
{
    static uint xormix1[20] =
    [
                0xbaa96887, 0x1e17d32c, 0x03bcdc3c, 0x0f33d1b2,
                0x76a6491d, 0xc570d85d, 0xe382b1e3, 0x78db4362,
                0x7439a9d4, 0x9cea8ac5, 0x89537c5c, 0x2588f55d,
                0x415b5e1d, 0x216e3d95, 0x85c662e7, 0x5e8ab368,
                0x3ea5cc8c, 0xd26a0f74, 0xf3a9222b, 0x48aad7e4
    ];

    static uint xormix2[20] =
    [
                0x4b0f3b58, 0xe874f0c3, 0x6955c5a6, 0x55a7ca46,
                0x4d9a9d86, 0xfe28a195, 0xb1ca7865, 0x6b235751,
                0x9a997a61, 0xaa6e95c8, 0xaaa98ee1, 0x5af9154c,
                0xfc8e2263, 0x390f5e8c, 0x58ffd802, 0xac0a5eba,
                0xac4874f6, 0xa9df0913, 0x86be4c74, 0xed2c123b
    ];

    uint hiword, loword, hihold, temp, itmpl, itmph, i;

    loword = seed;
    hiword = index++;
    for (i = 0; i < 4; i++)		// loop limit can be 2..20, we choose 4
    {
        hihold  = hiword;                           // save hiword for later
        temp    = hihold ^  xormix1[i];             // mix up bits of hiword
        itmpl   = temp   &  0xffff;                 // decompose to hi & lo
        itmph   = temp   >> 16;                     // 16-bit words
        temp    = itmpl * itmpl + ~(itmph * itmph); // do a multiplicative mix
        temp    = (temp >> 16) | (temp << 16);      // swap hi and lo halves
        hiword  = loword ^ ((temp ^ xormix2[i]) + itmpl * itmph); //loword mix
        loword  = hihold;                           // old hiword is loword
    }
    return hiword;
}

static this()
{
    ulong s;

    version(Win32)
    {
	QueryPerformanceCounter(&s);
    }
    else version(Unix)
    {
	// time.h
	// sys/time.h

	timeval tv;

	if (gettimeofday(&tv, null))
	{   // Some error happened - try time() instead
	    s = time(null);
	}
	else
	{
	    s = cast(ulong)((cast(long)tv.tv_sec << 32) + tv.tv_usec);
	}
    }
    else version(NoSystem)
    {
	// nothing
    }
    else
	static assert(false);
    rand_seed(cast(uint) s, cast(uint)(s >> 32));
}


unittest
{
    static uint results[10] =
    [
	0x8c0188cb,
	0xb161200c,
	0xfc904ac5,
	0x2702e049,
	0x9705a923,
	0x1c139d89,
	0x346b6d1f,
	0xf8c33e32,
	0xdb9fef76,
	0xa97fcb3f
    ];
    int i;
    uint seedsave = seed;
    uint indexsave = index;

    rand_seed(1234, 5678);
    for (i = 0; i < 10; i++)
    {	uint r = rand();
	//printf("0x%x,\n", rand());
	assert(r == results[i]);
    }

    seed = seedsave;
    index = indexsave;
}
