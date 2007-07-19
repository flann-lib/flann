/* 
Project: aggnn
*/

import std.stdio;
import std.string;



class Features {

		int count;         /* Number of vectors. */
		int veclen;         /* Length of each vector. */
		float[][] vecs;      /* Float vecs. */
		int[] match;         /* Array of indices to correct nearest neighbor. */
		int[] mtype;         /* Array of flags indicating if match is correct. */


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
	
		int vcount, veclen, vtype;
		if (fscanf(fp, "NN %d %d %d", &vcount, &veclen, &vtype) != 3) {
			throw new Exception("Invalid NN file header.");
		}
	
		this.count = vcount;
		this.veclen = veclen;
		this.vecs = new float[][count];
		this.match = new int[count];
		this.mtype = new int[count];
		
		/* Read input vectors. */
		for (int i = 0; i < count; i++) {
	
			int seq, mat, mtype;
			if (fscanf(fp, "%d %d %d", &seq, &mat, &mtype) != 3) {
				throw new Exception("Invalid NN file.");
			}
			assert(seq == i);
			this.match[i] = mat;
			this.mtype[i] = mtype;
			this.vecs[i] = new float[veclen];
	
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

}