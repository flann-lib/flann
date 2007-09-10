/* 
Project: nn
*/

module util.features;

import std.stdio;
import std.string;
import std.c.string;
import std.stream;
import std.ctype;
import std.conv;
import std.file;

import serialization.serializer;
import util.logger;
import util.utils;
import util.random;
import util.allocator;



class Features {

		enum signature {
			NN_FILE,
			DAT_FILE,
			BINARY_FILE	
		} 


		int count;         /* Number of vectors. */
		int veclen;         /* Length of each vector. */
		float[][] vecs;      /* Float vecs. */
		ubyte[][] uvecs;
		int[] match;         /* Array of indices to correct nearest neighbor. */
// 		int[] mtype;         /* Array of flags indicating if match is correct. */

		public this() {}
		
		public this(int size) 
		{
			this.count = size;
			vecs.length = size;
			match.length = size;
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
	private void readNNFile(FILE* fp) 
	{
	
		int vcount, veclen, vtype;
		if (fscanf(fp, "NN %d %d %d ", &vcount, &veclen, &vtype) != 3) {
			throw new Exception("Invalid NN file header.");
		}
	
		this.count = vcount;
		this.veclen = veclen;
		this.vecs = new float[][](count,veclen);
		this.match = new int[count];
// 		this.mtype = new int[count];
		
		/* Read input vectors. */
		for (int i = 0; i < count; i++) {
	
			int seq, mat, mtype;
			if (fscanf(fp, "%d %d %d", &seq, &mat, &mtype) != 3) {
				throw new Exception("Invalid NN file.");
			}
			assert(seq == i);
			this.match[i] = mat;
// 			this.mtype[i] = mtype;
	
			float val;
			/* Read an input vector. */
			for (int j = 0; j < veclen; j++) {
				if (fscanf(fp, "%f ", &val) != 1) {
					throw new Exception("Invalid vector value.");
				}
				this.vecs[i][j] = val;
			}
		}
		return this;
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
	
	private void readDATFile(FILE* fp) 
	{
		const int MAX_BUF = 10000;
		char buffer[MAX_BUF];
		
		char *ret = fgets(&buffer[0],MAX_BUF,fp);
		string line = buffer[0..strlen(&buffer[0])];
		
		string delimiter;
		delimiter ~= guessDelimiter(line);
		string[] tokens = strip(line).split(delimiter);
		
		veclen = tokens.length;
		
// 		writefln("veclen: %d",veclen);
		
		vecs = new float[][10]; // an initial size
		
		count = 0;
		vecs[count++] = toVec!(float)(tokens);
				
		ret = fgets(&buffer[0],MAX_BUF,fp);
		while (ret!=null) {
			line = buffer[0..strlen(&buffer[0])];
			tokens = strip(line).split(delimiter);
			if (tokens.length==veclen) {
				// increase vecs size if needed
				if (vecs.length==count) {
					vecs.length = vecs.length * 2;
				}
				
				vecs[count++] = toVec!(float)(tokens);
			} else {
				debug {
					Logger.log(Logger.DEBUG,"Wrong number of values on line %d... ignoring",(count+1));
				}
			}		
			ret = fgets(&buffer[0],MAX_BUF,fp);
		}
		
		vecs = vecs[0..count];
// 		writefln("read %d vectors",count);

		//dumpDatabase();
	}
	
	
	public void readMatches(string file)
	{
		FILE* fp = fopen(toStringz(file),"r");
		if (fp is null) {
			throw new Exception("Cannot open input file: "~file);
		}
		
		match.length = count;
	
		int index, m;
		for (int i=0;i<count;++i) {
			if (fscanf(fp, "%d %d", &index, &m)!=2) {
				throw new Exception("Invalid match file");
			}
			match[index] = m;
		}
		
	
	}
	
	private void dumpDatabase()
	{
		for (int i=0;i<count;++i) {
			for (int j=0;j<veclen;++j) {
				fprintf(stderr,"%f ",vecs[i][j]);
			}
			fprintf(stderr,"\n");
		}
	}
	
	private void readBINARYFile(FILE* fp) 
	{
		string header = readln(fp);
		if (strip(header) != "BINARY") {
			Logger.log(Logger.INFO,header);
			throw new Exception("Invalid file type");
		}
		
		string realFile = strip(readln(fp));
		int dim = toInt(strip(readln(fp)));
		int elemSize = toInt(strip(readln(fp)));
		
		assert(elemSize==1); // for now assume 1 byte per element
		
		ulong fileSize = getSize(realFile);
		count = fileSize / (dim*elemSize);
		
		Logger.log(Logger.INFO,"features: ",count);
				
		FILE* bFile = fopen(toStringz(realFile	),"r");
		if (bFile is null) {
			throw new Exception("Cannot open input file: "~realFile);
		}
		
		uvecs = allocate_mat!(ubyte[][])(count,dim);
	
		for (int i=0;i<count;++i) {
			fread(&uvecs[i][0],dim,1,bFile);
			
			if (i%100000==0) {
				Logger.log(Logger.INFO,"read %d elements\n",i);
			}
		}

		
		fclose(bFile);
		
		Logger.log(Logger.INFO,"Read %d elements",count);
	}

	
	
	private signature checkSignature(string file)
	{
		FILE* fp = fopen(toStringz(file),"r");
		if (fp is null) {
			throw new Exception("Cannot open input file: "~file);
		}		
		char buf[10];
		fread(&buf[0],buf.length,char.sizeof,fp);
		fclose(fp);

		if (buf[0..2]=="NN") {
			return signature.NN_FILE;
		}
		else if (buf[0..6]=="BINARY") {
				return signature.BINARY_FILE;
		}
		else {
			return signature.DAT_FILE;
		}
	}
	
	public void readFromFile(char[] file)
	{
		signature sig = checkSignature(file);
		
		FILE* fp = fopen(toStringz(file),"r");
		if (fp is null) {
			throw new Exception("Cannot open input file: "~file);
		}
		
		
		if (sig == signature.NN_FILE) {
			readNNFile(fp);
		}
		else if (sig == signature.DAT_FILE) {
			readDATFile(fp);
		}
		else if (sig == signature.BINARY_FILE) {
			readBINARYFile(fp);
		}
		
	}
	
	public void writeToFile(char[] file)
	{
		FILE* fp = fopen(toStringz(file),"w");
		if (fp is null) {
			throw new Exception("Cannot open input file: "~file);
		}
		
		for (int i=0;i<count;++i) {
			for (int j=0;j<vecs[i].length;++j) {
				if (j!=0) {
					fwritef(fp," ");
				}
				fwritef(fp,"%g",vecs[i][j]);
			}
			fwritef(fp,"\n");
		}
		
		fclose(fp);
	}
	
	
	public Features extractSubset(int size, bool remove = true)
	{
		DistinctRandom rand = new DistinctRandom(size);
		Features newSet = new Features(size);
		
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

}


