#include "Random.h"
#include <stdio.h>


int main()
{
    srand(3);
    UniqueRandom r(10);

    int rnd;
    rnd = r.next();
    while (rnd>=0) {
        printf("%d\n",rnd);
        rnd = r.next();
    }
    r.init(15);
    printf("Init\n");
    rnd = r.next();
    while (rnd>=0) {
        printf("%d\n",rnd);
        rnd = r.next();
    }
    r.init(15);
    printf("Init\n");
    rnd = r.next();
    while (rnd>=0) {
        printf("%d\n",rnd);
        rnd = r.next();
    }

}
