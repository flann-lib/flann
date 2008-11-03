#include "Allocator.h"
#include <stdio.h>


struct Test {
    int a;
    float b;
};

int main()
{
    PooledAllocator pool;

    Test* vec[100000];
    

    for (int i=0;i<100000;i++) {
        vec[i] = pool.allocate<Test>(100);
        vec[i][0].a = 10;
        vec[i][99].b = 20.1f;
    }


}
