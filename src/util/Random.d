/*
Project: nn
*/


module util.Random;

import tango.stdc.time;

import util.Utils;



extern (C) {
	double drand48();
	double lrand48();
	double srand48(long);
}


static this() {
	srand48(time(null));
}


class DistinctRandom
{
	private int[] vals;
	private int counter;
	
	
	public this() {};
	
	public this(int n) {
		init(n);
	}
	
	public void init(int n) {
		vals.length = n;
		for(int i=0;i<n;++i) {
			vals[i] = i;
		}
		
		for (int i=0;i<n;++i) {
			int rand = cast(int) (drand48() * n);  
			assert(rand >=0 && rand < n);
			swap(vals[i], vals[rand]);
		}
		
		counter = 0;
	}
	
	public int nextRandom() {
		if (counter==vals.length) {
			return -1;
		} else {
			return vals[counter++];
		}
	}
}


