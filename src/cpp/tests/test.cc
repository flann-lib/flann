#include <stdio.h>
#include <map>
#include <vector>

using namespace std;


int test(int a[2])
{
   printf("a = {%d,%d}\n",a[0],a[1]);
}






int main()
{

    int a[2];

    int* b;

    b = a;

    a[0] = 1;
    a[1] = 2;

    b[1] = 3;

    test(a);
    test(b);

    int c[3];

    test(c);


    int x = 2;
    int y = 3;

    int d[] = { x,y};

    test(d);
 
    
}
