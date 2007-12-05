/* 
Project: nn
*/

module dataset.features;

import util.defines;
import util.logger;
import util.profiler;
import util.utils;
import util.random;
import util.allocator;
import output.console;
import dataset.compute_gt;
import dataset.FormatHandler;
import dataset.DatFormatHandler;
import dataset.BinaryFormatHandler;

void addTo(T,U)(T[] a, U[] b) {
	foreach(index, inout value; a) {
		value += b[index];
	}
/+	for(int i=0; i<a.length;i+=4) {
		a[i] += b[i];
		a[i+1] += b[i+1];
		a[i+2] += b[i+2];
		a[i+3] += b[i+3];
	}+/
}



void writeToFile(float[][] vecs, char[] file) 
{
	withOpenFile(file, (FormatOutput write) {
		for (int i=0;i<vecs.length;++i) {
			if (i!=0) {
				write(" ");
			}
			write.format("{}",vecs[i]);
		}
		write.newline;
	});
}




class Features(T = float) {

	T[][] vecs;    
	int[][] match;         /* indices to correct nearest neighbors. */
	Allocator allocator;

	static FormatHandler!(T) handler;
	
	static this() {
		addFormat(new DatFormatHandler!(T));
		addFormat(new BinaryFormatHandler!(T));
	}
	
	static void addFormat(FormatHandler!(T) handler) 
	{
		handler.next = this.handler;
		this.handler = handler;
	}


	public this() 
	{
		allocator = new Allocator();
	}
	
	public ~this()
	{
		delete allocator;
	}
	
	
	public this(int size, int veclen) 
	{
		this();
		vecs = allocator.allocate!(T[][])(size,veclen);
	}

	public void init(U)(Features!(U) dataset) 
	{
		vecs = allocator.allocate!(T[][])(dataset.count,dataset.veclen);
		foreach (index,vec;dataset.vecs) {
			array_copy(vecs[index],vec);
		}			
	}
	
	public int count() {
		return vecs.length;
	}
	
	public int veclen()
	{
		if (vecs is null) {
			return -1;
		} else {
			return vecs[0].length;
		}
	}
	

	
	public void readMatches(string file)
	{
		auto gridData = new DatFormatHandler!(int)();		
		int[][] values = gridData.read(file, allocator);
		
		match.length = values.length;
		foreach (v;values) {
			match[v[0]] = v[1..$];
		}		
	}
	
	
	public void readFromFile(char[] file)
	{
		vecs = handler.read(file, allocator);
	}
	
	
	public void writeToFile(char[] file, char[] format = "dat")
	{
		handler.write(file,vecs,format);
	}
	
	
	public Features!(T) sample(int size, bool remove = true)
	{
		DistinctRandom rand = new DistinctRandom(count);
		Features!(T) newSet = new Features!(T)(size,veclen);		
		
		for (int i=0;i<size;++i) {
			int r = rand.nextRandom();
			newSet.vecs[i][] = vecs[r];
			if (remove) {
				swap(vecs[count-i-1],vecs[r]);
			}
		}
		
		if (remove) {
			vecs.length = vecs.length - size;
		}
		
		return newSet;
	}
	
	public void computeGT(U)(Features!(U) dataset, int nn, int skip = 0)
	{
		match = computeGroundTruth(dataset,this, nn, skip);
	}

}


