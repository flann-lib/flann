module util.allocator;

import std.c.stdlib;


template class_allocator()
{
	new(size_t sz)
	{
		void* p = Pool.malloc(sz);
		assert(p !is null);
		//std.gc.addRange(p, p + sz);
		return p;
	}

	delete(void* p)
	{
	}
}


public T* allocate(T)() {
	T* mem = cast(T*) Pool.malloc(T.sizeof);
	 
	return mem;
}


public T[] allocate(T : T[])(int count) {
	T* mem = cast(T*) Pool.malloc(count*T.sizeof);
	 
	 return mem[0..count];
}

public T[][] allocate_mat(T : T[][])(int rows, int cols) {
	void* mem = Pool.malloc(rows*(T[]).sizeof+rows*cols*T.sizeof);
	T[]* index = cast(T[]*) mem;
	T* mat = cast(T*) (mem+rows*(T[]).sizeof);
	
	for (int i=0;i<rows;++i) {
		index[i] = mat[0..cols];
		mat += cols;
	}
	
	return index[0..rows];
}


public T allocate_once(T, A...)(A a) {
	allocate!(T)(a);
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
	
	private static {
			
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
	
	private this() {};
	/* 
		Default constructor. Initializes a new pool.
	*/
	static this()
	{
		remaining = 0;
		base = null;
	}
	
	/* Returns a pointer to a piece of new memory of the given size in bytes
		allocated from the pool.
	*/
	
	public static void* malloc(int size)
	{
		char* m, rloc;
		int blocksize;
		
		//int size = T.sizeof * count;
	
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
				throw new Exception("Failed to allocate memory.");
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
		return rloc;
	}
	
	
	/* Free all storage that was previously allocated to this pool.
	*/
	public static void free()
	{
		char *prev;
	
		while (base != null) {
			prev = *(cast(char **) base);  /* Get pointer to prev block. */
			.free(base);
			base = prev;
		}
	}
	
}