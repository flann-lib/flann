#include "Heap.h"
#include <stdio.h>


int main()
{
    Heap<int> h(10);

    int val;
    h.insert(10);
    h.insert(2);
    h.insert(12);
    h.insert(20);

    h.popMin(val);

    printf("Value is: %d\n",val);
}
