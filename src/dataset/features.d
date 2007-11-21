/* 
Project: nn
*/

module dataset.features;

// import std.stdio;
// import std.string;
// import std.c.string;
// import std.stream;
// import std.ctype;
// import std.conv;
// import std.file;
import tango.stdc.string;
import tango.core.Array;
import tango.text.Util : trim,split;
import tango.io.FilePath;

// import serialization.serializer;
import util.defines;
import util.logger;
import util.utils;
import util.random;
import util.allocator;
import output.console;
import dataset.compute_gt;



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
	withOpenFile(file, (Writer write) {
		for (int i=0;i<vecs.length;++i) {
			write(vecs[i]);
		}
	});
/+	FILE* fp = fopen(toStringz(file),"w");
	if (fp is null) {
		throw new Exception("Cannot open output file: "~file);
	}
	
	for (int i=0;i<vecs.length;++i) {
		for (int j=0;j<vecs[i].length;++j) {
			if (j!=0) {
				fprintf(fp," ");
			}
			fprintf(fp,"%f", vecs[i][j]);
		}
		fprintf(fp,"\n");
	}
	fclose(fp);+/
}


int readValue(U) (FILE* f, inout U value) {
	throw new Exception("readValue not implemented for type: "~U.stringof);
}

int readValue(U : float) (FILE* f, inout U value) {
	return fscanf(f,"%f ",&value);
}

int readValue(U : int) (FILE* f, inout U value) {		
	return fscanf(f,"%d ",&value);
}

int readValue(U : ubyte) (FILE* f, inout U value) {
	return fscanf(f,"%hhu ",&value);
}


int writeValue(U) (FILE* f, U value) {
	throw new Exception("readValue not implemented for type: "~U.stringof);
}

int writeValue(U : float) (FILE* f, U value) {
	return fprintf(f,"%g",value);
}

int writeValue(U : int) (FILE* f, U value) {		
	return fprintf(f,"%d",value);
}

int writeValue(U : ubyte) (FILE* f, U value) {
	return fprintf(f,"%hhu",value);
}


class GridDataFile(T)
{
	private string file;

	public this(string file)
	{
		this.file = file;
	}	
	
	private char guessDelimiter(string line)
	{
		string numberChars = "01234567890.e+-";
		int pos = 0;
		
		while (numberChars.find(line[pos])==-1) {
			pos++;
		}
		while (numberChars.find(line[pos])!=-1) {
			pos++;
		}
		
		return line[pos];
	}
	
	
	public int getLinesNo()
	{
		const int MAX_BUF = 1024;
		char buffer[MAX_BUF];
		
		int cnt = 0;
		withOpenFile(file, (FileInput stream) {
			while (stream.read(buffer)==MAX_BUF) {
				cnt += count(buffer,'\n');
			}
		});
		
		return cnt;	
	}
	
	


	private T[][] getValues()
	{
		static string buffer;
		
		int lines = getLinesNo();
		T[][] vecs;
		
		withOpenFile(file, (LineInput stream) {
			
			string line = stream.next;
			string delimiter;
			delimiter ~= guessDelimiter(line);
			
			string[] tokens = trim(line).split(delimiter);
			int veclen = tokens.length;
			int cnt = 0;
			vecs = new T[][](lines,veclen);
			array_copy(vecs[cnt++],tokens);
			
			foreach (index,line; stream) {
				tokens = trim(line).split(delimiter);
				if (tokens.length==veclen) {
					array_copy(vecs[cnt++],tokens);
				} else {
					debug {
						Logger.log(Logger.DEBUG,"Wrong number of values on line %d... ignoring",(cnt+1));
					}
				}
					
			}
			Logger.log(Logger.INFO,"Read %d features.",cnt);
			vecs = vecs[0..cnt];
		});
		return vecs;
	}


}









class Features(T = float) {

		enum signature {
			NN_FILE,
			DAT_FILE,
			BINARY_FILE	
		} 

		signature sig;

		int count;         /* Number of vectors. */
		int veclen;         /* Length of each vector. */
		T[][] vecs;      /* Float vecs. */
 		int[][] match;         /* Array of indices to correct nearest neighbor. */
// 		int[] mtype;         /* Array of flags indicating if match is correct. */

		public this() {}
		
		
		public this(int size) 
		{
			this.count = size;
			vecs = new T[][size];
		}

		public void init(U)(Features!(U) dataset) 
		{
			this.count = dataset.count;
			this.veclen = dataset.veclen;
			vecs = new T[][](count,veclen);
			foreach (index,vec;dataset.vecs) {
				array_copy(vecs[index],vec);
			}			
		}



	/** 
		Read an NN file containing vectors for nearest-neighbor matching.
	
		The file format for NN files:
		1. First two characters are NN to confirm file type.
		2. Integer (vcount) giving the number of vectors.
		3. Integer (veclen) giving the length of each vector.
		4. Integer specifying type of vectors: 0 means integer byte values in
		range [0,255]; 1 means floating point values.
		5. This is followed by a list of all vectors.  Each contains:
		A. Integer giving the sequential index of this vector (starting at 0)
		B. Integer giving the index of the exact nearest neighbor.
		C. Integer value 0 or 1, with 0 meaning that nearest neighbor is not
		known to be a correct match, while 1 means it is correct
		D. A sequence of the veclen values for the vector elements.
	*/	
	private void readNNFile(string file) 
	{
	
		withOpenFile(file, (Reader stream) {
		
			int vcount, veclen, vtype;
			string header;
			stream (header)(vcount)(veclen)(vtype);
			
			if (header!="NN") {
				throw new Exception("Invalid NN file header.");
			}
	
			this.count = vcount;
			this.veclen = veclen;
			this.vecs = new T[][](count,veclen);
			this.match = new int[][](count,1);
			
		
			/* Read input vectors. */
			for (int i = 0; i < count; i++) {
		
				int seq, mat, mtype;
				stream (seq)(mat)(mtype);
				assert(seq == i);		
				this.match[i][0] = mat;
		
				stream (vecs[i]);
			}
		});
	}
	
	

	
	
	private void readDATFile(string file)
	{
		auto gridData = new GridDataFile!(T)(file);
		vecs = gridData.getValues();
		count = vecs.length;
	}
	
	
	public void readMatches(string file)
	{
		auto gridData = new GridDataFile!(int)(file);
		
		int[][] values = gridData.getValues();
		
		match.length = values.length;
		foreach (v;values) {
			match[v[0]] = v[1..$];
		}		
	}
	
// 	private void dumpDatabase()
// 	{
// 		for (int i=0;i<count;++i) {
// 			for (int j=0;j<veclen;++j) {
// 				fprintf(stderr,"%f ",vecs[i][j]);
// 			}
// 			fprintf(stderr,"\n");
// 		}
// 	}
		
	private void readBINARYFile(string file) 
	{
		string realFile;
		int elemSize;
		
		withOpenFile(file, (Reader read) {
			string header;
			read (header);
			if (header != "BINARY") {
				throw new Exception("Invalid file header, was expecting BINARY");
			}
			
			read(realFile);
			read(veclen);
			read(elemSize);	
		});
		
		if (elemSize!=T.sizeof) {
			Logger.log(Logger.INFO, "Data elements size not equal to used type size. Performing conversion.\n	");
		}
		
		ulong fileSize = FilePath(realFile).fileSize;
		count = fileSize / (veclen*elemSize);
		
		Logger.log(Logger.INFO,"\nReading %d features: ",count);
				
		withOpenFile(realFile, (FileInput stream) {
		
			vecs = new T[][](count,veclen);
			ubyte[] buffer = new ubyte[veclen*elemSize];
		
			showProgressBar(100, 70, (Ticker tick){
				int t = count/100;
				for (int i=0;i<count;++i) {
					stream.read(buffer);
					array_copy(vecs[i],buffer);
					
					if (i%t==0) tick();
				}
			});
		});		
	}

	
	
	private signature checkSignature(string file)
	{
		signature sig;
		withOpenFile(file, (FileInput stream) {
			
			char buf[10];
			stream.read(buf);
			if (buf[0..2]=="NN") {
				sig = signature.NN_FILE;
			}
			else if (buf[0..6]=="BINARY") {
				sig = signature.BINARY_FILE;
			}
			else {
				sig = signature.DAT_FILE;
			}
		});
		
		return sig;
	}
	
	public void readFromFile(char[] file)
	{
		sig = checkSignature(file);
		
		if (sig == signature.NN_FILE) {
			readNNFile(file);
		}
		else if (sig == signature.DAT_FILE) {
			readDATFile(file);
		}
		else if (sig == signature.BINARY_FILE) {
			readBINARYFile(file);
		}
	}
	
	
	private void writeToFile_BINARY(char[] file)
	{
		char[] bin_file = file ~ ".bin";
	
		withOpenFile(file, (FormatOutput print) {
			print("BINARY").newline;
			print(bin_file).newline;
			print(veclen).newline;
			print(T.sizeof).newline;
		});
		
		withOpenFile(bin_file, (FileOutput stream) {
		
			for (int i=0;i<count;++i) {
				stream.write(vecs[i]);
			}
		});
	}
	
	private void writeToFile_DAT(char[] file)
	{
		withOpenFile(file, (Writer write) {
			for (int i=0;i<count;++i) {
				write(vecs[i]);
			}
		});
		
	}
	
	public void writeToFile(char[] file)
	{
		if (sig == signature.BINARY_FILE) {
			writeToFile_BINARY(file);
		}
		else {
			writeToFile_DAT(file);
		}
	}
	
	
	public Features!(T) sample(int size, bool remove = true)
	{
		DistinctRandom rand = new DistinctRandom(count);
		Features!(T) newSet = new Features!(T)(size);		
		newSet.veclen = veclen;
		newSet.sig = sig;
		
		for (int i=0;i<size;++i) {
			int r = rand.nextRandom();
			newSet.vecs[i] = vecs[r];
			if (remove) {
				swap(vecs[count-i-1],vecs[r]);
			}
		}
		
		if (remove) {
			count -= size;
			vecs.length = count;
		}
		
		return newSet;
	}
	
	public void computeGT(U)(Features!(U) dataset, int nn, int skip = 0)
	{
		match = computeGroundTruth(dataset,this, nn, skip);
	}

}


