#include <flann/flann.hpp>
#include <flann/io/hdf5.h>

using namespace flann;


int main()
{


	Matrix<float> data;
	Matrix<float> query;
	
    printf("Load data\n");
    load_from_file(data, "sift100K.h5","dataset");                              
    load_from_file(query,"sift100K.h5","query"); 

    printf("Build index\n");
    Index<L2<float> > index(data, KDTreeIndexParams(4));
    index.buildIndex();
    
    printf("Search knn\n");
    int nn = 3;
	Matrix<float> dists1(new float[query.rows*nn], query.rows, nn);
	Matrix<int> indices1(new int[query.rows*nn], query.rows, nn);
    index.knnSearch(query, indices1, dists1, nn, flann::SearchParams(32));
    
    printf("Save index\n");
    index.save("saved_index.idx");

    printf("Load index\n");
    Index<L2<float> > saved_index(data, SavedIndexParams("saved_index.idx"));


	
    printf("Search knn with saved index\n");
    Matrix<float> dists2(new float[query.rows*nn], query.rows, nn);
	Matrix<int> indices2(new int[query.rows*nn], query.rows, nn);
    saved_index.knnSearch(query, indices2, dists2, nn, SearchParams(32));

    bool ok = true;
    for (size_t i=0;i<query.cols;++i) {
        for (int j=0;j<nn;++j) {
            if (indices1[i][j]!=indices2[i][j]) {
                printf("OUCH! Different indices found at location: %d,%d\n", i,j);
                ok = false;
            }
        }
    }

    if (ok) {
        printf("Index saving seems to work fine.\n");
    }
    else {
        printf("There are errors in index saving.\n");
    }



    return 0;
}

