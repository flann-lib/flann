/************************************************************************
Project: aggnn
Project: convert

Module: util.d (utility routines for memory allocation, etc.
Author: David Lowe (2006)
Conversion to D: Marius Muja

*************************************************************************/

module util.utils;

public import util.dist;

import std.c.stdlib;
import std.conv;
import std.string;
import util.logger;

template MAX(T) {
	T MAX(T x, T y) { return x > y ? x : y; }
}

template MIN(T) {
	T MIN(T x, T y) { return x < y ? x : y; }
}

template ABS(T) {
	T ABS(T x) { return x < 0 ? -x : x; }
}


void swap(T) (ref T a, ref T b) {
     T t = a;
     a = b;
     b = t;
}



T convert(T : int)(string value) { return toInt(value); }
T convert(T : float)(string value) { return toFloat(value); }
T convert(T : double)(string value) { return toDouble(value); }


T[] toVec(T)(string[] strVec)
{
	T[] vec = new T[strVec.length];
	for (int i=0;i<strVec.length;++i) {
		vec[i] = convert!(T)(strVec[i]);
	}
	
	return vec;
}


struct BranchStruct(T) {
	T node;           /* Tree node at which search resumes */
	float mindistsq;     /* Minimum distance to query for all nodes below. */
	
	int opCmp(BranchStruct!(T) rhs) 
	{ 
		if (mindistsq < rhs.mindistsq) {
			return -1;
		} if (mindistsq > rhs.mindistsq) {
			return 1;
		} else {
			return 0;
		}
	}
	
	static BranchStruct!(T) opCall(T aNode, float dist) 
	{
		BranchStruct!(T) s;
		s.node = aNode;
		s.mindistsq = dist;
		
		return s;
	}
	
}; 






extern (C) {
	double drand48();
	double lrand48();
}


/*---------------parameters----------------------*/

struct Params {
 	int numTrees;
	int branching;
	bool random;
}


/*---------------- index registry--------------------*/

import algo.nnindex;
import util.features;

alias NNIndex delegate(Features, Params) index_delegate;
static index_delegate[string] indexRegistry;

alias NNIndex delegate(string) load_index_delegate;
static load_index_delegate[string] loadIndexRegistry;


/*------------------- module constructor template--------------------*/

template AlgorithmRegistry(T)
{
	
	import serialization.serializer;
	import std.stream;
	
	static this() 
	{
		indexRegistry[T.NAME] = delegate(Features inputData, Params params) {return cast(NNIndex) new T(inputData, params);};
		
		Serializer.registerClassConstructor!(T)({return new T();});
		
		loadIndexRegistry[T.NAME] = delegate(string file) 
			{ Serializer s = new Serializer(file, FileMode.In);
				T index;
				s.describe(index);
				return cast(NNIndex)index;
				};
	}
}





/*----------------------- Error messages --------------------------------*/
 
/* Print message and quit. */
void FatalError(char *msg)
{
    Logger.log(Logger.ERROR, "FATAL ERROR: %s\n",msg);
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
	
	Logger.log(Logger.INFO,"Queue unittest passed");
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
