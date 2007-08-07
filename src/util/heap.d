/*
Project: aggnn

Module: Priority Queue Implementation
Author: David Lowe (2006)
Conversion to D: Marius Muja
*/


/* The priority queue is implemented with a heap.  A heap is a complete
   (full) binary tree in which each parent is less than both of its
   children, but the order of the children is unspecified.
   Note that a heap uses 1-based indexing to allow for power-of-2
   location of parents and children.  We ignore element 0 of Heap array.
 */


module util.heap;

template Heap(T) {

class Heap {

	private {
		T heap[];
		int count;
	}
	
	public this(int size) 
	{
		heap = new T[size+1];  // heap uses 1-based indexing
		count = 0;
	}

	public int size() 
	{
		return count;
	}
	
	public bool empty() 
	{
		return size()==0;	
	}

	public void init() 
	{
		count = 0;
	}

	/* Insert a new element in the heap, with values "node" and "mindistsq".
		We select the next empty leaf node, and then keep moving any larger
		parents down until the right location is found to store this element.
	*/
	public void insert(in T value)
	{
		/* If heap is full, then return without adding this element. */
		if (count == heap.length-1) {
			heap.length = heap.length * 2;
			//return;
		}
	
		int loc = ++(count);   /* Remember 1-based indexing. */
	
		/* Keep moving parents down until a place is found for this node. */
		int par = loc / 2;                 /* Location of parent. */
		while (par > 0  &&  heap[par] > value) {
			heap[loc] = heap[par];     /* Move parent down to loc. */
			loc = par;
			par = loc / 2;
		}
		/* Insert the element at the determined location. */
		heap[loc] = value;
	}
	
	
	public void remove(in T value)
	{
		if (count == 0) {
 			return;
		}
		
		int ind = 1;
		while (ind<=count) {
			if (heap[ind]==value) {
				swap(heap[ind],heap[count]);
				count--;
				heapify(ind); 
				
				break;
			}
			ind++;
		}
	}
	
	
	/* Return the node from the heap with minimum value.  Reorganize
		to maintain the heap.
	*/
	public bool popMin(out T value)
	{
		if (count == 0) {
 			return false;
		}
	
		/* Switch first node with last. */
		swap(heap[1],heap[count]);
	
		count -= 1;
		heapify(1);      /* Move new node 1 to right position. */
	
		value = heap[count + 1];
		return true;  /* Return old last node. */
	}
	
	
	/* Take a heap rooted at position "parent" and enforce the heap critereon
		that a parent must be smaller than its children.
	*/
	private void heapify(int parent) 
	{
		int left, right, minloc = parent;
	
		/* Check the left child */
		left = 2 * parent;
		if (left <= count && heap[left] < heap[parent]) {
			minloc = left;
		}
	
		/* Check the right child */
		right = left + 1;
		if (right <= count && heap[right] < heap[minloc]) {
			minloc = right;
		}
	
		/* If a child was smaller, than swap parent with it and Heapify. */
		if (minloc != parent) {
			swap(heap[parent],heap[minloc]);
			heapify( minloc);
		}
	}
	
	
	
	private void swap(T) (inout T a, inout T b) {
		T t = a;
		a = b;
		b = t;
	}

}
}
