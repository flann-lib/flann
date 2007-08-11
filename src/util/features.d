/* 
Project: aggnn
*/

module util.features;

import std.stdio;
import std.string;
import std.c.string;
import std.stream;
import std.conv;

import serialization.serializer;

alias float[] feature;

static this() {
	Serializer.registerClass!(Feature)();
}


class Feature {
	int id;
	float[] data;
	int checkID;
	
	this() {
	};
	
	this(int id, float[] data) {
		this();
		this.id = id;
		this.data = data;
	}
	
		
	float opIndex(int index) { return data[index]; }
	float opIndexAssign(int index, float value) { data[index] = value; return value; }
	
	void describe(T)(T ar)
	{
		ar.describe(id);
		ar.describe(data);
	}	
};



class Features {

		enum signature {
			NN_FILE,
			DAT_FILE
		} 


		int count;         /* Number of vectors. */
		int veclen;         /* Length of each vector. */
		feature[] vecs;      /* Float vecs. */
		int[] match;         /* Array of indices to correct nearest neighbor. */
// 		int[] mtype;         /* Array of flags indicating if match is correct. */


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
	private void readNNFile(string firstLine, FILE* fp) 
	{
	
		int vcount, veclen, vtype;
		if (sscanf(&firstLine[0], "NN %d %d %d", &vcount, &veclen, &vtype) != 3) {
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
	
	
	float[] toFloatVec(string[] strVec)
	{
		float[] vec = new float[strVec.length];
		for (int i=0;i<strVec.length;++i) {
			vec[i] = toFloat(strVec[i]);
		}
		
		return vec;
	}
	
	
	private void readDATFile(string firstLine, FILE* fp) 
	{
		string[] tokens = firstLine.split();
		veclen = tokens.length;
		
// 		writefln("veclen: %d",veclen);
		
		vecs = new float[][10]; // an initial size
		
		count = 0;
		vecs[count++] = toFloatVec(tokens);
		
		
		const int MAX_BUF = 10000;
		
		string buffer;
		buffer.length = MAX_BUF;
		char *ret = fgets(&buffer[0],MAX_BUF,fp);
		while (ret!=null) {
			string line = buffer[0..strlen(&buffer[0])];
			tokens = split(line);
			if (tokens.length==veclen) {
				// increase vecs size if needed
				if (vecs.length==count) {
					vecs.length = vecs.length * 2;
				}
				
				vecs[count++] = toFloatVec(tokens);
			} else {
				debug {
					writefln("Wrong number of values on line %d... ignoring",(count+1));
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
	
	private signature checkSignature(string header)
	{
		if (header[0..2]=="NN") {
			return signature.NN_FILE;
		}
		else {
			return signature.DAT_FILE;
		}
	}
	
	public void readFromFile(char[] file)
	{
		FILE* fp;
		if (file is null) {
			fp = stdin;
		}
		else {
			fp = fopen(toStringz(file),"r");
			if (fp is null) {
				throw new Exception("Cannot open input file: "~file);
			}
		}
		
		string line;
		
		readln(fp,line);
		
		signature sig = checkSignature(line);
		
		if (sig == signature.NN_FILE) {
			readNNFile(line,fp);
		}
		else if (sig == signature.DAT_FILE) {
			readDATFile(line,fp);
		}
		
	}
	

}