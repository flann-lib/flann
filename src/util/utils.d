/************************************************************************
Project: nn
Project: convert

Module: util.d (utility routines for memory allocation, etc.
Author: David Lowe (2006)
Conversion to D: Marius Muja

*************************************************************************/

module util.utils;

public import util.dist;

import std.c.stdio;
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


FILE* fOpen(string file, string mode, lazy string message)
{
	FILE *f = std.c.stdio.fopen(toStringz(file),toStringz(mode));
	if (f is null) {
		throw new Exception(message());
	}
	return f;
}


void array_copy(U,V)(U[] dst, V[] src)
{
	foreach(index,value;src) {
		dst[index] = convert!(U,V)(value);
	}
} 



void mat_copy(U,V)(U[][] dst, V[][] src)
{
	foreach(row_index,row;src) {
		foreach(index,value;row) {
			dst[row_index][index] = cast(V) value;
		}
	}
} 



T convert(T,U) (U value) { return cast(T) value; }
T convert(T : int, U : string)(U value) { return toInt(value); }
T convert(T : float, U : string)(U value) { return toFloat(value); }
T convert(T : double, U : string)(U value) { return toDouble(value); }

T convert(T : ubyte, U : string)(U value) { return toUbyte(value); }

T convert(T : float, U : ubyte)(ubyte value) { return value; }

T[] toVec(T,U=string)(U[] strVec)
{
	T[] vec = new T[strVec.length];
	for (int i=0;i<strVec.length;++i) {
		vec[i] = convert!(T,U)(strVec[i]);
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
	string centersAlgorithm;
}





/*----------------------- Error messages --------------------------------*/
 
/* Print message and quit. */
void FatalError(char *msg)
{
    Logger.log(Logger.ERROR, "FATAL ERROR: %s\n",msg);
    exit(1);
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

