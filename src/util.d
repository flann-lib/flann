/************************************************************************
Project: aggnn
Project: convert

Module: util.d (utility routines for memory allocation, etc.
Author: David Lowe (2006)
Conversion to D: Marius Muja

*************************************************************************/

import std.c.stdlib;
import std.stdio;

template MAX(T) {
	T MAX(T x, T y) { return x > y ? x : y; }
}

template MIN(T) {
	T MIN(T x, T y) { return x < y ? x : y; }
}

template ABS(T) {
	T ABS(T x) { return x < 0 ? -x : x; }
}


void swap(T) (inout T a, inout T b) {
     T t = a;
     a = b;
     b = t;
}


extern (C) {
	double drand48();
	double lrand48();
}


/*----------------------- Error messages --------------------------------*/
 
/* Print message and quit. */
void FatalError(char *msg)
{
    fprintf(stderr, "FATAL ERROR: %s\n",msg);
    exit(1);
}



/*-------------------- Pooled storage allocator ---------------------------*/

/* The following routines allow for the efficient allocation of storage in
     small chunks from a specified pool.  Rather than allowing each structure
     to be freed individually, an entire pool of storage is freed at once.
   This method has two advantages over just using malloc() and free().  First,
     it is far more efficient for allocating small objects, as there is
     no overhead for remembering all the information needed to free each
     object or consolidating fragmented memory.  Second, the decision about 
     how long to keep an object is made at the time of allocation, and there
     is no need to track down all the objects to free them.
*/

/* The memory allocated by this class is not handled by the garbage collector. Be 
carefull not to store in this memory pointers to memory handled by the gc.
*/

class Pool {
	
	private {
			
		/* We maintain memory alignment to word boundaries by requiring that all
			allocations be in multiples of the machine wordsize.  
		*/
		const int WORDSIZE=4;   /* Size of machine word in bytes.  Must be power of 2. */
		
		const int BLOCKSIZE=2048;	/* Minimum number of bytes requested at a time from
						the system.  Must be multiple of WORDSIZE. */
		
		int remaining;  /* Number of bytes left in current block of storage. */
		char *base;     /* Pointer to base of current block of storage. */
		char *loc;      /* Current location in block to next allocate memory. */
	}
	
	/* 
		Default constructor. Initializes a new pool.
	*/
	public this()
	{
		remaining = 0;
		base = null;
	}
	
	/* Returns a pointer to a piece of new memory of the given size in bytes
		allocated from the pool.
	*/
	
	T* malloc(T)(int count = 1)
	{
		char* m, rloc;
		int blocksize;
		
		int size = T.sizeof * count;
	
		/* Round size up to a multiple of wordsize.  The following expression
			only works for WORDSIZE that is a power of 2, by masking last bits of
			incremented size to zero.
		*/
		size = (size + WORDSIZE - 1) & ~(WORDSIZE - 1);
	
		/* Check whether a new block must be allocated.  Note that the first word
			of a block is reserved for a pointer to the previous block.
		*/
		if (size > remaining) {
			blocksize = (size + (void*).sizeof > BLOCKSIZE) ?
						size + (void*).sizeof : BLOCKSIZE;
			m = cast(char*) .malloc(blocksize);
			if (! m) {
				FatalError("Failed to allocate memory.");
			}
			
			remaining = blocksize - (void*).sizeof;
			/* Fill first word of new block with pointer to previous block. */
			(cast(char **) m)[0] = base;
			base = m;
			loc = m + (void*).sizeof;
		}
		/* Allocate new storage. */
		rloc = loc;
		loc += size;
		remaining -= size;
		return cast(T*)rloc;
	}
	
	
	/* Free all storage that was previously allocated to this pool.
	*/
	public ~this()
	{
		char *prev;
	
		while (base != null) {
			prev = *(cast(char **) base);  /* Get pointer to prev block. */
			free(base);
			base = prev;
		}
	}
	
}


class Queue(T) 
{
	T[] storage;
	int head, tail;
	
	this(int capacity)
	{
		storage = new T[capacity+1];
		head = 0;
		tail = 0;
	}
	
	int size()
	{
		return (tail-head+storage.length)%storage.length;
	}
	
	bool full()
	{
		return size==storage.length-1;
	}
	
	bool empty()
	{
		return size==0;
	}
	
	bool push(T val)
	{
		if (full) {
			return false;
		}
		storage[tail] = val;
		tail = (tail+1)%storage.length;
		return true;
	}
	
	bool pop(out T val)
	{
		if (empty) {
			return false;
		}
		val = storage[head];
		head = (head+1)%storage.length;
		return true;
	}
	
	 T opIndex(size_t ind)
	 {
	 	if (empty) {
	 		throw new Exception("Queue empty");
	 	}
	 	if (ind<0 || ind>=size) {
	 		throw new Exception("Illegal index argument");
	 	}
	 	return storage[(head+ind+storage.length)%storage.length];
	 }
}

unittest 
{
	Queue!(int) q = new Queue!(int)(5);
	
	assert(q.empty);
	q.push(1);	
	assert(!q.empty);
	assert(!q.full);
	q.push(2);
	assert(!q.empty);
	assert(!q.full);
	q.push(3);
	assert(!q.empty);
	assert(!q.full);
	q.push(4);
	assert(!q.empty);
	assert(!q.full);
	q.push(5);
	assert(q.full);
	
	
	assert(q[0]==1);
	assert(q[1]==2);
	assert(q[4]==5);
	
	int a;
	q.pop(a);
	assert(a==1);
	assert(!q.empty);
	assert(!q.full);
	assert(q[0]==2);
	try {
		a = q[5];
		assert(false);
	} catch (Exception e){};
	q.pop(a);
	assert(a==2);
	assert(!q.empty);
	assert(!q.full);
	assert(q[0]==3);
	assert(q[1]==4);
	q.pop(a);
	assert(a==3);
	assert(!q.empty);
	assert(!q.full);
	q.pop(a);
	assert(a==4);
	assert(!q.empty);
	assert(!q.full);
	q.pop(a);
	assert(a==5);
	try {
		a = q[0];
		assert(false);
	} catch (Exception e){};
	
	assert(q.empty);
	
	writef("Queue unittest passed");
}



public float squaredDist(float[] a, float[] b) 
{
	return DistSquared(&a[0], &b[0],a.length);
}


/* Return the squared distance between two vectors. 
	This is highly optimized, with loop unrolling, as it is one
	of the most expensive inner loops of recognition.
*/
public float DistSquared(float *v1, float *v2, int veclen)
{
	float diff, distsq = 0.0;
	float diff0, diff1, diff2, diff3;
	float *final_, finalgroup;

	final_ = v1 + veclen;
	finalgroup = final_ - 3;

	/* Process 4 pixels with each loop for efficiency. */
	while (v1 < finalgroup) {
		diff0 = v1[0] - v2[0];
		diff1 = v1[1] - v2[1];
		diff2 = v1[2] - v2[2];
		diff3 = v1[3] - v2[3];
		distsq += diff0 * diff0 + diff1 * diff1 + diff2 * diff2 + diff3 * diff3;
		v1 += 4;
		v2 += 4;
	}
	/* Process last 0-3 pixels.  Not needed for standard vector lengths. */
	while (v1 < final_) {
		diff = *v1++ - *v2++;
		distsq += diff * diff;
	}
	return distsq;
}


public float computeVariance(float[][] points)
{
	if (points.length==0) {
		return 0;
	}
	
	float[] mu = points[0].dup;
	
	mu[] = 0;	
	for (int j=0;j<mu.length;++j) {
		for (int i=0;i<points.length;++i) {
			mu[j] += points[i][j];
		}
		mu[j]/=points.length;
	}
	
	float variance = 0;
	for (int i=0;i<points.length;++i) {
		variance += squaredDist(mu,points[i]);
	}
	variance/=points.length;

	return variance;
}