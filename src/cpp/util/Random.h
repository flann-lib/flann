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

#ifndef RANDOM_H
#define RANDOM_H

#include <algorithm>
#include <cstdlib>
#include <cassert>

using namespace std;


void seed_random(unsigned int seed);

double rand_double(double high = 1.0, double low=0);

int rand_int(int high = RAND_MAX, int low = 0);


/**
 * Random number generator that returns a distinct number from 
 * the [0,n) interval each time.
 * 
 * TODO: improve on this to use a generator function instread of an
 * array of randomly permuted numbers
 */
class UniqueRandom
{
	int* vals;
    int size;
	int counter;

public:
	/**
	 * Constructor.
	 * Params:
	 *     n = the size of the interval from which to generate
	 *     		random numbers.
	 */
	UniqueRandom(int n) : vals(NULL) {
		init(n);
	}
	
	~UniqueRandom()
	{
		delete[] vals;
	}
	
	/**
	 * Initializes the number generator.
	 * Params:
	 * 		n = the size of the interval from which to generate
	 *     		random numbers.
	 */
	void init(int n) 
	{	
    	// create and initialize an array of size n
		if (vals == NULL || n!=size) {
            delete[] vals;
	        size = n;
            vals = new int[size];
    	}
    	for(int i=0;i<size;++i) {
			vals[i] = i;
		}
	
		// shuffle the elements in the array
        // Fisher-Yates shuffle
		for (int i=size;i>0;--i) {
// 			int rand = cast(int) (drand48() * n);  
			int rnd = rand_int(i);
			assert(rnd >=0 && rnd < i);
			swap(vals[i-1], vals[rnd]);
		}
		
		counter = 0;
	}
	
	/**
	 * Return a distinct random integer in greater or equal to 0 and less
	 * than 'n' on each call. It should be called maximum 'n' times.
	 * Returns: a random integer
	 */
	int next() {
		if (counter==size) {
			return -1;
		} else {
			return vals[counter++];
		}
	}
};


#endif //RANDOM_H
