#include <gtest/gtest.h>
#include <time.h>

#include <flann/flann.h>
#include <flann/io/hdf5.h>

#include "flann_tests.h"

using namespace flann;

/**
 * Test fixture for SIFT 10K dataset
 */
class Linear_SIFT10K : public DatasetTestFixture<float, float> {
protected:
	Linear_SIFT10K() : DatasetTestFixture("sift10K.h5") {}
};


TEST_F(Linear_SIFT10K, TestSearch)
{
    Index<L2<float> > index(data, flann::LinearIndexParams());
    start_timer("Building linear index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, knn, flann::SearchParams(0) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_EQ(precision, 1.0); // linear search, must be exact
    printf("Precision: %g\n", precision);
}



TEST_F(Linear_SIFT10K, TestRemove)
{
	Index<L2<float> > index(data, flann::LinearIndexParams());
	start_timer("Building linear index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN before removing points...");
    index.knnSearch(query, indices, dists, knn, flann::SearchParams(128) );
    printf("done (%g seconds)\n", stop_timer());

    // remove about 50% of neighbors found
    std::set<int> neighbors;
    for (size_t i=0;i<indices.rows;++i) {
        for (size_t j=0;j<indices.cols;++j) {
        	if (rand_double()<0.5) {
        		neighbors.insert(indices[i][j]);
        	}
        }
    }
    for (std::set<int>::iterator it = neighbors.begin(); it!=neighbors.end();++it) {
    	index.removePoint(*it);
    }

    // also remove 10% of the initial points
    size_t offset = data.rows/10;
    for (size_t i=0;i<offset;++i) {
    	index.removePoint(i);
    }

    start_timer("Searching KNN after remove points...");
    index.knnSearch(query, indices, dists, 5, flann::SearchParams(128) );
    printf("done (%g seconds)\n", stop_timer());

    for (size_t i=0;i<indices.rows;++i) {
        for (size_t j=0;j<indices.cols;++j) {
        	EXPECT_GE(indices[i][j], offset);
        	EXPECT_TRUE(neighbors.find(indices[i][j])==neighbors.end());
        }
    }

	// rebuild index
	index.buildIndex();

	start_timer("Searching KNN after remove points and rebuild index...");
	index.knnSearch(query, indices, dists, knn, flann::SearchParams(128) );
	printf("done (%g seconds)\n", stop_timer());

	for (size_t i=0;i<indices.rows;++i) {
		for (size_t j=0;j<indices.cols;++j) {
			EXPECT_GE(indices[i][j], offset);
			EXPECT_TRUE(neighbors.find(indices[i][j])==neighbors.end());
		}
	}
}


TEST_F(Linear_SIFT10K, TestSave)
{
    Index<L2<float> > index(data, flann::LinearIndexParams());
    start_timer("Building linear index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, knn, flann::SearchParams(0) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    printf("Precision: %g\n", precision);
    EXPECT_EQ(precision, 1.0);

    printf("Saving index\n");
    index.save("test_saved_index.idx");

    printf("Loading index\n");
    Index<L2<float> > index2(data, flann::SavedIndexParams("test_saved_index.idx"));
    index2.buildIndex();

    start_timer("Searching KNN...");
    index2.knnSearch(query, indices, dists, knn, flann::SearchParams(0) );
    printf("done (%g seconds)\n", stop_timer());

    float precision2 = compute_precision(match, indices);
    printf("Precision: %g\n", precision2);
    EXPECT_EQ(precision, precision2);
}

TEST_F(Linear_SIFT10K, TestCopy)
{
	Index<L2<float> > index(data, flann::LinearIndexParams());
    start_timer("Building k-d tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, knn, flann::SearchParams(256) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    printf("Precision: %g\n", precision);
    EXPECT_EQ(precision, 1);

    // test copy constructor
    Index<L2<float> > index2(index);

    start_timer("Searching KNN...");
    index2.knnSearch(query, indices, dists, knn, flann::SearchParams(256) );
    printf("done (%g seconds)\n", stop_timer());

    float precision2 = compute_precision(match, indices);
    printf("Precision: %g\n", precision2);
    EXPECT_EQ(precision, precision2);

    // test assignment operator
    Index<L2<float> > index3(data, flann::LinearIndexParams());
    index3 = index;

    start_timer("Searching KNN...");
    index3.knnSearch(query, indices, dists, knn, flann::SearchParams(256) );
    printf("done (%g seconds)\n", stop_timer());

    float precision3 = compute_precision(match, indices);
    printf("Precision: %g\n", precision3);
    EXPECT_EQ(precision, precision3);
}


TEST_F(Linear_SIFT10K, TestCopy2)
{
	LinearIndex<L2<float> > index(data, flann::LinearIndexParams());
    start_timer("Building k-d tree index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, knn, flann::SearchParams(256) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    printf("Precision: %g\n", precision);
    EXPECT_EQ(precision, 1);

    // test copy constructor
    LinearIndex<L2<float> > index2(index);

    start_timer("Searching KNN...");
    index2.knnSearch(query, indices, dists, knn, flann::SearchParams(256) );
    printf("done (%g seconds)\n", stop_timer());

    float precision2 = compute_precision(match, indices);
    printf("Precision: %g\n", precision2);
    EXPECT_EQ(precision, precision2);

    // test assignment operator
    LinearIndex<L2<float> > index3(data, flann::LinearIndexParams());
    index3 = index;

    start_timer("Searching KNN...");
    index3.knnSearch(query, indices, dists, knn, flann::SearchParams(256) );
    printf("done (%g seconds)\n", stop_timer());

    float precision3 = compute_precision(match, indices);
    printf("Precision: %g\n", precision3);
    EXPECT_EQ(precision, precision3);
}


/**
 * Test fixture for SIFT 100K dataset
 */
class Linear_SIFT100K :  public DatasetTestFixture<float, float> {
protected:
	Linear_SIFT100K() : DatasetTestFixture("sift100K.h5") {}
};


TEST_F(Linear_SIFT100K, TestSearch)
{
    Index<L2<float> > index(data, flann::LinearIndexParams());
    start_timer("Building linear index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, knn, flann::SearchParams(0) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_EQ(precision, 1.0); // linear search, must be exact
    printf("Precision: %g\n", precision);
}


/**
 * Test fixture for SIFT 10K dataset with byte feature elements
 */
class Linear_SIFT10K_byte : public DatasetTestFixture<unsigned char, float> {
protected:
	Linear_SIFT10K_byte() : DatasetTestFixture("sift10K_byte.h5") {}
};



TEST_F(Linear_SIFT10K_byte, Linear)
{
    flann::Index<L2<unsigned char> > index(data, flann::LinearIndexParams());
    start_timer("Building linear index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, knn, flann::SearchParams(0) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_EQ(precision, 1.0); // linear search, must be exact
    printf("Precision: %g\n", precision);
}




class Linear_SIFT100K_byte : public DatasetTestFixture<unsigned char, float> {
protected:
	Linear_SIFT100K_byte() : DatasetTestFixture("sift100K_byte.h5") {}
};



TEST_F(Linear_SIFT100K_byte, TestSearch)
{
    flann::Index<L2<unsigned char> > index(data, flann::LinearIndexParams());
    start_timer("Building linear index...");
    index.buildIndex();
    printf("done (%g seconds)\n", stop_timer());

    start_timer("Searching KNN...");
    index.knnSearch(query, indices, dists, knn, flann::SearchParams(0) );
    printf("done (%g seconds)\n", stop_timer());

    float precision = compute_precision(match, indices);
    EXPECT_EQ(precision, 1.0); // linear search, must be exact
    printf("Precision: %g\n", precision);
}



int main(int argc, char** argv)
{
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
