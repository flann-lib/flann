/************************************************************************
 * Random numbers generation.
 *
 * This module contains routines used for random number generation. 
 * 
 * Authors: Marius Muja, mariusm@cs.ubc.ca
 * 
 * Version: 0.9
 * 
 * History:
 * 
 * License:
 * 
 *************************************************************************/
module util.Random;

import tango.stdc.time;
import tango.math.Random;

import util.Utils;
import util.Logger;

/**
 * Declaration for random functions from C world.
 */
// extern (C) {
// 	double drand48();
// 	double lrand48();
// 	double srand48(long);
// }
// 


/**
 * Initialize the random number generator with a random seed
 * using the system time.
 */
static this() {
// 	srand48(time(null));
// 	srand48(0);
}


void seed_random(uint value)
{
	Random.shared.seed(value);
}

uint next_random(uint max)
{
	return Random.shared.next(max);
}

double next_random()
{
	return (cast(double)Random.shared.next())/uint.max;
}

/**
 * Random number generator that returns a distinct number from 
 * the [0,n) interval each time.
 * 
 * TODO: improve on this to use a generator function instread of an
 * array of randomly permuted numbers
 */
class DistinctRandom
{
	private int[] vals;
	private int counter;

	/**
	 * Constructor.
	 * Params:
	 *     n = the size of the interval from which to generate
	 *     		random numbers.
	 */
	public this(int n) {
		init(n);
	}
	
	public ~this()
	{
		delete vals;
	}
	
	/**
	 * Initializes the number generator.
	 * Params:
	 * 		n = the size of the interval from which to generate
	 *     		random numbers.
	 */
	private void init(int n) 
	{	
		// create and initialize an array of size n
		if (vals is null) {
			vals = new int[n];
		}
		foreach(i,ref v;vals) {
			v = i;
		}
	
		// shuffle the elements in the array
        // Fisher-Yates shuffle
		for (int i=n;i>0;--i) {
// 			int rand = cast(int) (drand48() * n);  
			int rand = next_random(i);
			assert(rand >=0 && rand < i);
			swap(vals[i], vals[rand]);
		}
		
		counter = 0;
	}
	
	/**
	 * Return a distinct random integer in greater or equal to 0 and less
	 * than 'n' on each call. It should be called maximum 'n' times.
	 * Returns: a random integer
	 */
	public int nextRandom() {
		if (counter==vals.length) {
			return -1;
		} else {
			return vals[counter++];
		}
	}
}


