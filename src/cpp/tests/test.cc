#include <stdio.h>
#include <map>
#include <vector>

using namespace std;






int main()
{

    vector<int> vi(10);
    vector<int> vi2(10);

    vi[0] = 10;
    
    vi2 = vi;

    vi2[0] = 12;

    printf("vi = %d, vi2 = %d \n",vi[0],vi2[0]);
    
}
