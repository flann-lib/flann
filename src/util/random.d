/*
Project: aggnn
*/


module util.random;

import util.utils;

class DistinctRandom
{
	private int[] vals;
	private int counter;
	
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
		return vals[counter++];
	}
}


