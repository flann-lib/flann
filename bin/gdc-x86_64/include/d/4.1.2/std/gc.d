
/*
 *  Copyright (C) 1999-2006 by Digital Mars, www.digitalmars.com
 *  Written by Walter Bright
 *
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, subject to the following restrictions:
 *
 *  o  The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  o  Altered source versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *  o  This notice may not be removed or altered from any source
 *     distribution.
 */


/**
 * The garbage collector normally works behind the scenes without needing any
 * specific interaction. These functions are for advanced applications that
 * benefit from tuning the operation of the collector.
 * Macros:
 *	WIKI=Phobos/StdGc
 */

module std.gc;

import gcstats;

/**
 * Add p to list of roots. Roots are references to memory allocated by the
 collector that are maintained in memory outside the collector pool. The garbage
 collector will by default look for roots in the stacks of each thread, the
 registers, and the default static data segment. If roots are held elsewhere,
 use addRoot() or addRange() to tell the collector not to free the memory it
 points to.
 */
void addRoot(void *p);		// add p to list of roots

/**
 * Remove p from list of roots.
 */
void removeRoot(void *p);	// remove p from list of roots

/**
 * Add range to scan for roots.
 */
void addRange(void *pbot, void *ptop);	// add range to scan for roots

/**
 * Remove range.
 */
void removeRange(void *pbot);		// remove range

/**
 * Mark a gc allocated block of memory as possibly containing pointers.
 */
void hasPointers(void* p);

/**
 * Mark a gc allocated block of memory as definitely NOT containing pointers.
 */
void hasNoPointers(void* p);

/**
 * Mark a gc allocated block of memory pointed to by p as being populated with
 * an array of TypeInfo ti (as many as will fit).
 */
void setTypeInfo(TypeInfo ti, void* p);

/**
 * Allocate nbytes of uninitialized data.
 * The allocated memory will be scanned for pointers during
 * a gc collection cycle, unless
 * it is followed by a call to hasNoPointers().
 */
void[] malloc(size_t nbytes);

/**
 * Resize allocated memory block pointed to by p to be at least nbytes long.
 * It will try to resize the memory block in place.
 * If nbytes is 0, the memory block is free'd.
 * If p is null, the memory block is allocated using malloc.
 * The returned array may not be at the same location as the original
 * memory block.
 * The allocated memory will be scanned for pointers during
 * a gc collection cycle, unless
 * it is followed by a call to hasNoPointers().
 */
void[] realloc(void* p, size_t nbytes);

/**
 * Attempt to enlarge the memory block pointed to by p
 * by at least minbytes beyond its current capacity,
 * up to a maximum of maxbytes.
 * Returns:
 *	0 if could not extend p,
 *	total size of entire memory block if successful.
 */
size_t extend(void* p, size_t minbytes, size_t maxbytes);

/**
 * Returns capacity (size of the memory block) that p
 * points to the beginning of.
 * If p does not point into the gc memory pool, or does
 * not point to the beginning of an allocated memory block,
 * 0 is returned.
 */
size_t capacity(void* p);

/**
 * Set gc behavior to match that of 1.0.
 */
void setV1_0();

/***********************************
 * Run a full garbage collection cycle.
 *
 * The collector normally runs synchronously with a storage allocation request
 (i.e. it never happens when in code that does not allocate memory). In some
 circumstances, for example when a particular task is finished, it is convenient
 to explicitly run the collector and free up all memory used by that task. It
 can also be helpful to run a collection before starting a new task that would
 be annoying if it ran a collection in the middle of that task. Explicitly
 running a collection can also be done in a separate very low priority thread,
 so that if the program is idly waiting for input, memory can be cleaned up.
 */

void fullCollect();

/***********************************
 * Run a generational garbage collection cycle.
 * Takes less time than a fullcollect(), but isn't
 * as effective.
 */

void genCollect();

void genCollectNoStack();

/**
 * Minimizes physical memory usage
 */
void minimize();

/***************************************
 * disable() temporarily disables garbage collection cycle, enable()
 * then reenables them.
 *
 * This is used for brief time critical sections of code, so the amount of time
 * it will take is predictable.
 * If the collector runs out of memory while it is disabled, it will throw an
 * std.outofmemory.OutOfMemoryException.
 * The disable() function calls can be nested, but must be
 * matched with corresponding enable() calls.
 * By default collections are enabled.
 */

void disable();

/**
 * ditto
 */
void enable();

void getStats(out GCStats stats);

/***************************************
 * Get handle to the collector.
 */

void* getGCHandle();

/***************************************
 * Set handle to the collector.
 */

void setGCHandle(void* p);

void endGCHandle();

extern (C)
{
    void gc_init();
    void gc_term();
}
