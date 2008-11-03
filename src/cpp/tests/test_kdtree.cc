#include "KDTree.h"
#include <stdio.h>


int main()
{
    Params params;
    Dataset<float> d(1000,128);

    params["trees"] = 8;
    
    for (int i=0;i<1000;++i) {
        for (int j=0;j<128;++j) {
            d[i][j] = (float) rand_double();
        }
    }

    

   KDTree t(d,params);
    t.buildIndex();
}
