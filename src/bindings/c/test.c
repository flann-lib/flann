
#include "nn.h"

#include <stdio.h>

int main()
{
	float dataset[] = { 10,2, 3,4, 6,6, 2,30, 2,2};
	
	float testset[] = {1,3};
	int result;
	
	Parameters p;
	p.checks=32;
	p.algo = LINEAR;
	p.trees=1;
	p.branching=2;
	p.iterations=7;
	
   nn_init();  
	find_nearest_neighbors(dataset,5,2,testset, 1, &result, 1, 95, &p);
	
   printf("Nearest neighbor index: %d\n",result);  
	return 0;
}
