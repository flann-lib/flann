
#include "Random.h"


void seed_random(unsigned int seed)
{
    srand(seed);    
}

double rand_double(double high, double low)
{
    return low + ((high-low) * (std::rand() / (RAND_MAX + 1.0)));
}


int rand_int(int high, int low)
{
    return low + (int) ( double(high-low) * (std::rand() / (RAND_MAX + 1.0)));    
}
