/************************************************************************
Project: nn
Project: convert

Module: util.d (utility routines for memory allocation, etc.
Author: David Lowe (2006)
Conversion to D: Marius Muja

*************************************************************************/

module util.utils;

import tango.util.Convert;
import tango.text.convert.Layout;
import tango.io.stream.MapStream;

import util.variant;
import util.logger;
import util.defines;

public import util.dist;

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

/********************************************************************************
	
	Helper functions for working with files 

********************************************************************************/
import tango.io.FileConduit;
import tango.scrapple.PlainTextProtocol;
public import tango.io.stream.FileStream;
public import tango.io.stream.LineStream;
public import tango.io.stream.BufferStream;
public import tango.io.stream.FormatStream;
public import tango.io.protocol.Reader;
public import tango.io.protocol.Writer;
public import tango.text.stream.StreamIterator;
public import tango.text.stream.SimpleIterator;

alias SimpleIterator!(char) ScanIterator;

private template isArray(T)
{
    static if( is( T U : U[] ) )
        const isArray = true;
    else
        const isArray = false;
}

class ScanReader
{
	private StreamIterator!(char) streamIterator;
	
	alias get opCall;

	public this(StreamIterator!(char) stream)
	{
		streamIterator = stream;
	}

	public ScanReader get(T) (inout T x)
	{
		static if ( isArray!(T) ) {
			static if ( is(T==char[])) {
				x = next;
			}
			else {
				foreach (ref elem;x) {
					elem = to!(typeof(elem))(next);
				}
			}
		}
		else {
			x = to!(T)(next);
		}
		return this;
	}
	
	private char[] next()
	{
		char[] tmp = streamIterator.next;
		while (tmp !is null && tmp.length==0) {
			tmp = streamIterator.next;
		}
		if (tmp is null) {
				throw new Exception("Reading past the end of file");
		}
		return tmp;
	}
}

void withOpenFile(string file, void delegate(FileInput) action) 
{
	auto stream = new FileInput(file);
	scope (exit) stream.close();
	action(stream);
}

void withOpenFile(string file, void delegate(FileOutput) action) 
{
	auto stream = new FileOutput(file);
	scope (exit) stream.close();
	action(stream);
}



void withOpenFile(string file, void delegate(LineInput) action) 
{
	auto stream = new LineInput(new FileInput(file));
	scope (exit) stream.close();
	action(stream);
}

void withOpenFile(string file, void delegate(ScanReader) action, char[] delimiter = " \t\n" ) 
{
	auto stream = new FileInput(file);
	auto reader = new ScanReader(new ScanIterator(delimiter,stream));
	scope (exit) stream.close();
	action(reader);
}

void withOpenFile(string file, void delegate(FormatOutput) action) 
{
	auto stream = new FormatOutput(new FileOutput(file));
	scope (exit) stream.close();
	action(stream);
}


void withOpenFile(string file, void delegate(Reader) action) 
{
	auto conduit = new FileInput(file);
	auto stream = new Reader(new PlainTextProtocol(conduit,false));
	scope (exit) conduit.close();
	action(stream);
}

void withOpenFile(string file, void delegate(Writer) action) 
{
	auto conduit = new FileInput(file);
	auto stream = new Writer(new PlainTextProtocol(conduit,false));
	scope (exit) conduit.close();
	action(stream);
}


/********************************************************************************/






void array_copy(U,V)(U[] dst, V[] src)
{
	static if ( is ( T == U) ) {
		dst[] = src[0..$];
	}
	else {
		foreach(index,value;src) {
			dst[index] = convert!(U,V)(value);
		}
	}
} 

void mat_copy(U,V)(U[][] dst, V[][] src)
{
	static if ( is ( T == U) ) {
		foreach(row_index,row;src) {
			dst[row_index][] = row[0..$];
		}
	}
	else {
		foreach(row_index,row;src) {
			foreach(index,value;row) {
				dst[row_index][index] = convert!(U,V)(value);
			}
		}
	}
} 








T convert(T,U) (U value) 
{ 
	return to!(T)(value);
}

T[] convert(T : T[],U : U[])(U[] srcVec)
{
	static if ( is ( T == U) )
		return srcVec.dup;
	else {
		T[] vec = new T[srcVec.length];
		foreach (i,value; srcVec) {
			vec[i] = convert!(T,U)(value);
		}
		
		return vec;
	}
}




/* This record represents a branch point when finding neighbors in
	the tree.  It contains a record of the minimum distance to the query
	point, as well as the node at which the search resumes.
*/
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







/*---------------parameters----------------------*/

struct Params 
{
	Variant[string] data;
	
	Variant opIndex(string index) 
	{
		if (!(index in data)) {
			throw new Exception("Cannot find param index:"~index);
		}
		return data[index];
	}
	
	void opIndexAssign(T)(T value, string index)
	{
		Variant v;
		v = value;
		data[index] = v;
	}
	int opApply(int delegate(ref Variant) dg)
    {   
    	int result = 0;

		foreach (elem;data)
		{
			result = dg(elem);
			if (result) break;
		}
		return result;
    }
    
   	int opApply(int delegate(ref string, ref Variant) dg)
    {   
    	int result = 0;

		foreach (key,elem;data)
		{
			result = dg(key,elem);
			if (result) break;
		}
		return result;
    }

	string toString()
	{
		auto formater = new Layout!(char);
		return formater("{}",data);
	}
	
	
	void save(string file) {
	
		withOpenFile(file,(FormatOutput writer) {
			foreach(name,value;data) {
				writer.formatln("{} = {}",name,value);
			}
		});
	}


	void load(string file) {
		
		withOpenFile(file, (FileInput stream) {
			auto input = new MapInput!(char)(stream);
			
			foreach (name,value;input) {
				opIndexAssign(value,name);
			}
		});
	}	
}

void copy(ref Params a,Params b)
{
	foreach(k,v;b) {
		a[k] = v;
	}
}





struct OrderedParams
{
	Params values;
	private string[] order;
	
	Variant opIndex(string index) 
	{
		return values[index];
	}
	
	void opIndexAssign(T)(T value, string name) 
	{
		order ~= name;
		values[name] = value;
	}

	int opApply(int delegate(ref Variant) dg)
    {   
    	int result = 0;

		for (int index;index<order.length;++index)
		{
			result = dg(values[order[index]]);
			if (result) break;
		}
		return result;
    }
	
	int opApply(int delegate(ref string, ref Variant) dg)
    {   
    	int result = 0;

		for (int index;index<order.length;++index)
		{
			result = dg(order[index],values[order[index]]);
			if (result) break;
		}
		return result;
    }
}



void copyParams(T,U)(ref T a,U b,string[] params)
{
	foreach(param;params) {
		a[param] = b[param];
	}
}






// class Range 
// {
// 	int begin;
// 	int end;
// 	int skip;
// 	
// 	this(int begin, int end, int skip) {
// 		this.begin = begin;
// 		this.end = end;
// 		this.skip = skip;
// 	}
// 	
// 	this(string range) {
// 		int[] values = convert!(int[],string[])(split(range,":"));
// 		
// 		begin = values[0];
// 		if (values.length>1) {
// 			end = values[1];
// 			
// 			if (values.length>2) {
// 				skip = values[2];
// 			}
// 			else {
// 				skip = 1;
// 			}
// 		}
// 		else {
// 			skip = 1;
// 			end = begin + skip;
// 		} 
// 	}
// }




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




public float computeVariance(T)(T[][] points)
{
	if (points.length==0) {
		return 0;
	}
	
	float[] mu = convert!(float[],T[])(points[0]);
	
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

