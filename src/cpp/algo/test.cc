#include "KMeansTree.h"
#include <stdio.h>


int main()
{
    Params params;
    Dataset<float> d(1000,128);

    params["branching"] = 32;
    params["max-iterations"] = 7;
    params["centers-init"] = "random";
    
    

   KMeansTree t(d,params);
}
