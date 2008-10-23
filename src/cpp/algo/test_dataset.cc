#include <stdio.h>
#include "Dataset.h"


int main()
{

    Dataset<int> d(100,100);


    d[10][31] = 1031;
 
    d[21][40] = 2140;

    printf("%d %d",d[10][31],d[21][40]);
}
