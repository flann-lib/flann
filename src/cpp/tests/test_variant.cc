#include  "variant.h"
#include <stdio.h>
#include <map>

using namespace std;

int main()
{
    map<char*,Variant> params;

    params["int"] = 17;
    params["float"] = 4.5f;
    params["double"] = 9.1;
    params["string"] = "Test string";

    printf("Int value: %d\n",(int)params["int"]);
    printf("Float value: %g\n",(float)params["float"]);
    printf("Double value: %lg\n",(double)params["double"]);
    printf("String value: %s\n",(char*)params["string"]);

}
