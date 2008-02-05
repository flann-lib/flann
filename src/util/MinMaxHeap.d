module MinMaxHeap;


import tango.math.Math;
debug import tango.io.Stdout;

class MinMaxHeap(T) {

	private {
		T heap[];
		int count;
	}
	
	public this(int capacity) 
	{
		heap = new T[capacity+1];  // heap uses 1-based indexing
		count = 0;
	}
	
	public ~this()
	{
		delete heap;
	}

	public int size() 
	{
		return count;
	}
	
	public int capacity()
	{
		return heap.length-1;
	}
	
	public bool empty() 
	{
		return size()==0;	
	}


   /**
    * Usefull helper functions
    * 
    * Things that belong in the standard library
    */ 
   private void swap(T) (inout T a, inout T b) {
      T t = a;
      a = b;
      b = t;
   }
   
   /**
    * ditto
    */
   private T min(T) (T x, T y) { 
      return x < y ? x : y; 
   }


	/**
	 * Clear heap
	 * 
	 * Removes all elements from the heap.
	 */
	public void clear() 
	{
		count = 0;
	}
	
	/**
    * Min level test
    *  
    * Function return true is the argument position is on a min level
    * and false otherwise
    */
	private bool isMinLevel(int pos)
	{
		return (floor(log2(level))%2==0);	
	}
	
	/**
	 *  Bubble an element up on the max levels to preserve the heap property
	 */	
	private void bubbleUpMax(int loc, T item)
	{
		int grandparent = loc/4;
		while (grandparent>0 && item > heap[grandparent]) {
			heap[loc] = heap[grandparent];
			loc = grandparent;
			grandparent /= 4;
		}
		heap[loc] = item;
	}
	
	/**
	 *  Bubble an element up on the min levels to preserve the heap property
	 */	
	private void bubbleUpMin(int loc, T item)
	{
		int grandparent = loc/4;
		while (grandparent>0 && item < heap[grandparent]) {
			heap[loc] = heap[grandparent];
			loc = grandparent;
			grandparent /= 4;
		}
		heap[loc] = item;
	}


	/**
	 * Insert new element into heap
	 *
	 * Inserts a new element in heap and reorganizes the heap.
	 * If the heap is full, the new element is inserted only if
	 * it's smaller than the largest element in the heap. The largest
	 * element from the heap is removed.
	 */
	public void insert(in T value)
	{
      // if heap is full we insert the new element only if it's smaller than the 
      // biggest element currently in the heap  
		if (count == capacity) { 
         if (count >= 2) {    
            int pos = 2;
            T max = heap[pos];
            if (count>=3 && heap[3]>max) {
               pos = 3;
               max = heap[3];
            }
            if (value<max) {
               if (value<heap[1]) {
                  swap(value,heap[1]);
               }
               trickleDownMax(pos,value);
            }
         }
         else { // heap of 1 element
            if (value<heap[1]) {
               heap[1] = value;
            }
         }
			return;
		}
			
		int loc = ++(count);   /* Remember 1-based indexing. */
		int parent = loc/2;
		
		if (parent==0) { // heap is empty, insert in the first position
			heap[1] = value;
		}
		else {
			if (isMinLevel(parent)) {
				if (value < heap[parent] ) {
					heap[loc] = heap[parent];
					bubbleUpMin(parent,value);
				}
				else {
					bubbleUpMax(loc,value);
				}
			}
			else {
				if (value > heap[parent] ) {
					heap[loc] = heap[parent];
					bubbleUpMax(parent,value);
				}
				else {
					bubbleUpMin(loc,value);
				}				
			}
		}
	}

	/**
	 * Get minimum element form heao
	 * 
	 * Return the node from the heap with minimum value.  Reorganize
	 * to maintain the heap.
	 */
	public bool popMin(out T value)
	{
		if (count == 0) {  // heap is empty
 			return false;
		}
	
		value = heap[1];
		
		count--;
		trickleDownMin(1,heap[count+1]);
		
		return true;  /* Return old last node. */
	}
		
	private int minChildGrandchild(int loc)
	{
		assert(2*loc<=count);
		
		// check childs
		int minloc = 2*loc;
		T minval = heap[minloc];
		
		int next = minloc+1;
		if (next<=count && heap[next]<minval) {
			minval = heap[next];
			minloc = next;
		}
		
		// check grandchilds
		next = 4*loc;
		int maxind = min(next+3,count);
		while (next <= maxind) {
			if (heap[next]<minval) {
				minval = heap[next];
				minloc = next;
			}
			next++;
		}
		
		return minloc;
	}
	
	private int maxChildGrandchild(int loc)
	{
		assert(2*loc<=count);
		
		// check childs
		int minloc = 2*loc;
		T minval = heap[minloc];
		
		int next = minloc+1;
		if (next<=count && heap[next]>minval) {
			minval = heap[next];
			minloc = next;
		}
		
		// check grandchilds
		next = 4*loc;
		int maxind = min(next+3,count);
		while (next <= maxind) {
			if (heap[next]>minval) {
				minval = heap[next];
				minloc = next;
			}
			next++;
		}
		
		return minloc;
	}

	private void trickleDownMin(int loc, T item)
	{
		while (2*loc <= count) { // while loc has children
			int k = minChildGrandchild(loc);
			if (item <= heap[k]) { // no need to go further down, place the element here
				break;
			}
			heap[loc] = heap[k];
			if (k <= 2*loc+1) { // if it k is a child (also means that there are no grandchilds)
				loc = k; // insert the element in place of the child
				break;
			}
			// if we got here, k is a grandchild of loc
			int parent = k/2;
			if (item > heap[parent]) {
				swap(heap[parent],item);
			}
			loc = k;
		}
		heap[loc] = item;		
	}

	private void trickleDownMax(int loc, T item)
	{
		while (loc <= count/2) {
			int k = maxChildGrandchild(loc);
			if (item >= heap[k]) { // no need to go further down, place the element here
				break;
			}
			heap[loc] = heap[k];
			if (k <= 2*loc+1) { // if it k is a child (also means that there are no grandchilds)
				loc = k; // insert the element in place of the child
				break;
			}
			// if we got here, k is a grandchild of loc
			int parent = k/2;
			if (item < heap[parent]) {
				swap(heap[parent],item);
			}
			loc = k;
		}
		heap[loc] = item;		
	}
	
	debug public void print()
	{
		int num = 2;
		int i=1;
		
		while (true) {
			while (i<=count && i<num) {
				Stdout(heap[i])(" ");
				i++;
			}
			Stdout.newline;
			if (i>count) break;
			num *= 2;
		}
		Stdout("-----------------------------").newline;
	}
}
