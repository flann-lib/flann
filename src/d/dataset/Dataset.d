/* 
Project: nn
*/

module dataset.Dataset;

import util.defines;
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
	
	public this(T* dataset, int rows, int cols)
	{
		vecs = allocate!(T[][])(rows);
		for (int i=0;i<rows;++i) {
			vecs[i] = dataset[0..cols];
			dataset += cols;
		}
	}
	
	public ~this()
	{
		free(vecs);
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
    
    Dataset!(S) astype(S)()
    {
        auto ret = new Dataset!(S)(rows,cols);
        foreach (index,vec;vecs) {
            array_copy(ret.vecs[index],vec);
        }           
        return ret;
    }
	


}




