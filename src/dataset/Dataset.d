/* 
Project: nn
*/

module dataset.Dataset;

import util.defines;
import output.Console;
import dataset.ComputeGroundTruth;
import dataset.FormatHandler;
import dataset.DatFormatHandler;
import dataset.BinaryFormatHandler;
import util.Logger;
import util.Profile;
import util.Utils;
import util.Random;
import util.Allocator;


class Dataset(T = float) {

	T[][] vecs;    
	int[][] match;         /* indices to correct nearest neighbors. */

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
	}
		
	public this(int size, int veclen) 
	{
		vecs = allocate!(T[][])(size,veclen);
	}

	public this(T[][] dataset) 
	{
		vecs = dataset;
	}
	
	public ~this()
	{
		if (match !is null) {
			free(match);
		}
		free(vecs);
	}

	public void init(U)(Dataset!(U) dataset) 
	{
		vecs = allocate!(T[][])(dataset.rows,dataset.cols);
		foreach (index,vec;dataset.vecs) {
			array_copy(vecs[index],vec);
		}			
	}
	
	public int rows() {
		return vecs.length;
	}
	
	public int cols()
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
		int[][] values = gridData.read(file);
		
		if (values.length >= 1) {
			match = allocate!(int[][])(values.length, values[0].length-1);
			foreach (v;values) {
				match[v[0]][] = v[1..$];
			}
		}
		free(values);
	}
	
	
	public void readFromFile(char[] file)
	{
		vecs = handler.read(file);
	}
	
	
	public void writeToFile(char[] file, char[] format = "dat")
	{
		handler.write(file,vecs,format);
	}
	
	
	public Dataset!(T) sample(int size, bool remove = true)
	{
		DistinctRandom rand = new DistinctRandom(rows);
		Dataset!(T) newSet = new Dataset!(T)(size,cols);
		
		for (int i=0;i<size;++i) {
			int r = rand.nextRandom();
			newSet.vecs[i][] = vecs[r];
			if (remove) {
				swap(vecs[rows-i-1],vecs[r]);
			}
		}
		
		if (remove) {
			vecs.length = vecs.length - size;
		}
		
		return newSet;
	}
	
	public void computeGT(U)(Dataset!(U) dataset, int nn, int skip = 0)
	{
		match = computeGroundTruth(dataset,this, nn, skip);
	}

}


